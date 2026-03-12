import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'cloud_provider.dart';

/// Provider Google Drive con OAuth reale e upload
class GoogleDriveProvider implements CloudProvider {
  GoogleDriveProvider() : _signIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope, drive.DriveApi.driveScope]);

  final GoogleSignIn _signIn;
  drive.DriveApi? _api;
  final Map<String, String> _folderIdByPath = {};

  @override
  String get name => 'Google Drive';
  @override
  String get emoji => '📁';

  @override
  Future<bool> authenticate() async {
    try {
      final account = await _signIn.signIn();
      if (account == null) return false;
      final client = await _signIn.authenticatedClient();
      if (client == null) return false;
      _api = drive.DriveApi(client);
      _folderIdByPath.clear();
      return true;
    } catch (_) {
      _api = null;
      return false;
    }
  }

  Future<bool> get isAuthenticated async {
    final account = _signIn.currentUser;
    if (account == null) return false;
    final client = await _signIn.authenticatedClient();
    return client != null;
  }

  /// Risolvi o crea la cartella per il path (es. "PhotoAI/2024") e ritorna l'id.
  Future<String?> _ensureFolderId(String remotePath) async {
    if (_api == null) return null;
    final path = remotePath.replaceAll(r'\', '/').replaceFirst(RegExp(r'^/'), '');
    if (path.isEmpty) return 'root';
    if (_folderIdByPath.containsKey(path)) return _folderIdByPath[path];
    final parts = path.split('/');
    String? parentId = 'root';
    for (var i = 0; i < parts.length; i++) {
      final segment = parts[i];
      if (segment.isEmpty) continue;
      final key = parts.sublist(0, i + 1).join('/');
      if (_folderIdByPath.containsKey(key)) {
        parentId = _folderIdByPath[key];
        continue;
      }
      final existing = await _findFolderByName(segment, parentId!);
      if (existing != null) {
        _folderIdByPath[key] = existing;
        parentId = existing;
        continue;
      }
      final meta = drive.File()
        ..name = segment
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [parentId];
      final created = await _api!.files.create(meta);
      final id = created.id;
      if (id == null) return null;
      _folderIdByPath[key] = id;
      parentId = id;
    }
    return parentId;
  }

  Future<String?> _findFolderByName(String name, String parentId) async {
    if (_api == null) return null;
    final list = await _api!.files.list(
      q: "name = '$name' and '$parentId' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      $fields: 'files(id)',
      pageSize: 1,
    );
    final files = list.files;
    if (files == null || files.isEmpty) return null;
    return files.first.id;
  }

  @override
  Future<void> createFolder(String remotePath) async {
    await _ensureFolderId(remotePath);
  }

  @override
  Future<bool> fileExists(String remotePath) async {
    if (_api == null) return false;
    final path = remotePath.replaceAll(r'\', '/').replaceFirst(RegExp(r'^/'), '');
    if (path.isEmpty) return false;
    final parts = path.split('/');
    if (parts.isEmpty) return false;
    final fileName = parts.last;
    final parentPath = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('/') : '';
    final parentId = await _ensureFolderId(parentPath);
    if (parentId == null) return false;
    final list = await _api!.files.list(
      q: "name = '$fileName' and '$parentId' in parents and trashed = false",
      pageSize: 1,
    );
    return list.files != null && list.files!.isNotEmpty;
  }

  @override
  Future<List<String>> listFolder(String remotePath) async {
    if (_api == null) return [];
    final parentId = await _ensureFolderId(remotePath);
    if (parentId == null) return [];
    final list = await _api!.files.list(
      q: "'$parentId' in parents and trashed = false",
      $fields: 'files(name)',
    );
    final files = list.files;
    if (files == null) return [];
    return files.map((f) => f.name ?? '').where((n) => n.isNotEmpty).toList();
  }

  @override
  Future<void> uploadFile(File file, String remotePath) async {
    if (_api == null) return;
    final path = remotePath.replaceAll(r'\', '/').replaceFirst(RegExp(r'^/'), '');
    final parts = path.split('/');
    if (parts.isEmpty) return;
    final fileName = parts.last;
    final parentPath = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('/') : '';
    final parentId = await _ensureFolderId(parentPath);
    if (parentId == null) return;
    final meta = drive.File()
      ..name = fileName
      ..parents = [parentId];
    final media = drive.Media(file.openRead(), file.lengthSync());
    await _api!.files.create(meta, uploadMedia: media);
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    _api = null;
    _folderIdByPath.clear();
  }
}
