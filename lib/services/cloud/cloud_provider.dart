import 'dart:io';

/// Interfaccia per provider cloud (Drive, Dropbox, OneDrive, Mega, cartella manuale)
abstract class CloudProvider {
  String get name;
  String get emoji;
  Future<bool> authenticate();
  Future<void> uploadFile(File file, String remotePath);
  Future<void> createFolder(String remotePath);
  Future<List<String>> listFolder(String remotePath);
  Future<bool> fileExists(String remotePath);
}
