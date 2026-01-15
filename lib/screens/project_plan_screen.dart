import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';

class ProjectPlanScreen extends StatefulWidget {
  const ProjectPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectPlanScreen()),
    );
  }

  @override
  State<ProjectPlanScreen> createState() => _ProjectPlanScreenState();
}

class _ProjectPlanScreenState extends State<ProjectPlanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedProject;

  static const List<_Deliverable> _deliverables = [];
  static const List<_CommunicationPlan> _communications = [];
  static const List<String> _currencyOptions = ['USD', 'EUR', 'GBP', 'ZAR', 'NGN', 'KES', 'GHS'];

  final TextEditingController _overviewSummaryController = TextEditingController();
  final TextEditingController _budgetTotalController = TextEditingController();
  final TextEditingController _budgetContingencyController = TextEditingController();
  final TextEditingController _budgetApprovedByController = TextEditingController();

  String _budgetCurrency = 'USD';

  final List<_ListEntry> _overviewObjectives = [];
  final List<_ListEntry> _overviewScope = [];
  final List<_ListEntry> _overviewAssumptions = [];
  final List<_MilestoneEntry> _overviewMilestones = [];

  final List<_ResourceEntry> _resourcePlan = [];
  final List<_VendorEntry> _vendors = [];
  final List<_ToolEntry> _tools = [];

  final List<_TaskEntry> _tasks = [];
  final List<_BudgetEntry> _budgetBreakdown = [];
  final List<_RiskEntry> _risks = [];

  final _Debouncer _overviewSaveDebounce = _Debouncer();
  final _Debouncer _resourcesSaveDebounce = _Debouncer();
  final _Debouncer _tasksSaveDebounce = _Debouncer();
  final _Debouncer _budgetSaveDebounce = _Debouncer();
  final _Debouncer _risksSaveDebounce = _Debouncer();

  bool _loadingOverview = false;
  bool _loadingResources = false;
  bool _loadingTasks = false;
  bool _loadingBudget = false;
  bool _loadingRisks = false;

  bool _suspendOverviewSave = false;
  bool _suspendBudgetSave = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _overviewSummaryController.addListener(() {
      if (_suspendOverviewSave) return;
      _scheduleOverviewSave();
    });
    _budgetTotalController.addListener(() {
      if (_suspendBudgetSave) return;
      _scheduleBudgetSave();
    });
    _budgetContingencyController.addListener(() {
      if (_suspendBudgetSave) return;
      _scheduleBudgetSave();
    });
    _budgetApprovedByController.addListener(() {
      if (_suspendBudgetSave) return;
      _scheduleBudgetSave();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectName = ProjectDataHelper.getData(context).projectName.trim();
      if (projectName.isNotEmpty && mounted) {
        setState(() => _selectedProject = projectName);
      }
      _loadOverview();
      _loadResources();
      _loadTasks();
      _loadBudget();
      _loadRisks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _overviewSummaryController.dispose();
    _budgetTotalController.dispose();
    _budgetContingencyController.dispose();
    _budgetApprovedByController.dispose();
    _overviewSaveDebounce.dispose();
    _resourcesSaveDebounce.dispose();
    _tasksSaveDebounce.dispose();
    _budgetSaveDebounce.dispose();
    _risksSaveDebounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 36;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Project Plan'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isMobile),
                        const SizedBox(height: 24),
                        const PlanningAiNotesCard(
                          title: 'Notes',
                          sectionLabel: 'Project Plan',
                          noteKey: 'planning_project_plan_notes',
                          checkpoint: 'project_plan',
                          description: 'Summarize the project plan, key deliverables, and alignment checkpoints.',
                        ),
                        const SizedBox(height: 24),
                        _ProjectPlanOverviewCard(isMobile: isMobile),
                        const SizedBox(height: 24),
                        _buildTabBar(),
                        const SizedBox(height: 24),
                        _buildTabContent(isMobile),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Project Plan',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    const Spacer(),
                    _buildEditPlanButton(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProjectDropdown(),
                const SizedBox(height: 12),
                _buildStatusBadges(),
              ],
            )
          : Row(
              children: [
                const Text(
                  'Project Plan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                const SizedBox(width: 32),
                _buildProjectDropdown(),
                const Spacer(),
                _buildStatusBadges(),
                const SizedBox(width: 10),
                _buildEditPlanButton(),
              ],
            ),
    );
  }

  Widget _buildProjectDropdown() {
    if ((_selectedProject ?? '').isEmpty) {
      return const _EmptyStateChip(label: 'Select project', icon: Icons.folder_open_outlined);
    }
    final options = [_selectedProject!];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProject ?? options.first,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF6B7280)),
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.w500),
          items: options
              .map((project) => DropdownMenuItem<String>(value: project, child: Text(project)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedProject = value);
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadges() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text('Status: —', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            const Text('Start —', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            const Icon(Icons.flag_outlined, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            const Text('End —', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
      ],
    );
  }

  Widget _buildEditPlanButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Edit Plan'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD54F),
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 2,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Resources'),
          Tab(text: 'Tasks'),
          Tab(text: 'Budget'),
          Tab(text: 'Risks'),
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isMobile) {
    switch (_tabController.index) {
      case 0:
        return _buildOverviewTab(isMobile);
      case 1:
        return _buildResourcesTab();
      case 2:
        return _buildTasksTab();
      case 3:
        return _buildBudgetTab(isMobile);
      case 4:
        return _buildRisksTab();
      default:
        return _buildOverviewTab(isMobile);
    }
  }

  Widget _buildOverviewTab(bool isMobile) {
    return _TabSectionCard(
      title: 'Overview',
      subtitle: 'Capture the intent, scope, and success criteria for this plan.',
      isLoading: _loadingOverview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledTextField(
            label: 'Executive summary',
            controller: _overviewSummaryController,
            hintText: 'Outline the plan purpose, key outcomes, and strategic alignment.',
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          if (isMobile)
            Column(
              children: [
                _ListEditor(
                  title: 'Objectives',
                  subtitle: 'Set the primary outcomes the plan must achieve.',
                  hintText: 'Add an objective',
                  items: _overviewObjectives,
                  onAdd: _addOverviewObjective,
                  onChanged: _updateOverviewObjective,
                  onDelete: _deleteOverviewObjective,
                ),
                const SizedBox(height: 16),
                _ListEditor(
                  title: 'Scope',
                  subtitle: 'Define what is included and excluded.',
                  hintText: 'Add scope item',
                  items: _overviewScope,
                  onAdd: _addOverviewScope,
                  onChanged: _updateOverviewScope,
                  onDelete: _deleteOverviewScope,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ListEditor(
                    title: 'Objectives',
                    subtitle: 'Set the primary outcomes the plan must achieve.',
                    hintText: 'Add an objective',
                    items: _overviewObjectives,
                    onAdd: _addOverviewObjective,
                    onChanged: _updateOverviewObjective,
                    onDelete: _deleteOverviewObjective,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _ListEditor(
                    title: 'Scope',
                    subtitle: 'Define what is included and excluded.',
                    hintText: 'Add scope item',
                    items: _overviewScope,
                    onAdd: _addOverviewScope,
                    onChanged: _updateOverviewScope,
                    onDelete: _deleteOverviewScope,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          _ListEditor(
            title: 'Assumptions & constraints',
            subtitle: 'Document constraints, dependencies, and assumptions.',
            hintText: 'Add assumption or constraint',
            items: _overviewAssumptions,
            onAdd: _addOverviewAssumption,
            onChanged: _updateOverviewAssumption,
            onDelete: _deleteOverviewAssumption,
          ),
          const SizedBox(height: 20),
          _SectionTableCard(
            title: 'Milestones',
            subtitle: 'Track key dates, owners, and progress indicators.',
            onAdd: _addMilestone,
            child: _buildMilestonesTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    return _TabSectionCard(
      title: 'Resources',
      subtitle: 'Plan staffing, vendors, and tooling required to deliver the plan.',
      isLoading: _loadingResources,
      child: Column(
        children: [
          _SectionTableCard(
            title: 'Resource plan',
            subtitle: 'Define roles, allocations, and coverage windows.',
            onAdd: _addResource,
            child: _buildResourceTable(),
          ),
          const SizedBox(height: 20),
          _SectionTableCard(
            title: 'Vendors & partners',
            subtitle: 'Capture external suppliers, contracts, and ownership.',
            onAdd: _addVendor,
            child: _buildVendorTable(),
          ),
          const SizedBox(height: 20),
          _SectionTableCard(
            title: 'Tools & systems',
            subtitle: 'List key platforms, ownership, and readiness status.',
            onAdd: _addTool,
            child: _buildToolsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return _TabSectionCard(
      title: 'Tasks',
      subtitle: 'Break down the work into clear deliverables and owners.',
      isLoading: _loadingTasks,
      child: _SectionTableCard(
        title: 'Work plan',
        subtitle: 'Track tasks, dependencies, and delivery status.',
        onAdd: _addTask,
        child: _buildTasksTable(),
      ),
    );
  }

  Widget _buildBudgetTab(bool isMobile) {
    return _TabSectionCard(
      title: 'Budget',
      subtitle: 'Document the financial plan, approvals, and tracking.',
      isLoading: _loadingBudget,
      child: Column(
        children: [
          _SectionCard(
            title: 'Budget summary',
            subtitle: 'Capture baseline totals and approvals.',
            child: isMobile
                ? Column(
                    children: [
                      _LabeledTextField(
                        label: 'Total budget',
                        controller: _budgetTotalController,
                        hintText: 'e.g., 250000',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _LabeledDropdown(
                        label: 'Currency',
                        value: _budgetCurrency,
                        options: _currencyOptions,
                        onChanged: (value) {
                          setState(() => _budgetCurrency = value);
                          _scheduleBudgetSave();
                        },
                      ),
                      const SizedBox(height: 12),
                      _LabeledTextField(
                        label: 'Contingency',
                        controller: _budgetContingencyController,
                        hintText: 'e.g., 10%',
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 12),
                      _LabeledTextField(
                        label: 'Approved by',
                        controller: _budgetApprovedByController,
                        hintText: 'Name or role',
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _LabeledTextField(
                        label: 'Total budget',
                        controller: _budgetTotalController,
                        hintText: 'e.g., 250000',
                        keyboardType: TextInputType.number,
                        width: 200,
                      ),
                      _LabeledDropdown(
                        label: 'Currency',
                        value: _budgetCurrency,
                        options: _currencyOptions,
                        onChanged: (value) {
                          setState(() => _budgetCurrency = value);
                          _scheduleBudgetSave();
                        },
                        width: 140,
                      ),
                      _LabeledTextField(
                        label: 'Contingency',
                        controller: _budgetContingencyController,
                        hintText: 'e.g., 10%',
                        keyboardType: TextInputType.text,
                        width: 160,
                      ),
                      _LabeledTextField(
                        label: 'Approved by',
                        controller: _budgetApprovedByController,
                        hintText: 'Name or role',
                        width: 220,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          _SectionTableCard(
            title: 'Budget breakdown',
            subtitle: 'Track estimates, actuals, and variance by category.',
            onAdd: _addBudgetItem,
            child: _buildBudgetTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildRisksTab() {
    return _TabSectionCard(
      title: 'Risks',
      subtitle: 'Identify, score, and mitigate delivery risks.',
      isLoading: _loadingRisks,
      child: _SectionTableCard(
        title: 'Risk register',
        subtitle: 'Monitor probability, impact, mitigation, and ownership.',
        onAdd: _addRisk,
        child: _buildRisksTable(),
      ),
    );
  }

  String? _projectId() => ProjectDataHelper.getData(context).projectId;

  void _scheduleOverviewSave() {
    _overviewSaveDebounce.run(_persistOverview);
  }

  void _scheduleResourcesSave() {
    _resourcesSaveDebounce.run(_persistResources);
  }

  void _scheduleTasksSave() {
    _tasksSaveDebounce.run(_persistTasks);
  }

  void _scheduleBudgetSave() {
    _budgetSaveDebounce.run(_persistBudget);
  }

  void _scheduleRisksSave() {
    _risksSaveDebounce.run(_persistRisks);
  }

  Future<void> _loadOverview() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    setState(() => _loadingOverview = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('project_plan_sections')
          .doc('overview')
          .get();
      final data = doc.data() ?? {};
      final summary = data['summary']?.toString() ?? '';
      _suspendOverviewSave = true;
      _overviewSummaryController.text = summary;
      _suspendOverviewSave = false;
      final objectives = _ListEntry.fromList(data['objectives']);
      final scope = _ListEntry.fromList(data['scope']);
      final assumptions = _ListEntry.fromList(data['assumptions']);
      final milestones = _MilestoneEntry.fromList(data['milestones']);
      if (!mounted) return;
      setState(() {
        _overviewObjectives
          ..clear()
          ..addAll(objectives);
        _overviewScope
          ..clear()
          ..addAll(scope);
        _overviewAssumptions
          ..clear()
          ..addAll(assumptions);
        _overviewMilestones
          ..clear()
          ..addAll(milestones);
      });
    } catch (error) {
      debugPrint('Failed to load project plan overview: $error');
    } finally {
      if (mounted) setState(() => _loadingOverview = false);
    }
  }

  Future<void> _loadResources() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    setState(() => _loadingResources = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('project_plan_sections')
          .doc('resources')
          .get();
      final data = doc.data() ?? {};
      final resources = _ResourceEntry.fromList(data['resourcePlan']);
      final vendors = _VendorEntry.fromList(data['vendors']);
      final tools = _ToolEntry.fromList(data['tools']);
      if (!mounted) return;
      setState(() {
        _resourcePlan
          ..clear()
          ..addAll(resources);
        _vendors
          ..clear()
          ..addAll(vendors);
        _tools
          ..clear()
          ..addAll(tools);
      });
    } catch (error) {
      debugPrint('Failed to load project plan resources: $error');
    } finally {
      if (mounted) setState(() => _loadingResources = false);
    }
  }

  Future<void> _loadTasks() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    setState(() => _loadingTasks = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('project_plan_sections')
          .doc('tasks')
          .get();
      final data = doc.data() ?? {};
      final tasks = _TaskEntry.fromList(data['tasks']);
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(tasks);
      });
    } catch (error) {
      debugPrint('Failed to load project plan tasks: $error');
    } finally {
      if (mounted) setState(() => _loadingTasks = false);
    }
  }

  Future<void> _loadBudget() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    setState(() => _loadingBudget = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('project_plan_sections')
          .doc('budget')
          .get();
      final data = doc.data() ?? {};
      final totalBudget = data['totalBudget']?.toString() ?? '';
      final contingency = data['contingency']?.toString() ?? '';
      final approvedBy = data['approvedBy']?.toString() ?? '';
      final currency = data['currency']?.toString();
      _suspendBudgetSave = true;
      _budgetTotalController.text = totalBudget;
      _budgetContingencyController.text = contingency;
      _budgetApprovedByController.text = approvedBy;
      if (currency != null && _currencyOptions.contains(currency)) {
        _budgetCurrency = currency;
      }
      _suspendBudgetSave = false;
      final breakdown = _BudgetEntry.fromList(data['breakdown']);
      if (!mounted) return;
      setState(() {
        _budgetBreakdown
          ..clear()
          ..addAll(breakdown);
      });
    } catch (error) {
      debugPrint('Failed to load project plan budget: $error');
    } finally {
      if (mounted) setState(() => _loadingBudget = false);
    }
  }

  Future<void> _loadRisks() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    setState(() => _loadingRisks = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('project_plan_sections')
          .doc('risks')
          .get();
      final data = doc.data() ?? {};
      final risks = _RiskEntry.fromList(data['risks']);
      if (!mounted) return;
      setState(() {
        _risks
          ..clear()
          ..addAll(risks);
      });
    } catch (error) {
      debugPrint('Failed to load project plan risks: $error');
    } finally {
      if (mounted) setState(() => _loadingRisks = false);
    }
  }

  Future<void> _persistOverview() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    final payload = {
      'summary': _overviewSummaryController.text.trim(),
      'objectives': _overviewObjectives.map((item) => item.toJson()).toList(),
      'scope': _overviewScope.map((item) => item.toJson()).toList(),
      'assumptions': _overviewAssumptions.map((item) => item.toJson()).toList(),
      'milestones': _overviewMilestones.map((item) => item.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('project_plan_sections')
        .doc('overview')
        .set(payload, SetOptions(merge: true));
  }

  Future<void> _persistResources() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    final payload = {
      'resourcePlan': _resourcePlan.map((item) => item.toJson()).toList(),
      'vendors': _vendors.map((item) => item.toJson()).toList(),
      'tools': _tools.map((item) => item.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('project_plan_sections')
        .doc('resources')
        .set(payload, SetOptions(merge: true));
  }

  Future<void> _persistTasks() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    final payload = {
      'tasks': _tasks.map((item) => item.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('project_plan_sections')
        .doc('tasks')
        .set(payload, SetOptions(merge: true));
  }

  Future<void> _persistBudget() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    final payload = {
      'totalBudget': _budgetTotalController.text.trim(),
      'contingency': _budgetContingencyController.text.trim(),
      'approvedBy': _budgetApprovedByController.text.trim(),
      'currency': _budgetCurrency,
      'breakdown': _budgetBreakdown.map((item) => item.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('project_plan_sections')
        .doc('budget')
        .set(payload, SetOptions(merge: true));
  }

  Future<void> _persistRisks() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    final payload = {
      'risks': _risks.map((item) => item.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('project_plan_sections')
        .doc('risks')
        .set(payload, SetOptions(merge: true));
  }

  void _addOverviewObjective() {
    setState(() => _overviewObjectives.add(_ListEntry.empty()));
    _scheduleOverviewSave();
  }

  void _updateOverviewObjective(_ListEntry updated) {
    final index = _overviewObjectives.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _overviewObjectives[index] = updated);
    _scheduleOverviewSave();
  }

  void _deleteOverviewObjective(String id) {
    setState(() => _overviewObjectives.removeWhere((item) => item.id == id));
    _scheduleOverviewSave();
  }

  void _addOverviewScope() {
    setState(() => _overviewScope.add(_ListEntry.empty()));
    _scheduleOverviewSave();
  }

  void _updateOverviewScope(_ListEntry updated) {
    final index = _overviewScope.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _overviewScope[index] = updated);
    _scheduleOverviewSave();
  }

  void _deleteOverviewScope(String id) {
    setState(() => _overviewScope.removeWhere((item) => item.id == id));
    _scheduleOverviewSave();
  }

  void _addOverviewAssumption() {
    setState(() => _overviewAssumptions.add(_ListEntry.empty()));
    _scheduleOverviewSave();
  }

  void _updateOverviewAssumption(_ListEntry updated) {
    final index = _overviewAssumptions.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _overviewAssumptions[index] = updated);
    _scheduleOverviewSave();
  }

  void _deleteOverviewAssumption(String id) {
    setState(() => _overviewAssumptions.removeWhere((item) => item.id == id));
    _scheduleOverviewSave();
  }

  void _addMilestone() {
    setState(() => _overviewMilestones.add(_MilestoneEntry.empty()));
    _scheduleOverviewSave();
  }

  void _updateMilestone(_MilestoneEntry updated) {
    final index = _overviewMilestones.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _overviewMilestones[index] = updated);
    _scheduleOverviewSave();
  }

  void _deleteMilestone(String id) {
    setState(() => _overviewMilestones.removeWhere((item) => item.id == id));
    _scheduleOverviewSave();
  }

  void _addResource() {
    setState(() => _resourcePlan.add(_ResourceEntry.empty()));
    _scheduleResourcesSave();
  }

  void _updateResource(_ResourceEntry updated) {
    final index = _resourcePlan.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _resourcePlan[index] = updated);
    _scheduleResourcesSave();
  }

  void _deleteResource(String id) {
    setState(() => _resourcePlan.removeWhere((item) => item.id == id));
    _scheduleResourcesSave();
  }

  void _addVendor() {
    setState(() => _vendors.add(_VendorEntry.empty()));
    _scheduleResourcesSave();
  }

  void _updateVendor(_VendorEntry updated) {
    final index = _vendors.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _vendors[index] = updated);
    _scheduleResourcesSave();
  }

  void _deleteVendor(String id) {
    setState(() => _vendors.removeWhere((item) => item.id == id));
    _scheduleResourcesSave();
  }

  void _addTool() {
    setState(() => _tools.add(_ToolEntry.empty()));
    _scheduleResourcesSave();
  }

  void _updateTool(_ToolEntry updated) {
    final index = _tools.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _tools[index] = updated);
    _scheduleResourcesSave();
  }

  void _deleteTool(String id) {
    setState(() => _tools.removeWhere((item) => item.id == id));
    _scheduleResourcesSave();
  }

  void _addTask() {
    setState(() => _tasks.add(_TaskEntry.empty()));
    _scheduleTasksSave();
  }

  void _updateTask(_TaskEntry updated) {
    final index = _tasks.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _tasks[index] = updated);
    _scheduleTasksSave();
  }

  void _deleteTask(String id) {
    setState(() => _tasks.removeWhere((item) => item.id == id));
    _scheduleTasksSave();
  }

  void _addBudgetItem() {
    setState(() => _budgetBreakdown.add(_BudgetEntry.empty()));
    _scheduleBudgetSave();
  }

  void _updateBudgetItem(_BudgetEntry updated) {
    final index = _budgetBreakdown.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _budgetBreakdown[index] = updated);
    _scheduleBudgetSave();
  }

  void _deleteBudgetItem(String id) {
    setState(() => _budgetBreakdown.removeWhere((item) => item.id == id));
    _scheduleBudgetSave();
  }

  void _addRisk() {
    setState(() => _risks.add(_RiskEntry.empty()));
    _scheduleRisksSave();
  }

  void _updateRisk(_RiskEntry updated) {
    final index = _risks.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _risks[index] = updated);
    _scheduleRisksSave();
  }

  void _deleteRisk(String id) {
    setState(() => _risks.removeWhere((item) => item.id == id));
    _scheduleRisksSave();
  }

  Widget _buildMilestonesTable() {
    final columns = [
      const _TableColumnDef('Milestone', 220),
      const _TableColumnDef('Target date', 140),
      const _TableColumnDef('Owner', 160),
      const _TableColumnDef('Status', 140),
      const _TableColumnDef('Notes', 220),
      const _TableColumnDef('', 64),
    ];

    if (_overviewMilestones.isEmpty) {
      return const _InlineEmptyState(
        title: 'No milestones yet',
        message: 'Add milestones to track delivery checkpoints.',
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in _overviewMilestones)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.title,
                fieldKey: '${entry.id}_title',
                hintText: 'Milestone name',
                onChanged: (value) => _updateMilestone(entry.copyWith(title: value)),
              ),
              _TextCell(
                value: entry.targetDate,
                fieldKey: '${entry.id}_target',
                hintText: 'YYYY-MM-DD',
                onChanged: (value) => _updateMilestone(entry.copyWith(targetDate: value)),
              ),
              _TextCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                hintText: 'Owner',
                onChanged: (value) => _updateMilestone(entry.copyWith(owner: value)),
              ),
              _DropdownCell(
                value: entry.status,
                fieldKey: '${entry.id}_status',
                options: const ['Planned', 'In progress', 'At risk', 'Complete'],
                onChanged: (value) => _updateMilestone(entry.copyWith(status: value)),
              ),
              _TextCell(
                value: entry.notes,
                fieldKey: '${entry.id}_notes',
                hintText: 'Notes',
                onChanged: (value) => _updateMilestone(entry.copyWith(notes: value)),
              ),
              _DeleteCell(onPressed: () => _deleteMilestone(entry.id)),
            ],
          ),
      ],
    );
  }

  Widget _buildResourceTable() {
    final columns = [
      const _TableColumnDef('Role/Skill', 200),
      const _TableColumnDef('Allocation', 120),
      const _TableColumnDef('Start', 120),
      const _TableColumnDef('End', 120),
      const _TableColumnDef('Owner', 160),
      const _TableColumnDef('Notes', 220),
      const _TableColumnDef('', 64),
    ];

    if (_resourcePlan.isEmpty) {
      return const _InlineEmptyState(
        title: 'No resource plan yet',
        message: 'Add team roles and allocations.',
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in _resourcePlan)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.role,
                fieldKey: '${entry.id}_role',
                hintText: 'Role or skill',
                onChanged: (value) => _updateResource(entry.copyWith(role: value)),
              ),
              _TextCell(
                value: entry.allocation,
                fieldKey: '${entry.id}_allocation',
                hintText: 'e.g., 0.5 FTE',
                onChanged: (value) => _updateResource(entry.copyWith(allocation: value)),
              ),
              _TextCell(
                value: entry.startDate,
                fieldKey: '${entry.id}_start',
                hintText: 'YYYY-MM-DD',
                onChanged: (value) => _updateResource(entry.copyWith(startDate: value)),
              ),
              _TextCell(
                value: entry.endDate,
                fieldKey: '${entry.id}_end',
                hintText: 'YYYY-MM-DD',
                onChanged: (value) => _updateResource(entry.copyWith(endDate: value)),
              ),
              _TextCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                hintText: 'Owner',
                onChanged: (value) => _updateResource(entry.copyWith(owner: value)),
              ),
              _TextCell(
                value: entry.notes,
                fieldKey: '${entry.id}_notes',
                hintText: 'Notes',
                onChanged: (value) => _updateResource(entry.copyWith(notes: value)),
              ),
              _DeleteCell(onPressed: () => _deleteResource(entry.id)),
            ],
          ),
      ],
    );
  }

  Widget _buildVendorTable() {
    final columns = [
      const _TableColumnDef('Vendor', 200),
      const _TableColumnDef('Service', 200),
      const _TableColumnDef('Contact', 180),
      const _TableColumnDef('Status', 140),
      const _TableColumnDef('Notes', 220),
      const _TableColumnDef('', 64),
    ];

    if (_vendors.isEmpty) {
      return const _InlineEmptyState(
        title: 'No vendors yet',
        message: 'Track external providers and contract status.',
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in _vendors)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.name,
                fieldKey: '${entry.id}_name',
                hintText: 'Vendor name',
                onChanged: (value) => _updateVendor(entry.copyWith(name: value)),
              ),
              _TextCell(
                value: entry.service,
                fieldKey: '${entry.id}_service',
                hintText: 'Service',
                onChanged: (value) => _updateVendor(entry.copyWith(service: value)),
              ),
              _TextCell(
                value: entry.contact,
                fieldKey: '${entry.id}_contact',
                hintText: 'Contact',
                onChanged: (value) => _updateVendor(entry.copyWith(contact: value)),
              ),
              _DropdownCell(
                value: entry.status,
                fieldKey: '${entry.id}_status',
                options: const ['Planned', 'Contracted', 'Active', 'Complete'],
                onChanged: (value) => _updateVendor(entry.copyWith(status: value)),
              ),
              _TextCell(
                value: entry.notes,
                fieldKey: '${entry.id}_notes',
                hintText: 'Notes',
                onChanged: (value) => _updateVendor(entry.copyWith(notes: value)),
              ),
              _DeleteCell(onPressed: () => _deleteVendor(entry.id)),
            ],
          ),
      ],
    );
  }

  Widget _buildToolsTable() {
    final columns = [
      const _TableColumnDef('Tool/System', 200),
      const _TableColumnDef('Purpose', 220),
      const _TableColumnDef('Owner', 180),
      const _TableColumnDef('Status', 140),
      const _TableColumnDef('Notes', 200),
      const _TableColumnDef('', 64),
    ];

    if (_tools.isEmpty) {
      return const _InlineEmptyState(
        title: 'No tools or systems yet',
        message: 'List platforms and readiness state.',
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in _tools)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.name,
                fieldKey: '${entry.id}_name',
                hintText: 'Tool or system',
                onChanged: (value) => _updateTool(entry.copyWith(name: value)),
              ),
              _TextCell(
                value: entry.purpose,
                fieldKey: '${entry.id}_purpose',
                hintText: 'Purpose',
                onChanged: (value) => _updateTool(entry.copyWith(purpose: value)),
              ),
              _TextCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                hintText: 'Owner',
                onChanged: (value) => _updateTool(entry.copyWith(owner: value)),
              ),
              _DropdownCell(
                value: entry.status,
                fieldKey: '${entry.id}_status',
                options: const ['Planned', 'In setup', 'Ready', 'Retired'],
                onChanged: (value) => _updateTool(entry.copyWith(status: value)),
              ),
              _TextCell(
                value: entry.notes,
                fieldKey: '${entry.id}_notes',
                hintText: 'Notes',
                onChanged: (value) => _updateTool(entry.copyWith(notes: value)),
              ),
              _DeleteCell(onPressed: () => _deleteTool(entry.id)),
            ],
          ),
      ],
    );
  }

  Widget _buildTasksTable() {
    final columns = [
      const _TableColumnDef('Task', 240),
      const _TableColumnDef('Owner', 180),
      const _TableColumnDef('Start', 120),
      const _TableColumnDef('Due', 120),
      const _TableColumnDef('Status', 140),
      const _TableColumnDef('Dependency', 200),
      const _TableColumnDef('Notes', 220),
      const _TableColumnDef('', 64),
    ];

    if (_tasks.isEmpty) {
      return const _InlineEmptyState(
        title: 'No tasks yet',
        message: 'Add tasks to build a delivery plan.',
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in _tasks)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.title,
                fieldKey: '${entry.id}_title',
                hintText: 'Task description',
                onChanged: (value) => _updateTask(entry.copyWith(title: value)),
              ),
              _TextCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                hintText: 'Owner',
                onChanged: (value) => _updateTask(entry.copyWith(owner: value)),
              ),
              _TextCell(
                value: entry.startDate,
                fieldKey: '${entry.id}_start',
                hintText: 'YYYY-MM-DD',
                onChanged: (value) => _updateTask(entry.copyWith(startDate: value)),
              ),
              _TextCell(
                value: entry.dueDate,
                fieldKey: '${entry.id}_due',
                hintText: 'YYYY-MM-DD',
                onChanged: (value) => _updateTask(entry.copyWith(dueDate: value)),
              ),
              _DropdownCell(
                value: entry.status,
                fieldKey: '${entry.id}_status',
                options: const ['Not started', 'In progress', 'Blocked', 'Complete'],
                onChanged: (value) => _updateTask(entry.copyWith(status: value)),
              ),
              _TextCell(
                value: entry.dependency,
                fieldKey: '${entry.id}_dependency',
                hintText: 'Dependency',
                onChanged: (value) => _updateTask(entry.copyWith(dependency: value)),
              ),
              _TextCell(
                value: entry.notes,
                fieldKey: '${entry.id}_notes',
                hintText: 'Notes',
                onChanged: (value) => _updateTask(entry.copyWith(notes: value)),
              ),
              _DeleteCell(onPressed: () => _deleteTask(entry.id)),
            ],
          ),
      ],
    );
  }

  Widget _buildBudgetTable() {
    final columns = [
      const _TableColumnDef('Category', 220),
      const _TableColumnDef('Estimate', 140),
      const _TableColumnDef('Actual', 140),
      const _TableColumnDef('Variance', 140),
      const _TableColumnDef('Notes', 220),
      const _TableColumnDef('', 64),
    ];

    if (_budgetBreakdown.isEmpty) {
      return const _InlineEmptyState(
        title: 'No budget items yet',
        message: 'Add categories to track spend.',
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in _budgetBreakdown)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.category,
                fieldKey: '${entry.id}_category',
                hintText: 'Category',
                onChanged: (value) => _updateBudgetItem(entry.copyWith(category: value)),
              ),
              _TextCell(
                value: entry.estimate,
                fieldKey: '${entry.id}_estimate',
                hintText: 'Estimate',
                onChanged: (value) => _updateBudgetItem(entry.copyWith(estimate: value)),
              ),
              _TextCell(
                value: entry.actual,
                fieldKey: '${entry.id}_actual',
                hintText: 'Actual',
                onChanged: (value) => _updateBudgetItem(entry.copyWith(actual: value)),
              ),
              _TextCell(
                value: entry.variance,
                fieldKey: '${entry.id}_variance',
                hintText: 'Variance',
                onChanged: (value) => _updateBudgetItem(entry.copyWith(variance: value)),
              ),
              _TextCell(
                value: entry.notes,
                fieldKey: '${entry.id}_notes',
                hintText: 'Notes',
                onChanged: (value) => _updateBudgetItem(entry.copyWith(notes: value)),
              ),
              _DeleteCell(onPressed: () => _deleteBudgetItem(entry.id)),
            ],
          ),
      ],
    );
  }

  Widget _buildRisksTable() {
    final columns = [
      const _TableColumnDef('Risk', 240),
      const _TableColumnDef('Impact', 140),
      const _TableColumnDef('Probability', 140),
      const _TableColumnDef('Mitigation', 240),
      const _TableColumnDef('Owner', 160),
      const _TableColumnDef('Status', 140),
      const _TableColumnDef('Target date', 140),
      const _TableColumnDef('', 64),
    ];

    if (_risks.isEmpty) {
      return const _InlineEmptyState(
        title: 'No risks logged',
        message: 'Capture risks and mitigation steps.',
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in _risks)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.title,
                fieldKey: '${entry.id}_title',
                hintText: 'Risk description',
                onChanged: (value) => _updateRisk(entry.copyWith(title: value)),
              ),
              _DropdownCell(
                value: entry.impact,
                fieldKey: '${entry.id}_impact',
                options: const ['Low', 'Medium', 'High'],
                onChanged: (value) => _updateRisk(entry.copyWith(impact: value)),
              ),
              _DropdownCell(
                value: entry.probability,
                fieldKey: '${entry.id}_probability',
                options: const ['Low', 'Medium', 'High'],
                onChanged: (value) => _updateRisk(entry.copyWith(probability: value)),
              ),
              _TextCell(
                value: entry.mitigation,
                fieldKey: '${entry.id}_mitigation',
                hintText: 'Mitigation plan',
                onChanged: (value) => _updateRisk(entry.copyWith(mitigation: value)),
              ),
              _TextCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                hintText: 'Owner',
                onChanged: (value) => _updateRisk(entry.copyWith(owner: value)),
              ),
              _DropdownCell(
                value: entry.status,
                fieldKey: '${entry.id}_status',
                options: const ['Open', 'Mitigating', 'Watching', 'Closed'],
                onChanged: (value) => _updateRisk(entry.copyWith(status: value)),
              ),
              _TextCell(
                value: entry.targetDate,
                fieldKey: '${entry.id}_target',
                hintText: 'YYYY-MM-DD',
                onChanged: (value) => _updateRisk(entry.copyWith(targetDate: value)),
              ),
              _DeleteCell(onPressed: () => _deleteRisk(entry.id)),
            ],
          ),
      ],
    );
  }
}

