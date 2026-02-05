import 'package:flutter/material.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/text_sanitizer.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';
import 'package:ndu_project/models/procurement/procurement_models.dart';
import 'package:ndu_project/services/procurement_service.dart';
import 'package:ndu_project/widgets/procurement_tables.dart'; // Updated import
import 'package:ndu_project/widgets/procurement_dialogs.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'dart:convert';

/// Front End Planning – Contract and Vendor Quotes screen.
/// Mirrors the provided mock with the shared workspace chrome,
/// short notes field, large contract/vendor entry area, and
/// the bottom info + AI hint + next control row.
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

  Stream<List<ProcurementItemModel>>? _itemsStream;
  Stream<List<ContractModel>>? _contractsStream;
  bool _generating = false;
  String? _lastProjectId;

  @override
  void initState() {
    super.initState();
    ApiKeyManager.initializeApiKey();
    // Streams are now handled in didChangeDependencies to react to ProjectId changes
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final projectData = ProjectDataHelper.getData(context);
    final projectId = projectData.projectId;

    // Only update streams if projectId has changed and is valid
    if (projectId != _lastProjectId &&
        projectId != null &&
        projectId.isNotEmpty) {
      _lastProjectId = projectId;
      _itemsStream = ProcurementService.streamItems(projectId);
      _contractsStream = ProcurementService.streamContracts(projectId);
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
      // Ensure the result has the correct projectId before creating
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
        // Ensure the result has the correct projectId before creating
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
    final projectData = ProjectDataHelper.getData(context);
    final projectId = projectData.projectId;

    if (projectId == null || projectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Project not initialized. Cannot generate items.')),
      );
      return;
    }

    setState(() => _generating = true);
    try {
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
          'For "contracts": "title" (string), "description" (string), "contractor" (string, potential name), "cost" (number), "duration" (string). '
          'For "procurement_items": "name" (string), "category" (string), "budget" (number), "potential_vendors" (string). '
          'Context: $contextText';

      final response = await OpenAiServiceSecure().generateCompletion(prompt);
      final cleanJson = TextSanitizer.cleanJson(response);
      Map<String, dynamic> parsed = {};
      try {
        parsed = jsonDecode(cleanJson);
      } catch (e) {
        debugPrint('JSON decode error, attempting fallback cleanup: $e');
        throw Exception('AI returned invalid data format.');
      }

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
              duration: item['duration'] ?? 'TBD',
              status: 'Draft',
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
              description: item['category'] ??
                  '', // Description often fits here if brief
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
              content:
                  Text('Contractors and Vendors auto-populated successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error regenerating contracts: $e');
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      activeItemLabel: 'Contract & Vendor Quotes',
      backgroundColor: Colors.white,
      floatingActionButton: const KazAiChatBubble(),
      body: Stack(
        children: [
          const AdminEditToggle(),
          Column(
            children: [
              const FrontEndPlanningHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _roundedField(
                          controller: _notesController,
                          hint: 'Input your notes here...',
                          minLines: 3),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                EditableContentText(
                                  contentKey:
                                      'fep_contract_vendor_quotes_title',
                                  fallback: 'Contract and Vendor Quotes',
                                  category: 'front_end_planning',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                SizedBox(height: 6),
                                EditableContentText(
                                  contentKey:
                                      'fep_contract_vendor_quotes_subtitle',
                                  fallback:
                                      'Manage your contractors and vendors below.',
                                  category: 'front_end_planning',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PageRegenerateAllButton(
                            onRegenerateAll: () async {
                              final confirmed =
                                  await showRegenerateAllConfirmation(context);
                              if (confirmed && mounted) {
                                await _regenerateAllContracts();
                              }
                            },
                            isLoading: _generating,
                            tooltip: 'Auto-populate Contractors and Vendors',
                          ),
                          const SizedBox(width: 12),
                          const SizedBox(width: 12),
                          // Actions moved to section headers
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Check for Project ID
                      if (ProjectDataHelper.getData(context).projectId ==
                          null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 48, color: Color(0xFFDC2626)),
                              const SizedBox(height: 16),
                              const Text(
                                'Project Not Initialized',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF991B1B)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please return to the "Project Details" or "Initiation" section and ensure the project is saved before managing contracts and vendors.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFFB91C1C)),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Active Contracts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _openAddContractDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Contract'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEFF6FF),
                                foregroundColor: const Color(0xFF2563EB),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<List<ContractModel>>(
                          stream: _contractsStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            return ContractsTable(contracts: snapshot.data!);
                          },
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Procurement & Vendors',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _openAddItemDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEFF6FF),
                                foregroundColor: const Color(0xFF2563EB),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<List<ProcurementItemModel>>(
                          stream: _itemsStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                    'Error loading items: ${snapshot.error}',
                                    style: const TextStyle(
                                        color: Color(0xFFDC2626))),
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final items = snapshot.data ?? [];
                            return ProcurementTable(items: items);
                          },
                        ),
                        const SizedBox(height: 140),
                      ], // Close else block
                    ],
                  ),
                ),
              ),
            ],
          ),
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
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.onNext});

  final VoidCallback onNext;

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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
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
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB))),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 34, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: const Text('Next',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
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
