import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/gemini_prompts.dart';
import '../core/utils/image_utils.dart';
import '../models/profession.dart';

class AIService {
  GenerativeModel? _model;
  String? _apiKey;

  void setApiKey(String? key) {
    _apiKey = key;
    _model = key != null && key.isNotEmpty
        ? GenerativeModel(model: 'gemini-2.0-flash', apiKey: key)
        : null;
  }

  Future<bool> isConfigured() async {
    return _apiKey != null && _apiKey!.isNotEmpty;
  }

  /// Analizza una foto e restituisce category_id, confidence, description
  Future<Map<String, dynamic>?> analyzeImage({
    required String imagePath,
    required List<ProfessionCategory> categories,
  }) async {
    if (_model == null) return null;
    final compressed = await ImageUtils.compressForAi(imagePath);
    if (compressed == null || !await compressed.exists()) return null;
    final bytes = await compressed.readAsBytes();
    final prompt = GeminiPrompts.buildCategoryPrompt(
      categories.map((c) => '${c.name} (id: ${c.id}): ${c.description}').toList(),
    );
    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ]),
      ];
      final response = await _model!.generateContent(content);
      final text = response.text?.trim();
      if (text == null) return null;
      // Estrai JSON dalla risposta (può essere inline in markdown)
      String jsonStr = text;
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        jsonStr = text.substring(start, end + 1);
      }
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final categoryId = map['category_id'] as String? ?? 'altro';
      final confidence = (map['confidence'] as num?)?.toDouble() ?? 0.0;
      final description = map['description'] as String? ?? '';
      return {
        'category_id': categoryId,
        'confidence': confidence,
        'description': description,
      };
    } catch (_) {
      return null;
    }
  }
}
