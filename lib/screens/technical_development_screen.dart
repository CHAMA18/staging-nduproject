import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/providers/project_data_provider.dart';

class TechnicalDevelopmentScreen extends StatefulWidget {
  const TechnicalDevelopmentScreen({super.key});

  @override
  State<TechnicalDevelopmentScreen> createState() => _TechnicalDevelopmentScreenState();
}

class _TechnicalDevelopmentScreenState extends State<TechnicalDevelopmentScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _approachController = TextEditingController();
  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;

  // Build strategy chips data
  List<_ChipItem> _standardsChips = [];

  // Workstreams data
  List<_WorkstreamItem> _workstreams = [];

  // Readiness checklist items
  List<_ReadinessItem> _readinessItems = [];

  static const List<String> _workstreamStatusOptions = [
    'Team staffed',
    'Backlog ready',
    'Depends on vendor access',
    'In planning',
    'At risk',
    'Blocked',
  ];

  static const List<String> _readinessStatusOptions = [
    'Ready',
    'In review',
    'Partially ready',
    'Draft',
    'Blocked',
  ];

  List<String> _ownerOptions({String? currentValue}) {
    final provider = ProjectDataInherited.maybeOf(context);
    final members = provider?.projectData.teamMembers ?? [];
    final names = members
        .map((member) {
          final name = member.name.trim();
          if (name.isNotEmpty) return name;
          final email = member.email.trim();
          if (email.isNotEmpty) return email;
          return member.role.trim();
        })
        .where((value) => value.isNotEmpty)
        .toList();
    final options = names.isEmpty ? <String>['Owner'] : names.toSet().toList();
    final normalized = currentValue?.trim() ?? '';
    if (normalized.isNotEmpty && !options.contains(normalized)) {
      return [normalized, ...options];
    }
    return options;
  }

  @override
  void initState() {
    super.initState();
    _standardsChips = _defaultStandards();
    _workstreams = _defaultWorkstreams();
    _readinessItems = _defaultReadinessItems();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
    _notesController.addListener(_scheduleSave);
    _approachController.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _approachController.dispose();
    _saveDebouncer.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> _docFor(String projectId) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('design_phase_sections')
        .doc('technical_development');
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
        _approachController.text = data['approach']?.toString() ?? '';
        final chips = _ChipItem.fromList(data['standardsChips']);
        final workstreams = _WorkstreamItem.fromList(data['workstreams']);
        final readiness = _ReadinessItem.fromList(data['readinessItems']);
        _standardsChips = chips.isEmpty ? _defaultStandards() : chips;
        _workstreams = workstreams.isEmpty ? _defaultWorkstreams() : workstreams;
        _readinessItems = readiness.isEmpty ? _defaultReadinessItems() : readiness;
      });
    } catch (error) {
      debugPrint('Technical development load error: $error');
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
        'approach': _approachController.text.trim(),
        'standardsChips': _standardsChips.map((e) => e.toMap()).toList(),
        'workstreams': _workstreams.map((e) => e.toMap()).toList(),
        'readinessItems': _readinessItems.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Technical development save error: $error');
    }
  }

  List<_ChipItem> _defaultStandards() {
    return [
      _ChipItem(id: _newId(), label: 'Code guidelines defined'),
      _ChipItem(id: _newId(), label: 'Branching model agreed'),
      _ChipItem(id: _newId(), label: 'Definition of Ready'),
      _ChipItem(id: _newId(), label: 'Definition of Done'),
    ];
  }

  List<_WorkstreamItem> _defaultWorkstreams() {
    return [
      _WorkstreamItem(id: _newId(), title: 'Core platform', subtitle: 'APIs, auth, data access', status: 'Team staffed'),
      _WorkstreamItem(id: _newId(), title: 'User experience', subtitle: 'UI flows, accessibility, theming', status: 'Backlog ready'),
      _WorkstreamItem(id: _newId(), title: 'Integration build', subtitle: '3rd-party, internal systems', status: 'Depends on vendor access'),
      _WorkstreamItem(id: _newId(), title: 'Quality & automation', subtitle: 'Test suites, pipelines, tooling', status: 'In planning'),
    ];
  }

  List<_ReadinessItem> _defaultReadinessItems() {
    return [
      _ReadinessItem(id: _newId(), title: 'Critical user journeys documented', owner: 'Product', status: 'Ready'),
      _ReadinessItem(id: _newId(), title: 'Architecture & data models approved', owner: 'Lead engineer', status: 'In review'),
      _ReadinessItem(id: _newId(), title: 'Environments & pipelines available', owner: 'DevOps', status: 'Partially ready'),
      _ReadinessItem(id: _newId(), title: 'Non-functional targets agreed', owner: 'Architecture', status: 'Draft'),
    ];
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

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
              const PlanningPhaseHeader(
                title: 'Design Phase',
                showImportButton: false,
                showContentButton: false,
                showNavigationButtons: false,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                      if (_isLoading) const SizedBox(height: 16),
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
                          minLines: 1,
                          maxLines: null,
                          textAlign: TextAlign.center,
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

                      // Three Cards - stacked vertically on all screen sizes
                      Column(
                        children: [
                          _buildBuildStrategyCard(),
                          const SizedBox(height: 16),
                          _buildWorkstreamsCard(),
                          const SizedBox(height: 16),
                          _buildReadinessChecklistCard(),
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
      width: double.infinity,
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
          TextField(
            controller: _approachController,
            minLines: 1,
            maxLines: null,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Describe the delivery approach and release gates.',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          // Standards & constraints section
          Text('Standards & constraints', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[800])),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._standardsChips.map(_buildEditableChip),
              _addChipButton(onTap: _addStandardChip),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableChip(_ChipItem chip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            child: TextFormField(
              key: ValueKey('chip-${chip.id}'),
              initialValue: chip.label,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              onChanged: (value) => _updateStandardChip(chip.copyWith(label: value)),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              minLines: 1,
              maxLines: null,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
            onPressed: () => _deleteStandardChip(chip.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _addChipButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add, size: 14),
            SizedBox(width: 6),
            Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
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
          TextButton.icon(
            onPressed: _addWorkstream,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add workstream'),
          ),
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
                TextFormField(
                  key: ValueKey('workstream-title-${item.id}'),
                  initialValue: item.title,
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  minLines: 1,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  onChanged: (value) => _updateWorkstream(item.copyWith(title: value)),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  key: ValueKey('workstream-subtitle-${item.id}'),
                  initialValue: item.subtitle,
                  decoration: InputDecoration(
                    hintText: 'Describe scope',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  minLines: 1,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  onChanged: (value) => _updateWorkstream(item.copyWith(subtitle: value)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(item),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
            onPressed: () => _deleteWorkstream(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(_WorkstreamItem item) {
    final status = item.status;
    Color bgColor;
    Color dotColor;
    Color textColor;

    if (status.toLowerCase().contains('ready') || status.toLowerCase().contains('staffed')) {
      bgColor = Colors.green[50]!;
      dotColor = Colors.green;
      textColor = Colors.green[700]!;
    } else if (status.toLowerCase().contains('depends') || status.toLowerCase().contains('blocked')) {
      bgColor = Colors.orange[50]!;
      dotColor = Colors.orange;
      textColor = Colors.orange[700]!;
    } else {
      bgColor = Colors.yellow[50]!;
      dotColor = Colors.yellow[700]!;
      textColor = Colors.yellow[800]!;
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
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _workstreamStatusOptions.contains(status) ? status : _workstreamStatusOptions.first,
              items: _workstreamStatusOptions
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _updateWorkstream(item.copyWith(status: value));
              },
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
          TextButton.icon(
            onPressed: _addReadinessItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add checklist item'),
          ),
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
    final ownerOptions = _ownerOptions(currentValue: item.owner);
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
            child: TextFormField(
              key: ValueKey('readiness-title-${item.id}'),
              initialValue: item.title,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              minLines: 1,
              maxLines: null,
              textAlign: TextAlign.center,
              onChanged: (value) => _updateReadinessItem(item.copyWith(title: value)),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  value: ownerOptions.contains(item.owner.trim())
                      ? item.owner.trim()
                      : ownerOptions.first,
                  items: ownerOptions
                      .map((owner) => DropdownMenuItem(
                            value: owner,
                            child: Center(
                              child: Text(
                                owner,
                                style:
                                    TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _updateReadinessItem(item.copyWith(owner: value));
                  },
                  decoration:
                      const InputDecoration(border: InputBorder.none, isDense: true),
                  isExpanded: true,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 140,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _readinessStatusOptions.contains(item.status) ? item.status : _readinessStatusOptions.first,
                    items: _readinessStatusOptions
                        .map((status) => DropdownMenuItem(value: status, child: Text(status, style: TextStyle(fontSize: 11, color: Colors.grey[600]))))
                        .toList(),
                    onChanged: (value) => _updateReadinessItem(item.copyWith(status: value ?? _readinessStatusOptions.first)),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
            onPressed: () => _deleteReadinessItem(item.id),
          ),
        ],
      ),
    );
  }

  void _addStandardChip() {
    setState(() {
      _standardsChips.add(_ChipItem(id: _newId(), label: ''));
    });
    _scheduleSave();
  }

  void _updateStandardChip(_ChipItem chip) {
    final index = _standardsChips.indexWhere((item) => item.id == chip.id);
    if (index == -1) return;
    setState(() => _standardsChips[index] = chip);
    _scheduleSave();
  }

  void _deleteStandardChip(String id) {
    setState(() => _standardsChips.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addWorkstream() {
    setState(() {
      _workstreams.add(_WorkstreamItem(
        id: _newId(),
        title: '',
        subtitle: '',
        status: _workstreamStatusOptions.first,
      ));
    });
    _scheduleSave();
  }

  void _updateWorkstream(_WorkstreamItem item) {
    final index = _workstreams.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    setState(() => _workstreams[index] = item);
    _scheduleSave();
  }

  void _deleteWorkstream(String id) {
    setState(() => _workstreams.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addReadinessItem() {
    setState(() {
      _readinessItems.add(_ReadinessItem(
        id: _newId(),
        title: '',
        owner: '',
        status: _readinessStatusOptions.first,
      ));
    });
    _scheduleSave();
  }

  void _updateReadinessItem(_ReadinessItem item) {
    final index = _readinessItems.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    setState(() => _readinessItems[index] = item);
    _scheduleSave();
  }

  void _deleteReadinessItem(String id) {
    setState(() => _readinessItems.removeWhere((item) => item.id == id));
    _scheduleSave();
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

class _WorkstreamItem {
  final String id;
  final String title;
  final String subtitle;
  final String status;

  _WorkstreamItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  _WorkstreamItem copyWith({String? title, String? subtitle, String? status}) {
    return _WorkstreamItem(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'status': status,
      };

  static List<_WorkstreamItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _WorkstreamItem(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
        status: map['status']?.toString() ?? 'In planning',
      );
    }).toList();
  }
}

class _ReadinessItem {
  final String id;
  final String title;
  final String owner;
  final String status;

  _ReadinessItem({
    required this.id,
    required this.title,
    required this.owner,
    required this.status,
  });

  _ReadinessItem copyWith({String? title, String? owner, String? status}) {
    return _ReadinessItem(
      id: id,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'owner': owner,
        'status': status,
      };

  static List<_ReadinessItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ReadinessItem(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Draft',
      );
    }).toList();
  }
}

class _ChipItem {
  final String id;
  final String label;

  _ChipItem({required this.id, required this.label});

  _ChipItem copyWith({String? label}) => _ChipItem(id: id, label: label ?? this.label);

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
      };

  static List<_ChipItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ChipItem(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
      );
    }).toList();
  }
}

class _Debouncer {
  _Debouncer({Duration? delay}) : delay = delay ?? const Duration(milliseconds: 700);

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
