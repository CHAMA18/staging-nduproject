import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show window;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/screens/requirements_implementation_screen.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/architecture_canvas.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/architecture_service.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/utils/phase_transition_helper.dart';
import 'package:ndu_project/widgets/whiteboard_canvas.dart';
import 'package:ndu_project/widgets/chart_builder_workspace.dart';
import 'package:ndu_project/widgets/text_formatting_toolbar.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ndu_project/widgets/design_management_widgets.dart';
import 'package:ndu_project/widgets/design_phase_progress_indicator.dart';
import 'package:ndu_project/services/design_phase_service.dart';
import 'package:ndu_project/models/design_phase_models.dart';

class DesignPhaseScreen extends StatefulWidget {
  const DesignPhaseScreen(
      {super.key, this.activeItemLabel = 'Design Management'});

  final String activeItemLabel;

  static void open(
    BuildContext context, {
    String activeItemLabel = 'Design Management',
    String destinationCheckpoint = 'design_management',
  }) {
    PhaseTransitionHelper.pushPhaseAware(
      context: context,
      builder: (_) => DesignPhaseScreen(activeItemLabel: activeItemLabel),
      destinationCheckpoint: destinationCheckpoint,
    );
  }

  @override
  State<DesignPhaseScreen> createState() => _DesignPhaseScreenState();
}

enum DesignTool {
  architecture,
  whiteboard,
  chartBuilder,
  richText,
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

  DesignTool _activeTool = DesignTool.architecture;
  late final TextEditingController _richTextController;
  bool _showRichPreview = true;

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

  DesignPhaseProgress? _progress;

