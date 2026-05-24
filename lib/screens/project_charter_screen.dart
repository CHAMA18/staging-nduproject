import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/project_framework_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/front_end_planning_navigation.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';

import 'package:ndu_project/screens/project_charter_sections.dart';
import 'package:ndu_project/screens/charter_governance_section.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';

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
      appBarTitle: 'Project Charter',
      backgroundColor: const Color(0xFFF7F9FB),
      floatingActionButton: const KazAiChatBubble(positioned: false),
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
          : Stack(
              children: [
                // Main scrollable content
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: pagePadding,
                    right: pagePadding,
                    top: pagePadding + (isMobile ? 16 : 24),
                    bottom: 120, // Space for floating approval bar
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ─── 1. Hero Header ───
                          CharterHeroHeader(
                            data: _projectData,
                            onRegenerateAll: () async {
                              final confirmed =
                                  await showRegenerateAllConfirmation(context);
                              if (confirmed && mounted) {
                                await _regenerateAllCharter();
                              }
                            },
                            isLoading: _isGenerating,
                          ),
                          const SizedBox(height: 24),

                          // ─── 2. Dashboard Stats Grid ───
                          CharterDashboardStats(data: _projectData),
                          const SizedBox(height: 24),

                          // ─── 3. Meta Info Horizontal Scroll ───
                          CharterMetaInfoScroll(data: _projectData),
                          const SizedBox(height: 24),

                          // ─── 4. Project Definition Bento (2-col grid) ───
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 768;
                              if (isWide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left column
                                    Expanded(
                                      child: Column(
                                        children: [
                                          CharterProjectDefinition(
                                            data: _projectData,
                                            onGenerate: () =>
                                                _generateSection('definition'),
                                          ),
                                          const SizedBox(height: 12),
                                          CharterSuccessCriteria(
                                              data: _projectData),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Right column
                                    Expanded(
                                      child: Column(
                                        children: [
                                          CharterFinancialOverview(
                                              data: _projectData),
                                          const SizedBox(height: 12),
                                          CharterScope(
                                            data: _projectData,
                                            onGenerate: () =>
                                                _generateSection('scope'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                              // Mobile: single column
                              return Column(
                                children: [
                                  CharterProjectDefinition(
                                    data: _projectData,
                                    onGenerate: () =>
                                        _generateSection('definition'),
                                  ),
                                  const SizedBox(height: 12),
                                  CharterFinancialOverview(data: _projectData),
                                  const SizedBox(height: 12),
                                  CharterSuccessCriteria(data: _projectData),
                                  const SizedBox(height: 12),
                                  CharterScope(
                                    data: _projectData,
                                    onGenerate: () =>
                                        _generateSection('scope'),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // ─── 5. Key Risks Section ───
                          CharterRisks(
                            data: _projectData,
                            onGenerate: () => _generateSection('risks'),
                          ),
                          const SizedBox(height: 24),

                          // ─── 6. Technical & Procurement Bento ───
                          CharterTechnicalProcurementBento(
                            data: _projectData,
                            onGenerate: () => _generateSection('tech'),
                          ),
                          const SizedBox(height: 24),

                          // ─── 7. Tentative Schedule Timeline ───
                          CharterScheduleTimeline(data: _projectData),
                          const SizedBox(height: 24),

                          // ─── 8. Governance Section ───
                          CharterGovernanceSection(data: _projectData),
                          const SizedBox(height: 24),

                          // ─── 9. Assumptions (Collapsible) ───
                          CharterAssumptions(data: _projectData),
                          const SizedBox(height: 32),

                          // ─── 10. Launch Phase Navigation ───
                          LaunchPhaseNavigation(
                            backLabel: 'Back',
                            nextLabel: 'Next',
                            onBack: () => FrontEndPlanningNavigation.goToPrevious(
                              context,
                              'project_charter',
                            ),
                            onNext: () => ProjectFrameworkScreen.open(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── Floating Approval Action Bar ───
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CharterFloatingApprovalBar(data: _projectData),
                ),
              ],
            ),
    );
  }
}
