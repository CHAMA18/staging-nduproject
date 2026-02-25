import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'dart:math' as math;

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
  final OpenAiServiceSecure _openAi = OpenAiServiceSecure();
  final Map<String, TextEditingController> _mitigationControllers = {};
  final Map<String, String> _mitigationPlans = {};
  final _Debouncer _mitigationDebounce = _Debouncer();
  bool _notesSaving = false;
  DateTime? _notesSavedAt;
  bool _mitigationSaving = false;
  DateTime? _mitigationSavedAt;
  bool _didInitNotes = false;
  bool _loadingMitigationSuggestions = false;
  String? _mitigationSuggestionError;
  final Set<String> _seededRiskDescriptions = {};
  final Set<String> _regeneratingMitigationIds = {};

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
    _mitigationDebounce.dispose();
    for (final controller in _mitigationControllers.values) {
      controller.dispose();
    }
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
      final firestoreEntries =
          snapshot.docs.map((doc) => _RiskEntry.fromFirestore(doc)).toList();
      final provider = ProjectDataHelper.getProvider(context);
      final projectData = provider.projectData;
      final mergedEntries = await _mergeEntriesWithSolutionRisks(
          firestoreEntries, projectData.solutionRisks);
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(mergedEntries);
        _mitigationPlans
          ..clear()
          ..addAll(projectData.riskMitigationPlans);
        _mitigationSuggestionError = null;
      });
      _ensureMitigationControllers(mergedEntries);
      await _maybeSeedMitigationPlans(mergedEntries, projectData);
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
      discipline: '',
      role: '',
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
                  // TODO: Migrate to RadioGroup when this screen is revisited.
                  // ignore: deprecated_member_use
                  groupValue: current,
                  // ignore: deprecated_member_use
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
    final stats = _RiskStats.fromEntries(entries);

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
                        _MetricsWrap(isMobile: isMobile, stats: stats),
                        const SizedBox(height: 28),
                        _RiskMatrixCard(stats: stats),
                        const SizedBox(height: 28),
                        _MitigationPlanCard(
                          entries: entries,
                          controllers: _mitigationControllers,
                          onChanged: _handleMitigationChanged,
                          onRegenerate: _regenerateMitigationForEntry,
                          loadingSuggestions: _loadingMitigationSuggestions,
                          suggestionError: _mitigationSuggestionError,
                          saving: _mitigationSaving,
                          savedAt: _mitigationSavedAt,
                          regeneratingIds: _regeneratingMitigationIds,
                        ),
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

  String _normalizeRiskDescription(String value) => value.trim().toLowerCase();

  Future<List<_RiskEntry>> _mergeEntriesWithSolutionRisks(
    List<_RiskEntry> baseEntries,
    List<SolutionRisk> solutionRisks,
  ) async {
    final normalizedExisting = <String>{};
    for (final entry in baseEntries) {
      final normalized = _normalizeRiskDescription(entry.description);
      if (normalized.isNotEmpty) {
        normalizedExisting.add(normalized);
      }
    }
    _seededRiskDescriptions
        .removeWhere((description) => normalizedExisting.contains(description));

    final merged = List<_RiskEntry>.from(baseEntries);
    for (final solutionRisk in solutionRisks) {
      final solutionTitle = solutionRisk.solutionTitle.trim();
      for (final riskTextRaw in solutionRisk.risks) {
        final riskText = riskTextRaw.trim();
        if (riskText.isEmpty) continue;
        final normalized = _normalizeRiskDescription(riskText);
        if (normalizedExisting.contains(normalized) ||
            _seededRiskDescriptions.contains(normalized)) continue;

        final newEntry = _RiskEntry(
          docId: _newEntryId(),
          id: 'R-${DateTime.now().millisecondsSinceEpoch}',
          description: riskText,
          category:
              solutionTitle.isNotEmpty ? solutionTitle : 'Initiation risk',
          probability: 'Medium',
          impact: 'Medium',
          score: '0',
          discipline: '',
          role: '',
          owner: '',
          status: 'Open',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        merged.insert(0, newEntry);
        normalizedExisting.add(normalized);
        _seededRiskDescriptions.add(normalized);
        try {
          await _persistEntry(newEntry, isNew: true);
        } catch (e) {
          debugPrint('Could not persist seeded risk: $e');
        }
      }
    }
    return merged;
  }

  void _ensureMitigationControllers(List<_RiskEntry> entries) {
    final desired = entries.map((e) => e.docId).toSet();
    for (final entry in entries) {
      final controller = _mitigationControllers[entry.docId];
      final stored = _mitigationPlans[entry.docId] ?? '';
      if (controller == null) {
        _mitigationControllers[entry.docId] =
            TextEditingController(text: stored);
      } else if (controller.text != stored) {
        controller.text = stored;
      }
    }
    final toRemove = _mitigationControllers.keys
        .where((id) => !desired.contains(id))
        .toList();
    for (final id in toRemove) {
      _mitigationControllers[id]?.dispose();
      _mitigationControllers.remove(id);
    }
  }

  Future<void> _maybeSeedMitigationPlans(
    List<_RiskEntry> entries,
    ProjectDataModel projectData,
  ) async {
    if (_loadingMitigationSuggestions) return;
    final missing = entries.where((entry) {
      final stored = _mitigationPlans[entry.docId]?.trim() ?? '';
      return stored.isEmpty;
    }).toList();
    if (missing.isEmpty) return;

    setState(() => _loadingMitigationSuggestions = true);
    final mitigationContext = ProjectDataHelper.buildProjectContextScan(
        projectData,
        sectionLabel: 'Risk Mitigation Plan');
    try {
      final requests = missing
          .map((entry) => RiskMitigationRequest(
              id: entry.docId,
              risk: entry.description,
              solutionTitle: entry.category))
          .toList();
      final suggestions = await _openAi.generateRiskMitigationPlans(
        risks: requests,
        context: mitigationContext,
      );
      if (suggestions.isNotEmpty) {
        var updated = false;
        for (final entry in missing) {
          final plan = suggestions[entry.docId];
          if (plan == null || plan.trim().isEmpty) continue;
          final trimmed = plan.trim();
          final existing = _mitigationPlans[entry.docId]?.trim() ?? '';
          if (existing == trimmed) continue;
          _mitigationPlans[entry.docId] = trimmed;
          final controller = _mitigationControllers[entry.docId];
          if (controller != null) {
            controller.text = trimmed;
          }
          updated = true;
        }
        if (updated) {
          await _persistMitigationPlans();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _mitigationSuggestionError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loadingMitigationSuggestions = false);
      }
    }
  }

  void _handleMitigationChanged(String docId, String value) {
    _mitigationPlans[docId] = value;
    _scheduleMitigationSave();
  }

  void _scheduleMitigationSave() {
    _mitigationDebounce.run(() {
      _persistMitigationPlans();
    });
  }

  Future<void> _persistMitigationPlans({bool showSnackbar = false}) async {
    if (!mounted) return;
    final trimmed = <String, String>{};
    for (final entry in _mitigationPlans.entries) {
      trimmed[entry.key] = entry.value.trim();
    }
    setState(() => _mitigationSaving = true);
    final success = await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'risk_assessment',
      dataUpdater: (data) => data.copyWith(riskMitigationPlans: trimmed),
      showSnackbar: showSnackbar,
    );
    if (!mounted) return;
    setState(() {
      _mitigationSaving = false;
      if (success) _mitigationSavedAt = DateTime.now();
    });
  }

  Future<void> _regenerateMitigationForEntry(_RiskEntry entry) async {
    if (_regeneratingMitigationIds.contains(entry.docId)) return;
    setState(() => _regeneratingMitigationIds.add(entry.docId));
    final provider = ProjectDataHelper.getProvider(context);
    final mitigationContext = ProjectDataHelper.buildProjectContextScan(
        provider.projectData,
        sectionLabel: 'Risk Mitigation Plan');
    try {
      final suggestions = await _openAi.generateRiskMitigationPlans(
        risks: [
          RiskMitigationRequest(
            id: entry.docId,
            risk: entry.description,
            solutionTitle: entry.category,
          )
        ],
        context: mitigationContext,
      );
      final plan = suggestions[entry.docId];
      if (plan != null && plan.trim().isNotEmpty) {
        final trimmed = plan.trim();
        _mitigationPlans[entry.docId] = trimmed;
        final controller = _mitigationControllers[entry.docId];
        if (controller != null) {
          controller.text = trimmed;
        }
        await _persistMitigationPlans();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI did not return a mitigation plan.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate mitigation plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _regeneratingMitigationIds.remove(entry.docId));
      }
    }
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
          'Risk Planning',
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

