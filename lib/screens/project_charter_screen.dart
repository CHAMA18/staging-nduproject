import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/theme.dart';
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
  final TextEditingController _projectManagerController =
      TextEditingController();
  final TextEditingController _projectSponsorController =
      TextEditingController();
  bool _isSavingNames = false;

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
        _projectManagerController.text =
            provider.projectData.charterProjectManagerName;
        _projectSponsorController.text =
            provider.projectData.charterProjectSponsorName;

        // Auto-generate charter content if needed
        if (_projectData != null) {
          await _ensureCharterContent();
        }
      }
    });
  }

  @override
  void dispose() {
    _projectManagerController.dispose();
    _projectSponsorController.dispose();
    super.dispose();
  }

  Future<void> _regenerateAllCharter() async {
    if (_projectData == null) return;
    // Reset content to trigger regeneration
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

    // Check if we need to generate content
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
        // Generate overview if needed
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

        // Generate goals if needed
        if (needsGoals) {
          try {
            final goalsText = await _openAi.generateFepSectionText(
              section: 'Project Goals and Objectives',
              context: projectContext,
              maxTokens: 500,
            );

            // Parse goals from text and add to project goals
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
                  // Remove bullet points if present
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

        // Generate assumptions/constraints if needed (read-only in UI)
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
      backgroundColor: AppSemanticColors.subtle,
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
                  top: pagePadding + (isMobile ? 16 : 32), bottom: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Project Charter',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: isMobile ? 24 : 32,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
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
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: _CharterContent(
                      isStacked: isMobile,
                      projectData: _projectData,
                      projectManagerController: _projectManagerController,
                      projectSponsorController: _projectSponsorController,
                      isSavingNames: _isSavingNames,
                      onSaveNames: () async {
                        if (!mounted) return;
                        setState(() => _isSavingNames = true);
                        final provider = ProjectDataInherited.of(context);
                        provider.updateField(
                          (data) => data.copyWith(
                            charterProjectManagerName:
                                _projectManagerController.text.trim(),
                            charterProjectSponsorName:
                                _projectSponsorController.text.trim(),
                          ),
                        );
                        await provider.saveToFirebase(
                            checkpoint: 'project_charter');
                        if (mounted) {
                          setState(() {
                            _isSavingNames = false;
                            _projectData = provider.projectData;
                          });
                        }
                      },
                      onProjectDataChanged: () {
                        if (mounted) {
                          final provider = ProjectDataInherited.of(context);
                          setState(() {
                            _projectData = provider.projectData;
                          });
                        }
                      },
                    ),
                  ),
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
}

class _CharterContent extends StatelessWidget {
  const _CharterContent({
    required this.isStacked,
    required this.projectData,
    required this.projectManagerController,
    required this.projectSponsorController,
    required this.isSavingNames,
    required this.onSaveNames,
    required this.onProjectDataChanged,
  });

  final bool isStacked;
  final ProjectDataModel? projectData;
  final TextEditingController projectManagerController;
  final TextEditingController projectSponsorController;
  final bool isSavingNames;
  final Future<void> Function() onSaveNames;
  final VoidCallback onProjectDataChanged;

  @override
  Widget build(BuildContext context) {
    if (isStacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CharterSummaryPanel(
            isStacked: true,
            projectData: projectData,
            projectManagerController: projectManagerController,
            projectSponsorController: projectSponsorController,
            isSavingNames: isSavingNames,
            onSaveNames: onSaveNames,
          ),
          const Divider(height: 1, color: AppSemanticColors.border),
          _CharterDetailsPanel(
            isStacked: true,
            projectData: projectData,
            onProjectDataChanged: onProjectDataChanged,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CharterSummaryPanel(
          isStacked: false,
          projectData: projectData,
          projectManagerController: projectManagerController,
          projectSponsorController: projectSponsorController,
          isSavingNames: isSavingNames,
          onSaveNames: onSaveNames,
        ),
        Expanded(
            child: _CharterDetailsPanel(
          isStacked: false,
          projectData: projectData,
          onProjectDataChanged: onProjectDataChanged,
        )),
      ],
    );
  }
}

class _CharterSummaryPanel extends StatelessWidget {
  const _CharterSummaryPanel(
      {required this.isStacked,
      required this.projectData,
      required this.projectManagerController,
      required this.projectSponsorController,
      required this.isSavingNames,
      required this.onSaveNames});

  final bool isStacked;
  final ProjectDataModel? projectData;
  final TextEditingController projectManagerController;
  final TextEditingController projectSponsorController;
  final bool isSavingNames;
  final Future<void> Function() onSaveNames;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final borderRadius = isStacked
        ? const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24))
        : const BorderRadius.only(
            topLeft: Radius.circular(24), bottomLeft: Radius.circular(24));

    return Container(
      width: isMobile ? double.infinity : 300,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Charter',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 24),
          _EditableSummaryField(
            label: 'Project Manager',
            controller: projectManagerController,
            placeholder: _extractProjectManager(projectData),
            onChanged: (_) => onSaveNames(),
          ),
          _EditableSummaryField(
            label: 'Project Sponsor',
            controller: projectSponsorController,
            placeholder: _extractProjectSponsor(projectData),
            onChanged: (_) => onSaveNames(),
          ),
          if (isSavingNames) ...[
            const SizedBox(height: 6),
            Text(
              'Saving…',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ],
          _SummaryRow(
            label: 'Start Date',
            value: _formatDate(projectData?.createdAt) ?? 'Not specified',
          ),
          _SummaryRow(
            label: 'Estimated End Date',
            value: _extractEndDate(projectData),
          ),
          _SummaryRow(
            label: 'Estimated Project Cost',
            value: _extractTotalCost(projectData),
          ),
          const SizedBox(height: 32),
          Text(
            'Project Budget',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 20),
          _ProjectBudgetChart(projectData: projectData),
          const SizedBox(height: 24),
          _BudgetLegend(projectData: projectData),
        ],
      ),
    );
  }

  static String _extractProjectManager(ProjectDataModel? data) {
    if (data == null) return 'Add Name Here';
    if (data.charterProjectManagerName.trim().isNotEmpty) {
      return data.charterProjectManagerName.trim();
    }

    // Try to find Project Manager from team members
    final manager = data.teamMembers.firstWhere(
      (m) =>
          m.role.toLowerCase().contains('manager') ||
          m.role.toLowerCase().contains('pm'),
      orElse: () => TeamMember(),
    );

    if (manager.name.isNotEmpty) return manager.name;
    return 'Add Name Here';
  }

  static String _extractProjectSponsor(ProjectDataModel? data) {
    if (data == null) return 'Add Name Here';
    if (data.charterProjectSponsorName.trim().isNotEmpty) {
      return data.charterProjectSponsorName.trim();
    }

    // Try to find Project Sponsor from team members
    final sponsor = data.teamMembers.firstWhere(
      (m) => m.role.toLowerCase().contains('sponsor'),
      orElse: () => TeamMember(),
    );

    if (sponsor.name.isNotEmpty) return sponsor.name;
    return 'Add Name Here';
  }

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String _extractEndDate(ProjectDataModel? data) {
    if (data == null) return 'Not specified';

    // Try to get the latest milestone date
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
          return _formatDate(date) ?? latestMilestone.dueDate;
        } catch (e) {
          return latestMilestone.dueDate;
        }
      }
    }

    return 'Not specified';
  }

  static String _extractTotalCost(ProjectDataModel? data) {
    if (data == null) return 'Not calculated';

    // Sum up costs from preferred solution analysis
    double totalCost = 0.0;

    if (data.preferredSolutionAnalysis != null) {
      for (final analysis in data.preferredSolutionAnalysis!.solutionAnalyses) {
        for (final cost in analysis.costs) {
          totalCost += cost.estimatedCost;
        }
      }
    }

    // Add cost analysis data if available
    if (data.costAnalysisData != null) {
      for (final solution in data.costAnalysisData!.solutionCosts) {
        for (final row in solution.costRows) {
          final costStr = row.cost.replaceAll(RegExp(r'[^\d.]'), '');
          final cost = double.tryParse(costStr) ?? 0.0;
          totalCost += cost;
        }
      }
    }

    if (totalCost > 0) {
      return '\$${totalCost.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (match) => ',',
          )}';
    }

    return 'Not calculated';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: AppSemanticColors.border),
        ],
      ),
    );
  }
}

