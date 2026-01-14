import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';

class RiskAssessmentScreen extends StatelessWidget {
  const RiskAssessmentScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RiskAssessmentScreen()),
    );
  }

  // No default register entries – we want a clean slate by default.
  static const List<_RiskEntry> _entries = [];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 36;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Risk Assessment'),
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
                        const _PageHeading(),
                        const SizedBox(height: 20),
                        const PlanningAiNotesCard(
                          title: 'Notes',
                          sectionLabel: 'Risk Assessment',
                          noteKey: 'planning_risk_assessment_notes',
                          checkpoint: 'risk_assessment',
                          description: 'Summarize key risks, probability/impact themes, and mitigation focus.',
                        ),
                        const SizedBox(height: 24),
                        _MetricsWrap(isMobile: isMobile),
                        const SizedBox(height: 28),
                        const _RiskMatrixCard(),
                        const SizedBox(height: 28),
                        _RiskRegister(entries: _entries, isMobile: isMobile),
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
            'Risk Mitigation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          const Spacer(),
          const _UserChip(name: 'Samuel kamanga', role: 'Product manager'),
          const SizedBox(width: 12),
          _OutlinedButton(label: 'Export', onPressed: () {}),
          const SizedBox(width: 10),
          _YellowButton(label: 'New Project', onPressed: () {}),
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

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: const Color(0xFF111827),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class _YellowButton extends StatelessWidget {
  const _YellowButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD54F),
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Assessment',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        SizedBox(height: 8),
        Text(
          'Identify, analyze and mitigate project risks.',
          style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _MetricsWrap extends StatelessWidget {
  const _MetricsWrap({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    // Derive metrics dynamically from project data; no hardcoded defaults.
    final project = context.watch<ProjectDataProvider>().projectData;
    final allRisks = project.solutionRisks
        .expand((sr) => sr.risks)
        .where((r) => r.trim().isNotEmpty)
        .toList();
    final int totalRisks = allRisks.length;

    // Placeholder logic for areas/status until richer data exists.
    // Keep UI consistent without implying default data.
    const String unknown = '—';
    final double? progress = null; // Unknown until mitigation statuses exist
    final String statusSubtitle = unknown;
    final String topRiskArea = unknown;
    final String unaddressed = totalRisks == 0 ? '0' : unknown;

    const double cardHeight = 148; // Uniform height to prevent visual jumps/overflow
    final cards = [
      _MetricCard(
        height: cardHeight,
        title: 'Total Risks',
        subtitle: '$totalRisks',
        // Show simple category summary only if present later; keep minimal now.
      ),
      _MetricCard(
        height: cardHeight,
        title: 'Risk Status',
        subtitle: statusSubtitle,
        progress: progress,
      ),
      _MetricCard(
        height: cardHeight,
        title: 'Top Risk Area',
        subtitle: topRiskArea,
        footer: totalRisks == 0 ? 'No risks yet' : null,
        footerIcon: totalRisks == 0 ? Icons.info_outline : null,
      ),
      _MetricCard(
        height: cardHeight,
        title: 'Unaddressed',
        subtitle: unaddressed,
        footer: totalRisks == 0 ? 'Add risks to begin tracking' : null,
        footerIcon: totalRisks == 0 ? Icons.info_outline : null,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == cards.length - 1 ? 0 : 16),
              child: SizedBox(width: double.infinity, child: cards[i]),
            ),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards
          .map(
            (card) => SizedBox(width: 260, child: card),
          )
          .toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.subtitle,
    this.badges = const [],
    this.height,
    this.progress,
    this.footer,
    this.footerIcon,
  });

  final String title;
  final String subtitle;
  final double? height;
  final List<_Badge> badges;
  final double? progress;
  final String? footer;
  final IconData? footerIcon;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges,
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD54F)),
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (footerIcon != null)
                  Icon(footerIcon, size: 16, color: const Color(0xFF6B7280)),
                if (footerIcon != null) const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    footer!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (height != null) {
      return SizedBox(height: height, child: content);
    }
    return content;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
      ),
    );
  }
}

class _RiskMatrixCard extends StatelessWidget {
  const _RiskMatrixCard();

