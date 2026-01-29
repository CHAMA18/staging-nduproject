/// Model for a scope tracking item in Scope Tracking & Implementation page
class ScopeTrackingItem {
  final String id;
  String scopeItem; // Pre-populated from Scope Statement
  String implementationStatus; // Not Started, In-Progress, Verified, Out-of-Scope
  String owner; // From Staff Needs dropdown
  String verificationMethod; // Testing, UAT, Stakeholder Review
  String verificationSteps; // "." bullet format
  String trackingNotes; // Prose (no bullets), empty by default, manual input only

  ScopeTrackingItem({
    String? id,
    this.scopeItem = '',
    this.implementationStatus = 'Not Started',
    this.owner = '',
    this.verificationMethod = '',
    this.verificationSteps = '',
    this.trackingNotes = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  ScopeTrackingItem copyWith({
    String? scopeItem,
    String? implementationStatus,
    String? owner,
    String? verificationMethod,
    String? verificationSteps,
    String? trackingNotes,
  }) {
    return ScopeTrackingItem(
      id: id,
      scopeItem: scopeItem ?? this.scopeItem,
      implementationStatus: implementationStatus ?? this.implementationStatus,
      owner: owner ?? this.owner,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      verificationSteps: verificationSteps ?? this.verificationSteps,
      trackingNotes: trackingNotes ?? this.trackingNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scopeItem': scopeItem,
        'implementationStatus': implementationStatus,
        'owner': owner,
        'verificationMethod': verificationMethod,
        'verificationSteps': verificationSteps,
        'trackingNotes': trackingNotes,
      };

  factory ScopeTrackingItem.fromJson(Map<String, dynamic> json) {
    return ScopeTrackingItem(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      scopeItem: json['scopeItem']?.toString() ?? '',
      implementationStatus:
          json['implementationStatus']?.toString() ?? 'Not Started',
      owner: json['owner']?.toString() ?? '',
      verificationMethod: json['verificationMethod']?.toString() ?? '',
      verificationSteps: json['verificationSteps']?.toString() ?? '',
      trackingNotes: json['trackingNotes']?.toString() ?? '',
    );
  }
}
