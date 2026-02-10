import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/expandable_text.dart';

// --- Shared Styles ---
const kSectionTitleStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w700,
  color: Color(0xFF111827), // Gray 900
  letterSpacing: 0.5,
);

const kCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(12)),
  boxShadow: [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.05),
      offset: Offset(0, 2),
      blurRadius: 4,
    )
  ],
);

// --- 1. Executive Snapshot Header (New) ---

class CharterExecutiveSnapshot extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterExecutiveSnapshot({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    // Calculate metrics
    final totalCost = _calculateTotalCost(data!);
    final duration = _calculateDuration(data!);
    final riskLevel = _calculateRiskLevel(data!);
    final sponsor = _determineSponsor(data!);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800 - Executive Dark Theme
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.2),
            offset: Offset(0, 4),
            blurRadius: 12,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSnapshotItem('TOTAL ESTIMATED COST', totalCost, Colors.white),
          _buildDivider(),
          _buildSnapshotItem('ESTIMATED DURATION', duration, Colors.blueAccent),
          _buildDivider(),
          _buildSnapshotItem('RISK LEVEL', riskLevel, _getRiskColor(riskLevel)),
          _buildDivider(),
          _buildSnapshotItem('EXECUTIVE SPONSOR', sponsor, Colors.amberAccent),
        ],
      ),
    );
  }

  Widget _buildSnapshotItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  String _calculateTotalCost(ProjectDataModel data) {
    if (data.costEstimateItems.isEmpty) return '\$0.00';
    final total =
        data.costEstimateItems.fold(0.0, (sum, item) => sum + item.amount);
    return NumberFormat.simpleCurrency(name: data.costBenefitCurrency)
        .format(total);
  }

  // Removed _calculateOpportunitiesCount - replaced with duration display

  String _calculateDuration(ProjectDataModel data) {
    if (data.keyMilestones.isEmpty) return 'TBD';

    DateTime? start;
    DateTime? end;

    for (var m in data.keyMilestones) {
      final date = DateTime.tryParse(m.dueDate);
      if (date != null) {
        if (start == null || date.isBefore(start)) start = date;
        if (end == null || date.isAfter(end)) end = date;
      }
    }

    if (start != null && end != null) {
      final days = end.difference(start).inDays;
      // Ensure positive duration
      final displayDays = days < 0 ? 0 : days;
      return '$displayDays Days';
    }

    return 'TBD';
  }

  String _calculateRiskLevel(ProjectDataModel data) {
    // Logic: Check Risk Register for severity
    final register = data.frontEndPlanning.riskRegisterItems;
    if (register.isNotEmpty) {
      bool hasHigh = register.any((r) => r.impactLevel.toLowerCase() == 'high');
      if (hasHigh) return 'High';
      bool hasMedium =
          register.any((r) => r.impactLevel.toLowerCase() == 'medium');
      if (hasMedium) return 'Medium';
      return 'Low';
    }

    // Fallback if register empty but risks exist in solution risks
    if (data.solutionRisks.isNotEmpty) {
      return 'Medium'; // Default safe assumption if risks exist but undefined severity
    }

    return 'Low';
  }

  String _determineSponsor(ProjectDataModel data) {
    if (data.charterProjectSponsorName.isNotEmpty) {
      return data.charterProjectSponsorName;
    }
    if (data.charterProjectManagerName.isNotEmpty) {
      return data.charterProjectManagerName; // Fallback to Owner
    }
    return 'Assign';
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }
}

// --- 2. General Information Header ---