class _RiskStats {
  _RiskStats({
    required this.total,
    required this.statusCounts,
    required this.statusSubtitle,
    required this.progress,
    required this.topRiskArea,
    required this.openCount,
    required this.matrixCounts,
  });

  factory _RiskStats.fromEntries(List<_RiskEntry> entries) {
    final total = entries.length;
    final statusCounts = <String, int>{};
    int closedCount = 0;
    final areaCounts = <String, int>{};
    final matrixCounts = {
      for (final level in _levels)
        level: {for (final inner in _levels) inner: 0}
    };

    for (final entry in entries) {
      final status = entry.status.trim();
      if (status.isNotEmpty) {
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        if (status.toLowerCase() == 'closed') {
          closedCount += 1;
        }
      }
      final category = entry.category.trim();
      if (category.isNotEmpty) {
        areaCounts[category] = (areaCounts[category] ?? 0) + 1;
      }
      final probability = _normalizeLevel(entry.probability);
      final impact = _normalizeLevel(entry.impact);
      matrixCounts[probability]?[impact] =
          (matrixCounts[probability]?[impact] ?? 0) + 1;
    }

    final statusList = statusCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final statusSubtitle = statusList.isEmpty
        ? '—'
        : statusList
            .take(3)
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' · ');

    final topRiskArea = areaCounts.entries.isEmpty
        ? '—'
        : areaCounts.entries
            .reduce(
              (current, next) => next.value > current.value ? next : current,
            )
            .key;

