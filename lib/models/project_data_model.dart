import 'package:flutter/foundation.dart';

/// Comprehensive project data model that captures all information across the application flow
class ProjectDataModel {
  // Initiation Phase Data
  String projectName;
  String solutionTitle;
  String solutionDescription;
  String businessCase;
  String notes;

  // Strategic Planning Data (editable in Project Details)
  List<String> assumptions;
  List<String> constraints;
  List<String> outOfScope;
  List<String> opportunities;

  // Project Charter (editable in Project Charter screen)
  String charterAssumptions;
  String charterConstraints;
  String charterProjectManagerName;
  String charterProjectSponsorName;
  String charterReviewedBy; // Added
  DateTime? charterApprovalDate; // Added
  String charterEmail;
  String charterPhone;
  String charterOrganizationalUnit;
  String charterGreenBelt;
  String charterBlackBelt;
  List<String> tags;
  List<Contractor> contractors; // Added
  List<Vendor> vendors; // Added
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
  List<WorkItem> wbsTree;

  // Issue Management Data
  List<IssueLogItem> issueLogItems;
  // Lessons learned
  List<LessonRecord> lessonsLearned;

  // Front End Planning Data
  FrontEndPlanningData frontEndPlanning;
  // Technology/IT Data
  List<Map<String, dynamic>> technologyDefinitions;
  List<Map<String, dynamic>> technologyInventory;

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

  // Organisation Plan Data
  List<RoleDefinition> projectRoles;
  List<StaffingRequirement> staffingRequirements;
  List<TrainingActivity> trainingActivities;

  // Design Deliverables Data
  DesignDeliverablesData designDeliverablesData;

  // Design Management Data
  DesignManagementData? designManagementData;

  // Execution Phase Data
  ExecutionPhaseData? executionPhaseData;

  // Stakeholder Management Data
  List<StakeholderEntry> stakeholderEntries;
  List<EngagementPlanEntry> engagementPlanEntries;

  // Quality Management Data
  QualityManagementData? qualityManagementData;

  // Metadata
  bool isBasicPlanProject;
  Map<String, int> aiUsageCounts;

  List<Map<String, dynamic>> aiIntegrations;
  List<Map<String, dynamic>> aiRecommendations;
  String? projectId;
  DateTime? createdAt;
  DateTime? updatedAt;
  String currentCheckpoint;

  // Field History Tracking for Undo functionality
  Map<String, FieldHistory> fieldHistories;

  // Currency setting for Cost-Benefit Analysis
  String costBenefitCurrency;

  // Preferred Solution Reference
  String? preferredSolutionId;

  ProjectDataModel({
    this.projectName = '',
    this.solutionTitle = '',
    this.solutionDescription = '',
    this.businessCase = '',
    this.notes = '',
    this.charterAssumptions = '',
    this.charterConstraints = '',
    this.charterProjectManagerName = '',
    this.charterProjectSponsorName = '',
    this.charterReviewedBy = '',
    this.charterApprovalDate,
    this.designManagementData,
    this.charterEmail = '',
    this.charterPhone = '',
    this.charterOrganizationalUnit = '',
    this.charterGreenBelt = '',
    this.charterBlackBelt = '',
    this.tags = const [],
    List<Contractor>? contractors,
    List<Vendor>? vendors,
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
    List<String>? assumptions,
    List<String>? constraints,
    List<String>? outOfScope,
    List<String>? opportunities,
    List<List<WorkItem>>? goalWorkItems,
    List<WorkItem>? wbsTree,
    List<IssueLogItem>? issueLogItems,
    List<LessonRecord>? lessonsLearned,
    List<Map<String, dynamic>>? technologyDefinitions,
    List<Map<String, dynamic>>? technologyInventory,
    FrontEndPlanningData? frontEndPlanning,
    SSHERData? ssherData,
    List<TeamMember>? teamMembers,
    List<LaunchChecklistItem>? launchChecklistItems,
    this.costAnalysisData,
    List<CostEstimateItem>? costEstimateItems,
    this.itConsiderationsData,
    this.infrastructureConsiderationsData,
    this.coreStakeholdersData,
    List<RoleDefinition>? projectRoles,
    List<StaffingRequirement>? staffingRequirements,
    List<TrainingActivity>? trainingActivities,
    DesignDeliverablesData? designDeliverablesData,
    this.isBasicPlanProject = false,
    Map<String, int>? aiUsageCounts,
    List<Map<String, dynamic>>? aiIntegrations,
    List<Map<String, dynamic>>? aiRecommendations,
    List<StakeholderEntry>? stakeholderEntries,
    List<EngagementPlanEntry>? engagementPlanEntries,
    this.qualityManagementData,
    this.executionPhaseData,
    this.projectId,
    this.createdAt,
    this.updatedAt,
    this.currentCheckpoint = 'initiation',
    Map<String, FieldHistory>? fieldHistories,
    String? costBenefitCurrency,
    String? preferredSolutionId,
  })  : potentialSolutions = potentialSolutions ?? [],
        solutionRisks = solutionRisks ?? [],
        contractors = contractors ?? [],
        vendors = vendors ?? [],
        projectGoals = projectGoals ?? [],
        assumptions = assumptions ?? [],
        constraints = constraints ?? [],
        outOfScope = outOfScope ?? [],
        opportunities = opportunities ?? [],
        planningGoals = planningGoals ??
            List.generate(3, (i) => PlanningGoal(goalNumber: i + 1)),
        keyMilestones = keyMilestones ?? [],
        planningNotes = planningNotes ?? {},
        goalWorkItems = goalWorkItems ?? List.generate(3, (_) => []),
        wbsTree = wbsTree ?? [],
        issueLogItems = issueLogItems ?? [],
        lessonsLearned = lessonsLearned ?? [],
        technologyDefinitions = technologyDefinitions ?? [],
        technologyInventory = technologyInventory ?? [],
        frontEndPlanning = frontEndPlanning ?? FrontEndPlanningData(),
        ssherData = ssherData ?? SSHERData(),
        teamMembers = teamMembers ?? [],
        launchChecklistItems = launchChecklistItems ?? [],
        costEstimateItems = costEstimateItems ?? [],
        designDeliverablesData =
            designDeliverablesData ?? DesignDeliverablesData(),
        projectRoles = projectRoles ?? [],
        staffingRequirements = staffingRequirements ?? [],
        trainingActivities = trainingActivities ?? [],
        aiUsageCounts = aiUsageCounts ?? {},
        aiIntegrations = aiIntegrations ?? [],
        aiRecommendations = aiRecommendations ?? [],
        stakeholderEntries = stakeholderEntries ?? [],
        engagementPlanEntries = engagementPlanEntries ?? [],
        fieldHistories = fieldHistories ?? {},
        costBenefitCurrency = costBenefitCurrency ?? 'USD',
        preferredSolutionId = preferredSolutionId;

