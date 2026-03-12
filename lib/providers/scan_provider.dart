import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_result.dart';
import '../models/profession.dart';
import '../services/scan_service.dart';
import 'profile_provider.dart';
import 'ai_provider.dart';
import 'albums_provider.dart';

final scanServiceProvider = Provider<ScanService>((ref) {
  final ai = ref.watch(aiServiceProvider);
  return ScanService(aiService: ai);
});

final scanStateProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  final scanService = ref.watch(scanServiceProvider);
  final profile = ref.watch(activeProfileProvider);
  return ScanNotifier(ref, scanService, profile);
});

class ScanNotifier extends StateNotifier<ScanState> {
  ScanNotifier(this._ref, this._scanService, this._profile) : super(const ScanState());

  final Ref _ref;
  final ScanService _scanService;
  final AsyncValue<UserProfile?> _profile;

  void reset() {
    state = const ScanState();
  }

  Future<void> startScan({int maxPhotos = 50, bool incremental = true, bool useAi = true, UserProfile? profile}) async {
    final p = profile ?? _profile.valueOrNull;
    if (p == null) {
      state = ScanState(status: ScanStatus.error, errorMessage: 'Seleziona un profilo');
      return;
    }
    state = const ScanState(status: ScanStatus.scanning, total: 0, processed: 0);
    await _scanService.runScan(
      profile: p,
      onProgress: (s) => state = s,
      maxPhotos: maxPhotos,
      incremental: incremental,
      useAi: useAi,
    );
    // Dopo una scansione completa, ricarichiamo gli album del profilo attivo.
    _ref.invalidate(albumsForActiveProfileProvider);
  }
}