class _Deliverable {
  const _Deliverable({
    required this.id,
    required this.name,
    required this.phase,
    required this.dueDate,
    required this.status,
    required this.owner,
  });

  final String id;
  final String name;
  final String phase;
  final String dueDate;
  final String status;
  final String owner;
}

class _CommunicationPlan {
  const _CommunicationPlan({
    required this.meetingType,
    required this.frequency,
    required this.attendees,
    required this.purpose,
  });

  final String meetingType;
  final String frequency;
  final String attendees;
  final String purpose;
}

class _ProjectPlanOverviewCard extends StatelessWidget {
  const _ProjectPlanOverviewCard({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final data = ProjectDataHelper.getData(context);
    final objectives = _objectiveItems(data);
    final scopes = _scopeItems(data);
    final hasOverview = data.projectName.trim().isNotEmpty || objectives.isNotEmpty || scopes.isNotEmpty;
    if (!hasOverview) {
      return const _SectionEmptyState(
        title: 'No project overview yet',
        message: 'Add goals, objectives, or scope details to populate the overview.',
        icon: Icons.assignment_outlined,
      );
    }
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Plan Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 24),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProjectDetails(context),
                    const SizedBox(height: 24),
                    _buildProjectObjectives(objectives),
                    const SizedBox(height: 24),
                    _buildProjectScope(scopes),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildProjectDetails(context)),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _buildProjectObjectives(objectives)),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _buildProjectScope(scopes)),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildProjectDetails(BuildContext context) {
    final data = ProjectDataHelper.getData(context);
    final projectName = data.projectName.trim().isEmpty ? '—' : data.projectName.trim();
    final manager = _firstTeamMemberName(data, keyword: 'manager') ?? '—';
    final sponsor = _firstTeamMemberName(data, keyword: 'sponsor') ?? '—';
    const methodology = '—';
    const startDate = '—';
    const endDate = '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('Project Name:', projectName),
        const SizedBox(height: 10),
        _buildDetailRow('Project Manager:', manager),
        const SizedBox(height: 10),
        _buildDetailRow('Sponsor:', sponsor),
        const SizedBox(height: 10),
        _buildDetailRow('Methodology:', methodology),
        const SizedBox(height: 10),
        _buildDetailRow('Start Date:', startDate),
        const SizedBox(height: 10),
        _buildDetailRow('End Date:', endDate),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectObjectives(List<String> objectives) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Objectives',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        if (objectives.isEmpty)
          const Text(
            'No objectives captured yet.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          )
        else
          ...objectives.map((obj) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    Expanded(
                      child: Text(obj, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildProjectScope(List<String> scopes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Scope',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 8),
        Text(
          scopes.isEmpty ? 'No scope defined yet.' : 'Scope highlights:',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 12),
        if (scopes.isNotEmpty)
          ...scopes.map((scope) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    Expanded(
                      child: Text(scope, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  List<String> _objectiveItems(ProjectDataModel data) {
    final items = <String>[];
    final objective = data.projectObjective.trim();
    if (objective.isNotEmpty) items.add(objective);
    for (final goal in data.projectGoals) {
      final desc = goal.description.trim();
      if (desc.isNotEmpty) items.add(desc);
    }
    return items;
  }

  List<String> _scopeItems(ProjectDataModel data) {
    final items = <String>[];
    final requirements = data.frontEndPlanning.requirements.trim();
    if (requirements.isNotEmpty) {
      items.addAll(
        requirements
            .split(RegExp(r'[\n•]+'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );
    }
    return items;
  }

  String? _firstTeamMemberName(ProjectDataModel data, {required String keyword}) {
    for (final member in data.teamMembers) {
      final role = member.role.toLowerCase();
      if (role.contains(keyword) && member.name.trim().isNotEmpty) {
        return member.name.trim();
      }
    }
    return data.teamMembers.isNotEmpty ? data.teamMembers.first.name.trim() : null;
  }
}

class _KeyDeliverablesCard extends StatelessWidget {
  const _KeyDeliverablesCard({required this.deliverables, required this.isMobile});

  final List<_Deliverable> deliverables;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (deliverables.isEmpty) {
      return const _SectionEmptyState(
        title: 'No deliverables yet',
        message: 'Add deliverables to track ownership, phase, and due dates.',
        icon: Icons.task_alt_outlined,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            child: const Text(
              'Key Deliverables',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          LayoutBuilder(
            builder: (context, constraints) {
              final mediaWidth = MediaQuery.of(context).size.width;
              final bool hasBoundedWidth = constraints.hasBoundedWidth && constraints.maxWidth.isFinite;
              final double tableWidth = hasBoundedWidth ? constraints.maxWidth : mediaWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                  headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                  horizontalMargin: 28,
                  columnSpacing: 48,
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Deliverable')),
                    DataColumn(label: Text('Phase')),
                    DataColumn(label: Text('Due Date')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Owner')),
                  ],
                  rows: deliverables.map((d) => DataRow(
                    cells: [
                      DataCell(Text(d.id, style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(d.name)),
                      DataCell(Text(d.phase)),
                      DataCell(Text(d.dueDate)),
                      DataCell(_StatusBadge(status: d.status)),
                      DataCell(Text(d.owner)),
                    ],
                  )).toList(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'completed':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        break;
      case 'in progress':
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFFCA8A04);
        break;
      case 'not started':
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState({required this.title, required this.message, required this.icon});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateChip extends StatelessWidget {
  const _EmptyStateChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _CommunicationPlanCard extends StatelessWidget {
  const _CommunicationPlanCard({required this.communications, required this.isMobile});

  final List<_CommunicationPlan> communications;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            child: const Text(
              'Communication Plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          LayoutBuilder(
            builder: (context, constraints) {
              final mediaWidth = MediaQuery.of(context).size.width;
              final bool hasBoundedWidth = constraints.hasBoundedWidth && constraints.maxWidth.isFinite;
              final double tableWidth = hasBoundedWidth ? constraints.maxWidth : mediaWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                  headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                  horizontalMargin: 28,
                  columnSpacing: 48,
                  columns: const [
                    DataColumn(label: Text('Meeting Type')),
                    DataColumn(label: Text('Frequency')),
                    DataColumn(label: Text('Attendees')),
                    DataColumn(label: Text('Purpose')),
                  ],
                  rows: communications.map((c) => DataRow(
                    cells: [
                      DataCell(Text(c.meetingType, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(c.frequency)),
                      DataCell(Text(c.attendees)),
                      DataCell(SizedBox(width: 300, child: Text(c.purpose, softWrap: true))),
                    ],
                  )).toList(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TabSectionCard extends StatelessWidget {
  const _TabSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.isLoading = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          if (isLoading) const LinearProgressIndicator(minHeight: 2),
          if (isLoading) const SizedBox(height: 16),
          child,
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
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
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
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SectionTableCard extends StatelessWidget {
  const _SectionTableCard({
    required this.title,
    required this.subtitle,
    required this.onAdd,
    required this.child,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      subtitle: subtitle,
      trailing: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add'),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1F2937),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          backgroundColor: const Color(0xFFFFF3C4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      child: child,
    );
  }
}

class _ListEditor extends StatelessWidget {
  const _ListEditor({
    required this.title,
    this.subtitle,
    required this.hintText,
    required this.items,
    required this.onAdd,
    required this.onChanged,
    required this.onDelete,
  });

  final String title;
  final String? subtitle;
  final String hintText;
  final List<_ListEntry> items;
  final VoidCallback onAdd;
  final ValueChanged<_ListEntry> onChanged;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      subtitle: subtitle ?? 'Add clear, measurable statements.',
      trailing: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add'),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1F2937),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          backgroundColor: const Color(0xFFFFF3C4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      child: Column(
        children: [
          if (items.isEmpty)
            const _InlineEmptyState(
              title: 'No entries yet',
              message: 'Add the first item to get started.',
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(item.id),
                        initialValue: item.text,
                        decoration: InputDecoration(
                          hintText: hintText,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                        onChanged: (value) => onChanged(item.copyWith(text: value)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                      onPressed: () => onDelete(item.id),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.width,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
        ),
      ],
    );

    if (width == null) {
      return field;
    }
    return SizedBox(width: width, child: field);
  }
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.width,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
        ),
      ],
    );

    if (width == null) {
      return field;
    }
    return SizedBox(width: width, child: field);
  }
}

class _EditableTable extends StatelessWidget {
  const _EditableTable({required this.columns, required this.rows});

  final List<_TableColumnDef> columns;
  final List<_EditableRow> rows;

  @override
  Widget build(BuildContext context) {
    final header = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: columns
            .map((column) => SizedBox(
                  width: column.width,
                  child: Text(
                    column.label.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Color(0xFF6B7280)),
                  ),
                ))
            .toList(),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: columns.fold<double>(0, (sum, col) => sum + col.width)),
        child: Column(
          children: [
            header,
            const SizedBox(height: 8),
            for (int i = 0; i < rows.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: i.isEven ? Colors.white : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: rows[i],
              ),
          ],
        ),
      ),
    );
  }
}

class _EditableRow extends StatelessWidget {
  const _EditableRow({super.key, required this.columns, required this.cells});

  final List<_TableColumnDef> columns;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        cells.length,
        (index) => SizedBox(width: columns[index].width, child: cells[index]),
      ),
    );
  }
}

class _TableColumnDef {
  const _TableColumnDef(this.label, this.width);

  final String label;
  final double width;
}

class _TextCell extends StatelessWidget {
  const _TextCell({
    required this.value,
    required this.fieldKey,
    required this.onChanged,
    this.hintText,
  });

  final String value;
  final String fieldKey;
  final String? hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(fieldKey),
      initialValue: value,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
      onChanged: onChanged,
    );
  }
}

class _DropdownCell extends StatelessWidget {
  const _DropdownCell({
    required this.value,
    required this.fieldKey,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final String fieldKey;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final resolvedValue = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<String>(
      key: ValueKey(fieldKey),
      value: resolvedValue,
      items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: InputDecoration(
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
    );
  }
}

class _DeleteCell extends StatelessWidget {
  const _DeleteCell({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: IconButton(
        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
        onPressed: onPressed,
      ),
    );
  }
}

class _ListEntry {
  const _ListEntry({required this.id, required this.text});

  final String id;
  final String text;

  factory _ListEntry.empty() {
    return _ListEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: '',
    );
  }

  _ListEntry copyWith({String? text}) {
    return _ListEntry(id: id, text: text ?? this.text);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
    };
  }

  static List<_ListEntry> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _ListEntry(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        text: data['text']?.toString() ?? '',
      );
    }).toList();
  }
}

class _MilestoneEntry {
  const _MilestoneEntry({
    required this.id,
    required this.title,
    required this.targetDate,
    required this.owner,
    required this.status,
    required this.notes,
  });

  final String id;
  final String title;
  final String targetDate;
  final String owner;
  final String status;
  final String notes;

  factory _MilestoneEntry.empty() {
    return _MilestoneEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: '',
      targetDate: '',
      owner: '',
      status: 'Planned',
      notes: '',
    );
  }

  _MilestoneEntry copyWith({
    String? title,
    String? targetDate,
    String? owner,
    String? status,
    String? notes,
  }) {
    return _MilestoneEntry(
      id: id,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetDate': targetDate,
      'owner': owner,
      'status': status,
      'notes': notes,
    };
  }

  static List<_MilestoneEntry> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _MilestoneEntry(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: data['title']?.toString() ?? '',
        targetDate: data['targetDate']?.toString() ?? '',
        owner: data['owner']?.toString() ?? '',
        status: data['status']?.toString() ?? 'Planned',
        notes: data['notes']?.toString() ?? '',
      );
    }).toList();
  }
}

class _ResourceEntry {
  const _ResourceEntry({
    required this.id,
    required this.role,
    required this.allocation,
    required this.startDate,
    required this.endDate,
    required this.owner,
    required this.notes,
  });

  final String id;
  final String role;
  final String allocation;
  final String startDate;
  final String endDate;
  final String owner;
  final String notes;

  factory _ResourceEntry.empty() {
    return _ResourceEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: '',
      allocation: '',
      startDate: '',
      endDate: '',
      owner: '',
      notes: '',
    );
  }

  _ResourceEntry copyWith({
    String? role,
    String? allocation,
    String? startDate,
    String? endDate,
    String? owner,
    String? notes,
  }) {
    return _ResourceEntry(
      id: id,
      role: role ?? this.role,
      allocation: allocation ?? this.allocation,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      owner: owner ?? this.owner,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'allocation': allocation,
      'startDate': startDate,
      'endDate': endDate,
      'owner': owner,
      'notes': notes,
    };
  }

  static List<_ResourceEntry> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _ResourceEntry(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        role: data['role']?.toString() ?? '',
        allocation: data['allocation']?.toString() ?? '',
        startDate: data['startDate']?.toString() ?? '',
        endDate: data['endDate']?.toString() ?? '',
        owner: data['owner']?.toString() ?? '',
        notes: data['notes']?.toString() ?? '',
      );
    }).toList();
  }
}

