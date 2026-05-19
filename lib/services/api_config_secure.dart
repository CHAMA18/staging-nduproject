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
  static const String model = 'gpt-5.4';

  // Reasoning effort level for gpt-5.4 model.
  // 'high' enables deep chain-of-thought reasoning for more accurate,
  // thorough, and well-structured project management content.
  static const String reasoningEffort = 'high';

  /// Returns model parameters including reasoning configuration for gpt-5.4.
  /// Callers should merge this into their request body map, e.g.:
  ///   final body = {...SecureAPIConfig.modelParams(), 'messages': [...], ...};
  static Map<String, dynamic> modelParams({int? maxTokens, double? temperature}) {
    final params = <String, dynamic>{
      'model': model,
      'reasoning': {'effort': reasoningEffort},
    };
    if (maxTokens != null) params['max_tokens'] = maxTokens;
    if (temperature != null) params['temperature'] = temperature;
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
