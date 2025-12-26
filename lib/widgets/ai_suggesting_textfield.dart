import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ndu_project/openai/openai_config.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

/// Debouncer utility to limit API calls while typing
class _Debouncer {
  _Debouncer();
  final Duration delay;
  Timer? _timer;
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
  void dispose() => _timer?.cancel();
}

/// A text field with inline OpenAI-powered suggestions
/// - Shows suggestion chips beneath the field
/// - Suggestions are based on current text and prior project context
class AiSuggestingTextField extends StatefulWidget {
  const AiSuggestingTextField({
    super.key,
    required this.fieldLabel,
    required this.hintText,
    required this.sectionLabel,
    this.onChanged,
    this.initialText,
  });

  final String fieldLabel;
  final String hintText;
  final String sectionLabel;
  final ValueChanged<String>? onChanged;
  final String? initialText;

  @override
  State<AiSuggestingTextField> createState() => _AiSuggestingTextFieldState();
}

class _AiSuggestingTextFieldState extends State<AiSuggestingTextField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _debouncer = _Debouncer();
  List<String> _suggestions = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if ((widget.initialText ?? '').isNotEmpty) {
      _controller.text = widget.initialText!;
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);
    _debouncer.run(() async {
      await _fetchSuggestions();
    });
  }

  Future<void> _fetchSuggestions() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _suggestions = const [];
        _error = null;
      });
      return;
    }

    final contextText = ProjectDataHelper.buildFepContext(
      ProjectDataHelper.getData(context),
      sectionLabel: widget.sectionLabel,
    );

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await OpenAiAutocompleteService.instance.fetchSuggestions(
        fieldName: widget.fieldLabel,
        currentText: text,
        context: contextText,
        maxSuggestions: 4,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Check if OpenAI is configured
        if (!OpenAiConfig.isConfigured) {
          _error = 'OpenAI API key not configured. Please add your API key to enable AI suggestions.';
        } else {
          final warn = OpenAiConfig.configurationWarning();
          _error = warn ?? e.toString();
        }
        _loading = false;
      });
    }
  }

  void _applySuggestion(String suggestion) {
    final current = _controller.text.trimRight();
    final needsSpace = current.isNotEmpty && !current.endsWith('\n') && !current.endsWith(' ');
    final next = current + (needsSpace ? ' ' : '') + suggestion;
    _controller.text = next;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.fieldLabel,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 14),
        Stack(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 12,
              minLines: 8,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.6),
                ),
                suffixIcon: IconButton(
                  tooltip: 'AI suggest',
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B)),
                  onPressed: _loading ? null : _fetchSuggestions,
                ),
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827), height: 1.5),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if ((_error ?? '').isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB91C1C)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        if (_suggestions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((s) => ActionChip(
                      backgroundColor: const Color(0xFFE1EEFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      label: Text(
                        s,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                      ),
                      avatar: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF1F2937)),
                      onPressed: () => _applySuggestion(s),
                    ))
                .toList(),
          ),
      ],
    );
  }
}
