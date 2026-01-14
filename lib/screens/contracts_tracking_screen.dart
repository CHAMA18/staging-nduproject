import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/progress_tracking_screen.dart';
import 'package:ndu_project/screens/vendor_tracking_screen.dart';
import 'package:ndu_project/services/contract_service.dart';
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
  State<ContractsTrackingScreen> createState() => _ContractsTrackingScreenState();
}

class _ContractsTrackingScreenState extends State<ContractsTrackingScreen> {
  final Set<String> _selectedFilters = {'All contracts'};

  String? get _projectId {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
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
        _actionButton(Icons.add, 'Add contract', onPressed: () => _showAddContractDialog(context)),
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
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
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
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All contracts', 'Renewal due', 'At risk', 'Pending sign-off', 'Archived'];
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
        final totalValue = contracts.fold<double>(0.0, (sum, c) => sum + c.estimatedValue);
        final atRiskCount = contracts.where((c) => c.status == 'At risk').length;

        final stats = [
          _StatCardData('Active contracts', '$activeCount', '${contracts.length} total', const Color(0xFF0EA5E9)),
          _StatCardData('Renewal due', '$renewalDue', 'Next 30 days', const Color(0xFFF97316)),
          _StatCardData('Total value', '\$${(totalValue / 1000000).toStringAsFixed(1)}M', 'FY spend', const Color(0xFF10B981)),
          _StatCardData('At risk', '$atRiskCount', atRiskCount > 0 ? 'Require attention' : 'All stable', const Color(0xFF6366F1)),
        ];

        if (isNarrow) {
          return Column(
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                SizedBox(width: double.infinity, child: _buildStatCard(stats[i])),
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
          Text(data.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: data.color)),
          const SizedBox(height: 6),
          Text(data.label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(data.supporting, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: data.color)),
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
            child: Text('No project selected. Please open a project first.', style: TextStyle(color: Color(0xFF64748B))),
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
            return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading contracts: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
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
                    const Text('No contracts found.', style: TextStyle(color: Color(0xFF64748B))),
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

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Contract Name', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Renewal', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Value', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                    rows: filteredContracts.map((contract) {
                      final renewalDate = DateFormat('MMM dd').format(contract.endDate);
                      final valueStr = contract.estimatedValue >= 1000000
                          ? '\$${(contract.estimatedValue / 1000000).toStringAsFixed(1)}M'
                          : '\$${(contract.estimatedValue / 1000).toStringAsFixed(0)}K';
                      final contractId = contract.id.length > 8 ? contract.id.substring(0, 8).toUpperCase() : contract.id.toUpperCase();
                      final ownerName = contract.createdByName.split(' ').map((n) => n[0]).join('. ');
                      
                      return DataRow(cells: [
                        DataCell(Text('CT-$contractId', style: const TextStyle(fontSize: 12, color: Color(0xFF0EA5E9)))),
                        DataCell(Text(contract.name, style: const TextStyle(fontSize: 13))),
                        DataCell(_chip(contract.contractType)),
                        DataCell(_statusChip(contract.status)),
                        DataCell(Text(renewalDate, style: const TextStyle(fontSize: 12))),
                        DataCell(Text(valueStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        DataCell(Text(ownerName, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Color(0xFF64748B)),
                                onPressed: () => _showEditContractDialog(context, contract),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
                                onPressed: () => _showDeleteContractDialog(context, contract),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              );
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
        return daysUntilRenewal <= 30 && daysUntilRenewal > 0;
      }
      if (_selectedFilters.contains('At risk') && c.status == 'At risk') return true;
      if (_selectedFilters.contains('Pending sign-off') && c.status == 'Pending sign-off') return true;
      if (_selectedFilters.contains('Archived') && c.status == 'Archived') return true;
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
      child: StreamBuilder<List<ContractModel>>(
        stream: ContractService.streamContracts(_projectId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final contracts = snapshot.data!;
          final now = DateTime.now();
          
          final renewal30 = contracts.where((c) {
            final days = c.endDate.difference(now).inDays;
            return days <= 30 && days > 0;
          }).length;
          
          final renewal60 = contracts.where((c) {
            final days = c.endDate.difference(now).inDays;
            return days <= 60 && days > 30;
          }).length;
          
          final renewal90 = contracts.where((c) {
            final days = c.endDate.difference(now).inDays;
            return days <= 90 && days > 60;
          }).length;

          final lanes = [
            _RenewalLane('30 days', renewal30, const Color(0xFFF97316)),
            _RenewalLane('60 days', renewal60, const Color(0xFF6366F1)),
            _RenewalLane('90 days', renewal90, const Color(0xFF10B981)),
          ];

          return Column(
            children: lanes.map((lane) {
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
                      decoration: BoxDecoration(color: lane.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(lane.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Text('${lane.count} contracts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: lane.color)),
                  ],
                ),
              );
            }).toList(),
          );
        },
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
      child: StreamBuilder<List<ContractModel>>(
        stream: ContractService.streamContracts(_projectId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final contracts = snapshot.data!;
          final renewalDue = contracts.where((c) {
            final days = c.endDate.difference(DateTime.now()).inDays;
            return days <= 7 && days > 0;
          }).length;
          final atRiskCount = contracts.where((c) => c.status == 'At risk').length;
          final pendingCount = contracts.where((c) => c.status == 'Pending sign-off').length;

          final signals = <_SignalItem>[];
          if (renewalDue > 0) {
            signals.add(_SignalItem('Renewal risk flagged', '$renewalDue contract${renewalDue > 1 ? 's' : ''} require escalation this week.'));
          }
          if (atRiskCount > 0) {
            signals.add(_SignalItem('At-risk contracts', '$atRiskCount contract${atRiskCount > 1 ? 's' : ''} marked as at risk.'));
          }
          if (pendingCount > 0) {
            signals.add(_SignalItem('Legal review backlog', '$pendingCount item${pendingCount > 1 ? 's' : ''} awaiting legal sign-off.'));
          }

          if (signals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No active risk signals', style: TextStyle(color: Color(0xFF10B981))),
              ),
            );
          }

          return Column(
            children: signals.map((signal) {
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
                    Text(signal.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(signal.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildApprovalsPanel() {
    return _PanelShell(
      title: 'Approval readiness',
      subtitle: 'Legal and finance checkpoints',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ApprovalItem('Legal review queue', '2 pending', true),
          _ApprovalItem('Finance sign-off', 'Complete', true),
          _ApprovalItem('Security assessment', 'Scheduled', false),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
    );
  }

  Widget _statusChip(String label) {
    Color color;
    switch (label) {
      case 'Renewal due':
        color = const Color(0xFFF97316);
        break;
      case 'At risk':
        color = const Color(0xFFEF4444);
        break;
      case 'Pending sign-off':
        color = const Color(0xFF6366F1);
        break;
      default:
        color = const Color(0xFF10B981);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)      ),
    );
  }

  void _showAddContractDialog(BuildContext context) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showContractDialog(context, null, projectId);
  }

  void _showEditContractDialog(BuildContext context, ContractModel contract) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showContractDialog(context, contract, projectId);
  }

  void _showContractDialog(BuildContext context, ContractModel? contract, String projectId) {
    final isEdit = contract != null;
    final nameController = TextEditingController(text: contract?.name ?? '');
    final descriptionController = TextEditingController(text: contract?.description ?? '');
    final contractTypeController = TextEditingController(text: contract?.contractType ?? '');
    final paymentTypeController = TextEditingController(text: contract?.paymentType ?? '');
    final statusController = TextEditingController(text: contract?.status ?? 'Active');
    final estimatedValueController = TextEditingController(text: contract?.estimatedValue.toString() ?? '0');
    final scopeController = TextEditingController(text: contract?.scope ?? '');
    final disciplineController = TextEditingController(text: contract?.discipline ?? '');
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
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Contract Name *')),
                const SizedBox(height: 12),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description *'), maxLines: 2),
                const SizedBox(height: 12),
                TextField(controller: contractTypeController, decoration: const InputDecoration(labelText: 'Contract Type *')),
                const SizedBox(height: 12),
                TextField(controller: paymentTypeController, decoration: const InputDecoration(labelText: 'Payment Type *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: statusController.text,
                  decoration: const InputDecoration(labelText: 'Status *'),
                  items: ['Active', 'Renewal due', 'At risk', 'Pending sign-off', 'Archived'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => statusController.text = v ?? 'Active'),
                ),
                const SizedBox(height: 12),
                TextField(controller: estimatedValueController, decoration: const InputDecoration(labelText: 'Estimated Value *', hintText: 'e.g., 1000000')),
                const SizedBox(height: 12),
                ListTile(
                  title: Text('Start Date: ${startDate != null ? DateFormat('MMM dd, yyyy').format(startDate!) : 'Not set'}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: startDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (date != null) setDialogState(() => startDate = date);
                  },
                ),
                ListTile(
                  title: Text('End Date: ${endDate != null ? DateFormat('MMM dd, yyyy').format(endDate!) : 'Not set'}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: endDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (date != null) setDialogState(() => endDate = date);
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: scopeController, decoration: const InputDecoration(labelText: 'Scope *')),
                const SizedBox(height: 12),
                TextField(controller: disciplineController, decoration: const InputDecoration(labelText: 'Discipline *')),
                const SizedBox(height: 12),
                TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
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
                if (nameController.text.isEmpty || descriptionController.text.isEmpty || startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final estimatedValue = double.tryParse(estimatedValueController.text) ?? 0.0;

                  if (isEdit) {
                    await ContractService.updateContract(
                      projectId: projectId,
                      contractId: contract.id,
                      name: nameController.text,
                      description: descriptionController.text,
                      contractType: contractTypeController.text,
                      paymentType: paymentTypeController.text,
                      status: statusController.text,
                      estimatedValue: estimatedValue,
                      startDate: startDate!,
                      endDate: endDate!,
                      scope: scopeController.text,
                      discipline: disciplineController.text,
                      notes: notesController.text.isEmpty ? null : notesController.text,
                    );
                  } else {
                    await ContractService.createContract(
                      projectId: projectId,
                      name: nameController.text,
                      description: descriptionController.text,
                      contractType: contractTypeController.text,
                      paymentType: paymentTypeController.text,
                      status: statusController.text,
                      estimatedValue: estimatedValue,
                      startDate: startDate!,
                      endDate: endDate!,
                      scope: scopeController.text,
                      discipline: disciplineController.text,
                      notes: notesController.text,
                      createdById: user?.uid ?? '',
                      createdByEmail: user?.email ?? '',
                      createdByName: user?.displayName ?? user?.email?.split('@').first ?? '',
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Contract updated successfully' : 'Contract added successfully')),
                    );
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
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contract'),
        content: Text('Are you sure you want to delete "${contract.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ContractService.deleteContract(projectId: projectId, contractId: contract.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contract deleted successfully')),
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
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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

class _ApprovalItem extends StatelessWidget {
  const _ApprovalItem(this.title, this.status, this.complete);

  final String title;
  final String status;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = complete ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
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
          Icon(complete ? Icons.check_circle : Icons.schedule, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Text(status, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _RenewalLane {
  const _RenewalLane(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;
}

class _SignalItem {
  const _SignalItem(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
