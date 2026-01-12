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

  // Lessons Learned Data
  LessonsLearnedData lessonsLearnedData;

  // Security Management Data
  SecurityManagementData securityManagementData;

  // Quality Management Data
  QualityManagementData qualityManagementData;

  // Technical Debt Management Data
  TechnicalDebtManagementData technicalDebtManagementData;
  
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

  // Risk Tracking Data
  List<Map<String, dynamic>> trackingRisks;
  
  // Technology and Integration Workspaces
  List<Map<String, dynamic>> technologyInventory;
  List<Map<String, dynamic>> aiIntegrations;
  List<Map<String, dynamic>> externalIntegrations;
  List<Map<String, dynamic>> technologyDefinitions;
  List<Map<String, dynamic>> aiRecommendations;
  
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
    LessonsLearnedData? lessonsLearnedData,
    SecurityManagementData? securityManagementData,
    QualityManagementData? qualityManagementData,
    TechnicalDebtManagementData? technicalDebtManagementData,
    SSHERData? ssherData,
    List<TeamMember>? teamMembers,
    List<LaunchChecklistItem>? launchChecklistItems,
    this.costAnalysisData,
    List<CostEstimateItem>? costEstimateItems,
    this.itConsiderationsData,
    this.infrastructureConsiderationsData,
    this.coreStakeholdersData,
  List<Map<String, dynamic>>? trackingRisks,
  List<Map<String, dynamic>>? technologyInventory,
  List<Map<String, dynamic>>? aiIntegrations,
  List<Map<String, dynamic>>? externalIntegrations,
  List<Map<String, dynamic>>? technologyDefinitions,
  List<Map<String, dynamic>>? aiRecommendations,
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
        lessonsLearnedData = lessonsLearnedData ?? LessonsLearnedData(),
        securityManagementData = securityManagementData ?? SecurityManagementData(),
        qualityManagementData = qualityManagementData ?? QualityManagementData(),
        technicalDebtManagementData = technicalDebtManagementData ?? TechnicalDebtManagementData(),
        ssherData = ssherData ?? SSHERData(),
        teamMembers = teamMembers ?? [],
        launchChecklistItems = launchChecklistItems ?? [],
        costEstimateItems = costEstimateItems ?? [],
  trackingRisks = trackingRisks ?? [],
  technologyInventory = technologyInventory ?? [],
  aiIntegrations = aiIntegrations ?? [],
  externalIntegrations = externalIntegrations ?? [],
  technologyDefinitions = technologyDefinitions ?? [],
  aiRecommendations = aiRecommendations ?? [],
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
    LessonsLearnedData? lessonsLearnedData,
    SecurityManagementData? securityManagementData,
    QualityManagementData? qualityManagementData,
    TechnicalDebtManagementData? technicalDebtManagementData,
    SSHERData? ssherData,
    List<TeamMember>? teamMembers,
    List<LaunchChecklistItem>? launchChecklistItems,
    CostAnalysisData? costAnalysisData,
    List<CostEstimateItem>? costEstimateItems,
    ITConsiderationsData? itConsiderationsData,
    InfrastructureConsiderationsData? infrastructureConsiderationsData,
    CoreStakeholdersData? coreStakeholdersData,
  List<Map<String, dynamic>>? trackingRisks,
  List<Map<String, dynamic>>? technologyInventory,
  List<Map<String, dynamic>>? aiIntegrations,
  List<Map<String, dynamic>>? externalIntegrations,
  List<Map<String, dynamic>>? technologyDefinitions,
  List<Map<String, dynamic>>? aiRecommendations,
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
      lessonsLearnedData: lessonsLearnedData ?? this.lessonsLearnedData,
      securityManagementData: securityManagementData ?? this.securityManagementData,
      qualityManagementData: qualityManagementData ?? this.qualityManagementData,
      technicalDebtManagementData: technicalDebtManagementData ?? this.technicalDebtManagementData,
      ssherData: ssherData ?? this.ssherData,
       teamMembers: teamMembers ?? this.teamMembers,
      launchChecklistItems: launchChecklistItems ?? this.launchChecklistItems,
      costAnalysisData: costAnalysisData ?? this.costAnalysisData,
      costEstimateItems: costEstimateItems ?? this.costEstimateItems,
      itConsiderationsData: itConsiderationsData ?? this.itConsiderationsData,
      infrastructureConsiderationsData: infrastructureConsiderationsData ?? this.infrastructureConsiderationsData,
      coreStakeholdersData: coreStakeholdersData ?? this.coreStakeholdersData,
      trackingRisks: trackingRisks ?? this.trackingRisks,
  technologyInventory: technologyInventory ?? this.technologyInventory,
  aiIntegrations: aiIntegrations ?? this.aiIntegrations,
  externalIntegrations: externalIntegrations ?? this.externalIntegrations,
  technologyDefinitions: technologyDefinitions ?? this.technologyDefinitions,
  aiRecommendations: aiRecommendations ?? this.aiRecommendations,
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
      'lessonsLearnedData': lessonsLearnedData.toJson(),
      'securityManagementData': securityManagementData.toJson(),
      'qualityManagementData': qualityManagementData.toJson(),
      'technicalDebtManagementData': technicalDebtManagementData.toJson(),
      'ssherData': ssherData.toJson(),
      'teamMembers': teamMembers.map((m) => m.toJson()).toList(),
      'launchChecklistItems': launchChecklistItems.map((item) => item.toJson()).toList(),
      if (costAnalysisData != null) 'costAnalysisData': costAnalysisData!.toJson(),
      'costEstimateItems': costEstimateItems.map((item) => item.toJson()).toList(),
      if (itConsiderationsData != null) 'itConsiderationsData': itConsiderationsData!.toJson(),
      if (infrastructureConsiderationsData != null) 'infrastructureConsiderationsData': infrastructureConsiderationsData!.toJson(),
      if (coreStakeholdersData != null) 'coreStakeholdersData': coreStakeholdersData!.toJson(),
  'trackingRisks': trackingRisks,
  'technologyInventory': technologyInventory,
  'aiIntegrations': aiIntegrations,
  'externalIntegrations': externalIntegrations,
  'technologyDefinitions': technologyDefinitions,
  'aiRecommendations': aiRecommendations,
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
      lessonsLearnedData: safeParseSingle('lessonsLearnedData', LessonsLearnedData.fromJson) ?? LessonsLearnedData(),
      securityManagementData: safeParseSingle('securityManagementData', SecurityManagementData.fromJson) ?? SecurityManagementData(),
      qualityManagementData: safeParseSingle('qualityManagementData', QualityManagementData.fromJson) ?? QualityManagementData(),
      technicalDebtManagementData:
          safeParseSingle('technicalDebtManagementData', TechnicalDebtManagementData.fromJson) ?? TechnicalDebtManagementData(),
      ssherData: safeParseSingle('ssherData', SSHERData.fromJson) ?? SSHERData(),
      teamMembers: safeParseList('teamMembers', TeamMember.fromJson),
      launchChecklistItems: safeParseList('launchChecklistItems', LaunchChecklistItem.fromJson),
      costAnalysisData: safeParseSingle('costAnalysisData', CostAnalysisData.fromJson),
      costEstimateItems: safeParseList('costEstimateItems', CostEstimateItem.fromJson),
      itConsiderationsData: safeParseSingle('itConsiderationsData', ITConsiderationsData.fromJson),
      infrastructureConsiderationsData: safeParseSingle('infrastructureConsiderationsData', InfrastructureConsiderationsData.fromJson),
      coreStakeholdersData: safeParseSingle('coreStakeholdersData', CoreStakeholdersData.fromJson),
      trackingRisks: (json['trackingRisks'] is List) ? List<Map<String, dynamic>>.from(json['trackingRisks'] as List) : [],
  technologyInventory: (json['technologyInventory'] is List) ? List<Map<String, dynamic>>.from(json['technologyInventory'] as List) : [],
  aiIntegrations: (json['aiIntegrations'] is List) ? List<Map<String, dynamic>>.from(json['aiIntegrations'] as List) : [],
  externalIntegrations: (json['externalIntegrations'] is List) ? List<Map<String, dynamic>>.from(json['externalIntegrations'] as List) : [],
  technologyDefinitions: (json['technologyDefinitions'] is List) ? List<Map<String, dynamic>>.from(json['technologyDefinitions'] as List) : [],
  aiRecommendations: (json['aiRecommendations'] is List) ? List<Map<String, dynamic>>.from(json['aiRecommendations'] as List) : [],
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