class _EditableSummaryField extends StatelessWidget {
  const _EditableSummaryField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: placeholder,
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withValues(alpha: 0.7),
                  ),
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppSemanticColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppSemanticColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 1.4),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: AppSemanticColors.border),
        ],
      ),
    );
  }
}

class _ProjectBudgetChart extends StatelessWidget {
  const _ProjectBudgetChart({required this.projectData});

  final ProjectDataModel? projectData;

  @override
  Widget build(BuildContext context) {
    final slices = _extractBudgetSlices(projectData);
    final totalPercentage =
        slices.fold<double>(0.0, (sum, slice) => sum + slice.value);

    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: CustomPaint(
          painter: _DonutChartPainter(
            slices: slices,
            innerColor: Theme.of(context).colorScheme.surface,
            palette: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.tertiary,
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
              Theme.of(context).colorScheme.tertiaryContainer,
              Theme.of(context).colorScheme.inversePrimary,
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Budget',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalPercentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static List<_ChartSlice> _extractBudgetSlices(ProjectDataModel? data) {
    // Colors will be attached later based on theme; default slice with placeholder
    if (data == null) {
      return const [
        _ChartSlice(color: Colors.transparent, value: 100, label: 'No data'),
      ];
    }

    final Map<String, double> costBreakdown = {};

    // Extract costs from preferred solution analysis
    if (data.preferredSolutionAnalysis != null) {
      for (final analysis in data.preferredSolutionAnalysis!.solutionAnalyses) {
        for (final cost in analysis.costs) {
          final key = cost.item.isEmpty ? 'Miscellaneous' : cost.item;
          costBreakdown[key] = (costBreakdown[key] ?? 0.0) + cost.estimatedCost;
        }
      }
    }

    // Extract from cost analysis data
    if (data.costAnalysisData != null) {
      for (final solution in data.costAnalysisData!.solutionCosts) {
        for (final row in solution.costRows) {
          final costStr = row.cost.replaceAll(RegExp(r'[^\d.]'), '');
          final cost = double.tryParse(costStr) ?? 0.0;
          final key = row.itemName.isEmpty ? 'Miscellaneous' : row.itemName;
          costBreakdown[key] = (costBreakdown[key] ?? 0.0) + cost;
        }
      }
    }

    if (costBreakdown.isEmpty) {
      return const [
        _ChartSlice(color: Colors.transparent, value: 100, label: 'No data'),
      ];
    }

    // Convert to slices
    final totalCost =
        costBreakdown.values.fold<double>(0.0, (sum, val) => sum + val);
    if (totalCost == 0) {
      return const [
        _ChartSlice(color: Colors.transparent, value: 100, label: 'No data'),
      ];
    }

    final entries = costBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final slices = <_ChartSlice>[];
    double remainingPercentage = 100.0;

    // Take top 7 items, ensuring percentages sum to 100%
    for (int i = 0; i < entries.length && i < 7; i++) {
      final entry = entries[i];
      final percentage = (entry.value / totalCost) * 100;

      // For the last item, use remaining percentage to ensure total is 100%
      if (i == entries.length - 1 || i == 6) {
        slices.add(_ChartSlice(
          color: Colors.transparent,
          value: remainingPercentage,
          label: entry.key,
        ));
        break;
      }

      slices.add(_ChartSlice(
        color: Colors.transparent,
        value: percentage,
        label: entry.key,
      ));
      remainingPercentage -= percentage;
    }

    return slices;
  }
}

class _BudgetLegend extends StatelessWidget {
  const _BudgetLegend({required this.projectData});

  final ProjectDataModel? projectData;

  @override
  Widget build(BuildContext context) {
    final slices = _ProjectBudgetChart._extractBudgetSlices(projectData);
    final palette = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.primaryContainer,
      Theme.of(context).colorScheme.secondaryContainer,
      Theme.of(context).colorScheme.tertiaryContainer,
      Theme.of(context).colorScheme.inversePrimary,
    ];

    // Map slices to consistent legend colors
    final entries = <_ChartSlice>[];
    for (int i = 0; i < slices.length; i++) {
      final s = slices[i];
      final color =
          s.color == Colors.transparent ? palette[i % palette.length] : s.color;
      entries.add(_ChartSlice(
        color: color,
        value: s.value,
        label: '${s.label} ${s.value.toStringAsFixed(0)}%',
      ));
    }

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 12, height: 12, color: entry.color),
              const SizedBox(width: 8),
              Text(
                entry.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
      ],
    );
  }
}

