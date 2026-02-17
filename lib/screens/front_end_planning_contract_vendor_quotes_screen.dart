import 'package:flutter/material.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';

import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/text_sanitizer.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';
import 'package:ndu_project/models/procurement/procurement_models.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/procurement_service.dart';
import 'package:ndu_project/widgets/procurement_tables.dart';
import 'package:ndu_project/widgets/procurement_dialogs.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'dart:convert';
// Layout Imports
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/responsive.dart'; // Added for AppBreakpoints
import 'package:intl/intl.dart';

/// Front End Planning – Contracting screen (formerly Contract & Vendor Quotes).
/// Updated to use the standard FEP layout with DraggableSidebar and FrontEndPlanningHeader.
class FrontEndPlanningContractVendorQuotesScreen extends StatefulWidget {
  const FrontEndPlanningContractVendorQuotesScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const FrontEndPlanningContractVendorQuotesScreen()),
    );
  }

  @override
  State<FrontEndPlanningContractVendorQuotesScreen> createState() =>
      _FrontEndPlanningContractVendorQuotesScreenState();
}

class _FrontEndPlanningContractVendorQuotesScreenState
    extends State<FrontEndPlanningContractVendorQuotesScreen> {
  static const int _initialContractsLimit = 40;
  static const int _initialItemsLimit = 40;
  static const int _loadMoreStep = 40;
  static const int _maxAiImportRows = 25;
  final NumberFormat _currency = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );
  final NumberFormat _compactCurrency = NumberFormat.compactCurrency(
    symbol: '\$',
    decimalDigits: 1,
  );

  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isNotesSyncReady = false;

  Stream<List<ProcurementItemModel>>? _itemsStream;
  Stream<List<ContractModel>>? _contractsStream;
  int _contractQueryLimit = _initialContractsLimit;
  int _itemQueryLimit = _initialItemsLimit;
  bool _generating = false;
  String? _lastProjectId;

  @override
  void initState() {
    super.initState();
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final data = ProjectDataHelper.getData(context);
      _notesController.text = data.frontEndPlanning.contractVendorQuotes;
      _notesController.addListener(_syncContractNotes);
      _isNotesSyncReady = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final projectData = ProjectDataHelper.getData(context);
    final projectId = projectData.projectId;

    if (projectId != _lastProjectId &&
        projectId != null &&
        projectId.isNotEmpty) {
      _lastProjectId = projectId;
      _bindProcurementStreams(projectId);
    }
  }

  void _bindProcurementStreams(String projectId) {
    _itemsStream =
        ProcurementService.streamItems(projectId, limit: _itemQueryLimit);
    _contractsStream = ProcurementService.streamContracts(projectId,
        limit: _contractQueryLimit);
  }

  String? _activeProjectIdOrNull() {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.trim().isEmpty) {
      return null;
    }
    return projectId.trim();
  }

  void _loadMoreContracts() {
    final projectId = _activeProjectIdOrNull();
    if (projectId == null) return;
    setState(() {
      _contractQueryLimit += _loadMoreStep;
      _bindProcurementStreams(projectId);
    });
  }

  void _loadMoreItems() {
    final projectId = _activeProjectIdOrNull();
    if (projectId == null) return;
    setState(() {
      _itemQueryLimit += _loadMoreStep;
      _bindProcurementStreams(projectId);
    });
  }

  Future<void> _openAddContractDialog() async {
    final projectData = ProjectDataHelper.getData(context);
    final projectId = projectData.projectId;

    if (projectId == null || projectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Project not initialized. Cannot add contract.')),
      );
      return;
    }

    final categoryOptions = const ['Construction', 'Services', 'Consulting'];
    final result = await showDialog<ContractModel>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AddContractDialog(
        contextChips: _buildDialogContextChips(),
        categoryOptions: categoryOptions,
      ),
    );

    if (result != null) {
      final contractToSave = result.copyWith(projectId: projectId);
      await ProcurementService.createContract(contractToSave);
    }
  }

  Future<void> _openAddItemDialog() async {
    final projectData = ProjectDataHelper.getData(context);
    final projectId = projectData.projectId;

    if (projectId == null || projectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Project not initialized. Cannot add item.')),
      );
      return;
    }

    final categoryOptions = const [
      'Materials',
      'Equipment',
      'Services',
      'IT Equipment',
      'Construction Services',
      'Furniture',
      'Security',
      'Logistics',
      'Consulting',
      'Labor'
    ];

    final result = await showDialog<ProcurementItemModel>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return AddItemDialog(
          contextChips: _buildDialogContextChips(),
          categoryOptions: categoryOptions,
        );
      },
    );

    if (result != null) {
      try {
        final itemToSave = result.copyWith(projectId: projectId);
        await ProcurementService.createItem(itemToSave);
      } catch (e) {
        debugPrint('Error creating item: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating item: $e')),
          );
        }
      }
    }
  }

  List<Widget> _buildDialogContextChips() {
    final data = ProjectDataHelper.getData(context);
    final chips = <Widget>[
      const ContextChip(label: 'Phase', value: 'Front End Planning'),
    ];
    final projectName = data.projectName.trim();
    if (projectName.isNotEmpty) {
      chips.insert(0, ContextChip(label: 'Project', value: projectName));
    }
    return chips;
  }

  Future<void> _regenerateAllContracts() async {
    final projectId = _activeProjectIdOrNull();

    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Project not initialized. Cannot generate items.')),
      );
      return;
    }
    await _performGeneration(projectId, silent: false);
  }

  Future<void> _performGeneration(String projectId,
      {required bool silent}) async {
    setState(() => _generating = true);
    try {
      final projectData = ProjectDataHelper.getData(context);
      final projectDescription = projectData.solutionDescription.isNotEmpty
          ? projectData.solutionDescription
          : projectData.businessCase;
      final contextText =
          'Project: ${projectData.projectName}. Description: $projectDescription. '
          'Objective: ${projectData.projectObjective}. Solution: ${projectData.solutionDescription}.';

      final prompt =
          'Generate a breakdown of detailed contracts and procurement items needed for this project. '
          'Return a JSON object with two keys: "contracts" and "procurement_items". '
          'Both should be arrays of objects. '
          'For "contracts": "title" (string), "description" (string), "contractor" (string, potential name), "cost" (number), "duration" (string), "owner" (string, hypothetical role e.g. Project Manager). '
          'For "procurement_items": "name" (string), "category" (string), "budget" (number), "potential_vendors" (string). '
          'Context: $contextText';

      final response = await OpenAiServiceSecure()
          .generateCompletion(prompt)
          .timeout(const Duration(seconds: 45));
      final cleanJson = TextSanitizer.cleanJson(response);
      Map<String, dynamic> parsed = {};
      try {
        parsed = jsonDecode(cleanJson);
      } catch (e) {
        throw Exception('AI returned invalid data format.');
      }

      if (!mounted) return;

      bool shouldImport = silent;
      if (!silent) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => _AiPreviewDialog(data: parsed),
        );
        shouldImport = confirmed == true;
      }

      if (shouldImport) {
        if (parsed.containsKey('contracts') && parsed['contracts'] is List) {
          final List<dynamic> contracts =
              (parsed['contracts'] as List).take(_maxAiImportRows).toList();
          for (final item in contracts) {
            if (item is Map<String, dynamic>) {
              final contract = ContractModel(
                id: '',
                projectId: projectId,
                title: item['title'] ?? 'Contract',
                description: item['description'] ?? '',
                contractorName: item['contractor'] ?? 'To be determined',
                estimatedCost: (item['cost'] as num?)?.toDouble() ?? 0.0,
                duration: item['duration'] ?? '3 Months',
                status: ContractStatus.draft,
                owner: item['owner'] ?? 'Unassigned',
                createdAt: DateTime.now(),
              );
              await ProcurementService.createContract(contract);
            }
          }
        }

        if (parsed.containsKey('procurement_items') &&
            parsed['procurement_items'] is List) {
          final List<dynamic> items = (parsed['procurement_items'] as List)
              .take(_maxAiImportRows)
              .toList();
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              final newItem = ProcurementItemModel(
                id: '',
                projectId: projectId,
                name: item['name'] ?? 'New Item',
                description: item['category'] ?? '',
                category: item['category'] ?? 'Equipment',
                budget: (item['budget'] as num?)?.toDouble() ?? 0.0,
                notes: item['potential_vendors'] ?? '',
                status: ProcurementItemStatus.planning,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await ProcurementService.createItem(newItem);
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Contractors and Vendors auto-populated successfully!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error regenerating contracts: $e');
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating items: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  void dispose() {
    if (_isNotesSyncReady) {
      _notesController.removeListener(_syncContractNotes);
    }
    _notesController.dispose();
    super.dispose();
  }

  void _syncContractNotes() {
    if (!mounted) return;
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          contractVendorQuotes: _notesController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _navigateToProcurement() async {
    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'fep_contract_vendor_quotes',
      destinationCheckpoint: 'fep_procurement',
      saveInBackground: true,
      nextScreenBuilder: () => const FrontEndPlanningProcurementScreen(),
      dataUpdater: (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          contractVendorQuotes: _notesController.text.trim(),
        ),
      ),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F6F8),
      drawer: Drawer(
        width: MediaQuery.sizeOf(context).width * 0.88,
        child: const SafeArea(
          child: InitiationLikeSidebar(activeItemLabel: 'Contracting'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 10, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(Icons.menu_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Expanded(
                    child: Text(
                      'Contract & Vendor Quotes',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 13,
                    backgroundColor: Color(0xFF2563EB),
                    child: Text('Ch',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ContractModel>>(
                stream: _contractsStream,
                builder: (context, contractSnapshot) {
                  if (contractSnapshot.hasError) {
                    return _buildErrorState(context, contractSnapshot.error!);
                  }
                  if (contractSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      !contractSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final contracts =
                      contractSnapshot.data ?? const <ContractModel>[];
                  return StreamBuilder<List<ProcurementItemModel>>(
                    stream: _itemsStream,
                    builder: (context, itemSnapshot) {
                      if (itemSnapshot.hasError) {
                        return _buildErrorState(context, itemSnapshot.error!);
                      }
                      if (itemSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !itemSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items =
                          itemSnapshot.data ?? const <ProcurementItemModel>[];
                      final summary =
                          _buildMobileContractSummary(contracts, items);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FRONT END PLANNING',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9CA3AF),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Working Notes',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            _roundedField(
                              controller: _notesController,
                              hint: 'Input your notes here...',
                              minLines: 3,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Contract and Vendor Quotes',
                                    style: TextStyle(
                                      fontSize: 22,
                                      height: 1.05,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _generating
                                      ? null
                                      : _regenerateAllContracts,
                                  icon: _generating
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.refresh_rounded,
                                          color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                            const Text(
                              '(Brief explanation here)',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                  fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.fromLTRB(12, 12, 12, 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Text(
                                summary,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF374151),
                                  height: 1.42,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'AI generation runs only when you tap regenerate.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F1FF),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFD7E5FF)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.auto_awesome,
                                      size: 16, color: Color(0xFF2563EB)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Focus on major risks associated with each potential solution.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _navigateToProcurement,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToProcurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4B400),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildMobileContractSummary(
      List<ContractModel> contracts, List<ProcurementItemModel> items) {
    final contractLines = contracts
        .where((contract) => contract.title.trim().isNotEmpty)
        .take(4)
        .map((contract) =>
            '- ${contract.title.trim()}: ${contract.description.trim().isEmpty ? 'Coordinate vendor scope and pricing review.' : contract.description.trim()}')
        .toList();

    final itemLines = items
        .where((item) => item.name.trim().isNotEmpty)
        .take(3)
        .map((item) =>
            '- ${item.name.trim()} (${item.category.trim().isEmpty ? 'General' : item.category.trim()})')
        .toList();

    final combined = <String>[
      if (contractLines.isNotEmpty) ...contractLines,
      if (itemLines.isNotEmpty) ...itemLines,
    ];
    if (combined.isNotEmpty) {
      return combined.join('\n\n');
    }

    return 'For the successful establishment of this project, secure vendors and contracts that align with scope and milestones.\n\n'
        '- Identify key vendors for each category and evaluate reliability.\n\n'
        '- Request detailed quotes with pricing, lead times, and terms of service.\n\n'
        '- Validate compliance and capability before final selection.\n\n'
        '- Negotiate terms to reduce budget exposure and schedule risk.';
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    debugPrint('Procurement Stream Error: $error');
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFEE2E2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text(
              'Unable to load procurement data',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB91C1C),
                  fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please refresh the page or contact support if the issue persists.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    if (isMobile) {
      return _buildMobileScaffold(context);
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: null,
      floatingActionButton: const KazAiChatBubble(),
      body: Stack(
        children: [
          Row(
            children: [
              DraggableSidebar(
                openWidth: AppBreakpoints.sidebarWidth(context),
                child:
                    const InitiationLikeSidebar(activeItemLabel: 'Contracting'),
              ),
              Expanded(
                child: Column(
                  children: [
                    FrontEndPlanningHeader(
                      title: 'Contracting',
                      scaffoldKey: _scaffoldKey,
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          const AdminEditToggle(),
                          SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _roundedField(
                                    controller: _notesController,
                                    hint: 'Input your notes here...',
                                    minLines: 3),
                                const SizedBox(height: 32),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          EditableContentText(
                                            contentKey: 'fep_contracting_title',
                                            fallback: 'Contracting',
                                            category: 'front_end_planning',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          EditableContentText(
                                            contentKey:
                                                'fep_contracting_subtitle',
                                            fallback:
                                                'Manage contracts for vendors, services, and materials required for project execution. Ensure all agreements align with project scope and budget constraints.',
                                            category: 'front_end_planning',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                // Contracts Section
                                _SectionHeader(
                                  title: 'Contracts',
                                  actionLabel: 'Add Contract',
                                  onAction: _openAddContractDialog,
                                ),
                                const SizedBox(height: 12),
                                StreamBuilder<List<ContractModel>>(
                                  stream: _contractsStream,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return _buildErrorState(
                                          context, snapshot.error!);
                                    }
                                    if (!snapshot.hasData) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    final contracts = snapshot.data!;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ContractsTable(contracts: contracts),
                                        if (contracts.length >=
                                            _contractQueryLimit)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: _loadMoreContracts,
                                              icon: const Icon(
                                                Icons.unfold_more_rounded,
                                                size: 16,
                                              ),
                                              label: Text(
                                                'Load ${_loadMoreStep.toString()} more contracts',
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 48),

                                // Procurement Section
                                _SectionHeader(
                                  title: 'Procurement & Vendors',
                                  actionLabel: 'Add Item',
                                  onAction: _openAddItemDialog,
                                ),
                                const SizedBox(height: 12),
                                StreamBuilder<List<ProcurementItemModel>>(
                                  stream: _itemsStream,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return _buildErrorState(
                                          context, snapshot.error!);
                                    }
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    final items = snapshot.data ??
                                        const <ProcurementItemModel>[];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ProcurementTable(items: items),
                                        if (items.length >= _itemQueryLimit)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: _loadMoreItems,
                                              icon: const Icon(
                                                Icons.unfold_more_rounded,
                                                size: 16,
                                              ),
                                              label: Text(
                                                'Load ${_loadMoreStep.toString()} more items',
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),

                                // Actions Footer
                                const SizedBox(height: 40),
                                Center(
                                  child: Column(
                                    children: [
                                      PageRegenerateAllButton(
                                        onRegenerateAll: () async {
                                          final confirmed =
                                              await showRegenerateAllConfirmation(
                                                  context);
                                          if (confirmed && mounted) {
                                            await _regenerateAllContracts();
                                          }
                                        },
                                        isLoading: _generating,
                                        tooltip:
                                            'Generate contractors and vendors',
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Generation is manual only to keep page loads stable.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // New Cost Basis Section (Placeholder)
                                const SizedBox(height: 60),
                                _buildCostBasisPlaceholder(),
                                const SizedBox(height: 120), // Bottom padding
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // AI Bottom Overlay
          _BottomOverlay(onNext: () async {
            await _navigateToProcurement();
          }),
        ],
      ),
    );
  }

  Widget _buildCostBasisPlaceholder() {
    final projectData = ProjectDataHelper.getData(context, listen: true);
    final costData = projectData.costAnalysisData;

    if (costData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F2A48), Color(0xFF173E69)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF2E5A8B)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0F172A),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined,
                    color: Color(0xFFFACF3A), size: 20),
                SizedBox(width: 10),
                Text(
                  'Cost Basis Intelligence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Text(
              'No Cost Basis data found yet. Complete Cost Analysis to surface live contracting financials here.',
              style: TextStyle(
                color: Color(0xFFDCE7F6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final preferredSolution = projectData.potentialSolutions.firstWhere(
      (solution) => solution.id == projectData.preferredSolutionId,
      orElse: () => PotentialSolution.empty(id: '', number: 0),
    );

    final preferredTitle = preferredSolution.title.trim();
    SolutionCostData? matchedSolutionCost;
    if (preferredTitle.isNotEmpty) {
      for (final solutionCost in costData.solutionCosts) {
        if (solutionCost.solutionTitle.trim() == preferredTitle) {
          matchedSolutionCost = solutionCost;
          break;
        }
      }
    }

    final selectedCostRows = matchedSolutionCost != null
        ? matchedSolutionCost.costRows
        : costData.solutionCosts
            .expand((solutionCost) => solutionCost.costRows)
            .toList();

    final parsedRows = selectedCostRows
        .map((row) => (
              item: row.itemName.trim().isEmpty
                  ? 'Unnamed cost item'
                  : row.itemName.trim(),
              amount: _parseCurrency(row.cost),
            ))
        .where((row) => row.amount > 0)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalCost =
        parsedRows.fold<double>(0, (sum, row) => sum + row.amount);
    final topDrivers = parsedRows.take(4).toList();
    final topDriverMax = topDrivers.isEmpty ? 1.0 : topDrivers.first.amount;

    final totalBenefits = costData.benefitLineItems.fold<double>(
      0,
      (sum, item) =>
          sum + _parseCurrency(item.unitValue) * _parseCurrency(item.units),
    );
    final projectValue = _parseCurrency(costData.projectValueAmount);
    final savingsTarget = _parseCurrency(costData.savingsTarget);
    final coverageRatio =
        projectValue > 0 && totalCost > 0 ? (projectValue / totalCost) : 0.0;
    final normalizedCoverage = coverageRatio.clamp(0.0, 1.0);
    final delta = projectValue - totalCost;
    final deltaLabel = delta >= 0 ? 'Value surplus' : 'Cost exposure';
    final activeSolutionLabel = preferredTitle.isNotEmpty
        ? preferredTitle
        : matchedSolutionCost?.solutionTitle.trim().isNotEmpty == true
            ? matchedSolutionCost!.solutionTitle.trim()
            : 'All cost basis entries';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2A48), Color(0xFF173E69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2E5A8B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined,
                  color: Color(0xFFFACF3A), size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Cost Basis Intelligence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACF3A).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFACF3A)),
                ),
                child: const Text(
                  'Live from Cost Basis',
                  style: TextStyle(
                    color: Color(0xFFFCE588),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Active baseline: $activeSolutionLabel',
            style: const TextStyle(
              color: Color(0xFFDCE7F6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _costInsightTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Total Cost Basis',
                value: _currency.format(totalCost),
              ),
              _costInsightTile(
                icon: Icons.trending_up_outlined,
                label: 'Project Value',
                value: projectValue > 0 ? _currency.format(projectValue) : '--',
              ),
              _costInsightTile(
                icon: Icons.savings_outlined,
                label: 'Benefit Potential',
                value: totalBenefits > 0
                    ? _compactCurrency.format(totalBenefits)
                    : '--',
              ),
              _costInsightTile(
                icon: Icons.flag_outlined,
                label: 'Savings Target',
                value: savingsTarget > 0
                    ? _compactCurrency.format(savingsTarget)
                    : '--',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A223B).withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF315B86)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Cost Coverage vs Value',
                      style: TextStyle(
                        color: Color(0xFFDCE7F6),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(coverageRatio * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Color(0xFFFCE588),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: normalizedCoverage,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF1F3E62),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFF4C430)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$deltaLabel: ${_currency.format(delta.abs())}',
                  style: const TextStyle(
                    color: Color(0xFFDCE7F6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (topDrivers.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Top Cost Drivers',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final row in topDrivers) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.item,
                      style: const TextStyle(
                        color: Color(0xFFDCE7F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _compactCurrency.format(row.amount),
                    style: const TextStyle(
                      color: Color(0xFFFCE588),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (row.amount / topDriverMax).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: const Color(0xFF1F3E62),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _costSignalChip(
                label:
                    'Benefit Items: ${costData.benefitLineItems.length.toString()}',
              ),
              _costSignalChip(
                label:
                    'Basis: ${costData.basisFrequency ?? costData.trackerBasisFrequency}',
              ),
              if (costData.savingsTarget.trim().isNotEmpty)
                _costSignalChip(
                    label: 'Target: ${costData.savingsTarget.trim()}'),
            ],
          ),
        ],
      ),
    );
  }

  double _parseCurrency(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(clean) ?? 0;
  }

  Widget _costInsightTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A223B).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF315B86)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF93C5FD)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFAFC7E4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
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

  Widget _costSignalChip({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A5C),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF315B86)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFDCE7F6),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 24,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F1FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD7E5FF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text('AI',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                SizedBox(width: 12),
                Text(
                  'Focus on major risks associated with each potential solution.',
                  style: TextStyle(color: Color(0xFF1F2937)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF6C437),
              foregroundColor: const Color(0xFF111827),
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              elevation: 0,
            ),
            child: const Text('Next',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

Widget _roundedField(
    {required TextEditingController controller,
    required String hint,
    int minLines = 1}) {
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
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader(
      {required this.title, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add, size: 16),
          label: Text(actionLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEFF6FF),
            foregroundColor: const Color(0xFF2563EB),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

class _AiPreviewDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AiPreviewDialog({required this.data});

  @override
  Widget build(BuildContext context) {
    final contracts = data['contracts'] as List? ?? [];
    final items = data['procurement_items'] as List? ?? [];

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
          SizedBox(width: 12),
          Text('AI Suggested Procurement'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Found ${contracts.length} contracts and ${items.length} procurement items.',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            if (contracts.isNotEmpty) ...[
              const Text('Contracts Preview:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...contracts.take(3).map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${c['title']} (${c['contractor'] ?? 'TBD'})',
                        style: const TextStyle(fontSize: 12)),
                  )),
              if (contracts.length > 3)
                Text('+ ${contracts.length - 3} more contracts...',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 16),
            ],
            if (items.isNotEmpty) ...[
              const Text('Items Preview:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...items.take(3).map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${i['name']} (${i['category']})',
                        style: const TextStyle(fontSize: 12)),
                  )),
              if (items.length > 3)
                Text('+ ${items.length - 3} more items...',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm & Save'),
        ),
      ],
    );
  }
}
