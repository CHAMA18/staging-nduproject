import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/screens/startup_planning_screen.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/ai_suggesting_textfield.dart';

class InterfaceManagementScreen extends StatelessWidget {
  const InterfaceManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InterfaceManagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 20.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Interface Management'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final gap = 24.0;
                        final twoCol = width >= 980;
                        final halfWidth = twoCol ? (width - gap) / 2 : width;
                        final data = ProjectDataHelper.getDataListening(context);
                        final entries = data.interfaceEntries;
                        final activeInterfaces = entries.length;
                        final criticalDependencies = entries
                            .where((entry) => _isCriticalRisk(entry.risk))
                            .length;
                        final integrationOwners = entries
                            .map((entry) => entry.owner.trim())
                            .where((owner) => owner.isNotEmpty)
                            .toSet()
                            .length;
                        final openIssues = entries
                            .where((entry) => _isOpenStatus(entry.status))
                            .length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(onBack: () => Navigator.maybePop(context)),
                            const SizedBox(height: 12),
                            const Text(
                              'Coordinate system interfaces, dependencies, and handoffs.',
                              style:
                                  TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            const PlanningAiNotesCard(
                              title: 'Notes',
                              sectionLabel: 'Interface Management',
                              noteKey: 'planning_interface_management_notes',
                              checkpoint: 'interface_management',
                              description:
                                  'Summarize interface ownership, dependency risks, and governance cadence.',
                            ),
                            const SizedBox(height: 24),
                            const InterfacePlanCard(),
                            const SizedBox(height: 24),
                            _MetricsRow(
                              activeInterfaces: activeInterfaces,
                              criticalDependencies: criticalDependencies,
                              integrationOwners: integrationOwners,
                              openIssues: openIssues,
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                  width: halfWidth,
                                  child: _InterfaceMapCard(entries: entries),
                                ),
                                SizedBox(
                                  width: halfWidth,
                                  child: _GovernanceCard(entries: entries),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const _InterfaceRegisterCard(),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                  width: halfWidth,
                                  child: _RisksCard(entries: entries),
                                ),
                                SizedBox(
                                  width: halfWidth,
                                  child: _DecisionLogCard(entries: entries),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const SizedBox(height: 12),
                            LaunchPhaseNavigation(
                              backLabel: 'Back: Technology',
                              nextLabel: 'Next: Start-Up Planning',
                              onBack: () => Navigator.of(context).maybePop(),
                              onNext: () => StartUpPlanningScreen.open(context),
                            ),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
                    ),
                  ),
                  const Positioned(right: 24, bottom: 24, child: KazAiChatBubble()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        const _CircleIconButton(icon: Icons.arrow_forward_ios_rounded),
        const SizedBox(width: 16),
        const Text(
          'Interface Management',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const Spacer(),
        const _UserChip(),
      ],
    );
  }
}

class InterfacePlanCard extends StatefulWidget {
  const InterfacePlanCard({super.key});

  @override
  State<InterfacePlanCard> createState() => _InterfacePlanCardState();
}

class _InterfacePlanCardState extends State<InterfacePlanCard> {
  static const String _noteKey = 'planning_interface_management_plan';
  Timer? _saveDebounce;
  DateTime? _lastSavedAt;
  late String _initialText;

