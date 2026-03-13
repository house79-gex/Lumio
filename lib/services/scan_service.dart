import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/photo.dart';
import '../models/album.dart';
import '../models/scan_result.dart';
import '../models/profession.dart';
import 'gallery_service.dart';
import 'ai_service.dart';
import 'folder_service.dart';
import '../repositories/album_repository.dart';
import '../repositories/settings_repository.dart';

class ScanService {
  ScanService({AIService? aiService}) : _ai = aiService ?? AIService();
  final GalleryService _gallery = GalleryService();
  final AIService _ai;
  final FolderService _folder = FolderService();
  final AlbumRepository _albumRepo = AlbumRepository();
  final _uuid = const Uuid();

  static const int _batchSize = 200;

  /// Sincronizza: rimuove dal catalogo i file eliminati dal dispositivo.
  Future<int> purgeMissingPhotos() => _albumRepo.purgeMissingFiles();

  Future<void> runScan({
    required UserProfile profile,
    required void Function(ScanState) onProgress,
    int maxPhotos = 50,
    bool incremental = true,
    bool useAi = true,
    bool scanAllDevice = false,
  }) async {
    onProgress(ScanState(status: ScanStatus.scanning, total: 0, processed: 0));
    final hasAccess = await _gallery.hasAccess();
    if (!hasAccess) {
      final ok = await _gallery.requestPermission();
      if (!ok) {
        onProgress(ScanState(status: ScanStatus.error, errorMessage: 'Permesso galleria negato'));
        return;
      }
    }
    Set<String> existingPaths = {};
    if (incremental) {
      existingPaths = await _albumRepo.getAnalyzedPhotoPaths();
    }
    final settings = SettingsRepository();
    final groupByYear = await settings.getGroupByYear();
    final groupByMonth = await settings.getGroupByMonth();
    final groupBySource = await settings.getGroupBySource();

    final now = DateTime.now().millisecondsSinceEpoch;
    final threshold = AppConstants.defaultConfidenceThreshold;
    final results = <ScanResult>[];
    int processedCount = 0;

    await _folder.createProfileFolderStructure(profile);

    if (scanAllDevice) {
      final totalAssets = await _gallery.getTotalImageCount();
      debugPrint('[ScanService] runScan TUTTO IL DISPOSITIVO -> ~$totalAssets immagini');
      final unlimited = maxPhotos <= 0;
      for (var start = 0; start < totalAssets; start += _batchSize) {
        final batch = await _gallery.getImageAssets(limit: _batchSize, start: start);
        for (final asset in batch) {
          if (!unlimited && processedCount >= maxPhotos) break;
          final done = await _processOneAsset(
            asset: asset,
            profile: profile,
            existingPaths: existingPaths,
            incremental: incremental,
            useAi: useAi,
            groupByYear: groupByYear,
            groupByMonth: groupByMonth,
            groupBySource: groupBySource,
            now: now,
            threshold: threshold,
            results: results,
          );
          if (done) processedCount++;
        }
        onProgress(ScanState(
          status: ScanStatus.scanning,
          total: totalAssets,
          processed: processedCount,
          results: List.from(results),
        ));
        if (!unlimited && processedCount >= maxPhotos) break;
      }
      onProgress(ScanState(status: ScanStatus.done, total: totalAssets, processed: processedCount, results: results));
      return;
    }

    final allAssets = await _gallery.getImageAssets(limit: maxPhotos * 3);
    debugPrint('[ScanService] runScan -> assets caricati: ${allAssets.length}');
    for (var i = 0; i < allAssets.length && processedCount < maxPhotos; i++) {
      final done = await _processOneAsset(
        asset: allAssets[i],
        profile: profile,
        existingPaths: existingPaths,
        incremental: incremental,
        useAi: useAi,
        groupByYear: groupByYear,
        groupByMonth: groupByMonth,
        groupBySource: groupBySource,
        now: now,
        threshold: threshold,
        results: results,
      );
      if (done) processedCount++;
      onProgress(ScanState(
        status: ScanStatus.scanning,
        total: maxPhotos,
        processed: processedCount,
        results: List.from(results),
      ));
    }
    onProgress(ScanState(status: ScanStatus.done, total: maxPhotos, processed: processedCount, results: results));
  }

