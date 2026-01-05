import 'package:flutter/foundation.dart';

/// Comprehensive project data model that captures all information across the application flow
class ProjectDataModel {
  // Initiation Phase Data
  String projectName;
  String solutionTitle;
  String solutionDescription;
  String businessCase;
  String notes;
  List<String> tags;
  List<PotentialSolution> potentialSolutions;
  List<SolutionRisk> solutionRisks;
  PreferredSolutionAnalysis? preferredSolutionAnalysis;
  
  // Project Framework Data
  String? overallFramework;
  List<ProjectGoal> projectGoals;
  
  // Planning Phase Data
  String potentialSolution;
  String projectObjective;
  List<PlanningGoal> planningGoals;
  List<Milestone> keyMilestones;
  Map<String, String> planningNotes;
  
  // Work Breakdown Structure Data
  String? wbsCriteriaA;
  String? wbsCriteriaB;
  List<List<WorkItem>> goalWorkItems;

  // Issue Management Data
  List<IssueLogItem> issueLogItems;
  
  // Front End Planning Data
  FrontEndPlanningData frontEndPlanning;
  
  // SSHER Data
  SSHERData ssherData;
  
  // Team Management Data
  List<TeamMember> teamMembers;

  // Launch Checklist Data
  List<LaunchChecklistItem> launchChecklistItems;
  
  // Cost Analysis Data
  CostAnalysisData? costAnalysisData;

  // Cost Estimate Data
  List<CostEstimateItem> costEstimateItems;
  
  // IT Considerations Data
  ITConsiderationsData? itConsiderationsData;
  
  // Infrastructure Considerations Data
  InfrastructureConsiderationsData? infrastructureConsiderationsData;
  
  // Core Stakeholders Data
  CoreStakeholdersData? coreStakeholdersData;
  
  // Metadata
  bool isBasicPlanProject;
  Map<String, int> aiUsageCounts;
  String? projectId;
  DateTime? createdAt;
  DateTime? updatedAt;
  String currentCheckpoint;

  ProjectDataModel({
    this.projectName = '',
    this.solutionTitle = '',
    this.solutionDescription = '',
    this.businessCase = '',
    this.notes = '',
    this.tags = const [],
    List<PotentialSolution>? potentialSolutions,
    List<SolutionRisk>? solutionRisks,
    this.preferredSolutionAnalysis,
    this.overallFramework,
    List<ProjectGoal>? projectGoals,
    this.potentialSolution = '',
    this.projectObjective = '',
    List<PlanningGoal>? planningGoals,
    List<Milestone>? keyMilestones,
    Map<String, String>? planningNotes,
    this.wbsCriteriaA,
    this.wbsCriteriaB,
    List<List<WorkItem>>? goalWorkItems,
    List<IssueLogItem>? issueLogItems,
    FrontEndPlanningData? frontEndPlanning,
    SSHERData? ssherData,
    List<TeamMember>? teamMembers,
    List<LaunchChecklistItem>? launchChecklistItems,
    this.costAnalysisData,
    List<CostEstimateItem>? costEstimateItems,
    this.itConsiderationsData,
    this.infrastructureConsiderationsData,
    this.coreStakeholdersData,
    this.isBasicPlanProject = false,
    Map<String, int>? aiUsageCounts,
    this.projectId,
    this.createdAt,
    this.updatedAt,
    this.currentCheckpoint = 'initiation',
  })  : potentialSolutions = potentialSolutions ?? [],
        solutionRisks = solutionRisks ?? [],
        projectGoals = projectGoals ?? [],
        planningGoals = planningGoals ?? List.generate(3, (i) => PlanningGoal(goalNumber: i + 1)),
        keyMilestones = keyMilestones ?? [],
        planningNotes = planningNotes ?? {},
        goalWorkItems = goalWorkItems ?? List.generate(3, (_) => []),
        issueLogItems = issueLogItems ?? [],
        frontEndPlanning = frontEndPlanning ?? FrontEndPlanningData(),
        ssherData = ssherData ?? SSHERData(),
        teamMembers = teamMembers ?? [],
        launchChecklistItems = launchChecklistItems ?? [],
        costEstimateItems = costEstimateItems ?? [],
        aiUsageCounts = aiUsageCounts ?? {};

