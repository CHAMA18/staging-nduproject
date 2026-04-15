import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/ai_suggesting_textfield.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/contract_service.dart';
import 'package:ndu_project/services/planning_contracting_service.dart';
import 'package:ndu_project/models/planning_contracting_models.dart';
import 'package:ndu_project/screens/planning_procurement_screen.dart';

const Color _kFabYellow = Color(0xFFFBBF24);
const Color _kFabOnYellow = Color(0xFF111827);

String _formatCurrency(double value) {
  final rounded = value.round();
  final text = rounded.toString();
  return text.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
}

class PlanningContractingScreen extends StatefulWidget {
  const PlanningContractingScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlanningContractingScreen()),
    );
  }

  @override
  State<PlanningContractingScreen> createState() =>
      _PlanningContractingScreenState();
}

class _PlanningContractingScreenState extends State<PlanningContractingScreen> {
  int _selectedTab = 0;

  static const _tabLabels = [
    'Overview',
    'RFPs',
    'Evaluation',
    'Payments',
    'Admin',
    'Negotiation',
    'Budget',
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final hPad = isMobile ? 20.0 : 40.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Contract'),
            ),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                              horizontal: hPad, vertical: isMobile ? 20 : 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BuildHeader(
                                onBack: () => Navigator.maybePop(context),
                                onProcurement: _openProcurement,
                              ),
                              SizedBox(height: isMobile ? 18 : 28),
                              _TabBar(
                                labels: _tabLabels,
                                selectedIndex: _selectedTab,
                                onSelected: (i) =>
                                    setState(() => _selectedTab = i),
                              ),
                              SizedBox(height: isMobile ? 18 : 28),
                              _buildTabContent(),
                              SizedBox(height: isMobile ? 60 : 100),
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
      case 0:
        return const _OverviewTab();
      case 1:
        return const _RfpTab();
      case 2:
        return const _EvaluationTab();
      case 3:
        return const _PaymentsTab();
      case 4:
        return const _AdminTab();
      case 5:
        return const _NegotiationTab();
      case 6:
        return const _BudgetTab();
      default:
        return const SizedBox.shrink();
    }
  }

  void _openProcurement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlanningProcurementScreen()),
    );
  }
}

