import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../album/album_list_screen.dart';
import '../album/album_detail_screen.dart';
import '../scan/scan_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/api_key_setup_screen.dart';
import '../../providers/profile_provider.dart';
import '../../providers/albums_provider.dart';
import '../../providers/ai_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider);
    final albumsAsync = ref.watch(albumsForActiveProfileProvider);
    final aiEnabledAsync = ref.watch(aiEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PhotoAI Catalog'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
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
                  // Banner IA non configurata
                  aiEnabledAsync.when(
                    data: (enabled) {
                      if (enabled) return const SizedBox.shrink();
                      return Card(
                        color: Colors.amber.shade50,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Text(
                                    'IA non ancora configurata',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Per creare album intelligenti in base al contenuto delle foto, attiva ora la chiave IA di Google Gemini.',
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ApiKeySetupScreen()),
                                    );
                                  },
                                  child: const Text('Configura IA ora'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(profile.emoji, style: const TextStyle(fontSize: 40)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
                                Text('${profile.categories.length} categorie', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  albumsAsync.when(
                    data: (albums) {
                      debugPrint('[HomeScreen] albums per profilo ${profile.id}: ${albums.length}');
                      if (albums.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Icon(Icons.photo_library_outlined, size: 48),
                                const SizedBox(height: 8),
                                const Text('Nessun album ancora. Avvia una scansione.'),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
                                  icon: const Icon(Icons.search),
                                  label: const Text('Nuova scansione'),
                                ),
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
                              Text('Album (${albums.length})', style: Theme.of(context).textTheme.titleMedium),
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
                              childAspectRatio: 1.1,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: albums.length > 6 ? 6 : albums.length,
                            itemBuilder: (context, i) {
                              final album = albums[i];
                              return Card(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AlbumDetailScreen(albumId: album.id, albumName: album.name),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(album.emoji ?? '📁', style: const TextStyle(fontSize: 32)),
                                        const SizedBox(height: 4),
                                        Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                        Text('${album.photoCount} foto', style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
                            icon: const Icon(Icons.search),
                            label: const Text('Nuova scansione'),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
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
