import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:ndu_project/models/design_phase_models.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/download_helper.dart' as download_helper;
import 'package:ndu_project/utils/design_planning_document.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const Color _kPageBg = Color(0xFFF5F7FB);
const Color _kSurface = Colors.white;
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kText = Color(0xFF0F172A);
const Color _kMuted = Color(0xFF64748B);
const Color _kPrimary = Color(0xFF2563EB);
const Color _kPrimarySoft = Color(0xFFE8F0FF);
const Color _kSuccess = Color(0xFF0F9D58);
const Color _kWarning = Color(0xFFF59E0B);
const String _kSectionProgressNotesKey = 'planning_design_section_progress';

enum _SectionProgressState { pending, complete, notApplicable }

class DesignPlanningScreen extends StatefulWidget {
  const DesignPlanningScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DesignPlanningScreen()),
    );
  }

  @override
  State<DesignPlanningScreen> createState() => _DesignPlanningScreenState();
}

class _DesignPlanningScreenState extends State<DesignPlanningScreen> {
  static const _statusOptions = ['Draft', 'In Review', 'Approved'];
  static const _mappingStatusOptions = [
    'Draft',
    'Planned',
    'Active',
    'Blocked'
  ];
  static const _workStatusOptions = ['Draft', 'Planned', 'In Review', 'Ready'];
  static const _riskStatusOptions = ['Open', 'Monitoring', 'Closed'];
  static const _approvalStatusOptions = ['Pending', 'In Review', 'Approved'];
  static const _specRuleTypeOptions = ['Internal', 'External'];
  static const _specSourceTypeOptions = [
    'Contracts',
    'Vendors',
    'Regulatory',
    'Standards',
  ];
  static const _specificationTypeOptions = [
    'Code',
    'Law',
    'Standard',
    'Criteria',
    'Guideline',
    'Contract',
    'Other',
  ];
  static const _specDisciplineOptions = [
    'Architecture',
    'Civil',
    'Structural',
    'Geotechnical',
    'Mechanical (HVAC)',
    'Electrical',
    'Plumbing',
    'Fire Protection',
    'Survey / Geomatics',
    'Landscape',
    'Environmental',
    'Telecommunications / ICT',
    'Frontend',
    'Backend',
    'Full-Stack',
    'Data / Analytics',
    'Integration / APIs',
    'DevOps / Platform / SRE',
    'QA / Testing',
    'Cybersecurity',
    'IT / Infrastructure',
    'Operations',
    'Procurement',
    'Commercial / Contracts',
    'Quality / QA-QC',
    'Regulatory / Compliance',
    'Program / Project Management',
    'Safety / HSE',
  ];
  static const _specAreaOptions = [
    'General',
    'Design',
    'Construction',
    'Operations',
    'Security',
    'Compliance',
    'Testing',
    'Data',
    'Integration',
    'Quality',
    'Safety',
    'Environmental',
    'UI/UX',
    'Frontend',
    'Backend',
    'Infrastructure',
    'Procurement',
    'Commercial',
  ];
  static const _specRowStatusOptions = ['Draft', 'Planned', 'In Review'];
  static const _designAreaOptions = [
    'Architecture',
    'UI/UX',
    'Technical',
    'Data',
    'Security',
    'Validation',
  ];
  static const _dependencyTypeOptions = [
    'System',
    'Team',
    'Vendor',
    'Approval',
    'Tooling',
    'Data',
    'Interface',
  ];

  Future<void> _editVersion() async {
    final controller = TextEditingController(text: _document.version);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set document version'),
          content: TextField(
            controller: controller,
            decoration: _inputDecoration('e.g. v1.0, v1.2, v2.0'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (!mounted || updated == null || updated.isEmpty) return;
    setState(() => _document.version = updated);
    _queueSave();
  }

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {
    for (final section in _sectionOrder) section.id: GlobalKey(),
  };
  final Map<String, GlobalKey> _specificationRowKeys = {};
  Timer? _saveDebounce;
  bool _didInit = false;
  bool _saving = false;
  bool _pendingSave = false;
  DateTime? _lastSavedAt;
  final Map<String, bool> _aiGenerating = {};
  late Map<String, _SectionProgressState> _sectionProgress;
  late Map<String, bool> _sectionExpanded;
  late Map<String, int> _sectionTileVersion;
  String _activeSectionId = _sectionOrder.first.id;

  late DesignPlanningDocument _document;
  late TextEditingController _overviewController;
  late TextEditingController _designWhoController;
  late TextEditingController _designHowController;
  late TextEditingController _designVendorsController;
  late TextEditingController _designInterfacesController;
  late TextEditingController _objectivesController;
  late TextEditingController _successCriteriaController;
  late TextEditingController _scopeController;
  late TextEditingController _outOfScopeController;
  late TextEditingController _architectureController;
  late TextEditingController _diagramReferenceController;
  late TextEditingController _dataFlowController;
  late TextEditingController _uiUxController;
  late TextEditingController _designSystemController;
  late TextEditingController _technicalFrontendController;
  late TextEditingController _technicalBackendController;
  late TextEditingController _technicalDataController;
  late TextEditingController _constraintsController;
  late TextEditingController _assumptionsController;
  late TextEditingController _validationController;
  late TextEditingController _governanceController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    ApiKeyManager.initializeApiKey();
    final data = ProjectDataHelper.getData(context);
    _document = DesignPlanningDocument.fromProjectData(data);
    _overviewController =
        TextEditingController(text: _document.overviewSummary);
    _designWhoController =
        TextEditingController(text: _document.designWhoAndOwnership);
    _designHowController =
        TextEditingController(text: _document.designExecutionApproach);
    _designVendorsController =
        TextEditingController(text: _document.designVendorContractInputs);
    _designInterfacesController =
        TextEditingController(text: _document.designInterfacesAndConstraints);
    _objectivesController = TextEditingController(text: _document.objectives);
    _successCriteriaController =
        TextEditingController(text: _document.successCriteria);
    _scopeController = TextEditingController(text: _document.scope);
    _outOfScopeController = TextEditingController(text: _document.outOfScope);
    _architectureController =
        TextEditingController(text: _document.architectureSummary);
    _diagramReferenceController =
        TextEditingController(text: _document.diagramReference);
    _dataFlowController =
        TextEditingController(text: _document.dataFlowSummary);
    _uiUxController = TextEditingController(text: _document.uiUxSummary);
    _designSystemController =
        TextEditingController(text: _document.designSystemNotes);
    _technicalFrontendController =
        TextEditingController(text: _document.technicalFrontend);
    _technicalBackendController =
        TextEditingController(text: _document.technicalBackend);
    _technicalDataController =
        TextEditingController(text: _document.technicalData);
    _constraintsController =
        TextEditingController(text: _document.constraints.join('\n'));
    _assumptionsController =
        TextEditingController(text: _document.assumptions.join('\n'));
    _validationController =
        TextEditingController(text: _document.validationSummary);
    _governanceController =
        TextEditingController(text: _document.governanceNotes);
    _hydrateGuidedSectionState(data);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _scrollController.dispose();
    _overviewController.dispose();
    _designWhoController.dispose();
    _designHowController.dispose();
    _designVendorsController.dispose();
    _designInterfacesController.dispose();
    _objectivesController.dispose();
    _successCriteriaController.dispose();
    _scopeController.dispose();
    _outOfScopeController.dispose();
    _architectureController.dispose();
    _diagramReferenceController.dispose();
    _dataFlowController.dispose();
    _uiUxController.dispose();
    _designSystemController.dispose();
    _technicalFrontendController.dispose();
    _technicalBackendController.dispose();
    _technicalDataController.dispose();
    _constraintsController.dispose();
    _assumptionsController.dispose();
    _validationController.dispose();
    _governanceController.dispose();
    super.dispose();
  }

  Future<void> _scrollToSectionStart(String id) async {
    final firstContext = _sectionKeys[id]?.currentContext;
    if (firstContext == null || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final targetContext = _sectionKeys[id]?.currentContext;
    if (targetContext == null || !mounted || !targetContext.mounted) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
    // Re-run once after tile animation to keep the section header at the top.
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    final settleContext = _sectionKeys[id]?.currentContext;
    if (settleContext == null || !settleContext.mounted) return;
    await Scrollable.ensureVisible(
      settleContext,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
  }

  Future<void> _openSpecificationsAndScrollToRow(String rowId) async {
    if (!mounted) return;
    setState(() {
      _sectionExpanded['design_specifications_workspace'] = true;
      _sectionTileVersion['design_specifications_workspace'] =
          (_sectionTileVersion['design_specifications_workspace'] ?? 0) + 1;
      _activeSectionId = 'design_specifications_workspace';
    });
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    await _scrollToSectionStart('design_specifications_workspace');
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    final target = _specificationRowKeys[rowId]?.currentContext;
    if (target == null || !target.mounted) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
  }

  void _hydrateGuidedSectionState(ProjectDataModel data) {
    final progress = <String, _SectionProgressState>{
      for (final section in _sectionOrder)
        section.id: _SectionProgressState.pending,
    };
    final raw = data.planningNotes[_kSectionProgressNotesKey];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((key, value) {
            if (!progress.containsKey(key)) return;
            progress[key] = _parseProgressState(value?.toString());
          });
        }
      } catch (_) {
        // Keep defaults if progress payload is malformed.
      }
    }

    _sectionProgress = progress;
    _activeSectionId = _sectionOrder
        .firstWhere(
          (section) => !_isSectionResolved(section.id),
          orElse: () => _sectionOrder.first,
        )
        .id;
    _sectionExpanded = {
      for (final section in _sectionOrder)
        section.id: section.id == _activeSectionId,
    };
    _sectionTileVersion = {
      for (final section in _sectionOrder) section.id: 0,
    };
  }

