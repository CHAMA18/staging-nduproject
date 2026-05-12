import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ndu_project/screens/design_deliverables_screen.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/activity_log_service.dart';
import 'package:ndu_project/services/design_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/models/design_phase_models.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

const Color _kSpecSurface = Colors.white;
const Color _kSpecBorder = Color(0xFFDCE4F2);
const Color _kSpecPanel = Color(0xFFEAF1FF);
const Color _kSpecPanelSoft = Color(0xFFF8FAFF);
const Color _kSpecPrimary = Color(0xFF0B4DBB);
const Color _kSpecPrimaryDeep = Color(0xFF082A63);
const Color _kSpecTeal = Color(0xFF0B7D68);
const Color _kSpecText = Color(0xFF111827);
const Color _kSpecSubtext = Color(0xFF667085);
const Color _kSpecError = Color(0xFFB42318);

class SpecializedDesignScreen extends StatefulWidget {
  const SpecializedDesignScreen({super.key});

  @override
  State<SpecializedDesignScreen> createState() =>
      _SpecializedDesignScreenState();
}

class _SpecializedDesignScreenState extends State<SpecializedDesignScreen> {
  final TextEditingController _notesController = TextEditingController();
  Timer? _saveDebounce;
  bool _isLoading = false;
  String? _loadError;
  bool _didAttemptAutoGeneration = false;

  final List<SecurityPatternRow> _securityRows = [];

  final List<PerformancePatternRow> _performanceRows = [];

  final List<IntegrationFlowRow> _integrationRows = [];

  final List<String> _statusOptions = const [
    'Ready',
    'In review',
    'Draft',
    'Pending',
    'In progress'
  ];