    final openCount = total - closedCount;
    final progress =
        total > 0 ? (closedCount / total).clamp(0, 1).toDouble() : null;

    return _RiskStats(
      total: total,
      statusCounts: statusCounts,
      statusSubtitle: statusSubtitle,
      progress: progress,
      topRiskArea: topRiskArea,
      openCount: openCount,
      matrixCounts: matrixCounts,
    );
  }

  static const List<String> _levels = ['Low', 'Medium', 'High'];

  static String _normalizeLevel(String value) {
    final lower = value.trim().toLowerCase();
    if (lower.startsWith('h')) return 'High';
    if (lower.startsWith('m')) return 'Medium';
    return 'Low';
  }

  final int total;
  final Map<String, int> statusCounts;
  final String statusSubtitle;
  final double? progress;
  final String topRiskArea;
  final int openCount;
  final Map<String, Map<String, int>> matrixCounts;

  int countFor(String likelihood, String impact) =>
      matrixCounts[likelihood]?[impact] ?? 0;

  int get maxCellCount {
    var maxCount = 0;
    for (final row in matrixCounts.values) {
      for (final cell in row.values) {
        if (cell > maxCount) {
          maxCount = cell;
        }
      }
    }
    return maxCount;
  }
}

class _MetricsWrap extends StatelessWidget {
  const _MetricsWrap({required this.isMobile, required this.stats});

  final bool isMobile;
  final _RiskStats stats;

