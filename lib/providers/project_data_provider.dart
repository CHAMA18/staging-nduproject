import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider that manages project data state across the entire application
class ProjectDataProvider extends ChangeNotifier {
  ProjectDataModel _projectData = ProjectDataModel();
  bool _isSaving = false;
  String? _lastError;
  String? _cachedProjectId; // Cache to prevent redundant loads

  ProjectDataModel get projectData => _projectData;
  bool get isSaving => _isSaving;
  String? get lastError => _lastError;

  /// Update project data and notify listeners
  void updateProjectData(ProjectDataModel data) {
    if (_projectData == data) return; // Skip if no change
    _projectData = data;
    notifyListeners();
  }

  /// Update specific fields in project data
  void updateField(ProjectDataModel Function(ProjectDataModel) updater) {
    _projectData = updater(_projectData);
    notifyListeners();
  }

  /// Save current project data to Firebase
  Future<bool> saveToFirebase({String? checkpoint}) async {
    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _lastError = 'User not authenticated';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final projectsCol = FirebaseFirestore.instance.collection('projects');
      final now = FieldValue.serverTimestamp();
      
      // Prepare data payload
      final dataPayload = {
        ..._projectData.toJson(),
        'ownerId': user.uid,
        'ownerName': user.displayName ?? user.email ?? 'User',
        'ownerEmail': user.email,
        'updatedAt': now,
        if (checkpoint != null) 'checkpointRoute': checkpoint,
        if (checkpoint != null) 'checkpointAt': now,
      };

      if (_projectData.projectId != null) {
        // Update existing project
        await projectsCol.doc(_projectData.projectId).update(dataPayload);
      } else {
        // Create new project
        dataPayload['createdAt'] = now;
        dataPayload['status'] = dataPayload['status'] ?? 'Initiation'; // Use Initiation instead of 'In Progress' to match query expectations
        dataPayload['progress'] = dataPayload['progress'] ?? 0.1;
        dataPayload['investmentMillions'] = dataPayload['investmentMillions'] ?? 0.0;
        dataPayload['milestone'] = checkpoint ?? 'initiation';
        
        // Ensure both 'name' and 'projectName' are set for query compatibility
        final projectName = dataPayload['projectName'] ?? dataPayload['name'] ?? '';
        if (projectName.isNotEmpty) {
          dataPayload['name'] = projectName;
          dataPayload['projectName'] = projectName;
        }
        
        // Ensure isBasicPlanProject is set
        dataPayload['isBasicPlanProject'] = dataPayload['isBasicPlanProject'] ?? false;
        
        final ref = await projectsCol.add(dataPayload);
        _projectData = _projectData.copyWith(
          projectId: ref.id,
          createdAt: DateTime.now(),
        );
        
        debugPrint('✅ Project created with ID: ${ref.id}, name: $projectName, ownerId: ${user.uid}');
      }

      _projectData = _projectData.copyWith(
        updatedAt: DateTime.now(),
        currentCheckpoint: checkpoint ?? _projectData.currentCheckpoint,
      );

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Load project data from Firebase by ID
  Future<bool> loadFromFirebase(String projectId) async {
    // Skip if already loaded and cached, but only if data is valid
    if (_cachedProjectId == projectId && 
        _projectData.projectId == projectId && 
        _projectData.projectId != null &&
        _projectData.projectId!.isNotEmpty) {
      // Verify the cached data is still valid by checking if project exists
      try {
        final doc = await FirebaseFirestore.instance.collection('projects').doc(projectId).get();
        if (doc.exists) {
          return true; // Cached data is valid
        }
      } catch (e) {
        debugPrint('Error validating cached project: $e');
        // Continue to reload if validation fails
      }
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('projects').doc(projectId).get();
      
      if (!doc.exists) {
        _lastError = 'Project not found';
        debugPrint('❌ Project not found: $projectId');
        notifyListeners();
        return false;
      }

      final data = doc.data();
      if (data == null) {
        _lastError = 'Project data is empty';
        debugPrint('❌ Project data is null: $projectId');
        notifyListeners();
        return false;
      }

      debugPrint('📦 Loading project data for: $projectId');
      debugPrint('Raw data keys: ${data.keys.toList()}');

      // Convert Firestore Timestamps to ISO8601 strings for compatibility (recursive)
      final sanitizedData = _sanitizeTimestampsRecursive(data) as Map<String, dynamic>;

      try {
        _projectData = ProjectDataModel.fromJson(sanitizedData);
        _projectData = _projectData.copyWith(projectId: projectId);
        _cachedProjectId = projectId;
        debugPrint('✅ Project loaded successfully: ${_projectData.projectName}');
        notifyListeners();
        return true;
      } catch (parseError) {
        _lastError = 'Failed to parse project data: ${parseError.toString()}';
        debugPrint('❌ Parse error: $parseError');
        debugPrint('Sanitized data: $sanitizedData');
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _lastError = e.toString();
      debugPrint('❌ Error loading project: $e');
      debugPrint('Stack trace: $stackTrace');
      notifyListeners();
      return false;
    }
  }

  /// Recursively sanitize Timestamp objects in nested data structures
  static dynamic _sanitizeTimestampsRecursive(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is List) {
      return value.map((item) => _sanitizeTimestampsRecursive(item)).toList();
    } else if (value is Map) {
      final sanitizedMap = <String, dynamic>{};
      value.forEach((key, val) {
        sanitizedMap[key.toString()] = _sanitizeTimestampsRecursive(val);
      });
      return sanitizedMap;
    }
    return value;
  }

  /// Reset project data to initial state
  void reset() {
    final hadData = _projectData.projectId != null;
    _projectData = ProjectDataModel();
    _lastError = null;
    _cachedProjectId = null; // Clear cache
    if (hadData) notifyListeners(); // Only notify if there was data to clear
  }

  /// Update initiation phase data
  void updateInitiationData({
    String? projectName,
    String? solutionTitle,
    String? solutionDescription,
    String? businessCase,
    String? notes,
    List<String>? tags,
    List<PotentialSolution>? potentialSolutions,
    List<SolutionRisk>? solutionRisks,
  }) {
    _projectData = _projectData.copyWith(
      projectName: projectName ?? _projectData.projectName,
      solutionTitle: solutionTitle ?? _projectData.solutionTitle,
      solutionDescription: solutionDescription ?? _projectData.solutionDescription,
      businessCase: businessCase ?? _projectData.businessCase,
      notes: notes ?? _projectData.notes,
      tags: tags ?? _projectData.tags,
      potentialSolutions: potentialSolutions ?? _projectData.potentialSolutions,
      solutionRisks: solutionRisks ?? _projectData.solutionRisks,
    );
    notifyListeners();
  }

  /// Update project framework data
  void updateFrameworkData({
    String? overallFramework,
    List<ProjectGoal>? projectGoals,
  }) {
    _projectData = _projectData.copyWith(
      overallFramework: overallFramework ?? _projectData.overallFramework,
      projectGoals: projectGoals ?? _projectData.projectGoals,
    );
    notifyListeners();
  }

  /// Update planning phase data
  void updatePlanningData({
    String? potentialSolution,
    String? projectObjective,
    List<PlanningGoal>? planningGoals,
    List<Milestone>? keyMilestones,
    Map<String, String>? planningNotes,
  }) {
    _projectData = _projectData.copyWith(
      potentialSolution: potentialSolution ?? _projectData.potentialSolution,
      projectObjective: projectObjective ?? _projectData.projectObjective,
      planningGoals: planningGoals ?? _projectData.planningGoals,
      keyMilestones: keyMilestones ?? _projectData.keyMilestones,
      planningNotes: planningNotes ?? _projectData.planningNotes,
    );
    notifyListeners();
  }

  /// Update work breakdown structure data
  void updateWBSData({
    String? wbsCriteriaA,
    String? wbsCriteriaB,
    List<List<WorkItem>>? goalWorkItems,
    List<WorkItem>? wbsTree,
  }) {
    _projectData = _projectData.copyWith(
      wbsCriteriaA: wbsCriteriaA ?? _projectData.wbsCriteriaA,
      wbsCriteriaB: wbsCriteriaB ?? _projectData.wbsCriteriaB,
      goalWorkItems: goalWorkItems ?? _projectData.goalWorkItems,
      wbsTree: wbsTree ?? _projectData.wbsTree,
    );
    notifyListeners();
  }

  /// Update front end planning data
  void updateFrontEndPlanningData(FrontEndPlanningData data) {
    _projectData = _projectData.copyWith(frontEndPlanning: data);
    notifyListeners();
  }

  /// Update SSHER data
  void updateSSHERData(SSHERData data) {
    _projectData = _projectData.copyWith(ssherData: data);
    notifyListeners();
  }

  /// Update team members
  void updateTeamMembers(List<TeamMember> members) {
    _projectData = _projectData.copyWith(teamMembers: members);
    notifyListeners();
  }
}

/// InheritedWidget to provide project data throughout the widget tree
class ProjectDataInherited extends InheritedNotifier<ProjectDataProvider> {
  const ProjectDataInherited({
    super.key,
    required ProjectDataProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static ProjectDataProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ProjectDataInherited>()?.notifier;
  }

  static ProjectDataProvider of(BuildContext context) {
    final provider = maybeOf(context);
    assert(provider != null, 'No ProjectDataInherited found in context');
    return provider!;
  }
}
