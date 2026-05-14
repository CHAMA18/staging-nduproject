import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/planning_contracting_models.dart';
import 'package:ndu_project/models/procurement/procurement_models.dart';
import 'package:ndu_project/models/procurement/procurement_ui_extensions.dart';
import 'package:ndu_project/models/procurement/procurement_workflow_step.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/screens/planning_contracting_screen.dart';
import 'package:ndu_project/services/contract_service.dart'
    as planning_contracts;
import 'package:ndu_project/services/planning_contracting_service.dart';
import 'package:ndu_project/services/procurement_seeding_service.dart';
import 'package:ndu_project/services/procurement_service.dart';
import 'package:ndu_project/services/procurement_workflow_service.dart';
import 'package:ndu_project/services/schedule_linkage_service.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/procurement/budget_tracking_table.dart';
import 'package:ndu_project/widgets/procurement/po_approval_dialog.dart';
import 'package:ndu_project/widgets/procurement_dialogs.dart';
import 'package:ndu_project/widgets/procurement/procurement_timeline_view.dart';
import 'package:ndu_project/widgets/procurement/procurement_workflow_builder.dart';
import 'package:ndu_project/widgets/procurement/vendor_comparison_table.dart';
import 'package:ndu_project/widgets/responsive.dart';

class PlanningProcurementV2Screen extends StatefulWidget {
  const PlanningProcurementV2Screen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlanningProcurementV2Screen()),
    );
  }

  @override
  State<PlanningProcurementV2Screen> createState() =>
      _PlanningProcurementV2ScreenState();
}

