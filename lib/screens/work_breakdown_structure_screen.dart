import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/download_helper.dart' as download_helper;
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/services/project_route_registry.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/screens/project_framework_next_screen.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';

import 'package:ndu_project/widgets/voice_text_field.dart';
const Color _kSurfaceBackground = Color(0xFFFCFCFC);
const Color _kAccentColor = Color(0xFFFFC107);
const Color _kPrimaryText = Color(0xFF212529);
const Color _kSecondaryText = Color(0xFF495057);
const Color _kCardBorder = Color(0xFFE9ECEF);
const Color _kTextLight = Color(0xFF868E96);
const Color _kGrayBg = Color(0xFFF8F9FA);
const Color _kInfoBg = Color(0xFFE8F0FE);
const Color _kInfoText = Color(0xFF1A73E8);
const Color _kStatusBlue = Color(0xFF0D6EFD);
const Color _kStatusRed = Color(0xFFDC3545);

class WorkBreakdownStructureScreen extends StatelessWidget {
  const WorkBreakdownStructureScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WorkBreakdownStructureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurfaceBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DraggableSidebar(
                  openWidth: AppBreakpoints.sidebarWidth(context),
                  child: const InitiationLikeSidebar(
                      activeItemLabel: 'Work Breakdown Structure'),
                ),
                Expanded(child: _WorkBreakdownStructureBody()),
              ],
            ),
            const KazAiChatBubble(),
          ],
        ),
      ),
    );
  }
}

class _WorkBreakdownStructureBody extends StatefulWidget {
  const _WorkBreakdownStructureBody();

  @override
  State<_WorkBreakdownStructureBody> createState() =>
      _WorkBreakdownStructureBodyState();
}

