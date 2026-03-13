import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/profession.dart';
import '../../models/scan_result.dart';
import '../../providers/scan_provider.dart';
import '../../providers/albums_provider.dart';
import '../../services/notification_service.dart';

enum ScanProgressMode { fullDeviceGrezza, syncLibrary }

/// Schermata a schermo intero durante scansione: barra avanzamento, blocco indietro, notifica a fine.
class ScanProgressScreen extends ConsumerStatefulWidget {
  const ScanProgressScreen({
    super.key,
    required this.mode,
    required this.profile,
  });

  final ScanProgressMode mode;
  final UserProfile profile;

  @override
  ConsumerState<ScanProgressScreen> createState() => _ScanProgressScreenState();
}

class _ScanProgressScreenState extends ConsumerState<ScanProgressScreen>
    with SingleTickerProviderStateMixin {
  bool _started = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _pulse.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    await NotificationService.init();
    await NotificationService.requestPermissionIfNeeded();
    await WakelockPlus.enable();
    final notifier = ref.read(scanStateProvider.notifier);
    try {
      if (widget.mode == ScanProgressMode.fullDeviceGrezza) {
        await notifier.startFullDeviceGrezza(profile: widget.profile);
      } else {
        await notifier.syncLibrary(profile: widget.profile);
      }
    } catch (_) {}
    await WakelockPlus.disable();
    if (!mounted) return;
    final state = ref.read(scanStateProvider);
    ref.invalidate(albumsForActiveProfileProvider);
    if (state.status == ScanStatus.done) {
      await NotificationService.showScanComplete(processed: state.processed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Completato: ${state.processed} foto. Controlla anche la notifica.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } else if (state.status == ScanStatus.error) {
      await NotificationService.showScanError(state.errorMessage ?? 'Errore sconosciuto');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage ?? 'Errore'), backgroundColor: Colors.red),
        );
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(scanStateProvider);
    final theme = Theme.of(context);
    final title = widget.mode == ScanProgressMode.fullDeviceGrezza
        ? 'Scansione dispositivo'
        : 'Sincronizzazione libreria';
    final subtitle = widget.mode == ScanProgressMode.fullDeviceGrezza
        ? 'Stiamo indicizzando tutte le foto (senza IA). Con migliaia di foto può richiedere diversi minuti.'
        : 'Rimozione file eliminati + aggiunta foto nuove.';

    return PopScope(
      canPop: scan.status != ScanStatus.scanning,
      onPopInvokedWithResult: (didPop, result) {
        if (scan.status == ScanStatus.scanning && !didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendi il termine della scansione, oppure chiudi l\'app (la scansione si interromperà).'),
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                      child: Icon(Icons.photo_library_rounded, size: 48, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (scan.status == ScanStatus.scanning) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: scan.total > 0 ? scan.processed / scan.total : null,
                      minHeight: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    scan.total > 0
                        ? '${scan.processed} / ${scan.total} foto (${(100 * scan.processed / scan.total).toStringAsFixed(0)}%)'
                        : 'Preparazione…',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Suggerimento', style: theme.textTheme.titleSmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Lo schermo resta acceso per non interrompere il lavoro.\n'
                            '• Puoi usare altre app con il tasto Home: se il telefono non chiude PhotoAI, la scansione continua; altrimenti riapri l\'app.\n'
                            '• Al termine riceverai una notifica e potrai chiudere questa schermata.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (scan.status == ScanStatus.done)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 72),
                          const SizedBox(height: 16),
                          Text('Completato: ${scan.processed} foto', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Torna all\'app'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (scan.status == ScanStatus.error)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 64),
                          const SizedBox(height: 16),
                          Text(scan.errorMessage ?? 'Errore', textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          FilledButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Chiudi')),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
