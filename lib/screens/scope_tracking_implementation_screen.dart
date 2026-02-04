import 'package:flutter/material.dart';
import 'package:ndu_project/screens/agile_development_iterations_screen.dart';
import 'package:ndu_project/screens/stakeholder_alignment_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/execution_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/scope_tracking_item.dart';
import 'package:ndu_project/widgets/scope_tracking_table_widget.dart';
import 'package:ndu_project/utils/auto_bullet_text_controller.dart';

class ScopeTrackingImplementationScreen extends StatefulWidget {
  const ScopeTrackingImplementationScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ScopeTrackingImplementationScreen()),
    );
  }

  @override
  State<ScopeTrackingImplementationScreen> createState() =>
      _ScopeTrackingImplementationScreenState();
}

class _ScopeTrackingImplementationScreenState
    extends State<ScopeTrackingImplementationScreen> {
  final Set<String> _selectedFilters = {'All'};
  List<ScopeTrackingItem> _items = [];
  List<String> _availableRoles = [];
  List<String> _scopeStatementDeliverables = [];
  bool _isLoading = false;

  String? get _projectId {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems();
      _loadAvailableRoles();
      _loadScopeStatementDeliverables();
    });
  }

  Future<void> _loadItems() async {
    final projectId = _projectId;
    if (projectId == null) return;

    setState(() => _isLoading = true);
    try {
      final items = await ExecutionPhaseService.loadScopeTrackingItems(
          projectId: projectId);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading scope tracking items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAvailableRoles() async {
    final projectId = _projectId;
    if (projectId == null) return;

    try {
      final staffRows =
          await ExecutionPhaseService.loadStaffingRows(projectId: projectId);
      if (mounted) {
        setState(() {
          _availableRoles = staffRows
              .map((row) => row.role)
              .where((role) => role.isNotEmpty)
              .toSet()
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading staff roles: $e');
    }
  }

  Future<void> _loadScopeStatementDeliverables() async {
    final projectId = _projectId;
    if (projectId == null) return;

    try {
      final deliverables =
          await ExecutionPhaseService.loadScopeStatementDeliverables(
              projectId: projectId);
      if (mounted) {
        setState(() {
          _scopeStatementDeliverables = deliverables;
        });
        // Auto-populate scope items if none exist
        if (_items.isEmpty && deliverables.isNotEmpty) {
          _autoPopulateScopeItems(deliverables);
        }
      }
    } catch (e) {
      debugPrint('Error loading scope statement deliverables: $e');
    }
  }

  Future<void> _autoPopulateScopeItems(List<String> deliverables) async {
    final projectId = _projectId;
    if (projectId == null) return;

    try {
      final newItems = <ScopeTrackingItem>[];
      for (final deliverable in deliverables.take(5)) {
        // Limit to first 5 to avoid overwhelming
        if (deliverable.trim().isNotEmpty) {
          // Check if this scope item already exists
          final exists =
              _items.any((item) => item.scopeItem == deliverable.trim());
          if (!exists) {
            newItems.add(ScopeTrackingItem(
              scopeItem: deliverable.trim(),
              implementationStatus: 'Not Started',
              owner: _availableRoles.isNotEmpty ? _availableRoles.first : '',
              verificationMethod: '',
            ));
          }
        }
      }
      if (newItems.isNotEmpty) {
        setState(() {
          _items.addAll(newItems);
        });
        await _saveItems();
        // Auto-generate verification steps for new scope items
        for (final item in newItems) {
          _autoGenerateVerificationSteps(item);
        }
      }
    } catch (e) {
      debugPrint('Error auto-populating scope items: $e');
    }
  }

  Future<void> _autoGenerateVerificationSteps(ScopeTrackingItem item) async {
    if (item.scopeItem.isEmpty) return;

    try {
      final provider = ProjectDataInherited.maybeOf(context);
      if (provider == null) return;

      final projectId = provider.projectData.projectId;
      if (projectId == null || projectId.isEmpty) return;

      final projectData = provider.projectData;

      final projectContext =
          ProjectDataHelper.buildExecutivePlanContext(projectData);
      final designComponents = await ExecutionPhaseService.loadDesignComponents(
        projectId: projectId,
      );
      final componentNames =
          designComponents.map((c) => c.componentName).toList();

      final openAiService = OpenAiServiceSecure();
      final steps = await openAiService.generateVerificationSteps(
        context: projectContext,
        scopeItem: item.scopeItem,
        designComponents: componentNames,
      );

      if (steps.isNotEmpty && mounted) {
        setState(() {
          final index = _items.indexWhere((i) => i.id == item.id);
          if (index >= 0) {
            _items[index] = item.copyWith(verificationSteps: steps);
          }
        });
        await _saveItems();
      }
    } catch (e) {
      debugPrint('Error auto-generating verification steps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 18 : 32;
    final isNarrow = MediaQuery.sizeOf(context).width < 980;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Scope Tracking Implementation'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        if (_isLoading) const SizedBox(height: 16),
                        _buildPageHeader(context),
                        const SizedBox(height: 20),
                        _buildFilterChips(context),
                        const SizedBox(height: 24),
                        _buildStatsRow(isNarrow),
                        const SizedBox(height: 24),
                        _buildScopeTable(),
                        const SizedBox(height: 24),
                        _buildFooterNavigation(context),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'SCOPE CONTROL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scope Tracking & Implementation',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Monitor scope delivery, variance, and change approvals during execution. Ensure what is being built stays aligned with the original Scope Statement and Detailed Design.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (!isMobile) _buildHeaderActions(),
          ],
        ),
        if (isMobile) ...[
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
        FilledButton.icon(
          onPressed: _showAddItemDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Scope Item',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5E9),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    const filters = [
      'All',
      'Not Started',
      'In-Progress',
      'Verified',
      'Out-of-Scope'
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((filter) {
        final selected = _selectedFilters.contains(filter);
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFilters.clear();
              _selectedFilters.add(filter);
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
    // Calculate metrics
    final totalItems = _items.length;
    final inProgressOrVerified = _items
        .where((item) =>
            item.implementationStatus == 'In-Progress' ||
            item.implementationStatus == 'Verified')
        .length;
    final scopeAdherence = totalItems > 0
        ? ((inProgressOrVerified / totalItems) * 100).round()
        : 0;

    // Count items not in original scope (scope creep)
    final originalScopeItems = _scopeStatementDeliverables.toSet();
    final identifiedCreep = _items
        .where((item) => !originalScopeItems.contains(item.scopeItem))
        .length;

    // Count original items not started
    final trackedItems = _items.map((item) => item.scopeItem).toSet();
    final implementationGap = _scopeStatementDeliverables
        .where((deliverable) => !trackedItems.contains(deliverable))
        .length;

    final stats = [
      _StatCardData(
        'Scope Adherence',
        '$scopeAdherence%',
        '$inProgressOrVerified of $totalItems items',
        const Color(0xFF2563EB),
      ),
      _StatCardData(
        'Identified Creep',
        '$identifiedCreep',
        'Items added outside scope',
        const Color(0xFFF59E0B),
      ),
      _StatCardData(
        'Implementation Gap',
        '$implementationGap',
        'Original items not started',
        const Color(0xFFEF4444),
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
      children: stats
          .map((stat) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildStatCard(stat),
                ),
              ))
          .toList(),
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
          Text(
            data.value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: data.color),
          ),
          const SizedBox(height: 6),
          Text(data.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(data.supporting,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: data.color)),
        ],
      ),
    );
  }

  Widget _buildScopeTable() {
    final filteredItems = _items.where((item) {
      if (_selectedFilters.contains('All')) return true;
      return _selectedFilters.contains(item.implementationStatus);
    }).toList();

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
          const Text('Scope Implementation Table',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
              'Track implementation status and verification for each scope item',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          ScopeTrackingTableWidget(
            items: filteredItems,
            availableRoles: _availableRoles,
            onUpdated: (item) {
              setState(() {
                final index = _items.indexWhere((i) => i.id == item.id);
                if (index >= 0) {
                  _items[index] = item;
                } else {
                  _items.add(item);
                }
              });
            },
            onDeleted: (item) {
              setState(() {
                _items.removeWhere((i) => i.id == item.id);
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddItemDialog() async {
    final scopeItemController = TextEditingController();
    final verificationStepsController = AutoBulletTextController();
    final trackingNotesController = TextEditingController();

    String? selectedScopeItem;
    String selectedStatus = 'Not Started';
    String? selectedOwner;
    String? selectedVerificationMethod;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Scope Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedScopeItem,
                    decoration: const InputDecoration(
                      labelText: 'Scope Item/Deliverable',
                      hintText: 'Select from Scope Statement or enter new',
                    ),
                    items: [
                      ..._scopeStatementDeliverables.map((deliverable) {
                        return DropdownMenuItem<String>(
                          value: deliverable,
                          child: Text(deliverable),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: '__NEW__',
                        child: Text('+ Add New Item'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == '__NEW__') {
                        selectedScopeItem = null;
                        scopeItemController.clear();
                      } else {
                        selectedScopeItem = value;
                        scopeItemController.text = value ?? '';
                      }
                      setDialogState(() {});
                    },
                  ),
                  if (selectedScopeItem == null ||
                      selectedScopeItem == '__NEW__')
                    TextField(
                      controller: scopeItemController,
                      decoration: const InputDecoration(
                        labelText: 'Scope Item/Deliverable',
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                        labelText: 'Implementation Status'),
                    items: [
                      'Not Started',
                      'In-Progress',
                      'Verified',
                      'Out-of-Scope'
                    ]
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedStatus = value);
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedOwner,
                    decoration: const InputDecoration(labelText: 'Owner'),
                    items: _availableRoles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedOwner = value);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedVerificationMethod,
                    decoration:
                        const InputDecoration(labelText: 'Verification Method'),
                    items: ['Testing', 'UAT', 'Stakeholder Review']
                        .map((method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedVerificationMethod = value);
                    },
                  ),
                  TextField(
                    controller: verificationStepsController,
                    decoration: const InputDecoration(
                      labelText: 'Verification Steps (use "." bullets)',
                      hintText: 'Enter verification steps...',
                    ),
                    maxLines: 4,
                  ),
                  TextField(
                    controller: trackingNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Tracking Notes (prose, no bullets)',
                      hintText: 'Enter tracking notes...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final scopeItem = scopeItemController.text.trim();
                  if (scopeItem.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scope Item is required.')),
                    );
                    return;
                  }
                  final newItem = ScopeTrackingItem(
                    scopeItem: scopeItem,
                    implementationStatus: selectedStatus,
                    owner: selectedOwner ?? '',
                    verificationMethod: selectedVerificationMethod ?? '',
                    verificationSteps: verificationStepsController.text.trim(),
                    trackingNotes: trackingNotesController.text.trim(),
                  );
                  setState(() {
                    _items.add(newItem);
                  });
                  await _saveItems();
                  Navigator.of(dialogContext).pop();

                  // Auto-generate verification steps if scope item is provided
                  if (scopeItem.isNotEmpty &&
                      verificationStepsController.text.trim().isEmpty) {
                    _autoGenerateVerificationSteps(newItem);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveItems() async {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) return;

    try {
      await ExecutionPhaseService.saveScopeTrackingItems(
        projectId: projectId,
        items: _items,
      );
    } catch (e) {
      debugPrint('Error saving scope tracking items: $e');
    }
  }

  Widget _buildFooterNavigation(BuildContext context) {
    return LaunchPhaseNavigation(
      backLabel: 'Back: Agile Development Iterations',
      nextLabel: 'Next: Stakeholder Alignment',
      onBack: () => AgileDevelopmentIterationsScreen.open(context),
      onNext: () => StakeholderAlignmentScreen.open(context),
    );
  }
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
