import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../album/album_list_screen.dart';
import '../album/album_detail_screen.dart';
import '../settings/api_key_setup_screen.dart';
import '../../providers/profile_provider.dart';
import '../../providers/albums_provider.dart';
import '../../providers/ai_provider.dart';

/// Home “pulita”: profilo, IA, anteprima album. Scansione → tab dedicato.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider);
    final albumsAsync = ref.watch(albumsForActiveProfileProvider);
    final aiEnabledAsync = ref.watch(aiEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PhotoAI'),
        actions: [
          Tooltip(
            message: 'Apri tutti gli album',
            child: IconButton(
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlbumListScreen())),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Nessun profilo attivo'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/profession_picker'),
                    child: const Text('Scegli professione'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeProfileProvider);
              ref.invalidate(albumsForActiveProfileProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  aiEnabledAsync.when(
                    data: (enabled) {
                      if (enabled) return const SizedBox.shrink();
                      return Card(
                        color: Colors.amber.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
                          title: const Text('Attiva l\'IA'),
                          subtitle: const Text('Serve per catalogare le foto per contenuto.'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiKeySetupScreen())),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: ListTile(
                      leading: Text(profile.emoji, style: const TextStyle(fontSize: 36)),
                      title: Text(profile.name),
                      subtitle: Text('${profile.categories.length} categorie · scheda Altro per modificare'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.folder_open, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Primo utilizzo?', style: Theme.of(context).textTheme.titleSmall),
                                const Text(
                                  'Vai alla scheda Scansione in basso → "Scansiona tutto il dispositivo". '
                                  'Vedrai barra di avanzamento e una notifica al termine.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  albumsAsync.when(
                    data: (albums) {
                      if (albums.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(Icons.photo_library_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
                                const SizedBox(height: 12),
                                const Text('Nessun album ancora'),
                                const SizedBox(height: 8),
                                const Text('Scheda Scansione → indicizza il dispositivo', textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Album recenti', style: Theme.of(context).textTheme.titleMedium),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlbumListScreen())),
                                child: const Text('Vedi tutti'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.15,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: albums.length > 6 ? 6 : albums.length,
                            itemBuilder: (context, i) {
                              final album = albums[i];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AlbumDetailScreen(albumId: album.id, albumName: album.name),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(album.emoji ?? '📁', style: const TextStyle(fontSize: 28)),
                                        const SizedBox(height: 4),
                                        Text(album.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                        Text('${album.photoCount} foto', style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                    error: (e, _) => Text('Errore: $e'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
      ),
    );
  }
}
