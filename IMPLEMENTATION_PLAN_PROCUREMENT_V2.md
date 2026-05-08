# Planning Phase Procurement Screen Rebuild - Implementation Plan

## Executive Summary

Rebuild the Planning Phase Procurement screen as a dedicated 8-tab interface that:
1. **Reuses** data models and Firestore collections from FEP procurement
2. **Extracts** shared widgets from `FrontEndPlanningProcurementScreen` for code reuse
3. **Integrates** live contracting data from both planning contracts and procurement contracts
4. **Links** procurement items to WBS/schedule milestones with auto-update capability
5. **Seeds** procurement items automatically from contracting packages
6. **Removes** the reports gating (always accessible in planning phase)

---

## Phase 1: Data Model Extensions

### 1.1 Extend PurchaseOrderModel

**File:** `lib/models/procurement/procurement_models.dart`

```dart
class PurchaseOrderModel {
  // ... existing fields

  // NEW: Approval workflow fields
  String? approverId;
  String? approverName;
  DateTime? approvalDate;
  String approvalStatus; // 'draft', 'pending', 'approved', 'rejected', 'escalated'
  String? rejectionReason;
  String? approverComments;
  int escalationDays; // Configurable per PO, default 3
  String? escalationTargetId;

  const PurchaseOrderModel({
    // ... existing parameters
    this.approverId,
    this.approverName,
    this.approvalDate,
    this.approvalStatus = 'draft',
    this.rejectionReason,
    this.approverComments,
    this.escalationDays = 3,
    this.escalationTargetId,
  });

  PurchaseOrderModel copyWith({
    // ... existing parameters
    String? approverId,
    String? approverName,
    DateTime? approvalDate,
    String? approvalStatus,
    String? rejectionReason,
    String? approverComments,
    int? escalationDays,
    String? escalationTargetId,
  }) {
    return PurchaseOrderModel(
      // ... existing fields
      approverId: approverId ?? this.approverId,
      approverName: approverName ?? this.approverName,
      approvalDate: approvalDate ?? this.approvalDate,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approverComments: approverComments ?? this.approverComments,
      escalationDays: escalationDays ?? this.escalationDays,
      escalationTargetId: escalationTargetId ?? this.escalationTargetId,
    );
  }

  Map<String, dynamic> toMap() => {
        // ... existing fields
        'approverId': approverId,
        'approverName': approverName,
        'approvalDate': approvalDate != null
            ? Timestamp.fromDate(approvalDate!)
            : null,
        'approvalStatus': approvalStatus,
        'rejectionReason': rejectionReason,
        'approverComments': approverComments,
        'escalationDays': escalationDays,
        'escalationTargetId': escalationTargetId,
      };

  // Update fromDoc to parse new fields
}

// Helper: Check if PO is overdue for approval
extension PurchaseOrderApprovalExtension on PurchaseOrderModel {
  bool get isPendingApproval =>
      approvalStatus == 'pending' &&
      (approvalDate == null ||
          DateTime.now().isAfter(
              approvalDate!.add(Duration(days: escalationDays))));

  bool get isEscalated => approvalStatus == 'escalated';

  String get approvalStatusDisplay {
    if (isEscalated) return 'Escalated';
    if (approvalStatus == 'pending' && isPendingApproval) return 'Overdue';
    return approvalStatus.capitalize();
  }
}
```

### 1.2 Extend ProcurementItemModel

**File:** `lib/models/procurement/procurement_models.dart`

