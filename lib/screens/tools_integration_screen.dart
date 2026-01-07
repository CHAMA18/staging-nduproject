import 'package:flutter/material.dart';
import 'package:ndu_project/services/integration_oauth_service.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/app_logo.dart';

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
  
  // Mock data for integrations
  final List<_IntegrationItem> _integrations = [
    _IntegrationItem(
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

  @override
  void initState() {
    super.initState();
    _refreshIntegrationStatuses();
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
                  _buildHeader(isNarrow),
                  const SizedBox(height: 24),
                  _buildStatsRow(isNarrow),
                  const SizedBox(height: 24),
                  _buildToolConnectionManager(isNarrow),
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
    if (mounted) setState(() {});
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

  Widget _buildHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandMark(),
        const SizedBox(height: 16),
        // Phase tabs and search row
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildPhaseTabs(),
            const SizedBox(width: 8),
            SizedBox(
              width: isNarrow ? double.infinity : 280,
              child: _buildSearchBar(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Title and description
        Row(
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
                    'Monitor, configure, and troubleshoot Figma, Draw.io, Miro, and whiteboard integrations in one place.',
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
    final stats = [
      _StatItem('Connected tools', '4 / 4 healthy', Colors.green),
      _StatItem('Integration health score', '92 / 100', const Color(0xFF0EA5E9)),
      _StatItem('Last full sync', '09:42 · every 15 min', Colors.grey),
      _StatItem('Open integration issues', '4 items', Colors.orange),
    ];

    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => _buildStatChip(stat, flex: false)).toList(),
      );
    }

    return Row(
      children: stats.map((stat) => Expanded(child: Padding(
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
          Text(stat.label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(width: 8),
          Text(
            stat.value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: stat.valueColor),
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
                  Text(
                    '${item.name} · ',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F)),
                  ),
                  Text(
                    item.subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Scopes: ${item.scopes} · ${item.features}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildStatusBadge(item.status, item.statusColor),
                  if (item.errorInfo != null) ...[
                    const SizedBox(width: 12),
                    Text(item.errorInfo!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ],
                  if (item.lastSync != null) ...[
                    const SizedBox(width: 12),
                    Text(item.lastSync!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                  if (item.events != null) ...[
                    const SizedBox(width: 12),
                    Text(item.events!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                  if (item.sessions != null) ...[
                    const SizedBox(width: 12),
                    Text(item.sessions!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              _buildMappingRow(item),
            ],
          ),
        ),
        // Configure button
        OutlinedButton(
          onPressed: () => _openIntegrationConfig(item, index),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Configure', style: TextStyle(fontSize: 13)),
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
                  Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(item.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            _buildStatusBadge(item.status, item.statusColor),
          ],
        ),
        const SizedBox(height: 12),
        Text('Scopes: ${item.scopes}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(item.features, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 8),
        _buildMappingRow(item),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _openIntegrationConfig(item, index),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: const Text('Configure'),
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
    if (!mounted) return;
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'Status: $status',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingRow(_IntegrationItem item) {
    final chips = <Widget>[];
    chips.add(_buildMappingChip('Maps to: ${item.mapsTo}'));
    if (item.autoHandoff != null) chips.add(_buildMappingChip('Auto-handoff: ${item.autoHandoff}'));
    if (item.syncMode != null) chips.add(_buildMappingChip('Sync mode: ${item.syncMode}'));
    if (item.autoSummary != null) chips.add(_buildMappingChip('Auto-summary: ${item.autoSummary}'));
    if (item.autoTranscribe != null) chips.add(_buildMappingChip('Auto-transcribe: ${item.autoTranscribe}'));

    return Wrap(spacing: 8, runSpacing: 6, children: chips);
  }

  Widget _buildMappingChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
    );
  }
}

class _IntegrationItem {
  static const Object _unset = Object();

  final IntegrationProvider provider;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String scopes;
  final String features;
  final String status;
  final Color statusColor;
  final String mapsTo;
  final String? autoHandoff;
  final String? syncMode;
  final String? autoSummary;
  final String? autoTranscribe;
  final String? lastSync;
  final String? errorInfo;
  final String? events;
  final String? sessions;

  const _IntegrationItem({
    required this.provider,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.scopes,
    required this.features,
    required this.status,
    required this.statusColor,
    required this.mapsTo,
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
    String? status,
    Color? statusColor,
    String? scopes,
    String? mapsTo,
    String? autoHandoff,
    String? syncMode,
    String? autoSummary,
    String? autoTranscribe,
    Object? lastSync = _unset,
  }) {
    final resolvedLastSync = identical(lastSync, _unset) ? this.lastSync : lastSync as String?;
    return _IntegrationItem(
      provider: provider,
      name: name,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      scopes: scopes ?? this.scopes,
      features: features,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
      mapsTo: mapsTo ?? this.mapsTo,
      autoHandoff: autoHandoff ?? this.autoHandoff,
      syncMode: syncMode ?? this.syncMode,
      autoSummary: autoSummary ?? this.autoSummary,
      autoTranscribe: autoTranscribe ?? this.autoTranscribe,
      lastSync: resolvedLastSync,
      errorInfo: errorInfo,
      events: events,
      sessions: sessions,
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final Color valueColor;

  const _StatItem(this.label, this.value, this.valueColor);
}
