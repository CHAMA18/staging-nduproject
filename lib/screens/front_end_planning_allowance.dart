import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/screens/project_charter_screen.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';
import 'package:ndu_project/widgets/responsive.dart';

/// Front End Planning – Allowance screen
/// Refactored to support structured "Program-Aware Financial Inputs".
///
/// TODO: Each allowance item NEEDS to support role/person assignment.
/// Users should be able to specify WHO is responsible for managing each
/// allowance (e.g., "Finance Manager", "John Doe"). This enables tracking
/// and accountability for budget items throughout the project lifecycle.
///
/// The "Applies To" field determines WHERE the allowance applies (Estimate,
/// Schedule, Training, etc.), while "Assigned To" determines WHO manages it.
/// This feature is highlighted in the requirements screenshots and needs implementation.
class FrontEndPlanningAllowanceScreen extends StatefulWidget {
  const FrontEndPlanningAllowanceScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const FrontEndPlanningAllowanceScreen()),
    );
  }

  @override
  State<FrontEndPlanningAllowanceScreen> createState() =>
      _FrontEndPlanningAllowanceScreenState();
}

class _FrontEndPlanningAllowanceScreenState
    extends State<FrontEndPlanningAllowanceScreen> {
  final TextEditingController _notes = TextEditingController();

  // Local state for list items
  List<AllowanceItem> _allowanceItems = [];
  bool _isSyncReady = false;
  bool _isGenerating = false;
  late final OpenAiServiceSecure _openAi;

  @override
  void initState() {
    super.initState();
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ProjectDataHelper.getData(context);
      _notes.text = data.frontEndPlanning
          .allowance; // Legacy field used for general notes now?
      // Actually, let's keep _notes separate if we want general notes.
      // The user said "Convert simple text box to structured List".
      // I'll keep the top notes field for "General Allowance Notes" and map it to the old string field for now,
      // or just use a separate field if available, but FEP data has `allowance` string.
      // I'll use `allowance` for general notes text.

      this._allowanceItems = List.from(data.frontEndPlanning.allowanceItems);

      _notes.addListener(_syncNotesToProvider);
      _isSyncReady = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notes.removeListener(_syncNotesToProvider);
    _notes.dispose();
    super.dispose();
  }

  void _syncNotesToProvider() {
    if (!mounted || !_isSyncReady) return;
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          allowance: _notes.text, // Sync general notes
        ),
      ),
    );
  }

  void _syncItemsToProvider() {
    if (!mounted || !_isSyncReady) return;
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          allowanceItems: _allowanceItems,
        ),
      ),
    );
  }

  Future<void> _generateDefaultAllowances() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final data = ProjectDataHelper.getData(context);
      final sb = StringBuffer();
      sb.writeln('Project: ${data.projectName}');
      sb.writeln('Description: ${data.solutionDescription}');
      if (data.projectGoals.isNotEmpty) {
        sb.writeln('Goals: ${data.projectGoals.join(", ")}');
      }
      if (data.frontEndPlanning.requirements.isNotEmpty) {
        sb.writeln('Requirements:\n${data.frontEndPlanning.requirements}');
      }
      if (data.frontEndPlanning.risks.isNotEmpty) {
        sb.writeln('Risks:\n${data.frontEndPlanning.risks}');
      }

      final newItems =
          await _openAi.generateAllowancesFromContext(sb.toString());

      if (mounted) {
        setState(() {
          _allowanceItems.addAll(newItems);
        });
        _syncItemsToProvider();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating allowances: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _addItem() {
    _showItemDialog();
  }

  void _editItem(AllowanceItem item) {
    _showItemDialog(item: item);
  }

  void _deleteItem(String id) {
    setState(() {
      _allowanceItems.removeWhere((item) => item.id == id);
    });
    _syncItemsToProvider();
  }

  Future<void> _showItemDialog({AllowanceItem? item}) async {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final amountController =
        TextEditingController(text: item?.amount.toString() ?? '0');
    final appliesToController =
        TextEditingController(text: item?.appliesTo.join(', ') ?? '');
    final assignedToController =
        TextEditingController(text: item?.assignedTo ?? '');
    final notesController = TextEditingController(text: item?.notes ?? '');
    String selectedType = item?.type ?? 'Contingency';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Allowance' : 'Add Allowance'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                    labelText: 'Type', border: OutlineInputBorder()),
                items: ['Contingency', 'Training', 'Staffing', 'Tech', 'Other']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => selectedType = val!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: appliesToController,
                decoration: const InputDecoration(
                    labelText: 'Applies To (comma separated)',
                    hintText: 'e.g., Estimate, Schedule, Training',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: assignedToController,
                decoration: const InputDecoration(
                    labelText: 'Assigned To (Role or Person)',
                    hintText: 'e.g., Finance Manager, John Doe',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Notes', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC812),
                foregroundColor: Colors.black),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      if (name.isEmpty) return;

      final amount =
          double.tryParse(amountController.text.replaceAll(',', '')) ?? 0.0;
      final appliesTo = appliesToController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final newItem = AllowanceItem(
        id: item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        number: item?.number ?? (_allowanceItems.length + 1),
        name: name,
        type: selectedType,
        amount: amount,
        appliesTo: appliesTo,
        assignedTo: assignedToController.text.trim(),
        notes: notesController.text.trim(),
      );

      setState(() {
        if (isEditing) {
          final index = _allowanceItems.indexWhere((i) => i.id == item!.id);
          if (index != -1) _allowanceItems[index] = newItem;
        } else {
          _allowanceItems.add(newItem);
        }
      });
      _syncItemsToProvider();
    }
  }

  Widget _buildCostSummary(
      ProjectDataModel projectData, CostAnalysisData costData) {
    // 1. Correctly identify the preferred solution
    final preferredId = projectData.preferredSolutionId;
    final preferredSolution = projectData.potentialSolutions.firstWhere(
        (s) => s.id == preferredId,
        orElse: () => PotentialSolution.empty(id: 'empty', number: 0));

    // 2. Find cost data for that solution title
    final solutionCost = costData.solutionCosts.firstWhere(
      (s) => s.solutionTitle == preferredSolution.title,
      orElse: () => SolutionCostData(),
    );

    // 3. Calculate total
    double totalCost = 0.0;
    for (final row in solutionCost.costRows) {
      // Clean string currency to double
      final clean = row.cost.replaceAll(RegExp(r'[^0-9.]'), '');
      totalCost += double.tryParse(clean) ?? 0.0;
    }

    final hasPreferred =
        preferredId != null && preferredSolution.title.isNotEmpty;
    final formatter = NumberFormat.simpleCurrency(decimalDigits: 0);

    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        if (hasPreferred)
          _CostMetaItem(
            label: 'Preferred Solution',
            value: preferredSolution.title,
            isHighlight: true,
          ),
        _CostMetaItem(
          label: 'Est. Total Cost',
          value: hasPreferred ? formatter.format(totalCost) : '--',
        ),
        _CostMetaItem(
            label: 'Total Budget',
            value: costData.projectValueAmount.isEmpty
                ? '--'
                : '\$${costData.projectValueAmount}'),
      ],
    );
  }

  Widget _buildAllowanceItemCard(AllowanceItem item) {
    final formatter = NumberFormat.simpleCurrency(decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.monetization_on_outlined,
                    color: Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.type,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4B5563)),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatter.format(item.amount),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                    if (item.assignedTo.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(
                            item.assignedTo,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151)),
                          ),
                        ],
                      ),
                    ],
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.notes,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF4B5563)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTapDown: (details) {
                  showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                    ),
                    items: [
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: () => Future.delayed(
                          Duration.zero,
                          () => _editItem(item),
                        ),
                      ),
                      PopupMenuItem(
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                        onTap: () => _deleteItem(item.id),
                      ),
                    ],
                  );
                },
                child: const Icon(Icons.more_vert,
                    size: 20, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Apply to:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 8,
                children: [
                  _ApplyChip(
                    label: 'Estimate',
                    isActive: item.appliesTo.contains('Estimate'),
                    onToggle: (isActive) =>
                        _toggleApply(item, 'Estimate', isActive),
                  ),
                  _ApplyChip(
                    label: 'Training',
                    isActive: item.appliesTo.contains('Training'),
                    onToggle: (isActive) =>
                        _toggleApply(item, 'Training', isActive),
                  ),
                  _ApplyChip(
                    label: 'Schedule',
                    isActive: item.appliesTo.contains('Schedule'),
                    onToggle: (isActive) =>
                        _toggleApply(item, 'Schedule', isActive),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleApply(AllowanceItem item, String tag, bool isActive) {
    setState(() {
      if (isActive) {
        if (!item.appliesTo.contains(tag)) {
          item.appliesTo.add(tag);
        }
      } else {
        item.appliesTo.remove(tag);
      }
    });
    _syncItemsToProvider();
  }

  @override
  Widget build(BuildContext context) {
    final projectData = ProjectDataHelper.getData(context, listen: true);
    final costData = projectData.costAnalysisData;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Allowance'),
            ),
            Expanded(
              child: Stack(
                children: [
                  const AdminEditToggle(),
                  Column(
                    children: [
                      const FrontEndPlanningHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cost Details Container (Blue)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFBFDBFE)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.analytics_outlined,
                                            color: Color(0xFF1E40AF)),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Cost Details from Cost Basis Analysis',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E3A8A),
                                          ),
                                        ),
                                        if (costData == null) ...[
                                          const Spacer(),
                                          const Text(
                                            '(No analysis data yet)',
                                            style: TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic),
                                          )
                                        ],
                                      ],
                                    ),
                                    if (costData != null) ...[
                                      const SizedBox(height: 16),
                                      _buildCostSummary(projectData, costData),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              const Text('Allowance',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      color: Color(0xFF111827))),
                              const SizedBox(height: 8),
                              const Text(
                                'Predefined provisions for uncertain or variable elements, such as cost, time, or resources, set aside to accommodate expected variability without changing the approved scope.',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF6B7280)),
                              ),
                              const SizedBox(height: 16),
                              _roundedField(
                                  controller: _notes,
                                  hint: 'Input your notes here...',
                                  minLines: 3),
                              const SizedBox(height: 32),

                              // Header Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Allowance & Contingency Items',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      PageRegenerateAllButton(
                                        onRegenerateAll: () async {
                                          final confirmed =
                                              await showRegenerateAllConfirmation(
                                                  context);
                                          if (confirmed && mounted) {
                                            await _generateDefaultAllowances();
                                          }
                                        },
                                        isLoading: _isGenerating,
                                        tooltip:
                                            'Generate suggested allowances',
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: _addItem,
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Add Item'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // List of Items
                              if (_allowanceItems.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                        style: BorderStyle.solid),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No allowance items added yet.\nClick "Add Item" or "Generate" to start.',
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(color: Color(0xFF9CA3AF)),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: _allowanceItems.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = _allowanceItems[index];
                                    return _buildAllowanceItemCard(item);
                                  },
                                ),

                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _BottomOverlay(onNext: () {
                    // Save is automatic via list methods, but we trigger standard save & navigate
                    ProjectDataHelper.saveAndNavigate(
                      context: context,
                      checkpoint: 'fep_allowance',
                      nextScreenBuilder: () =>
                          const ProjectCharterScreen(), // Usually next is charter or similar
                      dataUpdater: (data) => data.copyWith(
                        frontEndPlanning: ProjectDataHelper.updateFEPField(
                          current: data.frontEndPlanning,
                          allowance: _notes.text, // Sync final text
                          allowanceItems: _allowanceItems, // Sync items
                        ),
                      ),
                    );
                  }),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const _ApplyChip({
    required this.label,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onToggle(!isActive),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              const Icon(Icons.check, size: 12, color: Color(0xFF3B82F6)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF1E40AF)
                    : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostMetaItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _CostMetaItem(
      {required this.label, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isHighlight ? const Color(0xFF1E3A8A) : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  final VoidCallback onNext;

  const _BottomOverlay({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true, // Only buttons interactive
        child: Stack(
          children: [
            Positioned(
              left: 24,
              bottom: 24,
              child: IgnorePointer(
                ignoring: false,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: Color(0xFFB3D9FF), shape: BoxShape.circle),
                  child: const Icon(Icons.info_outline, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: IgnorePointer(
                ignoring: false,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F1FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD7E5FF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                          SizedBox(width: 10),
                          Text('AI',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB))),
                          SizedBox(width: 12),
                          Text(
                            'Define budget allowances and contingency plans.',
                            style: TextStyle(color: Color(0xFF1F2937)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC812),
                        foregroundColor: const Color(0xFF111827),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 34, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                        elevation: 0,
                      ),
                      child: const Text('Next',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _roundedField(
    {required TextEditingController controller,
    required String hint,
    int minLines = 1}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE4E7EC)),
    ),
    padding: const EdgeInsets.all(14),
    child: TextField(
      controller: controller,
      minLines: minLines,
      maxLines: null,
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
    ),
  );
}