  @override
  void initState() {
    super.initState();
    _initialText =
        ProjectDataHelper.getData(context).planningNotes[_noteKey] ?? '';
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () async {
      final trimmed = value.trim();
      final success = await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'interface_management',
        dataUpdater: (data) => data.copyWith(
          planningNotes: {
            ...data.planningNotes,
            _noteKey: trimmed,
          },
        ),
        showSnackbar: false,
      );
      if (!mounted) return;
      if (success) {
        setState(() => _lastSavedAt = DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Interface Plan',
      subtitle:
          'Describe ownership, cadence, and risk handling so teams coordinate before handoffs.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AiSuggestingTextField(
            fieldLabel: 'Interface Plan',
            hintText:
                'Outline the governance rhythm, ownership, and risk mitigations for key interfaces.',
            sectionLabel: 'Interface Management',
            showLabel: false,
            autoGenerate: true,
            autoGenerateSection: 'Interface Management Plan',
            initialText: _initialText,
            onChanged: _handleChanged,
          ),
          if (_lastSavedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Saved ${TimeOfDay.fromDateTime(_lastSavedAt!).format(context)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final email = user?.email ?? '';

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final role = isAdmin ? 'Admin' : 'Member';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                child: user?.photoURL == null
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(role, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF9CA3AF)),
            ],
          ),
        );
      },
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.activeInterfaces,
    required this.criticalDependencies,
    required this.integrationOwners,
    required this.openIssues,
  });

  final int activeInterfaces;
  final int criticalDependencies;
  final int integrationOwners;
  final int openIssues;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(
            label: 'Active Interfaces',
            value: activeInterfaces.toString(),
            accent: const Color(0xFF2563EB)),
        _MetricCard(
            label: 'Critical Dependencies',
            value: criticalDependencies.toString(),
            accent: const Color(0xFFF59E0B)),
        _MetricCard(
            label: 'Integration Owners',
            value: integrationOwners.toString(),
            accent: const Color(0xFF10B981)),
        _MetricCard(
            label: 'Open Issues',
            value: openIssues.toString(),
            accent: const Color(0xFFEF4444)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent),
          ),
        ],
      ),
    );
  }
}

class _InterfaceMapCard extends StatelessWidget {
  const _InterfaceMapCard({required this.entries});

  final List<InterfaceEntry> entries;