```dart
class ProcurementItemModel {
  // ... existing fields

  // NEW: Schedule linkage fields
  String? linkedWbsId;        // Links to ScheduleActivity.wbsId
  String? linkedMilestoneId;  // Links to ScheduleActivity.id
  DateTime? requiredByDate;   // Derived from milestone, manual override

  const ProcurementItemModel({
    // ... existing parameters
    this.linkedWbsId,
    this.linkedMilestoneId,
    this.requiredByDate,
  });

  // Update copyWith, toMap, fromDoc
}

// Helper: Calculate committed amount from linked POs
extension ProcurementItemBudgetExtension on ProcurementItemModel {
  double committedAmount(List<PurchaseOrderModel> allPos) {
    return allPos
        .where((po) => po.vendorId != null && po.status == PurchaseOrderStatus.issued)
        .fold(0.0, (sum, po) => sum + po.amount);
  }

  double remainingBudget(double committed) => budget - spent - committed;

  double variancePercent(double committed) {
    if (budget == 0) return 0;
    return ((spent + committed - budget) / budget * 100);
  }

  String budgetStatus(double committed) {
    final variance = variancePercent(committed);
    if (variance > 10) return 'over';
    if (variance > -10) return 'within';
    return 'under';
  }
}
```

---

## Phase 2: Service Layer Updates

### 2.1 Extend ProcurementService

**File:** `lib/services/procurement_service.dart`

```dart
class ProcurementService {
  // ... existing methods

  // NEW: Approval workflow methods
  static Future<void> submitForApproval(
    String projectId,
    String poId,
    String approverId,
    String approverName,
    int escalationDays,
  ) async {
    await _posCol(projectId).doc(poId).update({
      'approvalStatus': 'pending',
      'approverId': approverId,
      'approverName': approverName,
      'approvalDate': FieldValue.serverTimestamp(),
      'escalationDays': escalationDays,
    });
  }

  static Future<void> approvePo(
    String projectId,
    String poId,
    String comments,
  ) async {
    await _posCol(projectId).doc(poId).update({
      'approvalStatus': 'approved',
      'status': 'issued', // Also update PO status
      'approverComments': comments,
      'approvalDate': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> rejectPo(
    String projectId,
    String poId,
    String reason,
  ) async {
    await _posCol(projectId).doc(poId).update({
      'approvalStatus': 'rejected',
      'status': 'draft',
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> escalatePo(
    String projectId,
    String poId,
    String escalationTargetId,
  ) async {
    await _posCol(projectId).doc(poId).update({
      'approvalStatus': 'escalated',
      'escalationTargetId': escalationTargetId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // NEW: Get POs with approval status filtering
  static Stream<List<PurchaseOrderModel>> streamPendingApprovals(
    String projectId,
  ) {
    return _posCol(projectId)
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PurchaseOrderModel.fromDoc(doc))
            .toList());
  }

  // NEW: Schedule-linked items
  static Future<void> updateItemScheduleLink(
    String projectId,
    String itemId,
    String? wbsId,
    String? milestoneId,
    DateTime? requiredBy,
  ) async {
    await _itemsCol(projectId).doc(itemId).update({
      'linkedWbsId': wbsId,
      'linkedMilestoneId': milestoneId,
      'requiredByDate': requiredBy != null
          ? Timestamp.fromDate(requiredBy)
          : FieldValue.delete(),
    });
  }
}
```

### 2.2 Create ScheduleLinkageService (New)

**File:** `lib/services/schedule_linkage_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/procurement_service.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

/// Manages linkage between procurement items and schedule milestones
class ScheduleLinkageService {
  /// Update procurement items when linked milestone dates change
  static Future<void> syncRequiredByDates(
    BuildContext context,
    List<ScheduleActivity> updatedActivities,
  ) async {
    final data = ProjectDataHelper.getData(context);

    for (final activity in updatedActivities) {
      if (!activity.isMilestone) continue;

      // Find items linked to this milestone
      final items = await ProcurementService.streamItems(data.id).first;
      final linkedItems = items
          .where((item) => item.linkedMilestoneId == activity.id)
          .toList();

      for (final item in linkedItems) {
        final newDate = DateTime.tryParse(activity.dueDate);
        if (newDate != null) {
          await ProcurementService.updateItemScheduleLink(
            data.id,
            item.id,
            item.linkedWbsId,
            activity.id,
            newDate,
          );
        }
      }
    }
  }

  /// Get available milestones for linking
  static List<ScheduleActivity> getMilestones(ProjectDataModel data) {
    return data.scheduleActivities
        .where((a) => a.isMilestone && a.dueDate.isNotEmpty)
        .toList();
  }

  /// Get WBS elements for linking
  static List<ScheduleActivity> getWbsElements(ProjectDataModel data) {
    return data.scheduleActivities
        .where((a) => a.wbsId.isNotEmpty)
        .toList();
  }
}
```

