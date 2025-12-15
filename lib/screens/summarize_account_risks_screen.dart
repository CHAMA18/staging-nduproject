import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/screens/vendor_account_close_out_screen.dart';
import 'package:ndu_project/screens/commerce_viability_screen.dart';

class SummarizeAccountRisksScreen extends StatefulWidget {
  const SummarizeAccountRisksScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SummarizeAccountRisksScreen()),
    );
  }

  @override
  State<SummarizeAccountRisksScreen> createState() => _SummarizeAccountRisksScreenState();
}

class _SummarizeAccountRisksScreenState extends State<SummarizeAccountRisksScreen> {
  final Set<String> _selectedFilters = {'Account picture is clear', 'Overall account health'};

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 18 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Summarize Account Of All Section Including Risks'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageHeader(context),
                        const SizedBox(height: 20),
                        _buildFilterChips(context),
                        const SizedBox(height: 24),
                        _buildMainContent(context, isMobile),
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
            'SUMMARIZE ACCOUNT & RISKS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'One-page summary of where the account stands at launch',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Capture how healthy the account is, what went well, and which risks or follow-ups need attention after go-live.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
            height: 1.5,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final List<String> filterRow1 = [
      'Account picture is clear',
      'Key risks documented',
      'Owners assigned',
      'Follow-ups scheduled',
    ];
    final List<String> filterRow2 = [
      'Overall account health',
      'Delivery & quality',
      'Risk & issues',
      'Next 90 days',
    ];
    final List<String> filterRow3 = [
      'Highlight top 3 risks only',
      'Show critical dependencies',
      'Draft exec-ready summary',
    ];

    Widget buildChip(String label, {bool filled = false}) {
      final isSelected = _selectedFilters.contains(label);
      return GestureDetector(
        onTap: () => setState(() {
          if (isSelected) {
            _selectedFilters.remove(label);
          } else {
            _selectedFilters.add(label);
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filterRow1.map((label) => buildChip(label)).toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filterRow2.map((label) => buildChip(label)).toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filterRow3.map((label) => buildChip(label)).toList(),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountHealthSnapshot(context),
              const SizedBox(height: 16),
              _buildWhatWentWell(context),
              const SizedBox(height: 16),
              _buildKeyDeliveryRisks(context),
              const SizedBox(height: 16),
              _buildRiskOwnersMitigation(context),
              const SizedBox(height: 16),
              _buildDependenciesAssumptions(context),
              const SizedBox(height: 16),
              _buildNext90DaysFocus(context),
              const SizedBox(height: 16),
              _buildExecutiveSummary(context),
              const SizedBox(height: 16),
              _buildAiAssistSummaryDrafting(context),
            ],
          );
        }
        return Column(
          children: [
            // Row 1: 3 cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAccountHealthSnapshot(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildWhatWentWell(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildKeyDeliveryRisks(context)),
              ],
            ),
            const SizedBox(height: 16),
            // Row 2: 3 cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildRiskOwnersMitigation(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildDependenciesAssumptions(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildNext90DaysFocus(context)),
              ],
            ),
            const SizedBox(height: 16),
            // Row 3: 2 cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildExecutiveSummary(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildAiAssistSummaryDrafting(context)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountHealthSnapshot(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Account health snapshot',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Healthy with watchpoints',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'The relationship is in good standing, delivery obligations are largely met, and remaining work is documented with clear owners.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Green',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
              const Text(
                ' delivery confidence',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                '2',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFC812),
                ),
              ),
              const Text(
                ' open follow-up items',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'No active escalation at launch',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatWentWell(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'What went well',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                'Strengths to reuse',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Capture repeatable patterns that worked, so future projects can benefit from this experience.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildBulletPoint('Vendor met or exceeded delivery dates on critical milestones.'),
          const SizedBox(height: 8),
          _buildBulletPoint('Collaboration across teams was responsive and transparent.'),
          const SizedBox(height: 8),
          _buildBulletPoint('Technical quality and documentation supported smooth launch.'),
        ],
      ),
    );
  }

  Widget _buildKeyDeliveryRisks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Key delivery risks & issues',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Risks to\nwatch',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Record the most important risks in one place, so they don\'t get lost as the team transitions.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildBulletPoint('List up to three highest-impact risks, with clear likelihood and impact.'),
          const SizedBox(height: 8),
          _buildBulletPoint('Note any known defects, gaps, or fragile workflows.'),
          const SizedBox(height: 8),
          _buildBulletPoint('Flag dependencies on other vendors, teams, or platforms.'),
        ],
      ),
    );
  }

  Widget _buildRiskOwnersMitigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Risk owners & mitigation',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Who is on point',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Assign a clear owner for each risk and describe how it will be monitored or reduced.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildBulletPoint('Each risk has a named owner and backup.'),
          const SizedBox(height: 8),
          _buildBulletPoint('Mitigation or contingency actions are defined.'),
          const SizedBox(height: 8),
          _buildBulletPoint('Target review dates (e.g. 30 / 60 / 90 days) are captured.'),
        ],
      ),
    );
  }

  Widget _buildDependenciesAssumptions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Dependencies & assumptions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                'What could change',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Summarize major assumptions and dependencies that would affect value if they change.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildBulletPoint('Call out critical technology, process, or staffing dependencies.'),
          const SizedBox(height: 8),
          _buildBulletPoint('Note assumptions around volume, demand, or data quality.'),
          const SizedBox(height: 8),
          _buildBulletPoint('Document any "must stay true" conditions for success.'),
        ],
      ),
    );
  }

  Widget _buildNext90DaysFocus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Next 90 days focus',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                'Post-launch plan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Give operations and leadership a crisp view of what matters most after launch.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildBulletPoint('Top 3 priorities for stabilizing and optimizing the solution.'),
          const SizedBox(height: 8),
          _buildBulletPoint('Checkpoints for measuring benefits and performance.'),
          const SizedBox(height: 8),
          _buildBulletPoint('Planned vendor touchpoints (e.g. QBRs, check-ins).'),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Executive summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                'One slide narrative',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'A short narrative you can reuse in steering committees, emails, or documentation.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildBulletPoint('1–2 sentences on current account health.'),
          const SizedBox(height: 8),
          _buildBulletPoint('1–2 sentences on key risks and how they are being managed.'),
          const SizedBox(height: 8),
          _buildBulletPoint('1–2 sentences on expected next outcomes or checkpoints.'),
        ],
      ),
    );
  }

  Widget _buildAiAssistSummaryDrafting(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI assist for summary drafting',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                'Turn notes into narrative',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Use this to convert scattered notes into a consistent, executive-ready summary of account status and risks.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildBulletPoint('Combine highlights, risks, and next steps into one view.'),
          const SizedBox(height: 8),
          _buildBulletPoint('Adjust tone for leadership, operations, or vendor audiences.'),
          const SizedBox(height: 8),
          _buildBulletPoint('Export as text to paste into email, slides, or documents.'),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF6B7280),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterNavigation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => VendorAccountCloseOutScreen.open(context),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back: Vendor account close out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Launch phase · Summarize account & risks',
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {
                // AI draft summary action
              },
              icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF10B981)),
              label: const Text('Help me draft the summary'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: Color(0xFF10B981)),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => CommerceViabilityScreen.open(context),
              icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              label: const Text('Next: Commerce viability'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFFFC812)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'If someone reviews this project a year from now, can they quickly see whether the account is healthy, what the real risks are, and who owns them?',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Review account & risk summary',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
