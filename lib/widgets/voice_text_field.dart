import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndu_project/services/voice_input_service.dart';

/// A drop-in replacement for [TextField] that adds a microphone button
/// for voice-to-text input.
///
/// The mic icon appears as a suffixIcon inside the text field's decoration.
/// When tapped, it requests microphone permission and starts listening.
/// Recognized speech is appended to the field's text.
///
/// Set [enableVoice] to false to hide the mic button (defaults to true).
class VoiceTextField extends StatefulWidget {
  const VoiceTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.readOnly = false,
    this.showCursor,
    this.autofocus = false,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20),
    this.enableInteractiveSelection = true,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints = const [],
    this.enableVoice = true,
    this.voiceIconColor,
    this.onTapOutside,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;
  final bool readOnly;
  final bool? showCursor;
  final bool autofocus;
  final String obscuringCharacter;
  final bool obscureText;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String> autofillHints;

  /// Whether to show the voice input mic button. Defaults to true.
  final bool enableVoice;

  /// Color of the mic icon. Defaults to brand yellow if not specified.
  final Color? voiceIconColor;

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField> {
  late TextEditingController _controller;
  final VoiceInputService _voiceService = VoiceInputService.instance;
  StreamSubscription<VoiceResult>? _resultSubscription;
  StreamSubscription<VoiceStatus>? _statusSubscription;
  bool _isListening = false;
  bool _voiceAvailable = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _checkAvailability();
  }

  @override
  void didUpdateWidget(VoiceTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? TextEditingController();
    }
  }

  Future<void> _checkAvailability() async {
    final available = await _voiceService.initialize();
    if (mounted && available != _voiceAvailable) {
      setState(() => _voiceAvailable = available);
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _voiceService.stopListening();
      _cleanupSubscriptions();
      if (mounted) setState(() => _isListening = false);
    } else {
      final started = await _voiceService.startListening(
        existingText: _controller.text,
      );
      if (!started) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition is not available on this device.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      _resultSubscription = _voiceService.onResult.listen((result) {
        if (!mounted) return;
        final text = result.text;
        _controller.text = text;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        widget.onChanged?.call(text);

        if (result.isFinal) {
          if (mounted) setState(() => _isListening = false);
          _cleanupSubscriptions();
        }
      });

      _statusSubscription = _voiceService.onStatusChanged.listen((status) {
        if (status == VoiceStatus.stopped || status == VoiceStatus.error) {
          if (mounted) setState(() => _isListening = false);
          _cleanupSubscriptions();
        }
      });

      if (mounted) setState(() => _isListening = true);
    }
  }

  void _cleanupSubscriptions() {
    _resultSubscription?.cancel();
    _resultSubscription = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
  }

  @override
  void dispose() {
    _cleanupSubscriptions();
    // Only dispose the controller if we created it
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceEnabled = widget.enableVoice && _voiceAvailable && !widget.obscureText;
    final effectiveDecoration = _buildDecoration(voiceEnabled);

    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      decoration: effectiveDecoration,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      style: widget.style,
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      textDirection: widget.textDirection,
      readOnly: widget.readOnly,
      showCursor: widget.showCursor,
      autofocus: widget.autofocus,
      obscuringCharacter: widget.obscuringCharacter,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      onTapOutside: widget.onTapOutside,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorColor: widget.cursorColor,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      scrollController: widget.scrollController,
      scrollPhysics: widget.scrollPhysics,
      autofillHints: widget.autofillHints,
    );
  }

  InputDecoration _buildDecoration(bool voiceEnabled) {
    final base = widget.decoration ?? const InputDecoration();
    final micIcon = _buildMicIcon();

    if (!voiceEnabled) return base;

    // Merge the mic icon with any existing suffixIcon
    final existingSuffix = base.suffixIcon;
    Widget suffixWidget;

    if (existingSuffix != null) {
      suffixWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          existingSuffix,
          micIcon,
        ],
      );
    } else {
      suffixWidget = micIcon;
    }

    return base.copyWith(suffixIcon: suffixWidget);
  }

  Widget _buildMicIcon() {
    final iconColor = widget.voiceIconColor ?? const Color(0xFFFFB800);

    if (_isListening) {
      return Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            Icons.mic,
            color: iconColor,
            size: 18,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: _toggleVoiceInput,
          tooltip: 'Stop voice input',
        ),
      );
    }

    return IconButton(
      icon: Icon(
        Icons.mic_none_outlined,
        color: iconColor,
        size: 18,
      ),
      padding: const EdgeInsets.only(right: 4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: _toggleVoiceInput,
      tooltip: 'Voice input',
    );
  }
}

