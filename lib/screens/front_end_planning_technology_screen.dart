import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/user_access_chip.dart';
import 'package:ndu_project/widgets/premium_edit_dialog.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/screens/interface_management_screen.dart';
import 'package:ndu_project/models/project_data_model.dart';

/// Technology – Planning Dashboard
/// World‑class UX matching the provided design:
/// - Summary cards: Total Items, Total Technology Budget, AI Integrations
/// - Segmented tabs: Technology Inventory, AI Integrations, External Integrations,
///   Technology Definitions, AI Recommendations (default)
/// - Search + Category filter row
/// - AI recommendations panel and recommended items
/// - Bottom overlays: subtle AI hint + Next button to Technology Personnel
class FrontEndPlanningTechnologyScreen extends StatefulWidget {
  const FrontEndPlanningTechnologyScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const FrontEndPlanningTechnologyScreen()),
    );
  }

  // Clean seed data avoiding any encoding issues with currency symbols
  List<_TechItem> _seedItemsClean() {
    return [
      _TechItem(
        name: 'Development Workstation',
        description:
            'High-performance developer workstation with dual monitors',
        categoryName: 'Hardware',
        categorySub: 'Workstation',
        icon: Icons.desktop_windows_outlined,
        vendor: 'Dell',
        costText: '\$2,500 (one-time)',
        status: 'Deployed',
        addedDate: '2025-02-15',
        addedTeam: 'IT Department',
        tags: const ['development', 'hardware'],
      ),
      _TechItem(
        name: 'Figma Professional',
        description: 'UI/UX design software subscription.',
        categoryName: 'Software',
        categorySub: 'Design',
        icon: Icons.design_services_outlined,
        vendor: 'Figma',
        costText: '\$45/month',
        status: 'Deployed',
        addedDate: '2025-01-10',
        addedTeam: 'Design Team',
        tags: const ['design', 'UI/UX'],
      ),
      _TechItem(
        name: 'Jira Software',
        description: 'Project tracking and agile delivery workspace.',
        categoryName: 'Software',
        categorySub: 'Project Management',
        icon: Icons.assignment_outlined,
        vendor: 'Atlassian',
        costText: '\$140/month',
        status: 'Deployed',
        addedDate: '2025-02-01',
        addedTeam: 'Product Team',
        tags: const ['planning', 'agile'],
      ),
      _TechItem(
        name: 'GitHub Enterprise',
        description: 'Source code management and CI/CD platform',
        categoryName: 'Devtools',
        categorySub: 'Version Control',
        icon: Icons.code_outlined,
        vendor: 'GitHub',
        costText: '\$252/month',
        status: 'Deployed',
        addedDate: '2024-12-05',
        addedTeam: 'Development Team',
        tags: const ['devops', 'version control'],
      ),
      _TechItem(
        name: 'Cloud Server Infrastructure',
        description: 'Producing and staging environments on AWS',
        categoryName: 'Hardware',
        categorySub: 'Cloud',
        icon: Icons.cloud_outlined,
        vendor: 'AWS',
        costText: '\$1,500/month',
        status: 'Deployed',
        addedDate: '2025-01-20',
        addedTeam: 'IT Department',
        tags: const ['cloud', 'infrastructure'],
      ),
    ];
  }

  @override
  State<FrontEndPlanningTechnologyScreen> createState() =>
      _FrontEndPlanningTechnologyScreenState();
}