  /// Catalogazione IA solo per foto già in un album (per photoIds).
  Future<int> runAiCatalogForPhotos({
    required UserProfile profile,
    required List<String> photoIds,
    void Function(int done, int total)? onProgress,
  }) async {
    var done = 0;
    final all = await _albumRepo.getAllPhotos();
    final map = {for (final p in all) p.id: p};
    for (final id in photoIds) {
      final photo = map[id];
      if (photo == null) continue;
      final path = photo.path;
      final analyzed = await _ai.analyzeImage(imagePath: path, categories: profile.categories);
      if (analyzed != null) {
        final categoryId = analyzed['category_id'] as String?;
        final confidence = (analyzed['confidence'] as num?)?.toDouble() ?? 0.0;
        final description = analyzed['description'] as String?;
        // Update photo in DB - need updatePhoto in repository
        await _albumRepo.updatePhotoAi(id, categoryId, confidence, description);
        final threshold = AppConstants.defaultConfidenceThreshold;
        final toReview = confidence < threshold;
        String? categoryName;
        String? categoryFolderName;
        String? emoji;
        bool categorySplitByYear = false;
        int? year = photo.year;
        if (categoryId != null) {
          final catList = profile.categories.where((c) => c.id == categoryId).toList();
          if (catList.isNotEmpty) {
            final cat = catList.first;
            categoryName = cat.name;
            categoryFolderName = cat.folderName;
            emoji = cat.emoji;
            categorySplitByYear = cat.splitByYear;
          }
        }
        if (!toReview && categoryName != null) {
          final localPath = await _folder.copyPhotoToAlbumFolder(
            sourcePath: path,
            categoryFolderName: categoryFolderName ?? categoryName,
            profileName: profile.name,
            year: categorySplitByYear ? year : null,
            splitByYear: categorySplitByYear,
            toReview: false,
          );
          if (localPath != null) {
            await _albumRepo.updatePhotoLocalPath(id, localPath);
          }
          final albumName = categorySplitByYear && year != null ? '$categoryName $year' : categoryName;
          final album = await _ensureAlbum(profile, albumName, emoji ?? '📁', categoryId, localPath ?? path);
          if (album != null) await _albumRepo.addPhotoToAlbum(id, album.id);
        }
      }
      done++;
      onProgress?.call(done, photoIds.length);
    }
    return done;
  }

