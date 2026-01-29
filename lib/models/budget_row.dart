/// Model for a budget row in Progress Tracking
class BudgetRow {
  final String id;
  String category; // e.g., "Contracts", "Staffing", "Tools", etc.
  double plannedAmount;
  double actualAmount;
  String period; // e.g., "Q1 2024", "Monthly", etc.
  String notes; // Manual notes only, no AI generation

  BudgetRow({
    String? id,
    this.category = '',
    this.plannedAmount = 0.0,
    this.actualAmount = 0.0,
    this.period = '',
    this.notes = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  /// Calculate variance (actual - planned)
  double get variance => actualAmount - plannedAmount;

  /// Calculate variance percentage
  double get variancePercent {
    if (plannedAmount == 0) return 0.0;
    return (variance / plannedAmount) * 100;
  }

  BudgetRow copyWith({
    String? category,
    double? plannedAmount,
    double? actualAmount,
    String? period,
    String? notes,
  }) {
    return BudgetRow(
      id: id,
      category: category ?? this.category,
      plannedAmount: plannedAmount ?? this.plannedAmount,
      actualAmount: actualAmount ?? this.actualAmount,
      period: period ?? this.period,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'plannedAmount': plannedAmount,
        'actualAmount': actualAmount,
        'period': period,
        'notes': notes,
      };

  factory BudgetRow.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    return BudgetRow(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      category: json['category']?.toString() ?? '',
      plannedAmount: parseDouble(json['plannedAmount']),
      actualAmount: parseDouble(json['actualAmount']),
      period: json['period']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}