class _VendorEntry {
  const _VendorEntry({
    required this.id,
    required this.name,
    required this.service,
    required this.contact,
    required this.status,
    required this.notes,
  });

  final String id;
  final String name;
  final String service;
  final String contact;
  final String status;
  final String notes;

  factory _VendorEntry.empty() {
    return _VendorEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
      service: '',
      contact: '',
      status: 'Planned',
      notes: '',
    );
  }

  _VendorEntry copyWith({
    String? name,
    String? service,
    String? contact,
    String? status,
    String? notes,
  }) {
    return _VendorEntry(
      id: id,
      name: name ?? this.name,
      service: service ?? this.service,
      contact: contact ?? this.contact,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'service': service,
      'contact': contact,
      'status': status,
      'notes': notes,
    };
  }

  static List<_VendorEntry> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _VendorEntry(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: data['name']?.toString() ?? '',
        service: data['service']?.toString() ?? '',
        contact: data['contact']?.toString() ?? '',
        status: data['status']?.toString() ?? 'Planned',
        notes: data['notes']?.toString() ?? '',
      );
    }).toList();
  }
}

class _ToolEntry {
  const _ToolEntry({
    required this.id,
    required this.name,
    required this.purpose,
    required this.owner,
    required this.status,
    required this.notes,
  });

