import 'dart:io';
import 'cloud_provider.dart';

/// Stub Google Drive: richiede configurazione OAuth reale
class GoogleDriveProvider implements CloudProvider {
  @override
  String get name => 'Google Drive';
  @override
  String get emoji => '📁';

  bool _authenticated = false;

  @override
  Future<bool> authenticate() async {
    // TODO: integrare google_sign_in + googleapis
    _authenticated = true;
    return true;
  }

  @override
  Future<void> createFolder(String remotePath) async {
    if (!_authenticated) return;
    // TODO: creare cartelle su Drive
  }

  @override
  Future<bool> fileExists(String remotePath) async => false;

  @override
  Future<List<String>> listFolder(String remotePath) async => [];

  @override
  Future<void> uploadFile(File file, String remotePath) async {
    if (!_authenticated) return;
    // TODO: upload tramite Drive API
  }
}