---

## Phase 3: Shared Widget Extraction

Extract these widgets from `FrontEndPlanningProcurementScreen` into reusable components:

### 3.1 Create Widget Files

| Widget | File | Purpose |
|--------|------|---------|
| `ProcurementTimelineView` | `lib/widgets/procurement/procurement_timeline_view.dart` | Gantt-like timeline with milestone markers |
| `VendorComparisonTable` | `lib/widgets/procurement/vendor_comparison_table.dart` | Side-by-side vendor scoring |
| `BudgetTrackingTable` | `lib/widgets/procurement/budget_tracking_table.dart` | Budget vs actual with variance |
| `ProcurementWorkflowBuilder` | `lib/widgets/procurement/procurement_workflow_builder.dart` | Configurable workflow steps |
| `PoApprovalDialog` | `lib/widgets/procurement/po_approval_dialog.dart` | PO approval/rejection UI |
| `ProcurementKpiCards` | `lib/widgets/procurement/procurement_kpi_cards.dart` | KPI metrics display |

### 3.2 Extraction Pattern

```dart
// Before: Inline in FrontEndPlanningProcurementScreen
Widget _buildTimeline() { /* 500+ lines */ }

// After: Reusable widget
class ProcurementTimelineView extends StatelessWidget {
  final List<ProcurementItemModel> items;
  final List<ScheduleActivity> milestones;
  final ValueChanged<ProcurementItemModel>? onItemTap;

  const ProcurementTimelineView({
    required this.items,
    required this.milestones,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    // Extracted timeline logic
  }
}
```

---

## Phase 4: Auto-Seed Service

### 4.1 Create ProcurementSeedingService

**File:** `lib/services/procurement_seeding_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndu_project/models/planning_contracting_models.dart';
import 'package:ndu_project/models/procurement/procurement_models.dart';
import 'package:ndu_project/services/planning_contracting_service.dart';
import 'package:ndu_project/services/procurement_service.dart';

/// Handles automatic seeding of procurement items from contracting data
class ProcurementSeedingService {
  static const String _seededFlagKey =
      'procurement_auto_seeded_from_contracting';

  /// Check if seeding has already occurred
  static bool hasSeeded(ProjectDataModel data) {
    return data.planningNotes[_seededFlagKey] == 'true';
  }

  /// Mark project as seeded
  static Future<void> markSeeded(BuildContext context) async {
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'procurement',
      dataUpdater: (data) => data.copyWith(
        planningNotes: {...data.planningNotes, _seededFlagKey: 'true'},
      ),
    );
  }

  /// Seed procurement items from contracting data
  static Future<int> seedFromContracting(
    BuildContext context, {
    bool force = false,
  }) async {
    final data = ProjectDataHelper.getData(context);

    if (!force && hasSeeded(data)) {
      return 0; // Already seeded
    }

    final projectId = data.id;
    int createdCount = 0;

    // 1. Fetch planning RFQs (contracting packages)
    final rfqs = await PlanningContractingService.streamRfqs(projectId).first;

    // 2. Fetch contracts
    final contracts = await ProcurementService.streamContracts(projectId).first;

    // 3. Create procurement items from RFQ scopes
    for (final rfq in rfqs) {
      if (rfq.status == 'Closed' || rfq.status == 'Awarded') {
        // Create procurement item for awarded contract
        final item = ProcurementItemModel(
          id: '',
          projectId: projectId,
          name: rfq.title,
          description: rfq.scopeOfWork,
          category: _inferCategory(rfq.title),
          status: ProcurementItemStatus.planning,
          priority: _inferPriority(rfq),
          budget: rfq.budgetAmount ?? 0.0,
          contractId: rfq.id,
          responsibleMember: rfq.contractManager ?? '',
          notes: 'Auto-seeded from contracting package: ${rfq.title}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await ProcurementService.createItem(item);
        createdCount++;
      }
    }

    // 4. Create procurement items from contracts
    for (final contract in contracts) {
      // Skip if already created from RFQ
      final existingItems = await ProcurementService.streamItems(
        projectId,
      ).first;
      if (existingItems.any((i) => i.contractId == contract.id)) {
        continue;
      }

      final item = ProcurementItemModel(
        id: '',
        projectId: projectId,
        name: contract.title,
        description: contract.description,
        category: _inferCategory(contract.title),
        status: ProcurementItemStatus.planning,
        priority: ProcurementPriority.medium,
        budget: contract.estimatedCost,
        contractId: contract.id,
        responsibleMember: contract.owner,
        notes: 'Auto-seeded from contract: ${contract.title}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ProcurementService.createItem(item);
      createdCount++;
    }

    // 5. Mark as seeded
    if (createdCount > 0) {
      await markSeeded(context);
    }

    return createdCount;
  }

  static String _inferCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('it') || lower.contains('software') || lower.contains('tech')) {
      return 'IT Equipment';
    }
    if (lower.contains('construct') || lower.contains('facil') || lower.contains('build')) {
      return 'Construction Services';
    }
    if (lower.contains('office') || lower.contains('furn')) {
      return 'Office & Workspace';
    }
    if (lower.contains('consult') || lower.contains('profess')) {
      return 'Professional Services';
    }
    return 'General Procurement';
  }

  static ProcurementPriority _inferPriority(PlanningRfq rfq) {
    // Use evaluation criteria count as proxy for complexity/priority
    if (rfq.evaluationCriteria.length > 5) {
      return ProcurementPriority.high;
    }
    if (rfq.submissionDeadline != null &&
        DateTime.now().difference(rfq.submissionDeadline!).inDays < 30) {
      return ProcurementPriority.critical;
    }
    return ProcurementPriority.medium;
  }
}
```