  static const Color _high = Color(0xFFFEE2E2);
  static const Color _medium = Color(0xFFFEF3C7);
  static const Color _low = Color(0xFFDCFCE7);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Risk Matrix',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              const Spacer(),
              _LegendDot(color: _high, label: 'High Risk'),
              const SizedBox(width: 16),
              _LegendDot(color: _medium, label: 'Medium Risk'),
              const SizedBox(width: 16),
              _LegendDot(color: _low, label: 'Low Risk'),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final double cellHeight = constraints.maxWidth < 540 ? 64 : 80;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      SizedBox(width: 90),
                      Expanded(
                        child: _MatrixHeaderRow(labels: ['Low', 'Medium', 'High']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Likelihood',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _MatrixRow(label: 'Low', height: cellHeight, colors: const [_low, _low, _medium]),
                      _MatrixRow(label: 'Medium', height: cellHeight, colors: const [_low, _medium, _high]),
                      _MatrixRow(label: 'High', height: cellHeight, colors: const [_medium, _high, _high]),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _MatrixHeaderRow extends StatelessWidget {
  const _MatrixHeaderRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MatrixRow extends StatelessWidget {
  const _MatrixRow({required this.label, required this.height, required this.colors});

  final String label;
  final double height;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
            ),
          ),
          Expanded(
            child: Row(
              children: colors
                  .map(
                    (color) => Expanded(
                      child: Container(
                        height: height,
                        margin: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskRegister extends StatelessWidget {
  const _RiskRegister({required this.entries, required this.isMobile});

  final List<_RiskEntry> entries;
  final bool isMobile;

  static const List<int> _columnFlex = [2, 3, 2, 2, 3, 2, 2, 2];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Register',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Monitor risk exposure and mitigation status across the project portfolio.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 280,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OutlinedButton(label: 'Filter', onPressed: () {}),
                  const SizedBox(width: 10),
                  _OutlinedButton(label: 'Export', onPressed: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (entries.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: const [
                  Icon(Icons.inbox_outlined, size: 28, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 10),
                  Text(
                    'No risks yet',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Add risks from Risk Identification or Preferred Solution Analysis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ] else ...[
            _RegisterHeader(columnFlex: _columnFlex),
            const SizedBox(height: 12),
            ...List.generate(entries.length, (index) {
              final entry = entries[index];
              final bool isLast = index == entries.length - 1;
              return Column(
                children: [
                  _RegisterRow(entry: entry, columnFlex: _columnFlex),
                  if (!isLast) const Divider(height: 26, thickness: 1, color: Color(0xFFF3F4F6)),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({required this.columnFlex});

  final List<int> columnFlex;

  static const List<String> _labels = [
    'Risk ID',
    'Description',
    'Category',
    'Probability',
    'Impact',
    'Risk Score',
    'Owner',
    'Status',
    'Actions',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(_labels.length, (index) {
          if (index == _labels.length - 1) {
            return const SizedBox(width: 60); // reserve space for icons
          }
          final flex = columnFlex[index];
          return Expanded(
            flex: flex,
            child: Text(
              _labels[index],
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
            ),
          );
        }),
      ],
    );
  }
}

class _RegisterRow extends StatelessWidget {
  const _RegisterRow({required this.entry, required this.columnFlex});

  final _RiskEntry entry;
  final List<int> columnFlex;

  @override
  Widget build(BuildContext context) {
    Color pillColor;
    Color pillText;
    switch (entry.status) {
      case 'In Progress':
        pillColor = const Color(0xFFFFF7E6);
        pillText = const Color(0xFF92400E);
        break;
      case 'Monitoring':
        pillColor = const Color(0xFFE0F2F1);
        pillText = const Color(0xFF065F46);
        break;
      default:
        pillColor = const Color(0xFFE5E7EB);
        pillText = const Color(0xFF374151);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: columnFlex[0],
          child: Text(
            entry.id,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          ),
        ),
        Expanded(
          flex: columnFlex[1],
          child: Text(
            entry.description,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          ),
        ),
        Expanded(
          flex: columnFlex[2],
          child: Text(
            entry.category,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          flex: columnFlex[3],
          child: _RiskTag(label: entry.probability),
        ),
        Expanded(
          flex: columnFlex[4],
          child: _RiskTag(label: entry.impact),
        ),
        Expanded(
          flex: columnFlex[5],
          child: Text(
            entry.score,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          flex: columnFlex[6],
          child: Text(
            entry.owner,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          ),
        ),
        Expanded(
          flex: columnFlex[7],
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: pillColor, borderRadius: BorderRadius.circular(999)),
              child: Text(
                entry.status,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: pillText),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF6B7280)),
                onPressed: () {},
                tooltip: 'View',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6B7280)),
                onPressed: () {},
                tooltip: 'Edit',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RiskTag extends StatelessWidget {
  const _RiskTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isHigh = label.toLowerCase() == 'high';
    final bool isMedium = label.toLowerCase() == 'medium';
    Color background;
    Color textColor;

    if (isHigh) {
      background = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFB91C1C);
    } else if (isMedium) {
      background = const Color(0xFFFEF3C7);
      textColor = const Color(0xFF92400E);
    } else {
      background = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }
}

class _RiskEntry {
  const _RiskEntry({
    required this.id,
    required this.description,
    required this.category,
    required this.probability,
    required this.impact,
    required this.score,
    required this.owner,
    required this.status,
  });

  final String id;
  final String description;
  final String category;
  final String probability;
  final String impact;
  final String score;
  final String owner;
  final String status;
}
