import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

class PlanningAiNotesCard extends StatefulWidget {
  const PlanningAiNotesCard({
    super.key,
    required this.title,
    required this.sectionLabel,
    required this.noteKey,
    required this.checkpoint,
    this.description,
    this.hintText = 'Capture the key decisions and details for this section...',
    this.autoGenerateMaxTokens = 900,
    this.autoGenerateTemperature = 0.5,
  });

  final String title;
  final String sectionLabel;
  final String noteKey;
  final String checkpoint;
  final String? description;
  final String hintText;
  final int autoGenerateMaxTokens;
  final double autoGenerateTemperature;

  @override
  State<PlanningAiNotesCard> createState() => _PlanningAiNotesCardState();
}

class _PlanningAiNotesCardState extends State<PlanningAiNotesCard> {
  final _saveDebounce = _Debouncer();
  String _currentText = '';
  late TextEditingController _controller;
  bool _didInit = false;
  bool _saving = false;
  DateTime? _lastSavedAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    final data = ProjectDataHelper.getData(context);
    _currentText = data.planningNotes[widget.noteKey] ?? '';
  _controller = TextEditingController(text: _currentText);
    _didInit = true;
  }

  @override
  void dispose() {
    _saveDebounce.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final trimmed = value.trim();
    _currentText = trimmed;
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        planningNotes: {
          ...data.planningNotes,
          widget.noteKey: trimmed,
        },
      ),
    );
  // Keep controller in sync
  if (_controller.text != value) _controller.text = value;
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveDebounce.run(() async {
      if (!mounted) return;
      await _saveNow();
    });
  }

  Future<void> _saveNow() async {
    if (_saving) return;
    setState(() => _saving = true);
    final success = await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: widget.checkpoint,
      showSnackbar: false,
      dataUpdater: (data) => data.copyWith(
        planningNotes: {
          ...data.planningNotes,
          widget.noteKey: _currentText.trim(),
        },
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (success) {
        _lastSavedAt = DateTime.now();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedAt = _lastSavedAt;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4CC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B), size: 18),
              ),
              const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Notes',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                ),
              if (_saving)
                _StatusChip(label: 'Saving...', color: const Color(0xFF64748B))
              else if (savedAt != null)
                _StatusChip(
                  label: 'Saved ${TimeOfDay.fromDateTime(savedAt).format(context)}',
                  color: const Color(0xFF16A34A),
                  background: const Color(0xFFECFDF3),
                ),
            ],
          ),
          if ((widget.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.description!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: _handleChanged,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color, this.background});

  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _Debouncer {
  _Debouncer({Duration? delay}) : delay = delay ?? const Duration(milliseconds: 700);

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
