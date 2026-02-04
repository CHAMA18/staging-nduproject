import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/content_text.dart'; // Assuming this exists or use Text
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

// --- 1. Executive Summary & KPI Card ---

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
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration.copyWith(
        border: Border(left: BorderSide(color: Colors.amber.shade400, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data!.projectName.isNotEmpty ? data!.projectName : 'Untitled Project',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ref: ${data!.projectId ?? "Draft"}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    color: Colors.blue.shade800
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildKpiItem('Sponsor', data!.charterProjectSponsorName, Icons.person_outline),
              _buildKpiItem('Manager', data!.charterProjectManagerName, Icons.manage_accounts_outlined),
              _buildKpiItem('Start Date', _formatDate(data!.createdAt), Icons.calendar_today_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
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
              _buildMetric('Est. Cost', cost, Colors.red.shade700),
              _buildMetric('Est. Savings', savings, Colors.green.shade700),
              _buildMetric('Duration', duration, Colors.blue.shade700),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  String _extractTotalCost(ProjectDataModel data) {
    if (data.costEstimateItems.isEmpty) return 'TBD';
    final total = data.costEstimateItems.fold(0.0, (sum, item) => sum + item.amount);
    return NumberFormat.simpleCurrency(name: data.costBenefitCurrency).format(total);
  }

  String _extractTotalBenefits(ProjectDataModel data) {
    if (data.costAnalysisData == null) return 'TBD';
    // Simplified logic as actual benefits calculation might be complex
    return data.costAnalysisData!.savingsTarget.isNotEmpty ? data.costAnalysisData!.savingsTarget : 'TBD';
  }

  String _calculateDuration(ProjectDataModel data) {
    // Simple logic: if deadlines exist, calc diff. Else 'TBD'
    // This requires proper milestone dates. Placeholder for now.
    return '90 Days'; // Placeholder based on typical quarterly planning
  }
}

// --- 4. Project Definition ---

class CharterProjectDefinition extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterProjectDefinition({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROJECT DEFINITION', style: kSectionTitleStyle),
          const SizedBox(height: 20),
          _buildDefinitionBlock('Business Case', data!.businessCase, 'Why are we doing this project?'),
          const Divider(height: 32),
          _buildDefinitionBlock('Project Purpose', data!.projectObjective, 'What will this project achieve?'),
          const Divider(height: 32),
          Text('Goals & Success Metrics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          if (data!.projectGoals.isEmpty)
             const Text('No specific goals defined yet.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          ...data!.projectGoals.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text('${g.name}: ${g.description}')),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDefinitionBlock(String label, String content, String placeholder) {
    final text = content.trim().isEmpty ? placeholder : content;
    final isPlaceholder = content.trim().isEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 8),
        ExpandableText(
          text: text, 
          style: TextStyle(
            fontSize: 14, 
            height: 1.5,
            color: isPlaceholder ? Colors.grey : Colors.black87
          ),
          maxLines: 4,
        ),
      ],
    );
  }
}

// --- 5. Scope ---

class CharterScope extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterScope({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROJECT SCOPE', style: kSectionTitleStyle),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildScopeList('Within Scope', data!.planningNotes['Within Scope'] ?? '', Colors.green)),
              const SizedBox(width: 24),
              Expanded(child: _buildScopeList('Out of Scope', data!.outOfScope.join('\n'), Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScopeList(String title, String content, Color accentColor) {
    final List<String> items = content.split('\n').where((s) => s.trim().isNotEmpty).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor)),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text('Not specified', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, size: 14, color: accentColor.withOpacity(0.7)),
              const SizedBox(width: 8),
              Expanded(child: Text(item, style: const TextStyle(fontSize: 13, height: 1.4))),
            ],
          ),
        )),
      ],
    );
  }
}

// --- 6. Risks (Table View) ---