  _SectionProgressState _parseProgressState(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'complete':
        return _SectionProgressState.complete;
      case 'notapplicable':
      case 'not_applicable':
        return _SectionProgressState.notApplicable;
      default:
        return _SectionProgressState.pending;
    }
  }

  String _encodeSectionProgress() {
    final payload = <String, String>{
      for (final section in _sectionOrder)
        section.id: _sectionProgress[section.id]!.name,
    };
    return jsonEncode(payload);
  }

  bool _isSectionResolved(String sectionId) =>
      _sectionProgress[sectionId] != _SectionProgressState.pending;

  bool _canOpenSection(String sectionId) {
    final targetIndex =
        _sectionOrder.indexWhere((section) => section.id == sectionId);
    if (targetIndex <= 0) return true;
    for (var i = 0; i < targetIndex; i++) {
      if (!_isSectionResolved(_sectionOrder[i].id)) return false;
    }
    return true;
  }

  String? _firstBlockingSectionLabel(String sectionId) {
    final targetIndex =
        _sectionOrder.indexWhere((section) => section.id == sectionId);
    if (targetIndex <= 0) return null;
    for (var i = 0; i < targetIndex; i++) {
      final id = _sectionOrder[i].id;
      if (!_isSectionResolved(id)) {
        return _sectionOrder[i].label;
      }
    }
    return null;
  }

  void _showLockedSectionFeedback(String sectionId) {
    final blocking = _firstBlockingSectionLabel(sectionId);
    _showToast(
      blocking == null
          ? 'Complete prior sections first.'
          : 'Complete or mark "$blocking" as not applicable before continuing.',
    );
  }

  Future<void> _activateSection(String sectionId) async {
    if (!_canOpenSection(sectionId)) {
      _showLockedSectionFeedback(sectionId);
      setState(() {
        _sectionExpanded = {
          for (final section in _sectionOrder)
            section.id: section.id == _activeSectionId,
        };
      });
      return;
    }
    setState(() {
      _activeSectionId = sectionId;
      _sectionExpanded = {
        for (final section in _sectionOrder)
          section.id: section.id == sectionId,
      };
    });
    await _scrollToSectionStart(sectionId);
  }

  Future<void> _onSectionExpansionChanged(
      String sectionId, bool expanded) async {
    if (!expanded) {
      setState(() => _sectionExpanded[sectionId] = false);
      return;
    }
    if (!_canOpenSection(sectionId)) {
      _showLockedSectionFeedback(sectionId);
      setState(() {
        _sectionExpanded[sectionId] = false;
        _sectionTileVersion[sectionId] =
            (_sectionTileVersion[sectionId] ?? 0) + 1;
      });
      return;
    }
    await _activateSection(sectionId);
  }

  Future<void> _setSectionProgress({
    required String sectionId,
    required _SectionProgressState state,
  }) async {
    final current =
        _sectionProgress[sectionId] ?? _SectionProgressState.pending;
    if (current == state) return;
    if (state == _SectionProgressState.complete &&
        (sectionId == 'requirements' ||
            sectionId == 'design_specifications_workspace')) {
      final requirementOptions =
          _requirementAttachmentOptions(ProjectDataHelper.getData(context));
      final missing = _unlinkedRequirements(requirementOptions);
      if (missing.isNotEmpty) {
        final preview = missing.take(3).map((item) => item.label).join(', ');
        _showToast(
          'Link specifications to all requirements first. '
          '${missing.length} requirement(s) still unlinked'
          '${preview.isEmpty ? '' : ': $preview'}',
        );
        return;
      }
    }
    if (state != _SectionProgressState.pending) {
      final confirmed = await _confirmStatusChange(state);
      if (!confirmed) return;
    }
    setState(() {
      _sectionProgress[sectionId] = state;
    });
    _queueSave();
  }

  Future<bool> _confirmStatusChange(_SectionProgressState state) async {
    final label = state == _SectionProgressState.complete
        ? 'mark this section as complete'
        : 'mark this section as not applicable';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Section Status'),
          content: Text('Are you sure you want to $label?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Widget _buildSectionProgressControls(String sectionId) {
    final state = _sectionProgress[sectionId] ?? _SectionProgressState.pending;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: state == _SectionProgressState.complete,
                onChanged: (checked) {
                  _setSectionProgress(
                    sectionId: sectionId,
                    state: checked == true
                        ? _SectionProgressState.complete
                        : _SectionProgressState.pending,
                  );
                },
              ),
              const Text('Complete'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: state == _SectionProgressState.notApplicable,
                onChanged: (checked) {
                  _setSectionProgress(
                    sectionId: sectionId,
                    state: checked == true
                        ? _SectionProgressState.notApplicable
                        : _SectionProgressState.pending,
                  );
                },
              ),
              const Text('Not applicable'),
            ],
          ),
        ],
      ),
    );
  }

  void _updateCoreFields() {
    _document.overviewSummary = _overviewController.text.trim();
    _document.designWhoAndOwnership = _designWhoController.text.trim();
    _document.designExecutionApproach = _designHowController.text.trim();
    _document.designVendorContractInputs = _designVendorsController.text.trim();
    _document.designInterfacesAndConstraints =
        _designInterfacesController.text.trim();
    _document.objectives = _objectivesController.text.trim();
    _document.successCriteria = _successCriteriaController.text.trim();
    _document.scope = _scopeController.text.trim();
    _document.outOfScope = _outOfScopeController.text.trim();
    _document.architectureSummary = _architectureController.text.trim();
    _document.diagramReference = _diagramReferenceController.text.trim();
    _document.dataFlowSummary = _dataFlowController.text.trim();
    _document.uiUxSummary = _uiUxController.text.trim();
    _document.designSystemNotes = _designSystemController.text.trim();
    _document.technicalFrontend = _technicalFrontendController.text.trim();
    _document.technicalBackend = _technicalBackendController.text.trim();
    _document.technicalData = _technicalDataController.text.trim();
    _document.constraints = _splitLines(_constraintsController.text);
    _document.assumptions = _splitLines(_assumptionsController.text);
    _document.validationSummary = _validationController.text.trim();
    _document.governanceNotes = _governanceController.text.trim();
  }

  void _queueSave() {
    _updateCoreFields();
    _document.touch();
    _saveDebounce?.cancel();
    _pendingSave = true;
    _saveDebounce = Timer(const Duration(milliseconds: 600), _saveDocument);
    if (mounted) setState(() {});
  }

  Future<void> _saveDocument() async {
    if (!mounted || _saving) return;
    _updateCoreFields();
    _document.touch();
    setState(() => _saving = true);
    final data = ProjectDataHelper.getData(context);
    final notesPatch = {
      ...data.planningNotes,
      ..._document.toPlanningNotesPatch(),
      _kSectionProgressNotesKey: _encodeSectionProgress(),
    };
    final riskPlans = {
      ...data.riskMitigationPlans,
      ..._document.toRiskMitigationPlans(),
    };
    final success = await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'design',
      showSnackbar: false,
      dataUpdater: (current) {
        final mappedMethodology =
            ProjectDataHelper.projectMethodologyFromOverallFramework(
          current.overallFramework,
        );
        final designManagementData = mappedMethodology == null
            ? current.designManagementData
            : (current.designManagementData ?? DesignManagementData()).copyWith(
                methodology: mappedMethodology,
              );

        return current.copyWith(
          planningNotes: notesPatch,
          planningRequirementItems: _document.toPlanningRequirementItems(),
          designDeliverablesData: _document
              .toDesignDeliverablesData(current.designDeliverablesData),
          withinScopeItems: _document.toScopeItems(),
          outOfScopeItems: _document.toOutOfScopeItems(),
          constraintItems: _document.toConstraintItems(),
          assumptionItems: _document.toAssumptionItems(),
          riskMitigationPlans: riskPlans,
          designManagementData: designManagementData,
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (success) {
        _pendingSave = false;
        _lastSavedAt = DateTime.now();
      }
    });
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addSpecificationRow() {
    setState(() {
      _document.specifications.add(
        DesignSpecificationPlanRow(
          specificationType: _specificationTypeOptions[2],
          sourceType: _specSourceTypeOptions.first,
          ruleType: _specRuleTypeOptions.first,
        ),
      );
    });
    _queueSave();
  }

  void _addDeviation() {
    setState(() {
      _document.deviations.add(DesignSpecificationDeviation());
    });
    _queueSave();
  }

  Future<void> _showSpecificationsTableDialog() async {
    final rows = _specificationOptions();
    final searchController = TextEditingController();
    var query = '';
    var disciplineFilter = 'All';
    var areaFilter = 'All';
    var typeFilter = 'All';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final disciplineOptions = _dedupeOptions([
              'All',
              ...rows.map((row) => row.discipline).where((e) => e.isNotEmpty),
            ]);
            final areaOptions = _dedupeOptions([
              'All',
              ...rows.map((row) => row.area).where((e) => e.isNotEmpty),
            ]);
            final typeOptions = _dedupeOptions([
              'All',
              ...rows
                  .map((row) => row.specificationType)
                  .where((e) => e.isNotEmpty),
            ]);

            final filteredRows = rows.where((row) {
              final haystack = [
                row.title,
                row.details,
                row.discipline,
                row.area,
                row.specificationType,
                row.sourceType,
                row.owner,
                row.status,
                row.wbsWorkPackageTitle,
              ].join(' ').toLowerCase();
              final matchesQuery = query.isEmpty ||
                  haystack.contains(query.toLowerCase().trim());
              final matchesDiscipline = disciplineFilter == 'All' ||
                  row.discipline == disciplineFilter;
              final matchesArea = areaFilter == 'All' || row.area == areaFilter;
              final matchesType =
                  typeFilter == 'All' || row.specificationType == typeFilter;
              return matchesQuery &&
                  matchesDiscipline &&
                  matchesArea &&
                  matchesType;
            }).toList(growable: false);

            return AlertDialog(
              title: const Text('Specifications Table'),
              content: SizedBox(
                width: 1320,
                child: rows.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No specification rows available.',
                          style: TextStyle(color: _kMuted),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FourColumnGrid(
                            children: [
                              TextField(
                                controller: searchController,
                                decoration:
                                    _inputDecoration('Search specifications'),
                                onChanged: (value) {
                                  setDialogState(() => query = value);
                                },
                              ),
                              _DropdownField(
                                value: disciplineFilter,
                                label: 'Discipline',
                                options: disciplineOptions,
                                onChanged: (value) => setDialogState(
                                    () => disciplineFilter = value),
                              ),
                              _DropdownField(
                                value: areaFilter,
                                label: 'Area',
                                options: areaOptions,
                                onChanged: (value) =>
                                    setDialogState(() => areaFilter = value),
                              ),
                              _DropdownField(
                                value: typeFilter,
                                label: 'Document type',
                                options: typeOptions,
                                onChanged: (value) =>
                                    setDialogState(() => typeFilter = value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${filteredRows.length} row(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _kMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 420,
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(minWidth: 1240),
                                    child: DataTable(
                                      columnSpacing: 30,
                                      dataRowMinHeight: 56,
                                      dataRowMaxHeight: 76,
                                      columns: const [
                                        DataColumn(
                                            label: SizedBox(
                                                width: 220,
                                                child: Text('Title'))),
                                        DataColumn(
                                            label: SizedBox(
                                                width: 120,
                                                child: Text('Spec type'))),
                                        DataColumn(
                                            label: SizedBox(
                                                width: 140,
                                                child: Text('Discipline'))),
                                        DataColumn(
                                            label: SizedBox(
                                                width: 140,
                                                child: Text('Area'))),
                                        DataColumn(
                                            label: SizedBox(
                                                width: 170,
                                                child:
                                                    Text('WBS Work Package'))),
                                        DataColumn(
                                            label: SizedBox(
                                                width: 120,
                                                child: Text('Source type'))),
                                        DataColumn(
                                            label: SizedBox(
                                                width: 120,
                                                child: Text('Owner'))),
                                        DataColumn(
                                            label: SizedBox(
                                                width: 90,
                                                child: Text('Status'))),
                                      ],
                                      rows: filteredRows
                                          .map(
                                            (item) => DataRow(
                                              cells: [
                                                DataCell(SizedBox(
                                                  width: 220,
                                                  child: Text(
                                                    item.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )),
                                                DataCell(SizedBox(
                                                  width: 120,
                                                  child: Text(
                                                    item.specificationType,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )),
                                                DataCell(SizedBox(
                                                  width: 140,
                                                  child: Text(
                                                    item.discipline.isEmpty
                                                        ? '-'
                                                        : item.discipline,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )),
                                                DataCell(SizedBox(
                                                  width: 140,
                                                  child: Text(
                                                    item.area.isEmpty
                                                        ? '-'
                                                        : item.area,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )),
                                                DataCell(SizedBox(
                                                  width: 170,
                                                  child: Text(
                                                    item.wbsWorkPackageTitle
                                                            .isEmpty
                                                        ? '-'
                                                        : item
                                                            .wbsWorkPackageTitle,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )),
                                                DataCell(SizedBox(
                                                  width: 120,
                                                  child: Text(
                                                    item.sourceType.isEmpty
                                                        ? '-'
                                                        : item.sourceType,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )),
                                                DataCell(SizedBox(
                                                  width: 120,
                                                  child: Text(
                                                    item.owner.isEmpty
                                                        ? '-'
                                                        : item.owner,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )),
                                                DataCell(SizedBox(
                                                  width: 90,
                                                  child: Text(
                                                    item.status.isEmpty
                                                        ? '-'
                                                        : item.status,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )),
                                              ],
                                            ),
                                          )
                                          .toList(growable: false),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                FilledButton.icon(
                  onPressed: filteredRows.isEmpty
                      ? null
                      : () => _exportSpecificationsTablePdf(filteredRows),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Export PDF'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
    searchController.dispose();
  }

  String _pdfCellValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _buildSpecificationsPdfFilename() {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'design_specifications_table_$stamp.pdf';
  }

  Future<void> _exportSpecificationsTablePdf(
    List<_SpecificationOption> rows,
  ) async {
    if (rows.isEmpty) {
      _showToast('No table rows to export.');
      return;
    }

    final filename = _buildSpecificationsPdfFilename();

    try {
      final doc = pw.Document();
      final generatedAt = DateTime.now();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => [
            pw.Text(
              'Design Specifications Table',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated ${generatedAt.toLocal().toIso8601String()}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColor(0.93, 0.95, 0.98)),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignment: pw.Alignment.topLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              headers: const [
                'Title',
                'Spec type',
                'Discipline',
                'Area',
                'WBS Work Package',
                'Source type',
                'Owner',
                'Status',
              ],
              data: rows
                  .map(
                    (item) => [
                      _pdfCellValue(item.title),
                      _pdfCellValue(item.specificationType),
                      _pdfCellValue(item.discipline),
                      _pdfCellValue(item.area),
                      _pdfCellValue(item.wbsWorkPackageTitle),
                      _pdfCellValue(item.sourceType),
                      _pdfCellValue(item.owner),
                      _pdfCellValue(item.status),
                    ],
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      if (kIsWeb) {
        download_helper.downloadFile(
          bytes,
          filename,
          mimeType: 'application/pdf',
        );
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }

      if (!mounted) return;
      _showToast('PDF exported: $filename');
    } catch (e) {
      if (!mounted) return;
      _showToast('Failed to export PDF: $e');
    }
  }

  void _addSpecificationDocument() {
    setState(() {
      _document.specificationDocuments.add(
        DesignPlanningReferenceDoc(category: _specSourceTypeOptions.first),
      );
    });
    _queueSave();
  }

  Future<void> _uploadSpecificationArtifact(String rowId) async {
    final uploaded = await _pickAndUploadAttachment(
      folder: 'planning-design-spec-artifacts',
    );
    if (uploaded == null) return;
    final index =
        _document.specifications.indexWhere((item) => item.id == rowId);
    if (index == -1) return;
    setState(() {
      _document.specifications[index].referenceLink = uploaded.url;
      _document.specifications[index].uploadedFileName = uploaded.name;
      _document.specifications[index].uploadedStoragePath =
          uploaded.storagePath;
    });
    _queueSave();
    _showToast('Specification artifact uploaded.');
  }

  Future<void> _uploadSpecificationDocument(String documentId) async {
    final uploaded = await _pickAndUploadAttachment(
      folder: 'planning-design-spec-documents',
    );
    if (uploaded == null) return;
    final index = _document.specificationDocuments
        .indexWhere((item) => item.id == documentId);
    if (index == -1) return;
    setState(() {
      _document.specificationDocuments[index].link = uploaded.url;
      _document.specificationDocuments[index].fileName = uploaded.name;
      _document.specificationDocuments[index].storagePath =
          uploaded.storagePath;
    });
    _queueSave();
    _showToast('Design specification document uploaded.');
  }

  Future<_UploadedDoc?> _pickAndUploadAttachment({
    required String folder,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showToast('Sign in is required before uploading files.');
      return null;
    }
    final data = ProjectDataHelper.getData(context);
    final projectId = data.projectId;
    if (projectId == null || projectId.trim().isEmpty) {
      _showToast('Select a project before uploading files.');
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
        _showToast('Unable to read selected file.');
        return null;
      }
      final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final storagePath =
          'projects/${projectId.trim()}/$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';
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
      );
    } on FirebaseException catch (error) {
      _showToast('Failed to upload file: ${error.message ?? error.code}');
      return null;
    } catch (error) {
      _showToast('Failed to upload file: $error');
      return null;
    }
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

  bool _isGenerating(String key) => _aiGenerating[key] == true;

  Future<void> _runAiGenerate({
    required String key,
    required String section,
    required TextEditingController controller,
  }) async {
    if (_isGenerating(key)) return;
    setState(() => _aiGenerating[key] = true);
    try {
      final data = ProjectDataHelper.getData(context);
      final contextText = ProjectDataHelper.buildExecutivePlanContext(
        data,
        sectionLabel: section,
      );
      final generated = await OpenAiServiceSecure().generateFepSectionText(
        section: section,
        context: contextText,
        maxTokens: 900,
        temperature: 0.45,
      );
      if (!mounted) return;
      if (generated.trim().isEmpty) {
        _showToast('AI returned an empty result for $section.');
        return;
      }
      controller.text = generated.trim();
      _queueSave();
      _showToast('$section generated from project context.');
    } catch (e) {
      if (!mounted) return;
      _showToast('AI generation failed for $section: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _aiGenerating[key] = false);
      }
    }
  }

  void _autofillOverview(ProjectDataModel data) {
    _overviewController.text = [
      data.solutionDescription.trim(),
      data.businessCase.trim(),
      data.notes.trim(),
    ].where((value) => value.isNotEmpty).join('\n\n');
    _objectivesController.text = [
      data.projectObjective.trim(),
      ...data.planningGoals
          .map((goal) => goal.title.trim())
          .where((value) => value.isNotEmpty),
    ].where((value) => value.isNotEmpty).join('\n');
    _successCriteriaController.text = data.frontEndPlanning.successCriteriaItems
        .map((item) => item.description.trim())
        .where((value) => value.isNotEmpty)
        .join('\n');
    _scopeController.text = data.withinScopeItems
        .map((item) => item.description.trim())
        .where((value) => value.isNotEmpty)
        .join('\n');
    _outOfScopeController.text = data.outOfScopeItems
        .map((item) => item.description.trim())
        .where((value) => value.isNotEmpty)
        .join('\n');
    _queueSave();
    _showToast('Overview autofilled from initiation/planning context.');
  }

  void _autofillDesignOverview(ProjectDataModel data) {
    _designWhoController.text = [
      if (data.charterProjectManagerName.trim().isNotEmpty)
        'Project Manager: ${data.charterProjectManagerName.trim()}',
      if (data.charterProjectSponsorName.trim().isNotEmpty)
        'Project Sponsor: ${data.charterProjectSponsorName.trim()}',
      if (data.charterReviewedBy.trim().isNotEmpty)
        'Reviewer: ${data.charterReviewedBy.trim()}',
      ...data.teamMembers
          .where((member) =>
              member.name.trim().isNotEmpty || member.role.trim().isNotEmpty)
          .take(8)
          .map((member) => [
                if (member.name.trim().isNotEmpty) member.name.trim(),
                if (member.role.trim().isNotEmpty) member.role.trim(),
                if (member.responsibilities.trim().isNotEmpty)
                  member.responsibilities.trim(),
              ].join(' | ')),
    ].where((value) => value.isNotEmpty).join('\n');

    _designHowController.text = [
      if ((data.overallFramework ?? '').trim().isNotEmpty)
        'Framework: ${data.overallFramework!.trim()}',
      if (data.projectObjective.trim().isNotEmpty)
        'Objective: ${data.projectObjective.trim()}',
      if (data.designManagementData != null)
        'Methodology: ${data.designManagementData!.methodology.name}',
      if (data.designManagementData != null)
        'Execution strategy: ${data.designManagementData!.executionStrategy.name}',
      if (data.designManagementData != null &&
          data.designManagementData!.applicableStandards.isNotEmpty)
        'Applicable standards: ${data.designManagementData!.applicableStandards.join(', ')}',
      ...data.planningGoals
          .map((goal) => goal.title.trim())
          .where((value) => value.isNotEmpty)
          .take(5)
          .map((value) => 'Design priority: $value'),
    ].where((value) => value.isNotEmpty).join('\n');

    _designVendorsController.text = [
      if (data.frontEndPlanning.contracts.trim().isNotEmpty)
        'Contracts context: ${data.frontEndPlanning.contracts.trim()}',
      if (data.frontEndPlanning.contractVendorQuotes.trim().isNotEmpty)
        'Vendor quotes context: ${data.frontEndPlanning.contractVendorQuotes.trim()}',
      if (data.frontEndPlanning.procurement.trim().isNotEmpty)
        'Procurement context: ${data.frontEndPlanning.procurement.trim()}',
      if (data.contractors.isNotEmpty)
        'Contractors:\n${data.contractors.map((item) => [
              item.name.trim(),
              item.service.trim(),
              item.status.trim(),
            ].where((value) => value.isNotEmpty).join(' | ')).where((value) => value.isNotEmpty).join('\n')}',
      if (data.vendors.isNotEmpty)
        'Vendors:\n${data.vendors.map((item) => [
              item.name.trim(),
              item.equipmentOrService.trim(),
              item.procurementStage.trim(),
              item.status.trim(),
            ].where((value) => value.isNotEmpty).join(' | ')).where((value) => value.isNotEmpty).join('\n')}',
    ].where((value) => value.isNotEmpty).join('\n\n');

    _designInterfacesController.text = [
      if (data.interfaceEntries.isNotEmpty)
        'Interfaces:\n${data.interfaceEntries.map((entry) => [
              entry.boundary.trim(),
              if (entry.owner.trim().isNotEmpty) 'Owner: ${entry.owner.trim()}',
              if (entry.status.trim().isNotEmpty)
                'Status: ${entry.status.trim()}',
              if (entry.risk.trim().isNotEmpty) 'Risk: ${entry.risk.trim()}',
            ].whereType<String>().join(' | ')).where((value) => value.isNotEmpty).join('\n')}',
      ...data.constraintItems
          .map((item) => item.description.trim())
          .where((value) => value.isNotEmpty)
          .take(6)
          .map((value) => 'Constraint: $value'),
      ...data.assumptionItems
          .map((item) => item.description.trim())
          .where((value) => value.isNotEmpty)
          .take(6)
          .map((value) => 'Assumption: $value'),
      ...data.frontEndPlanning.riskRegisterItems
          .map((item) => item.riskName.trim())
          .where((value) => value.isNotEmpty)
          .take(4)
          .map((value) => 'Risk driver: $value'),
    ].where((value) => value.isNotEmpty).join('\n');

    _queueSave();
    _showToast('Design Overview seeded from initiation and planning context.');
  }

  void _autofillArchitecture(ProjectDataModel data) {
    _architectureController.text = [
      data.frontEndPlanning.infrastructure.trim(),
      data.planningNotes[kDesignPlanningArchitectureKey]?.trim() ?? '',
    ].where((value) => value.isNotEmpty).join('\n\n');
    _dataFlowController.text = data.interfaceEntries
        .map((entry) => [
              entry.boundary.trim(),
              entry.owner.trim().isEmpty
                  ? null
                  : 'Owner: ${entry.owner.trim()}',
              entry.status.trim().isEmpty
                  ? null
                  : 'Status: ${entry.status.trim()}',
            ].whereType<String>().join(' | '))
        .where((value) => value.isNotEmpty)
        .join('\n');
    _document.modules = data.designDeliverablesData.register
        .where((item) => item.name.trim().isNotEmpty)
        .map(
          (item) => DesignPlanningWorkItem(
            name: item.name.trim(),
            purpose: item.risk.trim(),
            owner: item.owner.trim(),
            status: item.status.trim().isEmpty ? 'Planned' : item.status.trim(),
          ),
        )
        .toList();
    _queueSave();
    _showToast('Architecture basis autofilled from planning data.');
  }

  void _autofillUiUx(ProjectDataModel data) {
    _uiUxController.text = [
      data.frontEndPlanning.summary.trim(),
      data.planningNotes[kDesignPlanningUiUxKey]?.trim() ?? '',
    ].where((value) => value.isNotEmpty).join('\n\n');
    _designSystemController.text =
        data.frontEndPlanning.requirementsNotes.trim();
    _document.journeys = data.planningGoals
        .where((goal) => goal.title.trim().isNotEmpty)
        .map(
          (goal) => DesignPlanningWorkItem(
            name: goal.title.trim(),
            purpose: goal.description.trim(),
            status: 'Planned',
          ),
        )
        .toList();
    _document.interfaces = data.interfaceEntries
        .where((entry) => entry.boundary.trim().isNotEmpty)
        .map(
          (entry) => DesignPlanningWorkItem(
            name: entry.boundary.trim(),
            purpose: entry.notes.trim(),
            owner: entry.owner.trim(),
            status:
                entry.status.trim().isEmpty ? 'Planned' : entry.status.trim(),
          ),
        )
        .toList();
    _queueSave();
    _showToast('UI/UX basis autofilled from previous context.');
  }

  void _autofillTechnical(ProjectDataModel data) {
    _technicalFrontendController.text = data.frontEndPlanning.technology.trim();
    _technicalBackendController.text = data.technologyDefinitions
        .map((item) => item['name']?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .join(', ');
    _technicalDataController.text = [
      data.notes.trim(),
      data.frontEndPlanning.infrastructure.trim(),
    ].where((value) => value.isNotEmpty).join('\n\n');
    _document.integrations = data.interfaceEntries
        .where((entry) => entry.boundary.trim().isNotEmpty)
        .map(
          (entry) => DesignPlanningWorkItem(
            name: entry.boundary.trim(),
            purpose: entry.notes.trim(),
            owner: entry.owner.trim(),
            status:
                entry.status.trim().isEmpty ? 'Planned' : entry.status.trim(),
          ),
        )
        .toList();
    _queueSave();
    _showToast('Technical basis autofilled from technology/interface context.');
  }

  void _autofillValidation(ProjectDataModel data) {
    _validationController.text = [
      ...data.planningRequirementItems
          .map((item) => item.acceptanceCriteria.trim())
          .where((value) => value.isNotEmpty),
      ...data.planningRequirementItems
          .map((item) => item.verificationMethod.trim())
          .where((value) => value.isNotEmpty),
    ].join('\n');
    _queueSave();
    _showToast('Validation criteria seeded from planning requirements.');
  }

  List<String> _ownerOptions(ProjectDataModel data) {
    final options = <String>{
      for (final member in data.teamMembers)
        if (member.name.trim().isNotEmpty)
          member.name.trim()
        else if (member.role.trim().isNotEmpty)
          member.role.trim(),
      if (data.charterProjectManagerName.trim().isNotEmpty)
        data.charterProjectManagerName.trim(),
      if (data.charterProjectSponsorName.trim().isNotEmpty)
        data.charterProjectSponsorName.trim(),
    };
    if (options.isEmpty) {
      return const ['Owner'];
    }
    return options.toList()..sort();
  }

  List<_RequirementAttachmentOption> _requirementAttachmentOptions(
    ProjectDataModel projectData,
  ) {
    final options = <_RequirementAttachmentOption>[];
    for (var index = 0;
        index < projectData.frontEndPlanning.requirementItems.length;
        index++) {
      final item = projectData.frontEndPlanning.requirementItems[index];
      final description = item.description.trim();
      if (description.isEmpty && item.id.trim().isEmpty) continue;
      final id = item.id.trim().isNotEmpty
          ? item.id.trim()
          : 'fep_req_${index + 1}_${description.toLowerCase().hashCode.abs()}';
      options.add(
        _RequirementAttachmentOption(
          id: id,
          label: description.isEmpty ? 'Requirement ${index + 1}' : description,
        ),
      );
    }
    options
        .sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return options;
  }

  List<_SpecificationOption> _specificationOptions() {
    final options = <_SpecificationOption>[];
    for (var index = 0; index < _document.specifications.length; index++) {
      final row = _document.specifications[index];
      final fallback = 'Specification ${index + 1}';
      final title = row.title.trim().isEmpty ? fallback : row.title.trim();
      options.add(
        _SpecificationOption(
          id: row.id,
          title: title,
          details: row.details.trim(),
          specificationType: row.specificationType.trim(),
          discipline: row.discipline.trim(),
          area: row.area.trim(),
          sourceType: row.sourceType.trim(),
          owner: row.owner.trim(),
          status: row.status.trim(),
          referenceLink: row.referenceLink.trim(),
          wbsWorkPackageId: row.wbsWorkPackageId.trim(),
          wbsWorkPackageTitle: row.wbsWorkPackageTitle.trim(),
        ),
      );
    }
    return options;
  }

  String _stripWbsPrefix(String title) {
    final pattern = RegExp(r'^[GS]\d+(?:\.\d+)*(?:\s*[:\-])?\s*');
    return title.replaceFirst(pattern, '').trim();
  }

  List<_WbsWorkPackageOption> _extractWbsWorkPackages(ProjectDataModel data) {
    final output = <_WbsWorkPackageOption>[];

    void addOption({
      required WorkItem item,
      required String parentTitle,
      required String disciplineSeed,
      required String areaSeed,
      required int level,
    }) {
      final title = _stripWbsPrefix(item.title);
      if (title.isEmpty) return;
      final rawId = item.id.trim();
      final id = rawId.isNotEmpty
          ? rawId
          : 'wbs_pkg_${level}_${output.length + 1}_${parentTitle.hashCode.abs()}_${title.hashCode.abs()}';
      output.add(
        _WbsWorkPackageOption(
          id: id,
          title: title,
          parentTitle: parentTitle,
          level: level,
          disciplineSeed: disciplineSeed,
          areaSeed: areaSeed,
        ),
      );
    }

    for (final topLevel in data.wbsTree) {
      final topTitle = _stripWbsPrefix(topLevel.title);
      if (topLevel.children.isNotEmpty) {
        for (final level2 in topLevel.children) {
          final level2Title = _stripWbsPrefix(level2.title);
          addOption(
            item: level2,
            parentTitle: topTitle,
            disciplineSeed: topTitle,
            areaSeed: level2Title.isEmpty ? topTitle : level2Title,
            level: 2,
          );
        }
      } else {
        addOption(
          item: topLevel,
          parentTitle: '',
          disciplineSeed: topTitle,
          areaSeed: topTitle,
          level: 1,
        );
      }
    }

    return output;
  }

  List<String> _wbsDisciplineOptions(
    List<_WbsWorkPackageOption> packages,
    List<String> fallback,
  ) {
    final values = <String>[
      ...packages
          .map((item) => item.disciplineSeed.trim())
          .where((value) => value.isNotEmpty),
      ...fallback,
    ];
    return _dedupeOptions(values);
  }

  List<String> _wbsAreaOptions(
    List<_WbsWorkPackageOption> packages,
    List<String> fallback,
  ) {
    final values = <String>[
      ...packages
          .map((item) => item.areaSeed.trim())
          .where((value) => value.isNotEmpty),
      ...fallback,
    ];
    return _dedupeOptions(values);
  }

  List<String> _dedupeOptions(List<String> values) {
    final output = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      output.add(trimmed);
    }
    return output;
  }

  List<_RequirementAttachmentOption> _unlinkedRequirements(
    List<_RequirementAttachmentOption> requirementOptions,
  ) {
    final linkedIds = <String>{};
    for (final row in _document.specifications) {
      for (final id in row.attachedRequirementIds) {
        final trimmed = id.trim();
        if (trimmed.isNotEmpty) linkedIds.add(trimmed);
      }
    }
    return requirementOptions
        .where((option) => !linkedIds.contains(option.id))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final projectData = ProjectDataHelper.getData(context);
    final isMobile = AppBreakpoints.isMobile(context);
    final owners = _ownerOptions(projectData);
    final pagePadding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Design Planning',
      backgroundColor: _kPageBg,
      floatingActionButton: const KazAiChatBubble(),
      body: Column(
        children: [
          PlanningPhaseHeader(
            title: 'Design Planning',
            showImportButton: false,
            showContentButton: false,
            onBack: () =>
                PlanningPhaseNavigation.goToPrevious(context, 'design'),
            onForward: () =>
                PlanningPhaseNavigation.goToNext(context, 'design'),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                pagePadding,
                20,
                pagePadding,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(projectData),
                  const SizedBox(height: 20),
                  if (isMobile)
                    Column(
                      children: [
                        _buildMainColumn(projectData, owners),
                        const SizedBox(height: 20),
                        _buildSectionNav(),
                        const SizedBox(height: 20),
                        _buildRightRail(projectData),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 220, child: _buildSectionNav()),
                        const SizedBox(width: 20),
                        Expanded(
                            flex: 7,
                            child: _buildMainColumn(projectData, owners)),
                        const SizedBox(width: 20),
                        SizedBox(
                            width: 320, child: _buildRightRail(projectData)),
                      ],
                    ),
                  const SizedBox(height: 24),
                  LaunchPhaseNavigation(
                    backLabel: PlanningPhaseNavigation.backLabel('design'),
                    nextLabel: PlanningPhaseNavigation.nextLabel('design'),
                    onBack: () =>
                        PlanningPhaseNavigation.goToPrevious(context, 'design'),
                    onNext: () =>
                        PlanningPhaseNavigation.goToNext(context, 'design'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ProjectDataModel data) {
    final counts = [
      _StatChip(
          label: 'Requirements', value: '${_document.requirements.length}'),
      _StatChip(label: 'Risks', value: '${_document.risks.length}'),
      _StatChip(label: 'Approvals', value: '${_document.approvals.length}'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Badge(
                label: data.projectName.trim().isEmpty
                    ? 'Unnamed Project'
                    : data.projectName.trim(),
                background: _kPrimarySoft,
                foreground: _kPrimary,
              ),
              _VersionChip(
                version: _document.version,
                onPressed: _editVersion,
              ),
              _DropdownBadge(
                value: _document.status,
                items: _statusOptions,
                onChanged: (value) {
                  _document.status = value;
                  _queueSave();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Design Basis Document',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _kText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Define the planning-level design basis, keep requirement traceability intact, and hand structured direction into the design phase.',
            style: const TextStyle(
              fontSize: 13,
              color: _kMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: counts),
          const SizedBox(height: 14),
          Row(
            children: [
              _ActionButton(
                label: _saving ? 'Saving...' : 'Save',
                icon: Icons.save_outlined,
                primary: true,
                onPressed: _saving ? null : _saveDocument,
              ),
              const SizedBox(width: 10),
              _ActionButton(
                label: 'Submit for Review',
                icon: Icons.rate_review_outlined,
                onPressed: () {
                  _document.status = 'In Review';
                  _queueSave();
                },
              ),
              const Spacer(),
              _AutoSaveIndicator(
                saving: _saving,
                pending: _pendingSave,
                lastSavedAt: _lastSavedAt,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionNav() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sections',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const SizedBox(height: 12),
          for (final section in _sectionOrder) ...[
            Builder(
              builder: (context) {
                final isLocked = !_canOpenSection(section.id);
                final isActive = _activeSectionId == section.id;
                final state = _sectionProgress[section.id] ??
                    _SectionProgressState.pending;
                final sectionColor =
                    isLocked ? _kMuted.withValues(alpha: 0.45) : section.accent;
                final textColor = isLocked ? _kMuted : _kText;
                return InkWell(
                  onTap: () => _activateSection(section.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive ? _kPrimarySoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: sectionColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            section.label,
                            style: TextStyle(fontSize: 13, color: textColor),
                          ),
                        ),
                        if (state == _SectionProgressState.complete)
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: _kSuccess,
                          ),
                        if (state == _SectionProgressState.notApplicable)
                          const Icon(
                            Icons.remove_circle,
                            size: 16,
                            color: _kWarning,
                          ),
                        if (isLocked)
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: _kMuted.withValues(alpha: 0.8),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRightRail(ProjectDataModel data) {
    final mappedSpecificationIds = _document.requirements
        .map((item) => item.requirementId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final mappedSpecsCount = _document.specifications
        .where((item) => mappedSpecificationIds.contains(item.id))
        .length;
    final deviationsCount = _document.deviations
        .where((item) =>
            item.specificationId.trim().isNotEmpty ||
            item.description.trim().isNotEmpty)
        .length;
    final summary = [
      (
        'Solution',
        data.solutionTitle.trim().isEmpty
            ? 'Not set'
            : data.solutionTitle.trim()
      ),
      ('Milestones', '${data.keyMilestones.length}'),
      ('Team', '${data.teamMembers.length}'),
      ('Technology', data.technology),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RailCard(
          title: 'Initiation Context',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in summary) ...[
                Text(
                  item.$1,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (data.businessCase.trim().isNotEmpty)
                Text(
                  data.businessCase.trim(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kMuted,
                    height: 1.5,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _RailCard(
          title: 'Design Phase Handoff',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniMetric(
                label: 'Architecture modules',
                value:
                    '${_document.modules.where((item) => item.name.trim().isNotEmpty).length}',
              ),
              _MiniMetric(
                label: 'UI/UX journeys',
                value:
                    '${_document.journeys.where((item) => item.name.trim().isNotEmpty).length}',
              ),
              _MiniMetric(
                label: 'Technical integrations',
                value:
                    '${_document.integrations.where((item) => item.name.trim().isNotEmpty).length}',
              ),
              _MiniMetric(
                label: 'Validation lines',
                value: '${_splitLines(_document.validationSummary).length}',
              ),
              const SizedBox(height: 10),
              Text(
                _document.buildExecutionHandoff().isEmpty
                    ? 'Fill the document to seed architecture, UI/UX, engineering, and governance context downstream.'
                    : _document.buildExecutionHandoff(),
                style: const TextStyle(
                  fontSize: 12,
                  color: _kMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _RailCard(
          title: 'Specs',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(
                    label: 'Mapped specs: $mappedSpecsCount',
                    background: const Color(0xFFE8F0FF),
                    foreground: _kPrimary,
                  ),
                  _Badge(
                    label: 'Deviations: $deviationsCount',
                    background: const Color(0xFFECFDF3),
                    foreground: _kSuccess,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_document.specifications.isEmpty)
                const Text(
                  'No specification rows yet.',
                  style: TextStyle(fontSize: 12, color: _kMuted, height: 1.45),
                ),
              for (var i = 0; i < _document.specifications.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _openSpecificationsAndScrollToRow(
                      _document.specifications[i].id,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F766E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              _document.specifications[i].title.trim().isEmpty
                                  ? 'Spec Row ${i + 1}'
                                  : _document.specifications[i].title.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _kText,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainColumn(ProjectDataModel data, List<String> owners) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewSection(data),
        const SizedBox(height: 18),
        _buildDesignOverviewSection(data),
        const SizedBox(height: 18),
        _buildDesignSpecificationsWorkspaceSection(),
        const SizedBox(height: 18),
        _buildDeviationsSection(),
        const SizedBox(height: 18),
        _buildRequirementsSection(owners),
        const SizedBox(height: 18),
        _buildArchitectureSection(owners),
        const SizedBox(height: 18),
        _buildUiUxSection(owners),
        const SizedBox(height: 18),
        _buildTechnicalSection(owners),
        const SizedBox(height: 18),
        _buildConstraintsSection(),
        const SizedBox(height: 18),
        _buildRisksSection(owners),
        const SizedBox(height: 18),
        _buildDependenciesSection(owners),
        const SizedBox(height: 18),
        _buildDecisionLogSection(owners),
        const SizedBox(height: 18),
        _buildValidationSection(),
        const SizedBox(height: 18),
        _buildApprovalsSection(owners),
      ],
    );
  }

  Widget _buildGuidedSectionCard({
    required String sectionId,
    required GlobalKey sectionKey,
    required String title,
    required String subtitle,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      key: sectionKey,
      child: _SectionCard(
        expansionKey: ValueKey(
            'tile_${sectionId}_${_sectionExpanded[sectionId] == true}_${_sectionTileVersion[sectionId] ?? 0}'),
        title: title,
        subtitle: subtitle,
        accent: accent,
        expanded: _sectionExpanded[sectionId] ?? false,
        enabled: true,
        onExpansionChanged: (expanded) =>
            _onSectionExpansionChanged(sectionId, expanded),
        child: Column(
          children: [
            _buildSectionProgressControls(sectionId),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(ProjectDataModel data) {
    return _buildGuidedSectionCard(
      sectionId: 'overview',
      sectionKey: _sectionKeys['overview']!,
      title: 'Project Overview',
      subtitle:
          'Capture the design basis, objectives, success criteria, and the planning boundary for the whole design effort.',
      accent: _kPrimary,
      child: Column(
        children: [
          _AssistActions(
            onAutofill: () => _autofillOverview(data),
            generating: _isGenerating('overview'),
            onGenerate: () => _runAiGenerate(
              key: 'overview',
              section: 'Project Overview',
              controller: _overviewController,
            ),
          ),
          const SizedBox(height: 12),
          _TextAreaField(
            controller: _overviewController,
            label: 'Design basis summary',
            hintText:
                'Describe the design basis and the project design intent.',
            minLines: 4,
            onChanged: (_) => _queueSave(),
          ),
          const SizedBox(height: 14),
          _ResponsivePair(
            left: _TextAreaField(
              controller: _objectivesController,
              label: 'Objectives',
              hintText: 'One item per line',
              minLines: 5,
              onChanged: (_) => _queueSave(),
            ),
            right: _TextAreaField(
              controller: _successCriteriaController,
              label: 'Success criteria',
              hintText: 'One item per line',
              minLines: 5,
              onChanged: (_) => _queueSave(),
            ),
          ),
          const SizedBox(height: 14),
          _ResponsivePair(
            left: _TextAreaField(
              controller: _scopeController,
              label: 'In scope',
              hintText: 'One item per line',
              minLines: 4,
              onChanged: (_) => _queueSave(),
            ),
            right: _TextAreaField(
              controller: _outOfScopeController,
              label: 'Out of scope',
              hintText: 'One item per line',
              minLines: 4,
              onChanged: (_) => _queueSave(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsSection(List<String> owners) {
    final specificationOptions = _specificationOptions();
    final requirementOptions =
        _requirementAttachmentOptions(ProjectDataHelper.getData(context));
    final unlinkedRequirements = _unlinkedRequirements(requirementOptions);
    return _buildGuidedSectionCard(
      sectionId: 'requirements',
      sectionKey: _sectionKeys['requirements']!,
      title: 'Requirements to Design Mapping',
      subtitle:
          'Link specification items from planning to concrete design details, owners, and evidence.',
      accent: const Color(0xFF0F9D58),
      child: Column(
        children: [
          if (unlinkedRequirements.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Text(
                '${unlinkedRequirements.length} requirement(s) are not linked to specifications yet.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          _SubHeader(
            title: 'Mappings',
            actionLabel: 'Add mapping',
            onAction: () {
              setState(
                  () => _document.requirements.add(DesignRequirementMapping()));
              _queueSave();
              _showToast('Mapping row added.');
            },
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _document.requirements.length; i++) ...[
            _MappingCard(
              data: _document.requirements[i],
              availableSpecifications: specificationOptions,
              owners: owners,
              onChanged: _queueSave,
              onRemove: () {
                setState(() => _document.requirements.removeAt(i));
                _queueSave();
              },
            ),
            if (i != _document.requirements.length - 1)
              const SizedBox(height: 12),
          ],
          if (_document.requirements.isEmpty)
            const _EmptyState(
              message:
                  'No mappings yet. Add rows here to make the design basis traceable.',
            ),
        ],
      ),
    );
  }

  Widget _buildDesignOverviewSection(ProjectDataModel data) {
    return _buildGuidedSectionCard(
      sectionId: 'design_overview',
      sectionKey: _sectionKeys['design_overview']!,
      title: 'Design Overview',
      subtitle:
          'Document design basis details covering who owns design outcomes, how design will be executed, and what vendor/contract/interface constraints shape the solution.',
      accent: const Color(0xFF1D4ED8),
      child: Column(
        children: [
          _AssistActions(
            onAutofill: () => _autofillDesignOverview(data),
            generating: _isGenerating('design_overview'),
            onGenerate: () => _runAiGenerate(
              key: 'design_overview',
              section: 'Design Overview (Who, How, Vendors, Contracts)',
              controller: _designHowController,
            ),
          ),
          const SizedBox(height: 12),
          _TextAreaField(
            controller: _designWhoController,
            label: 'Responsibilities',
            hintText:
                'Who leads architecture, UI/UX, technical design, reviews, and approvals.',
            minLines: 4,
            onChanged: (_) => _queueSave(),
          ),
          const SizedBox(height: 14),
          _TextAreaField(
            controller: _designHowController,
            label: 'Design Execution Strategy',
            hintText:
                'Methodology, cadence, standards, decision flow, and governance approach.',
            minLines: 4,
            onChanged: (_) => _queueSave(),
          ),
          const SizedBox(height: 14),
          _TextAreaField(
            controller: _designVendorsController,
            label: 'Vendor & contract inputs',
            hintText:
                'Contractors, vendors, procurement stage, and contract dependencies impacting design.',
            minLines: 5,
            onChanged: (_) => _queueSave(),
          ),
          const SizedBox(height: 14),
          _TextAreaField(
            controller: _designInterfacesController,
            label: 'Interfaces, constraints, and risk drivers',
            hintText:
                'Key interfaces plus constraints/assumptions that must be honored by design.',
            minLines: 5,
            onChanged: (_) => _queueSave(),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectureSection(List<String> owners) {
    return _buildGuidedSectionCard(
      sectionId: 'architecture',
      sectionKey: _sectionKeys['architecture']!,
      title: 'System Architecture Basis',
      subtitle:
          'Define the architecture direction, modules, diagram references, and data flow that downstream design must honor.',
      accent: const Color(0xFF7C3AED),
      child: Column(
        children: [
          _AssistActions(
            onAutofill: () =>
                _autofillArchitecture(ProjectDataHelper.getData(context)),
            generating: _isGenerating('architecture'),
            onGenerate: () => _runAiGenerate(
              key: 'architecture',
              section: 'System Architecture Basis',
              controller: _architectureController,
            ),
          ),
          const SizedBox(height: 12),
          _SubHeader(
            title: 'Modules',
            actionLabel: 'Add module',
            onAction: () {
              setState(() => _document.modules.add(DesignPlanningWorkItem()));
              _queueSave();
              _showToast('Architecture module row added.');
            },
          ),
          const SizedBox(height: 12),
          _TextAreaField(
            controller: _architectureController,
            label: 'Architecture summary',
            hintText:
                'Describe the intended system architecture and boundaries.',
            minLines: 4,
            onChanged: (_) => _queueSave(),
          ),
          const SizedBox(height: 14),
          _TextField(
            controller: _diagramReferenceController,
            label: 'Diagram reference / upload link',
            hintText:
                'Figma, Miro, Draw.io, URL, or internal artifact reference',
            onChanged: (_) => _queueSave(),
          ),
          const SizedBox(height: 14),
          _TextAreaField(
            controller: _dataFlowController,
            label: 'Data flow summary',
            hintText:
                'Summarize key flows, boundaries, and integration routes.',
            minLines: 3,
            onChanged: (_) => _queueSave(),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _document.modules.length; i++) ...[
            _WorkItemCard(
              title: 'Module ${i + 1}',
              data: _document.modules[i],
              owners: owners,
              onChanged: _queueSave,
              onRemove: () {
                setState(() => _document.modules.removeAt(i));
                _queueSave();
              },
            ),
            if (i != _document.modules.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildDesignSpecificationsWorkspaceSection() {
    final projectData = ProjectDataHelper.getData(context);
    final owners = _ownerOptions(projectData);
    final requirementOptions = _requirementAttachmentOptions(projectData);
    final wbsWorkPackages = _extractWbsWorkPackages(projectData);
    final disciplineOptions =
        _wbsDisciplineOptions(wbsWorkPackages, _specDisciplineOptions);
    final areaOptions = _wbsAreaOptions(wbsWorkPackages, _specAreaOptions);
    final unlinkedRequirements = _unlinkedRequirements(requirementOptions);
    return _buildGuidedSectionCard(
      sectionId: 'design_specifications_workspace',
      sectionKey: _sectionKeys['design_specifications_workspace']!,
      title: 'Design Specifications',
      subtitle:
          'Plan the configuration, rows, links, and supporting documents that feed the Design Phase specifications workspace.',
      accent: const Color(0xFF0F766E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Use this workspace for executable design specifications:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prepare spec rows and document references here, then open the design-phase workspace to continue with full implementation and section approval.',
            style: TextStyle(
              fontSize: 12.5,
              color: _kMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                label: 'Open Design Phase Workspace',
                icon: Icons.open_in_new,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DesignPhaseScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (unlinkedRequirements.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Text(
                          'Requirement coverage gap: ${unlinkedRequirements.length} requirement(s) not linked to any specification row.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9A3412),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    if (wbsWorkPackages.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Text(
                          'WBS continuity warning: no WBS work packages found. Populate Work Breakdown Structure first to auto-seed Discipline and Area.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    _SubHeader(
                      title: 'Specification rows',
                      actionLabel: 'Add row',
                      onAction: _addSpecificationRow,
                    ),
                    const SizedBox(height: 8),
                    _ActionButton(
                      label: 'View table',
                      icon: Icons.table_chart_outlined,
                      onPressed: _showSpecificationsTableDialog,
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0;
                        i < _document.specifications.length;
                        i++) ...[
                      Container(
                        key: _specificationRowKeys.putIfAbsent(
                          _document.specifications[i].id,
                          () => GlobalKey(
                            debugLabel:
                                'spec_row_${_document.specifications[i].id}',
                          ),
                        ),
                        child: _SpecificationPlanRowCard(
                          key: ValueKey(_document.specifications[i].id),
                          index: i + 1,
                          data: _document.specifications[i],
                          owners: owners,
                          requirementOptions: requirementOptions,
                          specificationTypeOptions: _specificationTypeOptions,
                          disciplineOptions: disciplineOptions,
                          areaOptions: areaOptions,
                          wbsWorkPackages: wbsWorkPackages,
                          sourceTypeOptions: _specSourceTypeOptions,
                          ruleTypeOptions: _specRuleTypeOptions,
                          statusOptions: _specRowStatusOptions,
                          uploadsEnabled: true,
                          onChanged: _queueSave,
                          onUpload: () => _uploadSpecificationArtifact(
                            _document.specifications[i].id,
                          ),
                          onRemove: () {
                            final removedId = _document.specifications[i].id;
                            setState(() {
                              _document.specifications.removeAt(i);
                              _specificationRowKeys.remove(removedId);
                            });
                            _queueSave();
                          },
                        ),
                      ),
                      if (i != _document.specifications.length - 1)
                        const SizedBox(height: 12),
                    ],
                    if (_document.specifications.isEmpty)
                      const _EmptyState(
                        message:
                            'No specification planning rows yet. Add rows to define internal/external rules and source context.',
                      ),
                    const SizedBox(height: 14),
                    _SubHeader(
                      title: 'Documents and links',
                      actionLabel: 'Add document',
                      onAction: _addSpecificationDocument,
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0;
                        i < _document.specificationDocuments.length;
                        i++) ...[
                      _SpecificationDocumentCard(
                        key: ValueKey(_document.specificationDocuments[i].id),
                        index: i + 1,
                        data: _document.specificationDocuments[i],
                        requirementOptions: requirementOptions,
                        sourceTypeOptions: _specSourceTypeOptions,
                        uploadsEnabled: true,
                        onChanged: _queueSave,
                        onUpload: () => _uploadSpecificationDocument(
                          _document.specificationDocuments[i].id,
                        ),
                        onRemove: () {
                          setState(() =>
                              _document.specificationDocuments.removeAt(i));
                          _queueSave();
                        },
                      ),
                      if (i != _document.specificationDocuments.length - 1)
                        const SizedBox(height: 12),
                    ],
                    if (_document.specificationDocuments.isEmpty)
                      const _EmptyState(
                        message:
                            'No specification reference documents yet. Add links or upload files to seed the Design Phase workspace.',
                      ),
                  ],
                ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviationsSection() {
    final specificationOptions = _specificationOptions();
    return _buildGuidedSectionCard(
      sectionId: 'deviations',
      sectionKey: _sectionKeys['deviations']!,
      title: 'Deviations',
      subtitle:
          'Record approved exceptions that deviate from planned specification items before execution begins.',
      accent: const Color(0xFF0EA5E9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(
            title: 'Deviation entries',
            actionLabel: 'Add deviation',
            onAction: _addDeviation,
          ),
          const SizedBox(height: 8),
          const Text(
            'Exceptions from Specifications, Codes, Standards and Criteria',
            style: TextStyle(
              fontSize: 12.5,
              color: _kMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _document.deviations.length; i++) ...[
            _SpecificationDeviationCard(
              key: ValueKey(_document.deviations[i].id),
              index: i + 1,
              data: _document.deviations[i],
              specificationOptions: specificationOptions,
              onChanged: _queueSave,
              onRemove: () {
                setState(() => _document.deviations.removeAt(i));
                _queueSave();
              },
            ),
            if (i != _document.deviations.length - 1)
              const SizedBox(height: 12),
          ],
          if (_document.deviations.isEmpty)
            const _EmptyState(
              message:
                  'No deviations logged. Add deviations to capture approved exceptions.',
            ),
        ],
      ),
    );
  }

  Widget _buildUiUxSection(List<String> owners) {
    return _buildGuidedSectionCard(
      sectionId: 'uiux',
      sectionKey: _sectionKeys['uiux']!,
      title: 'UI/UX Design Basis',
      subtitle:
          'Capture journeys, interface areas, and design-system expectations that should feed the later UI/UX design work.',
      accent: const Color(0xFFDB2777),
      child: Column(
        children: [
          _AssistActions(
            onAutofill: () => _autofillUiUx(ProjectDataHelper.getData(context)),
            generating: _isGenerating('uiux'),
            onGenerate: () => _runAiGenerate(
              key: 'uiux',
              section: 'UI/UX Design Basis',
              controller: _uiUxController,
            ),
          ),
          const SizedBox(height: 12),
          _TextAreaField(
            controller: _uiUxController,
            label: 'Experience summary',
            hintText:
                'Describe the intended experience, primary outcomes, and user focus.',
            minLines: 4,
            onChanged: (_) => _queueSave(),
          ),
          const SizedBox(height: 14),
          _TextAreaField(
            controller: _designSystemController,
            label: 'Design system expectations',
            hintText:
                'Colors, typography, accessibility, components, interaction rules.',
            minLines: 4,
            onChanged: (_) => _queueSave(),
          ),
          const SizedBox(height: 14),
          _SubHeader(
            title: 'User journeys',
            actionLabel: 'Add journey',
            onAction: () {
              setState(() => _document.journeys.add(DesignPlanningWorkItem()));
              _queueSave();
              _showToast('UI/UX journey row added.');
            },
          ),
          for (var i = 0; i < _document.journeys.length; i++) ...[
            _WorkItemCard(
              title: 'Journey ${i + 1}',
              data: _document.journeys[i],
              owners: owners,
              onChanged: _queueSave,
              onRemove: () {
                setState(() => _document.journeys.removeAt(i));
                _queueSave();
              },
            ),
            if (i != _document.journeys.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 14),
          _SubHeader(
            title: 'Interface areas',
            actionLabel: 'Add interface',
            onAction: () {
              setState(
                  () => _document.interfaces.add(DesignPlanningWorkItem()));
              _queueSave();
              _showToast('Interface row added.');
            },
          ),
          for (var i = 0; i < _document.interfaces.length; i++) ...[
            _WorkItemCard(
              title: 'Interface ${i + 1}',
              data: _document.interfaces[i],
              owners: owners,
              onChanged: _queueSave,
              onRemove: () {
                setState(() => _document.interfaces.removeAt(i));
                _queueSave();
              },
            ),
            if (i != _document.interfaces.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildTechnicalSection(List<String> owners) {
    return _buildGuidedSectionCard(
      sectionId: 'technical',
      sectionKey: _sectionKeys['technical']!,
      title: 'Technical Design Basis',
      subtitle:
          'Record the planning-level stack, integrations, and technical rules the engineering design work should inherit.',
      accent: const Color(0xFF0F766E),
      child: Column(
        children: [
          _AssistActions(
            onAutofill: () =>
                _autofillTechnical(ProjectDataHelper.getData(context)),
            generating: _isGenerating('technical'),
            onGenerate: () => _runAiGenerate(
              key: 'technical',
              section: 'Technical Design Basis',
              controller: _technicalDataController,
            ),
          ),
          const SizedBox(height: 12),
          _ResponsivePair(
            left: _TextAreaField(
              controller: _technicalFrontendController,
              label: 'Frontend / application stack',
              hintText: 'Frameworks, platforms, client architecture.',
              minLines: 4,
              onChanged: (_) => _queueSave(),
            ),
            right: _TextAreaField(
              controller: _technicalBackendController,
              label: 'Backend / service stack',
              hintText: 'Services, APIs, integrations, backend expectations.',
              minLines: 4,
              onChanged: (_) => _queueSave(),
            ),
          ),
          const SizedBox(height: 14),
          _TextAreaField(
            controller: _technicalDataController,
            label: 'Database / data / platform notes',
            hintText:
                'Data model, storage, environments, platform constraints.',
            minLines: 4,
            onChanged: (_) => _queueSave(),
          ),
          const SizedBox(height: 14),
          _SubHeader(
            title: 'Integrations',
            actionLabel: 'Add integration',
            onAction: () {
              setState(
                  () => _document.integrations.add(DesignPlanningWorkItem()));
              _queueSave();
              _showToast('Integration row added.');
            },
          ),
          for (var i = 0; i < _document.integrations.length; i++) ...[
            _WorkItemCard(
              title: 'Integration ${i + 1}',
              data: _document.integrations[i],
              owners: owners,
              onChanged: _queueSave,
              onRemove: () {
                setState(() => _document.integrations.removeAt(i));
                _queueSave();
              },
            ),
            if (i != _document.integrations.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildConstraintsSection() {
    return _buildGuidedSectionCard(
      sectionId: 'constraints',
      sectionKey: _sectionKeys['constraints']!,
      title: 'Constraints & Assumptions',
      subtitle:
          'State the basis conditions the design is planning against. One item per line keeps this compact and traceable.',
      accent: const Color(0xFFF59E0B),
      child: _ResponsivePair(
        left: _TextAreaField(
          controller: _constraintsController,
          label: 'Constraints',
          hintText: 'Budget, timeline, technology, policy, staffing...',
          minLines: 6,
          onChanged: (_) => _queueSave(),
        ),
        right: _TextAreaField(
          controller: _assumptionsController,
          label: 'Assumptions',
          hintText: 'Availability, dependencies, approvals, environments...',
          minLines: 6,
          onChanged: (_) => _queueSave(),
        ),
      ),
    );
  }

  Widget _buildRisksSection(List<String> owners) {
    return _buildGuidedSectionCard(
      sectionId: 'risks',
      sectionKey: _sectionKeys['risks']!,
      title: 'Risks & Mitigation',
      subtitle:
          'Expose design-planning risks early so the design phase can inherit mitigations instead of rediscovering them.',
      accent: const Color(0xFFDC2626),
      child: Column(
        children: [
          _SubHeader(
            title: 'Risk register',
            actionLabel: 'Add risk',
            onAction: () {
              setState(() => _document.risks.add(DesignRiskEntry()));
              _queueSave();
              _showToast('Risk row added.');
            },
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _document.risks.length; i++) ...[
            _RiskCard(
              data: _document.risks[i],
              owners: owners,
              onChanged: _queueSave,
              onRemove: () {
                setState(() => _document.risks.removeAt(i));
                _queueSave();
              },
            ),
            if (i != _document.risks.length - 1) const SizedBox(height: 12),
          ],
          if (_document.risks.isEmpty)
            const _EmptyState(
              message: 'No design-planning risks logged yet.',
            ),
        ],
      ),
    );
  }

  Widget _buildDependenciesSection(List<String> owners) {
    return _buildGuidedSectionCard(
      sectionId: 'dependencies',
      sectionKey: _sectionKeys['dependencies']!,
      title: 'Dependencies',
      subtitle:
          'Track the external systems, teams, approvals, and vendors the design effort depends on.',
      accent: const Color(0xFF0891B2),
      child: Column(
        children: [
          _SubHeader(
            title: 'Dependency register',
            actionLabel: 'Add dependency',
            onAction: () {
              setState(
                  () => _document.dependencies.add(DesignDependencyEntry()));
              _queueSave();
              _showToast('Dependency row added.');
            },
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _document.dependencies.length; i++) ...[
            _DependencyCard(
              data: _document.dependencies[i],
              owners: owners,
              onChanged: _queueSave,
              onRemove: () {
                setState(() => _document.dependencies.removeAt(i));
                _queueSave();
              },
            ),
            if (i != _document.dependencies.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildDecisionLogSection(List<String> owners) {
    return _buildGuidedSectionCard(
      sectionId: 'decisions',
      sectionKey: _sectionKeys['decisions']!,
      title: 'Design Decision Log',
      subtitle:
          'Keep rationale visible so architecture, UI/UX, and engineering decisions remain traceable during execution.',
      accent: const Color(0xFF4F46E5),
      child: Column(
        children: [
          _SubHeader(
            title: 'Decision entries',
            actionLabel: 'Add decision',
            onAction: () {
              setState(() => _document.decisions.add(DesignDecisionEntry()));
              _queueSave();
              _showToast('Decision log row added.');
            },
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _document.decisions.length; i++) ...[
            _DecisionCard(
              data: _document.decisions[i],
              owners: owners,
              onChanged: _queueSave,
              onRemove: () {
                setState(() => _document.decisions.removeAt(i));
                _queueSave();
              },
            ),
            if (i != _document.decisions.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationSection() {
    return _buildGuidedSectionCard(
      sectionId: 'validation',
      sectionKey: _sectionKeys['validation']!,
      title: 'Validation & Acceptance Criteria',
      subtitle:
          'Define how the planned design will be tested, reviewed, and accepted before execution starts.',
      accent: const Color(0xFF15803D),
      child: Column(
        children: [
          _AssistActions(
            onAutofill: () =>
                _autofillValidation(ProjectDataHelper.getData(context)),
            generating: _isGenerating('validation'),
            onGenerate: () => _runAiGenerate(
              key: 'validation',
              section: 'Validation & Acceptance Criteria',
              controller: _validationController,
            ),
          ),
          const SizedBox(height: 12),
          _TextAreaField(
            controller: _validationController,
            label: 'Validation and acceptance',
            hintText:
                'One item per line or structured notes covering review and approval criteria.',
            minLines: 6,
            onChanged: (_) => _queueSave(),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsSection(List<String> owners) {
    return _buildGuidedSectionCard(
      sectionId: 'approvals',
      sectionKey: _sectionKeys['approvals']!,
      title: 'Approvals & Governance',
      subtitle:
          'Define reviewer roles, approval state, and governance notes that must remain visible in the design phase.',
      accent: const Color(0xFF7C2D12),
      child: Column(
        children: [
          _SubHeader(
            title: 'Reviewer approvals',
            actionLabel: 'Add reviewer',
            onAction: () {
              setState(() => _document.approvals.add(DesignApprovalEntry()));
              _queueSave();
              _showToast('Reviewer row added.');
            },
          ),
          const SizedBox(height: 12),
          _TextAreaField(
            controller: _governanceController,
            label: 'Governance notes',
            hintText:
                'Review workflow, governance gates, compliance expectations.',
            minLines: 4,
            onChanged: (_) => _queueSave(),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _document.approvals.length; i++) ...[
            _ApprovalCard(
              key: ValueKey(_document.approvals[i].id),
              data: _document.approvals[i],
              owners: owners,
              onChanged: _queueSave,
              onRemove: () {
                setState(() => _document.approvals.removeAt(i));
                _queueSave();
              },
            ),
            if (i != _document.approvals.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  static List<String> _splitLines(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}

class _SectionMeta {
  const _SectionMeta(this.id, this.label, this.accent);

  final String id;
  final String label;
  final Color accent;
}

const List<_SectionMeta> _sectionOrder = [
  _SectionMeta('overview', 'Project Overview', _kPrimary),
  _SectionMeta('design_overview', 'Design Overview', Color(0xFF1D4ED8)),
  _SectionMeta('design_specifications_workspace', 'Design Specifications',
      Color(0xFF0F766E)),
  _SectionMeta('deviations', 'Deviations', Color(0xFF0EA5E9)),
  _SectionMeta('requirements', 'Requirements Mapping', Color(0xFF0F9D58)),
  _SectionMeta('architecture', 'Architecture Basis', Color(0xFF7C3AED)),
  _SectionMeta('uiux', 'UI/UX Basis', Color(0xFFDB2777)),
  _SectionMeta('technical', 'Technical Basis', Color(0xFF0F766E)),
  _SectionMeta('constraints', 'Constraints & Assumptions', Color(0xFFF59E0B)),
  _SectionMeta('risks', 'Risks & Mitigation', Color(0xFFDC2626)),
  _SectionMeta('dependencies', 'Dependencies', Color(0xFF0891B2)),
  _SectionMeta('decisions', 'Decision Log', Color(0xFF4F46E5)),
  _SectionMeta('validation', 'Validation', Color(0xFF15803D)),
  _SectionMeta('approvals', 'Approvals', Color(0xFF7C2D12)),
];

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    this.expansionKey,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
    required this.expanded,
    required this.enabled,
    required this.onExpansionChanged,
  });

  final Key? expansionKey;
  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;
  final bool expanded;
  final bool enabled;
  final ValueChanged<bool> onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ExpansionTile(
        key: expansionKey,
        initiallyExpanded: expanded,
        enabled: enabled,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: _kMuted, height: 1.45),
          ),
        ),
        children: [child],
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return Column(
        children: [
          left,
          const SizedBox(height: 14),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: _inputDecoration(hintText),
        ),
      ],
    );
  }
}

class _TextAreaField extends StatelessWidget {
  const _TextAreaField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.minLines,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int minLines;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines + 2,
          onChanged: onChanged,
          decoration: _inputDecoration(hintText),
        ),
      ],
    );
  }
}

class _MappingCard extends StatelessWidget {
  const _MappingCard({
    required this.data,
    required this.availableSpecifications,
    required this.owners,
    required this.onChanged,
    required this.onRemove,
  });

  final DesignRequirementMapping data;
  final List<_SpecificationOption> availableSpecifications;
  final List<String> owners;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final specificationOptions = <_SpecificationOption>[
      ...availableSpecifications.where(
        (item) => item.title.trim().isNotEmpty || item.id.trim().isNotEmpty,
      ),
    ];
    final selectedId = specificationOptions.any(
      (item) => item.id == data.requirementId,
    )
        ? data.requirementId
        : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Mapping Row',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          if (specificationOptions.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: selectedId,
              isExpanded: true,
              decoration: _inputDecoration('Select specification item'),
              items: specificationOptions
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              selectedItemBuilder: (context) {
                return specificationOptions
                    .map(
                      (item) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList();
              },
              onChanged: (value) {
                if (value == null) return;
                final selected = specificationOptions.firstWhere(
                  (item) => item.id == value,
                  orElse: () => _SpecificationOption(id: value, title: ''),
                );
                data.requirementId = selected.id;
                data.requirementText =
                    selected.title.isEmpty ? selected.details : selected.title;
                if (selected.details.isNotEmpty) {
                  data.designResponse = selected.details;
                }
                final mappedArea = selected.area.isNotEmpty
                    ? selected.area
                    : selected.discipline;
                if (mappedArea.isNotEmpty) {
                  data.designArea = mappedArea;
                }
                if (selected.owner.isNotEmpty) {
                  data.owner = selected.owner;
                }
                if (selected.referenceLink.isNotEmpty) {
                  data.linkedArtifact = selected.referenceLink;
                  data.verificationMethod = selected.referenceLink;
                }
                onChanged();
              },
            ),
          if (specificationOptions.isNotEmpty) const SizedBox(height: 12),
          TextFormField(
            initialValue: data.requirementText,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDecoration('Specification item'),
            onChanged: (value) {
              data.requirementText = value;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: data.designResponse,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDecoration('Details'),
            onChanged: (value) {
              data.designResponse = value;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          _FourColumnGrid(
            children: [
              _TextFormField(
                initialValue: data.designArea,
                label: 'Design area',
                suggestions: _DesignPlanningScreenState._designAreaOptions,
                onChanged: (value) {
                  data.designArea = value;
                  onChanged();
                },
              ),
              _DropdownField(
                value: data.owner,
                label: 'Owner',
                options: owners,
                onChanged: (value) {
                  data.owner = value;
                  onChanged();
                },
              ),
              _DropdownField(
                value: data.status,
                label: 'Status',
                options: _DesignPlanningScreenState._mappingStatusOptions,
                onChanged: (value) {
                  data.status = value;
                  onChanged();
                },
              ),
              _TextFormField(
                initialValue: data.linkedArtifact,
                label: 'Linked artifacts',
                onChanged: (value) {
                  data.linkedArtifact = value;
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ResponsivePair(
            left: _TextFormField(
              initialValue: data.acceptanceCriteria,
              label: 'Acceptance criteria',
              maxLines: 3,
              onChanged: (value) {
                data.acceptanceCriteria = value;
                onChanged();
              },
            ),
            right: _TextFormField(
              initialValue: data.verificationMethod,
              label: 'Verification method',
              maxLines: 3,
              onChanged: (value) {
                data.verificationMethod = value;
                onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkItemCard extends StatelessWidget {
  const _WorkItemCard({
    required this.title,
    required this.data,
    required this.owners,
    required this.onChanged,
    required this.onRemove,
  });

  final String title;
  final DesignPlanningWorkItem data;
  final List<String> owners;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          _ResponsivePair(
            left: _TextFormField(
              initialValue: data.name,
              label: 'Name',
              onChanged: (value) {
                data.name = value;
                onChanged();
              },
            ),
            right: _TextFormField(
              initialValue: data.purpose,
              label: 'Purpose / notes',
              maxLines: 3,
              onChanged: (value) {
                data.purpose = value;
                onChanged();
              },
            ),
          ),
          const SizedBox(height: 12),
          _ResponsivePair(
            left: _DropdownField(
              value: data.owner,
              label: 'Owner',
              options: owners,
              onChanged: (value) {
                data.owner = value;
                onChanged();
              },
            ),
            right: _DropdownField(
              value: data.status,
              label: 'Status',
              options: _DesignPlanningScreenState._workStatusOptions,
              onChanged: (value) {
                data.status = value;
                onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecificationPlanRowCard extends StatelessWidget {
  const _SpecificationPlanRowCard({
    super.key,
    required this.index,
    required this.data,
    required this.owners,
    required this.requirementOptions,
    required this.specificationTypeOptions,
    required this.disciplineOptions,
    required this.areaOptions,
    required this.wbsWorkPackages,
    required this.sourceTypeOptions,
    required this.ruleTypeOptions,
    required this.statusOptions,
    required this.uploadsEnabled,
    required this.onChanged,
    required this.onUpload,
    required this.onRemove,
  });

  final int index;
  final DesignSpecificationPlanRow data;
  final List<String> owners;
  final List<_RequirementAttachmentOption> requirementOptions;
  final List<String> specificationTypeOptions;
  final List<String> disciplineOptions;
  final List<String> areaOptions;
  final List<_WbsWorkPackageOption> wbsWorkPackages;
  final List<String> sourceTypeOptions;
  final List<String> ruleTypeOptions;
  final List<String> statusOptions;
  final bool uploadsEnabled;
  final VoidCallback onChanged;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final wbsPackageLabels = wbsWorkPackages
        .map((item) => item.displayLabel)
        .toList(growable: false);
    String selectedWbsPackageLabel = '';
    if (data.wbsWorkPackageTitle.trim().isNotEmpty) {
      for (final item in wbsWorkPackages) {
        if (item.displayLabel == data.wbsWorkPackageTitle.trim()) {
          selectedWbsPackageLabel = item.displayLabel;
          break;
        }
      }
    }
    if (selectedWbsPackageLabel.isEmpty) {
      for (final item in wbsWorkPackages) {
        if (item.id == data.wbsWorkPackageId) {
          selectedWbsPackageLabel = item.displayLabel;
          break;
        }
      }
    }
    if (selectedWbsPackageLabel.isEmpty &&
        data.wbsWorkPackageTitle.trim().isNotEmpty) {
      selectedWbsPackageLabel = data.wbsWorkPackageTitle.trim();
    }
    final wbsValue = selectedWbsPackageLabel.isEmpty
        ? 'Not mapped'
        : selectedWbsPackageLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Spec Row $index',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (uploadsEnabled)
                TextButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Upload'),
                ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          _ResponsivePair(
            left: _TextFormField(
              initialValue: data.title,
              label: 'Title',
              onChanged: (value) {
                data.title = value;
                onChanged();
              },
            ),
            right: _TextFormField(
              initialValue: data.referenceLink,
              label: 'Reference link',
              onChanged: (value) {
                data.referenceLink = value;
                onChanged();
              },
            ),
          ),
          const SizedBox(height: 12),
          _TextFormField(
            initialValue: data.details,
            label: 'Details',
            maxLines: 3,
            onChanged: (value) {
              data.details = value;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          _RequirementMultiSelectField(
            label: 'Attached requirements',
            options: requirementOptions,
            selectedIds: data.attachedRequirementIds,
            onChanged: (ids) {
              data.attachedRequirementIds = ids;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          _FourColumnGrid(
            children: [
              _DropdownField(
                value: data.specificationType,
                label: 'Specification type',
                options: specificationTypeOptions,
                onChanged: (value) {
                  data.specificationType = value;
                  onChanged();
                },
              ),
              _DropdownField(
                value: data.ruleType,
                label: 'Source',
                options: ruleTypeOptions,
                onChanged: (value) {
                  data.ruleType = value;
                  onChanged();
                },
              ),
              _FilterableCreatableDropdownField(
                value: data.discipline,
                label: 'Discipline',
                options: disciplineOptions,
                onChanged: (value) {
                  data.discipline = value.trim();
                  onChanged();
                },
              ),
              _FilterableCreatableDropdownField(
                value: data.area,
                label: 'Area',
                options: areaOptions,
                onChanged: (value) {
                  data.area = value.trim();
                  onChanged();
                },
              ),
              _DropdownField(
                value: data.sourceType,
                label: 'Source type',
                options: sourceTypeOptions,
                onChanged: (value) {
                  data.sourceType = value;
                  onChanged();
                },
              ),
              _DropdownField(
                value: data.owner,
                label: 'Owner',
                options: owners,
                onChanged: (value) {
                  data.owner = value;
                  onChanged();
                },
              ),
              _DropdownField(
                value: data.status,
                label: 'Status',
                options: statusOptions,
                onChanged: (value) {
                  data.status = value;
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DropdownField(
            value: wbsValue,
            label: 'WBS work package',
            options: ['Not mapped', ...wbsPackageLabels],
            onChanged: (value) {
              if (value.trim() == 'Not mapped') {
                data.wbsWorkPackageId = '';
                data.wbsWorkPackageTitle = '';
                onChanged();
                return;
              }
              _WbsWorkPackageOption? selected;
              for (final item in wbsWorkPackages) {
                if (item.displayLabel == value) {
                  selected = item;
                  break;
                }
              }
              if (selected == null || value.trim().isEmpty) {
                data.wbsWorkPackageId = '';
                data.wbsWorkPackageTitle = '';
                onChanged();
                return;
              }
              data.wbsWorkPackageId = selected.id;
              data.wbsWorkPackageTitle = selected.displayLabel;
              if (data.discipline.trim().isEmpty &&
                  selected.disciplineSeed.trim().isNotEmpty) {
                data.discipline = selected.disciplineSeed.trim();
              }
              if (data.area.trim().isEmpty &&
                  selected.areaSeed.trim().isNotEmpty) {
                data.area = selected.areaSeed.trim();
              }
              onChanged();
            },
          ),
          if (data.uploadedFileName.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Uploaded file: ${data.uploadedFileName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpecificationDeviationCard extends StatelessWidget {
  const _SpecificationDeviationCard({
    super.key,
    required this.index,
    required this.data,
    required this.specificationOptions,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final DesignSpecificationDeviation data;
  final List<_SpecificationOption> specificationOptions;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final selectedId = specificationOptions.any(
      (item) => item.id == data.specificationId,
    )
        ? data.specificationId
        : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Deviation $index',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          if (specificationOptions.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: selectedId,
              isExpanded: true,
              decoration: _inputDecoration('Select specification item'),
              items: specificationOptions
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                data.specificationId = value;
                onChanged();
              },
            )
          else
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add specification rows before selecting a specification item.',
                style: TextStyle(fontSize: 12, color: _kMuted),
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: data.description,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDecoration('Deviation description'),
            onChanged: (value) {
              data.description = value;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _SpecificationDocumentCard extends StatelessWidget {
  const _SpecificationDocumentCard({
    super.key,
    required this.index,
    required this.data,
    required this.requirementOptions,
    required this.sourceTypeOptions,
    required this.uploadsEnabled,
    required this.onChanged,
    required this.onUpload,
    required this.onRemove,
  });

  final int index;
  final DesignPlanningReferenceDoc data;
  final List<_RequirementAttachmentOption> requirementOptions;
  final List<String> sourceTypeOptions;
  final bool uploadsEnabled;
  final VoidCallback onChanged;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Document $index',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (uploadsEnabled)
                TextButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Upload'),
                ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          _ResponsivePair(
            left: _TextFormField(
              initialValue: data.title,
              label: 'Title',
              onChanged: (value) {
                data.title = value;
                onChanged();
              },
            ),
            right: _DropdownField(
              value: data.category,
              label: 'Category',
              options: sourceTypeOptions,
              onChanged: (value) {
                data.category = value;
                onChanged();
              },
            ),
          ),
          const SizedBox(height: 12),
          _RequirementMultiSelectField(
            label: 'Attached requirements',
            options: requirementOptions,
            selectedIds: data.attachedRequirementIds,
            onChanged: (ids) {
              data.attachedRequirementIds = ids;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          _ResponsivePair(
            left: _TextFormField(
              initialValue: data.link,
              label: 'Link',
              onChanged: (value) {
                data.link = value;
                onChanged();
              },
            ),
            right: _TextFormField(
              initialValue: data.notes,
              label: 'Notes',
              maxLines: 2,
              onChanged: (value) {
                data.notes = value;
                onChanged();
              },
            ),
          ),
          if (data.fileName.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Uploaded file: ${data.fileName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({
    required this.data,
    required this.owners,
    required this.onChanged,
    required this.onRemove,
  });

  final DesignRiskEntry data;
  final List<String> owners;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Risk', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          _TextFormField(
            initialValue: data.risk,
            label: 'Risk',
            onChanged: (value) {
              data.risk = value;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          _FourColumnGrid(
            children: [
              _TextFormField(
                initialValue: data.impact,
                label: 'Impact',
                onChanged: (value) {
                  data.impact = value;
                  onChanged();
                },
              ),
              _TextFormField(
                initialValue: data.likelihood,
                label: 'Likelihood',
                onChanged: (value) {
                  data.likelihood = value;
                  onChanged();
                },
              ),
              _DropdownField(
                value: data.owner,
                label: 'Owner',
                options: owners,
                onChanged: (value) {
                  data.owner = value;
                  onChanged();
                },
              ),
              _DropdownField(
                value: data.status,
                label: 'Status',
                options: _DesignPlanningScreenState._riskStatusOptions,
                onChanged: (value) {
                  data.status = value;
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TextFormField(
            initialValue: data.mitigation,
            label: 'Mitigation',
            maxLines: 3,
            onChanged: (value) {
              data.mitigation = value;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _DependencyCard extends StatelessWidget {
  const _DependencyCard({
    required this.data,
    required this.owners,
    required this.onChanged,
    required this.onRemove,
  });

  final DesignDependencyEntry data;
  final List<String> owners;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Dependency',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          _ResponsivePair(
            left: _TextFormField(
              initialValue: data.name,
              label: 'Dependency',
              onChanged: (value) {
                data.name = value;
                onChanged();
              },
            ),
            right: _TextFormField(
              initialValue: data.source,
              label: 'Source',
              onChanged: (value) {
                data.source = value;
                onChanged();
              },
            ),
          ),
          const SizedBox(height: 12),
          _FourColumnGrid(
            children: [
              _DropdownField(
                value: data.type,
                label: 'Type',
                options: _DesignPlanningScreenState._dependencyTypeOptions,
                onChanged: (value) {
                  data.type = value;
                  onChanged();
                },
              ),
              _TextFormField(
                initialValue: data.neededBy,
                label: 'Needed by',
                onChanged: (value) {
                  data.neededBy = value;
                  onChanged();
                },
              ),
              _DropdownField(
                value: data.owner,
                label: 'Owner',
                options: owners,
                onChanged: (value) {
                  data.owner = value;
                  onChanged();
                },
              ),
              _DropdownField(
                value: data.status,
                label: 'Status',
                options: _DesignPlanningScreenState._workStatusOptions,
                onChanged: (value) {
                  data.status = value;
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TextFormField(
            initialValue: data.notes,
            label: 'Notes',
            maxLines: 3,
            onChanged: (value) {
              data.notes = value;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.data,
    required this.owners,
    required this.onChanged,
    required this.onRemove,
  });

  final DesignDecisionEntry data;
  final List<String> owners;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Decision',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          _TextFormField(
            initialValue: data.decision,
            label: 'Decision',
            onChanged: (value) {
              data.decision = value;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          _ResponsivePair(
            left: _TextFormField(
              initialValue: data.rationale,
              label: 'Rationale',
              maxLines: 3,
              onChanged: (value) {
                data.rationale = value;
                onChanged();
              },
            ),
            right: _TextFormField(
              initialValue: data.alternatives,
              label: 'Alternatives considered',
              maxLines: 3,
              onChanged: (value) {
                data.alternatives = value;
                onChanged();
              },
            ),
          ),
          const SizedBox(height: 12),
          _FourColumnGrid(
            children: [
              _DropdownField(
                value: data.owner,
                label: 'Owner',
                options: owners,
                onChanged: (value) {
                  data.owner = value;
                  onChanged();
                },
              ),
              _TextFormField(
                initialValue: data.date,
                label: 'Date',
                onChanged: (value) {
                  data.date = value;
                  onChanged();
                },
              ),
              _DropdownField(
                value: data.status,
                label: 'Status',
                options: _DesignPlanningScreenState._mappingStatusOptions,
                onChanged: (value) {
                  data.status = value;
                  onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    super.key,
    required this.data,
    required this.owners,
    required this.onChanged,
    required this.onRemove,
  });

  final DesignApprovalEntry data;
  final List<String> owners;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Reviewer',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          _ResponsivePair(
            left: _DropdownField(
              value: data.reviewer,
              label: 'Reviewer',
              options: owners,
              onChanged: (value) {
                data.reviewer = value;
                onChanged();
              },
            ),
            right: _TextFormField(
              initialValue: data.role,
              label: 'Role',
              onChanged: (value) {
                data.role = value;
                onChanged();
              },
            ),
          ),
          const SizedBox(height: 12),
          _ResponsivePair(
            left: _DropdownField(
              value: data.status,
              label: 'Status',
              options: _DesignPlanningScreenState._approvalStatusOptions,
              onChanged: (value) {
                data.status = value;
                onChanged();
              },
            ),
            right: _TextFormField(
              initialValue: data.comment,
              label: 'Comments',
              maxLines: 3,
              onChanged: (value) {
                data.comment = value;
                onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.label,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final String label;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final normalized = value.trim();
    final items =
        options.toSet().where((item) => item.trim().isNotEmpty).toList();
    if (normalized.isNotEmpty && !items.contains(normalized)) {
      items.insert(0, normalized);
    }
    if (items.isEmpty) {
      items.add('Select');
    }
    final selected = items.contains(normalized) ? normalized : items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          decoration: _inputDecoration(''),
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          selectedItemBuilder: (context) {
            return items
                .map(
                  (item) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList();
          },
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
      ],
    );
  }
}

class _FilterableCreatableDropdownField extends StatefulWidget {
  const _FilterableCreatableDropdownField({
    required this.value,
    required this.label,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final String label;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  State<_FilterableCreatableDropdownField> createState() =>
      _FilterableCreatableDropdownFieldState();
}

class _FilterableCreatableDropdownFieldState
    extends State<_FilterableCreatableDropdownField> {
  static const _createTokenPrefix = '__create__:';

  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.trim());
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _FilterableCreatableDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final next = widget.value.trim();
      if (_controller.text.trim() != next) {
        _controller.text = next;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<String> _normalizedOptions() {
    final deduped = <String>[];
    final seen = <String>{};
    for (final option in widget.options) {
      final normalized = option.trim();
      if (normalized.isEmpty) continue;
      final key = normalized.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      deduped.add(normalized);
    }
    return deduped;
  }

  Iterable<String> _buildOptions(String query) {
    final trimmed = query.trim();
    final all = _normalizedOptions();
    if (trimmed.isEmpty) return all;

    final needle = trimmed.toLowerCase();
    final matches = all
        .where((option) => option.toLowerCase().contains(needle))
        .toList(growable: false);
    if (matches.isNotEmpty) return matches;
    return ['$_createTokenPrefix$trimmed'];
  }

  String _displayLabel(String option) {
    if (option.startsWith(_createTokenPrefix)) {
      final custom = option.substring(_createTokenPrefix.length);
      return 'Create "$custom"';
    }
    return option;
  }

  String _resolvedValue(String option) {
    if (!option.startsWith(_createTokenPrefix)) return option;
    return option.substring(_createTokenPrefix.length);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 6),
        RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (textEditingValue) {
            return _buildOptions(textEditingValue.text);
          },
          displayStringForOption: _displayLabel,
          onSelected: (selected) {
            final value = _resolvedValue(selected).trim();
            _controller.text = value;
            widget.onChanged(value);
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: _inputDecoration(
                'Type to filter options. If no match, create custom.',
              ),
              onFieldSubmitted: (raw) {
                final value = raw.trim();
                if (value.isEmpty) return;
                widget.onChanged(value);
                onSubmitted();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final list = options.toList(growable: false);
            if (list.isEmpty) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                color: _kSurface,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 240,
                    minWidth: 260,
                    maxWidth: 440,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _kBorder),
                    itemBuilder: (context, index) {
                      final option = list[index];
                      final isCreate = option.startsWith(_createTokenPrefix);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCreate ? Icons.add_circle : Icons.list_alt,
                                size: 16,
                                color: isCreate ? _kPrimary : _kMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _displayLabel(option),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isCreate ? _kPrimary : _kText,
                                    fontWeight: isCreate
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RequirementAttachmentOption {
  const _RequirementAttachmentOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _SpecificationOption {
  const _SpecificationOption({
    required this.id,
    required this.title,
    this.details = '',
    this.specificationType = '',
    this.discipline = '',
    this.area = '',
    this.sourceType = '',
    this.owner = '',
    this.status = '',
    this.referenceLink = '',
    this.wbsWorkPackageId = '',
    this.wbsWorkPackageTitle = '',
  });

  final String id;
  final String title;
  final String details;
  final String specificationType;
  final String discipline;
  final String area;
  final String sourceType;
  final String owner;
  final String status;
  final String referenceLink;
  final String wbsWorkPackageId;
  final String wbsWorkPackageTitle;
}

class _WbsWorkPackageOption {
  const _WbsWorkPackageOption({
    required this.id,
    required this.title,
    required this.parentTitle,
    required this.level,
    required this.disciplineSeed,
    required this.areaSeed,
  });

  final String id;
  final String title;
  final String parentTitle;
  final int level;
  final String disciplineSeed;
  final String areaSeed;

  String get displayLabel {
    if (parentTitle.trim().isEmpty) return title;
    return '$parentTitle > $title';
  }
}

class _RequirementMultiSelectField extends StatelessWidget {
  const _RequirementMultiSelectField({
    required this.label,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
  });

  final String label;
  final List<_RequirementAttachmentOption> options;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  Future<void> _openSelector(BuildContext context) async {
    final selected = {...selectedIds};
    final searchController = TextEditingController();
    String query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = options.where((option) {
              return option.label.toLowerCase().contains(query.toLowerCase());
            }).toList(growable: false);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kText,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            selected.clear();
                            setModalState(() {});
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      decoration: _inputDecoration(
                        'Filter requirements by text',
                      ),
                      onChanged: (value) {
                        setModalState(() => query = value.trim());
                      },
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No matching requirements.',
                                style: TextStyle(color: _kMuted),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final option = filtered[index];
                                final checked = selected.contains(option.id);
                                return CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  value: checked,
                                  title: Text(
                                    option.label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onChanged: (value) {
                                    setModalState(() {
                                      if (value == true) {
                                        selected.add(option.id);
                                      } else {
                                        selected.remove(option.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          onChanged(selected.toList(growable: false));
                          Navigator.of(context).pop();
                        },
                        child: const Text('Apply selection'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelsById = {
      for (final option in options) option.id: option.label,
    };
    final selectedLabels = selectedIds
        .where((id) => id.trim().isNotEmpty)
        .map((id) => labelsById[id] ?? 'Requirement (unavailable)')
        .toList(growable: false);
    final summary =
        selectedLabels.isEmpty ? 'None' : '${selectedLabels.length} selected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: options.isEmpty ? null : () => _openSelector(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: _inputDecoration(
              options.isEmpty ? 'No requirements available' : '',
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    summary,
                    style: const TextStyle(color: _kText),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _kMuted,
                ),
              ],
            ),
          ),
        ),
        if (selectedLabels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selectedLabels
                .take(6)
                .map(
                  (label) => Chip(
                    label: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _TextFormField extends StatelessWidget {
  const _TextFormField({
    required this.initialValue,
    required this.label,
    required this.onChanged,
    this.maxLines = 1,
    this.suggestions = const [],
  });

  final String initialValue;
  final String label;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          decoration: _inputDecoration(
              suggestions.isEmpty ? '' : suggestions.join(', ')),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FourColumnGrid extends StatelessWidget {
  const _FourColumnGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final isTablet = AppBreakpoints.isTablet(context);
    final preferredColumns = isMobile ? 1 : (isTablet ? 2 : 4);
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 12.0;
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        var columns = preferredColumns;
        var available = maxWidth - (spacing * (columns - 1));
        while (columns > 1 && available <= 0) {
          columns -= 1;
          available = maxWidth - (spacing * (columns - 1));
        }
        final width = columns == 1
            ? maxWidth
            : (available <= 0 ? maxWidth : available / columns);
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(
                  width: width.clamp(0, double.infinity), child: child))
              .toList(),
        );
      },
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _kMuted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({required this.version, required this.onPressed});

  final String version;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: Text(
        'Version ${version.trim().isEmpty ? 'v1.0' : version.trim()}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _kText,
        side: const BorderSide(color: _kBorder),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _DropdownBadge extends StatelessWidget {
  const _DropdownBadge({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    this.primary = false,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = primary
        ? ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: _kText,
            side: const BorderSide(color: _kBorder),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          );
    final child = primary ? ElevatedButton.icon : OutlinedButton.icon;
    return child(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: style,
    );
  }
}

class _AutoSaveIndicator extends StatelessWidget {
  const _AutoSaveIndicator({
    required this.saving,
    required this.pending,
    required this.lastSavedAt,
  });

  final bool saving;
  final bool pending;
  final DateTime? lastSavedAt;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    late final Color background;
    late final IconData icon;
    if (saving) {
      label = 'Auto-save: saving...';
      color = const Color(0xFF0F62FE);
      background = const Color(0xFFE9F0FF);
      icon = Icons.sync;
    } else if (pending) {
      label = 'Auto-save: unsaved changes';
      color = const Color(0xFFB45309);
      background = const Color(0xFFFFF7ED);
      icon = Icons.schedule;
    } else if (lastSavedAt != null) {
      label =
          'Auto-save: saved ${TimeOfDay.fromDateTime(lastSavedAt!).format(context)}';
      color = const Color(0xFF15803D);
      background = const Color(0xFFECFDF3);
      icon = Icons.check_circle_outline;
    } else {
      label = 'Auto-save: waiting for first change';
      color = _kMuted;
      background = const Color(0xFFF8FAFC);
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistActions extends StatelessWidget {
  const _AssistActions({
    required this.onAutofill,
    required this.onGenerate,
    required this.generating,
  });

  final VoidCallback onAutofill;
  final VoidCallback onGenerate;
  final bool generating;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: onAutofill,
            icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
            label: const Text('Autofill From Context'),
          ),
          ElevatedButton.icon(
            onPressed: generating ? null : onGenerate,
            icon: generating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 16),
            label: Text(generating ? 'Generating...' : 'Generate With AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
            ),
          ),
          TextButton.icon(
            onPressed: generating ? null : onGenerate,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kText,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        const Spacer(),
        _InlineAddButton(label: actionLabel, onPressed: onAction),
      ],
    );
  }
}

class _InlineAddButton extends StatelessWidget {
  const _InlineAddButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 16),
      label: Text(label),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: _kMuted, height: 1.45),
      ),
    );
  }
}

class _UploadedDoc {
  const _UploadedDoc({
    required this.name,
    required this.url,
    required this.storagePath,
  });

  final String name;
  final String url;
  final String storagePath;
}

InputDecoration _inputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText.isEmpty ? null : hintText,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kPrimary),
    ),
  );
}