---

## Phase 5: Main Screen Implementation

### 5.1 Create PlanningProcurementV2Screen

**File:** `lib/screens/planning_procurement_v2_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/services/procurement_service.dart';
import 'package:ndu_project/services/planning_contracting_service.dart';
import 'package:ndu_project/services/procurement_seeding_service.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

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

class _PlanningProcurementV2ScreenState extends State<PlanningProcurementV2Screen> {
  int _selectedTab = 0;

  static const _tabLabels = [
    'Overview',
    'Procurement Items',
    'Timeline',
    'Vendor Comparison',
    'Purchase Orders',
    'Budget Tracking',
    'Workflows',
    'Reports',
  ];

  late final String _projectId;
  List<ProcurementItemModel> _items = [];
  List<PurchaseOrderModel> _pos = [];
  List<PlanningRfq> _rfqs = [];
  List<ContractModel> _contracts = [];

  @override
  void initState() {
    super.initState();
    _projectId = ProjectDataHelper.getData(context).id;
    _subscribeToData();
    _checkAutoSeed();
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
                activeItemLabel: 'Procurement',
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
                            vertical: isMobile ? 20 : 36,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Header(onContracting: () => _openContracting()),
                              const SizedBox(height: 28),
                              _TabBar(
                                labels: _tabLabels,
                                selectedIndex: _selectedTab,
                                onSelected: (i) =>
                                    setState(() => _selectedTab = i),
                              ),
                              const SizedBox(height: 28),
                              _buildTabContent(),
                              const SizedBox(height: 100),
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

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0: return _OverviewTab(items: _items, rfqs: _rfqs, contracts: _contracts);
      case 1: return _ItemsTab(items: _items, onRefresh: _refreshData);
      case 2: return _TimelineTab(items: _items);
      case 3: return _VendorComparisonTab(items: _items);
      case 4: return _PurchaseOrdersTab(pos: _pos);
      case 5: return _BudgetTrackingTab(items: _items, pos: _pos);
      case 6: return _WorkflowsTab();
      case 7: return _ReportsTab(items: _items, pos: _pos);
      default: return const SizedBox.shrink();
    }
  }

  void _subscribeToData() {
    // Stream items, POs, RFQs, contracts
    ProcurementService.streamItems(_projectId).listen((items) {
      if (mounted) setState(() => _items = items);
    });
    ProcurementService.streamPos(_projectId).listen((pos) {
      if (mounted) setState(() => _pos = pos);
    });
    PlanningContractingService.streamRfqs(_projectId).listen((rfqs) {
      if (mounted) setState(() => _rfqs = rfqs);
    });
    ProcurementService.streamContracts(_projectId).listen((contracts) {
      if (mounted) setState(() => _contracts = contracts);
    });
  }

  Future<void> _checkAutoSeed() async {
    final data = ProjectDataHelper.getData(context);
    if (!ProcurementSeedingService.hasSeeded(data) && _items.isEmpty) {
      final count = await ProcurementSeedingService.seedFromContracting(context);
      if (count > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count items from contracting')),
        );
      }
    }
  }

  void _refreshData() {
    // Trigger refresh
  }

  void _openContracting() {
    Navigator.of(context).pop(); // Or navigate to contracting
  }
}

// Tab widgets...
```

