import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

class StartUpPlanningOperationsScreen extends StatelessWidget {
  const StartUpPlanningOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartUpPlanningSectionScreen(
      config: _StartUpPlanningSectionConfig(
        title: 'Operations Plan & Manual',
        subtitle: 'Define runbooks, ownership, and operating procedures for launch readiness.',
        noteKey: 'planning_startup_operations_notes',
        checkpoint: 'startup_planning_operations',
        activeItemLabel: 'Start-Up Planning - Operations Plan and Manual',
        sectionId: 'startup_operations_plan',
        metrics: const [
          _MetricData('Runbook coverage', '92%', Color(0xFF10B981)),
          _MetricData('On-call readiness', '100%', Color(0xFF2563EB)),
          _MetricData('Escalation SLA', '15 min', Color(0xFFF59E0B)),
          _MetricData('Monitoring coverage', '36 services', Color(0xFF8B5CF6)),
        ],
        sections: const [
          _SectionData(
            title: 'Runbook and SOPs',
            subtitle: 'Ensure operational playbooks cover critical flows and recovery steps.',
            bullets: [
              _BulletData('Critical service runbooks reviewed with owners', true),
              _BulletData('Failure modes and rollback steps validated', true),
              _BulletData('Dependency map and contacts documented', false),
            ],
            statusRows: [
              _StatusRowData('Runbook completeness', 'On track', Color(0xFF10B981)),
              _StatusRowData('Ownership matrix', 'In review', Color(0xFFF59E0B)),
            ],
          ),
          _SectionData(
            title: 'On-call and escalation',
            subtitle: 'Define coverage, escalation paths, and decision authority.',
            bullets: [
              _BulletData('Primary and secondary roster published', true),
              _BulletData('War room channels and tooling ready', true),
              _BulletData('Vendor escalation path confirmed', true),
            ],
            statusRows: [
              _StatusRowData('On-call coverage', 'Ready', Color(0xFF10B981)),
              _StatusRowData('Escalation SLA', '15 min', Color(0xFF2563EB)),
            ],
          ),
          _SectionData(
            title: 'Monitoring and KPIs',
            subtitle: 'Align golden signals and alert thresholds for go-live.',
            bullets: [
              _BulletData('Golden signals defined per service', true),
              _BulletData('Dashboards linked to runbooks', false),
              _BulletData('Alert thresholds agreed with Ops', true),
            ],
            statusRows: [
              _StatusRowData('Monitoring coverage', '85%', Color(0xFF8B5CF6)),
              _StatusRowData('Alert tuning', 'In progress', Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }
}

/// World-class Operations Plan editor used when the section is empty.
class _WorldClassOpsEditor extends StatefulWidget {
  const _WorldClassOpsEditor({required this.sectionId, this.sectionTitle});

  final String sectionId;
  final String? sectionTitle;

  @override
  State<_WorldClassOpsEditor> createState() => _WorldClassOpsEditorState();
}

class _WorldClassOpsEditorState extends State<_WorldClassOpsEditor> {
  final TextEditingController _editorCtrl = TextEditingController();
  final TextEditingController _titleCtrl = TextEditingController();
  final _Debouncer _autosaveDebouncer = _Debouncer();
  final Set<String> _selectedRoles = {};
  late final List<String> _roles;
  late final List<String> _templates;
  String? _selectedTemplate;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isHydrating = true;
  bool _hasExistingDoc = false;
  bool _isUploading = false;
  List<_AttachmentMeta> _attachments = [];
  DateTime? _lastSavedAt;
  DateTime? _publishedAt;

  @override
  void initState() {
    super.initState();
    _configureTemplatesAndRoles();
    _titleCtrl.text = widget.sectionTitle ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraft());
  }

  @override
  void dispose() {
    _autosaveDebouncer.dispose();
    _editorCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _configureTemplatesAndRoles() {
    switch (widget.sectionId) {
      case 'startup_hypercare_plan':
        _templates = ['Hypercare checklist', 'Monitoring rota', 'Incident response', 'Handover notes'];
        _roles = ['Hypercare Lead', 'Support', 'Monitoring', 'QA', 'Product'];
        break;
      case 'startup_devops':
        _templates = ['Pipeline checklist', 'Release playbook', 'Infrastructure readiness', 'Rollback plan'];
        _roles = ['DevOps Lead', 'SRE', 'Release Manager', 'Security', 'QA'];
        break;
      case 'startup_closeout_plan':
        _templates = ['Acceptance checklist', 'Handover summary', 'Post-launch review', 'Backlog triage'];
        _roles = ['Project Lead', 'Ops', 'Support', 'Finance', 'Legal'];
        break;
      default:
        _templates = ['Runbook', 'On-call rota', 'Escalation steps', 'Monitoring checklist'];
        _roles = ['Ops Lead', 'SRE', 'Support', 'QA', 'Product'];
    }
    _selectedRoles
      ..clear()
      ..add(_roles.first);
  }

  void _applyTemplate(String template) {
    setState(() {
      _selectedTemplate = template;
      _editorCtrl.text = switch (template) {
        'Runbook' => 'Objective:\n\nScope:\n\nStep 1: ...\nStep 2: ...\n\nContact: Ops Lead',
        'On-call rota' => 'Week 1: Primary\nWeek 2: Secondary\n\nEscalation: ...',
        'Escalation steps' => '1. Triage\n2. Notify\n3. Escalate to vendor',
        'Monitoring checklist' => '1. Metrics to watch\n2. Alert thresholds\n3. Runbook link',
        'Hypercare checklist' => 'Day 1: Stabilization checks\nDay 2: Performance sweep\nDay 3: Feedback review',
        'Monitoring rota' => 'Shift A: 08:00-16:00\nShift B: 16:00-00:00\nShift C: 00:00-08:00',
        'Incident response' => '1. Declare incident\n2. Assign commander\n3. Communicate status',
        'Handover notes' => 'Known issues:\n\nMitigations:\n\nOwner contacts:',
        'Pipeline checklist' => 'Build passes\nTest coverage met\nArtifact signed\nDeploy automation ready',
        'Release playbook' => 'Pre-flight checks\nCanary rollout\nPost-deploy validation',
        'Infrastructure readiness' => 'IaC drift check\nSecrets rotation\nCapacity validation',
        'Rollback plan' => 'Rollback trigger\nData recovery steps\nCommunication plan',
        'Acceptance checklist' => 'Criteria met\nStakeholder sign-off\nAudit evidence captured',
        'Handover summary' => 'Service overview\nKey contacts\nSupport SLAs\nRunbook links',
        'Post-launch review' => 'KPIs baseline\nLessons learned\nAction items',
        'Backlog triage' => 'Outstanding requests\nPriority ranking\nOwner assignments',
        _ => _editorCtrl.text,
      };
    });
    _scheduleAutosave();
  }

  Future<void> _attachFile() async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a project to attach files.')),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file selected.')));
        }
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read file bytes. Try a smaller file.')),
        );
        return;
      }

      setState(() => _isUploading = true);
      final fileName = file.name;
      final extension = file.extension?.toLowerCase();
      final storagePath = 'projects/$projectId/startup_planning_sections/${widget.sectionId}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final storageRef = FirebaseStorage.instance.ref(storagePath);
      final metadata = SettableMetadata(contentType: _contentTypeForExtension(extension));
      final snapshot = await storageRef.putData(bytes, metadata);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      final attachment = _AttachmentMeta(
        id: storagePath,
        name: fileName,
        sizeBytes: file.size,
        extension: extension ?? '',
        storagePath: storagePath,
        downloadUrl: downloadUrl,
        uploadedAt: DateTime.now(),
      );

      if (!mounted) return;
      setState(() {
        _attachments = [..._attachments, attachment];
        _isUploading = false;
      });
      await _persistAttachments(showToast: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload file: $error')),
      );
    }
  }

  Future<void> _loadDraft() async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isHydrating = false;
        });
      }
      return;
    }
    try {
      final doc = await _docRef(projectId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        _hasExistingDoc = true;
        final savedTitle = (data['title'] as String?)?.trim();
        if ((savedTitle ?? '').isNotEmpty) {
          _titleCtrl.text = savedTitle!;
        }
        _editorCtrl.text = (data['body'] as String?) ?? '';
        final savedTemplate = data['template'] as String?;
        if (savedTemplate != null) {
          if (!_templates.contains(savedTemplate)) {
            _templates.add(savedTemplate);
          }
          _selectedTemplate = savedTemplate;
        }
        final savedRoles = (data['roles'] as List?)?.whereType<String>().toList() ?? [];
        if (savedRoles.isNotEmpty) {
          for (final role in savedRoles) {
            if (!_roles.contains(role)) {
              _roles.add(role);
            }
          }
          _selectedRoles
            ..clear()
            ..addAll(savedRoles);
        }
        _lastSavedAt = _readTimestamp(data['updatedAt']) ?? _readTimestamp(data['createdAt']);
        _publishedAt = _readTimestamp(data['publishedAt']);
        _attachments = _decodeAttachments(data['attachments']);
      }
    } catch (error) {
      debugPrint('Failed to load start-up planning draft: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isHydrating = false;
        });
      }
    }
  }

  Future<void> _saveDraft({bool publish = false, bool showToast = true}) async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a project to save this plan.')));
      }
      return;
    }
    if (mounted) setState(() => _isSaving = true);
    final payload = <String, dynamic>{
      'sectionId': widget.sectionId,
      'sectionTitle': widget.sectionTitle ?? '',
      'title': _titleCtrl.text.trim(),
      'body': _editorCtrl.text.trim(),
      'roles': _selectedRoles.toList()..sort(),
      'template': _selectedTemplate,
      'attachments': _attachments.map((attachment) => attachment.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!_hasExistingDoc) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    if (publish) {
      payload['publishedAt'] = FieldValue.serverTimestamp();
      payload['isPublished'] = true;
    }
    try {
      await _docRef(projectId).set(payload, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _hasExistingDoc = true;
        _isSaving = false;
        _lastSavedAt = DateTime.now();
        if (publish) _publishedAt = DateTime.now();
      });
      if (showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(publish ? 'Plan published.' : 'Draft saved.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save draft: $error')),
        );
      }
    }
  }

  List<_AttachmentMeta> _decodeAttachments(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _AttachmentMeta(
        id: (data['id'] as String?) ?? (data['storagePath'] as String?) ?? '',
        name: (data['name'] as String?) ?? 'Attachment',
        sizeBytes: (data['sizeBytes'] as num?)?.toInt() ?? 0,
        extension: (data['extension'] as String?) ?? '',
        storagePath: (data['storagePath'] as String?) ?? '',
        downloadUrl: (data['downloadUrl'] as String?) ?? '',
        uploadedAt: _readTimestamp(data['uploadedAt']) ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> _persistAttachments({bool showToast = false}) async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) return;
    try {
      await _docRef(projectId).set(
        {
          'attachments': _attachments.map((attachment) => attachment.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attachment uploaded.')));
      }
    } catch (error) {
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save attachment metadata: $error')));
      }
    }
  }

  Future<void> _removeAttachment(_AttachmentMeta attachment) async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) return;
    setState(() => _attachments.removeWhere((item) => item.id == attachment.id));
    await _persistAttachments();
    await _deleteStorageObject(attachment.storagePath);
  }

  Future<void> _deleteStorageObject(String storagePath) async {
    if (storagePath.trim().isEmpty) return;
    try {
      await FirebaseStorage.instance.ref(storagePath).delete();
    } catch (error) {
      debugPrint('Failed to delete storage object: $error');
    }
  }

  String _contentTypeForExtension(String? extension) {
    final ext = (extension ?? '').toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'csv':
        return 'text/csv';
      case 'txt':
      case 'md':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  Future<void> _confirmClear() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear draft?'),
        content: const Text('This will permanently delete the saved plan for this section.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (shouldClear == true) {
      await _clearDraft();
    }
  }

  Future<void> _clearDraft() async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) return;
    setState(() {
      _isHydrating = true;
      _isSaving = true;
    });
    try {
      if (_attachments.isNotEmpty) {
        for (final attachment in _attachments) {
          await _deleteStorageObject(attachment.storagePath);
        }
      }
      await _docRef(projectId).delete();
      _titleCtrl.text = widget.sectionTitle ?? '';
      _editorCtrl.clear();
      _selectedTemplate = null;
      _selectedRoles
        ..clear()
        ..add(_roles.first);
      _attachments = [];
      if (!mounted) return;
      setState(() {
        _hasExistingDoc = false;
        _lastSavedAt = null;
        _publishedAt = null;
        _isSaving = false;
        _isHydrating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft cleared.')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isHydrating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to clear draft: $error')));
    }
  }

  DocumentReference<Map<String, dynamic>> _docRef(String projectId) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('startup_planning_sections')
        .doc(widget.sectionId);
  }

  DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  void _scheduleAutosave() {
    if (_isHydrating) return;
    _autosaveDebouncer.run(() => _saveDraft(showToast: false));
  }

  String _formatTime(DateTime dateTime) {
    return TimeOfDay.fromDateTime(dateTime).format(context);
  }

  Widget _buildAttachmentsList() {
    if (_attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Attachments', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${_attachments.length} files', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(height: 8),
          for (final attachment in _attachments)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined, size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(attachment.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(_formatFileSize(attachment.sizeBytes), style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                    onPressed: () => _removeAttachment(attachment),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (_isSaving) {
      chips.add(const _StatusPill(label: 'Saving...', color: Color(0xFF64748B), background: Color(0xFFE2E8F0)));
    }
    if (_isUploading) {
      chips.add(const _StatusPill(label: 'Uploading...', color: Color(0xFF0F172A), background: Color(0xFFE2E8F0)));
    }
    if (_publishedAt != null) {
      chips.add(
        _StatusPill(
          label: 'Published ${_formatTime(_publishedAt!)}',
          color: const Color(0xFF2563EB),
          background: const Color(0xFFDBEAFE),
        ),
      );
    }
    if (_lastSavedAt != null) {
      chips.add(
        _StatusPill(
          label: 'Saved ${_formatTime(_lastSavedAt!)}',
          color: const Color(0xFF16A34A),
          background: const Color(0xFFECFDF3),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_isLoading) const LinearProgressIndicator(minHeight: 2),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _titleCtrl,
              onChanged: (_) => _scheduleAutosave(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Title (e.g. Operations Plan & Manual)',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _attachFile,
            icon: const Icon(Icons.attach_file, size: 18),
            label: const Text('Attach'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3F4F6), foregroundColor: Colors.black),
          ),
        ]),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(spacing: 8, runSpacing: 8, children: chips),
          ),
        ],
        const SizedBox(height: 12),

        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in _templates)
            ChoiceChip(
              label: Text(t),
              selected: _selectedTemplate == t,
              onSelected: (_) => _applyTemplate(t),
              selectedColor: const Color(0xFFFFF8DC),
              backgroundColor: const Color(0xFFF8FAFC),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
        ]),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(10)),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            const Text('Assign roles: ', style: TextStyle(fontWeight: FontWeight.w700)),
            for (final r in _roles)
              FilterChip(
                label: Text(r),
                selected: _selectedRoles.contains(r),
                onSelected: (v) {
                  setState(() => v ? _selectedRoles.add(r) : _selectedRoles.remove(r));
                  _scheduleAutosave();
                },
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (_attachments.isNotEmpty) ...[
          _buildAttachmentsList(),
          const SizedBox(height: 12),
        ],

        Container(
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _editorCtrl,
            onChanged: (_) => _scheduleAutosave(),
            maxLines: null,
            style: const TextStyle(fontSize: 14, height: 1.6),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Start writing your plan — use templates above to get started.',
            ),
          ),
        ),
        const SizedBox(height: 14),

        Row(children: [
          ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _saveDraft(showToast: true),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save draft'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEFF6FF), foregroundColor: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _confirmClear,
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Clear'),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _saveDraft(publish: true, showToast: true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
            child: const Text('Publish', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ])
      ]),
    );
  }
}

