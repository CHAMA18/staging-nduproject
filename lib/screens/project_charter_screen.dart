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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = ProjectDataInherited.of(context);
      if (mounted) {
        setState(() {
          _projectData = provider.projectData;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pagePadding = AppBreakpoints.pagePadding(context);
    final isMobile = AppBreakpoints.isMobile(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Project Charter',
      backgroundColor: AppSemanticColors.subtle,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(pagePadding).copyWith(top: pagePadding + (isMobile ? 16 : 32), bottom: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Project Charter',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: isMobile ? 24 : 32,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: _CharterContent(isStacked: isMobile, projectData: _projectData),
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
  const _CharterContent({required this.isStacked, required this.projectData});

  final bool isStacked;
  final ProjectDataModel? projectData;

  @override
  Widget build(BuildContext context) {
    if (isStacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CharterSummaryPanel(isStacked: true, projectData: projectData),
          const Divider(height: 1, color: AppSemanticColors.border),
          _CharterDetailsPanel(isStacked: true, projectData: projectData),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CharterSummaryPanel(isStacked: false, projectData: projectData),
        Expanded(child: _CharterDetailsPanel(isStacked: false, projectData: projectData)),
      ],
    );
  }
}

class _CharterSummaryPanel extends StatelessWidget {
  const _CharterSummaryPanel({required this.isStacked, required this.projectData});

  final bool isStacked;
  final ProjectDataModel? projectData;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final borderRadius = isStacked
        ? const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))
        : const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24));

    return Container(
      width: isMobile ? double.infinity : 300,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        // Use themed primary container for the left summary panel
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
          _SummaryRow(
            label: 'Project Manager',
            value: _extractProjectManager(projectData),
          ),
          _SummaryRow(
            label: 'Project Sponsor',
            value: _extractProjectSponsor(projectData),
          ),
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
    
    // Try to find Project Manager from team members
    final manager = data.teamMembers.firstWhere(
      (m) => m.role.toLowerCase().contains('manager') || m.role.toLowerCase().contains('pm'),
      orElse: () => TeamMember(),
    );
    
    if (manager.name.isNotEmpty) return manager.name;
    return 'Add Name Here';
  }

  static String _extractProjectSponsor(ProjectDataModel? data) {
    if (data == null) return 'Add Name Here';
    
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
        return latestMilestone.dueDate;
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
        RegExp(r'\\B(?=(\\d{3})+(?!\\d))'),
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

class _ProjectBudgetChart extends StatelessWidget {
  const _ProjectBudgetChart({required this.projectData});

  final ProjectDataModel? projectData;

  @override
  Widget build(BuildContext context) {
    final slices = _extractBudgetSlices(projectData);

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
                  '100%',
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
          final costStr = row.cost.replaceAll(RegExp(r'[^\\d.]'), '');
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
    final totalCost = costBreakdown.values.fold<double>(0.0, (sum, val) => sum + val);
    final entries = costBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final slices = <_ChartSlice>[];
    for (int i = 0; i < entries.length && i < 7; i++) {
      final entry = entries[i];
      final percentage = (entry.value / totalCost) * 100;
      // Temporarily set transparent color; will be mapped in painter using theme
      slices.add(_ChartSlice(
        color: Colors.transparent,
        value: percentage,
        label: entry.key,
      ));
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
      final color = s.color == Colors.transparent ? palette[i % palette.length] : s.color;
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

class _CharterDetailsPanel extends StatelessWidget {
  const _CharterDetailsPanel({required this.isStacked, required this.projectData});

  final bool isStacked;
  final ProjectDataModel? projectData;

  @override
  Widget build(BuildContext context) {
    final borderRadius = isStacked
        ? const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))
        : const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24));

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
            'Project Name: ${_extractProjectName(projectData)}',
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
            _extractProjectOverview(projectData),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 24),
          const _SectionHeading(title: 'Goals / Key Objectives'),
          const SizedBox(height: 12),
          _BulletList(items: _extractGoals(projectData)),
          const SizedBox(height: 32),
          _CardRow(projectData: projectData),
          const SizedBox(height: 32),
          const _SectionHeading(title: 'Project Milestones'),
          const SizedBox(height: 16),
          _MilestoneGrid(projectData: projectData),
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
    if (data == null) return 'No project overview available. Please complete the business case section to generate a comprehensive project charter.';
    
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
          (s) => s.solutionTitle == data.preferredSolutionAnalysis!.selectedSolutionTitle,
          orElse: () => analyses.first,
        );
        if (selectedSolution.solutionDescription.isNotEmpty) {
          parts.add('\\n\\nSelected Solution: ${selectedSolution.solutionDescription}');
        }
      }
    } else if (data.solutionDescription.isNotEmpty) {
      parts.add('\\n\\n${data.solutionDescription}');
    }
    
    // Add project objective
    if (data.projectObjective.isNotEmpty) {
      parts.add('\\n\\nObjective: ${data.projectObjective}');
    }
    
    if (parts.isEmpty) {
      return 'No project overview available. Please complete the business case section to generate a comprehensive project charter.';
    }
    
    return parts.join('');
  }

  static List<String> _extractGoals(ProjectDataModel? data) {
    if (data == null) return ['Define project goals in the planning phase'];
    
    final goals = <String>[];
    
    // Extract from project goals
    for (final goal in data.projectGoals) {
      if (goal.name.isNotEmpty) {
        goals.add('${goal.name}${goal.description.isNotEmpty ? ': ${goal.description}' : ''}');
      }
    }
    
    // Extract from planning goals
    for (final goal in data.planningGoals) {
      if (goal.title.isNotEmpty) {
        goals.add('${goal.title}${goal.description.isNotEmpty ? ': ${goal.description}' : ''}');
      }
    }
    
    if (goals.isEmpty) {
      return ['Define project goals in the planning phase'];
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
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
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

class _CardRow extends StatelessWidget {
  const _CardRow({required this.projectData});

  final ProjectDataModel? projectData;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final cards = _extractCardData(projectData);

    if (isMobile) {
      return Column(
        children: [
          for (final data in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _InfoCard(data: data),
            ),
        ],
      );
    }

    // Stack the info cards vertically so Assumptions / Constraints / Risks appear
    // on top of each other instead of side-by-side.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < cards.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == cards.length - 1 ? 0 : 18),
            child: _InfoCard(data: cards[i]),
          ),
      ],
    );
  }

  static List<_CardData> _extractCardData(ProjectDataModel? data) {
    if (data == null) {
      return const [
        _CardData(title: 'Assumptions', bullets: ['Complete business case to populate']),
        _CardData(title: 'Constraints', bullets: ['Complete business case to populate']),
        _CardData(title: 'Risks', bullets: ['Complete business case to populate']),
      ];
    }

    // Extract assumptions (from cost analysis or notes)
    final assumptions = <String>[];
    if (data.costAnalysisData != null) {
      for (final solution in data.costAnalysisData!.solutionCosts) {
        for (final row in solution.costRows) {
          if (row.assumptions.isNotEmpty) {
            assumptions.add(row.assumptions);
          }
        }
      }
    }
    if (assumptions.isEmpty) {
      assumptions.add('No specific assumptions documented');
    }

    // Extract constraints (from infrastructure, IT, or general notes)
    final constraints = <String>[];
    if (data.infrastructureConsiderationsData != null) {
      for (final infra in data.infrastructureConsiderationsData!.solutionInfrastructureData) {
        if (infra.majorInfrastructure.isNotEmpty) {
          constraints.add('Infrastructure: ${infra.majorInfrastructure}');
        }
      }
    }
    if (data.itConsiderationsData != null) {
      for (final it in data.itConsiderationsData!.solutionITData) {
        if (it.coreTechnology.isNotEmpty) {
          constraints.add('Technology: ${it.coreTechnology}');
        }
      }
    }
    if (constraints.isEmpty) {
      constraints.add('No specific constraints documented');
    }

    // Extract risks
    final risks = <String>[];
    if (data.preferredSolutionAnalysis != null) {
      for (final analysis in data.preferredSolutionAnalysis!.solutionAnalyses) {
        risks.addAll(analysis.risks.where((r) => r.isNotEmpty));
      }
    }
    for (final risk in data.solutionRisks) {
      risks.addAll(risk.risks.where((r) => r.isNotEmpty));
    }
    if (risks.isEmpty) {
      risks.add('No specific risks identified');
    }

    return [
      _CardData(title: 'Assumptions', bullets: assumptions.take(5).toList()),
      _CardData(title: 'Constraints', bullets: constraints.take(5).toList()),
      _CardData(title: 'Risks', bullets: risks.take(5).toList()),
    ];
  }
}

