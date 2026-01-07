import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for salvage/disposal team members
class SalvageTeamMemberModel {
  final String id;
  final String projectId;
  final String name;
  final String role;
  final String email;
  final String status; // 'Active', 'On Leave', etc.
  final int itemsHandled;
  final String createdById;
  final String createdByEmail;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SalvageTeamMemberModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.role,
    required this.email,
    required this.status,
    required this.itemsHandled,
    required this.createdById,
    required this.createdByEmail,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'name': name,
        'role': role,
        'email': email,
        'status': status,
        'itemsHandled': itemsHandled,
        'createdById': createdById,
        'createdByEmail': createdByEmail,
        'createdByName': createdByName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static SalvageTeamMemberModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return SalvageTeamMemberModel(
      id: doc.id,
      projectId: (data['projectId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      role: (data['role'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      status: (data['status'] ?? 'Active').toString(),
      itemsHandled: (data['itemsHandled'] ?? 0) as int,
      createdById: (data['createdById'] ?? '').toString(),
      createdByEmail: (data['createdByEmail'] ?? '').toString(),
      createdByName: (data['createdByName'] ?? '').toString(),
      createdAt: parseTs(data['createdAt']),
      updatedAt: parseTs(data['updatedAt']),
    );
  }
}

/// Model for salvage inventory items
class SalvageInventoryItemModel {
  final String id;
  final String projectId;
  final String assetId;
  final String name;
  final String category;
  final String condition; // 'Excellent', 'Good', 'Fair', etc.
  final String location;
  final String status; // 'Ready', 'Pending', 'Review', 'Flagged'
  final String estimatedValue;
  final String createdById;
  final String createdByEmail;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SalvageInventoryItemModel({
    required this.id,
    required this.projectId,
    required this.assetId,
    required this.name,
    required this.category,
    required this.condition,
    required this.location,
    required this.status,
    required this.estimatedValue,
    required this.createdById,
    required this.createdByEmail,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'assetId': assetId,
        'name': name,
        'category': category,
        'condition': condition,
        'location': location,
        'status': status,
        'estimatedValue': estimatedValue,
        'createdById': createdById,
        'createdByEmail': createdByEmail,
        'createdByName': createdByName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static SalvageInventoryItemModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return SalvageInventoryItemModel(
      id: doc.id,
      projectId: (data['projectId'] ?? '').toString(),
      assetId: (data['assetId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      condition: (data['condition'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      estimatedValue: (data['estimatedValue'] ?? '').toString(),
      createdById: (data['createdById'] ?? '').toString(),
      createdByEmail: (data['createdByEmail'] ?? '').toString(),
      createdByName: (data['createdByName'] ?? '').toString(),
      createdAt: parseTs(data['createdAt']),
      updatedAt: parseTs(data['updatedAt']),
    );
  }
}

/// Model for disposal queue items
class SalvageDisposalItemModel {
  final String id;
  final String projectId;
  final String assetId;
  final String name;
  final String category;
  final String status; // 'Pending Review', 'Approved', 'In Progress', etc.
  final String estimatedValue;
  final String priority; // 'High', 'Medium', 'Low'
  final String createdById;
  final String createdByEmail;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SalvageDisposalItemModel({
    required this.id,
    required this.projectId,
    required this.assetId,
    required this.name,
    required this.category,
    required this.status,
    required this.estimatedValue,
    required this.priority,
    required this.createdById,
    required this.createdByEmail,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'assetId': assetId,
        'name': name,
        'category': category,
        'status': status,
        'estimatedValue': estimatedValue,
        'priority': priority,
        'createdById': createdById,
        'createdByEmail': createdByEmail,
        'createdByName': createdByName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static SalvageDisposalItemModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return SalvageDisposalItemModel(
      id: doc.id,
      projectId: (data['projectId'] ?? '').toString(),
      assetId: (data['assetId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      estimatedValue: (data['estimatedValue'] ?? '').toString(),
      priority: (data['priority'] ?? 'Medium').toString(),
      createdById: (data['createdById'] ?? '').toString(),
      createdByEmail: (data['createdByEmail'] ?? '').toString(),
      createdByName: (data['createdByName'] ?? '').toString(),
      createdAt: parseTs(data['createdAt']),
      updatedAt: parseTs(data['updatedAt']),
    );
  }
}

class SalvageService {
  // Team Members CRUD
  static CollectionReference<Map<String, dynamic>> _teamMembersCol(String projectId) =>
      FirebaseFirestore.instance.collection('projects').doc(projectId).collection('salvage_team_members');

  static Future<String> createTeamMember({
    required String projectId,
    required String name,
    required String role,
    required String email,
    required String status,
    int itemsHandled = 0,
    String? createdById,
    String? createdByEmail,
    String? createdByName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = createdById ?? user?.uid ?? '';
    final userEmail = createdByEmail ?? user?.email ?? '';
    final userName = createdByName ?? user?.displayName ?? userEmail.split('@').first;

    final payload = SalvageTeamMemberModel(
      id: '',
      projectId: projectId,
      name: name,
      role: role,
      email: email,
      status: status,
      itemsHandled: itemsHandled,
      createdById: userId,
      createdByEmail: userEmail,
      createdByName: userName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).toMap();

    final ref = await _teamMembersCol(projectId).add(payload);
    return ref.id;
  }

  static Future<void> updateTeamMember({
    required String projectId,
    required String memberId,
    String? name,
    String? role,
    String? email,
    String? status,
    int? itemsHandled,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updateData['name'] = name;
    if (role != null) updateData['role'] = role;
    if (email != null) updateData['email'] = email;
    if (status != null) updateData['status'] = status;
    if (itemsHandled != null) updateData['itemsHandled'] = itemsHandled;

    await _teamMembersCol(projectId).doc(memberId).update(updateData);
  }

  static Future<void> deleteTeamMember({
    required String projectId,
    required String memberId,
  }) async {
    await _teamMembersCol(projectId).doc(memberId).delete();
  }

  static Stream<List<SalvageTeamMemberModel>> streamTeamMembers(String projectId, {int limit = 50}) {
    return _teamMembersCol(projectId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(SalvageTeamMemberModel.fromDoc).toList());
  }

  // Inventory Items CRUD
  static CollectionReference<Map<String, dynamic>> _inventoryCol(String projectId) =>
      FirebaseFirestore.instance.collection('projects').doc(projectId).collection('salvage_inventory');

  static Future<String> createInventoryItem({
    required String projectId,
    required String assetId,
    required String name,
    required String category,
    required String condition,
    required String location,
    required String status,
    required String estimatedValue,
    String? createdById,
    String? createdByEmail,
    String? createdByName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = createdById ?? user?.uid ?? '';
    final userEmail = createdByEmail ?? user?.email ?? '';
    final userName = createdByName ?? user?.displayName ?? userEmail.split('@').first;

    final payload = SalvageInventoryItemModel(
      id: '',
      projectId: projectId,
      assetId: assetId,
      name: name,
      category: category,
      condition: condition,
      location: location,
      status: status,
      estimatedValue: estimatedValue,
      createdById: userId,
      createdByEmail: userEmail,
      createdByName: userName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).toMap();

    final ref = await _inventoryCol(projectId).add(payload);
    return ref.id;
  }

  static Future<void> updateInventoryItem({
    required String projectId,
    required String itemId,
    String? assetId,
    String? name,
    String? category,
    String? condition,
    String? location,
    String? status,
    String? estimatedValue,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (assetId != null) updateData['assetId'] = assetId;
    if (name != null) updateData['name'] = name;
    if (category != null) updateData['category'] = category;
    if (condition != null) updateData['condition'] = condition;
    if (location != null) updateData['location'] = location;
    if (status != null) updateData['status'] = status;
    if (estimatedValue != null) updateData['estimatedValue'] = estimatedValue;

    await _inventoryCol(projectId).doc(itemId).update(updateData);
  }

  static Future<void> deleteInventoryItem({
    required String projectId,
    required String itemId,
  }) async {
    await _inventoryCol(projectId).doc(itemId).delete();
  }

  static Stream<List<SalvageInventoryItemModel>> streamInventoryItems(String projectId, {int limit = 50}) {
    return _inventoryCol(projectId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(SalvageInventoryItemModel.fromDoc).toList());
  }

  // Disposal Items CRUD
  static CollectionReference<Map<String, dynamic>> _disposalCol(String projectId) =>
      FirebaseFirestore.instance.collection('projects').doc(projectId).collection('salvage_disposal');

  static Future<String> createDisposalItem({
    required String projectId,
    required String assetId,
    required String name,
    required String category,
    required String status,
    required String estimatedValue,
    required String priority,
    String? createdById,
    String? createdByEmail,
    String? createdByName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = createdById ?? user?.uid ?? '';
    final userEmail = createdByEmail ?? user?.email ?? '';
    final userName = createdByName ?? user?.displayName ?? userEmail.split('@').first;

    final payload = SalvageDisposalItemModel(
      id: '',
      projectId: projectId,
      assetId: assetId,
      name: name,
      category: category,
      status: status,
      estimatedValue: estimatedValue,
      priority: priority,
      createdById: userId,
      createdByEmail: userEmail,
      createdByName: userName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).toMap();

    final ref = await _disposalCol(projectId).add(payload);
    return ref.id;
  }

  static Future<void> updateDisposalItem({
    required String projectId,
    required String itemId,
    String? assetId,
    String? name,
    String? category,
    String? status,
    String? estimatedValue,
    String? priority,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (assetId != null) updateData['assetId'] = assetId;
    if (name != null) updateData['name'] = name;
    if (category != null) updateData['category'] = category;
    if (status != null) updateData['status'] = status;
    if (estimatedValue != null) updateData['estimatedValue'] = estimatedValue;
    if (priority != null) updateData['priority'] = priority;

    await _disposalCol(projectId).doc(itemId).update(updateData);
  }

  static Future<void> deleteDisposalItem({
    required String projectId,
    required String itemId,
  }) async {
    await _disposalCol(projectId).doc(itemId).delete();
  }

  static Stream<List<SalvageDisposalItemModel>> streamDisposalItems(String projectId, {String? status, int limit = 50}) {
    Query<Map<String, dynamic>> query = _disposalCol(projectId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.snapshots().map((snap) => snap.docs.map(SalvageDisposalItemModel.fromDoc).toList());
  }
}
