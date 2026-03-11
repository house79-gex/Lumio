import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/profession.dart';

class FolderService {
  Future<Directory> getBaseDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString(AppConstants.prefsKeyBaseFolderPath);
    if (customPath != null && customPath.isNotEmpty) {
      return Directory(customPath);
    }
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDir.path, AppConstants.baseFolderName));
  }

  Future<String> getBasePath() async {
    final dir = await getBaseDirectory();
    return dir.path;
  }

  /// Crea la struttura cartelle per un profilo
  Future<void> createProfileFolderStructure(UserProfile profile) async {
    final base = await getBaseDirectory();
    final profileDir = Directory(p.join(base.path, _sanitize(profile.name)));
    if (!await profileDir.exists()) await profileDir.create(recursive: true);
    for (final category in profile.categories) {
      final categoryPath = p.join(profileDir.path, category.folderName);
      await Directory(categoryPath).create(recursive: true);
    }
    final daRevisionare = Directory(p.join(base.path, AppConstants.daRevisionareFolder));
    if (!await daRevisionare.exists()) await daRevisionare.create(recursive: true);
  }

  /// Copia la foto nella cartella corretta
  Future<String?> copyPhotoToAlbumFolder({
    required String sourcePath,
    required String categoryFolderName,
    required String profileName,
    int? year,
    String? personName,
    bool toReview = false,
  }) async {
    final base = await getBaseDirectory();
    String targetDirPath;
    if (toReview) {
      targetDirPath = p.join(base.path, AppConstants.daRevisionareFolder);
    } else if (personName != null) {
      targetDirPath = p.join(base.path, _sanitize(profileName), 'Persone', _sanitize(personName));
    } else {
      targetDirPath = p.join(base.path, _sanitize(profileName), categoryFolderName);
      if (year != null) targetDirPath = p.join(targetDirPath, year.toString());
    }
    await Directory(targetDirPath).create(recursive: true);
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return null;
    final fileName = p.basename(sourcePath);
    final targetPath = p.join(targetDirPath, fileName);
    final targetFile = File(targetPath);
    if (!await targetFile.exists()) {
      await sourceFile.copy(targetPath);
    }
    return targetPath;
  }

  static String _sanitize(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}