class CharterExecutiveSummary extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterExecutiveSummary({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    final status = data!.currentCheckpoint.isNotEmpty
        ? data!.currentCheckpoint.toUpperCase().replaceAll('_', ' ')
        : 'INITIATION';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: kCardDecoration.copyWith(
        border:
            Border(left: BorderSide(color: Colors.amber.shade400, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data!.projectName.isNotEmpty
                          ? data!.projectName
                          : 'Untitled Project',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data!.businessCase.isNotEmpty
                          ? _getShortSummary(data!.businessCase)
                          : 'Strategic Objective: Define project value proposition.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Financial & Status Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Financial Justification Badges
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMiniBadge('ROI', _getROI(data!)),
                      const SizedBox(width: 8),
                      _buildMiniBadge('NPV', _getNPV(data!)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildKpiItem('Ref ID', data!.projectId ?? 'Draft', Icons.tag),
              _buildKpiItem('Project Manager', data!.charterProjectManagerName,
                  Icons.person_outline),
              _buildKpiItem('Start Date', _formatDate(data!.createdAt),
                  Icons.calendar_today_outlined),
            ],
          ),
        ],
      ),
    );
  }

  String _getShortSummary(String text) {
    if (text.length > 150) {
      return '${text.substring(0, 150)}...';
    }
    return text;
  }

  String _getROI(ProjectDataModel data) {
    // Try to get ROI from preferred solution analysis
    final analysis = data.preferredSolutionAnalysis;
    if (analysis != null) {
      // Access via cost items if stored there, simplified lookup
      // Assuming logic exists or using placeholder for now as logic is complex
      return 'TBD';
    }
    return 'TBD';
  }

  String _getNPV(ProjectDataModel data) {
    return 'TBD';
  }

  Widget _buildMiniBadge(String label, String value) {
    if (value == 'TBD') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800)),
          Text(value,
              style: TextStyle(fontSize: 11, color: Colors.green.shade900)),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
                Text(
                  value.isNotEmpty ? value : 'Assign',
                  style: value.isNotEmpty
                      ? const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)
                      : TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (value.isEmpty && label == 'Project Manager')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '(Click to assign)',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not Provided';
    return DateFormat('MMM d, yyyy').format(date);
  }
}

// --- 3. Financial Snapshot ---

class CharterFinancialSnapshot extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterFinancialSnapshot({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    final cost = _extractTotalCost(data!);
    final savings = _extractTotalBenefits(data!);
    final duration = _calculateDuration(data!);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FINANCIAL SNAPSHOT', style: kSectionTitleStyle),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetric(
                  'Est. Cost of Business Case', cost, Colors.red.shade700),
              _buildMetric('Est. Savings', savings, Colors.green.shade700),
              _buildMetric('Duration', duration, Colors.blue.shade700),
            ],
          ),
          const SizedBox(height: 24),
          // Visual Breakdown Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                    flex: 7, child: Container(height: 8, color: Colors.blue)),
                Expanded(
                    flex: 3,
                    child: Container(height: 8, color: Colors.greenAccent)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cost Breakdown',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              Text('Savings Potential',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  String _extractTotalCost(ProjectDataModel data) {
    double total = 0.0;
    // Sum Allowances
    for (var item in data.frontEndPlanning.allowanceItems) {
      total += item.amount;
    }
    // Sum Contractors
    for (var contractor in data.contractors) {
      total += contractor.estimatedCost;
    }
    // Sum Vendors
    for (var vendor in data.vendors) {
      total += vendor.estimatedPrice;
    }

    if (total == 0 && data.costEstimateItems.isNotEmpty) {
      // Fallback to old cost estimate items if new structures are empty
      total =
          data.costEstimateItems.fold(0.0, (sum, item) => sum + item.amount);
    }

    if (total == 0) return 'TBD';

    return NumberFormat.simpleCurrency(name: data.costBenefitCurrency)
        .format(total);
  }

  String _extractTotalBenefits(ProjectDataModel data) {
    double total = 0.0;
    for (var item in data.frontEndPlanning.opportunityItems) {
      // Clean string and parse
      String clean =
          item.potentialCostSavings.replaceAll(RegExp(r'[^\d.]'), '');
      if (clean.isNotEmpty) {
        total += double.tryParse(clean) ?? 0.0;
      }
    }

    if (total == 0) return 'TBD';

    return NumberFormat.simpleCurrency(name: data.costBenefitCurrency)
        .format(total);
  }

  String _calculateDuration(ProjectDataModel data) {
    if (data.keyMilestones.isEmpty) return 'TBD';

    DateTime? start;
    DateTime? end;

    // Scan all milestones for min start and max end
    for (var m in data.keyMilestones) {
      final date = DateTime.tryParse(m.dueDate);
      if (date != null) {
        if (date.isBefore(start ?? date)) start = date;
        if (date.isAfter(end ?? date)) end = date;
      }
    }

    // Also check creation date as a fallback start
    if (start == null && data.createdAt != null) {
      start = data.createdAt;
    }

    if (start != null && end != null) {
      final days = end.difference(start).inDays;
      // Ensure at least 1 day if start == end
      return '${days > 0 ? days : 1} Days';
    }

    return 'TBD';
  }
}

// --- 4. Project Definition ---