class _CharterDetailsPanel extends StatefulWidget {
  const _CharterDetailsPanel({
    required this.isStacked,
    required this.projectData,
    required this.onProjectDataChanged,
  });

  final bool isStacked;
  final ProjectDataModel? projectData;
  final VoidCallback onProjectDataChanged;

  @override
  State<_CharterDetailsPanel> createState() => _CharterDetailsPanelState();
}

class _CharterDetailsPanelState extends State<_CharterDetailsPanel> {
  late List<_EditableGoal> _goals;
  late List<_EditableMilestone> _milestones;
  bool _isGeneratingGoals = false;
  bool _isGeneratingMilestones = false;
  late final OpenAiServiceSecure _openAi;

  @override
  void initState() {
    super.initState();
    _openAi = OpenAiServiceSecure();
    _loadGoalsAndMilestones();
  }

  void _loadGoalsAndMilestones() {
    final data = widget.projectData;
    _goals = (data?.projectGoals ?? [])
        .map((g) => _EditableGoal(
              nameController: TextEditingController(text: g.name),
              descriptionController: TextEditingController(text: g.description),
            ))
        .toList();
    _milestones = (data?.keyMilestones ?? [])
        .map((m) => _EditableMilestone(
              nameController: TextEditingController(text: m.name),
              disciplineController: TextEditingController(text: m.discipline),
              dueDateController: TextEditingController(text: m.dueDate),
              commentsController: TextEditingController(text: m.comments),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final goal in _goals) {
      goal.nameController.dispose();
      goal.descriptionController.dispose();
    }
    for (final milestone in _milestones) {
      milestone.nameController.dispose();
      milestone.disciplineController.dispose();
      milestone.dueDateController.dispose();
      milestone.commentsController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveGoalsAndMilestones() async {
    final provider = ProjectDataInherited.of(context);
    final goals = _goals
        .map((g) => ProjectGoal(
              name: g.nameController.text.trim(),
              description: g.descriptionController.text.trim(),
            ))
        .where((g) => g.name.isNotEmpty)
        .toList();
    final milestones = _milestones
        .map((m) => Milestone(
              name: m.nameController.text.trim(),
              discipline: m.disciplineController.text.trim(),
              dueDate: m.dueDateController.text.trim(),
              comments: m.commentsController.text.trim(),
            ))
        .where((m) => m.name.isNotEmpty)
        .toList();

    provider.updateField((data) => data.copyWith(
          projectGoals: goals,
          keyMilestones: milestones,
        ));
    await provider.saveToFirebase(checkpoint: 'project_charter');
    widget.onProjectDataChanged();
  }

  void _addGoal() {
    setState(() {
      _goals.add(_EditableGoal(
        nameController: TextEditingController(),
        descriptionController: TextEditingController(),
      ));
    });
    _saveGoalsAndMilestones();
  }

  void _deleteGoal(int index) {
    if (index < 0 || index >= _goals.length) return;
    setState(() {
      _goals[index].nameController.dispose();
      _goals[index].descriptionController.dispose();
      _goals.removeAt(index);
    });
    _saveGoalsAndMilestones();
  }

  void _addMilestone() {
    setState(() {
      _milestones.add(_EditableMilestone(
        nameController: TextEditingController(),
        disciplineController: TextEditingController(),
        dueDateController: TextEditingController(),
        commentsController: TextEditingController(),
      ));
    });
    _saveGoalsAndMilestones();
  }

  void _deleteMilestone(int index) {
    if (index < 0 || index >= _milestones.length) return;
    setState(() {
      _milestones[index].nameController.dispose();
      _milestones[index].disciplineController.dispose();
      _milestones[index].dueDateController.dispose();
      _milestones[index].commentsController.dispose();
      _milestones.removeAt(index);
    });
    _saveGoalsAndMilestones();
  }

  Future<void> _generateGoals() async {
    if (_isGeneratingGoals) return;
    setState(() => _isGeneratingGoals = true);

    try {
      final projectContext = ProjectDataHelper.buildFepContext(widget.projectData!);
      final goalsText = await _openAi.generateFepSectionText(
        section: 'Project Goals and Objectives',
        context: projectContext,
        maxTokens: 500,
      );

      if (mounted && goalsText.isNotEmpty) {
        final lines = goalsText
            .split('\n')
            .map((l) => l.trim())
            .where((l) =>
                l.isNotEmpty && !l.startsWith('-') && !l.startsWith('•'))
            .take(5)
            .toList();

        if (lines.isNotEmpty) {
          setState(() {
            // Dispose old controllers
            for (final goal in _goals) {
              goal.nameController.dispose();
              goal.descriptionController.dispose();
            }
            _goals.clear();

            // Add new goals
            for (final line in lines) {
              final cleanLine = line.replaceAll(RegExp(r'^[-•]\s*'), '');
              _goals.add(_EditableGoal(
                nameController: TextEditingController(
                  text: cleanLine.length > 50
                      ? cleanLine.substring(0, 50)
                      : cleanLine,
                ),
                descriptionController: TextEditingController(
                  text: cleanLine.length > 50 ? cleanLine : '',
                ),
              ));
            }
          });
          await _saveGoalsAndMilestones();
        }
      }
    } catch (e) {
      debugPrint('Error generating goals: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate goals: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingGoals = false);
      }
    }
  }

  Future<void> _generateMilestones() async {
    if (_isGeneratingMilestones) return;
    setState(() => _isGeneratingMilestones = true);

    try {
      final projectContext = ProjectDataHelper.buildFepContext(widget.projectData!);
      final milestonesText = await _openAi.generateFepSectionText(
        section: 'Project Milestones',
        context: projectContext,
        maxTokens: 400,
      );

      if (mounted && milestonesText.isNotEmpty) {
        final lines = milestonesText
            .split('\n')
            .map((l) => l.trim())
            .where((l) =>
                l.isNotEmpty && !l.startsWith('-') && !l.startsWith('•'))
            .take(5)
            .toList();

        if (lines.isNotEmpty) {
          setState(() {
            // Dispose old controllers
            for (final milestone in _milestones) {
              milestone.nameController.dispose();
              milestone.disciplineController.dispose();
              milestone.dueDateController.dispose();
              milestone.commentsController.dispose();
            }
            _milestones.clear();

            // Add new milestones
            for (final line in lines) {
              final cleanLine = line.replaceAll(RegExp(r'^[-•]\s*'), '');
              _milestones.add(_EditableMilestone(
                nameController: TextEditingController(text: cleanLine),
                disciplineController: TextEditingController(),
                dueDateController: TextEditingController(),
                commentsController: TextEditingController(),
              ));
            }
          });
          await _saveGoalsAndMilestones();
        }
      }
    } catch (e) {
      debugPrint('Error generating milestones: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate milestones: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingMilestones = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.isStacked
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))
        : const BorderRadius.only(
            topRight: Radius.circular(24), bottomRight: Radius.circular(24));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Name: ${_extractProjectName(widget.projectData)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 24),
          const _SectionHeading(title: 'Project Overview'),
          const SizedBox(height: 12),
          Text(
            _extractProjectOverview(widget.projectData),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: _SectionHeading(title: 'Goals / Key Objectives'),
              ),
              IconButton(
                icon: _isGeneratingGoals
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 20),
                tooltip: 'Generate goals with AI',
                onPressed: _isGeneratingGoals ? null : _generateGoals,
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                tooltip: 'Add goal',
                onPressed: _addGoal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_goals.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No goals yet. Click the + button to add a goal or use AI to generate.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < _goals.length; i++)
                  _EditableGoalCard(
                    goal: _goals[i],
                    index: i,
                    onDelete: () => _deleteGoal(i),
                    onChanged: _saveGoalsAndMilestones,
                  ),
              ],
            ),
          const SizedBox(height: 32),
          _AssumptionsConstraintsRisksTable(
            projectData: widget.projectData,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(
                child: _SectionHeading(title: 'Project Milestones'),
              ),
              IconButton(
                icon: _isGeneratingMilestones
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 20),
                tooltip: 'Generate milestones with AI',
                onPressed: _isGeneratingMilestones ? null : _generateMilestones,
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                tooltip: 'Add milestone',
                onPressed: _addMilestone,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_milestones.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No milestones yet. Click the + button to add a milestone or use AI to generate.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            _EditableMilestoneGrid(milestones: _milestones, onDelete: _deleteMilestone, onChanged: _saveGoalsAndMilestones),
        ],
      ),
    );
  }

  static String _extractProjectName(ProjectDataModel? data) {
    if (data == null) return 'Untitled Project';
    if (data.projectName.isNotEmpty) return data.projectName;
    if (data.solutionTitle.isNotEmpty) return data.solutionTitle;
    return 'Untitled Project';
  }

  static String _extractProjectOverview(ProjectDataModel? data) {
    if (data == null) {
      return 'This project charter outlines the key objectives, scope, and approach for delivering the proposed solution. The project aims to address identified business needs through a structured implementation approach, ensuring alignment with organizational goals and stakeholder expectations.';
    }

    final parts = <String>[];

    // Add business case
    if (data.businessCase.isNotEmpty) {
      parts.add(data.businessCase);
    }

    // Add solution description from preferred solution
    if (data.preferredSolutionAnalysis?.selectedSolutionTitle != null) {
      final analyses = data.preferredSolutionAnalysis!.solutionAnalyses;
      if (analyses.isNotEmpty) {
        final selectedSolution = analyses.firstWhere(
          (s) =>
              s.solutionTitle ==
              data.preferredSolutionAnalysis!.selectedSolutionTitle,
          orElse: () => analyses.first,
        );
        if (selectedSolution.solutionDescription.isNotEmpty) {
          parts.add(
              '\n\nSelected Solution: ${selectedSolution.solutionDescription}');
        }
      }
    } else if (data.solutionDescription.isNotEmpty) {
      parts.add('\n\n${data.solutionDescription}');
    }

    // Add project objective
    if (data.projectObjective.isNotEmpty) {
      parts.add('\n\nObjective: ${data.projectObjective}');
    }

    if (parts.isEmpty) {
      // Generate fallback overview
      final projectName = data.projectName.trim().isEmpty
          ? 'this project'
          : data.projectName.trim();
      return 'This project charter outlines the key objectives, scope, and approach for delivering $projectName. The project aims to address identified business needs through a structured implementation approach, ensuring alignment with organizational goals and stakeholder expectations. Key focus areas include delivering value-driven outcomes, managing risks effectively, and maintaining quality standards throughout the project lifecycle.';
    }

    return parts.join('');
  }

  static List<String> _extractGoals(ProjectDataModel? data) {
    if (data == null) {
      return [
        'Deliver the proposed solution within budget and timeline constraints',
        'Ensure alignment with organizational strategic objectives',
        'Maintain quality standards throughout project execution',
        'Manage project risks effectively and proactively',
      ];
    }

    final goals = <String>[];

    // Extract from project goals
    for (final goal in data.projectGoals) {
      if (goal.name.isNotEmpty) {
        goals.add(
            '${goal.name}${goal.description.isNotEmpty ? ': ${goal.description}' : ''}');
      }
    }

    // Extract from planning goals
    for (final goal in data.planningGoals) {
      if (goal.title.isNotEmpty) {
        goals.add(
            '${goal.title}${goal.description.isNotEmpty ? ': ${goal.description}' : ''}');
      }
    }

    if (goals.isEmpty) {
      // Provide fallback goals
      final projectName = data.projectName.trim().isEmpty
          ? 'the project'
          : data.projectName.trim();
      return [
        'Successfully deliver $projectName within established budget and timeline',
        'Ensure alignment with organizational strategic objectives and stakeholder expectations',
        'Maintain high quality standards throughout project execution',
        'Effectively manage and mitigate project risks',
        'Achieve defined project success criteria and deliverables',
      ];
    }

    return goals.take(10).toList();
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.6,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AssumptionsConstraintsRisksTable extends StatelessWidget {
  const _AssumptionsConstraintsRisksTable({
    required this.projectData,
  });

  final ProjectDataModel? projectData;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        );
    final border = BorderSide(color: Theme.of(context).dividerColor);

    final topRisks = _extractTopRisks(projectData);
    final assumptions = (projectData?.charterAssumptions ?? '').trim();
    final constraints = (projectData?.charterConstraints ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppSemanticColors.subtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _simpleSectionHeading(context, 'Assumptions'),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(140),
              1: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            border: TableBorder(
              horizontalInside: border,
              verticalInside: border,
            ),
            children: [
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Category', style: labelStyle),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Description / Detail', style: labelStyle),
                  ),
                ],
              ),
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Assumptions'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(assumptions.isEmpty ? '—' : assumptions),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _simpleSectionHeading(context, 'Constraints'),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(140),
              1: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            border: TableBorder(
              horizontalInside: border,
              verticalInside: border,
            ),
            children: [
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Constraints'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(constraints.isEmpty ? '—' : constraints),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _simpleSectionHeading(context, 'Risks'),
          const Divider(height: 18),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(240),
              1: FixedColumnWidth(140),
              2: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            border: TableBorder(
              horizontalInside: border,
              verticalInside: border,
            ),
            children: [
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Risk Name', style: labelStyle),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Impact Level', style: labelStyle),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Mitigation Strategy', style: labelStyle),
                  ),
                ],
              ),
              ...topRisks.map((r) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(r.riskName.isEmpty ? '—' : r.riskName),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child:
                          Text(r.impactLevel.isEmpty ? '—' : r.impactLevel),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(r.mitigationStrategy.isEmpty
                          ? '—'
                          : r.mitigationStrategy),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _simpleSectionHeading(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }

  static List<RiskRegisterItem> _extractTopRisks(ProjectDataModel? data) {
    if (data == null) return const <RiskRegisterItem>[];

    // Prefer risks for the selected solution (keeps Charter concise and relevant).
    final selected = data.preferredSolutionAnalysis?.selectedSolutionTitle ?? '';
    final desired = <String>[];
    if (selected.trim().isNotEmpty) {
      final match = data.solutionRisks.cast<SolutionRisk?>().firstWhere(
            (r) =>
                (r?.solutionTitle ?? '').trim().toLowerCase() ==
                selected.trim().toLowerCase(),
            orElse: () => null,
          );
      if (match != null) {
        desired.addAll(
            match.risks.map((e) => e.trim()).where((e) => e.isNotEmpty));
      }
    }
    if (desired.isEmpty) {
      for (final sr in data.solutionRisks) {
        desired.addAll(sr.risks.map((e) => e.trim()).where((e) => e.isNotEmpty));
      }
    }

    final distinct = <String>[];
    for (final r in desired) {
      if (distinct.length >= 3) break;
      final k = r.toLowerCase();
      if (distinct.any((e) => e.toLowerCase() == k)) continue;
      distinct.add(r);
    }

    // Enrich from structured risk register if present.
    final register = data.frontEndPlanning.riskRegisterItems;
    return distinct.map((name) {
      final found = register.cast<RiskRegisterItem?>().firstWhere(
            (item) => (item?.riskName ?? '')
                .trim()
                .toLowerCase()
                .contains(name.trim().toLowerCase()),
            orElse: () => null,
          );
      return RiskRegisterItem(
        riskName: name,
        impactLevel: (found?.impactLevel ?? '').trim().isNotEmpty
            ? found!.impactLevel.trim()
            : 'Medium',
        mitigationStrategy: (found?.mitigationStrategy ?? '').trim().isNotEmpty
            ? found!.mitigationStrategy.trim()
            : 'Define mitigation plan, assign an owner, and monitor triggers.',
      );
    }).toList();
  }
}

