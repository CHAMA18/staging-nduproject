import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
import 'package:ndu_project/utils/planning_phase_navigation.dart';

const Color _kSurfaceBackground = Color(0xFFF7F8FC);
const Color _kAccentColor = Color(0xFFFFC812);
const Color _kPrimaryText = Color(0xFF1A1D1F);
const Color _kSecondaryText = Color(0xFF6B7280);
const Color _kCardBorder = Color(0xFFE4E7EC);

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
  static const int _maxWbsDepth = 3;
  static const List<Map<String, String>> _criteriaOptions = [
    {
      'value': 'Project Area',
      'description': 'Segment work by functional zones or geographical regions',
    },
    {
      'value': 'Discipline',
      'description': 'Segment work by professional specialty or skill set',
    },
    {
      'value': 'Contract Type',
      'description': 'Segment by contractual boundaries and vendor agreements',
    },
    {
      'value': 'Sub Scope',
      'description': 'Segment into logical sub-projects or feature modules',
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
  bool _isAiLoading = false;
  List<WorkItem> _wbsItems = [];
  final List<String> _goalTitles = List.filled(3, '');
  final List<String> _goalDescriptions = List.filled(3, '');
  final Set<String> _collapsedNodeIds = {};
  Map<String, dynamic>? _contextSnapshot;
  DateTime? _contextCapturedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final projectData = ProjectDataHelper.getProvider(context).projectData;
      _selectedCriteriaA = projectData.wbsCriteriaA;
      _syncGoalContext(projectData);

      _wbsItems = projectData.wbsTree;
      if (_wbsItems.isEmpty &&
          projectData.goalWorkItems.any((list) => list.isNotEmpty)) {
        _migrateFromGoalsToTree(projectData.goalWorkItems);
      }

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
            const SnackBar(
              content: Text('Maximum WBS depth is Level 3.'),
              backgroundColor: Color(0xFFEF4444),
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
  }

  Future<WorkItem?> _openAddNodeDialog(
      {String parentId = '', WorkItem? existingNode}) async {
    final titleController = TextEditingController(text: existingNode?.title);
    final descriptionController =
        TextEditingController(text: existingNode?.description);
    final formKey = GlobalKey<FormState>();
    var selectedStatus = existingNode?.status ?? 'not_started';
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
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Title'),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Please enter a title'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
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
                  result = existingNode;
                } else {
                  result = WorkItem(
                    parentId: parentId,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    status: selectedStatus,
                  );
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
      final contextSnapshot = _buildContextSnapshot(projectData);
      final generatedItems = await OpenAiServiceSecure().generateWbsStructure(
        projectName: projectData.projectName,
        projectObjective: projectData.projectObjective,
        dimension: dimension,
        dimensionDescription: _getDimensionDescription(dimension),
        goals: projectData.projectGoals,
      );

      if (generatedItems.isNotEmpty) {
        setState(() {
          _trimWbsDepth(generatedItems, _maxWbsDepth);
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
    for (var i = 0; i < 3; i++) {
      _goalTitles[i] = '';
      _goalDescriptions[i] = '';
    }

    for (var i = 0; i < data.planningGoals.length && i < 3; i++) {
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

    for (var i = 0; i < data.projectGoals.length && i < 3; i++) {
      if (_goalTitles[i].isEmpty) {
        _goalTitles[i] = data.projectGoals[i].name.trim();
      }
      if (_goalDescriptions[i].isEmpty) {
        _goalDescriptions[i] = data.projectGoals[i].description.trim();
      }
    }
  }

  Widget _buildCriteriaDropdown(
      {required String hint,
      required String? value,
      required ValueChanged<String?> onChanged}) {
    return SizedBox(
      width: 280,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kCardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kCardBorder),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: _kSecondaryText),
        items: _criteriaOptions
            .map((option) => DropdownMenuItem<String>(
                  value: option['value'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(option['value']!,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kPrimaryText)),
                      Text(option['description']!,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: _kSecondaryText)),
                    ],
                  ),
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
      ),
    );
  }

  Widget _buildCriteriaRow() {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 24,
      runSpacing: 16,
      children: [
        const Text(
          'Breakdown Dimension:',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: _kPrimaryText),
        ),
        _buildCriteriaDropdown(
          hint: 'Select',
          value: _selectedCriteriaA,
          onChanged: (value) => setState(() => _selectedCriteriaA = value),
        ),
        if (_isAiLoading)
          const SizedBox(
            width: 24,
            height: 24,
            child:
                CircularProgressIndicator(strokeWidth: 3, color: _kAccentColor),
          ),
        ElevatedButton.icon(
          onPressed: _isAiLoading ? null : _handleGenerateWbsAi,
          icon: _isAiLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(_isAiLoading ? 'Generating...' : 'Suggest Structure'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAccentColor,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildWbsTreeView() {
    if (_wbsItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_tree_outlined,
                size: 64, color: _kSecondaryText),
            const SizedBox(height: 16),
            const Text(
              'No WBS items yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kSecondaryText),
            ),
            const SizedBox(height: 24),
            _buildAddTopLevelButton(),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 48, 48),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _wbsItems.length; i++) ...[
              _buildWbsNodeRecursive(_wbsItems[i], path: [i + 1]),
              const SizedBox(width: 32),
            ],
            _buildAddTopLevelButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWbsNodeRecursive(WorkItem item, {required List<int> path}) {
    final isCollapsed = _collapsedNodeIds.contains(item.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWbsNodeCard(item, path: path),
        if (item.children.isNotEmpty && !isCollapsed) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < item.children.length; i++) ...[
                  _buildWbsNodeRecursive(item.children[i],
                      path: [...path, i + 1]),
                  if (i != item.children.length - 1) const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWbsNodeCard(WorkItem item, {required List<int> path}) {
    final level = path.length - 1;
    final nodeColor = _getNodeColor(level);
    final canAddChild = path.length < _maxWbsDepth;
    final displayTitle = _formatWbsTitle(path: path, title: item.title);
    final isCollapsed = _collapsedNodeIds.contains(item.id);
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: nodeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _kPrimaryText),
                      ),
                    ),
                    _buildStatusIcon(item.status),
                    if (item.children.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _toggleCollapse(item),
                        child: Icon(
                          isCollapsed
                              ? Icons.chevron_right
                              : Icons.expand_more,
                          size: 18,
                          color: _kSecondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kSecondaryText),
                  ),
                ],
                if (item.children.isNotEmpty && isCollapsed) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${item.children.length} sub-items hidden',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kSecondaryText),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _handleEditNode(item),
                      child: const Icon(Icons.edit_outlined,
                          size: 18, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _handleDeleteNode(item),
                      child: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        if (!canAddChild) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Maximum WBS depth is Level 3.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }
                        _handleAddNode(parent: item);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: (_kAccentColor.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add,
                            size: 18, color: _kPrimaryText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTopLevelButton() {
    return GestureDetector(
      onTap: () => _handleAddNode(),
      child: Container(
        width: 280,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kCardBorder, style: BorderStyle.none),
        ),
        child: _DottedBorder(
          color: _kCardBorder,
          strokeWidth: 2,
          dashPattern: const [8, 4],
          borderType: BorderType.rRect,
          radius: const Radius.circular(16),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: _kSecondaryText),
                SizedBox(height: 4),
                Text(
                  'Add Main Segment',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kSecondaryText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNodeColor(int level) {
    switch (level) {
      case 0:
        return const Color(0xFFFF5252); // Red
      case 1:
        return const Color(0xFF00BFA5); // Cyan (teal-ish)
      case 2:
        return const Color(0xFFFFD54F); // Yellow
      default:
        return Colors.blueGrey.shade100;
    }
  }

  String _formatWbsTitle({
    required List<int> path,
    required String title,
  }) {
    if (path.isEmpty) return title;
    final goalIndex = path.first;
    final suffix = path.length > 1 ? '.${path.sublist(1).join('.')}' : '';
    final label = 'G$goalIndex$suffix';
    final cleanTitle = _stripWbsPrefix(title);
    return '$label: $cleanTitle';
  }

  String _stripWbsPrefix(String title) {
    final pattern = RegExp(r'^G\d+(?:\.\d+)*:\s*');
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

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'completed':
        icon = Icons.check_circle;
        color = const Color(0xFF059669);
        break;
      case 'in_progress':
        icon = Icons.pending;
        color = const Color(0xFF2563EB);
        break;
      default:
        icon = Icons.radio_button_unchecked;
        color = Colors.grey;
    }
    return Icon(icon, size: 16, color: color);
  }

  Widget _buildNotesCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: const PlanningAiNotesCard(
        title: 'Notes',
        sectionLabel: 'Work Breakdown Structure',
        noteKey: 'planning_wbs_notes',
        checkpoint: 'wbs',
        description:
            'Summarize the WBS structure, criteria decisions, and any key dependencies.',
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFBFD9FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'The WBS is a breakdown of the project into manageable bitesize components for more effective execution. This is dependent on the project type and could be by project area, sub scope, discipline, contract, or a different criteria.',
        style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimaryText),
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
    final projectObjective =
        (contextData['projectObjective'] ?? '').toString();
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Project Context Used For WBS',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _kPrimaryText),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _downloadContextPdf(contextData),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Download PDF'),
              ),
            ],
          ),
          Text(
            caption,
            style: const TextStyle(fontSize: 11, color: _kSecondaryText),
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
                final description =
                    (goalMap['description'] ?? '').toString();
                final framework = (goalMap['framework'] ?? '').toString();
                if (name.trim().isEmpty && description.trim().isEmpty) {
                  return const SizedBox.shrink();
                }
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kCardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Goal',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kPrimaryText),
                      ),
                      if (description.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondaryText),
                        ),
                      ],
                      if (framework.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Framework: $framework',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondaryText),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
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

  @override
  Widget build(BuildContext context) {
    final padding = AppBreakpoints.pagePadding(context);
    final isMobile = AppBreakpoints.isMobile(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      color: _kSurfaceBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FrontEndPlanningHeader(title: 'Work Breakdown Structure'),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : padding * 1.5,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoBanner(),
                              const SizedBox(height: 20),
                              _buildContextCard(),
                              const SizedBox(height: 28),
                              _buildCriteriaRow(),
                              const SizedBox(height: 32),
                              _buildWbsTreeView(),
                              const SizedBox(height: 28),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _buildNotesCard(),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            final navIndex = PlanningPhaseNavigation.getPageIndex(
                                'work_breakdown_structure');
                            if (navIndex > 0) {
                              final prevPage =
                                  PlanningPhaseNavigation.pages[navIndex - 1];
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: prevPage.builder),
                              );
                            } else {
                              Navigator.maybePop(context);
                            }
                          },
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF374151),
                            elevation: 0,
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final navIndex =
                                PlanningPhaseNavigation.getPageIndex(
                                    'work_breakdown_structure');
                            if (navIndex != -1 &&
                                navIndex <
                                    PlanningPhaseNavigation.pages.length - 1) {
                              final nextPage =
                                  PlanningPhaseNavigation.pages[navIndex + 1];

                              await ProjectDataHelper.saveAndNavigate(
                                context: context,
                                checkpoint: 'work_breakdown_structure',
                                saveInBackground: true,
                                nextScreenBuilder: () =>
                                    nextPage.builder(context),
                                dataUpdater: (data) => data.copyWith(
                                  wbsCriteriaA: _selectedCriteriaA,
                                  wbsTree: _wbsItems,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC044),
                            foregroundColor: const Color(0xFF111827),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