class CharterProjectDefinition extends StatelessWidget {
  final ProjectDataModel? data;
  final VoidCallback? onGenerate;

  const CharterProjectDefinition(
      {super.key, required this.data, this.onGenerate});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PROJECT DEFINITION', style: kSectionTitleStyle),
              if (onGenerate != null)
                TextButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label:
                      const Text('AI Generate', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // 1. Business Case & Project Aim
          _buildDefinitionBlock(
              'Business Case',
              data!.projectObjective.isNotEmpty
                  ? data!.projectObjective
                  : 'No project purpose defined.',
              'Define the business case and what this project will deliver'),
          const Divider(height: 32),
          // 2. Detailed Justification
          _buildDefinitionBlock(
              'Detailed Business Justification',
              data!.businessCase,
              'Outline what the project will deliver and its key objectives'),
          // Removed Goals section as requested
        ],
      ),
    );
  }

  Widget _buildDefinitionBlock(
      String label, String content, String placeholder) {
    final text = content.trim().isEmpty ? placeholder : content;
    final isPlaceholder = content.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
        const SizedBox(height: 8),
        ExpandableText(
          text: text,
          style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isPlaceholder ? Colors.grey : Colors.black87),
          maxLines: 4,
        ),
      ],
    );
  }
}

// --- 5. Scope ---

class CharterScope extends StatelessWidget {
  final ProjectDataModel? data;
  final VoidCallback? onGenerate;

  const CharterScope({super.key, required this.data, this.onGenerate});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PROJECT SCOPE', style: kSectionTitleStyle),
              if (onGenerate != null)
                TextButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label:
                      const Text('AI Generate', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _buildScopeList('Within Scope',
                      data!.withinScope.join('\n'), Colors.green)),
              const SizedBox(width: 24),
              Expanded(
                  child: _buildScopeList(
                      'Out of Scope', data!.outOfScope.join('\n'), Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScopeList(String title, String content, Color accentColor) {
    final List<String> items =
        content.split('\n').where((s) => s.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accentColor)),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text('Not specified',
              style:
                  TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: accentColor.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(item,
                          style: const TextStyle(fontSize: 13, height: 1.4))),
                ],
              ),
            )),
      ],
    );
  }
}

// --- 6. Risks (Table View) ---

