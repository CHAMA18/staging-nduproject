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
import 'package:ndu_project/services/procurement_service.dart';
import 'package:ndu_project/widgets/procurement_tables.dart';
import 'package:ndu_project/widgets/procurement_dialogs.dart';
import 'dart:convert';
// Layout Imports
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/responsive.dart'; // Added for AppBreakpoints

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
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Stream<List<ProcurementItemModel>>? _itemsStream;
  Stream<List<ContractModel>>? _contractsStream;
  bool _generating = false;
  String? _lastProjectId;

  @override
  void initState() {
    super.initState();
    ApiKeyManager.initializeApiKey();
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
      _itemsStream = ProcurementService.streamItems(projectId);
      _contractsStream = ProcurementService.streamContracts(projectId);
      _checkAndAutoPopulate(projectId);
    }
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

  Future<void> _checkAndAutoPopulate(String projectId) async {
    if (_generating) return;

    try {
      final hasContracts = await ProcurementService.streamContracts(projectId)
          .first
          .then((l) => l.isNotEmpty)
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      final hasItems = await ProcurementService.streamItems(projectId)
          .first
          .then((l) => l.isNotEmpty)
          .timeout(const Duration(seconds: 2), onTimeout: () => false);

      if (!hasContracts && !hasItems) {
        debugPrint('Contracts/Items empty. Auto-generating...');
        await _performGeneration(projectId, silent: true);
      }
    } catch (e) {
      debugPrint('Error checking for auto-population: $e');
    }
  }

  Future<void> _regenerateAllContracts() async {
    final projectData = ProjectDataHelper.getData(context);
    final projectId = projectData.projectId;

    if (projectId == null || projectId.isEmpty) {
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

      final response = await OpenAiServiceSecure().generateCompletion(prompt);
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
          final List<dynamic> contracts = parsed['contracts'];
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
          final List<dynamic> items = parsed['procurement_items'];
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
    _notesController.dispose();
    super.dispose();
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: isMobile ? const InitiationLikeSidebar() : null,
      floatingActionButton: const KazAiChatBubble(),
      body: Stack(
        children: [
          Row(
            children: [
              if (!isMobile)
                DraggableSidebar(
                    openWidth: AppBreakpoints.sidebarWidth(context),
                    child: InitiationLikeSidebar()),
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
                                    return ContractsTable(
                                        contracts: snapshot.data!);
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
                                    return ProcurementTable(
                                        items: snapshot.data ?? []);
                                  },
                                ),

                                // Actions Footer
                                const SizedBox(height: 40),
                                Center(
                                  child: PageRegenerateAllButton(
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
                                        'Auto-populate Contractors and Vendors',
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
            await ProjectDataHelper.saveAndNavigate(
              context: context,
              checkpoint: 'fep_contracts',
              nextScreenBuilder: () =>
                  const FrontEndPlanningProcurementScreen(),
              dataUpdater: (data) => data,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCostBasisPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5B8E), // Dark blue as per screenshot
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: const [
          Text(
            'Cost details from the Cost Basis Analysis show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