  ProjectDataModel copyWith({
    String? projectName,
    String? solutionTitle,
    String? solutionDescription,
    String? businessCase,
    String? notes,
    String? charterAssumptions,
    String? charterConstraints,
    String? charterProjectManagerName,
    String? charterProjectSponsorName,
    String? charterReviewedBy,
    DateTime? charterApprovalDate,
    String? charterEmail,
    String? charterPhone,
    String? charterOrganizationalUnit,
    String? charterGreenBelt,
    String? charterBlackBelt,
    List<String>? tags,
    List<Contractor>? contractors,
    List<Vendor>? vendors,
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
    List<String>? assumptions,
    List<String>? constraints,
    List<String>? outOfScope,
    List<String>? opportunities,
    String? wbsCriteriaA,
    String? wbsCriteriaB,
    List<List<WorkItem>>? goalWorkItems,
    List<WorkItem>? wbsTree,
    List<IssueLogItem>? issueLogItems,
    List<LessonRecord>? lessonsLearned,
    List<Map<String, dynamic>>? technologyDefinitions,
    List<Map<String, dynamic>>? technologyInventory,
    FrontEndPlanningData? frontEndPlanning,
    SSHERData? ssherData,
    List<TeamMember>? teamMembers,
    List<LaunchChecklistItem>? launchChecklistItems,
    CostAnalysisData? costAnalysisData,
    List<CostEstimateItem>? costEstimateItems,
    ITConsiderationsData? itConsiderationsData,
    InfrastructureConsiderationsData? infrastructureConsiderationsData,
    CoreStakeholdersData? coreStakeholdersData,
    List<RoleDefinition>? projectRoles,
    List<StaffingRequirement>? staffingRequirements,
    List<TrainingActivity>? trainingActivities,
    DesignDeliverablesData? designDeliverablesData,
    DesignManagementData? designManagementData,
    ExecutionPhaseData? executionPhaseData,
    bool? isBasicPlanProject,
    Map<String, int>? aiUsageCounts,
    List<Map<String, dynamic>>? aiIntegrations,
    List<Map<String, dynamic>>? aiRecommendations,
    String? projectId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currentCheckpoint,
    Map<String, FieldHistory>? fieldHistories,
    String? costBenefitCurrency,
    String? preferredSolutionId,
    List<StakeholderEntry>? stakeholderEntries,
    List<EngagementPlanEntry>? engagementPlanEntries,
    QualityManagementData? qualityManagementData,
  }) {
    return ProjectDataModel(
      projectName: projectName ?? this.projectName,
      solutionTitle: solutionTitle ?? this.solutionTitle,
      solutionDescription: solutionDescription ?? this.solutionDescription,
      businessCase: businessCase ?? this.businessCase,
      notes: notes ?? this.notes,
      charterAssumptions: charterAssumptions ?? this.charterAssumptions,
      charterConstraints: charterConstraints ?? this.charterConstraints,
      charterProjectManagerName:
          charterProjectManagerName ?? this.charterProjectManagerName,
      charterProjectSponsorName:
          charterProjectSponsorName ?? this.charterProjectSponsorName,
      charterReviewedBy: charterReviewedBy ?? this.charterReviewedBy,
      charterApprovalDate: charterApprovalDate ?? this.charterApprovalDate,
      designManagementData: designManagementData ?? this.designManagementData,
      charterEmail: charterEmail ?? this.charterEmail,
      charterPhone: charterPhone ?? this.charterPhone,
      charterOrganizationalUnit:
          charterOrganizationalUnit ?? this.charterOrganizationalUnit,
      charterGreenBelt: charterGreenBelt ?? this.charterGreenBelt,
      charterBlackBelt: charterBlackBelt ?? this.charterBlackBelt,
      tags: tags ?? this.tags,
      contractors: contractors ?? this.contractors,
      vendors: vendors ?? this.vendors,
      potentialSolutions: potentialSolutions ?? this.potentialSolutions,
      solutionRisks: solutionRisks ?? this.solutionRisks,
      preferredSolutionAnalysis:
          preferredSolutionAnalysis ?? this.preferredSolutionAnalysis,
      overallFramework: overallFramework ?? this.overallFramework,
      projectGoals: projectGoals ?? this.projectGoals,
      potentialSolution: potentialSolution ?? this.potentialSolution,
      projectObjective: projectObjective ?? this.projectObjective,
      planningGoals: planningGoals ?? this.planningGoals,
      keyMilestones: keyMilestones ?? this.keyMilestones,
      planningNotes: planningNotes ?? this.planningNotes,
      assumptions: assumptions ?? this.assumptions,
      constraints: constraints ?? this.constraints,
      outOfScope: outOfScope ?? this.outOfScope,
      opportunities: opportunities ?? this.opportunities,
      wbsCriteriaA: wbsCriteriaA ?? this.wbsCriteriaA,
      wbsCriteriaB: wbsCriteriaB ?? this.wbsCriteriaB,
      goalWorkItems: goalWorkItems ?? this.goalWorkItems,
      wbsTree: wbsTree ?? this.wbsTree,
      issueLogItems: issueLogItems ?? this.issueLogItems,
      lessonsLearned: lessonsLearned ?? this.lessonsLearned,
      technologyDefinitions:
          technologyDefinitions ?? this.technologyDefinitions,
      technologyInventory: technologyInventory ?? this.technologyInventory,
      frontEndPlanning: frontEndPlanning ?? this.frontEndPlanning,
      ssherData: ssherData ?? this.ssherData,
      teamMembers: teamMembers ?? this.teamMembers,
      launchChecklistItems: launchChecklistItems ?? this.launchChecklistItems,
      costAnalysisData: costAnalysisData ?? this.costAnalysisData,
      costEstimateItems: costEstimateItems ?? this.costEstimateItems,
      itConsiderationsData: itConsiderationsData ?? this.itConsiderationsData,
      infrastructureConsiderationsData: infrastructureConsiderationsData ??
          this.infrastructureConsiderationsData,
      coreStakeholdersData: coreStakeholdersData ?? this.coreStakeholdersData,
      projectRoles: projectRoles ?? this.projectRoles,
      staffingRequirements: staffingRequirements ?? this.staffingRequirements,
      trainingActivities: trainingActivities ?? this.trainingActivities,
      designDeliverablesData:
          designDeliverablesData ?? this.designDeliverablesData,
      executionPhaseData: executionPhaseData ?? this.executionPhaseData,
      isBasicPlanProject: isBasicPlanProject ?? this.isBasicPlanProject,
      aiUsageCounts: aiUsageCounts ?? this.aiUsageCounts,
      aiIntegrations: aiIntegrations ?? this.aiIntegrations,
      aiRecommendations: aiRecommendations ?? this.aiRecommendations,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentCheckpoint: currentCheckpoint ?? this.currentCheckpoint,
      fieldHistories: fieldHistories ?? this.fieldHistories,
      costBenefitCurrency: costBenefitCurrency ?? this.costBenefitCurrency,
      preferredSolutionId: preferredSolutionId ?? this.preferredSolutionId,
      stakeholderEntries: stakeholderEntries ?? this.stakeholderEntries,
      engagementPlanEntries:
          engagementPlanEntries ?? this.engagementPlanEntries,
      qualityManagementData:
          qualityManagementData ?? this.qualityManagementData,
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
      'assumptions': assumptions,
      'constraints': constraints,
      'outOfScope': outOfScope,
      'opportunities': opportunities,
      'charterAssumptions': charterAssumptions,
      'charterConstraints': charterConstraints,
      'charterProjectManagerName': charterProjectManagerName,
      'charterProjectSponsorName': charterProjectSponsorName,
      'charterReviewedBy': charterReviewedBy,
      'charterApprovalDate': charterApprovalDate?.toIso8601String(),
      'charterEmail': charterEmail,
      'charterPhone': charterPhone,
      'charterOrganizationalUnit': charterOrganizationalUnit,
      'charterGreenBelt': charterGreenBelt,
      'charterBlackBelt': charterBlackBelt,
      'tags': tags,
      'contractors': contractors.map((c) => c.toJson()).toList(),
      'vendors': vendors.map((v) => v.toJson()).toList(),
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
      'wbsTree': wbsTree.map((item) => item.toJson()).toList(),
      'issueLogItems': issueLogItems.map((item) => item.toJson()).toList(),
      'lessonsLearned': lessonsLearned.map((l) => l.toJson()).toList(),
      'technologyDefinitions': technologyDefinitions,
      'technologyInventory': technologyInventory,
      'frontEndPlanning': frontEndPlanning.toJson(),
      'ssherData': ssherData.toJson(),
      'teamMembers': teamMembers.map((m) => m.toJson()).toList(),
      'launchChecklistItems':
          launchChecklistItems.map((item) => item.toJson()).toList(),
      if (costAnalysisData != null)
        'costAnalysisData': costAnalysisData!.toJson(),
      'costEstimateItems':
          costEstimateItems.map((item) => item.toJson()).toList(),
      if (itConsiderationsData != null)
        'itConsiderationsData': itConsiderationsData!.toJson(),
      if (infrastructureConsiderationsData != null)
        'infrastructureConsiderationsData':
            infrastructureConsiderationsData!.toJson(),
      if (coreStakeholdersData != null)
        'coreStakeholdersData': coreStakeholdersData!.toJson(),
      'projectRoles': projectRoles.map((r) => r.toJson()).toList(),
      'staffingRequirements':
          staffingRequirements.map((s) => s.toJson()).toList(),
      'trainingActivities': trainingActivities.map((t) => t.toJson()).toList(),
      'designDeliverables': designDeliverablesData.toJson(),
      'currentCheckpoint': currentCheckpoint,
      'isBasicPlanProject': isBasicPlanProject,
      'aiUsageCounts': aiUsageCounts,

      'aiIntegrations': aiIntegrations,
      'aiRecommendations': aiRecommendations,
      'projectId': projectId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'fieldHistories':
          fieldHistories.map((key, value) => MapEntry(key, value.toJson())),
      'costBenefitCurrency': costBenefitCurrency,
      'preferredSolutionId': preferredSolutionId,
      'stakeholderEntries': stakeholderEntries.map((e) => e.toJson()).toList(),
      'engagementPlanEntries':
          engagementPlanEntries.map((e) => e.toJson()).toList(),
      'qualityManagementData': qualityManagementData?.toJson(),
      'designManagementData': designManagementData?.toJson(),
      'executionPhaseData': executionPhaseData?.toJson(),
    };
  }