  final String id;
  final String name;
  final String purpose;
  final String owner;
  final String status;
  final String notes;

  factory _ToolEntry.empty() {
    return _ToolEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
      purpose: '',
      owner: '',
      status: 'Planned',
      notes: '',
    );
  }

  _ToolEntry copyWith({
    String? name,
    String? purpose,
    String? owner,
    String? status,
    String? notes,
  }) {
    return _ToolEntry(
      id: id,
      name: name ?? this.name,
      purpose: purpose ?? this.purpose,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'purpose': purpose,
      'owner': owner,
      'status': status,
      'notes': notes,
    };
  }

  static List<_ToolEntry> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _ToolEntry(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: data['name']?.toString() ?? '',
        purpose: data['purpose']?.toString() ?? '',
        owner: data['owner']?.toString() ?? '',
        status: data['status']?.toString() ?? 'Planned',
        notes: data['notes']?.toString() ?? '',
      );
    }).toList();
  }
}

class _TaskEntry {
  const _TaskEntry({
    required this.id,
    required this.title,
    required this.owner,
    required this.startDate,
    required this.dueDate,
    required this.status,
    required this.dependency,
    required this.notes,
  });

  final String id;
  final String title;
  final String owner;
  final String startDate;
  final String dueDate;
  final String status;
  final String dependency;
  final String notes;