class _FrontEndPlanningTechnologyScreenState
    extends State<FrontEndPlanningTechnologyScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _activeTab = 4; // 4 = AI Recommendations
  String _category = 'All Categories';
  bool _isGeneratingRecommendations = false;

  late List<_TechItem> _items;
  late List<_AiRecommendation> _aiRecommendations;
  late List<_AiIntegrationItem> _aiIntegrations;
  late List<_ExternalIntegrationItem> _externalIntegrations;
  late List<_TechnologyDefinitionItem> _techDefinitions;

  static const String _kInventoryKey = 'technology_inventory_items';
  static const String _kAiRecommendationsKey = 'technology_ai_recommendations';
  static const String _kAiIntegrationsKey = 'technology_ai_integrations';
  static const String _kExternalIntegrationsKey =
      'technology_external_integrations';
  static const String _kDefinitionsKey = 'technology_definitions';

  @override
  void initState() {
    super.initState();
    _items = [];
    _aiRecommendations = [];
    _aiIntegrations = [];
    _externalIntegrations = [];
    _techDefinitions = [];
    _searchCtrl.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPersistedData());
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_handleSearchChanged);
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Technology'),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    children: [
                      // Page top bar matching the mock (back/forward + title + user chip)
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: _TopBar(),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              const PlanningAiNotesCard(
                                title: 'Notes',
                                sectionLabel: 'Technology',
                                noteKey: 'planning_technology_notes',
                                checkpoint: 'technology',
                                description:
                                    'Summarize technology decisions, integrations, and budget assumptions.',
                              ),
                              const SizedBox(height: 24),
                              _SummaryRow2(
                                items: _items,
                                aiIntegrations: _aiIntegrations,
                                aiRecommendations: _aiRecommendations,
                              ),
                              const SizedBox(height: 20),
                              _Tabs(
                                  active: _activeTab,
                                  onChanged: _handleTabChanged),
                              const SizedBox(height: 12),
                              _TabActionsBar(
                                activeTab: _activeTab,
                                isLoadingRecommendations:
                                    _isGeneratingRecommendations,
                                onAddInventory: _addInventoryItem,
                                onAddAiIntegration: _addAiIntegration,
                                onAddExternalIntegration:
                                    _addExternalIntegration,
                                onAddDefinition: _addTechDefinition,
                                onAddRecommendation: _generateAiRecommendations,
                              ),
                              const SizedBox(height: 18),
                              if (_activeTab == 0) ...[
                                _InventoryTable(
                                  items: _filteredItems(),
                                  onEdit: _editInventoryItem,
                                  onDelete: _deleteInventoryItem,
                                ),
                              ] else if (_activeTab == 1) ...[
                                _AiIntegrationsView(
                                  items: _filteredAiIntegrations(),
                                  onEdit: _editAiIntegration,
                                  onDelete: _deleteAiIntegration,
                                ),
                              ] else if (_activeTab == 2) ...[
                                _ExternalIntegrationsView(
                                  items: _filteredExternalIntegrations(),
                                  onEdit: _editExternalIntegration,
                                  onDelete: _deleteExternalIntegration,
                                ),
                              ] else if (_activeTab == 3) ...[
                                _TechnologyDefinitionsView(
                                  items: _filteredTechDefinitions(),
                                  onEdit: _editTechDefinition,
                                  onDelete: _deleteTechDefinition,
                                ),
                              ] else if (_activeTab == 4) ...[
                                _AiRecommendationsView(
                                  recommendations: _aiRecommendations,
                                  onEdit: _editAiRecommendation,
                                  onDelete: _deleteAiRecommendation,
                                  onImplement: _applyRecommendationToInventory,
                                ),
                              ],
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const AdminEditToggle(),
                  const _BottomOverlays(),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_TechItem> _filteredItems() {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _items.where((e) {
      final matchQuery = q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          e.tags.any((t) => t.toLowerCase().contains(q));
      final matchCat =
          _category == 'All Categories' || _category == e.categoryName;
      return matchQuery && matchCat;
    }).toList();
  }

  List<String> _categoryOptionsForTab(int tab) {
    switch (tab) {
      case 1:
        return const [
          'All Categories',
          'NLP',
          'Vision',
          'Automation',
          'Analytics'
        ];
      case 2:
        return const [
          'All Categories',
          'Payments',
          'CRM',
          'ERP',
          'Logistics',
          'Analytics'
        ];
      case 3:
        return const ['All Categories'];
      case 4:
        return const ['All Categories'];
      default:
        return const ['All Categories', 'Hardware', 'Software', 'Devtools'];
    }
  }

  void _handleTabChanged(int i) {
    final options = _categoryOptionsForTab(i);
    setState(() {
      _activeTab = i;
      if (!options.contains(_category)) {
        _category = options.first;
      }
    });
  }

  void _handleSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _today() => DateTime.now().toIso8601String().split('T').first;

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  List<AiSolutionItem> _buildSolutionItems(ProjectDataModel data) {
    final potential = data.potentialSolutions
        .map((s) => AiSolutionItem(
            title: s.title.trim(), description: s.description.trim()))
        .where((s) => s.title.isNotEmpty || s.description.isNotEmpty)
        .toList();
    if (potential.isNotEmpty) return potential;

    final preferred = data.preferredSolutionAnalysis?.solutionAnalyses
            .map((s) => AiSolutionItem(
                  title: s.solutionTitle.trim(),
                  description: s.solutionDescription.trim(),
                ))
            .where((s) => s.title.isNotEmpty || s.description.isNotEmpty)
            .toList() ??
        [];
    if (preferred.isNotEmpty) return preferred;

    final fallbackTitle = data.solutionTitle.trim();
    final fallbackDescription = data.solutionDescription.trim();
    if (fallbackTitle.isNotEmpty || fallbackDescription.isNotEmpty) {
      return [
        AiSolutionItem(title: fallbackTitle, description: fallbackDescription)
      ];
    }
    return [];
  }

  Future<void> _persistTechnologyData() async {
    final provider = ProjectDataHelper.getProvider(context);
    final notes = {
      ...provider.projectData.planningNotes,
      _kInventoryKey: _encodeList(_items, (item) => item.toJson()),
      _kAiRecommendationsKey:
          _encodeList(_aiRecommendations, (item) => item.toJson()),
      _kAiIntegrationsKey:
          _encodeList(_aiIntegrations, (item) => item.toJson()),
      _kExternalIntegrationsKey:
          _encodeList(_externalIntegrations, (item) => item.toJson()),
      _kDefinitionsKey: _encodeList(_techDefinitions, (item) => item.toJson()),
    };
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'technology',
      dataUpdater: (d) => d.copyWith(planningNotes: notes),
      showSnackbar: false,
    );
  }

  IconData _iconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'hardware':
        return Icons.memory_outlined;
      case 'software':
        return Icons.apps_outlined;
      case 'devtools':
        return Icons.developer_mode_outlined;
      default:
        return Icons.grid_view_outlined;
    }
  }

  void _addInventoryItem() => _showInventoryDialog();
  void _editInventoryItem(_TechItem item) =>
      _showInventoryDialog(existing: item);
  void _deleteInventoryItem(_TechItem item) async {
    setState(() => _items.remove(item));
    await _persistTechnologyData();
  }

  void _addAiIntegration() => _showAiIntegrationDialog();
  void _editAiIntegration(_AiIntegrationItem item) =>
      _showAiIntegrationDialog(existing: item);
  void _deleteAiIntegration(_AiIntegrationItem item) async {
    setState(() => _aiIntegrations.remove(item));
    await _persistTechnologyData();
  }

  void _addExternalIntegration() => _showExternalIntegrationDialog();
  void _editExternalIntegration(_ExternalIntegrationItem item) =>
      _showExternalIntegrationDialog(existing: item);
  void _deleteExternalIntegration(_ExternalIntegrationItem item) async {
    setState(() => _externalIntegrations.remove(item));
    await _persistTechnologyData();
  }

  void _addTechDefinition() => _showDefinitionDialog();
  void _editTechDefinition(_TechnologyDefinitionItem item) =>
      _showDefinitionDialog(existing: item);
  void _deleteTechDefinition(_TechnologyDefinitionItem item) async {
    setState(() => _techDefinitions.remove(item));
    await _persistTechnologyData();
  }

  // ignore: unused_element
  void _addAiRecommendation() => _showRecommendationDialog();
  void _editAiRecommendation(_AiRecommendation item) =>
      _showRecommendationDialog(existing: item);
  void _deleteAiRecommendation(_AiRecommendation item) async {
    setState(() => _aiRecommendations.remove(item));
    await _persistTechnologyData();
  }

  Future<void> _generateAiRecommendations() async {
    if (_isGeneratingRecommendations) return;
    final messenger = ScaffoldMessenger.of(context);
    final data = ProjectDataHelper.getProvider(context).projectData;
    final solutions = _buildSolutionItems(data);
    if (solutions.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
            content:
                Text('Add project solutions to generate AI recommendations.')),
      );
      return;
    }
    setState(() => _isGeneratingRecommendations = true);
    try {
      final contextNotes =
          ProjectDataHelper.buildFepContext(data, sectionLabel: 'Technology');
      final map = await OpenAiServiceSecure().generateTechnologiesForSolutions(
        solutions,
        contextNotes: contextNotes,
      );
      if (!mounted) return;
      final generated = <_AiRecommendation>[];
      for (final entry in map.entries) {
        for (final tech in entry.value) {
          generated.add(_AiRecommendation(
            title: tech,
            description:
                'Recommended for ${entry.key.isNotEmpty ? entry.key : 'this solution'} based on project context.',
            estimatedCost: 'TBD',
            vendor: 'TBD',
            benefits: const [
              'Aligns with project requirements',
              'Supports delivery efficiency',
            ],
          ));
        }
      }
      if (generated.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No AI recommendations returned.')),
        );
      } else {
        setState(() => _aiRecommendations = generated);
        await _persistTechnologyData();
        if (!mounted) return;
        _scrollToTop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to generate AI recommendations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingRecommendations = false);
      }
    }
  }

  void _applyRecommendationToInventory(_AiRecommendation rec) async {
    final item = _TechItem(
      name: rec.title,
      description: rec.description,
      categoryName: 'Software',
      categorySub: 'AI',
      icon: _iconForCategory('Software'),
      vendor: rec.vendor,
      costText: rec.estimatedCost,
      status: 'Proposed',
      addedDate: _today(),
      addedTeam: 'Technology',
      tags: const ['ai', 'recommendation'],
    );
    setState(() => _items.insert(0, item));
    await _persistTechnologyData();
    _scrollToTop();
  }

  Future<void> _showInventoryDialog({_TechItem? existing}) async {
    if (!mounted) return;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String categoryName = existing?.categoryName ?? 'Software';
    const categoryOptions = ['Hardware', 'Software', 'Devtools', 'Other'];
    final categorySubCtrl =
        TextEditingController(text: existing?.categorySub ?? '');
    final vendorCtrl = TextEditingController(text: existing?.vendor ?? '');
    final costCtrl = TextEditingController(text: existing?.costText ?? '');
    final statusCtrl = TextEditingController(text: existing?.status ?? '');
    final addedDateCtrl =
        TextEditingController(text: existing?.addedDate ?? _today());
    final addedTeamCtrl =
        TextEditingController(text: existing?.addedTeam ?? '');
    final tagsCtrl = TextEditingController(
        text: existing == null ? '' : existing.tags.join(', '));

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => PremiumEditDialog(
          title:
              existing == null ? 'Add Technology Item' : 'Edit Technology Item',
          icon: Icons.settings_outlined,
          onSave: () async {
            final normalizedCategory = categoryOptions.contains(categoryName)
                ? categoryName
                : 'Software';
            final item = _TechItem(
              name: nameCtrl.text.trim(),
              description: descCtrl.text.trim(),
              categoryName: normalizedCategory,
              categorySub: categorySubCtrl.text.trim(),
              icon: _iconForCategory(normalizedCategory),
              vendor: vendorCtrl.text.trim(),
              costText: costCtrl.text.trim(),
              status: statusCtrl.text.trim(),
              addedDate: addedDateCtrl.text.trim(),
              addedTeam: addedTeamCtrl.text.trim(),
              tags: tagsCtrl.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList(),
            );
            Navigator.pop(dialogContext);
            setState(() {
              if (existing != null) {
                final idx = _items.indexOf(existing);
                if (idx != -1) _items[idx] = item;
              } else {
                _items.insert(0, item);
              }
            });
            await _persistTechnologyData();
            _scrollToTop();
          },
          children: [
            PremiumEditDialog.fieldLabel('Name'),
            PremiumEditDialog.textField(
                controller: nameCtrl, hint: 'Item name'),
            const SizedBox(height: 12),
            PremiumEditDialog.fieldLabel('Description'),
            PremiumEditDialog.textField(
                controller: descCtrl, hint: 'Short description', maxLines: 3),
            const SizedBox(height: 12),
            PremiumEditDialog.fieldLabel('Category'),
            DropdownButtonFormField<String>(
              initialValue:
                  categoryOptions.contains(categoryName) ? categoryName : null,
              items: categoryOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) =>
                  setDialogState(() => categoryName = v ?? categoryName),
              hint: const Text('Select category'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            PremiumEditDialog.fieldLabel('Category Detail'),
            PremiumEditDialog.textField(
                controller: categorySubCtrl, hint: 'Sub-category'),
            const SizedBox(height: 12),
            PremiumEditDialog.fieldLabel('Vendor'),
            PremiumEditDialog.textField(controller: vendorCtrl, hint: 'Vendor'),
            const SizedBox(height: 12),
            PremiumEditDialog.fieldLabel('Cost'),
            PremiumEditDialog.textField(controller: costCtrl, hint: 'Cost'),
            const SizedBox(height: 12),
            PremiumEditDialog.fieldLabel('Status'),
            PremiumEditDialog.textField(controller: statusCtrl, hint: 'Status'),
            const SizedBox(height: 12),
            PremiumEditDialog.fieldLabel('Added Date'),
            PremiumEditDialog.textField(
                controller: addedDateCtrl, hint: 'YYYY-MM-DD'),
            const SizedBox(height: 12),
            PremiumEditDialog.fieldLabel('Added Team'),
            PremiumEditDialog.textField(
                controller: addedTeamCtrl, hint: 'Team'),
            const SizedBox(height: 12),
            PremiumEditDialog.fieldLabel('Tags (comma-separated)'),
            PremiumEditDialog.textField(
                controller: tagsCtrl, hint: 'tag1, tag2'),
          ],
        ),
      ),
    );
  }

  Future<void> _showAiIntegrationDialog({_AiIntegrationItem? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final summaryCtrl = TextEditingController(text: existing?.summary ?? '');
    final modelCtrl = TextEditingController(text: existing?.model ?? '');
    final statusCtrl = TextEditingController(text: existing?.status ?? '');
    final ownerCtrl = TextEditingController(text: existing?.owner ?? '');
    final latencyCtrl = TextEditingController(text: existing?.latency ?? '');
    final costCtrl = TextEditingController(text: existing?.monthlyCost ?? '');
    final categoryCtrl = TextEditingController(text: existing?.category ?? '');
    final tagsCtrl = TextEditingController(
        text: existing == null ? '' : existing.tags.join(', '));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => PremiumEditDialog(
        title: existing == null ? 'Add AI Integration' : 'Edit AI Integration',
        icon: Icons.auto_awesome,
        onSave: () async {
          final item = _AiIntegrationItem(
            name: nameCtrl.text.trim(),
            summary: summaryCtrl.text.trim(),
            model: modelCtrl.text.trim(),
            status: statusCtrl.text.trim(),
            owner: ownerCtrl.text.trim(),
            latency: latencyCtrl.text.trim(),
            monthlyCost: costCtrl.text.trim(),
            category: categoryCtrl.text.trim(),
            tags: tagsCtrl.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList(),
          );
          Navigator.pop(dialogContext);
          setState(() {
            if (existing != null) {
              final idx = _aiIntegrations.indexOf(existing);
              if (idx != -1) _aiIntegrations[idx] = item;
            } else {
              _aiIntegrations.insert(0, item);
            }
          });
          await _persistTechnologyData();
          _scrollToTop();
        },
        children: [
          PremiumEditDialog.fieldLabel('Name'),
          PremiumEditDialog.textField(controller: nameCtrl, hint: 'Name'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Summary'),
          PremiumEditDialog.textField(
              controller: summaryCtrl, hint: 'Summary', maxLines: 3),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Model'),
          PremiumEditDialog.textField(controller: modelCtrl, hint: 'Model'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Status'),
          PremiumEditDialog.textField(controller: statusCtrl, hint: 'Status'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Owner'),
          PremiumEditDialog.textField(controller: ownerCtrl, hint: 'Owner'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Latency'),
          PremiumEditDialog.textField(controller: latencyCtrl, hint: 'Latency'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Monthly Cost'),
          PremiumEditDialog.textField(controller: costCtrl, hint: 'Cost'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Category'),
          PremiumEditDialog.textField(
              controller: categoryCtrl, hint: 'Category'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Tags (comma-separated)'),
          PremiumEditDialog.textField(controller: tagsCtrl, hint: 'tag1, tag2'),
        ],
      ),
    );
  }

  Future<void> _showExternalIntegrationDialog(
      {_ExternalIntegrationItem? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final summaryCtrl = TextEditingController(text: existing?.summary ?? '');
    final vendorCtrl = TextEditingController(text: existing?.vendor ?? '');
    final statusCtrl = TextEditingController(text: existing?.status ?? '');
    final slaCtrl = TextEditingController(text: existing?.sla ?? '');
    final dataFlowCtrl = TextEditingController(text: existing?.dataFlow ?? '');
    final lastSyncCtrl = TextEditingController(text: existing?.lastSync ?? '');
    final ownerCtrl = TextEditingController(text: existing?.owner ?? '');
    final categoryCtrl = TextEditingController(text: existing?.category ?? '');
    final tagsCtrl = TextEditingController(
        text: existing == null ? '' : existing.tags.join(', '));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => PremiumEditDialog(
        title: existing == null
            ? 'Add External Integration'
            : 'Edit External Integration',
        icon: Icons.link,
        onSave: () async {
          final item = _ExternalIntegrationItem(
            name: nameCtrl.text.trim(),
            summary: summaryCtrl.text.trim(),
            vendor: vendorCtrl.text.trim(),
            status: statusCtrl.text.trim(),
            sla: slaCtrl.text.trim(),
            dataFlow: dataFlowCtrl.text.trim(),
            lastSync: lastSyncCtrl.text.trim(),
            owner: ownerCtrl.text.trim(),
            category: categoryCtrl.text.trim(),
            tags: tagsCtrl.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList(),
          );
          Navigator.pop(dialogContext);
          setState(() {
            if (existing != null) {
              final idx = _externalIntegrations.indexOf(existing);
              if (idx != -1) _externalIntegrations[idx] = item;
            } else {
              _externalIntegrations.insert(0, item);
            }
          });
          await _persistTechnologyData();
          _scrollToTop();
        },
        children: [
          PremiumEditDialog.fieldLabel('Name'),
          PremiumEditDialog.textField(controller: nameCtrl, hint: 'Name'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Summary'),
          PremiumEditDialog.textField(
              controller: summaryCtrl, hint: 'Summary', maxLines: 3),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Vendor'),
          PremiumEditDialog.textField(controller: vendorCtrl, hint: 'Vendor'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Status'),
          PremiumEditDialog.textField(controller: statusCtrl, hint: 'Status'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('SLA'),
          PremiumEditDialog.textField(controller: slaCtrl, hint: 'SLA'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Data Flow'),
          PremiumEditDialog.textField(
              controller: dataFlowCtrl, hint: 'Data flow'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Last Sync'),
          PremiumEditDialog.textField(
              controller: lastSyncCtrl, hint: 'Last sync'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Owner'),
          PremiumEditDialog.textField(controller: ownerCtrl, hint: 'Owner'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Category'),
          PremiumEditDialog.textField(
              controller: categoryCtrl, hint: 'Category'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Tags (comma-separated)'),
          PremiumEditDialog.textField(controller: tagsCtrl, hint: 'tag1, tag2'),
        ],
      ),
    );
  }

  Future<void> _showDefinitionDialog(
      {_TechnologyDefinitionItem? existing}) async {
    final domainCtrl = TextEditingController(text: existing?.domain ?? '');
    final stackCtrl = TextEditingController(text: existing?.stack ?? '');
    final decisionCtrl = TextEditingController(text: existing?.decision ?? '');
    final rationaleCtrl =
        TextEditingController(text: existing?.rationale ?? '');
    final ownerCtrl = TextEditingController(text: existing?.owner ?? '');
    final standardsCtrl = TextEditingController(
        text: existing == null ? '' : existing.standards.join(', '));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => PremiumEditDialog(
        title: existing == null
            ? 'Add Technology Definition'
            : 'Edit Technology Definition',
        icon: Icons.fact_check_outlined,
        onSave: () async {
          final item = _TechnologyDefinitionItem(
            domain: domainCtrl.text.trim(),
            stack: stackCtrl.text.trim(),
            decision: decisionCtrl.text.trim(),
            rationale: rationaleCtrl.text.trim(),
            owner: ownerCtrl.text.trim(),
            standards: standardsCtrl.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList(),
          );
          Navigator.pop(dialogContext);
          setState(() {
            if (existing != null) {
              final idx = _techDefinitions.indexOf(existing);
              if (idx != -1) _techDefinitions[idx] = item;
            } else {
              _techDefinitions.insert(0, item);
            }
          });
          await _persistTechnologyData();
          _scrollToTop();
        },
        children: [
          PremiumEditDialog.fieldLabel('Domain'),
          PremiumEditDialog.textField(controller: domainCtrl, hint: 'Domain'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Stack'),
          PremiumEditDialog.textField(controller: stackCtrl, hint: 'Stack'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Decision'),
          PremiumEditDialog.textField(
              controller: decisionCtrl, hint: 'Decision'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Rationale'),
          PremiumEditDialog.textField(
              controller: rationaleCtrl, hint: 'Rationale', maxLines: 3),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Owner'),
          PremiumEditDialog.textField(controller: ownerCtrl, hint: 'Owner'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Standards (comma-separated)'),
          PremiumEditDialog.textField(
              controller: standardsCtrl, hint: 'standard1, standard2'),
        ],
      ),
    );
  }

  Future<void> _showRecommendationDialog({_AiRecommendation? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final costCtrl = TextEditingController(text: existing?.estimatedCost ?? '');
    final vendorCtrl = TextEditingController(text: existing?.vendor ?? '');
    final benefitsCtrl = TextEditingController(
        text: existing == null ? '' : existing.benefits.join(', '));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => PremiumEditDialog(
        title: existing == null
            ? 'Add AI Recommendation'
            : 'Edit AI Recommendation',
        icon: Icons.auto_awesome,
        onSave: () async {
          final item = _AiRecommendation(
            title: titleCtrl.text.trim(),
            description: descCtrl.text.trim(),
            estimatedCost: costCtrl.text.trim(),
            vendor: vendorCtrl.text.trim(),
            benefits: benefitsCtrl.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList(),
          );
          Navigator.pop(dialogContext);
          setState(() {
            if (existing != null) {
              final idx = _aiRecommendations.indexOf(existing);
              if (idx != -1) _aiRecommendations[idx] = item;
            } else {
              _aiRecommendations.insert(0, item);
            }
          });
          await _persistTechnologyData();
          _scrollToTop();
        },
        children: [
          PremiumEditDialog.fieldLabel('Title'),
          PremiumEditDialog.textField(controller: titleCtrl, hint: 'Title'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Description'),
          PremiumEditDialog.textField(
              controller: descCtrl, hint: 'Description', maxLines: 3),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Estimated Cost'),
          PremiumEditDialog.textField(controller: costCtrl, hint: 'Cost'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Vendor'),
          PremiumEditDialog.textField(controller: vendorCtrl, hint: 'Vendor'),
          const SizedBox(height: 12),
          PremiumEditDialog.fieldLabel('Benefits (comma-separated)'),
          PremiumEditDialog.textField(
              controller: benefitsCtrl, hint: 'benefit1, benefit2'),
        ],
      ),
    );
  }

  List<_AiIntegrationItem> _filteredAiIntegrations() {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _aiIntegrations.where((item) {
      final matchQuery = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.summary.toLowerCase().contains(q) ||
          item.tags.any((t) => t.toLowerCase().contains(q));
      final matchCat =
          _category == 'All Categories' || _category == item.category;
      return matchQuery && matchCat;
    }).toList();
  }

  List<_ExternalIntegrationItem> _filteredExternalIntegrations() {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _externalIntegrations.where((item) {
      final matchQuery = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.summary.toLowerCase().contains(q) ||
          item.tags.any((t) => t.toLowerCase().contains(q));
      final matchCat =
          _category == 'All Categories' || _category == item.category;
      return matchQuery && matchCat;
    }).toList();
  }

  List<_TechnologyDefinitionItem> _filteredTechDefinitions() {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _techDefinitions.where((item) {
      final matchQuery = q.isEmpty ||
          item.domain.toLowerCase().contains(q) ||
          item.decision.toLowerCase().contains(q) ||
          item.stack.toLowerCase().contains(q);
      return matchQuery;
    }).toList();
  }

  List<_AiRecommendation> _seedAiRecommendations() {
    return const [
      _AiRecommendation(
        title: 'Project Management Messaging',
        description:
            'Implement an in-app messaging system for team communication and document collaboration.',
        estimatedCost: '\$2,500 (one-time)',
        vendor: 'TeamChat',
        benefits: [
          'Improved team collaboration',
          'Centralized communication',
          'Document sharing',
        ],
      ),
    ];
  }

  Future<void> _loadPersistedData() async {
    final data = ProjectDataHelper.getData(context, listen: false);
    final notes = data.planningNotes;
    bool needsSave = false;

    final inventoryResult = _decodeList<_TechItem>(
      notes[_kInventoryKey],
      (json) => _TechItem.fromJson(json),
      widget._seedItemsClean(),
    );
    final aiRecResult = _decodeList<_AiRecommendation>(
      notes[_kAiRecommendationsKey],
      (json) => _AiRecommendation.fromJson(json),
      _seedAiRecommendations(),
    );
    final aiIntResult = _decodeList<_AiIntegrationItem>(
      notes[_kAiIntegrationsKey],
      (json) => _AiIntegrationItem.fromJson(json),
      _seedAiIntegrations(),
    );
    final externalResult = _decodeList<_ExternalIntegrationItem>(
      notes[_kExternalIntegrationsKey],
      (json) => _ExternalIntegrationItem.fromJson(json),
      _seedExternalIntegrations(),
    );
    final definitionsResult = _decodeList<_TechnologyDefinitionItem>(
      notes[_kDefinitionsKey],
      (json) => _TechnologyDefinitionItem.fromJson(json),
      _seedTechDefinitions(),
    );

    _items = inventoryResult.items;
    _aiRecommendations = aiRecResult.items;
    _aiIntegrations = aiIntResult.items;
    _externalIntegrations = externalResult.items;
    _techDefinitions = definitionsResult.items;

    needsSave = needsSave ||
        inventoryResult.usedFallback ||
        aiRecResult.usedFallback ||
        aiIntResult.usedFallback ||
        externalResult.usedFallback ||
        definitionsResult.usedFallback;

    if (needsSave) {
      final updatedNotes = {
        ...notes,
        _kInventoryKey: _encodeList(_items, (item) => item.toJson()),
        _kAiRecommendationsKey:
            _encodeList(_aiRecommendations, (item) => item.toJson()),
        _kAiIntegrationsKey:
            _encodeList(_aiIntegrations, (item) => item.toJson()),
        _kExternalIntegrationsKey:
            _encodeList(_externalIntegrations, (item) => item.toJson()),
        _kDefinitionsKey:
            _encodeList(_techDefinitions, (item) => item.toJson()),
      };
      await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'technology',
        dataUpdater: (data) => data.copyWith(planningNotes: updatedNotes),
        showSnackbar: false,
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  _DecodedList<T> _decodeList<T>(
    String? source,
    T Function(Map<String, dynamic>) fromJson,
    List<T> fallback,
  ) {
    if (source == null || source.trim().isEmpty) {
      return _DecodedList<T>(fallback, true);
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is List) {
        final items = <T>[];
        for (final entry in decoded) {
          if (entry is Map) {
            items.add(fromJson(
                entry.map((key, value) => MapEntry(key.toString(), value))));
          }
        }
        return _DecodedList<T>(items, false);
      }
    } catch (_) {}
    return _DecodedList<T>(fallback, true);
  }

  String _encodeList<T>(
      List<T> items, Map<String, dynamic> Function(T) toJson) {
    return jsonEncode(items.map(toJson).toList());
  }

  List<_AiIntegrationItem> _seedAiIntegrations() {
    return const [
      _AiIntegrationItem(
        name: 'Customer Support Copilot',
        summary: 'AI agent that drafts responses and routes tickets by intent.',
        model: 'GPT-4.1 mini',
        status: 'Deployed',
        owner: 'Support Ops',
        latency: '1.2s',
        monthlyCost: '\$1,100',
        category: 'NLP',
        tags: ['ticketing', 'agent assist'],
      ),
      _AiIntegrationItem(
        name: 'Vision Quality Scanner',
        summary: 'Detects defects in image uploads and flags manual review.',
        model: 'Vision Inspect v2',
        status: 'Pilot',
        owner: 'QA',
        latency: '850ms',
        monthlyCost: '\$820',
        category: 'Vision',
        tags: ['computer vision', 'risk'],
      ),
      _AiIntegrationItem(
        name: 'Forecasting Engine',
        summary: 'Predicts demand and resource needs by region.',
        model: 'TimeCast X',
        status: 'Pending',
        owner: 'Analytics',
        latency: '2.6s',
        monthlyCost: '\$640',
        category: 'Analytics',
        tags: ['forecasting', 'capacity'],
      ),
      _AiIntegrationItem(
        name: 'Workflow Automation',
        summary: 'Auto-triage recurring tasks and apply rule-based approvals.',
        model: 'FlowSense',
        status: 'Deployed',
        owner: 'PMO',
        latency: '1.6s',
        monthlyCost: '\$540',
        category: 'Automation',
        tags: ['approvals', 'efficiency'],
      ),
    ];
  }

  List<_ExternalIntegrationItem> _seedExternalIntegrations() {
    return const [
      _ExternalIntegrationItem(
        name: 'Stripe Payments',
        summary: 'Primary card payments and invoicing.',
        vendor: 'Stripe',
        status: 'Live',
        sla: '99.9%',
        dataFlow: 'Bi-directional',
        lastSync: '10 mins ago',
        owner: 'Finance',
        category: 'Payments',
        tags: ['pci', 'billing'],
      ),
      _ExternalIntegrationItem(
        name: 'Salesforce CRM',
        summary: 'Customer records and sales pipeline.',
        vendor: 'Salesforce',
        status: 'Live',
        sla: '99.5%',
        dataFlow: 'Inbound',
        lastSync: '35 mins ago',
        owner: 'Revenue Ops',
        category: 'CRM',
        tags: ['accounts', 'contacts'],
      ),
      _ExternalIntegrationItem(
        name: 'SAP ERP',
        summary: 'Finance, procurement, and inventory data sync.',
        vendor: 'SAP',
        status: 'In Review',
        sla: '99.0%',
        dataFlow: 'Outbound',
        lastSync: '2 hrs ago',
        owner: 'IT',
        category: 'ERP',
        tags: ['finance', 'procurement'],
      ),
      _ExternalIntegrationItem(
        name: 'Segment Analytics',
        summary: 'Event routing and customer analytics.',
        vendor: 'Segment',
        status: 'Live',
        sla: '99.9%',
        dataFlow: 'Outbound',
        lastSync: '5 mins ago',
        owner: 'Analytics',
        category: 'Analytics',
        tags: ['events', 'tracking'],
      ),
      _ExternalIntegrationItem(
        name: 'Shippo Logistics',
        summary: 'Shipment labels and tracking updates.',
        vendor: 'Shippo',
        status: 'Pending',
        sla: '98.9%',
        dataFlow: 'Bi-directional',
        lastSync: 'Not connected',
        owner: 'Operations',
        category: 'Logistics',
        tags: ['shipping', 'tracking'],
      ),
    ];
  }

  List<_TechnologyDefinitionItem> _seedTechDefinitions() {
    return const [
      _TechnologyDefinitionItem(
        domain: 'Frontend Experience',
        stack: 'Flutter Web + Tailwind tokens',
        decision: 'Single UI stack for admin and web.',
        rationale: 'Accelerate delivery while keeping design tokens aligned.',
        owner: 'Design Systems',
        standards: ['WCAG AA', 'Responsive grid', 'Theme tokens'],
      ),
      _TechnologyDefinitionItem(
        domain: 'Backend Services',
        stack: 'Node.js + GraphQL + Firebase',
        decision: 'GraphQL gateway for all product APIs.',
        rationale: 'Reduce coupling and provide a unified schema.',
        owner: 'Platform',
        standards: ['Schema-first', 'Rate limits', 'Audit logs'],
      ),
      _TechnologyDefinitionItem(
        domain: 'Data & Analytics',
        stack: 'BigQuery + dbt + Looker',
        decision: 'Centralize analytics in a governed warehouse.',
        rationale: 'Single source of truth for product reporting.',
        owner: 'Data Team',
        standards: ['PII masking', 'Daily SLAs', 'Metric registry'],
      ),
      _TechnologyDefinitionItem(
        domain: 'Infrastructure',
        stack: 'AWS + Terraform + CloudWatch',
        decision: 'Infrastructure as code for all environments.',
        rationale: 'Consistent deployments and auditability.',
        owner: 'SRE',
        standards: ['IaC reviews', 'DR drills', 'Budget alerts'],
      ),
      _TechnologyDefinitionItem(
        domain: 'Security & Compliance',
        stack: 'Okta + Vault + Prisma',
        decision: 'Zero-trust access with continuous posture checks.',
        rationale: 'Protect sensitive project data end-to-end.',
        owner: 'Security',
        standards: ['SOC2', 'Secrets rotation', 'Pen testing'],
      ),
    ];
  }

  /* List<_TechItem> _seedItems() {
    return [
      _TechItem(
        name: 'Development Workstation',
        description: 'High-performance developer workstation with dual monitors',
        categoryName: 'Hardware',
        categorySub: 'Workstation',
        icon: Icons.desktop_windows_outlined,
        vendor: 'Dell',
        costText: '24,500 (one-time)'.replaceFirst('\u00', '\\u00'), // ensure $ display in code block
        status: 'Deployed',
        addedDate: '2025-02-15',
        addedTeam: 'IT Department',
        tags: const ['development', 'hardware'],
      ),
      _TechItem(
        name: 'Figma Professional',
        description: 'UI/UX design software subscription.',
        categoryName: 'Software',
        categorySub: 'Design',
        icon: Icons.design_services_outlined,
        vendor: 'Figma',
        costText: '45/month'.replaceFirst('\u00', '\\u00'),
        status: 'Deployed',
        addedDate: '2025-01-10',
        addedTeam: 'Design Team',
        tags: const ['design', 'UI/UX'],
      ),
      _TechItem(
        name: 'GitHub Enterprise',
        description: 'Source code management and CI/CD platform',
        categoryName: 'Devtools',
        categorySub: 'Version Control',
        icon: Icons.code_outlined,
        vendor: 'GitHub',
        costText: '252/month'.replaceFirst('\u00', '\\u00'),
        status: 'Deployed',
        addedDate: '2024-12-05',
        addedTeam: 'Development Team',
        tags: const ['devops', 'version control'],
      ),
      _TechItem(
        name: 'Cloud Server Infrastructure',
        description: 'Producing and staging environments on AWS',
        categoryName: 'Hardware',
        categorySub: 'Cloud',
        icon: Icons.cloud_outlined,
        vendor: 'AWS',
        costText: '1,500/month'.replaceFirst('\u00', '\\u00'),
        status: 'Deployed',
        addedDate: '2025-01-20',
        addedTeam: 'IT Department',
        tags: const ['cloud', 'infrastructure'],
      ),
    ];
  } */
}

// ===== Summary Row =========================================================
/* class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.items});
  final List<_TechItem> items;

  int get _hardware => items.where((e) => e.categoryName == 'Hardware').length;
  int get _software => items.where((e) => e.categoryName == 'Software').length;
  int get _devtools => items.where((e) => e.categoryName.toLowerCase() == 'devtools').length;

  @override
  Widget build(BuildContext context) {
    // Budget numbers are illustrative based on mock
    return LayoutBuilder(
      builder: (context, c) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Technology Items',
                primary: items.length.toString(),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legend(Icons.devices_other_outlined, 'Hardware', _hardware),
                    const SizedBox(height: 6),
                    _legend(Icons.apps_outlined, 'Software', _software),
                    const SizedBox(height: 6),
                    _legend(Icons.developer_mode_outlined, 'Development Tools', _devtools),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: 'Total Technology Budget',
                primary: '24,157'.replaceFirst('\u00', '\\u00'),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _Kv('One-time Costs', '2,500'),
                    _Kv('Annual Running Costs', '\u0021,657/year'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: 'AI Integrations',
                primary: '3',
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Kv('Deployed', '1'),
                    SizedBox(height: 6),
                    _Kv('Proposed/Pending', '2'),
                    SizedBox(height: 6),
                    _Kv('Available Recommendations', '4'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _legend(IconData icon, String label, int count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
        const Spacer(),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
      ],
    );
  }
} */

// Revised summary row with clean currency strings
class _SummaryRow2 extends StatelessWidget {
  const _SummaryRow2({
    required this.items,
    required this.aiIntegrations,
    required this.aiRecommendations,
  });
  final List<_TechItem> items;
  final List<_AiIntegrationItem> aiIntegrations;
  final List<_AiRecommendation> aiRecommendations;

  int get _hardware => items.where((e) => e.categoryName == 'Hardware').length;
  int get _software => items.where((e) => e.categoryName == 'Software').length;
  int get _devtools =>
      items.where((e) => e.categoryName.toLowerCase() == 'devtools').length;

  @override
  Widget build(BuildContext context) {
    final bool hasBudget = items.isNotEmpty;
    final String budgetLabel = hasBudget ? '—' : '—';
    final String oneTimeLabel = hasBudget ? '—' : 'Not set';
    final String annualLabel = hasBudget ? '—' : 'Not set';
    final int deployedCount = aiIntegrations
        .where((e) => e.status.toLowerCase() == 'deployed')
        .length;
    final int proposedCount = aiIntegrations
        .where((e) =>
            e.status.toLowerCase().contains('proposed') ||
            e.status.toLowerCase().contains('pending'))
        .length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Technology Items',
            primary: items.length.toString(),
            icon: Icons.settings_outlined,
            iconColor: const Color(0xFF14B8A6),
            iconBg: const Color(0xFFE6FFFB),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legend(Icons.devices_other_outlined, 'Hardware', _hardware,
                    const Color(0xFF14B8A6)),
                const SizedBox(height: 6),
                _legend(Icons.apps_outlined, 'Software', _software,
                    const Color(0xFFF97316)),
                const SizedBox(height: 6),
                _legend(Icons.developer_mode_outlined, 'Development Tools',
                    _devtools, const Color(0xFF0EA5E9)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Total Technology Budget',
            primary: budgetLabel,
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF16A34A),
            iconBg: const Color(0xFFE9FBEF),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Kv('One-time Costs', oneTimeLabel),
                _Kv('Annual Running Costs', annualLabel),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'AI Integrations',
            primary: aiIntegrations.length.toString(),
            icon: Icons.grid_view_rounded,
            iconColor: const Color(0xFF14B8A6),
            iconBg: const Color(0xFFE6FFFB),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Kv('Deployed', deployedCount.toString()),
                const SizedBox(height: 6),
                _Kv('Proposed/Pending', proposedCount.toString()),
                const SizedBox(height: 6),
                _Kv('Available Recommendations',
                    aiRecommendations.length.toString()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legend(IconData icon, String label, int count, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
        const Spacer(),
        Text('$count',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF111827))),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.primary,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
  final String title;
  final String primary;
  final Widget subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563))),
            ],
          ),
          const SizedBox(height: 8),
          Text(primary,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827))),
          const SizedBox(height: 14),
          subtitle,
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv(this.k, this.v);
  final String k;
  final String v;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        Text(v,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827))),
      ],
    );
  }
}

// ===== Tabs ================================================================
class _Tabs extends StatelessWidget {
  const _Tabs({required this.active, required this.onChanged});
  final int active;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = const [
      'Technology Inventory',
      'AI Integrations',
      'External Integrations',
      'Technology Definitions',
      'AI Recommendations',
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(
              child: _TabChip(
                label: labels[i],
                selected: active == i,
                onTap: () => onChanged(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: const Color(0xFFE5E7EB)) : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color:
                  selected ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabActionsBar extends StatelessWidget {
  const _TabActionsBar({
    required this.activeTab,
    required this.isLoadingRecommendations,
    required this.onAddInventory,
    required this.onAddAiIntegration,
    required this.onAddExternalIntegration,
    required this.onAddDefinition,
    required this.onAddRecommendation,
  });

  final int activeTab;
  final bool isLoadingRecommendations;
  final VoidCallback onAddInventory;
  final VoidCallback onAddAiIntegration;
  final VoidCallback onAddExternalIntegration;
  final VoidCallback onAddDefinition;
  final VoidCallback onAddRecommendation;

  @override
  Widget build(BuildContext context) {
    String label;
    VoidCallback? onTap;

    switch (activeTab) {
      case 0:
        label = 'Add Inventory Item';
        onTap = onAddInventory;
        break;
      case 1:
        label = 'Add AI Integration';
        onTap = onAddAiIntegration;
        break;
      case 2:
        label = 'Add External Integration';
        onTap = onAddExternalIntegration;
        break;
      case 3:
        label = 'Add Definition';
        onTap = onAddDefinition;
        break;
      case 4:
        label = isLoadingRecommendations
            ? 'Generating...'
            : 'Generate AI Recommendations';
        onTap = isLoadingRecommendations ? null : onAddRecommendation;
        break;
      default:
        label = '';
        onTap = null;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _yellowPillButton(label: label, onTap: onTap, enabled: onTap != null),
      ],
    );
  }
}

// ===== Search + Filter =====================================================
// ignore: unused_element
class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({
    required this.searchCtrl,
    required this.category,
    required this.onCategoryChanged,
    required this.options,
  });
  final TextEditingController searchCtrl;
  final String category;
  final ValueChanged<String> onCategoryChanged;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 900;
    final searchField = SizedBox(
      width: isNarrow ? double.infinity : 260,
      child: _roundedField(
        controller: searchCtrl,
        hint: 'Search technology.',
        prefixIcon: Icons.search,
      ),
    );
    final categoryField = SizedBox(
      width: isNarrow ? double.infinity : 220,
      child: _CategoryDropdown(
          value: category, onChanged: onCategoryChanged, options: options),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12),
          categoryField,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        searchField,
        const SizedBox(width: 12),
        categoryField,
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown(
      {required this.value, required this.onChanged, required this.options});
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> options;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_rounded,
              color: Color(0xFF6B7280)),
          items: [
            for (final o in options)
              DropdownMenuItem<String>(
                value: o,
                child: Text(o, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }
}

// ===== Inventory Table =====================================================
class _InventoryTable extends StatelessWidget {
  const _InventoryTable({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });
  final List<_TechItem> items;
  final ValueChanged<_TechItem> onEdit;
  final ValueChanged<_TechItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final minWidth = 980.0; // ensure wide layout like the mock
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: minWidth > c.maxWidth ? minWidth : c.maxWidth),
            child: Column(
              children: [
                _headerRow(),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                for (final e in items) _dataRow(e),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _headerRow() {
    final style = const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280));
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          _cell(const SizedBox(), flex: 3),
          _cell(Text('Category', style: style), flex: 2),
          _cell(Text('Cost', style: style), flex: 2),
          _cell(Text('Status', style: style)),
          _cell(Text('Vendor', style: style)),
          _cell(Text('Added', style: style), flex: 2),
          _cell(Text('Actions', style: style)),
        ],
      ),
    );
  }

  Widget _dataRow(_TechItem e) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cell(_NameCell(item: e), flex: 3),
          _cell(_CategoryCell(item: e), flex: 2),
          _cell(Text(e.costText,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          _cell(_statusChip(e.status)),
          _cell(
              Text(e.vendor, style: const TextStyle(color: Color(0xFF111827)))),
          _cell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.addedDate,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(e.addedTeam,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
              flex: 2),
          _cell(
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit(e);
                } else if (value == 'delete') {
                  onDelete(e);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              icon: const Icon(Icons.more_horiz, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(Widget child, {int flex = 1}) =>
      Expanded(flex: flex, child: child);
}

class _NameCell extends StatelessWidget {
  const _NameCell({required this.item});
  final _TechItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Icon(item.icon, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(item.description,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in item.tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(t,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF4B5563))),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({required this.item});
  final _TechItem item;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(_categoryIcon(item.categoryName), color: const Color(0xFF6B7280)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.categoryName,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(item.categorySub,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ]),
      ],
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'hardware':
        return Icons.memory_outlined;
      case 'software':
        return Icons.apps_outlined;
      case 'devtools':
        return Icons.developer_mode_outlined;
      default:
        return Icons.grid_view_outlined;
    }
  }
}

Widget _statusChip(String status) {
  final normalized = status.toLowerCase();
  Color bg = const Color(0xFFE3FCEF);
  Color fg = const Color(0xFF16A34A);
  if (normalized.contains('pending') || normalized.contains('pilot')) {
    bg = const Color(0xFFFFF7E6);
    fg = const Color(0xFF92400E);
  } else if (normalized.contains('review')) {
    bg = const Color(0xFFE0F2FE);
    fg = const Color(0xFF0369A1);
  } else if (normalized.contains('live') || normalized.contains('deployed')) {
    bg = const Color(0xFFE3FCEF);
    fg = const Color(0xFF16A34A);
  } else {
    bg = const Color(0xFFF3F4F6);
    fg = const Color(0xFF6B7280);
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: bg.withValues(alpha: 0.8)),
    ),
    child: Text(status,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
  );
}

// ===== AI Integrations ====================================================
class _AiIntegrationsView extends StatelessWidget {
  const _AiIntegrationsView({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<_AiIntegrationItem> items;
  final ValueChanged<_AiIntegrationItem> onEdit;
  final ValueChanged<_AiIntegrationItem> onDelete;

  int get _deployed =>
      items.where((e) => e.status.toLowerCase().contains('deployed')).length;
  int get _pending =>
      items.where((e) => !e.status.toLowerCase().contains('deployed')).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'AI Integrations',
          subtitle: 'Track AI services, model coverage, and readiness signals.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricTile(
                label: 'Deployed',
                value: '$_deployed',
                accent: const Color(0xFF10B981)),
            _MetricTile(
                label: 'Pending/Pilot',
                value: '$_pending',
                accent: const Color(0xFFF59E0B)),
            const _MetricTile(
                label: 'Avg Latency', value: '1.4s', accent: Color(0xFF2563EB)),
            const _MetricTile(
                label: 'Compliance', value: '92%', accent: Color(0xFF8B5CF6)),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool wide = constraints.maxWidth >= 980;
            final double gap = 20;
            final double cardWidth =
                wide ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(width: cardWidth, child: const _ModelGovernanceCard()),
                SizedBox(
                    width: cardWidth, child: const _IntegrationPipelineCard()),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Active Integrations',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _AiIntegrationCard(
              item: item,
              onEdit: () => onEdit(item),
              onDelete: () => onDelete(item),
            )),
      ],
    );
  }
}

class _AiIntegrationCard extends StatelessWidget {
  const _AiIntegrationCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final _AiIntegrationItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD7E5FF)),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827)),
                      ),
                    ),
                    _statusChip(item.status),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      icon: const Icon(Icons.more_horiz,
                          color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.summary,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _MetaPair(label: 'Model', value: item.model),
                    _MetaPair(label: 'Latency', value: item.latency),
                    _MetaPair(label: 'Owner', value: item.owner),
                    _MetaPair(label: 'Cost', value: item.monthlyCost),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in item.tags)
                      _TagChip(label: tag, tone: const Color(0xFF2563EB)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelGovernanceCard extends StatelessWidget {
  const _ModelGovernanceCard();

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Model Governance',
      subtitle: 'Controls, reviews, and guardrails for AI use.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _BulletRow(text: 'Bias evaluation complete for 3 models'),
          _BulletRow(text: 'Human-in-the-loop enabled for critical flows'),
          _BulletRow(text: 'Audit trail stored for model decisions'),
          SizedBox(height: 12),
          _StatusRow(
              label: 'Next review', value: 'Oct 22', tone: Color(0xFF2563EB)),
        ],
      ),
    );
  }
}

