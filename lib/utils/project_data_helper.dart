import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/models/project_data_model.dart';

/// Helper functions for easy integration of ProjectDataProvider across screens
class ProjectDataHelper {
  /// Save current screen data and navigate to next screen with automatic Firebase sync
  static Future<void> saveAndNavigate({
    required BuildContext context,
    required String checkpoint,
    required Widget Function() nextScreenBuilder,
    ProjectDataModel Function(ProjectDataModel)? dataUpdater,
  }) async {
    final provider = ProjectDataInherited.of(context);
    
    // Update data if updater is provided
    if (dataUpdater != null) {
      provider.updateField(dataUpdater);
    }
    
    // Save to Firebase
    final success = await provider.saveToFirebase(checkpoint: checkpoint);
    
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Warning: ${provider.lastError ?? "Could not save data"}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
    // Navigate to next screen
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => nextScreenBuilder()),
      );
    }
  }

  /// Build a compact, structured context string for Front End Planning prompts.
  /// This aggregates prior inputs across the project to enable high‑quality AI suggestions.
  static String buildFepContext(ProjectDataModel data, {String? sectionLabel}) {
    final buf = StringBuffer();
    void w(String label, String? value) {
      final v = (value ?? '').trim();
      if (v.isEmpty) return;
      buf.writeln('$label:');
      buf.writeln(v);
      buf.writeln();
    }

    buf.writeln('Project Context');
    buf.writeln('================');
    w('Project Name', data.projectName);
    w('Solution Title', data.solutionTitle);
    w('Solution Description', data.solutionDescription);
    w('Business Case', data.businessCase);
    w('Project Objective', data.projectObjective);

    if (data.projectGoals.isNotEmpty) {
      buf.writeln('Project Goals:');
      for (final g in data.projectGoals) {
        final name = (g.name).trim();
        final desc = (g.description).trim();
        if (name.isEmpty && desc.isEmpty) continue;
        buf.writeln('- ${name.isEmpty ? 'Goal' : name}: ${desc.isEmpty ? '' : desc}');
      }
      buf.writeln();
    }

    if (data.planningGoals.isNotEmpty) {
      buf.writeln('Planning Goals:');
      for (final g in data.planningGoals) {
        final title = (g.title).trim();
        final desc = (g.description).trim();
        final year = (g.targetYear).trim();
        if (title.isEmpty && desc.isEmpty && year.isEmpty) continue;
        buf.writeln('- ${title.isEmpty ? 'Goal ${g.goalNumber}' : title} (${year.isEmpty ? 'n/a' : year}): $desc');
      }
      buf.writeln();
    }

    if (data.keyMilestones.isNotEmpty) {
      buf.writeln('Key Milestones:');
      for (final m in data.keyMilestones) {
        final name = (m.name).trim();
        final due = (m.dueDate).trim();
        final discipline = (m.discipline).trim();
        if (name.isEmpty && due.isEmpty && discipline.isEmpty) continue;
        buf.writeln('- ${name.isEmpty ? 'Milestone' : name} | Due: ${due.isEmpty ? 'TBD' : due} | ${discipline.isEmpty ? '' : 'Discipline: $discipline'}');
      }
      buf.writeln();
    }

    // Include any prior Front End Planning fields already provided
    final fep = data.frontEndPlanning;
    w('Front End Planning – Requirements', fep.requirements);
    w('Front End Planning – Risks', fep.risks);
    w('Front End Planning – Opportunities', fep.opportunities);
    w('Front End Planning – Contract & Vendor Quotes', fep.contractVendorQuotes);
    w('Front End Planning – Procurement', fep.procurement);
    w('Front End Planning – Security', fep.security);
    w('Front End Planning – Allowance', fep.allowance);
    w('Front End Planning – Summary', fep.summary);
    w('Front End Planning – Technology', fep.technology);
    w('Front End Planning – Personnel', fep.personnel);
    w('Front End Planning – Infrastructure', fep.infrastructure);

    if ((sectionLabel ?? '').isNotEmpty) {
      buf.writeln('Target Section: ${sectionLabel!.trim()}');
    }

    return buf.toString().trim();
  }

  /// Get project data from context
  static ProjectDataModel getData(BuildContext context) {
    return ProjectDataInherited.of(context).projectData;
  }

  /// Get provider from context
  static ProjectDataProvider getProvider(BuildContext context) {
    return ProjectDataInherited.of(context);
  }

  /// Update and save data without navigation
  static Future<bool> updateAndSave({
    required BuildContext context,
    required String checkpoint,
    required ProjectDataModel Function(ProjectDataModel) dataUpdater,
    bool showSnackbar = true,
  }) async {
    final provider = ProjectDataInherited.of(context);
    provider.updateField(dataUpdater);
    
    final success = await provider.saveToFirebase(checkpoint: checkpoint);
    
    if (!success && context.mounted && showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.lastError ?? "Could not save data"}'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (success && context.mounted && showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data saved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
    
    return success;
  }

  /// Convert legacy goal format to new format
  static List<ProjectGoal> convertLegacyGoals(List<Map<String, String>>? legacyGoals) {
    if (legacyGoals == null || legacyGoals.isEmpty) return [];
    
    return legacyGoals.map((g) => ProjectGoal(
      name: g['name'] ?? g['title'] ?? '',
      description: g['description'] ?? '',
      framework: g['framework'],
    )).toList();
  }

  /// Convert legacy planning goals to new format
  static List<PlanningGoal> convertLegacyPlanningGoals(List<Map<String, String>>? legacyGoals) {
    if (legacyGoals == null || legacyGoals.isEmpty) {
      return List.generate(3, (i) => PlanningGoal(goalNumber: i + 1));
    }
    
    return legacyGoals.asMap().entries.map((entry) {
      final i = entry.key;
      final g = entry.value;
      return PlanningGoal(
        goalNumber: i + 1,
        title: g['title'] ?? '',
        description: g['description'] ?? '',
        targetYear: g['year'] ?? '',
      );
    }).toList();
  }

  /// Show saving indicator
  static void showSavingIndicator(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Saving...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Helper to update Front End Planning data while preserving other fields
  static FrontEndPlanningData updateFEPField({
    required FrontEndPlanningData current,
    String? requirements,
    String? risks,
    String? opportunities,
    String? contractVendorQuotes,
    String? procurement,
    String? security,
    String? allowance,
    String? summary,
    String? technology,
    String? personnel,
    String? infrastructure,
    String? contracts,
  }) {
    return FrontEndPlanningData(
      requirements: requirements ?? current.requirements,
      risks: risks ?? current.risks,
      opportunities: opportunities ?? current.opportunities,
      contractVendorQuotes: contractVendorQuotes ?? current.contractVendorQuotes,
      procurement: procurement ?? current.procurement,
      security: security ?? current.security,
      allowance: allowance ?? current.allowance,
      summary: summary ?? current.summary,
      technology: technology ?? current.technology,
      personnel: personnel ?? current.personnel,
      infrastructure: infrastructure ?? current.infrastructure,
      contracts: contracts ?? current.contracts,
    );
  }
}
