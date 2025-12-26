import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/architecture_canvas.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/architecture_service.dart';
import 'package:ndu_project/services/project_navigation_service.dart';

class DesignPhaseScreen extends StatefulWidget {
  const DesignPhaseScreen({super.key});

  @override
  State<DesignPhaseScreen> createState() => _DesignPhaseScreenState();
}

class _DesignPhaseScreenState extends State<DesignPhaseScreen> {
  // Dynamic Output Documents list
  final List<_DocItem> _outputDocs = [];

  // Architecture canvas state
  final List<ArchitectureNode> _nodes = [];
  final List<ArchitectureEdge> _edges = [];
  int _nodeCounter = 0;

  // Persistence state
  String? _projectId;
  bool _isSaving = false;
  DateTime? _lastSavedAt;
  Timer? _saveDebounce;

  // Component Library for dragging into Output Docs OR directly onto canvas
  final List<_PaletteItem> _library = const [
    _PaletteItem('Service', Icons.settings_suggest),
    _PaletteItem('API', Icons.cloud_sync_outlined),
    _PaletteItem('Database', Icons.storage),
    _PaletteItem('Queue', Icons.sync_alt),
    _PaletteItem('Cache', Icons.memory),
    _PaletteItem('Auth', Icons.verified_user),
    _PaletteItem('Mobile App', Icons.phone_android),
    _PaletteItem('Web App', Icons.language),
    _PaletteItem('Admin Portal', Icons.admin_panel_settings),
    _PaletteItem('3rd-Party', Icons.link),
  ];

  ArchitectureNode _createNodeFromDrop(Offset pos, dynamic payload) {
    final label = payload is ArchitectureDragPayload
        ? payload.label
        : payload is _DocItem
            ? payload.title
            : payload.toString();
    final icon = payload is ArchitectureDragPayload
        ? payload.icon
        : payload is _DocItem
            ? payload.icon
            : null;
    return ArchitectureNode(
      id: 'n_${_nodeCounter++}',
      label: label,
      position: pos,
      color: Colors.white,
      icon: icon,
    );
  }
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final pid = provider?.projectData.projectId;
      if (pid != null && pid.isNotEmpty) {
        setState(() => _projectId = pid);
        _loadPersisted(pid);
        // Save this page as the last visited page for the project
        await ProjectNavigationService.instance.saveLastPage(pid, 'design');
      }
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPersisted(String projectId) async {
    final data = await ArchitectureService.load(projectId);
    if (data == null) return;
    try {
      final docs = (data['outputDocs'] as List?) ?? const [];
      final nodes = (data['nodes'] as List?) ?? const [];
      final edges = (data['edges'] as List?) ?? const [];

      setState(() {
        _outputDocs
          ..clear()
          ..addAll(docs.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return _DocItem(
              m['title']?.toString() ?? 'Untitled',
              icon: _iconFromCode(m['iconCode'] as int?, m['iconFont']?.toString()),
              color: _colorFromHex(m['color']?.toString()),
            );
          }));

        _nodes
          ..clear()
          ..addAll(nodes.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            final id = m['id']?.toString() ?? 'n_${_nodeCounter++}';
            final dx = (m['x'] is num) ? (m['x'] as num).toDouble() : 0.0;
            final dy = (m['y'] is num) ? (m['y'] as num).toDouble() : 0.0;
            return ArchitectureNode(
              id: id,
              label: m['label']?.toString() ?? 'Node',
              position: Offset(dx, dy),
              color: _colorFromHex(m['color']?.toString()) ?? Colors.white,
              icon: _iconFromCode(m['iconCode'] as int?, m['iconFont']?.toString()),
            );
          }));
        _nodeCounter = _nodes.fold<int>(0, (acc, n) {
          final parts = n.id.split('_');
          final maybe = int.tryParse(parts.isNotEmpty ? parts.last : '');
          return maybe != null && maybe > acc ? maybe : acc;
        }) + 1;

        _edges
          ..clear()
          ..addAll(edges.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return ArchitectureEdge(
              fromId: m['from']?.toString() ?? '',
              toId: m['to']?.toString() ?? '',
              label: m['label']?.toString() ?? '',
            );
          }));
      });
    } catch (e, st) {
      debugPrint('⚠️ Failed to parse architecture doc: $e\n$st');
    }
  }

  void _scheduleSave() {
    if (_projectId == null || _projectId!.isEmpty) return;
    _saveDebounce?.cancel();
    setState(() => _isSaving = true);
    _saveDebounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final payload = {
          'outputDocs': _outputDocs.map((d) => {
                'title': d.title,
                'iconCode': d.icon?.codePoint,
                'iconFont': d.icon?.fontFamily,
                'color': _hexFromColor(d.color),
              }).toList(),
          'nodes': _nodes.map((n) => {
                'id': n.id,
                'label': n.label,
                'x': n.position.dx,
                'y': n.position.dy,
                'iconCode': n.icon?.codePoint,
                'iconFont': n.icon?.fontFamily,
                'color': _hexFromColor(n.color),
              }).toList(),
          'edges': _edges.map((e) => {
                'from': e.fromId,
                'to': e.toId,
                'label': e.label,
              }).toList(),
        };
        await ArchitectureService.save(_projectId!, payload);
        if (mounted) {
          setState(() {
            _isSaving = false;
            _lastSavedAt = DateTime.now();
          });
        }
      } catch (e, st) {
        debugPrint('❌ Failed to save architecture: $e\n$st');
        if (mounted) setState(() => _isSaving = false);
      }
    });
  }

  static Color? _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final buffer = StringBuffer();
      var value = hex.replaceFirst('#', '').toUpperCase();
      if (value.length == 6) buffer.write('FF');
      buffer.write(value);
      final intColor = int.parse(buffer.toString(), radix: 16);
      return Color(intColor);
    } catch (_) {
      return null;
    }
  }

  static String? _hexFromColor(Color? c) {
    if (c == null) return null;
    return '#${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static IconData? _iconFromCode(int? codePoint, String? fontFamily) {
    if (codePoint == null) return null;
    return IconData(codePoint, fontFamily: fontFamily ?? 'MaterialIcons');
  }
  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = isMobile ? 16.0 : 24.0;

    return ResponsiveScaffold(
      activeItemLabel: 'Design Management',
      body: Column(
        children: [
          const PlanningPhaseHeader(title: 'Design'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notes Section
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const TextField(
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Input your notes here...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Collaborative workspace for Waterfall design and documentation',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Main Layout: Responsive - stacked on mobile, side-by-side on desktop
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Design Management',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Develop project design documentation',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        _buildManagementCards(),
                        const SizedBox(height: 24),
                        _buildEditorSection(),
                        const SizedBox(height: 24),
                        _buildDocumentsSection(),
                        const SizedBox(height: 24),
                        _buildDesignToolsSidebarSection(),
                        const SizedBox(height: 24),
                        _buildCollaboratorsSection(),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Internal Left Sidebar
                        SizedBox(
                          width: 260,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDocumentsSection(),
                              const SizedBox(height: 24),
                              _buildDesignToolsSidebarSection(),
                              const SizedBox(height: 24),
                              _buildCollaboratorsSection(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Main Content Area
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Design Management',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Develop project design documentation',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              _buildManagementCards(),
                              const SizedBox(height: 24),
                              _buildEditorSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    // Keep public signature for existing calls but forward to themed builder
    return _buildDocumentsSectionThemed(context);
  }

  Widget _buildDocumentsSectionThemed(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Documents', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${_outputDocs.length} items', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 16),
          Text('Input Documents', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 8),
          _buildDocStatic('API Design Spec', isActive: false),
          _buildDocStatic('Security Requirements', isActive: false),
          const SizedBox(height: 16),
          Text('Output Documents', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 8),
          // DragTarget to add new output docs from the Component Library
          DragTarget<ArchitectureDragPayload>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) {
              setState(() {
                final data = details.data;
                _outputDocs.add(
                  _DocItem(
                    data.label,
                    icon: data.icon ?? Icons.insert_drive_file_outlined,
                    color: Colors.blueGrey,
                  ),
                );
              });
            },
            builder: (context, candidates, rejects) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: candidates.isNotEmpty ? LightModeColors.accent.withValues(alpha: 0.2) : cs.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppSemanticColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.download_for_offline_outlined, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        candidates.isNotEmpty ? 'Release to add as Output Document' : 'Drag components here to add as Output Docs',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          ..._outputDocs.map((d) => _buildDocDraggable(d, isActive: d.title == 'System Architecture')),
        ],
      ),
    );
  }

  Widget _buildDocItem(String title, {IconData? icon, Color? color, bool isBlue = false}) {
    // Legacy static builder (kept for reference)
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isBlue ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          if (icon != null) 
            Icon(icon, size: 16, color: color ?? Colors.blue)
          else
            const SizedBox(width: 16), // Spacer if no icon to align text
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isBlue ? Colors.blue : Colors.black87,
                fontWeight: isBlue ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocStatic(String title, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocDraggable(_DocItem d, {bool isActive = false}) {
    return LongPressDraggable<_DocItem>(
      data: d,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: _docChip(d, elevated: true),
      ),
      child: _docChip(d, elevated: isActive),
    );
  }

  Widget _docChip(_DocItem d, {bool elevated = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: elevated ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(d.icon ?? Icons.insert_drive_file_outlined, size: 16, color: d.color ?? Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              d.title,
              style: TextStyle(
                fontSize: 13,
                color: elevated ? Colors.blue : Colors.black87,
                fontWeight: elevated ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDesignToolsSidebarSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Design Tools', style: TextStyle(fontWeight: FontWeight.w600)),
              const Icon(Icons.add, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text('Select to use', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 12),
          _buildToolItem('Draw.io', Icons.account_tree, isSelected: true),
          _buildToolItem('Miro', Icons.dashboard_outlined),
          _buildToolItem('Figma', Icons.design_services),
          _buildToolItem('Rich Text Editor', Icons.text_fields),
          _buildToolItem('Whiteboard', Icons.brush),
          _buildToolItem('Chart Builder', Icons.bar_chart),
        ],
      ),
    );
  }

  Widget _buildToolItem(String title, IconData icon, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.blue : Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.blue : Colors.black87,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (!isSelected)
            Icon(Icons.open_in_new, size: 14, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildCollaboratorsSection() {
    final provider = ProjectDataInherited.maybeOf(context);
    final teamMembers = provider?.projectData.teamMembers ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Collaborators', style: TextStyle(fontWeight: FontWeight.w600)),
              const Icon(Icons.add, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text('${teamMembers.length} members', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 12),
          if (teamMembers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No team members yet. Add team members in Team Management.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            )
          else
            ...teamMembers.map((member) {
              final initials = _getInitials(member.name);
              final color = _getColorForMember(member.name);
              return _buildCollaboratorItem(
                member.name,
                member.role.isNotEmpty ? member.role : 'Team Member',
                initials,
                color,
              );
            }),
        ],
      ),
    );
  }
  
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }
  
  Color _getColorForMember(String name) {
    final colors = [Colors.blue, Colors.purple, Colors.orange, Colors.teal, Colors.pink, Colors.indigo, Colors.cyan, Colors.amber];
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  Widget _buildCollaboratorItem(String name, String role, String initials, Color color, {bool isOnline = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(initials, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text(role, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          if (statusColor != null)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            )
          else if (isOnline)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManagementCards() {
    return SizedBox(
      height: 200, // Fixed height for cards
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildCard(
              title: 'Design Specifications',
              subtitle: 'Identify all applicable Industry, Company and Project specifications for each project requirement here.',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    '5',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Active requirements',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow('Defined', '3', true),
                  _buildStatusRow('Validated', '', false),
                  _buildStatusRow('Implemented', '', false),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCard(
              title: 'Design Documents',
              subtitle: 'Identify design deliverables. Create, upload and/or link them.',
              content: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildActionButton('Design Input', true)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildActionButton('Design Output', true)),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCard(
              title: 'Design Tools',
              subtitle: 'Hub for core design documents, templates, etc.',
              content: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildActionButton('Tools', true)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildActionButton('External Tools', true)),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required String subtitle, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String count, bool isBold) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (count.isNotEmpty)
            Text(
              count,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, bool isYellow) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isYellow ? const Color(0xFFFFD700) : Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEditorSection() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 620,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        children: [
          // Editor Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppSemanticColors.border)),
            ),
            child: Row(
              children: [
                const Text('System Architecture', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Text('Output Document', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppSemanticColors.successSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 14, color: AppSemanticColors.success),
                      const SizedBox(width: 4),
                      Text(
                        _isSaving
                            ? 'Saving…'
                            : _lastSavedAt != null
                                ? 'Saved'
                                : 'Ready',
                        style: const TextStyle(fontSize: 11, color: AppSemanticColors.success),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.fullscreen, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 12),
                const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
              ],
            ),
          ),
          // Editor Body
          Expanded(
            child: Row(
              children: [
                // Component Library
                Container(
                  width: 220,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: AppSemanticColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text('Component Library', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _library.length,
                          itemBuilder: (context, i) {
                            final item = _library[i];
                            final payload = ArchitectureDragPayload(item.label, icon: item.icon, color: Colors.blueGrey[50]);
                            return LongPressDraggable<ArchitectureDragPayload>(
                              data: payload,
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              feedback: Material(
                                color: Colors.transparent,
                                child: _componentTile(item, isDragging: true, showAddButton: false),
                              ),
                              child: _componentTile(
                                item,
                                showAddButton: true,
                                onAddToCanvas: () {
                                  // Add node to center of visible canvas
                                  final centerPos = Offset(200 + (_nodes.length * 40).toDouble(), 200 + (_nodes.length * 40).toDouble());
                                  final newNode = ArchitectureNode(
                                    id: 'n_[4mnodeCounter++}',
                                    label: item.label,
                                    position: centerPos,
                                    color: Colors.white,
                                    icon: item.icon,
                                  );
                                  setState(() {
                                    _nodes.add(newNode);
                                  });
                                  _scheduleSave();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tip: Click + to add to canvas, or drag to position.',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use "Connect" mode to draw workflow arrows between components.',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Canvas
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ArchitectureCanvas(
                      nodes: _nodes,
                      edges: _edges,
                      onNodesChanged: (n) => setState(() {
                        _nodes
                          ..clear()
                          ..addAll(n);
                        _scheduleSave();
                      }),
                      onEdgesChanged: (e) => setState(() {
                        _edges
                          ..clear()
                          ..addAll(e);
                        _scheduleSave();
                      }),
                      onRequestAddNodeFromDrop: (pos, payload) {
                        final node = _createNodeFromDrop(pos, payload);
                        return node;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppSemanticColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: AppSemanticColors.success),
                const SizedBox(width: 24),
                Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  _isSaving
                      ? 'Saving…'
                      : _lastSavedAt != null
                          ? 'Saved ${TimeOfDay.fromDateTime(_lastSavedAt!).format(context)}'
                          : 'No changes yet',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const Spacer(),
                Text('${_nodes.length} elements on canvas', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _componentTile(_PaletteItem item, {bool isDragging = false, bool showAddButton = false, VoidCallback? onAddToCanvas}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDragging ? LightModeColors.accent.withValues(alpha: 0.15) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: Colors.blueGrey[800]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          if (showAddButton && onAddToCanvas != null) ...[
            InkWell(
              onTap: onAddToCanvas,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.add_circle_outline, size: 18, color: LightModeColors.accent),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

class _DocItem {
  _DocItem(this.title, {this.icon, this.color});
  final String title;
  final IconData? icon;
  final Color? color;
}

class _PaletteItem {
  const _PaletteItem(this.label, this.icon);
  final String label;
  final IconData icon;
}
