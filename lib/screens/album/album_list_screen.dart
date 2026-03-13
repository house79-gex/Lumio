import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/albums_provider.dart';
import '../../providers/profile_provider.dart';
import 'album_detail_screen.dart';

class AlbumListScreen extends ConsumerWidget {
  const AlbumListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsForActiveProfileProvider);
    final profileAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Album')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Nessun profilo attivo'));
          }
          return albumsAsync.when(
            data: (albums) {
              if (albums.isEmpty) {
                return const Center(child: Text('Nessun album'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: albums.length,
                itemBuilder: (context, i) {
                  final album = albums[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Text(album.emoji ?? '📁', style: const TextStyle(fontSize: 28)),
                      title: Text(album.name),
                      subtitle: Text('${album.photoCount} foto'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AlbumDetailScreen(albumId: album.id, albumName: album.name),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'delete') {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Elimina album'),
                                content: Text('Eliminare "${album.name}"? Le foto restano in "Tutte le foto" / altri album se presenti.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Elimina')),
                                ],
                              ),
                            );
                            if (ok == true && context.mounted) {
                              await ref.read(albumRepositoryProvider).deleteAlbum(album.id);
                              ref.invalidate(albumsForActiveProfileProvider);
                            }
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'delete', child: Text('Elimina album')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Errore: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
      ),
    );
  }
}
