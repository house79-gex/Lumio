import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profession.dart';
import '../repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepository());

final activeProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getActiveProfile();
});

final profilesListProvider = FutureProvider<List<UserProfile>>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getProfiles();
});

final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  try {
    // Protezione extra: se per qualsiasi motivo SharedPreferences dovesse bloccarsi,
    // dopo pochi secondi consideriamo l'onboarding "non completato" e mostriamo comunque la welcome.
    return await repo.isOnboardingDone().timeout(
          const Duration(seconds: 3),
          onTimeout: () => false,
        );
  } catch (_) {
    // In caso di errore imprevisto, fallback sicuro: onboarding non fatto -> mostra WelcomeScreen.
    return false;
  }
});
