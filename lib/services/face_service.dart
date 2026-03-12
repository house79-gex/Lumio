import 'dart:io';
import 'dart:ui' show Rect;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Risultato del rilevamento volti su una singola immagine
class FaceDetectionResult {
  final String imagePath;
  final int faceCount;
  final List<Rect> bounds;

  FaceDetectionResult({required this.imagePath, required this.faceCount, required this.bounds});
}

/// Servizio per il rilevamento volti con ML Kit
class FaceService {
  FaceDetector? _detector;

  FaceDetector get _getDetector {
    _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: false,
        enableContours: false,
        minFaceSize: 0.15,
        enableTracking: false,
      ),
    );
    return _detector!;
  }

  /// Rileva i volti in un'immagine dal path di file.
  /// Ritorna null se il file non esiste o in caso di errore.
  Future<FaceDetectionResult?> detectFaces(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _getDetector.processImage(inputImage);
      final bounds = faces.map((f) => f.boundingBox).toList();
      return FaceDetectionResult(
        imagePath: imagePath,
        faceCount: faces.length,
        bounds: bounds,
      );
    } catch (_) {
      return null;
    }
  }

  /// Rilascia le risorse del detector (chiamare quando non serve più)
  Future<void> close() async {
    await _detector?.close();
    _detector = null;
  }
}