class StartUpPlanningHypercareScreen extends StatelessWidget {
  const StartUpPlanningHypercareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartUpPlanningSectionScreen(
      config: _StartUpPlanningSectionConfig(
        title: 'Hypercare Plan',
        subtitle: 'Define post-launch monitoring, coverage, and escalation routines.',
        noteKey: 'planning_startup_hypercare_notes',
        checkpoint: 'startup_planning_hypercare',
        activeItemLabel: 'Start-Up Planning - Hypercare Plan',
        sectionId: 'startup_hypercare_plan',
        metrics: const [
          _MetricData('Coverage days', '14', Color(0xFF8B5CF6)),
          _MetricData('War room hours', '16/day', Color(0xFF2563EB)),
          _MetricData('Critical alerts', '0', Color(0xFF10B981)),
          _MetricData('Open incidents', '2', Color(0xFFF59E0B)),
        ],
        sections: const [
          _SectionData(
            title: 'Hypercare operating model',
            subtitle: 'Define cadence, ownership, and stabilization responsibilities.',
            bullets: [
              _BulletData('War room schedule and rotations set', true),
              _BulletData('Incident commander assigned', true),
              _BulletData('Daily stability review scheduled', false),
            ],
            statusRows: [
              _StatusRowData('Coverage staffed', 'Planned', Color(0xFF2563EB)),
              _StatusRowData('Decision authority', 'Confirmed', Color(0xFF10B981)),
            ],
          ),
          _SectionData(
            title: 'Customer communications',
            subtitle: 'Maintain consistent updates and rapid issue visibility.',
            bullets: [
              _BulletData('Stakeholder update cadence agreed', true),
              _BulletData('Support scripts and FAQ ready', true),
              _BulletData('Feedback loop for regression signals', true),
            ],
            statusRows: [
              _StatusRowData('Comms readiness', 'Ready', Color(0xFF10B981)),
              _StatusRowData('Support enablement', 'On track', Color(0xFF2563EB)),
            ],
          ),
          _SectionData(
            title: 'Stabilization checklist',
            subtitle: 'Track critical issues, regressions, and release gates.',
            bullets: [
              _BulletData('High severity alerts triaged within SLA', true),
              _BulletData('Rollback criteria defined', true),
              _BulletData('Release freeze window published', false),
            ],
            statusRows: [
              _StatusRowData('Escalation SLA', '30 min', Color(0xFFF59E0B)),
              _StatusRowData('Release gates', 'In review', Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }
}

class StartUpPlanningDevOpsScreen extends StatelessWidget {
  const StartUpPlanningDevOpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartUpPlanningSectionScreen(
      config: _StartUpPlanningSectionConfig(
        title: 'DevOps',
        subtitle: 'Assess pipeline readiness, environments, and automation coverage.',
        noteKey: 'planning_startup_devops_notes',
        checkpoint: 'startup_planning_devops',
        activeItemLabel: 'Start-Up Planning - DevOps',
        sectionId: 'startup_devops',
        metrics: const [
          _MetricData('Pipeline health', '98%', Color(0xFF10B981)),
          _MetricData('Deploy frequency', '3x/week', Color(0xFF2563EB)),
          _MetricData('Change fail rate', '4%', Color(0xFFF59E0B)),
          _MetricData('MTTR', '45 min', Color(0xFF8B5CF6)),
        ],
        sections: const [
          _SectionData(
            title: 'CI/CD pipeline',
            subtitle: 'Automate builds, tests, and releases with compliance gates.',
            bullets: [
              _BulletData('Automated tests gated on merge', true),
              _BulletData('Artifact signing and provenance checks', true),
              _BulletData('Rollback automation validated', false),
            ],
            statusRows: [
              _StatusRowData('Pipeline readiness', 'Ready', Color(0xFF10B981)),
              _StatusRowData('Rollback automation', 'In progress', Color(0xFFF59E0B)),
            ],
          ),
          _SectionData(
            title: 'Environment readiness',
            subtitle: 'Ensure production parity, secrets, and observability.',
            bullets: [
              _BulletData('Prod parity validated in staging', true),
              _BulletData('Secrets managed via vault', true),
              _BulletData('Tracing and logs integrated', true),
            ],
            statusRows: [
              _StatusRowData('Infrastructure drift', 'Low', Color(0xFF10B981)),
              _StatusRowData('Observability', 'Healthy', Color(0xFF2563EB)),
            ],
          ),
          _SectionData(
            title: 'Release governance',
            subtitle: 'Align change approvals and progressive delivery strategy.',
            bullets: [
              _BulletData('Change approvals mapped to risk tiers', true),
              _BulletData('Canary rollout strategy defined', true),
              _BulletData('Post-deploy validation checklist', false),
            ],
            statusRows: [
              _StatusRowData('Release cadence', 'Stable', Color(0xFF2563EB)),
              _StatusRowData('Change governance', 'On track', Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }
}

class StartUpPlanningCloseOutPlanScreen extends StatelessWidget {
  const StartUpPlanningCloseOutPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartUpPlanningSectionScreen(
      config: _StartUpPlanningSectionConfig(
        title: 'Close Out Plan',
        subtitle: 'Outline post-launch closure activities and acceptance criteria.',
        noteKey: 'planning_startup_closeout_notes',
        checkpoint: 'startup_planning_closeout',
        activeItemLabel: 'Start-Up Planning - Close Out Plan',
        sectionId: 'startup_closeout_plan',
        metrics: const [
          _MetricData('Open items', '6', Color(0xFFF59E0B)),
          _MetricData('Docs complete', '85%', Color(0xFF2563EB)),
          _MetricData('Sign-offs', '3/5', Color(0xFF8B5CF6)),
          _MetricData('Audit readiness', '90%', Color(0xFF10B981)),
        ],
        sections: const [
          _SectionData(
            title: 'Acceptance and closure',
            subtitle: 'Define criteria, sign-offs, and residual risk tracking.',
            bullets: [
              _BulletData('Acceptance criteria reviewed with stakeholders', true),
              _BulletData('Final audit checklist prepared', true),
              _BulletData('Residual risk register updated', false),
            ],
            statusRows: [
              _StatusRowData('Sign-offs', 'Pending', Color(0xFFF59E0B)),
              _StatusRowData('Audit checklist', 'Ready', Color(0xFF10B981)),
            ],
          ),
          _SectionData(
            title: 'Knowledge transfer',
            subtitle: 'Ensure operations, support, and clients have the materials they need.',
            bullets: [
              _BulletData('Runbooks and SOPs handed off', true),
              _BulletData('Ops training sessions completed', false),
              _BulletData('Support escalation map shared', true),
            ],
            statusRows: [
              _StatusRowData('Training completion', '60%', Color(0xFFF59E0B)),
              _StatusRowData('Docs readiness', 'On track', Color(0xFF2563EB)),
            ],
          ),
          _SectionData(
            title: 'Post-launch review',
            subtitle: 'Capture outcomes, lessons learned, and next-step backlog.',
            bullets: [
              _BulletData('KPIs baseline recorded', true),
              _BulletData('Lessons learned workshop scheduled', true),
              _BulletData('Backlog triage for enhancements', false),
            ],
            statusRows: [
              _StatusRowData('Review readiness', 'Scheduled', Color(0xFF2563EB)),
              _StatusRowData('Backlog triage', 'Queued', Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartUpPlanningSectionScreen extends StatelessWidget {
  const _StartUpPlanningSectionScreen({required this.config});

  final _StartUpPlanningSectionConfig config;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 20.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: InitiationLikeSidebar(activeItemLabel: config.activeItemLabel),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final gap = 24.0;
                        final twoCol = width >= 980;
                        final halfWidth = twoCol ? (width - gap) / 2 : width;
                        final hasContent = config.metrics.isNotEmpty || config.sections.isNotEmpty;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(title: config.title, onBack: () => Navigator.maybePop(context)),
                            const SizedBox(height: 12),
                            Text(
                              config.subtitle,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            PlanningAiNotesCard(
                              title: 'Notes',
                              sectionLabel: config.title,
                              noteKey: config.noteKey,
                              checkpoint: config.checkpoint,
                              description: 'Capture critical decisions, dependencies, and readiness updates.',
                            ),
                            const SizedBox(height: 24),
                            if (hasContent) ...[
                              _StartUpPlanningInputs(
                                sectionId: config.sectionId,
                                defaultMetrics: config.metrics,
                                defaultSections: config.sections,
                                cardWidth: halfWidth,
                                gap: gap,
                              ),
                              const SizedBox(height: 24),
                            ],
                            _WorldClassOpsEditor(
                              sectionTitle: config.title,
                              sectionId: config.sectionId,
                            ),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
                    ),
                  ),
                  const Positioned(right: 24, bottom: 24, child: KazAiChatBubble()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartUpPlanningSectionConfig {
  const _StartUpPlanningSectionConfig({
    required this.title,
    required this.subtitle,
    required this.noteKey,
    required this.checkpoint,
    required this.activeItemLabel,
    required this.sectionId,
    required this.metrics,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final String noteKey;
  final String checkpoint;
  final String activeItemLabel;
  final String sectionId;
  final List<_MetricData> metrics;
  final List<_SectionData> sections;
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        const _CircleIconButton(icon: Icons.arrow_forward_ios_rounded),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const Spacer(),
        const _UserChip(),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final email = user?.email ?? '';

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final role = isAdmin ? 'Admin' : 'Member';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                child: user?.photoURL == null
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(role, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF9CA3AF)),
            ],
          ),
        );
      },
    );
  }
}

class _StartUpPlanningInputs extends StatefulWidget {
  const _StartUpPlanningInputs({
    required this.sectionId,
    required this.defaultMetrics,
    required this.defaultSections,
    required this.cardWidth,
    required this.gap,
  });

  final String sectionId;
  final List<_MetricData> defaultMetrics;
  final List<_SectionData> defaultSections;
  final double cardWidth;
  final double gap;

  @override
  State<_StartUpPlanningInputs> createState() => _StartUpPlanningInputsState();
}

class _StartUpPlanningInputsState extends State<_StartUpPlanningInputs> {
  final _Debouncer _autosaveDebouncer = _Debouncer();
  bool _loading = true;
  bool _saving = false;
  bool _hydrating = true;
  DateTime? _lastSavedAt;
  List<_EditableMetric> _metrics = [];
  List<_EditableSection> _sections = [];

  static const _statusColors = [
    _StatusColorOption('Green', Color(0xFF10B981)),
    _StatusColorOption('Blue', Color(0xFF2563EB)),
    _StatusColorOption('Amber', Color(0xFFF59E0B)),
    _StatusColorOption('Red', Color(0xFFEF4444)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInputs());
  }

  @override
  void dispose() {
    _autosaveDebouncer.dispose();
    super.dispose();
  }

  Future<void> _loadInputs() async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      setState(() {
        _metrics = _seedMetrics(widget.defaultMetrics);
        _sections = _seedSections(widget.defaultSections);
        _loading = false;
        _hydrating = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('startup_planning_sections')
          .doc(widget.sectionId)
          .get();
      final data = doc.data() ?? {};
      final metricsRaw = data.containsKey('metrics') ? data['metrics'] : null;
      final sectionsRaw = data.containsKey('sections') ? data['sections'] : null;

      setState(() {
        _metrics = metricsRaw == null ? _seedMetrics(widget.defaultMetrics) : _decodeMetrics(metricsRaw);
        _sections = sectionsRaw == null ? _seedSections(widget.defaultSections) : _decodeSections(sectionsRaw);
        _lastSavedAt = _readTimestamp(data['updatedAt']);
        _loading = false;
        _hydrating = false;
      });
    } catch (error) {
      debugPrint('Failed to load start-up planning inputs: $error');
      setState(() {
        _metrics = _seedMetrics(widget.defaultMetrics);
        _sections = _seedSections(widget.defaultSections);
        _loading = false;
        _hydrating = false;
      });
    }
  }

  void _scheduleSave() {
    if (_hydrating) return;
    _autosaveDebouncer.run(_saveInputs);
  }

  Future<void> _saveInputs() async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) return;
    if (mounted) setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('startup_planning_sections')
          .doc(widget.sectionId)
          .set(
            {
              'metrics': _metrics.map((metric) => metric.toJson()).toList(),
              'sections': _sections.map((section) => section.toJson()).toList(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _lastSavedAt = DateTime.now();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save inputs: $error')),
      );
    }
  }

  List<_EditableMetric> _seedMetrics(List<_MetricData> defaults) {
    return defaults
        .map(
          (metric) => _EditableMetric(
            id: _slug(metric.label),
            label: metric.label,
            value: metric.value,
            color: metric.color,
          ),
        )
        .toList();
  }

  List<_EditableSection> _seedSections(List<_SectionData> defaults) {
    return defaults
        .map(
          (section) => _EditableSection(
            id: _slug(section.title),
            title: section.title,
            subtitle: section.subtitle,
            bullets: section.bullets
                .map((bullet) => _EditableBullet(id: _newId(), text: bullet.text, isCheck: bullet.isCheck))
                .toList(),
            statuses: section.statusRows
                .map((row) => _EditableStatus(id: _newId(), label: row.label, value: row.value, colorValue: row.color.value))
                .toList(),
          ),
        )
        .toList();
  }

  List<_EditableMetric> _decodeMetrics(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _EditableMetric(
        id: (data['id'] as String?) ?? _newId(),
        label: (data['label'] as String?) ?? '',
        value: (data['value'] as String?) ?? '',
        color: Color((data['color'] as num?)?.toInt() ?? const Color(0xFF2563EB).value),
      );
    }).toList();
  }

  List<_EditableSection> _decodeSections(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _EditableSection(
        id: (data['id'] as String?) ?? _newId(),
        title: (data['title'] as String?) ?? '',
        subtitle: (data['subtitle'] as String?) ?? '',
        bullets: _decodeBullets(data['bullets']),
        statuses: _decodeStatuses(data['statuses']),
      );
    }).toList();
  }

  List<_EditableBullet> _decodeBullets(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _EditableBullet(
        id: (data['id'] as String?) ?? _newId(),
        text: (data['text'] as String?) ?? '',
        isCheck: (data['isCheck'] as bool?) ?? false,
      );
    }).toList();
  }

  List<_EditableStatus> _decodeStatuses(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _EditableStatus(
        id: (data['id'] as String?) ?? _newId(),
        label: (data['label'] as String?) ?? '',
        value: (data['value'] as String?) ?? '',
        colorValue: (data['color'] as num?)?.toInt() ?? const Color(0xFF2563EB).value,
      );
    }).toList();
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  String _slug(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    return slug.isEmpty ? _newId() : slug;
  }

  DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  void _addMetric() {
    setState(() {
      _metrics.add(
        _EditableMetric(
          id: _newId(),
          label: 'New metric',
          value: '',
          color: const Color(0xFF2563EB),
        ),
      );
    });
    _scheduleSave();
  }

  void _removeMetric(int index) {
    setState(() => _metrics.removeAt(index));
    _scheduleSave();
  }

  void _addSection() {
    setState(() {
      _sections.add(
        _EditableSection(
          id: _newId(),
          title: 'New section',
          subtitle: '',
          bullets: [_EditableBullet(id: _newId(), text: '', isCheck: false)],
          statuses: [],
        ),
      );
    });
    _scheduleSave();
  }

  void _removeSection(int index) {
    setState(() => _sections.removeAt(index));
    _scheduleSave();
  }

  @override
  Widget build(BuildContext context) {
    final statusPills = <Widget>[];
    if (_saving) {
      statusPills.add(const _StatusPill(label: 'Saving...', color: Color(0xFF64748B), background: Color(0xFFE2E8F0)));
    } else if (_lastSavedAt != null) {
      statusPills.add(
        _StatusPill(
          label: 'Saved ${TimeOfDay.fromDateTime(_lastSavedAt!).format(context)}',
          color: const Color(0xFF16A34A),
          background: const Color(0xFFECFDF3),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Operational inputs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            Wrap(spacing: 8, runSpacing: 8, children: statusPills),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Wrap(
          spacing: widget.gap,
          runSpacing: widget.gap,
          children: [
            for (var i = 0; i < _metrics.length; i++)
              SizedBox(
                width: 190,
                child: _MetricInputCard(
                  metric: _metrics[i],
                  onChanged: (updated) {
                    setState(() => _metrics[i] = updated);
                    _scheduleSave();
                  },
                  onRemove: _metrics.length > 1 ? () => _removeMetric(i) : null,
                ),
              ),
            SizedBox(
              width: 190,
              child: _MetricAddCard(onPressed: _addMetric),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: widget.gap,
          runSpacing: widget.gap,
          children: [
            for (var i = 0; i < _sections.length; i++)
              SizedBox(
                width: widget.cardWidth,
                child: _EditableSectionCard(
                  section: _sections[i],
                  statusColors: _statusColors,
                  onRemove: _sections.length > 1 ? () => _removeSection(i) : null,
                  onSectionChanged: (updated) {
                    setState(() => _sections[i] = updated);
                    _scheduleSave();
                  },
                ),
              ),
            SizedBox(
              width: widget.cardWidth,
              child: _AddSectionCard(onPressed: _addSection),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _EditableMetric {
  _EditableMetric({
    required this.id,
    required this.label,
    required this.value,
    required this.color,
  });

  final String id;
  String label;
  String value;
  Color color;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'value': value,
      'color': color.value,
    };
  }
}

class _EditableSection {
  _EditableSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.statuses,
  });

  final String id;
  String title;
  String subtitle;
  List<_EditableBullet> bullets;
  List<_EditableStatus> statuses;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'bullets': bullets.map((bullet) => bullet.toJson()).toList(),
      'statuses': statuses.map((status) => status.toJson()).toList(),
    };
  }
}

class _EditableBullet {
  _EditableBullet({
    required this.id,
    required this.text,
    required this.isCheck,
  });

  final String id;
  String text;
  bool isCheck;

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'isCheck': isCheck};
}

class _EditableStatus {
  _EditableStatus({
    required this.id,
    required this.label,
    required this.value,
    required this.colorValue,
  });

  final String id;
  String label;
  String value;
  int colorValue;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'value': value,
        'color': colorValue,
      };
}

class _StatusColorOption {
  const _StatusColorOption(this.label, this.color);

  final String label;
  final Color color;
}

class _MetricInputCard extends StatelessWidget {
  const _MetricInputCard({
    required this.metric,
    required this.onChanged,
    this.onRemove,
  });

  final _EditableMetric metric;
  final ValueChanged<_EditableMetric> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: metric.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('Metric', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const Spacer(),
              if (onRemove != null)
                InkWell(
                  onTap: onRemove,
                  child: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('metric-label-${metric.id}'),
            initialValue: metric.label,
            decoration: const InputDecoration(
              hintText: 'Label',
              isDense: true,
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            onChanged: (value) => onChanged(
              _EditableMetric(id: metric.id, label: value.trim(), value: metric.value, color: metric.color),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey('metric-value-${metric.id}'),
            initialValue: metric.value,
            decoration: const InputDecoration(
              hintText: 'Value',
              isDense: true,
              border: InputBorder.none,
            ),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: metric.color),
            onChanged: (value) => onChanged(
              _EditableMetric(id: metric.id, label: metric.label, value: value.trim(), color: metric.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricAddCard extends StatelessWidget {
  const _MetricAddCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF6B7280)),
              SizedBox(height: 6),
              Text('Add metric', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableSectionCard extends StatelessWidget {
  const _EditableSectionCard({
    required this.section,
    required this.statusColors,
    required this.onSectionChanged,
    this.onRemove,
  });

  final _EditableSection section;
  final List<_StatusColorOption> statusColors;
  final ValueChanged<_EditableSection> onSectionChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('section-title-${section.id}'),
                  initialValue: section.title,
                  decoration: const InputDecoration(
                    hintText: 'Section title',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  onChanged: (value) {
                    section.title = value.trim();
                    onSectionChanged(section);
                  },
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                  onPressed: onRemove,
                ),
            ],
          ),
          TextFormField(
            key: ValueKey('section-subtitle-${section.id}'),
            initialValue: section.subtitle,
            decoration: const InputDecoration(
              hintText: 'Subtitle or guidance',
              isDense: true,
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
            onChanged: (value) {
              section.subtitle = value.trim();
              onSectionChanged(section);
            },
          ),
          const SizedBox(height: 14),
          const Text('Key checkpoints', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          for (var i = 0; i < section.bullets.length; i++)
            _BulletInputRow(
              bullet: section.bullets[i],
              onChanged: (updated) {
                section.bullets[i] = updated;
                onSectionChanged(section);
              },
              onRemove: section.bullets.length > 1
                  ? () {
                      section.bullets.removeAt(i);
                      onSectionChanged(section);
                    }
                  : null,
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              section.bullets.add(_EditableBullet(id: DateTime.now().microsecondsSinceEpoch.toString(), text: '', isCheck: false));
              onSectionChanged(section);
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add checkpoint'),
          ),
          const SizedBox(height: 12),
          const Text('Status signals', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          for (var i = 0; i < section.statuses.length; i++)
            _StatusInputRow(
              status: section.statuses[i],
              options: statusColors,
              onChanged: (updated) {
                section.statuses[i] = updated;
                onSectionChanged(section);
              },
              onRemove: section.statuses.length > 1
                  ? () {
                      section.statuses.removeAt(i);
                      onSectionChanged(section);
                    }
                  : null,
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              section.statuses.add(
                _EditableStatus(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  label: '',
                  value: '',
                  colorValue: statusColors.first.color.value,
                ),
              );
              onSectionChanged(section);
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add status'),
          ),
        ],
      ),
    );
  }
}

class _BulletInputRow extends StatelessWidget {
  const _BulletInputRow({
    required this.bullet,
    required this.onChanged,
    this.onRemove,
  });

  final _EditableBullet bullet;
  final ValueChanged<_EditableBullet> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: bullet.isCheck,
            onChanged: (value) => onChanged(
              _EditableBullet(id: bullet.id, text: bullet.text, isCheck: value ?? false),
            ),
          ),
          Expanded(
            child: TextFormField(
              key: ValueKey('bullet-${bullet.id}'),
              initialValue: bullet.text,
              decoration: const InputDecoration(
                hintText: 'Describe the checkpoint',
                isDense: true,
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4),
              onChanged: (value) => onChanged(
                _EditableBullet(id: bullet.id, text: value.trim(), isCheck: bullet.isCheck),
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF)),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _StatusInputRow extends StatelessWidget {
  const _StatusInputRow({
    required this.status,
    required this.options,
    required this.onChanged,
    this.onRemove,
  });

  final _EditableStatus status;
  final List<_StatusColorOption> options;
  final ValueChanged<_EditableStatus> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('status-label-${status.id}'),
              initialValue: status.label,
              decoration: const InputDecoration(
                hintText: 'Label',
                isDense: true,
                border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (value) => onChanged(
                _EditableStatus(
                  id: status.id,
                  label: value.trim(),
                  value: status.value,
                  colorValue: status.colorValue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('status-value-${status.id}'),
              initialValue: status.value,
              decoration: const InputDecoration(
                hintText: 'Value',
                isDense: true,
                border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (value) => onChanged(
                _EditableStatus(
                  id: status.id,
                  label: status.label,
                  value: value.trim(),
                  colorValue: status.colorValue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: status.colorValue,
              items: options
                  .map(
                    (option) => DropdownMenuItem<int>(
                      value: option.color.value,
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: option.color, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(option.label, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                onChanged(
                  _EditableStatus(
                    id: status.id,
                    label: status.label,
                    value: status.value,
                    colorValue: value,
                  ),
                );
              },
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF)),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _AddSectionCard extends StatelessWidget {
  const _AddSectionCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF6B7280)),
              SizedBox(height: 6),
              Text('Add section', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionData {
  const _SectionData({
    required this.title,
    required this.subtitle,
    this.bullets = const [],
    this.statusRows = const [],
  });

  final String title;
  final String subtitle;
  final List<_BulletData> bullets;
  final List<_StatusRowData> statusRows;
}

class _BulletData {
  const _BulletData(this.text, this.isCheck);

  final String text;
  final bool isCheck;
}

class _StatusRowData {
  const _StatusRowData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _AttachmentMeta {
  const _AttachmentMeta({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.extension,
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadedAt,
  });

  final String id;
  final String name;
  final int sizeBytes;
  final String extension;
  final String storagePath;
  final String downloadUrl;
  final DateTime uploadedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sizeBytes': sizeBytes,
      'extension': extension,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
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