class _WorkBreakdownStructureBodyState
    extends State<_WorkBreakdownStructureBody> {
  static const int _maxWbsDepth = 5;
  static const List<Map<String, String>> _criteriaOptions = [
    {
      'value': 'Deliverable',
      'description':
          'Focuses on what must be produced, not activities. Standard approach.',
    },
    {
      'value': 'Discipline',
      'description':
          'Segment by major components or systems (e.g., structural, electrical).',
    },
    {
      'value': 'Functional Areas',
      'description':
          'Organize by who performs the work (department designation).',
    },
    {
      'value': 'Geographic Location',
      'description': 'Used in multi-site projects or infrastructure rollouts.',
    },
    {
      'value': 'Project Phases',
      'description': 'Least preferred. Based on lifecycle stages.',
    },
  ];

  String _getDimensionDescription(String? value) {
    if (value == null) return '';
    final option = _criteriaOptions.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'value': '', 'description': ''},
    );
    return option['description'] ?? '';
  }

  String? _selectedCriteriaA;
  String _overallFramework = '';
  bool _isAiLoading = false;
  List<WorkItem> _wbsItems = [];
  final List<String> _goalTitles = List.filled(5, '');
  final List<String> _goalDescriptions = List.filled(5, '');
  final Set<String> _collapsedNodeIds = {};
  bool _contextExpanded = false;
  Map<String, dynamic>? _contextSnapshot;
  DateTime? _contextCapturedAt;

  String? _projectId() => ProjectDataHelper.getData(context).projectId;

  Future<bool> _isSectionInitialized(String flagKey) async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('planning_meta')
          .doc('initialization_flags')
          .get();
      return doc.data()?[flagKey] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markSectionInitialized(String flagKey) async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('planning_meta')
          .doc('initialization_flags')
          .set({flagKey: true, '${flagKey}_at': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (_) {}
  }

  void _syncWbsToProvider() {
    if (!mounted) return;
    ProjectDataHelper.getProvider(context).updateWBSData(wbsTree: _wbsItems);
    if (_wbsItems.isNotEmpty) {
      _markSectionInitialized('wbs_initialized');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final projectData = ProjectDataHelper.getProvider(context).projectData;
      _selectedCriteriaA = projectData.wbsCriteriaA;
      _overallFramework = projectData.overallFramework ?? '';
      _syncGoalContext(projectData);

      _wbsItems = projectData.wbsTree;
      if (_wbsItems.isEmpty &&
          projectData.goalWorkItems.any((list) => list.isNotEmpty)) {
        final wbsInitialized = await _isSectionInitialized('wbs_initialized');
        if (!wbsInitialized) {
          _migrateFromGoalsToTree(projectData.goalWorkItems);
          _syncWbsToProvider();
        }
      }
      _syncGoalFrameworks(projectData);
      _applyOverallFrameworkRules(projectData);

      setState(() {});
    });
  }

  void _migrateFromGoalsToTree(List<List<WorkItem>> goalWorkItems) {
    for (int i = 0; i < goalWorkItems.length; i++) {
      if (goalWorkItems[i].isNotEmpty) {
        final goalTitle =
            _goalTitles[i].isNotEmpty ? _goalTitles[i] : 'Goal ${i + 1}';
        final goalNode =
            WorkItem(title: goalTitle, description: _goalDescriptions[i]);
        goalNode.children.addAll(goalWorkItems[i]);
        _wbsItems.add(goalNode);
      }
    }
  }

  Future<void> _handleAddNode({WorkItem? parent}) async {
    if (parent != null) {
      final parentDepth = _getDepthForNode(parent);
      if (parentDepth >= _maxWbsDepth) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum WBS depth is Level $_maxWbsDepth.'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
        return;
      }
    }
    final newNode = await _openAddNodeDialog(parentId: parent?.id ?? '');
    if (newNode == null) return;

    setState(() {
      if (parent == null) {
        _wbsItems.add(newNode);
      } else {
        parent.children.add(newNode);
        _collapsedNodeIds.remove(parent.id);
      }
    });
    _syncWbsToProvider();
  }

  Future<WorkItem?> _openAddNodeDialog(
      {String parentId = '', WorkItem? existingNode}) async {
    final titleController = TextEditingController(text: existingNode?.title);
    final descriptionController =
        TextEditingController(text: existingNode?.description);
    final formKey = GlobalKey<FormState>();
    var selectedStatus = existingNode?.status ?? 'not_started';
    var selectedFramework = _sanitizeFramework(existingNode?.framework ?? '');
    WorkItem? result;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            existingNode != null
                ? 'Edit Item'
                : (parentId.isEmpty
                    ? 'Create Main Segment'
                    : 'Create Sub-Deliverable'),
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: _kPrimaryText),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 550,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VoiceTextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Title'),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Please enter a title'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        VoiceTextFormField(
                          controller: descriptionController,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          minLines: 3,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: const InputDecoration(
                              labelText: 'Initial Status'),
                          items: const [
                            DropdownMenuItem(
                                value: 'not_started',
                                child: Text('Not Started')),
                            DropdownMenuItem(
                                value: 'in_progress',
                                child: Text('In Progress')),
                            DropdownMenuItem(
                                value: 'completed', child: Text('Completed')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setStateDialog(() => selectedStatus = value);
                            }
                          },
                        ),
                        if (parentId.isEmpty && _isHybridOverall) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: selectedFramework.isEmpty
                                ? null
                                : selectedFramework,
                            decoration: const InputDecoration(
                                labelText: 'Framework (Goal level)'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Waterfall', child: Text('Waterfall')),
                              DropdownMenuItem(
                                  value: 'Agile', child: Text('Agile')),
                            ],
                            onChanged: (value) {
                              setStateDialog(
                                  () => selectedFramework = value ?? '');
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;

                if (existingNode != null) {
                  existingNode.title = titleController.text.trim();
                  existingNode.description = descriptionController.text.trim();
                  existingNode.status = selectedStatus;
                  if (existingNode.parentId.isEmpty) {
                    existingNode.framework = _resolveTopLevelFramework(
                      selectedFramework,
                    );
                    if (existingNode.framework.isNotEmpty) {
                      _applyFrameworkToSubtree(
                          existingNode, existingNode.framework);
                    }
                  }
                  result = existingNode;
                } else {
                  result = WorkItem(
                    parentId: parentId,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    status: selectedStatus,
                    framework: parentId.isEmpty
                        ? _resolveTopLevelFramework(selectedFramework)
                        : '',
                  );
                  if (result != null && result!.framework.isNotEmpty) {
                    _applyFrameworkToSubtree(result!, result!.framework);
                  }
                }
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccentColor,
                foregroundColor: _kPrimaryText,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(existingNode != null ? 'Update' : 'Create'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<void> _handleEditNode(WorkItem node) async {
    final updated = await _openAddNodeDialog(existingNode: node);
    if (updated != null) {
      setState(() {});
      _syncWbsToProvider();
    }
  }

  void _handleDeleteNode(WorkItem node) {
    setState(() {
      if (node.parentId.isEmpty) {
        _wbsItems.remove(node);
      } else {
        _removeNodeFromChildren(_wbsItems, node);
      }
      _removeCollapsedIds(node);
    });
    _syncWbsToProvider();
  }

  void _removeNodeFromChildren(List<WorkItem> items, WorkItem nodeToRemove) {
    for (var item in items) {
      if (item.children.contains(nodeToRemove)) {
        item.children.remove(nodeToRemove);
        return;
      }
      _removeNodeFromChildren(item.children, nodeToRemove);
    }
  }

  void _removeCollapsedIds(WorkItem node) {
    _collapsedNodeIds.remove(node.id);
    for (final child in node.children) {
      _removeCollapsedIds(child);
    }
  }

  Future<void> _handleGenerateWbsAi() async {
    final projectData = ProjectDataHelper.getProvider(context).projectData;
    final dimension = _selectedCriteriaA;
    if (dimension == null || dimension.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Breakdown Dimension first.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Show loading
    setState(() {
      _isAiLoading = true;
    });

    try {
      final goalsForAi = _prepareGoalsForGeneration(projectData);
      final contextSnapshot = _buildContextSnapshot(projectData);
      final generatedItems = await OpenAiServiceSecure().generateWbsStructure(
        projectName: projectData.projectName,
        projectObjective: projectData.projectObjective,
        dimension: dimension,
        dimensionDescription: _getDimensionDescription(dimension),
        goals: goalsForAi,
        overallFramework: _overallFramework,
      );

      if (generatedItems.isNotEmpty) {
        setState(() {
          _trimWbsDepth(generatedItems, _maxWbsDepth);
          _applyFrameworksToGeneratedItems(
            generatedItems,
            goalsForAi,
            _overallFramework,
          );
          _wbsItems = generatedItems;
          _contextSnapshot = contextSnapshot;
          _contextCapturedAt = DateTime.now();
        });

        if (mounted) {
          final provider = ProjectDataHelper.getProvider(context);
          provider.updateWBSData(wbsTree: _wbsItems);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WBS Structure updated'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate suggest structure: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiLoading = false;
        });
      }
    }
  }

  void _syncGoalContext(ProjectDataModel data) {
    for (var i = 0; i < 5; i++) {
      _goalTitles[i] = '';
      _goalDescriptions[i] = '';
    }

    for (var i = 0; i < data.planningGoals.length && i < 5; i++) {
      final planningGoal = data.planningGoals[i];
      final title = planningGoal.title.trim();
      final description = planningGoal.description.trim();
      final targetYear = planningGoal.targetYear.trim();
      if (title.isNotEmpty) {
        _goalTitles[i] = title;
      }
      if (description.isNotEmpty) {
        _goalDescriptions[i] = description;
      } else if (targetYear.isNotEmpty) {
        _goalDescriptions[i] = 'Target year: $targetYear';
      }
    }

    for (var i = 0; i < data.projectGoals.length && i < 5; i++) {
      if (_goalTitles[i].isEmpty) {
        _goalTitles[i] = data.projectGoals[i].name.trim();
      }
      if (_goalDescriptions[i].isEmpty) {
        _goalDescriptions[i] = data.projectGoals[i].description.trim();
      }
    }
  }

  void _syncGoalFrameworks(ProjectDataModel data) {
    if (_wbsItems.isEmpty || data.projectGoals.isEmpty) return;
    var updatedGoals = false;
    final goals = List<ProjectGoal>.from(data.projectGoals);

    for (int i = 0; i < _wbsItems.length && i < goals.length; i++) {
      final item = _wbsItems[i];
      final goal = goals[i];
      final itemFramework = item.framework.trim();
      final goalFramework = (goal.framework ?? '').trim();

      if (itemFramework.isEmpty && goalFramework.isNotEmpty) {
        item.framework = goalFramework;
      } else if (itemFramework.isNotEmpty && goalFramework.isEmpty) {
        goals[i] = ProjectGoal(
          name: goal.name,
          description: goal.description,
          framework: itemFramework,
        );
        updatedGoals = true;
      }
    }

    if (updatedGoals) {
      ProjectDataHelper.getProvider(context).updateField(
        (data) => data.copyWith(projectGoals: goals),
      );
    }
  }

  bool get _isHybridOverall => _overallFramework == 'Hybrid';

  String _sanitizeFramework(String value) {
    if (_isHybridOverall) {
      return (value == 'Waterfall' || value == 'Agile') ? value : '';
    }
    return (_overallFramework == 'Waterfall' || _overallFramework == 'Agile')
        ? _overallFramework
        : '';
  }

  String _resolveTopLevelFramework(String selectedFramework) {
    if (_isHybridOverall) {
      return (selectedFramework == 'Waterfall' || selectedFramework == 'Agile')
          ? selectedFramework
          : '';
    }
    return (_overallFramework == 'Waterfall' || _overallFramework == 'Agile')
        ? _overallFramework
        : '';
  }

  void _applyFrameworkToSubtree(WorkItem item, String framework) {
    item.framework = framework;
    for (final child in item.children) {
      _applyFrameworkToSubtree(child, framework);
    }
  }

  void _applyOverallFrameworkRules(ProjectDataModel data) {
    final overall = _overallFramework;
    if (overall != 'Waterfall' && overall != 'Agile') {
      // Hybrid or unset: normalize any invalid framework values.
      var normalized = false;
      for (final item in _wbsItems) {
        final cleaned = _sanitizeFramework(item.framework);
        if (item.framework != cleaned) {
          item.framework = cleaned;
          if (cleaned.isNotEmpty) {
            _applyFrameworkToSubtree(item, cleaned);
          }
          normalized = true;
        }
      }
      if (normalized) {
        ProjectDataHelper.getProvider(context)
            .updateWBSData(wbsTree: _wbsItems);
      }
      return;
    }

    var updatedGoals = false;
    final goals = List<ProjectGoal>.from(data.projectGoals);
    for (int i = 0; i < goals.length; i++) {
      final goal = goals[i];
      if (goal.framework != overall) {
        goals[i] = ProjectGoal(
          name: goal.name,
          description: goal.description,
          framework: overall,
        );
        updatedGoals = true;
      }
    }
    if (updatedGoals) {
      ProjectDataHelper.getProvider(context)
          .updateField((data) => data.copyWith(projectGoals: goals));
    }

    if (_wbsItems.isNotEmpty) {
      for (final item in _wbsItems) {
        _applyFrameworkToSubtree(item, overall);
      }
      ProjectDataHelper.getProvider(context).updateWBSData(wbsTree: _wbsItems);
    }
  }

  Future<void> _updateCriteriaSelection(String? value) async {
    setState(() => _selectedCriteriaA = value);
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'work_breakdown_structure',
      dataUpdater: (data) => data.copyWith(wbsCriteriaA: value),
      showSnackbar: false,
    );
  }

  Widget _buildCriteriaDropdown(
      {required String hint,
      required String? value,
      required ValueChanged<String?> onChanged}) {
    final normalizedValue =
        _criteriaOptions.any((o) => o['value'] == value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: normalizedValue,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kAccentColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _kTextLight, size: 18),
      items: _criteriaOptions
          .map((option) => DropdownMenuItem<String>(
                value: option['value'],
                child: Text(option['value']!,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimaryText)),
              ))
          .toList(),
      onChanged: onChanged,
      hint: Text(hint,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kSecondaryText)),
      selectedItemBuilder: (context) => _criteriaOptions
          .map((option) => Align(
                alignment: Alignment.centerLeft,
                child: Text(option['value']!,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimaryText)),
              ))
          .toList(),
    );
  }

  Widget _buildControlsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Breakdown Dimension:',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimaryText),
          ),
          const SizedBox(height: 6),
          _buildCriteriaDropdown(
            hint: 'Select',
            value: _selectedCriteriaA,
            onChanged: _updateCriteriaSelection,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isAiLoading ||
                      _selectedCriteriaA == null ||
                      _selectedCriteriaA!.isEmpty)
                  ? null
                  : _handleGenerateWbsAi,
              icon: _isAiLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kPrimaryText),
                    )
                  : const Icon(Icons.auto_fix_high, size: 18),
              label: Text(_isAiLoading ? 'Generating...' : 'Suggest Structure'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGrayBg,
                foregroundColor: _kPrimaryText,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                side: const BorderSide(color: _kCardBorder),
                elevation: 0,
                shadowColor: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWbsSegmentList() {
    if (_wbsItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.account_tree_outlined,
                size: 48, color: _kTextLight),
            const SizedBox(height: 12),
            const Text(
              'No WBS items yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kTextLight),
            ),
            const SizedBox(height: 16),
            _buildAddTopLevelButton(),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _wbsItems.length; i++) ...[
            _buildSegmentCard(_wbsItems[i], path: [i + 1]),
            const SizedBox(height: 12),
          ],
          _buildAddTopLevelButton(),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(WorkItem item, {required List<int> path}) {
    final isCollapsed = _collapsedNodeIds.contains(item.id);
    final level = path.length - 1;
    final canAddChild = path.length < _maxWbsDepth;
    final goalIndex = path.isNotEmpty ? path.first - 1 : 0;
    final isTopLevel = level == 0;
    final segmentLabel = path.isEmpty ? '' : 'S${path.first}';
    final cleanTitle = _stripWbsPrefix(item.title);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Red top border for all segments
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: _kStatusRed,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ),
          // Content area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with segment label, title, and status dot
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (segmentLabel.isNotEmpty) ...[
                            Text(
                              '$segmentLabel:',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimaryText,
                                  height: 1.2),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: GestureDetector(
                              onTap: item.children.isNotEmpty ? () => _toggleCollapse(item) : null,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      cleanTitle,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: _kPrimaryText,
                                          height: 1.2),
                                    ),
                                  ),
                                  if (item.children.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      isCollapsed ? Icons.chevron_right : Icons.expand_more,
                                      size: 20,
                                      color: _kTextLight,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusDot(item.status),
                  ],
                ),
                // Description
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: _kSecondaryText,
                        height: 1.4),
                  ),
                ],
                // Framework dropdown for top-level items
                if (isTopLevel) ...[
                  const SizedBox(height: 8),
                  _buildFrameworkDropdown(item, goalIndex),
                ],
                // Collapsed sub-items indicator
                if (item.children.isNotEmpty && isCollapsed) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${item.children.length} sub-items hidden',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _kTextLight),
                  ),
                ],
              ],
            ),
          ),
          // Bottom action row with top border divider
          const SizedBox(height: 8),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit button
                Tooltip(
                  message: 'Edit',
                  child: InkWell(
                    onTap: () => _handleEditNode(item),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined, size: 20, color: _kTextLight),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete button
                Tooltip(
                  message: 'Delete',
                  child: InkWell(
                    onTap: () => _handleDeleteNode(item),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline, size: 20, color: _kTextLight),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Add sub-segment button
                Tooltip(
                  message: 'Add Sub-segment',
                  child: InkWell(
                    onTap: () {
                      if (!canAddChild) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Maximum WBS depth is Level $_maxWbsDepth.'),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                        return;
                      }
                      _handleAddNode(parent: item);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.add, size: 20, color: _kTextLight),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Nested sub-segment cards (when expanded)
          if (item.children.isNotEmpty && !isCollapsed) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < item.children.length; i++) ...[
                    _buildSegmentCard(item.children[i], path: [...path, i + 1]),
                    if (i != item.children.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusDot(String status) {
    Color dotColor;
    bool filled;
    switch (status) {
      case 'completed':
        dotColor = _kStatusBlue;
        filled = true;
        break;
      case 'in_progress':
        dotColor = _kStatusBlue;
        filled = true;
        break;
      default:
        dotColor = _kTextLight;
        filled = false;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: filled ? dotColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: dotColor, width: 2),
      ),
    );
  }

  Widget _buildAddTopLevelButton() {
    return GestureDetector(
      onTap: () => _handleAddNode(),
      child: _DottedBorder(
        color: _kCardBorder,
        strokeWidth: 2,
        dashPattern: const [8, 4],
        borderType: BorderType.rRect,
        radius: const Radius.circular(6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kGrayBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 22, color: _kTextLight),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add Main Segment',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _kTextLight),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatWbsTitle({
    required List<int> path,
    required String title,
  }) {
    if (path.isEmpty) return title;
    final goalIndex = path.first;
    final suffix = path.length > 1 ? '.${path.sublist(1).join('.')}' : '';
    final label = 'S$goalIndex$suffix';
    final cleanTitle = _stripWbsPrefix(title);
    return '$label: $cleanTitle';
  }

  String _stripWbsPrefix(String title) {
    final pattern = RegExp(r'^[GS]\d+(?:\.\d+)*(?:\s*[:\-])?\s*');
    return title.replaceFirst(pattern, '');
  }

  void _trimWbsDepth(List<WorkItem> items, int maxDepth,
      {int currentDepth = 1}) {
    for (final item in items) {
      if (currentDepth >= maxDepth) {
        item.children.clear();
      } else {
        _trimWbsDepth(item.children, maxDepth, currentDepth: currentDepth + 1);
      }
    }
  }

  int _getDepthForNode(WorkItem node) {
    int maxDepth = 0;
    bool found = false;

    void visit(List<WorkItem> items, int depth) {
      for (final item in items) {
        if (found) return;
        if (identical(item, node) || item.id == node.id) {
          maxDepth = depth;
          found = true;
          return;
        }
        if (item.children.isNotEmpty) {
          visit(item.children, depth + 1);
        }
      }
    }

    visit(_wbsItems, 1);
    return maxDepth;
  }

  Widget _buildFrameworkDropdown(WorkItem item, int goalIndex) {
    if (!_isHybridOverall) {
      final framework = _sanitizeFramework(item.framework);
      if (framework.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kCardBorder),
        ),
        child: Text(
          'Framework: $framework',
          style: const TextStyle(fontSize: 12, color: _kSecondaryText),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: item.framework.isEmpty ? null : item.framework,
      isDense: true,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kCardBorder),
        ),
      ),
      hint: const Text(
        'Select framework',
        style: TextStyle(fontSize: 12, color: _kSecondaryText),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _kSecondaryText, size: 18),
      items: const [
        DropdownMenuItem(value: 'Waterfall', child: Text('Waterfall')),
        DropdownMenuItem(value: 'Agile', child: Text('Agile')),
      ],
      onChanged: (value) {
        final framework = value ?? '';
        setState(() {
          item.framework = framework;
          if (framework.isNotEmpty) {
            _applyFrameworkToSubtree(item, framework);
          }
        });
        _updateGoalFramework(goalIndex, framework);
      },
    );
  }

  void _updateGoalFramework(int goalIndex, String framework) {
    final provider = ProjectDataHelper.getProvider(context);
    final goals = List<ProjectGoal>.from(provider.projectData.projectGoals);
    if (goalIndex < 0 || goalIndex >= goals.length) return;
    final goal = goals[goalIndex];
    goals[goalIndex] = ProjectGoal(
      name: goal.name,
      description: goal.description,
      framework: framework,
    );
    provider.updateField((data) => data.copyWith(projectGoals: goals));
    if (goalIndex >= 0 && goalIndex < _wbsItems.length) {
      final item = _wbsItems[goalIndex];
      if (framework.isNotEmpty) {
        _applyFrameworkToSubtree(item, framework);
      }
      provider.updateWBSData(wbsTree: _wbsItems);
    }
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _WbsNotesCard(
        description:
            'Summarize the WBS structure, criteria decisions, and any key dependencies.',
        noteKey: 'planning_wbs_notes',
        checkpoint: 'wbs',
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _kInfoBg,
        border: Border(bottom: BorderSide(color: Color(0xFFBBDEFB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, size: 16, color: _kInfoText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'The WBS is a breakdown of the project into manageable bitesize components for more effective execution. This is dependent on the project type and could be by project area, sub scope, discipline, contract, or a different criteria.',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w400, color: _kInfoText, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleCollapse(WorkItem item) {
    setState(() {
      if (_collapsedNodeIds.contains(item.id)) {
        _collapsedNodeIds.remove(item.id);
      } else {
        _collapsedNodeIds.add(item.id);
      }
    });
  }

  Map<String, dynamic> _buildContextSnapshot(ProjectDataModel data) {
    final dimension = _selectedCriteriaA;
    return {
      'projectName': data.projectName,
      'projectObjective': data.projectObjective,
      'breakdownDimension': dimension ?? '',
      'dimensionDescription':
          dimension == null ? '' : _getDimensionDescription(dimension),
      'goals': data.projectGoals
          .map((g) => {
                'name': g.name,
                'description': g.description,
                if (g.framework != null && g.framework!.isNotEmpty)
                  'framework': g.framework,
              })
          .toList(),
    };
  }

  List<ProjectGoal> _prepareGoalsForGeneration(ProjectDataModel data) {
    final overall = _overallFramework;
    final goals = List<ProjectGoal>.from(data.projectGoals);
    var updated = false;

    if (overall == 'Waterfall' || overall == 'Agile') {
      for (int i = 0; i < goals.length; i++) {
        if (goals[i].framework != overall) {
          goals[i] = ProjectGoal(
            name: goals[i].name,
            description: goals[i].description,
            framework: overall,
          );
          updated = true;
        }
      }
    } else if (overall == 'Hybrid') {
      for (int i = 0; i < goals.length; i++) {
        final framework = goals[i].framework ?? '';
        if (framework == 'Hybrid') {
          goals[i] = ProjectGoal(
            name: goals[i].name,
            description: goals[i].description,
            framework: '',
          );
          updated = true;
        }
      }
    }

    if (updated) {
      ProjectDataHelper.getProvider(context)
          .updateField((data) => data.copyWith(projectGoals: goals));
    }
    return goals;
  }

  void _applyFrameworksToGeneratedItems(
    List<WorkItem> items,
    List<ProjectGoal> goals,
    String overall,
  ) {
    if (overall == 'Waterfall' || overall == 'Agile') {
      for (final item in items) {
        _applyFrameworkToSubtree(item, overall);
      }
      return;
    }

    if (overall == 'Hybrid') {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final itemFramework = _sanitizeFramework(item.framework);
        final goalFramework =
            i < goals.length ? (goals[i].framework ?? '') : '';
        final resolved = itemFramework.isNotEmpty
            ? itemFramework
            : _sanitizeFramework(goalFramework);
        if (resolved.isNotEmpty) {
          _applyFrameworkToSubtree(item, resolved);
        } else {
          item.framework = '';
        }
      }
    }
  }

  String _formatCapturedAt(DateTime? capturedAt) {
    if (capturedAt == null) return '';
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatFullDate(capturedAt);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(capturedAt),
      alwaysUse24HourFormat: false,
    );
    return '$date at $time';
  }

  String _formatPdfTimestamp(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  pw.Widget _pdfField(String label, String value) {
    final display = value.trim().isEmpty ? 'Not provided' : value.trim();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          display,
          style: const pw.TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _downloadContextPdf(Map<String, dynamic> contextData) async {
    final filename =
        'wbs_project_context_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final goals = (contextData['goals'] as List?) ?? const [];
    final projectName = (contextData['projectName'] ?? '').toString();
    final projectObjective = (contextData['projectObjective'] ?? '').toString();
    final dimension = (contextData['breakdownDimension'] ?? '').toString();
    final dimensionDescription =
        (contextData['dimensionDescription'] ?? '').toString();
    final capturedAt = _contextCapturedAt;

    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (_) => [
            pw.Text(
              'Project Context Used For WBS',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              capturedAt != null
                  ? 'Captured: ${_formatPdfTimestamp(capturedAt)}'
                  : 'Generated: ${_formatPdfTimestamp(DateTime.now())}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 16),
            _pdfField('Project Name', projectName),
            pw.SizedBox(height: 10),
            _pdfField('Project Objective', projectObjective),
            pw.SizedBox(height: 10),
            _pdfField(
              'Breakdown Dimension',
              dimension.isNotEmpty ? dimension : 'Not selected',
            ),
            if (dimensionDescription.trim().isNotEmpty) ...[
              pw.SizedBox(height: 10),
              _pdfField('Dimension Rationale', dimensionDescription),
            ],
            pw.SizedBox(height: 16),
            pw.Text(
              'Project Goals',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            if (goals.isEmpty)
              pw.Text(
                'No project goals provided.',
                style: const pw.TextStyle(fontSize: 11),
              )
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: List.generate(goals.length, (index) {
                  final goal = goals[index];
                  final goalMap = goal is Map
                      ? Map<String, dynamic>.from(goal)
                      : <String, dynamic>{};
                  final name = (goalMap['name'] ?? '').toString().trim();
                  final description =
                      (goalMap['description'] ?? '').toString().trim();
                  final framework =
                      (goalMap['framework'] ?? '').toString().trim();
                  final title = name.isNotEmpty ? name : 'Goal ${index + 1}';
                  final detailParts = <String>[];
                  if (description.isNotEmpty) detailParts.add(description);
                  if (framework.isNotEmpty) {
                    detailParts.add('Framework: $framework');
                  }
                  final details = detailParts.join(' | ');
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      details.isNotEmpty
                          ? '${index + 1}. $title - $details'
                          : '${index + 1}. $title',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  );
                }),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF ready: $filename')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create PDF: $e')),
      );
    }
  }

  Widget _buildContextCard() {
    final data = ProjectDataHelper.getProvider(context).projectData;
    final contextData = _contextSnapshot ?? _buildContextSnapshot(data);
    final dimension = (contextData['breakdownDimension'] ?? '').toString();
    final dimensionDescription =
        (contextData['dimensionDescription'] ?? '').toString();
    final goals = (contextData['goals'] as List?) ?? const [];
    final hasSnapshot = _contextSnapshot != null;
    final caption = hasSnapshot
        ? 'Captured ${_formatCapturedAt(_contextCapturedAt)}'
        : 'Current project context (no AI snapshot yet).';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _contextExpanded = !_contextExpanded),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Project Context Used For WBS',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimaryText),
                    ),
                  ),
                  Icon(
                    _contextExpanded ? Icons.expand_less : Icons.keyboard_arrow_down,
                    color: _kTextLight,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_contextExpanded) ...[
            const Divider(height: 1, color: _kCardBorder),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          caption,
                          style: const TextStyle(fontSize: 11, color: _kTextLight),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _downloadContextPdf(contextData),
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: const Text('Download PDF'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildContextField(
                      'Project Name', (contextData['projectName'] ?? '').toString()),
                  const SizedBox(height: 12),
                  _buildContextField('Project Objective',
                      (contextData['projectObjective'] ?? '').toString()),
                  const SizedBox(height: 12),
                  _buildContextField(
                    'Breakdown Dimension',
                    dimension.isNotEmpty ? dimension : 'Not selected',
                  ),
                  if (dimension.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildContextField('Dimension Rationale', dimensionDescription),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Project Goals',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kPrimaryText),
                  ),
                  const SizedBox(height: 8),
                  if (goals.isEmpty)
                    const Text(
                      'No project goals provided yet.',
                      style: TextStyle(fontSize: 12, color: _kSecondaryText),
                    )
                  else
                    Column(
                      children: goals.map((goal) {
                        final goalMap = goal is Map
                            ? goal
                            : {'name': '', 'description': goal.toString()};
                        final name = (goalMap['name'] ?? '').toString();
                        final description = (goalMap['description'] ?? '').toString();
                        final framework = (goalMap['framework'] ?? '').toString();
                        if (name.trim().isEmpty && description.trim().isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _kGrayBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _kCardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isNotEmpty ? name : 'Goal',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimaryText),
                              ),
                              if (description.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: const TextStyle(
                                      fontSize: 12, color: _kSecondaryText),
                                ),
                              ],
                              if (framework.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Framework: $framework',
                                  style: const TextStyle(
                                      fontSize: 11, color: _kTextLight),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContextField(String label, String value) {
    final display = value.trim().isEmpty ? 'Not provided' : value.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kSecondaryText),
        ),
        const SizedBox(height: 4),
        Text(
          display,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimaryText),
        ),
      ],
    );
  }

  // ignore: unused_element
  Future<void> _handleNextPressed() async {
    // Use ProjectRouteRegistry to find next accessible screen
    final nextScreen =
        ProjectRouteRegistry.getNextScreen(context, 'work_breakdown_structure');

    if (nextScreen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No next screen available')),
      );
      return;
    }

    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'work_breakdown_structure',
      saveInBackground: true,
      nextScreenBuilder: () => nextScreen,
      dataUpdater: (data) => data.copyWith(
        wbsCriteriaA: _selectedCriteriaA,
        wbsTree: _wbsItems,
      ),
    );
  }

  Widget _buildBreadcrumbsAndTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kCardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Planning Phase',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kTextLight),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_right, size: 14, color: _kTextLight),
              const SizedBox(width: 4),
              Text(
                'Work Breakdown Structure',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kPrimaryText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Work Breakdown Structure',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _kPrimaryText,
                letterSpacing: -0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kCardBorder)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: () => PlanningPhaseNavigation.goToPrevious(
              context,
              'work_breakdown_structure',
            ),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _kPrimaryText,
              elevation: 0,
              side: const BorderSide(color: _kCardBorder),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final nextScreen =
                  PlanningPhaseNavigation.resolveNextScreen(
                        context,
                        'work_breakdown_structure',
                      ) ??
                      const ProjectFrameworkNextScreen();

              await ProjectDataHelper.saveAndNavigate(
                context: context,
                checkpoint: 'work_breakdown_structure',
                saveInBackground: true,
                nextScreenBuilder: () => nextScreen,
                dataUpdater: (data) => data.copyWith(
                  wbsCriteriaA: _selectedCriteriaA,
                  wbsTree: _wbsItems,
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccentColor,
              foregroundColor: _kPrimaryText,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              side: const BorderSide(color: Color(0xFFFFB300)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurfaceBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FrontEndPlanningHeader(title: 'Work Breakdown Structure'),
          _buildBreadcrumbsAndTitle(),
          _buildInfoBanner(),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildControlsSection(),
                      const SizedBox(height: 12),
                      _buildContextCard(),
                      const SizedBox(height: 16),
                      _buildWbsSegmentList(),
                      const SizedBox(height: 16),
                      _buildNotesSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomNavigationBar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;

  const _DottedBorder({
    required this.child,
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.dashPattern = const [3, 1],
    this.borderType = BorderType.rRect,
    this.radius = Radius.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashPattern: dashPattern,
        borderType: borderType,
        radius: radius,
      ),
      child: child,
    );
  }
}

enum BorderType {
  rRect,
  rect,
  circle,
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;

  _DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
    required this.borderType,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path;
    switch (borderType) {
      case BorderType.rRect:
        path = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Offset.zero & size,
            radius,
          ));
        break;
      case BorderType.rect:
        path = Path()..addRect(Offset.zero & size);
        break;
      case BorderType.circle:
        path = Path()..addOval(Offset.zero & size);
        break;
    }

    final dashPath = _dashPath(path, dashPattern);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path source, List<double> dashPattern) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      int i = 0;
      while (distance < metric.length) {
        final double len = dashPattern[i];
        if (draw) {
          dest.addPath(
              metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
        i = (i + 1) % dashPattern.length;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// WBS Notes Card — matches the HTML design's inline notes section with
// sparkle icon header, format button, and textarea, while retaining
// Firebase persistence through ProjectDataHelper.
// ---------------------------------------------------------------------------
class _WbsNotesCard extends StatefulWidget {
  final String description;
  final String noteKey;
  final String checkpoint;

  const _WbsNotesCard({
    required this.description,
    required this.noteKey,
    required this.checkpoint,
  });

  @override
  State<_WbsNotesCard> createState() => _WbsNotesCardState();
}

class _WbsNotesCardState extends State<_WbsNotesCard> {
  late TextEditingController _controller;
  String _currentText = '';
  bool _saving = false;
  DateTime? _lastSavedAt;
  bool _didInit = false;
  Timer? _debounceTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final stored =
        ProjectDataHelper.getData(context).planningNotes[widget.noteKey] ?? '';
    _currentText = stored.trim();
    _controller = TextEditingController(text: _currentText);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final trimmed = value.trim();
    if (trimmed == _currentText) return;
    setState(() {
      _currentText = trimmed;
    });

    // Update in-memory state
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField((data) => data.copyWith(
      planningNotes: {
        ...data.planningNotes,
        widget.noteKey: trimmed,
      },
    ));

    // Debounced save
    _scheduleSave();
  }

  void _scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), _saveNow);
  }

  Future<void> _saveNow() async {
    if (_saving) return;
    _saving = true;
    try {
      await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: widget.checkpoint,
        showSnackbar: false,
        dataUpdater: (data) => data.copyWith(
          planningNotes: {
            ...data.planningNotes,
            widget.noteKey: _currentText,
          },
        ),
      );
      if (mounted) {
        setState(() {
          _lastSavedAt = DateTime.now();
        });
      }
    } catch (_) {
      // Silent fail
    } finally {
      _saving = false;
    }
  }

  String _formatSaveTime(DateTime? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return 'Saved $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(bottom: BorderSide(color: _kCardBorder)),
            ),
            child: Row(
              children: [
                // Sparkle icon + "Notes" label
                const Icon(Icons.auto_awesome, size: 18, color: _kAccentColor),
                const SizedBox(width: 8),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kAccentColor,
                  ),
                ),
                const Spacer(),
                // Save status
                if (_saving)
                  const Text(
                    'Saving...',
                    style: TextStyle(fontSize: 11, color: _kTextLight),
                  )
                else if (_lastSavedAt != null)
                  Text(
                    _formatSaveTime(_lastSavedAt),
                    style: const TextStyle(fontSize: 11, color: _kTextLight),
                  ),
                if (_lastSavedAt != null || _saving)
                  const SizedBox(width: 8),
                // History button
                Tooltip(
                  message: 'History',
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.history, size: 18, color: _kTextLight),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Undo button
                Tooltip(
                  message: 'Undo',
                  child: InkWell(
                    onTap: () {
                      _controller.clear();
                      _handleChanged('');
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.undo, size: 18, color: _kTextLight),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _kSecondaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Format button
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: _kCardBorder),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.text_fields, size: 14, color: _kTextLight),
                        SizedBox(width: 4),
                        Text(
                          'Format',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kTextLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Textarea
                TextField(
                  controller: _controller,
                  onChanged: _handleChanged,
                  maxLines: 4,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _kPrimaryText,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Capture the key decisions and details for this section...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _kTextLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
