import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../constants/app_constants.dart';

class ImageUtils {
  /// Comprimi e ridimensiona immagine per invio a Gemini (max 800px)
  static Future<File?> compressForAi(String sourcePath) async {
    final dir = await getTemporaryDirectory();
    final name = p.basenameWithoutExtension(sourcePath);
    final targetPath = p.join(dir.path, '${name}_compressed.jpg');
    final file = File(sourcePath);
    if (!await file.exists()) return null;
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: 85,
      minWidth: AppConstants.maxImageSizeForAi,
      minHeight: AppConstants.maxImageSizeForAi,
    );
    return result != null ? File(result.path) : null;
  }

  /// Leggi bytes da file (per API)
  static Future<List<int>?> readBytes(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }
}
