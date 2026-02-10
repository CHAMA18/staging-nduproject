import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences and first-time user detection
class UserPreferencesService {
  static const String _firstTimeKey = 'first_time_user';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  /// Check if this is the first time the user is opening the app
  static Future<bool> isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstTimeKey) ?? true;
  }

  /// Mark that the user has completed onboarding
  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstTimeKey, false);
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  /// Check if the user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Reset first-time user status (useful for testing)
  static Future<void> resetFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstTimeKey);
    await prefs.remove(_onboardingCompleteKey);
  }
}
