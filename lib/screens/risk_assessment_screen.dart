import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';

class RiskAssessmentScreen extends StatefulWidget {
  const RiskAssessmentScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RiskAssessmentScreen()),
    );
  }

  @override
  State<RiskAssessmentScreen> createState() => _RiskAssessmentScreenState();
}

class _RiskAssessmentScreenState extends State<RiskAssessmentScreen> {
  final List<_RiskEntry> _entries = [];
  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter;
  bool _loadingEntries = false;

  final TextEditingController _notesController = TextEditingController();
  final _Debouncer _notesDebounce = _Debouncer();
  bool _notesSaving = false;
  DateTime? _notesSavedAt;
  bool _didInitNotes = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEntries());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitNotes) return;
    final data = ProjectDataHelper.getData(context);
    _notesController.text =
        data.planningNotes['planning_risk_assessment_notes'] ?? '';
    _didInitNotes = true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    _notesDebounce.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) return;
    setState(() => _loadingEntries = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('risk_assessment_entries')
          .orderBy('createdAt', descending: true)
          .get();
      final entries =
          snapshot.docs.map((doc) => _RiskEntry.fromFirestore(doc)).toList();
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(entries);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load risk register data')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingEntries = false);
    }
  }

  Future<void> _persistEntry(_RiskEntry entry, {required bool isNew}) async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) return;
    final docRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('risk_assessment_entries')
        .doc(entry.docId);
    await docRef.set(entry.toFirestore(isNew: isNew), SetOptions(merge: true));
  }

  void _handleNotesChanged(String value) {
    final trimmed = value.trim();
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        planningNotes: {
          ...data.planningNotes,
          'planning_risk_assessment_notes': trimmed,
        },
      ),
    );
    _notesDebounce.run(() async {
      if (!mounted) return;
      setState(() => _notesSaving = true);
      final success = await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'risk_assessment',
        dataUpdater: (data) => data.copyWith(
          planningNotes: {
            ...data.planningNotes,
            'planning_risk_assessment_notes': trimmed,
          },
        ),
        showSnackbar: false,
      );
      if (!mounted) return;
      setState(() {
        _notesSaving = false;
        if (success) _notesSavedAt = DateTime.now();
      });
    });
  }

  Future<void> _openEntryDialog(
      {_RiskEntry? entry, bool readOnly = false}) async {
    final idController = TextEditingController(text: entry?.id ?? '');
    final descriptionController =
        TextEditingController(text: entry?.description ?? '');
    final categoryController =
        TextEditingController(text: entry?.category ?? '');
    final probabilityController =
        TextEditingController(text: entry?.probability ?? '');
    final impactController = TextEditingController(text: entry?.impact ?? '');
    final scoreController = TextEditingController(text: entry?.score ?? '');
    final ownerController = TextEditingController(text: entry?.owner ?? '');
    final statusController = TextEditingController(text: entry?.status ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final bool isEditing = entry != null;
        return AlertDialog(
          title: Text(
              readOnly ? 'View risk' : (isEditing ? 'Edit risk' : 'Add risk')),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(
                      controller: idController,
                      label: 'Risk ID',
                      readOnly: readOnly),
                  _dialogField(
                      controller: descriptionController,
                      label: 'Description',
                      readOnly: readOnly,
                      maxLines: 2),
                  _dialogField(
                      controller: categoryController,
                      label: 'Category',
                      readOnly: readOnly),
                  _dialogField(
                      controller: probabilityController,
                      label: 'Probability',
                      readOnly: readOnly),
                  _dialogField(
                      controller: impactController,
                      label: 'Impact',
                      readOnly: readOnly),
                  _dialogField(
                      controller: scoreController,
                      label: 'Risk Score',
                      readOnly: readOnly),
                  _dialogField(
                      controller: ownerController,
                      label: 'Owner',
                      readOnly: readOnly),
                  _dialogField(
                      controller: statusController,
                      label: 'Status',
                      readOnly: readOnly),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Close')),
            if (!readOnly)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
          ],
        );
      },
    );

    if (result != true || readOnly) return;
    final newEntry = _RiskEntry(
      docId: entry?.docId ?? _newEntryId(),
      id: idController.text.trim().isEmpty
          ? 'R-${DateTime.now().millisecondsSinceEpoch}'
          : idController.text.trim(),
      description: descriptionController.text.trim(),
      category: categoryController.text.trim(),
      probability: probabilityController.text.trim(),
      impact: impactController.text.trim(),
      score: scoreController.text.trim(),
      owner: ownerController.text.trim(),
      status: statusController.text.trim().isEmpty
          ? 'Open'
          : statusController.text.trim(),
      createdAt: entry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      final index = _entries.indexWhere((item) => item.docId == newEntry.docId);
      if (index == -1) {
        _entries.insert(0, newEntry);
      } else {
        _entries[index] = newEntry;
      }
    });
    await _persistEntry(newEntry, isNew: entry == null);
  }

  String _newEntryId() {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('risk_assessment_entries')
        .doc()
        .id;
  }

  List<_RiskEntry> _filteredEntries() {
    final query = _searchController.text.trim().toLowerCase();
    return _entries.where((entry) {
      final matchesStatus =
          _statusFilter == null || entry.status == _statusFilter;
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;
      final haystack = [
        entry.id,
        entry.description,
        entry.category,
        entry.owner,
        entry.status,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _openFilterDialog() async {
    final current = _statusFilter;
    final options = ['All', 'Open', 'In Progress', 'Monitoring', 'Closed'];
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                RadioListTile<String?>(
                  title: Text(option),
                  value: option == 'All' ? null : option,
                  groupValue: current,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
            ],
          ),
        );
      },
    );
    if (result == null && current == null) return;
    setState(() => _statusFilter = result);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 36;
    final entries = _filteredEntries();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Risk Assessment'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopUtilityBar(
                            onBack: () => Navigator.maybePop(context)),
                        const SizedBox(height: 24),
                        const _PageHeading(),
                        const SizedBox(height: 20),
                        _RiskNotesCard(
                          controller: _notesController,
                          saving: _notesSaving,
                          savedAt: _notesSavedAt,
                          onChanged: _handleNotesChanged,
                        ),
                        const SizedBox(height: 24),
                        _MetricsWrap(isMobile: isMobile),
                        const SizedBox(height: 28),
                        const _RiskMatrixCard(),
                        const SizedBox(height: 28),
                        _RiskRegister(
                          entries: entries,
                          isMobile: isMobile,
                          loading: _loadingEntries,
                          searchController: _searchController,
                          onAdd: () => _openEntryDialog(),
                          onFilter: _openFilterDialog,
                          onView: (entry) =>
                              _openEntryDialog(entry: entry, readOnly: true),
                          onEdit: (entry) => _openEntryDialog(entry: entry),
                        ),
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
}