  ProjectDataModel copyWith({
    String? projectName,
    String? solutionTitle,
    String? solutionDescription,
    String? businessCase,
    String? notes,
    List<String>? tags,
    List<PotentialSolution>? potentialSolutions,
    List<SolutionRisk>? solutionRisks,
    PreferredSolutionAnalysis? preferredSolutionAnalysis,
    String? overallFramework,
    List<ProjectGoal>? projectGoals,
    String? potentialSolution,
    String? projectObjective,
    List<PlanningGoal>? planningGoals,
    List<Milestone>? keyMilestones,
    Map<String, String>? planningNotes,
    String? wbsCriteriaA,
    String? wbsCriteriaB,
    List<List<WorkItem>>? goalWorkItems,
    List<IssueLogItem>? issueLogItems,
    FrontEndPlanningData? frontEndPlanning,
    SSHERData? ssherData,
    List<TeamMember>? teamMembers,
    List<LaunchChecklistItem>? launchChecklistItems,
    CostAnalysisData? costAnalysisData,
    List<CostEstimateItem>? costEstimateItems,
    ITConsiderationsData? itConsiderationsData,
    InfrastructureConsiderationsData? infrastructureConsiderationsData,
    CoreStakeholdersData? coreStakeholdersData,
    bool? isBasicPlanProject,
    Map<String, int>? aiUsageCounts,
    String? projectId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currentCheckpoint,
  }) {
    return ProjectDataModel(
      projectName: projectName ?? this.projectName,
      solutionTitle: solutionTitle ?? this.solutionTitle,
      solutionDescription: solutionDescription ?? this.solutionDescription,
      businessCase: businessCase ?? this.businessCase,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      potentialSolutions: potentialSolutions ?? this.potentialSolutions,
      solutionRisks: solutionRisks ?? this.solutionRisks,
      preferredSolutionAnalysis: preferredSolutionAnalysis ?? this.preferredSolutionAnalysis,
      overallFramework: overallFramework ?? this.overallFramework,
      projectGoals: projectGoals ?? this.projectGoals,
      potentialSolution: potentialSolution ?? this.potentialSolution,
      projectObjective: projectObjective ?? this.projectObjective,
      planningGoals: planningGoals ?? this.planningGoals,
      keyMilestones: keyMilestones ?? this.keyMilestones,
      planningNotes: planningNotes ?? this.planningNotes,
      wbsCriteriaA: wbsCriteriaA ?? this.wbsCriteriaA,
      wbsCriteriaB: wbsCriteriaB ?? this.wbsCriteriaB,
      goalWorkItems: goalWorkItems ?? this.goalWorkItems,
      issueLogItems: issueLogItems ?? this.issueLogItems,
      frontEndPlanning: frontEndPlanning ?? this.frontEndPlanning,
      ssherData: ssherData ?? this.ssherData,
       teamMembers: teamMembers ?? this.teamMembers,
      launchChecklistItems: launchChecklistItems ?? this.launchChecklistItems,
      costAnalysisData: costAnalysisData ?? this.costAnalysisData,
      costEstimateItems: costEstimateItems ?? this.costEstimateItems,
      itConsiderationsData: itConsiderationsData ?? this.itConsiderationsData,
      infrastructureConsiderationsData: infrastructureConsiderationsData ?? this.infrastructureConsiderationsData,
      coreStakeholdersData: coreStakeholdersData ?? this.coreStakeholdersData,
      isBasicPlanProject: isBasicPlanProject ?? this.isBasicPlanProject,
      aiUsageCounts: aiUsageCounts ?? this.aiUsageCounts,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentCheckpoint: currentCheckpoint ?? this.currentCheckpoint,
    );
  }