class _BuildHeader extends StatelessWidget {
  const _BuildHeader({required this.onBack, required this.onProcurement});
  final VoidCallback onBack;
  final VoidCallback onProcurement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleBtn(icon: Icons.arrow_back_ios_new, onTap: onBack),
        const SizedBox(width: 10),
        const _CircleBtn(icon: Icons.arrow_forward_ios),
        const SizedBox(width: 20),
        const Text('Contracting',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827))),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onProcurement,
          icon: const Icon(Icons.inventory_2_outlined, size: 16),
          label: const Text('Procurement',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF374151)),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showAll = constraints.maxWidth >= labels.length * 110;
          final visibleLabels = showAll
              ? labels
              : labels.sublist(0, labels.length > 4 ? 4 : labels.length);

          return Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(visibleLabels.length, (i) {
              final isSelected = i == selectedIndex;
              return _TabPill(
                label: visibleLabels[i],
                selected: isSelected,
                onTap: () => onSelected(i),
              );
            }),
          );
        },
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A0F172A), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827))),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    this.supporting = '',
  });
  final String value;
  final String label;
  final Color color;
  final String supporting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          if (supporting.isNotEmpty)
            Text(supporting,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ─── OVERVIEW TAB ────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  String _awardStrategy = 'Sole Source';
  String _contractType = 'Not Sure';

  static const _tabNoteKey = 'planning_contract_plan';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStrategy());
  }

  Future<void> _loadStrategy() async {
    final provider = ProjectDataHelper.getProvider(context);
    final projectId = provider.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('contracting')
          .doc('strategy')
          .get();
      if (doc.exists && mounted) {
        final d = doc.data() ?? {};
        setState(() {
          _awardStrategy = (d['awardStrategy'] ?? _awardStrategy).toString();
          _contractType = (d['contractType'] ?? _contractType).toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _persistStrategy() async {
    final provider = ProjectDataHelper.getProvider(context);
    final projectId = provider.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('contracting')
          .doc('strategy')
          .set({
        'awardStrategy': _awardStrategy,
        'contractType': _contractType,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final projectData = ProjectDataHelper.getData(context);
    final projectId = projectData.projectId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<ContractModel>>(
          stream: projectId != null && projectId.isNotEmpty
              ? ContractService.streamContracts(projectId)
              : Stream.value(const []),
          builder: (context, snap) {
            final contracts = snap.data ?? const [];
            final totalValue =
                contracts.fold<double>(0.0, (t, c) => t + c.estimatedValue);
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                    value: contracts.length.toString(),
                    label: 'Contracts',
                    color: const Color(0xFF2563EB),
                    supporting: 'Pre-award list'),
                _StatCard(
                    value: contracts.isEmpty
                        ? 'TBD'
                        : '\$${_formatCurrency(totalValue)}',
                    label: 'Total Estimated',
                    color: const Color(0xFF059669),
                    supporting: 'Budget alignment'),
                _StatCard(
                    value:
                        _contractType == 'Not Sure' ? 'Not set' : _contractType,
                    label: 'Contract Type',
                    color: const Color(0xFFF59E0B),
                    supporting: 'From strategy'),
                _StatCard(
                    value: _awardStrategy,
                    label: 'Award Strategy',
                    color: const Color(0xFF7C3AED),
                    supporting: 'From strategy'),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Contracting Strategy',
          subtitle: 'Define the contracting approach for this project',
          child: _StrategySection(
            awardStrategy: _awardStrategy,
            contractType: _contractType,
            onAwardChanged: (v) {
              setState(() => _awardStrategy = v);
              _persistStrategy();
            },
            onContractTypeChanged: (v) {
              setState(() => _contractType = v);
              _persistStrategy();
            },
          ),
        ),
        _SectionCard(
          title: 'Contract Plan',
          subtitle:
              'AI drafts a contract plan using your prior planning context. Edit it to match your strategy.',
          child: AiSuggestingTextField(
            fieldLabel: 'Contract Plan',
            hintText:
                'Outline scope, delivery model, commercial terms, milestones, vendor roles, and approval gates.',
            sectionLabel: 'Contract Plan',
            autoGenerate: true,
            autoGenerateSection: 'Contract Plan',
            initialText: projectData.planningNotes[_tabNoteKey],
            onChanged: (value) async {
              final trimmed = value.trim();
              await ProjectDataHelper.updateAndSave(
                context: context,
                checkpoint: 'contracts',
                dataUpdater: (data) => data.copyWith(
                  planningNotes: {...data.planningNotes, _tabNoteKey: trimmed},
                ),
                showSnackbar: false,
              );
            },
            onAutoGenerated: (value) async {
              final trimmed = value.trim();
              await ProjectDataHelper.updateAndSave(
                context: context,
                checkpoint: 'contracts',
                dataUpdater: (data) => data.copyWith(
                  planningNotes: {...data.planningNotes, _tabNoteKey: trimmed},
                ),
                showSnackbar: false,
              );
            },
          ),
        ),
        _SectionCard(
          title: 'FEP Scopes Reference',
          subtitle:
              'Contracting scopes identified in the Initiation (FEP) phase',
          child: _FepScopesPreview(projectId: projectId),
        ),
        _SectionCard(
          title: 'Contracts Preview',
          subtitle: 'Pre-define contracts that will feed execution tracking',
          trailing: TextButton.icon(
            onPressed: () => _showCreateContractDialog(context, projectId),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Contract',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
          ),
          child: _ContractsPreview(projectId: projectId),
        ),
      ],
    );
  }
}

class _StrategySection extends StatelessWidget {
  const _StrategySection({
    required this.awardStrategy,
    required this.contractType,
    required this.onAwardChanged,
    required this.onContractTypeChanged,
  });
  final String awardStrategy;
  final String contractType;
  final ValueChanged<String> onAwardChanged;
  final ValueChanged<String> onContractTypeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 780;
        final children = [
          Expanded(
            child: _RadioGroup(
              title: 'Award Strategy',
              options: const ['Sole Source', 'Competitive Bidding', 'Not Sure'],
              selected: awardStrategy,
              onChanged: onAwardChanged,
            ),
          ),
          SizedBox(width: narrow ? 0 : 28, height: narrow ? 20 : 0),
          Expanded(
            child: _RadioGroup(
              title: 'Contract Type',
              options: const [
                'Reimbursable (Time & Materials)',
                'Lump Sum (Fixed Price)',
                'Not Sure'
              ],
              selected: contractType,
              onChanged: onContractTypeChanged,
            ),
          ),
        ];
        if (narrow) {
          return Column(children: children);
        }
        return Row(
            crossAxisAlignment: CrossAxisAlignment.start, children: children);
      },
    );
  }
}

