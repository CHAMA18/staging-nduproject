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
  // Using o3 — the highest-performance model available (May 2026).
  // o3 supports Chat Completions API and reasoning capabilities.
  // Note: o3 only supports temperature=1 (default); non-default values
  // cause a 400 error. The wrapBody() helper strips temperature for
  // reasoning models automatically.
  static const String model = 'o3';

  /// Whether the current model is an OpenAI reasoning model (o1, o3, o4, etc.)
  /// Reasoning models only support temperature=1 (default) and the wrapBody()
  /// helper strips non-default temperature values automatically.
  static bool get isReasoningModel =>
      model.startsWith('o1') || model.startsWith('o3') || model.startsWith('o4');

  /// Returns model parameters for API requests.
  /// The Chat Completions API now requires `max_completion_tokens` for
  /// reasoning models (o3, o4). The legacy `max_tokens` parameter causes
  /// a 400 error, so we always use `max_completion_tokens`.
  static Map<String, dynamic> modelParams({int? maxTokens, double? temperature}) {
    final params = <String, dynamic>{
      'model': model,
    };
    if (maxTokens != null) {
      // All models use max_completion_tokens (required for o3/o4 reasoning models)
      params['max_completion_tokens'] = maxTokens;
    }
    // Reasoning models (o3, o4) only support temperature=1; omit it for them.
    // The wrapBody() helper handles this automatically, but we avoid adding
    // it here for reasoning models to keep the params clean.
    if (temperature != null && !isReasoningModel) params['temperature'] = temperature;
    return params;
  }

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
