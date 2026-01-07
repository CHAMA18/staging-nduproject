import 'package:cloud_firestore/cloud_firestore.dart';

class ContractModel {
  final String id;
  final String projectId;
  final String name; // Contract Name
  final String description;
  final String contractType;
  final String paymentType;
  final String status;
  final double estimatedValue;
  final DateTime startDate;
  final DateTime endDate;
  final String scope;
  final String discipline;
  final String notes; // optional
  final String createdById;
  final String createdByEmail;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContractModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.contractType,
    required this.paymentType,
    required this.status,
    required this.estimatedValue,
    required this.startDate,
    required this.endDate,
    required this.scope,
    required this.discipline,
    required this.notes,
    required this.createdById,
    required this.createdByEmail,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'name': name,
        'description': description,
        'contractType': contractType,
        'paymentType': paymentType,
        'status': status,
        'estimatedValue': estimatedValue,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'scope': scope,
        'discipline': discipline,
        'notes': notes,
        'createdById': createdById,
        'createdByEmail': createdByEmail,
        'createdByName': createdByName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static ContractModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    return ContractModel(
      id: doc.id,
      projectId: (data['projectId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      contractType: (data['contractType'] ?? '').toString(),
      paymentType: (data['paymentType'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      estimatedValue: parseDouble(data['estimatedValue']),
      startDate: parseTs(data['startDate']),
      endDate: parseTs(data['endDate']),
      scope: (data['scope'] ?? '').toString(),
      discipline: (data['discipline'] ?? '').toString(),
      notes: (data['notes'] ?? '').toString(),
      createdById: (data['createdById'] ?? '').toString(),
      createdByEmail: (data['createdByEmail'] ?? '').toString(),
      createdByName: (data['createdByName'] ?? '').toString(),
      createdAt: parseTs(data['createdAt']),
      updatedAt: parseTs(data['updatedAt']),
    );
  }
}

class ContractService {
  static CollectionReference<Map<String, dynamic>> _contractsCol(String projectId) =>
      FirebaseFirestore.instance.collection('projects').doc(projectId).collection('contracts');

  static Future<String> createContract({
    required String projectId,
    required String name,
    required String description,
    required String contractType,
    required String paymentType,
    required String status,
    required double estimatedValue,
    required DateTime startDate,
    required DateTime endDate,
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

  static Stream<List<ContractModel>> streamContracts(String projectId, {int limit = 50}) {
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

    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (contractType != null) updateData['contractType'] = contractType;
    if (paymentType != null) updateData['paymentType'] = paymentType;
    if (status != null) updateData['status'] = status;
    if (estimatedValue != null) updateData['estimatedValue'] = estimatedValue;
    if (startDate != null) updateData['startDate'] = Timestamp.fromDate(startDate);
    if (endDate != null) updateData['endDate'] = Timestamp.fromDate(endDate);
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
