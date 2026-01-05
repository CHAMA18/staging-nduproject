import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProjectRecord {
  final String id;
  final String ownerId;
  final String ownerEmail;
  final String ownerName;
  final String name;
  final String solutionTitle;
  final String solutionDescription;
  final String businessCase;
  final String notes;
  final String status;
  final double progress;
  final double investmentMillions;
  final String milestone;
  final List<String> tags;
  final bool isBasicPlanProject;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String checkpointRoute; // identifies where to resume when opening from dashboard
  final DateTime? checkpointAt;

  ProjectRecord({
    required this.id,
    required this.ownerId,
    required this.ownerEmail,
    required this.ownerName,
    required this.name,
    required this.solutionTitle,
    required this.solutionDescription,
    required this.businessCase,
    required this.notes,
    required this.status,
    required this.progress,
    required this.investmentMillions,
    required this.milestone,
    required this.tags,
    required this.isBasicPlanProject,
    required this.createdAt,
    required this.updatedAt,
    required this.checkpointRoute,
    required this.checkpointAt,
  });

  factory ProjectRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final tagsRaw = data['tags'];
    final createdTs = data['createdAt'];
    final updatedTs = data['updatedAt'];

    List<String> parseTags(dynamic raw) {
      if (raw is Iterable) {
        return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList(growable: false);
      }
      return const [];
    }

    DateTime parseTimestamp(dynamic ts, {required DateTime fallback}) {
      if (ts is Timestamp) return ts.toDate();
      if (ts is DateTime) return ts;
      return fallback;
    }

    double parseDouble(dynamic value, {double fallback = 0}) {
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      return parsed ?? fallback;
    }

    return ProjectRecord(
      id: doc.id,
      ownerId: (data['ownerId'] ?? '').toString(),
      ownerEmail: (data['ownerEmail'] ?? '').toString(),
      ownerName: (data['ownerName'] ?? '').toString(),
      name: (data['name'] ?? data['projectName'] ?? '').toString(),
      solutionTitle: (data['solutionTitle'] ?? '').toString(),
      solutionDescription: (data['solutionDescription'] ?? '').toString(),
      businessCase: (data['businessCase'] ?? '').toString(),
      notes: (data['notes'] ?? '').toString(),
      status: (data['status'] ?? 'Initiation').toString(),
      progress: parseDouble(data['progress'], fallback: 0.0).clamp(0.0, 1.0).toDouble(),
      investmentMillions: parseDouble(data['investmentMillions'], fallback: 0.0),
      milestone: (data['milestone'] ?? '').toString(),
      tags: parseTags(tagsRaw),
      isBasicPlanProject: data['isBasicPlanProject'] == true,
      createdAt: parseTimestamp(createdTs, fallback: DateTime.fromMillisecondsSinceEpoch(0)),
      updatedAt: parseTimestamp(updatedTs, fallback: DateTime.fromMillisecondsSinceEpoch(0)),
      checkpointRoute: (data['checkpointRoute'] ?? '').toString(),
      checkpointAt: data['checkpointAt'] is Timestamp ? (data['checkpointAt'] as Timestamp).toDate() : null,
    );
  }
}

class ProjectService {
  static final CollectionReference<Map<String, dynamic>> _projectsCol = FirebaseFirestore.instance.collection('projects');