class _MilestoneGrid extends StatelessWidget {
  const _MilestoneGrid({required this.projectData});

  final ProjectDataModel? projectData;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final milestones = _extractMilestones(projectData);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final milestone in milestones)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _MilestoneTile(milestone: milestone),
            ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < milestones.length; i++)
          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(right: i == milestones.length - 1 ? 0 : 18),
              child: _MilestoneTile(milestone: milestones[i]),
            ),
          ),
      ],
    );
  }

  static List<_MilestoneData> _extractMilestones(ProjectDataModel? data) {
    if (data == null) {
      final now = DateTime.now();
      return [
        _MilestoneData(
          title: 'Project Initiation',
          description:
              'Due: ${DateFormat('MMM dd, yyyy').format(now.add(const Duration(days: 30)))}',
        ),
        _MilestoneData(
          title: 'Planning Completion',
          description:
              'Due: ${DateFormat('MMM dd, yyyy').format(now.add(const Duration(days: 60)))}',
        ),
        _MilestoneData(
          title: 'Design Phase',
          description:
              'Due: ${DateFormat('MMM dd, yyyy').format(now.add(const Duration(days: 90)))}',
        ),
        _MilestoneData(
          title: 'Implementation Start',
          description:
              'Due: ${DateFormat('MMM dd, yyyy').format(now.add(const Duration(days: 120)))}',
        ),
      ];
    }

    final milestones = <_MilestoneData>[];

    // Extract from key milestones
    for (final milestone in data.keyMilestones) {
      if (milestone.name.isNotEmpty) {
        final description = [
          if (milestone.discipline.isNotEmpty)
            'Discipline: ${milestone.discipline}',
          if (milestone.dueDate.isNotEmpty) 'Due: ${milestone.dueDate}',
          if (milestone.comments.isNotEmpty) milestone.comments,
        ].join(' • ');

        milestones.add(_MilestoneData(
          title: milestone.name,
          description:
              description.isNotEmpty ? description : 'No description available',
        ));
      }
    }

    // Extract from planning goals milestones
    for (final goal in data.planningGoals) {
      for (final milestone in goal.milestones) {
        if (milestone.title.isNotEmpty) {
          final description = milestone.deadline.isNotEmpty
              ? 'Due: ${milestone.deadline}'
              : 'No deadline specified';

          milestones.add(_MilestoneData(
            title: milestone.title,
            description: description,
          ));
        }
      }
    }

    if (milestones.isEmpty) {
      // Provide fallback milestones
      final now = DateTime.now();
      final projectName =
          data.projectName.trim().isEmpty ? 'Project' : data.projectName.trim();
      return [
        _MilestoneData(
          title: '$projectName Initiation',
          description:
              'Due: ${DateFormat('MMM dd, yyyy').format(now.add(const Duration(days: 30)))}',
        ),
        _MilestoneData(
          title: 'Planning Phase Completion',
          description:
              'Due: ${DateFormat('MMM dd, yyyy').format(now.add(const Duration(days: 60)))}',
        ),
        _MilestoneData(
          title: 'Design Phase Completion',
          description:
              'Due: ${DateFormat('MMM dd, yyyy').format(now.add(const Duration(days: 90)))}',
        ),
        _MilestoneData(
          title: 'Implementation Start',
          description:
              'Due: ${DateFormat('MMM dd, yyyy').format(now.add(const Duration(days: 120)))}',
        ),
      ];
    }

    return milestones.take(8).toList();
  }
}

