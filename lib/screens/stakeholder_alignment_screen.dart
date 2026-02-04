import 'package:flutter/material.dart';
import 'package:ndu_project/screens/scope_tracking_implementation_screen.dart';
import 'package:ndu_project/screens/update_ops_maintenance_plans_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/execution_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/stakeholder_alignment_item.dart';
import 'package:ndu_project/widgets/stakeholder_alignment_table_widget.dart';
import 'package:ndu_project/utils/auto_bullet_text_controller.dart';

class StakeholderAlignmentScreen extends StatefulWidget {
  const StakeholderAlignmentScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StakeholderAlignmentScreen()),
    );
  }

  @override
  State<StakeholderAlignmentScreen> createState() =>
      _StakeholderAlignmentScreenState();
}

class _StakeholderAlignmentScreenState
    extends State<StakeholderAlignmentScreen> {
  final Set<String> _selectedFilters = {'All'};
  List<StakeholderAlignmentItem> _items = [];
  List<Map<String, String>> _coreStakeholders = [];
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
      _loadCoreStakeholders();
    });
  }

  Future<void> _loadItems() async {
    final projectId = _projectId;
    if (projectId == null) return;

    setState(() => _isLoading = true);
    try {
      final items = await ExecutionPhaseService.loadStakeholderAlignmentItems(
          projectId: projectId);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stakeholder alignment items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCoreStakeholders() async {
    final projectId = _projectId;
    if (projectId == null) return;

    try {
      final stakeholders = await ExecutionPhaseService.loadCoreStakeholders(
          projectId: projectId);
      if (mounted) {
        setState(() {
          _coreStakeholders = stakeholders;
        });
        // Auto-populate stakeholders if none exist
        if (_items.isEmpty && stakeholders.isNotEmpty) {
          _autoPopulateStakeholders(stakeholders);
        }
      }
    } catch (e) {
      debugPrint('Error loading core stakeholders: $e');
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
                  activeItemLabel: 'Stakeholder Alignment'),
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
                        _buildStakeholderTable(),
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
            'STAKEHOLDER ALIGNMENT',
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
                    'Stakeholder Alignment',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Stakeholder Alignment must pull from your earlier work to show how well you\'ve met expectations. Keep sponsors, operations, and governance aligned as execution closes.',
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
          onPressed: _showAddStakeholderDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Stakeholder',
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
    const filters = ['All', 'Aligned', 'Neutral', 'Concerned', 'Resistent'];
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
    final alignedCount =
        _items.where((item) => item.alignmentStatus == 'Aligned').length;
    final consensusScore =
        totalItems > 0 ? ((alignedCount / totalItems) * 100).round() : 0;

    // Engagement rate: stakeholders with feedback or engagement date
    final engagedCount = _items
        .where((item) =>
            item.feedbackSummary.isNotEmpty || item.lastEngagementDate != null)
        .length;
    final engagementRate =
        totalItems > 0 ? ((engagedCount / totalItems) * 100).round() : 0;

    // Open concerns: Concerned or Resistent stakeholders
    final openConcerns = _items
        .where((item) =>
            item.alignmentStatus == 'Concerned' ||
            item.alignmentStatus == 'Resistent')
        .length;

    final stats = [
      _StatCardData(
        'Consensus Score',
        '$consensusScore%',
        '$alignedCount of $totalItems aligned',
        const Color(0xFF10B981),
      ),
      _StatCardData(
        'Engagement Rate',
        '$engagementRate%',
        '$engagedCount stakeholders engaged',
        const Color(0xFF2563EB),
      ),
      _StatCardData(
        'Open Concerns',
        '$openConcerns',
        'Require attention',
        const Color(0xFFF59E0B),
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

  Widget _buildStakeholderTable() {
    final filteredItems = _items.where((item) {
      if (_selectedFilters.contains('All')) return true;
      return _selectedFilters.contains(item.alignmentStatus);
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
          const Text('Stakeholder Alignment Table',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
              'Track alignment status, engagement, and feedback for each stakeholder',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          StakeholderAlignmentTableWidget(
            items: filteredItems,
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

  Future<void> _showAddStakeholderDialog() async {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final feedbackController = TextEditingController();
    final engagementStrategyController = AutoBulletTextController();

    String? selectedStakeholder;
    String selectedStatus = 'Neutral';
    String? selectedKeyInterest;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Stakeholder'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedStakeholder,
                    decoration: const InputDecoration(
                      labelText: 'Stakeholder Name/Role',
                      hintText: 'Select from Core Stakeholders or enter new',
                    ),
                    items: [
                      ..._coreStakeholders.map((stakeholder) {
                        final displayName =
                            '${stakeholder['name']} - ${stakeholder['role']}';
                        return DropdownMenuItem<String>(
                          value: displayName,
                          child: Text(displayName),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: '__NEW__',
                        child: Text('+ Add New Stakeholder'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == '__NEW__') {
                        selectedStakeholder = null;
                        nameController.clear();
                        roleController.clear();
                      } else if (value != null) {
                        selectedStakeholder = value;
                        final parts = value.split(' - ');
                        nameController.text = parts[0];
                        roleController.text = parts.length > 1 ? parts[1] : '';
                      }
                      setDialogState(() {});
                    },
                  ),
                  if (selectedStakeholder == null ||
                      selectedStakeholder == '__NEW__') ...[
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Stakeholder Name',
                      ),
                    ),
                    TextField(
                      controller: roleController,
                      decoration: const InputDecoration(
                        labelText: 'Stakeholder Role',
                      ),
                    ),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration:
                        const InputDecoration(labelText: 'Alignment Status'),
                    items: ['Aligned', 'Neutral', 'Concerned', 'Resistent']
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
                    initialValue: selectedKeyInterest,
                    decoration:
                        const InputDecoration(labelText: 'Key Interest/Value'),
                    items: [
                      'ROI',
                      'Security',
                      'Ease of Use',
                      'Cost Savings',
                      'Revenue',
                      'Compliance',
                      'Performance',
                      'Innovation',
                      'Risk Mitigation',
                      'User Experience',
                    ]
                        .map((interest) => DropdownMenuItem(
                              value: interest,
                              child: Text(interest),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedKeyInterest = value);
                    },
                  ),
                  TextField(
                    controller: feedbackController,
                    decoration: const InputDecoration(
                      labelText: 'Feedback Summary (prose, no bullets)',
                      hintText: 'Enter feedback...',
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
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Stakeholder Name is required.')),
                    );
                    return;
                  }
                  final newItem = StakeholderAlignmentItem(
                    stakeholderName: name,
                    stakeholderRole: roleController.text.trim(),
                    alignmentStatus: selectedStatus,
                    keyInterest: selectedKeyInterest ?? '',
                    feedbackSummary: feedbackController.text.trim(),
                    engagementStrategy:
                        engagementStrategyController.text.trim(),
                  );
                  setState(() {
                    _items.add(newItem);
                  });
                  await _saveItems();
                  Navigator.of(dialogContext).pop();

                  // Auto-generate engagement strategy if key fields are filled
                  if (name.isNotEmpty &&
                      (selectedKeyInterest != null ||
                          roleController.text.trim().isNotEmpty)) {
                    _autoGenerateEngagementStrategy(newItem);
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

  Future<void> _autoPopulateStakeholders(
      List<Map<String, String>> stakeholders) async {
    final projectId = _projectId;
    if (projectId == null) return;

    try {
      final newItems = <StakeholderAlignmentItem>[];
      for (final stakeholder in stakeholders.take(10)) {
        // Limit to first 10
        final name = stakeholder['name'] ?? '';
        final role = stakeholder['role'] ?? 'Stakeholder';
        if (name.isNotEmpty) {
          // Check if this stakeholder already exists
          final exists = _items.any((item) =>
              item.stakeholderName == name && item.stakeholderRole == role);
          if (!exists) {
            newItems.add(StakeholderAlignmentItem(
              stakeholderName: name,
              stakeholderRole: role,
              alignmentStatus: 'Neutral',
              keyInterest: '',
            ));
          }
        }
      }
      if (newItems.isNotEmpty) {
        setState(() {
          _items.addAll(newItems);
        });
        await _saveItems();
        // Auto-generate engagement strategies for new stakeholders
        for (final item in newItems) {
          _autoGenerateEngagementStrategy(item);
        }
      }
    } catch (e) {
      debugPrint('Error auto-populating stakeholders: $e');
    }
  }

  Future<void> _autoGenerateEngagementStrategy(
      StakeholderAlignmentItem item) async {
    if (item.stakeholderName.isEmpty) return;

    try {
      final provider = ProjectDataInherited.maybeOf(context);
      if (provider == null) return;

      final projectId = provider.projectData.projectId;
      if (projectId == null || projectId.isEmpty) return;

      final projectData = provider.projectData;

      final projectContext =
          ProjectDataHelper.buildExecutivePlanContext(projectData);
      final openAiService = OpenAiServiceSecure();
      final strategy = await openAiService.generateEngagementStrategy(
        context: projectContext,
        stakeholderName: item.stakeholderName,
        stakeholderRole: item.stakeholderRole,
        keyInterest: item.keyInterest.isNotEmpty ? item.keyInterest : 'ROI',
        alignmentStatus: item.alignmentStatus,
        feedbackSummary: item.feedbackSummary,
      );

      if (strategy.isNotEmpty && mounted) {
        setState(() {
          final index = _items.indexWhere((i) => i.id == item.id);
          if (index >= 0) {
            _items[index] = item.copyWith(engagementStrategy: strategy);
          }
        });
        await _saveItems();
      }
    } catch (e) {
      debugPrint('Error auto-generating engagement strategy: $e');
    }
  }

  Future<void> _saveItems() async {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) return;

    try {
      await ExecutionPhaseService.saveStakeholderAlignmentItems(
        projectId: projectId,
        items: _items,
      );
    } catch (e) {
      debugPrint('Error saving stakeholder alignment items: $e');
    }
  }

  Widget _buildFooterNavigation(BuildContext context) {
    return LaunchPhaseNavigation(
      backLabel: 'Back: Scope Tracking Implementation',
      nextLabel: 'Next: Update Ops & Maintenance Plans',
      onBack: () => ScopeTrackingImplementationScreen.open(context),
      onNext: () => UpdateOpsMaintenancePlansScreen.open(context),
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
