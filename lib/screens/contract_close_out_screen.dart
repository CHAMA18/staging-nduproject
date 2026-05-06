import 'package:flutter/material.dart';

import 'package:ndu_project/models/launch_phase_models.dart';
import 'package:ndu_project/screens/transition_to_prod_team_screen.dart';
import 'package:ndu_project/screens/vendor_account_close_out_screen.dart';
import 'package:ndu_project/services/launch_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/execution_phase_ui.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_data_table.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class ContractCloseOutScreen extends StatefulWidget {
  const ContractCloseOutScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContractCloseOutScreen()),
    );
  }

  @override
  State<ContractCloseOutScreen> createState() => _ContractCloseOutScreenState();
}

class _ContractCloseOutScreenState extends State<ContractCloseOutScreen> {
  List<LaunchContractItem> _contracts = [];
  List<LaunchCloseOutStep> _closeOutSteps = [];
  List<LaunchApproval> _signOffs = [];
  List<LaunchFinancialMetric> _financialSummary = [];

  bool _isLoading = true;
  bool _isGenerating = false;
  bool _hasLoaded = false;
  bool _suspendSave = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  String? get _projectId => ProjectDataHelper.getData(context).projectId;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 980;

    return ResponsiveScaffold(
      activeItemLabel: 'Contract Close Out',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(positioned: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: isMobile ? 16 : 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildMetricsRow(),
            const SizedBox(height: 20),
            _buildFinancialSummaryPanel(),
            const SizedBox(height: 16),
            _buildContractsPanel(),
            const SizedBox(height: 16),
            _buildCloseOutStepsPanel(),
            const SizedBox(height: 16),
            _buildSignOffsPanel(),
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Transition To Production Team',
              nextLabel: 'Next: Vendor Account Close Out',
              onBack: () => TransitionToProdTeamScreen.open(context),
              onNext: () => VendorAccountCloseOutScreen.open(context),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ExecutionPageHeader(
      badge: 'LAUNCH PHASE',
      title: 'Contract Close Out',
      description:
          'Formally close all project contracts, confirm deliverables accepted, and settle financial obligations.',
      trailing: ExecutionActionBar(
        actions: [
          ExecutionActionItem(
            label: 'Import Contracts',
            icon: Icons.download_outlined,
            tone: ExecutionActionTone.secondary,
            onPressed: _importContracts,
          ),
          ExecutionActionItem(
            label: _isGenerating ? 'Generating…' : 'AI Assist',
            icon: Icons.auto_awesome_outlined,
            tone: ExecutionActionTone.ai,
            isLoading: _isGenerating,
            onPressed: _isGenerating ? null : _populateFromAi,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final open = _contracts.where((c) => c.closeOutStatus == 'Open').length;
    final inProgress =
        _contracts.where((c) => c.closeOutStatus == 'In Progress').length;
    final closed = _contracts.where((c) => c.closeOutStatus == 'Closed').length;
    final disputed =
        _contracts.where((c) => c.closeOutStatus == 'Disputed').length;

    return ExecutionMetricsGrid(
      metrics: [
        ExecutionMetricData(
          label: 'Total Contracts',
          value: '${_contracts.length}',
          icon: Icons.description_outlined,
          emphasisColor: const Color(0xFF2563EB),
        ),
        ExecutionMetricData(
          label: 'Open / In Progress',
          value: '$open / $inProgress',
          icon: Icons.pending_outlined,
          emphasisColor: const Color(0xFFF59E0B),
        ),
        ExecutionMetricData(
          label: 'Open',
          value: '$open',
          icon: Icons.pending_outlined,
          emphasisColor: const Color(0xFFF59E0B),
        ),
        ExecutionMetricData(
          label: 'Closed',
          value: '$closed',
          icon: Icons.check_circle_outline,
          emphasisColor: const Color(0xFF10B981),
        ),
        ExecutionMetricData(
          label: 'Disputed',
          value: '$disputed',
          icon: Icons.warning_amber_outlined,
          emphasisColor:
              disputed > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildFinancialSummaryPanel() {
    return LaunchDataTable(
      title: 'Financial Summary',
      subtitle: 'Key financial metrics for contract close-out.',
      columns: const ['Metric', 'Value', 'Notes'],
      rowCount: _financialSummary.length,
      onAdd: () {
        setState(() => _financialSummary.add(LaunchFinancialMetric()));
        _scheduleSave();
      },
      emptyMessage:
          'Track total contract value, payments, and pending amounts.',
      cellBuilder: (context, idx) {
        final item = _financialSummary[idx];
        return LaunchDataRow(
          onDelete: () async {
            final ok = await launchConfirmDelete(context,
                itemName: 'financial metric');
            if (!ok || !mounted) return;
            setState(() => _financialSummary.removeAt(idx));
            _scheduleSave();
          },
          cells: [
            LaunchEditableCell(
              value: item.label,
              hint: 'Metric',
              bold: true,
              expand: true,
              onChanged: (v) {
                _financialSummary[idx] = item.copyWith(label: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.value,
              hint: 'Value',
              width: 120,
              onChanged: (v) {
                _financialSummary[idx] = item.copyWith(value: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.notes,
              hint: 'Notes',
              expand: true,
              onChanged: (v) {
                _financialSummary[idx] = item.copyWith(notes: v);
                _scheduleSave();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildContractsPanel() {
    return LaunchDataTable(
      title: 'Contracts Status',
      subtitle:
          'All contracts requiring close-out. Import from execution or add manually.',
      columns: const ['Contract', 'Vendor', 'Ref', 'Value', 'Status'],
      rowCount: _contracts.length,
      onAdd: () {
        setState(() => _contracts.add(LaunchContractItem()));
        _scheduleSave();
      },
      importLabel: 'Import',
      onImport: _importContracts,
      emptyMessage: 'Import contracts from execution phase or add manually.',
      cellBuilder: (context, idx) {
        final item = _contracts[idx];
        return LaunchDataRow(
          onDelete: () async {
            final ok = await launchConfirmDelete(context, itemName: 'contract');
            if (!ok || !mounted) return;
            setState(() => _contracts.removeAt(idx));
            _scheduleSave();
          },
          cells: [
            LaunchEditableCell(
              value: item.contractName,
              hint: 'Contract',
              bold: true,
              expand: true,
              onChanged: (v) {
                _contracts[idx] = item.copyWith(contractName: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.vendor,
              hint: 'Vendor',
              width: 120,
              onChanged: (v) {
                _contracts[idx] = item.copyWith(vendor: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.contractRef,
              hint: 'Ref',
              width: 80,
              onChanged: (v) {
                _contracts[idx] = item.copyWith(contractRef: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.value,
              hint: 'Value',
              width: 80,
              onChanged: (v) {
                _contracts[idx] = item.copyWith(value: v);
                _scheduleSave();
              },
            ),
            LaunchStatusDropdown(
              value: item.closeOutStatus,
              items: LaunchContractItem.closeOutStatuses,
              onChanged: (v) {
                if (v == null) return;
                _contracts[idx] = item.copyWith(closeOutStatus: v);
                _scheduleSave();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCloseOutStepsPanel() {
    return LaunchDataTable(
      title: 'Close-Out Steps',
      subtitle: 'Standardized steps to verify each contract is fully closed.',
      columns: const ['Step', 'Contract Ref', 'Status', 'Notes'],
      rowCount: _closeOutSteps.length,
      onAdd: () {
        setState(() => _closeOutSteps.add(LaunchCloseOutStep()));
        _scheduleSave();
      },
      emptyMessage:
          'Add steps like: final deliverable accepted, payments settled, warranties confirmed.',
      cellBuilder: (context, idx) {
        final item = _closeOutSteps[idx];
        return LaunchDataRow(
          onDelete: () async {
            final ok =
                await launchConfirmDelete(context, itemName: 'close-out step');
            if (!ok || !mounted) return;
            setState(() => _closeOutSteps.removeAt(idx));
            _scheduleSave();
          },
          cells: [
            LaunchEditableCell(
              value: item.step,
              hint: 'Step',
              bold: true,
              expand: true,
              onChanged: (v) {
                _closeOutSteps[idx] = item.copyWith(step: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.contractRef,
              hint: 'Ref',
              width: 100,
              onChanged: (v) {
                _closeOutSteps[idx] = item.copyWith(contractRef: v);
                _scheduleSave();
              },
            ),
            LaunchStatusDropdown(
              value: item.status,
              items: const ['Pending', 'In Progress', 'Complete'],
              onChanged: (v) {
                if (v == null) return;
                _closeOutSteps[idx] = item.copyWith(status: v);
                _scheduleSave();
                setState(() {});
              },
            ),
            LaunchEditableCell(
              value: item.notes,
              hint: 'Notes',
              expand: true,
              onChanged: (v) {
                _closeOutSteps[idx] = item.copyWith(notes: v);
                _scheduleSave();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSignOffsPanel() {
    return LaunchDataTable(
      title: 'Financial & Compliance Sign-Off',
      subtitle: 'Track approvals from finance, legal, and compliance.',
      columns: const ['Approver', 'Role', 'Status', 'Date', 'Notes'],
      rowCount: _signOffs.length,
      onAdd: () {
        setState(() => _signOffs.add(LaunchApproval()));
        _scheduleSave();
      },
      emptyMessage: 'Track finance and compliance approval status.',
      cellBuilder: (context, idx) {
        final item = _signOffs[idx];
        return LaunchDataRow(
          onDelete: () async {
            final ok = await launchConfirmDelete(context, itemName: 'sign-off');
            if (!ok || !mounted) return;
            setState(() => _signOffs.removeAt(idx));
            _scheduleSave();
          },
          cells: [
            LaunchEditableCell(
              value: item.stakeholder,
              hint: 'Name',
              bold: true,
              expand: true,
              onChanged: (v) {
                _signOffs[idx] = item.copyWith(stakeholder: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.role,
              hint: 'Role',
              expand: true,
              onChanged: (v) {
                _signOffs[idx] = item.copyWith(role: v);
                _scheduleSave();
              },
            ),
            LaunchStatusDropdown(
              value: item.status,
              items: const ['Pending', 'Approved', 'Rejected'],
              onChanged: (v) {
                if (v == null) return;
                _signOffs[idx] = item.copyWith(status: v);
                _scheduleSave();
                setState(() {});
              },
            ),
            LaunchDateCell(
              value: item.date,
              hint: 'Date',
              width: 90,
              onChanged: (v) {
                _signOffs[idx] = item.copyWith(date: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.notes,
              hint: 'Notes',
              expand: true,
              onChanged: (v) {
                _signOffs[idx] = item.copyWith(notes: v);
                _scheduleSave();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _importContracts() async {
    if (_projectId == null) return;
    final imported =
        await LaunchPhaseService.loadExecutionContracts(_projectId!);
    if (imported.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No contracts found to import.')));
      }
      return;
    }
    setState(() {
      final existing = _contracts.map((c) => c.contractName).toSet();
      for (final c in imported) {
        if (!existing.contains(c.contractName)) _contracts.add(c);
      }
    });
    _scheduleSave();
  }

  void _scheduleSave() {
    if (_suspendSave || !_hasLoaded) return;
    Future.microtask(() {
      if (mounted) _persistData();
    });
  }

  Future<void> _loadData() async {
    if (_hasLoaded || _projectId == null) return;
    _suspendSave = true;
    try {
      final r =
          await LaunchPhaseService.loadContractCloseOut(projectId: _projectId!);
      if (!mounted) return;
      setState(() {
        _contracts = r.contracts;
        _closeOutSteps = r.closeOutSteps;
        _signOffs = r.signOffs;
        _financialSummary = r.financialSummary;
        _isLoading = false;
        _hasLoaded = true;
      });
      if (_contracts.isEmpty) {
        await _importContracts();
        if (!mounted) return;
        setState(() {});
      }
      if (_contracts.isEmpty &&
          _closeOutSteps.isEmpty &&
          _signOffs.isEmpty &&
          _financialSummary.isEmpty) {
        await _populateFromAi();
      }
    } catch (e) {
      debugPrint('Contract close-out load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
    _suspendSave = false;
  }

  Future<void> _persistData() async {
    if (_projectId == null) return;
    try {
      await LaunchPhaseService.saveContractCloseOut(
        projectId: _projectId!,
        contracts: _contracts,
        closeOutSteps: _closeOutSteps,
        signOffs: _signOffs,
        financialSummary: _financialSummary,
      );
    } catch (e) {
      debugPrint('Contract close-out save error: $e');
    }
  }

  Future<void> _populateFromAi() async {
    if (_isGenerating) return;
    final data = ProjectDataHelper.getData(context);
    var ctx = ProjectDataHelper.buildExecutivePlanContext(data,
        sectionLabel: 'Contract Close Out');
    if (ctx.trim().isEmpty) {
      ctx = ProjectDataHelper.buildProjectContextScan(data,
          sectionLabel: 'Contract Close Out');
    }
    if (ctx.trim().isEmpty) return;

    if (_projectId != null) {
      final contracts = await LaunchPhaseService.loadExecutionContracts(_projectId!);
      final budgetRows = await LaunchPhaseService.loadBudgetRows(_projectId!);
      if (mounted) {
        final contractsSummary = contracts.isEmpty ? 'No contract data.' : contracts.map((c) => '- ${c.contractName} (vendor: ${c.vendor}, value: ${c.value}, status: ${c.closeOutStatus})').take(8).join('\n');
        final budgetSummary = budgetRows.isEmpty ? 'No budget data.' : budgetRows.map((b) => '- ${b['category'] ?? 'Unknown'}: planned ${b['plannedAmount'] ?? '0'}, actual ${b['actualAmount'] ?? '0'}').take(8).join('\n');
        ctx = ProjectDataHelper.buildLaunchPhaseContext(
          baseContext: ctx,
          sectionLabel: 'Contract Close Out',
          contractsSummary: contractsSummary,
          budgetSummary: budgetSummary,
        );
      }
    }

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> gen = {};
    try {
      gen = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: ctx,
        sections: const {
          'financial_summary':
              'Financial metrics with "label", "value", "notes"',
          'contracts': 'Contracts with "contract_name", "vendor", "value", "close_out_status"',
          'closeout_steps': 'Close-out verification steps with "step", "status", "notes"',
          'signoffs': 'Finance and compliance approvers with "stakeholder", "role", "status"',
        },
        itemsPerSection: 3,
      );
    } catch (e) {
      debugPrint('Contract AI error: $e');
    }
    if (!mounted) return;
    final hasData = _contracts.isNotEmpty ||
        _closeOutSteps.isNotEmpty ||
        _signOffs.isNotEmpty ||
        _financialSummary.isNotEmpty;
    if (hasData) {
      setState(() => _isGenerating = false);
      return;
    }
    setState(() {
      _financialSummary = _mapMetrics(gen['financial_summary']);
      _contracts = _mapContracts(gen['contracts']);
      _closeOutSteps = _mapSteps(gen['closeout_steps']);
      _signOffs = _mapApprovals(gen['signoffs']);
      _isGenerating = false;
    });
    await _persistData();
  }

  List<LaunchFinancialMetric> _mapMetrics(List<Map<String, dynamic>>? r) =>
      (r ?? [])
          .map((m) => LaunchFinancialMetric(
              label: (m['title'] ?? '').toString().trim(),
              value: (m['details'] ?? '').toString().trim()))
          .where((i) => i.label.isNotEmpty)
          .toList();
  List<LaunchContractItem> _mapContracts(
          List<Map<String, dynamic>>? r) =>
      (r ?? [])
          .map((m) => LaunchContractItem(
              contractName: (m['title'] ?? '').toString().trim(),
              vendor: (m['details'] ?? '').toString().trim(),
              closeOutStatus: _ns(m['status'], 'Open')))
          .where((i) => i.contractName.isNotEmpty)
          .toList();
  List<LaunchCloseOutStep> _mapSteps(List<Map<String, dynamic>>? r) => (r ?? [])
      .map((m) => LaunchCloseOutStep(
          step: (m['title'] ?? '').toString().trim(),
          notes: (m['details'] ?? '').toString().trim(),
          status: _ns(m['status'], 'Pending')))
      .where((i) => i.step.isNotEmpty)
      .toList();
  List<LaunchApproval> _mapApprovals(List<Map<String, dynamic>>? r) => (r ?? [])
      .map((m) => LaunchApproval(
          stakeholder: (m['title'] ?? '').toString().trim(),
          role: (m['details'] ?? '').toString().trim(),
          status: _ns(m['status'], 'Pending')))
      .where((i) => i.stakeholder.isNotEmpty)
      .toList();
  String _ns(dynamic v, String fb) =>
      (v ?? '').toString().trim().isEmpty ? fb : v.toString().trim();
}
