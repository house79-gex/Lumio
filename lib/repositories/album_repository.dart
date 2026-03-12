import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../core/database/database_helper.dart';
import '../models/photo.dart';
import '../models/album.dart';

class AlbumRepository {
  Future<Database> get _db => DatabaseHelper.database;

  Future<void> insertPhoto(Photo photo) async {
    final db = await _db;
    await db.insert('photos', photo.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertAlbum(Album album) async {
    final db = await _db;
    await db.insert('albums', album.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAlbumPhotoCount(String albumId, int count) async {
    final db = await _db;
    await db.update('albums', {'photo_count': count, 'updated_at': DateTime.now().millisecondsSinceEpoch}, where: 'id = ?', whereArgs: [albumId]);
  }

  Future<List<Album>> getAlbumsByProfile(String profileId) async {
    final db = await _db;
    final list = await db.query('albums', where: 'profile_id = ?', whereArgs: [profileId], orderBy: 'name');
    return list.map((e) => Album.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Photo>> getPhotosByAlbum(String albumId) async {
    final db = await _db;
    final album = await db.query('albums', where: 'id = ?', whereArgs: [albumId]);
    if (album.isEmpty) return [];
    final folderPath = album.first['folder_path'] as String?;
    if (folderPath == null || folderPath.isEmpty) return [];
    final albumDirNormalized = p.normalize(p.absolute(folderPath));
    final list = await db.query('photos', where: 'local_folder_path IS NOT NULL');
    return list
        .where((row) {
          final localPath = row['local_folder_path'] as String? ?? '';
          if (localPath.isEmpty) return false;
          final photoDirNormalized = p.normalize(p.absolute(p.dirname(localPath)));
          return photoDirNormalized == albumDirNormalized;
        })
        .map((e) => Photo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Photo>> getAllPhotos() async {
    final db = await _db;
    final list = await db.query('photos', orderBy: 'analyzed_at DESC');
    return list.map((e) => Photo.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Insieme dei path già presenti in DB (per scansione incrementale)
  Future<Set<String>> getAnalyzedPhotoPaths() async {
    final db = await _db;
    final list = await db.query('photos', columns: ['path']);
    return list.map((e) => e['path'] as String).toSet();
  }
}
