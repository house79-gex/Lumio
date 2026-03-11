/// Costanti applicative
class AppConstants {
  AppConstants._();

  static const String appName = 'PhotoAI Catalog';
  static const String baseFolderName = 'PhotoAI';
  static const String daRevisionareFolder = '_Da_revisionare';
  static const double defaultConfidenceThreshold = 0.75;
  static const int maxImageSizeForAi = 800;
  static const int geminiRateLimitPerMinute = 14;
  static const String prefsKeyOnboardingDone = 'onboarding_done';
  static const String prefsKeyActiveProfileId = 'active_profile_id';
  static const String prefsKeyBaseFolderPath = 'base_folder_path';
  static const String prefsKeyGeminiApiKey = 'gemini_api_key';
}
