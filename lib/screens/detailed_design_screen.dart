import 'package:flutter/material.dart';
import 'package:ndu_project/screens/agile_development_iterations_screen.dart';
import 'package:ndu_project/screens/vendor_tracking_screen.dart';
import 'package:ndu_project/models/design_component.dart';
import 'package:ndu_project/services/execution_phase_service.dart';
import 'package:ndu_project/utils/auto_bullet_text_controller.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/detailed_design_table_widget.dart';

class DetailedDesignScreen extends StatefulWidget {
  const DetailedDesignScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DetailedDesignScreen()),
    );
  }

  @override
  State<DetailedDesignScreen> createState() => _DetailedDesignScreenState();
}

class _DetailedDesignScreenState extends State<DetailedDesignScreen> {
  final Set<String> _selectedFilters = {'All packages'};
  List<DesignComponent> _components = [];
  bool _isLoading = false;

  String? get _projectId {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadComponents());
  }

  Future<void> _loadComponents() async {
    final projectId = _projectId;
    if (projectId == null) return;

    setState(() => _isLoading = true);
    try {
      final components = await ExecutionPhaseService.loadDesignComponents(
        projectId: projectId,
      );
      if (mounted) {
        setState(() {
          _components = components;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading design components: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Detailed Design',
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
                if (isNarrow)
                  Column(
                    children: [
                      _buildPackageRegister(),
                      const SizedBox(height: 20),
                      _buildReviewPanel(),
                      const SizedBox(height: 20),
                      _buildDecisionPanel(),
                      const SizedBox(height: 20),
                      _buildArtifactsPanel(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildPackageRegister()),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildReviewPanel(),
                            const SizedBox(height: 20),
                            _buildDecisionPanel(),
                            const SizedBox(height: 20),
                            _buildArtifactsPanel(),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                LaunchPhaseNavigation(
                  backLabel: 'Back: Vendor Tracking',
                  nextLabel: 'Next: Agile Development Iterations',
                  onBack: () => VendorTrackingScreen.open(context),
                  onNext: () => AgileDevelopmentIterationsScreen.open(context),
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
            'EXECUTION DESIGN',
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
                    'Detailed Design',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Finalize the technical and operational blueprints. Define specific architectural components, security protocols, and integration workflows to ensure a robust deployment.',
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
        _actionButton(Icons.add, 'Add package',
            onPressed: () => _showAddComponentDialog(context)),
        _actionButton(Icons.description_outlined, 'Export bundle',
            onPressed: () {}),
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

  Widget _buildFilterChips() {
    const filters = ['All packages', 'Ready', 'In review', 'Draft', 'Pending'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((filter) {
        final selected = _selectedFilters.contains(filter);
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFilters.clear();
              _selectedFilters.add(filter);
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
    // Calculate metrics from components
    final coreComponents = _components.length;
    final securityStandards =
        _components.where((c) => c.category == 'Security').length;
    final integrationCount =
        _components.where((c) => c.integrationPoint.isNotEmpty).length;
    final totalComponents = _components.length;
    final integrationReadiness = totalComponents > 0
        ? ((integrationCount / totalComponents) * 100).round()
        : 0;

    final stats = [
      _StatCardData('Core Components', '$coreComponents',
          'Technical modules defined', const Color(0xFF0EA5E9)),
      _StatCardData('Security Standards', '$securityStandards',
          'Compliance protocols', const Color(0xFFEF4444)),
      _StatCardData(
          'Integration Readiness',
          '$integrationReadiness%',
          '${integrationCount}/${totalComponents} mapped',
          const Color(0xFF6366F1)),
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

  Widget _buildPackageRegister() {
    if (_isLoading) {
      return _PanelShell(
        title: 'Design package register',
        subtitle: 'Traceable artifacts and approvals',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final filteredComponents = _filterComponents(_components);

    return _PanelShell(
      title: 'Design package register',
      subtitle: 'Traceable artifacts and approvals',
      trailing: _actionButton(Icons.filter_list, 'Filter'),
      child: DetailedDesignTableWidget(
        components: filteredComponents,
        onUpdated: (component) {
          setState(() {
            final index = _components.indexWhere((c) => c.id == component.id);
            if (index != -1) {
              _components[index] = component;
            } else {
              _components.add(component);
            }
          });
        },
        onDeleted: (component) {
          setState(() {
            _components.removeWhere((c) => c.id == component.id);
          });
        },
      ),
    );
  }

  List<DesignComponent> _filterComponents(List<DesignComponent> components) {
    if (_selectedFilters.contains('All packages')) return components;
    return components.where((c) {
      if (_selectedFilters.contains('Ready') && c.status == 'Approved')
        return true;
      if (_selectedFilters.contains('In review') && c.status == 'Reviewed')
        return true;
      if (_selectedFilters.contains('Draft') && c.status == 'Draft')
        return true;
      if (_selectedFilters.contains('Pending') && c.status == 'Draft')
        return true;
      return false;
    }).toList();
  }

  Widget _buildReviewPanel() {
    return _PanelShell(
      title: 'Design review pulse',
      subtitle: 'Readiness by workstream',
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No review data available',
              style: TextStyle(color: Color(0xFF64748B))),
        ),
      ),
    );
  }

  Widget _buildDecisionPanel() {
    return _PanelShell(
      title: 'Decision log',
      subtitle: 'Open decisions needing closure',
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No decisions logged',
              style: TextStyle(color: Color(0xFF64748B))),
        ),
      ),
    );
  }

  Widget _buildArtifactsPanel() {
    return _PanelShell(
      title: 'Artifact readiness',
      subtitle: 'Design assets staged for handoff',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ArtifactItem('API schema v4', 'Ready for build', true),
          _ArtifactItem('Sequence diagrams', 'Review pending', false),
          _ArtifactItem('Observability plan', 'Ready for build', true),
        ],
      ),
    );
  }

  void _showAddComponentDialog(BuildContext context) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }

    final componentNameController = TextEditingController();
    var selectedCategory = 'Backend';
    final specificationController = AutoBulletTextController(text: '');
    final integrationController = TextEditingController();
    var selectedStatus = 'Draft';
    final notesController = TextEditingController(); // Prose, no bullets

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Design Component',
              style: TextStyle(fontSize: 18)),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: componentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Component Name *',
                      hintText: 'e.g., API Gateway, User Authentication',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                        labelText: 'Category *', isDense: true),
                    items: const [
                      'UI/UX',
                      'Backend',
                      'Security',
                      'Networking',
                      'Physical Infrastructure',
                    ]
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedCategory = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: specificationController,
                    decoration: const InputDecoration(
                      labelText: 'Specification Details',
                      hintText: 'Use "." bullet format',
                      isDense: true,
                    ),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: integrationController,
                    decoration: const InputDecoration(
                      labelText: 'Integration Point',
                      hintText: 'What other systems does this touch?',
                      isDense: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                        labelText: 'Status *', isDense: true),
                    items: const ['Draft', 'Reviewed', 'Approved']
                        .map((status) => DropdownMenuItem(
                            value: status, child: Text(status)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedStatus = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Design Notes',
                      hintText: 'Prose description, no bullets',
                      isDense: true,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (componentNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a component name')),
                  );
                  return;
                }

                try {
                  final newComponent = DesignComponent(
                    componentName: componentNameController.text.trim(),
                    category: selectedCategory,
                    specificationDetails: specificationController.text.trim(),
                    integrationPoint: integrationController.text.trim(),
                    status: selectedStatus,
                    designNotes: notesController.text.trim(),
                  );

                  setState(() {
                    _components.add(newComponent);
                  });

                  // Save to service
                  await ExecutionPhaseService.saveDesignComponents(
                    projectId: projectId,
                    components: _components,
                  );

                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Component added successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding component: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
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

class _ArtifactItem extends StatelessWidget {
  const _ArtifactItem(this.title, this.status, this.ready);

  final String title;
  final String status;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final color = ready ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
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
          Icon(ready ? Icons.check_circle : Icons.schedule,
              size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(status,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
