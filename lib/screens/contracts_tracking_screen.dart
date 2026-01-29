import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/progress_tracking_screen.dart';
import 'package:ndu_project/screens/vendor_tracking_screen.dart';
import 'package:ndu_project/services/contract_service.dart';
import 'package:ndu_project/services/execution_phase_service.dart';
import 'package:ndu_project/utils/auto_bullet_text_controller.dart';
import 'package:ndu_project/widgets/contracts_table_widget.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class ContractsTrackingScreen extends StatefulWidget {
  const ContractsTrackingScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContractsTrackingScreen()),
    );
  }

  @override
  State<ContractsTrackingScreen> createState() =>
      _ContractsTrackingScreenState();
}

class _ContractsTrackingScreenState extends State<ContractsTrackingScreen> {
  final Set<String> _selectedFilters = {'All contracts'};
  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;

  List<_RenewalLaneData> _renewalLanes = [];
  List<_RiskSignalData> _riskSignals = [];
  List<_ApprovalCheckpointData> _approvalCheckpoints = [];

  static const List<String> _riskStatusOptions = [
    'On track',
    'At risk',
    'Needs review',
    'Blocked',
  ];

  static const List<String> _approvalStatusOptions = [
    'Pending',
    'In review',
    'Complete',
    'Scheduled',
  ];

