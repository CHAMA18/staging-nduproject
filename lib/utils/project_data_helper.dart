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
    w('Initiation Notes', data.notes);
    w('Potential Solution', data.potentialSolution);
    w('Project Objective', data.projectObjective);
    w('Overall Framework', data.overallFramework);

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

    if (data.planningNotes.isNotEmpty) {
      buf.writeln('Planning Phase Notes:');
      data.planningNotes.forEach((key, value) {
        final v = value.trim();
        if (v.isEmpty) return;
        buf.writeln('- ${key.trim()}: $v');
      });
      buf.writeln();
    }

    // Include any prior Front End Planning fields already provided
    final fep = data.frontEndPlanning;
    w('Front End Planning – Requirements Notes', fep.requirementsNotes);
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

  /// Build a richer, cross-application context string for executive plan diagrams.
  /// Includes only populated fields to avoid noise and random output.
  static String buildExecutivePlanContext(ProjectDataModel data, {String? sectionLabel}) {
    final buf = StringBuffer();
    var hasContent = false;

    String clamp(String value, {int max = 420}) {
      final trimmed = value.trim();
      if (trimmed.length <= max) return trimmed;
      return '${trimmed.substring(0, max - 3)}...';
    }

    void w(String label, String? value) {
      final v = clamp(value ?? '');
      if (v.isEmpty) return;
      hasContent = true;
      buf.writeln('$label:');
      buf.writeln(v);
      buf.writeln();
    }

    void wList(String label, Iterable<String> items) {
      final list = items.map(clamp).where((e) => e.isNotEmpty).toList();
      if (list.isEmpty) return;
      hasContent = true;
      buf.writeln('$label:');
      for (final item in list) {
        buf.writeln('- $item');
      }
      buf.writeln();
    }

    buf.writeln('Project Context');
    buf.writeln('================');
    w('Project Name', data.projectName);
    w('Solution Title', data.solutionTitle);
    w('Solution Description', data.solutionDescription);
    w('Business Case', data.businessCase);
    w('Project Objective', data.projectObjective);
    w('Overall Framework', data.overallFramework);
    w('Notes', data.notes);
    wList('Tags', data.tags);

    if (data.projectGoals.isNotEmpty) {
      final items = data.projectGoals.map((g) {
        final name = g.name.trim().isEmpty ? 'Goal' : g.name.trim();
        final desc = g.description.trim();
        return desc.isEmpty ? name : '$name: $desc';
      });
      wList('Project Goals', items);
    }

    if (data.planningGoals.isNotEmpty) {
      final items = data.planningGoals.map((g) {
        final title = g.title.trim().isEmpty ? 'Goal ${g.goalNumber}' : g.title.trim();
        final year = g.targetYear.trim();
        final desc = g.description.trim();
        final suffix = [
          if (year.isNotEmpty) 'Target: $year',
          if (desc.isNotEmpty) desc,
        ].join(' | ');
        return suffix.isEmpty ? title : '$title ($suffix)';
      });
      wList('Planning Goals', items);
    }

    if (data.keyMilestones.isNotEmpty) {
      final items = data.keyMilestones.map((m) {
        final name = m.name.trim().isEmpty ? 'Milestone' : m.name.trim();
        final due = m.dueDate.trim();
        final discipline = m.discipline.trim();
        final details = [
          if (due.isNotEmpty) 'Due: $due',
          if (discipline.isNotEmpty) 'Discipline: $discipline',
        ].join(' | ');
        return details.isEmpty ? name : '$name ($details)';
      });
      wList('Key Milestones', items);
    }

    if (data.planningNotes.isNotEmpty) {
      final items = data.planningNotes.entries
          .where((e) => e.value.trim().isNotEmpty)
          .map((e) => '${e.key}: ${e.value}');
      wList('Planning Notes', items);
    }

    if (data.potentialSolutions.isNotEmpty) {
      final items = data.potentialSolutions.map((s) {
        final title = s.title.trim().isEmpty ? 'Solution' : s.title.trim();
        final desc = s.description.trim();
        return desc.isEmpty ? title : '$title: $desc';
      });
      wList('Potential Solutions', items);
    }

    final preferred = data.preferredSolutionAnalysis;
    if (preferred != null) {
      w('Selected Solution', preferred.selectedSolutionTitle);
      w('Preferred Solution Notes', preferred.workingNotes);
    }

    if (data.solutionRisks.isNotEmpty) {
      final items = <String>[];
      for (final r in data.solutionRisks) {
        final title = r.solutionTitle.trim().isEmpty ? 'Solution' : r.solutionTitle.trim();
        final risks = r.risks.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        if (risks.isEmpty) continue;
        items.add('$title: ${risks.join('; ')}');
      }
      wList('Key Risks', items);
    }

    if ((data.wbsCriteriaA ?? '').trim().isNotEmpty || (data.wbsCriteriaB ?? '').trim().isNotEmpty) {
      w('WBS Criteria A', data.wbsCriteriaA);
      w('WBS Criteria B', data.wbsCriteriaB);
    }

    if (data.goalWorkItems.isNotEmpty) {
      final items = <String>[];
      for (var i = 0; i < data.goalWorkItems.length; i++) {
        final list = data.goalWorkItems[i].where((w) => w.title.trim().isNotEmpty).toList();
        if (list.isEmpty) continue;
        final sample = list.take(3).map((w) => w.title.trim()).join(', ');
        items.add('Goal ${i + 1} Work Items: $sample');
      }
      wList('Work Breakdown Highlights', items);
    }

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
    w('Front End Planning – Contracts', fep.contracts);

    if (data.teamMembers.isNotEmpty) {
      final items = data.teamMembers.map((m) {
        final name = m.name.trim();
        final role = m.role.trim();
        final resp = m.responsibilities.trim();
        final base = [name, role].where((e) => e.isNotEmpty).join(' - ');
        return resp.isEmpty ? base : '$base: $resp';
      }).where((e) => e.isNotEmpty);
      wList('Team Members', items);
    }

    final stakeholders = data.coreStakeholdersData;
    if (stakeholders != null) {
      w('Core Stakeholders Notes', stakeholders.notes);
      if (stakeholders.solutionStakeholderData.isNotEmpty) {
        final items = stakeholders.solutionStakeholderData.map((s) {
          final title = s.solutionTitle.trim().isEmpty ? 'Solution' : s.solutionTitle.trim();
          final notable = s.notableStakeholders.trim();
          return notable.isEmpty ? title : '$title: $notable';
        });
        wList('Notable Stakeholders', items);
      }
    }

    final it = data.itConsiderationsData;
    if (it != null) {
      w('IT Considerations Notes', it.notes);
      if (it.solutionITData.isNotEmpty) {
        final items = it.solutionITData.map((s) {
          final title = s.solutionTitle.trim().isEmpty ? 'Solution' : s.solutionTitle.trim();
          final tech = s.coreTechnology.trim();
          return tech.isEmpty ? title : '$title: $tech';
        });
        wList('Core Technologies', items);
      }
    }

    final infra = data.infrastructureConsiderationsData;
    if (infra != null) {
      w('Infrastructure Notes', infra.notes);
      if (infra.solutionInfrastructureData.isNotEmpty) {
        final items = infra.solutionInfrastructureData.map((s) {
          final title = s.solutionTitle.trim().isEmpty ? 'Solution' : s.solutionTitle.trim();
          final major = s.majorInfrastructure.trim();
          return major.isEmpty ? title : '$title: $major';
        });
        wList('Major Infrastructure', items);
      }
    }

    final cost = data.costAnalysisData;
    if (cost != null) {
      w('Project Value Target', cost.projectValueAmount);
      w('Savings Target', cost.savingsTarget);
      w('Savings Notes', cost.savingsNotes);
      if (cost.benefitLineItems.isNotEmpty) {
        final items = cost.benefitLineItems.map((b) {
          final title = b.title.trim().isEmpty ? 'Benefit' : b.title.trim();
          final units = b.units.trim();
          final unitValue = b.unitValue.trim();
          final details = [
            if (unitValue.isNotEmpty) 'Unit: $unitValue',
            if (units.isNotEmpty) 'Units: $units',
          ].join(' | ');
          return details.isEmpty ? title : '$title ($details)';
        });
        wList('Benefit Line Items', items.take(6));
      }
    }

    final ssher = data.ssherData;
    if (ssher.entries.isNotEmpty) {
      final items = ssher.entries.map((entry) {
        final concern = entry.concern.trim().isEmpty ? 'SSHER Item' : entry.concern.trim();
        final category = entry.category.trim();
        return category.isEmpty ? concern : '$concern ($category)';
      });
      wList('SSHER Items', items);
    } else if (ssher.safetyItems.isNotEmpty) {
      final items = ssher.safetyItems.map((s) {
        final title = s.title.trim().isEmpty ? 'Safety Item' : s.title.trim();
        final category = s.category.trim();
        return category.isEmpty ? title : '$title ($category)';
      });
      wList('SSHER Safety Items', items);
    }
    w('SSHER Notes', ssher.screen1Data);
    w('SSHER Notes (2)', ssher.screen2Data);
    w('SSHER Notes (3)', ssher.screen3Data);
    w('SSHER Notes (4)', ssher.screen4Data);

    if ((sectionLabel ?? '').trim().isNotEmpty) {
      buf.writeln('Target Section: ${sectionLabel!.trim()}');
      buf.writeln();
    }

    if (!hasContent) return '';
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
    String? requirementsNotes,
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
    List<RequirementItem>? requirementItems,
    ProcurementWorkspaceData? procurementWorkspace,
  }) {
    return FrontEndPlanningData(
      requirements: requirements ?? current.requirements,
      requirementsNotes: requirementsNotes ?? current.requirementsNotes,
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
      requirementItems: requirementItems ?? current.requirementItems,
      procurementWorkspace: procurementWorkspace ?? current.procurementWorkspace,
    );
  }
}