  Map<String, dynamic> toJson() {
    // Flatten goalWorkItems to avoid nested arrays (Firestore doesn't support nested arrays)
    final flattenedWorkItems = <Map<String, dynamic>>[];
    for (int goalIndex = 0; goalIndex < goalWorkItems.length; goalIndex++) {
      for (final item in goalWorkItems[goalIndex]) {
        flattenedWorkItems.add({
          ...item.toJson(),
          'goalIndex': goalIndex,
        });
      }
    }

    return {
      'name': projectName, // Map to 'name' for ProjectService compatibility
      'projectName': projectName,
      'solutionTitle': solutionTitle,
      'solutionDescription': solutionDescription,
      'businessCase': businessCase,
      'notes': notes,
      'tags': tags,
      'potentialSolutions': potentialSolutions.map((s) => s.toJson()).toList(),
      'solutionRisks': solutionRisks.map((r) => r.toJson()).toList(),
      'preferredSolutionAnalysis': preferredSolutionAnalysis?.toJson(),
      'overallFramework': overallFramework,
      'projectGoals': projectGoals.map((g) => g.toJson()).toList(),
      'potentialSolution': potentialSolution,
      'projectObjective': projectObjective,
      'planningGoals': planningGoals.map((g) => g.toJson()).toList(),
      'keyMilestones': keyMilestones.map((m) => m.toJson()).toList(),
      'planningNotes': planningNotes,
      'wbsCriteriaA': wbsCriteriaA,
      'wbsCriteriaB': wbsCriteriaB,
      'goalWorkItems': flattenedWorkItems,
      'issueLogItems': issueLogItems.map((item) => item.toJson()).toList(),
      'frontEndPlanning': frontEndPlanning.toJson(),
      'ssherData': ssherData.toJson(),
      'teamMembers': teamMembers.map((m) => m.toJson()).toList(),
      'launchChecklistItems': launchChecklistItems.map((item) => item.toJson()).toList(),
      if (costAnalysisData != null) 'costAnalysisData': costAnalysisData!.toJson(),
      'costEstimateItems': costEstimateItems.map((item) => item.toJson()).toList(),
      if (itConsiderationsData != null) 'itConsiderationsData': itConsiderationsData!.toJson(),
      if (infrastructureConsiderationsData != null) 'infrastructureConsiderationsData': infrastructureConsiderationsData!.toJson(),
      if (coreStakeholdersData != null) 'coreStakeholdersData': coreStakeholdersData!.toJson(),
      'currentCheckpoint': currentCheckpoint,
      'isBasicPlanProject': isBasicPlanProject,
      'aiUsageCounts': aiUsageCounts,
      'projectId': projectId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ProjectDataModel.fromJson(Map<String, dynamic> json) {
    // Reconstruct goalWorkItems from flattened structure
    List<List<WorkItem>> reconstructedGoalWorkItems = List.generate(3, (_) => []);
    final rawWorkItems = json['goalWorkItems'] as List?;
    
    if (rawWorkItems != null) {
      try {
        // Check if it's the old nested format or new flattened format
        if (rawWorkItems.isNotEmpty && rawWorkItems.first is List) {
          // Old nested format (backward compatibility)
          reconstructedGoalWorkItems = rawWorkItems.map((items) => (items as List).map((i) => WorkItem.fromJson(i)).toList()).toList();
        } else {
          // New flattened format
          for (final item in rawWorkItems) {
            final itemMap = item as Map<String, dynamic>;
            final goalIndex = itemMap['goalIndex'] as int? ?? 0;
            
            // Ensure the list is large enough
            while (reconstructedGoalWorkItems.length <= goalIndex) {
              reconstructedGoalWorkItems.add([]);
            }
            
            reconstructedGoalWorkItems[goalIndex].add(WorkItem.fromJson(itemMap));
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing goalWorkItems: $e');
        reconstructedGoalWorkItems = List.generate(3, (_) => []);
      }
    }

    // Safe parsing helper for lists
    List<T> safeParseList<T>(String key, T Function(Map<String, dynamic>) parser) {
      try {
        final list = json[key] as List?;
        if (list == null) return [];
        return list.map((item) {
          try {
            return parser(item as Map<String, dynamic>);
          } catch (e) {
            debugPrint('⚠️ Error parsing item in $key: $e');
            return null;
          }
        }).whereType<T>().toList();
      } catch (e) {
        debugPrint('⚠️ Error parsing list $key: $e');
        return [];
      }
    }

    // Safe parsing helper for single objects
    T? safeParseSingle<T>(String key, T Function(Map<String, dynamic>) parser) {
      try {
        final obj = json[key];
        if (obj == null) return null;
        return parser(obj as Map<String, dynamic>);
      } catch (e) {
        debugPrint('⚠️ Error parsing $key: $e');
        return null;
      }
    }

    // Safe DateTime parsing
    DateTime? safeParseDateTime(String key) {
      try {
        final value = json[key];
        if (value == null) return null;
        if (value is String) return DateTime.parse(value);
        if (value is DateTime) return value;
        return null;
      } catch (e) {
        debugPrint('⚠️ Error parsing DateTime $key: $e');
        return null;
      }
    }

    return ProjectDataModel(
      projectName: json['projectName']?.toString() ?? json['name']?.toString() ?? '',
      solutionTitle: json['solutionTitle']?.toString() ?? '',
      solutionDescription: json['solutionDescription']?.toString() ?? '',
      businessCase: json['businessCase']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      potentialSolutions: safeParseList('potentialSolutions', PotentialSolution.fromJson),
      solutionRisks: safeParseList('solutionRisks', SolutionRisk.fromJson),
      preferredSolutionAnalysis: safeParseSingle('preferredSolutionAnalysis', PreferredSolutionAnalysis.fromJson),
      overallFramework: json['overallFramework']?.toString(),
      projectGoals: safeParseList('projectGoals', ProjectGoal.fromJson),
      potentialSolution: json['potentialSolution']?.toString() ?? '',
      projectObjective: json['projectObjective']?.toString() ?? '',
      planningGoals: safeParseList<PlanningGoal>('planningGoals', PlanningGoal.fromJson).takeWhile((value) => true).toList().isEmpty
          ? List.generate(3, (i) => PlanningGoal(goalNumber: i + 1))
          : safeParseList('planningGoals', PlanningGoal.fromJson),
      keyMilestones: safeParseList('keyMilestones', Milestone.fromJson),
      planningNotes: (json['planningNotes'] is Map)
          ? Map<String, String>.from(
              (json['planningNotes'] as Map).map((key, value) => MapEntry(key.toString(), value.toString())),
            )
          : {},
      wbsCriteriaA: json['wbsCriteriaA']?.toString(),
      wbsCriteriaB: json['wbsCriteriaB']?.toString(),
      goalWorkItems: reconstructedGoalWorkItems,
      issueLogItems: safeParseList('issueLogItems', IssueLogItem.fromJson),
      frontEndPlanning: safeParseSingle('frontEndPlanning', FrontEndPlanningData.fromJson) ?? FrontEndPlanningData(),
      ssherData: safeParseSingle('ssherData', SSHERData.fromJson) ?? SSHERData(),
      teamMembers: safeParseList('teamMembers', TeamMember.fromJson),
      launchChecklistItems: safeParseList('launchChecklistItems', LaunchChecklistItem.fromJson),
      costAnalysisData: safeParseSingle('costAnalysisData', CostAnalysisData.fromJson),
      costEstimateItems: safeParseList('costEstimateItems', CostEstimateItem.fromJson),
      itConsiderationsData: safeParseSingle('itConsiderationsData', ITConsiderationsData.fromJson),
      infrastructureConsiderationsData: safeParseSingle('infrastructureConsiderationsData', InfrastructureConsiderationsData.fromJson),
      coreStakeholdersData: safeParseSingle('coreStakeholdersData', CoreStakeholdersData.fromJson),
      isBasicPlanProject: json['isBasicPlanProject'] == true,
      aiUsageCounts: (json['aiUsageCounts'] is Map)
          ? Map<String, int>.from(
              (json['aiUsageCounts'] as Map).map((key, value) {
                final parsed = value is int ? value : int.tryParse(value.toString()) ?? 0;
                return MapEntry(key.toString(), parsed);
              }),
            )
          : {},
      currentCheckpoint: json['currentCheckpoint']?.toString() ?? json['checkpointRoute']?.toString() ?? 'initiation',
      projectId: json['projectId']?.toString(),
      createdAt: safeParseDateTime('createdAt'),
      updatedAt: safeParseDateTime('updatedAt'),
    );
  }
}

class ProjectGoal {
  String name;
  String description;
  String? framework;

  ProjectGoal({
    this.name = '',
    this.description = '',
    this.framework,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'framework': framework,
      };

  factory ProjectGoal.fromJson(Map<String, dynamic> json) {
    return ProjectGoal(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      framework: json['framework'],
    );
  }
}

class PlanningGoal {
  int goalNumber;
  String title;
  String description;
  String targetYear;
  List<PlanningMilestone> milestones;

  PlanningGoal({
    required this.goalNumber,
    this.title = '',
    this.description = '',
    this.targetYear = '',
    List<PlanningMilestone>? milestones,
  }) : milestones = milestones ?? [PlanningMilestone()];

  Map<String, dynamic> toJson() => {
        'goalNumber': goalNumber,
        'title': title,
        'description': description,
        'targetYear': targetYear,
        'milestones': milestones.map((m) => m.toJson()).toList(),
      };

  factory PlanningGoal.fromJson(Map<String, dynamic> json) {
    return PlanningGoal(
      goalNumber: json['goalNumber'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetYear: json['targetYear'] ?? '',
      milestones: (json['milestones'] as List?)?.map((m) => PlanningMilestone.fromJson(m)).toList() ?? [PlanningMilestone()],
    );
  }
}

class PlanningMilestone {
  String title;
  String deadline;

  PlanningMilestone({
    this.title = '',
    this.deadline = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'deadline': deadline,
      };

  factory PlanningMilestone.fromJson(Map<String, dynamic> json) {
    return PlanningMilestone(
      title: json['title'] ?? '',
      deadline: json['deadline'] ?? '',
    );
  }
}

class LaunchChecklistItem {
  LaunchChecklistItem({
    String? id,
    this.itemName = '',
    this.details = '',
    this.owner = '',
    this.dueBefore = '',
    this.statusTag = 'Pending sign-off',
    this.completionRule = '',
  }) : id = id ?? _generateId();

  final String id;
  String itemName;
  String details;
  String owner;
  String dueBefore;
  String statusTag;
  String completionRule;

  LaunchChecklistItem copyWith({
    String? itemName,
    String? details,
    String? owner,
    String? dueBefore,
    String? statusTag,
    String? completionRule,
  }) {
    return LaunchChecklistItem(
      id: id,
      itemName: itemName ?? this.itemName,
      details: details ?? this.details,
      owner: owner ?? this.owner,
      dueBefore: dueBefore ?? this.dueBefore,
      statusTag: statusTag ?? this.statusTag,
      completionRule: completionRule ?? this.completionRule,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemName': itemName,
        'details': details,
        'owner': owner,
        'dueBefore': dueBefore,
        'statusTag': statusTag,
        'completionRule': completionRule,
      };

  factory LaunchChecklistItem.fromJson(Map<String, dynamic> json) {
    return LaunchChecklistItem(
      id: json['id']?.toString(),
      itemName: json['itemName']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      dueBefore: json['dueBefore']?.toString() ?? '',
      statusTag: json['statusTag']?.toString() ?? 'Pending sign-off',
      completionRule: json['completionRule']?.toString() ?? '',
    );
  }

  static String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class Milestone {
  String name;
  String discipline;
  String dueDate;
  String references;
  String comments;

  Milestone({
    this.name = '',
    this.discipline = '',
    this.dueDate = '',
    this.references = '',
    this.comments = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'discipline': discipline,
        'dueDate': dueDate,
        'references': references,
        'comments': comments,
      };

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      name: json['name'] ?? '',
      discipline: json['discipline'] ?? '',
      dueDate: json['dueDate'] ?? '',
      references: json['references'] ?? '',
      comments: json['comments'] ?? '',
    );
  }
}

class WorkItem {
  String title;
  String description;
  String status;

  WorkItem({
    this.title = '',
    this.description = '',
    this.status = 'not_started',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'status': status,
      };

  factory WorkItem.fromJson(Map<String, dynamic> json) {
    return WorkItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'not_started',
    );
  }
}

class IssueLogItem {
  String id;
  String title;
  String description;
  String type;
  String severity;
  String status;
  String assignee;
  String dueDate;
  String milestone;

  IssueLogItem({
    this.id = '',
    this.title = '',
    this.description = '',
    this.type = '',
    this.severity = '',
    this.status = '',
    this.assignee = '',
    this.dueDate = '',
    this.milestone = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type,
        'severity': severity,
        'status': status,
        'assignee': assignee,
        'dueDate': dueDate,
        'milestone': milestone,
      };

  factory IssueLogItem.fromJson(Map<String, dynamic> json) {
    return IssueLogItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      severity: json['severity'] ?? '',
      status: json['status'] ?? '',
      assignee: json['assignee'] ?? '',
      dueDate: json['dueDate'] ?? '',
      milestone: json['milestone'] ?? '',
    );
  }
}

class RequirementItem {
  String description;
  String requirementType;
  String comments;

  RequirementItem({
    this.description = '',
    this.requirementType = '',
    this.comments = '',
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'requirementType': requirementType,
        'comments': comments,
      };

  factory RequirementItem.fromJson(Map<String, dynamic> json) {
    return RequirementItem(
      description: json['description'] ?? '',
      requirementType: json['requirementType'] ?? '',
      comments: json['comments'] ?? '',
    );
  }
}

class FrontEndPlanningData {
  String requirements;
  String requirementsNotes;
  String risks;
  String opportunities;
  String contractVendorQuotes;
  String procurement;
  String security;
  String allowance;
  String summary;
  String technology;
  String personnel;
  String infrastructure;
  String contracts;
  List<RequirementItem> requirementItems;

  FrontEndPlanningData({
    this.requirements = '',
    this.requirementsNotes = '',
    this.risks = '',
    this.opportunities = '',
    this.contractVendorQuotes = '',
    this.procurement = '',
    this.security = '',
    this.allowance = '',
    this.summary = '',
    this.technology = '',
    this.personnel = '',
    this.infrastructure = '',
    this.contracts = '',
    List<RequirementItem>? requirementItems,
  }) : requirementItems = requirementItems ?? [];

  Map<String, dynamic> toJson() => {
        'requirements': requirements,
        'requirementsNotes': requirementsNotes,
        'risks': risks,
        'opportunities': opportunities,
        'contractVendorQuotes': contractVendorQuotes,
        'procurement': procurement,
        'security': security,
        'allowance': allowance,
        'summary': summary,
        'technology': technology,
        'personnel': personnel,
        'infrastructure': infrastructure,
        'contracts': contracts,
        'requirementsItems': requirementItems.map((item) => item.toJson()).toList(),
      };

  factory FrontEndPlanningData.fromJson(Map<String, dynamic> json) {
    return FrontEndPlanningData(
      requirements: json['requirements'] ?? '',
      requirementsNotes: json['requirementsNotes'] ?? '',
      risks: json['risks'] ?? '',
      opportunities: json['opportunities'] ?? '',
      contractVendorQuotes: json['contractVendorQuotes'] ?? '',
      procurement: json['procurement'] ?? '',
      security: json['security'] ?? '',
      allowance: json['allowance'] ?? '',
      summary: json['summary'] ?? '',
      technology: json['technology'] ?? '',
      personnel: json['personnel'] ?? '',
      infrastructure: json['infrastructure'] ?? '',
      contracts: json['contracts'] ?? '',
      requirementItems: (json['requirementsItems'] as List?)
              ?.map((item) => RequirementItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SSHERData {
  List<SafetyItem> safetyItems;
  List<SsherEntry> entries;
  String screen1Data;
  String screen2Data;
  String screen3Data;
  String screen4Data;

  SSHERData({
    List<SafetyItem>? safetyItems,
    List<SsherEntry>? entries,
    this.screen1Data = '',
    this.screen2Data = '',
    this.screen3Data = '',
    this.screen4Data = '',
  })  : safetyItems = safetyItems ?? [],
        entries = entries ?? [];

  Map<String, dynamic> toJson() => {
        'safetyItems': safetyItems.map((s) => s.toJson()).toList(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'screen1Data': screen1Data,
        'screen2Data': screen2Data,
        'screen3Data': screen3Data,
        'screen4Data': screen4Data,
      };

  factory SSHERData.fromJson(Map<String, dynamic> json) {
    return SSHERData(
      safetyItems: (json['safetyItems'] as List?)?.map((s) => SafetyItem.fromJson(s)).toList() ?? [],
      entries: (json['entries'] as List?)?.map((e) => SsherEntry.fromJson(e)).toList() ?? [],
      screen1Data: json['screen1Data'] ?? '',
      screen2Data: json['screen2Data'] ?? '',
      screen3Data: json['screen3Data'] ?? '',
      screen4Data: json['screen4Data'] ?? '',
    );
  }

  SSHERData copyWith({
    List<SafetyItem>? safetyItems,
    List<SsherEntry>? entries,
    String? screen1Data,
    String? screen2Data,
    String? screen3Data,
    String? screen4Data,
  }) {
    return SSHERData(
      safetyItems: safetyItems ?? this.safetyItems,
      entries: entries ?? this.entries,
      screen1Data: screen1Data ?? this.screen1Data,
      screen2Data: screen2Data ?? this.screen2Data,
      screen3Data: screen3Data ?? this.screen3Data,
      screen4Data: screen4Data ?? this.screen4Data,
    );
  }
}

class SsherEntry {
  String category;
  String department;
  String teamMember;
  String concern;
  String riskLevel;
  String mitigation;

  SsherEntry({
    this.category = '',
    this.department = '',
    this.teamMember = '',
    this.concern = '',
    this.riskLevel = '',
    this.mitigation = '',
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'department': department,
        'teamMember': teamMember,
        'concern': concern,
        'riskLevel': riskLevel,
        'mitigation': mitigation,
      };

  factory SsherEntry.fromJson(Map<String, dynamic> json) {
    return SsherEntry(
      category: json['category'] ?? '',
      department: json['department'] ?? '',
      teamMember: json['teamMember'] ?? '',
      concern: json['concern'] ?? '',
      riskLevel: json['riskLevel'] ?? '',
      mitigation: json['mitigation'] ?? '',
    );
  }
}

class SafetyItem {
  String title;
  String description;
  String category;

  SafetyItem({
    this.title = '',
    this.description = '',
    this.category = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
      };

  factory SafetyItem.fromJson(Map<String, dynamic> json) {
    return SafetyItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
    );
  }
}

class PotentialSolution {
  String title;
  String description;

  PotentialSolution({
    this.title = '',
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
      };

  factory PotentialSolution.fromJson(Map<String, dynamic> json) {
    return PotentialSolution(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class SolutionRisk {
  String solutionTitle;
  List<String> risks;

  SolutionRisk({
    this.solutionTitle = '',
    List<String>? risks,
  }) : risks = risks ?? ['', '', ''];

  Map<String, dynamic> toJson() => {
        'solutionTitle': solutionTitle,
        'risks': risks,
      };

  factory SolutionRisk.fromJson(Map<String, dynamic> json) {
    final riskList = (json['risks'] as List?)?.map((r) => r.toString()).toList() ?? ['', '', ''];
    // Ensure we always have 3 risks
    while (riskList.length < 3) {
      riskList.add('');
    }
    return SolutionRisk(
      solutionTitle: json['solutionTitle'] ?? '',
      risks: riskList.take(3).toList(),
    );
  }
}

class TeamMember {
  String name;
  String role;
  String email;
  String responsibilities;

  TeamMember({
    this.name = '',
    this.role = '',
    this.email = '',
    this.responsibilities = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'email': email,
        'responsibilities': responsibilities,
      };

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      email: json['email'] ?? '',
      responsibilities: json['responsibilities'] ?? '',
    );
  }
}

class PreferredSolutionAnalysis {
  String workingNotes;
  List<SolutionAnalysisItem> solutionAnalyses;
  String? selectedSolutionTitle;

  PreferredSolutionAnalysis({
    this.workingNotes = '',
    List<SolutionAnalysisItem>? solutionAnalyses,
    this.selectedSolutionTitle,
  }) : solutionAnalyses = solutionAnalyses ?? [];

  Map<String, dynamic> toJson() => {
        'workingNotes': workingNotes,
        'solutionAnalyses': solutionAnalyses.map((s) => s.toJson()).toList(),
        'selectedSolutionTitle': selectedSolutionTitle,
      };

  factory PreferredSolutionAnalysis.fromJson(Map<String, dynamic> json) {
    return PreferredSolutionAnalysis(
      workingNotes: json['workingNotes'] ?? '',
      solutionAnalyses: (json['solutionAnalyses'] as List?)?.map((s) => SolutionAnalysisItem.fromJson(s)).toList() ?? [],
      selectedSolutionTitle: json['selectedSolutionTitle'],
    );
  }
}

class SolutionAnalysisItem {
  String solutionTitle;
  String solutionDescription;
  List<String> stakeholders;
  List<String> risks;
  List<String> technologies;
  List<String> infrastructure;
  List<CostItem> costs;

  SolutionAnalysisItem({
    this.solutionTitle = '',
    this.solutionDescription = '',
    List<String>? stakeholders,
    List<String>? risks,
    List<String>? technologies,
    List<String>? infrastructure,
    List<CostItem>? costs,
  })  : stakeholders = stakeholders ?? [],
        risks = risks ?? [],
        technologies = technologies ?? [],
        infrastructure = infrastructure ?? [],
        costs = costs ?? [];

  Map<String, dynamic> toJson() => {
        'solutionTitle': solutionTitle,
        'solutionDescription': solutionDescription,
        'stakeholders': stakeholders,
        'risks': risks,
        'technologies': technologies,
        'infrastructure': infrastructure,
        'costs': costs.map((c) => c.toJson()).toList(),
      };

  factory SolutionAnalysisItem.fromJson(Map<String, dynamic> json) {
    return SolutionAnalysisItem(
      solutionTitle: json['solutionTitle'] ?? '',
      solutionDescription: json['solutionDescription'] ?? '',
      stakeholders: List<String>.from(json['stakeholders'] ?? []),
      risks: List<String>.from(json['risks'] ?? []),
      technologies: List<String>.from(json['technologies'] ?? []),
      infrastructure: List<String>.from(json['infrastructure'] ?? []),
      costs: (json['costs'] as List?)?.map((c) => CostItem.fromJson(c)).toList() ?? [],
    );
  }
}

class CostItem {
  String item;
  String description;
  double estimatedCost;
  double roiPercent;
  Map<int, double> npvByYear;

  CostItem({
    this.item = '',
    this.description = '',
    this.estimatedCost = 0.0,
    this.roiPercent = 0.0,
    Map<int, double>? npvByYear,
  }) : npvByYear = npvByYear ?? {};

  Map<String, dynamic> toJson() => {
        'item': item,
        'description': description,
        'estimatedCost': estimatedCost,
        'roiPercent': roiPercent,
        'npvByYear': npvByYear.map((key, value) => MapEntry(key.toString(), value)),
      };

  factory CostItem.fromJson(Map<String, dynamic> json) {
    final npvMap = json['npvByYear'] as Map?;
    final convertedNpv = <int, double>{};
    if (npvMap != null) {
      npvMap.forEach((key, value) {
        final intKey = int.tryParse(key.toString()) ?? 0;
        final doubleValue = (value is num) ? value.toDouble() : 0.0;
        convertedNpv[intKey] = doubleValue;
      });
    }

    return CostItem(
      item: json['item'] ?? '',
      description: json['description'] ?? '',
      estimatedCost: (json['estimatedCost'] is num) ? (json['estimatedCost'] as num).toDouble() : 0.0,
      roiPercent: (json['roiPercent'] is num) ? (json['roiPercent'] as num).toDouble() : 0.0,
      npvByYear: convertedNpv,
    );
  }
}

class CostEstimateItem {
  String id;
  String title;
  String notes;
  double amount;
  String costType;

  CostEstimateItem({
    String? id,
    this.title = '',
    this.notes = '',
    this.amount = 0.0,
    this.costType = 'direct',
  }) : id = id ?? _generateId();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'amount': amount,
        'costType': costType,
      };

  factory CostEstimateItem.fromJson(Map<String, dynamic> json) {
    return CostEstimateItem(
      id: json['id']?.toString(),
      title: json['title'] ?? '',
      notes: json['notes'] ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      costType: json['costType']?.toString() ?? 'direct',
    );
  }

  static String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class CostAnalysisData {
  String notes;
  List<SolutionCostData> solutionCosts;
  // Step 1: Project Value data
  String projectValueAmount;
  Map<String, String> projectValueBenefits;
  List<BenefitLineItem> benefitLineItems;
  String savingsNotes;
  String savingsTarget;

  CostAnalysisData({
    this.notes = '',
    List<SolutionCostData>? solutionCosts,
    this.projectValueAmount = '',
    Map<String, String>? projectValueBenefits,
    List<BenefitLineItem>? benefitLineItems,
    this.savingsNotes = '',
    this.savingsTarget = '',
  }) : solutionCosts = solutionCosts ?? [],
       projectValueBenefits = projectValueBenefits ?? {},
       benefitLineItems = benefitLineItems ?? [];

  Map<String, dynamic> toJson() => {
        'notes': notes,
        'solutionCosts': solutionCosts.map((s) => s.toJson()).toList(),
        'projectValueAmount': projectValueAmount,
        'projectValueBenefits': projectValueBenefits,
        'benefitLineItems': benefitLineItems.map((b) => b.toJson()).toList(),
        'savingsNotes': savingsNotes,
        'savingsTarget': savingsTarget,
      };

  factory CostAnalysisData.fromJson(Map<String, dynamic> json) {
    return CostAnalysisData(
      notes: json['notes'] ?? '',
      solutionCosts: (json['solutionCosts'] as List?)?.map((s) => SolutionCostData.fromJson(s)).toList() ?? [],
      projectValueAmount: json['projectValueAmount'] ?? '',
      projectValueBenefits: Map<String, String>.from(json['projectValueBenefits'] ?? {}),
      benefitLineItems: (json['benefitLineItems'] as List?)?.map((b) => BenefitLineItem.fromJson(b)).toList() ?? [],
      savingsNotes: json['savingsNotes'] ?? '',
      savingsTarget: json['savingsTarget'] ?? '',
    );
  }
}

class SolutionCostData {
  String solutionTitle;
  List<CostRowData> costRows;

  SolutionCostData({
    this.solutionTitle = '',
    List<CostRowData>? costRows,
  }) : costRows = costRows ?? [];

  Map<String, dynamic> toJson() => {
        'solutionTitle': solutionTitle,
        'costRows': costRows.map((r) => r.toJson()).toList(),
      };

  factory SolutionCostData.fromJson(Map<String, dynamic> json) {
    return SolutionCostData(
      solutionTitle: json['solutionTitle'] ?? '',
      costRows: (json['costRows'] as List?)?.map((r) => CostRowData.fromJson(r)).toList() ?? [],
    );
  }
}

class CostRowData {
  String itemName;
  String description;
  String cost;
  String assumptions;

  CostRowData({
    this.itemName = '',
    this.description = '',
    this.cost = '',
    this.assumptions = '',
  });

  Map<String, dynamic> toJson() => {
        'itemName': itemName,
        'description': description,
        'cost': cost,
        'assumptions': assumptions,
      };

  factory CostRowData.fromJson(Map<String, dynamic> json) {
    return CostRowData(
      itemName: json['itemName'] ?? '',
      description: json['description'] ?? '',
      cost: json['cost'] ?? '',
      assumptions: json['assumptions'] ?? '',
    );
  }
}

class BenefitLineItem {
  String id;
  String categoryKey;
  String title;
  String unitValue;
  String units;
  String notes;

  BenefitLineItem({
    required this.id,
    this.categoryKey = '',
    this.title = '',
    this.unitValue = '',
    this.units = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryKey': categoryKey,
        'title': title,
        'unitValue': unitValue,
        'units': units,
        'notes': notes,
      };

  factory BenefitLineItem.fromJson(Map<String, dynamic> json) {
    return BenefitLineItem(
      id: json['id'] ?? '',
      categoryKey: json['categoryKey'] ?? '',
      title: json['title'] ?? '',
      unitValue: json['unitValue'] ?? '',
      units: json['units'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}

class ITConsiderationsData {
  String notes;
  List<SolutionITData> solutionITData;

  ITConsiderationsData({
    this.notes = '',
    List<SolutionITData>? solutionITData,
  }) : solutionITData = solutionITData ?? [];

  Map<String, dynamic> toJson() => {
        'notes': notes,
        'solutionITData': solutionITData.map((s) => s.toJson()).toList(),
      };

  factory ITConsiderationsData.fromJson(Map<String, dynamic> json) {
    return ITConsiderationsData(
      notes: json['notes'] ?? '',
      solutionITData: (json['solutionITData'] as List?)?.map((s) => SolutionITData.fromJson(s)).toList() ?? [],
    );
  }
}

class SolutionITData {
  String solutionTitle;
  String coreTechnology;

  SolutionITData({
    this.solutionTitle = '',
    this.coreTechnology = '',
  });

  Map<String, dynamic> toJson() => {
        'solutionTitle': solutionTitle,
        'coreTechnology': coreTechnology,
      };

  factory SolutionITData.fromJson(Map<String, dynamic> json) {
    return SolutionITData(
      solutionTitle: json['solutionTitle'] ?? '',
      coreTechnology: json['coreTechnology'] ?? '',
    );
  }
}

class InfrastructureConsiderationsData {
  String notes;
  List<SolutionInfrastructureData> solutionInfrastructureData;

  InfrastructureConsiderationsData({
    this.notes = '',
    List<SolutionInfrastructureData>? solutionInfrastructureData,
  }) : solutionInfrastructureData = solutionInfrastructureData ?? [];

  Map<String, dynamic> toJson() => {
        'notes': notes,
        'solutionInfrastructureData': solutionInfrastructureData.map((s) => s.toJson()).toList(),
      };

  factory InfrastructureConsiderationsData.fromJson(Map<String, dynamic> json) {
    return InfrastructureConsiderationsData(
      notes: json['notes'] ?? '',
      solutionInfrastructureData: (json['solutionInfrastructureData'] as List?)?.map((s) => SolutionInfrastructureData.fromJson(s)).toList() ?? [],
    );
  }
}

class SolutionInfrastructureData {
  String solutionTitle;
  String majorInfrastructure;

  SolutionInfrastructureData({
    this.solutionTitle = '',
    this.majorInfrastructure = '',
  });

  Map<String, dynamic> toJson() => {
        'solutionTitle': solutionTitle,
        'majorInfrastructure': majorInfrastructure,
      };

  factory SolutionInfrastructureData.fromJson(Map<String, dynamic> json) {
    return SolutionInfrastructureData(
      solutionTitle: json['solutionTitle'] ?? '',
      majorInfrastructure: json['majorInfrastructure'] ?? '',
    );
  }
}

class CoreStakeholdersData {
  String notes;
  List<SolutionStakeholderData> solutionStakeholderData;

  CoreStakeholdersData({
    this.notes = '',
    List<SolutionStakeholderData>? solutionStakeholderData,
  }) : solutionStakeholderData = solutionStakeholderData ?? [];

  Map<String, dynamic> toJson() => {
        'notes': notes,
        'solutionStakeholderData': solutionStakeholderData.map((s) => s.toJson()).toList(),
      };

  factory CoreStakeholdersData.fromJson(Map<String, dynamic> json) {
    return CoreStakeholdersData(
      notes: json['notes'] ?? '',
      solutionStakeholderData: (json['solutionStakeholderData'] as List?)?.map((s) => SolutionStakeholderData.fromJson(s)).toList() ?? [],
    );
  }
}

class SolutionStakeholderData {
  String solutionTitle;
  String notableStakeholders;

  SolutionStakeholderData({
    this.solutionTitle = '',
    this.notableStakeholders = '',
  });

  Map<String, dynamic> toJson() => {
        'solutionTitle': solutionTitle,
        'notableStakeholders': notableStakeholders,
      };

  factory SolutionStakeholderData.fromJson(Map<String, dynamic> json) {
    return SolutionStakeholderData(
      solutionTitle: json['solutionTitle'] ?? '',
      notableStakeholders: json['notableStakeholders'] ?? '',
    );
  }
}
