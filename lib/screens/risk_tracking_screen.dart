import 'package:flutter/material.dart';
import 'package:ndu_project/screens/launch_checklist_screen.dart';
import 'package:ndu_project/screens/scope_completion_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/models/project_data_model.dart';

class RiskTrackingScreen extends StatefulWidget {
  const RiskTrackingScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RiskTrackingScreen()),
    );
  }

  @override
  State<RiskTrackingScreen> createState() => _RiskTrackingScreenState();
}

class _RiskTrackingScreenState extends State<RiskTrackingScreen> {
  final Set<String> _selectedFilters = {'All risks'};

  final List<_RiskItem> _risks = [];
  List<_RiskSignal> _signals = [];
  List<_MitigationPlan> _plans = [];
  bool _isLoadingData = true;
  String? _projectId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final provider = ProjectDataInherited.maybeOf(context);
    if (provider == null) {
      setState(() => _isLoadingData = false);
      return;
    }

    _projectId = provider.projectData.projectId;
    
    // Load risks from project data
    final risks = provider.projectData.trackingRisks;
    setState(() {
      _risks.clear();
      _risks.addAll(risks.map((r) => _RiskItem(
        r['id'] ?? '',
        r['title'] ?? '',
        r['owner'] ?? '',
        r['probability'] ?? '0.5',
        r['impact'] ?? 'Medium',
        r['status'] ?? 'Mitigating',
        r['nextReview'] ?? '',
      )));
    });

