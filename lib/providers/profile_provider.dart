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
  return repo.isOnboardingDone();
});
