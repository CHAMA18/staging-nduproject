import 'package:flutter/material.dart';

import 'package:ndu_project/models/launch_phase_models.dart';
import 'package:ndu_project/screens/contract_close_out_screen.dart';
import 'package:ndu_project/screens/deliver_project_closure_screen.dart';
import 'package:ndu_project/services/launch_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/execution_phase_ui.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_data_table.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class TransitionToProdTeamScreen extends StatefulWidget {
  const TransitionToProdTeamScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransitionToProdTeamScreen()),
    );
  }

  @override
  State<TransitionToProdTeamScreen> createState() =>
      _TransitionToProdTeamScreenState();
}

class _TransitionToProdTeamScreenState
    extends State<TransitionToProdTeamScreen> {
  List<LaunchTeamMember> _teamRoster = [];
  List<LaunchHandoverItem> _handoverChecklist = [];
  List<LaunchKnowledgeTransfer> _knowledgeTransfers = [];
  List<LaunchApproval> _signOffs = [];

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
      activeItemLabel: 'Transition To Production Team',
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
            _buildTeamRosterPanel(),
            const SizedBox(height: 16),
            _buildHandoverChecklistPanel(),
            const SizedBox(height: 16),
            _buildKnowledgeTransferPanel(),
            const SizedBox(height: 16),
            _buildSignOffsPanel(),
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Deliver Project',
              nextLabel: 'Next: Contract Close Out',
              onBack: () => DeliverProjectClosureScreen.open(context),
              onNext: () => ContractCloseOutScreen.open(context),
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
      title: 'Transition to Production Team',
      description:
          'Hand over deliverables, documentation, and system access to the operations team. Track sign-offs and knowledge transfer.',
      trailing: ExecutionActionBar(
        actions: [
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
    final active = _teamRoster.where((m) => m.releaseStatus == 'Active').length;
    final pendingHandover =
        _handoverChecklist.where((h) => h.status == 'Pending').length;
    final pendingKt =
        _knowledgeTransfers.where((k) => k.status == 'Pending').length;
    final pendingSignOff = _signOffs.where((s) => s.status == 'Pending').length;

    return ExecutionMetricsGrid(
      metrics: [
        ExecutionMetricData(
          label: 'Team Members',
          value: '${_teamRoster.length}',
          icon: Icons.people_outline,
          emphasisColor: const Color(0xFF2563EB),
          helper: '$active active',
        ),
        ExecutionMetricData(
          label: 'Handover Items',
          value: '${_handoverChecklist.length}',
          icon: Icons.swap_horiz,
          emphasisColor: const Color(0xFF8B5CF6),
          helper: '$pendingHandover pending',
        ),
        ExecutionMetricData(
          label: 'Knowledge Transfers',
          value: '${_knowledgeTransfers.length}',
          icon: Icons.school_outlined,
          emphasisColor: const Color(0xFFF59E0B),
          helper: '$pendingKt pending',
        ),
        ExecutionMetricData(
          label: 'Sign-Offs',
          value: '$pendingSignOff / ${_signOffs.length}',
          icon: Icons.assignment_turned_in_outlined,
          emphasisColor: pendingSignOff > 0
              ? const Color(0xFFEF4444)
              : const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildTeamRosterPanel() {
    return LaunchDataTable(
      title: 'Production Team Roster',
      subtitle: 'Members receiving the handover from the project team.',
      columns: const ['Name', 'Role', 'Contact', 'Start Date', 'Status'],
      rowCount: _teamRoster.length,
      onAdd: _addMember,
      importLabel: 'Import from Staffing',
      onImport: _importStaffing,
      emptyMessage:
          'No team members yet. Add production team members or import from staffing.',
      cellBuilder: (context, idx) {
        final item = _teamRoster[idx];
        return LaunchDataRow(
          onDelete: () => _deleteTeamMember(idx),
          cells: [
            LaunchEditableCell(
              value: item.name,
              hint: 'Name',
              bold: true,
              expand: true,
              onChanged: (v) {
                _teamRoster[idx] = item.copyWith(name: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.role,
              hint: 'Role',
              expand: true,
              onChanged: (v) {
                _teamRoster[idx] = item.copyWith(role: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.contact,
              hint: 'Contact',
              expand: true,
              onChanged: (v) {
                _teamRoster[idx] = item.copyWith(contact: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.startDate,
              hint: 'Start',
              expand: true,
              onChanged: (v) {
                _teamRoster[idx] = item.copyWith(startDate: v);
                _scheduleSave();
              },
            ),
            LaunchStatusDropdown(
              value: item.releaseStatus,
              items: const ['Active', 'Transitioning', 'Released'],
              onChanged: (v) {
                if (v == null) return;
                _teamRoster[idx] = item.copyWith(releaseStatus: v);
                _scheduleSave();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHandoverChecklistPanel() {
    return LaunchDataTable(
      title: 'Handover Checklist',
      subtitle:
          'Structured items to transfer to production: docs, access, monitoring, training, runbooks.',
      columns: const ['Category', 'Item', 'Owner', 'Due', 'Status'],
      rowCount: _handoverChecklist.length,
      onAdd: _addHandoverItem,
      emptyMessage:
          'No handover items. Add items to track the production handover.',
      cellBuilder: (context, idx) {
        final item = _handoverChecklist[idx];
        return LaunchDataRow(
          onDelete: () => _deleteHandoverItem(idx),
          cells: [
            LaunchStatusDropdown(
              value: item.category,
              items: LaunchHandoverItem.categories,
              onChanged: (v) {
                if (v == null) return;
                _handoverChecklist[idx] = item.copyWith(category: v);
                _scheduleSave();
                setState(() {});
              },
            ),
            LaunchEditableCell(
              value: item.item,
              hint: 'Item',
              bold: true,
              expand: true,
              onChanged: (v) {
                _handoverChecklist[idx] = item.copyWith(item: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.owner,
              hint: 'Owner',
              expand: true,
              onChanged: (v) {
                _handoverChecklist[idx] = item.copyWith(owner: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.dueDate,
              hint: 'Due',
              expand: true,
              onChanged: (v) {
                _handoverChecklist[idx] = item.copyWith(dueDate: v);
                _scheduleSave();
              },
            ),
            LaunchStatusDropdown(
              value: item.status,
              items: const ['Pending', 'In Progress', 'Complete'],
              onChanged: (v) {
                if (v == null) return;
                _handoverChecklist[idx] = item.copyWith(status: v);
                _scheduleSave();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildKnowledgeTransferPanel() {
    return LaunchDataTable(
      title: 'Knowledge Transfer',
      subtitle: 'Track sessions, artifacts, and owners for knowledge capture.',
      columns: const ['Topic', 'From', 'To', 'Method', 'Status'],
      rowCount: _knowledgeTransfers.length,
      onAdd: _addKnowledgeTransfer,
      emptyMessage:
          'No knowledge transfers. Track knowledge handoff from project team to operations.',
      cellBuilder: (context, idx) {
        final item = _knowledgeTransfers[idx];
        return LaunchDataRow(
          onDelete: () => _deleteKnowledgeTransfer(idx),
          cells: [
            LaunchEditableCell(
              value: item.topic,
              hint: 'Topic',
              bold: true,
              expand: true,
              onChanged: (v) {
                _knowledgeTransfers[idx] = item.copyWith(topic: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.fromPerson,
              hint: 'From',
              expand: true,
              onChanged: (v) {
                _knowledgeTransfers[idx] = item.copyWith(fromPerson: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.toPerson,
              hint: 'To',
              expand: true,
              onChanged: (v) {
                _knowledgeTransfers[idx] = item.copyWith(toPerson: v);
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.method,
              hint: 'Method',
              expand: true,
              onChanged: (v) {
                _knowledgeTransfers[idx] = item.copyWith(method: v);
                _scheduleSave();
              },
            ),
            LaunchStatusDropdown(
              value: item.status,
              items: const ['Pending', 'Scheduled', 'Complete'],
              onChanged: (v) {
                if (v == null) return;
                _knowledgeTransfers[idx] = item.copyWith(status: v);
                _scheduleSave();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSignOffsPanel() {
    return LaunchDataTable(
      title: 'Ops & Client Sign-Offs',
      subtitle: 'Track who needs to approve the handover and their status.',
      columns: const ['Stakeholder', 'Role', 'Status', 'Date', 'Notes'],
      rowCount: _signOffs.length,
      onAdd: _addApproval,
      emptyMessage:
          'No sign-offs yet. Capture who needs to approve the handover.',
      cellBuilder: (context, idx) {
        final item = _signOffs[idx];
        return LaunchDataRow(
          onDelete: () => _deleteApproval(idx),
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
            LaunchEditableCell(
              value: item.date,
              hint: 'Date',
              expand: true,
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

  void _addMember() {
    setState(() => _teamRoster.add(LaunchTeamMember()));
    _scheduleSave();
  }

  void _addHandoverItem() {
    setState(() => _handoverChecklist.add(LaunchHandoverItem()));
    _scheduleSave();
  }

  void _addKnowledgeTransfer() {
    setState(() => _knowledgeTransfers.add(LaunchKnowledgeTransfer()));
    _scheduleSave();
  }

  void _addApproval() {
    setState(() => _signOffs.add(LaunchApproval()));
    _scheduleSave();
  }

  Future<void> _deleteTeamMember(int idx) async {
    final name = _teamRoster[idx].name.isNotEmpty
        ? _teamRoster[idx].name
        : 'team member';
    final confirmed = await launchConfirmDelete(context, itemName: name);
    if (!confirmed) return;
    setState(() => _teamRoster.removeAt(idx));
    _scheduleSave();
  }

  Future<void> _deleteHandoverItem(int idx) async {
    final label = _handoverChecklist[idx].item.isNotEmpty
        ? _handoverChecklist[idx].item
        : 'handover item';
    final confirmed = await launchConfirmDelete(context, itemName: label);
    if (!confirmed) return;
    setState(() => _handoverChecklist.removeAt(idx));
    _scheduleSave();
  }

  Future<void> _deleteKnowledgeTransfer(int idx) async {
    final topic = _knowledgeTransfers[idx].topic.isNotEmpty
        ? _knowledgeTransfers[idx].topic
        : 'knowledge transfer';
    final confirmed = await launchConfirmDelete(context, itemName: topic);
    if (!confirmed) return;
    setState(() => _knowledgeTransfers.removeAt(idx));
    _scheduleSave();
  }

  Future<void> _deleteApproval(int idx) async {
    final who = _signOffs[idx].stakeholder.isNotEmpty
        ? _signOffs[idx].stakeholder
        : 'sign-off';
    final confirmed = await launchConfirmDelete(context, itemName: who);
    if (!confirmed) return;
    setState(() => _signOffs.removeAt(idx));
    _scheduleSave();
  }

  Future<void> _importStaffing() async {
    if (_projectId == null) return;
    final staff = await LaunchPhaseService.loadExecutionStaffing(_projectId!);
    if (staff.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No team members found to import.')),
        );
      }
      return;
    }
    setState(() {
      final existing = _teamRoster.map((m) => m.name).toSet();
      for (final m in staff) {
        if (!existing.contains(m.name)) _teamRoster.add(m);
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
      final result =
          await LaunchPhaseService.loadTransitionToProd(projectId: _projectId!);
      if (!mounted) return;
      setState(() {
        _teamRoster = result.teamRoster;
        _handoverChecklist = result.handoverChecklist;
        _knowledgeTransfers = result.knowledgeTransfers;
        _signOffs = result.signOffs;
        _isLoading = false;
        _hasLoaded = true;
      });

      if (_teamRoster.isEmpty) {
        await _autoImportStaffing();
      }

      final allEmpty = _teamRoster.isEmpty &&
          _handoverChecklist.isEmpty &&
          _knowledgeTransfers.isEmpty &&
          _signOffs.isEmpty;
      if (allEmpty) await _populateFromAi();
    } catch (e) {
      debugPrint('Transition load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
    _suspendSave = false;
  }

  Future<void> _autoImportStaffing() async {
    if (_projectId == null) return;
    try {
      final staff = await LaunchPhaseService.loadExecutionStaffing(_projectId!);
      if (staff.isNotEmpty && mounted) {
        setState(() {
          _teamRoster.addAll(staff);
        });
        await _persistData();
      }
    } catch (_) {}
  }

  Future<void> _persistData() async {
    if (_projectId == null) return;
    try {
      await LaunchPhaseService.saveTransitionToProd(
        projectId: _projectId!,
        teamRoster: _teamRoster,
        handoverChecklist: _handoverChecklist,
        knowledgeTransfers: _knowledgeTransfers,
        signOffs: _signOffs,
      );
    } catch (e) {
      debugPrint('Transition save error: $e');
    }
  }

  Future<void> _populateFromAi() async {
    if (_isGenerating) return;
    final projectData = ProjectDataHelper.getData(context);
    var contextText = ProjectDataHelper.buildExecutivePlanContext(
      projectData,
      sectionLabel: 'Transition to Production Team',
    );
    if (contextText.trim().isEmpty) {
      contextText = ProjectDataHelper.buildProjectContextScan(
        projectData,
        sectionLabel: 'Transition to Production Team',
      );
    }
    if (contextText.trim().isEmpty) return;

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> generated = {};
    try {
      generated = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: contextText,
        sections: const {
          'team_roster': 'Production team members with name, role, contact',
          'handover_checklist':
              'Handover items with category, item description, owner, status',
          'knowledge_transfer':
              'Knowledge transfer topics with from-person, to-person, method, status',
          'signoffs': 'Sign-off approvers with name, role, status',
        },
        itemsPerSection: 3,
      );
    } catch (e) {
      debugPrint('Transition AI error: $e');
    }

    if (!mounted) return;
    final hasExisting = _teamRoster.isNotEmpty ||
        _handoverChecklist.isNotEmpty ||
        _knowledgeTransfers.isNotEmpty ||
        _signOffs.isNotEmpty;
    if (hasExisting) {
      setState(() => _isGenerating = false);
      return;
    }

    setState(() {
      _teamRoster = _mapMembers(generated['team_roster']);
      _handoverChecklist = _mapHandoverItems(generated['handover_checklist']);
      _knowledgeTransfers = _mapKT(generated['knowledge_transfer']);
      _signOffs = _mapApprovals(generated['signoffs']);
      _isGenerating = false;
    });
    await _persistData();
  }

  List<LaunchTeamMember> _mapMembers(List<Map<String, dynamic>>? raw) {
    if (raw == null) return [];
    return raw
        .map((m) {
          final title = (m['title'] ?? '').toString().trim();
          final details = (m['details'] ?? '').toString().trim();
          return LaunchTeamMember(
              name: title, role: details.isNotEmpty ? details : 'Team Member');
        })
        .where((i) => i.name.isNotEmpty)
        .toList();
  }

  List<LaunchHandoverItem> _mapHandoverItems(List<Map<String, dynamic>>? raw) {
    if (raw == null) return [];
    return raw
        .map((m) {
          return LaunchHandoverItem(
            item: (m['title'] ?? '').toString().trim(),
            owner: (m['details'] ?? '').toString().trim(),
            status: _norm(m['status'], 'Pending'),
          );
        })
        .where((i) => i.item.isNotEmpty)
        .toList();
  }

  List<LaunchKnowledgeTransfer> _mapKT(List<Map<String, dynamic>>? raw) {
    if (raw == null) return [];
    return raw
        .map((m) {
          return LaunchKnowledgeTransfer(
            topic: (m['title'] ?? '').toString().trim(),
            status: _norm(m['status'], 'Pending'),
          );
        })
        .where((i) => i.topic.isNotEmpty)
        .toList();
  }

  List<LaunchApproval> _mapApprovals(List<Map<String, dynamic>>? raw) {
    if (raw == null) return [];
    return raw
        .map((m) {
          return LaunchApproval(
            stakeholder: (m['title'] ?? '').toString().trim(),
            role: (m['details'] ?? '').toString().trim(),
            status: _norm(m['status'], 'Pending'),
          );
        })
        .where((i) => i.stakeholder.isNotEmpty)
        .toList();
  }

  String _norm(dynamic v, String fb) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? fb : s;
  }
}