class _TopUtilityBar extends StatelessWidget {
  const _TopUtilityBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final email = user?.email ?? '';
    final primaryText = email.isNotEmpty ? email : displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _circleButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 12),
          _circleButton(
              icon: Icons.arrow_forward_ios_rounded,
              onTap: () {
                final navIndex =
                    PlanningPhaseNavigation.getPageIndex('risk_management');
                if (navIndex != -1 &&
                    navIndex < PlanningPhaseNavigation.pages.length - 1) {
                  final nextPage = PlanningPhaseNavigation.pages[navIndex + 1];
                  Navigator.push(
                      context, MaterialPageRoute(builder: nextPage.builder));
                }
              }),
          const SizedBox(width: 20),
          const Text(
            'Risk Mitigation',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827)),
          ),
          const Spacer(),
          StreamBuilder<bool>(
            stream: UserService.watchAdminStatus(),
            builder: (context, snapshot) {
              final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
              final role = isAdmin ? 'Admin' : 'Member';
              return _UserChip(name: primaryText, role: role);
            },
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _RiskNotesCard extends StatelessWidget {
  const _RiskNotesCard({
    required this.controller,
    required this.saving,
    required this.savedAt,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool saving;
  final DateTime? savedAt;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.note_outlined,
                    color: Color(0xFF475569), size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Notes',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
              ),
              if (saving)
                const _StatusChip(label: 'Saving...', color: Color(0xFF64748B))
              else if (savedAt != null)
                _StatusChip(
                  label:
                      'Saved ${TimeOfDay.fromDateTime(savedAt!).format(context)}',
                  color: const Color(0xFF16A34A),
                  background: const Color(0xFFECFDF3),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Summarize key risks, probability/impact themes, and mitigation focus.',
            style:
                TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Capture risk assessment notes here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(
      {required this.label, required this.color, this.background});

  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE5E7EB),
            child: Icon(Icons.person, size: 18, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827)),
              ),
              Text(
                role,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: const Color(0xFF111827),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class _YellowButton extends StatelessWidget {
  const _YellowButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD54F),
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Assessment',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827)),
        ),
        SizedBox(height: 8),
        Text(
          'Identify, analyze and mitigate project risks.',
          style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _MetricsWrap extends StatelessWidget {
  const _MetricsWrap({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    // Derive metrics dynamically from project data; no hardcoded defaults.
    final project = context.watch<ProjectDataProvider>().projectData;
    final allRisks = project.solutionRisks
        .expand((sr) => sr.risks)
        .where((r) => r.trim().isNotEmpty)
        .toList();
    final int totalRisks = allRisks.length;

    // Placeholder logic for areas/status until richer data exists.
    // Keep UI consistent without implying default data.
    const String unknown = '—';
    final double? progress = null; // Unknown until mitigation statuses exist
    final String statusSubtitle = unknown;
    final String topRiskArea = unknown;
    final String unaddressed = totalRisks == 0 ? '0' : unknown;

    const double cardHeight =
        148; // Uniform height to prevent visual jumps/overflow
    final cards = [
      _MetricCard(
        height: cardHeight,
        title: 'Total Risks',
        subtitle: '$totalRisks',
        // Show simple category summary only if present later; keep minimal now.
      ),
      _MetricCard(
        height: cardHeight,
        title: 'Risk Status',
        subtitle: statusSubtitle,
        progress: progress,
      ),
      _MetricCard(
        height: cardHeight,
        title: 'Top Risk Area',
        subtitle: topRiskArea,
        footer: totalRisks == 0 ? 'No risks yet' : null,
        footerIcon: totalRisks == 0 ? Icons.info_outline : null,
      ),
      _MetricCard(
        height: cardHeight,
        title: 'Unaddressed',
        subtitle: unaddressed,
        footer: totalRisks == 0 ? 'Add risks to begin tracking' : null,
        footerIcon: totalRisks == 0 ? Icons.info_outline : null,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == cards.length - 1 ? 0 : 16),
              child: SizedBox(width: double.infinity, child: cards[i]),
            ),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards
          .map(
            (card) => SizedBox(width: 260, child: card),
          )
          .toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.subtitle,
    this.height,
    List<_Badge>? badges,
    this.progress,
    this.footer,
    this.footerIcon,
  }) : badges = badges ?? const [];

  final String title;
  final String subtitle;
  final double? height;
  final List<_Badge> badges;
  final double? progress;
  final String? footer;
  final IconData? footerIcon;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827)),
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges,
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD54F)),
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (footerIcon != null)
                  Icon(footerIcon, size: 16, color: const Color(0xFF6B7280)),
                if (footerIcon != null) const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    footer!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (height != null) {
      return SizedBox(height: height, child: content);
    }
    return content;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151)),
      ),
    );
  }
}