  @override
  void initState() {
    super.initState();
    _richTextController = TextEditingController(
      text:
          '### Design Notes\n\nStart drafting your design narrative here. Use the toolbar above for quick formatting.',
    );
    _richTextController.addListener(_onRichTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final pid = provider?.projectData.projectId;
      if (pid != null && pid.isNotEmpty) {
        setState(() => _projectId = pid);
        _loadPersisted(pid);
        _loadProgress(pid);
        // Save this page as the last visited page for the project
        await ProjectNavigationService.instance.saveLastPage(pid, 'design');
      }
    });
  }

  Future<void> _loadProgress(String projectId) async {
    try {
      final progress =
          await DesignPhaseService.instance.getDesignProgress(projectId);
      if (mounted) setState(() => _progress = progress);
    } catch (e) {
      debugPrint('Error loading design progress: $e');
    }
  }

  Widget _buildDesignDashboard(double padding) {
    if (_progress == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Design Progress',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildProgressMetric('Requirements',
                      _progress!.specificationsProgress, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildProgressMetric('Alignment',
                      _progress!.alignmentProgress, Colors.purple)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildComplexityMetric(
                      'Architecture', _nodes.length, Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('${(value * 100).toInt()}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildComplexityMetric(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('$value nodes',
                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value > 0
              ? (value / 20).clamp(0.05, 1.0)
              : 0, // Mock scale of complexity
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _richTextController.removeListener(_onRichTextChanged);
    _richTextController.dispose();
    super.dispose();
  }

  void _onRichTextChanged() {
    if (!mounted) return;
    if (_showRichPreview) {
      setState(() {});
    }
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
              icon: _iconFromCode(
                  m['iconCode'] as int?, m['iconFont']?.toString()),
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
              icon: _iconFromCode(
                  m['iconCode'] as int?, m['iconFont']?.toString()),
            );
          }));
        _nodeCounter = _nodes.fold<int>(0, (acc, n) {
              final parts = n.id.split('_');
              final maybe = int.tryParse(parts.isNotEmpty ? parts.last : '');
              return maybe != null && maybe > acc ? maybe : acc;
            }) +
            1;

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
          'outputDocs': _outputDocs
              .map((d) => {
                    'title': d.title,
                    'iconCode': d.icon?.codePoint,
                    'iconFont': d.icon?.fontFamily,
                    'color': _hexFromColor(d.color),
                  })
              .toList(),
          'nodes': _nodes
              .map((n) => {
                    'id': n.id,
                    'label': n.label,
                    'x': n.position.dx,
                    'y': n.position.dy,
                    'iconCode': n.icon?.codePoint,
                    'iconFont': n.icon?.fontFamily,
                    'color': _hexFromColor(n.color),
                  })
              .toList(),
          'edges': _edges
              .map((e) => {
                    'from': e.fromId,
                    'to': e.toId,
                    'label': e.label,
                  })
              .toList(),
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
    final argb = c.value;
    return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  // Keep icon resolution to a known set so web builds can tree-shake icons safely.
  static final Map<int, IconData> _iconLookup = <int, IconData>{
    Icons.settings_suggest.codePoint: Icons.settings_suggest,
    Icons.cloud_sync_outlined.codePoint: Icons.cloud_sync_outlined,
    Icons.storage.codePoint: Icons.storage,
    Icons.sync_alt.codePoint: Icons.sync_alt,
    Icons.memory.codePoint: Icons.memory,
    Icons.verified_user.codePoint: Icons.verified_user,
    Icons.phone_android.codePoint: Icons.phone_android,
    Icons.language.codePoint: Icons.language,
    Icons.admin_panel_settings.codePoint: Icons.admin_panel_settings,
    Icons.link.codePoint: Icons.link,
    Icons.insert_drive_file_outlined.codePoint:
        Icons.insert_drive_file_outlined,
    Icons.widgets_outlined.codePoint: Icons.widgets_outlined,
  };

  static IconData? _iconFromCode(int? codePoint, String? fontFamily) {
    if (codePoint == null) return null;
    if (fontFamily != null && fontFamily != 'MaterialIcons') return null;
    return _iconLookup[codePoint];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = isMobile ? 16.0 : 24.0;

    return ResponsiveScaffold(
      activeItemLabel: widget.activeItemLabel,
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Design',
            showImportButton: false,
            showContentButton: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Move Design Dashboard inside scroll view
                  if (_projectId != null) ...[
                    _buildDesignDashboard(padding),
                    const SizedBox(height: 16),
                  ],
                  const PlanningAiNotesCard(
                    title: 'Notes',
                    sectionLabel: 'Design',
                    noteKey: 'planning_design_notes',
                    checkpoint: 'design',
                    description:
                        'Summarize design goals, artifacts, and key decisions.',
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
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
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
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Design Management',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          LaunchPhaseNavigation(
            backLabel: 'Back: Design overview',
            nextLabel: 'Next: Requirements Implementation',
            onBack: () => Navigator.of(context).maybePop(),
            onNext: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const RequirementsImplementationScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docChip(_DocItem d, {bool elevated = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            elevated ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(d.icon ?? Icons.insert_drive_file_outlined,
              size: 16, color: d.color ?? Colors.blueGrey),
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
              const Text('Design Tools',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Icon(Icons.add, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text('Select to use',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolItem(
                  'Draw.io',
                  Icons.account_tree,
                  isSelected: _activeTool == DesignTool.architecture,
                  onTap: () =>
                      setState(() => _activeTool = DesignTool.architecture),
                ),
                const SizedBox(width: 8),
                _buildToolItem(
                  'Miro',
                  Icons.dashboard_outlined,
                  onTap: () =>
                      _openToolWebView('Miro', 'https://miro.com/login/'),
                  showExternalIcon: true,
                ),
                const SizedBox(width: 8),
                _buildToolItem(
                  'Figma',
                  Icons.design_services,
                  onTap: () =>
                      _openToolWebView('Figma', 'https://www.figma.com/'),
                  showExternalIcon: true,
                ),
                const SizedBox(width: 8),
                _buildToolItem(
                  'Rich Text Editor',
                  Icons.text_fields,
                  isSelected: _activeTool == DesignTool.richText,
                  onTap: () =>
                      setState(() => _activeTool = DesignTool.richText),
                ),
                const SizedBox(width: 8),
                _buildToolItem(
                  'Whiteboard',
                  Icons.brush,
                  isSelected: _activeTool == DesignTool.whiteboard,
                  onTap: () =>
                      setState(() => _activeTool = DesignTool.whiteboard),
                ),
                const SizedBox(width: 8),
                _buildToolItem(
                  'Chart Builder',
                  Icons.bar_chart,
                  isSelected: _activeTool == DesignTool.chartBuilder,
                  onTap: () =>
                      setState(() => _activeTool = DesignTool.chartBuilder),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem(
    String title,
    IconData icon, {
    bool isSelected = false,
    VoidCallback? onTap,
    bool showExternalIcon = false,
  }) {
    final backgroundColor = isSelected
        ? Colors.blue.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.06);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18, color: isSelected ? Colors.blue : Colors.grey[700]),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.blue : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (showExternalIcon)
                Icon(Icons.open_in_new, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
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
              const Text('Collaborators',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Icon(Icons.add, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text('${teamMembers.length} members',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 12),
          if (teamMembers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No team members yet. Add team members in Team Management.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic),
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
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  Color _getColorForMember(String name) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber
    ];
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  Widget _buildCollaboratorItem(
      String name, String role, String initials, Color color,
      {bool isOnline = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(initials,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(role,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
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

  void _openToolWebView(String title, String url) {
    // For web platform, open in new tab since WebView is not supported
    if (kIsWeb) {
      // Open in new tab
      html.window.open(url, '_blank');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening $title in new tab'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // For mobile/desktop, use modal with WebView
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.public, color: Colors.grey.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              // WebView Content
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: WebViewWidget(
                    controller: WebViewController()
                      ..setJavaScriptMode(JavaScriptMode.unrestricted)
                      ..loadRequest(Uri.parse(url)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isBroad = constraints.maxWidth > 1100;
        if (isBroad) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: DesignPhaseProgressIndicator()),
              SizedBox(width: 16),
              Expanded(child: DesignDocumentsCard()),
              SizedBox(width: 16),
              Expanded(child: DesignToolsCard()),
            ],
          );
        } else {
          return const Column(
            children: [
              DesignPhaseProgressIndicator(),
              SizedBox(height: 16),
              DesignDocumentsCard(),
              SizedBox(height: 16),
              DesignToolsCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildEditorSection() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 680,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Editor Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: AppSemanticColors.border)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('System Architecture',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Design Editor · Output Document',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Live canvas',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    final node = ArchitectureNode(
                      id: 'n_${_nodeCounter++}',
                      label: 'New node',
                      position: Offset(220 + (_nodes.length * 24).toDouble(),
                          160 + (_nodes.length * 24).toDouble()),
                      color: Colors.white,
                      icon: Icons.widgets_outlined,
                    );
                    setState(() => _nodes.add(node));
                    _scheduleSave();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add node',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppSemanticColors.successSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 14, color: AppSemanticColors.success),
                      const SizedBox(width: 4),
                      Text(
                        _isSaving
                            ? 'Saving…'
                            : _lastSavedAt != null
                                ? 'Saved'
                                : 'Ready',
                        style: const TextStyle(
                            fontSize: 11, color: AppSemanticColors.success),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.fullscreen, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 12),
                const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 860;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDesignToolsSidebarSection(),
                      const SizedBox(height: 16),
                      _buildCollaboratorsSection(),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDesignToolsSidebarSection()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCollaboratorsSection()),
                  ],
                );
              },
            ),
          ),
          // Editor Body
          Expanded(
            child: Row(
              children: [
                _buildToolSidePanel(),

                // Canvas
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildActiveCanvas(),
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
                const Icon(Icons.check_circle_outline,
                    size: 16, color: AppSemanticColors.success),
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
                Text(_toolFooterLabel(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolSidePanel() {
    if (_activeTool != DesignTool.architecture) {
      return Container(
        width: 220,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: AppSemanticColors.border)),
        ),
        child: _buildToolSidebarContent(),
      );
    }
    return Container(
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
            child: Text('Component Library',
                style: TextStyle(
                    color: Colors.grey[800], fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _library.length,
              itemBuilder: (context, i) {
                final item = _library[i];
                final payload = ArchitectureDragPayload(item.label,
                    icon: item.icon, color: Colors.blueGrey[50]);
                return LongPressDraggable<ArchitectureDragPayload>(
                  data: payload,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _componentTile(item,
                        isDragging: true, showAddButton: false),
                  ),
                  child: _componentTile(
                    item,
                    showAddButton: true,
                    onAddToCanvas: () {
                      // Add node to center of visible canvas
                      final centerPos = Offset(
                          200 + (_nodes.length * 40).toDouble(),
                          200 + (_nodes.length * 40).toDouble());
                      final newNode = ArchitectureNode(
                        id: 'n_${_nodeCounter++}',
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
    );
  }

  Widget _buildToolSidebarContent() {
    switch (_activeTool) {
      case DesignTool.whiteboard:
        return _toolSidebarCard(
          title: 'Whiteboard Tips',
          lines: const [
            'Draw freely with pen or marker.',
            'Use the eraser to clean sections.',
            'Undo restores the last stroke.',
            'Clear removes everything instantly.',
          ],
        );
      case DesignTool.chartBuilder:
        return _toolSidebarCard(
          title: 'Chart Builder',
          lines: const [
            'Switch chart types in the header.',
            'Edit labels and values on the right.',
            'Add points to grow the chart.',
            'Use colors to group meaning.',
          ],
        );
      case DesignTool.richText:
        return _toolSidebarCard(
          title: 'Rich Text Editor',
          lines: const [
            'Draft narratives beside diagrams.',
            'Use headings for quick scannability.',
            'Keep key decisions highlighted.',
          ],
        );
      case DesignTool.architecture:
        return const SizedBox.shrink();
    }
  }

  Widget _toolSidebarCard(
      {required String title, required List<String> lines}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: Colors.grey[800], fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(line,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pro tip: switch tools any time - your work stays here.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCanvas() {
    switch (_activeTool) {
      case DesignTool.whiteboard:
        return const WhiteboardCanvas();
      case DesignTool.chartBuilder:
        return const ChartBuilderWorkspace();
      case DesignTool.richText:
        return _buildRichTextPlaceholder();
      case DesignTool.architecture:
        return ArchitectureCanvas(
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
        );
    }
  }

  Widget _buildRichTextPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('Rich Text Editor',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.grey[800])),
                const Spacer(),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showRichPreview = !_showRichPreview),
                  icon: Icon(
                      _showRichPreview
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 16),
                  label:
                      Text(_showRichPreview ? 'Hide preview' : 'Show preview'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormattingToolbar(controller: _richTextController),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _richTextController,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Start typing your design notes...',
                        ),
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  ),
                  if (_showRichPreview) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Markdown(
                          data: _richTextController.text,
                          shrinkWrap: true,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(Theme.of(context))
                                  .copyWith(
                            p: const TextStyle(height: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _toolFooterLabel() {
    switch (_activeTool) {
      case DesignTool.whiteboard:
        return 'Whiteboard ready for freehand sketching';
      case DesignTool.chartBuilder:
        return 'Chart builder active';
      case DesignTool.richText:
        return 'Rich text workspace ready';
      case DesignTool.architecture:
        return '${_nodes.length} elements on canvas';
    }
  }

  Widget _componentTile(_PaletteItem item,
      {bool isDragging = false,
      bool showAddButton = false,
      VoidCallback? onAddToCanvas}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDragging
            ? LightModeColors.accent.withValues(alpha: 0.15)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: Colors.blueGrey[800]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          if (showAddButton && onAddToCanvas != null) ...[
            InkWell(
              onTap: onAddToCanvas,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.add_circle_outline,
                    size: 18, color: LightModeColors.accent),
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
