import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndu_project/models/planning_contracting_models.dart';

String _normalizeStatusForStorage(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) return 'draft';
  switch (normalized) {
    case 'draft':
    case 'under_review':
    case 'approved':
    case 'executed':
    case 'expired':
    case 'terminated':
      return normalized;
  }
  if (normalized.contains('not started')) return 'draft';
  if (normalized.contains('pending')) return 'under_review';
  if (normalized.contains('review')) return 'under_review';
  if (normalized.contains('in progress')) return 'approved';
  if (normalized.contains('progress')) return 'approved';
  if (normalized.contains('complete')) return 'executed';
  if (normalized.contains('completed')) return 'executed';
  return 'draft';
}

String _normalizeStatusForDisplay(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) return 'Not Started';
  switch (normalized) {
    case 'draft':
      return 'Not Started';
    case 'under_review':
      return 'Pending Review';
    case 'approved':
      return 'In Progress';
    case 'executed':
      return 'Completed';
    case 'expired':
    case 'terminated':
      return 'Completed';
  }
  if (normalized.contains('not started')) return 'Not Started';
  if (normalized.contains('pending')) return 'Pending Review';
  if (normalized.contains('review')) return 'Pending Review';
  if (normalized.contains('in progress')) return 'In Progress';
  if (normalized.contains('progress')) return 'In Progress';
  if (normalized.contains('complete')) return 'Completed';
  if (normalized.contains('completed')) return 'Completed';
  return status.trim();
}

class ContractModel {
  final String id;
  final String projectId;
  final String name; // Contract Name
  final String description;
  final String contractType;
  final String paymentType;
  final String status;
  final double estimatedValue;
  final DateTime? startDate;
  final DateTime? endDate;
  final String scope;
  final String discipline;
  final String contractorName;
  final String owner;
  final String notes; // optional
  final String createdById;
  final String createdByEmail;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PaymentMilestone>? paymentMilestones;
  final String? changeOrderProcedure;
  final String? disputeResolution;
  final String? contractManagerId;
  final String? contractManagerName;
  final String? reportingFrequency;
  final double? contingencyAmount;
  final double? contingencyPercent;
  final String? negotiationStatus;
  final String? negotiationObjectives;
  final String? negotiationAuthority;
  final List<NegotiationItem>? negotiationItems;
  final String? linkedRfqId;
  final List<EvaluationScore>? evaluationScores;
  final ContractBudgetBreakdown? budgetBreakdown;
  final String? performanceKpis;
  final String? awardStrategy;