class CharterRisks extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterRisks({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();
    
    // Combine general risks and solution risks
    // For this audit we focus on SolutionRisk or create a dedicated RiskRegisterItem list usage if populated
    // As per user request, we need a table: Risk, Impact, Likelihood, Mitigation.
    // We will use solutionRisks for now, adapting them to the table.
    
    final risks = data!.solutionRisks.expand((r) => r.risks.map((riskStr) => RiskRegisterItem(
      riskName: riskStr,
      impactLevel: 'Medium', // Default as we don't have this data in string list
      likelihood: 'Unknown',
      mitigationStrategy: 'TBD'
    ))).toList();
    
    // Also include riskRegisterItems if they exist (which we added logic for)
    // Note: ProjectDataModel might not populate riskRegisterItems from UI yet, but we are prepping the view.

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('KEY RISKS & CONSTRAINTS', style: kSectionTitleStyle),
          const SizedBox(height: 20),
          if (risks.isEmpty && data!.charterConstraints.isEmpty)
             const Text('No major risks or constraints identified yet.', style: TextStyle(color: Colors.grey)),

          if (risks.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Risk Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Impact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Likelihood', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Mitigation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: risks.take(5).map((r) => DataRow(cells: [
                  DataCell(SizedBox(width: 200, child: Text(r.riskName, overflow: TextOverflow.ellipsis))),
                  DataCell(Text(r.impactLevel)),
                  DataCell(Text(r.likelihood)),
                  DataCell(SizedBox(width: 150, child: Text(r.mitigationStrategy, overflow: TextOverflow.ellipsis))),
                ])).toList(),
              ),
            ),
            
          if (data!.charterConstraints.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Proejct Constraints', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
             const SizedBox(height: 8),
             Text(data!.charterConstraints, style: const TextStyle(fontSize: 13, height: 1.5)),
          ]
        ],
      ),
    );
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
              Expanded(child: _buildResourceColumn('Project Team', data!.teamMembers.map((m) => '${m.name} (${m.role})').toList())),
              const SizedBox(width: 24),
              Expanded(child: _buildResourceColumn('Tech Stack', data!.technologyInventory.map((t) => t['name']?.toString() ?? '').toList())),
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
         Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
         const SizedBox(height: 8),
         if (validItems.isEmpty)
           const Text('None listed', style: TextStyle(color: Colors.grey, fontSize: 13)),
         ...validItems.take(6).map((item) => Padding(
           padding: const EdgeInsets.only(bottom: 4),
           child: Text('• $item', style: const TextStyle(fontSize: 13)),
         )),
       ],
     );
   }
}

// --- 9. Visual Charts ---

class CharterTimelineChart extends StatelessWidget {
  final ProjectDataModel? data;

  const CharterTimelineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();
    
    final start = data!.createdAt ?? DateTime.now();
    DateTime end = DateTime.now().add(const Duration(days: 90)); 
    
    final milestones = data!.keyMilestones;
    if (milestones.isNotEmpty) {
      final sorted = List<Milestone>.from(milestones)
        ..sort((a, b) => (_parseDate(a.dueDate) ?? DateTime.now())
                .compareTo(_parseDate(b.dueDate) ?? DateTime.now()));
      if (sorted.isNotEmpty) {
        final lastDate = _parseDate(sorted.last.dueDate);
        if (lastDate != null) end = lastDate;
      }
    }

    if (end.isBefore(start)) end = start.add(const Duration(days: 1));
    final totalDuration = end.difference(start).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration,
      height: 200, // Fixed height for chart
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TIMELINE OVERVIEW', style: kSectionTitleStyle),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Phase background (simplified)
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Progress
                LayoutBuilder(
                  builder: (context, constraints) {
                    final now = DateTime.now();
                    if (now.isBefore(start)) return const SizedBox();
                    final elapsed = now.difference(start).inDays;
                    final progress = (elapsed / (totalDuration == 0 ? 1 : totalDuration)).clamp(0.0, 1.0);
                    return Container(
                      width: constraints.maxWidth * progress,
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade700]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    );
                  },
                ),
                // Milestones
                ...milestones.map((m) {
                  final mDate = _parseDate(m.dueDate);
                  if (mDate == null) return const SizedBox();
                  final offset = mDate.difference(start).inDays;
                  final pct = (offset / (totalDuration == 0 ? 1 : totalDuration)).clamp(0.0, 1.0);
                  
                  return Align(
                    alignment: Alignment(pct * 2 - 1, -0.6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 2, height: 16, color: Colors.black54),
                        Text(m.name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDate(start), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(_formatDate(end), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty || dateStr == 'TBD') return null;
    return DateTime.tryParse(dateStr);
  }

  String _formatDate(DateTime d) {
    return DateFormat('MMM yyyy').format(d);
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
        child: const Center(child: Text('No cost estimates available.', style: TextStyle(color: Colors.grey))),
      );
    }

    final total = items.fold(0.0, (sum, item) => sum + item.amount);
    final sorted = List<CostEstimateItem>.from(items)..sort((a,b) => b.amount.compareTo(a.amount));
    
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
            child: sorted.isEmpty ? const SizedBox() : Row(
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
                             Expanded(child: Text(item.title, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                             SizedBox(
                               width: 100,
                               child: LinearProgressIndicator(value: pct, backgroundColor: Colors.grey[100], color: _getColor(sorted.indexOf(item))),
                             ),
                             const SizedBox(width: 8),
                             Text('${(pct*100).toInt()}%', style: const TextStyle(fontSize: 11)),
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
    const table = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple];
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
              horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
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
                  Padding(padding: EdgeInsets.all(8), child: Text('KEY MILESTONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('START', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('FINISH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
              // Items
              ...milestones.map((m) => TableRow(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Text(m['name']!, style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Text(m['start']!, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Text(m['finish']!, style: const TextStyle(fontSize: 12, color: Colors.grey))),
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
