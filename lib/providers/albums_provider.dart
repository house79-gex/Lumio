import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import '../repositories/album_repository.dart';
import 'profile_provider.dart';

final albumRepositoryProvider = Provider<AlbumRepository>((ref) => AlbumRepository());

final albumsListProvider = FutureProvider.family<List<Album>, String>((ref, profileId) async {
  final repo = ref.watch(albumRepositoryProvider);
  return repo.getAlbumsByProfile(profileId);
});

final albumsForActiveProfileProvider = FutureProvider<List<Album>>((ref) async {
  final profile = await ref.watch(activeProfileProvider.future);
  if (profile == null) return [];
  final repo = ref.watch(albumRepositoryProvider);
  return repo.getAlbumsByProfile(profile.id);
});