### 5.2 Tab Contents Overview

| Tab | Key Components | Data Sources |
|-----|----------------|--------------|
| **Overview** | Summary dashboard, Contracting context, Procurement plan AI, Items preview | `items`, `rfqs`, `contracts`, `ProjectDataModel` |
| **Items** | CRUD table, Schedule linkage dropdown, Responsible member picker | `items`, `scheduleActivities` |
| **Timeline** | `ProcurementTimelineView`, milestone markers, filter controls | `items`, `scheduleActivities` |
| **Vendor Comparison** | `VendorComparisonTable`, weighted scoring | `vendors`, `items` |
| **Purchase Orders** | PO table, `PoApprovalDialog`, escalation banner | `pos`, `project team` |
| **Budget Tracking** | `BudgetTrackingTable`, category grouping, variance charts | `items`, `pos` |
| **Workflows** | `ProcurementWorkflowBuilder`, scope-specific toggles | `procurement_workflows` collection |
| **Reports** | `ProcurementKpiCards`, always accessible (no gate) | `items`, `pos`, `vendors` |

---

## Phase 6: Navigation Updates

### 6.1 Update PlanningProcurementScreen (Route)

**File:** `lib/screens/planning_procurement_screen.dart`

```dart
class PlanningProcurementScreen extends StatelessWidget {
  const PlanningProcurementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlanningProcurementV2Screen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Direct to new screen
    return const PlanningProcurementV2Screen();
  }
}
```

### 6.2 Update NavigationRouteResolver

**File:** `lib/utils/navigation_route_resolver.dart`

No changes needed - existing `'procurement'` case already routes to `PlanningProcurementScreen`.

### 6.3 Update ProjectRouteRegistry

**File:** `lib/services/project_route_registry.dart`

```dart
static final Map<String, Widget Function()> _screens = {
  // ... existing
  'procurement': () => const PlanningProcurementV2Screen(),
};
```

---

## Implementation Order

### Sprint 1: Foundation (Days 1-3)
1. ✅ Extend `PurchaseOrderModel` with approval fields
2. ✅ Extend `ProcurementItemModel` with schedule linkage
3. ✅ Add approval methods to `ProcurementService`
4. ✅ Create `ScheduleLinkageService`

### Sprint 2: Shared Widgets (Days 4-6)
5. ✅ Extract `ProcurementTimelineView` widget
6. ✅ Extract `VendorComparisonTable` widget
7. ✅ Extract `BudgetTrackingTable` widget
8. ✅ Extract `ProcurementWorkflowBuilder` widget
9. ✅ Create `PoApprovalDialog` widget

### Sprint 3: Services (Days 7-8)
10. ✅ Create `ProcurementSeedingService`
11. ✅ Implement auto-seed from contracting logic
12. ✅ Add seeded flag tracking in project notes

