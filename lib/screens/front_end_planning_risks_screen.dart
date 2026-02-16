import 'package:flutter/material.dart';
import 'package:ndu_project/screens/front_end_planning_opportunities_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';

/// Front End Planning – Project Risks page
/// Matches the provided screenshot with:
/// - Top bar (back/forward, centered title, user chip)
/// - Notes field
/// - "Project Risks (Highlight and quantify known and/or anticipated risks here)" title
/// - Table with columns: Risk | Project | Category | Probability | Impact | Risk Level | Status | Ac
/// - Bottom-left info circle, bottom-right AI hint and yellow Next button
class FrontEndPlanningRisksScreen extends StatefulWidget {
  const FrontEndPlanningRisksScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FrontEndPlanningRisksScreen()),
    );
  }

  @override
  State<FrontEndPlanningRisksScreen> createState() =>
      _FrontEndPlanningRisksScreenState();
}

class _FrontEndPlanningRisksScreenState
    extends State<FrontEndPlanningRisksScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSyncReady = false;
  bool _isApplyingNotesSummary = false;

  // Backing rows for the table; built from incoming requirements (if any).
  late List<_RiskItem> _rows;
  bool _isGeneratingRequirements = false;

  @override
  void initState() {
    super.initState();
    _rows = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectData = ProjectDataHelper.getData(context);
      _notesController.text =
          _summarizeNotesText(projectData.frontEndPlanning.risks);
      _notesController.addListener(_syncRisksToProvider);
      _isSyncReady = true;
      _syncRisksToProvider();

      // Load existing risks from saved data if available
      _loadSavedRisks(projectData);

      // Generate risks if no existing risks OR if risks exist but have empty risk fields
      if (_rows.isEmpty ||
          _rows.any((r) => r.risk.isEmpty || r.category.isEmpty)) {
        _generateRequirementsFromBusinessCase();
      }

      if (mounted) setState(() {});
    });
  }

  void _loadSavedRisks(ProjectDataModel data) {
    // Try to load from saved risks text first
    final savedRisksText = data.frontEndPlanning.risks.trim();
    if (savedRisksText.isNotEmpty) {
      // Parse risks from text format (if any)
      // For now, we'll rely on AI generation or manual entry
    }

    // Load requirements from Project Requirements collection
    final requirements = data.frontEndPlanning.requirementItems;
    if (requirements.isNotEmpty) {
      // Create risk items from requirements
      _rows = requirements.asMap().entries.map((entry) {
        final req = entry.value;
        return _RiskItem(
          id: _generateId(entry.key + 1),
          requirement: req.description,
          requirementType: req.requirementType,
          risk: '', // Will be filled by AI or user
          description: '',
          category: '',
          probability: '',
          impact: '',
          riskValue: '',
          riskLevel: '',
          mitigation: '',
          discipline: '',
          owner: '',
          status: 'Identified',
        );
      }).toList();
    }
  }

  Future<void> _regenerateAllRisks() async {
    await _generateRequirementsFromBusinessCase();
  }

  Future<void> _generateRequirementsFromBusinessCase() async {
    setState(() => _isGeneratingRequirements = true);
    final data = ProjectDataHelper.getData(context);
    final provider = ProjectDataHelper.getProvider(context);
    final requirements = data.frontEndPlanning.requirementItems;

    try {
      // Track field history before regenerating
      for (final row in _rows) {
        if (row.risk.trim().isNotEmpty) {
          provider.addFieldToHistory(
            'fep_risk_${row.id}_risk',
            row.risk,
            isAiGenerated: true,
          );
        }
        if (row.description.trim().isNotEmpty) {
          provider.addFieldToHistory(
            'fep_risk_${row.id}_description',
            row.description,
            isAiGenerated: true,
          );
        }
      }

      final ctx = ProjectDataHelper.buildFepContext(data,
          sectionLabel: 'Project Risks');
      final aiService = OpenAiServiceSecure();

      // Generate risks with all fields (Title, Category, Probability, Impact, Mitigation)
      // Request enough risks to match the number of requirements (or at least 8)
      final riskCount = requirements.isNotEmpty ? requirements.length : 8;
      final risks = await aiService.generateFepRisks(ctx, minCount: riskCount);

      if (!mounted) return;
      setState(() {
        // If we have requirements, map risks to requirements
        if (requirements.isNotEmpty) {
          // Ensure we have at least as many risks as requirements
          // If we have fewer risks than requirements, cycle through risks
          _rows = requirements.asMap().entries.map((entry) {
            final reqIndex = entry.key;
            final req = entry.value;
            final riskIndex =
                reqIndex < risks.length ? reqIndex : reqIndex % risks.length;
            final riskData = risks[riskIndex];

            // Calculate risk level from probability and impact
            final prob = riskData['probability']?.toLowerCase() ?? 'medium';
            final impact = riskData['impact']?.toLowerCase() ?? 'medium';
            String riskLevel = 'Medium';
            if ((prob == 'high' && impact == 'high') ||
                (prob == 'high' && impact == 'medium') ||
                (prob == 'medium' && impact == 'high')) {
              riskLevel = 'High';
            } else if ((prob == 'low' && impact == 'low') ||
                (prob == 'low' && impact == 'medium') ||
                (prob == 'medium' && impact == 'low')) {
              riskLevel = 'Low';
            }

            // Generate a more detailed description based on the risk title and requirement
            final riskTitle = riskData['title'] ?? '';
            final riskDescription = riskTitle.isNotEmpty
                ? '$riskTitle. This risk is associated with: ${req.description}'
                : req.description;

            final riskItem = _RiskItem(
              id: _generateId(entry.key + 1),
              requirement: req.description, // Pull from requirements
              requirementType: req.requirementType, // Pull from requirements
              risk: riskTitle,
              description: riskDescription,
              category: riskData['category'] ?? '',
              probability: riskData['probability'] ?? '',
              impact: riskData['impact'] ?? '',
              riskValue: '', // Can be calculated later if needed
              riskLevel: riskLevel,
              mitigation: (riskData['mitigationStrategy'] ?? '')
                      .toString()
                      .trim()
                      .isNotEmpty
                  ? (riskData['mitigationStrategy'] ?? '').toString().trim()
                  : 'Assign an owner, define mitigation actions, and monitor early warning indicators.',
              discipline: '', // Can be filled by user later
              owner: '', // Can be filled by user later
              status: 'Identified',
            );

            // Track AI-generated content in field history
            if (riskTitle.isNotEmpty) {
              provider.addFieldToHistory(
                'fep_risk_${riskItem.id}_risk',
                riskTitle,
                isAiGenerated: true,
              );
            }
            if (riskDescription.isNotEmpty) {
              provider.addFieldToHistory(
                'fep_risk_${riskItem.id}_description',
                riskDescription,
                isAiGenerated: true,
              );
            }

            return riskItem;
          }).toList();
        } else {
          // No requirements, generate risks without requirement mapping
          _rows = risks.asMap().entries.map((entry) {
            final riskData = entry.value;
            // Calculate risk level from probability and impact
            final prob = riskData['probability']?.toLowerCase() ?? 'medium';
            final impact = riskData['impact']?.toLowerCase() ?? 'medium';
            String riskLevel = 'Medium';
            if ((prob == 'high' && impact == 'high') ||
                (prob == 'high' && impact == 'medium') ||
                (prob == 'medium' && impact == 'high')) {
              riskLevel = 'High';
            } else if ((prob == 'low' && impact == 'low') ||
                (prob == 'low' && impact == 'medium') ||
                (prob == 'medium' && impact == 'low')) {
              riskLevel = 'Low';
            }

            final riskItem = _RiskItem(
              id: _generateId(entry.key + 1),
              requirement: '',
              requirementType: '',
              risk: riskData['title'] ?? '',
              description:
                  riskData['title'] ?? '', // Use title as description initially
              category: riskData['category'] ?? '',
              probability: riskData['probability'] ?? '',
              impact: riskData['impact'] ?? '',
              riskValue: '',
              riskLevel: riskLevel,
              mitigation: (riskData['mitigationStrategy'] ?? '')
                      .toString()
                      .trim()
                      .isNotEmpty
                  ? (riskData['mitigationStrategy'] ?? '').toString().trim()
                  : 'Assign an owner, define mitigation actions, and monitor early warning indicators.',
              discipline: '',
              owner: '',
              status: 'Identified',
            );

            // Track AI-generated content in field history
            final riskTitle = riskData['title'] ?? '';
            if (riskTitle.isNotEmpty) {
              provider.addFieldToHistory(
                'fep_risk_${riskItem.id}_risk',
                riskTitle,
                isAiGenerated: true,
              );
            }
            if (riskTitle.isNotEmpty) {
              provider.addFieldToHistory(
                'fep_risk_${riskItem.id}_description',
                riskTitle,
                isAiGenerated: true,
              );
            }

            return riskItem;
          }).toList();
        }
        _isGeneratingRequirements = false;
      });
      _syncRisksToProvider();
    } catch (e) {
      if (!mounted) return;
      debugPrint('Risk generation failed: $e');
      // Even on error, risks should have been generated via fallback
      // But if _rows is still empty, create some basic risks from requirements
      if (_rows.isEmpty) {
        final requirements = data.frontEndPlanning.requirementItems;
        if (requirements.isNotEmpty) {
          setState(() {
            _rows = requirements.asMap().entries.map((entry) {
              final req = entry.value;
              return _RiskItem(
                id: _generateId(entry.key + 1),
                requirement: req.description,
                requirementType: req.requirementType,
                risk: 'Risk associated with ${req.description}',
                description: 'Potential risk related to: ${req.description}',
                category: 'Technical',
                probability: 'Medium',
                impact: 'Medium',
                riskValue: '',
                riskLevel: 'Medium',
                mitigation: '',
                discipline: '',
                owner: '',
                status: 'Identified',
              );
            }).toList();
            _isGeneratingRequirements = false;
          });
          _syncRisksToProvider();
        } else {
          setState(() => _isGeneratingRequirements = false);
        }
      } else {
        setState(() => _isGeneratingRequirements = false);
      }
    }
  }

  String _generateId(int number) {
    return number.toString().padLeft(3, '0');
  }

  void _addNewRisk() {
    setState(() {
      _rows.add(_RiskItem(
        id: _generateId(_rows.length + 1),
        requirement: '',
        requirementType: '',
        risk: '',
        description: '',
        category: '',
        probability: '',
        impact: '',
        riskValue: '',
        riskLevel: '',
        mitigation: '',
        discipline: '',
        owner: '',
        status: '',
      ));
    });
    // Open edit dialog for the new item
    Future.delayed(const Duration(milliseconds: 100), () {
      _showEditRiskSheet(_rows.length - 1);
    });
  }

  Future<void> _showEditRiskSheet(int index) async {
    if (index < 0 || index >= _rows.length) return;
    final current = _rows[index];

    final idCtrl = TextEditingController(text: current.id);
    final requirementCtrl = TextEditingController(text: current.requirement);
    final riskCtrl = TextEditingController(text: current.risk);
    final descriptionCtrl = TextEditingController(text: current.description);
    final categoryCtrl = TextEditingController(text: current.category);
    final riskValueCtrl = TextEditingController(text: current.riskValue);
    final mitigationCtrl = TextEditingController(text: current.mitigation);
    final disciplineCtrl = TextEditingController(text: current.discipline);
    final ownerCtrl = TextEditingController(text: current.owner);
    // Dropdown options
    const requirementTypeOptions = [
      'Functional',
      'Non-Functional',
      'Technical',
      'Business',
      'Regulatory'
    ];
    const probabilityOptions = ['High', 'Medium', 'Low'];
    const impactOptions = ['High', 'Medium', 'Low'];
    const riskLevelOptions = ['Critical', 'Moderate', 'Low'];
    const statusOptions = ['Open', 'Mitigated', 'Closed'];

    String selectedRequirementType =
        current.requirementType.isEmpty ? '' : current.requirementType;
    String selectedProbability =
        current.probability.isEmpty ? '' : current.probability;
    String selectedImpact = current.impact.isEmpty ? '' : current.impact;
    String selectedRiskLevel =
        current.riskLevel.isEmpty ? '' : current.riskLevel;
    String selectedStatus = current.status.isEmpty ? '' : current.status;

    // Ensure custom previously-saved values still appear in dropdowns
    List<String> requirementTypeItems = [
      ...requirementTypeOptions,
      if (selectedRequirementType.isNotEmpty &&
          !requirementTypeOptions.contains(selectedRequirementType))
        selectedRequirementType,
    ];
    List<String> probabilityItems = [
      ...probabilityOptions,
      if (selectedProbability.isNotEmpty &&
          !probabilityOptions.contains(selectedProbability))
        selectedProbability,
    ];
    List<String> impactItems = [
      ...impactOptions,
      if (selectedImpact.isNotEmpty && !impactOptions.contains(selectedImpact))
        selectedImpact,
    ];
    List<String> riskLevelItems = [
      ...riskLevelOptions,
      if (selectedRiskLevel.isNotEmpty &&
          !riskLevelOptions.contains(selectedRiskLevel))
        selectedRiskLevel,
    ];
    List<String> statusItems = [
      ...statusOptions,
      if (selectedStatus.isNotEmpty && !statusOptions.contains(selectedStatus))
        selectedStatus,
    ];

    final result = await showDialog<_RiskItem>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(20, 16, 20, 16 + viewInsets.bottom),
                child: StatefulBuilder(
                  builder: (ctx, setLocal) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.edit_note, color: Color(0xFF111827)),
                              SizedBox(width: 8),
                              Text('Edit Risk',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _LabeledField(
                              label: 'ID', controller: idCtrl, enabled: false),
                          const SizedBox(height: 12),
                          _LabeledField(
                              label: 'Requirement',
                              controller: requirementCtrl,
                              autofocus: true),
                          const SizedBox(height: 12),
                          _LabeledDropdown(
                            label: 'Requirement Type',
                            value: selectedRequirementType.isEmpty
                                ? null
                                : selectedRequirementType,
                            hint: 'e.g. Functional/Technical',
                            items: requirementTypeItems,
                            onChanged: (v) => setLocal(
                                () => selectedRequirementType = v ?? ''),
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                              label: 'Risk Title', controller: riskCtrl),
                          const SizedBox(height: 12),
                          _LabeledField(
                              label: 'Description',
                              controller: descriptionCtrl),
                          const SizedBox(height: 12),
                          _LabeledField(
                              label: 'Category', controller: categoryCtrl),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _LabeledDropdown(
                                  label: 'Probability',
                                  value: selectedProbability.isEmpty
                                      ? null
                                      : selectedProbability,
                                  hint: 'e.g. High/Medium/Low',
                                  items: probabilityItems,
                                  onChanged: (v) => setLocal(
                                      () => selectedProbability = v ?? ''),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _LabeledDropdown(
                                  label: 'Impact',
                                  value: selectedImpact.isEmpty
                                      ? null
                                      : selectedImpact,
                                  hint: 'e.g. High/Medium/Low',
                                  items: impactItems,
                                  onChanged: (v) =>
                                      setLocal(() => selectedImpact = v ?? ''),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                              label: 'Risk Value', controller: riskValueCtrl),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _LabeledDropdown(
                                  label: 'Risk Level',
                                  value: selectedRiskLevel.isEmpty
                                      ? null
                                      : selectedRiskLevel,
                                  hint: 'e.g. Critical/Moderate/Low',
                                  items: riskLevelItems,
                                  onChanged: (v) => setLocal(
                                      () => selectedRiskLevel = v ?? ''),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _LabeledDropdown(
                                  label: 'Status',
                                  value: selectedStatus.isEmpty
                                      ? null
                                      : selectedStatus,
                                  hint: 'e.g. Open/Mitigated/Closed',
                                  items: statusItems,
                                  onChanged: (v) =>
                                      setLocal(() => selectedStatus = v ?? ''),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                              label: 'Mitigation', controller: mitigationCtrl),
                          const SizedBox(height: 12),
                          _LabeledField(
                              label: 'Discipline', controller: disciplineCtrl),
                          const SizedBox(height: 12),
                          _LabeledField(label: 'Owner', controller: ownerCtrl),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(null),
                                child: const Text('Cancel'),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check,
                                    color: Colors.black),
                                label: const Text('Save',
                                    style: TextStyle(color: Colors.black)),
                                onPressed: () {
                                  final requirement =
                                      requirementCtrl.text.trim();
                                  if (requirement.isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please enter the Requirement')),
                                    );
                                    return;
                                  }
                                  Navigator.of(ctx).pop(_RiskItem(
                                    id: current.id,
                                    requirement: requirement,
                                    requirementType: selectedRequirementType,
                                    risk: riskCtrl.text.trim(),
                                    description: descriptionCtrl.text.trim(),
                                    category: categoryCtrl.text.trim(),
                                    probability: selectedProbability,
                                    impact: selectedImpact,
                                    riskValue: riskValueCtrl.text.trim(),
                                    riskLevel: selectedRiskLevel,
                                    mitigation: mitigationCtrl.text.trim(),
                                    discipline: disciplineCtrl.text.trim(),
                                    owner: ownerCtrl.text.trim(),
                                    status: selectedStatus,
                                  ));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _rows[index] = result;
      });
      _syncRisksToProvider();
    }
  }

  Future<void> _confirmAndDeleteRow(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete row?',
          style:
              TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111827)),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFE4E6),
              foregroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && index >= 0 && index < _rows.length) {
      setState(() {
        _rows.removeAt(index);
      });
      _syncRisksToProvider();
    }
  }

  @override
  void dispose() {
    if (_isSyncReady) {
      _notesController.removeListener(_syncRisksToProvider);
    }
    _notesController.dispose();
    super.dispose();
  }

  void _syncRisksToProvider() {
    if (!mounted || !_isSyncReady || _isApplyingNotesSummary) return;
    final summaryFromRows = _buildRiskSummaryFromRows();
    final value = summaryFromRows.isNotEmpty
        ? summaryFromRows
        : _summarizeNotesText(_notesController.text.trim());

    if (summaryFromRows.isNotEmpty &&
        _notesController.text.trim() != summaryFromRows) {
      _isApplyingNotesSummary = true;
      _notesController.value = TextEditingValue(
        text: summaryFromRows,
        selection: TextSelection.collapsed(offset: summaryFromRows.length),
      );
      _isApplyingNotesSummary = false;
    }

    final riskRegisterItems = _rows
        .map((r) => RiskRegisterItem(
              riskName: r.risk.trim(),
              impactLevel: (r.impact.trim().isNotEmpty
                          ? r.impact.trim()
                          : r.riskLevel.trim())
                      .isNotEmpty
                  ? (r.impact.trim().isNotEmpty
                      ? r.impact.trim()
                      : r.riskLevel.trim())
                  : 'Medium',
              mitigationStrategy: r.mitigation.trim().isNotEmpty
                  ? r.mitigation.trim()
                  : 'Assign an owner, define mitigation actions, and monitor early warning indicators.',
            ))
        .where((r) => r.riskName.isNotEmpty)
        .toList();
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          risks: value,
          riskRegisterItems: riskRegisterItems,
        ),
      ),
    );
  }

  String _buildRiskSummaryFromRows({int previewCount = 4}) {
    final populated = _rows.where((r) => r.risk.trim().isNotEmpty).toList();
    if (populated.isEmpty) return '';

    var highCount = 0;
    var mediumCount = 0;
    var lowCount = 0;

    for (final row in populated) {
      final normalized = _normalizeRiskLevel(
        row.riskLevel.trim().isNotEmpty ? row.riskLevel : row.impact,
      );
      switch (normalized) {
        case 'High':
          highCount++;
          break;
        case 'Low':
          lowCount++;
          break;
        default:
          mediumCount++;
          break;
      }
    }

    final highlights = populated
        .take(previewCount)
        .map((row) => _shortRiskLabel(row.risk))
        .where((value) => value.isNotEmpty)
        .toList();
    final remainingCount = populated.length - highlights.length;
    final suffix = remainingCount > 0 ? ', +$remainingCount more' : '';

    return 'Key risks: ${highlights.join(', ')}$suffix. Total ${populated.length} '
        '(High: $highCount, Medium: $mediumCount, Low: $lowCount).';
  }

  String _summarizeNotesText(String text, {int maxItems = 4}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';

    final normalizedInline = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    if (!trimmed.contains('\n') && normalizedInline.length <= 220) {
      return normalizedInline;
    }

    final lines = trimmed
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return normalizedInline.length <= 220
          ? normalizedInline
          : '${normalizedInline.substring(0, 217)}...';
    }

    final highlights = lines.take(maxItems).map((line) {
      final candidate = line.contains(':') ? line.split(':').first : line;
      return _shortRiskLabel(candidate);
    }).toList();

    final remainingCount = lines.length - highlights.length;
    final suffix = remainingCount > 0 ? ', +$remainingCount more' : '';
    return 'Key risks: ${highlights.join(', ')}$suffix.';
  }

  String _normalizeRiskLevel(String rawValue) {
    final normalized = rawValue.trim().toLowerCase();
    if (normalized.contains('critical') || normalized == 'high') {
      return 'High';
    }
    if (normalized == 'low') {
      return 'Low';
    }
    return 'Medium';
  }

  String _shortRiskLabel(String value, {int maxChars = 54}) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxChars) {
      return normalized;
    }
    return '${normalized.substring(0, maxChars - 3)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ensure white background as requested
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use the same sidebar component used in PreferredSolutionAnalysisScreen
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child:
                  const InitiationLikeSidebar(activeItemLabel: 'Project Risks'),
            ),
            Expanded(
              child: Stack(
                children: [
                  const AdminEditToggle(),
                  Column(
                    children: [
                      const FrontEndPlanningHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _roundedField(
                                controller: _notesController,
                                hint: 'Input your notes here…',
                                minLines: 2,
                                maxLines: 4,
                              ),
                              const SizedBox(height: 22),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        EditableContentText(
                                          contentKey: 'fep_risks_title',
                                          fallback: 'Project Risks',
                                          category: 'front_end_planning',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        EditableContentText(
                                          contentKey: 'fep_risks_subtitle',
                                          fallback:
                                              '(Highlight and quantify known and/or anticipated risks here)',
                                          category: 'front_end_planning',
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
                                        await _regenerateAllRisks();
                                      }
                                    },
                                    isLoading: _isGeneratingRequirements,
                                    tooltip: 'Regenerate all risks',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (_isGeneratingRequirements)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 12),
                                        Text(
                                            'Generating requirements from Business Case...'),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                _buildRiskTable(context),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton.icon(
                                  onPressed: _addNewRisk,
                                  icon: const Icon(Icons.add,
                                      color: Colors.black, size: 18),
                                  label: const Text('Add Item',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFD700),
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const KazAiChatBubble(),
                  _BottomOverlays(
                    onNext: () async {
                      final risksText = _buildRiskSummaryFromRows();
                      await ProjectDataHelper.saveAndNavigate(
                        context: context,
                        checkpoint: 'fep_risks',
                        saveInBackground: true,
                        nextScreenBuilder: () =>
                            const FrontEndPlanningOpportunitiesScreen(),
                        dataUpdater: (data) => data.copyWith(
                          frontEndPlanning: ProjectDataHelper.updateFEPField(
                            current: data.frontEndPlanning,
                            risks: risksText.isNotEmpty
                                ? risksText
                                : _summarizeNotesText(
                                    _notesController.text.trim()),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskTable(BuildContext context) {
    final border = const BorderSide(color: Color(0xFFE5E7EB));
    final headerStyle = const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563));
    final cellStyle = const TextStyle(fontSize: 14, color: Color(0xFF111827));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate minimum width needed for all columns
          final minTableWidth = 1980.0;
          final tableWidth = constraints.maxWidth < minTableWidth
              ? minTableWidth
              : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(60),
                  1: FixedColumnWidth(150),
                  2: FixedColumnWidth(150),
                  3: FixedColumnWidth(150),
                  4: FixedColumnWidth(200),
                  5: FixedColumnWidth(100),
                  6: FixedColumnWidth(100),
                  7: FixedColumnWidth(100),
                  8: FixedColumnWidth(100),
                  9: FixedColumnWidth(120),
                  10: FixedColumnWidth(150),
                  11: FixedColumnWidth(100),
                  12: FixedColumnWidth(100),
                  13: FixedColumnWidth(100),
                  14: FixedColumnWidth(80),
                },
                border: TableBorder(
                  horizontalInside: border,
                  verticalInside: border,
                  top: border,
                  bottom: border,
                  left: border,
                  right: border,
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                    children: [
                      _th('ID', headerStyle),
                      _th('Requirement', headerStyle),
                      _th('Requirement Type', headerStyle),
                      _th('Risk Title', headerStyle),
                      _th('Description', headerStyle),
                      _th('Category', headerStyle),
                      _th('Probability', headerStyle),
                      _th('Impact', headerStyle),
                      _th('Risk Value', headerStyle),
                      _th('Risk Level', headerStyle),
                      _th('Mitigation', headerStyle),
                      _th('Discipline', headerStyle),
                      _th('Owner', headerStyle),
                      _th('Status', headerStyle),
                      _th('Ac', headerStyle),
                    ],
                  ),
                  ...List.generate(_rows.length, (i) {
                    final r = _rows[i];
                    return TableRow(children: [
                      _td(Text(r.id, style: cellStyle)),
                      _td(Text(
                        r.requirement,
                        style: cellStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      )),
                      _td(r.requirementType.isEmpty
                          ? const SizedBox.shrink()
                          : _chip(r.requirementType, const Color(0xFFDCFCE7),
                              const Color(0xFF16A34A))),
                      _td(Text(
                        r.risk,
                        style: cellStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      )),
                      _td(Text(
                        r.description,
                        style: cellStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      )),
                      _td(r.category.isEmpty
                          ? const SizedBox.shrink()
                          : _chip(r.category, const Color(0xFFF3E8FF),
                              const Color(0xFF7C3AED))),
                      _td(Text(r.probability, style: cellStyle)),
                      _td(Text(r.impact, style: cellStyle)),
                      _td(Text(r.riskValue, style: cellStyle)),
                      _td(r.riskLevel.isEmpty
                          ? const SizedBox.shrink()
                          : _chip(r.riskLevel, const Color(0xFFFFE4E6),
                              const Color(0xFFDC2626))),
                      _td(Text(r.mitigation, style: cellStyle)),
                      _td(Text(r.discipline, style: cellStyle)),
                      _td(Text(r.owner, style: cellStyle)),
                      _td(r.status.isEmpty
                          ? const SizedBox.shrink()
                          : _statusPill(r.status)),
                      _td(Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () => _showEditRiskSheet(i),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.edit,
                                  size: 18, color: Color(0xFF6B7280)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => _confirmAndDeleteRow(i),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.delete_outline,
                                  size: 18, color: Color(0xFF6B7280)),
                            ),
                          ),
                        ],
                      )),
                    ]);
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _th(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: EditableContentText(
        contentKey:
            'fep_risks_header_${text.toLowerCase().replaceAll(' ', '_')}',
        fallback: text,
        category: 'front_end_planning',
        style: style,
      ),
    );
  }

  Widget _td(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(label,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _statusPill(String status) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE4E6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(status,
            style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _RiskItem {
  final String id;
  final String requirement;
  final String requirementType;
  final String risk;
  final String description;
  final String category;
  final String probability;
  final String impact;
  final String riskValue;
  final String riskLevel;
  final String mitigation;
  final String discipline;
  final String owner;
  final String status;
  const _RiskItem({
    required this.id,
    required this.requirement,
    required this.requirementType,
    required this.risk,
    required this.description,
    required this.category,
    required this.probability,
    required this.impact,
    required this.riskValue,
    required this.riskLevel,
    required this.mitigation,
    required this.discipline,
    required this.owner,
    required this.status,
  });
}

class _BottomOverlays extends StatelessWidget {
  const _BottomOverlays({required this.onNext});
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
                  _aiHint(),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: const Text('Next',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E5FF)),
      ),
      child: Row(
        children: const [
          Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
          SizedBox(width: 8),
          Text('AI',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
          SizedBox(width: 10),
          Text('Focus on major risks associated with each potential solution.',
              style: TextStyle(color: Color(0xFF1F2937))),
        ],
      ),
    );
  }
}

Widget _roundedField(
    {required TextEditingController controller,
    required String hint,
    int minLines = 1,
    int maxLines = 4}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE4E7EC)),
    ),
    padding: const EdgeInsets.all(14),
    child: TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
    ),
  );
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool autofocus;
  final bool enabled;
  const _LabeledField({
    required this.label,
    required this.controller,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            enabled: enabled,
            decoration: InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final String? hint;
  final ValueChanged<String?> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: hint == null
                  ? null
                  : Text(hint!,
                      style: const TextStyle(color: Color(0xFF9CA3AF))),
              items: items
                  .map(
                      (e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF9CA3AF)),
            ),
          ),
        ),
      ],
    );
  }
}