    // Generate risk signals and mitigation plans from OpenAI
    try {
      final ai = OpenAiServiceSecure();
      final projectData = provider.projectData;
      
      // Generate risks context
      final contextText = _buildRiskContext(projectData);
      
      // Generate risk signals
      try {
        final signalsText = await ai.generateFepSectionText(
          section: 'Risk Signals',
          context: contextText,
          maxTokens: 500,
          temperature: 0.7,
        );
        final signalsList = _parseSignals(signalsText);
        
        // Generate mitigation plans
        final mitigationText = await ai.generateFepSectionText(
          section: 'Mitigation Coverage',
          context: contextText,
          maxTokens: 500,
          temperature: 0.7,
        );
        final plansList = _parseMitigationPlans(mitigationText);
        
        if (mounted) {
          setState(() {
            _signals = signalsList;
            _plans = plansList;
            _isLoadingData = false;
          });
        }
      } catch (e) {
        debugPrint('Error generating AI content: $e');
        if (mounted) {
          setState(() => _isLoadingData = false);
        }
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  String _buildRiskContext(ProjectDataModel data) {
    final buf = StringBuffer();
    buf.writeln('Project: ${data.projectName}');
    buf.writeln('Solution: ${data.solutionTitle}');
    buf.writeln('Objective: ${data.projectObjective}');
    buf.writeln('Current risks: ${_risks.length}');
    buf.writeln('Active risks: ${_risks.where((r) => r.status != "Accepted").length}');
    return buf.toString();
  }

  List<_RiskSignal> _parseSignals(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final signals = <_RiskSignal>[];
    for (int i = 0; i < lines.length - 1; i += 2) {
      signals.add(_RiskSignal(lines[i].trim(), lines[i + 1].trim()));
    }
    return signals.take(3).toList();
  }

  List<_MitigationPlan> _parseMitigationPlans(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final plans = <_MitigationPlan>[];
    final colors = [const Color(0xFF10B981), const Color(0xFFF97316), const Color(0xFF6366F1)];
    for (int i = 0; i < lines.length && plans.length < 3; i += 3) {
      if (i + 2 < lines.length) {
        plans.add(_MitigationPlan(
          lines[i].trim(),
          lines[i + 1].trim(),
          'On track',
          0.65,
          colors[plans.length % colors.length],
        ));
      }
    }
    return plans;
  }

  Future<void> _saveRisksToFirebase() async {
    if (_projectId == null) return;
    final provider = ProjectDataInherited.maybeOf(context);
    if (provider == null) return;
    
    final risksList = _risks.map((r) => {
      'id': r.id,
      'title': r.title,
      'owner': r.owner,
      'probability': r.probability,
      'impact': r.impact,
      'status': r.status,
      'nextReview': r.nextReview,
    }).toList();
    
    provider.updateField((data) {
      return data.copyWith(trackingRisks: risksList);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    if (_isLoadingData) {
      return ResponsiveScaffold(
        activeItemLabel: 'Risk Tracking',
        backgroundColor: const Color(0xFFF5F7FB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ResponsiveScaffold(
      activeItemLabel: 'Risk Tracking',
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isNarrow),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 20),
                _buildStatsRow(isNarrow),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildRiskRegister(),
                    const SizedBox(height: 20),
                    _buildAddRiskSection(),
                    const SizedBox(height: 20),
                    _buildMitigationPanel(),
                    const SizedBox(height: 20),
                    _buildSignalsPanel(),
                    const SizedBox(height: 20),
                    _buildEscalationPanel(),
                  ],
                ),
                const SizedBox(height: 24),
                LaunchPhaseNavigation(
                  backLabel: 'Back: Start-up / Launch Checklist',
                  nextLabel: 'Next: Scope Completion',
                  onBack: () => LaunchChecklistScreen.open(context),
                  onNext: () => ScopeCompletionScreen.open(context),
                ),
              ],
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'EXECUTION SAFETY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Risk Tracking',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Monitor active risks, mitigation coverage, and escalation readiness across execution.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (!isNarrow) _buildHeaderActions(),
          ],
        ),
        if (isNarrow) ...[
          const SizedBox(height: 12),
          _buildHeaderActions(),
        ],
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _actionButton(Icons.add, 'Add risk', onPressed: _openAddRiskDialog),
        _actionButton(Icons.download_outlined, 'Import risk log'),
        _actionButton(Icons.description_outlined, 'Export report'),
        _primaryButton('Run weekly review'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _primaryButton(String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.play_arrow, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All risks', 'Critical', 'High', 'Mitigating', 'Escalated', 'Watchlist'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((filter) {
        final selected = _selectedFilters.contains(filter);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedFilters.remove(filter);
              } else {
                _selectedFilters.add(filter);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              filter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow(bool isNarrow) {
    final stats = [
      _StatCardData(
        'Active risks',
        '$_activeRiskCount',
        '$_criticalRiskCount critical',
        const Color(0xFFEF4444),
      ),
      _StatCardData(
        'Mitigation coverage',
        '${(_mitigationCoverageRate * 100).round()}%',
        _risks.isEmpty
            ? 'Add risks to start tracking'
            : '$_mitigatedRiskCount of $_activeRiskCount mitigated',
        const Color(0xFF10B981),
      ),
      _StatCardData(
        'Escalations',
        '$_escalationCount',
        _escalationCount > 0 ? 'Exec sync scheduled' : 'None',
        const Color(0xFFF97316),
      ),
      _StatCardData(
        'Exposure score',
        _risks.isEmpty ? '—' : '$_exposureScore/100',
        _risks.isEmpty ? 'Add risks to compute' : _exposureStatus,
        const Color(0xFF6366F1),
      ),
    ];

    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => _buildStatCard(stat)).toList(),
      );
    }

    return Row(
      children: stats.map((stat) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildStatCard(stat),
        ),
      )).toList(),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: data.color)),
          const SizedBox(height: 6),
          Text(data.label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(data.supporting, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: data.color)),
        ],
      ),
    );
  }

  int get _activeRiskCount => _risks.length;

  int get _criticalRiskCount => _risks.where((risk) => risk.impact == 'High').length;

  int get _mitigatedRiskCount => _risks.where((risk) => _isMitigatingStatus(risk.status)).length;

  double get _mitigationCoverageRate => _risks.isEmpty ? 0 : _mitigatedRiskCount / _activeRiskCount;

  int get _escalationCount => _risks.where((risk) => risk.status == 'Escalated').length;

  double get _averageProbability => _risks.isEmpty
      ? 0
      : _risks.map((risk) => _safeProbability(risk.probability)).reduce((a, b) => a + b) / _activeRiskCount;

  int get _exposureScore => _risks.isEmpty ? 0 : ((1 - _averageProbability).clamp(0.0, 1.0) * 100).round();

  String get _exposureStatus => _exposureScore >= 70
      ? 'Stable'
      : _exposureScore >= 40
          ? 'Caution'
          : 'At risk';

  double _safeProbability(String value) {
    return (double.tryParse(value) ?? 0).clamp(0.0, 1.0);
  }

  bool _isMitigatingStatus(String status) {
    return status == 'Mitigating' || status == 'Monitoring' || status == 'Accepted';
  }

  Widget _buildRiskRegister() {
    return _PanelShell(
      title: 'Risk register',
      subtitle: 'Live view of probability, impact, and mitigation status',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionButton(Icons.filter_list, 'Filter'),
          const SizedBox(width: 12),
          _actionButton(Icons.add, 'Create Risk', onPressed: _openAddRiskDialog),
        ],
      ),
      child: _risks.isEmpty
        ? _buildEmptyRiskState()
            : SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Risk', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Probability', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Impact', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Next review', style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                    rows: _risks.map((risk) {
                      return DataRow(cells: [
                        DataCell(Text(risk.id, style: const TextStyle(fontSize: 12, color: Color(0xFF0EA5E9)))),
                        DataCell(Text(risk.title, style: const TextStyle(fontSize: 13))),
                        DataCell(Text(risk.owner, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                        DataCell(_chip('${risk.probability} p')),
                        DataCell(_impactChip(risk.impact)),
                        DataCell(_statusChip(risk.status)),
                        DataCell(Text(risk.nextReview, style: const TextStyle(fontSize: 12))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
      );
  }

  Widget _buildEmptyRiskState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No risks logged yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a risk to start tracking probability, impact, and mitigation status for your execution plan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _actionButton(Icons.add, 'Add risk', onPressed: _openAddRiskDialog),
        ],
      ),
    );
  }

  void _openAddRiskDialog() {
    final idController = TextEditingController();
    final titleController = TextEditingController();
    final ownerController = TextEditingController();
    final probabilityController = TextEditingController();
    final nextReviewController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedImpact = 'High';
    var selectedStatus = 'Mitigating';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add risk'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: idController,
                        decoration: const InputDecoration(labelText: 'Risk ID', hintText: 'e.g., R-050'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Enter an ID' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Risk title'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Describe the risk' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: ownerController,
                        decoration: const InputDecoration(labelText: 'Owner'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: probabilityController,
                        decoration: const InputDecoration(labelText: 'Probability (e.g., 0.42)'),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedImpact,
                        items: const ['Low', 'Medium', 'High']
                            .map((impact) => DropdownMenuItem(value: impact, child: Text(impact)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedImpact = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Impact'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        items: const ['Mitigating', 'Monitoring', 'Escalated', 'Accepted']
                            .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedStatus = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Status'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nextReviewController,
                        decoration: const InputDecoration(labelText: 'Next review (date or note)'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() {
                        _risks.add(
                          _RiskItem(
                            idController.text.trim(),
                            titleController.text.trim(),
                            ownerController.text.trim(),
                            probabilityController.text.trim(),
                            selectedImpact,
                            selectedStatus,
                            nextReviewController.text.trim(),
                          ),
                        );
                      });
                      _saveRisksToFirebase();
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add risk'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      idController.dispose();
      titleController.dispose();
      ownerController.dispose();
      probabilityController.dispose();
      nextReviewController.dispose();
    });
  }

  Widget _buildAddRiskSection() {
    return _PanelShell(
      title: 'Add new risk item',
      subtitle: 'Log a risk to the register and track its mitigation status',
      trailing: _actionButton(Icons.add, 'Add risk', onPressed: _openAddRiskDialog),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Text(
          'Click "Add risk" above to log a new risk to the register',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildMitigationPanel() {
    return _PanelShell(
      title: 'Mitigation coverage',
      subtitle: 'Execution readiness by risk program',
      child: Column(
        children: _plans.map((plan) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(plan.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    Text(plan.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: plan.color)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(plan.owner, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: plan.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(plan.color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSignalsPanel() {
    return _PanelShell(
      title: 'Risk signals',
      subtitle: 'Early warnings and momentum shifts',
      child: Column(
        children: _signals.map((signal) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(signal.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(signal.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEscalationPanel() {
    return _PanelShell(
      title: 'Escalation readiness',
      subtitle: 'Decision log & sponsor alignment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _EscalationItem('Executive sync', 'Fri 9:30 AM', 'Agenda locked'),
          _EscalationItem('Risk board update', 'Mon 3:00 PM', 'Pending approvals'),
          _EscalationItem('Ops stakeholder review', 'Wed 11:00 AM', 'Materials sent'),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
    );
  }

  Widget _statusChip(String label) {
    final color = label == 'Escalated'
        ? const Color(0xFFEF4444)
        : label == 'Mitigating'
            ? const Color(0xFF0EA5E9)
            : label == 'Monitoring'
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _impactChip(String label) {
    final color = label == 'High' ? const Color(0xFFEF4444) : label == 'Medium' ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EscalationItem extends StatelessWidget {
  const _EscalationItem(this.title, this.time, this.status);

  final String title;
  final String time;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: const Color(0xFF0EA5E9), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _RiskItem {
  const _RiskItem(this.id, this.title, this.owner, this.probability, this.impact, this.status, this.nextReview);

  final String id;
  final String title;
  final String owner;
  final String probability;
  final String impact;
  final String status;
  final String nextReview;
}

class _RiskSignal {
  const _RiskSignal(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

class _MitigationPlan {
  const _MitigationPlan(this.title, this.owner, this.status, this.progress, this.color);

  final String title;
  final String owner;
  final String status;
  final double progress;
  final Color color;
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