### Sprint 4: Screen Scaffold (Day 9)
13. ✅ Create `PlanningProcurementV2Screen` scaffold
14. ✅ Implement tab bar and navigation
15. ✅ Set up data streams

### Sprint 5: Tab Implementation (Days 10-15)
16. ✅ Overview Tab (dashboard + contracting context)
17. ✅ Items Tab (CRUD + schedule linkage)
18. ✅ Timeline Tab (visual scheduling)
19. ✅ Vendor Comparison Tab
20. ✅ Purchase Orders Tab (approval workflow)
21. ✅ Budget Tracking Tab
22. ✅ Workflows Tab
23. ✅ Reports Tab (ungated)

### Sprint 6: Integration & Polish (Days 16-18)
24. ✅ Wire navigation updates
25. ✅ Implement schedule auto-update listener
26. ✅ Add PO escalation notifications
27. ✅ Testing and bug fixes

---

## Testing Checklist

- [ ] Auto-seed creates items from contracting packages
- [ ] Seeding flag prevents duplicate imports
- [ ] Schedule milestone changes update item requiredByDate
- [ ] PO approval workflow: draft → pending → approved/issued
- [ ] PO escalation appears after configured days
- [ ] Budget committed calculation sums issued POs correctly
- [ ] Timeline shows milestone markers from schedule
- [ ] Vendor comparison weighted scoring works
- [ ] Reports tab is always accessible (no gate)
- [ ] All CRUD operations persist to Firestore correctly
- [ ] Navigation flows to/from contracting screen

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| FEP widget extraction breaks existing screen | Comprehensive regression testing of FEP procurement |
| Schedule linkage fails if WBS empty | Graceful fallback to manual date entry |
| Auto-seed creates duplicate items | Seeded flag + contractId deduplication check |
| PO approval workflow lacks approvers | Default to project owner, allow reassignment |
| Timeline performance with many items | Pagination limit, lazy loading |

---

## Dependencies

```
PlanningProcurementV2Screen
├── InitiationLikeSidebar (existing)
├── DraggableSidebar (existing)
├── ProcurementService (extend)
├── PlanningContractingService (existing)
├── ProcurementSeedingService (new)
├── ScheduleLinkageService (new)
├── CurrencyService (new)
├── ProjectDataHelper (existing)
├── ProcurementTimelineView (extracted, uses syncfusion_flutter_ganttage)
├── VendorComparisonTable (extracted)
├── BudgetTrackingTable (extracted)
├── ProcurementWorkflowBuilder (extracted)
└── PoApprovalDialog (new)
```

### pubspec.yaml Additions

```yaml
dependencies:
  syncfusion_flutter_ganttage: ^24.1.41  # Timeline/Gantt chart
```

### New Files (Updated)

- `lib/screens/planning_procurement_v2_screen.dart` (~800 lines)
- `lib/services/procurement_seeding_service.dart` (~150 lines)
- `lib/services/schedule_linkage_service.dart` (~80 lines)
- `lib/services/currency_service.dart` (~50 lines) ⭐ NEW
- `lib/widgets/procurement/procurement_timeline_view.dart` (~200 lines, uses syncfusion)
- `lib/widgets/procurement/vendor_comparison_table.dart` (~180 lines)
- `lib/widgets/procurement/budget_tracking_table.dart` (~150 lines)
- `lib/widgets/procurement/procurement_workflow_builder.dart` (~250 lines)
- `lib/widgets/procurement/po_approval_dialog.dart` (~120 lines)
- `lib/widgets/procurement/procurement_kpi_cards.dart` (~100 lines)

---

## File Summary

### New Files
- `lib/screens/planning_procurement_v2_screen.dart` (~800 lines)
- `lib/services/procurement_seeding_service.dart` (~150 lines)
- `lib/services/schedule_linkage_service.dart` (~80 lines)
- `lib/widgets/procurement/procurement_timeline_view.dart` (~200 lines)
- `lib/widgets/procurement/vendor_comparison_table.dart` (~180 lines)
- `lib/widgets/procurement/budget_tracking_table.dart` (~150 lines)
- `lib/widgets/procurement/procurement_workflow_builder.dart` (~250 lines)
- `lib/widgets/procurement/po_approval_dialog.dart` (~120 lines)
- `lib/widgets/procurement/procurement_kpi_cards.dart` (~100 lines)

