import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';
import '../../providers/albums_provider.dart';
import '../../providers/scan_provider.dart';
import '../../models/photo.dart';
import '../../models/album.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  const AlbumDetailScreen({super.key, required this.albumId, required this.albumName});

  final String albumId;
  final String albumName;

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  final Set<String> _selected = {};
  bool _loadingAi = false;
  List<Photo> _photos = [];

  Future<void> _reload() async {
    final repo = ref.read(albumRepositoryProvider);
    final list = await repo.getPhotosByAlbum(widget.albumId);
    if (mounted) setState(() => _photos = list);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _moveToAlbum() async {
    if (_selected.isEmpty) return;
    final profile = await ref.read(activeProfileProvider.future);
    if (profile == null) return;
    final albums = await ref.read(albumRepositoryProvider).getAlbumsByProfile(profile.id);
    final targets = albums.where((a) => a.id != widget.albumId).toList();
    if (!mounted) return;
    final chosen = await showModalBottomSheet<Album>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          const ListTile(title: Text('Sposta in album…')),
          ...targets.map((a) => ListTile(
                leading: Text(a.emoji ?? '📁'),
                title: Text(a.name),
                onTap: () => Navigator.pop(ctx, a),
              )),
        ],
      ),
    );
    if (chosen == null) return;
    final repo = ref.read(albumRepositoryProvider);
    for (final id in _selected) {
      await repo.movePhotoToAlbum(id, widget.albumId, chosen.id);
    }
    if (mounted) {
      setState(() => _selected.clear());
      await _reload();
      ref.invalidate(albumsForActiveProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Spostate in ${chosen.name}')));
    }
  }

  Future<void> _catalogWithAi() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleziona almeno una foto')));
      return;
    }
    final profile = await ref.read(activeProfileProvider.future);
    if (profile == null) return;
    setState(() => _loadingAi = true);
    try {
      final scan = ref.read(scanServiceProvider);
      await scan.runAiCatalogForPhotos(
        profile: profile,
        photoIds: _selected.toList(),
        onProgress: (d, t) {
          if (mounted) setState(() {});
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catalogazione IA completata')));
        setState(() => _selected.clear());
        await _reload();
        ref.invalidate(albumsForActiveProfileProvider);
      }
    } finally {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.albumName),
        actions: [
          if (_selected.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.drive_file_move_outline),
              onPressed: _loadingAi ? null : _moveToAlbum,
              tooltip: 'Sposta in altro album',
            ),
            IconButton(
              icon: _loadingAi ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
              onPressed: _loadingAi ? null : _catalogWithAi,
              tooltip: 'Cataloga con IA',
            ),
          ],
        ],
      ),
      body: _photos.isEmpty
          ? const Center(child: Text('Nessuna foto in questo album'))
          : Column(
              children: [
                if (_selected.isNotEmpty)
                  Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Text('${_selected.length} selezionate'),
                          const Spacer(),
                          TextButton(onPressed: () => setState(() => _selected.clear()), child: const Text('Annulla')),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, i) {
                      final photo = _photos[i];
                      final file = File(photo.path);
                      final sel = _selected.contains(photo.id);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (sel) {
                              _selected.remove(photo.id);
                            } else {
                              _selected.add(photo.id);
                            }
                          });
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (file.existsSync())
                              Image.file(file, fit: BoxFit.cover)
                            else
                              const ColoredBox(color: Colors.black26, child: Icon(Icons.broken_image)),
                            if (sel)
                              Container(
                                alignment: Alignment.topRight,
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.check_circle, color: Colors.white, shadows: [Shadow(blurRadius: 4)]),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
