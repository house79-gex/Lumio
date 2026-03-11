import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';
import '../../providers/albums_provider.dart';
import '../../models/photo.dart';

class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.albumId, required this.albumName});

  final String albumId;
  final String albumName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider);
    final repo = ref.watch(albumRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(albumName)),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          return FutureBuilder<List<Photo>>(
            future: repo.getPhotosByAlbum(albumId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final photos = snapshot.data!;
              if (photos.isEmpty) {
                return const Center(child: Text('Nessuna foto in questo album'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: photos.length,
                itemBuilder: (context, i) {
                  final photo = photos[i];
                  final file = File(photo.path);
                  if (!file.existsSync()) {
                    return const Icon(Icons.broken_image);
                  }
                  return Image.file(
                    file,
                    fit: BoxFit.cover,
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
      ),
    );
  }
}
