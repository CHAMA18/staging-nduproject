import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/salvage_service.dart';

class SalvageDisposalTeamScreen extends StatefulWidget {
  const SalvageDisposalTeamScreen({super.key});

  static void open(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SalvageDisposalTeamScreen()),
  );

  @override
  State<SalvageDisposalTeamScreen> createState() => _SalvageDisposalTeamScreenState();
}

class _SalvageDisposalTeamScreenState extends State<SalvageDisposalTeamScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Overview', 'Asset Inventory', 'Disposal Queue', 'Team Allocation'];
  
  String? _getProjectId() {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  final List<_StatItem> _overviewStats = [
    _StatItem('Team Members', '5 active', Icons.people, Colors.blue),
    _StatItem('Assets Pending', '12 items', Icons.inventory, Colors.orange),
    _StatItem('Total Salvage Value', '\$73,350', Icons.attach_money, Colors.green),
    _StatItem('Disposal Progress', '68%', Icons.pie_chart, const Color(0xFF8B5CF6)),
    _StatItem('Compliance Score', '94/100', Icons.verified, Colors.teal),
  ];

  final List<_StatItem> _inventoryStats = [
    _StatItem('Tracked Assets', '86', Icons.inventory_2_outlined, const Color(0xFF0284C7)),
    _StatItem('Ready for Disposal', '24', Icons.fact_check_outlined, const Color(0xFF10B981)),
    _StatItem('Estimated Value', '\$128.4K', Icons.savings_outlined, const Color(0xFF16A34A)),
    _StatItem('Reuse Potential', '41%', Icons.autorenew, const Color(0xFF7C3AED)),
  ];

  final List<_StatItem> _queueStats = [
    _StatItem('Queue Items', '18', Icons.list_alt_outlined, const Color(0xFF0EA5E9)),
    _StatItem('High Priority', '6', Icons.priority_high, const Color(0xFFEF4444)),
    _StatItem('Auction Value', '\$52.7K', Icons.sell_outlined, const Color(0xFFF59E0B)),
    _StatItem('Compliance Ready', '82%', Icons.verified_outlined, const Color(0xFF14B8A6)),
  ];

  final List<_StatItem> _allocationStats = [
    _StatItem('Active Specialists', '12', Icons.groups_outlined, const Color(0xFF0EA5E9)),
    _StatItem('Utilization', '74%', Icons.donut_large_outlined, const Color(0xFF6366F1)),
    _StatItem('Open Roles', '3', Icons.person_search_outlined, const Color(0xFFFB7185)),
    _StatItem('Training Due', '2', Icons.school_outlined, const Color(0xFFF59E0B)),
  ];

  final List<_TeamMember> _teamMembers = [
    _TeamMember('Sarah Mitchell', 'Team Lead', 'sarah.m@company.com', 'Active', 12, Colors.green),
    _TeamMember('James Rodriguez', 'Asset Specialist', 'james.r@company.com', 'Active', 8, Colors.green),
    _TeamMember('Emily Chen', 'Logistics Coordinator', 'emily.c@company.com', 'On Leave', 5, Colors.orange),
    _TeamMember('Michael Thompson', 'Disposal Technician', 'michael.t@company.com', 'Active', 15, Colors.green),
    _TeamMember('Lisa Park', 'Compliance Officer', 'lisa.p@company.com', 'Active', 9, Colors.green),
  ];

  final List<_InventoryItem> _inventoryItems = [
    _InventoryItem('SVG-019', 'Server Rack Set', 'Electronics', 'Excellent', 'Data Center', 'Ready', '\$18,400', Colors.green),
    _InventoryItem('SVG-023', 'Operations Console', 'Hardware', 'Good', 'Control Room', 'Pending', '\$6,750', Colors.orange),
    _InventoryItem('SVG-031', 'Hazmat Storage', 'Safety', 'Good', 'Warehouse B', 'Review', '\$4,200', Colors.blue),
    _InventoryItem('SVG-044', 'Generator Unit', 'Power', 'Fair', 'Substation', 'Flagged', '\$12,300', Colors.red),
    _InventoryItem('SVG-052', 'Network Switches', 'Electronics', 'Excellent', 'Data Center', 'Ready', '\$7,980', Colors.green),
  ];

  final List<_DisposalItem> _disposalItems = [
    _DisposalItem('SVG-001', 'Server Equipment', 'Electronics', 'Pending Review', '\$12,500', 'High', Colors.red),
    _DisposalItem('SVG-002', 'Office Furniture', 'Furniture', 'Approved', '\$3,200', 'Medium', Colors.orange),
    _DisposalItem('SVG-003', 'Construction Materials', 'Raw Materials', 'In Progress', '\$8,750', 'Low', Colors.green),
    _DisposalItem('SVG-004', 'Vehicle Fleet (3 units)', 'Vehicles', 'Pending Auction', '\$45,000', 'High', Colors.red),
    _DisposalItem('SVG-005', 'IT Peripherals', 'Electronics', 'Completed', '\$1,800', 'Low', Colors.green),
    _DisposalItem('SVG-006', 'Safety Equipment', 'PPE', 'Approved', '\$2,100', 'Medium', Colors.orange),
  ];

  final List<_QueueBoardItem> _queueBoardItems = [
    _QueueBoardItem('SVG-014', 'Industrial Sensors', 'Review', 'High', '\$9,500'),
    _QueueBoardItem('SVG-018', 'Control Panels', 'Review', 'Medium', '\$4,200'),
    _QueueBoardItem('SVG-022', 'Office Fixtures', 'Approved', 'Low', '\$2,800'),
    _QueueBoardItem('SVG-027', 'Cooling Units', 'Approved', 'High', '\$13,400'),
    _QueueBoardItem('SVG-033', 'Vehicle Fleet', 'Auction', 'High', '\$45,000'),
    _QueueBoardItem('SVG-038', 'Copper Wiring', 'Auction', 'Medium', '\$6,150'),
  ];

  final List<_AllocationItem> _allocationItems = [
    _AllocationItem('Sarah Mitchell', 'Team Lead', 'Compliance + Reporting', 82, 'Active'),
    _AllocationItem('James Rodriguez', 'Asset Specialist', 'Inventory Audit', 68, 'Active'),
    _AllocationItem('Emily Chen', 'Logistics Coordinator', 'Vendor Liaison', 45, 'On Leave'),
    _AllocationItem('Michael Thompson', 'Disposal Technician', 'Field Ops', 76, 'Active'),
    _AllocationItem('Lisa Park', 'Compliance Officer', 'Regulatory Review', 64, 'Active'),
  ];

  final List<_CapacityItem> _capacityItems = [
    _CapacityItem('Field Ops', 0.78, Colors.blue),
    _CapacityItem('Compliance', 0.64, Colors.green),
    _CapacityItem('Logistics', 0.52, Colors.orange),
    _CapacityItem('Reporting', 0.83, Colors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 900;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Salvage and/or Disposal Plan',
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isNarrow),
            const SizedBox(height: 24),
            _buildTabBar(),
            const SizedBox(height: 24),
            _buildTabContent(isNarrow),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isNarrow) {
    switch (_selectedTab) {
      case 1:
        return _buildAssetInventoryContent(isNarrow);
      case 2:
        return _buildDisposalQueueContent(isNarrow);
      case 3:
        return _buildTeamAllocationContent(isNarrow);
      case 0:
      default:
        return _buildOverviewContent(isNarrow);
    }
  }

  Widget _buildHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Salvage & Disposal Team Management',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage salvage operations, asset disposal workflows, and team assignments for project decommissioning.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (!isNarrow) ...[
              const SizedBox(width: 16),
              _buildActionButtons(),
            ],
          ],
        ),
        if (isNarrow) ...[
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ],
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0EA5E9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOverviewContent(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(isNarrow, _overviewStats),
        const SizedBox(height: 24),
        _buildInsightsRow(isNarrow),
        const SizedBox(height: 24),
        if (isNarrow) ...[
          _buildTeamManagementPanel(),
          const SizedBox(height: 24),
          _buildDisposalQueuePanel(),
          const SizedBox(height: 24),
          _buildCompliancePanel(),
          const SizedBox(height: 24),
          _buildTimelinePanel(),
        ] else ...[
          _buildTeamManagementPanel(),
          const SizedBox(height: 24),
          _buildCompliancePanel(),
          const SizedBox(height: 24),
          _buildDisposalQueuePanel(),
          const SizedBox(height: 24),
          _buildTimelinePanel(),
        ],
      ],
    );
  }

  Widget _buildAssetInventoryContent(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(isNarrow, _inventoryStats),
        const SizedBox(height: 24),
        if (isNarrow)
          Column(
            children: [
              _buildInventoryTable(),
              const SizedBox(height: 24),
              _buildInventorySignalsPanel(),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildInventoryTable()),
              const SizedBox(width: 24),
              Expanded(child: _buildInventorySignalsPanel()),
            ],
          ),
      ],
    );
  }

  Widget _buildDisposalQueueContent(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(isNarrow, _queueStats),
        const SizedBox(height: 24),
        if (isNarrow)
          Column(
            children: [
              _buildQueueBoard(),
              const SizedBox(height: 24),
              _buildDisposalQueuePanel(),
              const SizedBox(height: 24),
              _buildCompliancePanel(),
              const SizedBox(height: 24),
              _buildTimelinePanel(),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildQueueBoard(),
                    const SizedBox(height: 24),
                    _buildDisposalQueuePanel(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildCompliancePanel(),
                    const SizedBox(height: 24),
                    _buildTimelinePanel(),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTeamAllocationContent(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(isNarrow, _allocationStats),
        const SizedBox(height: 24),
        if (isNarrow)
          Column(
            children: [
              _buildAllocationTable(),
              const SizedBox(height: 24),
              _buildCapacityPanel(),
              const SizedBox(height: 24),
              _buildCoveragePanel(),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAllocationTable(),
              const SizedBox(height: 24),
              _buildCapacityPanel(),
              const SizedBox(height: 24),
              _buildCoveragePanel(),
            ],
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildActionButton(Icons.person_add, 'Add Team Member', onTap: () {}),
        _buildActionButton(Icons.inventory_2, 'New Asset Entry', onTap: () {}),
        _buildActionButton(Icons.assessment, 'Generate Report', onTap: () {}),
        _buildPrimaryActionButton('Start Disposal Process', onTap: () {}),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton(String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0EA5E9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isNarrow, List<_StatItem> stats) {
    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => _buildStatCard(stat, flex: false)).toList(),
      );
    }

    return Row(
      children: stats.map((stat) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildStatCard(stat),
        ),
      )).toList(),
    );
  }

  Widget _buildStatCard(_StatItem stat, {bool flex = true}) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(stat.icon, size: 18, color: stat.color),
              ),
              const Spacer(),
              Icon(Icons.trending_up, size: 14, color: Colors.green[400]),
            ],
          ),
          const SizedBox(height: 12),
          Text(stat.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: stat.color)),
          const SizedBox(height: 4),
          Text(stat.label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildInventoryTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Asset Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
                    SizedBox(height: 4),
                    Text('Track active assets, condition, and disposal readiness', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              _buildActionButton(Icons.filter_list, 'Filter', onTap: () {}),
              const SizedBox(width: 8),
              _buildActionButton(Icons.upload_file, 'Upload CSV', onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),
          _buildInventoryTableContent(),
        ],
      ),
    );
  }

  Widget _buildInventoryTableContent() {
    final projectId = _getProjectId();
    if (projectId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No project selected. Please open a project first.',
              style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }
    
    return StreamBuilder<List<SalvageInventoryItemModel>>(
      stream: SalvageService.streamInventoryItems(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            ),
          );
        }
        
        final items = snapshot.data ?? [];
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('Asset', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Condition', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Est. Value', style: TextStyle(fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
            ],
            rows: items.isEmpty
                ? [
                    const DataRow(cells: [
                      DataCell(Text('No inventory items added yet', style: TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic))),
                      DataCell(SizedBox()),
                      DataCell(SizedBox()),
                      DataCell(SizedBox()),
                      DataCell(SizedBox()),
                      DataCell(SizedBox()),
                      DataCell(SizedBox()),
                    ]),
                  ]
                : items.map((item) {
                    Color statusColor;
                    switch (item.status.toLowerCase()) {
                      case 'ready':
                        statusColor = Colors.green;
                        break;
                      case 'pending':
                        statusColor = Colors.orange;
                        break;
                      case 'flagged':
                        statusColor = Colors.red;
                        break;
                      default:
                        statusColor = Colors.blue;
                    }
                    
                    return DataRow(
                      cells: [
                        DataCell(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item.assetId, style: const TextStyle(fontSize: 12, color: Color(0xFF0EA5E9), fontWeight: FontWeight.w600)),
                            Text(item.name, style: const TextStyle(fontSize: 13)),
                          ],
                        )),
                        DataCell(_buildCategoryChip(item.category)),
                        DataCell(Text(item.condition, style: const TextStyle(fontSize: 13))),
                        DataCell(Text(item.location, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                        DataCell(_buildStatusBadge(item.status, statusColor)),
                        DataCell(Text(item.estimatedValue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => _showEditInventoryDialog(context, item),
                              color: const Color(0xFF64748B),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 16),
                              onPressed: () => _showDeleteInventoryDialog(context, item),
                              color: Colors.red,
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
          ),
        );
      },
    );
  }
  
  void _showEditInventoryDialog(BuildContext context, SalvageInventoryItemModel item) {
    final projectId = _getProjectId();
    if (projectId == null) return;
    
    final assetIdController = TextEditingController(text: item.assetId);
    final nameController = TextEditingController(text: item.name);
    final categoryController = TextEditingController(text: item.category);
    final conditionController = TextEditingController(text: item.condition);
    final locationController = TextEditingController(text: item.location);
    final statusController = TextEditingController(text: item.status);
    final valueController = TextEditingController(text: item.estimatedValue);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Inventory Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: assetIdController, decoration: const InputDecoration(labelText: 'Asset ID *')),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name *')),
              const SizedBox(height: 12),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category *')),
              const SizedBox(height: 12),
              TextField(controller: conditionController, decoration: const InputDecoration(labelText: 'Condition *')),
              const SizedBox(height: 12),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location *')),
              const SizedBox(height: 12),
              TextField(controller: statusController, decoration: const InputDecoration(labelText: 'Status *')),
              const SizedBox(height: 12),
              TextField(controller: valueController, decoration: const InputDecoration(labelText: 'Estimated Value *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await SalvageService.updateInventoryItem(
                  projectId: projectId,
                  itemId: item.id,
                  assetId: assetIdController.text,
                  name: nameController.text,
                  category: categoryController.text,
                  condition: conditionController.text,
                  location: locationController.text,
                  status: statusController.text,
                  estimatedValue: valueController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item updated successfully')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
  
  void _showAddInventoryDialog(BuildContext context) {
    final projectId = _getProjectId();
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    
    final assetIdController = TextEditingController();
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final conditionController = TextEditingController();
    final locationController = TextEditingController();
    final statusController = TextEditingController(text: 'Pending');
    final valueController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Inventory Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: assetIdController, decoration: const InputDecoration(labelText: 'Asset ID *')),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name *')),
              const SizedBox(height: 12),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category *')),
              const SizedBox(height: 12),
              TextField(controller: conditionController, decoration: const InputDecoration(labelText: 'Condition *')),
              const SizedBox(height: 12),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location *')),
              const SizedBox(height: 12),
              TextField(controller: statusController, decoration: const InputDecoration(labelText: 'Status *')),
              const SizedBox(height: 12),
              TextField(controller: valueController, decoration: const InputDecoration(labelText: 'Estimated Value *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (assetIdController.text.isEmpty || nameController.text.isEmpty || categoryController.text.isEmpty ||
                  conditionController.text.isEmpty || locationController.text.isEmpty || statusController.text.isEmpty ||
                  valueController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all required fields')),
                );
                return;
              }
              
              try {
                await SalvageService.createInventoryItem(
                  projectId: projectId,
                  assetId: assetIdController.text,
                  name: nameController.text,
                  category: categoryController.text,
                  condition: conditionController.text,
                  location: locationController.text,
                  status: statusController.text,
                  estimatedValue: valueController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added successfully')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteInventoryDialog(BuildContext context, SalvageInventoryItemModel item) {
    final projectId = _getProjectId();
    if (projectId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inventory Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await SalvageService.deleteInventoryItem(projectId: projectId, itemId: item.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted successfully')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySignalsPanel() {
    return Column(
      children: [
        _buildSignalCard(
          title: 'Category Mix',
          subtitle: 'Distribution of assets by category',
          child: Column(
            children: const [
              _SignalBar(label: 'Electronics', value: 0.42, color: Color(0xFF0EA5E9)),
              _SignalBar(label: 'Infrastructure', value: 0.28, color: Color(0xFF6366F1)),
              _SignalBar(label: 'Safety', value: 0.16, color: Color(0xFFF59E0B)),
              _SignalBar(label: 'Vehicles', value: 0.14, color: Color(0xFF22C55E)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSignalCard(
          title: 'Condition Snapshot',
          subtitle: 'Asset readiness by condition',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ConditionItem(label: 'Excellent', count: '28 assets', color: Color(0xFF22C55E)),
              _ConditionItem(label: 'Good', count: '34 assets', color: Color(0xFF10B981)),
              _ConditionItem(label: 'Fair', count: '18 assets', color: Color(0xFFF59E0B)),
              _ConditionItem(label: 'Needs Review', count: '6 assets', color: Color(0xFFEF4444)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignalCard({required String title, required String subtitle, required Widget child}) {
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildQueueBoard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Queue Pipeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
          const SizedBox(height: 4),
          Text('Stage assets by review status and auction readiness', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 700;
              final lanes = [
                _buildQueueLane('Review', const Color(0xFFFDE68A)),
                _buildQueueLane('Approved', const Color(0xFFBFDBFE)),
                _buildQueueLane('Auction', const Color(0xFFBBF7D0)),
              ];

              if (isStacked) {
                return Column(
                  children: lanes.map((lane) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: lane,
                  )).toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lanes.map((lane) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: lane,
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQueueLane(String status, Color accent) {
    final items = _queueBoardItems.where((item) => item.status == status).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            _buildQueueCard(item),
            const SizedBox(height: 10),
          ],
          if (items.isEmpty)
            Text('No items', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildQueueCard(_QueueBoardItem item) {
    final priorityColor = item.priority == 'High'
        ? const Color(0xFFEF4444)
        : item.priority == 'Medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9))),
          const SizedBox(height: 4),
          Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPriorityBadge(item.priority, priorityColor),
              const Spacer(),
              Text(item.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team Allocation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
                    SizedBox(height: 4),
                    Text('Workload balance by role and focus area', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              _buildActionButton(Icons.person_add_alt_1, 'Assign Role', onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Focus Area', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Workload', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                    rows: _allocationItems.map((item) {
                      final statusColor = item.status == 'Active' ? Colors.green : Colors.orange;
                      return DataRow(cells: [
                        DataCell(Text(item.name, style: const TextStyle(fontSize: 13))),
                        DataCell(Text(item.role, style: const TextStyle(fontSize: 13))),
                        DataCell(Text(item.focus, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                        DataCell(_buildWorkloadChip(item.workload)),
                        DataCell(_buildStatusBadge(item.status, statusColor)),
                        DataCell(Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: () {}, color: const Color(0xFF64748B)),
                            IconButton(icon: const Icon(Icons.more_horiz, size: 16), onPressed: () {}, color: const Color(0xFF64748B)),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadChip(int workload) {
    final color = workload >= 80
        ? const Color(0xFFEF4444)
        : workload >= 65
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$workload%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildCapacityPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Capacity Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Allocation by function', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          for (final item in _capacityItems) ...[
            _CapacityBar(item: item),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildCoveragePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shift Coverage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Upcoming availability and handoffs', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          _buildCoverageRow('Field Ops', 'Mon - Thu', 'On-site', const Color(0xFF38BDF8)),
          _buildCoverageRow('Compliance', 'Tue - Fri', 'Remote', const Color(0xFF34D399)),
          _buildCoverageRow('Logistics', 'Wed - Sat', 'Hybrid', const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildCoverageRow(String label, String window, String mode, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(window, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(mode, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamManagementPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team Roster', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
                    SizedBox(height: 4),
                    Text('Manage disposal team members and assignments', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Filter'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Tasks', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                    rows: _teamMembers.map((member) => DataRow(
                      cells: [
                        DataCell(Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                              child: Text(member.name[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9))),
                            ),
                            const SizedBox(width: 8),
                            Text(member.name, style: const TextStyle(fontSize: 13)),
                          ],
                        )),
                        DataCell(Text(member.role, style: const TextStyle(fontSize: 13))),
                        DataCell(Text(member.email, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                        DataCell(_buildStatusBadge(member.status, member.statusColor)),
                        DataCell(Text('${member.tasks}', style: const TextStyle(fontSize: 13))),
                        DataCell(Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: () {}, color: const Color(0xFF64748B)),
                            IconButton(icon: const Icon(Icons.visibility, size: 16), onPressed: () {}, color: const Color(0xFF64748B)),
                          ],
                        )),
                      ],
                    )).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDisposalQueuePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Disposal Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
                    SizedBox(height: 4),
                    Text('Track assets through the disposal workflow', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              _buildActionButton(Icons.add, 'Add Item', onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('Asset ID', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Est. Value', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                    rows: _disposalItems.map((item) => DataRow(
                      cells: [
                        DataCell(Text(item.id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9)))),
                        DataCell(Text(item.description, style: const TextStyle(fontSize: 13))),
                        DataCell(_buildCategoryChip(item.category)),
                        DataCell(_buildStatusPill(item.status)),
                        DataCell(Text(item.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                        DataCell(_buildPriorityBadge(item.priority, item.priorityColor)),
                      ],
                    )).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompliancePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Compliance & Regulations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
          const SizedBox(height: 4),
          Text('Environmental and safety compliance tracking', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 20),
          _buildComplianceItem('EPA Disposal Guidelines', 'Compliant', Icons.check_circle, Colors.green),
          _buildComplianceItem('OSHA Safety Standards', 'Compliant', Icons.check_circle, Colors.green),
          _buildComplianceItem('Hazmat Certification', 'Renewal Due', Icons.warning, Colors.orange),
          _buildComplianceItem('Asset Transfer Records', 'Compliant', Icons.check_circle, Colors.green),
          _buildComplianceItem('Environmental Impact Report', 'Pending', Icons.schedule, Colors.blue),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hazmat certification expires in 15 days. Schedule renewal.',
                    style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceItem(String label, String status, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Disposal Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
          const SizedBox(height: 4),
          Text('Upcoming milestones and deadlines', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 20),
          _buildTimelineItem('Asset Audit Complete', 'Mar 15', true),
          _buildTimelineItem('Vendor Bidding Opens', 'Mar 20', true),
          _buildTimelineItem('Auction Date', 'Mar 28', false),
          _buildTimelineItem('Final Disposal Report', 'Apr 5', false),
          _buildTimelineItem('Project Closure', 'Apr 15', false),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, String date, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: completed ? Colors.green : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check : Icons.circle,
              size: 14,
              color: completed ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: completed ? const Color(0xFF64748B) : const Color(0xFF1A1D1F))),
                Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          if (!completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Upcoming', style: TextStyle(fontSize: 10, color: Color(0xFF0284C7))),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightsRow(bool isNarrow) {
    final insights = [
      _InsightCard('Cost Recovery Potential', '\$58,200', 'Based on current market valuations for salvageable assets.', Icons.trending_up, Colors.green),
      _InsightCard('Environmental Impact', '12.5 tons', 'CO2 emissions avoided through proper recycling.', Icons.eco, Colors.teal),
      _InsightCard('Average Disposal Time', '18 days', '23% faster than industry benchmark.', Icons.speed, Colors.blue),
    ];

    if (isNarrow) {
      return Column(
        children: insights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildInsightCard(insight),
        )).toList(),
      );
    }

    return Row(
      children: insights.map((insight) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildInsightCard(insight),
        ),
      )).toList(),
    );
  }

  Widget _buildInsightCard(_InsightCard insight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: insight.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(insight.icon, size: 18, color: insight.color),
              ),
              const Spacer(),
              Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 12),
          Text(insight.title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(insight.value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: insight.color)),
          const SizedBox(height: 8),
          Text(insight.description, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(category, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'Completed':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        break;
      case 'In Progress':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF2563EB);
        break;
      case 'Pending Auction':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        break;
      case 'Approved':
        bgColor = const Color(0xFFE0E7FF);
        textColor = const Color(0xFF4F46E5);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textColor)),
    );
  }

  Widget _buildPriorityBadge(String priority, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(priority, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _TeamMember {
  final String name;
  final String role;
  final String email;
  final String status;
  final int tasks;
  final Color statusColor;

  const _TeamMember(this.name, this.role, this.email, this.status, this.tasks, this.statusColor);
}

class _DisposalItem {
  final String id;
  final String description;
  final String category;
  final String status;
  final String value;
  final String priority;
  final Color priorityColor;

  const _DisposalItem(this.id, this.description, this.category, this.status, this.value, this.priority, this.priorityColor);
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _InsightCard {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color color;

  const _InsightCard(this.title, this.value, this.description, this.icon, this.color);
}

class _SignalBar extends StatelessWidget {
  const _SignalBar({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              Text('${(value * 100).round()}%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionItem extends StatelessWidget {
  const _ConditionItem({required this.label, required this.count, required this.color});

  final String label;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Text(count, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  const _CapacityBar({required this.item});

  final _CapacityItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            Text('${(item.value * 100).round()}%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: item.value,
            minHeight: 8,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(item.color),
          ),
        ),
      ],
    );
  }
}

class _InventoryItem {
  final String id;
  final String name;
  final String category;
  final String condition;
  final String location;
  final String status;
  final String value;
  final Color statusColor;

  const _InventoryItem(this.id, this.name, this.category, this.condition, this.location, this.status, this.value, this.statusColor);
}

class _QueueBoardItem {
  final String id;
  final String title;
  final String status;
  final String priority;
  final String value;

  const _QueueBoardItem(this.id, this.title, this.status, this.priority, this.value);
}

class _AllocationItem {
  final String name;
  final String role;
  final String focus;
  final int workload;
  final String status;

  const _AllocationItem(this.name, this.role, this.focus, this.workload, this.status);
}

class _CapacityItem {
  final String label;
  final double value;
  final Color color;

  const _CapacityItem(this.label, this.value, this.color);
}
