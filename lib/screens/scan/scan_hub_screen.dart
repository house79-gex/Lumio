import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';
import '../../repositories/settings_repository.dart';
import 'scan_screen.dart';
import 'scan_progress_screen.dart';

/// Centro dedicato a scansione e raggruppamento (separato da Impostazioni app).
class ScanHubScreen extends ConsumerStatefulWidget {
  const ScanHubScreen({super.key});

  @override
  ConsumerState<ScanHubScreen> createState() => _ScanHubScreenState();
}

class _ScanHubScreenState extends ConsumerState<ScanHubScreen> {
  final _settingsRepo = SettingsRepository();
  bool _groupByYear = true;
  bool _groupByMonth = false;
  bool _groupBySource = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final y = await _settingsRepo.getGroupByYear();
    final m = await _settingsRepo.getGroupByMonth();
    final s = await _settingsRepo.getGroupBySource();
    if (mounted) setState(() {
      _groupByYear = y;
      _groupByMonth = m;
      _groupBySource = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scansione & gruppi'),
        actions: [
          Tooltip(
            message: 'Scansione rapida con limite foto e opzione IA',
            child: IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Seleziona un profilo da Altro → Profilo'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder_copy, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Raggruppamento grezzo', style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          Tooltip(
                            message: 'Si applica alle prossime scansioni. Ogni foto può finire in più album (es. Anno + Origine).',
                            child: Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Prima della IA, le foto vanno in album come Tutte le foto, Da revisionare, e in base alle opzioni sotto.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Per anno'),
                        subtitle: const Text('Album tipo "Anno 2024"'),
                        value: _groupByYear,
                        onChanged: (v) async {
                          setState(() => _groupByYear = v);
                          await _settingsRepo.setGroupByYear(v);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Per mese'),
                        subtitle: const Text('Album tipo "Mese 2024-03"'),
                        value: _groupByMonth,
                        onChanged: (v) async {
                          setState(() => _groupByMonth = v);
                          await _settingsRepo.setGroupByMonth(v);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Per origine'),
                        subtitle: const Text('WhatsApp, Fotocamera, Altro (dal percorso file)'),
                        value: _groupBySource,
                        onChanged: (v) async {
                          setState(() => _groupBySource = v);
                          await _settingsRepo.setGroupBySource(v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Tooltip(
                message: 'Indicizza tutte le immagini del telefono senza IA. Apre schermata con avanzamento e notifica a fine.',
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(20)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        fullscreenDialog: true,
                        builder: (_) => ScanProgressScreen(
                          mode: ScanProgressMode.fullDeviceGrezza,
                          profile: profile,
                        ),
                      ),
                    ).then((_) => ref.invalidate(activeProfileProvider));
                  },
                  icon: const Icon(Icons.phone_android),
                  label: const Text('Scansiona tutto il dispositivo'),
                ),
              ),
              const SizedBox(height: 12),
              Tooltip(
                message: 'Rimuove dal catalogo le foto cancellate dalla galleria e aggiunge le nuove.',
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        fullscreenDialog: true,
                        builder: (_) => ScanProgressScreen(
                          mode: ScanProgressMode.syncLibrary,
                          profile: profile,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizza libreria'),
                ),
              ),
              const SizedBox(height: 24),
              Text('Scansione rapida', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Limite foto + IA on/off'),
                subtitle: const Text('Es. 25–100 foto, con o senza Gemini'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