class _IntegrationPipelineCard extends StatelessWidget {
  const _IntegrationPipelineCard();

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Integration Pipeline',
      subtitle: 'AI services moving into production.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PipelineStep(
              step: '1', title: 'Discovery', detail: 'Use case validation'),
          _PipelineStep(step: '2', title: 'Pilot', detail: 'Sandbox testing'),
          _PipelineStep(
              step: '3', title: 'Security', detail: 'Threat modeling'),
          _PipelineStep(
              step: '4', title: 'Release', detail: 'Rollout + monitoring'),
        ],
      ),
    );
  }
}

// ===== External Integrations =============================================
class _ExternalIntegrationsView extends StatelessWidget {
  const _ExternalIntegrationsView({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<_ExternalIntegrationItem> items;
  final ValueChanged<_ExternalIntegrationItem> onEdit;
  final ValueChanged<_ExternalIntegrationItem> onDelete;

  int get _liveCount =>
      items.where((e) => e.status.toLowerCase().contains('live')).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'External Integrations',
          subtitle:
              'Monitor partner connectivity, data flow, and SLA adherence.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricTile(
                label: 'Active Integrations',
                value: _liveCount.toString(),
                accent: const Color(0xFF10B981)),
            const _MetricTile(
                label: 'Sync Success',
                value: '97.8%',
                accent: Color(0xFF2563EB)),
            const _MetricTile(
                label: 'Avg Data Latency',
                value: '4 mins',
                accent: Color(0xFFF59E0B)),
            const _MetricTile(
                label: 'Contracts Due', value: '2', accent: Color(0xFF8B5CF6)),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool wide = constraints.maxWidth >= 980;
            final double gap = 20;
            final double cardWidth =
                wide ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                    width: cardWidth, child: const _IntegrationHealthCard()),
                SizedBox(width: cardWidth, child: const _DataFlowMapCard()),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _ExternalIntegrationsTable(
          items: items,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _ExternalIntegrationsTable extends StatelessWidget {
  const _ExternalIntegrationsTable({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<_ExternalIntegrationItem> items;
  final ValueChanged<_ExternalIntegrationItem> onEdit;
  final ValueChanged<_ExternalIntegrationItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Integration Register',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(label: Text('Integration')),
                DataColumn(label: Text('Vendor')),
                DataColumn(label: Text('Data Flow')),
                DataColumn(label: Text('SLA')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Last Sync')),
                DataColumn(label: Text('Actions')),
              ],
              rows: [
                for (final item in items)
                  DataRow(
                    cells: [
                      DataCell(Text(item.name)),
                      DataCell(Text(item.vendor)),
                      DataCell(Text(item.dataFlow)),
                      DataCell(Text(item.sla)),
                      DataCell(_statusChip(item.status)),
                      DataCell(Text(item.lastSync)),
                      DataCell(
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit(item);
                            } else if (value == 'delete') {
                              onDelete(item);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                          icon: const Icon(Icons.more_horiz,
                              color: Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationHealthCard extends StatelessWidget {
  const _IntegrationHealthCard();

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Connection Health',
      subtitle: 'Signal strength and queue status.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _HealthRow(
              label: 'Queue backlog',
              value: '12 events',
              tone: Color(0xFFF59E0B)),
          _HealthRow(
              label: 'Error rate', value: '0.6%', tone: Color(0xFFEF4444)),
          _HealthRow(
              label: 'Retries in flight', value: '4', tone: Color(0xFF2563EB)),
          _HealthRow(
              label: 'SLA breach risk', value: 'Low', tone: Color(0xFF10B981)),
        ],
      ),
    );
  }
}

class _DataFlowMapCard extends StatelessWidget {
  const _DataFlowMapCard();

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Data Flow Map',
      subtitle: 'Inbound and outbound exchange paths.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _BulletRow(text: 'Payments data ingested hourly'),
          _BulletRow(text: 'CRM leads sync every 15 minutes'),
          _BulletRow(text: 'ERP batch jobs nightly at 02:00'),
          SizedBox(height: 12),
          _TagChip(label: '3 Inbound', tone: Color(0xFF2563EB)),
          _TagChip(label: '2 Outbound', tone: Color(0xFF10B981)),
          _TagChip(label: '1 Bi-directional', tone: Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}

// ===== Technology Definitions ============================================
class _TechnologyDefinitionsView extends StatelessWidget {
  const _TechnologyDefinitionsView({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<_TechnologyDefinitionItem> items;
  final ValueChanged<_TechnologyDefinitionItem> onEdit;
  final ValueChanged<_TechnologyDefinitionItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Technology Definitions',
          subtitle:
              'Document stack decisions, rationale, and delivery standards.',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool wide = constraints.maxWidth >= 980;
            final double gap = 20;
            final double cardWidth =
                wide ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in items)
                  SizedBox(
                    width: cardWidth,
                    child: _DefinitionCard(
                      item: item,
                      onEdit: () => onEdit(item),
                      onDelete: () => onDelete(item),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const _DefinitionGuardrailsCard(),
      ],
    );
  }
}

class _DefinitionCard extends StatelessWidget {
  const _DefinitionCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final _TechnologyDefinitionItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: item.domain,
      subtitle: item.decision,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _MetaPair(label: 'Stack', value: item.stack)),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                icon: const Icon(Icons.more_horiz, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.rationale,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          _MetaPair(label: 'Owner', value: item.owner),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in item.standards)
                _TagChip(label: tag, tone: const Color(0xFF2563EB)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DefinitionGuardrailsCard extends StatelessWidget {
  const _DefinitionGuardrailsCard();

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Architecture Guardrails',
      subtitle: 'Non-negotiable technical principles.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _BulletRow(
              text:
                  'All services publish telemetry to the same observability stack.'),
          _BulletRow(
              text:
                  'API changes must be versioned with backward compatibility.'),
          _BulletRow(
              text:
                  'Security reviews required before any production deployment.'),
          _BulletRow(
              text: 'Data access follows least-privilege and audit logging.'),
        ],
      ),
    );
  }
}

// ===== Shared Pieces ======================================================
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827))),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(
      {required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: accent)),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard(
      {required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0B000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep(
      {required this.step, required this.title, required this.detail});

  final String step;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(step,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(detail,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPair extends StatelessWidget {
  const _MetaPair({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
              text: value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tone),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF374151), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow(
      {required this.label, required this.value, required this.tone});

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            value,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: tone),
          ),
        ),
      ],
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow(
      {required this.label, required this.value, required this.tone});

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: tone),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    const labels = [
      'Technology Inventory',
      'AI Integrations',
      'External Integrations',
      'Technology Definitions',
      'AI Recommendations',
    ];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${labels[index]} will appear here.',
              style: const TextStyle(color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiRecommendationsView extends StatelessWidget {
  const _AiRecommendationsView({
    required this.recommendations,
    required this.onEdit,
    required this.onDelete,
    required this.onImplement,
  });

  final List<_AiRecommendation> recommendations;
  final ValueChanged<_AiRecommendation> onEdit;
  final ValueChanged<_AiRecommendation> onDelete;
  final ValueChanged<_AiRecommendation> onImplement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Technology Recommendations',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Based on your project needs, we recommend the following technologies',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF5FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD7E5FF)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEBFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Color(0xFF2563EB), size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI Technology Recommendations',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Based on your project needs, we recommend the following technologies:',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 12),
        ...recommendations.map((rec) => _RecommendationCard(
              recommendation: rec,
              onEdit: () => onEdit(rec),
              onDelete: () => onDelete(rec),
              onImplement: () => onImplement(rec),
            )),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.onEdit,
    required this.onDelete,
    required this.onImplement,
  });
  final _AiRecommendation recommendation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onImplement;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation.title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827)),
              ),
              const SizedBox(height: 6),
              Text(
                recommendation.description,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              Text(
                'Estimated cost: ${recommendation.estimatedCost}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 4),
              Text(
                'Suggested vendor: ${recommendation.vendor}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Benefits',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827)),
              ),
              const SizedBox(height: 6),
              ...recommendation.benefits.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF111827),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF374151)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: onImplement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF6C437),
                  foregroundColor: const Color(0xFF111827),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Implement',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      foregroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Edit',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      foregroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Delete',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: content),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}

