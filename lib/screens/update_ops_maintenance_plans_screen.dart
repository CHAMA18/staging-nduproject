import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndu_project/screens/launch_checklist_screen.dart';
import 'package:ndu_project/screens/stakeholder_alignment_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/project_insights_service.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/utils/execution_phase_ai_seed.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';

class UpdateOpsMaintenancePlansScreen extends StatefulWidget {
  const UpdateOpsMaintenancePlansScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const UpdateOpsMaintenancePlansScreen()),
    );
  }

  @override
  State<UpdateOpsMaintenancePlansScreen> createState() =>
      _UpdateOpsMaintenancePlansScreenState();
}

class _UpdateOpsMaintenancePlansScreenState
    extends State<UpdateOpsMaintenancePlansScreen> {
  final Set<String> _selectedFilters = {'All plans'};
  final List<String> _planStatuses = const [
    'Ready',
    'In review',
    'Pending',
    'Scheduled'
  ];

  final List<_CoverageItem> _coverage = [];
  final List<_SignalItem> _signals = [];
  final List<_MaintenanceWindowItem> _maintenanceWindows = [];
  final List<_StatCardData> _stats = [];

  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;
  bool _hasSavedData = false;
  bool _autoGenerationTriggered = false;
  bool _isAutoGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFromFirestore();
    });
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    if (_suspendSave) return;
    _saveDebouncer.run(_saveToFirestore);
  }

  Future<void> _loadFromFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_sections')
          .doc('update_ops_maintenance_plans')
          .get();
      final data = doc.data() ?? {};
      final stats = _StatCardData.fromList(data['stats']);
      final coverage = _CoverageItem.fromList(data['coverage']);
      final signals = _SignalItem.fromList(data['signals']);
      final windows =
          _MaintenanceWindowItem.fromList(data['maintenanceWindows']);

      _suspendSave = true;
      if (!mounted) return;
      setState(() {
        _stats
          ..clear()
          ..addAll(stats.isEmpty ? _defaultStats() : stats);
        _coverage
          ..clear()
          ..addAll(coverage.isEmpty ? _defaultCoverage() : coverage);
        _signals
          ..clear()
          ..addAll(signals);
        _maintenanceWindows
          ..clear()
          ..addAll(windows);
      });
      _hasSavedData = doc.exists &&
          (stats.isNotEmpty ||
              coverage.isNotEmpty ||
              signals.isNotEmpty ||
              windows.isNotEmpty);
      _suspendSave = false;
    } catch (error) {
      debugPrint('Update ops maintenance load error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    await _autoGenerateIfNeeded();
  }

  Future<void> _autoGenerateIfNeeded() async {
    if (!mounted || _autoGenerationTriggered || _isAutoGenerating) return;
    if (_hasSavedData) return;

    _autoGenerationTriggered = true;
    _isAutoGenerating = true;
    try {
      final generated = await ExecutionPhaseAiSeed.generateEntries(
        context: context,
        section: 'Update Ops and Maintenance Plans',
        sections: const {
          'stats': 'Operational readiness stats and progress snapshots',
          'coverage': 'Coverage areas for ops readiness',
          'signals': 'Operational signals and watch items',
          'maintenance': 'Upcoming maintenance windows',
        },
        itemsPerSection: 3,
      );

      final stats = generated['stats'] ?? const [];
      final coverage = generated['coverage'] ?? const [];
      final signals = generated['signals'] ?? const [];
      final maintenance = generated['maintenance'] ?? const [];

      if (stats.isNotEmpty) {
        _stats
          ..clear()
          ..addAll(_mapStats(stats));
      }
      if (coverage.isNotEmpty) {
        _coverage
          ..clear()
          ..addAll(_mapCoverage(coverage));
      }
      if (signals.isNotEmpty) {
        _signals
          ..clear()
          ..addAll(_mapSignals(signals));
      }
      if (maintenance.isNotEmpty) {
        _maintenanceWindows
          ..clear()
          ..addAll(_mapMaintenance(maintenance));
      }

      if (mounted) {
        setState(() {});
        await _saveToFirestore();
      }
    } catch (e) {
      debugPrint('Error auto-generating ops maintenance data: $e');
    } finally {
      _isAutoGenerating = false;
    }
  }

  List<_StatCardData> _mapStats(List<LaunchEntry> entries) {
    final colors = [
      const Color(0xFF0EA5E9),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];
    return [
      for (var i = 0; i < entries.length; i++)
        _StatCardData(
          id: _newId(),
          label: entries[i].title,
          value: entries[i].status?.isNotEmpty == true
              ? entries[i].status!
              : 'TBD',
          supporting: entries[i].details,
          color: colors[i % colors.length],
        )
    ];
  }

  List<_CoverageItem> _mapCoverage(List<LaunchEntry> entries) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];
    return [
      for (var i = 0; i < entries.length; i++)
        _CoverageItem(
          id: _newId(),
          label: entries[i].title,
          progress: 0.6,
          color: colors[i % colors.length],
        )
    ];
  }

  List<_SignalItem> _mapSignals(List<LaunchEntry> entries) {
    return [
      for (final entry in entries)
        _SignalItem(
          id: _newId(),
          title: entry.title,
          subtitle: entry.details,
        )
    ];
  }

  List<_MaintenanceWindowItem> _mapMaintenance(List<LaunchEntry> entries) {
    return [
      for (final entry in entries)
        _MaintenanceWindowItem(
          id: _newId(),
          title: entry.title,
          time: entry.details.isNotEmpty ? entry.details : 'TBD',
          status:
              entry.status?.isNotEmpty == true ? entry.status! : 'Scheduled',
        )
    ];
  }

  Future<void> _saveToFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_sections')
          .doc('update_ops_maintenance_plans')
          .set({
        'stats': _stats.map((e) => e.toMap()).toList(),
        'coverage': _coverage.map((e) => e.toMap()).toList(),
        'signals': _signals.map((e) => e.toMap()).toList(),
        'maintenanceWindows':
            _maintenanceWindows.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Update ops maintenance save error: $error');
    }
  }

  List<_StatCardData> _defaultStats() {
    return [
      _StatCardData(
          id: _newId(),
          label: 'Plans updated',
          value: '',
          supporting: '',
          color: const Color(0xFF0EA5E9)),
      _StatCardData(
          id: _newId(),
          label: 'Runbooks ready',
          value: '',
          supporting: '',
          color: const Color(0xFF10B981)),
      _StatCardData(
          id: _newId(),
          label: 'Training coverage',
          value: '',
          supporting: '',
          color: const Color(0xFFF59E0B)),
      _StatCardData(
          id: _newId(),
          label: 'Maintenance risk',
          value: '',
          supporting: '',
          color: const Color(0xFF6366F1)),
    ];
  }

  List<_CoverageItem> _defaultCoverage() {
    return [
      _CoverageItem(
          id: _newId(),
          label: 'Runbooks updated',
          progress: 0.0,
          color: const Color(0xFF10B981)),
      _CoverageItem(
          id: _newId(),
          label: 'Maintenance tasks',
          progress: 0.0,
          color: const Color(0xFF6366F1)),
      _CoverageItem(
          id: _newId(),
          label: 'Training readiness',
          progress: 0.0,
          color: const Color(0xFFF59E0B)),
      _CoverageItem(
          id: _newId(),
          label: 'Ops handoff',
          progress: 0.0,
          color: const Color(0xFF0EA5E9)),
    ];
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final double hPad = isMobile ? 20 : 40;
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            if (isMobile)
              _buildMobileLayout(hPad, projectId)
            else
              _buildDesktopLayout(hPad, projectId),
            const KazAiChatBubble(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(double hPad, String? projectId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DraggableSidebar(
          openWidth: AppBreakpoints.sidebarWidth(context),
          child: const InitiationLikeSidebar(
              activeItemLabel: 'Update Ops and Maintenance Plans'),
        ),
        Expanded(child: _buildScrollContent(hPad, projectId)),
      ],
    );
  }

  Widget _buildMobileLayout(double hPad, String? projectId) {
    return _buildScrollContent(hPad, projectId);
  }

  Widget _buildScrollContent(double hPad, String? projectId) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumHeader(context, projectId),
          const SizedBox(height: 32),
          _buildSectionIntro(),
          const SizedBox(height: 28),
          if (_isLoading) ...[
            const Center(
                child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
          ] else ...[
            _buildStatsRow(isNarrow),
            const SizedBox(height: 28),
            _buildPlanRegister(projectId),
            const SizedBox(height: 20),
            _buildCoveragePanel(),
            const SizedBox(height: 20),
            _buildSignalsPanel(),
            const SizedBox(height: 20),
            _buildMaintenancePanel(),
          ],
          const SizedBox(height: 36),
          _buildBottomActionBar(),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, String? projectId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => StakeholderAlignmentScreen.open(context)),
              const SizedBox(width: 12),
              _CircleIconButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  onTap: () => LaunchChecklistScreen.open(context)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Update Ops & Maintenance Plans',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const _CurrentUserProfileChip(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.rocket_launch_outlined,
                      size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  _isLoading
                      ? 'Execution Phase · Loading...'
                      : 'Execution Phase',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionIntro() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.build_circle_outlined,
              size: 22, color: Color(0xFF4338CA)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ops & Maintenance Plans',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Finalize operational playbooks, maintenance cadence, and training updates before launch.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: LaunchPhaseNavigation(
        backLabel: 'Back: Stakeholder Alignment',
        nextLabel: 'Next: Start-up / Launch Checklist',
        onBack: () => StakeholderAlignmentScreen.open(context),
        onNext: () => LaunchChecklistScreen.open(context),
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow(bool isNarrow) {
    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _stats.map((stat) => _buildStatCard(stat)).toList(),
      );
    }

    return Row(
      children: _stats
          .map((stat) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildStatCard(stat),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.analytics_outlined, size: 22, color: data.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value.isEmpty ? 'TBD' : data.value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: data.color),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ops Plan Register ────────────────────────────────────────────────────

  Widget _buildPlanRegister(String? projectId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.playlist_add_check_rounded,
                      size: 20, color: Color(0xFF059669)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ops Plan Register',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Maintenance and runbook updates',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterChips(),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: projectId == null
                          ? null
                          : () => _openAddPlanDialog(projectId),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Plan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          _buildPlanRegisterBody(projectId),
        ],
      ),
    );
  }

  Widget _buildPlanRegisterBody(String? projectId) {
    if (projectId == null) {
      return _premiumEmptyState(
        icon: Icons.folder_open_outlined,
        message: 'Select a project to manage ops plans.',
      );
    }
    return StreamBuilder<List<OpsPlanItem>>(
      stream: ProjectInsightsService.streamOpsPlans(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _premiumEmptyState(
            icon: Icons.error_outline_rounded,
            message: 'Unable to load ops plans. ${snapshot.error}',
          );
        }
        final plans = snapshot.data ?? [];
        final filtered = plans.where((plan) {
          if (_selectedFilters.contains('All plans')) return true;
          return _selectedFilters.contains(plan.status);
        }).toList();
        if (filtered.isEmpty) {
          return _premiumEmptyState(
            icon: Icons.inbox_outlined,
            message: 'No ops plans recorded yet.',
            actionLabel: 'Add first plan',
            onAction: () => _openAddPlanDialog(projectId),
          );
        }
        return Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              child: const Row(
                children: [
                  Expanded(flex: 1, child: _HeaderCell('ID')),
                  Expanded(flex: 3, child: _HeaderCell('Plan Item')),
                  Expanded(flex: 2, child: _HeaderCell('Team')),
                  Expanded(flex: 2, child: _HeaderCell('Status')),
                  Expanded(flex: 2, child: _HeaderCell('Due')),
                  Expanded(flex: 2, child: _HeaderCell('Owner')),
                ],
              ),
            ),
            ...List.generate(filtered.length, (i) {
              final plan = filtered[i];
              final isLast = i == filtered.length - 1;
              return _PlanRow(plan: plan, isLast: isLast);
            }),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} plan${filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Filtered view',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All plans', 'Ready', 'In review', 'Pending', 'Scheduled'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: filters.map((filter) {
        final selected = _selectedFilters.contains(filter);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedFilters.remove(filter);
              } else {
                _selectedFilters.add(filter);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE5E7EB)),
            ),
            child: Text(
              filter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Coverage Panel ──────────────────────────────────────────────────────

  Widget _buildCoveragePanel() {
    return _PremiumPanel(
      icon: Icons.track_changes_outlined,
      iconColor: const Color(0xFF6366F1),
      iconBg: const Color(0xFFEEF2FF),
      title: 'Readiness Coverage',
      subtitle: 'Operational readiness by capability',
      child: Column(
        children: [
          if (_coverage.isEmpty)
            _premiumEmptyState(
                icon: Icons.track_changes_outlined,
                message: 'No coverage items yet.')
          else
            ..._coverage.map((item) => _buildCoverageRow(item)),
          const SizedBox(height: 12),
          _addEntryButton('Add coverage line', _addCoverageItem),
        ],
      ),
    );
  }

  Widget _buildCoverageRow(_CoverageItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label.isEmpty ? 'Coverage label' : item.label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: item.color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '${(item.progress * 100).round()}%',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: item.color,
                      letterSpacing: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              _buildEditButton(() => _editCoverageItem(item)),
              const SizedBox(width: 8),
              _buildDeleteButton(() => _deleteCoverage(item.id)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Signals Panel ───────────────────────────────────────────────────────

  Widget _buildSignalsPanel() {
    return _PremiumPanel(
      icon: Icons.notifications_active_outlined,
      iconColor: const Color(0xFFD97706),
      iconBg: const Color(0xFFFEF3C7),
      title: 'Ops Signals',
      subtitle: 'Items that need immediate attention',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_signals.isEmpty)
            _premiumEmptyState(
                icon: Icons.notifications_active_outlined,
                message: 'No ops signals yet.')
          else
            ..._signals.map((signal) => _buildSignalRow(signal)),
          const SizedBox(height: 12),
          _addEntryButton('Add ops signal', _addSignal),
        ],
      ),
    );
  }

  Widget _buildSignalRow(_SignalItem signal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                size: 18, color: Color(0xFFD97706)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.title.isEmpty ? 'Signal title' : signal.title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827)),
                ),
                const SizedBox(height: 6),
                Text(
                  signal.subtitle.isEmpty ? 'Signal detail' : signal.subtitle,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildEditButton(() => _editSignalItem(signal)),
          const SizedBox(width: 8),
          _buildDeleteButton(() => _deleteSignal(signal.id)),
        ],
      ),
    );
  }

  // ─── Maintenance Panel ───────────────────────────────────────────────────

  Widget _buildMaintenancePanel() {
    return _PremiumPanel(
      icon: Icons.calendar_month_outlined,
      iconColor: const Color(0xFF0EA5E9),
      iconBg: const Color(0xFFE0F2FE),
      title: 'Maintenance Windows',
      subtitle: 'Upcoming maintenance schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_maintenanceWindows.isEmpty)
            _premiumEmptyState(
                icon: Icons.calendar_month_outlined,
                message: 'No maintenance windows yet.')
          else
            ..._maintenanceWindows.map(_buildMaintenanceRow),
        ],
      ),
    );
  }

  Widget _buildMaintenanceRow(_MaintenanceWindowItem item) {
    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'scheduled':
          return const Color(0xFF6366F1);
        case 'completed':
          return const Color(0xFF10B981);
        case 'in progress':
          return const Color(0xFF0EA5E9);
        case 'pending':
          return const Color(0xFFF59E0B);
        default:
          return const Color(0xFF6B7280);
      }
    }

    final statusColor = getStatusColor(item.status.isEmpty ? 'Scheduled' : item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.schedule_outlined,
                size: 16, color: Color(0xFF0EA5E9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isEmpty ? 'Window' : item.title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  item.time.isEmpty ? 'Time window' : item.time,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              item.status.isEmpty ? 'Scheduled' : item.status,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Helpers ──────────────────────────────────────────────────────

  Widget _premiumEmptyState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF9CA3AF), size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 16),
                label: Text(actionLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _addEntryButton(String label, VoidCallback onPressed) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  Widget _buildEditButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6366F1)),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
        ),
      ),
    );
  }

  Future<void> _editCoverageItem(_CoverageItem item) async {
    final labelController = TextEditingController(text: item.label);
    final progressController = TextEditingController(
      text: (item.progress * 100).round().toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.track_changes_outlined,
                            color: Color(0xFF6366F1), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit coverage item',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Update readiness coverage details.',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: labelController,
                    decoration: _dialogDecoration('Coverage label'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: progressController,
                    decoration: _dialogDecoration('Progress (%)',
                        hint: '0-100'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          final parsed = double.tryParse(progressController.text) ?? 0;
                          _updateCoverage(item.copyWith(
                            label: labelController.text.trim(),
                            progress: (parsed / 100).clamp(0.0, 1.0),
                          ));
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Save changes'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editSignalItem(_SignalItem signal) async {
    final titleController = TextEditingController(text: signal.title);
    final subtitleController = TextEditingController(text: signal.subtitle);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.notifications_active_outlined,
                            color: Color(0xFFD97706), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit ops signal',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Update signal details for attention tracking.',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: _dialogDecoration('Signal title',
                        hint: 'e.g. Database latency spike'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subtitleController,
                    decoration: _dialogDecoration('Signal detail',
                        hint: 'Additional context or notes'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          _updateSignal(signal.copyWith(
                            title: titleController.text.trim(),
                            subtitle: subtitleController.text.trim(),
                          ));
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Save changes'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inlineFieldDecoration(String hint) {
    return const InputDecoration(
      isDense: true,
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
    ).copyWith(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
    );
  }

  // ─── Dialog ──────────────────────────────────────────────────────────────

  Future<void> _openAddPlanDialog(String projectId) async {
    final idController = TextEditingController();
    final titleController = TextEditingController();
    final teamController = TextEditingController();
    final ownerController = TextEditingController();
    final dueController = TextEditingController();
    String status = _planStatuses.first;
    DateTime? dueDate;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                                Icons.playlist_add_check_rounded,
                                color: Color(0xFF059669),
                                size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add ops plan item',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700)),
                                SizedBox(height: 4),
                                Text(
                                    'Log a runbook or maintenance update for the ops register.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close,
                                color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _dialogField('Plan ID',
                          controller: idController, hint: 'e.g. OP-301'),
                      const SizedBox(height: 12),
                      _dialogField('Plan item',
                          controller: titleController,
                          hint: 'e.g. Runbook refresh'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _dialogField('Team',
                                  controller: teamController,
                                  hint: 'e.g. Operations')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _dialogField('Owner',
                                  controller: ownerController,
                                  hint: 'e.g. M. Thompson')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: status,
                              items: _planStatuses
                                  .map((option) => DropdownMenuItem(
                                      value: option, child: Text(option)))
                                  .toList(),
                              decoration: _dialogDecoration('Status'),
                              onChanged: (value) => setDialogState(
                                  () => status = value ?? _planStatuses.first),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: dueController,
                              readOnly: true,
                              decoration: _dialogDecoration('Due date',
                                      hint: 'Select date')
                                  .copyWith(
                                      suffixIcon: const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 18)),
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  firstDate:
                                      now.subtract(const Duration(days: 365)),
                                  lastDate:
                                      now.add(const Duration(days: 365 * 5)),
                                  initialDate: dueDate ?? now,
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    dueDate = picked;
                                    dueController.text =
                                        '${picked.month}/${picked.day}/${picked.year}';
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () async {
                              if (idController.text.trim().isEmpty ||
                                  titleController.text.trim().isEmpty ||
                                  teamController.text.trim().isEmpty ||
                                  ownerController.text.trim().isEmpty ||
                                  dueController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Please complete all fields.')),
                                );
                                return;
                              }
                              final navigator = Navigator.of(dialogContext);
                              await FirebaseFirestore.instance
                                  .collection('projects')
                                  .doc(projectId)
                                  .collection('opsMaintenance')
                                  .doc('overview')
                                  .collection('plans')
                                  .add({
                                'id': idController.text.trim(),
                                'title': titleController.text.trim(),
                                'team': teamController.text.trim(),
                                'status': status,
                                'due': dueController.text.trim(),
                                'owner': ownerController.text.trim(),
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                              if (!mounted) return;
                              navigator.pop();
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Add plan'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _dialogDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF0EA5E9), width: 1.5)),
    );
  }

  Widget _dialogField(String label,
      {required TextEditingController controller, String? hint}) {
    return TextFormField(
      controller: controller,
      decoration: _dialogDecoration(label, hint: hint),
    );
  }

  // ─── Data Mutations ──────────────────────────────────────────────────────

  void _updateStat(_StatCardData data) {
    final index = _stats.indexWhere((item) => item.id == data.id);
    if (index == -1) return;
    setState(() => _stats[index] = data);
    _scheduleSave();
  }

  void _addCoverageItem() {
    setState(() {
      _coverage.add(
        _CoverageItem(
            id: _newId(), label: '', progress: 0.0, color: const Color(0xFF0EA5E9)),
      );
    });
    _scheduleSave();
  }

  void _updateCoverage(_CoverageItem item) {
    final index = _coverage.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    setState(() => _coverage[index] = item);
    _scheduleSave();
  }

  void _deleteCoverage(String id) {
    setState(() => _coverage.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addSignal() {
    setState(() {
      _signals.add(_SignalItem(id: _newId(), title: '', subtitle: ''));
    });
    _scheduleSave();
  }

  void _updateSignal(_SignalItem signal) {
    final index = _signals.indexWhere((item) => item.id == signal.id);
    if (index == -1) return;
    setState(() => _signals[index] = signal);
    _scheduleSave();
  }

  void _deleteSignal(String id) {
    setState(() => _signals.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addMaintenanceWindow() {
    setState(() {
      _maintenanceWindows.add(
        _MaintenanceWindowItem(id: _newId(), title: '', time: '', status: ''),
      );
    });
    _scheduleSave();
  }

  void _updateMaintenance(_MaintenanceWindowItem item) {
    final index =
        _maintenanceWindows.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    setState(() => _maintenanceWindows[index] = item);
    _scheduleSave();
  }

  void _deleteMaintenance(String id) {
    setState(() => _maintenanceWindows.removeWhere((item) => item.id == id));
    _scheduleSave();
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
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

class _CurrentUserProfileChip extends StatelessWidget {
  const _CurrentUserProfileChip();

  String _initials(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r"\s+"));
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final photoUrl = user?.photoURL;
    final email = user?.email ?? '';

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final role = isAdmin ? 'Admin' : 'Member';

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                        _initials(displayName),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563)),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                  ),
                  Text(
                    role,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PremiumPanel extends StatelessWidget {
  const _PremiumPanel({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan, required this.isLast});

  final OpsPlanItem plan;
  final bool isLast;

  Color _statusColor(String status) {
    switch (status) {
      case 'Ready':
        return const Color(0xFF059669);
      case 'In review':
        return const Color(0xFF2563EB);
      case 'Pending':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Ready':
        return const Color(0xFFECFDF5);
      case 'In review':
        return const Color(0xFFEFF6FF);
      case 'Pending':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFEEF2FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(plan.status);
    final bg = _statusBg(plan.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(plan.id,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0EA5E9))),
          ),
          Expanded(
            flex: 3,
            child: Text(plan.title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827))),
          ),
          Expanded(
            flex: 2,
            child: Text(plan.team,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text(
                  plan.status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(plan.due,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569))),
          ),
          Expanded(
            flex: 2,
            child: Text(plan.owner,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class _CoverageItem {
  const _CoverageItem({
    required this.id,
    required this.label,
    required this.progress,
    required this.color,
  });

  final String id;
  final String label;
  final double progress;
  final Color color;

  _CoverageItem copyWith({String? label, double? progress, Color? color}) {
    return _CoverageItem(
      id: id,
      label: label ?? this.label,
      progress: progress ?? this.progress,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'progress': progress,
        'color': color.toARGB32(),
      };

  static List<_CoverageItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _CoverageItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        progress: (map['progress'] is num)
            ? (map['progress'] as num).toDouble()
            : double.tryParse(map['progress']?.toString() ?? '0') ?? 0,
        color: Color(map['color'] is int ? map['color'] as int : 0xFF0EA5E9),
      );
    }).toList();
  }
}

class _SignalItem {
  const _SignalItem({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;

  _SignalItem copyWith({String? title, String? subtitle}) {
    return _SignalItem(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
      };

  static List<_SignalItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _SignalItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
      );
    }).toList();
  }
}

class _StatCardData {
  const _StatCardData({
    required this.id,
    required this.label,
    required this.value,
    required this.supporting,
    required this.color,
  });

  final String id;
  final String label;
  final String value;
  final String supporting;
  final Color color;

  _StatCardData copyWith({
    String? label,
    String? value,
    String? supporting,
    Color? color,
  }) {
    return _StatCardData(
      id: id,
      label: label ?? this.label,
      value: value ?? this.value,
      supporting: supporting ?? this.supporting,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'value': value,
        'supporting': supporting,
        'color': color.toARGB32(),
      };

  static List<_StatCardData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _StatCardData(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        value: map['value']?.toString() ?? '',
        supporting: map['supporting']?.toString() ?? '',
        color: Color(map['color'] is int ? map['color'] as int : 0xFF0EA5E9),
      );
    }).toList();
  }
}

class _MaintenanceWindowItem {
  const _MaintenanceWindowItem({
    required this.id,
    required this.title,
    required this.time,
    required this.status,
  });

  final String id;
  final String title;
  final String time;
  final String status;

  _MaintenanceWindowItem copyWith(
      {String? title, String? time, String? status}) {
    return _MaintenanceWindowItem(
      id: id,
      title: title ?? this.title,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'time': time,
        'status': status,
      };

  static List<_MaintenanceWindowItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _MaintenanceWindowItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        time: map['time']?.toString() ?? '',
        status: map['status']?.toString() ?? '',
      );
    }).toList();
  }
}

class _Debouncer {
  _Debouncer({Duration? delay})
      : delay = delay ?? const Duration(milliseconds: 600);

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