  factory _TaskEntry.empty() {
    return _TaskEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: '',
      owner: '',
      startDate: '',
      dueDate: '',
      status: 'Not started',
      dependency: '',
      notes: '',
    );
  }

  _TaskEntry copyWith({
    String? title,
    String? owner,
    String? startDate,
    String? dueDate,
    String? status,
    String? dependency,
    String? notes,
  }) {
    return _TaskEntry(
      id: id,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      dependency: dependency ?? this.dependency,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'owner': owner,
      'startDate': startDate,
      'dueDate': dueDate,
      'status': status,
      'dependency': dependency,
      'notes': notes,
    };
  }

  static List<_TaskEntry> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _TaskEntry(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: data['title']?.toString() ?? '',
        owner: data['owner']?.toString() ?? '',
        startDate: data['startDate']?.toString() ?? '',
        dueDate: data['dueDate']?.toString() ?? '',
        status: data['status']?.toString() ?? 'Not started',
        dependency: data['dependency']?.toString() ?? '',
        notes: data['notes']?.toString() ?? '',
      );
    }).toList();
  }
}

class _BudgetEntry {
  const _BudgetEntry({
    required this.id,
    required this.category,
    required this.estimate,
    required this.actual,
    required this.variance,
    required this.notes,
  });

  final String id;
  final String category;
  final String estimate;
  final String actual;
  final String variance;
  final String notes;

