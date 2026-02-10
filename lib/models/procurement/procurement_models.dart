import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a procurement item
enum ProcurementItemStatus {
  planning,
  rfqReview,
  vendorSelection,
  ordered,
  delivered,
  cancelled
}

/// Priority of a procurement item
enum ProcurementPriority { low, medium, high, critical }

/// Status of a strategy
enum StrategyStatus { draft, active, archived }

/// Status of an RFQ
enum RfqStatus {
  draft,
  review, // Internal review
  inMarket, // Sent to vendors
  evaluation, // Evaluating responses
  awarded,
  closed
}

/// Status of a Purchase Order
enum PurchaseOrderStatus {
  draft,
  awaitingApproval,
  issued,
  inTransit,
  received,
  cancelled
}

/// Represents a timeline event for an item
class ProcurementEvent {
  final String title;
  final String description;
  final String subtext;
  final DateTime date;
  final String status; // 'completed', 'pending', 'issue'

  const ProcurementEvent({
    required this.title,
    required this.description,
    required this.subtext,
    required this.date,
    this.status = 'completed',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'subtext': subtext,
        'date': Timestamp.fromDate(date),
        'status': status,
      };

  factory ProcurementEvent.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return ProcurementEvent(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subtext: json['subtext'] ?? '',
      date: parseDate(json['date']),
      status: json['status'] ?? 'completed',
    );
  }
}

/// Main Procurement Item Model
class ProcurementItemModel {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final String category; // e.g., 'IT Equipment', 'Construction'
  final ProcurementItemStatus status;
  final ProcurementPriority priority;
  final double budget;
  final double spent; // Actual spend
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final double progress; // 0.0 to 1.0
  final String? vendorId; // Link to VendorCollection
  final String? contractId; // Link to ContractCollection
  final List<ProcurementEvent> events; // Tracking history
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String projectPhase; // e.g. "Planning", "Execution"
  final String responsibleMember;
  final String comments;

  const ProcurementItemModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.category,
    this.status = ProcurementItemStatus.planning,
    this.priority = ProcurementPriority.medium,
    this.budget = 0.0,
    this.spent = 0.0,
    this.estimatedDelivery,
    this.actualDelivery,
    this.progress = 0.0,
    this.vendorId,
    this.contractId,
    this.events = const [],
    this.notes = '',
    this.projectPhase = 'Planning',
    this.responsibleMember = '',
    this.comments = '',
    required this.createdAt,
    required this.updatedAt,
  });

  ProcurementItemModel copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    String? category,
    ProcurementItemStatus? status,
    ProcurementPriority? priority,
    double? budget,
    double? spent,
    DateTime? estimatedDelivery,
    DateTime? actualDelivery,
    double? progress,
    String? vendorId,
    String? contractId,
    List<ProcurementEvent>? events,
    String? notes,
    String? projectPhase,
    String? responsibleMember,
    String? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProcurementItemModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      actualDelivery: actualDelivery ?? this.actualDelivery,
      progress: progress ?? this.progress,
      vendorId: vendorId ?? this.vendorId,
      contractId: contractId ?? this.contractId,
      events: events ?? this.events,
      notes: notes ?? this.notes,
      projectPhase: projectPhase ?? this.projectPhase,
      responsibleMember: responsibleMember ?? this.responsibleMember,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'name': name,
        'description': description,
        'category': category,
        'status': status.name,
        'priority': priority.name,
        'budget': budget,
        'spent': spent,
        'estimatedDelivery': estimatedDelivery != null
            ? Timestamp.fromDate(estimatedDelivery!)
            : null,
        'actualDelivery':
            actualDelivery != null ? Timestamp.fromDate(actualDelivery!) : null,
        'progress': progress,
        'vendorId': vendorId,
        'contractId': contractId,
        'events': events.map((e) => e.toJson()).toList(),
        'notes': notes,
        'projectPhase': projectPhase,
        'responsibleMember': responsibleMember,
        'comments': comments,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static ProcurementItemModel fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    DateTime guaranteedDate(dynamic v) {
      return parseDate(v) ?? DateTime.now();
    }

    return ProcurementItemModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      status: ProcurementItemStatus.values.firstWhere(
          (e) => e.name == (data['status'] ?? 'planning'),
          orElse: () => ProcurementItemStatus.planning),
      priority: ProcurementPriority.values.firstWhere(
          (e) => e.name == (data['priority'] ?? 'medium'),
          orElse: () => ProcurementPriority.medium),
      budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
      spent: (data['spent'] as num?)?.toDouble() ?? 0.0,
      estimatedDelivery: parseDate(data['estimatedDelivery']),
      actualDelivery: parseDate(data['actualDelivery']),
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      vendorId: data['vendorId'],
      contractId: data['contractId'],
      events: (data['events'] as List?)
              ?.map((e) => ProcurementEvent.fromJson(e))
              .toList() ??
          [],
      notes: data['notes'] ?? '',
      projectPhase: data['projectPhase'] ?? 'Planning',
      responsibleMember: data['responsibleMember'] ?? '',
      comments: data['comments'] ?? '',
      createdAt: guaranteedDate(data['createdAt']),
      updatedAt: guaranteedDate(data['updatedAt']),
    );
  }
}

/// Status of a contract
enum ContractStatus {
  draft,
  // ignore: constant_identifier_names
  under_review,
  approved,
  executed,
  expired,
  terminated
}

