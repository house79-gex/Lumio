import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
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

  Future<void> runScan({
    required UserProfile profile,
    required void Function(ScanState) onProgress,
    int maxPhotos = 50,
    bool incremental = true,
    bool useAi = true,
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
    // Preferenze di raggruppamento "grezzo"
    final settings = SettingsRepository();
    final groupByYear = await settings.getGroupByYear();
    final groupByMonth = await settings.getGroupByMonth();
    final groupBySource = await settings.getGroupBySource();
    final allAssets = await _gallery.getImageAssets(limit: maxPhotos * 3);
    debugPrint('[ScanService] runScan -> assets caricati: ${allAssets.length}');
    final now = DateTime.now().millisecondsSinceEpoch;
    final threshold = AppConstants.defaultConfidenceThreshold;
    final results = <ScanResult>[];
    int processedCount = 0;

    await _folder.createProfileFolderStructure(profile);

    for (var i = 0; i < allAssets.length && processedCount < maxPhotos; i++) {
      try {
        final asset = allAssets[i];
        final path = await _gallery.getFilePath(asset);
        if (path == null || (incremental && existingPaths.contains(path))) {
          debugPrint('[ScanService] skip asset (path nullo o già analizzato): $path');
          continue;
        }
        processedCount++;

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

        final secs = asset.createDateSecond;
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
        debugPrint('[ScanService] photo inserita: $path (aiCategory=$categoryId, toReview=$toReview)');

        // Album "Tutte le foto" (sempre presente, indipendentemente dall'IA).
        final allPhotosAlbum = await _ensureAlbum(
          profile,
          'Tutte le foto',
          '📷',
          null,
          localPath,
        );
        if (allPhotosAlbum != null) {
          await _albumRepo.updateAlbumPhotoCount(allPhotosAlbum.id, (allPhotosAlbum.photoCount) + 1);
          debugPrint('[ScanService] aggiornato album Tutte le foto, count=${allPhotosAlbum.photoCount + 1}');
        }

        // Crea/aggiorna l'album corrispondente.
        // - Se la foto è classificata con confidenza sufficiente -> album per categoria/anno.
        // - Altrimenti finisce sempre in un album "Da revisionare", così qualcosa compare comunque in UI.
        Album? album;
        if (!toReview && categoryName != null) {
          final albumName = categorySplitByYear && year != null ? '$categoryName $year' : categoryName;
          album = await _ensureAlbum(profile, albumName, emoji ?? '📁', categoryId, localPath);
        } else {
          album = await _ensureAlbum(
            profile,
            'Da revisionare',
            '🧐',
            null,
            localPath,
          );
        }
        if (album != null) {
          await _albumRepo.updateAlbumPhotoCount(album.id, (album.photoCount) + 1);
          debugPrint('[ScanService] aggiornato album ${album.name}, count=${album.photoCount + 1}');
        }

        // Raggruppamenti "grezzi" opzionali
        // 1) Per anno
        if (groupByYear && year != null) {
          final yearAlbum = await _ensureAlbum(
            profile,
            'Anno $year',
            '📅',
            null,
            localPath,
          );
          if (yearAlbum != null) {
            await _albumRepo.updateAlbumPhotoCount(yearAlbum.id, (yearAlbum.photoCount) + 1);
          }
        }

        // 2) Per mese (YYYY-MM)
        if (groupByMonth && dateTaken != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(dateTaken);
          final monthStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          final monthAlbum = await _ensureAlbum(
            profile,
            'Mese $monthStr',
            '📆',
            null,
            localPath,
          );
          if (monthAlbum != null) {
            await _albumRepo.updateAlbumPhotoCount(monthAlbum.id, (monthAlbum.photoCount) + 1);
          }
        }

        // 3) Per origine (WhatsApp, Fotocamera, Altro)
        if (groupBySource) {
          String source = 'Altro';
          final lower = path.toLowerCase();
          if (lower.contains('whatsapp')) {
            source = 'WhatsApp';
          } else if (lower.contains('dcim') || lower.contains('camera')) {
            source = 'Fotocamera';
          }
          final sourceAlbum = await _ensureAlbum(
            profile,
            'Origine: $source',
            '📂',
            null,
            localPath,
          );
          if (sourceAlbum != null) {
            await _albumRepo.updateAlbumPhotoCount(sourceAlbum.id, (sourceAlbum.photoCount) + 1);
          }
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
        onProgress(ScanState(
          status: ScanStatus.scanning,
          total: maxPhotos,
          processed: processedCount,
          results: List.from(results),
        ));
      } catch (e, st) {
        debugPrint('[ScanService] errore su asset index=$i: $e\n$st');
      }
    }

    onProgress(ScanState(status: ScanStatus.done, total: maxPhotos, processed: processedCount, results: results));
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
