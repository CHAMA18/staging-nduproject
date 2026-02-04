import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/services/integration_oauth_service.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/theme.dart';

class ToolsIntegrationScreen extends StatefulWidget {
  const ToolsIntegrationScreen({super.key});

  static void open(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ToolsIntegrationScreen()),
  );

  @override
  State<ToolsIntegrationScreen> createState() => _ToolsIntegrationScreenState();
}

class _ToolsIntegrationScreenState extends State<ToolsIntegrationScreen> {
  int _selectedPhase = 1; // Phase 2 is selected by default (0-indexed)

  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;
  
  // Mock data for integrations
  List<_IntegrationItem> _integrations = [
    _IntegrationItem(
      id: 'figma',
      provider: IntegrationProvider.figma,
      name: 'Figma integration',
      subtitle: 'Design files',
      icon: Icons.design_services,
      iconColor: const Color(0xFFF24E1E),
      scopes: 'files:read, files:write, comments',
      features: 'Project mapping enabled.',
      status: 'Connected',
      statusColor: Colors.green,
      mapsTo: 'Epics, stories',
      autoHandoff: 'ON',
      lastSync: 'Last token refresh: 1 hr ago',
    ),
    _IntegrationItem(
      id: 'drawio',
      provider: IntegrationProvider.drawio,
      name: 'Draw.io integration',
      subtitle: 'Architecture diagrams',
      icon: Icons.account_tree,
      iconColor: const Color(0xFFFF6D00),
      scopes: 'diagrams:read',
      features: 'Change detection enabled with retries.',
      status: 'Degraded - retrying',
      statusColor: Colors.orange,
      mapsTo: 'Tech specs',
      syncMode: 'scheduled',
      errorInfo: '2 errors in last hour',
    ),
    _IntegrationItem(
      id: 'miro',
      provider: IntegrationProvider.miro,
      name: 'Miro integration',
      subtitle: 'Workshops & ideation',
      icon: Icons.dashboard,
      iconColor: const Color(0xFFFFD02F),
      scopes: 'boards:read, comments',
      features: 'Cluster-to-epic mapping.',
      status: 'Connected',
      statusColor: Colors.green,
      mapsTo: 'Requirements',
      autoSummary: 'ON',
      events: 'Events: 34 / min',
    ),
    _IntegrationItem(
      id: 'whiteboard',
      provider: IntegrationProvider.whiteboard,
      name: 'Whiteboard integration',
      subtitle: 'Live sessions',
      icon: Icons.sticky_note_2,
      iconColor: const Color(0xFF0078D4),
      scopes: 'sessions:read',
      features: 'Outputs pushed to notes & actions.',
      status: 'Connected',
      statusColor: Colors.green,
      mapsTo: 'Decisions, actions',
      autoTranscribe: 'ON',
      sessions: 'Sessions today: 3',
    ),
  ];

  List<_StatItem> _stats = [];

  static const List<String> _statusOptions = [
    'Connected',
    'Degraded',
    'Not connected',
    'Expired',
    'Paused',
  ];

  @override
  void initState() {
    super.initState();
    _stats = _defaultStats();
    _refreshIntegrationStatuses();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }

  InputDecoration _inlineDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
      ),
    );
  }

  DocumentReference<Map<String, dynamic>> _docFor(String projectId) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('design_phase_sections')
        .doc('tools_integration');
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
        final stats = _StatItem.fromList(data['stats']);
        final integrations = _IntegrationItem.fromList(data['integrations']);
        _stats = stats.isEmpty ? _defaultStats() : stats;
        _integrations = integrations.isEmpty ? _integrations : integrations;
      });
    } catch (error) {
      debugPrint('Tools integration load error: $error');
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
        'stats': _stats.map((e) => e.toMap()).toList(),
        'integrations': _integrations.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Tools integration save error: $error');
    }
  }

  List<_StatItem> _defaultStats() {
    return [
      _StatItem(id: 'connected_tools', label: 'Connected tools', value: '4 / 4 healthy', valueColor: Colors.green),
      _StatItem(id: 'health_score', label: 'Integration health score', value: '92 / 100', valueColor: const Color(0xFF0EA5E9)),
      _StatItem(id: 'last_sync', label: 'Last full sync', value: '09:42 · every 15 min', valueColor: Colors.grey),
      _StatItem(id: 'open_issues', label: 'Open integration issues', value: '4 items', valueColor: Colors.orange),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const InitiationLikeSidebar(activeItemLabel: 'Tools Integration'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isNarrow ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                  if (_isLoading) const SizedBox(height: 16),
                  _buildHeader(isNarrow),
                  const SizedBox(height: 24),
                  _buildToolConnectionManager(isNarrow),
                  const SizedBox(height: 24),
                  _buildBottomNavigation(isNarrow),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshIntegrationStatuses() async {
    final service = IntegrationOAuthService.instance;
    for (var i = 0; i < _integrations.length; i++) {
      final state = await service.loadState(_integrations[i].provider);
      _integrations[i] = _applyAuthState(_integrations[i], state);
    }
    if (mounted) {
      setState(() {});
      _scheduleSave();
    }
  }

  _IntegrationItem _applyAuthState(_IntegrationItem item, IntegrationAuthState state) {
    final status = state.connected
        ? 'Connected'
        : state.hasToken
            ? 'Expired'
            : 'Not connected';
    final statusColor = state.connected
        ? Colors.green
        : state.hasToken
            ? Colors.orange
            : Colors.grey;
    final lastSync = state.updatedAt == null
        ? item.lastSync
        : 'Token refresh: ${_formatRelativeTime(state.updatedAt!)}';

    return item.copyWith(
      status: status,
      statusColor: statusColor,
      lastSync: lastSync,
    );
  }

  void _addIntegration() {
    setState(() {
      _integrations.add(_IntegrationItem(
        id: _newId(),
        provider: IntegrationProvider.figma,
        name: '',
        subtitle: '',
        icon: Icons.link,
        iconColor: const Color(0xFF94A3B8),
        scopes: '',
        features: '',
        status: _statusOptions.first,
        statusColor: Colors.grey,
        mapsTo: '',
        autoHandoff: null,
        autoSummary: null,
        autoTranscribe: null,
        syncMode: null,
        lastSync: null,
        errorInfo: null,
        events: null,
        sessions: null,
      ));
    });
    _scheduleSave();
  }

  void _updateIntegration(_IntegrationItem item) {
    final index = _integrations.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    setState(() => _integrations[index] = item);
    _scheduleSave();
  }

  void _deleteIntegration(String id) {
    setState(() => _integrations.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _updateStat(_StatItem stat) {
    final index = _stats.indexWhere((entry) => entry.id == stat.id);
    if (index == -1) return;
    setState(() => _stats[index] = stat);
    _scheduleSave();
  }

  void _deleteStat(String id) {
    setState(() => _stats.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addStat() {
    setState(() {
      _stats.add(_StatItem(
        id: _newId(),
        label: '',
        value: '',
        valueColor: Colors.grey,
      ));
    });
    _scheduleSave();
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Widget _buildHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Design Integration Control Center',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monitor integration health, configure scopes, and coordinate sync rules across your design stack.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
        ),
        if (isNarrow) ...[
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ],
    );
  }

  Widget _buildBrandMark() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const AppLogo(height: 30, width: 120),
    );
  }

  Widget _buildPhaseTabs() {
    final phases = [
      'Phase 1 · Team & alignment',
      'Phase 2 · Delivery engine',
      'Phase 3 · Readiness',
      'Phase 4 · Closure',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(phases.length, (index) {
          final isSelected = _selectedPhase == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedPhase = index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0EA5E9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  phases[index],
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

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search tools, connections, logs...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildActionButton(Icons.add, 'Connect new tool', onTap: () {}),
        _buildActionButton(Icons.tune, 'Edit integration rules', onTap: () {}),
        _buildActionButton(Icons.warning_amber, 'View incidents', onTap: () {}),
        _buildPrimaryActionButton('Run manual sync', onTap: () {}),
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
            const Icon(Icons.sync, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isNarrow) {
    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _stats.map((stat) => _buildStatChip(stat, flex: false)).toList(),
      );
    }

    return Row(
      children: _stats.map((stat) => Expanded(child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: _buildStatChip(stat),
      ))).toList(),
    );
  }

  Widget _buildStatChip(_StatItem stat, {bool flex = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: flex ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey('stat-label-${stat.id}'),
              initialValue: stat.label,
              decoration: _inlineDecoration('Label'),
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              onChanged: (value) => _updateStat(stat.copyWith(label: value)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: TextFormField(
              key: ValueKey('stat-value-${stat.id}'),
              initialValue: stat.value,
              decoration: _inlineDecoration('Value'),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: stat.valueColor),
              textAlign: TextAlign.right,
              onChanged: (value) => _updateStat(stat.copyWith(value: value)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
            onPressed: () => _deleteStat(stat.id),
          ),
        ],
      ),
    );
  }

  Widget _buildToolConnectionManager(bool isNarrow) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tool connection manager',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review and manage each integration\'s configuration, scopes, and status.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit all'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _addIntegration,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add integration'),
          ),
          ..._integrations.asMap().entries.map((entry) => _buildIntegrationCard(entry.value, isNarrow, entry.key)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Use the connection manager to adjust scopes, rotate credentials, and pause integrations safely.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Open integration settings',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0EA5E9)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isNarrow) {
    const accent = LightModeColors.lightPrimary;
    const onAccent = Colors.white;
    return Column(
      children: [
        const Divider(height: 1),
        const SizedBox(height: 16),
        if (isNarrow)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Design phase · Tools integration',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/${AppRoutes.technicalDevelopment}'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back: Technical Development'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: const BorderSide(color: accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  foregroundColor: onAccent,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    context.push('/${AppRoutes.uiUxDesign}'),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next: UI/UX Design'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: onAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/${AppRoutes.technicalDevelopment}'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back: Technical Development'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: const BorderSide(color: accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  foregroundColor: onAccent,
                ),
              ),
              const SizedBox(width: 16),
              Text('Design phase · Tools integration',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () =>
                    context.push('/${AppRoutes.uiUxDesign}'),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next: UI/UX Design'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: onAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildIntegrationCard(_IntegrationItem item, bool isNarrow, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: isNarrow ? _buildNarrowCard(item, index) : _buildWideCard(item, index),
    );
  }

  Widget _buildWideCard(_IntegrationItem item, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: item.iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('integration-name-${item.id}'),
                      initialValue: item.name,
                      decoration: _inlineDecoration('Integration name'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F)),
                      onChanged: (value) => _updateIntegration(item.copyWith(name: value)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('integration-subtitle-${item.id}'),
                      initialValue: item.subtitle,
                      decoration: _inlineDecoration('Scope'),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      onChanged: (value) => _updateIntegration(item.copyWith(subtitle: value)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('integration-scopes-${item.id}'),
                      initialValue: item.scopes,
                      decoration: _inlineDecoration('Scopes'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      onChanged: (value) => _updateIntegration(item.copyWith(scopes: value)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('integration-features-${item.id}'),
                      initialValue: item.features,
                      decoration: _inlineDecoration('Features'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      onChanged: (value) => _updateIntegration(item.copyWith(features: value)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildMetaRow(item),
              const SizedBox(height: 6),
              _buildMappingRow(item),
            ],
          ),
        ),
        Column(
          children: [
            OutlinedButton(
              onPressed: () => _deleteIntegration(item.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Remove', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowCard(_IntegrationItem item, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    key: ValueKey('integration-name-narrow-${item.id}'),
                    initialValue: item.name,
                    decoration: _inlineDecoration('Integration name'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    onChanged: (value) => _updateIntegration(item.copyWith(name: value)),
                  ),
                  TextFormField(
                    key: ValueKey('integration-subtitle-narrow-${item.id}'),
                    initialValue: item.subtitle,
                    decoration: _inlineDecoration('Scope'),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    onChanged: (value) => _updateIntegration(item.copyWith(subtitle: value)),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(item),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: item.scopes,
          decoration: _inlineDecoration('Scopes'),
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          onChanged: (value) => _updateIntegration(item.copyWith(scopes: value)),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: item.features,
          decoration: _inlineDecoration('Features'),
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          onChanged: (value) => _updateIntegration(item.copyWith(features: value)),
        ),
        const SizedBox(height: 8),
        _buildMappingRow(item),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _deleteIntegration(item.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: const Text('Remove'),
          ),
        ),
      ],
    );
  }

  Future<void> _openIntegrationConfig(_IntegrationItem item, int index) async {
    final service = IntegrationOAuthService.instance;
    final clientConfig = await service.loadClientConfig(item.provider);
    final authState = await service.loadState(item.provider);
    final config = service.configFor(item.provider);

    final scopesController = TextEditingController(text: item.scopes);
    final mapsToController = TextEditingController(text: item.mapsTo);
    final clientIdController = TextEditingController(text: clientConfig.clientId ?? '');
    final clientSecretController = TextEditingController(text: clientConfig.clientSecret ?? '');
    String? syncMode = item.syncMode;
    bool autoHandoff = (item.autoHandoff ?? '').toLowerCase() == 'on';
    bool autoSummary = (item.autoSummary ?? '').toLowerCase() == 'on';
    bool autoTranscribe = (item.autoTranscribe ?? '').toLowerCase() == 'on';
    bool isConnecting = false;
    String? authError;

    _IntegrationItem? updated;
    try {
      updated = await showDialog<_IntegrationItem>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final statusLabel = authState.connected
                  ? 'Connected'
                  : authState.hasToken
                      ? 'Expired'
                      : 'Not connected';
              final statusColor = authState.connected
                  ? Colors.green
                  : authState.hasToken
                      ? Colors.orange
                      : Colors.grey;

              return AlertDialog(
                title: Text('${item.name} configuration'),
                content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Status: $statusLabel', style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                            ),
                            const Spacer(),
                            Text(
                              'Redirect URI: ${config.redirectUri}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: clientIdController,
                          decoration: const InputDecoration(
                            labelText: 'Client ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: clientSecretController,
                          decoration: const InputDecoration(
                            labelText: 'Client Secret (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: scopesController,
                          decoration: const InputDecoration(
                            labelText: 'Scopes',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: mapsToController,
                          decoration: const InputDecoration(
                            labelText: 'Maps to',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (item.syncMode != null) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: syncMode,
                            decoration: const InputDecoration(
                              labelText: 'Sync mode',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                              DropdownMenuItem(value: 'manual', child: Text('Manual')),
                              DropdownMenuItem(value: 'continuous', child: Text('Continuous')),
                            ],
                            onChanged: (value) => setDialogState(() => syncMode = value),
                          ),
                        ],
                        if (item.autoHandoff != null) ...[
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            value: autoHandoff,
                            onChanged: (value) => setDialogState(() => autoHandoff = value),
                            title: const Text('Auto-handoff'),
                          ),
                        ],
                        if (item.autoSummary != null) ...[
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            value: autoSummary,
                            onChanged: (value) => setDialogState(() => autoSummary = value),
                            title: const Text('Auto-summary'),
                          ),
                        ],
                        if (item.autoTranscribe != null) ...[
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            value: autoTranscribe,
                            onChanged: (value) => setDialogState(() => autoTranscribe = value),
                            title: const Text('Auto-transcribe'),
                          ),
                        ],
                        if ((authError ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(authError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  if (authState.connected)
                    TextButton(
                      onPressed: () async {
                        await service.disconnect(item.provider);
                        final updatedItem = item.copyWith(
                          status: 'Not connected',
                          statusColor: Colors.grey,
                          lastSync: null,
                          scopes: scopesController.text.trim().isEmpty ? item.scopes : scopesController.text.trim(),
                          mapsTo: mapsToController.text.trim().isEmpty ? item.mapsTo : mapsToController.text.trim(),
                          syncMode: item.syncMode != null ? (syncMode ?? item.syncMode) : null,
                          autoHandoff: item.autoHandoff != null ? (autoHandoff ? 'ON' : 'OFF') : null,
                          autoSummary: item.autoSummary != null ? (autoSummary ? 'ON' : 'OFF') : null,
                          autoTranscribe: item.autoTranscribe != null ? (autoTranscribe ? 'ON' : 'OFF') : null,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop(updatedItem);
                      },
                      child: const Text('Disconnect'),
                    )
                  else
                    FilledButton(
                      onPressed: isConnecting
                          ? null
                          : () async {
                              final clientId = clientIdController.text.trim();
                              if (clientId.isEmpty) {
                                setDialogState(() => authError = 'Client ID is required.');
                                return;
                              }
                              setDialogState(() {
                                authError = null;
                                isConnecting = true;
                              });
                              try {
                                await service.saveClientConfig(
                                  provider: item.provider,
                                  clientId: clientId,
                                  clientSecret: clientSecretController.text.trim(),
                                );
                                final scopes = _parseScopes(scopesController.text);
                                final state = await service.connect(
                                  provider: item.provider,
                                  clientId: clientId,
                                  clientSecret: clientSecretController.text.trim(),
                                  scopesOverride: scopes,
                                );
                                final updatedItem = item.copyWith(
                                  status: state.connected ? 'Connected' : 'Not connected',
                                  statusColor: state.connected ? Colors.green : Colors.grey,
                                  lastSync: state.updatedAt == null ? item.lastSync : 'Token refresh: ${_formatRelativeTime(state.updatedAt!)}',
                                  scopes: scopesController.text.trim().isEmpty ? item.scopes : scopesController.text.trim(),
                                  mapsTo: mapsToController.text.trim().isEmpty ? item.mapsTo : mapsToController.text.trim(),
                                  syncMode: item.syncMode != null ? (syncMode ?? item.syncMode) : null,
                                  autoHandoff: item.autoHandoff != null ? (autoHandoff ? 'ON' : 'OFF') : null,
                                  autoSummary: item.autoSummary != null ? (autoSummary ? 'ON' : 'OFF') : null,
                                  autoTranscribe: item.autoTranscribe != null ? (autoTranscribe ? 'ON' : 'OFF') : null,
                                );
                                if (!dialogContext.mounted) return;
                                Navigator.of(dialogContext).pop(updatedItem);
                              } catch (e) {
                                setDialogState(() => authError = e.toString());
                              } finally {
                                if (dialogContext.mounted) {
                                  setDialogState(() => isConnecting = false);
                                }
                              }
                            },
                      child: isConnecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      final updatedItem = item.copyWith(
                        scopes: scopesController.text.trim().isEmpty ? item.scopes : scopesController.text.trim(),
                        mapsTo: mapsToController.text.trim().isEmpty ? item.mapsTo : mapsToController.text.trim(),
                        syncMode: item.syncMode != null ? (syncMode ?? item.syncMode) : null,
                        autoHandoff: item.autoHandoff != null ? (autoHandoff ? 'ON' : 'OFF') : null,
                        autoSummary: item.autoSummary != null ? (autoSummary ? 'ON' : 'OFF') : null,
                        autoTranscribe: item.autoTranscribe != null ? (autoTranscribe ? 'ON' : 'OFF') : null,
                      );
                      Navigator.of(dialogContext).pop(updatedItem);
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      scopesController.dispose();
      mapsToController.dispose();
      clientIdController.dispose();
      clientSecretController.dispose();
    }

    final saved = updated;
    if (saved == null || !mounted) return;
    setState(() => _integrations[index] = saved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${saved.name} settings updated'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _statusColorFor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('connected')) return Colors.green;
    if (normalized.contains('degraded') || normalized.contains('retry')) return Colors.orange;
    if (normalized.contains('paused') || normalized.contains('disconnected')) return Colors.grey;
    return const Color(0xFF64748B);
  }

  String _formatRelativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  List<String> _parseScopes(String value) {
    return value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Widget _buildStatusBadge(_IntegrationItem item) {
    final status = item.status;
    final color = _statusColorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusOptions.contains(status) ? status : _statusOptions.first,
              items: _statusOptions
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _updateIntegration(item.copyWith(status: value));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(_IntegrationItem item) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildStatusBadge(item),
        if (item.errorInfo != null)
          _buildMetaField(
            key: ValueKey('integration-error-${item.id}'),
            value: item.errorInfo ?? '',
            hint: 'Error info',
            color: Colors.red,
            onChanged: (value) => _updateIntegration(item.copyWith(errorInfo: value)),
          ),
        if (item.lastSync != null)
          _buildMetaField(
            key: ValueKey('integration-sync-${item.id}'),
            value: item.lastSync ?? '',
            hint: 'Last sync',
            color: Colors.grey[500],
            onChanged: (value) => _updateIntegration(item.copyWith(lastSync: value)),
          ),
        if (item.events != null)
          _buildMetaField(
            key: ValueKey('integration-events-${item.id}'),
            value: item.events ?? '',
            hint: 'Events',
            color: Colors.grey[500],
            onChanged: (value) => _updateIntegration(item.copyWith(events: value)),
          ),
        if (item.sessions != null)
          _buildMetaField(
            key: ValueKey('integration-sessions-${item.id}'),
            value: item.sessions ?? '',
            hint: 'Sessions',
            color: Colors.grey[500],
            onChanged: (value) => _updateIntegration(item.copyWith(sessions: value)),
          ),
      ],
    );
  }

  Widget _buildMetaField({
    required Key key,
    required String value,
    required String hint,
    required Color? color,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 200,
      child: TextFormField(
        key: key,
        initialValue: value,
        maxLines: 1,
        decoration: _inlineDecoration(hint),
        style: TextStyle(fontSize: 12, color: color ?? Colors.grey[500]),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMappingRow(_IntegrationItem item) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildMappingChip(
          label: 'Maps to',
          value: item.mapsTo ?? '',
          onChanged: (value) => _updateIntegration(item.copyWith(mapsTo: value)),
        ),
        if (item.autoHandoff != null)
          _buildMappingChip(
            label: 'Auto-handoff',
            value: item.autoHandoff ?? '',
            onChanged: (value) => _updateIntegration(item.copyWith(autoHandoff: value)),
          ),
        if (item.syncMode != null)
          _buildMappingChip(
            label: 'Sync mode',
            value: item.syncMode ?? '',
            onChanged: (value) => _updateIntegration(item.copyWith(syncMode: value)),
          ),
        if (item.autoSummary != null)
          _buildMappingChip(
            label: 'Auto-summary',
            value: item.autoSummary ?? '',
            onChanged: (value) => _updateIntegration(item.copyWith(autoSummary: value)),
          ),
        if (item.autoTranscribe != null)
          _buildMappingChip(
            label: 'Auto-transcribe',
            value: item.autoTranscribe ?? '',
            onChanged: (value) => _updateIntegration(item.copyWith(autoTranscribe: value)),
          ),
      ],
    );
  }

  Widget _buildMappingChip({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
          SizedBox(
            width: 120,
            child: TextFormField(
              initialValue: value,
              maxLines: 1,
              decoration: _inlineDecoration(''),
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationItem {
  final String id;
  final IntegrationProvider provider;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String scopes;
  final String features;
  final String status;
  final Color statusColor;
  final String? mapsTo;
  final String? autoHandoff;
  final String? syncMode;
  final String? autoSummary;
  final String? autoTranscribe;
  final String? lastSync;
  final String? errorInfo;
  final String? events;
  final String? sessions;

  const _IntegrationItem({
    required this.id,
    required this.provider,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.scopes,
    required this.features,
    required this.status,
    required this.statusColor,
    this.mapsTo,
    this.autoHandoff,
    this.syncMode,
    this.autoSummary,
    this.autoTranscribe,
    this.lastSync,
    this.errorInfo,
    this.events,
    this.sessions,
  });

  _IntegrationItem copyWith({
    String? id,
    IntegrationProvider? provider,
    String? name,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    String? scopes,
    String? features,
    String? status,
    Color? statusColor,
    String? mapsTo,
    String? autoHandoff,
    String? syncMode,
    String? autoSummary,
    String? autoTranscribe,
    String? lastSync,
    String? errorInfo,
    String? events,
    String? sessions,
  }) {
    return _IntegrationItem(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      scopes: scopes ?? this.scopes,
      features: features ?? this.features,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
      mapsTo: mapsTo ?? this.mapsTo,
      autoHandoff: autoHandoff ?? this.autoHandoff,
      syncMode: syncMode ?? this.syncMode,
      autoSummary: autoSummary ?? this.autoSummary,
      autoTranscribe: autoTranscribe ?? this.autoTranscribe,
      lastSync: lastSync ?? this.lastSync,
      errorInfo: errorInfo ?? this.errorInfo,
      events: events ?? this.events,
      sessions: sessions ?? this.sessions,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'provider': provider.name,
        'name': name,
        'subtitle': subtitle,
        'icon': icon.codePoint,
        'iconColor': iconColor.value,
        'scopes': scopes,
        'features': features,
        'status': status,
        'mapsTo': mapsTo,
        'autoHandoff': autoHandoff,
        'syncMode': syncMode,
        'autoSummary': autoSummary,
        'autoTranscribe': autoTranscribe,
        'lastSync': lastSync,
        'errorInfo': errorInfo,
        'events': events,
        'sessions': sessions,
      };

  static List<_IntegrationItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      final providerName = map['provider']?.toString() ?? IntegrationProvider.figma.name;
      final provider = IntegrationProvider.values.firstWhere(
        (value) => value.name == providerName,
        orElse: () => IntegrationProvider.figma,
      );
      return _IntegrationItem(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        provider: provider,
        name: map['name']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
        icon: IconData(
          map['icon'] is int ? map['icon'] as int : Icons.link.codePoint,
          fontFamily: 'MaterialIcons',
        ),
        iconColor: Color(map['iconColor'] is int ? map['iconColor'] as int : const Color(0xFF94A3B8).value),
        scopes: map['scopes']?.toString() ?? '',
        features: map['features']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Not connected',
        statusColor: _statusColorForLabel(map['status']?.toString() ?? 'Not connected'),
        mapsTo: map['mapsTo']?.toString(),
        autoHandoff: map['autoHandoff']?.toString(),
        syncMode: map['syncMode']?.toString(),
        autoSummary: map['autoSummary']?.toString(),
        autoTranscribe: map['autoTranscribe']?.toString(),
        lastSync: map['lastSync']?.toString(),
        errorInfo: map['errorInfo']?.toString(),
        events: map['events']?.toString(),
        sessions: map['sessions']?.toString(),
      );
    }).toList();
  }
}

class _StatItem {
  final String id;
  final String label;
  final String value;
  final Color valueColor;

  const _StatItem({
    required this.id,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  _StatItem copyWith({String? label, String? value, Color? valueColor}) {
    return _StatItem(
      id: id,
      label: label ?? this.label,
      value: value ?? this.value,
      valueColor: valueColor ?? this.valueColor,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'value': value,
        'valueColor': valueColor.value,
      };

  static List<_StatItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _StatItem(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        value: map['value']?.toString() ?? '',
        valueColor: Color(map['valueColor'] is int ? map['valueColor'] as int : Colors.grey.value),
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

Color _statusColorForLabel(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('connected')) return Colors.green;
  if (normalized.contains('degraded') || normalized.contains('retry')) return Colors.orange;
  if (normalized.contains('paused') || normalized.contains('disconnected')) return Colors.grey;
  return const Color(0xFF64748B);
}