  factory ProjectDataModel.fromJson(Map<String, dynamic> json) {
    // Reconstruct goalWorkItems from flattened structure
    List<List<WorkItem>> reconstructedGoalWorkItems =
        List.generate(3, (_) => []);
    final rawWorkItems = json['goalWorkItems'] as List?;

    if (rawWorkItems != null) {
      try {
        // Check if it's the old nested format or new flattened format
        if (rawWorkItems.isNotEmpty && rawWorkItems.first is List) {
          // Old nested format (backward compatibility)
          reconstructedGoalWorkItems = rawWorkItems
              .map((items) =>
                  (items as List).map((i) => WorkItem.fromJson(i)).toList())
              .toList();
        } else {
          // New flattened format
          for (final item in rawWorkItems) {
            final itemMap = item as Map<String, dynamic>;
            final goalIndex = itemMap['goalIndex'] as int? ?? 0;

            // Ensure the list is large enough
            while (reconstructedGoalWorkItems.length <= goalIndex) {
              reconstructedGoalWorkItems.add([]);
            }

            reconstructedGoalWorkItems[goalIndex]
                .add(WorkItem.fromJson(itemMap));
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing goalWorkItems: $e');
        reconstructedGoalWorkItems = List.generate(3, (_) => []);
      }
    }

    // Safe parsing helper for lists
    List<T> safeParseList<T>(
        String key, T Function(Map<String, dynamic>) parser) {
      try {
        final list = json[key] as List?;
        if (list == null) return [];
        return list
            .map((item) {
              try {
                return parser(item as Map<String, dynamic>);
              } catch (e) {
                debugPrint('⚠️ Error parsing item in $key: $e');
                return null;
              }
            })
            .whereType<T>()
            .toList();
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
      projectName:
          json['projectName']?.toString() ?? json['name']?.toString() ?? '',
      solutionTitle: json['solutionTitle']?.toString() ?? '',
      solutionDescription: json['solutionDescription']?.toString() ?? '',
      businessCase: json['businessCase']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      assumptions:
          (json['assumptions'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      constraints:
          (json['constraints'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      outOfScope:
          (json['outOfScope'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      opportunities:
          (json['opportunities'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      charterAssumptions: json['charterAssumptions']?.toString() ?? '',
      charterConstraints: json['charterConstraints']?.toString() ?? '',
      charterProjectManagerName:
          json['charterProjectManagerName']?.toString() ?? '',
      charterProjectSponsorName:
          json['charterProjectSponsorName']?.toString() ?? '',
      charterReviewedBy: json['charterReviewedBy']?.toString() ?? '',
      charterApprovalDate: safeParseDateTime('charterApprovalDate'),
      charterEmail: json['charterEmail']?.toString() ?? '',
      charterPhone: json['charterPhone']?.toString() ?? '',
      charterOrganizationalUnit:
          json['charterOrganizationalUnit']?.toString() ?? '',
      charterGreenBelt: json['charterGreenBelt']?.toString() ?? '',
      charterBlackBelt: json['charterBlackBelt']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      contractors: safeParseList('contractors', Contractor.fromJson),
      vendors: safeParseList('vendors', Vendor.fromJson),
      potentialSolutions:
          safeParseList('potentialSolutions', PotentialSolution.fromJson),
      solutionRisks: safeParseList('solutionRisks', SolutionRisk.fromJson),
      preferredSolutionAnalysis: safeParseSingle(
          'preferredSolutionAnalysis', PreferredSolutionAnalysis.fromJson),
      overallFramework: json['overallFramework']?.toString(),
      projectGoals: safeParseList('projectGoals', ProjectGoal.fromJson),
      potentialSolution: json['potentialSolution']?.toString() ?? '',
      projectObjective: json['projectObjective']?.toString() ?? '',
      planningGoals: () {
        final parsed = safeParseList('planningGoals', PlanningGoal.fromJson);
        return parsed.isEmpty
            ? List.generate(3, (i) => PlanningGoal(goalNumber: i + 1))
            : parsed;
      }(),
      keyMilestones: safeParseList('keyMilestones', Milestone.fromJson),
      planningNotes: (json['planningNotes'] is Map)
          ? Map<String, String>.from(
              (json['planningNotes'] as Map).map(
                  (key, value) => MapEntry(key.toString(), value.toString())),
            )
          : {},
      wbsCriteriaA: json['wbsCriteriaA']?.toString(),
      wbsCriteriaB: json['wbsCriteriaB']?.toString(),
      goalWorkItems: reconstructedGoalWorkItems,
      wbsTree: safeParseList('wbsTree', WorkItem.fromJson),
      issueLogItems: safeParseList('issueLogItems', IssueLogItem.fromJson),
      lessonsLearned: safeParseList('lessonsLearned', LessonRecord.fromJson),
      technologyDefinitions: (json['technologyDefinitions'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      technologyInventory: (json['technologyInventory'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      frontEndPlanning:
          safeParseSingle('frontEndPlanning', FrontEndPlanningData.fromJson) ??
              FrontEndPlanningData(),
      ssherData:
          safeParseSingle('ssherData', SSHERData.fromJson) ?? SSHERData(),
      teamMembers: safeParseList('teamMembers', TeamMember.fromJson),
      launchChecklistItems:
          safeParseList('launchChecklistItems', LaunchChecklistItem.fromJson),
      costAnalysisData:
          safeParseSingle('costAnalysisData', CostAnalysisData.fromJson),
      costEstimateItems:
          safeParseList('costEstimateItems', CostEstimateItem.fromJson),
      itConsiderationsData: safeParseSingle(
          'itConsiderationsData', ITConsiderationsData.fromJson),
      infrastructureConsiderationsData: safeParseSingle(
          'infrastructureConsiderationsData',
          InfrastructureConsiderationsData.fromJson),
      coreStakeholdersData: safeParseSingle(
          'coreStakeholdersData', CoreStakeholdersData.fromJson),
      projectRoles: safeParseList('projectRoles', RoleDefinition.fromJson),
      staffingRequirements:
          safeParseList('staffingRequirements', StaffingRequirement.fromJson),
      trainingActivities:
          safeParseList('trainingActivities', TrainingActivity.fromJson),
      designDeliverablesData: safeParseSingle(
              'designDeliverables', DesignDeliverablesData.fromJson) ??
          DesignDeliverablesData(),
      executionPhaseData:
          safeParseSingle('executionPhaseData', ExecutionPhaseData.fromJson),
      designManagementData: safeParseSingle(
          'designManagementData', DesignManagementData.fromJson),
      isBasicPlanProject: json['isBasicPlanProject'] == true,
      aiUsageCounts: (json['aiUsageCounts'] is Map)
          ? Map<String, int>.from(
              (json['aiUsageCounts'] as Map).map((key, value) {
                final parsed =
                    value is int ? value : int.tryParse(value.toString()) ?? 0;
                return MapEntry(key.toString(), parsed);
              }),
            )
          : {},
      aiIntegrations: (json['aiIntegrations'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      aiRecommendations: (json['aiRecommendations'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      currentCheckpoint: json['currentCheckpoint']?.toString() ??
          json['checkpointRoute']?.toString() ??
          'initiation',
      projectId: json['projectId']?.toString(),
      createdAt: safeParseDateTime('createdAt'),
      updatedAt: safeParseDateTime('updatedAt'),
      fieldHistories: (json['fieldHistories'] is Map)
          ? Map<String, FieldHistory>.from(
              (json['fieldHistories'] as Map).map((key, value) {
                try {
                  return MapEntry(
                    key.toString(),
                    FieldHistory.fromJson(value as Map<String, dynamic>),
                  );
                } catch (e) {
                  debugPrint('⚠️ Error parsing FieldHistory for $key: $e');
                  return MapEntry(
                      key.toString(), FieldHistory(fieldName: key.toString()));
                }
              }),
            )
          : {},
      costBenefitCurrency: json['costBenefitCurrency']?.toString() ?? 'USD',
      preferredSolutionId: json['preferredSolutionId']?.toString(),
      stakeholderEntries: (json['stakeholderEntries'] as List?)
              ?.map((e) => StakeholderEntry.fromJson(e))
              .toList() ??
          [],
      engagementPlanEntries: (json['engagementPlanEntries'] as List?)
              ?.map((e) => EngagementPlanEntry.fromJson(e))
              .toList() ??
          [],
      qualityManagementData: json['qualityManagementData'] != null
          ? QualityManagementData.fromJson(json['qualityManagementData'])
          : null,
    );
  }

  /// Add a field value to history for undo functionality
  void addFieldToHistory(String fieldName, String value,
      {bool isAiGenerated = false}) {
    if (!fieldHistories.containsKey(fieldName)) {
      fieldHistories[fieldName] = FieldHistory(
        fieldName: fieldName,
        isAiGenerated: isAiGenerated,
      );
    }
    fieldHistories[fieldName]!.addToHistory(value);
  }

  /// Undo the last change to a field
  String? undoField(String fieldName) {
    return fieldHistories[fieldName]?.undo();
  }

  /// Check if a field can be undone
  bool canUndoField(String fieldName) {
    return (fieldHistories[fieldName]?.history.length ?? 0) > 1;
  }

  /// Add a new potential solution
  void addPotentialSolution() {
    if (potentialSolutions.length < 3) {
      potentialSolutions.add(PotentialSolution.empty(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        number: potentialSolutions.length + 1,
      ));
    }
  }

  /// Delete a potential solution by ID
  void deletePotentialSolution(String id) {
    potentialSolutions.removeWhere((s) => s.id == id);
    _renumberSolutions();
  }

  /// Renumber solutions after deletion
  void _renumberSolutions() {
    for (int i = 0; i < potentialSolutions.length; i++) {
      potentialSolutions[i].number = i + 1;
    }
  }

  /// Set the preferred solution
  void setPreferredSolution(String solutionId) {
    preferredSolutionId = solutionId;
  }

  /// Get the preferred solution
  PotentialSolution? get preferredSolution {
    if (preferredSolutionId == null) return null;
    try {
      return potentialSolutions.firstWhere(
        (s) => s.id == preferredSolutionId,
      );
    } catch (e) {
      return null;
    }
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
  bool isHighPriority;
  List<PlanningMilestone> milestones;

  PlanningGoal({
    required this.goalNumber,
    this.title = '',
    this.description = '',
    this.targetYear = '',
    this.isHighPriority = false,
    List<PlanningMilestone>? milestones,
  }) : milestones = milestones ?? [PlanningMilestone()];

  Map<String, dynamic> toJson() => {
        'goalNumber': goalNumber,
        'title': title,
        'description': description,
        'targetYear': targetYear,
        'isHighPriority': isHighPriority,
        'milestones': milestones.map((m) => m.toJson()).toList(),
      };

  factory PlanningGoal.fromJson(Map<String, dynamic> json) {
    return PlanningGoal(
      goalNumber: json['goalNumber'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetYear: json['targetYear'] ?? '',
      isHighPriority: json['isHighPriority'] == true,
      milestones: (json['milestones'] as List?)
              ?.map((m) => PlanningMilestone.fromJson(m))
              .toList() ??
          [PlanningMilestone()],
    );
  }
}

class PlanningMilestone {
  String title;
  String deadline;
  String status;

  PlanningMilestone({
    this.title = '',
    this.deadline = '',
    this.status = 'In Progress',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'deadline': deadline,
        'status': status,
      };

  factory PlanningMilestone.fromJson(Map<String, dynamic> json) {
    return PlanningMilestone(
      title: json['title'] ?? '',
      deadline: json['deadline'] ?? '',
      status: json['status'] ?? 'In Progress',
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

  static String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString();
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

/// Returns default milestones for fallback when AI generation fails
List<Milestone> getDefaultMilestones() {
  return [
    Milestone(
      name: 'Project Kickoff',
      discipline: 'All',
      dueDate: '',
      comments: 'Official project initiation and team mobilization',
    ),
    Milestone(
      name: 'Planning Completion',
      discipline: 'Planning, Management',
      dueDate: '',
      comments: 'All planning documents finalized and approved',
    ),
    Milestone(
      name: 'Execution Start',
      discipline: 'All',
      dueDate: '',
      comments: 'Begin implementation of project deliverables',
    ),
    Milestone(
      name: 'Execution Completion',
      discipline: 'All',
      dueDate: '',
      comments: 'All deliverables completed and ready for launch',
    ),
    Milestone(
      name: 'Project Launch',
      discipline: 'All',
      dueDate: '',
      comments: 'Go-live and transition to operations',
    ),
  ];
}

class WorkItem {
  String id;
  String parentId;
  String title;
  String description;
  String status;
  List<WorkItem> children;
  List<String> dependencies;

  WorkItem({
    String? id,
    this.parentId = '',
    this.title = '',
    this.description = '',
    this.status = 'not_started',
    List<WorkItem>? children,
    List<String>? dependencies,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        children = children ?? [],
        dependencies = dependencies ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentId': parentId,
        'title': title,
        'description': description,
        'status': status,
        'children': children.map((c) => c.toJson()).toList(),
        'dependencies': dependencies,
      };

  factory WorkItem.fromJson(Map<String, dynamic> json) {
    return WorkItem(
      id: json['id']?.toString(),
      parentId: json['parentId']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'not_started',
      children: (json['children'] as List?)
              ?.map((c) => WorkItem.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      dependencies:
          (json['dependencies'] as List?)?.map((d) => d.toString()).toList() ??
              [],
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
  // Milestone date fields
  String milestoneStartDate;
  String milestoneEndDate;
  List<RequirementItem> requirementItems;
  // Persisted scenario matrix items
  List<ScenarioRecord> scenarioMatrixItems;
  // Security management items
  List<RoleItem> securityRoles;
  List<PermissionItem> securityPermissions;
  List<SecuritySetting> securitySettings;
  List<AccessLogItem> securityAccessLogs;
  // Technical debt related fields
  List<DebtItem> technicalDebtItems;
  List<DebtInsight> technicalDebtRootCauses;
  List<RemediationTrack> technicalDebtTracks;
  List<OwnerItem> technicalDebtOwners;
  // Structured risk register items (used for charter/summary tables)
  List<RiskRegisterItem> riskRegisterItems;

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
    this.milestoneStartDate = '',
    this.milestoneEndDate = '',
    List<RequirementItem>? requirementItems,
    List<ScenarioRecord>? scenarioMatrixItems,
    List<RoleItem>? securityRoles,
    List<PermissionItem>? securityPermissions,
    List<SecuritySetting>? securitySettings,
    List<AccessLogItem>? securityAccessLogs,
    List<DebtItem>? technicalDebtItems,
    List<DebtInsight>? technicalDebtRootCauses,
    List<RemediationTrack>? technicalDebtTracks,
    List<OwnerItem>? technicalDebtOwners,
    List<RiskRegisterItem>? riskRegisterItems,
  })  : requirementItems = requirementItems ?? [],
        technicalDebtItems = technicalDebtItems ?? [],
        technicalDebtRootCauses = technicalDebtRootCauses ?? [],
        technicalDebtTracks = technicalDebtTracks ?? [],
        technicalDebtOwners = technicalDebtOwners ?? [],
        riskRegisterItems = riskRegisterItems ?? [],
        scenarioMatrixItems = scenarioMatrixItems ?? [],
        securityRoles = securityRoles ?? [],
        securityPermissions = securityPermissions ?? [],
        securitySettings = securitySettings ?? [],
        securityAccessLogs = securityAccessLogs ?? [];

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
        'milestoneStartDate': milestoneStartDate,
        'milestoneEndDate': milestoneEndDate,
        'requirementsItems':
            requirementItems.map((item) => item.toJson()).toList(),
        'riskRegisterItems':
            riskRegisterItems.map((item) => item.toJson()).toList(),
        'technicalDebtItems':
            technicalDebtItems.map((d) => d.toJson()).toList(),
        'technicalDebtRootCauses':
            technicalDebtRootCauses.map((r) => r.toJson()).toList(),
        'technicalDebtTracks':
            technicalDebtTracks.map((t) => t.toJson()).toList(),
        'technicalDebtOwners':
            technicalDebtOwners.map((o) => o.toJson()).toList(),
        'scenarioMatrixItems':
            scenarioMatrixItems.map((s) => s.toJson()).toList(),
        'securityRoles': securityRoles.map((r) => r.toJson()).toList(),
        'securityPermissions':
            securityPermissions.map((p) => p.toJson()).toList(),
        'securitySettings': securitySettings.map((s) => s.toJson()).toList(),
        'securityAccessLogs':
            securityAccessLogs.map((a) => a.toJson()).toList(),
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
      milestoneStartDate: json['milestoneStartDate'] ?? '',
      milestoneEndDate: json['milestoneEndDate'] ?? '',
      requirementItems: (json['requirementsItems'] as List?)
              ?.map((item) =>
                  RequirementItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      riskRegisterItems: (json['riskRegisterItems'] as List?)
              ?.map((item) =>
                  RiskRegisterItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      technicalDebtItems: (json['technicalDebtItems'] as List?)
              ?.map((item) => DebtItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      technicalDebtRootCauses: (json['technicalDebtRootCauses'] as List?)
              ?.map(
                  (item) => DebtInsight.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      technicalDebtTracks: (json['technicalDebtTracks'] as List?)
              ?.map((item) =>
                  RemediationTrack.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      technicalDebtOwners: (json['technicalDebtOwners'] as List?)
              ?.map((item) => OwnerItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      scenarioMatrixItems: (json['scenarioMatrixItems'] as List?)
              ?.map((item) =>
                  ScenarioRecord.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      securityRoles: (json['securityRoles'] as List?)
              ?.map((item) => RoleItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      securityPermissions: (json['securityPermissions'] as List?)
              ?.map((item) =>
                  PermissionItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      securitySettings: (json['securitySettings'] as List?)
              ?.map((item) =>
                  SecuritySetting.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      securityAccessLogs: (json['securityAccessLogs'] as List?)
              ?.map((item) =>
                  AccessLogItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RiskRegisterItem {
  String riskName;
  String impactLevel;
  String likelihood;
  String mitigationStrategy;

  RiskRegisterItem({
    this.riskName = '',
    this.impactLevel = '',
    this.likelihood = '',
    this.mitigationStrategy = '',
  });

  Map<String, dynamic> toJson() => {
        'riskName': riskName,
        'impactLevel': impactLevel,
        'likelihood': likelihood,
        'mitigationStrategy': mitigationStrategy,
      };

  factory RiskRegisterItem.fromJson(Map<String, dynamic> json) {
    return RiskRegisterItem(
      riskName: json['riskName'] ?? '',
      impactLevel: json['impactLevel'] ?? '',
      likelihood: json['likelihood'] ?? '',
      mitigationStrategy: json['mitigationStrategy'] ?? '',
    );
  }
}

class RoleItem {
  String id;
  String name;
  String description;

  RoleItem({String? id, this.name = '', this.description = ''})
      : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'description': description};

  factory RoleItem.fromJson(Map<String, dynamic> json) {
    return RoleItem(
        id: json['id']?.toString(),
        name: json['name'] ?? '',
        description: json['description'] ?? '');
  }
}

class PermissionItem {
  String id;
  String resource;
  String scope;

  PermissionItem({String? id, this.resource = '', this.scope = ''})
      : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() =>
      {'id': id, 'resource': resource, 'scope': scope};

  factory PermissionItem.fromJson(Map<String, dynamic> json) {
    return PermissionItem(
        id: json['id']?.toString(),
        resource: json['resource'] ?? '',
        scope: json['scope'] ?? '');
  }
}

class SecuritySetting {
  String key;
  String value;

  SecuritySetting({this.key = '', this.value = ''});

  Map<String, dynamic> toJson() => {'key': key, 'value': value};

  factory SecuritySetting.fromJson(Map<String, dynamic> json) {
    return SecuritySetting(key: json['key'] ?? '', value: json['value'] ?? '');
  }
}

class AccessLogItem {
  String id;
  String user;
  String action;
  String timestamp;

  AccessLogItem(
      {String? id, this.user = '', this.action = '', this.timestamp = ''})
      : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() =>
      {'id': id, 'user': user, 'action': action, 'timestamp': timestamp};

  factory AccessLogItem.fromJson(Map<String, dynamic> json) {
    return AccessLogItem(
      id: json['id']?.toString(),
      user: json['user'] ?? '',
      action: json['action'] ?? '',
      timestamp: json['timestamp'] ?? '',
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
      safetyItems: (json['safetyItems'] as List?)
              ?.map((s) => SafetyItem.fromJson(s))
              .toList() ??
          [],
      entries: (json['entries'] as List?)
              ?.map((e) => SsherEntry.fromJson(e))
              .toList() ??
          [],
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
  String id;
  String category;
  String department;
  String teamMember;
  String concern;
  String riskLevel;
  String mitigation;

  SsherEntry({
    String? id,
    this.category = '',
    this.department = '',
    this.teamMember = '',
    this.concern = '',
    this.riskLevel = '',
    this.mitigation = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'department': department,
        'teamMember': teamMember,
        'concern': concern,
        'riskLevel': riskLevel,
        'mitigation': mitigation,
      };

  factory SsherEntry.fromJson(Map<String, dynamic> json) {
    return SsherEntry(
      id: json['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
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
  final String id;
  int number;
  String title;
  String description;
  Map<String, FieldHistory> fieldHistories;

  PotentialSolution({
    required this.id,
    required this.number,
    this.title = '',
    this.description = '',
    Map<String, FieldHistory>? fieldHistories,
  }) : fieldHistories = fieldHistories ?? {};

  /// Factory constructor for creating empty solutions
  factory PotentialSolution.empty({
    required String id,
    required int number,
  }) {
    return PotentialSolution(
      id: id,
      number: number,
      title: '',
      description: '',
      fieldHistories: {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'title': title,
        'description': description,
        'fieldHistories':
            fieldHistories.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory PotentialSolution.fromJson(Map<String, dynamic> json) {
    return PotentialSolution(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      number: (json['number'] is num) ? (json['number'] as num).toInt() : 1,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fieldHistories: (json['fieldHistories'] is Map)
          ? Map<String, FieldHistory>.from(
              (json['fieldHistories'] as Map).map((key, value) {
                try {
                  return MapEntry(
                    key.toString(),
                    FieldHistory.fromJson(value as Map<String, dynamic>),
                  );
                } catch (e) {
                  return MapEntry(
                    key.toString(),
                    FieldHistory(fieldName: key.toString()),
                  );
                }
              }),
            )
          : {},
    );
  }

  PotentialSolution copyWith({
    String? id,
    int? number,
    String? title,
    String? description,
    Map<String, FieldHistory>? fieldHistories,
  }) {
    return PotentialSolution(
      id: id ?? this.id,
      number: number ?? this.number,
      title: title ?? this.title,
      description: description ?? this.description,
      fieldHistories: fieldHistories ?? this.fieldHistories,
    );
  }
}

class LessonRecord {
  String id;
  String lesson;
  String category;
  String type;
  String phase;
  String status;
  String submittedBy;
  String notes;
  DateTime? dateSubmitted;

  LessonRecord({
    String? id,
    this.lesson = '',
    this.category = '',
    this.type = '',
    this.phase = '',
    this.status = '',
    this.submittedBy = '',
    this.notes = '',
    this.dateSubmitted,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'lesson': lesson,
        'category': category,
        'type': type,
        'phase': phase,
        'status': status,
        'submittedBy': submittedBy,
        'notes': notes,
        'dateSubmitted': dateSubmitted?.toIso8601String(),
      };

  factory LessonRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parsed;
    try {
      if (json['dateSubmitted'] is String) {
        parsed = DateTime.parse(json['dateSubmitted']);
      }
    } catch (_) {}
    return LessonRecord(
      id: json['id']?.toString(),
      lesson: json['lesson'] ?? '',
      category: json['category'] ?? '',
      type: json['type'] ?? '',
      phase: json['phase'] ?? '',
      status: json['status'] ?? '',
      submittedBy: json['submittedBy'] ?? '',
      notes: json['notes'] ?? '',
      dateSubmitted: parsed,
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
    final riskList =
        (json['risks'] as List?)?.map((r) => r.toString()).toList() ??
            ['', '', ''];
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

  static String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}

class PreferredSolutionAnalysis {
  String workingNotes;
  List<SolutionAnalysisItem> solutionAnalyses;
  String? selectedSolutionTitle;
  String? selectedSolutionId; // UUID/ID for reliable matching
  int? selectedSolutionIndex; // Index fallback for matching

  PreferredSolutionAnalysis({
    this.workingNotes = '',
    List<SolutionAnalysisItem>? solutionAnalyses,
    this.selectedSolutionTitle,
    this.selectedSolutionId,
    this.selectedSolutionIndex,
  }) : solutionAnalyses = solutionAnalyses ?? [];

  Map<String, dynamic> toJson() => {
        'workingNotes': workingNotes,
        'solutionAnalyses': solutionAnalyses.map((s) => s.toJson()).toList(),
        'selectedSolutionTitle': selectedSolutionTitle,
        'selectedSolutionId': selectedSolutionId,
        'selectedSolutionIndex': selectedSolutionIndex,
      };

  factory PreferredSolutionAnalysis.fromJson(Map<String, dynamic> json) {
    return PreferredSolutionAnalysis(
      workingNotes: json['workingNotes'] ?? '',
      solutionAnalyses: (json['solutionAnalyses'] as List?)
              ?.map((s) => SolutionAnalysisItem.fromJson(s))
              .toList() ??
          [],
      selectedSolutionTitle: json['selectedSolutionTitle'],
      selectedSolutionId: json['selectedSolutionId']?.toString(),
      selectedSolutionIndex: json['selectedSolutionIndex'] is int
          ? json['selectedSolutionIndex'] as int
          : (json['selectedSolutionIndex'] != null
              ? int.tryParse(json['selectedSolutionIndex'].toString())
              : null),
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
  String? itConsiderationText;
  String? infraConsiderationText;

  SolutionAnalysisItem({
    this.solutionTitle = '',
    this.solutionDescription = '',
    List<String>? stakeholders,
    List<String>? risks,
    List<String>? technologies,
    List<String>? infrastructure,
    List<CostItem>? costs,
    this.itConsiderationText,
    this.infraConsiderationText,
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
        'itConsiderationText': itConsiderationText,
        'infraConsiderationText': infraConsiderationText,
      };

  factory SolutionAnalysisItem.fromJson(Map<String, dynamic> json) {
    return SolutionAnalysisItem(
      solutionTitle: json['solutionTitle'] ?? '',
      solutionDescription: json['solutionDescription'] ?? '',
      stakeholders: List<String>.from(json['stakeholders'] ?? []),
      risks: List<String>.from(json['risks'] ?? []),
      technologies: List<String>.from(json['technologies'] ?? []),
      infrastructure: List<String>.from(json['infrastructure'] ?? []),
      costs:
          (json['costs'] as List?)?.map((c) => CostItem.fromJson(c)).toList() ??
              [],
      itConsiderationText: json['itConsiderationText'],
      infraConsiderationText: json['infraConsiderationText'],
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
        'npvByYear':
            npvByYear.map((key, value) => MapEntry(key.toString(), value)),
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
      estimatedCost: (json['estimatedCost'] is num)
          ? (json['estimatedCost'] as num).toDouble()
          : 0.0,
      roiPercent: (json['roiPercent'] is num)
          ? (json['roiPercent'] as num).toDouble()
          : 0.0,
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
      amount:
          (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      costType: json['costType']?.toString() ?? 'direct',
    );
  }

  static String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString();
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
  })  : solutionCosts = solutionCosts ?? [],
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
      solutionCosts: (json['solutionCosts'] as List?)
              ?.map((s) => SolutionCostData.fromJson(s))
              .toList() ??
          [],
      projectValueAmount: json['projectValueAmount'] ?? '',
      projectValueBenefits:
          Map<String, String>.from(json['projectValueBenefits'] ?? {}),
      benefitLineItems: (json['benefitLineItems'] as List?)
              ?.map((b) => BenefitLineItem.fromJson(b))
              .toList() ??
          [],
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
      costRows: (json['costRows'] as List?)
              ?.map((r) => CostRowData.fromJson(r))
              .toList() ??
          [],
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
  String hardwareRequirements;
  String softwareRequirements;
  String networkRequirements;
  List<SolutionITData> solutionITData;

  ITConsiderationsData({
    this.notes = '',
    this.hardwareRequirements = '',
    this.softwareRequirements = '',
    this.networkRequirements = '',
    List<SolutionITData>? solutionITData,
  }) : solutionITData = solutionITData ?? [];

  Map<String, dynamic> toJson() => {
        'notes': notes,
        'hardwareRequirements': hardwareRequirements,
        'softwareRequirements': softwareRequirements,
        'networkRequirements': networkRequirements,
        'solutionITData': solutionITData.map((s) => s.toJson()).toList(),
      };

  factory ITConsiderationsData.fromJson(Map<String, dynamic> json) {
    return ITConsiderationsData(
      notes: json['notes'] ?? '',
      hardwareRequirements: json['hardwareRequirements'] ?? '',
      softwareRequirements: json['softwareRequirements'] ?? '',
      networkRequirements: json['networkRequirements'] ?? '',
      solutionITData: (json['solutionITData'] as List?)
              ?.map((s) => SolutionITData.fromJson(s))
              .toList() ??
          [],
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
  String physicalSpaceRequirements;
  String powerCoolingRequirements;
  String connectivityRequirements;
  List<SolutionInfrastructureData> solutionInfrastructureData;

  InfrastructureConsiderationsData({
    this.notes = '',
    this.physicalSpaceRequirements = '',
    this.powerCoolingRequirements = '',
    this.connectivityRequirements = '',
    List<SolutionInfrastructureData>? solutionInfrastructureData,
  }) : solutionInfrastructureData = solutionInfrastructureData ?? [];

  Map<String, dynamic> toJson() => {
        'notes': notes,
        'physicalSpaceRequirements': physicalSpaceRequirements,
        'powerCoolingRequirements': powerCoolingRequirements,
        'connectivityRequirements': connectivityRequirements,
        'solutionInfrastructureData':
            solutionInfrastructureData.map((s) => s.toJson()).toList(),
      };

  factory InfrastructureConsiderationsData.fromJson(Map<String, dynamic> json) {
    return InfrastructureConsiderationsData(
      notes: json['notes'] ?? '',
      physicalSpaceRequirements: json['physicalSpaceRequirements'] ?? '',
      powerCoolingRequirements: json['powerCoolingRequirements'] ?? '',
      connectivityRequirements: json['connectivityRequirements'] ?? '',
      solutionInfrastructureData: (json['solutionInfrastructureData'] as List?)
              ?.map((s) => SolutionInfrastructureData.fromJson(s))
              .toList() ??
          [],
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
        'solutionStakeholderData':
            solutionStakeholderData.map((s) => s.toJson()).toList(),
      };

  factory CoreStakeholdersData.fromJson(Map<String, dynamic> json) {
    return CoreStakeholdersData(
      notes: json['notes'] ?? '',
      solutionStakeholderData: (json['solutionStakeholderData'] as List?)
              ?.map((s) => SolutionStakeholderData.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class SolutionStakeholderData {
  String solutionTitle;
  String notableStakeholders;
  String internalStakeholders;
  String externalStakeholders;

  SolutionStakeholderData({
    this.solutionTitle = '',
    this.notableStakeholders = '',
    this.internalStakeholders = '',
    this.externalStakeholders = '',
  });

  Map<String, dynamic> toJson() => {
        'solutionTitle': solutionTitle,
        'notableStakeholders': notableStakeholders,
        'internalStakeholders': internalStakeholders,
        'externalStakeholders': externalStakeholders,
      };

  factory SolutionStakeholderData.fromJson(Map<String, dynamic> json) {
    return SolutionStakeholderData(
      solutionTitle: json['solutionTitle'] ?? '',
      notableStakeholders: json['notableStakeholders'] ?? '',
      internalStakeholders: json['internalStakeholders'] ?? '',
      externalStakeholders: json['externalStakeholders'] ?? '',
    );
  }
}

// Technical debt models (top-level)
class DebtItem {
  String id;
  String title;
  String area;
  String owner;
  String severity;
  String status;
  String target;

  DebtItem({
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

  factory DebtItem.fromJson(Map<String, dynamic> json) => DebtItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        area: json['area'] ?? '',
        owner: json['owner'] ?? '',
        severity: json['severity'] ?? '',
        status: json['status'] ?? '',
        target: json['target'] ?? '',
      );
}

class DebtInsight {
  String title;
  String subtitle;

  DebtInsight({this.title = '', this.subtitle = ''});

  Map<String, dynamic> toJson() => {'title': title, 'subtitle': subtitle};

  factory DebtInsight.fromJson(Map<String, dynamic> json) => DebtInsight(
        title: json['title'] ?? '',
        subtitle: json['subtitle'] ?? '',
      );
}

class RemediationTrack {
  String label;
  double progress;
  int colorValue;

  RemediationTrack(
      {this.label = '', this.progress = 0.0, this.colorValue = 0xFF6366F1});

  Map<String, dynamic> toJson() =>
      {'label': label, 'progress': progress, 'colorValue': colorValue};

  factory RemediationTrack.fromJson(Map<String, dynamic> json) =>
      RemediationTrack(
        label: json['label'] ?? '',
        progress: (json['progress'] is num)
            ? (json['progress'] as num).toDouble()
            : 0.0,
        colorValue: json['colorValue'] ?? 0xFF6366F1,
      );
}

class OwnerItem {
  String name;
  String count;
  String note;

  OwnerItem({this.name = '', this.count = '', this.note = ''});

  Map<String, dynamic> toJson() => {'name': name, 'count': count, 'note': note};

  factory OwnerItem.fromJson(Map<String, dynamic> json) => OwnerItem(
        name: json['name'] ?? '',
        count: json['count'] ?? '',
        note: json['note'] ?? '',
      );
}

// Execution Phase Data
class ExecutionPhaseData {
  final String? executionPlanOutline;
  final String? executionPlanStrategy;
  final Map<String, List<ExecutionPhaseEntry>> sectionData;

  ExecutionPhaseData({
    this.executionPlanOutline,
    this.executionPlanStrategy,
    Map<String, List<ExecutionPhaseEntry>>? sectionData,
  }) : sectionData = sectionData ?? {};

  bool get isEmpty =>
      (executionPlanOutline == null || executionPlanOutline!.isEmpty) &&
      (executionPlanStrategy == null || executionPlanStrategy!.isEmpty) &&
      sectionData.isEmpty;

  ExecutionPhaseData copyWith({
    String? executionPlanOutline,
    String? executionPlanStrategy,
    Map<String, List<ExecutionPhaseEntry>>? sectionData,
  }) {
    return ExecutionPhaseData(
      executionPlanOutline: executionPlanOutline ?? this.executionPlanOutline,
      executionPlanStrategy:
          executionPlanStrategy ?? this.executionPlanStrategy,
      sectionData: sectionData ?? this.sectionData,
    );
  }

  Map<String, dynamic> toJson() => {
        'executionPlanOutline': executionPlanOutline,
        'executionPlanStrategy': executionPlanStrategy,
        'sectionData': sectionData.map(
          (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
        ),
      };

  factory ExecutionPhaseData.fromJson(Map<String, dynamic> json) {
    final sectionDataMap = <String, List<ExecutionPhaseEntry>>{};
    final sectionDataJson = json['sectionData'];
    if (sectionDataJson is Map) {
      sectionDataJson.forEach((key, value) {
        if (value is List) {
          sectionDataMap[key.toString()] = value.map((e) {
            if (e is Map) {
              return ExecutionPhaseEntry.fromJson(Map<String, dynamic>.from(e));
            }
            return ExecutionPhaseEntry(title: '', details: '', status: '');
          }).toList();
        }
      });
    }
    return ExecutionPhaseData(
      executionPlanOutline: json['executionPlanOutline']?.toString(),
      executionPlanStrategy: json['executionPlanStrategy']?.toString(),
      sectionData: sectionDataMap,
    );
  }
}

class ExecutionPhaseEntry {
  final String title;
  final String details;
  final String status;

  ExecutionPhaseEntry({
    required this.title,
    required this.details,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'details': details,
        'status': status,
      };

  factory ExecutionPhaseEntry.fromJson(Map<String, dynamic> json) =>
      ExecutionPhaseEntry(
        title: json['title']?.toString() ?? '',
        details: json['details']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
      );
}

// Scenario matrix record persisted in project data
class ScenarioRecord {
  String id;
  String title;
  String detail;
  String category; // Impact / Gap / Plan / Custom
  String owner;
  int severity; // 1..3
  int likelihood; // 1..3

  ScenarioRecord({
    this.id = '',
    this.title = '',
    this.detail = '',
    this.category = 'Custom',
    this.owner = '',
    this.severity = 2,
    this.likelihood = 2,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'detail': detail,
        'category': category,
        'owner': owner,
        'severity': severity,
        'likelihood': likelihood,
      };

  factory ScenarioRecord.fromJson(Map<String, dynamic> json) => ScenarioRecord(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        detail: json['detail'] ?? '',
        category: json['category'] ?? 'Custom',
        owner: json['owner'] ?? '',
        severity:
            (json['severity'] is num) ? (json['severity'] as num).toInt() : 2,
        likelihood: (json['likelihood'] is num)
            ? (json['likelihood'] as num).toInt()
            : 2,
      );
}

class DesignDeliverablesData {
  final DesignDeliverablesMetrics metrics;
  final List<DesignDeliverablePipelineItem> pipeline;
  final List<String> approvals;
  final List<DesignDeliverableRegisterItem> register;
  final List<String> dependencies;
  final List<String> handoffChecklist;

  const DesignDeliverablesData({
    this.metrics = const DesignDeliverablesMetrics(),
    this.pipeline = const [],
    this.approvals = const [],
    this.register = const [],
    this.dependencies = const [],
    this.handoffChecklist = const [],
  });

  bool get isEmpty =>
      pipeline.isEmpty &&
      approvals.isEmpty &&
      register.isEmpty &&
      dependencies.isEmpty &&
      handoffChecklist.isEmpty;

  DesignDeliverablesData copyWith({
    DesignDeliverablesMetrics? metrics,
    List<DesignDeliverablePipelineItem>? pipeline,
    List<String>? approvals,
    List<DesignDeliverableRegisterItem>? register,
    List<String>? dependencies,
    List<String>? handoffChecklist,
  }) {
    return DesignDeliverablesData(
      metrics: metrics ?? this.metrics,
      pipeline: pipeline ?? this.pipeline,
      approvals: approvals ?? this.approvals,
      register: register ?? this.register,
      dependencies: dependencies ?? this.dependencies,
      handoffChecklist: handoffChecklist ?? this.handoffChecklist,
    );
  }

  Map<String, dynamic> toJson() => {
        'metrics': metrics.toJson(),
        'pipeline': pipeline.map((item) => item.toJson()).toList(),
        'approvals': approvals,
        'register': register.map((item) => item.toJson()).toList(),
        'dependencies': dependencies,
        'handoffChecklist': handoffChecklist,
      };

  factory DesignDeliverablesData.fromJson(Map<String, dynamic> json) {
    return DesignDeliverablesData(
      metrics: DesignDeliverablesMetrics.fromJson(
          json['metrics'] as Map<String, dynamic>? ?? {}),
      pipeline: (json['pipeline'] as List?)
              ?.map((e) => DesignDeliverablePipelineItem.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      approvals:
          (json['approvals'] as List?)?.map((e) => e.toString()).toList() ?? [],
      register: (json['register'] as List?)
              ?.map((e) => DesignDeliverableRegisterItem.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      dependencies:
          (json['dependencies'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      handoffChecklist: (json['handoffChecklist'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  factory DesignDeliverablesData.fromMap(Map<String, dynamic> map) =>
      DesignDeliverablesData.fromJson(map);
}

class DesignDeliverablesMetrics {
  final int active;
  final int inReview;
  final int approved;
  final int atRisk;

  const DesignDeliverablesMetrics({
    this.active = 0,
    this.inReview = 0,
    this.approved = 0,
    this.atRisk = 0,
  });

  DesignDeliverablesMetrics copyWith({
    int? active,
    int? inReview,
    int? approved,
    int? atRisk,
  }) {
    return DesignDeliverablesMetrics(
      active: active ?? this.active,
      inReview: inReview ?? this.inReview,
      approved: approved ?? this.approved,
      atRisk: atRisk ?? this.atRisk,
    );
  }

  Map<String, dynamic> toJson() => {
        'active': active,
        'inReview': inReview,
        'approved': approved,
        'atRisk': atRisk,
      };

  factory DesignDeliverablesMetrics.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return DesignDeliverablesMetrics(
      active: toInt(json['active']),
      inReview: toInt(json['inReview'] ?? json['in_review']),
      approved: toInt(json['approved']),
      atRisk: toInt(json['atRisk'] ?? json['at_risk']),
    );
  }
}

class DesignDeliverablePipelineItem {
  final String label;
  final String status;

  const DesignDeliverablePipelineItem({
    this.label = '',
    this.status = '',
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'status': status,
      };

  factory DesignDeliverablePipelineItem.fromJson(Map<String, dynamic> json) {
    return DesignDeliverablePipelineItem(
      label: json['label']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class DesignDeliverableRegisterItem {
  final String name;
  final String owner;
  final String status;
  final String due;
  final String risk;

  const DesignDeliverableRegisterItem({
    this.name = '',
    this.owner = '',
    this.status = '',
    this.due = '',
    this.risk = '',
  });

  DesignDeliverableRegisterItem copyWith({
    String? name,
    String? owner,
    String? status,
    String? due,
    String? risk,
  }) {
    return DesignDeliverableRegisterItem(
      name: name ?? this.name,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      due: due ?? this.due,
      risk: risk ?? this.risk,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'owner': owner,
        'status': status,
        'due': due,
        'risk': risk,
      };

  factory DesignDeliverableRegisterItem.fromJson(Map<String, dynamic> json) {
    return DesignDeliverableRegisterItem(
      name: json['name']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      due: json['due']?.toString() ?? '',
      risk: json['risk']?.toString() ?? '',
    );
  }
}

/// Field history tracking for undo functionality
class FieldHistory {
  final String fieldName;
  final List<String> history;
  final bool isAiGenerated;

  FieldHistory({
    required this.fieldName,
    List<String>? history,
    this.isAiGenerated = false,
  }) : history = history ?? [];

  /// Add a value to history
  void addToHistory(String value) {
    history.add(value);
    // Limit history to last 50 entries to prevent memory issues
    if (history.length > 50) {
      history.removeAt(0);
    }
  }

  /// Undo the last change (remove last entry and return previous)
  String? undo() {
    if (history.length > 1) {
      history.removeLast();
      return history.last;
    }
    return null;
  }

  /// Check if undo is possible
  bool get canUndo => history.length > 1;

  /// Get current value (last in history)
  String? get currentValue => history.isNotEmpty ? history.last : null;

  Map<String, dynamic> toJson() => {
        'fieldName': fieldName,
        'history': history,
        'isAiGenerated': isAiGenerated,
      };

  factory FieldHistory.fromJson(Map<String, dynamic> json) {
    return FieldHistory(
      fieldName: json['fieldName']?.toString() ?? '',
      history:
          (json['history'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isAiGenerated: json['isAiGenerated'] == true,
    );
  }
}

class RoleDefinition {
  String id;
  String title;
  String description;
  String workstream;
  bool isPredefined;

  RoleDefinition({
    String? id,
    this.title = '',
    this.description = '',
    this.workstream = '',
    this.isPredefined = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'workstream': workstream,
        'isPredefined': isPredefined,
      };

  factory RoleDefinition.fromJson(Map<String, dynamic> json) {
    return RoleDefinition(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      workstream: json['workstream']?.toString() ?? '',
      isPredefined: json['isPredefined'] == true,
    );
  }
}

class StaffingRequirement {
  String id;
  String title;
  int headcount;
  String startDate;
  String endDate;
  String status;
  String personName;
  String employmentType; // FT or PT
  String location;
  String employeeType; // e.g., Employee, Contractor

  StaffingRequirement({
    String? id,
    this.title = '',
    this.headcount = 1,
    this.startDate = '',
    this.endDate = '',
    this.status = 'Not Started',
    this.personName = '',
    this.employmentType = 'FT',
    this.location = '',
    this.employeeType = 'Employee',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'headcount': headcount,
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
        'personName': personName,
        'employmentType': employmentType,
        'location': location,
        'employeeType': employeeType,
      };

  factory StaffingRequirement.fromJson(Map<String, dynamic> json) {
    return StaffingRequirement(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      headcount: json['headcount'] as int? ?? 1,
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Not Started',
      personName: json['personName']?.toString() ?? '',
      employmentType: json['employmentType']?.toString() ?? 'FT',
      location: json['location']?.toString() ?? '',
      employeeType: json['employeeType']?.toString() ?? 'Employee',
    );
  }

  StaffingRequirement copyWith({
    String? title,
    int? headcount,
    String? startDate,
    String? endDate,
    String? status,
    String? personName,
    String? employmentType,
    String? location,
    String? employeeType,
  }) {
    return StaffingRequirement(
      id: id,
      title: title ?? this.title,
      headcount: headcount ?? this.headcount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      personName: personName ?? this.personName,
      employmentType: employmentType ?? this.employmentType,
      location: location ?? this.location,
      employeeType: employeeType ?? this.employeeType,
    );
  }
}

class TrainingActivity {
  String id;
  String title;
  String date;
  String duration;
  String category; // Training or Team Building
  String status;
  bool isMandatory;

  TrainingActivity({
    String? id,
    this.title = '',
    this.date = '',
    this.duration = '',
    this.category = 'Training',
    this.status = 'Upcoming',
    this.isMandatory = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'duration': duration,
        'category': category,
        'status': status,
        'isMandatory': isMandatory,
      };

  factory TrainingActivity.fromJson(Map<String, dynamic> json) {
    return TrainingActivity(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Training',
      status: json['status']?.toString() ?? 'Upcoming',
      isMandatory: json['isMandatory'] == true,
    );
  }

  TrainingActivity copyWith({
    String? title,
    String? date,
    String? duration,
    String? category,
    String? status,
    bool? isMandatory,
  }) {
    return TrainingActivity(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      status: status ?? this.status,
      isMandatory: isMandatory ?? this.isMandatory,
    );
  }
}

class StakeholderEntry {
  final String id;
  final String name;
  final String organization;
  final String role;
  final String influence;
  final String interest;
  final String channel;
  final String contactInfo;
  final String owner;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  StakeholderEntry({
    required this.id,
    required this.name,
    required this.organization,
    required this.role,
    required this.influence,
    required this.interest,
    required this.channel,
    required this.contactInfo,
    required this.owner,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StakeholderEntry.empty() {
    final now = DateTime.now();
    return StakeholderEntry(
      id: now.microsecondsSinceEpoch.toString(),
      name: '',
      organization: '',
      role: '',
      influence: 'Medium',
      interest: 'Medium',
      channel: '',
      contactInfo: '',
      owner: '',
      notes: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  StakeholderEntry copyWith({
    String? name,
    String? organization,
    String? role,
    String? influence,
    String? interest,
    String? channel,
    String? contactInfo,
    String? owner,
    String? notes,
    DateTime? updatedAt,
  }) {
    return StakeholderEntry(
      id: id,
      name: name ?? this.name,
      organization: organization ?? this.organization,
      role: role ?? this.role,
      influence: influence ?? this.influence,
      interest: interest ?? this.interest,
      channel: channel ?? this.channel,
      contactInfo: contactInfo ?? this.contactInfo,
      owner: owner ?? this.owner,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'organization': organization,
        'role': role,
        'influence': influence,
        'interest': interest,
        'channel': channel,
        'contactInfo': contactInfo,
        'owner': owner,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory StakeholderEntry.fromJson(Map<String, dynamic> json) {
    return StakeholderEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      organization: json['organization']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      influence: json['influence']?.toString() ?? 'Medium',
      interest: json['interest']?.toString() ?? 'Medium',
      channel: json['channel']?.toString() ?? '',
      contactInfo: json['contactInfo']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class EngagementPlanEntry {
  final String id;
  final String stakeholder;
  final String objective;
  final String method;
  final String frequency;
  final String owner;
  final String status;
  final String nextTouchpoint;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  EngagementPlanEntry({
    required this.id,
    required this.stakeholder,
    required this.objective,
    required this.method,
    required this.frequency,
    required this.owner,
    required this.status,
    required this.nextTouchpoint,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EngagementPlanEntry.empty() {
    final now = DateTime.now();
    return EngagementPlanEntry(
      id: now.microsecondsSinceEpoch.toString(),
      stakeholder: '',
      objective: '',
      method: '',
      frequency: '',
      owner: '',
      status: 'Planned',
      nextTouchpoint: '',
      notes: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  EngagementPlanEntry copyWith({
    String? stakeholder,
    String? objective,
    String? method,
    String? frequency,
    String? owner,
    String? status,
    String? nextTouchpoint,
    String? notes,
    DateTime? updatedAt,
  }) {
    return EngagementPlanEntry(
      id: id,
      stakeholder: stakeholder ?? this.stakeholder,
      objective: objective ?? this.objective,
      method: method ?? this.method,
      frequency: frequency ?? this.frequency,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      nextTouchpoint: nextTouchpoint ?? this.nextTouchpoint,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stakeholder': stakeholder,
        'objective': objective,
        'method': method,
        'frequency': frequency,
        'owner': owner,
        'status': status,
        'nextTouchpoint': nextTouchpoint,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory EngagementPlanEntry.fromJson(Map<String, dynamic> json) {
    return EngagementPlanEntry(
      id: json['id']?.toString() ?? '',
      stakeholder: json['stakeholder']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Planned',
      nextTouchpoint: json['nextTouchpoint']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

enum QualityTargetStatus { onTrack, monitoring, offTrack }

class QualityTarget {
  final String id;
  final String name;
  final String metric;
  final String target;
  final String current;
  final QualityTargetStatus status;

  QualityTarget({
    required this.id,
    required this.name,
    required this.metric,
    required this.target,
    required this.current,
    required this.status,
  });

  factory QualityTarget.empty() {
    return QualityTarget(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
      metric: '',
      target: '',
      current: '',
      status: QualityTargetStatus.onTrack,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'metric': metric,
        'target': target,
        'current': current,
        'status': status.index,
      };

  factory QualityTarget.fromJson(Map<String, dynamic> json) {
    var statusValue = json['status'];
    QualityTargetStatus status;
    if (statusValue is int) {
      status = QualityTargetStatus.values[statusValue];
    } else {
      status = QualityTargetStatus.onTrack;
    }

    return QualityTarget(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      metric: json['metric']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      current: json['current']?.toString() ?? '',
      status: status,
    );
  }

  QualityTarget copyWith({
    String? name,
    String? metric,
    String? target,
    String? current,
    QualityTargetStatus? status,
  }) {
    return QualityTarget(
      id: id,
      name: name ?? this.name,
      metric: metric ?? this.metric,
      target: target ?? this.target,
      current: current ?? this.current,
      status: status ?? this.status,
    );
  }
}

class QaTechnique {
  final String id;
  final String name;
  final String description;
  final String frequency;
  final String standards;

  QaTechnique({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
    required this.standards,
  });

  factory QaTechnique.empty() {
    return QaTechnique(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
      description: '',
      frequency: '',
      standards: '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'frequency': frequency,
        'standards': standards,
      };

  factory QaTechnique.fromJson(Map<String, dynamic> json) {
    return QaTechnique(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      standards: json['standards']?.toString() ?? '',
    );
  }

  QaTechnique copyWith({
    String? name,
    String? description,
    String? frequency,
    String? standards,
  }) {
    return QaTechnique(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      standards: standards ?? this.standards,
    );
  }
}

class QcTechnique {
  final String id;
  final String name;
  final String description;
  final String frequency;

  QcTechnique({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
  });

  factory QcTechnique.empty() {
    return QcTechnique(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
      description: '',
      frequency: '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'frequency': frequency,
      };

  factory QcTechnique.fromJson(Map<String, dynamic> json) {
    return QcTechnique(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
    );
  }

  QcTechnique copyWith({
    String? name,
    String? description,
    String? frequency,
  }) {
    return QcTechnique(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
    );
  }
}

class MetricValue {
  final String value;
  final String unit;
  final String change;
  final String trendDirection; // "up", "down", "neutral"

  MetricValue({
    this.value = '',
    this.unit = '',
    this.change = '',
    this.trendDirection = 'neutral',
  });

  factory MetricValue.empty() => MetricValue();

  Map<String, dynamic> toJson() => {
        'value': value,
        'unit': unit,
        'change': change,
        'trendDirection': trendDirection,
      };

  factory MetricValue.fromJson(Map<String, dynamic> json) {
    return MetricValue(
      value: json['value']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      change: json['change']?.toString() ?? '',
      trendDirection: json['trendDirection']?.toString() ?? 'neutral',
    );
  }

  MetricValue copyWith({
    String? value,
    String? unit,
    String? change,
    String? trendDirection,
  }) {
    return MetricValue(
      value: value ?? this.value,
      unit: unit ?? this.unit,
      change: change ?? this.change,
      trendDirection: trendDirection ?? this.trendDirection,
    );
  }
}

class QualityMetrics {
  final MetricValue defectDensity;
  final MetricValue customerSatisfaction;
  final MetricValue onTimeDelivery;
  final List<double> defectTrendData;
  final List<double> satisfactionTrendData;

  QualityMetrics({
    required this.defectDensity,
    required this.customerSatisfaction,
    required this.onTimeDelivery,
    required this.defectTrendData,
    required this.satisfactionTrendData,
  });

  factory QualityMetrics.empty() {
    return QualityMetrics(
      defectDensity: MetricValue.empty(),
      customerSatisfaction: MetricValue.empty(),
      onTimeDelivery: MetricValue.empty(),
      defectTrendData: [],
      satisfactionTrendData: [],
    );
  }

  Map<String, dynamic> toJson() => {
        'defectDensity': defectDensity.toJson(),
        'customerSatisfaction': customerSatisfaction.toJson(),
        'onTimeDelivery': onTimeDelivery.toJson(),
        'defectTrendData': defectTrendData,
        'satisfactionTrendData': satisfactionTrendData,
      };

  factory QualityMetrics.fromJson(Map<String, dynamic> json) {
    return QualityMetrics(
      defectDensity: json['defectDensity'] != null
          ? MetricValue.fromJson(json['defectDensity'])
          : MetricValue.empty(),
      customerSatisfaction: json['customerSatisfaction'] != null
          ? MetricValue.fromJson(json['customerSatisfaction'])
          : MetricValue.empty(),
      onTimeDelivery: json['onTimeDelivery'] != null
          ? MetricValue.fromJson(json['onTimeDelivery'])
          : MetricValue.empty(),
      defectTrendData: (json['defectTrendData'] as List?)
              ?.map((e) => double.tryParse(e.toString()) ?? 0.0)
              .toList() ??
          [],
      satisfactionTrendData: (json['satisfactionTrendData'] as List?)
              ?.map((e) => double.tryParse(e.toString()) ?? 0.0)
              .toList() ??
          [],
    );
  }

  QualityMetrics copyWith({
    MetricValue? defectDensity,
    MetricValue? customerSatisfaction,
    MetricValue? onTimeDelivery,
    List<double>? defectTrendData,
    List<double>? satisfactionTrendData,
  }) {
    return QualityMetrics(
      defectDensity: defectDensity ?? this.defectDensity,
      customerSatisfaction: customerSatisfaction ?? this.customerSatisfaction,
      onTimeDelivery: onTimeDelivery ?? this.onTimeDelivery,
      defectTrendData: defectTrendData ?? this.defectTrendData,
      satisfactionTrendData:
          satisfactionTrendData ?? this.satisfactionTrendData,
    );
  }
}

class QualityManagementData {
  final String qualityPlan;
  final List<QualityTarget> targets;
  final List<QaTechnique> qaTechniques;
  final List<QcTechnique> qcTechniques;
  final QualityMetrics metrics;

  QualityManagementData({
    required this.qualityPlan,
    required this.targets,
    required this.qaTechniques,
    required this.qcTechniques,
    required this.metrics,
  });

  factory QualityManagementData.empty() {
    return QualityManagementData(
      qualityPlan: '',
      targets: [],
      qaTechniques: [],
      qcTechniques: [],
      metrics: QualityMetrics.empty(),
    );
  }

  Map<String, dynamic> toJson() => {
        'qualityPlan': qualityPlan,
        'targets': targets.map((t) => t.toJson()).toList(),
        'qaTechniques': qaTechniques.map((t) => t.toJson()).toList(),
        'qcTechniques': qcTechniques.map((t) => t.toJson()).toList(),
        'metrics': metrics.toJson(),
      };

  factory QualityManagementData.fromJson(Map<String, dynamic> json) {
    return QualityManagementData(
      qualityPlan: json['qualityPlan']?.toString() ?? '',
      targets: (json['targets'] as List?)
              ?.map((e) => QualityTarget.fromJson(e))
              .toList() ??
          [],
      qaTechniques: (json['qaTechniques'] as List?)
              ?.map((e) => QaTechnique.fromJson(e))
              .toList() ??
          [],
      qcTechniques: (json['qcTechniques'] as List?)
              ?.map((e) => QcTechnique.fromJson(e))
              .toList() ??
          [],
      metrics: json['metrics'] != null
          ? QualityMetrics.fromJson(json['metrics'])
          : QualityMetrics.empty(),
    );
  }

  QualityManagementData copyWith({
    String? qualityPlan,
    List<QualityTarget>? targets,
    List<QaTechnique>? qaTechniques,
    List<QcTechnique>? qcTechniques,
    QualityMetrics? metrics,
  }) {
    return QualityManagementData(
      qualityPlan: qualityPlan ?? this.qualityPlan,
      targets: targets ?? this.targets,
      qaTechniques: qaTechniques ?? this.qaTechniques,
      qcTechniques: qcTechniques ?? this.qcTechniques,
      metrics: metrics ?? this.metrics,
    );
  }
}

class Contractor {
  final String id;
  String name;
  String service;
  double estimatedCost;
  String status;
  String notes;

  Contractor({
    required this.id,
    this.name = '',
    this.service = '',
    this.estimatedCost = 0.0,
    this.status = 'Pending',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'service': service,
        'estimatedCost': estimatedCost,
        'status': status,
        'notes': notes,
      };

  factory Contractor.fromJson(Map<String, dynamic> json) {
    return Contractor(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      estimatedCost: (json['estimatedCost'] is num)
          ? (json['estimatedCost'] as num).toDouble()
          : double.tryParse(json['estimatedCost']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'Pending',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class Vendor {
  final String id;
  String name;
  String equipmentOrService;
  double estimatedPrice;
  String procurementStage;
  String status;
  String notes;

  Vendor({
    required this.id,
    this.name = '',
    this.equipmentOrService = '',
    this.estimatedPrice = 0.0,
    this.procurementStage = 'Identified',
    this.status = 'Pending',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'equipmentOrService': equipmentOrService,
        'estimatedPrice': estimatedPrice,
        'procurementStage': procurementStage,
        'status': status,
        'notes': notes,
      };

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      equipmentOrService: json['equipmentOrService']?.toString() ?? '',
      estimatedPrice: (json['estimatedPrice'] is num)
          ? (json['estimatedPrice'] as num).toDouble()
          : double.tryParse(json['estimatedPrice']?.toString() ?? '0') ?? 0.0,
      procurementStage: json['procurementStage']?.toString() ?? 'Identified',
      status: json['status']?.toString() ?? 'Pending',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

// --- Design Management Data Models ---

class DesignManagementData {
  List<DesignSpecification> specifications;
  List<DesignDocument> documents;
  List<DesignToolLink> tools;

  DesignManagementData({
    List<DesignSpecification>? specifications,
    List<DesignDocument>? documents,
    List<DesignToolLink>? tools,
  })  : specifications = specifications ?? [],
        documents = documents ?? [],
        tools = tools ?? [];

  Map<String, dynamic> toJson() => {
        'specifications': specifications.map((e) => e.toJson()).toList(),
        'documents': documents.map((e) => e.toJson()).toList(),
        'tools': tools.map((e) => e.toJson()).toList(),
      };

  factory DesignManagementData.fromJson(Map<String, dynamic> json) {
    return DesignManagementData(
      specifications: (json['specifications'] as List?)
              ?.map((e) =>
                  DesignSpecification.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      documents: (json['documents'] as List?)
              ?.map(
                  (e) => DesignDocument.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      tools: (json['tools'] as List?)
              ?.map(
                  (e) => DesignToolLink.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}

class DesignSpecification {
  String id;
  String description;
  String status; // 'Defined', 'Validated', 'Implemented'

  DesignSpecification({
    String? id,
    this.description = '',
    this.status = 'Defined',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'status': status,
      };

  factory DesignSpecification.fromJson(Map<String, dynamic> json) {
    return DesignSpecification(
      id: json['id']?.toString(),
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Defined',
    );
  }
}

class DesignDocument {
  String id;
  String title;
  String type; // 'Input' or 'Output'
  String? url;
  String? notes;

  DesignDocument({
    String? id,
    this.title = '',
    this.type = 'Output',
    this.url,
    this.notes,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'url': url,
        'notes': notes,
      };

  factory DesignDocument.fromJson(Map<String, dynamic> json) {
    return DesignDocument(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Output',
      url: json['url']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class DesignToolLink {
  String id;
  String name;
  String url;
  bool isInternal;

  DesignToolLink({
    String? id,
    this.name = '',
    this.url = '',
    this.isInternal = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'isInternal': isInternal,
      };

  factory DesignToolLink.fromJson(Map<String, dynamic> json) {
    return DesignToolLink(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      isInternal: json['isInternal'] == true,
    );
  }
}