  /// Check if a project name already exists for the given owner.
  /// Case-sensitive match on the stored `name` field.
  static Future<bool> projectNameExists({
    required String ownerId,
    required String name,
  }) async {
    try {
      final query = await _projectsCol
          .where('ownerId', isEqualTo: ownerId)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (_) {
      // If the check fails for any reason, do not block save due to transient errors.
      return false;
    }
  }

  static Future<String> createProject({
    required String ownerId,
    required String ownerName,
    required String name,
    required String solutionTitle,
    required String solutionDescription,
    required String businessCase,
    required String notes,
    String? ownerEmail,
    double progress = 0.1,
    double investmentMillions = 0,
    String status = 'Initiation',
    String milestone = 'Initiation',
    List<String> tags = const [],
    String checkpointRoute = 'project_decision_summary',
  }) async {
    final now = FieldValue.serverTimestamp();
    final normalizedTags = tags.where((tag) => tag.trim().isNotEmpty).take(5).map((tag) => tag.trim()).toList();
    if (normalizedTags.isEmpty && status.trim().isNotEmpty) {
      normalizedTags.add(status.trim());
    }

    final sanitizedEmail = ownerEmail?.trim();

    if (ownerId.trim().isEmpty) {
      throw StateError('Missing owner ID for project creation');
    }

    final payload = {
      'ownerId': ownerId,
      'ownerName': ownerName,
      if (sanitizedEmail != null && sanitizedEmail.isNotEmpty) 'ownerEmail': sanitizedEmail.toLowerCase(),
      'name': name,
      'projectName': name,
      'solutionTitle': solutionTitle,
      'solutionDescription': solutionDescription,
      'businessCase': businessCase,
      'notes': notes,
      'status': status,
      'progress': progress,
      'investmentMillions': investmentMillions,
      'milestone': milestone,
      'tags': normalizedTags,
      'createdAt': now,
      'updatedAt': now,
      'checkpointRoute': checkpointRoute,
      'checkpointAt': now,
    };

    final ref = await _projectsCol.add(payload);
    return ref.id;
  }

  static Stream<List<ProjectRecord>> streamProjects({
    String? ownerId,
    int limit = 25,
    bool filterByOwner = true,
  }) {
    Query<Map<String, dynamic>> query = _projectsCol.orderBy('createdAt', descending: true).limit(limit);
    if (filterByOwner && ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.map(ProjectRecord.fromDoc).toList());
  }

  /// Stream projects by a list of project IDs (for program dashboard)
  static Stream<List<ProjectRecord>> streamProjectsByIds(List<String> projectIds) {
    if (projectIds.isEmpty) {
      return Stream.value([]);
    }
    
    // Firestore 'in' queries support up to 10 items, programs have max 3 projects so we're safe
    return _projectsCol
        .where(FieldPath.documentId, whereIn: projectIds)
        .snapshots()
        .handleError((error) {
          debugPrint('⚠️ Error streaming projects by IDs: $error');
          return null;
        })
        .map((snapshot) {
          final projects = <ProjectRecord>[];
          for (final doc in snapshot.docs) {
            try {
              if (doc.exists) {
                projects.add(ProjectRecord.fromDoc(doc));
              }
            } catch (e) {
              debugPrint('⚠️ Error parsing project ${doc.id}: $e');
            }
          }
          return projects;
        });
  }

  static Future<void> deleteProject(String projectId) {
    return _projectsCol.doc(projectId).delete();
  }

  /// Update project fields
  static Future<void> updateProject(String projectId, Map<String, dynamic> updates) async {
    final payload = Map<String, dynamic>.from(updates);
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _projectsCol.doc(projectId).update(payload);
  }

  /// Fetch a single project by id.
  static Future<ProjectRecord?> getProjectById(String projectId) async {
    try {
      final doc = await _projectsCol.doc(projectId).get();
      if (!doc.exists) return null;
      return ProjectRecord.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  /// Update a project's checkpoint route and timestamp.
  static Future<void> updateCheckpoint({
    required String projectId,
    required String checkpointRoute,
  }) async {
    await _projectsCol.doc(projectId).update({
      'checkpointRoute': checkpointRoute,
      'checkpointAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get total project count (admin only)
  static Future<int> getTotalProjectCount() async {
    try {
      final snapshot = await _projectsCol.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Watch all projects (admin only)
  static Stream<List<Map<String, dynamic>>> watchAllProjects() {
    return _projectsCol.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => {'projectId': doc.id, ...doc.data()}).toList(),
    );
  }
}