  factory _BudgetEntry.empty() {
    return _BudgetEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: '',
      estimate: '',
      actual: '',
      variance: '',
      notes: '',
    );
  }

  _BudgetEntry copyWith({
    String? category,
    String? estimate,
    String? actual,
    String? variance,
    String? notes,
  }) {
    return _BudgetEntry(
      id: id,
      category: category ?? this.category,
      estimate: estimate ?? this.estimate,
      actual: actual ?? this.actual,
      variance: variance ?? this.variance,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'estimate': estimate,
      'actual': actual,
      'variance': variance,
      'notes': notes,
    };
  }

  static List<_BudgetEntry> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _BudgetEntry(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        category: data['category']?.toString() ?? '',
        estimate: data['estimate']?.toString() ?? '',
        actual: data['actual']?.toString() ?? '',
        variance: data['variance']?.toString() ?? '',
        notes: data['notes']?.toString() ?? '',
      );
    }).toList();
  }
}

class _RiskEntry {
  const _RiskEntry({
    required this.id,
    required this.title,
    required this.impact,
    required this.probability,
    required this.mitigation,
    required this.owner,
    required this.status,
    required this.targetDate,
  });

  final String id;
  final String title;
  final String impact;
  final String probability;
  final String mitigation;
  final String owner;
  final String status;
  final String targetDate;

  factory _RiskEntry.empty() {
    return _RiskEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: '',
      impact: 'Medium',
      probability: 'Medium',
      mitigation: '',
      owner: '',
      status: 'Open',
      targetDate: '',
    );
  }

  _RiskEntry copyWith({
    String? title,
    String? impact,
    String? probability,
    String? mitigation,
    String? owner,
    String? status,
    String? targetDate,
  }) {
    return _RiskEntry(
      id: id,
      title: title ?? this.title,
      impact: impact ?? this.impact,
      probability: probability ?? this.probability,
      mitigation: mitigation ?? this.mitigation,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      targetDate: targetDate ?? this.targetDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'impact': impact,
      'probability': probability,
      'mitigation': mitigation,
      'owner': owner,
      'status': status,
      'targetDate': targetDate,
    };
  }

  static List<_RiskEntry> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _RiskEntry(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: data['title']?.toString() ?? '',
        impact: data['impact']?.toString() ?? 'Medium',
        probability: data['probability']?.toString() ?? 'Medium',
        mitigation: data['mitigation']?.toString() ?? '',
        owner: data['owner']?.toString() ?? '',
        status: data['status']?.toString() ?? 'Open',
        targetDate: data['targetDate']?.toString() ?? '',
      );
    }).toList();
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
