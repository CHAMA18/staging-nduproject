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

                  // Three Cards - stacked layout
                  Column(
                    children: [
                      _buildCategoriesCard(),
                      const SizedBox(height: 16),
                      _buildEquipmentTrackingCard(),
                      const SizedBox(height: 16),
                      _buildProcurementActionsCard(),
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
          Row(
            children: [
              const Expanded(
                child: Text('Equipment categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: _showCreateCategoryDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Item'),
                style: TextButton.styleFrom(
                  foregroundColor: LightModeColors.accent,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Types of items requiring early procurement', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ...List.generate(
            _categories.length,
            (index) => _buildCategoryItem(
              _categories[index],
              onModify: () => _showEditCategoryDialog(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(_EquipmentCategory item, {required VoidCallback onModify}) {
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
          TextButton(
            onPressed: onModify,
            style: TextButton.styleFrom(
              foregroundColor: LightModeColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Modify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
          Row(
            children: [
              const Expanded(
                child: Text('Equipment tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: _showCreateEquipmentDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Item'),
                style: TextButton.styleFrom(
                  foregroundColor: LightModeColors.accent,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
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
              Expanded(flex: 1, child: Text('Modify', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500))),
            ],
          ),
          const Divider(height: 16),
          ...List.generate(
            _equipmentItems.length,
            (index) => _buildEquipmentRow(
              _equipmentItems[index],
              onModify: () => _showEditEquipmentDialog(index),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Track all equipment with lead times exceeding 4 weeks to ensure timely delivery.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentRow(_EquipmentItem item, {required VoidCallback onModify}) {
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
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onModify,
                style: TextButton.styleFrom(
                  foregroundColor: LightModeColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Modify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
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
          Row(
            children: [
              const Expanded(
                child: Text('Procurement actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: _showCreateActionDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Item'),
                style: TextButton.styleFrom(
                  foregroundColor: LightModeColors.accent,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Steps to manage long-lead procurement', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ...List.generate(
            _actions.length,
            (index) => _buildActionItem(
              _actions[index],
              onModify: () => _showEditActionDialog(index),
            ),
          ),
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

  Widget _buildActionItem(_ProcurementAction item, {required VoidCallback onModify}) {
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
          TextButton(
            onPressed: onModify,
            style: TextButton.styleFrom(
              foregroundColor: LightModeColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Modify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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

  Future<void> _showCreateCategoryDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<_EquipmentCategory>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title is required.')),
                );
                return;
              }
              final description = descriptionController.text.trim();
              Navigator.of(dialogContext).pop(_EquipmentCategory(title, description));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _categories.add(result));
    }
  }

  Future<void> _showEditCategoryDialog(int index) async {
    final current = _categories[index];
    final titleController = TextEditingController(text: current.title);
    final descriptionController = TextEditingController(text: current.description);

    final result = await showDialog<_EditResult<_EquipmentCategory>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modify Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(const _EditResult.delete()),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title is required.')),
                );
                return;
              }
              final description = descriptionController.text.trim();
              Navigator.of(dialogContext).pop(
                _EditResult.save(_EquipmentCategory(title, description)),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    if (result.action == _EditAction.delete) {
      setState(() => _categories.removeAt(index));
      return;
    }
    if (result.item != null) {
      setState(() => _categories[index] = result.item!);
    }
  }

  Future<void> _showCreateEquipmentDialog() async {
    final nameController = TextEditingController();
    final vendorController = TextEditingController();
    final leadTimeController = TextEditingController();
    final statusController = TextEditingController();

    final result = await showDialog<_EquipmentItem>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Equipment Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: vendorController,
              decoration: const InputDecoration(labelText: 'Vendor'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: leadTimeController,
              decoration: const InputDecoration(labelText: 'Lead time'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: statusController,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item name is required.')),
                );
                return;
              }
              final vendor = vendorController.text.trim();
              final leadTime = leadTimeController.text.trim();
              final status = statusController.text.trim();
              Navigator.of(dialogContext).pop(_EquipmentItem(name, vendor, leadTime, status));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _equipmentItems.add(result));
    }
  }

  Future<void> _showEditEquipmentDialog(int index) async {
    final current = _equipmentItems[index];
    final nameController = TextEditingController(text: current.name);
    final vendorController = TextEditingController(text: current.vendor);
    final leadTimeController = TextEditingController(text: current.leadTime);
    final statusController = TextEditingController(text: current.status);

    final result = await showDialog<_EditResult<_EquipmentItem>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modify Equipment Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: vendorController,
              decoration: const InputDecoration(labelText: 'Vendor'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: leadTimeController,
              decoration: const InputDecoration(labelText: 'Lead time'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: statusController,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(const _EditResult.delete()),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item name is required.')),
                );
                return;
              }
              final vendor = vendorController.text.trim();
              final leadTime = leadTimeController.text.trim();
              final status = statusController.text.trim();
              Navigator.of(dialogContext).pop(
                _EditResult.save(_EquipmentItem(name, vendor, leadTime, status)),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    if (result.action == _EditAction.delete) {
      setState(() => _equipmentItems.removeAt(index));
      return;
    }
    if (result.item != null) {
      setState(() => _equipmentItems[index] = result.item!);
    }
  }

  Future<void> _showCreateActionDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<_ProcurementAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Procurement Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title is required.')),
                );
                return;
              }
              final description = descriptionController.text.trim();
              Navigator.of(dialogContext).pop(_ProcurementAction(title, description));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _actions.add(result));
    }
  }

  Future<void> _showEditActionDialog(int index) async {
    final current = _actions[index];
    final titleController = TextEditingController(text: current.title);
    final descriptionController = TextEditingController(text: current.description);

    final result = await showDialog<_EditResult<_ProcurementAction>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modify Procurement Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(const _EditResult.delete()),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title is required.')),
                );
                return;
              }
              final description = descriptionController.text.trim();
              Navigator.of(dialogContext).pop(
                _EditResult.save(_ProcurementAction(title, description)),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    if (result.action == _EditAction.delete) {
      setState(() => _actions.removeAt(index));
      return;
    }
    if (result.item != null) {
      setState(() => _actions[index] = result.item!);
    }
  }
}

enum _EditAction { save, delete }

class _EditResult<T> {
  const _EditResult.save(this.item) : action = _EditAction.save;
  const _EditResult.delete()
      : action = _EditAction.delete,
        item = null;

  final _EditAction action;
  final T? item;
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
