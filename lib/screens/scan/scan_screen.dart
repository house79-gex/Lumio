import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../providers/scan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/scan_result.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  static const List<int> maxPhotosOptions = [10, 25, 50, 100];
  int _maxPhotos = 25;
  bool _incremental = true;
  bool _useAi = true;

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanStateProvider);
    final profileAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scansione')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Seleziona un profilo dalle impostazioni'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profilo: ${profile.emoji} ${profile.name}', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        const Text('Numero massimo di foto da analizzare:'),
                        DropdownButton<int>(
                          value: _maxPhotos,
                          isExpanded: true,
                          items: maxPhotosOptions.map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                          onChanged: scanState.status == ScanStatus.scanning
                              ? null
                              : (v) {
                                  if (v != null) setState(() => _maxPhotos = v);
                                },
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          value: _incremental,
                          onChanged: scanState.status == ScanStatus.scanning ? null : (v) => setState(() => _incremental = v ?? true),
                          title: const Text('Scansione incrementale'),
                          subtitle: const Text('Analizza solo foto non già catalogate'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 12),
                        const Text('Modalità di scansione:'),
                        const SizedBox(height: 4),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              icon: Icon(Icons.bolt_outlined),
                              label: Text('Base (senza IA)'),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              icon: Icon(Icons.auto_awesome),
                              label: Text('Completa (con IA)'),
                            ),
                          ],
                          selected: {_useAi},
                          onSelectionChanged: scanState.status == ScanStatus.scanning
                              ? null
                              : (values) {
                                  setState(() {
                                    _useAi = values.first;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (scanState.status == ScanStatus.scanning) ...[
                  LinearProgressIndicator(value: scanState.total > 0 ? scanState.progress : null),
                  const SizedBox(height: 8),
                  Text('${scanState.processed} / ${scanState.total}'),
                  const SizedBox(height: 16),
                ],
                if (scanState.status == ScanStatus.done) ...[
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 48),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Completate ${scanState.results.length} foto.',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (scanState.status == ScanStatus.error) ...[
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(scanState.errorMessage ?? 'Errore'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (scanState.results.isNotEmpty) ...[
                  Text('Risultati (${scanState.results.length})', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...scanState.results.take(20).map((r) => ListTile(
                        leading: Text(r.emoji ?? '📷', style: const TextStyle(fontSize: 24)),
                        title: Text(r.categoryName ?? r.description ?? '—'),
                        subtitle: Text('Confidenza: ${(r.confidence * 100).toStringAsFixed(0)}%${r.toReview ? ' · Da revisionare' : ''}'),
                      )),
                  if (scanState.results.length > 20) Text('... e altri ${scanState.results.length - 20}'),
                  const SizedBox(height: 16),
                ],
                FilledButton.icon(
                  onPressed: scanState.status == ScanStatus.scanning
                      ? null
                      : () async {
                          debugPrint('[ScanScreen] avvio scansione: maxPhotos=$_maxPhotos, incremental=$_incremental, useAi=$_useAi');
                          ref.read(scanStateProvider.notifier).startScan(
                                maxPhotos: _maxPhotos,
                                incremental: _incremental,
                                useAi: _useAi,
                                scanAllDevice: false,
                                profile: profile,
                              );
                        },
                  icon: const Icon(Icons.search),
                  label: Text(
                    scanState.status == ScanStatus.scanning
                        ? 'Scansione in corso...'
                        : (_useAi ? 'Avvia scansione completa (IA)' : 'Avvia scansione base (senza IA)'),
                  ),
                ),
                if (scanState.status == ScanStatus.done || scanState.status == ScanStatus.error)
                  TextButton(
                    onPressed: () => ref.read(scanStateProvider.notifier).reset(),
                    child: const Text('Reset'),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
      ),
    );
  }
}