// ===== Data model ==========================================================
class _TechItem {
  final String name;
  final String description;
  final String categoryName;
  final String categorySub;
  final IconData icon;
  final String vendor;
  final String costText;
  final String status;
  final String addedDate;
  final String addedTeam;
  final List<String> tags;

  _TechItem({
    required this.name,
    required this.description,
    required this.categoryName,
    required this.categorySub,
    required this.icon,
    required this.vendor,
    required this.costText,
    required this.status,
    required this.addedDate,
    required this.addedTeam,
    required this.tags,
  });

  String get _iconKey {
    if (icon == Icons.desktop_windows_outlined) return 'desktop';
    if (icon == Icons.design_services_outlined) return 'design';
    if (icon == Icons.code_outlined) return 'code';
    if (icon == Icons.cloud_outlined) return 'cloud';
    return 'grid';
  }

  static IconData _iconFromKey(String key) {
    switch (key) {
      case 'desktop':
        return Icons.desktop_windows_outlined;
      case 'design':
        return Icons.design_services_outlined;
      case 'code':
        return Icons.code_outlined;
      case 'cloud':
        return Icons.cloud_outlined;
      default:
        return Icons.grid_view_outlined;
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'categoryName': categoryName,
        'categorySub': categorySub,
        'icon': _iconKey,
        'vendor': vendor,
        'costText': costText,
        'status': status,
        'addedDate': addedDate,
        'addedTeam': addedTeam,
        'tags': tags,
      };

  factory _TechItem.fromJson(Map<String, dynamic> json) {
    return _TechItem(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      categorySub: json['categorySub']?.toString() ?? '',
      icon: _iconFromKey(json['icon']?.toString() ?? ''),
      vendor: json['vendor']?.toString() ?? '',
      costText: json['costText']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      addedDate: json['addedDate']?.toString() ?? '',
      addedTeam: json['addedTeam']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

class _AiRecommendation {
  final String title;
  final String description;
  final String estimatedCost;
  final String vendor;
  final List<String> benefits;

  const _AiRecommendation({
    required this.title,
    required this.description,
    required this.estimatedCost,
    required this.vendor,
    required this.benefits,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'estimatedCost': estimatedCost,
        'vendor': vendor,
        'benefits': benefits,
      };

  factory _AiRecommendation.fromJson(Map<String, dynamic> json) {
    return _AiRecommendation(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      estimatedCost: json['estimatedCost']?.toString() ?? '',
      vendor: json['vendor']?.toString() ?? '',
      benefits:
          (json['benefits'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }
}

class _AiIntegrationItem {
  final String name;
  final String summary;
  final String model;
  final String status;
  final String owner;
  final String latency;
  final String monthlyCost;
  final String category;
  final List<String> tags;

  const _AiIntegrationItem({
    required this.name,
    required this.summary,
    required this.model,
    required this.status,
    required this.owner,
    required this.latency,
    required this.monthlyCost,
    required this.category,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'summary': summary,
        'model': model,
        'status': status,
        'owner': owner,
        'latency': latency,
        'monthlyCost': monthlyCost,
        'category': category,
        'tags': tags,
      };

  factory _AiIntegrationItem.fromJson(Map<String, dynamic> json) {
    return _AiIntegrationItem(
      name: json['name']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      latency: json['latency']?.toString() ?? '',
      monthlyCost: json['monthlyCost']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

class _ExternalIntegrationItem {
  final String name;
  final String summary;
  final String vendor;
  final String status;
  final String sla;
  final String dataFlow;
  final String lastSync;
  final String owner;
  final String category;
  final List<String> tags;

  const _ExternalIntegrationItem({
    required this.name,
    required this.summary,
    required this.vendor,
    required this.status,
    required this.sla,
    required this.dataFlow,
    required this.lastSync,
    required this.owner,
    required this.category,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'summary': summary,
        'vendor': vendor,
        'status': status,
        'sla': sla,
        'dataFlow': dataFlow,
        'lastSync': lastSync,
        'owner': owner,
        'category': category,
        'tags': tags,
      };

  factory _ExternalIntegrationItem.fromJson(Map<String, dynamic> json) {
    return _ExternalIntegrationItem(
      name: json['name']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      vendor: json['vendor']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      sla: json['sla']?.toString() ?? '',
      dataFlow: json['dataFlow']?.toString() ?? '',
      lastSync: json['lastSync']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

class _TechnologyDefinitionItem {
  final String domain;
  final String stack;
  final String decision;
  final String rationale;
  final String owner;
  final List<String> standards;

  const _TechnologyDefinitionItem({
    required this.domain,
    required this.stack,
    required this.decision,
    required this.rationale,
    required this.owner,
    required this.standards,
  });

  Map<String, dynamic> toJson() => {
        'domain': domain,
        'stack': stack,
        'decision': decision,
        'rationale': rationale,
        'owner': owner,
        'standards': standards,
      };

  factory _TechnologyDefinitionItem.fromJson(Map<String, dynamic> json) {
    return _TechnologyDefinitionItem(
      domain: json['domain']?.toString() ?? '',
      stack: json['stack']?.toString() ?? '',
      decision: json['decision']?.toString() ?? '',
      rationale: json['rationale']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      standards:
          (json['standards'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }
}

class _DecodedList<T> {
  const _DecodedList(this.items, this.usedFallback);

  final List<T> items;
  final bool usedFallback;
}

class _BottomOverlays extends StatelessWidget {
  const _BottomOverlays();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            Positioned(
              left: 24,
              bottom: 24,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                    color: Color(0xFFB3D9FF), shape: BoxShape.circle),
                child: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: Row(
                children: [
                  _aiHint(),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await ProjectDataHelper.saveAndNavigate(
                        context: context,
                        checkpoint: 'technology',
                        nextScreenBuilder: () =>
                            const InterfaceManagementScreen(),
                        dataUpdater: (d) => d,
                        destinationCheckpoint: 'interface_management',
                        destinationName: 'Interface Management',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: const Text('Next',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E5FF)),
      ),
      child: Row(
        children: const [
          Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
          SizedBox(width: 8),
          Text('AI',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
          SizedBox(width: 10),
          Text(
              'Capture the technology stack, integrations, and tooling decisions.',
              style: TextStyle(color: Color(0xFF1F2937))),
        ],
      ),
    );
  }
}

Widget _yellowPillButton({
  required String label,
  required VoidCallback? onTap,
  bool enabled = true,
}) {
  return ElevatedButton(
    onPressed: enabled ? onTap : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFFD700),
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    ),
    child: Text(label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
  );
}

Widget _roundedField({
  required TextEditingController controller,
  required String hint,
  int minLines = 1,
  IconData? prefixIcon,
}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE4E7EC)),
    ),
    padding: const EdgeInsets.all(14),
    child: TextField(
      controller: controller,
      minLines: minLines,
      maxLines: null,
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 18, color: const Color(0xFF9CA3AF)),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _circleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () async {
                await ProjectDataHelper.saveAndNavigate(
                  context: context,
                  checkpoint: 'technology',
                  nextScreenBuilder: () =>
                      const DesignPhaseScreen(activeItemLabel: 'Design'),
                  dataUpdater: (d) => d,
                  destinationCheckpoint: 'design',
                  destinationName: 'Design',
                );
              }),
          const SizedBox(width: 8),
          _circleButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () async {
              await ProjectDataHelper.saveAndNavigate(
                context: context,
                checkpoint: 'technology',
                nextScreenBuilder: () => const InterfaceManagementScreen(),
                dataUpdater: (d) => d,
                destinationCheckpoint: 'interface_management',
                destinationName: 'Interface Management',
              );
            },
          ),
          const SizedBox(width: 16),
          const EditableContentText(
            contentKey: 'tech_page_title',
            fallback: 'Technology',
            category: 'front_end_planning',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827)),
          ),
          const Spacer(),
          const UserAccessChip(),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }
}
