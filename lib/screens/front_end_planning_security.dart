import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/screens/front_end_planning_allowance.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/form_validation_engine.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/utils/front_end_planning_navigation.dart';
import 'package:ndu_project/utils/rich_text_editing_controller.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';
import 'package:ndu_project/widgets/scroll_indicator_overlay.dart';
import 'package:ndu_project/widgets/text_formatting_toolbar.dart';
import 'package:ndu_project/widgets/responsive_table_widgets.dart';

/// Front End Planning – Security screen
/// Mirrors the provided layout with shared workspace chrome,
/// large notes area, security text panel, and AI hint + Next controls.
class FrontEndPlanningSecurityScreen extends StatefulWidget {
  const FrontEndPlanningSecurityScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FrontEndPlanningSecurityScreen()),
    );
  }

  @override
  State<FrontEndPlanningSecurityScreen> createState() =>
      _FrontEndPlanningSecurityScreenState();
}

class _FrontEndPlanningSecurityScreenState
    extends State<FrontEndPlanningSecurityScreen> {
  final GlobalKey _securityFieldKey = GlobalKey();
  final ScrollController _contentScrollController = ScrollController();
  final TextEditingController _notes = RichTextEditingController();
  final TextEditingController _securityNotes = RichTextEditingController();
  bool _isSyncReady = false;
  bool _isGenerating = false;
  bool _autoGenerationTriggered = false;
  bool _autoRolesPermissionsTriggered = false;
  bool _isGeneratingRolesPermissions = false;
  late final OpenAiServiceSecure _openAi;
  Map<String, String> _validationErrors = const {};
  List<RoleItem> _securityRoles = [];
  List<PermissionItem> _securityPermissions = [];
  List<SecuritySetting> _securitySettings = [];
  List<AccessLogItem> _securityAccessLogs = [];

  @override
  void initState() {
    super.initState();
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = ProjectDataHelper.getData(context);
      _securityNotes.text = data.frontEndPlanning.security;
      _securityRoles = List<RoleItem>.from(data.frontEndPlanning.securityRoles);
      _securityPermissions =
          List<PermissionItem>.from(data.frontEndPlanning.securityPermissions);
      _securitySettings =
          List<SecuritySetting>.from(data.frontEndPlanning.securitySettings);
      _securityAccessLogs =
          List<AccessLogItem>.from(data.frontEndPlanning.securityAccessLogs);
      _securityNotes.addListener(_syncSecurityToProvider);
      _isSyncReady = true;
      _syncSecurityToProvider();
      if (data.frontEndPlanning.security.trim().isEmpty) {
        _triggerAutoSecurityGenerationIfMissing();
      }
      _triggerAutoSecurityRolesPermissionsIfMissing();

      if (mounted) setState(() {});
    });
  }

  Future<void> _triggerAutoSecurityGenerationIfMissing() async {
    if (_autoGenerationTriggered || _isGenerating || !mounted) return;
    if (_securityNotes.text.trim().isNotEmpty) return;
    _autoGenerationTriggered = true;
    await _generateSecurityContent();
  }

  Future<void> _triggerAutoSecurityRolesPermissionsIfMissing() async {
    if (_autoRolesPermissionsTriggered || _isGeneratingRolesPermissions) return;
    if (_securityRoles.isNotEmpty && _securityPermissions.isNotEmpty) return;
    _autoRolesPermissionsTriggered = true;
    await _generateSecurityRolesPermissions();
  }

  Future<void> _regenerateAllSecurity() async {
    await _generateSecurityContent();
  }

  Future<void> _generateSecurityContent() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final data = ProjectDataHelper.getData(context);
      final provider = ProjectDataHelper.getProvider(context);
      final projectContext =
          ProjectDataHelper.buildFepContext(data, sectionLabel: 'Security');

      // Track field history before regenerating
      if (_securityNotes.text.trim().isNotEmpty) {
        provider.addFieldToHistory(
          'fep_security_content',
          _securityNotes.text,
          isAiGenerated: true,
        );
      }

      if (projectContext.trim().isNotEmpty) {
        try {
          final generatedText = await _openAi.generateFepSectionText(
            section: 'Security',
            context: projectContext,
            maxTokens: 800,
          );

          if (mounted && generatedText.isNotEmpty) {
            // Track new AI-generated content
            provider.addFieldToHistory(
              'fep_security_content',
              generatedText,
              isAiGenerated: true,
            );

            setState(() {
              _securityNotes.text = generatedText;
              _syncSecurityToProvider();
            });
            await ProjectDataHelper.getProvider(context)
                .saveToFirebase(checkpoint: 'fep_security');
          }
        } catch (e) {
          debugPrint('Error generating security content: $e');
          // Use fallback content
          if (mounted) {
            setState(() {
              _securityNotes.text = _getFallbackSecurityContent(data);
              _syncSecurityToProvider();
            });
          }
        }
      } else {
        // Use fallback if no context available
        if (mounted) {
          setState(() {
            _securityNotes.text = _getFallbackSecurityContent(data);
            _syncSecurityToProvider();
          });
        }
      }

      await _triggerAutoSecurityRolesPermissionsIfMissing();
    } catch (e) {
      debugPrint('Error in security generation: $e');
      // Use fallback content
      if (mounted) {
        final data = ProjectDataHelper.getData(context);
        setState(() {
          _securityNotes.text = _getFallbackSecurityContent(data);
          _syncSecurityToProvider();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateSecurityRolesPermissions() async {
    if (_isGeneratingRolesPermissions || !mounted) return;
    _isGeneratingRolesPermissions = true;

    try {
      final data = ProjectDataHelper.getData(context);
      var contextText =
          ProjectDataHelper.buildFepContext(data, sectionLabel: 'Security');
      if (contextText.trim().isEmpty) {
        contextText = ProjectDataHelper.buildProjectContextScan(
          data,
          sectionLabel: 'Security',
        );
      }

      final result = await _openAi.generateSecurityRolesAndPermissions(
        context: contextText,
        maxRoles: 4,
        maxPermissions: 5,
      );

      final shouldUpdateRoles = _securityRoles.isEmpty;
      final shouldUpdatePermissions = _securityPermissions.isEmpty;

      final roles = shouldUpdateRoles
          ? result['roles']!
              .map(
                (entry) => RoleItem(
                  name: (entry['name'] ?? '').toString().trim(),
                  description: (entry['description'] ?? '')
                      .toString()
                      .trim(),
                ),
              )
              .where((role) => role.name.isNotEmpty)
              .toList()
          : const <RoleItem>[];

      final permissions = shouldUpdatePermissions
          ? result['permissions']!
              .map(
                (entry) => PermissionItem(
                  resource: (entry['resource'] ?? '').toString().trim(),
                  scope: (entry['scope'] ?? '').toString().trim(),
                ),
              )
              .where((perm) => perm.resource.isNotEmpty)
              .toList()
          : const <PermissionItem>[];

      if ((shouldUpdateRoles && roles.isNotEmpty) ||
          (shouldUpdatePermissions && permissions.isNotEmpty)) {
        _persistSecurityLists(
          roles: shouldUpdateRoles ? roles : null,
          permissions: shouldUpdatePermissions ? permissions : null,
        );
      }
    } catch (e) {
      debugPrint('Error generating security roles/permissions: $e');
    } finally {
      _isGeneratingRolesPermissions = false;
    }
  }

  String _getFallbackSecurityContent(ProjectDataModel data) {
    return '''Security Considerations and Requirements

Access Control and Authentication:
- Implement role-based access control (RBAC) to ensure users have appropriate permissions
- Establish multi-factor authentication (MFA) for sensitive systems and data access
- Define user access policies and review access rights regularly

Data Protection:
- Encrypt sensitive data at rest and in transit using industry-standard encryption protocols
- Implement data classification policies to identify and protect confidential information
- Establish secure data backup and recovery procedures

Network Security:
- Deploy firewalls and intrusion detection/prevention systems
- Implement network segmentation to isolate critical systems
- Establish secure VPN access for remote users

Compliance and Governance:
- Ensure compliance with relevant security standards and regulations (e.g., ISO 27001, GDPR)
- Conduct regular security audits and vulnerability assessments
- Establish incident response procedures and security monitoring

Physical Security:
- Secure physical access to facilities and equipment
- Implement environmental controls for data centers and server rooms
- Establish visitor access policies and procedures

Security Training:
- Provide security awareness training for all project team members
- Establish clear security policies and procedures
- Conduct regular security reviews and updates''';
  }

  @override
  void dispose() {
    if (_isSyncReady) {
      _securityNotes.removeListener(_syncSecurityToProvider);
    }
    _contentScrollController.dispose();
    _notes.dispose();
    _securityNotes.dispose();
    super.dispose();
  }

  void _syncSecurityToProvider() {
    if (!mounted || !_isSyncReady) return;
    if (_validationErrors.containsKey('security_requirements') &&
        _securityNotes.text.trim().isNotEmpty) {
      setState(() {
        _validationErrors = Map<String, String>.from(_validationErrors)
          ..remove('security_requirements');
      });
    }
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          security: _securityNotes.text.trim(),
        ),
      ),
    );
    provider.saveToFirebase(checkpoint: 'fep_security');
  }

  void _persistSecurityLists({
    List<RoleItem>? roles,
    List<PermissionItem>? permissions,
    List<SecuritySetting>? settings,
    List<AccessLogItem>? accessLogs,
  }) {
    if (!mounted) return;
    setState(() {
      if (roles != null) _securityRoles = roles;
      if (permissions != null) _securityPermissions = permissions;
      if (settings != null) _securitySettings = settings;
      if (accessLogs != null) _securityAccessLogs = accessLogs;
    });

    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: data.frontEndPlanning.copyWith(
          securityRoles: roles ?? _securityRoles,
          securityPermissions: permissions ?? _securityPermissions,
          securitySettings: settings ?? _securitySettings,
          securityAccessLogs: accessLogs ?? _securityAccessLogs,
        ),
      ),
    );
    provider.saveToFirebase(checkpoint: 'fep_security');
  }

  Future<RoleItem?> _showRoleDialog({RoleItem? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    final saved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(existing == null ? 'Add Security Role' : 'Edit Role'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Role Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;

    if (!saved) return null;
    final name = nameController.text.trim();
    if (name.isEmpty) return null;
    return RoleItem(
      id: existing?.id,
      name: name,
      description: descController.text.trim(),
    );
  }

  Future<PermissionItem?> _showPermissionDialog(
      {PermissionItem? existing}) async {
    final resourceController =
        TextEditingController(text: existing?.resource ?? '');
    final scopeController =
        TextEditingController(text: existing?.scope ?? '');
    final saved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(existing == null
                ? 'Add Permission'
                : 'Edit Permission'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: resourceController,
                    decoration:
                        const InputDecoration(labelText: 'Resource'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: scopeController,
                    decoration: const InputDecoration(labelText: 'Scope'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;

    if (!saved) return null;
    if (resourceController.text.trim().isEmpty) return null;
    return PermissionItem(
      id: existing?.id,
      resource: resourceController.text.trim(),
      scope: scopeController.text.trim(),
    );
  }

  Future<SecuritySetting?> _showSettingDialog(
      {SecuritySetting? existing}) async {
    final keyController = TextEditingController(text: existing?.key ?? '');
    final valueController = TextEditingController(text: existing?.value ?? '');
    final saved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title:
                Text(existing == null ? 'Add Setting' : 'Edit Setting'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: keyController,
                    decoration:
                        const InputDecoration(labelText: 'Setting Key'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valueController,
                    decoration:
                        const InputDecoration(labelText: 'Value'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;

    if (!saved) return null;
    if (keyController.text.trim().isEmpty) return null;
    return SecuritySetting(
      key: keyController.text.trim(),
      value: valueController.text.trim(),
    );
  }

  Future<AccessLogItem?> _showAccessLogDialog(
      {AccessLogItem? existing}) async {
    final userController = TextEditingController(text: existing?.user ?? '');
    final actionController =
        TextEditingController(text: existing?.action ?? '');
    final timestampController = TextEditingController(
      text: existing?.timestamp.isNotEmpty == true
          ? existing!.timestamp
          : DateTime.now().toIso8601String(),
    );
    final saved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(existing == null ? 'Add Access Log' : 'Edit Log'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: userController,
                    decoration: const InputDecoration(labelText: 'User'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: actionController,
                    decoration: const InputDecoration(labelText: 'Action'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timestampController,
                    decoration:
                        const InputDecoration(labelText: 'Timestamp'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;

    if (!saved) return null;
    if (userController.text.trim().isEmpty) return null;
    return AccessLogItem(
      id: existing?.id,
      user: userController.text.trim(),
      action: actionController.text.trim(),
      timestamp: timestampController.text.trim(),
    );
  }

  Future<void> _addSecurityRole() async {
    final result = await _showRoleDialog();
    if (result == null) return;
    final next = [..._securityRoles, result];
    _persistSecurityLists(roles: next);
  }

  Future<void> _editSecurityRole(RoleItem role) async {
    final result = await _showRoleDialog(existing: role);
    if (result == null) return;
    final next = _securityRoles
        .map((item) => item.id == role.id ? result : item)
        .toList();
    _persistSecurityLists(roles: next);
  }

  void _removeSecurityRole(String id) {
    final next = _securityRoles.where((item) => item.id != id).toList();
    _persistSecurityLists(roles: next);
  }

  Future<void> _addPermission() async {
    final result = await _showPermissionDialog();
    if (result == null) return;
    final next = [..._securityPermissions, result];
    _persistSecurityLists(permissions: next);
  }

  Future<void> _editPermission(PermissionItem item) async {
    final result = await _showPermissionDialog(existing: item);
    if (result == null) return;
    final next = _securityPermissions
        .map((entry) => entry.id == item.id ? result : entry)
        .toList();
    _persistSecurityLists(permissions: next);
  }

  void _removePermission(String id) {
    final next =
        _securityPermissions.where((item) => item.id != id).toList();
    _persistSecurityLists(permissions: next);
  }

  Future<void> _addSetting() async {
    final result = await _showSettingDialog();
    if (result == null) return;
    final next = [..._securitySettings, result];
    _persistSecurityLists(settings: next);
  }

  Future<void> _editSetting(SecuritySetting setting) async {
    final result = await _showSettingDialog(existing: setting);
    if (result == null) return;
    final next = _securitySettings
        .map((entry) => entry.key == setting.key ? result : entry)
        .toList();
    _persistSecurityLists(settings: next);
  }

  void _removeSetting(String key) {
    final next = _securitySettings.where((item) => item.key != key).toList();
    _persistSecurityLists(settings: next);
  }

  Future<void> _addAccessLog() async {
    final result = await _showAccessLogDialog();
    if (result == null) return;
    final next = [..._securityAccessLogs, result];
    _persistSecurityLists(accessLogs: next);
  }

  Future<void> _editAccessLog(AccessLogItem item) async {
    final result = await _showAccessLogDialog(existing: item);
    if (result == null) return;
    final next = _securityAccessLogs
        .map((entry) => entry.id == item.id ? result : entry)
        .toList();
    _persistSecurityLists(accessLogs: next);
  }

  void _removeAccessLog(String id) {
    final next = _securityAccessLogs.where((item) => item.id != id).toList();
    _persistSecurityLists(accessLogs: next);
  }

  FormValidationResult _validateSecuritySection() {
    return FormValidationEngine.validateForm([
      ValidationFieldRule(
        id: 'security_requirements',
        label: 'Security Measures',
        section: 'Security Details',
        type: ValidationFieldType.text,
        value: _securityNotes.text,
        fieldKey: _securityFieldKey,
      ),
    ]);
  }

  Widget _buildSecurityCrudSection({
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onAdd,
    required List<DataColumn> columns,
    required List<DataRow> rows,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: Text(actionLabel),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          buildNduTableEmptyState(context, message: emptyMessage)
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ResponsiveDataTableWrapper(
              minWidth: 720,
              child: buildNduDataTable(
                context: context,
                columnSpacing: 20,
                horizontalMargin: 18,
                headingRowHeight: 46,
                dataRowMinHeight: 54,
                dataRowMaxHeight: 90,
                columns: columns,
                rows: rows,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSecurityRolesSection() {
    return _buildSecurityCrudSection(
      title: 'Security roles',
      description: 'Define roles responsible for security controls.',
      actionLabel: 'Add Role',
      onAdd: _addSecurityRole,
      emptyMessage: 'No security roles added yet.',
      columns: const [
        DataColumn(label: Text('Role')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Actions')),
      ],
      rows: _securityRoles.map((role) {
        return DataRow(
          cells: [
            DataCell(Text(role.name.trim().isEmpty ? 'Untitled' : role.name)),
            DataCell(Text(
                role.description.trim().isEmpty ? '-' : role.description)),
            DataCell(
              Row(
                children: [
                  IconButton(
                    onPressed: () => _editSecurityRole(role),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit role',
                  ),
                  IconButton(
                    onPressed: () => _removeSecurityRole(role.id),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSecurityPermissionsSection() {
    return _buildSecurityCrudSection(
      title: 'Permissions',
      description: 'Track access permissions across systems and data.',
      actionLabel: 'Add Permission',
      onAdd: _addPermission,
      emptyMessage: 'No permissions added yet.',
      columns: const [
        DataColumn(label: Text('Resource')),
        DataColumn(label: Text('Scope')),
        DataColumn(label: Text('Actions')),
      ],
      rows: _securityPermissions.map((item) {
        return DataRow(
          cells: [
            DataCell(
                Text(item.resource.trim().isEmpty ? '-' : item.resource)),
            DataCell(Text(item.scope.trim().isEmpty ? '-' : item.scope)),
            DataCell(
              Row(
                children: [
                  IconButton(
                    onPressed: () => _editPermission(item),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit permission',
                  ),
                  IconButton(
                    onPressed: () => _removePermission(item.id),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSecuritySettingsSection() {
    return _buildSecurityCrudSection(
      title: 'Security settings',
      description: 'Capture key security configuration standards.',
      actionLabel: 'Add Setting',
      onAdd: _addSetting,
      emptyMessage: 'No security settings added yet.',
      columns: const [
        DataColumn(label: Text('Setting')),
        DataColumn(label: Text('Value')),
        DataColumn(label: Text('Actions')),
      ],
      rows: _securitySettings.map((setting) {
        return DataRow(
          cells: [
            DataCell(
                Text(setting.key.trim().isEmpty ? '-' : setting.key)),
            DataCell(Text(
                setting.value.trim().isEmpty ? '-' : setting.value)),
            DataCell(
              Row(
                children: [
                  IconButton(
                    onPressed: () => _editSetting(setting),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit setting',
                  ),
                  IconButton(
                    onPressed: () => _removeSetting(setting.key),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSecurityAccessLogsSection() {
    return _buildSecurityCrudSection(
      title: 'Access logs',
      description: 'Log key access events and audit activity.',
      actionLabel: 'Add Log',
      onAdd: _addAccessLog,
      emptyMessage: 'No access logs recorded yet.',
      columns: const [
        DataColumn(label: Text('User')),
        DataColumn(label: Text('Action')),
        DataColumn(label: Text('Timestamp')),
        DataColumn(label: Text('Actions')),
      ],
      rows: _securityAccessLogs.map((log) {
        return DataRow(
          cells: [
            DataCell(Text(log.user.trim().isEmpty ? '-' : log.user)),
            DataCell(Text(log.action.trim().isEmpty ? '-' : log.action)),
            DataCell(Text(
                log.timestamp.trim().isEmpty ? '-' : log.timestamp)),
            DataCell(
              Row(
                children: [
                  IconButton(
                    onPressed: () => _editAccessLog(log),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit log',
                  ),
                  IconButton(
                    onPressed: () => _removeAccessLog(log.id),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _nextFlowDestinationLabel() {
    final rawLabel =
        FrontEndPlanningNavigation.nextLabel(context, 'fep_security').trim();
    if (rawLabel.startsWith('Next:')) {
      final parsed = rawLabel.substring('Next:'.length).trim();
      if (parsed.isNotEmpty && parsed.toLowerCase() != 'next') {
        return parsed;
      }
    }
    return 'Milestone';
  }

  Future<void> _saveAndNavigateToAllowance({
    bool skippedValidation = false,
  }) async {
    if (!mounted) return;
    final destinationLabel = _nextFlowDestinationLabel();
    if (skippedValidation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Continuing to $destinationLabel. You can complete Security details later.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }

    final nextCheckpoint =
        FrontEndPlanningNavigation.nextCheckpoint(context, 'fep_security') ??
            'fep_milestone';
    final fallbackScreen =
        FrontEndPlanningNavigation.resolveScreen(context, 'fep_milestone') ??
            const FrontEndPlanningAllowanceScreen();
    final nextScreen =
        FrontEndPlanningNavigation.resolveScreen(context, nextCheckpoint) ??
            fallbackScreen;

    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'fep_security',
      saveInBackground: true,
      nextScreenBuilder: () => nextScreen,
      dataUpdater: (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          security: _securityNotes.text.trim(),
        ),
      ),
    );
  }

  Future<void> _handleNextPressed() async {
    final validation = _validateSecuritySection();

    if (!validation.isValid) {
      if (mounted) {
        setState(() => _validationErrors = validation.errorByFieldId);
      }

      FormValidationEngine.showValidationSnackBar(
        context,
        validation,
        intro:
            'Security details are recommended before proceeding. You can continue now and complete them later.',
        backgroundColor: const Color(0xFFF59E0B),
      );

      await _saveAndNavigateToAllowance(skippedValidation: true);
      return;
    }

    if (_validationErrors.isNotEmpty && mounted) {
      setState(() => _validationErrors = const {});
    }

    await _saveAndNavigateToAllowance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Security'),
            ),
            Expanded(
              child: Stack(
                children: [
                  const AdminEditToggle(),
                  Column(
                    children: [
                      const FrontEndPlanningHeader(),
                      Expanded(
                        child: ScrollIndicatorOverlay(
                          controller: _contentScrollController,
                          child: SingleChildScrollView(
                            controller: _contentScrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              _roundedField(
                                  controller: _notes,
                                  hint: 'Input your notes here...',
                                  minLines: 3),
                              const SizedBox(height: 24),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Security',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Define security requirements and considerations for the project',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PageRegenerateAllButton(
                                    onRegenerateAll: () async {
                                      final confirmed =
                                          await showRegenerateAllConfirmation(
                                              context);
                                      if (confirmed && mounted) {
                                        await _regenerateAllSecurity();
                                      }
                                    },
                                    isLoading: _isGenerating,
                                    tooltip: 'Regenerate all security content',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                                _SecurityPanel(
                                  fieldKey: _securityFieldKey,
                                  controller: _securityNotes,
                                  errorText: _validationErrors[
                                      'security_requirements'],
                                ),
                                const SizedBox(height: 24),
                                _buildSecurityRolesSection(),
                                const SizedBox(height: 24),
                                _buildSecurityPermissionsSection(),
                                const SizedBox(height: 24),
                                _buildSecuritySettingsSection(),
                                const SizedBox(height: 24),
                                _buildSecurityAccessLogsSection(),
                                const SizedBox(height: 140),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _BottomOverlay(
                    onNext: _handleNextPressed,
                  ),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityPanel extends StatelessWidget {
  const _SecurityPanel({
    required this.controller,
    this.errorText,
    this.fieldKey,
  });

  final TextEditingController controller;
  final String? errorText;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final hasError = (errorText ?? '').trim().isNotEmpty;
    return Column(
      key: fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  hasError ? const Color(0xFFEF4444) : const Color(0xFFE4E7EC),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormattingToolbar(controller: controller),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                minLines: 12,
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '',
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            Positioned(
              left: 24,
              bottom: 24,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                    color: Color(0xFFB3D9FF), shape: BoxShape.circle),
                child: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F1FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD7E5FF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                        SizedBox(width: 10),
                        Text('AI',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB))),
                        SizedBox(width: 12),
                        Text(
                          'Identify security measures and compliance requirements.',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC812),
                      foregroundColor: const Color(0xFF111827),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 34, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: const Text('Next',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _roundedField(
    {required TextEditingController controller,
    required String hint,
    int minLines = 1}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE4E7EC)),
    ),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormattingToolbar(controller: controller),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: null,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          ),
          style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
        ),
      ],
    ),
  );
}
