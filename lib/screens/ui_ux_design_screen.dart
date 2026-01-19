import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/screens/backend_design_screen.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class UiUxDesignScreen extends StatefulWidget {
  const UiUxDesignScreen({super.key});

  @override
  State<UiUxDesignScreen> createState() => _UiUxDesignScreenState();
}

class _UiUxDesignScreenState extends State<UiUxDesignScreen> {
  final TextEditingController _notesController = TextEditingController();
  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;
  bool _didSeedDefaults = false;

  // Primary user journeys data
  List<_JourneyItem> _journeys = [];

  // Interface structure data
  List<_InterfaceItem> _interfaces = [];

  // Design system elements data
  List<_DesignElement> _coreTokens = [];
  List<_DesignElement> _keyComponents = [];

  static const List<String> _journeyStatusOptions = [
    'Mapped',
    'Draft',
    'Planned',
    'In progress',
  ];

  static const List<String> _interfaceStateOptions = [
    'Wireframe',
    'User flow map',
    'To define',
    'Prototype',
    'Final',
  ];

  static const List<String> _elementStatusOptions = [
    'Ready',
    'Draft',
    'In review',
    'Planned',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _saveDebouncer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _journeys = _defaultJourneys();
    _interfaces = _defaultInterfaces();
    _coreTokens = _defaultCoreTokens();
    _keyComponents = _defaultKeyComponents();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
    _notesController.addListener(_scheduleSave);
  }

