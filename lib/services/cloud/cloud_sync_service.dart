import 'dart:io';
import 'package:path/path.dart' as p;
import 'cloud_provider.dart';
import '../folder_service.dart';

/// Sincronizza le cartelle locali PhotoAI con i provider cloud attivi
class CloudSyncService {
  final FolderService _folderService = FolderService();

  Future<void> syncAll({
    required List<CloudProvider> activeProviders,
    bool wifiOnly = true,
  }) async {
    if (activeProviders.isEmpty) return;
    final basePath = await _folderService.getBasePath();
    final baseDir = Directory(basePath);
    if (!await baseDir.exists()) return;
    for (final provider in activeProviders) {
      await _syncDirectoryToProvider(baseDir, provider, 'PhotoAI');
    }
  }

  Future<void> _syncDirectoryToProvider(
    Directory localDir,
    CloudProvider provider,
    String remotePath,
  ) async {
    await provider.createFolder(remotePath);
    await for (final entity in localDir.list()) {
      if (entity is Directory) {
        final folderName = p.basename(entity.path);
        await _syncDirectoryToProvider(entity, provider, '$remotePath/$folderName');
      } else if (entity is File) {
        final fileName = p.basename(entity.path);
        final remoteFilePath = '$remotePath/$fileName';
        if (!await provider.fileExists(remoteFilePath)) {
          await provider.uploadFile(entity, remoteFilePath);
        }
      }
    }
  }
}