  @override
  Widget build(BuildContext context) {
    final totalRisks = stats.total;
    final String statusSubtitle = stats.statusSubtitle;
    final double? progress = stats.progress;
    final String topRiskArea = stats.topRiskArea;
    final String unaddressed = totalRisks == 0 ? '0' : '${stats.openCount}';

    const double cardHeight =
        148; // Uniform height to prevent visual jumps/overflow
    final cards = [
      _MetricCard(
        height: cardHeight,
        title: 'Total Risks',
        subtitle: '$totalRisks',
      ),
      _MetricCard(
        height: cardHeight,
        width: 320,
        title: 'Risk Status',
        subtitle: statusSubtitle,
        progress: progress,
      ),
      _MetricCard(
        height: cardHeight,
        width: 320,
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
            (card) => SizedBox(width: card.width ?? 260, child: card),
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
    this.width,
    List<_Badge>? badges,
    this.progress,
    this.footer,
    this.footerIcon,
  }) : badges = badges ?? const [];

  final String title;
  final String subtitle;
  final double? height;
  final double? width;
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

    Widget sized = content;
    if (height != null || width != null) {
      sized = SizedBox(height: height, width: width, child: content);
    }
    return sized;
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
  const _RiskMatrixCard({required this.stats});

  final _RiskStats stats;

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
              final maxCount = stats.maxCellCount;
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
                    children: _RiskStats._levels
                        .map(
                          (likelihood) => _MatrixRow(
                            label: likelihood,
                            height: cellHeight,
                            cells: _RiskStats._levels
                                .map(
                                  (impact) => _MatrixCellData(
                                    color: _cellColor(likelihood, impact),
                                    count: stats.countFor(likelihood, impact),
                                    highlight: maxCount > 0 &&
                                        stats.countFor(likelihood, impact) ==
                                            maxCount,
                                  ),
                                )
                                .toList(),
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _cellColor(String likelihood, String impact) {
    if (likelihood == 'Low') {
      if (impact == 'High') return _medium;
      return _low;
    }
    if (likelihood == 'Medium') {
      if (impact == 'High') return _high;
      if (impact == 'Medium') return _medium;
      return _low;
    }
    // High likelihood
    if (impact == 'Low') return _medium;
    return _high;
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
      {required this.label, required this.height, required this.cells});

  final String label;
  final double height;
  final List<_MatrixCellData> cells;

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
              children: cells
                  .map(
                    (cell) => Expanded(
                      child: Container(
                        height: height,
                        margin: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          color: cell.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cell.highlight
                                ? const Color(0xFF111827)
                                : const Color(0xFFE5E7EB),
                            width: cell.highlight ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cell.count > 0 ? '${cell.count}' : '—',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'risks',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
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

class _MatrixCellData {
  const _MatrixCellData({
    required this.color,
    required this.count,
    required this.highlight,
  });

  final Color color;
  final int count;
  final bool highlight;
}

class _MitigationPlanCard extends StatelessWidget {
  const _MitigationPlanCard({
    required this.entries,
    required this.controllers,
    required this.onChanged,
    required this.onRegenerate,
    required this.loadingSuggestions,
    required this.suggestionError,
    required this.saving,
    required this.savedAt,
    required this.regeneratingIds,
  });

  final List<_RiskEntry> entries;
  final Map<String, TextEditingController> controllers;
  final void Function(String docId, String value) onChanged;
  final Future<void> Function(_RiskEntry entry) onRegenerate;
  final bool loadingSuggestions;
  final String? suggestionError;
  final bool saving;
  final DateTime? savedAt;
  final Set<String> regeneratingIds;

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
              const Icon(Icons.shield_rounded, color: Color(0xFF111827)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mitigation plan',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
          const SizedBox(height: 6),
          const Text(
            'Auto-filled with AI suggestions from initiation-phase risks. Update owners, steps, and cadence below.',
            style:
                TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
          ),
          if (loadingSuggestions) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 4),
          ],
          if (suggestionError != null) ...[
            const SizedBox(height: 8),
            Text(
              suggestionError!,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Center(
                child: Text(
                  'Risk register is empty. Add risks to capture mitigation plans.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ),
            )
          else ...[
            for (int i = 0; i < entries.length; i++) ...[
              _buildMitigationRow(context, entries[i]),
              if (i < entries.length - 1)
                const Divider(
                    height: 28, thickness: 1, color: Color(0xFFF3F4F6)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMitigationRow(BuildContext context, _RiskEntry entry) {
    final controller = controllers[entry.docId];
    if (controller == null) return const SizedBox.shrink();
    final isRegenerating = regeneratingIds.contains(entry.docId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                entry.description,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827)),
              ),
            ),
            Text(
              entry.category.isNotEmpty ? entry.category : 'Uncategorized',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mitigation plan',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            IconButton(
              icon: isRegenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.autorenew, size: 18),
              onPressed: () => onRegenerate(entry),
              tooltip: 'Refresh AI suggestion',
            ),
          ],
        ),
        TextField(
          controller: controller,
          onChanged: (value) => onChanged(entry.docId, value),
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Capture mitigation steps, owner, and cadence...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 12),
      ],
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

  static const List<int> _columnFlex = [4, 3, 2, 2, 2, 1, 2, 2];

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
            'Monitor risk exposure and mitigation status across the project',
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
            LayoutBuilder(
              builder: (context, constraints) {
                final viewportWidth = MediaQuery.of(context).size.width -
                    72; // account for padding
                final tableWidth = math.max(1080.0, viewportWidth);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
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
                                    height: 26,
                                    thickness: 1,
                                    color: Color(0xFFF3F4F6)),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
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
    'Description',
    'Category',
    'Prob.',
    'Impact',
    'Value',
    'Discipline',
    'Role',
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
            entry.description,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          ),
        ),
        Expanded(
          flex: columnFlex[1],
          child: Text(
            entry.category,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          flex: columnFlex[2],
          child: _RiskTag(label: entry.probability),
        ),
        Expanded(
          flex: columnFlex[3],
          child: _RiskTag(label: entry.impact),
        ),
        Expanded(
          flex: columnFlex[4],
          child: Text(
            entry.score,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          flex: columnFlex[5],
          child: Text(
            entry.discipline,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          flex: columnFlex[6],
          child: Text(
            entry.role,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          flex: columnFlex[7],
          child: Text(
            entry.owner,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          ),
        ),
        Expanded(
          flex: columnFlex[8],
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
    required this.discipline,
    required this.role,
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
  final String discipline;
  final String role;
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
      discipline: data['discipline']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
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
      'discipline': discipline,
      'role': role,
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
