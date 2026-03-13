import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _db;
  static const int _version = 2;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'photoai_catalog.db');
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS album_photos (
          photo_id TEXT NOT NULL,
          album_id TEXT NOT NULL,
          PRIMARY KEY (photo_id, album_id)
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_album_photos_album ON album_photos(album_id)');
      // Backfill: collega ogni foto agli album che condividono la stessa cartella (comportamento legacy)
      final albums = await db.query('albums', columns: ['id', 'folder_path']);
      for (final row in albums) {
        final albumId = row['id'] as String;
        final folderPath = row['folder_path'] as String?;
        if (folderPath == null || folderPath.isEmpty) continue;
        final photos = await db.query('photos', columns: ['id', 'local_folder_path']);
        for (final p in photos) {
          final localPath = p['local_folder_path'] as String?;
          if (localPath == null || localPath.isEmpty) continue;
          final dir = dirname(localPath);
          if (dir == folderPath) {
            await db.insert(
              'album_photos',
              {'photo_id': p['id'], 'album_id': albumId},
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
      }
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT,
        profession_id TEXT,
        base_folder_path TEXT,
        is_active INTEGER DEFAULT 0,
        created_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        profile_id TEXT,
        name TEXT NOT NULL,
        emoji TEXT,
        description TEXT,
        split_by_year INTEGER DEFAULT 0,
        folder_name TEXT,
        confidence_threshold REAL DEFAULT 0.75,
        is_predefined INTEGER DEFAULT 0,
        sort_order INTEGER,
        is_active INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        date_taken INTEGER,
        year INTEGER,
        ai_category TEXT,
        ai_confidence REAL,
        ai_description TEXT,
        is_manually_moved INTEGER DEFAULT 0,
        analyzed_at INTEGER,
        latitude REAL,
        longitude REAL,
        local_folder_path TEXT,
        cloud_sync_status TEXT DEFAULT 'pending',
        cloud_sync_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE albums (
        id TEXT PRIMARY KEY,
        profile_id TEXT,
        name TEXT NOT NULL,
        emoji TEXT,
        category_id TEXT,
        person_id TEXT,
        year INTEGER,
        folder_path TEXT,
        cover_photo_id TEXT,
        photo_count INTEGER DEFAULT 0,
        cloud_synced INTEGER DEFAULT 0,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE album_photos (
        photo_id TEXT NOT NULL,
        album_id TEXT NOT NULL,
        PRIMARY KEY (photo_id, album_id)
      )
    ''');
    await db.execute('CREATE INDEX idx_album_photos_album ON album_photos(album_id)');
    await db.execute('''
      CREATE TABLE persons (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        nickname TEXT,
        relationship TEXT,
        profile_image_path TEXT,
        album_id TEXT,
        folder_path TEXT,
        created_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE photo_persons (
        photo_id TEXT,
        person_id TEXT,
        confidence REAL,
        PRIMARY KEY (photo_id, person_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE cloud_sync_log (
        id TEXT PRIMARY KEY,
        provider TEXT,
        photo_id TEXT,
        remote_path TEXT,
        status TEXT,
        error_message TEXT,
        synced_at INTEGER
      )
    ''');
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
