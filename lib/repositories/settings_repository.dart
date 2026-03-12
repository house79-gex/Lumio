import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/profession.dart';

class SettingsRepository {
  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefsKeyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsKeyOnboardingDone, value);
  }

  Future<String?> getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefsKeyActiveProfileId);
  }

  Future<void> setActiveProfileId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(AppConstants.prefsKeyActiveProfileId);
    } else {
      await prefs.setString(AppConstants.prefsKeyActiveProfileId, id);
    }
  }

  Future<String?> getBaseFolderPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefsKeyBaseFolderPath);
  }

  Future<void> setBaseFolderPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(AppConstants.prefsKeyBaseFolderPath);
    } else {
      await prefs.setString(AppConstants.prefsKeyBaseFolderPath, path);
    }
  }

  Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefsKeyGeminiApiKey);
  }

  Future<void> setGeminiApiKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == null) {
      await prefs.remove(AppConstants.prefsKeyGeminiApiKey);
    } else {
      await prefs.setString(AppConstants.prefsKeyGeminiApiKey, key);
    }
  }

  Future<int?> getLastScanAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.prefsKeyLastScanAt);
  }

  Future<void> setLastScanAt(int? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(AppConstants.prefsKeyLastScanAt);
    } else {
      await prefs.setInt(AppConstants.prefsKeyLastScanAt, value);
    }
  }

  static const String _keyProfiles = 'user_profiles';

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getProfiles();
    final index = list.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      list[index] = profile;
    } else {
      list.add(profile);
    }
    final encoded = list.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_keyProfiles, encoded);
  }

  Future<List<UserProfile>> getProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyProfiles) ?? [];
    return list.map((e) => UserProfile.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  /// Esporta il profilo attivo come JSON. Ritorna null se non c'è profilo attivo.
  Future<String?> exportActiveProfileAsJson() async {
    final p = await getActiveProfile();
    return p == null ? null : jsonEncode(p.toJson());
  }

  /// Importa un profilo da JSON, lo salva nella lista e lo imposta come attivo.
  Future<UserProfile?> importProfileFromJson(String jsonString) async {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final profile = UserProfile.fromJson(map);
    await saveProfile(profile);
    await setActiveProfileId(profile.id);
    return profile;
  }

  Future<UserProfile?> getActiveProfile() async {
    final id = await getActiveProfileId();
    if (id == null) return null;
    final list = await getProfiles();
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
