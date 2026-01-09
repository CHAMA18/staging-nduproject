import 'package:flutter/material.dart';

import 'package:ndu_project/screens/risk_tracking_screen.dart';
import 'package:ndu_project/screens/update_ops_maintenance_plans_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class LaunchChecklistScreen extends StatefulWidget {
  const LaunchChecklistScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LaunchChecklistScreen()),
    );
  }

  @override
  State<LaunchChecklistScreen> createState() => _LaunchChecklistScreenState();
}

class _LaunchChecklistScreenState extends State<LaunchChecklistScreen> {
  final Set<String> _selectedFocusFilters = {'Readiness'};
  final Set<String> _selectedVisibilityFilters = {'Show dependencies'};

  static const List<String> _focusOptions = [
    'Readiness',
    'Execution',
    'Support',
    'Stakeholders',
    'Risk',
  ];

  static const List<String> _visibilityOptions = [
    'Show dependencies',
    'Highlight blockers',
    'Include completed',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: 'Launch Checklist',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(context, isMobile),
            const SizedBox(height: 20),
            _buildContextChips(isMobile),
            const SizedBox(height: 24),
            _buildToolbar(context),
            const SizedBox(height: 24),
            _buildStatusOverview(context),
            const SizedBox(height: 24),
            _buildChecklistBoard(context),
            const SizedBox(height: 24),
            _buildTimelineAndHighlights(context),
            const SizedBox(height: 28),
            _buildInsightsGrid(context),
            const SizedBox(height: 48),
            LaunchPhaseNavigation(
              backLabel: 'Back: Update Ops & Maintenance Plans',
              nextLabel: 'Next: Risk Tracking',
              onBack: () => UpdateOpsMaintenancePlansScreen.open(context),
              onNext: () => RiskTrackingScreen.open(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Launch Checklist',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: isMobile ? 24 : 30,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Coordinate cutover tasks, spotlight go-live risks, and align your launch room around the same priorities.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5563),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContextChips(bool isCompact) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _contextChips
          .map(
            (chip) => Container(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chip.icon, size: 18, color: const Color(0xFF6366F1)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chip.label,
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chip.value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              const Text(
                'Focus',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.article_outlined, size: 18),
                    label: const Text('Export runbook'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_active_outlined, size: 18),
                    label: const Text('Send launch update'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _focusOptions
                .map(
                  (option) => ChoiceChip(
                    label: Text(option),
                    selected: _selectedFocusFilters.contains(option),
                    onSelected: (_) => setState(() {
                      _selectedFocusFilters
                        ..clear()
                        ..add(option);
                    }),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    selectedColor: primary.withOpacity(0.12),
                    backgroundColor: const Color(0xFFF3F4F6),
                    labelStyle: TextStyle(
                      fontWeight: _selectedFocusFilters.contains(option) ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedFocusFilters.contains(option) ? primary : const Color(0xFF4B5563),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE5E7EB), height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _visibilityOptions
                .map(
                  (option) => FilterChip(
                    label: Text(option),
                    selected: _selectedVisibilityFilters.contains(option),
                    onSelected: (_) => setState(() {
                      if (_selectedVisibilityFilters.contains(option)) {
                        _selectedVisibilityFilters.remove(option);
                      } else {
                        _selectedVisibilityFilters.add(option);
                      }
                    }),
                    showCheckmark: false,
                    backgroundColor: const Color(0xFFF9FAFB),
                    selectedColor: const Color(0xFFEEF2FF),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _selectedVisibilityFilters.contains(option) ? const Color(0xFF3730A3) : const Color(0xFF4B5563),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isCompact = constraints.maxWidth < 920;
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConfidenceGauge(),
                    const SizedBox(height: 22),
                    _buildStatusMetricPanel(context),
                    const SizedBox(height: 22),
                    _buildMilestonesPanel(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfidenceGauge(),
                  const SizedBox(width: 24),
                  Expanded(child: _buildStatusMetricPanel(context)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildMilestonesPanel()),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool stack = constraints.maxWidth < 840;
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReadinessProgress(context),
                    const SizedBox(height: 24),
                    _buildApprovalAndCoordinatorPanel(context),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildReadinessProgress(context)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildApprovalAndCoordinatorPanel(context)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceGauge() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Confidence',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4C1D95),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: const [
                CircularProgressIndicator(
                  value: 0.68,
                  strokeWidth: 12,
                  backgroundColor: Color(0xFFE0E7FF),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '68%',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF312E81)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'On track',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4338CA)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.trending_up_rounded, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Trending stable · no net-new blockers escalated',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetricPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Launch status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
        ),
        const SizedBox(height: 12),
        ..._statusMetrics.map((metric) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: metric.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: metric.borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: metric.accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(metric.icon, size: 20, color: metric.accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          metric.value,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (metric.annotation != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            metric.annotation!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMilestonesPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Launch playbook',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 10),
          ..._milestones.map((milestone) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(milestone.icon, color: const Color(0xFF0C4A6E), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                milestone.title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: milestone.badgeColor.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                milestone.badgeLabel,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: milestone.badgeColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          milestone.detail,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          milestone.dateLabel,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.folder_copy_outlined),
            label: const Text('Open launch war room agenda'),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessProgress(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Launch readiness tracker',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              SizedBox(width: 10),
              _StatusPill('On track'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: const LinearProgressIndicator(
              value: 0.72,
              minHeight: 14,
              backgroundColor: Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '5 of 7 critical path items cleared · Next review Tue 10:00 AM',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _ReadinessTag(label: 'Cutover rehearsal', status: 'Complete'),
              _ReadinessTag(label: 'Rollback playbook', status: 'In review'),
              _ReadinessTag(label: 'Support playbooks', status: 'At risk'),
              _ReadinessTag(label: 'Customer comms', status: 'On track'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalAndCoordinatorPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Critical approvals & ownership',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          ..._approvalItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                              ),
                            ),
                            _StatusPill(item.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.detail,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Launch coordinator',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Morgan Reyes · Program Launch Director',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'morgan.reyes@example.com · +1 312 555 0196',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Open in Teams'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistBoard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Checklist items',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Track execution readiness and align owners on every launch-critical activity.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                    label: const Text('Assign owners'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add checklist item'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Expanded(flex: 4, child: _TableHeader(label: 'Checklist item')),
                Expanded(flex: 2, child: _TableHeader(label: 'Owner')),
                Expanded(flex: 2, child: _TableHeader(label: 'Due by')),
                Expanded(flex: 2, child: _TableHeader(label: 'Status')),
                SizedBox(width: 32),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ..._checklistRows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final bool isOdd = index.isOdd;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: isOdd ? const Color(0xFFF9FAFB) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          row.detail,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                        ),
                        if (row.flagLabel != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              row.flagLabel!,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.owner,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.due,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: _StatusPill(row.status),
                  ),
                  IconButton(
                    tooltip: 'More actions',
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineAndHighlights(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineCard(),
        const SizedBox(height: 24),
        _buildLaunchHighlightsCard(),
      ],
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Launch timeline & guardrails',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              SizedBox(width: 10),
              _StatusPill('In review'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.62,
              minHeight: 10,
              backgroundColor: Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Current phase: Cutover rehearsals · Go / no-go rehearsal in 3 days',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 18),
          ..._timelineStages.map((stage) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: stage.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(stage.icon, color: stage.accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stage.label,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                              ),
                            ),
                            Text(
                              stage.date,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stage.detail,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _InfoPill(icon: Icons.flag_circle_outlined, label: 'Go-live decision: 17 Aug, 09:00 AM'),
              _InfoPill(icon: Icons.groups_2_outlined, label: 'Hypercare squad rota confirmed'),
              _InfoPill(icon: Icons.safety_check, label: 'Rollback rehearsal scheduled for Fri'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchHighlightsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guardrails & escalation paths',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Keep stakeholders ready across risk scenarios, comms, and analytics coverage.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 16),
          ..._highlightItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.accent.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                                ),
                              ),
                              _StatusPill(item.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.detail,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                          ),
                          if (item.ctaLabel != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                              child: Text(item.ctaLabel!, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < _insightCards.length; i++) ...[
          _LaunchInsightCard(data: _insightCards[i]),
          if (i != _insightCards.length - 1) const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _LaunchInsightCard extends StatelessWidget {
  const _LaunchInsightCard({required this.data});

  final _InsightCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
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
                      data.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: data.tagColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  data.tag,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: data.tagColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: entry.iconColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(entry.icon, color: entry.iconColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.label,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                              ),
                            ),
                            if (entry.status != null) _StatusPill(entry.status!),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.detail,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (data.footerLabel != null) ...[
            const Divider(color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                data.footerLabel!,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final visual = _statusVisuals[status] ?? _statusVisuals['On track']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: visual.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 16, color: visual.textColor),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: visual.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessTag extends StatelessWidget {
  const _ReadinessTag({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(width: 10),
          _StatusPill(status),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }
}

class _InfoChipData {
  const _InfoChipData({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

class _StatusMetricData {
  const _StatusMetricData({
    required this.label,
    required this.value,
    this.annotation,
    required this.icon,
    required this.accentColor,
    required this.background,
    required this.borderColor,
  });

  final String label;
  final String value;
  final String? annotation;
  final IconData icon;
  final Color accentColor;
  final Color background;
  final Color borderColor;
}

class _MilestoneData {
  const _MilestoneData({
    required this.title,
    required this.detail,
    required this.dateLabel,
    required this.badgeLabel,
    required this.badgeColor,
    required this.icon,
  });

  final String title;
  final String detail;
  final String dateLabel;
  final String badgeLabel;
  final Color badgeColor;
  final IconData icon;
}

class _ApprovalItem {
  const _ApprovalItem({
    required this.label,
    required this.detail,
    required this.status,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String label;
  final String detail;
  final String status;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
}

class _ChecklistRowData {
  const _ChecklistRowData({
    required this.title,
    required this.detail,
    required this.owner,
    required this.due,
    required this.status,
    this.flagLabel,
  });

  final String title;
  final String detail;
  final String owner;
  final String due;
  final String status;
  final String? flagLabel;
}

class _TimelineStage {
  const _TimelineStage({
    required this.label,
    required this.detail,
    required this.date,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String detail;
  final String date;
  final IconData icon;
  final Color accent;
}

class _HighlightItem {
  const _HighlightItem({
    required this.title,
    required this.detail,
    required this.status,
    required this.icon,
    required this.accent,
    this.ctaLabel,
  });

  final String title;
  final String detail;
  final String status;
  final IconData icon;
  final Color accent;
  final String? ctaLabel;
}

class _InsightCardData {
  const _InsightCardData({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.entries,
    this.footerLabel,
  });

  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final List<_InsightEntryData> entries;
  final String? footerLabel;
}

class _InsightEntryData {
  const _InsightEntryData({
    required this.label,
    required this.detail,
    required this.icon,
    required this.iconColor,
    this.status,
  });

  final String label;
  final String detail;
  final IconData icon;
  final Color iconColor;
  final String? status;
}

class _StatusVisual {
  const _StatusVisual({
    required this.background,
    required this.border,
    required this.textColor,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color textColor;
  final IconData icon;
}

const List<_InfoChipData> _contextChips = [
  _InfoChipData(
    icon: Icons.flag_outlined,
    label: 'Program',
    value: 'AI operations uplift · Launch phase',
  ),
  _InfoChipData(
    icon: Icons.layers_outlined,
    label: 'Workstream',
    value: 'Customer experience platform',
  ),
  _InfoChipData(
    icon: Icons.calendar_month_outlined,
    label: 'Go-live window',
    value: 'Target 18 Aug · T−9 days',
  ),
  _InfoChipData(
    icon: Icons.update,
    label: 'Last sync',
    value: 'Executive review · 2h ago',
  ),
];

const List<_StatusMetricData> _statusMetrics = [
  _StatusMetricData(
    label: 'Current stage',
    value: 'Final launch readiness',
    annotation: 'All squads aligned · rehearsal booked',
    icon: Icons.stacked_line_chart,
    accentColor: Color(0xFF2563EB),
    background: Color(0xFFEFF6FF),
    borderColor: Color(0xFFD2E3FC),
  ),
  _StatusMetricData(
    label: 'Next exec gate',
    value: 'Go / no-go rehearsal · Thu 10 Aug',
    annotation: 'Agenda confirmed · decks in review',
    icon: Icons.event_available_outlined,
    accentColor: Color(0xFF0EA5E9),
    background: Color(0xFFE0F2FE),
    borderColor: Color(0xFFBAE6FD),
  ),
  _StatusMetricData(
    label: 'Risk posture',
    value: '2 watch items · 0 critical blockers',
    annotation: 'Escalations held daily with Ops & Tech',
    icon: Icons.warning_amber_outlined,
    accentColor: Color(0xFFF97316),
    background: Color(0xFFFFF7ED),
    borderColor: Color(0xFFFBD5BB),
  ),
  _StatusMetricData(
    label: 'Hypercare',
    value: '14-day coverage · roster confirmed',
    annotation: 'Control room opens 16 Aug · 06:30 AM',
    icon: Icons.support_agent_outlined,
    accentColor: Color(0xFF10B981),
    background: Color(0xFFECFDF5),
    borderColor: Color(0xFFCFFADE),
  ),
];

const List<_MilestoneData> _milestones = [
  _MilestoneData(
    title: 'Cutover rehearsal playback',
    detail: 'Ops + Engineering walk-through with war room dry run',
    dateLabel: 'Due Wed · 09 Aug',
    badgeLabel: 'Scheduled',
    badgeColor: Color(0xFF2563EB),
    icon: Icons.present_to_all_outlined,
  ),
  _MilestoneData(
    title: 'Rollback drill & automation test',
    detail: 'Validate failback steps · ensure observability hooks firing',
    dateLabel: 'Due Fri · 11 Aug',
    badgeLabel: 'Requires ops',
    badgeColor: Color(0xFFF97316),
    icon: Icons.security_update_warning_outlined,
  ),
  _MilestoneData(
    title: 'Customer comms final approval',
    detail: 'Exec sign-off on launch narratives, social + support packs',
    dateLabel: 'Due Mon · 14 Aug',
    badgeLabel: 'In review',
    badgeColor: Color(0xFF7C3AED),
    icon: Icons.campaign_outlined,
  ),
];

const List<_ApprovalItem> _approvalItems = [
  _ApprovalItem(
    label: 'Cutover rehearsal sign-off',
    detail: 'Delivery, platform, and ops leads approved latest runbook.',
    status: 'Complete',
    icon: Icons.check_circle_outline,
    iconColor: Color(0xFF16A34A),
    iconBackground: Color(0xFFDCFCE7),
  ),
  _ApprovalItem(
    label: 'Business readiness validation',
    detail: 'Support staffing matrix ready · escalation tree validated.',
    status: 'On track',
    icon: Icons.business_center_outlined,
    iconColor: Color(0xFF2563EB),
    iconBackground: Color(0xFFE0F2FE),
  ),
  _ApprovalItem(
    label: 'Comms go-live bundle',
    detail: 'Legal + comms still reviewing final messaging artefacts.',
    status: 'In review',
    icon: Icons.record_voice_over_outlined,
    iconColor: Color(0xFF6366F1),
    iconBackground: Color(0xFFEEF2FF),
  ),
];

const List<_ChecklistRowData> _checklistRows = [
  _ChecklistRowData(
    title: 'Cutover rehearsals signed off',
    detail: 'Dry run #2 captured follow-up items and warm stand-by plan.',
    owner: 'Operations lead',
    due: 'Aug 12',
    status: 'On track',
  ),
  _ChecklistRowData(
    title: 'Rollback playbook distribution',
    detail: 'Share final rollback guide with exec sponsors and war room.',
    owner: 'Program manager',
    due: 'Aug 09',
    status: 'At risk',
    flagLabel: 'Escalate with executive sponsor',
  ),
  _ChecklistRowData(
    title: 'Hypercare squad roster confirmed',
    detail: 'Roster, shifts, and virtual bridge details communicated.',
    owner: 'Launch director',
    due: 'Aug 15',
    status: 'In review',
  ),
  _ChecklistRowData(
    title: 'Customer comms final approval',
    detail: 'Legal + comms sign-off for all day-zero messaging.',
    owner: 'Change & comms',
    due: 'Aug 10',
    status: 'Decision pending',
  ),
  _ChecklistRowData(
    title: 'Analytics & monitoring readiness',
    detail: 'Dashboards, alerting, and anomaly detection configured.',
    owner: 'Data & insights',
    due: 'Aug 14',
    status: 'Complete',
  ),
  _ChecklistRowData(
    title: 'Cutover war room logistics',
    detail: 'Room booking, bridge links, and comms protocol ready.',
    owner: 'PMO',
    due: 'Aug 13',
    status: 'On track',
  ),
];

const List<_TimelineStage> _timelineStages = [
  _TimelineStage(
    label: 'Final readiness review',
    detail: 'All cutover and rollback artefacts verified with stakeholders.',
    date: 'Thu · 10 Aug',
    icon: Icons.fact_check_outlined,
    accent: Color(0xFF2563EB),
  ),
  _TimelineStage(
    label: 'Go / no-go rehearsal',
    detail: 'Dry run with scenario walk-through and escalation practices.',
    date: 'Fri · 11 Aug',
    icon: Icons.groups_outlined,
    accent: Color(0xFF7C3AED),
  ),
  _TimelineStage(
    label: 'Launch readiness lock',
    detail: 'All approvals collected · war room schedule published.',
    date: 'Mon · 14 Aug',
    icon: Icons.verified_user_outlined,
    accent: Color(0xFF16A34A),
  ),
];

const List<_HighlightItem> _highlightItems = [
  _HighlightItem(
    title: 'Stakeholder communications',
    detail: 'Exec sponsor updates drafted · customer comms ready for approval.',
    status: 'In review',
    icon: Icons.campaign_outlined,
    accent: Color(0xFF6366F1),
    ctaLabel: 'View comms bundle',
  ),
  _HighlightItem(
    title: 'Support & triage coverage',
    detail: 'Tier-2 rota staffed · escalation drills scheduled with SRE.',
    status: 'On track',
    icon: Icons.support_agent_outlined,
    accent: Color(0xFF0EA5E9),
    ctaLabel: 'Open support playbook',
  ),
  _HighlightItem(
    title: 'Experience & analytics guardrails',
    detail: 'Customer journey dashboards instrumented with launch-ready thresholds.',
    status: 'On track',
    icon: Icons.analytics_outlined,
    accent: Color(0xFF10B981),
  ),
];

const List<_InsightCardData> _insightCards = [
  _InsightCardData(
    title: 'Checklist overview at a glance',
    subtitle: 'Item progress, ownership coverage, and upcoming due dates.',
    tag: 'Execution',
    tagColor: Color(0xFF2563EB),
    entries: [
      _InsightEntryData(
        label: '18 active checklist items',
        detail: '12 on track · 4 in review · 2 at risk',
        icon: Icons.checklist_rtl,
        iconColor: Color(0xFF2563EB),
        status: 'On track',
      ),
      _InsightEntryData(
        label: 'Ownership coverage',
        detail: 'All stream leads assigned · 3 tasks with deputy owners.',
        icon: Icons.badge_outlined,
        iconColor: Color(0xFF0EA5E9),
      ),
      _InsightEntryData(
        label: 'Due this week',
        detail: '6 items · highlight rollback drill & comms sign-off.',
        icon: Icons.calendar_today_outlined,
        iconColor: Color(0xFFF97316),
        status: 'Highlight blockers',
      ),
    ],
    footerLabel: 'Open full checklist view',
  ),
  _InsightCardData(
    title: 'Execution management',
    subtitle: 'War room readiness, cutover rehearsals, and dependency calls.',
    tag: 'War room',
    tagColor: Color(0xFF7C3AED),
    entries: [
      _InsightEntryData(
        label: 'War room logistics',
        detail: 'Bridge links + escalation ladder circulated to squads.',
        icon: Icons.meeting_room_outlined,
        iconColor: Color(0xFF6366F1),
        status: 'On track',
      ),
      _InsightEntryData(
        label: 'Cutover rehearsal playback',
        detail: 'Action log in review · final playback on Wed.',
        icon: Icons.history_edu_outlined,
        iconColor: Color(0xFF2563EB),
        status: 'In review',
      ),
      _InsightEntryData(
        label: 'Dependency callouts',
        detail: 'Data platform dependency gating analytics automation.',
        icon: Icons.link_outlined,
        iconColor: Color(0xFFF97316),
        status: 'At risk',
      ),
    ],
  ),
  _InsightCardData(
    title: 'Experience & business readiness',
    subtitle: 'Customer journey, policy updates, and frontline enablement.',
    tag: 'CX',
    tagColor: Color(0xFF10B981),
    entries: [
      _InsightEntryData(
        label: 'Customer journey validation',
        detail: 'Support scenarios tested · KPI dashboards validated.',
        icon: Icons.route_outlined,
        iconColor: Color(0xFF10B981),
        status: 'On track',
      ),
      _InsightEntryData(
        label: 'Policy & compliance sign-off',
        detail: 'Privacy review cleared · financial controls pending note.',
        icon: Icons.verified_outlined,
        iconColor: Color(0xFF2563EB),
        status: 'In review',
      ),
      _InsightEntryData(
        label: 'Frontline enablement',
        detail: 'Knowledge base articles queued · training sessions set.',
        icon: Icons.school_outlined,
        iconColor: Color(0xFFFBBF24),
        status: 'On track',
      ),
    ],
  ),
  _InsightCardData(
    title: 'Verification & readiness tracking',
    subtitle: 'Quality gates, telemetry, and scenario walkthroughs.',
    tag: 'QA',
    tagColor: Color(0xFF2563EB),
    entries: [
      _InsightEntryData(
        label: 'Quality gate coverage',
        detail: 'All regression suites green · performance testing complete.',
        icon: Icons.fact_check_outlined,
        iconColor: Color(0xFF2563EB),
        status: 'Complete',
      ),
      _InsightEntryData(
        label: 'Telemetry alerts',
        detail: 'Observability thresholds tuned · pager alerts verified.',
        icon: Icons.leaderboard_outlined,
        iconColor: Color(0xFF0EA5E9),
        status: 'On track',
      ),
      _InsightEntryData(
        label: 'Scenario walkthroughs',
        detail: 'Critical incident scenarios rehearsed with SRE.',
        icon: Icons.science_outlined,
        iconColor: Color(0xFF7C3AED),
        status: 'In review',
      ),
    ],
  ),
  _InsightCardData(
    title: 'Launch day execution',
    subtitle: 'Control room setup, live dashboards, and hypercare plan.',
    tag: 'Launch',
    tagColor: Color(0xFF2563EB),
    entries: [
      _InsightEntryData(
        label: 'Control room readiness',
        detail: 'Logistics, access, and RACI confirmed with all leads.',
        icon: Icons.hardware_outlined,
        iconColor: Color(0xFF2563EB),
        status: 'On track',
      ),
      _InsightEntryData(
        label: 'Live dashboard coverage',
        detail: 'Product, support, and infra dashboards pinned for launch day.',
        icon: Icons.dashboard_customize_outlined,
        iconColor: Color(0xFF10B981),
        status: 'Complete',
      ),
      _InsightEntryData(
        label: 'Hypercare playbook',
        detail: 'Escalation ladder and success criteria rehearsed.',
        icon: Icons.auto_stories_outlined,
        iconColor: Color(0xFFF97316),
        status: 'In review',
      ),
    ],
  ),
  _InsightCardData(
    title: 'Stakeholder reporting & sign-offs',
    subtitle: 'Executives, partner teams, and customer comms alignment.',
    tag: 'Stakeholders',
    tagColor: Color(0xFF7C3AED),
    entries: [
      _InsightEntryData(
        label: 'Executive briefing cadence',
        detail: 'Daily updates in place · dashboard shared with ELT.',
        icon: Icons.pie_chart_outline,
        iconColor: Color(0xFF7C3AED),
        status: 'On track',
      ),
      _InsightEntryData(
        label: 'Partner team readiness',
        detail: 'Legal, finance, and CX sign-offs pending final review.',
        icon: Icons.handshake_outlined,
        iconColor: Color(0xFF2563EB),
        status: 'In review',
      ),
      _InsightEntryData(
        label: 'Customer comms status',
        detail: 'Social + email flows queued · waiting executive approval.',
        icon: Icons.mail_outline,
        iconColor: Color(0xFFF97316),
        status: 'Decision pending',
      ),
    ],
    footerLabel: 'View stakeholder deck',
  ),
];

const Map<String, _StatusVisual> _statusVisuals = {
  'On track': _StatusVisual(
    background: Color(0xFFE0F2FE),
    border: Color(0xFFBAE6FD),
    textColor: Color(0xFF0369A1),
    icon: Icons.task_alt_rounded,
  ),
  'Complete': _StatusVisual(
    background: Color(0xFFDCFCE7),
    border: Color(0xFFBBF7D0),
    textColor: Color(0xFF15803D),
    icon: Icons.check_circle_rounded,
  ),
  'In review': _StatusVisual(
    background: Color(0xFFEEF2FF),
    border: Color(0xFFE0E7FF),
    textColor: Color(0xFF4338CA),
    icon: Icons.visibility_outlined,
  ),
  'At risk': _StatusVisual(
    background: Color(0xFFFEE2E2),
    border: Color(0xFFFECACA),
    textColor: Color(0xFFB91C1C),
    icon: Icons.error_outline,
  ),
  'Decision pending': _StatusVisual(
    background: Color(0xFFFDF4FF),
    border: Color(0xFFF5D0FE),
    textColor: Color(0xFF86198F),
    icon: Icons.hourglass_top_outlined,
  ),
  'Highlight blockers': _StatusVisual(
    background: Color(0xFFFFF7ED),
    border: Color(0xFFFBD5BB),
    textColor: Color(0xFFD97706),
    icon: Icons.report_problem_outlined,
  ),
};