class CharterFinancialOverview extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterFinancialOverview({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    final cost = _calculateTotalCostValue(data!);
    final costStr = NumberFormat.simpleCurrency(name: data!.costBenefitCurrency)
        .format(cost);

    // Savings target is currently displayed as text; keep parsing logic out until we need numeric calculations again.
    String benefitsStr = 'TBD';
    if (data!.costAnalysisData != null &&
        data!.costAnalysisData!.savingsTarget.isNotEmpty) {
      benefitsStr = data!.costAnalysisData!.savingsTarget;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FINANCIAL JUSTIFICATION', style: kSectionTitleStyle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ROI Analysis',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildBigMetric(
                    'Total Estimated Cost', costStr, Colors.red.shade700),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24.0),
                  child: _buildBigMetric(
                      'Expected Benefit', benefitsStr, Colors.green.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Cost Breakdown Chart (Embedded)
          const Text('Estimated Cost of Business Case',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
          const SizedBox(height: 16),
          _buildEmbeddedCostChart(data!),
        ],
      ),
    );
  }

  Widget _buildBigMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildEmbeddedCostChart(ProjectDataModel data) {
    final items = data.costEstimateItems;
    if (items.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No cost estimates to display.',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      ));
    }

    final total = items.fold(0.0, (sum, item) => sum + item.amount);
    final sorted = List<CostEstimateItem>.from(items)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      children: sorted.take(5).map((item) {
        final pct = total > 0 ? item.amount / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade100,
                              color: _getColor(sorted.indexOf(item)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 40,
                          child: Text('${(pct * 100).toInt()}%',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  NumberFormat.compactSimpleCurrency(
                          name: data.costBenefitCurrency)
                      .format(item.amount),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getColor(int index) {
    const table = [
      Color(0xFF3B82F6), // Blue 500
      Color(0xFFEF4444), // Red 500
      Color(0xFF10B981), // Emerald 500
      Color(0xFFF59E0B), // Amber 500
      Color(0xFF8B5CF6), // Violet 500
    ];
    return table[index % table.length];
  }

  double _calculateTotalCostValue(ProjectDataModel data) {
    if (data.costEstimateItems.isEmpty) return 0.0;
    return data.costEstimateItems.fold(0.0, (sum, item) => sum + item.amount);
  }
}

// --- 6. Risks (Table View + Summary) ---

class CharterRisks extends StatelessWidget {
  final ProjectDataModel? data;
  final VoidCallback? onGenerate;

  const CharterRisks({super.key, required this.data, this.onGenerate});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    // 1. Get Risks (Prioritize Risk Register)
    final riskRegister = data!.frontEndPlanning.riskRegisterItems;
    List<Map<String, dynamic>> combinedItems = [];

    // Add risks to combined list
    if (riskRegister.isNotEmpty) {
      for (var risk in riskRegister) {
        combinedItems.add({
          'type': 'Risk',
          'description': risk.riskName,
          'impact': risk.impactLevel,
          'likelihood': 'Medium', // Default for now
          'mitigation': risk.mitigationStrategy,
        });
      }
    } else {
      // Fallback to solution risks
      for (var solutionRisk in data!.solutionRisks) {
        for (var riskStr in solutionRisk.risks) {
          combinedItems.add({
            'type': 'Risk',
            'description': riskStr,
            'impact': 'Medium',
            'likelihood': 'Medium',
            'mitigation': 'TBD',
          });
        }
      }
    }

    // Add constraints to combined list
    for (var constraint in data!.constraints) {
      if (constraint.trim().isNotEmpty) {
        combinedItems.add({
          'type': 'Constraint',
          'description': constraint,
          'impact': 'Medium',
          'likelihood': 'N/A',
          'mitigation': 'Manage within project scope',
        });
      }
    }

    // Sort: Risks first, then Constraints. Within risks, High -> Medium -> Low
    combinedItems.sort((a, b) {
      if (a['type'] != b['type']) {
        return a['type'] == 'Risk' ? -1 : 1;
      }
      final scoreA = _impactScore(a['impact']);
      final scoreB = _impactScore(b['impact']);
      return scoreB.compareTo(scoreA);
    });

    // Filter Logic: Show max 8 items
    final displayItems = combinedItems.take(8).toList();

    // Stats
    final totalRisks = combinedItems.where((i) => i['type'] == 'Risk').length;
    final totalConstraints =
        combinedItems.where((i) => i['type'] == 'Constraint').length;
    final highRisks = combinedItems
        .where((i) =>
            i['type'] == 'Risk' &&
            i['impact'].toString().toLowerCase() == 'high')
        .length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('KEY RISKS & CONSTRAINTS',
                      style: kSectionTitleStyle),
                  if (onGenerate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onGenerate,
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      tooltip: 'AI Generate Risks',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  _buildRiskCount(totalRisks, 'Risks', Colors.red.shade700),
                  const SizedBox(width: 8),
                  _buildRiskCount(
                      totalConstraints, 'Constraints', Colors.orange.shade700),
                  const SizedBox(width: 8),
                  _buildRiskCount(highRisks, 'High', Colors.red.shade900),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (combinedItems.isEmpty)
            const Text('No risks or constraints identified.',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          if (combinedItems.isNotEmpty)
            Column(
              children: [
                _buildCombinedTableHeader(),
                const SizedBox(height: 8),
                ...displayItems.map((item) => _buildCombinedRow(item)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRiskCount(int count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text('$count $label',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildCombinedTableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Text('TYPE',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600]))),
          Expanded(
              flex: 4,
              child: Text('DESCRIPTION',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600]))),
          Expanded(
              flex: 2,
              child: Text('IMPACT',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600]))),
          Expanded(
              flex: 2,
              child: Text('LIKELIHOOD',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600]))),
          Expanded(
              flex: 3,
              child: Text('MITIGATION',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600]))),
        ],
      ),
    );
  }

  Widget _buildCombinedRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item['type'] == 'Risk'
                    ? Colors.red.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item['type'],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: item['type'] == 'Risk'
                      ? Colors.red.shade700
                      : Colors.orange.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(item['description'],
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildImpactBadge(item['impact']),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(item['likelihood'],
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 3,
            child: Text(item['mitigation'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactBadge(String impact) {
    Color color = Colors.grey;
    if (impact.toLowerCase() == 'high') color = Colors.red;
    if (impact.toLowerCase() == 'medium') color = Colors.orange;
    if (impact.toLowerCase() == 'low') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(impact,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  int _impactScore(String impact) {
    switch (impact.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }
}

// --- 8. Resources ---

class CharterResources extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterResources({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RESOURCES & TECHNOLOGY', style: kSectionTitleStyle),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _buildResourceColumn(
                      'Project Team',
                      data!.teamMembers
                          .map((m) => '${m.name} (${m.role})')
                          .toList())),
              const SizedBox(width: 24),
              Expanded(
                  child: _buildResourceColumn(
                      'Tech Stack',
                      data!.technologyInventory
                          .map((t) => t['name']?.toString() ?? '')
                          .toList())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceColumn(String title, List<String> items) {
    final validItems = items.where((s) => s.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
        const SizedBox(height: 8),
        if (validItems.isEmpty)
          const Text('None listed',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ...validItems.take(6).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $item', style: const TextStyle(fontSize: 13)),
            )),
      ],
    );
  }
}

// --- 9. Visual Charts ---

// --- 9. Visual Charts ---

class CharterMilestoneVisualizer extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterMilestoneVisualizer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    final milestones =
        data!.keyMilestones.where((m) => m.dueDate.isNotEmpty).toList();
    if (milestones.isEmpty) return const SizedBox();

    // Sort by date
    milestones.sort((a, b) {
      final da = DateTime.tryParse(a.dueDate) ?? DateTime.now();
      final db = DateTime.tryParse(b.dueDate) ?? DateTime.now();
      return da.compareTo(db);
    });

    final start = DateTime.tryParse(data!.createdAt.toString()) ??
        DateTime.now().subtract(const Duration(days: 1));
    var end = DateTime.tryParse(milestones.last.dueDate) ??
        DateTime.now().add(const Duration(days: 30));

    // Add buffer to end
    if (end.isBefore(start)) end = start.add(const Duration(days: 30));
    final totalDuration = end.difference(start).inDays.clamp(1, 10000);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: kCardDecoration,
      height: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TIMELINE OVERVIEW', style: kSectionTitleStyle),
          const SizedBox(height: 32),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Base Line
                    Container(
                      height: 4,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Active Progress Line (Mocking current date relative to timeline)
                    _buildProgressLine(
                        start, totalDuration, constraints.maxWidth),

                    // Milestones
                    ...milestones.map((m) {
                      final mDate = DateTime.tryParse(m.dueDate);
                      if (mDate == null) return const SizedBox();

                      // Calculate position 0.0 to 1.0
                      double normalizedPos =
                          mDate.difference(start).inDays / totalDuration;
                      // Clamp to keep within bounds visually (0.05 to 0.95 to avoid edge clipping)
                      normalizedPos = normalizedPos.clamp(0.0, 1.0);

                      // Determine status based on date vs now
                      final isCompleted = mDate.isBefore(DateTime.now());
                      final isFuture = !isCompleted;

                      return Positioned(
                        left: normalizedPos * constraints.maxWidth -
                            12, // Center the 24px icon
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.blue.shade600
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCompleted
                                      ? Colors.blue.shade600
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                                boxShadow: [
                                  if (isFuture)
                                    BoxShadow(
                                        color: Colors.grey.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2))
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  isCompleted
                                      ? Icons.check
                                      : Icons.calendar_today,
                                  size: 12,
                                  color: isCompleted
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 80,
                              child: Text(
                                m.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatShortDate(mDate),
                              style: TextStyle(
                                  fontSize: 9, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Legend or Start/End Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatLongDate(start),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400)),
              Text(_formatLongDate(end),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(
      DateTime start, int totalDuration, double maxWidth) {
    final now = DateTime.now();
    if (now.isBefore(start)) return const SizedBox();

    final elapsed = now.difference(start).inDays;
    double progress = elapsed / totalDuration;
    progress = progress.clamp(0.0, 1.0);

    return Container(
      height: 4,
      width: maxWidth * progress,
      decoration: BoxDecoration(
        color: Colors.blue.shade400,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _formatShortDate(DateTime d) {
    return DateFormat('MMM d').format(d);
  }

  String _formatLongDate(DateTime d) {
    return DateFormat('MMM d, yyyy').format(d);
  }
}

class CharterCostChart extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterCostChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    final items = data!.costEstimateItems;
    if (items.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: kCardDecoration,
        child: const Center(
            child: Text('No cost estimates available.',
                style: TextStyle(color: Colors.grey))),
      );
    }

    final total = items.fold(0.0, (sum, item) => sum + item.amount);
    final sorted = List<CostEstimateItem>.from(items)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('COST DISTRIBUTION', style: kSectionTitleStyle),
          const SizedBox(height: 16),
          Expanded(
            child: sorted.isEmpty
                ? const SizedBox()
                : Row(
                    children: [
                      // Pie/Donut (simplified as stacked bar or just legend list for reliability without external charting libs)
                      // Using a simple visual list with bars
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: sorted.take(5).map((item) {
                            final pct = total > 0 ? item.amount / total : 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(item.title,
                                          style: const TextStyle(fontSize: 11),
                                          overflow: TextOverflow.ellipsis)),
                                  SizedBox(
                                    width: 100,
                                    child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: Colors.grey[100],
                                        color: _getColor(sorted.indexOf(item))),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${(pct * 100).toInt()}%',
                                      style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    ],
                  ),
          )
        ],
      ),
    );
  }

  Color _getColor(int index) {
    const table = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple
    ];
    return table[index % table.length];
  }
}

class CharterScheduleTable extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterScheduleTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();
    final milestones = _extractMilestones(data!);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TENTATIVE SCHEDULE', style: kSectionTitleStyle),
          const SizedBox(height: 16),
          Table(
            border: TableBorder(
              horizontalInside:
                  BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade50),
                children: const [
                  Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('KEY MILESTONE',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold))),
                  Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('START',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold))),
                  Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('FINISH',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
              // Items
              ...milestones.map((m) => TableRow(
                    children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                          child: Text(m['name']!,
                              style: const TextStyle(fontSize: 12))),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                          child: Text(m['start']!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey))),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                          child: Text(m['finish']!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey))),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _extractMilestones(ProjectDataModel data) {
    final milestones = <Map<String, String>>[];
    for (final m in data.keyMilestones) {
      if (m.name.isNotEmpty) {
        milestones.add({
          'name': m.name,
          'start': m.dueDate.isNotEmpty ? m.dueDate : '—',
          'finish': m.dueDate.isNotEmpty ? m.dueDate : '—',
        });
      }
    }
    if (milestones.isEmpty) {
      return [
        {'name': 'Project Initiation', 'start': 'TBD', 'finish': 'TBD'},
        {'name': 'Planning Phase', 'start': 'TBD', 'finish': 'TBD'},
        {'name': 'Implementation', 'start': 'TBD', 'finish': 'TBD'},
        {'name': 'Project Close Out', 'start': 'TBD', 'finish': 'TBD'},
      ];
    }
    return milestones;
  }
}

