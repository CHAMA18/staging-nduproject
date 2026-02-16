import 'package:flutter/material.dart';

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

import 'package:ndu_project/screens/project_charter_sections.dart';
import 'package:ndu_project/screens/charter_governance_section.dart';

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
  @override
  void initState() {
    super.initState();
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.read(context);
      if (mounted) {
        setState(() {
          _projectData = provider.projectData;
        });

        // Auto-generate charter content if needed
        if (_projectData != null) {
          await _ensureCharterContent();
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _regenerateAllCharter() async {
    if (_projectData == null) return;
    final provider = ProjectDataInherited.read(context);
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
    final needsAssumptions = _projectData!.charterAssumptions.trim().isEmpty;
    final needsConstraints = _projectData!.charterConstraints.trim().isEmpty;

    if (!needsOverview && !needsAssumptions && !needsConstraints) {
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
              final provider = ProjectDataInherited.read(context);
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

        if (needsAssumptions || needsConstraints) {
          if (!mounted) return;
          final provider = ProjectDataInherited.read(context);
          if (needsAssumptions) {
            try {
              final assumptions = await _openAi.generateFepSectionText(
                section: 'Assumptions',
                context: projectContext,
                maxTokens: 320,
              );
              if (mounted && assumptions.trim().isNotEmpty) {
                provider.updateField((data) =>
                    data.copyWith(charterAssumptions: assumptions.trim()));
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
                provider.updateField((data) =>
                    data.copyWith(charterConstraints: constraints.trim()));
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

  Future<void> _generateSection(String sectionType) async {
    if (_projectData == null || _isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final contextText = ProjectDataHelper.buildFepContext(_projectData!);
      final provider = ProjectDataInherited.read(context);

      if (sectionType == 'definition') {
        final overview = await _openAi.generateFepSectionText(
          section: 'Project Overview and Business Case',
          context: contextText,
          maxTokens: 800,
        );
        if (mounted && overview.isNotEmpty) {
          provider.updateField((data) => data.copyWith(
                businessCase: overview,
              ));
        }
      } else if (sectionType == 'scope') {
        final scope = await _openAi.generateProjectScope(
          context: contextText,
        );
        if (mounted) {
          final inScope = List<String>.from(scope['in'] ?? []);
          final outScope = List<String>.from(scope['out'] ?? []);
          if (inScope.isNotEmpty || outScope.isNotEmpty) {
            provider.updateField((data) => data.copyWith(
                  withinScope: inScope,
                  outOfScope: outScope,
                ));
          }
        }
      } else if (sectionType == 'risks') {
        final result = await _openAi.generateDetailedRisks(
          context: contextText,
        );
        if (mounted) {
          final newRisks = List<RiskRegisterItem>.from(result['risks'] ?? []);
          final newConstraints = List<String>.from(result['constraints'] ?? []);

          provider.updateField((data) {
            final fep = data.frontEndPlanning;
            final updatedFep = fep.copyWith(riskRegisterItems: newRisks);
            return data.copyWith(
              frontEndPlanning: updatedFep,
              constraints: newConstraints,
            );
          });
        }
      } else if (sectionType == 'tech') {
        final result = await _openAi.generateTechnicalRequirements(
          context: contextText,
        );
        if (mounted) {
          final it = result['it'] as ITConsiderationsData?;
          final infra = result['infra'] as InfrastructureConsiderationsData?;
          if (it != null || infra != null) {
            provider.updateField((data) => data.copyWith(
                  itConsiderationsData: it ?? data.itConsiderationsData,
                  infrastructureConsiderationsData:
                      infra ?? data.infrastructureConsiderationsData,
                ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _projectData = provider.projectData;
        });
      }
    } catch (e) {
      debugPrint('Error generating $sectionType: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate $sectionType: $e')),
        );
      }
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
                          final confirmed =
                              await showRegenerateAllConfirmation(context);
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
                    nextLabel: 'Next',
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
            const Icon(Icons.desktop_mac_outlined,
                size: 64, color: Colors.grey),
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

    // New Refactored Layout with width constraint
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 0. Executive Snapshot (New Upgrade)
            CharterExecutiveSnapshot(data: _projectData),

            // 1. Executive Summary (General Info Header)
            CharterExecutiveSummary(data: _projectData),
            const SizedBox(height: 24),

            // Main Content Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN (Narrative & Technical - 60%)
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      CharterProjectDefinition(
                        data: _projectData,
                        onGenerate: () => _generateSection('definition'),
                      ),
                      const SizedBox(height: 24),
                      CharterScope(
                        data: _projectData,
                        onGenerate: () => _generateSection('scope'),
                      ),
                      const SizedBox(height: 24),
                      // Key Risks & Constraints - Enhanced Left Panel
                      CharterRisks(
                        data: _projectData,
                        onGenerate: () => _generateSection('risks'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // RIGHT COLUMN (Analysis, Governance & Timeline - 40%)
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      // NEW Financial Overview Panel (Replaces Snapshot + Cost Chart)
                      CharterFinancialOverview(data: _projectData),
                      const SizedBox(height: 24),
                      // Timeline & Schedule
                      CharterScheduleTable(data: _projectData),
                      const SizedBox(height: 16),
                      CharterMilestoneVisualizer(data: _projectData),
                      const SizedBox(height: 16),
                      CharterAssumptions(data: _projectData),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CharterTechnicalEnvironment(
              data: _projectData,
              onGenerate: () => _generateSection('tech'),
            ),
            const SizedBox(height: 24),
            // NEW GOVERNANCE SECTION (Full Width)
            CharterGovernanceSection(data: _projectData),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