class _CardData {
  const _CardData({required this.title, required this.bullets});

  final String title;
  final List<String> bullets;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.data});

  final _CardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppSemanticColors.subtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          _BulletList(items: data.bullets),
        ],
      ),
    );
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
              padding: EdgeInsets.only(right: i == milestones.length - 1 ? 0 : 18),
              child: _MilestoneTile(milestone: milestones[i]),
            ),
          ),
      ],
    );
  }

  static List<_MilestoneData> _extractMilestones(ProjectDataModel? data) {
    if (data == null) {
      return const [
        _MilestoneData(title: 'Milestone 1', description: 'Define milestones in the planning phase'),
        _MilestoneData(title: 'Milestone 2', description: 'Define milestones in the planning phase'),
        _MilestoneData(title: 'Milestone 3', description: 'Define milestones in the planning phase'),
        _MilestoneData(title: 'Milestone 4', description: 'Define milestones in the planning phase'),
      ];
    }

    final milestones = <_MilestoneData>[];
    
    // Extract from key milestones
    for (final milestone in data.keyMilestones) {
      if (milestone.name.isNotEmpty) {
        final description = [
          if (milestone.discipline.isNotEmpty) 'Discipline: ${milestone.discipline}',
          if (milestone.dueDate.isNotEmpty) 'Due: ${milestone.dueDate}',
          if (milestone.comments.isNotEmpty) milestone.comments,
        ].join(' • ');
        
        milestones.add(_MilestoneData(
          title: milestone.name,
          description: description.isNotEmpty ? description : 'No description available',
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
      return const [
        _MilestoneData(title: 'Milestone 1', description: 'Define milestones in the planning phase'),
        _MilestoneData(title: 'Milestone 2', description: 'Define milestones in the planning phase'),
        _MilestoneData(title: 'Milestone 3', description: 'Define milestones in the planning phase'),
        _MilestoneData(title: 'Milestone 4', description: 'Define milestones in the planning phase'),
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
  const _ChartSlice({required this.color, required this.value, required this.label});

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
