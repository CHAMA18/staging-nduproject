import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/procurement/procurement_models.dart';
import 'package:ndu_project/models/procurement/procurement_ui_extensions.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/services/vendor_service.dart';

class ProcurementDialogShell extends StatelessWidget {
  const ProcurementDialogShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.contextChips,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> contextChips;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: 720, maxHeight: media.size.height * 0.88),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1F0F172A),
                blurRadius: 30,
                offset: Offset(0, 18)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8FAFF), Color(0xFFEFF6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE).withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x140F172A),
                                blurRadius: 10,
                                offset: Offset(0, 6)),
                          ],
                        ),
                        child: Icon(icon, color: const Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF475569)),
                            ),
                            if (contextChips.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: contextChips,
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onSecondary,
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: child,
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                children: [
                  const Text(
                    'Saved to this workspace only.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onPrimary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(primaryLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DialogSectionTitle extends StatelessWidget {
  const DialogSectionTitle({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class ContextChip extends StatelessWidget {
  const ContextChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

class AddItemDialog extends StatefulWidget {
  const AddItemDialog({
    super.key,
    required this.contextChips,
    required this.categoryOptions,
  });

  final List<Widget> contextChips;
  final List<String> categoryOptions;

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _budgetCtrl;

  late String _category;
  ProcurementItemStatus _status = ProcurementItemStatus.planning;
  ProcurementPriority _priority = ProcurementPriority.medium;
  DateTime? _deliveryDate;
  bool _showDateError = false;
  bool _isGenerating = false;

  final FocusNode _nameFocus = FocusNode();
  late final OpenAiServiceSecure _openAi;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _budgetCtrl = TextEditingController();
    _category = widget.categoryOptions.first;
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  int _parseCurrency(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  String _formatDisplayDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  Future<void> _generateWithAI() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      final projectData = ProjectDataHelper.getData(context);
      final projectName = projectData.projectName.trim().isEmpty
          ? 'Project'
          : projectData.projectName.trim();
      final solutionTitle = projectData.solutionTitle.trim().isEmpty
          ? 'Solution'
          : projectData.solutionTitle.trim();
      final notes = projectData.frontEndPlanning.procurement.trim();

      final result = await _openAi.generateProcurementItemSuggestion(
        projectName: projectName,
        solutionTitle: solutionTitle,
        category: _category,
        contextNotes: notes,
      );

      if (mounted) {
        final deliveryDays = result['estimatedDeliveryDays'] as int? ?? 90;
        final deliveryDate = DateTime.now().add(Duration(days: deliveryDays));

        ProcurementPriority priority;
        final priorityStr = result['priority'] as String? ?? 'medium';
        switch (priorityStr.toLowerCase()) {
          case 'critical':
            priority = ProcurementPriority.critical;
            break;
          case 'high':
            priority = ProcurementPriority.high;
            break;
          case 'low':
            priority = ProcurementPriority.low;
            break;
          default:
            priority = ProcurementPriority.medium;
        }

        setState(() {
          _nameCtrl.text = result['name'] ?? '';
          _descCtrl.text = result['description'] ?? '';
          _category = result['category'] ?? _category;
          _budgetCtrl.text = (result['budget'] as int? ?? 50000).toString();
          _priority = priority;
          _deliveryDate = deliveryDate;
          _showDateError = false;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate item: ${e.toString()}')),
        );
      }
    }
  }

  InputDecoration _dialogDecoration(
      {required String label,
      String? hint,
      Widget? prefixIcon,
      String? helperText,
      String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProcurementDialogShell(
      title: 'Add Procurement Item',
      subtitle: 'Capture scope, budget, and delivery timing.',
      icon: Icons.inventory_2_outlined,
      contextChips: widget.contextChips,
      primaryLabel: 'Add Item',
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.of(context).pop(),
      onPrimary: () {
        final valid = _formKey.currentState?.validate() ?? false;
        if (!valid) return;
        if (_deliveryDate == null) {
          setState(() => _showDateError = true);
          return;
        }
        final projectId =
            ProjectDataHelper.getData(context).projectId ?? 'project-1';
        final budget = _parseCurrency(_budgetCtrl.text);
        final item = ProcurementItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          projectId: projectId,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _category,
          status: _status,
          priority: _priority,
          budget: budget.toDouble(),
          spent: 0.0,
          estimatedDelivery: _deliveryDate,
          progress: 0,
          events: [],
          notes: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        Navigator.of(context).pop(item);
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: DialogSectionTitle(
                    title: 'Item details',
                    subtitle: 'What are you sourcing for this project?',
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isGenerating ? null : _generateWithAI,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Generate with AI'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              decoration: _dialogDecoration(
                  label: 'Item name', hint: 'e.g. Network core switches'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Item name is required.'
                  : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: _dialogDecoration(
                  label: 'Description', hint: 'Short scope description'),
            ),
            const SizedBox(height: 18),
            const DialogSectionTitle(
              title: 'Classification',
              subtitle: 'Align the item with sourcing workflow.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: _dialogDecoration(label: 'Category'),
                    items: widget.categoryOptions
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _category = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<ProcurementItemStatus>(
                    initialValue: _status,
                    decoration: _dialogDecoration(label: 'Status'),
                    items: ProcurementItemStatus.values
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _status = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProcurementPriority>(
              initialValue: _priority,
              decoration: _dialogDecoration(label: 'Priority'),
              items: ProcurementPriority.values
                  .map((option) => DropdownMenuItem(
                      value: option, child: Text(option.label)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 18),
            const DialogSectionTitle(
              title: 'Budget and timing',
              subtitle: 'Estimate cost and delivery window.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogDecoration(
                        label: 'Budget',
                        hint: 'e.g. 85000',
                        prefixIcon: const Icon(Icons.attach_money)),
                    validator: (value) {
                      final amount = _parseCurrency(value ?? '');
                      return amount <= 0 ? 'Enter a budget amount.' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _deliveryDate ??
                            DateTime.now().add(const Duration(days: 14)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(DateTime.now().year + 5),
                      );
                      if (picked == null) return;
                      setState(() {
                        _deliveryDate = picked;
                        _showDateError = false;
                      });
                    },
                    child: InputDecorator(
                      decoration: _dialogDecoration(
                        label: 'Est. delivery',
                        hint: 'Select date',
                        prefixIcon: const Icon(Icons.event),
                        errorText: _showDateError ? 'Select a date.' : null,
                      ),
                      child: Text(
                        _deliveryDate == null
                            ? 'Select date'
                            : _formatDisplayDate(_deliveryDate!),
                        style: TextStyle(
                          color: _deliveryDate == null
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddVendorDialog extends StatefulWidget {
  const AddVendorDialog({
    super.key,
    required this.contextChips,
    required this.categoryOptions,
    this.initialVendor,
  });

  final List<Widget> contextChips;
  final List<String> categoryOptions;
  final VendorModel? initialVendor;

  @override
  State<AddVendorDialog> createState() => _AddVendorDialogState();
}

class _AddVendorDialogState extends State<AddVendorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late String _category;
  double _rating = 4;
  bool _approved = true;
  bool _preferred = false;
  bool _isGenerating = false;

  final FocusNode _nameFocus = FocusNode();
  late final OpenAiServiceSecure _openAi;
  bool get _isEditing => widget.initialVendor != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.initialVendor?.name ?? '');
    _category = widget.initialVendor?.category ??
        widget.categoryOptions.first;
    _rating = _ratingFromLetter(widget.initialVendor?.rating ?? 'B');
    final status = widget.initialVendor?.status.toLowerCase() ?? 'active';
    _approved = status == 'active' || status == 'approved';
    final criticality =
        widget.initialVendor?.criticality.toLowerCase() ?? 'medium';
    _preferred = criticality == 'high';
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  String _deriveInitials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'NA';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  double _ratingFromLetter(String rating) {
    final raw = rating.trim().toUpperCase();
    final parsed = int.tryParse(raw);
    if (parsed != null) return parsed.toDouble().clamp(1, 5);
    switch (raw) {
      case 'A':
        return 5;
      case 'B':
        return 4;
      case 'C':
        return 3;
      case 'D':
        return 2;
      case 'E':
        return 1;
      default:
        return 4;
    }
  }

  String _ratingToLetter(double value) {
    final score = value.round().clamp(1, 5);
    switch (score) {
      case 5:
        return 'A';
      case 4:
        return 'B';
      case 3:
        return 'C';
      case 2:
        return 'D';
      default:
        return 'E';
    }
  }

  Future<void> _generateWithAI() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      final projectData = ProjectDataHelper.getData(context);
      final projectName = projectData.projectName.trim().isEmpty
          ? 'Project'
          : projectData.projectName.trim();
      final solutionTitle = projectData.solutionTitle.trim().isEmpty
          ? 'Solution'
          : projectData.solutionTitle.trim();
      final notes = projectData.frontEndPlanning.procurement.trim();

      final result = await _openAi.generateVendorSuggestion(
        projectName: projectName,
        solutionTitle: solutionTitle,
        category: _category,
        contextNotes: notes,
      );

      if (mounted) {
        setState(() {
          _nameCtrl.text = result['name'] ?? '';
          _category = result['category'] ?? _category;
          _rating = (result['rating'] as int? ?? 4).toDouble();
          _approved = result['approved'] as bool? ?? true;
          _preferred = result['preferred'] as bool? ?? false;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate vendor: ${e.toString()}')),
        );
      }
    }
  }

  InputDecoration _dialogDecoration(
      {required String label,
      String? hint,
      Widget? prefixIcon,
      String? helperText,
      String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = widget.categoryOptions.contains(_category)
        ? widget.categoryOptions
        : [_category, ...widget.categoryOptions];
    return ProcurementDialogShell(
      title: _isEditing ? 'Edit Vendor' : 'Add Vendor Partner',
      subtitle: _isEditing
          ? 'Update vendor details and qualification.'
          : 'Build your trusted supplier network.',
      icon: Icons.storefront_outlined,
      contextChips: widget.contextChips,
      primaryLabel: _isEditing ? 'Save Changes' : 'Add Vendor',
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.of(context).pop(),
      onPrimary: () {
        final valid = _formKey.currentState?.validate() ?? false;
        if (!valid) return;
        final name = _nameCtrl.text.trim();
        final projectId =
            ProjectDataHelper.getData(context).projectId ?? 'project-1';
        final vendorId = widget.initialVendor?.id ??
            'vendor_${DateTime.now().microsecondsSinceEpoch}';
        final status = _approved ? 'Active' : 'Watch';
        final criticality = _preferred ? 'High' : 'Medium';
        final nextReview = widget.initialVendor?.nextReview ??
            DateFormat('MMM d, yyyy')
                .format(DateTime.now().add(const Duration(days: 180)));
        final vendor = VendorModel(
          id: vendorId,
          projectId: projectId,
          name: name,
          category: _category,
          criticality: criticality,
          sla: widget.initialVendor?.sla ?? '98%',
          slaPerformance: widget.initialVendor?.slaPerformance ??
              (_rating / 5).clamp(0.0, 1.0),
          leadTime: widget.initialVendor?.leadTime ?? '14 Days',
          requiredDeliverables:
              widget.initialVendor?.requiredDeliverables ??
                  '• Quarterly review\n• SLA adherence',
          rating: _ratingToLetter(_rating),
          status: status,
          nextReview: nextReview,
          contractId: widget.initialVendor?.contractId,
          onTimeDelivery: widget.initialVendor?.onTimeDelivery ?? 0.95,
          incidentResponse: widget.initialVendor?.incidentResponse ?? 0.95,
          qualityScore: widget.initialVendor?.qualityScore ?? 0.95,
          costAdherence: widget.initialVendor?.costAdherence ?? 0.95,
          notes: widget.initialVendor?.notes,
          createdById: 'user',
          createdByEmail: 'user@email',
          createdByName: 'User',
          createdAt: widget.initialVendor?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        Navigator.of(context).pop(vendor);
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: DialogSectionTitle(
                    title: 'Vendor identity',
                    subtitle: 'Capture the partner name and sourcing category.',
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isGenerating ? null : _generateWithAI,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Generate with AI'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              decoration: _dialogDecoration(
                  label: 'Vendor name', hint: 'e.g. Atlas Tech Supply'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Vendor name is required.'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _dialogDecoration(label: 'Category'),
              items: categoryOptions
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _category = value);
              },
            ),
            const SizedBox(height: 18),
            const DialogSectionTitle(
              title: 'Qualification',
              subtitle: 'Define rating and approval status.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rating',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569))),
                      Slider(
                        value: _rating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _rating.round().toString(),
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (value) => setState(() => _rating = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: _approved,
                          activeThumbColor: const Color(0xFF2563EB),
                          onChanged: (value) =>
                              setState(() => _approved = value),
                        ),
                        const Text('Approved'),
                      ],
                    ),
                    Row(
                      children: [
                        Switch(
                          value: _preferred,
                          activeThumbColor: const Color(0xFF2563EB),
                          onChanged: (value) =>
                              setState(() => _preferred = value),
                        ),
                        const Text('Preferred'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreateRfqDialog extends StatefulWidget {
  const CreateRfqDialog({
    super.key,
    required this.contextChips,
    required this.categoryOptions,
  });

  final List<Widget> contextChips;
  final List<String> categoryOptions;

  @override
  State<CreateRfqDialog> createState() => _CreateRfqDialogState();
}

class _CreateRfqDialogState extends State<CreateRfqDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _budgetCtrl;
  late TextEditingController _invitedCtrl;
  late TextEditingController _responsesCtrl;

  late String _category;
  RfqStatus _status = RfqStatus.draft;
  ProcurementPriority _priority = ProcurementPriority.medium;
  DateTime? _dueDate;
  bool _showDateError = false;

  final FocusNode _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _ownerCtrl = TextEditingController();
    _budgetCtrl = TextEditingController();
    _invitedCtrl = TextEditingController(text: '0');
    _responsesCtrl = TextEditingController(text: '0');
    _category = widget.categoryOptions.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _ownerCtrl.dispose();
    _budgetCtrl.dispose();
    _invitedCtrl.dispose();
    _responsesCtrl.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  int _parseCurrency(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  String _formatDisplayDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  InputDecoration _dialogDecoration(
      {required String label,
      String? hint,
      Widget? prefixIcon,
      String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProcurementDialogShell(
      title: 'Create RFQ',
      subtitle: 'Kick off a request for quote with clear scope and timing.',
      icon: Icons.request_quote_outlined,
      contextChips: widget.contextChips,
      primaryLabel: 'Create RFQ',
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.of(context).pop(),
      onPrimary: () {
        final valid = _formKey.currentState?.validate() ?? false;
        if (!valid) return;
        if (_dueDate == null) {
          setState(() => _showDateError = true);
          return;
        }
        final budget = _parseCurrency(_budgetCtrl.text);
        final invited = int.tryParse(_invitedCtrl.text.trim()) ?? 0;
        final responses = int.tryParse(_responsesCtrl.text.trim()) ?? 0;
        final projectId =
            ProjectDataHelper.getData(context).projectId ?? 'project-1';
        final rfq = RfqModel(
          id: 'RFQ-${DateTime.now().millisecondsSinceEpoch % 10000}',
          title: _titleCtrl.text.trim(),
          projectId: projectId,
          category: _category,
          owner: _ownerCtrl.text.trim().isEmpty
              ? 'Unassigned'
              : _ownerCtrl.text.trim(),
          budget: budget.toDouble(),
          dueDate: _dueDate!,
          invitedCount: invited,
          responseCount: responses.clamp(0, invited).toInt(),
          status: _status,
          priority: _priority,
          createdAt: DateTime.now(),
        );
        Navigator.of(context).pop(rfq);
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DialogSectionTitle(
              title: 'RFQ overview',
              subtitle: 'Define the category and owner.',
            ),
            TextFormField(
              controller: _titleCtrl,
              focusNode: _titleFocus,
              decoration: _dialogDecoration(
                  label: 'RFQ title',
                  hint: 'e.g. Network infrastructure upgrade'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'RFQ title is required.'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: _dialogDecoration(label: 'Category'),
                    items: widget.categoryOptions
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _category = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ownerCtrl,
                    decoration: _dialogDecoration(
                        label: 'Owner', hint: 'e.g. J. Patel'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const DialogSectionTitle(
              title: 'Budget and schedule',
              subtitle: 'Set a due date and target budget.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogDecoration(
                        label: 'Budget',
                        hint: 'e.g. 120000',
                        prefixIcon: const Icon(Icons.attach_money)),
                    validator: (value) {
                      final amount = _parseCurrency(value ?? '');
                      return amount <= 0 ? 'Enter a budget amount.' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ??
                            DateTime.now().add(const Duration(days: 21)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(DateTime.now().year + 5),
                      );
                      if (picked == null) return;
                      setState(() {
                        _dueDate = picked;
                        _showDateError = false;
                      });
                    },
                    child: InputDecorator(
                      decoration: _dialogDecoration(
                        label: 'Due date',
                        hint: 'Select date',
                        prefixIcon: const Icon(Icons.event),
                        errorText: _showDateError ? 'Select a date.' : null,
                      ),
                      child: Text(
                        _dueDate == null
                            ? 'Select date'
                            : _formatDisplayDate(_dueDate!),
                        style: TextStyle(
                          color: _dueDate == null
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const DialogSectionTitle(
              title: 'Vendor outreach',
              subtitle: 'Track invitations and responses.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _invitedCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogDecoration(label: 'Invited', hint: '0'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _responsesCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        _dialogDecoration(label: 'Responses', hint: '0'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<RfqStatus>(
                    initialValue: _status,
                    decoration: _dialogDecoration(label: 'Status'),
                    items: RfqStatus.values
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _status = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<ProcurementPriority>(
                    initialValue: _priority,
                    decoration: _dialogDecoration(label: 'Priority'),
                    items: ProcurementPriority.values
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _priority = value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreatePoDialog extends StatefulWidget {
  const CreatePoDialog({
    super.key,
    required this.contextChips,
    required this.categoryOptions,
  });

  final List<Widget> contextChips;
  final List<String> categoryOptions;

  @override
  State<CreatePoDialog> createState() => _CreatePoDialogState();
}

class _CreatePoDialogState extends State<CreatePoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idCtrl;
  late TextEditingController _vendorCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _amountCtrl;

  late String _category;
  PurchaseOrderStatus _status = PurchaseOrderStatus.awaitingApproval;
  DateTime _orderedDate = DateTime.now();
  DateTime _expectedDate = DateTime.now().add(const Duration(days: 21));
  double _progress = 0.0;

  final FocusNode _idFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController();
    _vendorCtrl = TextEditingController();
    _ownerCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _category = widget.categoryOptions.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _idFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _vendorCtrl.dispose();
    _ownerCtrl.dispose();
    _amountCtrl.dispose();
    _idFocus.dispose();
    super.dispose();
  }

  int _parseCurrency(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  String _formatDisplayDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  InputDecoration _dialogDecoration(
      {required String label,
      String? hint,
      Widget? prefixIcon,
      String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProcurementDialogShell(
      title: 'Create Purchase Order',
      subtitle: 'Issue a PO with clear ownership and delivery timing.',
      icon: Icons.receipt_long_outlined,
      contextChips: widget.contextChips,
      primaryLabel: 'Create PO',
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.of(context).pop(),
      onPrimary: () {
        final valid = _formKey.currentState?.validate() ?? false;
        if (!valid) return;
        final amount = _parseCurrency(_amountCtrl.text);
        final poId = _idCtrl.text.trim().isEmpty
            ? 'PO-${DateTime.now().millisecondsSinceEpoch % 10000}'
            : _idCtrl.text.trim();
        final projectId =
            ProjectDataHelper.getData(context).projectId ?? 'project-1';
        final po = PurchaseOrderModel(
          id: poId,
          poNumber: poId,
          projectId: projectId,
          vendorName: _vendorCtrl.text.trim(),
          category: _category,
          owner: _ownerCtrl.text.trim().isEmpty
              ? 'Unassigned'
              : _ownerCtrl.text.trim(),
          orderedDate: _orderedDate,
          expectedDate: _expectedDate,
          amount: amount.toDouble(),
          progress: _progress,
          status: _status,
          createdAt: DateTime.now(),
        );
        Navigator.of(context).pop(po);
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DialogSectionTitle(
              title: 'PO details',
              subtitle: 'Define vendor, owner, and category.',
            ),
            TextFormField(
              controller: _idCtrl,
              focusNode: _idFocus,
              decoration: _dialogDecoration(
                  label: 'PO number', hint: 'Auto-generated if left blank'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vendorCtrl,
              decoration: _dialogDecoration(
                  label: 'Vendor', hint: 'e.g. GreenLeaf Office'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Vendor is required.'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: _dialogDecoration(label: 'Category'),
                    items: widget.categoryOptions
                        .map((option) => DropdownMenuItem(
                            value: option, child: Text(option)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _category = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ownerCtrl,
                    decoration:
                        _dialogDecoration(label: 'Owner', hint: 'e.g. L. Chen'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const DialogSectionTitle(
              title: 'Amounts and dates',
              subtitle: 'Track financials and delivery.',
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _dialogDecoration(
                  label: 'Amount',
                  hint: 'e.g. 72000',
                  prefixIcon: const Icon(Icons.attach_money)),
              validator: (value) {
                final amount = _parseCurrency(value ?? '');
                return amount <= 0 ? 'Enter a PO amount.' : null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _orderedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(DateTime.now().year + 5),
                      );
                      if (picked == null) return;
                      setState(() => _orderedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: _dialogDecoration(
                          label: 'Ordered date',
                          prefixIcon: const Icon(Icons.event)),
                      child: Text(
                        _formatDisplayDate(_orderedDate),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(DateTime.now().year + 5),
                      );
                      if (picked == null) return;
                      setState(() => _expectedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: _dialogDecoration(
                          label: 'Expected date',
                          prefixIcon: const Icon(Icons.event_available)),
                      child: Text(
                        _formatDisplayDate(_expectedDate),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PurchaseOrderStatus>(
              initialValue: _status,
              decoration: _dialogDecoration(label: 'Status'),
              items: PurchaseOrderStatus.values
                  .map((option) => DropdownMenuItem(
                      value: option, child: Text(option.label)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _status = value);
              },
            ),
            const SizedBox(height: 12),
            const Text('Progress',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569))),
            Slider(
              value: _progress,
              min: 0,
              max: 1,
              divisions: 10,
              label: '${(_progress * 100).round()}%',
              activeColor: const Color(0xFF2563EB),
              onChanged: (value) => setState(() => _progress = value),
            ),
          ],
        ),
      ),
    );
  }
}

class AddContractDialog extends StatefulWidget {
  const AddContractDialog({
    super.key,
    required this.contextChips,
    required this.categoryOptions, // Just for context, mainly service types
  });

  final List<Widget> contextChips;
  final List<String> categoryOptions;

  @override
  State<AddContractDialog> createState() => _AddContractDialogState();
}

class _AddContractDialogState extends State<AddContractDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _contractorCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _durationCtrl;

  String _status = 'Draft';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _contractorCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _costCtrl = TextEditingController();
    _durationCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contractorCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  int _parseCurrency(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  InputDecoration _dialogDecoration(
      {required String label,
      String? hint,
      Widget? prefixIcon,
      String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProcurementDialogShell(
      title: 'Add Contract',
      subtitle: 'Define a new contract agreement.',
      icon: Icons.assignment_outlined,
      contextChips: widget.contextChips,
      primaryLabel: 'Create Contract',
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.of(context).pop(),
      onPrimary: () {
        final valid = _formKey.currentState?.validate() ?? false;
        if (!valid) return;

        final projectId =
            ProjectDataHelper.getData(context).projectId ?? 'project-1';
        final cost = _parseCurrency(_costCtrl.text);

        final contract = ContractModel(
          id: '', // Service generates ID
          projectId: projectId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          contractorName: _contractorCtrl.text.trim(),
          estimatedCost: cost.toDouble(),
          duration: _durationCtrl.text.trim(),
          status: _status,
          createdAt: DateTime.now(),
        );
        Navigator.of(context).pop(contract);
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DialogSectionTitle(
              title: 'Contract basics',
              subtitle: 'What is being contracted and who is responsible?',
            ),
            TextFormField(
              controller: _titleCtrl,
              decoration: _dialogDecoration(
                  label: 'Contract Item', hint: 'e.g. Electrical Wiring'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contractorCtrl,
              decoration: _dialogDecoration(
                  label: 'Contractor Name', hint: 'e.g. Sparky Services'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Contractor name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: _dialogDecoration(
                  label: 'Description', hint: 'Scope of work...'),
            ),
            const SizedBox(height: 18),
            const DialogSectionTitle(
              title: 'Terms',
              subtitle: 'Cost, duration, and status.',
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costCtrl,
                    decoration: _dialogDecoration(
                        label: 'Est. Cost', prefixIcon: const Icon(Icons.attach_money)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _durationCtrl,
                    decoration: _dialogDecoration(
                        label: 'Duration', hint: 'e.g. 3 months'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: _dialogDecoration(label: 'Status'),
              items: ['Draft', 'Active', 'Pending', 'Closed']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