class _RadioGroup extends StatelessWidget {
  const _RadioGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827))),
        const SizedBox(height: 12),
        ...options.map(
          (o) => InkWell(
            onTap: () => onChanged(o),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Radio<String>(
                    value: o,
                    groupValue: selected,
                    onChanged: (_) => onChanged(o),
                    activeColor: const Color(0xFF2563EB),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(o,
                        style: TextStyle(
                          fontSize: 13,
                          color: o == selected
                              ? const Color(0xFF111827)
                              : const Color(0xFF4B5563),
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FepScopesPreview extends StatelessWidget {
  const _FepScopesPreview({this.projectId});
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    if (projectId == null || projectId!.isEmpty) {
      return const _EmptyPanel('No project selected.');
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('contracting_scopes')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const _EmptyPanel(
              'No FEP scopes found. Add contracting scopes in the Initiation phase.');
        }
        final docs = snap.data!.docs;
        return Column(
          children: docs.map((doc) {
            final d = doc.data();
            final name = (d['name'] ?? d['title'] ?? '').toString();
            final type = (d['type'] ?? '').toString();
            final value = d['estimatedValue'] ?? d['estimatedCost'] ?? 0;
            final status = (d['status'] ?? '').toString();
            return _FepScopeRow(
                name: name, type: type, value: value, status: status);
          }).toList(),
        );
      },
    );
  }
}

class _FepScopeRow extends StatelessWidget {
  const _FepScopeRow({
    required this.name,
    required this.type,
    required this.value,
    required this.status,
  });
  final String name;
  final String type;
  final double value;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(
              flex: 2,
              child: Text(type,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          Expanded(
              flex: 2,
              child: Text(value > 0 ? '\$${_formatCurrency(value)}' : 'TBD',
                  style: const TextStyle(fontSize: 12))),
          Expanded(
            flex: 2,
            child: _StatusChip(
              label: status.isEmpty ? 'Identified' : status,
              color: _statusColor(status.isEmpty ? 'identified' : status),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractsPreview extends StatelessWidget {
  const _ContractsPreview({this.projectId});
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    if (projectId == null || projectId!.isEmpty) {
      return const _EmptyPanel('No project selected.');
    }
    return StreamBuilder<List<ContractModel>>(
      stream: ContractService.streamContracts(projectId!),
      builder: (context, snap) {
        final contracts = snap.data ?? const [];
        if (contracts.isEmpty) {
          return const _EmptyPanel(
              'No contracts yet. Click "Add Contract" to get started.');
        }
        return Column(
          children: contracts.map((c) => _ContractRow(contract: c)).toList(),
        );
      },
    );
  }
}

class _ContractRow extends StatelessWidget {
  const _ContractRow({required this.contract});
  final ContractModel contract;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(contract.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(
              flex: 2,
              child: Text(
                  contract.contractorName.isEmpty
                      ? 'TBD'
                      : contract.contractorName,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          Expanded(
              flex: 2,
              child: Text('\$${_formatCurrency(contract.estimatedValue)}',
                  style: const TextStyle(fontSize: 12))),
          Expanded(
            flex: 2,
            child: _StatusChip(
              label: contract.status,
              color: _statusColor(contract.status),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  final s = status.toLowerCase();
  if (s.contains('award') || s.contains('complete') || s.contains('approved')) {
    return const Color(0xFF22C55E);
  }
  if (s.contains('behind') || s.contains('risk') || s.contains('blocked')) {
    return const Color(0xFFEF4444);
  }
  if (s.contains('review') ||
      s.contains('pending') ||
      s.contains('shortlist')) {
    return const Color(0xFFF59E0B);
  }
  if (s.contains('progress') ||
      s.contains('active') ||
      s.contains('identified')) {
    return const Color(0xFF2563EB);
  }
  return const Color(0xFF64748B);
}

void _showCreateContractDialog(BuildContext context, String? projectId) {
  if (projectId == null || projectId.isEmpty) return;
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final scopeCtrl = TextEditingController();
  final disciplineCtrl = TextEditingController();
  String contractType = 'Not Sure';
  String paymentType = 'TBD';

  showDialog(
    context: context,
    builder: (dCtx) => StatefulBuilder(
      builder: (dCtx, setDialog) => AlertDialog(
        title: const Text('Create Contract'),
        content: SizedBox(
          width: MediaQuery.of(dCtx).size.width > 600 ? 520 : null,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Contract Name *',
                        border: OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(
                    controller: valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Estimated Value',
                        prefixText: '\$',
                        border: OutlineInputBorder())),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: contractType,
                        items: [
                          'Not Sure',
                          'Lump Sum (Fixed Price)',
                          'Reimbursable (Time & Materials)'
                        ]
                            .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) =>
                            setDialog(() => contractType = v ?? 'Not Sure'),
                        decoration: const InputDecoration(
                            labelText: 'Contract Type',
                            border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: paymentType,
                        items: ['TBD', 'Monthly', 'Milestone-Based', 'Upfront']
                            .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) =>
                            setDialog(() => paymentType = v ?? 'TBD'),
                        decoration: const InputDecoration(
                            labelText: 'Payment Type',
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                          controller: scopeCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Scope',
                              border: OutlineInputBorder())),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                          controller: disciplineCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Discipline',
                              border: OutlineInputBorder())),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final user = FirebaseAuth.instance.currentUser;
              await ContractService.createContract(
                projectId: projectId,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                contractType: contractType,
                paymentType: paymentType,
                status: 'Not Started',
                estimatedValue: double.tryParse(valueCtrl.text) ?? 0.0,
                scope: scopeCtrl.text.trim(),
                discipline: disciplineCtrl.text.trim(),
                createdById: user?.uid ?? '',
                createdByEmail: user?.email ?? '',
                createdByName: user?.displayName ?? '',
              );
              if (dCtx.mounted) Navigator.pop(dCtx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _kFabYellow, foregroundColor: _kFabOnYellow),
            child: const Text('Create',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
  );
}

// ─── RFP TAB ─────────────────────────────────────────────────────────────────

class _RfpTab extends StatefulWidget {
  const _RfpTab();
  @override
  State<_RfpTab> createState() => _RfpTabState();
}

class _RfpTabState extends State<_RfpTab> {
  @override
  Widget build(BuildContext context) {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      return const _EmptyPanel('No project selected.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showRfpDialog(context, projectId),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create RFP',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<PlanningRfq>>(
          stream: PlanningContractingService.streamRfqs(projectId),
          builder: (context, snap) {
            final rfqs = snap.data ?? const [];
            if (rfqs.isEmpty) {
              return const _SectionCard(
                title: 'Requests for Proposal',
                subtitle:
                    'Create RFPs linked to FEP scopes and invite contractors',
                child: _EmptyPanel(
                    'No RFPs created yet. Click "Create RFP" to start.'),
              );
            }
            return _SectionCard(
              title: 'Requests for Proposal',
              subtitle: '${rfqs.length} RFP(s) created',
              child: Column(
                children: rfqs.map((rfq) => _RfqRow(rfq: rfq)).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RfqRow extends StatelessWidget {
  const _RfqRow({required this.rfq});
  final PlanningRfq rfq;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(rfq.title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(
              flex: 2,
              child: Text(
                  rfq.submissionDeadline != null
                      ? DateFormat('MMM dd, yyyy')
                          .format(rfq.submissionDeadline!)
                      : 'No deadline',
                  style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 2,
              child: Text('${rfq.invitedContractors.length} vendors',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          Expanded(
            flex: 2,
            child: _StatusChip(
              label: rfq.status,
              color: _rfqStatusColor(rfq.status),
            ),
          ),
        ],
      ),
    );
  }
}

Color _rfqStatusColor(String s) {
  final l = s.toLowerCase();
  if (l.contains('award') || l.contains('complete'))
    return const Color(0xFF22C55E);
  if (l.contains('publish') || l.contains('active'))
    return const Color(0xFF2563EB);
  if (l.contains('evaluat')) return const Color(0xFFF59E0B);
  return const Color(0xFF64748B);
}

void _showRfpDialog(BuildContext context, String projectId) {
  final titleCtrl = TextEditingController();
  final scopeCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (dCtx) => AlertDialog(
      title: const Text('Create RFP'),
      content: SizedBox(
        width: MediaQuery.of(dCtx).size.width > 600 ? 520 : null,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'RFP Title *', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              TextField(
                  controller: scopeCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Scope of Work',
                      border: OutlineInputBorder())),
              const SizedBox(height: 14),
              TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Notes', border: OutlineInputBorder())),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (titleCtrl.text.trim().isEmpty) return;
            final now = DateTime.now();
            await PlanningContractingService.createRfq(PlanningRfq(
              id: '',
              projectId: projectId,
              title: titleCtrl.text.trim(),
              scopeOfWork: scopeCtrl.text.trim(),
              notes: notesCtrl.text.trim(),
              createdAt: now,
              updatedAt: now,
            ));
            if (dCtx.mounted) Navigator.pop(dCtx);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white),
          child: const Text('Create',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

// ─── EVALUATION TAB ──────────────────────────────────────────────────────────

class _EvaluationTab extends StatefulWidget {
  const _EvaluationTab();
  @override
  State<_EvaluationTab> createState() => _EvaluationTabState();
}

class _EvaluationTabState extends State<_EvaluationTab> {
  @override
  Widget build(BuildContext context) {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      return const _EmptyPanel('No project selected.');
    }
    return StreamBuilder<List<ContractModel>>(
      stream: ContractService.streamContracts(projectId),
      builder: (context, snap) {
        final contracts = snap.data ?? const [];
        if (contracts.isEmpty) {
          return const _SectionCard(
            title: 'Bid Evaluation Matrix',
            subtitle: 'Score vendor responses against weighted criteria',
            child: _EmptyPanel('Add contracts first to set up evaluations.'),
          );
        }
        return _SectionCard(
          title: 'Bid Evaluation Matrix',
          subtitle:
              'Score vendor responses against weighted criteria per contract',
          child: Column(
            children: contracts
                .map((c) => _EvaluationContractRow(contract: c))
                .toList(),
          ),
        );
      },
    );
  }
}

class _EvaluationContractRow extends StatelessWidget {
  const _EvaluationContractRow({required this.contract});
  final ContractModel contract;

  @override
  Widget build(BuildContext context) {
    final scores = contract.evaluationScores ?? [];
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(
            child: Text(contract.name,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          _StatusChip(
            label: scores.isEmpty ? 'No Scores' : '${scores.length} scores',
            color: scores.isEmpty
                ? const Color(0xFF64748B)
                : const Color(0xFF2563EB),
          ),
        ],
      ),
      children: [
        if (scores.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No evaluation scores recorded yet.',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ),
        if (scores.isNotEmpty) _ScoreTable(scores: scores),
      ],
    );
  }
}

class _ScoreTable extends StatelessWidget {
  const _ScoreTable({required this.scores});
  final List<EvaluationScore> scores;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: const [
            _TableHeaderCell('Vendor'),
            _TableHeaderCell('Criteria'),
            _TableHeaderCell('Score'),
            _TableHeaderCell('Notes'),
          ],
        ),
        ...scores.map((s) => TableRow(children: [
              _TableCell(
                  Text(s.vendorName, style: const TextStyle(fontSize: 12))),
              _TableCell(
                  Text(s.criteriaId, style: const TextStyle(fontSize: 12))),
              _TableCell(Text(s.score.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600))),
              _TableCell(Text(s.notes,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
            ])),
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280))),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.child);
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: child);
  }
}

// ─── PAYMENTS TAB ────────────────────────────────────────────────────────────

class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab();
  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  @override
  Widget build(BuildContext context) {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      return const _EmptyPanel('No project selected.');
    }
    return StreamBuilder<List<ContractModel>>(
      stream: ContractService.streamContracts(projectId),
      builder: (context, snap) {
        final contracts = snap.data ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PaymentSummaryCards(contracts: contracts),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Payment Milestones',
              subtitle: 'Define and track payment milestones per contract',
              child: contracts.isEmpty
                  ? const _EmptyPanel(
                      'Add contracts first to set up payment milestones.')
                  : Column(
                      children: contracts
                          .where((c) =>
                              (c.paymentMilestones ?? []).isNotEmpty ||
                              c.estimatedValue > 0)
                          .map((c) => _PaymentContractExpansion(contract: c))
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PaymentSummaryCards extends StatelessWidget {
  const _PaymentSummaryCards({required this.contracts});
  final List<ContractModel> contracts;

  @override
  Widget build(BuildContext context) {
    final totalValue =
        contracts.fold<double>(0.0, (t, c) => t + c.estimatedValue);
    final allMilestones = contracts
        .expand((c) => c.paymentMilestones ?? <PaymentMilestone>[])
        .toList();
    final totalPlanned =
        allMilestones.fold<double>(0.0, (t, m) => t + m.amount);
    final paidCount = allMilestones.where((m) => m.status == 'Paid').length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
            value: '\$${_formatCurrency(totalValue)}',
            label: 'Total Contract Value',
            color: const Color(0xFF2563EB)),
        _StatCard(
            value: '\$${_formatCurrency(totalPlanned)}',
            label: 'Milestones Planned',
            color: const Color(0xFF059669)),
        _StatCard(
            value: '\$${_formatCurrency(totalValue - totalPlanned)}',
            label: 'Unplanned',
            color: const Color(0xFFF59E0B)),
        _StatCard(
            value: '$paidCount/${allMilestones.length}',
            label: 'Paid Milestones',
            color: const Color(0xFF7C3AED)),
      ],
    );
  }
}

class _PaymentContractExpansion extends StatelessWidget {
  const _PaymentContractExpansion({required this.contract});
  final ContractModel contract;

  @override
  Widget build(BuildContext context) {
    final milestones = contract.paymentMilestones ?? [];
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(
            child: Text(contract.name,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text('\$${_formatCurrency(contract.estimatedValue)}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669))),
        ],
      ),
      children: [
        if (milestones.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No payment milestones defined.',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          )
        else
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1.2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[100]),
                children: const [
                  _TableHeaderCell('Milestone'),
                  _TableHeaderCell('Amount'),
                  _TableHeaderCell('% of Total'),
                  _TableHeaderCell('Retention'),
                  _TableHeaderCell('Status'),
                ],
              ),
              ...milestones.map((m) => TableRow(children: [
                    _TableCell(Text(m.name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500))),
                    _TableCell(Text('\$${_formatCurrency(m.amount)}',
                        style: const TextStyle(fontSize: 12))),
                    _TableCell(Text(
                        '${m.percentOfContract.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12))),
                    _TableCell(Text('${m.retentionPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)))),
                    _TableCell(_StatusChip(
                        label: m.status, color: _paymentStatusColor(m.status))),
                  ])),
            ],
          ),
      ],
    );
  }
}

Color _paymentStatusColor(String s) {
  final l = s.toLowerCase();
  if (l == 'paid') return const Color(0xFF22C55E);
  if (l == 'approved') return const Color(0xFF7C3AED);
  if (l == 'submitted') return const Color(0xFF2563EB);
  if (l == 'due') return const Color(0xFFF59E0B);
  return const Color(0xFF64748B);
}

// ─── ADMIN TAB ───────────────────────────────────────────────────────────────

class _AdminTab extends StatefulWidget {
  const _AdminTab();
  @override
  State<_AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends State<_AdminTab> {
  @override
  Widget build(BuildContext context) {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      return const _EmptyPanel('No project selected.');
    }
    return StreamBuilder<List<ContractModel>>(
      stream: ContractService.streamContracts(projectId),
      builder: (context, snap) {
        final contracts = snap.data ?? const [];
        if (contracts.isEmpty) {
          return const _SectionCard(
            title: 'Contract Administration',
            subtitle:
                'Assign managers, define change order procedures, dispute resolution, and reporting',
            child:
                _EmptyPanel('Add contracts first to configure administration.'),
          );
        }
        return Column(
          children:
              contracts.map((c) => _AdminContractCard(contract: c)).toList(),
        );
      },
    );
  }
}

class _AdminContractCard extends StatefulWidget {
  const _AdminContractCard({required this.contract});
  final ContractModel contract;

  @override
  State<_AdminContractCard> createState() => _AdminContractCardState();
}

class _AdminContractCardState extends State<_AdminContractCard> {
  @override
  Widget build(BuildContext context) {
    final c = widget.contract;
    return _SectionCard(
      title: c.name,
      subtitle: c.contractorName.isEmpty
          ? 'No contractor assigned'
          : c.contractorName,
      child: Column(
        children: [
          _AdminField(
            label: 'Contract Manager',
            value: c.contractManagerName ?? 'Unassigned',
            options: const ['Unassigned', 'PM', 'Sponsor', 'Contract Manager'],
            onChanged: (v) =>
                _updateField(contractManagerName: v == 'Unassigned' ? '' : v),
          ),
          const SizedBox(height: 14),
          _AdminField(
            label: 'Change Order Procedure',
            value: c.changeOrderProcedure ?? 'Not Set',
            options: const ['Standard', 'Formal Review', 'Custom', 'Not Set'],
            onChanged: (v) => _updateField(changeOrderProcedure: v),
          ),
          const SizedBox(height: 14),
          _AdminField(
            label: 'Dispute Resolution',
            value: c.disputeResolution ?? 'Not Set',
            options: const [
              'Negotiation',
              'Mediation',
              'Arbitration',
              'Litigation',
              'Not Set'
            ],
            onChanged: (v) => _updateField(disputeResolution: v),
          ),
          const SizedBox(height: 14),
          _AdminField(
            label: 'Reporting Frequency',
            value: c.reportingFrequency ?? 'Not Set',
            options: const ['Weekly', 'Bi-weekly', 'Monthly', 'Not Set'],
            onChanged: (v) => _updateField(reportingFrequency: v),
          ),
        ],
      ),
    );
  }

  Future<void> _updateField({
    String? contractManagerName,
    String? changeOrderProcedure,
    String? disputeResolution,
    String? reportingFrequency,
  }) async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null) return;
    await ContractService.updatePlanningFields(
      projectId: projectId,
      contractId: widget.contract.id,
      contractManagerName: contractManagerName,
      changeOrderProcedure: changeOrderProcedure,
      disputeResolution: disputeResolution,
      reportingFrequency: reportingFrequency,
    );
  }
}

class _AdminField extends StatelessWidget {
  const _AdminField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 180,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButton<String>(
              value: options.contains(value) ? value : options.last,
              items: options
                  .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              underline: const SizedBox.shrink(),
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── NEGOTIATION TAB ─────────────────────────────────────────────────────────

class _NegotiationTab extends StatefulWidget {
  const _NegotiationTab();
  @override
  State<_NegotiationTab> createState() => _NegotiationTabState();
}

class _NegotiationTabState extends State<_NegotiationTab> {
  @override
  Widget build(BuildContext context) {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      return const _EmptyPanel('No project selected.');
    }
    return StreamBuilder<List<ContractModel>>(
      stream: ContractService.streamContracts(projectId),
      builder: (context, snap) {
        final contracts = snap.data ?? const [];
        if (contracts.isEmpty) {
          return const _SectionCard(
            title: 'Negotiation Planner',
            subtitle:
                'Prepare negotiation objectives, key items, BATNA, and authority levels',
            child: _EmptyPanel('Add contracts first to plan negotiations.'),
          );
        }
        return Column(
          children: contracts
              .map((c) => _NegotiationContractCard(contract: c))
              .toList(),
        );
      },
    );
  }
}

class _NegotiationContractCard extends StatelessWidget {
  const _NegotiationContractCard({required this.contract});
  final ContractModel contract;

  @override
  Widget build(BuildContext context) {
    final items = contract.negotiationItems ?? [];
    return _SectionCard(
      title: contract.name,
      subtitle:
          'Status: ${contract.negotiationStatus ?? "Not Started"} | Authority: ${contract.negotiationAuthority ?? "Not Set"}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contract.negotiationObjectives != null &&
              contract.negotiationObjectives!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Objectives',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(contract.negotiationObjectives!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF4B5563))),
                ],
              ),
            ),
          if (items.isEmpty)
            const Text('No negotiation items tracked.',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[100]),
                  children: const [
                    _TableHeaderCell('Item'),
                    _TableHeaderCell('Our Position'),
                    _TableHeaderCell('Their Position'),
                    _TableHeaderCell('Status'),
                  ],
                ),
                ...items.map((item) => TableRow(children: [
                      _TableCell(Text(item.item,
                          style: const TextStyle(fontSize: 12))),
                      _TableCell(Text(item.ourPosition,
                          style: const TextStyle(fontSize: 12))),
                      _TableCell(Text(item.theirPosition,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280)))),
                      _TableCell(_StatusChip(
                          label: item.status,
                          color: _negoStatusColor(item.status))),
                    ])),
              ],
            ),
        ],
      ),
    );
  }
}

Color _negoStatusColor(String s) {
  final l = s.toLowerCase();
  if (l == 'agreed' || l == 'won') return const Color(0xFF22C55E);
  if (l == 'compromised') return const Color(0xFFF59E0B);
  if (l == 'conceded') return const Color(0xFFEF4444);
  return const Color(0xFF64748B);
}

// ─── BUDGET TAB ──────────────────────────────────────────────────────────────

class _BudgetTab extends StatefulWidget {
  const _BudgetTab();
  @override
  State<_BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<_BudgetTab> {
  @override
  Widget build(BuildContext context) {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      return const _EmptyPanel('No project selected.');
    }
    return StreamBuilder<List<ContractModel>>(
      stream: ContractService.streamContracts(projectId),
      builder: (context, snap) {
        final contracts = snap.data ?? const [];
        final totalBase =
            contracts.fold<double>(0.0, (t, c) => t + c.estimatedValue);
        final totalContingency = contracts.fold<double>(
            0.0, (t, c) => t + (c.contingencyAmount ?? 0));
        final totalBudget = totalBase + totalContingency;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                    value: '\$${_formatCurrency(totalBase)}',
                    label: 'Base Contract Value',
                    color: const Color(0xFF2563EB)),
                _StatCard(
                    value: '\$${_formatCurrency(totalContingency)}',
                    label: 'Total Contingency',
                    color: const Color(0xFFF59E0B)),
                _StatCard(
                    value: '\$${_formatCurrency(totalBudget)}',
                    label: 'Total Budget',
                    color: const Color(0xFF059669)),
                _StatCard(
                    value: contracts.length.toString(),
                    label: 'Contracts',
                    color: const Color(0xFF7C3AED)),
              ],
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Budget Breakdown',
              subtitle:
                  'Detailed contract budget with contingency and tracking',
              child: contracts.isEmpty
                  ? const _EmptyPanel('No contracts to show budget breakdown.')
                  : Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1.2),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1.2),
                        4: FlexColumnWidth(1.2),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey[100]),
                          children: const [
                            _TableHeaderCell('Contract'),
                            _TableHeaderCell('Base Value'),
                            _TableHeaderCell('Contingency %'),
                            _TableHeaderCell('Contingency'),
                            _TableHeaderCell('Total'),
                          ],
                        ),
                        ...contracts.map((c) {
                          final base = c.estimatedValue;
                          final contAmt = c.contingencyAmount ?? 0;
                          final contPct = c.contingencyPercent ?? 0;
                          final total = base + contAmt;
                          return TableRow(children: [
                            _TableCell(Text(c.name,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500))),
                            _TableCell(Text('\$${_formatCurrency(base)}',
                                style: const TextStyle(fontSize: 12))),
                            _TableCell(Text('${contPct.toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 12))),
                            _TableCell(Text('\$${_formatCurrency(contAmt)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFFF59E0B)))),
                            _TableCell(Text('\$${_formatCurrency(total)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF059669)))),
                          ]);
                        }),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
