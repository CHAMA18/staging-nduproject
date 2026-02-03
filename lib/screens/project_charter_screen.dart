import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/project_framework_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';
import 'package:ndu_project/widgets/expandable_text.dart';

class ProjectCharterScreen extends StatefulWidget {
  const ProjectCharterScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProjectCharterScreen(),
      ),
    );
  }

  @override
  State<ProjectCharterScreen> createState() => _ProjectCharterScreenState();
}

class _ProjectCharterScreenState extends State<ProjectCharterScreen> {
  ProjectDataModel? _projectData;
  bool _isGenerating = false;
  late final OpenAiServiceSecure _openAi;
  final TextEditingController _projectManagerController = TextEditingController();
  final TextEditingController _projectSponsorController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _organizationalUnitController = TextEditingController();
  bool _isSavingData = false;

  @override
  void initState() {
    super.initState();
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.of(context);
      if (mounted) {
        setState(() {
          _projectData = provider.projectData;
        });
        
        // Load existing values or auto-fill from project data
        _loadAndAutoFillFields(provider.projectData);

        // Auto-generate charter content if needed
        if (_projectData != null) {
          await _ensureCharterContent();
        }
      }
    });
  }

  void _loadAndAutoFillFields(ProjectDataModel data) {
    // Project Manager - try to extract from team members if empty
    if (data.charterProjectManagerName.isNotEmpty) {
      _projectManagerController.text = data.charterProjectManagerName;
    } else {
      final manager = data.teamMembers.firstWhere(
        (m) => m.role.toLowerCase().contains('manager') || m.role.toLowerCase().contains('pm'),
        orElse: () => TeamMember(),
      );
      if (manager.name.isNotEmpty) {
        _projectManagerController.text = manager.name;
      }
    }
    
    // Project Sponsor - try to extract from team members if empty
    if (data.charterProjectSponsorName.isNotEmpty) {
      _projectSponsorController.text = data.charterProjectSponsorName;
    } else {
      final sponsor = data.teamMembers.firstWhere(
        (m) => m.role.toLowerCase().contains('sponsor') || m.role.toLowerCase().contains('executive'),
        orElse: () => TeamMember(),
      );
      if (sponsor.name.isNotEmpty) {
        _projectSponsorController.text = sponsor.name;
      }
    }
    
    // Load other fields
    _phoneController.text = data.charterPhone;
    _organizationalUnitController.text = data.charterOrganizationalUnit;
    
    // Auto-save if we auto-filled anything
    if (_projectManagerController.text.isNotEmpty || _projectSponsorController.text.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _saveAllFields();
      });
    }
  }

  @override
  void dispose() {
    _projectManagerController.dispose();
    _projectSponsorController.dispose();
    _phoneController.dispose();
    _organizationalUnitController.dispose();
    super.dispose();
  }

  Future<void> _saveAllFields() async {
    if (!mounted || _isSavingData) return;
    setState(() => _isSavingData = true);
    
    final provider = ProjectDataInherited.of(context);
    provider.updateField(
      (data) => data.copyWith(
        charterProjectManagerName: _projectManagerController.text.trim(),
        charterProjectSponsorName: _projectSponsorController.text.trim(),
        charterPhone: _phoneController.text.trim(),
        charterOrganizationalUnit: _organizationalUnitController.text.trim(),
      ),
    );
    await provider.saveToFirebase(checkpoint: 'project_charter');
    
    if (mounted) {
      setState(() {
        _isSavingData = false;
        _projectData = provider.projectData;
      });
    }
  }

  Future<void> _regenerateAllCharter() async {
    if (_projectData == null) return;
    final provider = ProjectDataInherited.of(context);
    provider.updateField((data) {
      return data.copyWith(
        businessCase: '',
        projectGoals: [],
        charterAssumptions: '',
        charterConstraints: '',
      );
    });
    setState(() {
      _projectData = provider.projectData;
    });
    await _ensureCharterContent();
  }

  Future<void> _ensureCharterContent() async {
    if (_projectData == null || _isGenerating) return;

    final needsOverview = _projectData!.businessCase.trim().isEmpty &&
        _projectData!.solutionDescription.trim().isEmpty;
    final needsGoals = _projectData!.projectGoals.isEmpty &&
        _projectData!.planningGoals.isEmpty;
    final needsAssumptions = _projectData!.charterAssumptions.trim().isEmpty;
    final needsConstraints = _projectData!.charterConstraints.trim().isEmpty;

    if (!needsOverview && !needsGoals && !needsAssumptions && !needsConstraints) {
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final projectContext = ProjectDataHelper.buildFepContext(_projectData!);

      if (projectContext.trim().isNotEmpty) {
        if (needsOverview) {
          try {
            final overview = await _openAi.generateFepSectionText(
              section: 'Project Overview',
              context: projectContext,
              maxTokens: 600,
            );

            if (mounted && overview.isNotEmpty && _projectData != null) {
              final provider = ProjectDataInherited.of(context);
              provider.updateField((data) {
                if (data.businessCase.trim().isEmpty) {
                  return data.copyWith(businessCase: overview);
                }
                return data;
              });

              setState(() {
                _projectData = provider.projectData;
              });
            }
          } catch (e) {
            debugPrint('Error generating charter overview: $e');
          }
        }

        if (needsGoals) {
          try {
            final goalsText = await _openAi.generateFepSectionText(
              section: 'Project Goals and Objectives',
              context: projectContext,
              maxTokens: 500,
            );

            if (mounted && goalsText.isNotEmpty && _projectData != null) {
              final lines = goalsText
                  .split('\n')
                  .map((l) => l.trim())
                  .where((l) => l.isNotEmpty && !l.startsWith('-') && !l.startsWith('•'))
                  .take(5)
                  .toList();

              if (lines.isNotEmpty) {
                final provider = ProjectDataInherited.of(context);
                final newGoals = lines.map((line) {
                  final cleanLine = line.replaceAll(RegExp(r'^[-•]\s*'), '');
                  return ProjectGoal(
                    name: cleanLine.length > 50 ? cleanLine.substring(0, 50) : cleanLine,
                    description: cleanLine.length > 50 ? cleanLine : '',
                  );
                }).toList();

                provider.updateField((data) {
                  if (data.projectGoals.isEmpty) {
                    return data.copyWith(projectGoals: newGoals);
                  }
                  return data;
                });

                setState(() {
                  _projectData = provider.projectData;
                });
              }
            }
          } catch (e) {
            debugPrint('Error generating charter goals: $e');
          }
        }

        if (needsAssumptions || needsConstraints) {
          final provider = ProjectDataInherited.of(context);
          if (needsAssumptions) {
            try {
              final assumptions = await _openAi.generateFepSectionText(
                section: 'Assumptions',
                context: projectContext,
                maxTokens: 320,
              );
              if (mounted && assumptions.trim().isNotEmpty) {
                provider.updateField((data) => data.copyWith(charterAssumptions: assumptions.trim()));
              }
            } catch (e) {
              debugPrint('Error generating charter assumptions: $e');
            }
          }
          if (needsConstraints) {
            try {
              final constraints = await _openAi.generateFepSectionText(
                section: 'Constraints',
                context: projectContext,
                maxTokens: 320,
              );
              if (mounted && constraints.trim().isNotEmpty) {
                provider.updateField((data) => data.copyWith(charterConstraints: constraints.trim()));
              }
            } catch (e) {
              debugPrint('Error generating charter constraints: $e');
            }
          }
          if (mounted) {
            setState(() {
              _projectData = provider.projectData;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error ensuring charter content: $e');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagePadding = AppBreakpoints.pagePadding(context);
    final isMobile = AppBreakpoints.isMobile(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Project Charter',
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isGenerating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Generating project charter...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(pagePadding).copyWith(
                top: pagePadding + (isMobile ? 16 : 24),
                bottom: 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with title and regenerate button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Project Charter',
                          style: TextStyle(
                            fontSize: isMobile ? 22 : 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      PageRegenerateAllButton(
                        onRegenerateAll: () async {
                          final confirmed = await showRegenerateAllConfirmation(context);
                          if (confirmed && mounted) {
                            await _regenerateAllCharter();
                          }
                        },
                        isLoading: _isGenerating,
                        tooltip: 'Regenerate all charter content',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Main Charter Content - Two Column Layout
                  _buildCharterContent(isMobile),
                  const SizedBox(height: 32),
                  LaunchPhaseNavigation(
                    backLabel: 'Back',
                    nextLabel: 'Next: Project framework',
                    onBack: () => Navigator.pop(context),
                    onNext: () => ProjectFrameworkScreen.open(context),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCharterContent(bool isMobile) {
    if (isMobile) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.desktop_mac_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Desktop View Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'The Project Charter is a comprehensive document\nbest viewed on a larger screen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    // Two-column layout for desktop
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (60%)
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGeneralProjectInfo(),
              const SizedBox(height: 16),
              // Add Visual Charts Here
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTentativeScheduleChart()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCostDistributionChart()),
                ],
              ),
              const SizedBox(height: 16),
              _buildProjectMetricsSection(),
              const SizedBox(height: 16),
              _buildProjectOverviewSection(),
              const SizedBox(height: 16),
              _buildProjectScopeSection(),
              const SizedBox(height: 16),
              _buildTentativeScheduleSection(),
              const SizedBox(height: 16),
              _buildResourcesSection(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right Column (40%)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCostsSection(),
              const SizedBox(height: 16),
              _buildBenefitsAndCustomersSection(),
              const SizedBox(height: 16),
              _buildRisksConstraintsAssumptionsSection(),
              const SizedBox(height: 16),
              _buildApprovalSection(),
            ],
          ),
        ),
      ],
    );
  }

  // --- Start of Chart Widgets ---

  Widget _buildTentativeScheduleChart() {
    final start = _projectData?.createdAt ?? DateTime.now();
    // Try to find end date from milestones or fallback
    DateTime end = DateTime.now().add(const Duration(days: 90)); // Default 3 months
    
    final milestones = _projectData?.keyMilestones ?? [];
    if (milestones.isNotEmpty) {
      // Sort to find last milestone
       final sorted = List<Milestone>.from(milestones)
        ..sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));
      if (sorted.isNotEmpty && sorted.last.date != null) {
        end = sorted.last.date!;
      }
    }

    if (end.isBefore(start)) end = start.add(const Duration(days: 1));

    final totalDuration = end.difference(start).inDays;

    return _CharterSection(
      title: 'TIMELINE OVERVIEW',
      backgroundColor: Colors.white,
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Base Timeline Bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Progress Fill (approximated by current time vs start/end)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final now = DateTime.now();
                      if (now.isBefore(start)) return const SizedBox();
                      
                      final elapsed = now.difference(start).inDays;
                      final progress = (elapsed / totalDuration).clamp(0.0, 1.0);
                      
                      return Container(
                        width: constraints.maxWidth * progress,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                  // Milestones Markers
                  if (milestones.isNotEmpty)
                    ...milestones.map((m) {
                      if (m.date == null) return const SizedBox();
                      final offset = m.date!.difference(start).inDays;
                      final pct = (offset / totalDuration).clamp(0.0, 1.0);
                      
                      return Align(
                        alignment: Alignment(pct * 2 - 1, -0.5), // Map 0..1 to -1..1
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 2,
                              height: 12,
                              color: Colors.black,
                            ),
                            Text(
                              m.title.length > 10 ? '${m.title.substring(0, 8)}...' : m.title,
                              style: const TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start: ${_formatDate(start)}', style: const TextStyle(fontSize: 10)),
                Text('End: ${_formatDate(end)}', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostDistributionChart() {
    final items = _projectData?.costEstimateItems ?? [];
    
    if (items.isEmpty) {
       return _CharterSection(
        title: 'COST DISTRIBUTION',
        backgroundColor: Colors.white,
        child: Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text(
              'No cost estimates available yet.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ),
      );
    }

    final total = items.fold(0.0, (sum, item) => sum + item.amount);
    
    // Group small items into "Other"
    final sortedItems = List<CostEstimateItem>.from(items)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    
    final topItems = sortedItems.take(4).toList(); // Top 4
    final otherItems = sortedItems.skip(4).toList();
    final otherTotal = otherItems.fold(0.0, (sum, item) => sum + item.amount);

    return _CharterSection(
      title: 'COST DISTRIBUTION',
      backgroundColor: Colors.white,
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...topItems.map((item) => _buildCostBarRow(
                    item.title.isNotEmpty ? item.title : 'Untitled Item',
                    total > 0 ? item.amount / total : 0,
                    _getColorForIndex(sortedItems.indexOf(item)),
                  )),
                  if (otherTotal > 0)
                    _buildCostBarRow('Other', otherTotal / total, Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getColorForIndex(int index) {
    const colors = [Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.red];
    return colors[index % colors.length];
  }

  Widget _buildCostBarRow(String label, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 70, 
            child: Text(
              label, 
              style: const TextStyle(fontSize: 10), 
              overflow: TextOverflow.ellipsis
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(height: 8, color: Colors.grey[100]),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(height: 8, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // --- End of Chart Widgets ---

  // ==================== GENERAL PROJECT INFORMATION ====================
  Widget _buildGeneralProjectInfo() {
    return _CharterSection(
      title: 'GENERAL PROJECT INFORMATION',
      backgroundColor: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          // Row 1: Project Name, Manager, Sponsor
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildInfoField('PROJECT NAME', _projectData?.projectName ?? 'Not specified'),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildEditableField('PROJECT MANAGER', _projectManagerController, _saveAllFields),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildEditableField('PROJECT SPONSOR', _projectSponsorController, _saveAllFields),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Phone, Organizational Unit, Start Date
          Row(
            children: [
              Expanded(
                child: _buildEditableField('PHONE', _phoneController, _saveAllFields),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildEditableField('ORGANIZATIONAL UNIT(S)', _organizationalUnitController, _saveAllFields),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoField('EXPECTED START DATE', _formatDate(_projectData?.createdAt)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3: Completion Date, Savings, Costs
          Row(
            children: [
              Expanded(
                child: _buildInfoField('EXPECTED COMPLETION', _extractEndDate(_projectData)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoField('EXPECTED SAVINGS', _extractTotalBenefits(_projectData)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoField('ESTIMATED COSTS', _extractTotalCost(_projectData)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, VoidCallback onSave) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          TextField(
            controller: controller,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'Enter here...',
              hintStyle: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            ),
            onChanged: (_) => onSave(),
          ),
        ],
      ),
    );
  }

  // ==================== PROJECT OVERVIEW ====================
  Widget _buildProjectOverviewSection() {
    return _CharterSection(
      title: 'PROJECT OVERVIEW',
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildYellowLabeledField(
            'PROBLEM OR ISSUE',
            _extractProblemStatement(_projectData),
          ),
          const SizedBox(height: 12),
          _buildYellowLabeledField(
            'PURPOSE OF PROJECT',
            _extractPurposeOfProject(_projectData),
          ),
          const SizedBox(height: 12),
          _buildYellowLabeledField(
            'BUSINESS CASE',
            _projectData?.businessCase ?? 'Business case not defined.',
          ),
          const SizedBox(height: 12),
          _buildYellowLabeledField(
            'GOALS / METRICS',
            _extractGoalsAndMetrics(_projectData),
          ),
          const SizedBox(height: 12),
          _buildYellowLabeledField(
            'EXPECTED DELIVERABLES',
            _extractDeliverables(_projectData),
          ),
        ],
      ),
    );
  }

  Widget _buildYellowLabeledField(String label, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF4D03F), // Yellow/gold
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: content.isEmpty
                ? const Text(
                    '—',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999999),
                    ),
                  )
                : ExpandableText(
                    text: content,
                    maxLines: 8,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.5,
                      color: Color(0xFF333333),
                    ),
                    expandButtonColor: const Color(0xFFF59E0B),
                  ),
          ),
        ),
      ],
    );
  }

  // ==================== PROJECT SCOPE ====================
  Widget _buildProjectScopeSection() {
    return _CharterSection(
      title: 'PROJECT SCOPE',
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildCyanLabeledField(
            'WITHIN SCOPE',
            _extractWithinScope(_projectData),
          ),
          const SizedBox(height: 12),
          _buildCyanLabeledField(
            'OUTSIDE OF SCOPE',
            _extractOutsideScope(_projectData),
          ),
        ],
      ),
    );
  }

  Widget _buildCyanLabeledField(String label, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F6F3), // Light cyan/teal
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              content.isEmpty ? '—' : content,
              style: const TextStyle(
                fontSize: 10,
                height: 1.5,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== TENTATIVE SCHEDULE ====================
  Widget _buildTentativeScheduleSection() {
    final milestones = _extractMilestones(_projectData);
    
    return _CharterSection(
      title: 'TENTATIVE SCHEDULE',
      backgroundColor: Colors.white,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
        },
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: const [
              Padding(
                padding: EdgeInsets.all(8),
                child: Text('KEY MILESTONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text('START', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text('FINISH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          // Data rows
          ...milestones.map((m) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(m['name'] ?? '', style: const TextStyle(fontSize: 10)),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(m['start'] ?? '', style: const TextStyle(fontSize: 10)),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(m['finish'] ?? '', style: const TextStyle(fontSize: 10)),
              ),
            ],
          )),
        ],
      ),
    );
  }

  // ==================== RESOURCES ====================
  Widget _buildResourcesSection() {
    return _CharterSection(
      title: 'RESOURCES',
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildGreenLabeledField(
            'PROJECT TEAM',
            _extractProjectTeam(_projectData),
          ),
          const SizedBox(height: 12),
          _buildGreenLabeledField(
            'SUPPORT RESOURCES',
            _extractSupportResources(_projectData),
          ),
          const SizedBox(height: 12),
          _buildGreenLabeledField(
            'SPECIAL NEEDS',
            _extractSpecialNeeds(_projectData),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenLabeledField(String label, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F8F5), // Light green
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              content.isEmpty ? '—' : content,
              style: const TextStyle(
                fontSize: 10,
                height: 1.5,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== COSTS ====================
  Widget _buildCostsSection() {
    final costs = _extractCostBreakdown(_projectData);
    final totalCost = _extractTotalCost(_projectData);
    
    return _CharterSection(
      title: 'COSTS',
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(0.7),
              4: FlexColumnWidth(1.2),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('COST TYPE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('VENDOR / LABOR NAMES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('RATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('QTY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('AMOUNT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              // Data rows
              ...costs.map((c) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(c['type'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(c['vendor'] ?? '', style: const TextStyle(fontSize: 9)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(c['rate'] ?? '', style: const TextStyle(fontSize: 9)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(c['qty'] ?? '', style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(c['amount'] ?? '', style: const TextStyle(fontSize: 9), textAlign: TextAlign.right),
                  ),
                ],
              )),
            ],
          ),
          const SizedBox(height: 8),
          // Total row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'TOTAL COSTS  \$',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  totalCost,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BENEFITS AND CUSTOMERS ====================
  Widget _buildBenefitsAndCustomersSection() {
    final benefits = _extractBenefitBreakdown(_projectData);
    final totalBenefit = _extractTotalBenefits(_projectData);
    
    return _CharterSection(
      title: 'BENEFITS AND CUSTOMERS',
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildYellowSmallLabeledField('PROCESS OWNER', _extractProcessOwner(_projectData)),
          const SizedBox(height: 8),
          _buildYellowSmallLabeledField('KEY STAKEHOLDERS', _extractKeyStakeholders(_projectData)),
          const SizedBox(height: 8),
          _buildYellowSmallLabeledField('FINAL CUSTOMER', _extractFinalCustomer(_projectData)),
          const SizedBox(height: 8),
          _buildYellowSmallLabeledField('EXPECTED BENEFITS', _extractExpectedBenefits(_projectData)),
          const SizedBox(height: 12),
          // Benefits breakdown table
          Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.2),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('TYPE OF BENEFIT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('BASIS OF ESTIMATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text('EST BENEFIT AMT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              // Data rows
              ...benefits.map((b) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(b['type'] ?? '', style: const TextStyle(fontSize: 9)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(b['basis'] ?? '', style: const TextStyle(fontSize: 9)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(b['amount'] ?? '', style: const TextStyle(fontSize: 9), textAlign: TextAlign.right),
                  ),
                ],
              )),
            ],
          ),
          const SizedBox(height: 8),
          // Total row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'TOTAL BENEFIT  \$',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  totalBenefit,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYellowSmallLabeledField(String label, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF4D03F),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: content.isEmpty
                ? const Text(
                    '—',
                    style: TextStyle(fontSize: 9, color: Color(0xFF999999)),
                  )
                : ExpandableText(
                    text: content,
                    maxLines: 8,
                    style: const TextStyle(fontSize: 9, color: Color(0xFF333333)),
                    expandButtonColor: const Color(0xFFF59E0B),
                  ),
          ),
        ),
      ],
    );
  }

  // ==================== RISKS (PROMINENT) ====================
  Widget _buildRisksSection() {
    final risks = _extractRisks(_projectData);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prominent header with warning icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'PROJECT RISKS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.red.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Risks content
          Padding(
            padding: const EdgeInsets.all(12),
            child: risks.isEmpty
                ? Text(
                    'No risks identified',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  )
                : Text(
                    risks,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.5,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==================== CONSTRAINTS AND ASSUMPTIONS ====================
  Widget _buildRisksConstraintsAssumptionsSection() {
    final constraints = _projectData?.constraints ?? [];
    final assumptions = _projectData?.assumptions ?? [];
    final oldConstraints = _projectData?.charterConstraints ?? '';
    final oldAssumptions = _projectData?.charterAssumptions ?? '';

    // Combine new list data with old string data if present
    final constraintText = constraints.isNotEmpty
        ? '• ${constraints.join('\n• ')}'
        : (oldConstraints.isNotEmpty ? oldConstraints : 'Not specified');

    final assumptionText = assumptions.isNotEmpty
        ? '• ${assumptions.join('\n• ')}'
        : (oldAssumptions.isNotEmpty ? oldAssumptions : 'Not specified');

    return Column(
      children: [
        // Prominent Risks section
        _buildRisksSection(),
        const SizedBox(height: 16),
        // Constraints and Assumptions
        _CharterSection(
          title: 'CONSTRAINTS AND ASSUMPTIONS',
          backgroundColor: Colors.white,
          child: Column(
            children: [
              _buildYellowSmallLabeledField('CONSTRAINTS', constraintText),
              const SizedBox(height: 8),
              _buildYellowSmallLabeledField('ASSUMPTIONS', assumptionText),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== APPROVAL SECTION ====================
  Widget _buildApprovalSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
        columnWidths: const {
          0: FlexColumnWidth(1.5),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(1.5),
        },
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade100),
            children: const [
              Padding(
                padding: EdgeInsets.all(8),
                child: Text('PREPARED BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text('TITLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          // Data row
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _projectManagerController.text.isEmpty ? 'Not specified' : _projectManagerController.text,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Project Manager', style: TextStyle(fontSize: 10)),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  DateFormat('MM/dd/yyyy').format(DateTime.now()),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== DATA EXTRACTION HELPERS ====================
  String _formatDate(DateTime? date) {
    if (date == null) return 'Not specified';
    return DateFormat('MM/dd/yyyy').format(date);
  }

  String _extractEndDate(ProjectDataModel? data) {
    if (data == null) return 'Not specified';
    if (data.keyMilestones.isNotEmpty) {
      final latestMilestone = data.keyMilestones.reduce((a, b) {
        if (a.dueDate.isEmpty) return b;
        if (b.dueDate.isEmpty) return a;
        try {
          final aDate = DateTime.parse(a.dueDate);
          final bDate = DateTime.parse(b.dueDate);
          return aDate.isAfter(bDate) ? a : b;
        } catch (e) {
          return a;
        }
      });
      if (latestMilestone.dueDate.isNotEmpty) {
        try {
          final date = DateTime.parse(latestMilestone.dueDate);
          return DateFormat('MM/dd/yyyy').format(date);
        } catch (e) {
          return latestMilestone.dueDate;
        }
      }
    }
    return 'Not specified';
  }

  String _extractTotalCost(ProjectDataModel? data) {
    if (data == null) return '0.00';
    double totalCost = 0.0;
    if (data.costAnalysisData != null) {
      for (final solution in data.costAnalysisData!.solutionCosts) {
        for (final row in solution.costRows) {
          final costStr = row.cost.replaceAll(RegExp(r'[^\d.]'), '');
          totalCost += double.tryParse(costStr) ?? 0.0;
        }
      }
    }
    return totalCost.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  String _extractTotalBenefits(ProjectDataModel? data) {
    if (data == null) return '0.00';
    double total = 0.0;
    if (data.costAnalysisData != null) {
      // Benefits are stored in benefitLineItems on CostAnalysisData
      for (final item in data.costAnalysisData!.benefitLineItems) {
        final valStr = item.unitValue.replaceAll(RegExp(r'[^\d.]'), '');
        final qty = double.tryParse(item.units) ?? 1.0;
        final unit = double.tryParse(valStr) ?? 0.0;
        total += unit * qty;
      }
    }
    return total.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  String _extractProblemStatement(ProjectDataModel? data) {
    if (data == null) return 'Problem statement not defined.';
    if (data.projectObjective.isNotEmpty) return data.projectObjective;
    if (data.solutionDescription.isNotEmpty) return data.solutionDescription;
    return 'The project aims to address identified business challenges through a structured solution implementation.';
  }

  String _extractPurposeOfProject(ProjectDataModel? data) {
    if (data == null) return 'Purpose not defined.';
    final parts = <String>[];
    if (data.projectObjective.isNotEmpty) {
      parts.add(data.projectObjective);
    }
    if (data.solutionDescription.isNotEmpty) {
      parts.add(data.solutionDescription);
    }
    if (parts.isEmpty) {
      return 'To deliver value through effective project management and stakeholder alignment.';
    }
    return parts.join(' ');
  }

  String _extractGoalsAndMetrics(ProjectDataModel? data) {
    if (data == null) return 'Goals not defined.';
    final goals = <String>[];
    for (final goal in data.projectGoals) {
      if (goal.name.isNotEmpty) {
        goals.add('• ${goal.name}${goal.description.isNotEmpty ? ": ${goal.description}" : ""}');
      }
    }
    for (final goal in data.planningGoals) {
      if (goal.title.isNotEmpty) {
        goals.add('• ${goal.title}${goal.description.isNotEmpty ? ": ${goal.description}" : ""}');
      }
    }
    if (goals.isEmpty) {
      return 'Project goals and key performance indicators will be defined during planning phase.';
    }
    return goals.join('\n');
  }

  String _extractDeliverables(ProjectDataModel? data) {
    if (data == null) return 'Deliverables not defined.';
    final deliverables = <String>[];
    if (data.solutionDescription.isNotEmpty) {
      deliverables.add('• ${data.solutionDescription}');
    }
    for (final goal in data.projectGoals) {
      if (goal.name.isNotEmpty) {
        deliverables.add('• ${goal.name}');
      }
    }
    if (deliverables.isEmpty) {
      return 'Specific deliverables will be defined during the planning phase.';
    }
    return deliverables.take(5).join('\n');
  }

  String _extractWithinScope(ProjectDataModel? data) {
    if (data == null) return 'Scope not defined.';
    final scopeItems = <String>[];
    // Use project objective and solution description as scope
    if (data.projectObjective.isNotEmpty) {
      scopeItems.add('• ${data.projectObjective}');
    }
    if (data.solutionDescription.isNotEmpty) {
      scopeItems.add('• ${data.solutionDescription}');
    }
    // Add deliverables from project goals
    for (final goal in data.projectGoals.take(3)) {
      if (goal.name.isNotEmpty) {
        scopeItems.add('• ${goal.name}');
      }
    }
    if (scopeItems.isEmpty) {
      return 'Project scope will be defined during the planning phase.';
    }
    return scopeItems.join('\n');
  }

  String _extractOutsideScope(ProjectDataModel? data) {
    if (data == null) return 'Out of scope items not defined.';
    
    // Use the explicit outOfScope list from Project Data
    if (data.outOfScope.isNotEmpty) {
      return '• ${data.outOfScope.join('\n• ')}';
    }

    // Fallback: Extract from risks or constraints as potential exclusions
    final exclusions = <String>[];
    if (data.charterConstraints.isNotEmpty) {
      exclusions.add('• ${data.charterConstraints}');
    }
    if (exclusions.isEmpty) {
      return 'Items outside the project scope will be identified during planning.';
    }
    return exclusions.join('\n');
  }

  List<Map<String, String>> _extractMilestones(ProjectDataModel? data) {
    final milestones = <Map<String, String>>[];
    if (data == null) {
      return [
        {'name': 'Project Initiation', 'start': 'TBD', 'finish': 'TBD'},
        {'name': 'Planning Phase', 'start': 'TBD', 'finish': 'TBD'},
        {'name': 'Implementation', 'start': 'TBD', 'finish': 'TBD'},
        {'name': 'Project Close Out', 'start': 'TBD', 'finish': 'TBD'},
      ];
    }
    for (final m in data.keyMilestones) {
      if (m.name.isNotEmpty) {
        milestones.add({
          'name': m.name,
          'start': m.dueDate.isNotEmpty ? m.dueDate : 'TBD',
          'finish': m.dueDate.isNotEmpty ? m.dueDate : 'TBD',
        });
      }
    }
    if (milestones.isEmpty) {
      return [
        {'name': 'Project Initiation', 'start': 'TBD', 'finish': 'TBD'},
        {'name': 'Planning Phase', 'start': 'TBD', 'finish': 'TBD'},
        {'name': 'Implementation', 'start': 'TBD', 'finish': 'TBD'},
        {'name': 'Project Close Out', 'start': 'TBD', 'finish': 'TBD'},
      ];
    }
    return milestones;
  }

  String _extractProjectTeam(ProjectDataModel? data) {
    if (data == null) return 'Team not defined.';
    final members = <String>[];
    for (final m in data.teamMembers) {
      if (m.name.isNotEmpty) {
        members.add('${m.name}${m.role.isNotEmpty ? " - ${m.role}" : ""}');
      }
    }
    if (members.isEmpty) {
      return 'Project team members will be assigned during planning.';
    }
    return members.join(', ');
  }

  String _extractSupportResources(ProjectDataModel? data) {
    if (data == null) return 'Support resources not defined.';
    final resources = <String>[];
    // Extract from core stakeholders data
    if (data.coreStakeholdersData != null) {
      for (final sr in data.coreStakeholdersData!.solutionStakeholderData) {
        if (sr.internalStakeholders.isNotEmpty) {
          resources.add(sr.internalStakeholders);
        }
      }
    }
    if (resources.isEmpty) {
      return 'Operations, Project Management, Engineering';
    }
    return resources.take(5).join(', ');
  }

  String _extractSpecialNeeds(ProjectDataModel? data) {
    if (data == null) return 'TBD';
    final needs = <String>[];
    // Extract from IT considerations data
    if (data.itConsiderationsData != null) {
      for (final it in data.itConsiderationsData!.solutionITData) {
        if (it.coreTechnology.isNotEmpty && !needs.contains(it.coreTechnology)) {
          needs.add(it.coreTechnology);
        }
      }
    }
    if (needs.isEmpty) {
      return 'Special requirements will be identified during planning.';
    }
    return needs.take(3).join(', ');
  }

  List<Map<String, String>> _extractCostBreakdown(ProjectDataModel? data) {
    final costs = <Map<String, String>>[];
    if (data == null || data.costAnalysisData == null) {
      return [
        {'type': 'Labor', 'vendor': 'TBD', 'rate': '\$0.00', 'qty': '0', 'amount': '\$0.00'},
      ];
    }
    for (final solution in data.costAnalysisData!.solutionCosts) {
      for (final row in solution.costRows) {
        costs.add({
          'type': row.itemName.isEmpty ? 'General' : row.itemName,
          'vendor': row.description.isEmpty ? 'TBD' : row.description,
          'rate': row.cost.isEmpty ? '\$0.00' : '\$${row.cost}',
          'qty': '1',
          'amount': row.cost.isEmpty ? '\$0.00' : '\$${row.cost}',
        });
      }
    }
    if (costs.isEmpty) {
      return [
        {'type': 'Labor', 'vendor': 'TBD', 'rate': '\$0.00', 'qty': '0', 'amount': '\$0.00'},
      ];
    }
    return costs.take(8).toList();
  }

  String _extractProcessOwner(ProjectDataModel? data) {
    if (data == null) return 'Not specified';
    if (_projectManagerController.text.isNotEmpty) {
      return '${_projectManagerController.text} - Project Manager';
    }
    return 'Project Manager';
  }

  String _extractKeyStakeholders(ProjectDataModel? data) {
    if (data == null) return 'Not specified';
    final stakeholders = <String>[];
    // Extract from core stakeholders data
    if (data.coreStakeholdersData != null) {
      for (final sr in data.coreStakeholdersData!.solutionStakeholderData) {
        if (sr.externalStakeholders.isNotEmpty) {
          stakeholders.add(sr.externalStakeholders);
        }
        if (sr.internalStakeholders.isNotEmpty) {
          stakeholders.add(sr.internalStakeholders);
        }
        if (sr.notableStakeholders.isNotEmpty) {
          stakeholders.add(sr.notableStakeholders);
        }
      }
    }
    if (stakeholders.isEmpty) {
      return 'Key stakeholders will be identified during planning.';
    }
    return stakeholders.take(5).join(', ');
  }

  String _extractFinalCustomer(ProjectDataModel? data) {
    if (data == null) return 'Not specified';
    return 'End users and stakeholders who will benefit from the project outcomes.';
  }

  String _extractExpectedBenefits(ProjectDataModel? data) {
    if (data == null) return 'Benefits not defined.';
    final benefits = <String>[];
    // Benefits are stored in benefitLineItems on CostAnalysisData
    if (data.costAnalysisData != null) {
      for (final item in data.costAnalysisData!.benefitLineItems) {
        if (item.title.isNotEmpty) {
          benefits.add(item.title);
        } else if (item.categoryKey.isNotEmpty) {
          benefits.add(item.categoryKey);
        }
      }
    }
    if (benefits.isEmpty) {
      return 'Expected benefits include improved efficiency, cost savings, and enhanced stakeholder satisfaction.';
    }
    return benefits.take(3).join(', ');
  }

  List<Map<String, String>> _extractBenefitBreakdown(ProjectDataModel? data) {
    final benefits = <Map<String, String>>[];
    if (data == null || data.costAnalysisData == null) {
      return [
        {'type': 'Cost Savings', 'basis': 'To be estimated', 'amount': '\$0.00'},
        {'type': 'Efficiency Gains', 'basis': 'To be estimated', 'amount': '\$0.00'},
      ];
    }
    // Benefits are stored in benefitLineItems on CostAnalysisData
    for (final item in data.costAnalysisData!.benefitLineItems) {
      final valStr = item.unitValue.replaceAll(RegExp(r'[^\d.]'), '');
      final qty = double.tryParse(item.units) ?? 1.0;
      final unit = double.tryParse(valStr) ?? 0.0;
      final total = (unit * qty).toStringAsFixed(2);
      benefits.add({
        'type': item.title.isEmpty ? (item.categoryKey.isEmpty ? 'General Benefit' : item.categoryKey) : item.title,
        'basis': 'Estimated projections',
        'amount': '\$$total',
      });
    }
    if (benefits.isEmpty) {
      return [
        {'type': 'Cost Savings', 'basis': 'To be estimated', 'amount': '\$0.00'},
        {'type': 'Efficiency Gains', 'basis': 'To be estimated', 'amount': '\$0.00'},
      ];
    }
    return benefits.take(7).toList();
  }

  String _extractRisks(ProjectDataModel? data) {
    if (data == null) return 'Risks not identified.';
    final risks = <String>[];
    for (final sr in data.solutionRisks) {
      for (final r in sr.risks) {
        if (r.isNotEmpty && !risks.contains(r)) {
          risks.add(r);
        }
      }
    }
    if (risks.isEmpty) {
      return 'Project risks will be identified and assessed during the planning phase.';
    }
    return risks.take(3).join('. ');
  }

  // ==================== VISUAL METRIC CARDS ====================
  Widget _buildProjectMetricsSection() {
    return _CharterSection(
      title: 'PROJECT METRICS AT A GLANCE',
      backgroundColor: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          if (isMobile) {
            // Stack vertically on mobile
            return Column(
              children: [
                _buildMetricCard(
                  'Est. Savings',
                  _formatCurrency(_projectData?.expectedAnnualProjectSavings ?? '0'),
                  Icons.trending_up,
                  const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                _buildMetricCard(
                  'Est. Costs',
                  _formatCurrency(_projectData?.estimatedProjectCost ?? '0'),
                  Icons.account_balance_wallet,
                  const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 12),
                _buildMetricCard(
                  'Duration',
                  _calculateDuration(
                    _projectData?.charterStartDate,
                    _projectData?.charterCompletionDate,
                  ),
                  Icons.calendar_today,
                  const Color(0xFF3B82F6),
                ),
              ],
            );
          }
          
          // Row layout for desktop
          return Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Est. Savings',
                  _formatCurrency(_projectData?.expectedAnnualProjectSavings ?? '0'),
                  Icons.trending_up,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Est. Costs',
                  _formatCurrency(_projectData?.estimatedProjectCost ?? '0'),
                  Icons.account_balance_wallet,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Duration',
                  _calculateDuration(
                    _projectData?.charterStartDate,
                    _projectData?.charterCompletionDate,
                  ),
                  Icons.calendar_today,
                  const Color(0xFF3B82F6),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(String value) {
    if (value.isEmpty || value == '0') return '\$0';
    // Remove any existing currency symbols and commas
    final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
    final number = double.tryParse(cleanValue);
    if (number == null) return '\$$value';
    
    // Format with thousands separator
    if (number >= 1000000) {
      return '\$${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '\$${(number / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${number.toStringAsFixed(0)}';
    }
  }

  String _calculateDuration(String? start, String? end) {
    if (start == null || end == null || start.isEmpty || end.isEmpty) {
      return 'TBD';
    }
    try {
      final startDate = DateFormat('MMM dd, yyyy').parse(start);
      final endDate = DateFormat('MMM dd, yyyy').parse(end);
      final days = endDate.difference(startDate).inDays;
      
      if (days < 0) return 'TBD';
      if (days == 0) return '1 day';
      if (days < 30) return '$days days';
      if (days < 365) {
        final months = (days / 30).round();
        return months == 1 ? '1 month' : '$months months';
      }
      final years = (days / 365).toStringAsFixed(1);
      return years == '1.0' ? '1 year' : '$years years';
    } catch (e) {
      return 'TBD';
    }
  }
}

// ==================== CHARTER SECTION WIDGET ====================
class _CharterSection extends StatelessWidget {
  const _CharterSection({
    required this.title,
    required this.child,
    this.backgroundColor = Colors.white,
  });

  final String title;
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          // Section content
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }


