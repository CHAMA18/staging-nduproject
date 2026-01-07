import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/services/vendor_service.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:intl/intl.dart';

class VendorTrackingScreen extends StatefulWidget {
  const VendorTrackingScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VendorTrackingScreen()),
    );
  }

  @override
  State<VendorTrackingScreen> createState() => _VendorTrackingScreenState();
}

class _VendorTrackingScreenState extends State<VendorTrackingScreen> {
  final Set<String> _selectedFilters = {'All vendors'};

  String? get _projectId {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Vendor Tracking',
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isNarrow),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 20),
                _buildStatsRow(isNarrow),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildVendorRegister(),
                    const SizedBox(height: 20),
                    _buildPerformancePanel(),
                    const SizedBox(height: 20),
                    _buildSignalsPanel(),
                    const SizedBox(height: 20),
                    _buildActionPanel(),
                  ],
                ),
              ],
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'VENDOR OVERSIGHT',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Vendor Tracking',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Monitor vendor performance, compliance, and delivery health across execution.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (!isNarrow) _buildHeaderActions(),
          ],
        ),
        if (isNarrow) ...[
          const SizedBox(height: 12),
          _buildHeaderActions(),
        ],
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _actionButton(Icons.add, 'Add vendor',
            onPressed: () => _showAddVendorDialog(context)),
        _actionButton(Icons.assessment_outlined, 'Quarterly review'),
        _actionButton(Icons.description_outlined, 'Export scorecard'),
        _primaryButton('Start vendor audit'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      label: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _primaryButton(String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.play_arrow, size: 18),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All vendors', 'At risk', 'Watchlist', 'Strategic', 'New'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((filter) {
        final selected = _selectedFilters.contains(filter);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedFilters.remove(filter);
              } else {
                _selectedFilters.add(filter);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              filter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow(bool isNarrow) {
    if (_projectId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<VendorModel>>(
      stream: VendorService.streamVendors(_projectId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final vendors = snapshot.data!;
        final activeVendors = vendors.where((v) => v.status == 'Active').length;
        final onTimeAvg = vendors.isEmpty
            ? 0.0
            : vendors.map((v) => v.onTimeDelivery).reduce((a, b) => a + b) /
                vendors.length;
        final atRiskCount = vendors.where((v) => v.status == 'At risk').length;
        final avgRating = _calculateAverageRating(vendors);

        final stats = [
          _StatCardData('Active vendors', '$activeVendors',
              '${vendors.length} total', const Color(0xFF0EA5E9)),
          _StatCardData('On-time delivery', '${(onTimeAvg * 100).round()}%',
              '${vendors.length} vendors tracked', const Color(0xFF10B981)),
          _StatCardData(
              'Risk rating',
              avgRating,
              atRiskCount > 0 ? '$atRiskCount at risk' : 'All stable',
              const Color(0xFFF59E0B)),
          _StatCardData('Total vendors', '${vendors.length}',
              'Across all categories', const Color(0xFF6366F1)),
        ];

        if (isNarrow) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: stats.map((stat) => _buildStatCard(stat)).toList(),
          );
        }

        return Row(
          children: stats
              .map((stat) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildStatCard(stat),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  String _calculateAverageRating(List<VendorModel> vendors) {
    if (vendors.isEmpty) return 'N/A';
    int total = 0;
    for (var vendor in vendors) {
      if (vendor.rating == 'A')
        total += 4;
      else if (vendor.rating == 'B')
        total += 3;
      else if (vendor.rating == 'C')
        total += 2;
      else if (vendor.rating == 'D') total += 1;
    }
    final avg = total / vendors.length;
    if (avg >= 3.5) return 'A';
    if (avg >= 2.5) return 'B';
    if (avg >= 1.5) return 'C';
    return 'D';
  }

  Widget _buildStatCard(_StatCardData data) {
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
          Text(data.value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: data.color)),
          const SizedBox(height: 6),
          Text(data.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(data.supporting,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: data.color)),
        ],
      ),
    );
  }

  Widget _buildVendorRegister() {
    if (_projectId == null) {
      return _PanelShell(
        title: 'Vendor scorecard',
        subtitle: 'Performance, rating, and compliance checkpoints',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('No project selected. Please open a project first.',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
        ),
      );
    }

    return _PanelShell(
      title: 'Vendor scorecard',
      subtitle: 'Performance, rating, and compliance checkpoints',
      trailing: _actionButton(Icons.filter_list, 'Filter'),
      child: StreamBuilder<List<VendorModel>>(
        stream: VendorService.streamVendors(_projectId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator()));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading vendors: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          final vendors = snapshot.data ?? [];
          final filteredVendors = _filterVendors(vendors);

          if (filteredVendors.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('No vendors found.',
                        style: TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddVendorDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add First Vendor'),
                    ),
                  ],
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(
                          label: Text('Vendor',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(
                          label: Text('Category',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(
                          label: Text('SLA',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(
                          label: Text('Rating',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(
                          label: Text('Status',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(
                          label: Text('Next review',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(
                          label: Text('Actions',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                    rows: filteredVendors.map((vendor) {
                      return DataRow(cells: [
                        DataCell(Text(vendor.name,
                            style: const TextStyle(fontSize: 13))),
                        DataCell(_chip(vendor.category)),
                        DataCell(Text(vendor.sla,
                            style: const TextStyle(fontSize: 12))),
                        DataCell(_ratingChip(vendor.rating)),
                        DataCell(_statusChip(vendor.status)),
                        DataCell(Text(vendor.nextReview,
                            style: const TextStyle(fontSize: 12))),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 18, color: Color(0xFF64748B)),
                                onPressed: () =>
                                    _showEditVendorDialog(context, vendor),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 18, color: Color(0xFFEF4444)),
                                onPressed: () =>
                                    _showDeleteVendorDialog(context, vendor),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<VendorModel> _filterVendors(List<VendorModel> vendors) {
    if (_selectedFilters.contains('All vendors')) return vendors;
    return vendors.where((v) {
      if (_selectedFilters.contains('At risk') && v.status == 'At risk')
        return true;
      if (_selectedFilters.contains('Watchlist') && v.status == 'Watch')
        return true;
      if (_selectedFilters.contains('Strategic') && v.rating == 'A')
        return true;
      if (_selectedFilters.contains('New') && v.status == 'Onboard')
        return true;
      return false;
    }).toList();
  }

  Widget _buildPerformancePanel() {
    if (_projectId == null) {
      return _PanelShell(
        title: 'Performance pulse',
        subtitle: 'Key service health indicators',
        child: const SizedBox.shrink(),
      );
    }

    return _PanelShell(
      title: 'Performance pulse',
      subtitle: 'Key service health indicators',
      child: StreamBuilder<List<VendorModel>>(
        stream: VendorService.streamVendors(_projectId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No vendor data available',
                    style: TextStyle(color: Color(0xFF64748B))),
              ),
            );
          }

          final vendors = snapshot.data!;
          final onTimeAvg =
              vendors.map((v) => v.onTimeDelivery).reduce((a, b) => a + b) /
                  vendors.length;
          final incidentAvg =
              vendors.map((v) => v.incidentResponse).reduce((a, b) => a + b) /
                  vendors.length;
          final qualityAvg =
              vendors.map((v) => v.qualityScore).reduce((a, b) => a + b) /
                  vendors.length;
          final costAvg =
              vendors.map((v) => v.costAdherence).reduce((a, b) => a + b) /
                  vendors.length;

          final pulses = [
            _PerformancePulse(
                'On-time delivery', onTimeAvg, const Color(0xFF10B981)),
            _PerformancePulse(
                'Incident response', incidentAvg, const Color(0xFF0EA5E9)),
            _PerformancePulse(
                'Quality score', qualityAvg, const Color(0xFF6366F1)),
            _PerformancePulse(
                'Cost adherence', costAvg, const Color(0xFFF59E0B)),
          ];

          return Column(
            children: pulses.map((pulse) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(pulse.label,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600))),
                        Text('${(pulse.value * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pulse.value,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(pulse.color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSignalsPanel() {
    if (_projectId == null) {
      return _PanelShell(
        title: 'Risk signals',
        subtitle: 'Active alerts and vendor watch items',
        child: const SizedBox.shrink(),
      );
    }

    return _PanelShell(
      title: 'Risk signals',
      subtitle: 'Active alerts and vendor watch items',
      child: StreamBuilder<List<VendorModel>>(
        stream: VendorService.streamVendors(_projectId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final vendors = snapshot.data!;
          final atRiskCount =
              vendors.where((v) => v.status == 'At risk').length;
          final watchCount = vendors.where((v) => v.status == 'Watch').length;
          final lowSlaCount = vendors.where((v) {
            final slaNum = double.tryParse(v.sla.replaceAll('%', '')) ?? 0;
            return slaNum < 80;
          }).length;

          final signals = <_SignalItem>[];
          if (atRiskCount > 0) {
            signals.add(_SignalItem('At-risk vendors',
                '$atRiskCount vendor${atRiskCount > 1 ? 's' : ''} require immediate attention.'));
          }
          if (watchCount > 0) {
            signals.add(_SignalItem('Watchlist items',
                '$watchCount vendor${watchCount > 1 ? 's' : ''} on watchlist.'));
          }
          if (lowSlaCount > 0) {
            signals.add(_SignalItem('SLA breaches',
                '$lowSlaCount vendor${lowSlaCount > 1 ? 's' : ''} below 80% SLA.'));
          }

          if (signals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No active risk signals',
                    style: TextStyle(color: Color(0xFF10B981))),
              ),
            );
          }

          return Column(
            children: signals.map((signal) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(signal.title,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(signal.subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildActionPanel() {
    return _PanelShell(
      title: 'Action plan',
      subtitle: 'Upcoming touchpoints and remediation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ActionItem('Quarterly business review', 'Oct 21', 'Agenda locked'),
          _ActionItem('Security compliance audit', 'Oct 25', 'Docs requested'),
          _ActionItem(
              'Performance tuning workshop', 'Nov 02', 'Pending invite'),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569))),
    );
  }

  Widget _ratingChip(String label) {
    final color = label == 'A'
        ? const Color(0xFF10B981)
        : label == 'B'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _statusChip(String label) {
    Color color;
    switch (label) {
      case 'At risk':
        color = const Color(0xFFEF4444);
        break;
      case 'Watch':
        color = const Color(0xFFF59E0B);
        break;
      case 'Onboard':
        color = const Color(0xFF6366F1);
        break;
      default:
        color = const Color(0xFF10B981);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  void _showAddVendorDialog(BuildContext context) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }

    _showVendorDialog(context, null, projectId);
  }

  void _showEditVendorDialog(BuildContext context, VendorModel vendor) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showVendorDialog(context, vendor, projectId);
  }

  void _showVendorDialog(
      BuildContext context, VendorModel? vendor, String projectId) {
    final isEdit = vendor != null;
    final nameController = TextEditingController(text: vendor?.name ?? '');
    final categoryController =
        TextEditingController(text: vendor?.category ?? '');
    final slaController = TextEditingController(text: vendor?.sla ?? '');
    final ratingController = TextEditingController(text: vendor?.rating ?? 'B');
    final statusController =
        TextEditingController(text: vendor?.status ?? 'Active');
    final nextReviewController =
        TextEditingController(text: vendor?.nextReview ?? '');
    final onTimeController = TextEditingController(
        text: vendor?.onTimeDelivery.toString() ?? '0.86');
    final incidentController = TextEditingController(
        text: vendor?.incidentResponse.toString() ?? '0.72');
    final qualityController =
        TextEditingController(text: vendor?.qualityScore.toString() ?? '0.79');
    final costController =
        TextEditingController(text: vendor?.costAdherence.toString() ?? '0.65');
    final notesController = TextEditingController(text: vendor?.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Vendor' : 'Add New Vendor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Vendor Name *')),
              const SizedBox(height: 12),
              TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category *')),
              const SizedBox(height: 12),
              TextField(
                  controller: slaController,
                  decoration: const InputDecoration(
                      labelText: 'SLA % *', hintText: 'e.g., 92%')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: ratingController.text,
                decoration: const InputDecoration(labelText: 'Rating *'),
                items: ['A', 'B', 'C', 'D']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => ratingController.text = v ?? 'B',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: statusController.text,
                decoration: const InputDecoration(labelText: 'Status *'),
                items: ['Active', 'Watch', 'At risk', 'Onboard']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => statusController.text = v ?? 'Active',
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: nextReviewController,
                  decoration: const InputDecoration(
                      labelText: 'Next Review *', hintText: 'e.g., Oct 28')),
              const SizedBox(height: 12),
              TextField(
                  controller: onTimeController,
                  decoration: const InputDecoration(
                      labelText: 'On-time Delivery (0.0-1.0) *')),
              const SizedBox(height: 12),
              TextField(
                  controller: incidentController,
                  decoration: const InputDecoration(
                      labelText: 'Incident Response (0.0-1.0) *')),
              const SizedBox(height: 12),
              TextField(
                  controller: qualityController,
                  decoration: const InputDecoration(
                      labelText: 'Quality Score (0.0-1.0) *')),
              const SizedBox(height: 12),
              TextField(
                  controller: costController,
                  decoration: const InputDecoration(
                      labelText: 'Cost Adherence (0.0-1.0) *')),
              const SizedBox(height: 12),
              TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  categoryController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please fill in required fields')),
                );
                return;
              }

              try {
                final onTime = double.tryParse(onTimeController.text) ?? 0.0;
                final incident =
                    double.tryParse(incidentController.text) ?? 0.0;
                final quality = double.tryParse(qualityController.text) ?? 0.0;
                final cost = double.tryParse(costController.text) ?? 0.0;

                if (isEdit && vendor != null) {
                  await VendorService.updateVendor(
                    projectId: projectId,
                    vendorId: vendor.id,
                    name: nameController.text,
                    category: categoryController.text,
                    sla: slaController.text,
                    rating: ratingController.text,
                    status: statusController.text,
                    nextReview: nextReviewController.text,
                    onTimeDelivery: onTime,
                    incidentResponse: incident,
                    qualityScore: quality,
                    costAdherence: cost,
                    notes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  );
                } else {
                  await VendorService.createVendor(
                    projectId: projectId,
                    name: nameController.text,
                    category: categoryController.text,
                    sla: slaController.text,
                    rating: ratingController.text,
                    status: statusController.text,
                    nextReview: nextReviewController.text,
                    onTimeDelivery: onTime,
                    incidentResponse: incident,
                    qualityScore: quality,
                    costAdherence: cost,
                    notes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(isEdit
                            ? 'Vendor updated successfully'
                            : 'Vendor added successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteVendorDialog(BuildContext context, VendorModel vendor) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor'),
        content: Text(
            'Are you sure you want to delete "${vendor.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await VendorService.deleteVendor(
                    projectId: projectId, vendorId: vendor.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vendor deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting vendor: $e')),
                  );
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
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem(this.title, this.date, this.status);

  final String title;
  final String date;
  final String status;

  @override
  Widget build(BuildContext context) {
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
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Color(0xFF0EA5E9), shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(date,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(status,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _PerformancePulse {
  const _PerformancePulse(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _SignalItem {
  const _SignalItem(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
