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
    final assets = await _gallery.getImageAssets(limit: maxPhotos);
    final total = assets.length;
    if (total == 0) {
      onProgress(ScanState(status: ScanStatus.done, total: 0, processed: 0, results: []));
      return;
    }
    await _folder.createProfileFolderStructure(profile);
    final threshold = AppConstants.defaultConfidenceThreshold;
    final results = <ScanResult>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < assets.length; i++) {
      final asset = assets[i];
      final path = await _gallery.getFilePath(asset);
      if (path == null) continue;
      final photoId = _uuid.v4();
      String? categoryId;
      String? categoryName;
      String? categoryFolderName;
      String? emoji;
      double confidence = 0.0;
      String? description;
      bool toReview = true;
      int? year;
      int? dateTaken = now;

      // Estrai anno e data da metadati asset (createDateSecond / EXIF)
      final secs = asset.createDateSecond;
      if (secs != null) {
        final createDate = DateTime.fromMillisecondsSinceEpoch(secs * 1000);
        year = createDate.year;
        dateTaken = createDate.millisecondsSinceEpoch;
      }

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
        }
      }

      final folderNameForCopy = toReview
          ? AppConstants.daRevisionareFolder
          : (categoryFolderName ?? categoryName ?? 'Altro');
      final localPath = await _folder.copyPhotoToAlbumFolder(
        sourcePath: path,
        categoryFolderName: folderNameForCopy,
        profileName: profile.name,
        year: year,
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

      if (!toReview && categoryName != null) {
        var album = await _ensureAlbum(profile, categoryName, emoji ?? '📁', categoryId, localPath);
        if (album != null) {
          await _albumRepo.updateAlbumPhotoCount(album.id, (album.photoCount) + 1);
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
      onProgress(ScanState(status: ScanStatus.scanning, total: total, processed: i + 1, results: List.from(results)));
    }

    onProgress(ScanState(status: ScanStatus.done, total: total, processed: total, results: results));
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
