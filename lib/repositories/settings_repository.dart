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
    return list.map((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      final base = map['baseProfession'] as Map<String, dynamic>;
      final cats = (map['categories'] as List<dynamic>).map((c) => ProfessionCategory.fromJson(c as Map<String, dynamic>)).toList();
      return UserProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        emoji: map['emoji'] as String? ?? '👤',
        baseProfession: Profession.fromJson(base),
        categories: cats,
        baseFolderPath: map['baseFolderPath'] as String? ?? '',
        cloudSyncEnabled: Map<String, bool>.from(map['cloudSyncEnabled'] as Map? ?? {}),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
    }).toList();
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
