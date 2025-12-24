import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';

class CostEstimateScreen extends StatefulWidget {
  const CostEstimateScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CostEstimateScreen()));
  }

  @override
  State<CostEstimateScreen> createState() => _CostEstimateScreenState();
}

class _CostEstimateScreenState extends State<CostEstimateScreen> {
  static const List<_CostSummary> _summaryMetrics = [
    _CostSummary(
      title: 'Total Project Cost',
      amount: 1317000.0,
      description: 'Composite of direct & indirect cost bases',
      backgroundColor: Colors.white,
      accentColor: Color(0xFF111827),
      descriptionColor: Color(0xFF6B7280),
      badgeLabel: 'All Programmes',
    ),
    _CostSummary(
      title: 'Direct Costs',
      amount: 1100000.0,
      description: '83.5% of total',
      backgroundColor: Color(0xFFEFF6FF),
      accentColor: Color(0xFF1D4ED8),
      descriptionColor: Color(0xFF1D4ED8),
      badgeLabel: 'Direct',
    ),
    _CostSummary(
      title: 'Indirect Costs',
      amount: 217000.0,
      description: '16.5% of total',
      backgroundColor: Color(0xFFEFFDF5),
      accentColor: Color(0xFF047857),
      descriptionColor: Color(0xFF047857),
      badgeLabel: 'Overheads',
    ),
  ];

  static const Map<_CostView, _CostViewDefinition> _views = {
    _CostView.direct: _CostViewDefinition(
      label: 'Direct Costs',
      description: 'Delivery spend, capital allocation & external squads',
      categories: [
        _CostCategory(title: 'Implementation Services', icon: Icons.handyman_outlined, amount: 240000.0),
        _CostCategory(title: 'Software Licences', icon: Icons.apps_outlined, amount: 215000.0),
        _CostCategory(title: 'Hardware & Infrastructure', icon: Icons.router_outlined, amount: 190000.0),
        _CostCategory(title: 'Specialist Contractors', icon: Icons.groups_2_outlined, amount: 165000.0),
        _CostCategory(title: 'Quality Assurance & Testing', icon: Icons.verified_outlined, amount: 150000.0),
        _CostCategory(title: 'Contingency Reserve', icon: Icons.savings_outlined, amount: 140000.0),
      ],
      trailingSummaryLabel: 'Total Direct Costs',
      trailingSummaryAmount: 1100000.0,
    ),
    _CostView.indirect: _CostViewDefinition(
      label: 'Indirect Costs',
      description: 'Programme overheads, enablement, shared services',
      categories: [
        _CostCategory(title: 'Rent', icon: Icons.business_outlined, amount: 42000.0),
        _CostCategory(title: 'Utilities', icon: Icons.lightbulb_outline, amount: 38000.0),
        _CostCategory(title: 'Maintenance', icon: Icons.handyman_outlined, amount: 36000.0),
        _CostCategory(title: 'Supplies', icon: Icons.inventory_2_outlined, amount: 32000.0),
        _CostCategory(title: 'Salaries', icon: Icons.people_alt_outlined, amount: 34000.0),
        _CostCategory(title: 'Accounting', icon: Icons.calculate_outlined, amount: 35000.0),
      ],
      trailingSummaryLabel: 'Total Indirect Costs',
      trailingSummaryAmount: 217000.0,
    ),
  };

  _CostView _activeView = _CostView.indirect;
  bool _showIndirectBudget = false;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final bool isTablet = AppBreakpoints.isTablet(context) && !isMobile;
    final double horizontalPadding = isMobile ? 20 : (isTablet ? 28 : 36);
    final _CostViewDefinition view = _views[_activeView]!;

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
                        const _HeroBanner(),
                        const SizedBox(height: 20),
                        _MetricStrip(metrics: _summaryMetrics, isMobile: isMobile),
                        const SizedBox(height: 26),
                        _ViewSelector(
                          activeView: _activeView,
                          definitions: _views,
                          onChanged: (view) => setState(() => _activeView = view),
                        ),
                        const SizedBox(height: 20),
                        _SectionHeader(
                          view: view,
                          onAiSuggestions: () => _showAiSuggestions(context),
                          onAddItem: () => _showAddItem(context),
                          isIndirectView: _activeView == _CostView.indirect,
                          showIndirectBudget: _showIndirectBudget,
                          onToggleIndirectBudget: () => setState(() => _showIndirectBudget = !_showIndirectBudget),
                        ),
                        const SizedBox(height: 18),
                        _CostCategoryList(view: view),
                        const SizedBox(height: 22),
                        _TrailingSummaryCard(view: view),
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

  void _showAiSuggestions(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI suggestions coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddItem(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add a cost item under ${_views[_activeView]!.label}.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          const _UserChip(name: 'Samuel kamanga', role: 'Product manager'),
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
    required this.isIndirectView,
    required this.showIndirectBudget,
    required this.onToggleIndirectBudget,
  });

  final _CostViewDefinition view;
  final VoidCallback onAiSuggestions;
  final VoidCallback onAddItem;
  final bool isIndirectView;
  final bool showIndirectBudget;
  final VoidCallback onToggleIndirectBudget;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        if (isIndirectView) ...[
          const SizedBox(height: 16),
          _IndirectBudgetToggle(
            isActive: showIndirectBudget,
            onToggle: onToggleIndirectBudget,
          ),
        ],
      ],
    );
  }
}

class _IndirectBudgetToggle extends StatelessWidget {
  const _IndirectBudgetToggle({required this.isActive, required this.onToggle});

  final bool isActive;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isActive ? onToggle : () {},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: !isActive ? const Color(0xFFFFB200) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: !isActive ? Colors.white : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: !isActive ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: !isActive ? onToggle : () {},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFFB200) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: isActive ? Colors.white : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Indirect Budget',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
  const _CostCategoryList({required this.view});

  final _CostViewDefinition view;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: view.categories
          .map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryTile(category: category),
            ),
          )
          .toList(),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final _CostCategory category;

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
            child: Icon(category.icon, size: 20, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap to expand line items & vendor notes',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Text(
            formatCurrency(category.amount),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
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

class _UserChip extends StatelessWidget {
  const _UserChip({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
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
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE5E7EB),
            child: Icon(Icons.person, size: 18, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              Text(
                role,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
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

class _CostCategory {
  const _CostCategory({required this.title, required this.icon, required this.amount});

  final String title;
  final IconData icon;
  final double amount;
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