### Modified Files
- `lib/models/procurement/procurement_models.dart` (+~60 lines)
- `lib/services/procurement_service.dart` (+~80 lines)
- `lib/screens/planning_procurement_screen.dart` (route to new screen)
- `lib/services/project_route_registry.dart` (update mapping)

### Refactored Files
- `lib/screens/front_end_planning_procurement_screen.dart` (extract widgets, ~-500 lines moved out)

---

## Design Decisions (Resolved)

| Decision | Choice |
|----------|--------|
| **PO Escalation Target** | Project owner (default), configurable per PO |
| **Schedule Listener** | Client-side check on screen open (via `ScheduleLinkageService`) |
| **Vendor Comparison Weighting** | Per-item configuration (stored on `ProcurementItemModel`) |
| **Budget Currency** | Multi-currency support (add `currencyCode` field to models) |
| **Timeline Widget** | `syncfusion_flutter_ganttage` package |

---

## Additional Model Changes for Multi-Currency

### Update ProcurementItemModel

```dart
class ProcurementItemModel {
  // ... existing fields

  // NEW: Currency support
  String currencyCode; // 'USD', 'EUR', 'GBP', etc.

  const ProcurementItemModel({
    // ... existing parameters
    this.currencyCode = 'USD',
  });
}
```

### Update PurchaseOrderModel

```dart
class PurchaseOrderModel {
  // ... existing fields

  // NEW: Currency support
  String currencyCode;

  const PurchaseOrderModel({
    // ... existing parameters
    this.currencyCode = 'USD',
  });
}
```

### Create CurrencyService

**File:** `lib/services/currency_service.dart`

```dart
import 'package:intl/intl.dart';

class CurrencyService {
  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CHF': 'CHF ',
    'CNY': '¥',
    'INR': '₹',
  };

  static String formatCurrency(double amount, String currencyCode) {
    final symbol = _currencySymbols[currencyCode] ?? currencyCode;
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String getSymbol(String currencyCode) {
    return _currencySymbols[currencyCode] ?? currencyCode;
  }
}
```

### Vendor Comparison Per-Item Weights

```dart
class VendorWeighting {
  final double priceWeight;       // Default 0.4
  final double qualityWeight;     // Default 0.3
  final double deliveryWeight;    // Default 0.2
  final double serviceWeight;     // Default 0.1

  const VendorWeighting({
    this.priceWeight = 0.4,
    this.qualityWeight = 0.3,
    this.deliveryWeight = 0.2,
    this.serviceWeight = 0.1,
  });

  Map<String, dynamic> toMap() => {
        'priceWeight': priceWeight,
        'qualityWeight': qualityWeight,
        'deliveryWeight': deliveryWeight,
        'serviceWeight': serviceWeight,
      };

  factory VendorWeighting.fromMap(Map<String, dynamic> map) {
    return VendorWeighting(
      priceWeight: (map['priceWeight'] as num?)?.toDouble() ?? 0.4,
      qualityWeight: (map['qualityWeight'] as num?)?.toDouble() ?? 0.3,
      deliveryWeight: (map['deliveryWeight'] as num?)?.toDouble() ?? 0.2,
      serviceWeight: (map['serviceWeight'] as num?)?.toDouble() ?? 0.1,
    );
  }

  double calculateScore({
    required double priceScore,
    required double qualityScore,
    required double deliveryScore,
    required double serviceScore,
  }) {
    return (priceScore * priceWeight) +
           (qualityScore * qualityWeight) +
           (deliveryScore * deliveryWeight) +
           (serviceScore * serviceWeight);
  }
}

// Add to ProcurementItemModel
class ProcurementItemModel {
  // ... existing fields
  final VendorWeighting? vendorWeighting;
}
```
