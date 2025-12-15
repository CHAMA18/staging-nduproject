import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/routing/app_router.dart';

class EngineeringDesignScreen extends StatefulWidget {
  const EngineeringDesignScreen({super.key});

  @override
  State<EngineeringDesignScreen> createState() => _EngineeringDesignScreenState();
}

class _EngineeringDesignScreenState extends State<EngineeringDesignScreen> {
  final TextEditingController _notesController = TextEditingController();

  // Core layers data
  final List<_CoreLayerItem> _coreLayers = [
    _CoreLayerItem('Presentation layer', 'Web & mobile'),
    _CoreLayerItem('Service layer', 'APIs & orchestration'),
    _CoreLayerItem('Data layer', 'OLTP + analytics'),
  ];

  // Components & interfaces data
  final List<_ComponentItem> _components = [
    _ComponentItem('Auth service', 'Identity, SSO, tokens', 'Defined', _InterfaceStatus.defined),
    _ComponentItem('Order service', 'Order lifecycle & rules', 'In review', _InterfaceStatus.inReview),
    _ComponentItem('Reporting engine', 'Aggregations & exports', 'Draft', _InterfaceStatus.draft),
    _ComponentItem('Integration hub', 'External systems & webhooks', 'Planned', _InterfaceStatus.planned),
  ];

  // Engineering readiness items
  final List<_ReadinessItem> _readinessItems = [
    _ReadinessItem('Architecture review', 'Validate target architecture & non-functionals', 'Lead architect'),
    _ReadinessItem('Component design freeze', 'Lock interfaces & data contracts', 'Domain engineers'),
    _ReadinessItem('Implementation kickoff', 'Handover to dev squads', 'Tech lead'),
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
      activeItemLabel: 'Engineering',
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
                        'ENGINEERING DESIGN',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: LightModeColors.accent,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Engineering the system architecture and technical blueprint',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Define the architecture, components, interfaces, and data models so developers have a clear and buildable engineering plan before coding starts.',
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
                            hintText: 'Capture engineering notes here... design assumptions, constraints, standards, and open technical decisions.',
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
                        'Use this view to turn conceptual designs into concrete engineering specifications and responsibilities.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),

                      // Three Cards - responsive layout
                      if (isMobile)
                        Column(
                          children: [
                            _buildSystemArchitectureCard(),
                            const SizedBox(height: 16),
                            _buildComponentsInterfacesCard(),
                            const SizedBox(height: 16),
                            _buildEngineeringReadinessCard(),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildSystemArchitectureCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildComponentsInterfacesCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildEngineeringReadinessCard()),
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

  Widget _buildSystemArchitectureCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppSemanticColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System architecture',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          'High-level structure of the solution',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        Text(
          'Architecture style',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        const Text(
          'Microservices with API gateway, shared auth, and separate data domains for core modules.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        Text(
          'Core layers',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]),
        ),
        const SizedBox(height: 12),
        ..._coreLayers.map((layer) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  layer.name,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              Text(
                layer.description,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
        Text(
          'Key decisions',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        const Text(
          'Document trade-offs for scalability, resilience, and security so all teams implement consistently.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    ),
  );

  Widget _buildComponentsInterfacesCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppSemanticColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Components & interfaces',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          'Who owns what and how they talk',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        // Header Row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                'Component',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Responsibility',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'Interface status',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._components.map((component) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  component.name,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    component.responsibility,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getStatusColor(component.status),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        component.statusLabel,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    ),
  );

  Widget _buildEngineeringReadinessCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppSemanticColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Engineering readiness',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          'Design reviews, sign-offs, and ownership',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        ..._readinessItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Owner: ${item.owner}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        )),
        const SizedBox(height: 8),
        // Add engineering entry button
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text(
                  'Add engineering entry',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Export button
        Center(
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: LightModeColors.accent, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export engineering blueprint'),
          ),
        ),
      ],
    ),
  );

  Color _getStatusColor(_InterfaceStatus status) {
    switch (status) {
      case _InterfaceStatus.defined:
        return const Color(0xFF22C55E); // Green
      case _InterfaceStatus.inReview:
        return const Color(0xFFFBBF24); // Yellow
      case _InterfaceStatus.draft:
        return const Color(0xFFFBBF24); // Yellow
      case _InterfaceStatus.planned:
        return const Color(0xFF22C55E); // Green
    }
  }

  Widget _buildBottomNavigation(bool isMobile) => Column(
    children: [
      if (isMobile)
        Column(
          children: [
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/${AppRoutes.uiUxDesign}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back: Backend design'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Design phase · Engineering Design',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/${AppRoutes.technicalDevelopment}'),
                style: FilledButton.styleFrom(
                  backgroundColor: LightModeColors.accent,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next: Engineering Design'),
              ),
            ),
          ],
        )
      else
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go('/${AppRoutes.uiUxDesign}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back: Backend design'),
            ),
            const SizedBox(width: 16),
            Text(
              'Design phase · Engineering Design',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => context.go('/${AppRoutes.technicalDevelopment}'),
              style: FilledButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Next: Engineering Design'),
            ),
          ],
        ),
      const SizedBox(height: 24),
      // Tip section
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: LightModeColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Keep engineering artifacts simple but precise: document architecture diagrams, component responsibilities, and interface contracts so implementation teams can build without reinterpreting the design.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    ],
  );
}

class _CoreLayerItem {
  final String name;
  final String description;
  _CoreLayerItem(this.name, this.description);
}

class _ComponentItem {
  final String name;
  final String responsibility;
  final String statusLabel;
  final _InterfaceStatus status;
  _ComponentItem(this.name, this.responsibility, this.statusLabel, this.status);
}

enum _InterfaceStatus { defined, inReview, draft, planned }

class _ReadinessItem {
  final String title;
  final String description;
  final String owner;
  _ReadinessItem(this.title, this.description, this.owner);
}
