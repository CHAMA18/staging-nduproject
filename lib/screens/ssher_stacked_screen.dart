import 'package:flutter/material.dart';
import 'package:ndu_project/screens/ssher_components.dart';
import 'package:ndu_project/screens/ssher_add_safety_item_dialog.dart';
import 'package:ndu_project/screens/ssher_safety_full_view.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/screens/change_management_screen.dart';

enum _SsherCategory { safety, security, health, environment, regulatory }

String _categoryKey(_SsherCategory category) => category.name;

class SsherStackedScreen extends StatefulWidget {
  const SsherStackedScreen({super.key});

  @override
  State<SsherStackedScreen> createState() => _SsherStackedScreenState();
}

class _SsherStackedScreenState extends State<SsherStackedScreen> {
  final Color _safetyAccent = const Color(0xFF34A853);
  final Color _securityAccent = const Color(0xFFEF5350);
  final Color _healthAccent = const Color(0xFF1E88E5);
  final Color _environmentAccent = const Color(0xFF2E7D32);
  final Color _regulatoryAccent = const Color(0xFF8E24AA);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _aiPlanSummary = '';
  bool _isGeneratingSummary = false;
  bool _summaryLoaded = false;
  bool _entriesGenerated = false;
  bool _isGeneratingEntries = false;

  late List<SsherEntry> _safetyEntries;
  late List<SsherEntry> _securityEntries;
  late List<SsherEntry> _healthEntries;
  late List<SsherEntry> _environmentEntries;
  late List<SsherEntry> _regulatoryEntries;

