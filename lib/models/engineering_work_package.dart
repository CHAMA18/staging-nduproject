/// Typed Engineering Work Package (EWP).
/// Complements the generic [WorkPackage] with EWP-specific fields.
///
/// P3.2: Added WBS/OBS/CBS cross-references and [copyWith] for
/// immutable updates and full project controls traceability.
class EngineeringWorkPackage {
  final String id;
  final String workPackageId; // FK to WorkPackage.id
  String drawingPackageRef;
  String designSpecificationId;
  String designDiscipline;
  String reviewStatus; // 'draft' | 'in_review' | 'approved' | 'issued_for_construction'
  DateTime? designCompletedDate;
  DateTime? issuedForConstructionDate;
  List<String> linkedProcurementPackageIds;
  List<String> linkedConstructionPackageIds;
  String notes;

  // ── P3.2: Cross-references for project controls traceability ──
  /// WBS element ID this EWP belongs to.
  String wbsId;
  /// OBS element ID (responsible organization).
  String obsId;
  /// CBS element ID (cost account).
  String cbsId;
  /// Control Account ID (WBS+OBS intersection).
  String controlAccountId;

  EngineeringWorkPackage({
    String? id,
    required this.workPackageId,
    this.drawingPackageRef = '',
    this.designSpecificationId = '',
    this.designDiscipline = '',
    this.reviewStatus = 'draft',
    this.designCompletedDate,
    this.issuedForConstructionDate,
    List<String>? linkedProcurementPackageIds,
    List<String>? linkedConstructionPackageIds,
    this.notes = '',
    this.wbsId = '',
    this.obsId = '',
    this.cbsId = '',
    this.controlAccountId = '',
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        linkedProcurementPackageIds = linkedProcurementPackageIds ?? [],
        linkedConstructionPackageIds = linkedConstructionPackageIds ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'workPackageId': workPackageId,
        'drawingPackageRef': drawingPackageRef,
        'designSpecificationId': designSpecificationId,
        'designDiscipline': designDiscipline,
        'reviewStatus': reviewStatus,
        'designCompletedDate': designCompletedDate?.toIso8601String(),
        'issuedForConstructionDate':
            issuedForConstructionDate?.toIso8601String(),
        'linkedProcurementPackageIds': linkedProcurementPackageIds,
        'linkedConstructionPackageIds': linkedConstructionPackageIds,
        'notes': notes,
        'wbsId': wbsId,
        'obsId': obsId,
        'cbsId': cbsId,
        'controlAccountId': controlAccountId,
      };

  factory EngineeringWorkPackage.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      if (v is DateTime) return v;
      return null;
    }

    return EngineeringWorkPackage(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      workPackageId: json['workPackageId']?.toString() ?? '',
      drawingPackageRef: json['drawingPackageRef']?.toString() ?? '',
      designSpecificationId:
          json['designSpecificationId']?.toString() ?? '',
      designDiscipline: json['designDiscipline']?.toString() ?? '',
      reviewStatus: json['reviewStatus']?.toString() ?? 'draft',
      designCompletedDate: parseDate(json['designCompletedDate']),
      issuedForConstructionDate:
          parseDate(json['issuedForConstructionDate']),
      linkedProcurementPackageIds:
          (json['linkedProcurementPackageIds'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      linkedConstructionPackageIds:
          (json['linkedConstructionPackageIds'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      notes: json['notes']?.toString() ?? '',
      wbsId: json['wbsId']?.toString() ?? '',
      obsId: json['obsId']?.toString() ?? '',
      cbsId: json['cbsId']?.toString() ?? '',
      controlAccountId: json['controlAccountId']?.toString() ?? '',
    );
  }

  /// ── P3.2: copyWith for immutable updates ──
  EngineeringWorkPackage copyWith({
    String? drawingPackageRef,
    String? designSpecificationId,
    String? designDiscipline,
    String? reviewStatus,
    DateTime? designCompletedDate,
    DateTime? issuedForConstructionDate,
    List<String>? linkedProcurementPackageIds,
    List<String>? linkedConstructionPackageIds,
    String? notes,
    String? wbsId,
    String? obsId,
    String? cbsId,
    String? controlAccountId,
  }) {
    return EngineeringWorkPackage(
      id: id,
      workPackageId: workPackageId,
      drawingPackageRef: drawingPackageRef ?? this.drawingPackageRef,
      designSpecificationId:
          designSpecificationId ?? this.designSpecificationId,
      designDiscipline: designDiscipline ?? this.designDiscipline,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      designCompletedDate: designCompletedDate ?? this.designCompletedDate,
      issuedForConstructionDate:
          issuedForConstructionDate ?? this.issuedForConstructionDate,
      linkedProcurementPackageIds:
          linkedProcurementPackageIds ?? List.from(this.linkedProcurementPackageIds),
      linkedConstructionPackageIds:
          linkedConstructionPackageIds ?? List.from(this.linkedConstructionPackageIds),
      notes: notes ?? this.notes,
      wbsId: wbsId ?? this.wbsId,
      obsId: obsId ?? this.obsId,
      cbsId: cbsId ?? this.cbsId,
      controlAccountId: controlAccountId ?? this.controlAccountId,
    );
  }
}
