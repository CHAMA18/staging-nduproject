// ignore_for_file: unused_element

import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:ndu_project/models/design_phase_models.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/design_phase_service.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';
import 'package:ndu_project/screens/development_set_up_screen.dart';
import 'package:ndu_project/screens/technical_alignment_screen.dart';
import 'package:ndu_project/screens/ui_ux_design_screen.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/design_phase_stable_shell.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/requirements_traceability_dashboard.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class RequirementsImplementationScreen extends StatefulWidget {
  const RequirementsImplementationScreen({super.key});

  @override
  State<RequirementsImplementationScreen> createState() =>
      _RequirementsImplementationScreenState();
}

class _RequirementsImplementationScreenState
    extends State<RequirementsImplementationScreen> {
  final TextEditingController _notesController = TextEditingController();
  Timer? _saveDebounce;
  bool _isLoading = false;
  bool _suspendSave = false;
  bool _showAllRows = false;
  int _selectedRequirementIndex = 0;
  String _sectionApprovalStatus = 'Draft';
  final TextEditingController _sectionApprovedByController =
      TextEditingController();
  final TextEditingController _sectionApprovalDateController =
      TextEditingController();
  final TextEditingController _sectionApprovalNotesController =
      TextEditingController();
  final List<_DesignSpecDocumentRow> _documents = [];

  final List<RequirementRow> _requirementRows = [
    RequirementRow(
      requirementId: 'REQ-001',
      title: 'API endpoint authentication for partner booking sync',
      owner: 'Product',
      definition:
          'Trace the service entry point, failure states, and implementation handoff into the design pack.',
      requirementType: 'Functional',
      designArtifactType: 'Figma',
      designArtifactLabel: 'Figma service blueprint',
      validationStatus: 'Mapped',
      acceptanceCriteria:
          'Authentication states and fallback handling are visible in the approved design artifact.',
      testMethod: 'API walkthrough and contract review',
      sourceDocument: 'Contract clause 4.2',
      gapStatus: 'Closed',
    ),
    RequirementRow(
      requirementId: 'REQ-002',
      title: 'Venue capacity and circulation planning',
      owner: 'Engineering',
      definition:
          'Confirm that occupancy limits, movement flow, and physical safety logic are represented in the design controls.',
      requirementType: 'Non-Functional',
      designArtifactType: 'PDF',
      designArtifactLabel: 'Venue compliance PDF pack',
      validationStatus: 'Mapped',
      acceptanceCriteria:
          'Capacity thresholds, egress assumptions, and signage logic are documented and reviewable.',
      testMethod: 'Venue safety and operations review',
      sourceDocument: 'Safety schedule appendix B',
      gapStatus: 'Closed',
    ),
    RequirementRow(
      requirementId: 'REQ-003',
      title: 'Brand wallfinding package for main foyer',
      owner: 'Platform',
      definition:
          'Coordinate the brand expression, physical signage pack, and downstream fabrication notes.',
      requirementType: 'Non-Functional',
      designArtifactType: 'PDF',
      validationStatus: 'Unmapped',
      acceptanceCriteria:
          'Wayfinding hierarchy, material guidance, and review ownership are defined.',
      testMethod: 'Brand and venue coordination review',
      sourceDocument: 'Brand standards section 7',
      gapStatus: 'Pending Approval',
      conflictNote:
          'Brand requirements are still waiting for final venue dimensions.',
      conflictImpact: 'Low',
    ),
  ];

  // Checklist items with status
  final List<RequirementChecklistItem> _checklistItems = [
    RequirementChecklistItem(
      title: 'Key flows covered',
      description: 'All priority user journeys have mapped requirements.',
      status: ChecklistStatus.ready,
    ),
    RequirementChecklistItem(
      title: 'Constraints documented',
      description: 'Performance, security, and compliance captured.',
      status: ChecklistStatus.inReview,
    ),
    RequirementChecklistItem(
      title: 'Stakeholder sign-off',
      description: 'Product, design, and engineering alignment.',
      status: ChecklistStatus.pending,
    ),
  ];

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<RequirementRow> _dedupeRequirements(Iterable<RequirementRow> rows) {
    final seen = <String>{};
    final deduped = <RequirementRow>[];
    for (final row in rows) {
      final key =
          '${_normalize(row.requirementId)}|${_normalize(row.title)}|${_normalize(row.owner)}|${_normalize(row.definition)}';
      if (_normalize(row.title).isEmpty && _normalize(row.definition).isEmpty) {
        continue;
      }
      if (seen.add(key)) deduped.add(row);
    }
    return deduped;
  }

  List<RequirementChecklistItem> _dedupeChecklist(
      Iterable<RequirementChecklistItem> rows) {
    final seen = <String>{};
    final deduped = <RequirementChecklistItem>[];
    for (final row in rows) {
      final key =
          '${_normalize(row.title)}|${_normalize(row.description)}|${row.status.name}|${_normalize(row.owner ?? '')}';
      if (key == '|||') continue;
      if (seen.add(key)) deduped.add(row);
    }
    return deduped;
  }

  @override
  void initState() {
    super.initState();
    _notesController.addListener(_onNotesChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncAndLoad();
      if (!mounted) return;
      final provider = ProjectDataInherited.maybeOf(context);
      final pid = provider?.projectData.projectId;
      if (pid != null && pid.isNotEmpty) {
        await ProjectNavigationService.instance
            .saveLastPage(pid, 'requirements-implementation');
      }
    });
  }

  Future<void> _syncAndLoad() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;

    // 1. Auto-sync from scope first
    try {
      final addedCount = await DesignPhaseService.instance
          .syncRequirementsFromScope(projectId);
      if (addedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Synced $addedCount new requirements from Project Scope'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }

    // 2. Load data
    await _loadFromFirestore();
  }

  @override
  void dispose() {
    _notesController.removeListener(_onNotesChanged);
    _notesController.dispose();
    _sectionApprovedByController.dispose();
    _sectionApprovalDateController.dispose();
    _sectionApprovalNotesController.dispose();
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _onNotesChanged() {
    if (_suspendSave) return;
    _scheduleSave();
  }

  Future<void> _saveNotesNow() async {
    await _saveToFirestore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Requirements notes saved.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  Future<void> _loadFromFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final data = await DesignPhaseService.instance
          .loadRequirementsImplementation(projectId);

      _suspendSave = true;
      if (mounted) {
        setState(() {
          _notesController.text = data['notes']?.toString() ?? '';

          if (data['requirements'] != null) {
            final parsed = (data['requirements'] as List)
                .map((e) => RequirementRow.fromMap(e as Map<String, dynamic>));
            _requirementRows
              ..clear()
              ..addAll(_dedupeRequirements(parsed));
          }

          if (data['checklist'] != null) {
            final parsed = (data['checklist'] as List).map((e) =>
                RequirementChecklistItem.fromMap(e as Map<String, dynamic>));
            _checklistItems
              ..clear()
              ..addAll(_dedupeChecklist(parsed));
          }

          _sectionApprovalStatus =
              data['sectionApprovalStatus']?.toString() ?? 'Draft';
          _sectionApprovedByController.text =
              data['sectionApprovedBy']?.toString() ?? '';
          _sectionApprovalDateController.text =
              data['sectionApprovalDate']?.toString() ?? '';
          _sectionApprovalNotesController.text =
              data['sectionApprovalNotes']?.toString() ?? '';

          final rawDocuments = data['documents'];
          if (rawDocuments is List) {
            _documents
              ..clear()
              ..addAll(
                rawDocuments.whereType<Map>().map((item) =>
                    _DesignSpecDocumentRow.fromMap(
                        Map<String, dynamic>.from(item))),
              );
          } else {
            _documents.clear();
          }

          if (_selectedRequirementIndex >= _requirementRows.length) {
            _selectedRequirementIndex =
                _requirementRows.isEmpty ? 0 : _requirementRows.length - 1;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading requirements: $e');
    } finally {
      _suspendSave = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 1000), _saveToFirestore);
  }

  Future<void> _saveToFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;

    try {
      final dedupedRequirements = _dedupeRequirements(_requirementRows);
      final dedupedChecklist = _dedupeChecklist(_checklistItems);
      await DesignPhaseService.instance.saveRequirementsImplementation(
        projectId,
        notes: _notesController.text,
        requirements: dedupedRequirements,
        checklist: dedupedChecklist,
        documents: _documents.map((item) => item.toMap()).toList(),
        sectionApprovalStatus: _sectionApprovalStatus,
        sectionApprovedBy: _sectionApprovedByController.text.trim(),
        sectionApprovalDate: _sectionApprovalDateController.text.trim(),
        sectionApprovalNotes: _sectionApprovalNotesController.text.trim(),
      );
    } catch (e) {
      debugPrint('Error saving requirements: $e');
    }
  }

  void _navigateToDesignOverview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DesignPhaseScreen()),
    );
  }

  void _navigateToTechnicalAlignment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TechnicalAlignmentScreen()),
    );
  }

  List<String> _ownerOptions(ProjectDataModel projectData) {
    final names = <String>{
      ...projectData.teamMembers
          .map((member) => member.name.trim())
          .where((name) => name.isNotEmpty),
    };
    if (projectData.charterProjectManagerName.trim().isNotEmpty) {
      names.add(projectData.charterProjectManagerName.trim());
    }
    if (projectData.charterProjectSponsorName.trim().isNotEmpty) {
      names.add(projectData.charterProjectSponsorName.trim());
    }
    if (names.isEmpty) {
      names.addAll(const ['Unassigned', 'Design Lead', 'Technical Lead']);
    }
    final options = names.toList()..sort();
    return options;
  }

  String _buildRequirementId(int index) =>
      'REQ-${index.toString().padLeft(3, '0')}';

  int get _safeSelectedRequirementIndex {
    if (_requirementRows.isEmpty) return 0;
    if (_selectedRequirementIndex < 0) return 0;
    if (_selectedRequirementIndex >= _requirementRows.length) {
      return _requirementRows.length - 1;
    }
    return _selectedRequirementIndex;
  }

  void _selectRequirement(int index) {
    if (index < 0 || index >= _requirementRows.length) return;
    setState(() => _selectedRequirementIndex = index);
  }

  void _updateRequirement(
    int index,
    RequirementRow Function(RequirementRow current) update,
  ) {
    if (index < 0 || index >= _requirementRows.length) return;
    setState(() {
      _requirementRows[index] = update(_requirementRows[index]);
    });
    _scheduleSave();
  }

  void _updateSelectedRequirement(
      RequirementRow Function(RequirementRow current) update) {
    _updateRequirement(_safeSelectedRequirementIndex, update);
  }

  void _toggleShowAllRows() {
    setState(() => _showAllRows = !_showAllRows);
  }

  void _addRequirement(ProjectDataModel projectData) {
    final ownerOptions = _ownerOptions(projectData);
    final requirementIndex = _requirementRows.length + 1;
    setState(() {
      _requirementRows.add(
        RequirementRow(
          requirementId: _buildRequirementId(requirementIndex),
          title: 'New requirement',
          owner: ownerOptions.first,
          definition:
              'Describe the requirement intent, design dependency, and release constraints.',
          requirementType: 'Functional',
          ruleType: 'Internal',
          sourceType: 'Standard',
          designArtifactType: 'Figma',
          validationStatus: 'Unmapped',
          acceptanceCriteria:
              'Define measurable criteria for design and implementation sign-off.',
          testMethod: 'Design walkthrough',
          sourceDocument: 'Planning requirement register',
          gapStatus: 'Pending Approval',
          conflictImpact: 'Low',
        ),
      );
      _selectedRequirementIndex = _requirementRows.length - 1;
      _showAllRows = true;
    });
    _scheduleSave();
  }

  Future<void> _deleteRequirement(int index) async {
    if (index < 0 || index >= _requirementRows.length) return;
    final confirmed = await _confirmDelete('requirement');
    if (!confirmed) return;
    setState(() {
      _requirementRows.removeAt(index);
      if (_selectedRequirementIndex >= _requirementRows.length) {
        _selectedRequirementIndex =
            _requirementRows.isEmpty ? 0 : _requirementRows.length - 1;
      }
    });
    _scheduleSave();
  }

  void _showArtifactMessage(RequirementRow row) {
    final message = row.designArtifactUrl.trim().isNotEmpty
        ? '${row.designArtifactLabel} linked to ${row.designArtifactUrl}'
        : row.designArtifactLabel.trim().isNotEmpty
            ? '${row.designArtifactLabel} is captured as a ${row.designArtifactType} artifact.'
            : 'No design artifact has been linked yet.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0F172A),
      ),
    );
  }

  Future<void> _uploadArtifactForRequirement(RequirementRow row) async {
    final uploaded = await _pickAndUploadAttachment(
      folder: 'design-specifications',
    );
    if (uploaded == null || !mounted) return;
    final index = _requirementRows.indexWhere((item) => item.id == row.id);
    if (index == -1) return;
    setState(() {
      _requirementRows[index] = _requirementRows[index].copyWith(
        designArtifactUrl: uploaded.url,
        artifactStoragePath: uploaded.storagePath,
        artifactFileName: uploaded.name,
        artifactMimeType: uploaded.contentType,
        artifactSizeBytes: uploaded.sizeBytes,
      );
    });
    _scheduleSave();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Artifact uploaded and linked.')),
    );
  }

  Future<_UploadedDoc?> _pickAndUploadAttachment({
    required String folder,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Sign in is required before uploading files.')),
      );
      return null;
    }
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select a project before uploading.')),
      );
      return null;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowedExtensions: const [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'csv',
          'png',
          'jpg',
          'jpeg'
        ],
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Unable to read selected file.')),
        );
        return null;
      }
      final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final storagePath =
          'projects/$projectId/$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final ref = FirebaseStorage.instance.ref(storagePath);
      final metadata = SettableMetadata(
        contentType: _contentTypeForExtension(file.extension),
      );
      await ref.putData(bytes, metadata);
      final downloadUrl = await ref.getDownloadURL();
      return _UploadedDoc(
        name: file.name,
        url: downloadUrl,
        storagePath: storagePath,
        contentType: metadata.contentType ?? '',
        sizeBytes: file.size,
      );
    } on FirebaseException catch (error) {
      _showStorageUploadError(error.toString());
      return null;
    } catch (error) {
      _showStorageUploadError(error.toString());
      return null;
    }
  }

  void _showStorageUploadError(String rawError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to upload file: $rawError')),
    );
  }

  String _contentTypeForExtension(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
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
      case 'csv':
        return 'text/csv';
      case 'txt':
        return 'text/plain';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  bool get _isDesignSpecificationsSectionReady {
    if (_requirementRows.isEmpty) return false;
    final allRowsValid = _requirementRows.every((row) {
      final baseReady = row.title.trim().isNotEmpty &&
          row.owner.trim().isNotEmpty &&
          row.definition.trim().isNotEmpty &&
          row.ruleType.trim().isNotEmpty &&
          row.sourceType.trim().isNotEmpty;
      if (!baseReady) return false;
      if (row.validationStatus.trim().toLowerCase() == 'mapped') {
        return row.acceptanceCriteria.trim().isNotEmpty &&
            row.testMethod.trim().isNotEmpty;
      }
      return true;
    });
    if (!allRowsValid) return false;

    final hasPending = _requirementRows
        .any((row) => row.gapStatus.trim().toLowerCase() == 'pending approval');
    if (hasPending) return false;

    return _sectionApprovalStatus == 'In Review' ||
        _sectionApprovalStatus == 'Approved';
  }

  Future<void> _tryNavigateToTechnicalAlignment() async {
    if (_isDesignSpecificationsSectionReady) {
      _navigateToTechnicalAlignment();
      return;
    }
    final reasons = <String>[];
    if (_requirementRows.isEmpty) {
      reasons.add('Add at least one specification row.');
    }
    final incompleteBasics = _requirementRows.where((row) =>
        row.title.trim().isEmpty ||
        row.owner.trim().isEmpty ||
        row.definition.trim().isEmpty ||
        row.ruleType.trim().isEmpty ||
        row.sourceType.trim().isEmpty);
    if (incompleteBasics.isNotEmpty) {
      reasons.add(
          'Complete required fields (title, owner, definition, rule/source type).');
    }
    final mappedMissingEvidence = _requirementRows.where((row) =>
        row.validationStatus.trim().toLowerCase() == 'mapped' &&
        (row.acceptanceCriteria.trim().isEmpty ||
            row.testMethod.trim().isEmpty));
    if (mappedMissingEvidence.isNotEmpty) {
      reasons.add(
          'Mapped items must include acceptance criteria and test method.');
    }
    if (_requirementRows.any(
        (row) => row.gapStatus.trim().toLowerCase() == 'pending approval')) {
      reasons.add('Resolve pending approval gaps before continuing.');
    }
    if (!(_sectionApprovalStatus == 'In Review' ||
        _sectionApprovalStatus == 'Approved')) {
      reasons.add('Set section approval status to In Review or Approved.');
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Design Specifications Incomplete'),
        content: Text(reasons.join('\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addDocumentRow() {
    setState(() => _documents.add(_DesignSpecDocumentRow()));
    _scheduleSave();
  }

  void _updateDocumentRow(int index,
      _DesignSpecDocumentRow Function(_DesignSpecDocumentRow row) update) {
    if (index < 0 || index >= _documents.length) return;
    setState(() => _documents[index] = update(_documents[index]));
    _scheduleSave();
  }

  Future<void> _uploadDocumentRow(int index) async {
    if (index < 0 || index >= _documents.length) return;
    final uploaded = await _pickAndUploadAttachment(folder: 'design-spec-docs');
    if (uploaded == null) return;
    _updateDocumentRow(
      index,
      (row) => row.copyWith(
        link: uploaded.url,
        storagePath: uploaded.storagePath,
        fileName: uploaded.name,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document uploaded.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 16.0 : 40.0;
    final provider = ProjectDataInherited.maybeOf(context);
    final projectData = provider?.projectData ?? ProjectDataModel();
    final ownerOptions = _ownerOptions(projectData);
    final selectedRequirement = _requirementRows.isEmpty
        ? null
        : _requirementRows[_safeSelectedRequirementIndex];

    if (kIsWeb) {
      return _buildStableWebScreen(
        horizontalPadding: horizontalPadding,
        projectData: projectData,
      );
    }

    return ResponsiveScaffold(
      activeItemLabel: 'Design Specifications',
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Design Specifications',
            showImportButton: false,
            showContentButton: false,
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Color(0xFFE5E7EB),
              color: Color(0xFF1D4ED8),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main content area
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionApprovalCard(ownerOptions),
                        const SizedBox(height: 16),
                        RequirementsTraceabilityDashboard(
                          projectData: projectData,
                          requirements: _requirementRows,
                          checklistItems: _checklistItems,
                          ownerOptions: ownerOptions,
                          notesController: _notesController,
                          selectedRequirementIndex:
                              _safeSelectedRequirementIndex,
                          selectedRequirement: selectedRequirement,
                          showAllRows: _showAllRows,
                          onAddRequirement: () => _addRequirement(projectData),
                          onRefreshContext: _syncAndLoad,
                          onToggleShowAll: _toggleShowAllRows,
                          onSelectRequirement: _selectRequirement,
                          onDeleteRequirement: _deleteRequirement,
                          onArtifactTap: _showArtifactMessage,
                          onUpdateSelectedRequirement:
                              _updateSelectedRequirement,
                          onUploadArtifact: _uploadArtifactForRequirement,
                        ),
                        const SizedBox(height: 16),
                        _buildDocumentsRegister(ownerOptions),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  LaunchPhaseNavigation(
                    backLabel: 'Back: Design Management',
                    nextLabel: 'Next: Technical Alignment',
                    onBack: _navigateToDesignOverview,
                    onNext: _tryNavigateToTechnicalAlignment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionApprovalCard(List<String> ownerOptions) {
    final approverOptions = <String>{
      ...ownerOptions,
      if (_sectionApprovedByController.text.trim().isNotEmpty)
        _sectionApprovedByController.text.trim(),
    }.toList()
      ..sort();
    final selectedApprover = _sectionApprovedByController.text.trim();
    final effectiveApprover = approverOptions.contains(selectedApprover)
        ? selectedApprover
        : (approverOptions.isEmpty ? '' : approverOptions.first);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Design Specifications Approval',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Section-level approval is required before continuing to Technical Alignment.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sectionApprovalStatus,
                  decoration: const InputDecoration(
                    labelText: 'Approval Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const ['Draft', 'In Review', 'Approved']
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _sectionApprovalStatus = value);
                    _scheduleSave();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue:
                      effectiveApprover.isEmpty ? null : effectiveApprover,
                  decoration: const InputDecoration(
                    labelText: 'Approved By',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: approverOptions
                      .map((owner) => DropdownMenuItem(
                            value: owner,
                            child: Text(owner),
                          ))
                      .toList(),
                  onChanged: (value) {
                    _sectionApprovedByController.text = value ?? '';
                    _scheduleSave();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _sectionApprovalDateController,
                  onChanged: (_) => _scheduleSave(),
                  decoration: const InputDecoration(
                    labelText: 'Approval Date',
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sectionApprovalNotesController,
            onChanged: (_) => _scheduleSave(),
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Approval Notes',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsRegister(List<String> ownerOptions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Documents & Links Register',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: _addDocumentRow,
                icon: const Icon(Icons.add),
                label: const Text('Add document'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_documents.isEmpty)
            const Text(
              'No documents added yet.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          for (var i = 0; i < _documents.length; i++) ...[
            const SizedBox(height: 10),
            _buildDocumentRow(i, _documents[i], ownerOptions),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentRow(
      int index, _DesignSpecDocumentRow row, List<String> ownerOptions) {
    final options = <String>{
      ...ownerOptions,
      if (row.owner.trim().isNotEmpty) row.owner.trim(),
    }.toList()
      ..sort();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: row.name,
                  onChanged: (value) => _updateDocumentRow(
                      index, (current) => current.copyWith(name: value)),
                  decoration: const InputDecoration(
                    labelText: 'Document Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: row.category,
                  onChanged: (value) => _updateDocumentRow(
                      index, (current) => current.copyWith(category: value)),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: row.version,
                  onChanged: (value) => _updateDocumentRow(
                      index, (current) => current.copyWith(version: value)),
                  decoration: const InputDecoration(
                    labelText: 'Version',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: options.contains(row.owner) ? row.owner : null,
                  decoration: const InputDecoration(
                    labelText: 'Owner',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: options
                      .map((owner) =>
                          DropdownMenuItem(value: owner, child: Text(owner)))
                      .toList(),
                  onChanged: (value) => _updateDocumentRow(
                    index,
                    (current) => current.copyWith(owner: value ?? ''),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: row.linkedSpecId,
                  onChanged: (value) => _updateDocumentRow(index,
                      (current) => current.copyWith(linkedSpecId: value)),
                  decoration: const InputDecoration(
                    labelText: 'Linked Spec ID',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: row.status,
                  onChanged: (value) => _updateDocumentRow(
                      index, (current) => current.copyWith(status: value)),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: row.link,
                  onChanged: (value) => _updateDocumentRow(
                      index, (current) => current.copyWith(link: value)),
                  decoration: const InputDecoration(
                    labelText: 'Link / Uploaded URL',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _uploadDocumentRow(index),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() => _documents.removeAt(index));
                  _scheduleSave();
                },
                icon:
                    const Icon(Icons.delete_outline, color: Color(0xFFB91C1C)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStableWebScreen({
    required double horizontalPadding,
    required ProjectDataModel projectData,
  }) {
    final closedCount = _requirementRows
        .where((row) => row.gapStatus.toLowerCase() == 'closed')
        .length;
    final pendingCount = _requirementRows.length - closedCount;

    return DesignPhaseStableShell(
      activeLabel: 'Design Specifications',
      onItemSelected: _openStableDesignItem,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          24,
          horizontalPadding,
          32,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _navigateToDesignOverview,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Design Specifications',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Stable web mode is active so the design specifications workspace remains visible while the heavier dashboard layout is isolated.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStableMetricCard(
                'Requirements',
                '${_requirementRows.length}',
                const Color(0xFF1D4ED8),
              ),
              _buildStableMetricCard(
                'Closed',
                '$closedCount',
                const Color(0xFF0F766E),
              ),
              _buildStableMetricCard(
                'Pending',
                '$pendingCount',
                const Color(0xFFD97706),
              ),
              _buildStableMetricCard(
                'Owners',
                '${_ownerOptions(projectData).length}',
                const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStableSectionCard(
            title: 'Current Requirements Snapshot',
            child: Column(
              children: _requirementRows.take(6).map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${row.requirementId} · ${row.title}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          row.definition,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildTag('Owner: ${row.owner}'),
                            _buildTag('Status: ${row.gapStatus}'),
                            _buildTag('Validation: ${row.validationStatus}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildStableSectionCard(
            title: 'Working Notes',
            child: TextField(
              controller: _notesController,
              minLines: 8,
              maxLines: 14,
              decoration: const InputDecoration(
                hintText:
                    'Capture implementation notes, handoff decisions, and traceability comments...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: _navigateToDesignOverview,
                child: const Text('Back: Design Management'),
              ),
              ElevatedButton(
                onPressed: _saveNotesNow,
                child: const Text('Save Notes'),
              ),
              ElevatedButton(
                onPressed: _tryNavigateToTechnicalAlignment,
                child: const Text('Next: Technical Alignment'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openStableDesignItem(String label) {
    Widget? destination;
    switch (label) {
      case 'Design Management':
        destination =
            const DesignPhaseScreen(activeItemLabel: 'Design Management');
        break;
      case 'Design Specifications':
        destination = const RequirementsImplementationScreen();
        break;
      case 'Technical Alignment':
        destination = const TechnicalAlignmentScreen();
        break;
      case 'Development Set Up':
        destination = const DevelopmentSetUpScreen();
        break;
      case 'UI/UX Design':
        destination = const UiUxDesignScreen();
        break;
    }

    if (destination == null) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination!),
    );
  }

  Widget _buildStableMetricCard(String label, String value, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStableSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D4ED8),
        ),
      ),
    );
  }

  Widget _buildRequirementsBreakdownCard(List<String> ownerOptions) {
    final rowCount = _requirementRows.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionIcon(
                  Icons.view_list_rounded, const Color(0xFF1D4ED8)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Requirements breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'World-class requirements ledger for implementation-ready scope.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _requirementRows.add(
                      RequirementRow(
                        title: 'New requirement',
                        owner: 'Owner',
                        definition: 'Define acceptance criteria and evidence.',
                      ),
                    );
                    _scheduleSave();
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add row'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1D4ED8),
                  side: const BorderSide(color: Color(0xFFD6DCE8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Requirement group', flex: 3),
              _TableColumn(label: 'Owner', flex: 2),
              _TableColumn(label: 'Definition of ready', flex: 4),
              _TableColumn(
                  label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < rowCount; i++) ...[
            _buildRequirementRow(
              _requirementRows[i],
              index: i,
              isStriped: i.isOdd,
              ownerOptions: ownerOptions,
            ),
            if (i != rowCount - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _requirementRows.add(
                      RequirementRow(
                        title: 'New requirement',
                        owner: 'Owner',
                        definition: 'Define acceptance criteria and evidence.',
                      ),
                    );
                    _scheduleSave();
                  });
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add requirement row'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1D1F),
                  side: const BorderSide(color: Color(0xFFD6DCE8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: _syncAndLoad,
                icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                label: const Text('Refresh from context'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessChecklistCard(List<String> ownerOptions) {
    final rowCount = _checklistItems.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionIcon(
                  Icons.fact_check_outlined, const Color(0xFF16A34A)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Readiness checklist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Exceptional readiness table for confident technical alignment.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _checklistItems.add(
                      RequirementChecklistItem(
                        title: 'New checklist item',
                        description: 'Describe the evidence required.',
                        status: ChecklistStatus.pending,
                      ),
                    );
                    _scheduleSave();
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add item'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16A34A),
                  side: const BorderSide(color: Color(0xFFD6DCE8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Checklist item', flex: 4),
              _TableColumn(label: 'Owner', flex: 2),
              _TableColumn(label: 'Status', flex: 2),
              _TableColumn(
                  label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < rowCount; i++) ...[
            _buildChecklistRow(
              _checklistItems[i],
              index: i,
              isStriped: i.isOdd,
              ownerOptions: ownerOptions,
            ),
            if (i != rowCount - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          Text(
            'Implementation notes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            maxLines: null,
            minLines: 3,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
            decoration: InputDecoration(
              hintText:
                  'Capture sequencing decisions, launch scope, and deferred items.',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF16A34A), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _saveNotesNow,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save notes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A1D1F),
                side: const BorderSide(color: Color(0xFFD6DCE8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionIcon(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildTableHeaderRow({required List<_TableColumn> columns}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          for (final column in columns)
            Expanded(
              flex: column.flex,
              child: Align(
                alignment: column.alignment,
                child: Text(
                  column.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(
    RequirementRow row, {
    required int index,
    required bool isStriped,
    required List<String> ownerOptions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStriped ? const Color(0xFFF9FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildTableField(
              initialValue: row.title,
              hintText: 'Requirement group',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildOwnerDropdown(
              value: row.owner,
              options: ownerOptions,
              onChanged: (value) {
                setState(() {
                  _requirementRows[index].owner = value;
                  _scheduleSave();
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: _buildTableField(
              initialValue: row.definition,
              hintText: 'Definition of ready',
              maxLines: null,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () async {
                  final confirmed = await _confirmDelete('requirement');
                  if (!confirmed) return;
                  setState(() {
                    _requirementRows.removeAt(index);
                    _scheduleSave();
                  });
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(
    RequirementChecklistItem item, {
    required int index,
    required bool isStriped,
    required List<String> ownerOptions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStriped ? const Color(0xFFF9FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTableField(
                  initialValue: item.title,
                  hintText: 'Checklist item',
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildOwnerDropdown(
              value: item.owner ?? '',
              options: ownerOptions,
              onChanged: (value) {
                setState(() {
                  _checklistItems[index].owner = value;
                  _scheduleSave();
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<ChecklistStatus>(
              initialValue: item.status,
              alignment: Alignment.center,
              isExpanded: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              selectedItemBuilder: (context) => ChecklistStatus.values
                  .map(
                    (status) => Align(
                      alignment: Alignment.center,
                      child: Text(_statusLabel(status),
                          textAlign: TextAlign.center),
                    ),
                  )
                  .toList(),
              items: ChecklistStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Center(
                        child: Text(_statusLabel(status),
                            textAlign: TextAlign.center),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _checklistItems[index].status = value;
                  _scheduleSave();
                });
              },
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF16A34A), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () async {
                  final confirmed = await _confirmDelete('checklist item');
                  if (!confirmed) return;
                  setState(() {
                    _checklistItems.removeAt(index);
                    _scheduleSave();
                  });
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableField({
    required String initialValue,
    required String hintText,
    int? maxLines,
    int minLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: TextInputType.multiline,
      textAlign: TextAlign.start,
      textAlignVertical: TextAlignVertical.top,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
        ),
      ),
    );
  }

  Widget _buildOwnerDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final normalized = value.trim();
    final items = normalized.isEmpty || options.contains(normalized)
        ? options
        : [normalized, ...options];
    return DropdownButtonFormField<String>(
      initialValue: items.first,
      alignment: Alignment.center,
      isExpanded: true,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      selectedItemBuilder: (context) => items
          .map((owner) => Align(
                alignment: Alignment.center,
                child: Text(owner, textAlign: TextAlign.center),
              ))
          .toList(),
      items: items
          .map((owner) => DropdownMenuItem(
                value: owner,
                child: Center(child: Text(owner, textAlign: TextAlign.center)),
              ))
          .toList(),
      onChanged: (newValue) {
        if (newValue == null) return;
        onChanged(newValue);
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(String label) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete row?'),
        content: Text('Remove this $label from the table?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFB91C1C)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  String _statusLabel(ChecklistStatus status) {
    switch (status) {
      case ChecklistStatus.ready:
        return 'Ready';
      case ChecklistStatus.inReview:
        return 'In review';
      case ChecklistStatus.pending:
        return 'Pending';
    }
  }
}

// End of _RequirementsImplementationScreenState

class _TableColumn {
  const _TableColumn({
    required this.label,
    this.flex = 1,
    this.alignment = Alignment.center,
  });

  final String label;
  final int flex;
  final Alignment alignment;
}

class _UploadedDoc {
  const _UploadedDoc({
    required this.name,
    required this.url,
    required this.storagePath,
    required this.contentType,
    required this.sizeBytes,
  });

  final String name;
  final String url;
  final String storagePath;
  final String contentType;
  final int sizeBytes;
}

class _DesignSpecDocumentRow {
  _DesignSpecDocumentRow({
    String? id,
    this.name = '',
    this.category = '',
    this.version = '',
    this.owner = '',
    this.linkedSpecId = '',
    this.link = '',
    this.status = 'Draft',
    this.fileName = '',
    this.storagePath = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  String name;
  String category;
  String version;
  String owner;
  String linkedSpecId;
  String link;
  String status;
  String fileName;
  String storagePath;

  _DesignSpecDocumentRow copyWith({
    String? name,
    String? category,
    String? version,
    String? owner,
    String? linkedSpecId,
    String? link,
    String? status,
    String? fileName,
    String? storagePath,
  }) {
    return _DesignSpecDocumentRow(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      version: version ?? this.version,
      owner: owner ?? this.owner,
      linkedSpecId: linkedSpecId ?? this.linkedSpecId,
      link: link ?? this.link,
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      storagePath: storagePath ?? this.storagePath,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'version': version,
        'owner': owner,
        'linkedSpecId': linkedSpecId,
        'link': link,
        'status': status,
        'fileName': fileName,
        'storagePath': storagePath,
      };

  factory _DesignSpecDocumentRow.fromMap(Map<String, dynamic> map) {
    return _DesignSpecDocumentRow(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      version: map['version']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      linkedSpecId: map['linkedSpecId']?.toString() ?? '',
      link: map['link']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
      fileName: map['fileName']?.toString() ?? '',
      storagePath: map['storagePath']?.toString() ?? '',
    );
  }
}
