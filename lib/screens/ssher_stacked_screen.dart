import 'package:flutter/material.dart';
import 'package:ndu_project/screens/ssher_add_safety_item_dialog.dart';
import 'package:ndu_project/screens/ssher_category_full_view.dart';
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
import 'package:ndu_project/utils/ssher_export_helper.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/utils/web_utils_stub.dart'
    if (dart.library.html) 'package:ndu_project/utils/web_utils_web.dart';

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
      _safetyEntries = entries
          .where((e) => e.category == _categoryKey(_SsherCategory.safety))
          .toList();
      _securityEntries = entries
          .where((e) => e.category == _categoryKey(_SsherCategory.security))
          .toList();
      _healthEntries = entries
          .where((e) => e.category == _categoryKey(_SsherCategory.health))
          .toList();
      _environmentEntries = entries
          .where((e) => e.category == _categoryKey(_SsherCategory.environment))
          .toList();
      _regulatoryEntries = entries
          .where((e) => e.category == _categoryKey(_SsherCategory.regulatory))
          .toList();
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
    final contextText =
        ProjectDataHelper.buildFepContext(projectData, sectionLabel: 'SSHER');
    if (contextText.trim().isEmpty) {
      _entriesGenerated = true;
      return;
    }

    setState(() => _isGeneratingEntries = true);

    List<SsherEntry> generatedEntries = [];
    try {
      generatedEntries = await OpenAiServiceSecure()
          .generateSsherEntries(context: contextText, itemsPerCategory: 2);
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

    final contextText =
        ProjectDataHelper.buildFepContext(projectData, sectionLabel: 'SSHER');
    if (contextText.trim().isEmpty) {
      setState(() => _summaryLoaded = true);
      return;
    }

    setState(() => _isGeneratingSummary = true);

    String summary = '';
    try {
      summary = await OpenAiServiceSecure()
          .generateSsherPlanSummary(context: contextText);
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

  Future<void> _deleteEntry(SsherEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        if (entry.category == 'safety') {
          _safetyEntries.removeWhere((e) => e.id == entry.id);
        }
        if (entry.category == 'security') {
          _securityEntries.removeWhere((e) => e.id == entry.id);
        }
        if (entry.category == 'health') {
          _healthEntries.removeWhere((e) => e.id == entry.id);
        }
        if (entry.category == 'environment') {
          _environmentEntries.removeWhere((e) => e.id == entry.id);
        }
        if (entry.category == 'regulatory') {
          _regulatoryEntries.removeWhere((e) => e.id == entry.id);
        }
      });
      await _saveEntries();
    }
  }

  Future<void> _editEntry(SsherEntry entry) async {
    Color accentColor;
    IconData icon;
    String heading;
    String blurb;
    String concernLabel;

    switch (entry.category) {
      case 'safety':
        accentColor = _safetyAccent;
        icon = Icons.health_and_safety;
        heading = 'Edit Safety Item';
        blurb = 'Update details for the safety record.';
        concernLabel = 'Safety Concern';
        break;
      case 'security':
        accentColor = _securityAccent;
        icon = Icons.shield_outlined;
        heading = 'Edit Security Item';
        blurb = 'Update the security exposure details.';
        concernLabel = 'Security Concern';
        break;
      case 'health':
        accentColor = _healthAccent;
        icon = Icons.volunteer_activism_outlined;
        heading = 'Edit Health Item';
        blurb = 'Update the health-related concern.';
        concernLabel = 'Health Concern';
        break;
      case 'environment':
        accentColor = _environmentAccent;
        icon = Icons.eco_outlined;
        heading = 'Edit Environment Item';
        blurb = 'Update log of environmental impact.';
        concernLabel = 'Environmental Concern';
        break;
      case 'regulatory':
        accentColor = _regulatoryAccent;
        icon = Icons.gavel_outlined;
        heading = 'Edit Regulatory Item';
        blurb = 'Update compliance requirement details.';
        concernLabel = 'Regulatory Requirement';
        break;
      default:
        return;
    }

    final input = await showDialog<SsherItemInput>(
      context: context,
      builder: (ctx) => AddSsherItemDialog(
        accentColor: accentColor,
        icon: icon,
        heading: heading,
        blurb: blurb,
        concernLabel: concernLabel,
        saveButtonLabel: 'Save Changes',
        initialData: SsherItemInput(
          department: entry.department,
          teamMember: entry.teamMember,
          concern: entry.concern,
          riskLevel: entry.riskLevel,
          mitigation: entry.mitigation,
        ),
      ),
    );

    if (input == null) return;

    setState(() {
      entry.department = input.department;
      entry.teamMember = input.teamMember;
      entry.concern = input.concern;
      entry.riskLevel = input.riskLevel;
      entry.mitigation = input.mitigation;
    });
    await _saveEntries();
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

  Future<void> _downloadCategory(_SsherCategory category) async {
    final isAdmin = await UserService.isCurrentUserAdmin();
    final hostname = getCurrentHostname() ?? '';
    final allowCsv = isAdmin && hostname.startsWith('admin.');

    if (allowCsv) {
      final entries = _entriesForCategory(category);
      final csv = SsherExportHelper.entriesToCsv(entries,
          categoryTitle: category.name.toUpperCase());
      await SsherExportHelper.downloadCsv(csv, 'ssher_${category.name}.csv');
    } else {
      await SsherExportHelper.exportToPdf(_entriesForCategory(category), categoryTitle: category.name.toUpperCase());
    }
  }

  Future<void> _downloadAll() async {
    final isAdmin = await UserService.isCurrentUserAdmin();
    final hostname = getCurrentHostname() ?? '';
    final allowCsv = isAdmin && hostname.startsWith('admin.');

    final map = {
      'SAFETY': _safetyEntries,
      'SECURITY': _securityEntries,
      'HEALTH': _healthEntries,
      'ENVIRONMENT': _environmentEntries,
      'REGULATORY': _regulatoryEntries,
    };

    if (allowCsv) {
      final csv = SsherExportHelper.allEntriesToCsv(map);
      await SsherExportHelper.downloadCsv(csv, 'ssher_all_categories.csv');
    } else {
      await SsherExportHelper.exportAllToPdf(map);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<bool>(
          stream: UserService.watchAdminStatus(),
          builder: (context, snapshot) {
            final isAdmin = snapshot.data ?? false;
            final hostname = getCurrentHostname() ?? '';
            final allowCsv = isAdmin && hostname.startsWith('admin.');

            return Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DraggableSidebar(
                      openWidth: AppBreakpoints.sidebarWidth(context),
                      child: const InitiationLikeSidebar(activeItemLabel: 'SSHER'),
                    ),
                    Expanded(
                      child: DefaultTabController(
                        length: 5,
                        child: _buildMainContent(const EdgeInsets.all(24), allowCsv: allowCsv),
                      ),
                    ),
                  ],
                ),
                const KazAiChatBubble(),
                const AdminEditToggle(),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildMainContent(EdgeInsetsGeometry padding, {required bool allowCsv}) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SSHER Planning',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _downloadAll,
                      icon: Icon(allowCsv ? Icons.download_for_offline : Icons.picture_as_pdf),
                      label: Text(allowCsv ? 'Download All (CSV)' : 'Download All (PDF)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const PlanningAiNotesCard(
                  title: 'Notes',
                  sectionLabel: 'SSHER',
                  noteKey: 'planning_ssher_notes',
                  checkpoint: 'ssher',
                  description:
                      'Summarize key SSHER risks, mitigation plans, and compliance requirements.',
                ),
                const SizedBox(height: 20),
                // Plan Summary
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.receipt_long,
                              size: 18, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: EditableContentText(
                            contentKey: 'ssher_plan_summary_title',
                            fallback: 'SSHER Plan Summary',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
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
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.25)),
                      ),
                      child: EditableContentText(
                        contentKey: 'ssher_plan_summary_description',
                        fallback:
                            'This SSHER plan encompasses comprehensive risk management across all operational domains.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        category: 'ssher',
                      ),
                    ),
                  ]),
                ),

                if (_isGeneratingSummary)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                'AI is preparing a tailored SSHER summary...',
                                style: TextStyle(
                                    color: Colors.blue, fontSize: 13))),
                      ],
                    ),
                  )
                else if (_aiPlanSummary.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI-generated SSHER Summary',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(_aiPlanSummary,
                            style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                                height: 1.5)),
                      ],
                    ),
                  ),
              ]),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: 'Safety', icon: Icon(Icons.health_and_safety)),
                  Tab(text: 'Security', icon: Icon(Icons.shield_outlined)),
                  Tab(
                      text: 'Health',
                      icon: Icon(Icons.volunteer_activism_outlined)),
                  Tab(text: 'Environment', icon: Icon(Icons.eco_outlined)),
                  Tab(text: 'Regulatory', icon: Icon(Icons.gavel_outlined)),
                ],
              ),
            ),
          ),
        ];
      },
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
             children: [
                _buildTab(
                    _SsherCategory.safety,
                    'Safety',
                    'Workplace safety protocols',
                    _safetyAccent,
                    Icons.health_and_safety,
                    'Comprehensive safety protocols including personal protective equipment requirements, emergency evacuation procedures, incident reporting systems, and regular safety training programs for all personnel.',
                    allowCsv: allowCsv),
                _buildTab(
                    _SsherCategory.security,
                    'Security',
                    'Physical and cyber security',
                    _securityAccent,
                    Icons.shield_outlined,
                    'Multi-layered security approach including physical access controls, cybersecurity measures, surveillance systems, and incident response.',
                    allowCsv: allowCsv),
                _buildTab(
                    _SsherCategory.health,
                    'Health',
                    'Occupational health programs',
                    _healthAccent,
                    Icons.volunteer_activism_outlined,
                    'Occupational health standards including ergonomic assessments, wellness programs, medical surveillance, and mental health support initiatives.',
                    allowCsv: allowCsv),
                _buildTab(
                    _SsherCategory.environment,
                    'Environment',
                    'Environmental sustainability',
                    _environmentAccent,
                    Icons.eco_outlined,
                    'Environmental stewardship program including waste reduction initiatives, energy efficiency measures, carbon footprint monitoring, and sustainable resource management.',
                    allowCsv: allowCsv),
                _buildTab(
                    _SsherCategory.regulatory,
                    'Regulatory',
                    'Compliance requirements',
                    _regulatoryAccent,
                    Icons.gavel_outlined,
                    'Comprehensive regulatory compliance framework ensuring adherence to industry standards, legal requirements, and best practices.',
                    allowCsv: allowCsv),
              ],
            ),
          ),
          // Navigation
          Padding(
            padding: const EdgeInsets.all(24),
            child: LaunchPhaseNavigation(
              backLabel: 'Back',
              nextLabel: 'Next',
              onBack: () {
                final navIndex = PlanningPhaseNavigation.getPageIndex('ssher');
                if (navIndex > 0) {
                  final prevPage = PlanningPhaseNavigation.pages[navIndex - 1];
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: prevPage.builder));
                } else {
                  Navigator.maybePop(context);
                }
              },
              onNext: () {
                 final navIndex = PlanningPhaseNavigation.getPageIndex('ssher');
                 if (navIndex != -1 && navIndex < PlanningPhaseNavigation.pages.length - 1) {
                   final nextPage = PlanningPhaseNavigation.pages[navIndex + 1];
                   Navigator.pushReplacement(context, MaterialPageRoute(builder: nextPage.builder));
                 } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No next screen available')));
                 }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(_SsherCategory category, String title, String subtitle,
      Color accent, IconData icon, String details, {required bool allowCsv}) {
    return SsherCategoryFullView(
      title: title,
      subtitle: subtitle,
      icon: icon,
      accentColor: accent,
      detailsText: details,
      allowCsv: allowCsv,
      columns: const [
        '#',
        'Department',
        'Team Member',
        'Concern',
        'Risk Level',
        'Mitigation Strategy',
        'Actions'
      ],
      entries: _entriesForCategory(category),
      addButtonLabel: 'Add $title Item',
      concernLabel: '$title Concern',
      onAddItem: (input) => _addEntry(category, input),
      onEditItem: _editEntry,
      onDeleteItem: _deleteEntry,
      onDownload: () => _downloadCategory(category),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
