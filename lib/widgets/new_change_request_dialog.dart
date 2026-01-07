import 'package:ndu_project/widgets/expanding_text_field.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/change_request_service.dart';

class NewChangeRequestDialog extends StatefulWidget {
  const NewChangeRequestDialog({super.key, this.changeRequest, this.onSaved});

  final ChangeRequest? changeRequest;
  final VoidCallback? onSaved;

  @override
  State<NewChangeRequestDialog> createState() => _NewChangeRequestDialogState();
}

class _NewChangeRequestDialogState extends State<NewChangeRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  // Controllers
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _justificationCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _requesterCtrl = TextEditingController(text: FirebaseAuthService.displayNameOrEmail(fallback: ''));

  // Dropdown states
  final List<String> _types = const ['Requirement', 'Scope', 'Design', 'Schedule', 'Cost', 'Quality', 'Other'];
  String? _selectedType;

  final List<String> _impacts = const ['High', 'Medium', 'Low'];
  String? _selectedImpact;

  final List<String> _statuses = const ['Pending', 'Approved', 'Rejected'];
  String _selectedStatus = 'Pending';

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final initial = widget.changeRequest;
    if (initial != null) {
      _titleCtrl.text = initial.title;
      _descriptionCtrl.text = initial.description ?? '';
      _justificationCtrl.text = initial.justification ?? '';
      _selectedType = initial.type.isEmpty ? null : initial.type;
      _selectedImpact = initial.impact.isEmpty ? null : initial.impact;
      _selectedStatus = initial.status;
      _requesterCtrl.text = initial.requester;
      _selectedDate = initial.requestDate;
      _dateCtrl.text = _formatDate(initial.requestDate);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _justificationCtrl.dispose();
    _dateCtrl.dispose();
    _requesterCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: _selectedDate ?? now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.change_circle_outlined, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Change request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('Submit details to start the change management process.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _grid(
                      children: [
                        _textField('Title', controller: _titleCtrl, hint: 'e.g. Update payment gateway'),
                        _dropdownField('Type', value: _selectedType, items: _types, onChanged: (v) => setState(() => _selectedType = v)),
                        _dropdownField('Impact', value: _selectedImpact, items: _impacts, onChanged: (v) => setState(() => _selectedImpact = v)),
                        _dropdownField('Status', value: _selectedStatus, items: _statuses, onChanged: (v) => setState(() => _selectedStatus = v ?? 'Pending')),
                        _dateField('Request date', controller: _dateCtrl, onTap: _pickDate),
                        _textField('Requester', controller: _requesterCtrl, hint: 'Your name'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _textField('Description', controller: _descriptionCtrl, maxLines: 4, hint: 'Describe the change and affected scope'),
                    const SizedBox(height: 12),
                    _textField('Justification / Reason', controller: _justificationCtrl, maxLines: 3, hint: 'Why is this change needed?'),
                    const SizedBox(height: 12),

                    // Attachments placeholder area (UI only)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, size: 18, color: Colors.black54),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Attachments (optional)', style: TextStyle(fontSize: 13, color: Colors.black87)),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              // Placeholder: integrate file_picker in future if needed.
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Attachment picker coming soon')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              side: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Add file'),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _submitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Create request', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) return;
    setState(() => _submitting = true);
    try {
      if (widget.changeRequest != null) {
        final updated = ChangeRequest(
          id: widget.changeRequest!.id,
          displayId: widget.changeRequest!.displayId,
          title: _titleCtrl.text.trim(),
          type: _selectedType!,
          impact: _selectedImpact!,
          status: _selectedStatus,
          requester: _requesterCtrl.text.trim(),
          description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
          justification: _justificationCtrl.text.trim().isEmpty ? null : _justificationCtrl.text.trim(),
          requestDate: _selectedDate!,
          createdAt: widget.changeRequest!.createdAt,
        );
        await ChangeRequestService.updateChangeRequest(updated);
      } else {
        await ChangeRequestService.createChangeRequest(
          title: _titleCtrl.text.trim(),
          type: _selectedType!,
          impact: _selectedImpact!,
          status: _selectedStatus,
          requester: _requesterCtrl.text.trim(),
          requestDate: _selectedDate!,
          description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
          justification: _justificationCtrl.text.trim().isEmpty ? null : _justificationCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
      widget.onSaved?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.changeRequest != null ? 'Failed to update request: $e' : 'Failed to create request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Layout helpers
  Widget _grid({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(children: [children[0], const SizedBox(height: 12), children[2], const SizedBox(height: 12), children[4]])),
              const SizedBox(width: 12),
              Expanded(child: Column(children: [children[1], const SizedBox(height: 12), children[3], const SizedBox(height: 12), children[5]])),
            ],
          );
        }
        return Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 12), children[i]]
          ],
        );
      },
    );
  }

  InputDecoration _decoration(String label, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.35))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.35))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.6)),
      suffixIcon: suffixIcon,
    );
  }

  Widget _textField(String label, {required TextEditingController controller, String? hint, int maxLines = 1}) {
    final isMultiline = maxLines != 1;
    if (isMultiline) {
      return ExpandingTextFormField(
        controller: controller,
        minLines: maxLines,
        decoration: _decoration(label, hint: hint),
        validator: (v) {
          if (label == 'Description' || label == 'Justification / Reason') return null; // optional
          if (v == null || v.trim().isEmpty) return 'Required';
          return null;
        },
      );
    }
    return TextFormField(
      controller: controller,
      validator: (v) {
        if (label == 'Description' || label == 'Justification / Reason') return null; // optional
        if (v == null || v.trim().isEmpty) return 'Required';
        return null;
      },
      decoration: _decoration(label, hint: hint),
    );
  }

  Widget _dateField(String label, {required TextEditingController controller, required VoidCallback onTap}) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      onTap: onTap,
      decoration: _decoration(label, hint: 'YYYY-MM-DD', suffixIcon: const Icon(Icons.calendar_today_outlined)),
    );
  }

  Widget _dropdownField(String label, {required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      decoration: _decoration(label),
    );
  }
}