  Future<bool> _processOneAsset({
    required AssetEntity asset,
    required UserProfile profile,
    required Set<String> existingPaths,
    required bool incremental,
    required bool useAi,
    required bool groupByYear,
    required bool groupByMonth,
    required bool groupBySource,
    required int now,
    required double threshold,
    required List<ScanResult> results,
  }) async {
    try {
      final path = await _gallery.getFilePath(asset);
      if (path == null || (incremental && existingPaths.contains(path))) {
        return false;
      }

      final photoId = _uuid.v4();
      String? categoryId;
      String? categoryName;
      String? categoryFolderName;
      String? emoji;
      bool categorySplitByYear = false;
      double confidence = 0.0;
      String? description;
      bool toReview = true;
      int? year;
      int? dateTaken = now;

      final secs = asset.createDateSecond as int?;
      if (secs != null) {
        final createDate = DateTime.fromMillisecondsSinceEpoch(secs * 1000);
        year = createDate.year;
        dateTaken = createDate.millisecondsSinceEpoch;
      }

      if (useAi) {
        final analyzed = await _ai.analyzeImage(imagePath: path, categories: profile.categories);
        if (analyzed != null) {
          categoryId = analyzed['category_id'] as String?;
          confidence = (analyzed['confidence'] as num?)?.toDouble() ?? 0.0;
          description = analyzed['description'] as String?;
          toReview = confidence < threshold;
          final catList = profile.categories.where((c) => c.id == categoryId).toList();
          if (catList.isNotEmpty) {
            final cat = catList.first;
            categoryName = cat.name;
            categoryFolderName = cat.folderName;
            emoji = cat.emoji;
            categorySplitByYear = cat.splitByYear;
          }
        }
      }

      final folderNameForCopy = toReview
          ? AppConstants.daRevisionareFolder
          : (categoryFolderName ?? categoryName ?? 'Altro');
      final localPath = await _folder.copyPhotoToAlbumFolder(
        sourcePath: path,
        categoryFolderName: folderNameForCopy,
        profileName: profile.name,
        year: categorySplitByYear ? year : null,
        splitByYear: categorySplitByYear,
        toReview: toReview,
      );

      final photo = Photo(
        id: photoId,
        path: path,
        dateTaken: dateTaken,
        year: year,
        aiCategory: categoryId,
        aiConfidence: confidence,
        aiDescription: description,
        analyzedAt: now,
        localFolderPath: localPath,
      );
      await _albumRepo.insertPhoto(photo);
      existingPaths.add(path);
      debugPrint('[ScanService] photo inserita: $path (aiCategory=$categoryId, toReview=$toReview)');

      Future<void> link(Album? album) async {
        if (album != null) await _albumRepo.addPhotoToAlbum(photoId, album.id);
      }

      final allPhotosAlbum = await _ensureAlbum(profile, 'Tutte le foto', '📷', null, localPath);
      if (allPhotosAlbum != null) await link(allPhotosAlbum);

      Album? album;
      if (!toReview && categoryName != null) {
        final albumName = categorySplitByYear && year != null ? '$categoryName $year' : categoryName;
        album = await _ensureAlbum(profile, albumName, emoji ?? '📁', categoryId, localPath);
      } else {
        album = await _ensureAlbum(profile, 'Da revisionare', '🧐', null, localPath);
      }
      if (album != null) await link(album);

      if (groupByYear && year != null) {
        final yearAlbum = await _ensureAlbum(profile, 'Anno $year', '📅', null, localPath);
        if (yearAlbum != null) await link(yearAlbum);
      }
      if (groupByMonth) {
        final dt = DateTime.fromMillisecondsSinceEpoch(dateTaken!);
        final monthStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        final monthAlbum = await _ensureAlbum(profile, 'Mese $monthStr', '📆', null, localPath);
        if (monthAlbum != null) await link(monthAlbum);
      }
      if (groupBySource) {
        String source = 'Altro';
        final lower = path.toLowerCase();
        if (lower.contains('whatsapp')) {
          source = 'WhatsApp';
        } else if (lower.contains('dcim') || lower.contains('camera')) {
          source = 'Fotocamera';
        }
        final sourceAlbum = await _ensureAlbum(profile, 'Origine: $source', '📂', null, localPath);
        if (sourceAlbum != null) await link(sourceAlbum);
      }

      results.add(ScanResult(
        photoId: photoId,
        path: path,
        categoryId: categoryId,
        categoryName: categoryName,
        emoji: emoji,
        confidence: confidence,
        description: description,
        year: year,
        toReview: toReview,
      ));
      return true;
    } catch (e, st) {
      debugPrint('[ScanService] errore asset: $e\n$st');
      return false;
    }
  }

  Future<Album?> _ensureAlbum(UserProfile profile, String name, String emoji, String? categoryId, String? folderPath) async {
    final existing = await _albumRepo.getAlbumsByProfile(profile.id);
    final found = existing.where((a) => a.name == name).toList();
    if (found.isNotEmpty) return found.first;
    final id = _uuid.v4();
    final album = Album(
      id: id,
      profileId: profile.id,
      name: name,
      emoji: emoji,
      categoryId: categoryId,
      folderPath: folderPath != null ? p.dirname(folderPath) : null,
      photoCount: 0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _albumRepo.insertAlbum(album);
    return album;
  }
}