  const ContractModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.contractType,
    required this.paymentType,
    required this.status,
    required this.estimatedValue,
    this.startDate,
    this.endDate,
    required this.scope,
    required this.discipline,
    this.contractorName = '',
    this.owner = '',
    required this.notes,
    required this.createdById,
    required this.createdByEmail,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.paymentMilestones,
    this.changeOrderProcedure,
    this.disputeResolution,
    this.contractManagerId,
    this.contractManagerName,
    this.reportingFrequency,
    this.contingencyAmount,
    this.contingencyPercent,
    this.negotiationStatus,
    this.negotiationObjectives,
    this.negotiationAuthority,
    this.negotiationItems,
    this.linkedRfqId,
    this.evaluationScores,
    this.budgetBreakdown,
    this.performanceKpis,
    this.awardStrategy,
  });

  Map<String, dynamic> toMap() {
    final normalizedStatus = _normalizeStatusForStorage(status);
    final statusLabel = _normalizeStatusForDisplay(status);
    return {
      'projectId': projectId,
      'name': name,
      'title': name,
      'description': description,
      'contractType': contractType,
      'paymentType': paymentType,
      'status': normalizedStatus,
      'statusLabel': statusLabel,
      'estimatedValue': estimatedValue,
      'estimatedCost': estimatedValue,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'scope': scope,
      'discipline': discipline,
      'contractorName': contractorName,
      'owner': owner,
      'notes': notes,
      'createdById': createdById,
      'createdByEmail': createdByEmail,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (paymentMilestones != null)
        'paymentMilestones': paymentMilestones!.map((m) => m.toMap()).toList(),
      if (changeOrderProcedure != null)
        'changeOrderProcedure': changeOrderProcedure,
      if (disputeResolution != null) 'disputeResolution': disputeResolution,
      if (contractManagerId != null) 'contractManagerId': contractManagerId,
      if (contractManagerName != null)
        'contractManagerName': contractManagerName,
      if (reportingFrequency != null) 'reportingFrequency': reportingFrequency,
      if (contingencyAmount != null) 'contingencyAmount': contingencyAmount,
      if (contingencyPercent != null) 'contingencyPercent': contingencyPercent,
      if (negotiationStatus != null) 'negotiationStatus': negotiationStatus,
      if (negotiationObjectives != null)
        'negotiationObjectives': negotiationObjectives,
      if (negotiationAuthority != null)
        'negotiationAuthority': negotiationAuthority,
      if (negotiationItems != null)
        'negotiationItems': negotiationItems!.map((n) => n.toMap()).toList(),
      if (linkedRfqId != null) 'linkedRfqId': linkedRfqId,
      if (evaluationScores != null)
        'evaluationScores': evaluationScores!.map((s) => s.toMap()).toList(),
      if (budgetBreakdown != null) 'budgetBreakdown': budgetBreakdown!.toMap(),
      if (performanceKpis != null) 'performanceKpis': performanceKpis,
      if (awardStrategy != null) 'awardStrategy': awardStrategy,
    };
  }

  static ContractModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? parseTs(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    String? _ns(dynamic v) {
      final s = (v ?? '').toString().trim();
      return s.isEmpty ? null : s;
    }

    double? _nd(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final d = double.tryParse(v.toString());
      return d;
    }

    List<PaymentMilestone>? _pm(dynamic v) {
      if (v is! List) return null;
      final items = v
          .whereType<Map>()
          .map((e) => PaymentMilestone.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      return items.isEmpty ? null : items;
    }

    List<NegotiationItem>? _ni(dynamic v) {
      if (v is! List) return null;
      final items = v
          .whereType<Map>()
          .map((e) => NegotiationItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      return items.isEmpty ? null : items;
    }

    List<EvaluationScore>? _es(dynamic v) {
      if (v is! List) return null;
      final items = v
          .whereType<Map>()
          .map((e) => EvaluationScore.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      return items.isEmpty ? null : items;
    }

    final rawStatus = (data['statusLabel'] ?? data['status'] ?? '').toString();
    final displayStatus = _normalizeStatusForDisplay(rawStatus);

    return ContractModel(
      id: doc.id,
      projectId: (data['projectId'] ?? '').toString(),
      name: (data['name'] ?? data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      contractType: (data['contractType'] ?? '').toString(),
      paymentType: (data['paymentType'] ?? '').toString(),
      status: displayStatus,
      estimatedValue:
          parseDouble(data['estimatedValue'] ?? data['estimatedCost']),
      startDate: parseTs(data['startDate']),
      endDate: parseTs(data['endDate']),
      scope: (data['scope'] ?? '').toString(),
      discipline: (data['discipline'] ?? '').toString(),
      contractorName: (data['contractorName'] ?? '').toString(),
      owner: (data['owner'] ?? '').toString(),
      notes: (data['notes'] ?? '').toString(),
      createdById: (data['createdById'] ?? '').toString(),
      createdByEmail: (data['createdByEmail'] ?? '').toString(),
      createdByName: (data['createdByName'] ?? '').toString(),
      createdAt:
          parseTs(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          parseTs(data['updatedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      paymentMilestones: _pm(data['paymentMilestones']),
      changeOrderProcedure: _ns(data['changeOrderProcedure']),
      disputeResolution: _ns(data['disputeResolution']),
      contractManagerId: _ns(data['contractManagerId']),
      contractManagerName: _ns(data['contractManagerName']),
      reportingFrequency: _ns(data['reportingFrequency']),
      contingencyAmount: _nd(data['contingencyAmount']),
      contingencyPercent: _nd(data['contingencyPercent']),
      negotiationStatus: _ns(data['negotiationStatus']),
      negotiationObjectives: _ns(data['negotiationObjectives']),
      negotiationAuthority: _ns(data['negotiationAuthority']),
      negotiationItems: _ni(data['negotiationItems']),
      linkedRfqId: _ns(data['linkedRfqId']),
      evaluationScores: _es(data['evaluationScores']),
      budgetBreakdown: data['budgetBreakdown'] != null
          ? ContractBudgetBreakdown.fromMap(
              Map<String, dynamic>.from(data['budgetBreakdown'] as Map))
          : null,
      performanceKpis: _ns(data['performanceKpis']),
      awardStrategy: _ns(data['awardStrategy']),
    );
  }
}

class ContractService {
  static CollectionReference<Map<String, dynamic>> _contractsCol(
          String projectId) =>
      FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('contracts');

  static Future<String> createContract({
    required String projectId,
    required String name,
    required String description,
    required String contractType,
    required String paymentType,
    required String status,
    required double estimatedValue,
    DateTime? startDate,
    DateTime? endDate,
    required String scope,
    required String discipline,
    String notes = '',
    required String createdById,
    required String createdByEmail,
    required String createdByName,
  }) async {
    final payload = ContractModel(
      id: '',
      projectId: projectId,
      name: name,
      description: description,
      contractType: contractType,
      paymentType: paymentType,
      status: status,
      estimatedValue: estimatedValue,
      startDate: startDate,
      endDate: endDate,
      scope: scope,
      discipline: discipline,
      contractorName: '',
      owner: '',
      notes: notes,
      createdById: createdById,
      createdByEmail: createdByEmail,
      createdByName: createdByName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).toMap();

    final ref = await _contractsCol(projectId).add(payload);
    return ref.id;
  }

  static Stream<List<ContractModel>> streamContracts(String projectId,
      {int limit = 50}) {
    return _contractsCol(projectId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ContractModel.fromDoc).toList());
  }

  /// Update an existing contract
  static Future<void> updateContract({
    required String projectId,
    required String contractId,
    String? name,
    String? description,
    String? contractType,
    String? paymentType,
    String? status,
    double? estimatedValue,
    DateTime? startDate,
    DateTime? endDate,
    String? scope,
    String? discipline,
    String? notes,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      updateData['name'] = name;
      updateData['title'] = name;
    }
    if (description != null) updateData['description'] = description;
    if (contractType != null) updateData['contractType'] = contractType;
    if (paymentType != null) updateData['paymentType'] = paymentType;
    if (status != null) {
      updateData['status'] = _normalizeStatusForStorage(status);
      updateData['statusLabel'] = _normalizeStatusForDisplay(status);
    }
    if (estimatedValue != null) {
      updateData['estimatedValue'] = estimatedValue;
      updateData['estimatedCost'] = estimatedValue;
    }
    if (startDate != null) {
      updateData['startDate'] = Timestamp.fromDate(startDate);
    }
    if (endDate != null) {
      updateData['endDate'] = Timestamp.fromDate(endDate);
    }
    if (scope != null) updateData['scope'] = scope;
    if (discipline != null) updateData['discipline'] = discipline;
    if (notes != null) updateData['notes'] = notes;

    await _contractsCol(projectId).doc(contractId).update(updateData);
  }

  /// Delete a contract
  static Future<void> deleteContract({
    required String projectId,
    required String contractId,
  }) async {
    await _contractsCol(projectId).doc(contractId).delete();
  }

  static Future<void> updatePlanningFields({
    required String projectId,
    required String contractId,
    List<PaymentMilestone>? paymentMilestones,
    String? changeOrderProcedure,
    String? disputeResolution,
    String? contractManagerId,
    String? contractManagerName,
    String? reportingFrequency,
    double? contingencyAmount,
    double? contingencyPercent,
    String? negotiationStatus,
    String? negotiationObjectives,
    String? negotiationAuthority,
    List<NegotiationItem>? negotiationItems,
    String? linkedRfqId,
    List<EvaluationScore>? evaluationScores,
    ContractBudgetBreakdown? budgetBreakdown,
    String? performanceKpis,
    String? awardStrategy,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (paymentMilestones != null) {
      updateData['paymentMilestones'] =
          paymentMilestones.map((m) => m.toMap()).toList();
    }
    if (changeOrderProcedure != null) {
      updateData['changeOrderProcedure'] = changeOrderProcedure;
    }
    if (disputeResolution != null) {
      updateData['disputeResolution'] = disputeResolution;
    }
    if (contractManagerId != null) {
      updateData['contractManagerId'] = contractManagerId;
    }
    if (contractManagerName != null) {
      updateData['contractManagerName'] = contractManagerName;
    }
    if (reportingFrequency != null) {
      updateData['reportingFrequency'] = reportingFrequency;
    }
    if (contingencyAmount != null) {
      updateData['contingencyAmount'] = contingencyAmount;
    }
    if (contingencyPercent != null) {
      updateData['contingencyPercent'] = contingencyPercent;
    }
    if (negotiationStatus != null) {
      updateData['negotiationStatus'] = negotiationStatus;
    }
    if (negotiationObjectives != null) {
      updateData['negotiationObjectives'] = negotiationObjectives;
    }
    if (negotiationAuthority != null) {
      updateData['negotiationAuthority'] = negotiationAuthority;
    }
    if (negotiationItems != null) {
      updateData['negotiationItems'] =
          negotiationItems.map((n) => n.toMap()).toList();
    }
    if (linkedRfqId != null) {
      updateData['linkedRfqId'] = linkedRfqId;
    }
    if (evaluationScores != null) {
      updateData['evaluationScores'] =
          evaluationScores.map((s) => s.toMap()).toList();
    }
    if (budgetBreakdown != null) {
      updateData['budgetBreakdown'] = budgetBreakdown.toMap();
    }
    if (performanceKpis != null) {
      updateData['performanceKpis'] = performanceKpis;
    }
    if (awardStrategy != null) {
      updateData['awardStrategy'] = awardStrategy;
    }
    await _contractsCol(projectId).doc(contractId).update(updateData);
  }

  /// Get a single contract
  static Future<ContractModel?> getContract({
    required String projectId,
    required String contractId,
  }) async {
    final doc = await _contractsCol(projectId).doc(contractId).get();
    if (!doc.exists) return null;
    return ContractModel.fromDoc(doc);
  }
}
