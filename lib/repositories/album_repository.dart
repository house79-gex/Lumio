import 'dart:io';
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

  Future<void> updatePhotoAi(String photoId, String? aiCategory, double? aiConfidence, String? aiDescription) async {
    final db = await _db;
    await db.update(
      'photos',
      {
        'ai_category': aiCategory,
        'ai_confidence': aiConfidence,
        'ai_description': aiDescription,
        'analyzed_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [photoId],
    );
  }

  Future<void> updatePhotoLocalPath(String photoId, String localPath) async {
    final db = await _db;
    await db.update('photos', {'local_folder_path': localPath}, where: 'id = ?', whereArgs: [photoId]);
  }

  Future<void> insertAlbum(Album album) async {
    final db = await _db;
    await db.insert('albums', album.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAlbumPhotoCount(String albumId, int count) async {
    final db = await _db;
    await db.update('albums', {'photo_count': count, 'updated_at': DateTime.now().millisecondsSinceEpoch}, where: 'id = ?', whereArgs: [albumId]);
  }

  Future<void> addPhotoToAlbum(String photoId, String albumId) async {
    final db = await _db;
    await db.insert(
      'album_photos',
      {'photo_id': photoId, 'album_id': albumId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await _recalcAlbumCount(albumId);
  }

  Future<void> removePhotoFromAlbum(String photoId, String albumId) async {
    final db = await _db;
    await db.delete('album_photos', where: 'photo_id = ? AND album_id = ?', whereArgs: [photoId, albumId]);
    await _recalcAlbumCount(albumId);
  }

  Future<void> _recalcAlbumCount(String albumId) async {
    final db = await _db;
    final n = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM album_photos WHERE album_id = ?', [albumId]),
    ) ?? 0;
    await updateAlbumPhotoCount(albumId, n);
  }

  Future<List<Album>> getAlbumsByProfile(String profileId) async {
    final db = await _db;
    final list = await db.query('albums', where: 'profile_id = ?', whereArgs: [profileId], orderBy: 'name');
    return list.map((e) => Album.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Photo>> getPhotosByAlbum(String albumId) async {
    final db = await _db;
    final linked = await db.rawQuery('''
      SELECT p.* FROM photos p
      INNER JOIN album_photos ap ON ap.photo_id = p.id AND ap.album_id = ?
      ORDER BY p.analyzed_at DESC
    ''', [albumId]);
    if (linked.isNotEmpty) {
      return linked.map((e) => Photo.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    // Legacy: per cartella
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

  Future<Set<String>> getAnalyzedPhotoPaths() async {
    final db = await _db;
    final list = await db.query('photos', columns: ['path']);
    return list.map((e) => e['path'] as String).toSet();
  }

  /// Elimina album e i soli legami album_photos (le foto restano nel catalogo se in altri album).
  Future<void> deleteAlbum(String albumId) async {
    final db = await _db;
    await db.delete('album_photos', where: 'album_id = ?', whereArgs: [albumId]);
    await db.delete('albums', where: 'id = ?', whereArgs: [albumId]);
  }

  /// Sposta membership da un album grezzo a un altro (stesso file su disco).
  Future<void> movePhotoToAlbum(String photoId, String fromAlbumId, String toAlbumId) async {
    await removePhotoFromAlbum(photoId, fromAlbumId);
    await addPhotoToAlbum(photoId, toAlbumId);
  }

  /// Rimuovi dal DB le foto il cui file originale non esiste più.
  Future<int> purgeMissingFiles() async {
    final db = await _db;
    final list = await db.query('photos', columns: ['id', 'path']);
    var removed = 0;
    for (final row in list) {
      final id = row['id'] as String;
      final path = row['path'] as String;
      if (!File(path).existsSync()) {
        await db.delete('album_photos', where: 'photo_id = ?', whereArgs: [id]);
        await db.delete('photos', where: 'id = ?', whereArgs: [id]);
        removed++;
      }
    }
    // Ricalcola conteggi album toccati
    final albums = await db.query('albums', columns: ['id']);
    for (final a in albums) {
      await _recalcAlbumCount(a['id'] as String);
    }
    return removed;
  }
}
