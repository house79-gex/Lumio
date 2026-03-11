import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import 'profile_provider.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final service = AIService();
  ref.watch(activeProfileProvider); // non usato ma per rebuild
  return service;
});

/// Inizializza la chiave API Gemini all'avvio
final initGeminiKeyProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  final service = ref.watch(aiServiceProvider);
  final key = await repo.getGeminiApiKey();
  service.setApiKey(key);
});