class LessonsLearnedEntry {
  String id;
  String lesson;
  String type;
  String category;
  String phase;
  String impact;
  String status;
  String submittedBy;
  String date;
  bool highlight;

  LessonsLearnedEntry({
    this.id = '',
    this.lesson = '',
    this.type = '',
    this.category = '',
    this.phase = '',
    this.impact = '',
    this.status = '',
    this.submittedBy = '',
    this.date = '',
    this.highlight = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lesson': lesson,
        'type': type,
        'category': category,
        'phase': phase,
        'impact': impact,
        'status': status,
        'submittedBy': submittedBy,
        'date': date,
        'highlight': highlight,
      };

  factory LessonsLearnedEntry.fromJson(Map<String, dynamic> json) {
    return LessonsLearnedEntry(
      id: json['id'] ?? '',
      lesson: json['lesson'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      phase: json['phase'] ?? '',
      impact: json['impact'] ?? '',
      status: json['status'] ?? '',
      submittedBy: json['submittedBy'] ?? '',
      date: json['date'] ?? '',
      highlight: json['highlight'] ?? false,
    );
  }
}

class LessonsLearnedData {
  List<LessonsLearnedEntry> entries;
  List<String> benefits;
  bool aiSeeded;

  LessonsLearnedData({
    List<LessonsLearnedEntry>? entries,
    List<String>? benefits,
    this.aiSeeded = false,
  })  : entries = entries ?? [],
        benefits = benefits ?? [];

  Map<String, dynamic> toJson() => {
        'entries': entries.map((entry) => entry.toJson()).toList(),
        'benefits': benefits,
        'aiSeeded': aiSeeded,
      };

  factory LessonsLearnedData.fromJson(Map<String, dynamic> json) {
    return LessonsLearnedData(
      entries: (json['entries'] as List?)
              ?.map((item) => LessonsLearnedEntry.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      benefits: (json['benefits'] as List?)?.map((item) => item.toString()).toList() ?? [],
      aiSeeded: json['aiSeeded'] ?? false,
    );
  }
}

class SecurityRoleData {
  String name;
  String tierLabel;
  String description;
  String createdDate;

  SecurityRoleData({
    this.name = '',
    this.tierLabel = '',
    this.description = '',
    this.createdDate = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'tierLabel': tierLabel,
        'description': description,
        'createdDate': createdDate,
      };

  factory SecurityRoleData.fromJson(Map<String, dynamic> json) {
    return SecurityRoleData(
      name: json['name'] ?? '',
      tierLabel: json['tierLabel'] ?? '',
      description: json['description'] ?? '',
      createdDate: json['createdDate'] ?? '',
    );
  }
}

class SecurityPermissionData {
  String name;
  String resource;
  String action;
  String description;

  SecurityPermissionData({
    this.name = '',
    this.resource = '',
    this.action = '',
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'resource': resource,
        'action': action,
        'description': description,
      };

  factory SecurityPermissionData.fromJson(Map<String, dynamic> json) {
    return SecurityPermissionData(
      name: json['name'] ?? '',
      resource: json['resource'] ?? '',
      action: json['action'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class SecurityAccessLogData {
  String timestamp;
  String user;
  String action;
  String resource;
  String status;
  String ipAddress;

  SecurityAccessLogData({
    this.timestamp = '',
    this.user = '',
    this.action = '',
    this.resource = '',
    this.status = '',
    this.ipAddress = '',
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'user': user,
        'action': action,
        'resource': resource,
        'status': status,
        'ipAddress': ipAddress,
      };

  factory SecurityAccessLogData.fromJson(Map<String, dynamic> json) {
    return SecurityAccessLogData(
      timestamp: json['timestamp'] ?? '',
      user: json['user'] ?? '',
      action: json['action'] ?? '',
      resource: json['resource'] ?? '',
      status: json['status'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
    );
  }
}

class SecuritySettingsData {
  int sessionTimeoutMinutes;
  int minPasswordLength;
  bool requireMfa;
  bool requireUppercase;
  bool requireNumbers;
  bool requireSpecial;

  SecuritySettingsData({
    this.sessionTimeoutMinutes = 30,
    this.minPasswordLength = 10,
    this.requireMfa = true,
    this.requireUppercase = true,
    this.requireNumbers = true,
    this.requireSpecial = true,
  });

  Map<String, dynamic> toJson() => {
        'sessionTimeoutMinutes': sessionTimeoutMinutes,
        'minPasswordLength': minPasswordLength,
        'requireMfa': requireMfa,
        'requireUppercase': requireUppercase,
        'requireNumbers': requireNumbers,
        'requireSpecial': requireSpecial,
      };

  factory SecuritySettingsData.fromJson(Map<String, dynamic> json) {
    return SecuritySettingsData(
      sessionTimeoutMinutes: (json['sessionTimeoutMinutes'] as num?)?.toInt() ?? 30,
      minPasswordLength: (json['minPasswordLength'] as num?)?.toInt() ?? 10,
      requireMfa: json['requireMfa'] ?? true,
      requireUppercase: json['requireUppercase'] ?? true,
      requireNumbers: json['requireNumbers'] ?? true,
      requireSpecial: json['requireSpecial'] ?? true,
    );
  }
}

class SecurityManagementData {
  List<SecurityRoleData> roles;
  List<SecurityPermissionData> permissions;
  List<SecurityAccessLogData> accessLogs;
  SecuritySettingsData settings;
  bool aiSeeded;

  SecurityManagementData({
    List<SecurityRoleData>? roles,
    List<SecurityPermissionData>? permissions,
    List<SecurityAccessLogData>? accessLogs,
    SecuritySettingsData? settings,
    this.aiSeeded = false,
  })  : roles = roles ?? [],
        permissions = permissions ?? [],
        accessLogs = accessLogs ?? [],
        settings = settings ?? SecuritySettingsData();

  Map<String, dynamic> toJson() => {
        'roles': roles.map((item) => item.toJson()).toList(),
        'permissions': permissions.map((item) => item.toJson()).toList(),
        'accessLogs': accessLogs.map((item) => item.toJson()).toList(),
        'settings': settings.toJson(),
        'aiSeeded': aiSeeded,
      };

  factory SecurityManagementData.fromJson(Map<String, dynamic> json) {
    return SecurityManagementData(
      roles: (json['roles'] as List?)?.map((item) => SecurityRoleData.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      permissions: (json['permissions'] as List?)
              ?.map((item) => SecurityPermissionData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      accessLogs: (json['accessLogs'] as List?)
              ?.map((item) => SecurityAccessLogData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      settings: json['settings'] is Map ? SecuritySettingsData.fromJson(json['settings'] as Map<String, dynamic>) : SecuritySettingsData(),
      aiSeeded: json['aiSeeded'] ?? false,
    );
  }
}

class QualityTargetData {
  String name;
  String metric;
  String target;
  String current;
  String status;

  QualityTargetData({
    this.name = '',
    this.metric = '',
    this.target = '',
    this.current = '',
    this.status = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'metric': metric,
        'target': target,
        'current': current,
        'status': status,
      };

  factory QualityTargetData.fromJson(Map<String, dynamic> json) {
    return QualityTargetData(
      name: json['name'] ?? '',
      metric: json['metric'] ?? '',
      target: json['target'] ?? '',
      current: json['current'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class QaTechniqueData {
  String name;
  String description;
  String frequency;
  String standards;

  QaTechniqueData({
    this.name = '',
    this.description = '',
    this.frequency = '',
    this.standards = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'frequency': frequency,
        'standards': standards,
      };

  factory QaTechniqueData.fromJson(Map<String, dynamic> json) {
    return QaTechniqueData(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      frequency: json['frequency'] ?? '',
      standards: json['standards'] ?? '',
    );
  }
}

class QcTechniqueData {
  String name;
  String description;
  String frequency;

  QcTechniqueData({
    this.name = '',
    this.description = '',
    this.frequency = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'frequency': frequency,
      };

  factory QcTechniqueData.fromJson(Map<String, dynamic> json) {
    return QcTechniqueData(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      frequency: json['frequency'] ?? '',
    );
  }
}

class QualityMetricSummaryData {
  String title;
  String value;
  String changeLabel;
  String changeContext;
  String trend;

  QualityMetricSummaryData({
    this.title = '',
    this.value = '',
    this.changeLabel = '',
    this.changeContext = '',
    this.trend = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'value': value,
        'changeLabel': changeLabel,
        'changeContext': changeContext,
        'trend': trend,
      };

  factory QualityMetricSummaryData.fromJson(Map<String, dynamic> json) {
    return QualityMetricSummaryData(
      title: json['title'] ?? '',
      value: json['value'] ?? '',
      changeLabel: json['changeLabel'] ?? '',
      changeContext: json['changeContext'] ?? '',
      trend: json['trend'] ?? '',
    );
  }
}

class QualityTrendSeriesData {
  String title;
  String subtitle;
  List<double> dataPoints;
  List<String> labels;
  double maxYBuffer;

  QualityTrendSeriesData({
    this.title = '',
    this.subtitle = '',
    List<double>? dataPoints,
    List<String>? labels,
    this.maxYBuffer = 0,
  })  : dataPoints = dataPoints ?? [],
        labels = labels ?? [];

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'dataPoints': dataPoints,
        'labels': labels,
        'maxYBuffer': maxYBuffer,
      };

  factory QualityTrendSeriesData.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return QualityTrendSeriesData(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      dataPoints: (json['dataPoints'] as List?)?.map((item) => parseDouble(item)).toList() ?? [],
      labels: (json['labels'] as List?)?.map((item) => item.toString()).toList() ?? [],
      maxYBuffer: (json['maxYBuffer'] as num?)?.toDouble() ?? 0,
    );
  }
}

class QualityManagementData {
  String plan;
  List<QualityTargetData> targets;
  List<QaTechniqueData> qaTechniques;
  List<QcTechniqueData> qcTechniques;
  List<QualityMetricSummaryData> metricSummaries;
  QualityTrendSeriesData defectTrend;
  QualityTrendSeriesData satisfactionTrend;
  bool aiSeeded;

  QualityManagementData({
    this.plan = '',
    List<QualityTargetData>? targets,
    List<QaTechniqueData>? qaTechniques,
    List<QcTechniqueData>? qcTechniques,
    List<QualityMetricSummaryData>? metricSummaries,
    QualityTrendSeriesData? defectTrend,
    QualityTrendSeriesData? satisfactionTrend,
    this.aiSeeded = false,
  })  : targets = targets ?? [],
        qaTechniques = qaTechniques ?? [],
        qcTechniques = qcTechniques ?? [],
        metricSummaries = metricSummaries ?? [],
        defectTrend = defectTrend ?? QualityTrendSeriesData(),
        satisfactionTrend = satisfactionTrend ?? QualityTrendSeriesData();

  Map<String, dynamic> toJson() => {
        'plan': plan,
        'targets': targets.map((item) => item.toJson()).toList(),
        'qaTechniques': qaTechniques.map((item) => item.toJson()).toList(),
        'qcTechniques': qcTechniques.map((item) => item.toJson()).toList(),
        'metricSummaries': metricSummaries.map((item) => item.toJson()).toList(),
        'defectTrend': defectTrend.toJson(),
        'satisfactionTrend': satisfactionTrend.toJson(),
        'aiSeeded': aiSeeded,
      };

  factory QualityManagementData.fromJson(Map<String, dynamic> json) {
    return QualityManagementData(
      plan: json['plan'] ?? '',
      targets: (json['targets'] as List?)?.map((item) => QualityTargetData.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      qaTechniques:
          (json['qaTechniques'] as List?)?.map((item) => QaTechniqueData.fromJson(item as Map<String, dynamic>)).toList() ??
              [],
      qcTechniques:
          (json['qcTechniques'] as List?)?.map((item) => QcTechniqueData.fromJson(item as Map<String, dynamic>)).toList() ??
              [],
      metricSummaries: (json['metricSummaries'] as List?)
              ?.map((item) => QualityMetricSummaryData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      defectTrend: json['defectTrend'] is Map
          ? QualityTrendSeriesData.fromJson(json['defectTrend'] as Map<String, dynamic>)
          : QualityTrendSeriesData(),
      satisfactionTrend: json['satisfactionTrend'] is Map
          ? QualityTrendSeriesData.fromJson(json['satisfactionTrend'] as Map<String, dynamic>)
          : QualityTrendSeriesData(),
      aiSeeded: json['aiSeeded'] ?? false,
    );
  }
}

class TechnicalDebtStatData {
  String label;
  String value;
  String supporting;
  String tone;

  TechnicalDebtStatData({
    this.label = '',
    this.value = '',
    this.supporting = '',
    this.tone = '',
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        'supporting': supporting,
        'tone': tone,
      };

  factory TechnicalDebtStatData.fromJson(Map<String, dynamic> json) {
    return TechnicalDebtStatData(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
      supporting: json['supporting'] ?? '',
      tone: json['tone'] ?? '',
    );
  }
}

class TechnicalDebtItemData {
  String id;
  String title;
  String area;
  String owner;
  String severity;
  String status;
  String target;

  TechnicalDebtItemData({
    this.id = '',
    this.title = '',
    this.area = '',
    this.owner = '',
    this.severity = '',
    this.status = '',
    this.target = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'area': area,
        'owner': owner,
        'severity': severity,
        'status': status,
        'target': target,
      };

  factory TechnicalDebtItemData.fromJson(Map<String, dynamic> json) {
    return TechnicalDebtItemData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      area: json['area'] ?? '',
      owner: json['owner'] ?? '',
      severity: json['severity'] ?? '',
      status: json['status'] ?? '',
      target: json['target'] ?? '',
    );
  }
}

class TechnicalDebtInsightData {
  String title;
  String subtitle;

  TechnicalDebtInsightData({
    this.title = '',
    this.subtitle = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
      };

  factory TechnicalDebtInsightData.fromJson(Map<String, dynamic> json) {
    return TechnicalDebtInsightData(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
    );
  }
}

class TechnicalDebtTrackData {
  String label;
  double progress;
  String tone;

  TechnicalDebtTrackData({
    this.label = '',
    this.progress = 0,
    this.tone = '',
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'progress': progress,
        'tone': tone,
      };

  factory TechnicalDebtTrackData.fromJson(Map<String, dynamic> json) {
    return TechnicalDebtTrackData(
      label: json['label'] ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      tone: json['tone'] ?? '',
    );
  }
}

class TechnicalDebtOwnerData {
  String name;
  String count;
  String note;

  TechnicalDebtOwnerData({
    this.name = '',
    this.count = '',
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'count': count,
        'note': note,
      };

  factory TechnicalDebtOwnerData.fromJson(Map<String, dynamic> json) {
    return TechnicalDebtOwnerData(
      name: json['name'] ?? '',
      count: json['count'] ?? '',
      note: json['note'] ?? '',
    );
  }
}

class TechnicalDebtManagementData {
  List<TechnicalDebtStatData> stats;
  List<TechnicalDebtItemData> items;
  List<TechnicalDebtInsightData> insights;
  List<TechnicalDebtTrackData> tracks;
  List<TechnicalDebtOwnerData> owners;
  bool aiSeeded;

  TechnicalDebtManagementData({
    List<TechnicalDebtStatData>? stats,
    List<TechnicalDebtItemData>? items,
    List<TechnicalDebtInsightData>? insights,
    List<TechnicalDebtTrackData>? tracks,
    List<TechnicalDebtOwnerData>? owners,
    this.aiSeeded = false,
  })  : stats = stats ?? [],
        items = items ?? [],
        insights = insights ?? [],
        tracks = tracks ?? [],
        owners = owners ?? [];

  Map<String, dynamic> toJson() => {
        'stats': stats.map((item) => item.toJson()).toList(),
        'items': items.map((item) => item.toJson()).toList(),
        'insights': insights.map((item) => item.toJson()).toList(),
        'tracks': tracks.map((item) => item.toJson()).toList(),
        'owners': owners.map((item) => item.toJson()).toList(),
        'aiSeeded': aiSeeded,
      };

  factory TechnicalDebtManagementData.fromJson(Map<String, dynamic> json) {
    return TechnicalDebtManagementData(
      stats: (json['stats'] as List?)
              ?.map((item) => TechnicalDebtStatData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      items: (json['items'] as List?)
              ?.map((item) => TechnicalDebtItemData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      insights: (json['insights'] as List?)
              ?.map((item) => TechnicalDebtInsightData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      tracks: (json['tracks'] as List?)
              ?.map((item) => TechnicalDebtTrackData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      owners: (json['owners'] as List?)
              ?.map((item) => TechnicalDebtOwnerData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      aiSeeded: json['aiSeeded'] ?? false,
    );
  }
}

class ProcurementWorkspaceData {
  List<ProcurementItemData> items;
  List<ProcurementStrategyData> strategies;
  List<ProcurementVendorData> vendors;
  List<ProcurementVendorHealthMetricData> vendorHealthMetrics;
  List<ProcurementVendorOnboardingTaskData> vendorOnboardingTasks;
  List<ProcurementVendorRiskData> vendorRiskItems;
  List<ProcurementRfqData> rfqs;
  List<ProcurementRfqCriterionData> rfqCriteria;
  List<ProcurementPurchaseOrderData> purchaseOrders;
  List<ProcurementTrackableItemData> trackableItems;
  List<ProcurementTrackingAlertData> trackingAlerts;
  List<ProcurementCarrierPerformanceData> carrierPerformance;
  List<ProcurementReportKpiData> reportKpis;
  List<ProcurementSpendBreakdownData> spendBreakdown;
  List<ProcurementLeadTimeMetricData> leadTimeMetrics;
  List<ProcurementSavingsOpportunityData> savingsOpportunities;
  List<ProcurementComplianceMetricData> complianceMetrics;
  bool aiSeeded;

  ProcurementWorkspaceData({
    List<ProcurementItemData>? items,
    List<ProcurementStrategyData>? strategies,
    List<ProcurementVendorData>? vendors,
    List<ProcurementVendorHealthMetricData>? vendorHealthMetrics,
    List<ProcurementVendorOnboardingTaskData>? vendorOnboardingTasks,
    List<ProcurementVendorRiskData>? vendorRiskItems,
    List<ProcurementRfqData>? rfqs,
    List<ProcurementRfqCriterionData>? rfqCriteria,
    List<ProcurementPurchaseOrderData>? purchaseOrders,
    List<ProcurementTrackableItemData>? trackableItems,
    List<ProcurementTrackingAlertData>? trackingAlerts,
    List<ProcurementCarrierPerformanceData>? carrierPerformance,
    List<ProcurementReportKpiData>? reportKpis,
    List<ProcurementSpendBreakdownData>? spendBreakdown,
    List<ProcurementLeadTimeMetricData>? leadTimeMetrics,
    List<ProcurementSavingsOpportunityData>? savingsOpportunities,
    List<ProcurementComplianceMetricData>? complianceMetrics,
    this.aiSeeded = false,
  })  : items = items ?? [],
        strategies = strategies ?? [],
        vendors = vendors ?? [],
        vendorHealthMetrics = vendorHealthMetrics ?? [],
        vendorOnboardingTasks = vendorOnboardingTasks ?? [],
        vendorRiskItems = vendorRiskItems ?? [],
        rfqs = rfqs ?? [],
        rfqCriteria = rfqCriteria ?? [],
        purchaseOrders = purchaseOrders ?? [],
        trackableItems = trackableItems ?? [],
        trackingAlerts = trackingAlerts ?? [],
        carrierPerformance = carrierPerformance ?? [],
        reportKpis = reportKpis ?? [],
        spendBreakdown = spendBreakdown ?? [],
        leadTimeMetrics = leadTimeMetrics ?? [],
        savingsOpportunities = savingsOpportunities ?? [],
        complianceMetrics = complianceMetrics ?? [];

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
        'strategies': strategies.map((item) => item.toJson()).toList(),
        'vendors': vendors.map((item) => item.toJson()).toList(),
        'vendorHealthMetrics': vendorHealthMetrics.map((item) => item.toJson()).toList(),
        'vendorOnboardingTasks': vendorOnboardingTasks.map((item) => item.toJson()).toList(),
        'vendorRiskItems': vendorRiskItems.map((item) => item.toJson()).toList(),
        'rfqs': rfqs.map((item) => item.toJson()).toList(),
        'rfqCriteria': rfqCriteria.map((item) => item.toJson()).toList(),
        'purchaseOrders': purchaseOrders.map((item) => item.toJson()).toList(),
        'trackableItems': trackableItems.map((item) => item.toJson()).toList(),
        'trackingAlerts': trackingAlerts.map((item) => item.toJson()).toList(),
        'carrierPerformance': carrierPerformance.map((item) => item.toJson()).toList(),
        'reportKpis': reportKpis.map((item) => item.toJson()).toList(),
        'spendBreakdown': spendBreakdown.map((item) => item.toJson()).toList(),
        'leadTimeMetrics': leadTimeMetrics.map((item) => item.toJson()).toList(),
        'savingsOpportunities': savingsOpportunities.map((item) => item.toJson()).toList(),
        'complianceMetrics': complianceMetrics.map((item) => item.toJson()).toList(),
        'aiSeeded': aiSeeded,
      };

  factory ProcurementWorkspaceData.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) parser) {
      try {
        final list = json[key] as List?;
        if (list == null) return [];
        return list.map((item) => parser(item as Map<String, dynamic>)).toList();
      } catch (_) {
        return [];
      }
    }

    return ProcurementWorkspaceData(
      items: parseList('items', ProcurementItemData.fromJson),
      strategies: parseList('strategies', ProcurementStrategyData.fromJson),
      vendors: parseList('vendors', ProcurementVendorData.fromJson),
      vendorHealthMetrics: parseList('vendorHealthMetrics', ProcurementVendorHealthMetricData.fromJson),
      vendorOnboardingTasks: parseList('vendorOnboardingTasks', ProcurementVendorOnboardingTaskData.fromJson),
      vendorRiskItems: parseList('vendorRiskItems', ProcurementVendorRiskData.fromJson),
      rfqs: parseList('rfqs', ProcurementRfqData.fromJson),
      rfqCriteria: parseList('rfqCriteria', ProcurementRfqCriterionData.fromJson),
      purchaseOrders: parseList('purchaseOrders', ProcurementPurchaseOrderData.fromJson),
      trackableItems: parseList('trackableItems', ProcurementTrackableItemData.fromJson),
      trackingAlerts: parseList('trackingAlerts', ProcurementTrackingAlertData.fromJson),
      carrierPerformance: parseList('carrierPerformance', ProcurementCarrierPerformanceData.fromJson),
      reportKpis: parseList('reportKpis', ProcurementReportKpiData.fromJson),
      spendBreakdown: parseList('spendBreakdown', ProcurementSpendBreakdownData.fromJson),
      leadTimeMetrics: parseList('leadTimeMetrics', ProcurementLeadTimeMetricData.fromJson),
      savingsOpportunities: parseList('savingsOpportunities', ProcurementSavingsOpportunityData.fromJson),
      complianceMetrics: parseList('complianceMetrics', ProcurementComplianceMetricData.fromJson),
      aiSeeded: json['aiSeeded'] ?? false,
    );
  }
}

class ProcurementItemData {
  String name;
  String description;
  String category;
  String status;
  String priority;
  int budget;
  String estimatedDelivery;
  double progress;

  ProcurementItemData({
    this.name = '',
    this.description = '',
    this.category = '',
    this.status = '',
    this.priority = '',
    this.budget = 0,
    this.estimatedDelivery = '',
    this.progress = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'category': category,
        'status': status,
        'priority': priority,
        'budget': budget,
        'estimatedDelivery': estimatedDelivery,
        'progress': progress,
      };

  factory ProcurementItemData.fromJson(Map<String, dynamic> json) {
    return ProcurementItemData(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
      budget: (json['budget'] as num?)?.toInt() ?? 0,
      estimatedDelivery: json['estimatedDelivery'] ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ProcurementStrategyData {
  String title;
  String status;
  int itemCount;
  String description;

  ProcurementStrategyData({
    this.title = '',
    this.status = '',
    this.itemCount = 0,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'status': status,
        'itemCount': itemCount,
        'description': description,
      };

  factory ProcurementStrategyData.fromJson(Map<String, dynamic> json) {
    return ProcurementStrategyData(
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      description: json['description'] ?? '',
    );
  }
}

class ProcurementVendorData {
  String initials;
  String name;
  String category;
  int rating;
  bool approved;
  bool preferred;

  ProcurementVendorData({
    this.initials = '',
    this.name = '',
    this.category = '',
    this.rating = 0,
    this.approved = false,
    this.preferred = false,
  });

  Map<String, dynamic> toJson() => {
        'initials': initials,
        'name': name,
        'category': category,
        'rating': rating,
        'approved': approved,
        'preferred': preferred,
      };

  factory ProcurementVendorData.fromJson(Map<String, dynamic> json) {
    return ProcurementVendorData(
      initials: json['initials'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      approved: json['approved'] ?? false,
      preferred: json['preferred'] ?? false,
    );
  }
}

class ProcurementVendorHealthMetricData {
  String category;
  double score;
  String change;

  ProcurementVendorHealthMetricData({
    this.category = '',
    this.score = 0,
    this.change = '',
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'score': score,
        'change': change,
      };

  factory ProcurementVendorHealthMetricData.fromJson(Map<String, dynamic> json) {
    return ProcurementVendorHealthMetricData(
      category: json['category'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      change: json['change'] ?? '',
    );
  }
}

class ProcurementVendorOnboardingTaskData {
  String title;
  String owner;
  String dueDate;
  String status;

  ProcurementVendorOnboardingTaskData({
    this.title = '',
    this.owner = '',
    this.dueDate = '',
    this.status = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'owner': owner,
        'dueDate': dueDate,
        'status': status,
      };

  factory ProcurementVendorOnboardingTaskData.fromJson(Map<String, dynamic> json) {
    return ProcurementVendorOnboardingTaskData(
      title: json['title'] ?? '',
      owner: json['owner'] ?? '',
      dueDate: json['dueDate'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class ProcurementVendorRiskData {
  String vendor;
  String risk;
  String severity;
  String lastIncident;

  ProcurementVendorRiskData({
    this.vendor = '',
    this.risk = '',
    this.severity = '',
    this.lastIncident = '',
  });

  Map<String, dynamic> toJson() => {
        'vendor': vendor,
        'risk': risk,
        'severity': severity,
        'lastIncident': lastIncident,
      };

  factory ProcurementVendorRiskData.fromJson(Map<String, dynamic> json) {
    return ProcurementVendorRiskData(
      vendor: json['vendor'] ?? '',
      risk: json['risk'] ?? '',
      severity: json['severity'] ?? '',
      lastIncident: json['lastIncident'] ?? '',
    );
  }
}

class ProcurementRfqData {
  String title;
  String category;
  String owner;
  String dueDate;
  int invited;
  int responses;
  int budget;
  String status;
  String priority;

  ProcurementRfqData({
    this.title = '',
    this.category = '',
    this.owner = '',
    this.dueDate = '',
    this.invited = 0,
    this.responses = 0,
    this.budget = 0,
    this.status = '',
    this.priority = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'owner': owner,
        'dueDate': dueDate,
        'invited': invited,
        'responses': responses,
        'budget': budget,
        'status': status,
        'priority': priority,
      };

  factory ProcurementRfqData.fromJson(Map<String, dynamic> json) {
    return ProcurementRfqData(
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      owner: json['owner'] ?? '',
      dueDate: json['dueDate'] ?? '',
      invited: (json['invited'] as num?)?.toInt() ?? 0,
      responses: (json['responses'] as num?)?.toInt() ?? 0,
      budget: (json['budget'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
    );
  }
}

class ProcurementRfqCriterionData {
  String label;
  double weight;

  ProcurementRfqCriterionData({
    this.label = '',
    this.weight = 0,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'weight': weight,
      };

  factory ProcurementRfqCriterionData.fromJson(Map<String, dynamic> json) {
    return ProcurementRfqCriterionData(
      label: json['label'] ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ProcurementPurchaseOrderData {
  String id;
  String vendor;
  String category;
  String owner;
  String orderedDate;
  String expectedDate;
  int amount;
  double progress;
  String status;

  ProcurementPurchaseOrderData({
    this.id = '',
    this.vendor = '',
    this.category = '',
    this.owner = '',
    this.orderedDate = '',
    this.expectedDate = '',
    this.amount = 0,
    this.progress = 0,
    this.status = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor': vendor,
        'category': category,
        'owner': owner,
        'orderedDate': orderedDate,
        'expectedDate': expectedDate,
        'amount': amount,
        'progress': progress,
        'status': status,
      };

  factory ProcurementPurchaseOrderData.fromJson(Map<String, dynamic> json) {
    return ProcurementPurchaseOrderData(
      id: json['id'] ?? '',
      vendor: json['vendor'] ?? '',
      category: json['category'] ?? '',
      owner: json['owner'] ?? '',
      orderedDate: json['orderedDate'] ?? '',
      expectedDate: json['expectedDate'] ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? '',
    );
  }
}

class ProcurementTrackableItemData {
  String name;
  String description;
  String orderStatus;
  String currentStatus;
  String? lastUpdate;
  List<ProcurementTimelineEventData> events;

  ProcurementTrackableItemData({
    this.name = '',
    this.description = '',
    this.orderStatus = '',
    this.currentStatus = '',
    this.lastUpdate,
    List<ProcurementTimelineEventData>? events,
  }) : events = events ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'orderStatus': orderStatus,
        'currentStatus': currentStatus,
        'lastUpdate': lastUpdate,
        'events': events.map((event) => event.toJson()).toList(),
      };

  factory ProcurementTrackableItemData.fromJson(Map<String, dynamic> json) {
    return ProcurementTrackableItemData(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      orderStatus: json['orderStatus'] ?? '',
      currentStatus: json['currentStatus'] ?? '',
      lastUpdate: json['lastUpdate'],
      events: (json['events'] as List?)?.map((e) => ProcurementTimelineEventData.fromJson(e)).toList() ?? [],
    );
  }
}

class ProcurementTimelineEventData {
  String title;
  String description;
  String subtext;
  String date;

  ProcurementTimelineEventData({
    this.title = '',
    this.description = '',
    this.subtext = '',
    this.date = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'subtext': subtext,
        'date': date,
      };

  factory ProcurementTimelineEventData.fromJson(Map<String, dynamic> json) {
    return ProcurementTimelineEventData(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subtext: json['subtext'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class ProcurementTrackingAlertData {
  String title;
  String description;
  String severity;
  String date;

  ProcurementTrackingAlertData({
    this.title = '',
    this.description = '',
    this.severity = '',
    this.date = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'severity': severity,
        'date': date,
      };

  factory ProcurementTrackingAlertData.fromJson(Map<String, dynamic> json) {
    return ProcurementTrackingAlertData(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class ProcurementCarrierPerformanceData {
  String carrier;
  int onTimeRate;
  int avgDays;

  ProcurementCarrierPerformanceData({
    this.carrier = '',
    this.onTimeRate = 0,
    this.avgDays = 0,
  });

  Map<String, dynamic> toJson() => {
        'carrier': carrier,
        'onTimeRate': onTimeRate,
        'avgDays': avgDays,
      };

  factory ProcurementCarrierPerformanceData.fromJson(Map<String, dynamic> json) {
    return ProcurementCarrierPerformanceData(
      carrier: json['carrier'] ?? '',
      onTimeRate: (json['onTimeRate'] as num?)?.toInt() ?? 0,
      avgDays: (json['avgDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProcurementReportKpiData {
  String label;
  String value;
  String delta;
  bool positive;

  ProcurementReportKpiData({
    this.label = '',
    this.value = '',
    this.delta = '',
    this.positive = true,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        'delta': delta,
        'positive': positive,
      };

  factory ProcurementReportKpiData.fromJson(Map<String, dynamic> json) {
    return ProcurementReportKpiData(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
      delta: json['delta'] ?? '',
      positive: json['positive'] ?? true,
    );
  }
}

class ProcurementSpendBreakdownData {
  String label;
  int amount;
  double percent;
  int colorValue;

  ProcurementSpendBreakdownData({
    this.label = '',
    this.amount = 0,
    this.percent = 0,
    this.colorValue = 0,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'percent': percent,
        'colorValue': colorValue,
      };

  factory ProcurementSpendBreakdownData.fromJson(Map<String, dynamic> json) {
    return ProcurementSpendBreakdownData(
      label: json['label'] ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProcurementLeadTimeMetricData {
  String label;
  double onTimeRate;

  ProcurementLeadTimeMetricData({
    this.label = '',
    this.onTimeRate = 0,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'onTimeRate': onTimeRate,
      };

  factory ProcurementLeadTimeMetricData.fromJson(Map<String, dynamic> json) {
    return ProcurementLeadTimeMetricData(
      label: json['label'] ?? '',
      onTimeRate: (json['onTimeRate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ProcurementSavingsOpportunityData {
  String title;
  String value;
  String owner;

  ProcurementSavingsOpportunityData({
    this.title = '',
    this.value = '',
    this.owner = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'value': value,
        'owner': owner,
      };

  factory ProcurementSavingsOpportunityData.fromJson(Map<String, dynamic> json) {
    return ProcurementSavingsOpportunityData(
      title: json['title'] ?? '',
      value: json['value'] ?? '',
      owner: json['owner'] ?? '',
    );
  }
}

class ProcurementComplianceMetricData {
  String label;
  double value;

  ProcurementComplianceMetricData({
    this.label = '',
    this.value = 0,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
      };

  factory ProcurementComplianceMetricData.fromJson(Map<String, dynamic> json) {
    return ProcurementComplianceMetricData(
      label: json['label'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
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
  ProcurementWorkspaceData procurementWorkspace;

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
    ProcurementWorkspaceData? procurementWorkspace,
  })  : requirementItems = requirementItems ?? [],
        procurementWorkspace = procurementWorkspace ?? ProcurementWorkspaceData();

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
        'procurementWorkspace': procurementWorkspace.toJson(),
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
      procurementWorkspace: json['procurementWorkspace'] is Map
          ? ProcurementWorkspaceData.fromJson(json['procurementWorkspace'] as Map<String, dynamic>)
          : ProcurementWorkspaceData(),
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
  String id;
  String name;
  String role;
  String email;
  String responsibilities;

  TeamMember({
    String? id,
    this.name = '',
    this.role = '',
    this.email = '',
    this.responsibilities = '',
  }) : id = id ?? _generateId();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'email': email,
        'responsibilities': responsibilities,
      };

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      email: json['email'] ?? '',
      responsibilities: json['responsibilities'] ?? '',
    );
  }

  static String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
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
