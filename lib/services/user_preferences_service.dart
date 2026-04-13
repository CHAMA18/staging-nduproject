import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences and first-time user detection
class UserPreferencesService {
  static const String _firstTimeKey = 'first_time_user';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _skipStepConfirmationKey = 'skip_step_confirmation';
  static Future<SharedPreferences>? _prefsFuture;

  static Future<SharedPreferences> _prefs() {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  /// Warm up shared preferences early to reduce first-read latency.
  static Future<void> warmUp() async {
    await _prefs();
  }

  /// Check if this is the first time the user is opening the app
  static Future<bool> isFirstTimeUser() async {
    final prefs = await _prefs();
    return prefs.getBool(_firstTimeKey) ?? true;
  }

  /// Mark that the user has completed onboarding
  static Future<void> markOnboardingComplete() async {
    final prefs = await _prefs();
    await prefs.setBool(_firstTimeKey, false);
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  /// Check if the user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await _prefs();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Reset first-time user status (useful for testing)
  static Future<void> resetFirstTimeUser() async {
    final prefs = await _prefs();
    await prefs.remove(_firstTimeKey);
    await prefs.remove(_onboardingCompleteKey);
  }

  /// Whether step-by-step confirmation prompts should be skipped.
  static Future<bool> shouldSkipStepConfirmation() async {
    final prefs = await _prefs();
    return prefs.getBool(_skipStepConfirmationKey) ?? false;
  }

  /// Persist step confirmation preference.
  static Future<void> setSkipStepConfirmation(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_skipStepConfirmationKey, value);
  }

  /// Reset confirmation preference to default behavior (show prompts).
  static Future<void> resetStepConfirmationPreference() async {
    final prefs = await _prefs();
    await prefs.remove(_skipStepConfirmationKey);
  }
}
