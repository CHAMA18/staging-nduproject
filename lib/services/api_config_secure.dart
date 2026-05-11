import 'package:flutter/foundation.dart';

/// Runtime OpenAI configuration that avoids hardcoding secrets in source.
/// ApiKeyManager sets and clears the key at runtime; callers read via [apiKey].
class SecureAPIConfig {
  SecureAPIConfig._();

  static String? _apiKey;

  // Cloud Function proxy endpoint (keeps the API key server-side).
  static const String baseUrl =
      'https://us-central1-ndu-d3f60.cloudfunctions.net/openaiProxy';

  // Default model used across OpenAI requests.
  static const String model = 'gpt-4o-mini';

  // Default OpenAI Agent Builder workflow used by the Firebase OpenAI proxy.
  static const String workflowId =
      'wf_69f1f5acc7ec819082fb76bbbf79b64d088ea0e514080150';

  static String? get apiKey => _apiKey;
  static bool get hasApiKey => _apiKey?.trim().isNotEmpty == true;

  static void setApiKey(String apiKey) {
    _apiKey = apiKey.trim().isEmpty ? null : apiKey.trim();
    debugPrint('SecureAPIConfig: runtime API key set.');
  }

  static void clearApiKey() {
    _apiKey = null;
    debugPrint('SecureAPIConfig: runtime API key cleared.');
  }
}