/// A drop-in replacement for [TextFormField] that adds a microphone button
/// for voice-to-text input.
///
/// Identical API surface to TextFormField with an additional [enableVoice] param.
class VoiceTextFormField extends StatefulWidget {
  const VoiceTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.readOnly = false,
    this.showCursor,
    this.autofocus = false,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLengthEnforcement,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.onTapOutside,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onSaved,
    this.validator,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20),
    this.enableInteractiveSelection = true,
    this.selectionControls,
    this.buildCounter,
    this.scrollPhysics,
    this.autofillHints = const [],
    this.autovalidateMode,
    this.scrollController,
    this.restorationId,
    this.enableVoice = true,
    this.voiceIconColor,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;
  final bool readOnly;
  final bool? showCursor;
  final bool autofocus;
  final String obscuringCharacter;
  final bool obscureText;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final InputCounterWidgetBuilder? buildCounter;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String> autofillHints;
  final AutovalidateMode? autovalidateMode;
  final ScrollController? scrollController;
  final String? restorationId;

  /// Whether to show the voice input mic button. Defaults to true.
  final bool enableVoice;

  /// Color of the mic icon. Defaults to brand yellow if not specified.
  final Color? voiceIconColor;

  @override
  State<VoiceTextFormField> createState() => _VoiceTextFormFieldState();
}

class _VoiceTextFormFieldState extends State<VoiceTextFormField> {
  late TextEditingController _controller;
  final VoiceInputService _voiceService = VoiceInputService.instance;
  StreamSubscription<VoiceResult>? _resultSubscription;
  StreamSubscription<VoiceStatus>? _statusSubscription;
  bool _isListening = false;
  bool _voiceAvailable = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _checkAvailability();
  }

  @override
  void didUpdateWidget(VoiceTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    }
  }

  Future<void> _checkAvailability() async {
    final available = await _voiceService.initialize();
    if (mounted && available != _voiceAvailable) {
      setState(() => _voiceAvailable = available);
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _voiceService.stopListening();
      _cleanupSubscriptions();
      if (mounted) setState(() => _isListening = false);
    } else {
      final started = await _voiceService.startListening(
        existingText: _controller.text,
      );
      if (!started) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition is not available on this device.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      _resultSubscription = _voiceService.onResult.listen((result) {
        if (!mounted) return;
        final text = result.text;
        _controller.text = text;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        widget.onChanged?.call(text);

        if (result.isFinal) {
          if (mounted) setState(() => _isListening = false);
          _cleanupSubscriptions();
        }
      });

      _statusSubscription = _voiceService.onStatusChanged.listen((status) {
        if (status == VoiceStatus.stopped || status == VoiceStatus.error) {
          if (mounted) setState(() => _isListening = false);
          _cleanupSubscriptions();
        }
      });

      if (mounted) setState(() => _isListening = true);
    }
  }

  void _cleanupSubscriptions() {
    _resultSubscription?.cancel();
    _resultSubscription = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
  }

  @override
  void dispose() {
    _cleanupSubscriptions();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceEnabled = widget.enableVoice && _voiceAvailable && !widget.obscureText;
    final effectiveDecoration = _buildDecoration(voiceEnabled);

    return TextFormField(
      controller: _controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      focusNode: widget.focusNode,
      decoration: effectiveDecoration,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,
      style: widget.style,
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      textDirection: widget.textDirection,
      readOnly: widget.readOnly,
      showCursor: widget.showCursor,
      autofocus: widget.autofocus,
      obscuringCharacter: widget.obscuringCharacter,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      onTapOutside: widget.onTapOutside,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
      onSaved: widget.onSaved,
      validator: widget.validator,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorColor: widget.cursorColor,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      selectionControls: widget.selectionControls,
      buildCounter: widget.buildCounter,
      scrollPhysics: widget.scrollPhysics,
      autofillHints: widget.autofillHints,
      autovalidateMode: widget.autovalidateMode,
      scrollController: widget.scrollController,
      restorationId: widget.restorationId,
    );
  }

  InputDecoration _buildDecoration(bool voiceEnabled) {
    final base = widget.decoration ?? const InputDecoration();
    final micIcon = _buildMicIcon();

    if (!voiceEnabled) return base;

    final existingSuffix = base.suffixIcon;
    Widget suffixWidget;

    if (existingSuffix != null) {
      suffixWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          existingSuffix,
          micIcon,
        ],
      );
    } else {
      suffixWidget = micIcon;
    }

    return base.copyWith(suffixIcon: suffixWidget);
  }

  Widget _buildMicIcon() {
    final iconColor = widget.voiceIconColor ?? const Color(0xFFFFB800);

    if (_isListening) {
      return Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            Icons.mic,
            color: iconColor,
            size: 18,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: _toggleVoiceInput,
          tooltip: 'Stop voice input',
        ),
      );
    }

    return IconButton(
      icon: Icon(
        Icons.mic_none_outlined,
        color: iconColor,
        size: 18,
      ),
      padding: const EdgeInsets.only(right: 4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: _toggleVoiceInput,
      tooltip: 'Voice input',
    );
  }
}
