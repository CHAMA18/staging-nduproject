/// Model for a design component in Detailed Design page
class DesignComponent {
  final String id;
  String componentName;
  String
      category; // UI/UX, Backend, Security, Networking, Physical Infrastructure
  String specificationDetails; // "." bullet format
  String integrationPoint;
  String status; // Draft, Reviewed, Approved
  String designNotes; // Prose, no bullets

  DesignComponent({
    String? id,
    this.componentName = '',
    this.category = 'Backend',
    this.specificationDetails = '',
    this.integrationPoint = '',
    this.status = 'Draft',
    this.designNotes = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  DesignComponent copyWith({
    String? componentName,
    String? category,
    String? specificationDetails,
    String? integrationPoint,
    String? status,
    String? designNotes,
  }) {
    return DesignComponent(
      id: id,
      componentName: componentName ?? this.componentName,
      category: category ?? this.category,
      specificationDetails: specificationDetails ?? this.specificationDetails,
      integrationPoint: integrationPoint ?? this.integrationPoint,
      status: status ?? this.status,
      designNotes: designNotes ?? this.designNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'componentName': componentName,
        'category': category,
        'specificationDetails': specificationDetails,
        'integrationPoint': integrationPoint,
        'status': status,
        'designNotes': designNotes,
      };

  factory DesignComponent.fromJson(Map<String, dynamic> json) {
    return DesignComponent(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      componentName: json['componentName']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Backend',
      specificationDetails: json['specificationDetails']?.toString() ?? '',
      integrationPoint: json['integrationPoint']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Draft',
      designNotes: json['designNotes']?.toString() ?? '',
    );
  }
}