  DocumentReference<Map<String, dynamic>> _docFor(String projectId) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('design_phase_sections')
        .doc('ui_ux_design');
  }

  void _scheduleSave() {
    if (_suspendSave) return;
    _saveDebouncer.run(_saveToFirestore);
  }

  Future<void> _loadFromFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final doc = await _docFor(projectId).get();
      final data = doc.data() ?? {};
      _suspendSave = true;
      if (!mounted) return;
      setState(() {
        _notesController.text = data['notes']?.toString() ?? '';
        final journeys = _JourneyItem.fromList(data['journeys']);
        final interfaces = _InterfaceItem.fromList(data['interfaces']);
        final coreTokens = _DesignElement.fromList(data['coreTokens']);
        final keyComponents = _DesignElement.fromList(data['keyComponents']);
        _journeys = journeys.isEmpty ? _defaultJourneys() : journeys;
        _interfaces = interfaces.isEmpty ? _defaultInterfaces() : interfaces;
        _coreTokens = coreTokens.isEmpty ? _defaultCoreTokens() : coreTokens;
        _keyComponents = keyComponents.isEmpty ? _defaultKeyComponents() : keyComponents;
      });
    } catch (error) {
      debugPrint('UI/UX design load error: $error');
    } finally {
      _suspendSave = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    try {
      await _docFor(projectId).set({
        'notes': _notesController.text.trim(),
        'journeys': _journeys.map((e) => e.toMap()).toList(),
        'interfaces': _interfaces.map((e) => e.toMap()).toList(),
        'coreTokens': _coreTokens.map((e) => e.toMap()).toList(),
        'keyComponents': _keyComponents.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('UI/UX design save error: $error');
    }
  }

  List<_JourneyItem> _defaultJourneys() {
    return [
      _JourneyItem(
        id: _newId(),
        title: 'Onboard & first value',
        description: 'From sign-up to experiencing the first meaningful outcome.',
        status: 'Mapped',
      ),
      _JourneyItem(
        id: _newId(),
        title: 'Core task completion',
        description: 'Critical path to complete the main job-to-be-done.',
        status: 'Draft',
      ),
      _JourneyItem(
        id: _newId(),
        title: 'Support & recovery',
        description: 'Error states, help entry points, and escalation paths.',
        status: 'Planned',
      ),
    ];
  }

  List<_InterfaceItem> _defaultInterfaces() {
    return [
      _InterfaceItem(
        id: _newId(),
        area: 'Dashboard',
        purpose: 'One-glance status and key shortcuts into primary actions.',
        state: 'Wireframe',
      ),
      _InterfaceItem(
        id: _newId(),
        area: 'Workflows',
        purpose: 'Step-by-step guidance for complex, multi-screen tasks.',
        state: 'User flow map',
      ),
      _InterfaceItem(
        id: _newId(),
        area: 'Settings & admin',
        purpose: 'Configuration, access management, and audit history.',
        state: 'To define',
      ),
    ];
  }

  List<_DesignElement> _defaultCoreTokens() {
    return [
      _DesignElement(
        id: _newId(),
        title: 'Color & typography',
        description: 'Brand palette, semantic roles, hierarchy, spacing scale.',
        status: 'Ready',
      ),
      _DesignElement(
        id: _newId(),
        title: 'Interactions & feedback',
        description: 'Loading, success, warning, error, and empty states.',
        status: 'Draft',
      ),
    ];
  }

  List<_DesignElement> _defaultKeyComponents() {
    return [
      _DesignElement(
        id: _newId(),
        title: 'Navigation system',
        description: 'Primary, secondary, and breadcrumb navigation patterns.',
        status: 'Planned',
      ),
    ];
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _exportPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text('UI/UX Specification', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text('Notes', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text(_notesController.text.trim().isEmpty ? 'No notes provided.' : _notesController.text.trim()),
          pw.SizedBox(height: 16),
          _pdfSection('Primary user journeys', _journeys.map((j) => '${j.title} — ${j.description} (${j.status})').toList()),
          _pdfSection('Interface structure', _interfaces.map((i) => '${i.area} — ${i.purpose} (${i.state})').toList()),
          _pdfSection('Core tokens', _coreTokens.map((e) => '${e.title} — ${e.description} (${e.status})').toList()),
          _pdfSection('Key components', _keyComponents.map((e) => '${e.title} — ${e.description} (${e.status})').toList()),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'ui-ux-specification.pdf',
    );
  }

  pw.Widget _pdfSection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        if (items.isEmpty)
          pw.Text('No entries.', style: const pw.TextStyle(fontSize: 12))
        else
          pw.Column(
            children: items.map((item) => pw.Bullet(text: item)).toList(),
          ),
        pw.SizedBox(height: 12),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);

    if (!_isLoading &&
        !_suspendSave &&
        !_didSeedDefaults &&
        _journeys.isEmpty &&
        _interfaces.isEmpty &&
        _coreTokens.isEmpty &&
        _keyComponents.isEmpty) {
      _didSeedDefaults = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _journeys = _defaultJourneys();
          _interfaces = _defaultInterfaces();
          _coreTokens = _defaultCoreTokens();
          _keyComponents = _defaultKeyComponents();
        });
        _scheduleSave();
      });
    }

    return ResponsiveScaffold(
      activeItemLabel: 'UI/UX Design',
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Design Phase',
            showImportButton: false,
            showContentButton: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  Text(
                    'UI/UX Design',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: LightModeColors.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture only the critical screens, flows, and components so teams can implement a consistent experience without over-designing.',
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
                        hintText: 'Input your notes here... (target users, accessibility constraints, brand rules, must-have journeys)',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text('Loading UI/UX data...', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Helper Text
                  Text(
                    'Focus on high-impact touchpoints first: how users discover, complete core tasks, and get support.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Three Cards - stacked layout
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPrimaryUserJourneysCard(),
                      const SizedBox(height: 16),
                      _buildInterfaceStructureCard(),
                      const SizedBox(height: 16),
                      _buildDesignSystemElementsCard(),
                    ],
                  ),
                  const SizedBox(height: 32),
                  LaunchPhaseNavigation(
                    backLabel: 'Back: Technical alignment',
                    nextLabel: 'Next: Backend design',
                    onBack: () => Navigator.of(context).maybePop(),
                    onNext: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackendDesignScreen())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryUserJourneysCard() {
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
          const Text('Primary user journeys', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('What users need to accomplish end-to-end', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ..._journeys.map((j) => _buildJourneyItem(j)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _journeys.add(_JourneyItem(id: _newId(), title: '', description: '', status: _journeyStatusOptions.first));
              });
              _scheduleSave();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add journey', style: TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyItem(_JourneyItem journey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: ValueKey('journey-title-${journey.id}'),
                  initialValue: journey.title,
                  decoration: _inlineInputDecoration('Journey title'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  onChanged: (value) {
                    journey.title = value;
                    _scheduleSave();
                  },
                ),
                const SizedBox(height: 2),
                TextFormField(
                  key: ValueKey('journey-desc-${journey.id}'),
                  initialValue: journey.description,
                  minLines: 1,
                  maxLines: null,
                  decoration: _inlineInputDecoration('Describe the journey'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  onChanged: (value) {
                    journey.description = value;
                    _scheduleSave();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _journeyStatusOptions.contains(journey.status)
                    ? journey.status
                    : _journeyStatusOptions.first,
                items: _journeyStatusOptions
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => journey.status = value);
                  _scheduleSave();
                },
                decoration: _inlineInputDecoration('Status'),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: () {
                  setState(() => _journeys.removeWhere((item) => item.id == journey.id));
                  _scheduleSave();
                },
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceStructureCard() {
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
          const Text('Interface structure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('How screens connect and what each view owns', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          // Table Header
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Area', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              ),
              Expanded(
                flex: 3,
                child: Text('Purpose', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              ),
              Expanded(
                flex: 2,
                child: Text('State', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const Divider(height: 16),
          ..._interfaces.map((i) => _buildInterfaceRow(i)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _interfaces.add(_InterfaceItem(id: _newId(), area: '', purpose: '', state: _interfaceStateOptions.first));
              });
              _scheduleSave();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add area', style: TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceRow(_InterfaceItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('interface-area-${item.id}'),
              initialValue: item.area,
              decoration: _inlineInputDecoration('Area'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              onChanged: (value) {
                item.area = value;
                _scheduleSave();
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              key: ValueKey('interface-purpose-${item.id}'),
              initialValue: item.purpose,
              minLines: 1,
              maxLines: null,
              decoration: _inlineInputDecoration('Purpose'),
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              onChanged: (value) {
                item.purpose = value;
                _scheduleSave();
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: _interfaceStateOptions.contains(item.state) ? item.state : _interfaceStateOptions.first,
              items: _interfaceStateOptions
                  .map((state) => DropdownMenuItem(value: state, child: Text(state)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => item.state = value);
                _scheduleSave();
              },
              decoration: _inlineInputDecoration('State'),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _interfaces.removeWhere((entry) => entry.id == item.id));
              _scheduleSave();
            },
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignSystemElementsCard() {
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
          const Text('Design system elements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Tokens, components, and states the build will rely on', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),

          // Core tokens section
          Text('Core tokens', style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ..._coreTokens.map((e) => _buildDesignElementItem(e, list: _coreTokens)),
          const SizedBox(height: 16),

          // Key components section
          Text('Key components', style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            'List the minimum set of reusable components (navigation, cards, forms, modals) that must be finalized before development starts.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          ..._keyComponents.map((e) => _buildDesignElementItem(e, list: _keyComponents)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _keyComponents.add(_DesignElement(id: _newId(), title: '', description: '', status: _elementStatusOptions.first));
              });
              _scheduleSave();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add item', style: TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          const SizedBox(height: 16),

          // Export button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export UI/UX specification'),
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

  Widget _buildDesignElementItem(_DesignElement element, {required List<_DesignElement> list}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: ValueKey('element-title-${element.id}'),
                  initialValue: element.title,
                  decoration: _inlineInputDecoration('Element'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  onChanged: (value) {
                    element.title = value;
                    _scheduleSave();
                  },
                ),
                const SizedBox(height: 2),
                TextFormField(
                  key: ValueKey('element-desc-${element.id}'),
                  initialValue: element.description,
                  minLines: 1,
                  maxLines: null,
                  decoration: _inlineInputDecoration('Description'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  onChanged: (value) {
                    element.description = value;
                    _scheduleSave();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _elementStatusOptions.contains(element.status)
                    ? element.status
                    : _elementStatusOptions.first,
                items: _elementStatusOptions
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => element.status = value);
                  _scheduleSave();
                },
                decoration: _inlineInputDecoration('Status'),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: () {
                  setState(() => list.removeWhere((entry) => entry.id == element.id));
                  _scheduleSave();
                },
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // _buildBottomNavigation removed — replaced by the shared LaunchPhaseNavigation in the main build.
}

InputDecoration _inlineInputDecoration(String hint) {
  return InputDecoration(
    isDense: true,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
    ),
  );
}

class _Debouncer {
  _Debouncer({Duration? delay}) : delay = delay ?? const Duration(milliseconds: 600);

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class _JourneyItem {
  final String id;
  String title;
  String description;
  String status;

  _JourneyItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status,
      };

  static List<_JourneyItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _JourneyItem(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Draft',
      );
    }).toList();
  }
}

class _InterfaceItem {
  final String id;
  String area;
  String purpose;
  String state;

  _InterfaceItem({
    required this.id,
    required this.area,
    required this.purpose,
    required this.state,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'area': area,
        'purpose': purpose,
        'state': state,
      };

  static List<_InterfaceItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _InterfaceItem(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        area: map['area']?.toString() ?? '',
        purpose: map['purpose']?.toString() ?? '',
        state: map['state']?.toString() ?? 'To define',
      );
    }).toList();
  }
}

class _DesignElement {
  final String id;
  String title;
  String description;
  String status;

  _DesignElement({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status,
      };

  static List<_DesignElement> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _DesignElement(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Draft',
      );
    }).toList();
  }
}
