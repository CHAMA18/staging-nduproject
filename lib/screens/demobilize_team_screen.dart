import 'package:flutter/material.dart';

import 'package:ndu_project/models/launch_phase_models.dart';
import 'package:ndu_project/screens/project_close_out_screen.dart';
import 'package:ndu_project/services/launch_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/execution_phase_ui.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_data_table.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class DemobilizeTeamScreen extends StatefulWidget {
  const DemobilizeTeamScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DemobilizeTeamScreen()),
    );
  }

  @override
  State<DemobilizeTeamScreen> createState() => _DemobilizeTeamScreenState();
}

class _DemobilizeTeamScreenState extends State<DemobilizeTeamScreen> {
  List<LaunchTeamMember> _teamRoster = [];
  List<LaunchKnowledgeTransfer> _knowledgeTransfers = [];
  List<LaunchFollowUpItem> _vendorOffboarding = [];
  List<LaunchCommunicationItem> _communications = [];
  LaunchClosureNotes _debriefNotes = LaunchClosureNotes();

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
      activeItemLabel: 'Demobilize Team',
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
            _buildKnowledgeTransferPanel(),
            const SizedBox(height: 16),
            _buildVendorOffboardingPanel(),
            const SizedBox(height: 16),
            _buildCommunicationsPanel(),
            const SizedBox(height: 16),
            _buildDebriefNotesPanel(),
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Project Close Out',
              nextLabel: 'Project Complete',
              onBack: () => ProjectCloseOutScreen.open(context),
              onNext: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Project launch phase complete! All steps finished.'),
                    duration: Duration(seconds: 4),
                  ),
                );
              },
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
      title: 'Demobilize Team',
      description:
          'Wind down the project team responsibly. Track releases, knowledge transfer, vendor offboarding, and communications.',
      trailing: ExecutionActionBar(
        actions: [
          ExecutionActionItem(
            label: 'Import Team',
            icon: Icons.download_outlined,
            tone: ExecutionActionTone.secondary,
            onPressed: _importTeam,
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
    final active = _teamRoster.where((m) => m.releaseStatus == 'Active').length;
    final released =
        _teamRoster.where((m) => m.releaseStatus == 'Released').length;
    final pendingKt =
        _knowledgeTransfers.where((k) => k.status != 'Complete').length;
    final pendingComms =
        _communications.where((c) => c.status != 'Sent').length;

    return ExecutionMetricsGrid(
      metrics: [
        ExecutionMetricData(
          label: 'Team Members',
          value: '${_teamRoster.length}',
          icon: Icons.people_outline,
          emphasisColor: const Color(0xFF2563EB),
          helper: '$active active, $released released',
        ),
        ExecutionMetricData(
          label: 'Knowledge Transfers',
          value: '$pendingKt pending',
          icon: Icons.school_outlined,
          emphasisColor:
              pendingKt > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        ),
        ExecutionMetricData(
          label: 'Vendor Offboarding',
          value: '${_vendorOffboarding.length}',
          icon: Icons.business_center_outlined,
          emphasisColor: const Color(0xFF8B5CF6),
        ),
        ExecutionMetricData(
          label: 'Communications',
          value: '$pendingComms pending',
          icon: Icons.campaign_outlined,
          emphasisColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildTeamRosterPanel() {
    return LaunchDataTable(
      title: 'Team Ramp-Down Roster',
      subtitle: 'Track each team member\'s release status and dates.',
      columns: const ['Name', 'Role', 'Contact', 'Status'],
      rowCount: _teamRoster.length,
      onAdd: () {
        setState(() => _teamRoster.add(LaunchTeamMember()));
        _save();
      },
      onImport: _importTeam,
      importLabel: 'Import',
      emptyMessage: 'No team members. Add or import from staffing.',
      cellBuilder: (context, i) {
        final m = _teamRoster[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirmed =
                await launchConfirmDelete(context, itemName: 'team member');
            if (!confirmed) return;
            setState(() => _teamRoster.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: m.name,
              hint: 'Name',
              bold: true,
              expand: true,
              onChanged: (s) {
                _teamRoster[i] = m.copyWith(name: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: m.role,
              hint: 'Role',
              expand: true,
              onChanged: (s) {
                _teamRoster[i] = m.copyWith(role: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: m.contact,
              hint: 'Contact',
              expand: true,
              onChanged: (s) {
                _teamRoster[i] = m.copyWith(contact: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: m.releaseStatus,
              items: const ['Active', 'Transitioning', 'Released'],
              onChanged: (s) {
                if (s == null) return;
                _teamRoster[i] = m.copyWith(releaseStatus: s);
                _save();
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
      subtitle: 'Sessions and artifacts being handed off before team release.',
      columns: const ['Topic', 'From', 'To', 'Method', 'Status'],
      rowCount: _knowledgeTransfers.length,
      onAdd: () {
        setState(() => _knowledgeTransfers.add(LaunchKnowledgeTransfer()));
        _save();
      },
      emptyMessage: 'No transfers. Track knowledge handoff sessions.',
      cellBuilder: (context, i) {
        final k = _knowledgeTransfers[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirmed = await launchConfirmDelete(context,
                itemName: 'knowledge transfer');
            if (!confirmed) return;
            setState(() => _knowledgeTransfers.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: k.topic,
              hint: 'Topic',
              bold: true,
              expand: true,
              onChanged: (s) {
                _knowledgeTransfers[i] = k.copyWith(topic: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: k.fromPerson,
              hint: 'From',
              expand: true,
              onChanged: (s) {
                _knowledgeTransfers[i] = k.copyWith(fromPerson: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: k.toPerson,
              hint: 'To',
              expand: true,
              onChanged: (s) {
                _knowledgeTransfers[i] = k.copyWith(toPerson: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: k.method,
              hint: 'Method',
              expand: true,
              onChanged: (s) {
                _knowledgeTransfers[i] = k.copyWith(method: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: k.status,
              items: const ['Pending', 'Scheduled', 'Complete'],
              onChanged: (s) {
                if (s == null) return;
                _knowledgeTransfers[i] = k.copyWith(status: s);
                _save();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildVendorOffboardingPanel() {
    return LaunchDataTable(
      title: 'Vendor Offboarding',
      subtitle:
          'Track vendor exits, access cleanup, and remaining obligations.',
      columns: const ['Task', 'Details', 'Owner', 'Status'],
      rowCount: _vendorOffboarding.length,
      onAdd: () {
        setState(() => _vendorOffboarding.add(LaunchFollowUpItem()));
        _save();
      },
      emptyMessage: 'No vendor items. Track vendor offboarding tasks.',
      cellBuilder: (context, i) {
        final v = _vendorOffboarding[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirmed = await launchConfirmDelete(context,
                itemName: 'vendor offboarding task');
            if (!confirmed) return;
            setState(() => _vendorOffboarding.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: v.title,
              hint: 'Task',
              bold: true,
              expand: true,
              onChanged: (s) {
                _vendorOffboarding[i] = v.copyWith(title: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: v.details,
              hint: 'Details',
              expand: true,
              onChanged: (s) {
                _vendorOffboarding[i] = v.copyWith(details: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: v.owner,
              hint: 'Owner',
              expand: true,
              onChanged: (s) {
                _vendorOffboarding[i] = v.copyWith(owner: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: v.status,
              items: const ['Pending', 'In Progress', 'Complete'],
              onChanged: (s) {
                if (s == null) return;
                _vendorOffboarding[i] = v.copyWith(status: s);
                _save();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommunicationsPanel() {
    return LaunchDataTable(
      title: 'Communications & People Care',
      subtitle:
          'Planned communications to stakeholders, team, and affected people.',
      columns: const ['Audience', 'Message', 'Channel', 'Send Date', 'Status'],
      rowCount: _communications.length,
      onAdd: () {
        setState(() => _communications.add(LaunchCommunicationItem()));
        _save();
      },
      emptyMessage:
          'No communications. Plan team and stakeholder communications.',
      cellBuilder: (context, i) {
        final c = _communications[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirmed =
                await launchConfirmDelete(context, itemName: 'communication');
            if (!confirmed) return;
            setState(() => _communications.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: c.audience,
              hint: 'Audience',
              bold: true,
              expand: true,
              onChanged: (s) {
                _communications[i] = c.copyWith(audience: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: c.message,
              hint: 'Message',
              expand: true,
              onChanged: (s) {
                _communications[i] = c.copyWith(message: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: c.channel,
              hint: 'Channel',
              expand: true,
              onChanged: (s) {
                _communications[i] = c.copyWith(channel: s);
                _save();
              },
            ),
            LaunchDateCell(
              value: c.sendDate,
              hint: 'Date',
              onChanged: (s) {
                _communications[i] = c.copyWith(sendDate: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: c.status,
              items: const ['Planned', 'Sent', 'Cancelled'],
              onChanged: (s) {
                if (s == null) return;
                _communications[i] = c.copyWith(status: s);
                _save();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDebriefNotesPanel() {
    return ExecutionPanelShell(
      title: 'Team Debrief Notes',
      subtitle:
          'Recognition, feedback, reassignment notes, and closing thoughts.',
      child: TextFormField(
        initialValue: _debriefNotes.notes,
        maxLines: 6,
        style: const TextStyle(fontSize: 13, height: 1.6),
        decoration: InputDecoration(
          hintText:
              'Team recognition, feedback, reassignment notes, closing thoughts…',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB))),
        ),
        onChanged: (v) {
          _debriefNotes = LaunchClosureNotes(notes: v);
          _save();
        },
      ),
    );
  }

  Future<void> _importTeam() async {
    if (_projectId == null) return;
    final staff = await LaunchPhaseService.loadExecutionStaffing(_projectId!);
    if (staff.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No team members found to import.')));
      }
      return;
    }
    setState(() {
      final existing = _teamRoster.map((m) => m.name).toSet();
      for (final m in staff) {
        if (!existing.contains(m.name)) _teamRoster.add(m);
      }
    });
    _save();
  }

  void _save() {
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
          await LaunchPhaseService.loadDemobilizeTeam(projectId: _projectId!);
      if (!mounted) return;
      setState(() {
        _teamRoster = r.teamRoster;
        _knowledgeTransfers = r.knowledgeTransfers;
        _vendorOffboarding = r.vendorOffboarding;
        _communications = r.communications;
        _debriefNotes = r.debriefNotes;
        _isLoading = false;
        _hasLoaded = true;
      });
      if (_teamRoster.isEmpty) {
        final staff =
            await LaunchPhaseService.loadExecutionStaffing(_projectId!);
        if (staff.isNotEmpty) {
          setState(() => _teamRoster.addAll(staff));
          await _persistData();
        }
      }
      final allEmpty = _teamRoster.isEmpty &&
          _knowledgeTransfers.isEmpty &&
          _vendorOffboarding.isEmpty &&
          _communications.isEmpty;
      if (allEmpty) {
        await _populateFromAi();
      }
    } catch (e) {
      debugPrint('Demobilize load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
    _suspendSave = false;
  }

  Future<void> _persistData() async {
    if (_projectId == null) return;
    try {
      await LaunchPhaseService.saveDemobilizeTeam(
          projectId: _projectId!,
          teamRoster: _teamRoster,
          knowledgeTransfers: _knowledgeTransfers,
          vendorOffboarding: _vendorOffboarding,
          communications: _communications,
          debriefNotes: _debriefNotes);
    } catch (e) {
      debugPrint('Demobilize save error: $e');
    }
  }

  Future<void> _populateFromAi() async {
    if (_isGenerating) return;
    final data = ProjectDataHelper.getData(context);
    var ctx = ProjectDataHelper.buildExecutivePlanContext(data,
        sectionLabel: 'Demobilize Team');
    if (ctx.trim().isEmpty) {
      ctx = ProjectDataHelper.buildProjectContextScan(data,
          sectionLabel: 'Demobilize Team');
    }
    if (ctx.trim().isEmpty) return;

    if (_projectId != null) {
      final staff = await LaunchPhaseService.loadExecutionStaffing(_projectId!);
      final vendors = await LaunchPhaseService.loadExecutionVendors(_projectId!);
      if (mounted) {
        final staffingSummary = staff.isEmpty ? 'No staffing data.' : staff.map((s) => '- ${s.name} (${s.role}, status: ${s.releaseStatus})').take(8).join('\n');
        final vendorsSummary = vendors.isEmpty ? 'No vendor data.' : vendors.map((v) => '- ${v.vendorName} (status: ${v.accountStatus})').take(8).join('\n');
        ctx = ProjectDataHelper.buildLaunchPhaseContext(
          baseContext: ctx,
          sectionLabel: 'Demobilize Team',
          staffingSummary: staffingSummary,
          vendorsSummary: vendorsSummary,
        );
      }
    }

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> gen = {};
    try {
      gen = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: ctx,
        sections: const {
          'team_roster': 'Team members with "name", "role", "release_status"',
          'knowledge_transfer':
              'Knowledge transfer sessions with "topic", "from_person", "to_person", "method", "status"',
          'vendor_offboarding': 'Vendor offboarding tasks with "title", "details", "status"',
          'communications':
              'Communications with "audience", "message", "channel", "send_date", "status"',
        },
        itemsPerSection: 3,
      );
    } catch (e) {
      debugPrint('Demobilize AI error: $e');
    }
    if (!mounted) return;
    final hasData = _teamRoster.isNotEmpty ||
        _knowledgeTransfers.isNotEmpty ||
        _vendorOffboarding.isNotEmpty ||
        _communications.isNotEmpty;
    if (hasData) {
      setState(() => _isGenerating = false);
      return;
    }
    setState(() {
      _teamRoster = (gen['team_roster'] ?? [])
          .map((m) => LaunchTeamMember(
              name: _s(m['title']),
              role: _s(m['details']),
              releaseStatus: 'Active'))
          .where((i) => i.name.isNotEmpty)
          .toList();
      _knowledgeTransfers = (gen['knowledge_transfer'] ?? [])
          .map((m) => LaunchKnowledgeTransfer(
              topic: _s(m['title']), status: _ns(m['status'], 'Pending')))
          .where((i) => i.topic.isNotEmpty)
          .toList();
      _vendorOffboarding = (gen['vendor_offboarding'] ?? [])
          .map((m) => LaunchFollowUpItem(
              title: _s(m['title']),
              details: _s(m['details']),
              status: _ns(m['status'], 'Pending')))
          .where((i) => i.title.isNotEmpty)
          .toList();
      _communications = (gen['communications'] ?? [])
          .map((m) => LaunchCommunicationItem(
              audience: _s(m['title']),
              message: _s(m['details']),
              status: _ns(m['status'], 'Planned')))
          .where((i) => i.audience.isNotEmpty)
          .toList();
      _isGenerating = false;
    });
    await _persistData();
  }

  String _s(dynamic v) => (v ?? '').toString().trim();
  String _ns(dynamic v, String fb) => _s(v).isEmpty ? fb : _s(v);
}