// --- 14. IT Considerations ---
// --- 14. Technical Environment (Combines IT + Infra + Security) ---

class CharterTechnicalEnvironment extends StatelessWidget {
  final ProjectDataModel? data;
  final VoidCallback? onGenerate;

  const CharterTechnicalEnvironment(
      {super.key, required this.data, this.onGenerate});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    final it = data!.itConsiderationsData;
    final infra = data!.infrastructureConsiderationsData;

    // Procurement Data
    final vendorCount = data!.vendors.length;
    final contractCount = data!.contractors.length;
    // Basic heuristics for "Major Equipment" from potential procurement
    // For now, we'll use the 'Equipment' category from vendors or allowance items if available
    // But aligning with "Potential Procurement" placeholder:
    final procurementItems = data!.frontEndPlanning.allowanceItems
        .where((i) => i.type == 'Tech' || i.type == 'Other')
        .toList();
    final procurementCount = procurementItems.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TECHNICAL ENVIRONMENT & PROCUREMENT',
                  style: kSectionTitleStyle),
              if (onGenerate != null)
                TextButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label:
                      const Text('AI Generate', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. IT CONSIDERATIONS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubHeader('IT CONSIDERATIONS'),
                      const SizedBox(height: 12),
                      if (it == null)
                        _buildEmptyState()
                      else ...[
                        if (it.hardwareRequirements.isNotEmpty)
                          _buildSimpleReq('Hardware', it.hardwareRequirements),
                        if (it.softwareRequirements.isNotEmpty)
                          _buildSimpleReq('Software', it.softwareRequirements),
                        if (it.networkRequirements.isNotEmpty)
                          _buildSimpleReq('Network', it.networkRequirements),
                        if (it.hardwareRequirements.isEmpty &&
                            it.softwareRequirements.isEmpty &&
                            it.networkRequirements.isEmpty)
                          _buildEmptyState(),
                      ]
                    ],
                  ),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: VerticalDivider()),
                // 2. INFRASTRUCTURE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubHeader('INFRASTRUCTURE'),
                      const SizedBox(height: 12),
                      if (infra == null)
                        _buildEmptyState()
                      else ...[
                        if (infra.physicalSpaceRequirements.isNotEmpty)
                          _buildSimpleReq(
                              'Space', infra.physicalSpaceRequirements),
                        if (infra.powerCoolingRequirements.isNotEmpty)
                          _buildSimpleReq(
                              'Power/Cooling', infra.powerCoolingRequirements),
                        if (infra.connectivityRequirements.isNotEmpty)
                          _buildSimpleReq(
                              'Connectivity', infra.connectivityRequirements),
                        if (infra.physicalSpaceRequirements.isEmpty &&
                            infra.powerCoolingRequirements.isEmpty &&
                            infra.connectivityRequirements.isEmpty)
                          _buildEmptyState(),
                      ]
                    ],
                  ),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: VerticalDivider()),
                // 3. POTENTIAL CONTRACTS
                Expanded(
                  child: _buildProcurementColumn(
                      'POTENTIAL CONTRACTS',
                      contractCount,
                      'Identify and review',
                      'Contracts Pending',
                      Colors.blue.shade700,
                      Colors.blue.shade50),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: VerticalDivider()),
                // 4. POTENTIAL PROCUREMENT
                Expanded(
                  child: _buildProcurementColumn(
                      'POTENTIAL PROCUREMENT',
                      vendorCount + procurementCount,
                      'Major equipment details',
                      'Items Identified',
                      Colors.teal.shade700,
                      Colors.teal.shade50),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleReq(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildProcurementColumn(String title, int count, String subtitle,
      String statusLabel, Color color, Color bg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader(title),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.8))),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSubHeader(String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            letterSpacing: 0.5));
  }

  Widget _buildEmptyState() {
    return const Text('No specific requirements defined.',
        style: TextStyle(
            color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13));
  }
}

