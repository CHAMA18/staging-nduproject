import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/routing/app_router.dart';

class TechnicalDevelopmentScreen extends StatefulWidget {
  const TechnicalDevelopmentScreen({super.key});

  @override
  State<TechnicalDevelopmentScreen> createState() => _TechnicalDevelopmentScreenState();
}

class _TechnicalDevelopmentScreenState extends State<TechnicalDevelopmentScreen> {
  final TextEditingController _notesController = TextEditingController();

  // Build strategy chips data
  final List<String> _standardsChips = [
    'Code guidelines defined',
    'Branching model agreed',
    'Definition of Ready',
    'Definition of Done',
  ];

  // Workstreams data
  final List<_WorkstreamItem> _workstreams = [
    _WorkstreamItem('Core platform', 'APIs, auth, data access', 'Team staffed', _StatusType.green),
    _WorkstreamItem('User experience', 'UI flows, accessibility, theming', 'Backlog ready', _StatusType.green),
    _WorkstreamItem('Integration build', '3rd-party, internal systems', 'Depends on vendor access', _StatusType.orange),
    _WorkstreamItem('Quality & automation', 'Test suites, pipelines, tooling', 'In planning', _StatusType.yellow),
  ];

  // Readiness checklist items
  final List<_ReadinessItem> _readinessItems = [
    _ReadinessItem('Critical user journeys documented', 'Product', 'Ready'),
    _ReadinessItem('Architecture & data models approved', 'Lead engineer', 'In review'),
    _ReadinessItem('Environments & pipelines available', 'DevOps', 'Partially ready'),
    _ReadinessItem('Non-functional targets agreed', 'Architecture', 'Draft'),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Technical Development',
      body: Stack(
        children: [
          Column(
            children: [
              const PlanningPhaseHeader(title: 'Design Phase'),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Title
                      Text(
                        'TECHNICAL DEVELOPMENT',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: LightModeColors.accent,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Translate design into a build-ready plan',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Outline how work will be built, sliced, and validated so engineering teams can start confidently without reworking the design phase.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 24),

                      // Notes Input
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppSemanticColors.border),
                        ),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Capture key build decisions here... coding standards, branching model, environments, and must-have automation.',
                            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Helper Text
                      Text(
                        'Keep this focused on what engineering needs on day one to start building safely.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),

                      // Three Cards - responsive layout
                      if (isMobile)
                        Column(
                          children: [
                            _buildBuildStrategyCard(),
                            const SizedBox(height: 16),
                            _buildWorkstreamsCard(),
                            const SizedBox(height: 16),
                            _buildReadinessChecklistCard(),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildBuildStrategyCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildWorkstreamsCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildReadinessChecklistCard()),
                          ],
                        ),
                      const SizedBox(height: 32),

                      // Bottom Navigation
                      _buildBottomNavigation(isMobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }

  Widget _buildBuildStrategyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Build strategy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('How the team will structure development', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          // Approach section
          Text('Approach', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[800])),
          const SizedBox(height: 8),
          Text(
            'Incremental delivery by feature slice, with hard gates for security and performance before release.',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          // Standards & constraints section
          Text('Standards & constraints', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[800])),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _standardsChips.map((chip) => _buildChip(chip)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildWorkstreamsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Workstreams & ownership', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Who builds what, and how it aligns to design', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ..._workstreams.map((item) => _buildWorkstreamItem(item)),
        ],
      ),
    );
  }

  Widget _buildWorkstreamItem(_WorkstreamItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(item.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(item.status, item.statusType),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, _StatusType type) {
    Color bgColor;
    Color dotColor;
    Color textColor;

    switch (type) {
      case _StatusType.green:
        bgColor = Colors.green[50]!;
        dotColor = Colors.green;
        textColor = Colors.green[700]!;
        break;
      case _StatusType.orange:
        bgColor = Colors.orange[50]!;
        dotColor = Colors.orange;
        textColor = Colors.orange[700]!;
        break;
      case _StatusType.yellow:
        bgColor = Colors.yellow[50]!;
        dotColor = Colors.yellow[700]!;
        textColor = Colors.yellow[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status,
              style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Readiness checklist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Confirm we can safely start development', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ..._readinessItems.map((item) => _buildReadinessItem(item)),
          const SizedBox(height: 16),
          // Export button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export development readiness summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessItem(_ReadinessItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Owner: ${item.owner}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text('Status: ${item.status}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isMobile) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Design phase · Technical Development', style: TextStyle(fontSize: 13, color: Colors.grey[500]), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back: Engineering Design'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.push('/${AppRoutes.toolsIntegration}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next: Tools integration'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Tip text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Capture only the decisions that unblock the first sprints. Anything more belongs in detailed engineering documentation, not the phase summary.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          Column(
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back: Engineering Design'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Design phase · Technical Development', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => context.push('/${AppRoutes.toolsIntegration}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Next: Tools integration'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Tip text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Capture only the decisions that unblock the first sprints. Anything more belongs in detailed engineering documentation, not the phase summary.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

enum _StatusType { green, orange, yellow }

class _WorkstreamItem {
  final String title;
  final String subtitle;
  final String status;
  final _StatusType statusType;

  _WorkstreamItem(this.title, this.subtitle, this.status, this.statusType);
}

class _ReadinessItem {
  final String title;
  final String owner;
  final String status;

  _ReadinessItem(this.title, this.owner, this.status);
}