class _RiskMatrixCard extends StatelessWidget {
  const _RiskMatrixCard();

  static const Color _high = Color(0xFFFEE2E2);
  static const Color _medium = Color(0xFFFEF3C7);
  static const Color _low = Color(0xFFDCFCE7);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Risk Matrix',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827)),
              ),
              const Spacer(),
              _LegendDot(color: _high, label: 'High Risk'),
              const SizedBox(width: 16),
              _LegendDot(color: _medium, label: 'Medium Risk'),
              const SizedBox(width: 16),
              _LegendDot(color: _low, label: 'Low Risk'),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final double cellHeight = constraints.maxWidth < 540 ? 64 : 80;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      SizedBox(width: 90),
                      Expanded(
                        child:
                            _MatrixHeaderRow(labels: ['Low', 'Medium', 'High']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Likelihood',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _MatrixRow(
                          label: 'Low',
                          height: cellHeight,
                          colors: const [_low, _low, _medium]),
                      _MatrixRow(
                          label: 'Medium',
                          height: cellHeight,
                          colors: const [_low, _medium, _high]),
                      _MatrixRow(
                          label: 'High',
                          height: cellHeight,
                          colors: const [_medium, _high, _high]),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _MatrixHeaderRow extends StatelessWidget {
  const _MatrixHeaderRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827)),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MatrixRow extends StatelessWidget {
  const _MatrixRow(
      {required this.label, required this.height, required this.colors});

  final String label;
  final double height;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827)),
            ),
          ),
          Expanded(
            child: Row(
              children: colors
                  .map(
                    (color) => Expanded(
                      child: Container(
                        height: height,
                        margin: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskRegister extends StatelessWidget {
  const _RiskRegister({
    required this.entries,
    required this.isMobile,
    required this.loading,
    required this.searchController,
    required this.onAdd,
    required this.onFilter,
    required this.onView,
    required this.onEdit,
  });

  final List<_RiskEntry> entries;
  final bool isMobile;
  final bool loading;
  final TextEditingController searchController;
  final VoidCallback onAdd;
  final VoidCallback onFilter;
  final ValueChanged<_RiskEntry> onView;
  final ValueChanged<_RiskEntry> onEdit;

  static const List<int> _columnFlex = [2, 3, 2, 2, 3, 2, 2, 2];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Register',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Monitor risk exposure and mitigation status across the project portfolio.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 280,
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OutlinedButton(label: 'Filter', onPressed: onFilter),
                  const SizedBox(width: 10),
                  _YellowButton(label: 'Add Risk', onPressed: onAdd),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (loading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (entries.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: const [
                  Icon(Icons.inbox_outlined,
                      size: 28, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 10),
                  Text(
                    'No risks yet',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Add risks from Risk Identification or Preferred Solution Analysis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ] else ...[
            _RegisterHeader(columnFlex: _columnFlex),
            const SizedBox(height: 12),
            ...List.generate(entries.length, (index) {
              final entry = entries[index];
              final bool isLast = index == entries.length - 1;
              return Column(
                children: [
                  _RegisterRow(
                    entry: entry,
                    columnFlex: _columnFlex,
                    onView: () => onView(entry),
                    onEdit: () => onEdit(entry),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 26, thickness: 1, color: Color(0xFFF3F4F6)),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({required this.columnFlex});

  final List<int> columnFlex;

  static const List<String> _labels = [
    'Risk ID',
    'Description',
    'Category',
    'Probability',
    'Impact',
    'Risk Score',
    'Owner',
    'Status',
    'Actions',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(_labels.length, (index) {
          if (index == _labels.length - 1) {
            return const SizedBox(width: 60); // reserve space for icons
          }
          final flex = columnFlex[index];
          return Expanded(
            flex: flex,
            child: Text(
              _labels[index],
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280)),
            ),
          );
        }),
      ],
    );
  }
}

class _RegisterRow extends StatelessWidget {
  const _RegisterRow({
    required this.entry,
    required this.columnFlex,
    required this.onView,
    required this.onEdit,
  });

  final _RiskEntry entry;
  final List<int> columnFlex;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    Color pillColor;
    Color pillText;
    switch (entry.status) {
      case 'In Progress':
        pillColor = const Color(0xFFFFF7E6);
        pillText = const Color(0xFF92400E);
        break;
      case 'Monitoring':
        pillColor = const Color(0xFFE0F2F1);
        pillText = const Color(0xFF065F46);
        break;
      default:
        pillColor = const Color(0xFFE5E7EB);
        pillText = const Color(0xFF374151);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: columnFlex[0],
          child: Text(
            entry.id,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          ),
        ),
        Expanded(
          flex: columnFlex[1],
          child: Text(
            entry.description,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          ),
        ),
        Expanded(
          flex: columnFlex[2],
          child: Text(
            entry.category,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          flex: columnFlex[3],
          child: _RiskTag(label: entry.probability),
        ),
        Expanded(
          flex: columnFlex[4],
          child: _RiskTag(label: entry.impact),
        ),
        Expanded(
          flex: columnFlex[5],
          child: Text(
            entry.score,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          flex: columnFlex[6],
          child: Text(
            entry.owner,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          ),
        ),
        Expanded(
          flex: columnFlex[7],
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: pillColor, borderRadius: BorderRadius.circular(999)),
              child: Text(
                entry.status,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, color: pillText),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined,
                    size: 18, color: Color(0xFF6B7280)),
                onPressed: onView,
                tooltip: 'View',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: Color(0xFF6B7280)),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RiskTag extends StatelessWidget {
  const _RiskTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isHigh = label.toLowerCase() == 'high';
    final bool isMedium = label.toLowerCase() == 'medium';
    Color background;
    Color textColor;

    if (isHigh) {
      background = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFB91C1C);
    } else if (isMedium) {
      background = const Color(0xFFFEF3C7);
      textColor = const Color(0xFF92400E);
    } else {
      background = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }
}

class _RiskEntry {
  const _RiskEntry({
    required this.docId,
    required this.id,
    required this.description,
    required this.category,
    required this.probability,
    required this.impact,
    required this.score,
    required this.owner,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String docId;
  final String id;
  final String description;
  final String category;
  final String probability;
  final String impact;
  final String score;
  final String owner;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory _RiskEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return _RiskEntry(
      docId: doc.id,
      id: data['id']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      probability: data['probability']?.toString() ?? '',
      impact: data['impact']?.toString() ?? '',
      score: data['score']?.toString() ?? '',
      owner: data['owner']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      createdAt: _readTimestamp(data['createdAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({required bool isNew}) {
    return {
      'id': id,
      'description': description,
      'category': category,
      'probability': probability,
      'impact': impact,
      'score': score,
      'owner': owner,
      'status': status,
      if (isNew) 'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }
}

DateTime _readTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}

Widget _dialogField({
  required TextEditingController controller,
  required String label,
  bool readOnly = false,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    ),
  );
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

  void dispose() => _timer?.cancel();
}