/// Contract Model for specific contracted work
class ContractModel {
  final String id;
  final String projectId;
  final String title; // "Item" in the table
  final String description;
  final String contractorName;
  final double estimatedCost;
  final String duration;
  final ContractStatus status; // Upgraded from String
  final DateTime? startDate; // Added
  final DateTime? endDate; // Added
  final String owner; // Added owner field
  final DateTime createdAt;

  const ContractModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.contractorName,
    this.estimatedCost = 0.0,
    this.duration = '',
    this.status = ContractStatus.draft,
    this.startDate,
    this.endDate,
    required this.owner,
    required this.createdAt,
  });

  ContractModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? contractorName,
    double? estimatedCost,
    String? duration,
    ContractStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? owner,
    DateTime? createdAt,
  }) {
    return ContractModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      contractorName: contractorName ?? this.contractorName,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      owner: owner ?? this.owner,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'title': title,
        'description': description,
        'contractorName': contractorName,
        'estimatedCost': estimatedCost,
        'duration': duration,
        'status': status.name,
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'owner': owner,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static ContractModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ContractModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      contractorName: data['contractorName'] ?? '',
      estimatedCost: (data['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      duration: data['duration'] ?? '',
      status: ContractStatus.values.firstWhere(
          (e) => e.name == (data['status'] ?? 'draft'),
          orElse: () => ContractStatus.draft),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      owner: data['owner'] ?? 'Unassigned',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Procurement Strategy Model
class ProcurementStrategyModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final StrategyStatus status;
  final int itemCount; // Cached count or manual entry
  final DateTime createdAt;

  const ProcurementStrategyModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    this.status = StrategyStatus.draft,
    this.itemCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'title': title,
        'description': description,
        'status': status.name,
        'itemCount': itemCount,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static ProcurementStrategyModel fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProcurementStrategyModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: StrategyStatus.values.firstWhere(
          (e) => e.name == (data['status'] ?? 'draft'),
          orElse: () => StrategyStatus.draft),
      itemCount: (data['itemCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Request for Quote (RFQ) Model
class RfqModel {
  final String id;
  final String projectId;
  final String title;
  final String category;
  final String owner;
  final DateTime dueDate;
  final int invitedCount;
  final int responseCount;
  final double budget;
  final RfqStatus status;
  final ProcurementPriority priority;
  final DateTime createdAt;

  const RfqModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.category,
    this.owner = '',
    required this.dueDate,
    this.invitedCount = 0,
    this.responseCount = 0,
    this.budget = 0.0,
    this.status = RfqStatus.draft,
    this.priority = ProcurementPriority.medium,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'title': title,
        'category': category,
        'owner': owner,
        'dueDate': Timestamp.fromDate(dueDate),
        'invitedCount': invitedCount,
        'responseCount': responseCount,
        'budget': budget,
        'status': status.name,
        'priority': priority.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static RfqModel fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RfqModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      owner: data['owner'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invitedCount: (data['invitedCount'] as num?)?.toInt() ?? 0,
      responseCount: (data['responseCount'] as num?)?.toInt() ?? 0,
      budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
      status: RfqStatus.values.firstWhere(
          (e) => e.name == (data['status'] ?? 'draft'),
          orElse: () => RfqStatus.draft),
      priority: ProcurementPriority.values.firstWhere(
          (e) => e.name == (data['priority'] ?? 'medium'),
          orElse: () => ProcurementPriority.medium),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Purchase Order (PO) Model
class PurchaseOrderModel {
  final String id;
  final String poNumber; // Separate generic ID from user-facing PO#
  final String projectId;
  final String vendorName; // Cached name for display
  final String? vendorId; // Link
  final String category;
  final String owner;
  final DateTime orderedDate;
  final DateTime expectedDate;
  final double amount;
  final double progress;
  final PurchaseOrderStatus status;
  final DateTime createdAt;

  const PurchaseOrderModel({
    required this.id,
    required this.poNumber,
    required this.projectId,
    required this.vendorName,
    this.vendorId,
    required this.category,
    this.owner = '',
    required this.orderedDate,
    required this.expectedDate,
    this.amount = 0.0,
    this.progress = 0.0,
    this.status = PurchaseOrderStatus.draft,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'poNumber': poNumber,
        'projectId': projectId,
        'vendorName': vendorName,
        'vendorId': vendorId,
        'category': category,
        'owner': owner,
        'orderedDate': Timestamp.fromDate(orderedDate),
        'expectedDate': Timestamp.fromDate(expectedDate),
        'amount': amount,
        'progress': progress,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static PurchaseOrderModel fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PurchaseOrderModel(
      id: doc.id,
      poNumber: data['poNumber'] ??
          (doc.id.length > 6 ? doc.id.substring(0, 6).toUpperCase() : doc.id),
      projectId: data['projectId'] ?? '',
      vendorName: data['vendorName'] ?? '',
      vendorId: data['vendorId'],
      category: data['category'] ?? '',
      owner: data['owner'] ?? '',
      orderedDate:
          (data['orderedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedDate:
          (data['expectedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      status: PurchaseOrderStatus.values.firstWhere(
          (e) => e.name == (data['status'] ?? 'draft'),
          orElse: () => PurchaseOrderStatus.draft),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
