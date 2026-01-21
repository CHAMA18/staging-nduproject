import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/screens/scope_tracking_plan_screen.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

class CostEstimateScreen extends StatefulWidget {
  const CostEstimateScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CostEstimateScreen()));
  }

  @override
  State<CostEstimateScreen> createState() => _CostEstimateScreenState();
}

class _CostEstimateScreenState extends State<CostEstimateScreen> {
  static const Map<_CostView, _CostViewMeta> _viewMeta = {
    _CostView.direct: _CostViewMeta(
      label: 'Direct Costs',
      description: 'Delivery spend, capital allocation & external squads',
    ),
    _CostView.indirect: _CostViewMeta(
      label: 'Indirect Costs',
      description: 'Programme overheads, enablement, shared services',
    ),
  };

  _CostView _activeView = _CostView.indirect;
  bool _loadedCostItems = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCostItemsFromFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final bool isTablet = AppBreakpoints.isTablet(context) && !isMobile;
    final double horizontalPadding = isMobile ? 20 : (isTablet ? 28 : 36);
    final projectData = ProjectDataHelper.getData(context);
    final directItems = _itemsForView(projectData, _CostView.direct);
    final indirectItems = _itemsForView(projectData, _CostView.indirect);
    final double directTotal = _sumCostItems(directItems);
    final double indirectTotal = _sumCostItems(indirectItems);
    final double total = directTotal + indirectTotal;
    final viewDefinitions = {
      _CostView.direct: _buildViewDefinition(_CostView.direct, directItems, directTotal),
      _CostView.indirect: _buildViewDefinition(_CostView.indirect, indirectItems, indirectTotal),
    };
    final _CostViewDefinition view = viewDefinitions[_activeView]!;
    final summaryMetrics = _buildSummaryMetrics(total, directTotal, indirectTotal);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Cost Estimate'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopUtilityBar(onBack: () => Navigator.maybePop(context)),
                        const SizedBox(height: 24),
                        const PlanningAiNotesCard(
                          title: 'Notes',
                          sectionLabel: 'Cost Estimate',
                          noteKey: 'planning_cost_estimate_notes',
                          checkpoint: 'cost_estimate',
                          description: 'Summarize cost drivers, assumptions, and mitigation for budget risks.',
                        ),
                        const SizedBox(height: 24),
                        const _HeroBanner(),
                        const SizedBox(height: 20),
                        _MetricStrip(metrics: summaryMetrics, isMobile: isMobile),
                        const SizedBox(height: 26),
                        _ViewSelector(
                          activeView: _activeView,
                          definitions: viewDefinitions,
                          onChanged: (view) => setState(() => _activeView = view),
                        ),
                        const SizedBox(height: 20),
                        _SectionHeader(
                          view: view,
                          onAiSuggestions: () => _showAiSuggestions(context),
                          onAddItem: () => _showAddItem(context),
                        ),
                        const SizedBox(height: 18),
                        _CostCategoryList(
                          items: _activeView == _CostView.direct ? directItems : indirectItems,
                          view: _activeView,
                          iconForItem: _iconForItem,
                          onEdit: (item) => _showEditItem(context, item),
                          onDelete: (item) => _deleteItem(context, item),
                        ),
                        const SizedBox(height: 22),
                        _TrailingSummaryCard(view: view),
                        const SizedBox(height: 16),
                        LaunchPhaseNavigation(
                          backLabel: 'Back: Issue Management',
                          nextLabel: 'Next: Scope Tracking Plan',
                          onBack: () => Navigator.of(context).maybePop(),
                          onNext: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScopeTrackingPlanScreen())),
                        ),
                        const SizedBox(height: 80),
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

  List<CostEstimateItem> _itemsForView(ProjectDataModel data, _CostView view) {
    final key = _viewKey(view);
    return data.costEstimateItems.where((item) => item.costType == key).toList();
  }

  double _sumCostItems(List<CostEstimateItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.amount);
  }

  _CostViewDefinition _buildViewDefinition(_CostView view, List<CostEstimateItem> items, double total) {
    final meta = _viewMeta[view]!;
    final categories = items
        .map(
          (item) => _CostCategory(
            title: item.title,
            icon: _iconForItem(item, view),
            amount: item.amount,
            notes: item.notes,
          ),
        )
        .toList();
    return _CostViewDefinition(
      label: meta.label,
      description: meta.description,
      categories: categories,
      trailingSummaryLabel: view == _CostView.direct ? 'Total Direct Costs' : 'Total Indirect Costs',
      trailingSummaryAmount: total,
    );
  }

  List<_CostSummary> _buildSummaryMetrics(double total, double directTotal, double indirectTotal) {
    final String totalDescription = total == 0
        ? 'No cost items yet'
        : 'Composite of direct & indirect cost bases';
    final String directDescription = total == 0
        ? 'No cost items yet'
        : '${_formatPercent(directTotal / total)} of total';
    final String indirectDescription = total == 0
        ? 'No cost items yet'
        : '${_formatPercent(indirectTotal / total)} of total';

    return [
      _CostSummary(
        title: 'Total Project Cost',
        amount: total,
        description: totalDescription,
        backgroundColor: Colors.white,
        accentColor: const Color(0xFF111827),
        descriptionColor: const Color(0xFF6B7280),
        badgeLabel: total == 0 ? null : 'All Programmes',
      ),
      _CostSummary(
        title: 'Direct Costs',
        amount: directTotal,
        description: directDescription,
        backgroundColor: const Color(0xFFEFF6FF),
        accentColor: const Color(0xFF1D4ED8),
        descriptionColor: const Color(0xFF1D4ED8),
        badgeLabel: directTotal == 0 ? null : 'Direct',
      ),
      _CostSummary(
        title: 'Indirect Costs',
        amount: indirectTotal,
        description: indirectDescription,
        backgroundColor: const Color(0xFFEFFDF5),
        accentColor: const Color(0xFF047857),
        descriptionColor: const Color(0xFF047857),
        badgeLabel: indirectTotal == 0 ? null : 'Overheads',
      ),
    ];
  }

  String _formatPercent(double value) {
    final percent = (value * 100).clamp(0, 100);
    return '${percent.toStringAsFixed(1)}%';
  }

  IconData _iconForItem(CostEstimateItem item, _CostView view) {
    final iconSet = view == _CostView.direct
        ? const [
            Icons.handyman_outlined,
            Icons.apps_outlined,
            Icons.router_outlined,
            Icons.groups_2_outlined,
            Icons.verified_outlined,
            Icons.savings_outlined,
            Icons.precision_manufacturing_outlined,
            Icons.build_circle_outlined,
          ]
        : const [
            Icons.business_outlined,
            Icons.lightbulb_outline,
            Icons.handyman_outlined,
            Icons.inventory_2_outlined,
            Icons.people_alt_outlined,
            Icons.calculate_outlined,
            Icons.support_agent_outlined,
            Icons.apartment_outlined,
          ];
    final index = item.title.isEmpty ? 0 : item.title.hashCode.abs() % iconSet.length;
    return iconSet[index];
  }

  String _viewKey(_CostView view) => view == _CostView.direct ? 'direct' : 'indirect';

  Future<void> _showAiSuggestions(BuildContext context) async {
    final provider = ProjectDataHelper.getProvider(context);
    final pd = provider.projectData;
    
    // Construct context context for AI
    final projectContext = '''
Project Info:
Name: ${pd.projectName}
Objective: ${pd.projectObjective}
Description: ${pd.solutionDescription}
Business Case: ${pd.businessCase}
Current Cost Items: ${pd.costEstimateItems.map((e) => "${e.title} (${e.costType})").join(", ")}
''';

    final selectedItems = await showDialog<List<CostEstimateItem>>(
      context: context,
      builder: (ctx) => _AiSuggestionsDialog(projectContext: projectContext),
    );

    if (selectedItems != null && selectedItems.isNotEmpty) {
      final items = List<CostEstimateItem>.from(pd.costEstimateItems)..addAll(selectedItems);
      provider.updateField((data) => data.copyWith(costEstimateItems: items));
      await provider.saveToFirebase(checkpoint: 'cost_estimate');
      
      // Also persist individually if needed, though saving full list usually suffices
      for (final item in selectedItems) {
        await _persistCostItem(item);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${selectedItems.length} items from AI suggestions'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showAddItem(BuildContext context) async {
    final selected = await showDialog<CostEstimateItem>(
      context: context,
      builder: (dialogContext) => _AddCostItemDialog(initialView: _activeView),
    );

    if (selected == null) return;

    final provider = ProjectDataHelper.getProvider(context);
    final items = List<CostEstimateItem>.from(provider.projectData.costEstimateItems)..add(selected);
    provider.updateField((data) => data.copyWith(costEstimateItems: items));
    await provider.saveToFirebase(checkpoint: 'cost_estimate');
    await _persistCostItem(selected);
  }

  Future<void> _showEditItem(BuildContext context, CostEstimateItem existing) async {
    final updated = await showDialog<CostEstimateItem>(
      context: context,
      builder: (dialogContext) => _AddCostItemDialog(
        initialView: existing.costType == 'direct' ? _CostView.direct : _CostView.indirect,
        existingItem: existing,
      ),
    );

    if (updated == null) return;

    final provider = ProjectDataHelper.getProvider(context);
    final items = provider.projectData.costEstimateItems.map((i) => i.id == existing.id ? updated : i).toList();
    provider.updateField((data) => data.copyWith(costEstimateItems: items));
    await provider.saveToFirebase(checkpoint: 'cost_estimate');
    await _persistCostItem(updated);
  }

  Future<void> _deleteItem(BuildContext context, CostEstimateItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete cost item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    final provider = ProjectDataHelper.getProvider(context);
    final items = provider.projectData.costEstimateItems.where((i) => i.id != item.id).toList();
    provider.updateField((data) => data.copyWith(costEstimateItems: items));
    await provider.saveToFirebase(checkpoint: 'cost_estimate');

    // Delete from Firestore
    final projectId = provider.projectData.projectId;
    if (projectId != null && projectId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('cost_estimate_items')
          .doc(item.id)
          .delete();
    }
  }

  Future<void> _loadCostItemsFromFirestore() async {
    if (_loadedCostItems) return;
    final provider = ProjectDataHelper.getProvider(context);
    final projectId = provider.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    if (provider.projectData.costEstimateItems.isNotEmpty) {
      _loadedCostItems = true;
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('cost_estimate_items')
          .get();
      if (snapshot.docs.isEmpty) {
        _loadedCostItems = true;
        return;
      }

      final items = snapshot.docs
          .map((doc) => CostEstimateItem.fromJson(doc.data()))
          .toList();
      provider.updateField((data) => data.copyWith(costEstimateItems: items));
      _loadedCostItems = true;
    } catch (error) {
      debugPrint('Failed to load cost estimate items: $error');
    }
  }

  Future<void> _persistCostItem(CostEstimateItem item) async {
    final provider = ProjectDataHelper.getProvider(context);
    final projectId = provider.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('cost_estimate_items')
        .doc(item.id)
        .set(item.toJson(), SetOptions(merge: true));
  }
}

class _TopUtilityBar extends StatelessWidget {
  const _TopUtilityBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _circleButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 12),
          _circleButton(icon: Icons.arrow_forward_ios_rounded),
          const SizedBox(width: 20),
          const Text(
            'Cost Estimate',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          const Spacer(),
          const _UserChip(name: '', role: ''),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB200),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB200).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Project Cost Estimate',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Comprehensive breakdown of all project costs by category.',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          const Icon(Icons.stacked_bar_chart_rounded, color: Colors.white, size: 46),
        ],
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.metrics, required this.isMobile});

  final List<_CostSummary> metrics;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: metrics
          .map(
            (metric) => _MetricCard(
              summary: metric,
              width: isMobile ? double.infinity : 260,
            ),
          )
          .toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.summary, required this.width});

  final _CostSummary summary;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: summary.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: summary.accentColor.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: summary.accentColor.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.badgeLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: summary.accentColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stacked_line_chart, size: 14, color: summary.accentColor),
                  const SizedBox(width: 6),
                  Text(
                    summary.badgeLabel!,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: summary.accentColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            summary.title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: summary.accentColor.withOpacity(0.9)),
          ),
          const SizedBox(height: 12),
          Text(
            formatCurrency(summary.amount),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: summary.accentColor),
          ),
          const SizedBox(height: 8),
          Text(
            summary.description,
            style: TextStyle(fontSize: 12, color: summary.descriptionColor),
          ),
        ],
      ),
    );
  }
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({required this.activeView, required this.definitions, required this.onChanged});

  final _CostView activeView;
  final Map<_CostView, _CostViewDefinition> definitions;
  final ValueChanged<_CostView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: _CostView.values.map((view) {
          final bool isActive = view == activeView;
          final _CostViewDefinition definition = definitions[view]!;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(view),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFFB200) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      definition.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      definition.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? Colors.white.withValues(alpha: 0.82) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.view,
    required this.onAiSuggestions,
    required this.onAddItem,
  });

  final _CostViewDefinition view;
  final VoidCallback onAiSuggestions;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${view.label} Categories',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 6),
              Text(
                view.description,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Align(
            alignment: isMobile ? Alignment.centerLeft : Alignment.centerRight,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: isMobile ? WrapAlignment.start : WrapAlignment.end,
              children: [
                _OutlinedActionButton(
                  label: 'AI Suggestions',
                  icon: Icons.bolt_outlined,
                  onPressed: onAiSuggestions,
                ),
                _FilledActionButton(
                  label: 'Add Cost Item',
                  icon: Icons.add,
                  onPressed: onAddItem,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        foregroundColor: const Color(0xFF0F172A),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _FilledActionButton extends StatelessWidget {
  const _FilledActionButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: const Color(0xFFFFB200),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}

class _CostCategoryList extends StatelessWidget {
  const _CostCategoryList({
    required this.items,
    required this.view,
    required this.iconForItem,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CostEstimateItem> items;
  final _CostView view;
  final IconData Function(CostEstimateItem, _CostView) iconForItem;
  final void Function(CostEstimateItem) onEdit;
  final void Function(CostEstimateItem) onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyCostState(viewLabel: view == _CostView.direct ? 'Direct Costs' : 'Indirect Costs');
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryTile(
                item: item,
                icon: iconForItem(item, view),
                onEdit: () => onEdit(item),
                onDelete: () => onDelete(item),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EmptyCostState extends StatelessWidget {
  const _EmptyCostState({required this.viewLabel});

  final String viewLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_task, color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No $viewLabel yet',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add your first cost item to start tracking estimates here.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.item,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
  });

  final CostEstimateItem item;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  item.notes.isEmpty ? 'No notes added' : item.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCurrency(item.amount),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
            tooltip: 'Edit',
            splashRadius: 18,
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
            tooltip: 'Delete',
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _TrailingSummaryCard extends StatelessWidget {
  const _TrailingSummaryCard({required this.view});

  final _CostViewDefinition view;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              view.trailingSummaryLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            Text(
              formatCurrency(view.trailingSummaryAmount),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCostItemDialog extends StatefulWidget {
  const _AddCostItemDialog({required this.initialView, this.existingItem});

  final _CostView initialView;
  final CostEstimateItem? existingItem;

  @override
  State<_AddCostItemDialog> createState() => _AddCostItemDialogState();
}

class _AddCostItemDialogState extends State<_AddCostItemDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late _CostView _selectedView = widget.initialView;
  bool _showValidation = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    if (existing != null) {
      _titleController.text = existing.title;
      _amountController.text = existing.amount.toStringAsFixed(2);
      _notesController.text = existing.notes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForView(_selectedView);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 12, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(0.16),
                    accent.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_isEditing ? Icons.edit_outlined : Icons.add_circle_outline, color: accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Cost Item' : 'Add Cost Item',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEditing
                              ? 'Update cost details for ${_viewLabel(_selectedView)}.'
                              : 'Capture a new cost line under ${_viewLabel(_selectedView)}.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Form(
                key: _formKey,
                autovalidateMode: _showValidation ? AutovalidateMode.always : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DialogLabel(label: 'Category'),
                    const SizedBox(height: 8),
                    _TypeSelector(
                      selectedView: _selectedView,
                      onChanged: (value) => setState(() => _selectedView = value),
                    ),
                    const SizedBox(height: 18),
                    _DialogLabel(label: 'Cost item'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('e.g., Vendor integration services'),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Add a short name for this cost item';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _DialogLabel(label: 'Estimated amount'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('0.00', prefix: '\$'),
                      validator: (value) {
                        final amount = _parseAmount(value ?? '');
                        if (amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _DialogLabel(label: 'Notes (optional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: _inputDecoration('Add vendor notes, scope details, or assumptions'),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              foregroundColor: const Color(0xFF475569),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(_isEditing ? 'Update item' : 'Add item', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _showValidation = true);
      return;
    }

    final amount = _parseAmount(_amountController.text);
    final item = CostEstimateItem(
      id: _isEditing ? widget.existingItem!.id : null,
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
      amount: amount,
      costType: _viewKey(_selectedView),
    );
    Navigator.of(context).pop(item);
  }

  double _parseAmount(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  InputDecoration _inputDecoration(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixStyle: const TextStyle(color: Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  Color _accentForView(_CostView view) => view == _CostView.direct ? const Color(0xFF2563EB) : const Color(0xFF047857);

  String _viewLabel(_CostView view) => view == _CostView.direct ? 'Direct Costs' : 'Indirect Costs';

  String _viewKey(_CostView view) => view == _CostView.direct ? 'direct' : 'indirect';
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selectedView, required this.onChanged});

  final _CostView selectedView;
  final ValueChanged<_CostView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: _CostView.values.map((view) {
          final bool isActive = view == selectedView;
          final Color accent = view == _CostView.direct ? const Color(0xFF2563EB) : const Color(0xFF047857);
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(view),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      view == _CostView.direct ? Icons.trending_up : Icons.layers_outlined,
                      size: 16,
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      view == _CostView.direct ? 'Direct Costs' : 'Indirect Costs',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DialogLabel extends StatelessWidget {
  const _DialogLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = FirebaseAuthService.displayNameOrEmail(fallback: name.isNotEmpty ? name : 'User');
    final email = user?.email ?? '';
    final primary = displayName.isNotEmpty ? displayName : (email.isNotEmpty ? email : name);
    final photoUrl = user?.photoURL ?? '';

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final resolvedRole = isAdmin ? 'Admin' : 'Member';
        final roleText = role.isNotEmpty ? role : resolvedRole;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Text(
                        primary.isNotEmpty ? primary[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  ),
                  Text(
                    roleText,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CostSummary {
  const _CostSummary({
    required this.title,
    required this.amount,
    required this.description,
    this.backgroundColor = Colors.white,
    this.accentColor = const Color(0xFF111827),
    this.descriptionColor = const Color(0xFF6B7280),
    this.badgeLabel,
  });

  final String title;
  final double amount;
  final String description;
  final Color backgroundColor;
  final Color accentColor;
  final Color descriptionColor;
  final String? badgeLabel;
}

class _CostViewMeta {
  const _CostViewMeta({required this.label, required this.description});

  final String label;
  final String description;
}

class _CostCategory {
  const _CostCategory({required this.title, required this.icon, required this.amount, this.notes = ''});

  final String title;
  final IconData icon;
  final double amount;
  final String notes;
}

enum _CostView { direct, indirect }

class _CostViewDefinition {
  const _CostViewDefinition({
    required this.label,
    required this.description,
    required this.categories,
    required this.trailingSummaryLabel,
    required this.trailingSummaryAmount,
  });

  final String label;
  final String description;
  final List<_CostCategory> categories;
  final String trailingSummaryLabel;
  final double trailingSummaryAmount;
}

String formatCurrency(double value) {
  final parts = value.toStringAsFixed(2).split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'(?<!^)(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return "\$$whole.${parts.last}";
}

class _AiSuggestionsDialog extends StatefulWidget {
  const _AiSuggestionsDialog({required this.projectContext});

  final String projectContext;

  @override
  State<_AiSuggestionsDialog> createState() => _AiSuggestionsDialogState();
}

class _AiSuggestionsDialogState extends State<_AiSuggestionsDialog> {
  final _service = OpenAiServiceSecure();
  bool _loading = false;
  List<CostEstimateItem> _suggestions = [];
  final Set<int> _selectedIndices = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    setState(() {
      _loading = true;
      _error = null;
      _suggestions = [];
      _selectedIndices.clear();
    });

    try {
      final items = await _service.generateCostEstimateSuggestions(context: widget.projectContext);
      if (mounted) {
        setState(() {
          _suggestions = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _loading = false;
        });
      }
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _addSelected() {
    final selected = _selectedIndices.map((i) => _suggestions[i]).toList();
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'AI Cost Suggestions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Select suggested items to add to your estimate.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 3),
                          SizedBox(height: 16),
                          Text('Generating realistic estimates...', style: TextStyle(color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  )
                : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _fetchSuggestions,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _suggestions.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No suggestions found. Try regenerating.', style: TextStyle(color: Color(0xFF64748B))),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final item = _suggestions[index];
                          final isSelected = _selectedIndices.contains(index);
                          return InkWell(
                            onTap: () => _toggleSelection(index),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.costType.toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.notes,
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          formatCurrency(item.amount),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2563EB), // Blue-600
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _loading ? null : _fetchSuggestions,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Regenerate'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                         onPressed: _selectedIndices.isEmpty ? null : _addSelected,
                         style: FilledButton.styleFrom(
                           backgroundColor: const Color(0xFF2563EB),
                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         child: Text('Add Selected (${_selectedIndices.length})'),
                      ),
                    ],
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
