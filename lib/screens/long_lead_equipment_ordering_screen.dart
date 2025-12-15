import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/theme.dart';

class LongLeadEquipmentOrderingScreen extends StatefulWidget {
  const LongLeadEquipmentOrderingScreen({super.key});

  @override
  State<LongLeadEquipmentOrderingScreen> createState() => _LongLeadEquipmentOrderingScreenState();
}

class _LongLeadEquipmentOrderingScreenState extends State<LongLeadEquipmentOrderingScreen> {
  final TextEditingController _notesController = TextEditingController();

  // Equipment categories data
  final List<_EquipmentCategory> _categories = [
    _EquipmentCategory('Critical path equipment', 'Items that must arrive before key milestones can begin.'),
    _EquipmentCategory('Long-lead manufacturing', 'Custom or specialized items with extended production times.'),
    _EquipmentCategory('Import & logistics-dependent', 'Equipment requiring customs clearance or complex shipping.'),
  ];

  // Equipment tracking data
  final List<_EquipmentItem> _equipmentItems = [
    _EquipmentItem('Primary processing unit', 'Vendor A', '12 weeks', 'Ordered'),
    _EquipmentItem('Control system modules', 'Vendor B', '8 weeks', 'In production'),
    _EquipmentItem('Safety interlock system', 'Vendor C', '16 weeks', 'Pending approval'),
  ];

  // Procurement actions data
  final List<_ProcurementAction> _actions = [
    _ProcurementAction('Pre-order specifications', 'Finalize technical specs and delivery requirements early.'),
    _ProcurementAction('Vendor coordination', 'Confirm production schedules and staging requirements.'),
    _ProcurementAction('Contingency planning', 'Identify alternate sources and expedite options if needed.'),
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
      activeItemLabel: 'Long Lead Equipment Ordering',
      body: Column(
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
                    'Long Lead Equipment Ordering',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: LightModeColors.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plan and track equipment with extended procurement timelines',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Identify and manage equipment that requires early ordering to avoid schedule delays and ensure timely project delivery.',
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
                        hintText: 'Input your notes here (equipment lead times, vendor contacts, critical dates)',
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
                    'Focus on items where procurement timing directly impacts project milestones or critical path activities.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Three Cards - responsive layout
                  if (isMobile)
                    Column(
                      children: [
                        _buildCategoriesCard(),
                        const SizedBox(height: 16),
                        _buildEquipmentTrackingCard(),
                        const SizedBox(height: 16),
                        _buildProcurementActionsCard(),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildCategoriesCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildEquipmentTrackingCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildProcurementActionsCard()),
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
    );
  }

  Widget _buildCategoriesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Equipment categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Types of items requiring early procurement', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ..._categories.map((c) => _buildCategoryItem(c)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(_EquipmentCategory item) {
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
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: LightModeColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(item.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentTrackingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Equipment tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Current status of long-lead items', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          // Table Header
          Row(
            children: [
              Expanded(flex: 2, child: Text('Item', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500))),
              Expanded(flex: 2, child: Text('Vendor', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500))),
              Expanded(flex: 1, child: Text('Lead time', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500))),
              Expanded(flex: 1, child: Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500))),
            ],
          ),
          const Divider(height: 16),
          ..._equipmentItems.map((e) => _buildEquipmentRow(e)),
          const SizedBox(height: 16),
          Text(
            'Track all equipment with lead times exceeding 4 weeks to ensure timely delivery.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentRow(_EquipmentItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text(item.vendor, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
          Expanded(flex: 1, child: Text(item.leadTime, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(item.status, style: TextStyle(fontSize: 11, color: Colors.grey[700]), textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcurementActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Procurement actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Steps to manage long-lead procurement', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ..._actions.map((a) => _buildActionItem(a)),
          const SizedBox(height: 16),
          // Export button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export equipment schedule'),
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

  Widget _buildActionItem(_ProcurementAction item) {
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
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: LightModeColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(item.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
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
              Text('Design phase • Long lead equipment ordering', style: TextStyle(fontSize: 13, color: Colors.grey[500]), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back: Tools integration'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next: Specialized design'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back: Tools integration'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Text('Design phase • Long lead equipment ordering', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next: Specialized design'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        // Footer hint
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, size: 18, color: LightModeColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Start procurement activities for long-lead items as early as possible to maintain schedule flexibility and reduce project risk.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EquipmentCategory {
  final String title;
  final String description;

  _EquipmentCategory(this.title, this.description);
}

class _EquipmentItem {
  final String name;
  final String vendor;
  final String leadTime;
  final String status;

  _EquipmentItem(this.name, this.vendor, this.leadTime, this.status);
}

class _ProcurementAction {
  final String title;
  final String description;

  _ProcurementAction(this.title, this.description);
}