class _PlanningProcurementV2ScreenState
    extends State<PlanningProcurementV2Screen> {
  static const List<ProcurementWorkflowStep> _defaultProcurementWorkflowTemplate = [
    ProcurementWorkflowStep(
      id: 'request_for_quote',
      name: 'Request for Quote (RFQ)',
      duration: 2,
      unit: 'week',
    ),
    ProcurementWorkflowStep(
      id: 'quote_evaluation',
      name: 'Quote Evaluation',
      duration: 2,
      unit: 'week',
    ),
    ProcurementWorkflowStep(
      id: 'request_for_information',
      name: 'Request for Information',
      duration: 1,
      unit: 'week',
    ),
    ProcurementWorkflowStep(
      id: 'purchase_order',
      name: 'Purchase Order',
      duration: 1,
      unit: 'week',
    ),
  ];

  static const List<String> _tabLabels = [
    'Overview',
    'Procurement Items',
    'Timeline',
    'Vendor Comparison',
    'Purchase Orders',
    'Budget Tracking',
    'Workflows',
    'Reports',
  ];

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  int _selectedTab = 0;
  String _projectId = '';
  bool _didInitialize = false;
  bool _seedCheckRunning = false;
  bool _workflowLoading = false;
  bool _workflowSaving = false;
  bool _customizeWorkflowByScope = false;

  List<ProcurementItemModel> _items = const [];
  List<PurchaseOrderModel> _pos = const [];
  List<PlanningRfq> _rfqs = const [];
  List<planning_contracts.ContractModel> _contracts = const [];
  String? _selectedWorkflowScopeId;
  List<ProcurementWorkflowStep> _globalWorkflowSteps =
      List<ProcurementWorkflowStep>.from(_defaultProcurementWorkflowTemplate);
  List<ProcurementWorkflowStep> _workflowDraftSteps =
      List<ProcurementWorkflowStep>.from(_defaultProcurementWorkflowTemplate);
  Map<String, List<ProcurementWorkflowStep>> _scopeWorkflowOverrides = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;

    final data = ProjectDataHelper.getData(context);
    _projectId = data.projectId ?? '';
    _didInitialize = true;

    if (_projectId.isEmpty) {
      return;
    }

    _subscribeToData();
    Future.microtask(() async {
      if (!mounted) return;
      await _loadProcurementWorkflowData();
      if (!mounted) return;
      await ScheduleLinkageService.checkAndSyncOnOpen(context);
      if (!mounted) return;
      await _checkAutoSeed();
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                activeItemLabel: 'Planning Procurement',
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20 : 40,
                            vertical: isMobile ? 20 : 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(context),
                              const SizedBox(height: 24),
                              _buildTabBar(),
                              const SizedBox(height: 24),
                              _buildTabContent(),
                              const SizedBox(height: 96),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const KazAiChatBubble(),
                  const AdminEditToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final data = ProjectDataHelper.getData(context, listen: true);
    final summaryCards = [
      _SummaryCardData(
        label: 'Items',
        value: '${_items.length}',
        supporting: 'Procurement records in planning',
      ),
      _SummaryCardData(
        label: 'Pending POs',
        value: '${_pos.where((po) => po.approvalStatus == 'pending').length}',
        supporting: 'Awaiting approval',
      ),
      _SummaryCardData(
        label: 'RFQs',
        value: '${_rfqs.length}',
        supporting: 'Planning RFQs feeding procurement',
      ),
      _SummaryCardData(
        label: 'Contracts',
        value: '${_contracts.length}',
        supporting: 'Live procurement contracts',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planning Procurement',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Continue procurement planning with contracting handoff, '
                    'schedule-linked items, and approval tracking for ${data.projectName.isNotEmpty ? data.projectName : 'this project'}.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF4B5563),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => PlanningContractingScreen.open(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Open Contracting'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: summaryCards
              .map((card) => _SummaryCard(card: card))
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List<Widget>.generate(_tabLabels.length, (index) {
        final selected = index == _selectedTab;
        return ChoiceChip(
          label: Text(_tabLabels[index]),
          selected: selected,
          onSelected: (_) => setState(() => _selectedTab = index),
          selectedColor: const Color(0xFF111827),
          labelStyle: TextStyle(
            color: selected ? Colors.white : const Color(0xFF111827),
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF111827)
                  : const Color(0xFFE5E7EB),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildItemsTab();
      case 2:
        return _buildTimelineTab();
      case 3:
        return _buildVendorComparisonTab();
      case 4:
        return _buildPurchaseOrdersTab();
      case 5:
        return _buildBudgetTrackingTab();
      case 6:
        return _buildWorkflowsTab();
      case 7:
        return _buildReportsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewTab() {
    final pendingApprovals =
        _pos.where((po) => po.approvalStatus == 'pending').toList();
    final overdueItems =
        ScheduleLinkageService.getOverdueItems(_items).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Current handoff state',
          subtitle:
              'This is the new planning-side procurement workspace. The deeper reusable widgets from the implementation plan are not wired yet, but the service layer, seeding path, and live data streams are now in place.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatusPill(
                label: '${pendingApprovals.length} pending approvals',
                color: const Color(0xFFF59E0B),
              ),
              _StatusPill(
                label: '${overdueItems.length} overdue items',
                color: const Color(0xFFDC2626),
              ),
              _StatusPill(
                label: '${_rfqs.length} contracting RFQs visible',
                color: const Color(0xFF2563EB),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Next implementation targets',
          subtitle:
              'These are the highest-value pieces still missing from the original plan.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ChecklistRow(text: 'Extract timeline, vendor comparison, budget, and workflow widgets from the FEP procurement screen'),
              _ChecklistRow(text: 'Replace placeholder tabs with CRUD and workflow actions'),
              _ChecklistRow(text: 'Wire PO approval and escalation actions into the purchase orders tab'),
              _ChecklistRow(text: 'Promote this screen as the definitive planning procurement route'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTab() {
    final data = ProjectDataHelper.getData(context, listen: true);
    return _SectionCard(
      title: 'Procurement items',
      subtitle:
          'Manage procurement scope records, budgets, owners, and schedule links from one place.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Live items from `projects/{projectId}/procurement_items`.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openAddItemDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            const Text(
              'No procurement items yet.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          else
            Column(
              children: [
                for (var i = 0; i < _items.length; i++) ...[
                  _ProcurementItemCard(
                    item: _items[i],
                    onEdit: () => _openEditItemDialog(_items[i]),
                    onDelete: () => _removeItem(_items[i]),
                    onLinkSchedule: () => _openScheduleLinkDialog(_items[i], data),
                    onClearSchedule: _items[i].linkedMilestoneId != null ||
                            _items[i].linkedWbsId != null ||
                            _items[i].requiredByDate != null
                        ? () => _clearScheduleLink(_items[i])
                        : null,
                  ),
                  if (i != _items.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDialogContextChips() {
    final data = ProjectDataHelper.getData(context);
    return [
      if (data.projectName.trim().isNotEmpty)
        ContextChip(label: 'Project', value: data.projectName.trim()),
      if (data.solutionTitle.trim().isNotEmpty)
        ContextChip(label: 'Solution', value: data.solutionTitle.trim()),
      ContextChip(label: 'Phase', value: 'Planning'),
    ];
  }

  List<ProcurementAssignableMemberOption> _assignableMembers() {
    final data = ProjectDataHelper.getData(context);
    final options = <ProcurementAssignableMemberOption>[];
    if (data.charterProjectManagerName.trim().isNotEmpty) {
      options.add(
        ProcurementAssignableMemberOption(
          id: 'project_manager',
          name: data.charterProjectManagerName.trim(),
          email: '',
          role: 'Project Manager',
          source: 'Charter',
        ),
      );
    }
    if (data.charterProjectSponsorName.trim().isNotEmpty) {
      options.add(
        ProcurementAssignableMemberOption(
          id: 'project_sponsor',
          name: data.charterProjectSponsorName.trim(),
          email: '',
          role: 'Project Sponsor',
          source: 'Charter',
        ),
      );
    }
    return options;
  }

  Future<void> _openAddItemDialog() async {
    final result = await showDialog<ProcurementItemModel>(
      context: context,
      builder: (dialogContext) {
        return AddItemDialog(
          contextChips: _buildDialogContextChips(),
          categoryOptions: const [
            'Materials',
            'Equipment',
            'Services',
            'IT Equipment',
            'Construction Services',
            'Furniture',
            'Security',
            'Logistics',
            'Other',
          ],
          responsibleOptions: _assignableMembers(),
          showAiGenerateButton: false,
          itemDomainLabel: 'Procurement',
        );
      },
    );

    if (result == null) return;
    try {
      final normalized = result.copyWith(projectId: _projectId);
      await ProcurementService.createItem(normalized);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added item "${normalized.name}".')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating procurement item: $e')),
      );
    }
  }

  Future<void> _openEditItemDialog(ProcurementItemModel item) async {
    final result = await showDialog<ProcurementItemModel>(
      context: context,
      builder: (dialogContext) {
        return AddItemDialog(
          contextChips: _buildDialogContextChips(),
          categoryOptions: const [
            'Materials',
            'Equipment',
            'Services',
            'IT Equipment',
            'Construction Services',
            'Furniture',
            'Security',
            'Logistics',
            'Other',
          ],
          responsibleOptions: _assignableMembers(),
          initialItem: item,
          showAiGenerateButton: false,
          itemDomainLabel: 'Procurement',
        );
      },
    );

    if (result == null) return;
    try {
      await ProcurementService.updateItem(_projectId, item.id, {
        'name': result.name.trim(),
        'description': result.description.trim(),
        'category': result.category.trim(),
        'status': result.status.name,
        'priority': result.priority.name,
        'budget': result.budget,
        'spent': result.spent,
        'estimatedDelivery': result.estimatedDelivery,
        'actualDelivery': result.actualDelivery,
        'progress': result.progress.clamp(0.0, 1.0),
        'vendorId': result.vendorId,
        'contractId': result.contractId,
        'events': result.events.map((event) => event.toJson()).toList(),
        'notes': result.notes,
        'projectPhase': result.projectPhase,
        'responsibleMember': result.responsibleMember,
        'comments': result.comments,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated item "${result.name}".')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to edit item: $e')),
      );
    }
  }

  Future<void> _removeItem(ProcurementItemModel item) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remove Procurement Item'),
            content: Text(
              'Delete "${item.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      await ProcurementService.deleteItem(_projectId, item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted item "${item.name}".')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete item: $e')),
      );
    }
  }

  Future<void> _openScheduleLinkDialog(
    ProcurementItemModel item,
    ProjectDataModel data,
  ) async {
    final milestones = ScheduleLinkageService.getMilestones(data);
    final wbsElements = ScheduleLinkageService.getWbsElements(data);

    String? selectedMilestoneId = item.linkedMilestoneId;
    String? selectedWbsId = item.linkedWbsId;

    final saved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              DateTime? resolvedRequiredBy() {
                if (selectedMilestoneId == null || selectedMilestoneId!.isEmpty) {
                  return null;
                }
                final milestone = milestones.where((activity) {
                  return activity.id == selectedMilestoneId;
                }).cast<ScheduleActivity?>().firstWhere(
                      (activity) => activity != null,
                      orElse: () => null,
                    );
                if (milestone == null) return null;
                return DateTime.tryParse(milestone.dueDate);
              }

              return AlertDialog(
                title: Text('Link Schedule for "${item.name}"'),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedWbsId,
                        decoration: const InputDecoration(
                          labelText: 'WBS element',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('Not linked'),
                          ),
                          ...wbsElements.map(
                            (activity) => DropdownMenuItem<String>(
                              value: activity.wbsId,
                              child: Text(
                                activity.title.trim().isNotEmpty
                                    ? activity.title
                                    : activity.wbsId,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => selectedWbsId =
                              (value ?? '').trim().isEmpty ? null : value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedMilestoneId,
                        decoration: const InputDecoration(
                          labelText: 'Milestone',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('Not linked'),
                          ),
                          ...milestones.map(
                            (activity) => DropdownMenuItem<String>(
                              value: activity.id,
                              child: Text(
                                activity.title.trim().isNotEmpty
                                    ? activity.title
                                    : activity.id,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => selectedMilestoneId =
                              (value ?? '').trim().isEmpty ? null : value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        resolvedRequiredBy() != null
                            ? 'Required by ${DateFormat('MMM dd, yyyy').format(resolvedRequiredBy()!)}'
                            : 'No required-by date will be set until a milestone with a due date is linked.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
        ) ??
        false;
    if (!saved) return;

    final milestone = milestones.where((activity) {
      return activity.id == selectedMilestoneId;
    }).cast<ScheduleActivity?>().firstWhere(
          (activity) => activity != null,
          orElse: () => null,
        );
    final requiredBy =
        milestone == null ? null : DateTime.tryParse(milestone.dueDate);

    try {
      await ProcurementService.updateItemScheduleLink(
        _projectId,
        item.id,
        wbsId: selectedWbsId,
        milestoneId: selectedMilestoneId,
        requiredByDate: requiredBy,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated schedule link for "${item.name}".')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update schedule link: $e')),
      );
    }
  }

  Future<void> _clearScheduleLink(ProcurementItemModel item) async {
    try {
      await ProcurementService.clearItemScheduleLink(_projectId, item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cleared schedule link for "${item.name}".')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to clear schedule link: $e')),
      );
    }
  }

  Widget _buildTimelineTab() {
    return _SectionCard(
      title: 'Timeline',
      subtitle:
          'Schedule-linked items already sync through `ScheduleLinkageService`. This tab now uses an extracted shared timeline view.',
      child: ProcurementTimelineView(items: _items),
    );
  }

  Widget _buildVendorComparisonTab() {
    final comparableContracts = _contracts.where((contract) {
      return (contract.evaluationScores ?? const []).isNotEmpty;
    }).toList();

    return _SectionCard(
      title: 'Vendor comparison',
      subtitle:
          'This tab now surfaces scored vendor comparisons from planning contracting data. Item-level weighting remains available for future procurement-native comparisons.',
      child: comparableContracts.isEmpty
          ? const Text(
              'No contract evaluation scores are available yet. Complete vendor evaluation in Contracting to populate this view.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < comparableContracts.length; i++) ...[
                  _VendorComparisonContractCard(
                    contract: comparableContracts[i],
                    rfqs: _rfqs,
                  ),
                  if (i != comparableContracts.length - 1)
                    const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }

  Widget _buildPurchaseOrdersTab() {
    final data = ProjectDataHelper.getData(context, listen: true);
    final pendingApprovals =
        _pos.where((po) => po.approvalStatus == 'pending').length;
    final overdueApprovals =
        _pos.where((po) => po.approvalStatus == 'pending' && po.isPendingApproval).length;

    return _SectionCard(
      title: 'Purchase orders',
      subtitle:
          'Approval workflow methods are now wired into this tab. Draft POs can be submitted, pending POs can be reviewed, and overdue requests can be escalated.',
      child: _pos.isEmpty
          ? const Text(
              'No purchase orders yet.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricTile(
                      label: 'POs',
                      value: '${_pos.length}',
                    ),
                    _MetricTile(
                      label: 'Pending approvals',
                      value: '$pendingApprovals',
                    ),
                    _MetricTile(
                      label: 'Overdue approvals',
                      value: '$overdueApprovals',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < _pos.length; i++) ...[
                  _PurchaseOrderCard(
                    po: _pos[i],
                    projectOwnerName: _projectOwnerName(data),
                    onSubmit: () => _submitPoForApproval(_pos[i], data),
                    onReview: () => _reviewPo(_pos[i], data),
                    onEscalate: () => _escalatePo(_pos[i], data),
                  ),
                  if (i != _pos.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  Future<void> _submitPoForApproval(
    PurchaseOrderModel po,
    ProjectDataModel data,
  ) async {
    final approverId = _primaryApproverId(data);
    final approverName = _projectOwnerName(data);
    try {
      await ProcurementService.submitPoForApproval(
        _projectId,
        po.id,
        approverId,
        approverName,
        po.escalationDays,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submitted PO #${po.poNumber} for approval.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit PO for approval: $e')),
      );
    }
  }

  Future<void> _reviewPo(
    PurchaseOrderModel po,
    ProjectDataModel data,
  ) async {
    final result = await showPoApprovalDialog(
      context,
      po: po,
      projectOwnerId: _primaryApproverId(data),
      projectOwnerName: _projectOwnerName(data),
    );
    if (result == null) return;

    try {
      if (result.isApprove) {
        await ProcurementService.approvePo(
          _projectId,
          po.id,
          comments: result.comments,
        );
      } else if (result.isReject) {
        await ProcurementService.rejectPo(
          _projectId,
          po.id,
          result.comments,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isApprove
                ? 'Approved PO #${po.poNumber}.'
                : 'Rejected PO #${po.poNumber}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update PO approval: $e')),
      );
    }
  }

  Future<void> _escalatePo(
    PurchaseOrderModel po,
    ProjectDataModel data,
  ) async {
    final targets = _escalationTargets(data);
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No escalation targets configured.')),
      );
      return;
    }

    final targetId = await showDialog<String>(
      context: context,
      builder: (context) => PoEscalationDialog(
        po: po,
        availableEscalationTargets: targets,
      ),
    );
    if (targetId == null) return;

    try {
      await ProcurementService.escalatePo(_projectId, po.id, targetId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Escalated PO #${po.poNumber}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to escalate PO: $e')),
      );
    }
  }

  String _projectOwnerName(ProjectDataModel data) {
    final manager = data.charterProjectManagerName.trim();
    final sponsor = data.charterProjectSponsorName.trim();
    if (manager.isNotEmpty) return manager;
    if (sponsor.isNotEmpty) return sponsor;
    return 'Project Owner';
  }

  String _primaryApproverId(ProjectDataModel data) {
    final manager = data.charterProjectManagerName.trim();
    if (manager.isNotEmpty) return 'project_manager';
    final sponsor = data.charterProjectSponsorName.trim();
    if (sponsor.isNotEmpty) return 'project_sponsor';
    return 'project_owner';
  }

  List<EscalationTarget> _escalationTargets(ProjectDataModel data) {
    final targets = <EscalationTarget>[];
    final manager = data.charterProjectManagerName.trim();
    final sponsor = data.charterProjectSponsorName.trim();
    if (manager.isNotEmpty) {
      targets.add(
        EscalationTarget(
          id: 'project_manager',
          name: manager,
          role: 'Project Manager',
        ),
      );
    }
    if (sponsor.isNotEmpty) {
      targets.add(
        EscalationTarget(
          id: 'project_sponsor',
          name: sponsor,
          role: 'Project Sponsor',
        ),
      );
    }
    if (targets.isEmpty) {
      targets.add(
        const EscalationTarget(
          id: 'project_owner',
          name: 'Project Owner',
          role: 'Owner',
        ),
      );
    }
    return targets;
  }

  Widget _buildBudgetTrackingTab() {
    return _SectionCard(
      title: 'Budget tracking',
      subtitle:
          'Committed amount now calculates from approved, issued POs. This tab now uses the shared budget tracking table widget.',
      child: BudgetTrackingTable(
        items: _items,
        purchaseOrders: _pos,
      ),
    );
  }

  Widget _buildWorkflowsTab() {
    final workflowScopeId = _resolveWorkflowScopeId();
    final workflowScope = _findWorkflowScopeById(workflowScopeId);
    final workflowDisabledForSelection = _customizeWorkflowByScope &&
        workflowScope != null &&
        !_scopeRequiresProcurementWorkflow(workflowScope);
    final workflowSteps =
        workflowDisabledForSelection ? const <ProcurementWorkflowStep>[] : _workflowDraftSteps;

    return _SectionCard(
      title: 'Workflows',
      subtitle:
          'The workflow builder is now extracted into a shared widget and persists per project. Global and scope-specific procurement cycles can be managed here.',
      child: ProcurementWorkflowBuilder(
        scopeItems: _items,
        customizeWorkflowByScope: _customizeWorkflowByScope,
        selectedScopeId: workflowScopeId,
        selectedScopeName: workflowScope?.name ?? '',
        workflowDisabledForSelection: workflowDisabledForSelection,
        workflowTotalWeeks: _totalWorkflowDurationInWeeks(workflowSteps),
        workflowSteps: workflowSteps,
        workflowLoading: _workflowLoading,
        workflowSaving: _workflowSaving,
        onCustomizeByScopeChanged: _setCustomizeWorkflowByScope,
        onWorkflowScopeSelected: _selectWorkflowScope,
        onAddWorkflowStep: _addWorkflowStepToDraft,
        onEditWorkflowStep: _editWorkflowStep,
        onDeleteWorkflowStep: _deleteWorkflowStepFromDraft,
        onMoveWorkflowStep: _moveWorkflowStepInDraft,
        onResetWorkflow: _resetWorkflowDraftToPreset,
        onSaveWorkflow: _saveWorkflowForSelection,
        onApplyWorkflowToAllScopes: _applyWorkflowDraftToAllScopes,
      ),
    );
  }

  Widget _buildReportsTab() {
    final overdueItems = ScheduleLinkageService.getOverdueItems(_items).length;
    final pendingApprovals =
        _pos.where((po) => po.approvalStatus == 'pending').length;

    return _SectionCard(
      title: 'Reports',
      subtitle:
          '',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _MetricTile(label: 'Items', value: '${_items.length}'),
          _MetricTile(label: 'Overdue', value: '$overdueItems'),
          _MetricTile(label: 'Pending approvals', value: '$pendingApprovals'),
          _MetricTile(label: 'RFQs in handoff', value: '${_rfqs.length}'),
        ],
      ),
    );
  }

  Future<void> _checkAutoSeed() async {
    if (_seedCheckRunning || _projectId.isEmpty) {
      return;
    }

    _seedCheckRunning = true;
    try {
      final data = ProjectDataHelper.getData(context);
      if (ProcurementSeedingService.hasSeeded(data) || _items.isNotEmpty) {
        return;
      }

      final created =
          await ProcurementSeedingService.seedFromContracting(context);
      if (created > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $created procurement item(s) from contracting.'),
          ),
        );
      }
    } finally {
      _seedCheckRunning = false;
    }
  }

  void _subscribeToData() {
    _subscriptions.addAll([
      ProcurementService.streamItems(_projectId).listen((items) {
        if (!mounted) return;
        setState(() {
          _items = items;
          _syncWorkflowStateWithScopes();
        });
      }),
      ProcurementService.streamPos(_projectId).listen((pos) {
        if (!mounted) return;
        setState(() => _pos = pos);
      }),
      PlanningContractingService.streamRfqs(_projectId).listen((rfqs) {
        if (!mounted) return;
        setState(() => _rfqs = rfqs);
      }),
      planning_contracts.ContractService.streamContracts(_projectId)
          .listen((contracts) {
        if (!mounted) return;
        setState(() => _contracts = contracts);
      }),
    ]);
  }

  List<ProcurementWorkflowStep> _cloneWorkflowSteps(
    List<ProcurementWorkflowStep> steps,
  ) {
    return ProcurementWorkflowService.cloneSteps(steps);
  }

  Future<void> _loadProcurementWorkflowData() async {
    if (_projectId.isEmpty) return;
    setState(() => _workflowLoading = true);

    try {
      final snapshot = await ProcurementWorkflowService.load(_projectId);
      if (!mounted) return;
      setState(() {
        _globalWorkflowSteps = snapshot.globalSteps.isEmpty
            ? _cloneWorkflowSteps(_defaultProcurementWorkflowTemplate)
            : _cloneWorkflowSteps(snapshot.globalSteps);
        _scopeWorkflowOverrides = snapshot.scopeOverrides;
        if (_customizeWorkflowByScope) {
          _selectedWorkflowScopeId = _resolveWorkflowScopeId();
          _hydrateWorkflowDraftForSelection();
        } else {
          _selectedWorkflowScopeId = null;
          _workflowDraftSteps = _cloneWorkflowSteps(_globalWorkflowSteps);
        }
        _syncWorkflowStateWithScopes();
      });
    } catch (e) {
      if (!mounted) return;
      // Show user-friendly message instead of raw Firestore internals
      final msg = e.toString().contains('INTERNAL ASSERTION')
          ? 'Network glitch while loading workflow — please refresh the page.'
          : 'Unable to load procurement workflow. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) {
        setState(() => _workflowLoading = false);
      }
    }
  }

  bool _scopeRequiresProcurementWorkflow(ProcurementItemModel item) {
    final value = item.responsibleMember.trim().toLowerCase();
    if ((item.vendorId ?? '').trim().isNotEmpty) return false;
    if (value == 'no' || value.startsWith('no ')) return false;
    if (value == 'not required' || value == 'none') return false;
    final potentialVendors = item.notes
        .replaceAll('\n', ',')
        .replaceAll(';', ',')
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
    if (potentialVendors.length == 1) {
      return false;
    }
    return true;
  }

  ProcurementItemModel? _findWorkflowScopeById(String? scopeId) {
    if (scopeId == null || scopeId.isEmpty) return null;
    for (final item in _items) {
      if (item.id == scopeId) return item;
    }
    return null;
  }

  String? _resolveWorkflowScopeId() {
    if (_items.isEmpty) return null;
    if (_selectedWorkflowScopeId != null &&
        _items.any((item) => item.id == _selectedWorkflowScopeId)) {
      return _selectedWorkflowScopeId;
    }
    return _items.first.id;
  }

  int _totalWorkflowDurationInWeeks(List<ProcurementWorkflowStep> steps) {
    var total = 0;
    for (final step in steps) {
      final duration = step.duration <= 0 ? 1 : step.duration;
      total += step.unit == 'month' ? duration * 4 : duration;
    }
    return total;
  }

  void _hydrateWorkflowDraftForSelection() {
    if (!_customizeWorkflowByScope) {
      _workflowDraftSteps = _cloneWorkflowSteps(_globalWorkflowSteps);
      return;
    }

    final scopeId = _resolveWorkflowScopeId();
    if (scopeId == null) {
      _selectedWorkflowScopeId = null;
      _workflowDraftSteps = <ProcurementWorkflowStep>[];
      return;
    }

    _selectedWorkflowScopeId = scopeId;
    final scoped = _scopeWorkflowOverrides[scopeId];
    if (scoped != null) {
      _workflowDraftSteps = _cloneWorkflowSteps(scoped);
    } else {
      _workflowDraftSteps = _cloneWorkflowSteps(_globalWorkflowSteps);
    }
  }

  void _syncWorkflowStateWithScopes() {
    final validScopeIds = _items
        .map((item) => item.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    _scopeWorkflowOverrides =
        Map<String, List<ProcurementWorkflowStep>>.from(_scopeWorkflowOverrides)
          ..removeWhere((scopeId, _) => !validScopeIds.contains(scopeId));

    var shouldHydrate = false;
    if (_customizeWorkflowByScope) {
      final resolved = _resolveWorkflowScopeId();
      if (_selectedWorkflowScopeId != resolved) {
        _selectedWorkflowScopeId = resolved;
        shouldHydrate = true;
      }
    } else if (_workflowDraftSteps.isEmpty) {
      shouldHydrate = true;
    }

    if (shouldHydrate) {
      _hydrateWorkflowDraftForSelection();
    }
  }

  void _setCustomizeWorkflowByScope(bool value) {
    setState(() {
      _customizeWorkflowByScope = value;
      if (!value) {
        _selectedWorkflowScopeId = null;
      }
      _hydrateWorkflowDraftForSelection();
    });
  }

  void _selectWorkflowScope(String scopeId) {
    setState(() {
      _selectedWorkflowScopeId = scopeId;
      _hydrateWorkflowDraftForSelection();
    });
  }

  void _resetWorkflowDraftToPreset() {
    setState(() {
      _workflowDraftSteps =
          _cloneWorkflowSteps(_defaultProcurementWorkflowTemplate);
    });
  }

  Future<ProcurementWorkflowStep?> _showWorkflowStepDialog({
    ProcurementWorkflowStep? initialStep,
  }) async {
    final nameController = TextEditingController(text: initialStep?.name ?? '');
    final durationController = TextEditingController(
      text: (initialStep?.duration ?? 1).toString(),
    );
    var unit = initialStep?.unit == 'month' ? 'month' : 'week';

    final result = await showDialog<ProcurementWorkflowStep>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(initialStep == null ? 'Add Workflow Step' : 'Edit Step'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Step name',
                    hintText: 'e.g. Quote Evaluation',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Duration'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: const [
                          DropdownMenuItem(value: 'week', child: Text('Week')),
                          DropdownMenuItem(
                            value: 'month',
                            child: Text('Month'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => unit = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final duration = int.tryParse(durationController.text.trim()) ??
                    initialStep?.duration ??
                    1;
                if (name.isEmpty || duration <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Provide a step name and valid duration.'),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(
                  ProcurementWorkflowStep(
                    id: initialStep?.id ??
                        'wf_${DateTime.now().microsecondsSinceEpoch}',
                    name: name,
                    duration: duration,
                    unit: unit,
                  ),
                );
              },
              child: Text(initialStep == null ? 'Add Step' : 'Save'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    durationController.dispose();
    return result;
  }

  Future<void> _addWorkflowStepToDraft() async {
    final result = await _showWorkflowStepDialog();
    if (result == null) return;
    setState(() => _workflowDraftSteps = [..._workflowDraftSteps, result]);
  }

  Future<void> _editWorkflowStep(ProcurementWorkflowStep step) async {
    final result = await _showWorkflowStepDialog(initialStep: step);
    if (result == null) return;

    setState(() {
      final next = List<ProcurementWorkflowStep>.from(_workflowDraftSteps);
      final index = next.indexWhere((entry) => entry.id == step.id);
      if (index == -1) return;
      next[index] = result.copyWith(id: step.id);
      _workflowDraftSteps = next;
    });
  }

  void _deleteWorkflowStepFromDraft(String stepId) {
    setState(() {
      _workflowDraftSteps =
          _workflowDraftSteps.where((step) => step.id != stepId).toList();
    });
  }

  void _moveWorkflowStepInDraft(int index, int direction) {
    final target = index + direction;
    if (index < 0 ||
        index >= _workflowDraftSteps.length ||
        target < 0 ||
        target >= _workflowDraftSteps.length) {
      return;
    }

    setState(() {
      final next = List<ProcurementWorkflowStep>.from(_workflowDraftSteps);
      final step = next.removeAt(index);
      next.insert(target, step);
      _workflowDraftSteps = next;
    });
  }

  void _saveWorkflowForSelection() {
    if (_workflowSaving) return;
    if (_customizeWorkflowByScope) {
      final scopeId = _resolveWorkflowScopeId();
      if (scopeId == null) return;
      setState(() {
        _scopeWorkflowOverrides = {
          ..._scopeWorkflowOverrides,
          scopeId: _cloneWorkflowSteps(_workflowDraftSteps),
        };
      });
    } else {
      setState(() {
        _globalWorkflowSteps = _cloneWorkflowSteps(_workflowDraftSteps);
        _scopeWorkflowOverrides = {};
      });
    }
    _persistProcurementWorkflowData(
      successMessage: _customizeWorkflowByScope
          ? 'Saved workflow for selected scope.'
          : 'Saved global procurement workflow.',
    );
  }

  void _applyWorkflowDraftToAllScopes() {
    if (_workflowSaving) return;
    final normalized = _cloneWorkflowSteps(_workflowDraftSteps);
    setState(() {
      _globalWorkflowSteps = _cloneWorkflowSteps(normalized);
      final next = <String, List<ProcurementWorkflowStep>>{};
      for (final item in _items) {
        if (!_scopeRequiresProcurementWorkflow(item)) {
          continue;
        }
        next[item.id] = _cloneWorkflowSteps(normalized);
      }
      _scopeWorkflowOverrides = next;
      _customizeWorkflowByScope = false;
      _selectedWorkflowScopeId = null;
      _hydrateWorkflowDraftForSelection();
    });
    _persistProcurementWorkflowData(
      successMessage: 'Applied workflow to all scopes requiring bidding.',
    );
  }

  Future<void> _persistProcurementWorkflowData({
    required String successMessage,
  }) async {
    if (_projectId.isEmpty) return;
    setState(() => _workflowSaving = true);

    try {
      await ProcurementWorkflowService.save(
        projectId: _projectId,
        globalSteps: _globalWorkflowSteps,
        scopeOverrides: _scopeWorkflowOverrides,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save procurement workflow: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _workflowSaving = false);
      }
    }
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.supporting,
  });

  final String label;
  final String value;
  final String supporting;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.card});

  final _SummaryCardData card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            card.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            card.supporting,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  const _PurchaseOrderCard({
    required this.po,
    required this.projectOwnerName,
    required this.onSubmit,
    required this.onReview,
    required this.onEscalate,
  });

  final PurchaseOrderModel po;
  final String projectOwnerName;
  final VoidCallback onSubmit;
  final VoidCallback onReview;
  final VoidCallback onEscalate;

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(symbol: '\$', decimalDigits: 0)
        .format(po.amount);
    final isPending = po.approvalStatus == 'pending';
    final canSubmit =
        po.approvalStatus == 'draft' || po.approvalStatus == 'rejected';
    final canReview = isPending || po.approvalStatus == 'escalated';
    final showEscalate = isPending || po.isEscalated;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PO #${po.poNumber}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      po.vendorName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
              _ApprovalStatusBadge(status: po.approvalStatusDisplay),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PurchaseInfoChip(
                icon: Icons.category_outlined,
                label: po.category,
              ),
              _PurchaseInfoChip(icon: Icons.payments_outlined, label: amount),
              _PurchaseInfoChip(
                icon: Icons.local_shipping_outlined,
                label: po.status.label,
              ),
              _PurchaseInfoChip(
                icon: Icons.person_outline,
                label: po.approverName?.trim().isNotEmpty == true
                    ? po.approverName!
                    : projectOwnerName,
              ),
            ],
          ),
          if (po.rejectionReason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              'Rejection reason: ${po.rejectionReason!.trim()}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
            ),
          ],
          if (po.approverComments?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              'Approver comments: ${po.approverComments!.trim()}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
          ],
          if (po.daysUntilEscalation != null) ...[
            const SizedBox(height: 8),
            Text(
              po.daysUntilEscalation == 0
                  ? 'Approval is overdue and ready for escalation.'
                  : 'Escalation deadline in ${po.daysUntilEscalation} day${po.daysUntilEscalation == 1 ? '' : 's'}.',
              style: TextStyle(
                fontSize: 12,
                color: po.daysUntilEscalation == 0
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF92400E),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (canSubmit)
                ElevatedButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Submit for Approval'),
                ),
              if (canReview)
                OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.approval_outlined, size: 16),
                  label: const Text('Review'),
                ),
              if (showEscalate)
                TextButton.icon(
                  onPressed: onEscalate,
                  icon: const Icon(Icons.priority_high_rounded, size: 16),
                  label: const Text('Escalate'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApprovalStatusBadge extends StatelessWidget {
  const _ApprovalStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color border;
    late final Color foreground;

    switch (status.toLowerCase()) {
      case 'approved':
        background = const Color(0xFFDCFCE7);
        border = const Color(0xFF86EFAC);
        foreground = const Color(0xFF15803D);
        break;
      case 'rejected':
        background = const Color(0xFFFEE2E2);
        border = const Color(0xFFFCA5A5);
        foreground = const Color(0xFFB91C1C);
        break;
      case 'overdue':
      case 'escalated':
        background = const Color(0xFFFFEDD5);
        border = const Color(0xFFFDBA74);
        foreground = const Color(0xFFC2410C);
        break;
      case 'pending':
      default:
        background = const Color(0xFFDBEAFE);
        border = const Color(0xFF93C5FD);
        foreground = const Color(0xFF1D4ED8);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _PurchaseInfoChip extends StatelessWidget {
  const _PurchaseInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}

class _VendorComparisonContractCard extends StatelessWidget {
  const _VendorComparisonContractCard({
    required this.contract,
    required this.rfqs,
  });

  final planning_contracts.ContractModel contract;
  final List<PlanningRfq> rfqs;

  @override
  Widget build(BuildContext context) {
    final scores = contract.evaluationScores ?? const <EvaluationScore>[];
    final selectedRfq = _selectedRfqForContract(contract, rfqs);
    final criteria = selectedRfq?.evaluationCriteria ?? const <EvaluationCriteria>[];
    final vendors = _vendorCandidatesForEvaluation(contract, selectedRfq);
    final technicalScreenings = _technicalScreeningMap(contract);
    final passedVendors = vendors
        .where(
          (vendor) =>
              (technicalScreenings[vendor]?.status ?? 'Pending').toLowerCase() ==
              'passed',
        )
        .toList();
    final ranking = _rankVendors(passedVendors, criteria, scores);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contract.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PurchaseInfoChip(
                icon: Icons.rule_folder_outlined,
                label: selectedRfq?.title ?? 'No linked RFQ',
              ),
              _PurchaseInfoChip(
                icon: Icons.fact_check_outlined,
                label: '${criteria.length} criteria',
              ),
              _PurchaseInfoChip(
                icon: Icons.groups_outlined,
                label: '${passedVendors.length} vendors passed technical',
              ),
              if ((contract.recommendedVendor ?? '').trim().isNotEmpty)
                _PurchaseInfoChip(
                  icon: Icons.emoji_events_outlined,
                  label: contract.recommendedVendor!.trim(),
                ),
            ],
          ),
          const SizedBox(height: 14),
          VendorComparisonTable(
            ranking: ranking,
            criteria: criteria,
            recommendedVendor: contract.recommendedVendor,
            summary: contract.vendorComparisonSummary,
          ),
        ],
      ),
    );
  }
}

class _ProcurementItemCard extends StatelessWidget {
  const _ProcurementItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onLinkSchedule,
    required this.onClearSchedule,
  });

  final ProcurementItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLinkSchedule;
  final VoidCallback? onClearSchedule;

  @override
  Widget build(BuildContext context) {
    final requiredBy = item.requiredByDate != null
        ? DateFormat('MMM dd, yyyy').format(item.requiredByDate!)
        : 'Not linked';
    final milestoneLabel = item.linkedMilestoneId?.trim().isNotEmpty == true
        ? item.linkedMilestoneId!
        : 'No milestone';
    final wbsLabel =
        item.linkedWbsId?.trim().isNotEmpty == true ? item.linkedWbsId! : 'No WBS';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _ApprovalStatusBadge(status: item.status.label),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PurchaseInfoChip(
                icon: Icons.category_outlined,
                label: item.category,
              ),
              _PurchaseInfoChip(
                icon: Icons.flag_outlined,
                label: item.priority.label,
              ),
              _PurchaseInfoChip(
                icon: Icons.attach_money_outlined,
                label: NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                    .format(item.budget),
              ),
              _PurchaseInfoChip(
                icon: Icons.person_outline,
                label: item.responsibleMember.trim().isEmpty
                    ? 'Unassigned'
                    : item.responsibleMember.trim(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PurchaseInfoChip(
                icon: Icons.account_tree_outlined,
                label: wbsLabel,
              ),
              _PurchaseInfoChip(
                icon: Icons.event_outlined,
                label: milestoneLabel,
              ),
              _PurchaseInfoChip(
                icon: Icons.schedule_outlined,
                label: requiredBy,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: onLinkSchedule,
                icon: const Icon(Icons.link_outlined, size: 16),
                label: const Text('Link Schedule'),
              ),
              if (onClearSchedule != null)
                TextButton.icon(
                  onPressed: onClearSchedule,
                  icon: const Icon(Icons.link_off_outlined, size: 16),
                  label: const Text('Clear Link'),
                ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

PlanningRfq? _selectedRfqForContract(
  planning_contracts.ContractModel contract,
  List<PlanningRfq> rfqs,
) {
  if (rfqs.isEmpty) return null;
  final linkedRfqId = contract.linkedRfqId ?? '';
  for (final rfq in rfqs) {
    if (rfq.id == linkedRfqId) return rfq;
  }
  return rfqs.first;
}

List<String> _vendorCandidatesForEvaluation(
  planning_contracts.ContractModel contract,
  PlanningRfq? rfq,
) {
  final vendors = <String>{
    ...?rfq?.invitedContractors,
    ...(contract.evaluationScores ?? const [])
        .map((score) => score.vendorName)
        .where((name) => name.trim().isNotEmpty),
    ...(contract.technicalScreenings ?? const [])
        .map((item) => item.vendorName)
        .where((name) => name.trim().isNotEmpty),
    if ((contract.recommendedVendor ?? '').trim().isNotEmpty)
      contract.recommendedVendor!.trim(),
  };
  final list = vendors.toList()..sort();
  return list;
}

Map<String, VendorTechnicalScreening> _technicalScreeningMap(
  planning_contracts.ContractModel contract,
) {
  return {
    for (final item in contract.technicalScreenings ?? const [])
      item.vendorName: item,
  };
}

double _weightedVendorScore(
  String vendor,
  List<EvaluationCriteria> criteria,
  List<EvaluationScore> scores,
) {
  var total = 0.0;
  for (final criterion in criteria) {
    final matchingScore = scores.where((score) {
      return score.vendorName == vendor && score.criteriaId == criterion.id;
    }).toList();
    if (matchingScore.isEmpty) continue;
    total += matchingScore.last.score * (criterion.weight / 100);
  }
  return total;
}

List<MapEntry<String, double>> _rankVendors(
  List<String> vendors,
  List<EvaluationCriteria> criteria,
  List<EvaluationScore> scores,
) {
  final ranking = vendors
      .map((vendor) => MapEntry(
            vendor,
            _weightedVendorScore(vendor, criteria, scores),
          ))
      .toList();
  ranking.sort((a, b) => b.value.compareTo(a.value));
  return ranking;
}