// --- 16. Stakeholders ---
class CharterStakeholders extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterStakeholders({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    // Combining core stakeholders and general stakeholder entries if relevant
    // For now, let's look at coreStakeholdersData and implicit stakeholders like Sponsor/Manager

    final items = <Map<String, String>>[];

    // Add Sponsor/Manager if not duplicate
    if (data!.charterProjectSponsorName.isNotEmpty) {
      items.add({
        'name': data!.charterProjectSponsorName,
        'role': 'Project Sponsor',
        'interest': 'High'
      });
    }
    if (data!.charterProjectManagerName.isNotEmpty) {
      items.add({
        'name': data!.charterProjectManagerName,
        'role': 'Project Manager',
        'interest': 'High'
      });
    }

    // Add from team members
    for (var m in data!.teamMembers) {
      if (m.name.isNotEmpty && !items.any((i) => i['name'] == m.name)) {
        items.add({'name': m.name, 'role': m.role, 'interest': 'Team'});
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('KEY STAKEHOLDERS', style: kSectionTitleStyle),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const Text('No stakeholders listed.',
                style: TextStyle(color: Colors.grey)),
          if (items.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                columnSpacing: 24,
                columns: const [
                  DataColumn(
                      label: Text('Name',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(
                      label: Text('Role',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(
                      label: Text('Interest Level',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: items
                    .map((item) => DataRow(cells: [
                          DataCell(Text(item['name']!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500))),
                          DataCell(Text(item['role']!)),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(item['interest']!,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.blue.shade800)),
                          )),
                        ]))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// --- 10. Assumptions (Summarized) ---

class CharterAssumptions extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterAssumptions({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROJECT ASSUMPTIONS (Summarized)',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 16),
          _buildSummaryList(data!.assumptions.join('\n')),
        ],
      ),
    );
  }

  Widget _buildSummaryList(String text) {
    if (text.isEmpty) {
      return const Text('None identified',
          style: TextStyle(
              fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey));
    }
    // Take first 3 lines/bullets
    final lines = text
        .split('\n')
        .where((l) => l.trim().length > 3)
        .take(3)
        .map((l) =>
            l.trim().replaceAll(RegExp(r'^[-•*]\s*'), '')); // Remove bullets

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Expanded(
                        child: Text(l, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
