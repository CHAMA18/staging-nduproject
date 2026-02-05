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
import 'package:ndu_project/screens/project_charter_sections.dart';
import 'package:ndu_project/screens/project_charter_sections_extended.dart';

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
      final provider = ProjectDataInherited.of(context);
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

    if (!needsOverview &&
        !needsGoals &&
        !needsAssumptions &&
        !needsConstraints) {
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
                  .where((l) =>
                      l.isNotEmpty && !l.startsWith('-') && !l.startsWith('•'))
                  .take(5)
                  .toList();

              if (lines.isNotEmpty) {
                final provider = ProjectDataInherited.of(context);
                final newGoals = lines.map((line) {
                  final cleanLine = line.replaceAll(RegExp(r'^[-•]\s*'), '');
                  return ProjectGoal(
                    name: cleanLine.length > 50
                        ? cleanLine.substring(0, 50)
                        : cleanLine,
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

    // New Refactored Layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Executive Summary
        CharterExecutiveSummary(data: _projectData),
        const SizedBox(height: 24),

        // 2. Visual Overview (Charts in Row)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: CharterTimelineChart(data: _projectData)),
            const SizedBox(width: 24),
            Expanded(child: CharterCostChart(data: _projectData)),
          ],
        ),
        const SizedBox(height: 24),

        // 3. Financial Snapshot
        CharterFinancialSnapshot(data: _projectData),
        const SizedBox(height: 24),

        // 4. Definition & Scope (Row)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: CharterProjectDefinition(data: _projectData)),
            const SizedBox(width: 24),
            Expanded(child: CharterScope(data: _projectData)),
          ],
        ),
        const SizedBox(height: 24),

        // 5. Risks
        CharterRisks(data: _projectData),
        const SizedBox(height: 24),

        // 6. IT & Infrastrucutre Considerations (Row)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: CharterITConsiderations(data: _projectData)),
            const SizedBox(width: 24),
            Expanded(
                child: CharterInfrastructureConsiderations(data: _projectData)),
          ],
        ),
        const SizedBox(height: 24),

        // 7. Schedule & Resources
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: CharterScheduleTable(data: _projectData)),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: CharterResources(data: _projectData)),
          ],
        ),
        const SizedBox(height: 24),

        // 8. Stakeholders
        CharterStakeholders(data: _projectData),
        const SizedBox(height: 48),

        // 9. Contractors & Vendors
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: CharterContractors(data: _projectData)),
            const SizedBox(width: 24),
            Expanded(child: CharterVendors(data: _projectData)),
          ],
        ),
        const SizedBox(height: 24),

        // 10. Security
        CharterSecurity(data: _projectData),
        const SizedBox(height: 24),

        // 11. Approvals
        CharterApprovals(data: _projectData),
        const SizedBox(height: 48),
      ],
    );
  }
}
