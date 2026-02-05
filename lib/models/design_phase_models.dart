// Enums
enum ChecklistStatus { ready, inReview, pending }

// Requirements Implementation Models
class RequirementRow {
  RequirementRow({
    required this.title,
    required this.owner,
    required this.definition,
  });

  String title;
  String owner;
  String definition;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'owner': owner,
      'definition': definition,
    };
  }

  factory RequirementRow.fromMap(Map<String, dynamic> map) {
    return RequirementRow(
      title: map['title']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      definition: map['definition']?.toString() ?? '',
    );
  }
}

class RequirementChecklistItem {
  String title;
  String description;
  ChecklistStatus status;
  String? owner;

  RequirementChecklistItem({
    required this.title,
    required this.description,
    required this.status,
    this.owner,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status.name,
      'owner': owner,
    };
  }

  factory RequirementChecklistItem.fromMap(Map<String, dynamic> map) {
    return RequirementChecklistItem(
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      status: ChecklistStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ChecklistStatus.pending,
      ),
      owner: map['owner']?.toString(),
    );
  }
}

// Technical Alignment Models
class ConstraintRow {
  ConstraintRow({
    required this.constraint,
    required this.guardrail,
    required this.owner,
    required this.status,
  });

  String constraint;
  String guardrail;
  String owner;
  String status;

  Map<String, dynamic> toMap() {
    return {
      'constraint': constraint,
      'guardrail': guardrail,
      'owner': owner,
      'status': status,
    };
  }

  factory ConstraintRow.fromMap(Map<String, dynamic> map) {
    return ConstraintRow(
      constraint: map['constraint']?.toString() ?? '',
      guardrail: map['guardrail']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
    );
  }
}

class RequirementMappingRow {
  RequirementMappingRow({
    required this.requirement,
    required this.approach,
    required this.status,
  });

  String requirement;
  String approach;
  String status;

  Map<String, dynamic> toMap() {
    return {
      'requirement': requirement,
      'approach': approach,
      'status': status,
    };
  }

  factory RequirementMappingRow.fromMap(Map<String, dynamic> map) {
    return RequirementMappingRow(
      requirement: map['requirement']?.toString() ?? '',
      approach: map['approach']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
    );
  }
}

class DependencyDecisionRow {
  DependencyDecisionRow({
    required this.item,
    required this.detail,
    required this.owner,
    required this.status,
  });

  String item;
  String detail;
  String owner;
  String status;

  Map<String, dynamic> toMap() {
    return {
      'item': item,
      'detail': detail,
      'owner': owner,
      'status': status,
    };
  }

  factory DependencyDecisionRow.fromMap(Map<String, dynamic> map) {
    return DependencyDecisionRow(
      item: map['item']?.toString() ?? '',
      detail: map['detail']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
    );
  }
}

// Specialized Design Models
class SecurityPatternRow {
  SecurityPatternRow({
    required this.pattern,
    required this.decision,
    required this.owner,
    required this.status,
  });

  String pattern;
  String decision;
  String owner;
  String status;

  Map<String, dynamic> toMap() => {
        'pattern': pattern,
        'decision': decision,
        'owner': owner,
        'status': status,
      };

  factory SecurityPatternRow.fromMap(Map<String, dynamic> map) {
    return SecurityPatternRow(
      pattern: map['pattern']?.toString() ?? '',
      decision: map['decision']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
    );
  }
}

class PerformancePatternRow {
  PerformancePatternRow({
    required this.hotspot,
    required this.focus,
    required this.sla,
    required this.status,
  });

  String hotspot;
  String focus;
  String sla;
  String status;

  Map<String, dynamic> toMap() => {
        'hotspot': hotspot,
        'focus': focus,
        'sla': sla,
        'status': status,
      };

  factory PerformancePatternRow.fromMap(Map<String, dynamic> map) {
    return PerformancePatternRow(
      hotspot: map['hotspot']?.toString() ?? '',
      focus: map['focus']?.toString() ?? '',
      sla: map['sla']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
    );
  }
}

class IntegrationFlowRow {
  IntegrationFlowRow({
    required this.flow,
    required this.owner,
    required this.system,
    required this.status,
  });

  String flow;
  String owner;
  String system;
  String status;

  Map<String, dynamic> toMap() => {
        'flow': flow,
        'owner': owner,
        'system': system,
        'status': status,
      };

  factory IntegrationFlowRow.fromMap(Map<String, dynamic> map) {
    return IntegrationFlowRow(
      flow: map['flow']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      system: map['system']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
    );
  }
}

class SpecializedDesignData {
  String notes;
  List<SecurityPatternRow> securityPatterns;
  List<PerformancePatternRow> performancePatterns;
  List<IntegrationFlowRow> integrationFlows;

  SpecializedDesignData({
    this.notes = '',
    this.securityPatterns = const [],
    this.performancePatterns = const [],
    this.integrationFlows = const [],
  });

  Map<String, dynamic> toMap() => {
        'notes': notes,
        'securityPatterns': securityPatterns.map((e) => e.toMap()).toList(),
        'performancePatterns':
            performancePatterns.map((e) => e.toMap()).toList(),
        'integrationFlows': integrationFlows.map((e) => e.toMap()).toList(),
      };

  factory SpecializedDesignData.fromMap(Map<String, dynamic> map) {
    return SpecializedDesignData(
      notes: map['notes']?.toString() ?? '',
      securityPatterns: (map['securityPatterns'] as List?)
              ?.map(
                  (e) => SecurityPatternRow.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      performancePatterns: (map['performancePatterns'] as List?)
              ?.map((e) =>
                  PerformancePatternRow.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      integrationFlows: (map['integrationFlows'] as List?)
              ?.map(
                  (e) => IntegrationFlowRow.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// Progress DTOs
class DesignPhaseProgress {
  final double specificationsProgress;
  final double alignmentProgress;
  final double overallProgress;

  DesignPhaseProgress({
    required this.specificationsProgress,
    required this.alignmentProgress,
    required this.overallProgress,
  });
}
