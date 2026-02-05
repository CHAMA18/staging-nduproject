import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ndu_project/models/design_phase_models.dart';
import 'package:ndu_project/models/project_data_model.dart'; // Import for DesignDeliverablesData

class DesignPhaseService {
  // Singleton instance
  static final DesignPhaseService instance = DesignPhaseService._();

  DesignPhaseService._();

  static const String _collectionPath = 'design_phase_sections';

  DocumentReference<Map<String, dynamic>> _projectDoc(String projectId) {
    return FirebaseFirestore.instance.collection('projects').doc(projectId);
  }

  DocumentReference<Map<String, dynamic>> _sectionDoc(
      String projectId, String section) {
    return _projectDoc(projectId).collection(_collectionPath).doc(section);
  }

  // --- Requirements Implementation (Design Specifications) ---

  Future<Map<String, dynamic>> loadRequirementsImplementation(
      String projectId) async {
    try {
      final doc =
          await _sectionDoc(projectId, 'requirements_implementation').get();
      return doc.data() ?? {};
    } catch (e) {
      debugPrint('Error loading requirements implementation: $e');
      return {};
    }
  }

  Future<void> saveRequirementsImplementation(
    String projectId, {
    required String notes,
    required List<RequirementRow> requirements,
    required List<RequirementChecklistItem> checklist,
  }) async {
    try {
      await _sectionDoc(projectId, 'requirements_implementation').set({
        'notes': notes,
        'requirements': requirements.map((e) => e.toMap()).toList(),
        'checklist': checklist.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving requirements implementation: $e');
      rethrow;
    }
  }

  // --- Technical Alignment ---

  Future<Map<String, dynamic>> loadTechnicalAlignment(String projectId) async {
    try {
      final doc = await _sectionDoc(projectId, 'technical_alignment').get();
      return doc.data() ?? {};
    } catch (e) {
      debugPrint('Error loading technical alignment: $e');
      return {};
    }
  }

  Future<void> saveTechnicalAlignment(
    String projectId, {
    required String notes,
    required List<ConstraintRow> constraints,
    required List<RequirementMappingRow> mappings,
    required List<DependencyDecisionRow> dependencies,
  }) async {
    try {
      await _sectionDoc(projectId, 'technical_alignment').set({
        'notes': notes,
        'constraints': constraints.map((e) => e.toMap()).toList(),
        'mappings': mappings.map((e) => e.toMap()).toList(),
        'dependencies': dependencies.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving technical alignment: $e');
      rethrow;
    }
  }

  // --- Specialized Design ---

  Future<SpecializedDesignData> loadSpecializedDesign(String projectId) async {
    try {
      final doc = await _sectionDoc(projectId, 'specialized_design').get();
      if (doc.exists && doc.data() != null) {
        return SpecializedDesignData.fromMap(doc.data()!);
      }
      return SpecializedDesignData();
    } catch (e) {
      debugPrint('Error loading specialized design: $e');
      return SpecializedDesignData();
    }
  }

  Future<void> saveSpecializedDesign(
      String projectId, SpecializedDesignData data) async {
    try {
      final map = data.toMap();
      map['updatedAt'] = FieldValue.serverTimestamp();
      await _sectionDoc(projectId, 'specialized_design')
          .set(map, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving specialized design: $e');
      rethrow;
    }
  }

  // --- Design Deliverables ---

  Future<DesignDeliverablesData?> loadDesignDeliverables(
      String projectId) async {
    try {
      final doc = await _sectionDoc(projectId, 'design_deliverables').get();
      if (doc.exists && doc.data() != null) {
        return DesignDeliverablesData.fromMap(doc.data()!);
      }
      return null; // Return null to signal "no data found", allowing fallback
    } catch (e) {
      debugPrint('Error loading design deliverables: $e');
      return null;
    }
  }

  Future<void> saveDesignDeliverables(
      String projectId, DesignDeliverablesData data) async {
    try {
      final map = data.toJson(); // DesignDeliverablesData uses toJson/fromJson
      map['updatedAt'] = FieldValue.serverTimestamp();
      await _sectionDoc(projectId, 'design_deliverables')
          .set(map, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving design deliverables: $e');
      rethrow;
    }
  }

  // --- Progress Calculation ---

  Future<DesignPhaseProgress> getDesignProgress(String projectId) async {
    try {
      final reqDoc =
          await _sectionDoc(projectId, 'requirements_implementation').get();
      final alignDoc =
          await _sectionDoc(projectId, 'technical_alignment').get();

      final double reqProgress = _calculateRequirementsProgress(reqDoc.data());
      final double alignProgress = _calculateAlignmentProgress(alignDoc.data());

      // Simple average for now, can be weighted later
      final double overall = (reqProgress + alignProgress) / 2.0;

      return DesignPhaseProgress(
        specificationsProgress: reqProgress,
        alignmentProgress: alignProgress,
        overallProgress: overall,
      );
    } catch (e) {
      debugPrint('Error calculating design progress: $e');
      return DesignPhaseProgress(
          specificationsProgress: 0, alignmentProgress: 0, overallProgress: 0);
    }
  }

  double _calculateRequirementsProgress(Map<String, dynamic>? data) {
    if (data == null) return 0.0;

    final checklist = (data['checklist'] as List?) ?? [];
    if (checklist.isEmpty) {
      return 0.0;
    }

    int completed = 0;
    for (var item in checklist) {
      final status = item['status']?.toString();
      if (status == 'ready' ||
          status == 'validated' ||
          status == 'ChecklistStatus.ready') {
        completed++;
      }
    }

    // Requirements definition count could also play a part
    // For now, base purely on checklist items if they exist
    return completed / checklist.length;
  }

  double _calculateAlignmentProgress(Map<String, dynamic>? data) {
    if (data == null) return 0.0;

    final constraints = (data['constraints'] as List?) ?? [];
    final mappings = (data['mappings'] as List?) ?? [];
    final dependencies = (data['dependencies'] as List?) ?? [];

    final totalItems =
        constraints.length + mappings.length + dependencies.length;
    if (totalItems == 0) return 0.0;

    int completed = 0;

    for (var item in constraints) {
      if (item['status'] == 'Aligned' || item['status'] == 'Validated') {
        completed++;
      }
    }
    for (var item in mappings) {
      if (item['status'] == 'Aligned') {
        completed++;
      }
    }
    for (var item in dependencies) {
      if (item['status'] == 'Resolved' || item['status'] == 'Aligned') {
        completed++;
      }
    }

    return completed / totalItems;
  }

  Stream<Map<String, dynamic>> calculateOverallProgress(String projectId) {
    // For now, returning a single-emit stream.
    // Ideally, this would combine streams from all sections for real-time updates.
    return Stream.fromFuture(_getOverallProgressMap(projectId));
  }

  Future<Map<String, dynamic>> _getOverallProgressMap(String projectId) async {
    final progress = await getDesignProgress(projectId);
    // Mocking 'approved sections' based on progress * total sections (14)
    // In a real scenario, this would count actual approved section documents.
    final totalSections = 14;
    final completedSections =
        (progress.overallProgress * totalSections).round();

    return {
      'progress': progress.overallProgress,
      'completed': completedSections,
      'total': totalSections,
    };
  }
}