  String? get _projectId {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _renewalLanes = _defaultRenewalLanes();
    _riskSignals = _defaultRiskSignals();
    _approvalCheckpoints = _defaultApprovalCheckpoints();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrackingData());
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> _trackingDoc(String projectId) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('execution_phase_sections')
        .doc('contracts_tracking');
  }

  void _scheduleSave() {
    if (_suspendSave) return;
    _saveDebouncer.run(_saveTrackingData);
  }

  Future<void> _loadTrackingData() async {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final doc = await _trackingDoc(projectId).get();
      final data = doc.data() ?? {};
      _suspendSave = true;
      if (!mounted) return;
      setState(() {
        final lanes = _RenewalLaneData.fromList(data['renewalLanes']);
        final signals = _RiskSignalData.fromList(data['riskSignals']);
        final approvals =
            _ApprovalCheckpointData.fromList(data['approvalCheckpoints']);
        _renewalLanes = lanes.isEmpty ? _defaultRenewalLanes() : lanes;
        _riskSignals = signals.isEmpty ? _defaultRiskSignals() : signals;
        _approvalCheckpoints =
            approvals.isEmpty ? _defaultApprovalCheckpoints() : approvals;
      });
    } catch (error) {
      debugPrint('Contracts tracking load error: $error');
    } finally {
      _suspendSave = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTrackingData() async {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) return;
    try {
      await _trackingDoc(projectId).set({
        'renewalLanes': _renewalLanes.map((e) => e.toMap()).toList(),
        'riskSignals': _riskSignals.map((e) => e.toMap()).toList(),
        'approvalCheckpoints':
            _approvalCheckpoints.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Contracts tracking save error: $error');
    }
  }

  List<_RenewalLaneData> _defaultRenewalLanes() {
    return [
      _RenewalLaneData(
          id: _newId(),
          label: '30 days',
          count: '0',
          note: 'Immediate renewals',
          color: const Color(0xFFF97316)),
      _RenewalLaneData(
          id: _newId(),
          label: '60 days',
          count: '0',
          note: 'Prepare negotiation pack',
          color: const Color(0xFF6366F1)),
      _RenewalLaneData(
          id: _newId(),
          label: '90 days',
          count: '0',
          note: 'Pipeline planning',
          color: const Color(0xFF10B981)),
    ];
  }

  List<_RiskSignalData> _defaultRiskSignals() {
    return [
      _RiskSignalData(
          id: _newId(),
          title: 'Renewal risk flagged',
          detail: 'Track renewals with expiring SLAs',
          owner: 'Legal',
          status: 'Needs review'),
    ];
  }

  List<_ApprovalCheckpointData> _defaultApprovalCheckpoints() {
    return [
      _ApprovalCheckpointData(
          id: _newId(),
          title: 'Legal review queue',
          status: 'Pending',
          owner: 'Legal',
          dueDate: 'TBD'),
      _ApprovalCheckpointData(
          id: _newId(),
          title: 'Finance sign-off',
          status: 'Complete',
          owner: 'Finance',
          dueDate: 'TBD'),
    ];
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Contracts Tracking',
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                if (_isLoading) const SizedBox(height: 16),
                _buildHeader(isNarrow),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 20),
                _buildStatsRow(isNarrow),
                const SizedBox(height: 24),
                Column(
                  children: [
                    _buildContractRegister(),
                    const SizedBox(height: 20),
                    _buildRenewalPanel(),
                    const SizedBox(height: 20),
                    _buildSignalsPanel(),
                    const SizedBox(height: 20),
                    _buildApprovalsPanel(),
                  ],
                ),
                const SizedBox(height: 24),
                LaunchPhaseNavigation(
                  backLabel: 'Back: Progress Tracking',
                  nextLabel: 'Next: Vendor Tracking',
                  onBack: () => ProgressTrackingScreen.open(context),
                  onNext: () => VendorTrackingScreen.open(context),
                ),
              ],
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'CONTRACT CONTROL',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Contracts Tracking',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Track renewals, approvals, and compliance milestones for critical vendor contracts.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (!isNarrow) _buildHeaderActions(),
          ],
        ),
        if (isNarrow) ...[
          const SizedBox(height: 12),
          _buildHeaderActions(),
        ],
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _actionButton(Icons.add, 'Add contract',
            onPressed: () => _showAddContractDialog(context)),
        _actionButton(Icons.upload_outlined, 'Upload addendum'),
        _actionButton(Icons.description_outlined, 'Export register'),
        _primaryButton('Start renewal review'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      label: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _primaryButton(String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.play_arrow, size: 18),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = [
      'All contracts',
      'Renewal due',
      'At risk',
      'Pending sign-off',
      'Archived'
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((filter) {
        final selected = _selectedFilters.contains(filter);
        return ChoiceChip(
          label: Text(
            filter,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
          ),
          selected: selected,
          selectedColor: const Color(0xFF111827),
          backgroundColor: Colors.white,
          shape: StadiumBorder(
            side: BorderSide(color: const Color(0xFFE5E7EB)),
          ),
          onSelected: (value) {
            setState(() {
              if (value) {
                if (filter == 'All contracts') {
                  _selectedFilters
                    ..clear()
                    ..add(filter);
                } else {
                  _selectedFilters
                    ..remove('All contracts')
                    ..add(filter);
                }
              } else {
                _selectedFilters.remove(filter);
                if (_selectedFilters.isEmpty) {
                  _selectedFilters.add('All contracts');
                }
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow(bool isNarrow) {
    if (_projectId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<ContractModel>>(
      stream: ContractService.streamContracts(_projectId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final contracts = snapshot.data!;
        final activeCount = contracts.where((c) => c.status == 'Active').length;
        final renewalDue = contracts.where((c) {
          final daysUntilRenewal = c.endDate.difference(DateTime.now()).inDays;
          return daysUntilRenewal <= 30 && daysUntilRenewal > 0;
        }).length;
        final totalValue =
            contracts.fold<double>(0.0, (sum, c) => sum + c.estimatedValue);
        final atRiskCount =
            contracts.where((c) => c.status == 'At risk').length;

        final stats = [
          _StatCardData('Active Contracts', '$activeCount',
              '${contracts.length} total', const Color(0xFF0EA5E9)),
          _StatCardData(
              'Total Committed Value',
              '\$${(totalValue / 1000000).toStringAsFixed(1)}M',
              'FY spend',
              const Color(0xFF10B981)),
          _StatCardData('Upcoming Renewals', '$renewalDue', 'Next 30-60 days',
              const Color(0xFFF97316)),
          _StatCardData(
              'At Risk',
              '$atRiskCount',
              atRiskCount > 0 ? 'Require attention' : 'All stable',
              const Color(0xFF6366F1)),
        ];

        if (isNarrow) {
          return Column(
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                SizedBox(
                    width: double.infinity, child: _buildStatCard(stats[i])),
                if (i < stats.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < stats.length; i++) ...[
              Expanded(child: _buildStatCard(stats[i])),
              if (i < stats.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: data.color)),
          const SizedBox(height: 6),
          Text(data.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(data.supporting,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: data.color)),
        ],
      ),
    );
  }

  Widget _buildContractRegister() {
    if (_projectId == null) {
      return _PanelShell(
        title: 'Contract register',
        subtitle: 'Track scope, owners, and renewal milestones',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('No project selected. Please open a project first.',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
        ),
      );
    }

    return _PanelShell(
      title: 'Contract register',
      subtitle: 'Track scope, owners, and renewal milestones',
      trailing: _actionButton(Icons.filter_list, 'Filter'),
      child: StreamBuilder<List<ContractModel>>(
        stream: ContractService.streamContracts(_projectId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator()));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading contracts: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          final contracts = snapshot.data ?? [];
          final filteredContracts = _filterContracts(contracts);

          if (filteredContracts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('No contracts found.',
                        style: TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddContractDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add First Contract'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ContractsTableWidget(
            contracts: filteredContracts,
            onContractUpdated: (updated) async {
              await _updateContract(updated);
            },
            onContractDeleted: (deleted) async {
              await _deleteContract(deleted);
            },
          );
        },
      ),
    );
  }

  List<ContractModel> _filterContracts(List<ContractModel> contracts) {
    if (_selectedFilters.contains('All contracts')) return contracts;
    return contracts.where((c) {
      if (_selectedFilters.contains('Renewal due')) {
        final daysUntilRenewal = c.endDate.difference(DateTime.now()).inDays;
        return daysUntilRenewal <= 60 && daysUntilRenewal > 0;
      }
      if (_selectedFilters.contains('At risk')) {
        final daysUntilRenewal = c.endDate.difference(DateTime.now()).inDays;
        return daysUntilRenewal <= 30 &&
            daysUntilRenewal > 0 &&
            c.status != 'Expired';
      }
      if (_selectedFilters.contains('Pending sign-off') && c.status == 'Draft')
        return true;
      if (_selectedFilters.contains('Archived') && c.status == 'Expired')
        return true;
      return false;
    }).toList();
  }

  Widget _buildRenewalPanel() {
    if (_projectId == null) {
      return _PanelShell(
        title: 'Renewal pipeline',
        subtitle: 'Contracts rolling into renewal windows',
        child: const SizedBox.shrink(),
      );
    }

    return _PanelShell(
      title: 'Renewal pipeline',
      subtitle: 'Contracts rolling into renewal windows',
      trailing: TextButton.icon(
        onPressed: _addRenewalLane,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add lane'),
      ),
      child: Column(
        children: _renewalLanes.map(_buildRenewalLane).toList(),
      ),
    );
  }

  Widget _buildSignalsPanel() {
    if (_projectId == null) {
      return _PanelShell(
        title: 'Risk signals',
        subtitle: 'Items that need attention this week',
        child: const SizedBox.shrink(),
      );
    }

    return _PanelShell(
      title: 'Risk signals',
      subtitle: 'Items that need attention this week',
      trailing: TextButton.icon(
        onPressed: _addRiskSignal,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add signal'),
      ),
      child: Column(
        children: _riskSignals.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No active risk signals',
                      style: TextStyle(color: Color(0xFF10B981))),
                ),
              ]
            : _riskSignals.map(_buildRiskSignal).toList(),
      ),
    );
  }

  Widget _buildApprovalsPanel() {
    return _PanelShell(
      title: 'Approval readiness',
      subtitle: 'Legal and finance checkpoints',
      trailing: TextButton.icon(
        onPressed: _addApprovalCheckpoint,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add checkpoint'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _approvalCheckpoints.map(_buildApprovalCheckpoint).toList(),
      ),
    );
  }

  Future<void> _updateContract(ContractModel contract) async {
    final projectId = _projectId;
    if (projectId == null) return;

    try {
      await ContractService.updateContract(
        projectId: projectId,
        contractId: contract.id,
        name: contract.name,
        description: contract.description,
        contractType: contract.contractType,
        paymentType: contract.paymentType,
        status: contract.status,
        estimatedValue: contract.estimatedValue,
        startDate: contract.startDate,
        endDate: contract.endDate,
        scope: contract.scope,
        discipline: contract.discipline,
        notes: contract.notes,
      );
      // Sync to Progress Tracking budget (only if value changed)
      // Note: Budget sync is handled in ContractsTableWidget._updateContract
      // This is a fallback for direct updates
    } catch (e) {
      debugPrint('Error updating contract: $e');
    }
  }

  Future<void> _deleteContract(ContractModel contract) async {
    final projectId = _projectId;
    if (projectId == null) return;

    try {
      await ContractService.deleteContract(
        projectId: projectId,
        contractId: contract.id,
      );
      // Sync to Progress Tracking budget (remove value)
      await _syncContractValueToBudget(contract, isDelete: true);
    } catch (e) {
      debugPrint('Error deleting contract: $e');
    }
  }

  Future<void> _restoreContract(ContractModel contract) async {
    final projectId = _projectId;
    if (projectId == null) return;

    try {
      // Recreate the contract
      final user = FirebaseAuth.instance.currentUser;
      await ContractService.createContract(
        projectId: projectId,
        name: contract.name,
        description: contract.description,
        contractType: contract.contractType,
        paymentType: contract.paymentType,
        status: contract.status,
        estimatedValue: contract.estimatedValue,
        startDate: contract.startDate,
        endDate: contract.endDate,
        scope: contract.scope,
        discipline: contract.discipline,
        notes: contract.notes,
        createdById: contract.createdById,
        createdByEmail: contract.createdByEmail,
        createdByName: contract.createdByName,
      );
      // Sync to budget
      await _syncContractValueToBudget(contract, isDelete: false);
    } catch (e) {
      debugPrint('Error restoring contract: $e');
    }
  }

  Future<void> _syncContractValueToBudget(ContractModel contract,
      {bool isDelete = false}) async {
    final projectId = _projectId;
    if (projectId == null) return;

    try {
      await ExecutionPhaseService.syncContractValueToBudget(
        projectId: projectId,
        contractValue: contract.estimatedValue,
        contractName: contract.name,
        isDelete: isDelete,
        userId: FirebaseAuth.instance.currentUser?.uid,
      );
    } catch (e) {
      debugPrint('Error syncing contract value to budget: $e');
      // Don't show error to user - budget sync is background operation
    }
  }

  Widget _buildRenewalLane(_RenewalLaneData lane) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: lane.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              initialValue: lane.label,
              decoration: _inlineDecoration('Lane label'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              onChanged: (value) =>
                  _updateRenewalLane(lane.copyWith(label: value)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: TextFormField(
              initialValue: lane.count,
              decoration: _inlineDecoration('Count'),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  _updateRenewalLane(lane.copyWith(count: value)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              initialValue: lane.note,
              decoration: _inlineDecoration('Note'),
              onChanged: (value) =>
                  _updateRenewalLane(lane.copyWith(note: value)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => _deleteRenewalLane(lane.id),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSignal(_RiskSignalData signal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: signal.title,
            decoration: _inlineDecoration('Signal title'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            onChanged: (value) =>
                _updateRiskSignal(signal.copyWith(title: value)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: signal.detail,
            decoration: _inlineDecoration('Detail'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            onChanged: (value) =>
                _updateRiskSignal(signal.copyWith(detail: value)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: signal.owner,
                  decoration: _inlineDecoration('Owner'),
                  onChanged: (value) =>
                      _updateRiskSignal(signal.copyWith(owner: value)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _riskStatusOptions.contains(signal.status)
                      ? signal.status
                      : _riskStatusOptions.first,
                  decoration: _inlineDecoration('Status'),
                  items: _riskStatusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => _updateRiskSignal(signal.copyWith(
                      status: value ?? _riskStatusOptions.first)),
                ),
              ),
              IconButton(
                icon:
                    const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                onPressed: () => _deleteRiskSignal(signal.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCheckpoint(_ApprovalCheckpointData checkpoint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: checkpoint.title,
              decoration: _inlineDecoration('Checkpoint'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              onChanged: (value) =>
                  _updateApprovalCheckpoint(checkpoint.copyWith(title: value)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String>(
              initialValue: _approvalStatusOptions.contains(checkpoint.status)
                  ? checkpoint.status
                  : _approvalStatusOptions.first,
              decoration: _inlineDecoration('Status'),
              items: _approvalStatusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) => _updateApprovalCheckpoint(checkpoint
                  .copyWith(status: value ?? _approvalStatusOptions.first)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              initialValue: checkpoint.owner,
              decoration: _inlineDecoration('Owner'),
              onChanged: (value) =>
                  _updateApprovalCheckpoint(checkpoint.copyWith(owner: value)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: TextFormField(
              initialValue: checkpoint.dueDate,
              decoration: _inlineDecoration('Due date'),
              onChanged: (value) => _updateApprovalCheckpoint(
                  checkpoint.copyWith(dueDate: value)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => _deleteApprovalCheckpoint(checkpoint.id),
          ),
        ],
      ),
    );
  }

  void _addRenewalLane() {
    setState(() {
      _renewalLanes.add(_RenewalLaneData(
        id: _newId(),
        label: '',
        count: '',
        note: '',
        color: const Color(0xFFF97316),
      ));
    });
    _scheduleSave();
  }

  void _updateRenewalLane(_RenewalLaneData lane) {
    final index = _renewalLanes.indexWhere((item) => item.id == lane.id);
    if (index == -1) return;
    setState(() => _renewalLanes[index] = lane);
    _scheduleSave();
  }

  void _deleteRenewalLane(String id) {
    setState(() => _renewalLanes.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addRiskSignal() {
    setState(() {
      _riskSignals.add(_RiskSignalData(
        id: _newId(),
        title: '',
        detail: '',
        owner: '',
        status: _riskStatusOptions.first,
      ));
    });
    _scheduleSave();
  }

  void _updateRiskSignal(_RiskSignalData signal) {
    final index = _riskSignals.indexWhere((item) => item.id == signal.id);
    if (index == -1) return;
    setState(() => _riskSignals[index] = signal);
    _scheduleSave();
  }

  void _deleteRiskSignal(String id) {
    setState(() => _riskSignals.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addApprovalCheckpoint() {
    setState(() {
      _approvalCheckpoints.add(_ApprovalCheckpointData(
        id: _newId(),
        title: '',
        status: _approvalStatusOptions.first,
        owner: '',
        dueDate: '',
      ));
    });
    _scheduleSave();
  }

  void _updateApprovalCheckpoint(_ApprovalCheckpointData checkpoint) {
    final index =
        _approvalCheckpoints.indexWhere((item) => item.id == checkpoint.id);
    if (index == -1) return;
    setState(() => _approvalCheckpoints[index] = checkpoint);
    _scheduleSave();
  }

  void _deleteApprovalCheckpoint(String id) {
    setState(() => _approvalCheckpoints.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  InputDecoration _inlineDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
      ),
    );
  }

  void _showAddContractDialog(BuildContext context) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showContractDialog(context, null, projectId);
  }

  void _showEditContractDialog(BuildContext context, ContractModel contract) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showContractDialog(context, contract, projectId);
  }

  Future<void> _showContractDialog(
      BuildContext context, ContractModel? contract, String projectId) async {
    final isEdit = contract != null;

    // Load External/Contractor roles from Staff Needs
    List<String> externalRoles = [];
    try {
      final staffRows =
          await ExecutionPhaseService.loadStaffingRows(projectId: projectId);
      externalRoles = staffRows
          .where((row) => !row.isInternal) // External/Contractor roles
          .map((row) => row.role)
          .where((role) => role.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error loading staff roles: $e');
    }

    final nameController = TextEditingController(text: contract?.name ?? '');
    final descriptionController =
        TextEditingController(text: contract?.description ?? '');
    final contractTypeController =
        TextEditingController(text: contract?.contractType ?? '');
    final paymentTypeController =
        TextEditingController(text: contract?.paymentType ?? '');
    var selectedStatus = contract?.status ?? 'Draft';
    final estimatedValueController =
        TextEditingController(text: contract?.estimatedValue.toString() ?? '0');
    // Key Terms (scope) - use AutoBulletTextController
    final scopeController =
        contract?.scope != null && contract!.scope.isNotEmpty
            ? AutoBulletTextController(text: contract.scope)
            : AutoBulletTextController();
    final disciplineController =
        TextEditingController(text: contract?.discipline ?? '');
    // Contract Notes - regular TextEditingController (prose)
    final notesController = TextEditingController(text: contract?.notes ?? '');
    DateTime? startDate = contract?.startDate;
    DateTime? endDate = contract?.endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Contract' : 'Add New Contract'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vendor/Party Name with suggestions from External roles
                if (externalRoles.isNotEmpty && !isEdit) ...[
                  Text(
                    'Suggested from External/Contractor roles:',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: externalRoles.take(5).map((role) {
                      return ActionChip(
                        label: Text(role, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          nameController.text = role;
                          setDialogState(() {});
                        },
                        backgroundColor: const Color(0xFFF3F4F6),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Vendor/Party Name *',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: contractTypeController.text.isEmpty
                      ? null
                      : contractTypeController.text,
                  decoration: const InputDecoration(
                    labelText: 'Contract Type *',
                    isDense: true,
                  ),
                  items: const [
                    'Service Level Agreement (SLA)',
                    'NDA',
                    'Procurement',
                    'Employment',
                  ]
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      contractTypeController.text = v;
                      setDialogState(() {});
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paymentTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Type *',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus.isEmpty ? null : selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status *',
                    isDense: true,
                  ),
                  items: const [
                    'Draft',
                    'Signed',
                    'Active',
                    'Expired',
                  ]
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setDialogState(() => selectedStatus = v ?? 'Draft');
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: estimatedValueController,
                  decoration: const InputDecoration(
                    labelText: 'Total Value *',
                    hintText: 'e.g., 1000000',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                      'Effective Date: ${startDate != null ? DateFormat('MMM dd, yyyy').format(startDate!) : 'Not set'}'),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setDialogState(() => startDate = date);
                  },
                ),
                ListTile(
                  title: Text(
                      'Expiry Date: ${endDate != null ? DateFormat('MMM dd, yyyy').format(endDate!) : 'Not set'}'),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setDialogState(() => endDate = date);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scopeController,
                  decoration: const InputDecoration(
                    labelText: 'Key Terms',
                    hintText: 'Use "." bullet format',
                    isDense: true,
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: disciplineController,
                  decoration: const InputDecoration(
                    labelText: 'Discipline',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Contract Notes',
                    hintText: 'Prose description, no bullets',
                    isDense: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    startDate == null ||
                    endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final estimatedValue =
                      double.tryParse(estimatedValueController.text) ?? 0.0;

                  if (isEdit) {
                    await ContractService.updateContract(
                      projectId: projectId,
                      contractId: contract.id,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      contractType: contractTypeController.text.trim(),
                      paymentType: paymentTypeController.text.trim(),
                      status: selectedStatus,
                      estimatedValue: estimatedValue,
                      startDate: startDate!,
                      endDate: endDate!,
                      scope: scopeController.text.trim(),
                      discipline: disciplineController.text.trim(),
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );
                    // Sync to Progress Tracking budget
                    final updatedContract = ContractModel(
                      id: contract.id,
                      projectId: projectId,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      contractType: contractTypeController.text.trim(),
                      paymentType: paymentTypeController.text.trim(),
                      status: selectedStatus,
                      estimatedValue: estimatedValue,
                      startDate: startDate!,
                      endDate: endDate!,
                      scope: scopeController.text.trim(),
                      discipline: disciplineController.text.trim(),
                      notes: notesController.text.trim(),
                      createdById: contract.createdById,
                      createdByEmail: contract.createdByEmail,
                      createdByName: contract.createdByName,
                      createdAt: contract.createdAt,
                      updatedAt: DateTime.now(),
                    );
                    await _syncContractValueToBudget(updatedContract);
                  } else {
                    final contractId = await ContractService.createContract(
                      projectId: projectId,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      contractType: contractTypeController.text.trim(),
                      paymentType: paymentTypeController.text.trim(),
                      status: selectedStatus,
                      estimatedValue: estimatedValue,
                      startDate: startDate!,
                      endDate: endDate!,
                      scope: scopeController.text.trim(),
                      discipline: disciplineController.text.trim(),
                      notes: notesController.text.trim(),
                      createdById: user?.uid ?? '',
                      createdByEmail: user?.email ?? '',
                      createdByName: user?.displayName ??
                          user?.email?.split('@').first ??
                          '',
                    );
                    // Sync to Progress Tracking budget
                    final newContract = await ContractService.getContract(
                      projectId: projectId,
                      contractId: contractId,
                    );
                    if (newContract != null) {
                      await _syncContractValueToBudget(newContract);
                    }
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteContractDialog(BuildContext context, ContractModel contract) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contract'),
        content: Text(
            'Are you sure you want to delete "${contract.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ContractService.deleteContract(
                    projectId: projectId, contractId: contract.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Contract deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting contract: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
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

class _RenewalLaneData {
  const _RenewalLaneData({
    required this.id,
    required this.label,
    required this.count,
    required this.note,
    required this.color,
  });

  final String id;
  final String label;
  final String count;
  final String note;
  final Color color;

  _RenewalLaneData copyWith(
      {String? label, String? count, String? note, Color? color}) {
    return _RenewalLaneData(
      id: id,
      label: label ?? this.label,
      count: count ?? this.count,
      note: note ?? this.note,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'count': count,
        'note': note,
        'color': color.value,
      };

  static List<_RenewalLaneData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _RenewalLaneData(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        count: map['count']?.toString() ?? '',
        note: map['note']?.toString() ?? '',
        color: Color(map['color'] is int
            ? map['color'] as int
            : const Color(0xFFF97316).value),
      );
    }).toList();
  }
}

class _RiskSignalData {
  const _RiskSignalData({
    required this.id,
    required this.title,
    required this.detail,
    required this.owner,
    required this.status,
  });

  final String id;
  final String title;
  final String detail;
  final String owner;
  final String status;

  _RiskSignalData copyWith(
      {String? title, String? detail, String? owner, String? status}) {
    return _RiskSignalData(
      id: id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      owner: owner ?? this.owner,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'detail': detail,
        'owner': owner,
        'status': status,
      };

  static List<_RiskSignalData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _RiskSignalData(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        detail: map['detail']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
        status: map['status']?.toString() ?? 'On track',
      );
    }).toList();
  }
}

class _ApprovalCheckpointData {
  const _ApprovalCheckpointData({
    required this.id,
    required this.title,
    required this.status,
    required this.owner,
    required this.dueDate,
  });

  final String id;
  final String title;
  final String status;
  final String owner;
  final String dueDate;

  _ApprovalCheckpointData copyWith(
      {String? title, String? status, String? owner, String? dueDate}) {
    return _ApprovalCheckpointData(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      owner: owner ?? this.owner,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'status': status,
        'owner': owner,
        'dueDate': dueDate,
      };

  static List<_ApprovalCheckpointData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ApprovalCheckpointData(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Pending',
        owner: map['owner']?.toString() ?? '',
        dueDate: map['dueDate']?.toString() ?? '',
      );
    }).toList();
  }
}

class _Debouncer {
  _Debouncer({Duration? delay})
      : delay = delay ?? const Duration(milliseconds: 700);

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

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