class _MilestoneData {
  const _MilestoneData({required this.title, required this.description});

  final String title;
  final String description;
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.milestone});

  final _MilestoneData milestone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          milestone.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          milestone.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}

class _ChartSlice {
  const _ChartSlice(
      {required this.color, required this.value, required this.label});

  final Color color;
  final double value;
  final String label;
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.slices,
    required this.innerColor,
    required this.palette,
  });

  final List<_ChartSlice> slices;
  final Color innerColor;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    if (total == 0) {
      return;
    }

    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final strokeWidth = radius * 0.48;
    final arcRect = Rect.fromCircle(center: center, radius: radius * 0.8);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweepAngle = (slice.value / total) * math.pi * 2;
      // If slice color is transparent (placeholder), rotate through a pleasant palette
      paint.color = slice.color == Colors.transparent
          ? palette[i % palette.length]
          : slice.color;
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.42, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EditableGoal {
  _EditableGoal({
    required this.nameController,
    required this.descriptionController,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
}

class _EditableMilestone {
  _EditableMilestone({
    required this.nameController,
    required this.disciplineController,
    required this.dueDateController,
    required this.commentsController,
  });

  final TextEditingController nameController;
  final TextEditingController disciplineController;
  final TextEditingController dueDateController;
  final TextEditingController commentsController;
}

class _EditableGoalCard extends StatelessWidget {
  const _EditableGoalCard({
    required this.goal,
    required this.index,
    required this.onDelete,
    required this.onChanged,
  });

  final _EditableGoal goal;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: goal.nameController,
                  decoration: InputDecoration(
                    hintText: 'Goal name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (_) => onChanged(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: goal.descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Goal description (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  onChanged: (_) => onChanged(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete goal',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EditableMilestoneGrid extends StatelessWidget {
  const _EditableMilestoneGrid({
    required this.milestones,
    required this.onDelete,
    required this.onChanged,
  });

  final List<_EditableMilestone> milestones;
  final void Function(int) onDelete;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < milestones.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EditableMilestoneCard(
                milestone: milestones[i],
                index: i,
                onDelete: () => onDelete(i),
                onChanged: onChanged,
              ),
            ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (int i = 0; i < milestones.length; i++)
          SizedBox(
            width: (MediaQuery.of(context).size.width - 120) / 3,
            child: _EditableMilestoneCard(
              milestone: milestones[i],
              index: i,
              onDelete: () => onDelete(i),
              onChanged: onChanged,
            ),
          ),
      ],
    );
  }
}

class _EditableMilestoneCard extends StatelessWidget {
  const _EditableMilestoneCard({
    required this.milestone,
    required this.index,
    required this.onDelete,
    required this.onChanged,
  });

  final _EditableMilestone milestone;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: milestone.nameController,
                  decoration: InputDecoration(
                    hintText: 'Milestone name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.red),
                tooltip: 'Delete milestone',
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: milestone.disciplineController,
            decoration: InputDecoration(
              hintText: 'Discipline',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: milestone.dueDateController,
            decoration: InputDecoration(
              hintText: 'Due date (YYYY-MM-DD)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            style: const TextStyle(fontSize: 12, color: Colors.blue),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: milestone.commentsController,
            decoration: InputDecoration(
              hintText: 'Comments',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}
