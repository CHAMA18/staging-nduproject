import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Singleton service that manages speech-to-text recognition across the app.
///
/// Usage:
///   final voice = VoiceInputService.instance;
///   if (await voice.startListening()) { ... }
///   voice.stopListening();
///   voice.currentText; // live transcript
class VoiceInputService {
  VoiceInputService._();
  static final VoiceInputService instance = VoiceInputService._();

  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  bool _isAvailable = false;
  bool _isListening = false;
  String _currentText = '';
  String _previousText = '';

  /// Stream of live transcription results
  final StreamController<VoiceResult> _resultController =
      StreamController<VoiceResult>.broadcast();

  /// Stream of status changes
  final StreamController<VoiceStatus> _statusController =
      StreamController<VoiceStatus>.broadcast();

  // --- Getters ---

  /// Whether speech recognition is available on this device
  bool get isAvailable => _isAvailable;

  /// Whether currently listening/recording
  bool get isListening => _isListening;

  /// Current live transcript text (cumulative for this session)
  String get currentText => _currentText;

  /// The text that was in the field before voice input started
  String get previousText => _previousText;

  /// Stream of voice recognition results
  Stream<VoiceResult> get onResult => _resultController.stream;

  /// Stream of voice status changes
  Stream<VoiceStatus> get onStatusChanged => _statusController.stream;

  // --- Initialization ---

  /// Initialize the speech recognition engine.
  /// Returns true if available on this device.
  Future<bool> initialize() async {
    if (_initialized) return _isAvailable;

    try {
      _isAvailable = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: false,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('[VoiceInputService] Initialization failed: $e');
      _isAvailable = false;
      _initialized = true;
    }
    return _isAvailable;
  }

  // --- Listening ---

  /// Start listening for speech input.
  /// Returns true if listening started successfully.
  ///
  /// [existingText] - text already in the field (will be prepended to result)
  /// [localeId] - language locale, e.g. 'en_US', defaults to system
  /// [listenMode] - dictation mode for continuous recognition
  Future<bool> startListening({
    String existingText = '',
    String? localeId,
    ListenMode listenMode = ListenMode.dictation,
  }) async {
    if (_isListening) return true;

    if (!_initialized) {
      await initialize();
    }

    if (!_isAvailable) {
      debugPrint('[VoiceInputService] Speech recognition not available');
      return false;
    }

    _previousText = existingText;
    _currentText = '';
    _isListening = true;
    _statusController.add(VoiceStatus.listening);

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        localeId: localeId,
        listenMode: listenMode,
        partialResults: true,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[VoiceInputService] Failed to start listening: $e');
      _isListening = false;
      _statusController.add(VoiceStatus.stopped);
      return false;
    }

    return true;
  }

  /// Stop listening and return final text
  Future<String> stopListening() async {
    if (!_isListening) return _currentText;

    _speech.stop();
    _isListening = false;
    _statusController.add(VoiceStatus.stopped);

    final fullText = _buildFullText();
    _resultController.add(VoiceResult(
      text: fullText,
      isFinal: true,
    ));
    return fullText;
  }

  /// Cancel listening without returning results
  Future<void> cancelListening() async {
    if (!_isListening) return;

    _speech.cancel();
    _isListening = false;
    _currentText = '';
    _statusController.add(VoiceStatus.stopped);
  }

  // --- Internal handlers ---

  void _onSpeechResult(SpeechRecognitionResult result) {
    _currentText = result.recognizedWords;

    final fullText = _buildFullText();
    _resultController.add(VoiceResult(
      text: fullText,
      isFinal: result.finalResult,
    ));
  }

  String _buildFullText() {
    if (_previousText.isEmpty) return _currentText;
    if (_currentText.isEmpty) return _previousText;

    // Add a space between existing text and new voice text
    final separator = _previousText.endsWith(' ') || _previousText.endsWith('\n')
        ? ''
        : ' ';
    return '$_previousText$separator$_currentText';
  }

  void _onError(SpeechRecognitionError error) {
    debugPrint('[VoiceInputService] Error: ${error.errorMsg} (permanent: ${error.permanent})');
    if (error.permanent) {
      _isListening = false;
      _statusController.add(VoiceStatus.error);
    }
  }

  void _onStatus(String status) {
    debugPrint('[VoiceInputService] Status: $status');
    switch (status) {
      case 'listening':
        _isListening = true;
        _statusController.add(VoiceStatus.listening);
        break;
      case 'notListening':
        _isListening = false;
        _statusController.add(VoiceStatus.stopped);
        break;
      case 'done':
        _isListening = false;
        _statusController.add(VoiceStatus.stopped);
        break;
    }
  }

  // --- Cleanup ---

  void dispose() {
    _resultController.close();
    _statusController.close();
  }
}

/// Result of a voice recognition session
class VoiceResult {
  final String text;
  final bool isFinal;

  const VoiceResult({required this.text, required this.isFinal});
}

/// Status of the voice input service
enum VoiceStatus {
  listening,
  stopped,
  error,
}