  @override
  Widget build(BuildContext context) {
    final boundaries = entries
        .map((entry) => entry.boundary.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final fallback = entries
        .where((entry) => entry.boundary.trim().isEmpty)
        .map((entry) => entry.owner.trim().isNotEmpty
            ? '${entry.owner.trim()} interface'
            : 'Unnamed interface')
        .toList();
    final display = [...boundaries, ...fallback];
    return _SectionCard(
      title: 'Interface Architecture Overview',
      subtitle: 'Key systems and integration touchpoints.',
      child: display.isEmpty
          ? const Text(
              'No interface boundaries recorded yet. Add entries below to map them.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...display.take(6).map(
                      (boundary) => Chip(
                        label: Text(boundary),
                        backgroundColor: const Color(0xFFE0F2FE),
                      ),
                    ),
                if (display.length > 6)
                  Text('+ ${display.length - 6} more boundaries',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
    );
  }
}

class _GovernanceCard extends StatelessWidget {
  const _GovernanceCard({required this.entries});

  final List<InterfaceEntry> entries;

  @override
  Widget build(BuildContext context) {
    final items = entries
        .where((entry) =>
            entry.cadence.trim().isNotEmpty ||
            entry.owner.trim().isNotEmpty ||
            entry.lastSync.trim().isNotEmpty)
        .map((entry) {
          final identity = entry.boundary.trim().isNotEmpty
              ? entry.boundary.trim()
              : entry.owner.trim().isNotEmpty
                  ? '${entry.owner.trim()} interface'
                  : 'Interface';
          final details = [
            if (entry.cadence.trim().isNotEmpty)
              'Cadence: ${entry.cadence.trim()}',
            if (entry.lastSync.trim().isNotEmpty)
              'Last sync: ${entry.lastSync.trim()}',
          ].join(' | ');
          return details.isNotEmpty ? '$identity | $details' : identity;
        })
        .toList();

    return _SectionCard(
      title: 'Governance & Cadence',
      subtitle: 'How interfaces are reviewed, approved, and synchronized.',
      child: items.isEmpty
          ? const Text(
              'Define interface owners and cadences to anchor your governance.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          : Column(
              children: items
                  .map((item) => _BulletRow(text: item))
                  .toList(),
            ),
    );
  }
}

class _InterfaceRegisterCard extends StatefulWidget {
  const _InterfaceRegisterCard();

  @override
  State<_InterfaceRegisterCard> createState() => _InterfaceRegisterCardState();
}

class _InterfaceRegisterCardState extends State<_InterfaceRegisterCard> {
  Future<void> _showEntryEditor([InterfaceEntry? entry]) async {
    final updated = await showDialog<InterfaceEntry>(
      context: context,
      builder: (_) => _InterfaceEntryDialog(initial: entry),
    );
    if (updated == null) return;
    if (!mounted) return;

    final data = ProjectDataHelper.getData(context);
    final entries = List<InterfaceEntry>.from(data.interfaceEntries);
    final index = entries.indexWhere((e) => e.id == updated.id);
    if (index == -1) {
      entries.add(updated);
    } else {
      entries[index] = updated;
    }

    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'interface_management',
      dataUpdater: (d) => d.copyWith(interfaceEntries: entries),
      showSnackbar: false,
    );
  }

  Future<void> _deleteEntry(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove interface entry'),
        content: const Text(
            'This will delete the interface entry and remove it from AI context.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    final data = ProjectDataHelper.getData(context);
    final entries =
        data.interfaceEntries.where((entry) => entry.id != id).toList();
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'interface_management',
      dataUpdater: (d) => d.copyWith(interfaceEntries: entries),
      showSnackbar: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = ProjectDataHelper.getDataListening(context).interfaceEntries;
    return _SectionCard(
      title: 'Interface Register',
      subtitle: 'Track ownership, status, cadence, and risk for every interface.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: ElevatedButton.icon(
              onPressed: () => _showEntryEditor(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Entry'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'No interface entries yet. Add a row to start capturing ownership and risks.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _InterfaceEntryRow(
                entry: entry,
                onEdit: () => _showEntryEditor(entry),
                onDelete: () => _deleteEntry(entry.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RisksCard extends StatelessWidget {
  const _RisksCard({required this.entries});

  final List<InterfaceEntry> entries;

  @override
  Widget build(BuildContext context) {
    final riskItems = entries
        .where((entry) => entry.risk.trim().isNotEmpty)
        .map((entry) {
          final label = entry.boundary.trim().isNotEmpty
              ? entry.boundary.trim()
              : entry.owner.trim().isNotEmpty
                  ? '${entry.owner.trim()} interface'
                  : 'Interface';
          final details = [
            entry.risk.trim(),
            if (entry.status.trim().isNotEmpty)
              'Status: ${entry.status.trim()}',
          ].join(' | ');
          return '$label | $details';
        })
        .toList();

    return _SectionCard(
      title: 'Dependency Risks',
      subtitle: 'Critical issues to resolve before baseline freeze.',
      child: riskItems.isEmpty
          ? const Text(
              'Record interface risks so teams can address blockers early.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          : Column(
              children:
                  riskItems.map((text) => _BulletRow(text: text)).toList(),
            ),
    );
  }
}

class _DecisionLogCard extends StatelessWidget {
  const _DecisionLogCard({required this.entries});

  final List<InterfaceEntry> entries;

  @override
  Widget build(BuildContext context) {
    final logItems = entries
        .where((entry) => entry.notes.trim().isNotEmpty)
        .map((entry) {
          final identifier = entry.boundary.trim().isNotEmpty
              ? entry.boundary.trim()
              : entry.owner.trim().isNotEmpty
                  ? '${entry.owner.trim()} interface'
                  : 'Interface note';
          final timestamp = entry.lastSync.trim().isNotEmpty
              ? entry.lastSync.trim()
              : 'Recent';
          return '$identifier: ${entry.notes.trim()} (Sync: $timestamp)';
        })
        .toList();

    return _SectionCard(
      title: 'Decision Log',
      subtitle: 'Recent interface decisions and approvals.',
      child: logItems.isEmpty
          ? const Text(
              'Add notes to capture decisions, approvals, and alignment.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          : Column(
              children: logItems
                  .map((text) => _BulletRow(text: text))
                  .toList(),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InterfaceEntryRow extends StatelessWidget {
  const _InterfaceEntryRow({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final InterfaceEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final boundary = entry.boundary.trim().isNotEmpty
        ? entry.boundary.trim()
        : 'Unnamed interface';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(boundary,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Edit entry',
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
                tooltip: 'Delete entry',
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (entry.owner.trim().isNotEmpty)
            Text('Owner: ${entry.owner.trim()}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          if (entry.cadence.trim().isNotEmpty)
            Text('Cadence: ${entry.cadence.trim()}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          if (entry.status.trim().isNotEmpty)
            Text('Status: ${entry.status.trim()}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          if (entry.risk.trim().isNotEmpty)
            Text('Risk: ${entry.risk.trim()}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          if (entry.lastSync.trim().isNotEmpty)
            Text('Last sync: ${entry.lastSync.trim()}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          if (entry.notes.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(entry.notes.trim(),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
            ),
        ],
      ),
    );
  }
}

class _InterfaceEntryDialog extends StatefulWidget {
  const _InterfaceEntryDialog({this.initial});

  final InterfaceEntry? initial;

  @override
  State<_InterfaceEntryDialog> createState() => _InterfaceEntryDialogState();
}

class _InterfaceEntryDialogState extends State<_InterfaceEntryDialog> {
  late final TextEditingController _boundaryCtrl;
  late final TextEditingController _ownerCtrl;
  late final TextEditingController _cadenceCtrl;
  late final TextEditingController _riskCtrl;
  late final TextEditingController _statusCtrl;
  late final TextEditingController _lastSyncCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _boundaryCtrl = TextEditingController(text: widget.initial?.boundary);
    _ownerCtrl = TextEditingController(text: widget.initial?.owner);
    _cadenceCtrl = TextEditingController(text: widget.initial?.cadence);
    _riskCtrl = TextEditingController(text: widget.initial?.risk);
    _statusCtrl = TextEditingController(text: widget.initial?.status);
    _lastSyncCtrl = TextEditingController(text: widget.initial?.lastSync);
    _notesCtrl = TextEditingController(text: widget.initial?.notes);
  }

  @override
  void dispose() {
    _boundaryCtrl.dispose();
    _ownerCtrl.dispose();
    _cadenceCtrl.dispose();
    _riskCtrl.dispose();
    _statusCtrl.dispose();
    _lastSyncCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final entry = InterfaceEntry(
      id: widget.initial?.id,
      boundary: _boundaryCtrl.text.trim(),
      owner: _ownerCtrl.text.trim(),
      cadence: _cadenceCtrl.text.trim(),
      risk: _riskCtrl.text.trim(),
      status: _statusCtrl.text.trim(),
      lastSync: _lastSyncCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    Navigator.of(context).pop(entry);
  }

  Widget _buildField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Interface Entry' : 'Edit Interface Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField('System Boundary', _boundaryCtrl),
            _buildField('Owner', _ownerCtrl),
            _buildField('Cadence', _cadenceCtrl),
            _buildField('Risk', _riskCtrl),
            _buildField('Status', _statusCtrl),
            _buildField('Last Sync', _lastSyncCtrl),
            _buildField('Notes', _notesCtrl, maxLines: 3),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4))),
        ],
      ),
    );
  }
}

bool _isCriticalRisk(String risk) {
  final normalized = risk.toLowerCase();
  return normalized.contains('high') ||
      normalized.contains('critical') ||
      normalized.contains('blocker') ||
      normalized.contains('severe');
}

bool _isOpenStatus(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  return !{
    'approved',
    'closed',
    'resolved',
    'done',
    'complete',
  }.contains(normalized);
}