  String _normalizeStatus(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return 'Draft';

    for (final option in _statusOptions) {
      if (_normalize(option) == normalized) return option;
    }

    const aliases = <String, String>{
      'recommended': 'In review',
      'recommend': 'In review',
      'under review': 'In review',
      'complete': 'Ready',
      'completed': 'Ready',
      'done': 'Ready',
      'todo': 'Draft',
      'to do': 'Draft',
      'not started': 'Draft',
      'inreview': 'In review',
      'in-review': 'In review',
      'inprogress': 'In progress',
      'in-progress': 'In progress',
    };

    return aliases[normalized] ?? 'Draft';
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<SecurityPatternRow> _dedupeSecurityRows(
      Iterable<SecurityPatternRow> rows) {
    final seen = <String>{};
    final deduped = <SecurityPatternRow>[];
    for (final row in rows) {
      final key =
          '${_normalize(row.pattern)}|${_normalize(row.decision)}|${_normalize(row.owner)}|${_normalize(row.status)}';
      if (key == '|||') continue;
      if (seen.add(key)) deduped.add(row);
    }
    return deduped;
  }

  List<PerformancePatternRow> _dedupePerformanceRows(
      Iterable<PerformancePatternRow> rows) {
    final seen = <String>{};
    final deduped = <PerformancePatternRow>[];
    for (final row in rows) {
      final key =
          '${_normalize(row.hotspot)}|${_normalize(row.focus)}|${_normalize(row.sla)}|${_normalize(row.status)}';
      if (key == '|||') continue;
      if (seen.add(key)) deduped.add(row);
    }
    return deduped;
  }

  List<IntegrationFlowRow> _dedupeIntegrationRows(
      Iterable<IntegrationFlowRow> rows) {
    final seen = <String>{};
    final deduped = <IntegrationFlowRow>[];
    for (final row in rows) {
      final key =
          '${_normalize(row.flow)}|${_normalize(row.owner)}|${_normalize(row.system)}|${_normalize(row.status)}';
      if (key == '|||') continue;
      if (seen.add(key)) deduped.add(row);
    }
    return deduped;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _notesController.dispose();
    _saveDebounce?.cancel();
    super.dispose();
  }

  String? _currentProjectId() {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return null;
    return projectId;
  }

  Future<void> _loadData() async {
    final projectId = _currentProjectId();
    if (projectId == null) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // 1. Try loading from new service
      var data =
          await DesignPhaseService.instance.loadSpecializedDesign(projectId);

      // 2. Fallback: If empty, check generic ProjectData from provider (legacy migration)
      final bool isEmpty = data.notes.isEmpty &&
          data.securityPatterns.isEmpty &&
          data.performancePatterns.isEmpty &&
          data.integrationFlows.isEmpty;

      if (isEmpty) {
        // No migration performed here: specialized design is stored under
        // `projects/{id}/design_phase_sections/specialized_design`.
        // Keeping this block makes the intent explicit without introducing extra reads.
      }

      setState(() {
        _notesController.text = data.notes;
        _securityRows
          ..clear()
          ..addAll(_dedupeSecurityRows(data.securityPatterns));
        for (final row in _securityRows) {
          row.status = _normalizeStatus(row.status);
        }
        _performanceRows
          ..clear()
          ..addAll(_dedupePerformanceRows(data.performancePatterns));
        for (final row in _performanceRows) {
          row.status = _normalizeStatus(row.status);
        }
        _integrationRows
          ..clear()
          ..addAll(_dedupeIntegrationRows(data.integrationFlows));
        for (final row in _integrationRows) {
          row.status = _normalizeStatus(row.status);
        }
        _isLoading = false;
      });

      final sectionIsEmpty = _notesController.text.trim().isEmpty &&
          _securityRows.isEmpty &&
          _performanceRows.isEmpty &&
          _integrationRows.isEmpty;
      if (sectionIsEmpty && !_didAttemptAutoGeneration) {
        _didAttemptAutoGeneration = true;
        await _generateAllSpecializedDesign(showSnackbar: false);
      }
    } catch (e) {
      debugPrint('Error loading specialized design: $e');
      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load specialized design data.';
      });
    }
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), _saveToService);
  }

  Future<void> _saveToService() async {
    final projectId = _currentProjectId();
    if (projectId == null) return;

    final data = SpecializedDesignData(
      notes: _notesController.text.trim(),
      securityPatterns: _dedupeSecurityRows(_securityRows),
      performancePatterns: _dedupePerformanceRows(_performanceRows),
      integrationFlows: _dedupeIntegrationRows(_integrationRows),
    );

    await DesignPhaseService.instance.saveSpecializedDesign(projectId, data);
    _logActivity('Updated Specialized Design data');
  }

  bool _isGenerating = false;
  final OpenAiServiceSecure _openAi = OpenAiServiceSecure();

  Future<void> _generateAllSpecializedDesign({bool showSnackbar = true}) async {
    final projectId = _currentProjectId();
    if (projectId == null) {
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No active project found.')),
        );
      }
      return;
    }

    setState(() {
      _isGenerating = true;
      _loadError = null;
    });

    try {
      // Build context
      final provider = ProjectDataInherited.maybeOf(context);
      final data = provider!.projectData;
      final contextBuffer = StringBuffer();
      contextBuffer.writeln('Project: ${data.projectName}');
      contextBuffer.writeln('Description: ${data.projectDescription}');
      contextBuffer.writeln('Goals: ${data.projectGoals.join(", ")}');
      contextBuffer.writeln('Tech Stack: ${data.technology}');
      contextBuffer
          .writeln('Requirements: ${data.frontEndPlanningData.requirements}');

      final result = await _openAi.generateSpecializedDesign(
        context: contextBuffer.toString(),
      );

      if (!mounted) return;

      setState(() {
        if (result.notes.isNotEmpty && _notesController.text.isEmpty) {
          _notesController.text = result.notes;
        }

        if (result.securityPatterns.isNotEmpty) {
          _securityRows
            ..clear()
            ..addAll(_dedupeSecurityRows(result.securityPatterns));
          for (final row in _securityRows) {
            row.status = _normalizeStatus(row.status);
          }
        }

        if (result.performancePatterns.isNotEmpty) {
          _performanceRows
            ..clear()
            ..addAll(_dedupePerformanceRows(result.performancePatterns));
          for (final row in _performanceRows) {
            row.status = _normalizeStatus(row.status);
          }
        }

        if (result.integrationFlows.isNotEmpty) {
          _integrationRows
            ..clear()
            ..addAll(_dedupeIntegrationRows(result.integrationFlows));
          for (final row in _integrationRows) {
            row.status = _normalizeStatus(row.status);
          }
        }
      });

      _scheduleSave();

      _logActivity('Generated Specialized Design with AI');

      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Specialized Design generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generating specialized design: $e');
      if (mounted) {
        setState(() {
          _loadError =
              'Unable to generate specialized design with AI right now.';
        });
        if (showSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI Generation failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  bool get _isSpecializedDesignEmpty =>
      _notesController.text.trim().isEmpty &&
      _securityRows.isEmpty &&
      _performanceRows.isEmpty &&
      _integrationRows.isEmpty;

  void _logActivity(String action, {Map<String, dynamic>? details}) {
    final projectId = _currentProjectId();
    if (projectId == null) return;
    unawaited(
      ActivityLogService.instance.logActivity(
        projectId: projectId,
        phase: 'Design Phase',
        page: 'Specialized Design',
        action: action,
        details: details,
      ),
    );
  }

  // Helper to build list of context-aware options (Project members)
  List<String> _ownerOptions() {
    final data = ProjectDataHelper.getData(context);
    final members = data.teamMembers
        .map((m) {
          final name = m.name.trim();
          final role = m.role.trim();
          if (name.isEmpty) return '';
          return role.isEmpty ? name : '$name ($role)';
        })
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (members.isEmpty) {
      return ['Unassigned', 'External Vendor', 'Client Team'];
    }
    return ['Unassigned', ...members];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final double padding = isMobile ? 16 : 24;
    final ownerOptions = _ownerOptions();

    return ResponsiveScaffold(
      activeItemLabel: 'Specialized Design',
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Specialized Design',
            showImportButton: false,
            showContentButton: false,
            showNavigationButtons: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(isMobile),
                  const SizedBox(height: 24),
                  _buildStatusStrip(),
                  const SizedBox(height: 24),
                  _buildUpperInsightGrid(),
                  const SizedBox(height: 24),
                  _buildMiddleInsightGrid(),
                  const SizedBox(height: 24),
                  _buildLowerInsightGrid(),
                  const SizedBox(height: 24),
                  _buildWorkingNotesCard(),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _kSpecSurface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: _kSpecBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Working Track Registers',
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 28,
                            fontWeight: FontWeight.w900,
                            color: _kSpecPrimaryDeep,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This is the editable execution layer. Use it to lock down the exact specialized controls, performance hotspots, and integration contracts that engineering and reviewers will follow.',
                          style: TextStyle(
                            fontSize: 14,
                            color: _kSpecSubtext,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text('Loading specialized design data...',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  if (_loadError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _loadError!,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFFB91C1C)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => _generateAllSpecializedDesign(
                                showSnackbar: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  if (_isGenerating && _isSpecializedDesignEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _kSpecBorder),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Generating Specialized Design with AI...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildSecurityPatternsCard(ownerOptions),
                  const SizedBox(height: 20),
                  _buildPerformancePatternsCard(),
                  const SizedBox(height: 20),
                  _buildIntegrationFlowsCard(ownerOptions),
                  const SizedBox(height: 32),
                  _buildBottomNavigation(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF9FBFF), Color(0xFFEAF1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _kSpecBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HeroChip(
                label: 'Security Track',
                icon: Icons.shield_outlined,
                selected: true,
              ),
              _HeroChip(
                label: 'Accessibility',
                icon: Icons.visibility_outlined,
              ),
              _HeroChip(
                label: 'Structural',
                icon: Icons.architecture_outlined,
              ),
              _HeroChip(
                label: 'SME Validation',
                icon: Icons.verified_user_outlined,
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 860;
              final headline = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DESIGN PHASE: SPECIALIZED TRACKS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: LightModeColors.accent,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'High-fidelity validation and sign-off architecture for critical design paths',
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 38,
                      fontWeight: FontWeight.w900,
                      color: _kSpecPrimaryDeep,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This workspace captures the non-generic design logic that determines whether the project is secure, compliant, resilient, and implementation-ready.',
                    style: TextStyle(
                      fontSize: 15,
                      color: _kSpecSubtext,
                      height: 1.6,
                    ),
                  ),
                ],
              );

              final actionButton = _isGenerating
                  ? const SizedBox(
                      height: 56,
                      width: 56,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : ElevatedButton.icon(
                      onPressed: _generateAllSpecializedDesign,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Generate Audit Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kSpecPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headline,
                    const SizedBox(height: 18),
                    actionButton,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: headline),
                  const SizedBox(width: 20),
                  actionButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStrip() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        const _InfoPill(
          label: 'Track: Security-first review',
          color: _kSpecPrimary,
          background: Color(0xFFE6EEFF),
          icon: Icons.shield_rounded,
        ),
        _InfoPill(
          label: _isLoading ? 'Loading data' : 'Data connected',
          color: _isLoading ? _kSpecPrimary : _kSpecTeal,
          background:
              _isLoading ? const Color(0xFFE6EEFF) : const Color(0xFFEAF8F3),
          icon: _isLoading ? Icons.sync : Icons.cloud_done_outlined,
        ),
        _InfoPill(
          label: _loadError == null ? 'Review flow healthy' : _loadError!,
          color: _loadError == null ? _kSpecTeal : _kSpecError,
          background: _loadError == null
              ? const Color(0xFFEAF8F3)
              : const Color(0xFFFEE4E2),
          icon: _loadError == null
              ? Icons.verified_outlined
              : Icons.error_outline,
        ),
      ],
    );
  }

  Widget _buildUpperInsightGrid() {
    return Column(
      children: [
        _DashboardPanel(
          title: 'Compliance & Regulatory Standards',
          icon: Icons.fact_check_outlined,
          accent: _kSpecPrimary,
          child: Column(
            children: const [
              _ComplianceRow(
                  name: 'GDPR (Data Residency)', status: 'Mandatory'),
              _ComplianceRow(
                  name: 'SOC2 Type II (Annual)', status: 'Mandatory'),
              _ComplianceRow(name: 'ISO 27001 Annex A', status: 'Optional'),
              _ComplianceRow(name: 'FedRAMP Compliance', status: 'Mandatory'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _DashboardPanel(
          title: 'Specialized Technical Specifications',
          icon: Icons.settings_input_component_outlined,
          accent: _kSpecPrimary,
          child: Column(
            children: const [
              _SpecGrid(),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'VIEW FULL ARCHITECTURAL MANIFESTO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _kSpecPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiddleInsightGrid() {
    return const Column(
      children: [
        _DashboardPanel(
          title: 'Subject Matter Experts',
          icon: Icons.groups_outlined,
          accent: _kSpecPrimary,
          child: Column(
            children: [
              _PersonRow(
                name: 'Marcus Thorne',
                role: 'Security Architect',
                badge: 'Sign-off',
                badgeColor: _kSpecTeal,
              ),
              SizedBox(height: 10),
              _PersonRow(
                name: 'Elena Vance',
                role: 'Structural Lead',
                badge: 'Review',
                badgeColor: _kSpecPrimary,
              ),
              SizedBox(height: 10),
              _PersonRow(
                name: 'Julian Sterling',
                role: 'Regulatory Officer',
                badge: 'Sign-off',
                badgeColor: _kSpecTeal,
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        _DashboardPanel(
          title: 'Validation Criteria',
          icon: Icons.biotech_outlined,
          accent: _kSpecPrimary,
          child: Column(
            children: [
              _ValidationRow(
                label: 'Penetration Testing (L3)',
                status: 'Pass',
                statusColor: _kSpecTeal,
                icon: Icons.check_circle,
              ),
              _ValidationRow(
                label: 'Structural Load Simulation',
                status: 'Fail',
                statusColor: _kSpecError,
                icon: Icons.cancel,
              ),
              _ValidationRow(
                label: 'WCAG 2.1 Compliance Audit',
                status: 'Pass',
                statusColor: _kSpecTeal,
                icon: Icons.check_circle,
              ),
              _ValidationRow(
                label: 'Disaster Recovery (RTO 4h)',
                status: 'Queued',
                statusColor: _kSpecPrimary,
                icon: Icons.hourglass_empty,
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        _DashboardPanel(
          title: 'Certifications',
          icon: Icons.article_outlined,
          accent: _kSpecPrimary,
          child: Column(
            children: [
              _DocumentRow(
                title: 'Fire Safety Cert (Class A)',
                subtitle: 'Validated: 12 Oct 2023',
                status: 'Uploaded',
                pending: false,
              ),
              SizedBox(height: 10),
              _DocumentRow(
                title: 'Data Privacy Impact (DPIA)',
                subtitle: 'Awaiting Final Draft',
                status: 'Pending',
                pending: true,
              ),
              SizedBox(height: 10),
              _DocumentRow(
                title: 'SLA Tier 1 Agreement',
                subtitle: 'Validated: 15 Oct 2023',
                status: 'Uploaded',
                pending: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLowerInsightGrid() {
    return Column(
      children: [
        const _DashboardPanel(
          title: 'Risk & Mitigation Strategy',
          icon: Icons.report_problem_outlined,
          accent: _kSpecError,
          child: Column(
            children: [
              _RiskRow(
                profile: 'Data Breach (Unauthorized Access)',
                control: 'Hardware-backed MFA & Zero Trust tunnels',
                impact: 'Critical',
                critical: true,
              ),
              _RiskRow(
                profile: 'Structural Fatigue (Vibration)',
                control: 'Passive damper systems & real-time sensors',
                impact: 'Moderate',
              ),
              _RiskRow(
                profile: 'Supply Chain Delay (Lead times)',
                control: 'Dual-sourcing Tier 1 components',
                impact: 'Low',
                low: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _DashboardPanel(
          title: 'Cross-System Integration Points',
          icon: Icons.hub_outlined,
          accent: _kSpecPrimary,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                crossAxisCount: constraints.maxWidth < 680 ? 1 : 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: constraints.maxWidth < 680 ? 2.8 : 1.65,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _IntegrationInsightCard(
                    title: 'Structural pillars block sightlines in Sector 4G',
                    area: 'Impact Area: Physical/Visibility',
                    detail: 'Re-routing required',
                    state: 'Active Conflict',
                    accent: _kSpecError,
                  ),
                  _IntegrationInsightCard(
                    title: 'SAML 2.0 Identity bridge to Legacy CRM',
                    area: 'Impact Area: Digital Architecture',
                    detail: 'Testing complete',
                    state: 'Resolved',
                    accent: _kSpecTeal,
                  ),
                  _IntegrationInsightCard(
                    title: 'Power load for GPU cluster cooling',
                    area: 'Impact Area: HVAC/Environmental',
                    detail: 'Under Review',
                    state: 'Draft Stage',
                    accent: _kSpecPrimary,
                  ),
                  _IntegrationInsightCard(
                    title: 'Maintenance corridor access control',
                    area: 'Impact Area: Operations',
                    detail: 'Dual-key validated',
                    state: 'Resolved',
                    accent: _kSpecTeal,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _kSpecSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kSpecBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    const Icon(Icons.edit_note_rounded, color: _kSpecPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Specialized Working Notes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _kSpecPrimaryDeep,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Capture the high-risk specialized decisions that should survive handoff without interpretation loss.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _kSpecSubtext,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _notesController,
            minLines: 3,
            maxLines: 8,
            onChanged: (_) => _scheduleSave(),
            style:
                const TextStyle(fontSize: 14, color: _kSpecText, height: 1.5),
            decoration: InputDecoration(
              hintText:
                  'Summarize the specialized design choices here: security zones, compliance obligations, performance hot paths, integration contracts, and validation caveats that must not be lost.',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              filled: true,
              fillColor: _kSpecPanelSoft,
              contentPadding: const EdgeInsets.all(18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: _kSpecBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: _kSpecBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: _kSpecPrimary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPatternsCard(List<String> ownerOptions) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.verified_user_outlined,
            color: const Color(0xFF1D4ED8),
            title: 'Security & compliance patterns',
            subtitle:
                'Exceptional guardrails for world-class data protection and access control.',
            actionLabel: 'Add control',
            onAction: () =>
                _openSecurityPatternDialog(ownerOptions: ownerOptions),
          ),
          const SizedBox(height: 16),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Pattern', flex: 3),
              _TableColumn(label: 'Decision and scope', flex: 5),
              _TableColumn(label: 'Owner', flex: 2),
              _TableColumn(label: 'Status', flex: 2),
              _TableColumn(
                  label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          if (_securityRows.isEmpty)
            _buildEmptyTableState(
              message:
                  'No security patterns captured yet. Add your first control.',
              actionLabel: 'Add control',
              onAction: () =>
                  _openSecurityPatternDialog(ownerOptions: ownerOptions),
            )
          else
            for (int i = 0; i < _securityRows.length; i++) ...[
              _buildSecurityRow(
                _securityRows[i],
                index: i,
                isStriped: i.isOdd,
                ownerOptions: ownerOptions,
              ),
              if (i != _securityRows.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildPerformancePatternsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.auto_graph_outlined,
            color: const Color(0xFF0F766E),
            title: 'Performance & scale patterns',
            subtitle:
                'Exceptional performance decisions that keep the system stable at peak load.',
            actionLabel: 'Add hotspot',
            onAction: _openPerformancePatternDialog,
          ),
          const SizedBox(height: 16),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Service hotspot', flex: 3),
              _TableColumn(label: 'Design focus', flex: 5),
              _TableColumn(label: 'SLA target', flex: 2),
              _TableColumn(label: 'Status', flex: 2),
              _TableColumn(
                  label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          if (_performanceRows.isEmpty)
            _buildEmptyTableState(
              message:
                  'No performance hotspots yet. Add the first scaling decision.',
              actionLabel: 'Add hotspot',
              onAction: _openPerformancePatternDialog,
            )
          else
            for (int i = 0; i < _performanceRows.length; i++) ...[
              _buildPerformanceRow(_performanceRows[i],
                  index: i, isStriped: i.isOdd),
              if (i != _performanceRows.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildIntegrationFlowsCard(List<String> ownerOptions) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.account_tree_outlined,
            color: const Color(0xFF9333EA),
            title: 'Complex data & integration flows',
            subtitle:
                'World-class clarity for every system boundary and data contract.',
            actionLabel: 'Add flow',
            onAction: () =>
                _openIntegrationFlowDialog(ownerOptions: ownerOptions),
          ),
          const SizedBox(height: 16),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Flow or contract', flex: 4),
              _TableColumn(label: 'Owner', flex: 2),
              _TableColumn(label: 'System', flex: 2),
              _TableColumn(label: 'Status', flex: 2),
              _TableColumn(
                  label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          if (_integrationRows.isEmpty)
            _buildEmptyTableState(
              message:
                  'No integration flows yet. Add the first contract or system boundary.',
              actionLabel: 'Add flow',
              onAction: () =>
                  _openIntegrationFlowDialog(ownerOptions: ownerOptions),
            )
          else
            for (int i = 0; i < _integrationRows.length; i++) ...[
              _buildIntegrationRow(
                _integrationRows[i],
                index: i,
                isStriped: i.isOdd,
                ownerOptions: ownerOptions,
              ),
              if (i != _integrationRows.length - 1) const SizedBox(height: 8),
            ],
          const SizedBox(height: 16),
          // Export button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showExportFeedback,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export specialized design brief'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _kSpecPrimaryDeep)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: _kSpecSubtext, height: 1.5)),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add, size: 18),
          label: Text(actionLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: const BorderSide(color: _kSpecBorder),
            backgroundColor: _kSpecPanelSoft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderRow({required List<_TableColumn> columns}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kSpecPanelSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kSpecBorder),
      ),
      child: Row(
        children: [
          for (final column in columns)
            Expanded(
              flex: column.flex,
              child: Align(
                alignment: column.alignment,
                child: Text(
                  column.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: _kSpecSubtext,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow(
    SecurityPatternRow row, {
    required int index,
    required bool isStriped,
    required List<String> ownerOptions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStriped ? _kSpecPanelSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kSpecBorder),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildTableField(
              initialValue: row.pattern,
              hintText: 'Security pattern',
              onChanged: (value) {
                row.pattern = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _buildTableField(
              initialValue: row.decision,
              hintText: 'Decision and scope',
              maxLines: 2,
              onChanged: (value) {
                row.decision = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildOwnerDropdown(
              value: row.owner,
              options: ownerOptions,
              onChanged: (value) {
                row.owner = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildStatusDropdown(
              value: row.status,
              onChanged: (value) {
                setState(() => _securityRows[index].status = value);
                _scheduleSave();
              },
              accent: const Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: _buildDeleteAction(() async {
                final confirmed = await _confirmDelete('security pattern');
                if (!confirmed) return;
                setState(() => _securityRows.removeAt(index));
                _scheduleSave();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(PerformancePatternRow row,
      {required int index, required bool isStriped}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStriped ? _kSpecPanelSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kSpecBorder),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildTableField(
              initialValue: row.hotspot,
              hintText: 'Service hotspot',
              onChanged: (value) {
                row.hotspot = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _buildTableField(
              initialValue: row.focus,
              hintText: 'Design focus',
              maxLines: 2,
              onChanged: (value) {
                row.focus = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildTableField(
              initialValue: row.sla,
              hintText: 'SLA target',
              onChanged: (value) {
                row.sla = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildStatusDropdown(
              value: row.status,
              onChanged: (value) {
                setState(() => _performanceRows[index].status = value);
                _scheduleSave();
              },
              accent: const Color(0xFF0F766E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: _buildDeleteAction(() async {
                final confirmed = await _confirmDelete('performance pattern');
                if (!confirmed) return;
                setState(() => _performanceRows.removeAt(index));
                _scheduleSave();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationRow(
    IntegrationFlowRow row, {
    required int index,
    required bool isStriped,
    required List<String> ownerOptions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStriped ? _kSpecPanelSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kSpecBorder),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _buildTableField(
              initialValue: row.flow,
              hintText: 'Flow or contract',
              maxLines: 2,
              onChanged: (value) {
                row.flow = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildOwnerDropdown(
              value: row.owner,
              options: ownerOptions,
              onChanged: (value) {
                row.owner = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildTableField(
              initialValue: row.system,
              hintText: 'System',
              onChanged: (value) {
                row.system = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildStatusDropdown(
              value: row.status,
              onChanged: (value) {
                setState(() => _integrationRows[index].status = value);
                _scheduleSave();
              },
              accent: const Color(0xFF9333EA),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: _buildDeleteAction(() async {
                final confirmed = await _confirmDelete('integration flow');
                if (!confirmed) return;
                setState(() => _integrationRows.removeAt(index));
                _scheduleSave();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableField({
    required String initialValue,
    required String hintText,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      minLines: 1,
      maxLines: null,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
        isDense: true,
        filled: true,
        fillColor: _kSpecPanelSoft,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kSpecBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kSpecBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kSpecPrimary, width: 2),
        ),
      ),
    );
  }

  Widget _buildOwnerDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final normalized = value.trim();
    final items = normalized.isEmpty || options.contains(normalized)
        ? options
        : [normalized, ...options];
    return DropdownButtonFormField<String>(
      initialValue: items.first,
      alignment: Alignment.center,
      isExpanded: true,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      selectedItemBuilder: (context) => items
          .map((owner) => Align(
                alignment: Alignment.center,
                child: Text(owner, textAlign: TextAlign.center),
              ))
          .toList(),
      items: items
          .map((owner) => DropdownMenuItem(
                value: owner,
                child: Center(child: Text(owner, textAlign: TextAlign.center)),
              ))
          .toList(),
      onChanged: (newValue) {
        if (newValue == null) return;
        onChanged(newValue);
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _kSpecPanelSoft,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kSpecBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kSpecBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kSpecPrimary, width: 2),
        ),
      ),
    );
  }

  Widget _buildEmptyTableState({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kSpecPanelSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kSpecBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1D1F),
              side: const BorderSide(color: _kSpecBorder),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown({
    required String value,
    required ValueChanged<String> onChanged,
    required Color accent,
  }) {
    final normalizedValue = _normalizeStatus(value);
    return DropdownButtonFormField<String>(
      initialValue: normalizedValue,
      alignment: Alignment.center,
      isExpanded: true,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      selectedItemBuilder: (context) => _statusOptions
          .map((status) => Align(
                alignment: Alignment.center,
                child: Text(status, textAlign: TextAlign.center),
              ))
          .toList(),
      items: _statusOptions
          .map((status) => DropdownMenuItem(
                value: status,
                child: Center(child: Text(status, textAlign: TextAlign.center)),
              ))
          .toList(),
      onChanged: (newValue) {
        if (newValue == null) return;
        onChanged(newValue);
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _kSpecPanelSoft,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kSpecBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kSpecBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }

  Widget _buildDeleteAction(Future<void> Function() onDelete) {
    return TextButton.icon(
      onPressed: () async {
        await onDelete();
      },
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('Delete'),
      style: TextButton.styleFrom(
        foregroundColor: _kSpecError,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  Future<bool> _confirmDelete(String label) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete row?'),
        content: Text('Remove this $label from the table?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFB91C1C)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _openSecurityPatternDialog({
    required List<String> ownerOptions,
  }) async {
    final patternController = TextEditingController();
    final decisionController = TextEditingController();
    String owner = ownerOptions.first;
    String status = 'Draft';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Add security control'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: patternController,
                  decoration: const InputDecoration(
                    labelText: 'Pattern',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: decisionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Decision and scope',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: owner,
                  items: ownerOptions
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => owner = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Owner',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: _statusOptions
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => status = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Add control'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    setState(() {
      _securityRows.add(
        SecurityPatternRow(
          pattern: patternController.text.trim(),
          decision: decisionController.text.trim(),
          owner: owner,
          status: status,
        ),
      );
    });
    _scheduleSave();
  }

  Future<void> _openPerformancePatternDialog() async {
    final hotspotController = TextEditingController();
    final focusController = TextEditingController();
    final slaController = TextEditingController();
    String status = 'Draft';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Add performance hotspot'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hotspotController,
                  decoration: const InputDecoration(
                    labelText: 'Service hotspot',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: focusController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Design focus',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: slaController,
                  decoration: const InputDecoration(
                    labelText: 'SLA target',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: _statusOptions
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => status = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Add hotspot'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    setState(() {
      _performanceRows.add(
        PerformancePatternRow(
          hotspot: hotspotController.text.trim(),
          focus: focusController.text.trim(),
          sla: slaController.text.trim(),
          status: status,
        ),
      );
    });
    _scheduleSave();
  }

  Future<void> _openIntegrationFlowDialog({
    required List<String> ownerOptions,
  }) async {
    final flowController = TextEditingController();
    final systemController = TextEditingController();
    String owner = ownerOptions.first;
    String status = 'Draft';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Add integration flow'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: flowController,
                  decoration: const InputDecoration(
                    labelText: 'Flow or contract',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: systemController,
                  decoration: const InputDecoration(
                    labelText: 'System',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: owner,
                  items: ownerOptions
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => owner = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Owner',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: _statusOptions
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => status = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Add flow'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    setState(() {
      _integrationRows.add(
        IntegrationFlowRow(
          flow: flowController.text.trim(),
          owner: owner,
          system: systemController.text.trim(),
          status: status,
        ),
      );
    });
    _scheduleSave();
  }

  void _showExportFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Specialized design brief export will use the latest saved rows.',
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isMobile) {
    const accent = LightModeColors.lightPrimary;
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Design phase · Specialized design',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back: Long lead equipment ordering'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: const BorderSide(color: accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => DesignDeliverablesScreen.open(context),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next: Design deliverables'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back: Long lead equipment ordering'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: const BorderSide(color: accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Text('Design phase · Specialized design',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => DesignDeliverablesScreen.open(context),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next: Design deliverables'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        // Footer hint
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline,
                size: 18, color: LightModeColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Only capture the opinions that truly shape implementation: anything that affects security posture, resilience, data integrity, or cross-team contracts should live in this specialized design summary.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TableColumn {
  const _TableColumn({
    required this.label,
    this.flex = 1,
    this.alignment = Alignment.center,
  });

  final String label;
  final int flex;
  final Alignment alignment;
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? _kSpecPanel : _kSpecSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: selected ? const Color(0xFFC6D7FF) : _kSpecBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? _kSpecPrimary : _kSpecSubtext),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? _kSpecPrimary : _kSpecSubtext,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _kSpecSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kSpecBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _kSpecPrimaryDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ComplianceRow extends StatelessWidget {
  const _ComplianceRow({required this.name, required this.status});

  final String name;
  final String status;

  @override
  Widget build(BuildContext context) {
    final mandatory = status.toLowerCase() == 'mandatory';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kSpecBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kSpecText,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color:
                  mandatory ? const Color(0xFFEAF8F3) : const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: mandatory ? _kSpecTeal : _kSpecPrimary,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecGrid extends StatelessWidget {
  const _SpecGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Encryption Standard', 'AES-256 GCM (Encrypted at Rest)'),
      ('Load Capacity', '500kg/m² (Seismic Grade B)'),
      ('Auth Protocol', 'OpenID Connect + mTLS'),
      ('HVAC Redundancy', 'N+2 Parallel Configuration'),
      ('Network Latency', '< 15ms Intra-Regional'),
      ('API Rate Limit', '5,000 Req/min (Burst 10k)'),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final item in items)
          SizedBox(
            width: 280,
            child: Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _kSpecBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _kSpecSubtext,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kSpecPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.role,
    required this.badge,
    required this.badgeColor,
  });

  final String name;
  final String role;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSpecPanelSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kSpecBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFDCE7FF),
            child: Text(
              name.split(' ').map((e) => e[0]).take(2).join(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: _kSpecPrimaryDeep,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kSpecText,
                  ),
                ),
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kSpecSubtext,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: badgeColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationRow extends StatelessWidget {
  const _ValidationRow({
    required this.label,
    required this.status,
    required this.statusColor,
    required this.icon,
  });

  final String label;
  final String status;
  final Color statusColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kSpecBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kSpecText,
              ),
            ),
          ),
          Row(
            children: [
              Icon(icon, size: 18, color: statusColor),
              const SizedBox(width: 6),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.pending,
  });

  final String title;
  final String subtitle;
  final String status;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSpecPanelSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kSpecBorder),
      ),
      child: Row(
        children: [
          Icon(
            pending ? Icons.cloud_upload_outlined : Icons.description_outlined,
            color: _kSpecSubtext,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: pending ? _kSpecSubtext : _kSpecText,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kSpecSubtext,
                  ),
                ),
              ],
            ),
          ),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: pending ? _kSpecError : _kSpecTeal,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({
    required this.profile,
    required this.control,
    required this.impact,
    this.critical = false,
    this.low = false,
  });

  final String profile;
  final String control;
  final String impact;
  final bool critical;
  final bool low;

  @override
  Widget build(BuildContext context) {
    final badgeColor = critical
        ? const Color(0xFFFEE4E2)
        : low
            ? const Color(0xFFE6EEFF)
            : const Color(0xFFEAF1FF);
    final textColor = critical
        ? _kSpecError
        : low
            ? _kSpecPrimary
            : _kSpecPrimaryDeep;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kSpecBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              profile,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _kSpecText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              control,
              style: const TextStyle(
                fontSize: 12,
                color: _kSpecSubtext,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              impact.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationInsightCard extends StatelessWidget {
  const _IntegrationInsightCard({
    required this.title,
    required this.area,
    required this.detail,
    required this.state,
    required this.accent,
  });

  final String title;
  final String area;
  final String detail;
  final String state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSpecPanelSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kSpecBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            area.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _kSpecSubtext,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _kSpecText,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kSpecSubtext,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Text(
                state.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
