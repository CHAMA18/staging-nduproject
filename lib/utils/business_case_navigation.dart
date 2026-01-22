import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/screens/initiation_phase_screen.dart';
import 'package:ndu_project/screens/potential_solutions_screen.dart';
import 'package:ndu_project/screens/risk_identification_screen.dart';
import 'package:ndu_project/screens/it_considerations_screen.dart';
import 'package:ndu_project/screens/infrastructure_considerations_screen.dart';
import 'package:ndu_project/screens/core_stakeholders_screen.dart';
import 'package:ndu_project/screens/cost_analysis_screen.dart';
import 'package:ndu_project/screens/work_breakdown_structure_screen.dart';
import 'package:ndu_project/screens/project_framework_screen.dart';
import 'package:ndu_project/screens/preferred_solution_analysis_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

/// Manages navigation flow for Business Case screens
class BusinessCaseNavigation {
  /// List of all Business Case screens in order
  static const List<_BusinessCaseScreen> _screens = [
    _BusinessCaseScreen('Business Case', 0),
    _BusinessCaseScreen('Potential Solutions', 1),
    _BusinessCaseScreen('Risk Identification', 2),
    _BusinessCaseScreen('IT Considerations', 3),
    _BusinessCaseScreen('Infrastructure Considerations', 4),
    _BusinessCaseScreen('Core Stakeholders', 5),
    _BusinessCaseScreen('Cost Benefit Analysis & Financial Metrics', 6),
    _BusinessCaseScreen('Preferred Solution Analysis', 7),
    _BusinessCaseScreen('Work Breakdown Structure', 8),
    _BusinessCaseScreen('Project Details', 9),
  ];

  /// Get the index of a screen by its label
  static int? getScreenIndex(String label) {
    for (int i = 0; i < _screens.length; i++) {
      if (_screens[i].label == label) return i;
    }
    return null;
  }

  /// Navigate to the previous screen
  static void navigateBack(BuildContext context, String currentScreen) {
    final currentIndex = getScreenIndex(currentScreen);
    if (currentIndex == null || currentIndex == 0) return;

    final previousIndex = currentIndex - 1;
    _navigateToScreen(context, previousIndex);
  }

  /// Navigate to the next screen
  static void navigateForward(BuildContext context, String currentScreen) {
    final currentIndex = getScreenIndex(currentScreen);
    if (currentIndex == null || currentIndex >= _screens.length - 1) return;

    final nextIndex = currentIndex + 1;
    _navigateToScreen(context, nextIndex);
  }

  /// Build solution items for downstream screens (Risk, IT, Infra, Stakeholders, CBA).
  /// Mirrors InitiationLikeSidebar._buildSolutionItems so Back/Next navigation preserves data.
  static List<AiSolutionItem> _buildSolutionItems(ProjectDataModel data) {
    final potential = data.potentialSolutions
        .map((s) => AiSolutionItem(title: s.title.trim(), description: s.description.trim()))
        .where((s) => s.title.isNotEmpty || s.description.isNotEmpty)
        .toList();
    if (potential.isNotEmpty) return potential;

    final preferred = data.preferredSolutionAnalysis?.solutionAnalyses
            .map((s) => AiSolutionItem(
                title: s.solutionTitle.trim(), description: s.solutionDescription.trim()))
            .where((s) => s.title.isNotEmpty || s.description.isNotEmpty)
            .toList() ??
        [];
    if (preferred.isNotEmpty) return preferred;

    final fallbackTitle = data.solutionTitle.trim();
    final fallbackDescription = data.solutionDescription.trim();
    if (fallbackTitle.isNotEmpty || fallbackDescription.isNotEmpty) {
      return [AiSolutionItem(title: fallbackTitle, description: fallbackDescription)];
    }

    return [];
  }

  /// Navigate to a specific screen by index
  static void _navigateToScreen(BuildContext context, int index) {
    final projectData = ProjectDataHelper.getData(context);
    final solutions = _buildSolutionItems(projectData);

    Widget screen;
    switch (index) {
      case 0: // Business Case
        screen = const InitiationPhaseScreen(scrollToBusinessCase: true);
        break;
      case 1: // Potential Solutions
        screen = const PotentialSolutionsScreen();
        break;
      case 2: // Risk Identification
        screen = RiskIdentificationScreen(
          notes: projectData.notes,
          solutions: solutions,
          businessCase: projectData.businessCase,
        );
        break;
      case 3: // IT Considerations
        screen = ITConsiderationsScreen(
          notes: projectData.itConsiderationsData?.notes ?? projectData.notes,
          solutions: solutions,
        );
        break;
      case 4: // Infrastructure Considerations
        screen = InfrastructureConsiderationsScreen(
          notes: projectData.infrastructureConsiderationsData?.notes ?? projectData.notes,
          solutions: solutions,
        );
        break;
      case 5: // Core Stakeholders
        screen = CoreStakeholdersScreen(
          notes: projectData.coreStakeholdersData?.notes ?? projectData.notes,
          solutions: solutions,
        );
        break;
      case 6: // Cost Analysis
        screen = CostAnalysisScreen(
          notes: projectData.notes,
          solutions: solutions,
        );
        break;
      case 7: // Preferred Solution Analysis
        screen = PreferredSolutionAnalysisScreen(
          notes: projectData.preferredSolutionAnalysis?.workingNotes ?? '',
          solutions: solutions,
          businessCase: projectData.businessCase,
        );
        break;
      case 8: // Work Breakdown Structure
        screen = const WorkBreakdownStructureScreen();
        break;
      case 9: // Project Framework
        screen = const ProjectFrameworkScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Check if there's a previous screen
  static bool hasPrevious(String currentScreen) {
    final index = getScreenIndex(currentScreen);
    return index != null && index > 0;
  }

  /// Check if there's a next screen
  static bool hasNext(String currentScreen) {
    final index = getScreenIndex(currentScreen);
    return index != null && index < _screens.length - 1;
  }
}

class _BusinessCaseScreen {
  final String label;
  final int index;

  const _BusinessCaseScreen(this.label, this.index);
}