  @override
  void initState() {
    super.initState();
    // Initialize all SSHER sections with NO default data.
    // Users can add items via the "Add ... Item" actions.
    _safetyEntries = [];
    _securityEntries = [];
    _healthEntries = [];
    _environmentEntries = [];
    _regulatoryEntries = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedEntries();
      _populateSsherSummaryFromAi();
    });
  }

  void _loadSavedEntries() {
    final ssherData = ProjectDataHelper.getData(context).ssherData;
    final entries = ssherData.entries;
    setState(() {
      _safetyEntries = entries.where((e) => e.category == _categoryKey(_SsherCategory.safety)).toList();
      _securityEntries = entries.where((e) => e.category == _categoryKey(_SsherCategory.security)).toList();
      _healthEntries = entries.where((e) => e.category == _categoryKey(_SsherCategory.health)).toList();
      _environmentEntries = entries.where((e) => e.category == _categoryKey(_SsherCategory.environment)).toList();
      _regulatoryEntries = entries.where((e) => e.category == _categoryKey(_SsherCategory.regulatory)).toList();
    });
    if (entries.isEmpty) {
      _populateSsherEntriesFromAi();
    } else {
      _entriesGenerated = true;
    }
  }

  Future<void> _populateSsherEntriesFromAi() async {
    if (_entriesGenerated || _isGeneratingEntries) return;
    if (_allEntries().isNotEmpty) {
      _entriesGenerated = true;
      return;
    }

    final projectData = ProjectDataHelper.getData(context);
    final contextText = ProjectDataHelper.buildFepContext(projectData, sectionLabel: 'SSHER');
    if (contextText.trim().isEmpty) {
      _entriesGenerated = true;
      return;
    }

    setState(() => _isGeneratingEntries = true);

    List<SsherEntry> generatedEntries = [];
    try {
      generatedEntries = await OpenAiServiceSecure().generateSsherEntries(context: contextText, itemsPerCategory: 2);
    } catch (error) {
      debugPrint('SSHER entries AI call failed: $error');
    }

    if (!mounted) return;

    if (_allEntries().isNotEmpty) {
      setState(() => _isGeneratingEntries = false);
      _entriesGenerated = true;
      return;
    }

    final safety = <SsherEntry>[];
    final security = <SsherEntry>[];
    final health = <SsherEntry>[];
    final environment = <SsherEntry>[];
    final regulatory = <SsherEntry>[];

    for (final entry in generatedEntries) {
      switch (entry.category) {
        case 'safety':
          safety.add(entry);
          break;
        case 'security':
          security.add(entry);
          break;
        case 'health':
          health.add(entry);
          break;
        case 'environment':
          environment.add(entry);
          break;
        case 'regulatory':
          regulatory.add(entry);
          break;
      }
    }

    if (safety.isEmpty &&
        security.isEmpty &&
        health.isEmpty &&
        environment.isEmpty &&
        regulatory.isEmpty) {
      setState(() => _isGeneratingEntries = false);
      _entriesGenerated = true;
      return;
    }

    setState(() {
      _safetyEntries = safety;
      _securityEntries = security;
      _healthEntries = health;
      _environmentEntries = environment;
      _regulatoryEntries = regulatory;
      _isGeneratingEntries = false;
    });
    _entriesGenerated = true;
    await _saveEntries();
  }

  Future<void> _populateSsherSummaryFromAi() async {
    if (_summaryLoaded) return;
    final projectData = ProjectDataHelper.getData(context);
    final existingSummary = projectData.ssherData.screen1Data.trim();
    if (existingSummary.isNotEmpty) {
      setState(() {
        _aiPlanSummary = existingSummary;
        _summaryLoaded = true;
      });
      return;
    }

    final contextText = ProjectDataHelper.buildFepContext(projectData, sectionLabel: 'SSHER');
    if (contextText.trim().isEmpty) {
      setState(() => _summaryLoaded = true);
      return;
    }

    setState(() {
      _isGeneratingSummary = true;
    });

    String summary = '';
    try {
      summary = await OpenAiServiceSecure().generateSsherPlanSummary(context: contextText);
    } catch (error) {
      debugPrint('SSHER summary AI call failed: $error');
    }

    if (!mounted) return;

    final trimmedSummary = summary.trim();
    setState(() {
      _aiPlanSummary = trimmedSummary;
      _isGeneratingSummary = false;
      _summaryLoaded = true;
    });

    if (trimmedSummary.isEmpty) return;
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'ssher',
      showSnackbar: false,
      dataUpdater: (data) => data.copyWith(
        ssherData: data.ssherData.copyWith(screen1Data: trimmedSummary),
      ),
    );
  }

  List<Widget> _buildRow({required int index, required SsherEntry entry}) {
    Widget risk;
    switch (entry.riskLevel) {
      case 'Low':
        risk = const RiskBadge.low();
        break;
      case 'Medium':
        risk = const RiskBadge.medium();
        break;
      default:
        risk = const RiskBadge.high();
    }

    return [
      Text('$index', style: const TextStyle(fontSize: 12)),
      Text(entry.department, style: const TextStyle(fontSize: 13)),
      Text(entry.teamMember, style: const TextStyle(fontSize: 13)),
      Text(entry.concern, style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis),
      risk,
      Text(entry.mitigation, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
      const ActionButtons(),
    ];
  }

  List<List<Widget>> _rowsFor(List<SsherEntry> entries) {
    return entries.asMap().entries.map((entry) {
      final index = entry.key + 1;
      return _buildRow(index: index, entry: entry.value);
    }).toList();
  }

  List<SsherEntry> _entriesForCategory(_SsherCategory category) {
    switch (category) {
      case _SsherCategory.safety:
        return _safetyEntries;
      case _SsherCategory.security:
        return _securityEntries;
      case _SsherCategory.health:
        return _healthEntries;
      case _SsherCategory.environment:
        return _environmentEntries;
      case _SsherCategory.regulatory:
        return _regulatoryEntries;
    }
  }

  List<SsherEntry> _allEntries() {
    return [
      ..._safetyEntries,
      ..._securityEntries,
      ..._healthEntries,
      ..._environmentEntries,
      ..._regulatoryEntries,
    ];
  }

  Future<void> _saveEntries() async {
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'ssher',
      dataUpdater: (data) => data.copyWith(
        ssherData: data.ssherData.copyWith(entries: _allEntries()),
      ),
      showSnackbar: false,
    );
  }

  Future<void> _addEntry(_SsherCategory category, SsherItemInput input) async {
    final entry = SsherEntry(
      category: _categoryKey(category),
      department: input.department,
      teamMember: input.teamMember,
      concern: input.concern,
      riskLevel: input.riskLevel,
      mitigation: input.mitigation,
    );
    setState(() => _entriesForCategory(category).add(entry));
    await _saveEntries();
  }

  Future<void> _onAddSafetyItem() async {
    final input = await showDialog<SsherItemInput>(
      context: context,
      builder: (ctx) => AddSsherItemDialog(
        accentColor: _safetyAccent,
        icon: Icons.health_and_safety,
        heading: 'Add Safety Item',
        blurb: 'Provide details for the new safety record. Make sure risk level and mitigation strategy are accurate.',
        concernLabel: 'Safety Concern',
      ),
    );
    if (input == null) return;
    await _addEntry(_SsherCategory.safety, input);
  }

  Future<void> _onAddSecurityItem() async {
    final input = await showDialog<SsherItemInput>(
      context: context,
      builder: (ctx) => AddSsherItemDialog(
        accentColor: _securityAccent,
        icon: Icons.shield_outlined,
        heading: 'Add Security Item',
        blurb: 'Capture the security exposure along with responsible contact and mitigation plan.',
        concernLabel: 'Security Concern',
      ),
    );
    if (input == null) return;
    await _addEntry(_SsherCategory.security, input);
  }

  Future<void> _onAddHealthItem() async {
    final input = await showDialog<SsherItemInput>(
      context: context,
      builder: (ctx) => AddSsherItemDialog(
        accentColor: _healthAccent,
        icon: Icons.volunteer_activism_outlined,
        heading: 'Add Health Item',
        blurb: 'Document the health-related concern and identify mitigation steps for your team.',
        concernLabel: 'Health Concern',
      ),
    );
    if (input == null) return;
    await _addEntry(_SsherCategory.health, input);
  }

  Future<void> _onAddEnvironmentItem() async {
    final input = await showDialog<SsherItemInput>(
      context: context,
      builder: (ctx) => AddSsherItemDialog(
        accentColor: _environmentAccent,
        icon: Icons.eco_outlined,
        heading: 'Add Environment Item',
        blurb: 'Log environmental impacts or sustainability risks to keep compliance in check.',
        concernLabel: 'Environmental Concern',
      ),
    );
    if (input == null) return;
    await _addEntry(_SsherCategory.environment, input);
  }

  Future<void> _onAddRegulatoryItem() async {
    final input = await showDialog<SsherItemInput>(
      context: context,
      builder: (ctx) => AddSsherItemDialog(
        accentColor: _regulatoryAccent,
        icon: Icons.gavel_outlined,
        heading: 'Add Regulatory Item',
        blurb: 'Detail the compliance requirement and note the mitigation strategy.',
        concernLabel: 'Regulatory Requirement',
      ),
    );
    if (input == null) return;
    await _addEntry(_SsherCategory.regulatory, input);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DraggableSidebar(
                  openWidth: AppBreakpoints.sidebarWidth(context),
                  child: const InitiationLikeSidebar(activeItemLabel: 'SSHER'),
                ),
                Expanded(
                  child: _buildMainContent(const EdgeInsets.all(24)),
                ),
              ],
            ),
            const KazAiChatBubble(),
            const AdminEditToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(EdgeInsetsGeometry padding) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(children: [
        const PlanningAiNotesCard(
          title: 'AI Notes',
          sectionLabel: 'SSHER',
          noteKey: 'planning_ssher_notes',
          checkpoint: 'ssher',
          description: 'Summarize key SSHER risks, mitigation plans, and compliance requirements.',
        ),
        const SizedBox(height: 20),
        // Plan Summary (from page 1)
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.receipt_long, size: 18, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: EditableContentText(
                    contentKey: 'ssher_plan_summary_title',
                    fallback: 'SSHER Plan Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    category: 'ssher',
                  ),
                ),
              ]),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
              ),
              child: EditableContentText(
                contentKey: 'ssher_plan_summary_description',
                fallback: 'This SSHER plan encompasses comprehensive risk management across all operational domains. Safety protocols focus on workplace injury prevention and emergency response procedures. Security measures address both physical and cyber threats with multi-layered protection strategies. Health initiatives promote employee wellbeing and occupational health standards. Environmental considerations ensure sustainable practices and regulatory compliance. Regulatory frameworks maintain adherence to industry standards and legal requirements.',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                category: 'ssher',
              ),
            ),
          ]),
        ),

        if (_isGeneratingSummary)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI is preparing a tailored SSHER summary using your prior section inputs. This will be saved automatically to your project.',
                    style: TextStyle(color: Colors.blue[900], fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else if (_aiPlanSummary.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI-generated SSHER Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  _aiPlanSummary,
                  style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),

        // Safety (from page 1)
        SsherSectionCard(
          leadingIcon: Icons.health_and_safety,
          accentColor: _safetyAccent,
          title: 'Safety',
          subtitle: 'Workplace safety protocols and risk management',
          detailsPlaceholder:
              'Comprehensive safety protocols including personal protective equipment requirements, emergency evacuation procedures, incident reporting systems , and regular safety training programs for all personnel .',
          itemsLabel: '${_safetyEntries.length} items',
          addButtonLabel: 'Add Safety Item',
          columns: const ['#', 'Department', 'Team Member', 'Safety Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
          rows: _rowsFor(_safetyEntries),
          onFullView: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SafetyFullViewScreen(
                  columns: const ['#', 'Department', 'Team Member', 'Safety Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
                  initialRows: _rowsFor(_safetyEntries),
                  accentColor: _safetyAccent,
                  detailsText: 'Comprehensive safety protocols including personal protective equipment requirements, emergency evacuation procedures, incident reporting systems , and regular safety training programs for all personnel .',
                  onAddItem: (input) {
                    _addEntry(_SsherCategory.safety, input);
                  },
                ),
              ),
            );
          },
          onAdd: _onAddSafetyItem,
        ),

        // Security (full table from page 2)
        SsherSectionCard(
          leadingIcon: Icons.shield_outlined,
          accentColor: _securityAccent,
          title: 'Security',
          subtitle: 'Physical and cyber security measures',
          detailsPlaceholder:
              'Multi- layered security approach including physical access controls, cybersecurity measures, surveillance systems, and incident response',
          itemsLabel: '${_securityEntries.length} items',
          addButtonLabel: 'Add Security Item',
          columns: const ['#', 'Department', 'Team Member', 'Security Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
          rows: _rowsFor(_securityEntries),
          onAdd: _onAddSecurityItem,
        ),

        // Health (from page 2/3)
        SsherSectionCard(
          leadingIcon: Icons.volunteer_activism_outlined,
          accentColor: _healthAccent,
          title: 'Health',
          subtitle: 'Occupational health and wellness programs',
          detailsPlaceholder:
              'Multi- layered security approach including physical access controls, cybersecurity measures, surveillance systems, and incident response',
          itemsLabel: '${_healthEntries.length} items',
          addButtonLabel: 'Add Health Item',
          columns: const ['#', 'Department', 'Team Member', 'Health Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
          rows: _rowsFor(_healthEntries),
          onAdd: _onAddHealthItem,
        ),

        // Environment (from page 3)
        SsherSectionCard(
          leadingIcon: Icons.eco_outlined,
          accentColor: _environmentAccent,
          title: 'Environment',
          subtitle: 'Environmental sustainability and compliance',
          detailsPlaceholder:
              'Environmental stewardship program including waste reduction initiatives, energy efficiency measures, carbon footprint monitoring, and sustainable resource management. Regular environmental impact assessments ensure compliance with regulations .',
          itemsLabel: '${_environmentEntries.length} items',
          addButtonLabel: 'Add Environment Item',
          columns: const ['#', 'Department', 'Team Member', 'Environmental Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
          rows: _rowsFor(_environmentEntries),
          onAdd: _onAddEnvironmentItem,
        ),

        // Regulatory (from page 4)
        SsherSectionCard(
          leadingIcon: Icons.gavel_outlined,
          accentColor: _regulatoryAccent,
          title: 'Regulatory',
          subtitle: 'Compliance and regulatory requirements',
          detailsPlaceholder:
              'EComprehensive regulatory compliance framework ensuring adherence to industry standards, legal requirements, and best practices. Regular audits documentation',
          itemsLabel: '${_regulatoryEntries.length} items',
          addButtonLabel: 'Add Regulatory Item',
          columns: const ['#', 'Department', 'Team Member', 'Regulatory Requirement', 'Risk Level', 'Mitigation Strategy', 'Actions'],
          rows: _rowsFor(_regulatoryEntries),
          onAdd: _onAddRegulatoryItem,
        ),

        const SizedBox(height: 16),
        LaunchPhaseNavigation(
          backLabel: 'Back: Project Management Framework',
          nextLabel: 'Next: Change Management',
          onBack: () => Navigator.of(context).maybePop(),
          onNext: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangeManagementScreen())),
        ),
      ]),
    );
  }
}
