import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/contract_service.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

/// Front End Planning – Contracts screen
/// Recreates the provided contract management mock with tabs, notes field,
/// contracting timeline, and a dashboard of completed contracts inside the shared workspace layout.
class FrontEndPlanningContractsScreen extends StatefulWidget {
  const FrontEndPlanningContractsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FrontEndPlanningContractsScreen()),
    );
  }

  @override
  State<FrontEndPlanningContractsScreen> createState() => _FrontEndPlanningContractsScreenState();
}

class _FrontEndPlanningContractsScreenState extends State<FrontEndPlanningContractsScreen> {
  final TextEditingController _notesController = TextEditingController();
  int _selectedTabIndex = 0;

  void _openCreateContract() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateContractScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final saved = ProjectDataHelper.getData(context).frontEndPlanning.contracts;
      if (saved.trim().isNotEmpty) {
        _notesController.text = saved;
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _navigateToProcurement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FrontEndPlanningProcurementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectData = ProjectDataHelper.getData(context);
    final hasContractData = (projectData.planningNotes['contract_dashboard_payload'] ?? '').trim().isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Contract'),
            ),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ContractHeader(
                                title: 'Contract',
                                onBack: () => Navigator.maybePop(context),
                                onForward: null,
                                onCreateContract: _openCreateContract,
                              ),
                              const SizedBox(height: 28),
                              _ContractTabs(
                                selectedIndex: _selectedTabIndex,
                                onTabSelected: (index) {
                                  if (index == 1) {
                                    // Navigate to the dedicated Contract Details dashboard screen
                                    // using the named route for clean, web-friendly URLs.
                                    context.pushNamed(AppRoutes.contractDetails);
                                    return;
                                  }
                                  setState(() => _selectedTabIndex = index);
                                },
                              ),
                              const SizedBox(height: 20),
                              const PlanningAiNotesCard(
                                title: 'AI Notes',
                                sectionLabel: 'Contract',
                                noteKey: 'planning_contract_notes',
                                checkpoint: 'contracts',
                                description: 'Summarize contract scope, vendor commitments, and negotiation priorities.',
                              ),
                              const SizedBox(height: 20),
                              _NotesField(
                                controller: _notesController,
                                onChanged: (value) async {
                                  await ProjectDataHelper.updateAndSave(
                                    context: context,
                                    checkpoint: 'contracts',
                                    dataUpdater: (data) => data.copyWith(
                                      frontEndPlanning: ProjectDataHelper.updateFEPField(
                                        current: data.frontEndPlanning,
                                        contracts: value.trim(),
                                      ),
                                    ),
                                    showSnackbar: false,
                                  );
                                },
                              ),
                              const SizedBox(height: 28),
                              if (!hasContractData)
                                const _EmptyContractsState()
                              else ...[
                                _TimelineSection(),
                                const SizedBox(height: 40),
                                const _ContractDashboardSection(),
                                const SizedBox(height: 32),
                                const _ContractingNoteBanner(),
                              ],
                              const SizedBox(height: 32),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: _navigateToProcurement,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0987FF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                               const SizedBox(height: 80),
                               ],
                            ),
                        ),
                      ),
                    ],
                  ),
                  const KazAiChatBubble(),
                  const AdminEditToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateContractScreen extends StatefulWidget {
  const CreateContractScreen({super.key});

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contractNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _estimatedValueController = TextEditingController();
  final TextEditingController _scopeController = TextEditingController();
  final TextEditingController _disciplineController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _contractType = 'Not Sure';
  String _paymentType = 'Not Sure';
  String _status = 'Not Started';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _contractNameController.dispose();
    _descriptionController.dispose();
    _estimatedValueController.dispose();
    _scopeController.dispose();
    _disciplineController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isStart ? (_startDate ?? now) : (_endDate ?? now);
    final DateTime firstDate = DateTime(now.year - 5);
    final DateTime lastDate = DateTime(now.year + 5);

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = selected;
      } else {
        _endDate = selected;
      }
    });
  }

  Future<void> _handleSubmit() async {
    final messenger = ScaffoldMessenger.of(context);
    final projectProvider = ProjectDataInherited.maybeOf(context);
    final projectId = projectProvider?.projectData.projectId;

    if (!(_formKey.currentState?.validate() ?? false)) {
      messenger.showSnackBar(const SnackBar(content: Text('Please complete all required fields.')));
      return;
    }
    if (_startDate == null || _endDate == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Please select Start Date and End Date.')));
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      messenger.showSnackBar(const SnackBar(content: Text('End Date cannot be before Start Date.')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      messenger.showSnackBar(const SnackBar(content: Text('You must be signed in to save a contract.')));
      return;
    }
    if (projectId == null || projectId.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Open or create a project before adding contracts.')));
      return;
    }

    final double? estValue = double.tryParse(_estimatedValueController.text.trim());
    if (estValue == null || estValue <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Estimated Value must be a positive number.')));
      return;
    }

    try {
      await ContractService.createContract(
        projectId: projectId,
        name: _contractNameController.text.trim(),
        description: _descriptionController.text.trim(),
        contractType: _contractType,
        paymentType: _paymentType,
        status: _status,
        estimatedValue: estValue,
        startDate: _startDate!,
        endDate: _endDate!,
        scope: _scopeController.text.trim(),
        discipline: _disciplineController.text.trim(),
        notes: _notesController.text.trim(),
        createdById: user.uid,
        createdByEmail: user.email ?? '',
        createdByName: user.displayName ?? (user.email ?? 'User'),
      );

      messenger.showSnackBar(const SnackBar(content: Text('Contract saved successfully.')));

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'ContractingStrategyScreen'),
          builder: (_) => const ContractingStrategyScreen(),
        ),
      );
    } catch (e) {
      debugPrint('❌ Failed to save contract: $e');
      messenger.showSnackBar(const SnackBar(content: Text('Failed to save contract. Please try again.')));
    }
  }

  String _formattedDate(DateTime? date) {
    if (date == null) {
      return 'Pick a date';
    }
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = AppBreakpoints.isMobile(context) ? 20 : 48;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Contract'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: AppBreakpoints.isMobile(context) ? 28 : 48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(builder: (context) {
                          final provider = ProjectDataInherited.maybeOf(context);
                          final projectName = provider?.projectData.projectName.trim();
                          final title = (projectName != null && projectName.isNotEmpty) ? projectName : 'Project';
                          return Align(
                            alignment: Alignment.center,
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppBreakpoints.isMobile(context) ? 24 : 30,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          );
                        }),
                        SizedBox(height: AppBreakpoints.isMobile(context) ? 18 : 24),
                        // Wrap the entire form content in a Form so validators run
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 1160),
                          padding: EdgeInsets.symmetric(
                            horizontal: AppBreakpoints.isMobile(context) ? 20 : 36,
                            vertical: AppBreakpoints.isMobile(context) ? 24 : 36,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppBreakpoints.isMobile(context) ? 20 : 30),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0A0F172A), blurRadius: 26, offset: Offset(0, 14)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              _LabeledField(
                                label: 'Contract Name*',
                                child: _ContractTextField(
                                  controller: _contractNameController,
                                  hintText: 'e.g. Office Renovation',
                                   validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              SizedBox(height: AppBreakpoints.isMobile(context) ? 18 : 24),
                              _LabeledField(
                                label: 'Description*',
                                child: _ContractTextField(
                                  controller: _descriptionController,
                                  hintText: 'Brief description of the contract scope',
                                  maxLines: 4,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                              SizedBox(height: AppBreakpoints.isMobile(context) ? 18 : 24),
                              _ResponsiveRow(
                                spacing: AppBreakpoints.isMobile(context) ? 16 : 24,
                                children: [
                                  _LabeledField(
                                    label: 'Contract Type*',
                                    child: _ContractDropdownField(
                                      value: _contractType,
                                      items: const ['Not Sure', 'Fixed Price', 'Time and Materials', 'Retainer'],
                                      onChanged: (value) => setState(() => _contractType = value ?? _contractType),
                                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                    ),
                                  ),
                                  _LabeledField(
                                    label: 'Payment Type*',
                                    child: _ContractDropdownField(
                                      value: _paymentType,
                                      items: const ['Not Sure', 'Milestone-based', 'Monthly', 'On Completion'],
                                      onChanged: (value) => setState(() => _paymentType = value ?? _paymentType),
                                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppBreakpoints.isMobile(context) ? 18 : 24),
                              _ResponsiveRow(
                                spacing: AppBreakpoints.isMobile(context) ? 16 : 24,
                                children: [
                                  _LabeledField(
                                    label: 'Status*',
                                    child: _ContractDropdownField(
                                      value: _status,
                                      items: const ['Not Started', 'In Progress', 'Pending Review', 'Completed'],
                                      onChanged: (value) => setState(() => _status = value ?? _status),
                                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                    ),
                                  ),
                                  _LabeledField(
                                    label: 'Estimated Value (\$)',
                                    child: _ContractTextField(
                                      controller: _estimatedValueController,
                                      hintText: 'e.g. 150000',
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        final t = v?.trim() ?? '';
                                        final d = double.tryParse(t);
                                        if (d == null || d <= 0) return 'Enter a valid amount';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppBreakpoints.isMobile(context) ? 18 : 24),
                              _ResponsiveRow(
                                spacing: AppBreakpoints.isMobile(context) ? 16 : 24,
                                children: [
                                  _LabeledField(
                                    label: 'Start Date',
                                    child: _ContractDateField(
                                      displayText: _formattedDate(_startDate),
                                      onTap: () => _pickDate(isStart: true),
                                    ),
                                  ),
                                  _LabeledField(
                                    label: 'End Date',
                                    child: _ContractDateField(
                                      displayText: _formattedDate(_endDate),
                                      onTap: () => _pickDate(isStart: false),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppBreakpoints.isMobile(context) ? 18 : 24),
                              _ResponsiveRow(
                                spacing: AppBreakpoints.isMobile(context) ? 16 : 24,
                                children: [
                                  _LabeledField(
                                    label: 'Scope*',
                                    child: _ContractTextField(
                                      controller: _scopeController,
                                      hintText: 'e.g. Operations',
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                    ),
                                  ),
                                  _LabeledField(
                                    label: 'Discipline*',
                                    child: _ContractTextField(
                                      controller: _disciplineController,
                                      hintText: 'e.g. REQ-2023-001',
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppBreakpoints.isMobile(context) ? 18 : 24),
                              _LabeledField(
                                label: 'Additional Notes',
                                child: _ContractTextField(
                                  controller: _notesController,
                                  hintText: 'Any additional information about this contract',
                                  maxLines: 4,
                                ),
                              ),
                              SizedBox(height: AppBreakpoints.isMobile(context) ? 24 : 36),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).maybePop(),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                      backgroundColor: const Color(0xFFF3F4F6),
                                      foregroundColor: const Color(0xFF6B7280),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                                      ),
                                    ),
                                    child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _handleSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0987FF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 18),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text('Next', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                        SizedBox(width: 12),
                                        Icon(Icons.arrow_forward, size: 18),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                  const AdminEditToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractingStrategyScreen extends StatefulWidget {
  const ContractingStrategyScreen({super.key});

  @override
  State<ContractingStrategyScreen> createState() => _ContractingStrategyScreenState();
}

class _ContractingStrategyScreenState extends State<ContractingStrategyScreen> {
  String _awardStrategy = 'Sole Source';
  String _contractType = 'Not Sure';

  void _openContractDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'ContractDetailsScreen'),
        builder: (_) => const ContractDetailsScreen(),
      ),
    );
  }

  void _openContractingStatus() {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'ContractingStatusScreen'),
        builder: (_) => const ContractingStatusScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 24 : 48;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Contract'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isMobile ? 28 : 48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StrategyHeader(onBack: () => Navigator.of(context).maybePop()),
                         SizedBox(height: isMobile ? 24 : 36),
                          _StrategyStepPills(
                           selectedIndex: 0,
                           onStepTap: (index) {
                             if (index == 1) {
                               _openContractDetails();
                             } else if (index == 2) {
                               _openContractingStatus();
                             } else if (index == 3) {
                                ContractingSummaryScreen.open(context);
                             }
                           },
                         ),
                        SizedBox(height: isMobile ? 24 : 36),
                        _ContractingStrategyCard(
                          selectedAwardStrategy: _awardStrategy,
                          onAwardStrategyChanged: (value) => setState(() => _awardStrategy = value),
                          selectedContractType: _contractType,
                          onContractTypeChanged: (value) => setState(() => _contractType = value),
                        ),
                        SizedBox(height: isMobile ? 28 : 40),
                          _ExistingQuotesSection(onViewDetails: _openContractDetails),
                          SizedBox(height: isMobile ? 24 : 32),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _openContractDetails,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.description_outlined, size: 18),
                              label: const Text('Contract Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        SizedBox(height: isMobile ? 80 : 120),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                  const AdminEditToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrategyHeader extends StatelessWidget {
  const _StrategyHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        const _CircleIconButton(icon: Icons.arrow_forward_ios_rounded),
        const SizedBox(width: 24),
        const Text(
          'Contract',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        const Spacer(),
        const _UserBadge(),
      ],
    );
  }
}

class _StrategyStepPills extends StatelessWidget {
  const _StrategyStepPills({required this.selectedIndex, this.onStepTap});

  final int selectedIndex;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final bool isNarrow = MediaQuery.of(context).size.width < 720;

    Widget buildPill(String label, int index) {
      final bool isSelected = index == selectedIndex;
      final Color backgroundColor = isSelected ? const Color(0xFF1D9BF0) : const Color(0xFFFFC947);
      final Color textColor = isSelected ? Colors.white : const Color(0xFF1F2937);

      return _StepPill(
        label: label,
        backgroundColor: backgroundColor,
        textColor: textColor,
        onTap: onStepTap != null ? () => onStepTap!(index) : null,
      );
    }

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildPill('Contracting Strategy', 0),
          const SizedBox(height: 12),
          buildPill('Contract Details', 1),
          const SizedBox(height: 12),
          buildPill('Contracting Status', 2),
          const SizedBox(height: 12),
          buildPill('Contracting Summary', 3),
        ],
      );
    }

    return Row(
      children: [
        buildPill('Contracting Strategy', 0),
        const SizedBox(width: 18),
        buildPill('Contract Details', 1),
        const SizedBox(width: 18),
        buildPill('Contracting Status', 2),
        const SizedBox(width: 18),
        buildPill('Contracting Summary', 3),
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.label, required this.backgroundColor, required this.textColor, this.onTap});

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Color(0x13000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
      ),
    );

    if (onTap == null) {
      return pill;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: pill,
    );
  }
}

class _ContractingStrategyCard extends StatelessWidget {
  const _ContractingStrategyCard({
    required this.selectedAwardStrategy,
    required this.onAwardStrategyChanged,
    required this.selectedContractType,
    required this.onContractTypeChanged,
  });

  final String selectedAwardStrategy;
  final ValueChanged<String> onAwardStrategyChanged;
  final String selectedContractType;
  final ValueChanged<String> onContractTypeChanged;

  static const Map<String, String> _awardDescriptions = {
    'Sole Source':
        'Contracting directly with a single vendor without a competitive process. Used when a specific vendor has unique qualifications, intellectual property, or prior experience crucial to the project.',
    'Competitive Bidding':
        'Invite multiple vendors to submit proposals so the project team can compare cost, quality, and delivery expectations before selecting a partner.',
    'Not Sure':
        'Review the project requirements with the procurement team to determine the best award strategy before moving forward.',
  };

  static const Map<String, String> _contractTypeDescriptions = {
    'Reimbursable (Time & Materials)':
        'Contractor bills for actual labor and material costs plus any agreed markups. Useful when scope is evolving or difficult to estimate.',
    'Lump Sum (Fixed Price)':
        'A fixed price for the entire scope of work. Provides budget certainty but requires detailed specifications and shifts risk of overruns to the contractor.',
    'Not Sure':
        'Explore the pros and cons of both pricing models with the project sponsor before finalizing the contract type.',
  };

  @override
  Widget build(BuildContext context) {
    final bool isTight = MediaQuery.of(context).size.width < 1160;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTight ? 24 : 36,
        vertical: isTight ? 28 : 36,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0D0F172A), blurRadius: 24, offset: Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contracting Strategy',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Define the contracting approach',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool stack = constraints.maxWidth < 840;
              final children = [
                Expanded(
                  child: _StrategySelectionColumn(
                    title: 'Award strategy',
                    options: const ['Sole Source', 'Competitive Bidding', 'Not Sure'],
                    selected: selectedAwardStrategy,
                    onChanged: onAwardStrategyChanged,
                    infoTitle: 'About ${selectedAwardStrategy == 'Sole Source' ? 'Sole Source' : selectedAwardStrategy}',
                    infoDescription: _awardDescriptions[selectedAwardStrategy] ?? '',
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: _StrategySelectionColumn(
                    title: 'Contract type',
                    options: const ['Reimbursable (Time & Materials)', 'Lump Sum (Fixed Price)', 'Not Sure'],
                    selected: selectedContractType,
                    onChanged: onContractTypeChanged,
                    infoTitle: selectedContractType == 'Lump Sum (Fixed Price)'
                        ? 'About Lump Sum (Fixed Price)'
                        : 'About ${selectedContractType == 'Reimbursable (Time & Materials)' ? 'Reimbursable (Time & Materials)' : selectedContractType}',
                    infoDescription: _contractTypeDescriptions[selectedContractType] ?? '',
                  ),
                ),
              ];

              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    children[0],
                    const SizedBox(height: 28),
                    children[2],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StrategySelectionColumn extends StatelessWidget {
  const _StrategySelectionColumn({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.infoTitle,
    required this.infoDescription,
  });

  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final String infoTitle;
  final String infoDescription;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 18),
        ...options.map(
          (option) => _RadioOptionRow(
            label: option,
            groupValue: selected,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 18),
        _StrategyInfoCard(title: infoTitle, description: infoDescription),
      ],
    );
  }
}

class _RadioOptionRow extends StatelessWidget {
  const _RadioOptionRow({required this.label, required this.groupValue, required this.onChanged});

  final String label;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = label == groupValue;

    return InkWell(
      onTap: () => onChanged(label),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Radio<String>(
              value: label,
              groupValue: groupValue,
              onChanged: (_) => onChanged(label),
              activeColor: const Color(0xFF2563EB),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? const Color(0xFF111827) : const Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrategyInfoCard extends StatelessWidget {
  const _StrategyInfoCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF4B5563)),
          ),
        ],
      ),
    );
  }
}

class _ExistingQuotesSection extends StatelessWidget {
  const _ExistingQuotesSection({this.onViewDetails});

  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    const quotes = [
      _QuoteRowData(
        contractor: 'Tech Systems Inc.',
        description: 'Equipment Procurement & Installation',
        estimatedValue: r'$115,000 - $125,000',
        status: 'Not a Contract',
        statusColor: Color(0xFF9CA3AF),
      ),
      _QuoteRowData(
        contractor: 'Contract Tech Solutions',
        description: 'Software Integration',
        estimatedValue: r'$40,000 - $50,000',
        status: 'Not a Contract',
        statusColor: Color(0xFF9CA3AF),
      ),
      _QuoteRowData(
        contractor: 'Office Supplies Co.',
        description: 'Project Management Supplies',
        estimatedValue: r'$3,000',
        status: 'Not a Contract',
        statusColor: Color(0xFF9CA3AF),
      ),
      _QuoteRowData(
        contractor: 'Engineering Consultants Ltd.',
        description: 'Engineering Services',
        estimatedValue: r'$60,000 - $90,000',
        status: 'Added as Contract',
        statusColor: Color(0xFF22C55E),
        showViewDetails: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Existing Contracting quotes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Review initial obtained quotes from earlier project phase and decide on how to proceed.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 18),
        _ExistingQuotesTable(quotes: quotes, onViewDetails: onViewDetails),
      ],
    );
  }
}

class _ExistingQuotesTable extends StatelessWidget {
  const _ExistingQuotesTable({required this.quotes, this.onViewDetails});

  final List<_QuoteRowData> quotes;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C0F172A), blurRadius: 18, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          _ExistingQuotesHeader(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          for (int i = 0; i < quotes.length; i++) ...[
            _ExistingQuotesRow(data: quotes[i], onViewDetails: onViewDetails),
            if (i != quotes.length - 1) const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ],
        ],
      ),
    );
  }
}

class _ExistingQuotesHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: Row(
        children: const [
          Expanded(flex: 24, child: Text('Contractor', style: style)),
          Expanded(flex: 26, child: Text('Description', style: style)),
          Expanded(flex: 18, child: Text('Estimated Value', style: style)),
          Expanded(flex: 18, child: Text('Status', style: style)),
          Expanded(flex: 14, child: Align(alignment: Alignment.centerRight, child: Text('Actions', style: style))),
        ],
      ),
    );
  }
}

class _ExistingQuotesRow extends StatelessWidget {
  const _ExistingQuotesRow({required this.data, this.onViewDetails});

  final _QuoteRowData data;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 24,
            child: Text(
              data.contractor,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
            ),
          ),
          Expanded(
            flex: 26,
            child: Text(
              data.description,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              data.estimatedValue,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            ),
          ),
          Expanded(
            flex: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _QuoteStatusChip(label: data.status, color: data.statusColor),
            ),
          ),
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerRight,
              child: data.showViewDetails
                   ? TextButton(
                       onPressed: onViewDetails,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    )
                  : Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(Icons.more_vert, size: 18, color: Color(0xFF6B7280)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteStatusChip extends StatelessWidget {
  const _QuoteStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.26)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _QuoteRowData {
  const _QuoteRowData({
    required this.contractor,
    required this.description,
    required this.estimatedValue,
    required this.status,
    required this.statusColor,
    this.showViewDetails = false,
  });

  final String contractor;
  final String description;
  final String estimatedValue;
  final String status;
  final Color statusColor;
  final bool showViewDetails;
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ContractTextField extends StatelessWidget {
  const _ContractTextField({
    required this.controller,
    required this.hintText,
    this.maxLines,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final int minLines = maxLines != null && maxLines! > 1 ? maxLines! : 1;

    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
        ),
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
    );
  }
}

class _ContractDropdownField extends StatelessWidget {
  const _ContractDropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      validator: validator,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937))),
            ),
          )
          .toList(),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
        ),
      ),
      dropdownColor: Colors.white,
    );
  }
}

class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({required this.children, this.spacing = 24});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useColumn = constraints.maxWidth < 720;
        if (useColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i != 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}

class _ContractDateField extends StatelessWidget {
  const _ContractDateField({required this.displayText, required this.onTap});

  final String displayText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isPlaceholder = displayText == 'Pick a date';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 14,
                  color: isPlaceholder ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF6B7280), size: 18),
          ],
        ),
      ),
    );
  }
}

class _ContractHeader extends StatelessWidget {
  const _ContractHeader({
    required this.title,
    this.onBack,
    this.onForward,
    this.onCreateContract,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback? onCreateContract;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack ?? () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(
          icon: Icons.arrow_forward_ios_rounded,
          onTap: onForward,
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
        ),
        const _UserBadge(),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: onCreateContract,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0987FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Create Contract', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _ContractTabs extends StatelessWidget {
  const _ContractTabs({required this.selectedIndex, required this.onTabSelected});

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _TabButton(
            label: 'Contract Management',
            isSelected: selectedIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          const SizedBox(width: 8),
          _TabButton(
            label: 'Contract Details',
            isSelected: selectedIndex == 1,
            onTap: () => onTabSelected(1),
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller, this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: controller,
        minLines: 5,
        maxLines: null,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Input your notes here...',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      ),
    );
  }
}

class _EmptyContractsState extends StatelessWidget {
  const _EmptyContractsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.description_outlined, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('No contract data yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                SizedBox(height: 6),
                Text(
                  'Capture contract notes or add contract details to populate the dashboard.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatefulWidget {
  const _TimelineSection();

  @override
  State<_TimelineSection> createState() => _TimelineSectionState();
}

class _TimelineSectionState extends State<_TimelineSection> {
  // store per-step min/max estimates
  final Map<int, int> _minDays = {1: 1, 2: 3, 3: 1, 4: 7, 5: 1};
  final Map<int, int> _maxDays = {1: 2, 2: 5, 3: 2, 4: 9, 5: 2};

  String _estimateLabel(int number) {
    final min = _minDays[number] ?? 0;
    final max = _maxDays[number] ?? min;
    if (min == max) return 'Estimated: $min days';
    return 'Estimated: $min-$max days';
  }

  String _totalEstimateLabel() {
    int totalMin = 0;
    int totalMax = 0;
    for (final n in [1, 2, 3, 4, 5]) {
      totalMin += _minDays[n] ?? 0;
      totalMax += _maxDays[n] ?? (_minDays[n] ?? 0);
    }
    if (totalMin == totalMax) return 'Total estimate time:\n$totalMin days';
    return 'Total estimate time:\n$totalMin-$totalMax days';
  }

  Future<void> _editEstimate(BuildContext context, int number) async {
    final minController = TextEditingController(text: (_minDays[number] ?? 0).toString());
    final maxController = TextEditingController(text: (_maxDays[number] ?? (_minDays[number] ?? 0)).toString());

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Set estimated days'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minimum days', hintText: 'e.g. 1'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Maximum days', hintText: 'e.g. 3'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final min = int.tryParse(minController.text.trim());
                final max = int.tryParse(maxController.text.trim());
                if (min == null || min < 0) {
                  Navigator.pop(ctx);
                  return;
                }
                final resolvedMax = (max == null || max < min) ? min : max;
                setState(() {
                  _minDays[number] = min;
                  _maxDays[number] = resolvedMax;
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStepData(
        number: 1,
        title: 'Contract Creation',
        description: 'Develop scope of work, identify potential contractors, etc.',
        estimate: _estimateLabel(1),
        status: _TimelineStatus.current,
      ),
      _TimelineStepData(
        number: 2,
        title: 'Internal Review',
        description: 'Review by key stakeholders',
        estimate: _estimateLabel(2),
        status: _TimelineStatus.current,
      ),
      _TimelineStepData(
        number: 3,
        title: 'Contractor review',
        description: 'Request for information and/or Quote',
        estimate: _estimateLabel(3),
        status: _TimelineStatus.current,
      ),
      _TimelineStepData(
        number: 4,
        title: 'Bidding and Contract Review',
        description: 'Review of bids and clarification cycles',
        estimate: _estimateLabel(4),
        status: _TimelineStatus.current, // highlight like 1-3
      ),
      _TimelineStepData(
        number: 5,
        title: 'Contract Award',
        description: 'Selection of contractor, contract signing',
        estimate: _estimateLabel(5),
        status: _TimelineStatus.current, // highlight like 1-3
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm Contracting Timeline',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final step in steps) ...[
                _TimelineStep(step: step, onEdit: () => _editEstimate(context, step.number)),
                const SizedBox(height: 24),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  _totalEstimateLabel(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContractDashboardSection extends StatelessWidget {
  const _ContractDashboardSection();

  @override
  Widget build(BuildContext context) {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contract Dashboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Review successfully created contracts, their status, and key milestones at a glance.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 20),
        if (projectId == null || projectId.isEmpty) ...[
          const _ContractMetricsRow(metrics: [
            _ContractMetricData(label: 'Total Contracts', value: '0', detail: 'Create a project first', icon: Icons.layers_outlined, accentColor: Color(0xFF2563EB)),
            _ContractMetricData(label: 'Active', value: '0', detail: '—', icon: Icons.sync_alt_rounded, accentColor: Color(0xFF0EA5E9)),
            _ContractMetricData(label: 'Completed', value: '0', detail: '—', icon: Icons.verified_outlined, accentColor: Color(0xFF10B981)),
          ]),
          const SizedBox(height: 12),
          const Text('No project selected. Open or create a project to see contracts.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ] else ...[
          StreamBuilder<List<ContractModel>>(
            // Build the stream defensively so synchronous errors don’t crash the tree
            stream: (() {
              try {
                return ContractService.streamContracts(projectId);
              } catch (e, st) {
                debugPrint('⚠️ Contracts stream init failed: $e\n$st');
                // Return an empty stream to keep UI responsive
                return const Stream<List<ContractModel>>.empty();
              }
            })(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('❌ Contracts stream error: ${snapshot.error}');
                const fallbackMetrics = [
                  _ContractMetricData(label: 'Total Contracts', value: '0', detail: 'Stream error', icon: Icons.layers_outlined, accentColor: Color(0xFF2563EB)),
                  _ContractMetricData(label: 'Active', value: '0', detail: '—', icon: Icons.sync_alt_rounded, accentColor: Color(0xFF0EA5E9)),
                  _ContractMetricData(label: 'Completed', value: '0', detail: '—', icon: Icons.verified_outlined, accentColor: Color(0xFF10B981)),
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _ContractMetricsRow(metrics: fallbackMetrics),
                    SizedBox(height: 12),
                    Text('Unable to load contracts right now. Please try again later.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                );
              }

              final contracts = snapshot.data ?? const <ContractModel>[];
              final total = contracts.length;
              final active = contracts.where((c) => (c.status.toLowerCase().contains('active') || c.status.toLowerCase().contains('in progress'))).length;
              final completed = contracts.where((c) => c.status.toLowerCase().contains('completed')).length;

              final metrics = [
                _ContractMetricData(label: 'Total Contracts', value: '$total', detail: '—', icon: Icons.layers_outlined, accentColor: const Color(0xFF2563EB)),
                _ContractMetricData(label: 'Active', value: '$active', detail: '—', icon: Icons.sync_alt_rounded, accentColor: const Color(0xFF0EA5E9)),
                _ContractMetricData(label: 'Completed', value: '$completed', detail: '—', icon: Icons.verified_outlined, accentColor: const Color(0xFF10B981)),
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContractMetricsRow(metrics: metrics),
                  const SizedBox(height: 26),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isStacked = constraints.maxWidth < 1040;
                      final double cardWidth = isStacked ? constraints.maxWidth : (constraints.maxWidth - 20) / 2;

                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: contracts
                            .map(
                              (c) => SizedBox(
                                width: cardWidth,
                                child: _ContractRecordCard(
                                  record: _ContractRecord(
                                    name: c.name,
                                    code: c.discipline.isNotEmpty ? c.discipline : '—',
                                    owner: c.createdByName,
                                    value: '\$${c.estimatedValue.toStringAsFixed(0)}',
                                    status: c.status,
                                    statusColor: c.status.toLowerCase().contains('completed') ? const Color(0xFF1E3A8A) : const Color(0xFF047857),
                                    effectiveDate: _formatMMMdY(c.startDate),
                                    renewalDate: _formatMMMdY(c.endDate),
                                    lastUpdated: 'Updated ${_relativeTime(c.updatedAt)}',
                                    highlights: [
                                      c.contractType.isNotEmpty ? 'Type: ${c.contractType}' : '—',
                                      c.paymentType.isNotEmpty ? 'Payment: ${c.paymentType}' : '—',
                                      c.scope.isNotEmpty ? 'Scope: ${c.scope}' : '—',
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

String _formatMMMdY(DateTime date) {
  // Simple US-style date like Jan 08, 2025
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final m = months[date.month - 1];
  final day = date.day.toString().padLeft(2, '0');
  return '$m $day, ${date.year}';
}

String _relativeTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return '$weeks wk ago';
  final months = (diff.inDays / 30).floor();
  if (months < 12) return '$months mo ago';
  final years = (diff.inDays / 365).floor();
  return '$years yr ago';
}

class _ContractingNoteBanner extends StatelessWidget {
  const _ContractingNoteBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFF3F4FF), Color(0xFFDDE9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFB4C9FF)),
      ),
      child: const Text(
        'Note that the contracting timeline would be applied to all contracts but can be adjusted when required for respective contracts.\nNeed help? Ask AI KAZ some prompting questions related to your project type',
        style: TextStyle(fontSize: 14, color: Color(0xFF0F172A), height: 1.4),
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  const _UserBadge();

  String _roleFor(User? user) {
    final email = user?.email?.toLowerCase() ?? '';
    if (email.endsWith('@nduproject.com')) {
      return 'Owner';
    }
    return 'Member';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final email = user?.email ?? '';
    final initials = _initials(displayName.isNotEmpty ? displayName : (email.isNotEmpty ? email : 'U'));
    final role = _roleFor(user);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE5E7EB),
            child: Text(initials, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                email.isNotEmpty ? email : displayName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              Text(
                role,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }

  String _initials(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 'U';
    }
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      final result = '$first$second';
      return result.isEmpty ? 'U' : result.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, this.onEdit});

  final _TimelineStepData step;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isCurrent = step.status == _TimelineStatus.current;
    final circleColor = isCurrent ? const Color(0xFFFFD233) : const Color(0xFFE5E7EB);
    final numberColor = isCurrent ? const Color(0xFF111827) : const Color(0xFF9CA3AF);
    final titleColor = isCurrent ? const Color(0xFF111827) : const Color(0xFF9CA3AF);
    final descriptionColor = isCurrent ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step.number.toString(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: numberColor),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: titleColor)),
              const SizedBox(height: 6),
              Text(step.description, style: TextStyle(fontSize: 14, color: descriptionColor)),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Make the estimate label itself editable/clickable
                  Tooltip(
                    message: 'Edit estimated days',
                    child: InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          step.estimate,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: onEdit,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 0),
                        foregroundColor: const Color(0xFF2563EB),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Set days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContractMetricsRow extends StatelessWidget {
  const _ContractMetricsRow({required this.metrics});

  final List<_ContractMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double gap = 16;
        double cardWidth = constraints.maxWidth;

        if (constraints.maxWidth >= 1080) {
          cardWidth = (constraints.maxWidth - (metrics.length - 1) * gap) / metrics.length;
        } else if (constraints.maxWidth >= 720) {
          cardWidth = (constraints.maxWidth - gap) / 2;
        }

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: cardWidth,
                  child: _ContractMetricCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ContractMetricCard extends StatelessWidget {
  const _ContractMetricCard({required this.metric});

  final _ContractMetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: metric.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(metric.icon, color: metric.accentColor, size: 22),
          ),
          const SizedBox(height: 18),
          Text(
            metric.value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          Text(
            metric.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          Text(
            metric.detail,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
        ],
      ),
    );
  }
}

class _ContractRecordCard extends StatelessWidget {
  const _ContractRecordCard({required this.record});

  final _ContractRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x09000000), blurRadius: 14, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.code,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Owner: ${record.owner}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: record.status, color: record.statusColor),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [
              _RecordInfoRow(icon: Icons.payments_outlined, label: 'Contract Value', value: record.value),
              _RecordInfoRow(
                icon: Icons.calendar_month_outlined,
                label: 'Effective',
                value: '${record.effectiveDate} • Renewals on ${record.renewalDate}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE5E7EB), height: 32),
          const Text(
            'Highlights',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          ...record.highlights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record.lastUpdated,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              TextButton.icon(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('View Contract', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _RecordInfoRow extends StatelessWidget {
  const _RecordInfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class ContractDetailsScreen extends StatefulWidget {
  const ContractDetailsScreen({super.key});

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  final TextEditingController _additionalInfoController = TextEditingController();
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  void _handleStepTap(int index) {
    if (index == 0) {
      Navigator.of(context).maybePop();
    } else if (index == 2) {
      _openContractingStatus();
    } else if (index == 3) {
      ContractingSummaryScreen.open(context);
    }
  }

  void _openContractingStatus() {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'ContractingStatusScreen'),
        builder: (_) => const ContractingStatusScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 24 : 48;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Contract'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isMobile ? 28 : 48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StrategyHeader(onBack: () => Navigator.of(context).maybePop()),
                        SizedBox(height: isMobile ? 24 : 36),
                        _StrategyStepPills(selectedIndex: 1, onStepTap: _handleStepTap),
                        SizedBox(height: isMobile ? 24 : 32),
                        _AdditionalInfoField(controller: _additionalInfoController),
                        SizedBox(height: isMobile ? 24 : 32),
                        const _ContractOverviewSummaryCard(),
                        SizedBox(height: isMobile ? 24 : 32),
                        _ContractDetailsContent(
                          selectedIndex: _selectedTabIndex,
                          onTabSelected: (index) => setState(() => _selectedTabIndex = index),
                        ),
                        SizedBox(height: isMobile ? 80 : 120),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                  const AdminEditToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractingStatusScreen extends StatefulWidget {
  const ContractingStatusScreen({super.key});

  @override
  State<ContractingStatusScreen> createState() => _ContractingStatusScreenState();
}

class _ContractingStatusScreenState extends State<ContractingStatusScreen> {
  final TextEditingController _additionalInfoController = TextEditingController();
  String _selectedView = 'Overview';
  String _selectedContract = 'Engineering Services Contract';
  String _selectedContractorStatus = 'All Status';

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  void _handleStepTap(int index) {
    if (index == 1) {
      Navigator.of(context).pop();
      return;
    }
    if (index == 0) {
      Navigator.of(context).popUntil(
        (route) => route.settings.name == 'ContractingStrategyScreen' || route.isFirst,
      );
      return;
    }
    if (index == 3) {
      ContractingSummaryScreen.open(context);
    }
  }

  Widget _buildSelectedView({required bool isMobile}) {
    switch (_selectedView) {
      case 'Overview':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ContractStatusOverview(isMobile: isMobile),
            SizedBox(height: isMobile ? 24 : 32),
            const _ContractStatusMilestonesCard(),
            SizedBox(height: isMobile ? 28 : 36),
            _ContractExecutionSection(
              selectedContract: _selectedContract,
              onContractChanged: (value) => setState(() => _selectedContract = value),
            ),
          ],
        );
      case 'Contractors':
        return _ContractorsDirectorySection(
          isMobile: isMobile,
          selectedStatus: _selectedContractorStatus,
          onStatusChanged: (value) => setState(() => _selectedContractorStatus = value),
        );
      case 'Contract Specifications':
      case 'Milestones':
      case 'Documents':
        return _StatusViewPlaceholder(label: _selectedView);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 24 : 48;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Contract'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isMobile ? 28 : 48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StrategyHeader(onBack: () => Navigator.of(context).maybePop()),
                        SizedBox(height: isMobile ? 24 : 36),
                        _StrategyStepPills(selectedIndex: 2, onStepTap: _handleStepTap),
                        SizedBox(height: isMobile ? 24 : 32),
                        _AdditionalInfoField(controller: _additionalInfoController),
                        SizedBox(height: isMobile ? 24 : 32),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedView,
                              items: const [
                                DropdownMenuItem(value: 'Overview', child: Text('Overview')),
                                DropdownMenuItem(value: 'Contractors', child: Text('Contractors')),
                                DropdownMenuItem(value: 'Contract Specifications', child: Text('Contract Specifications')),
                                DropdownMenuItem(value: 'Milestones', child: Text('Milestones')),
                                DropdownMenuItem(value: 'Documents', child: Text('Documents')),
                              ],
                              onChanged: (value) => setState(() => _selectedView = value ?? _selectedView),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                                ),
                              ),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 20 : 28),
                        _buildSelectedView(isMobile: isMobile),
                        SizedBox(height: isMobile ? 80 : 120),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                  const AdminEditToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractingSummaryScreen extends StatefulWidget {
  const ContractingSummaryScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'ContractingSummaryScreen'),
        builder: (_) => const ContractingSummaryScreen(),
      ),
    );
  }

  @override
  State<ContractingSummaryScreen> createState() => _ContractingSummaryScreenState();
}

class _ContractingSummaryScreenState extends State<ContractingSummaryScreen> {
  void _handleStepTap(int index) {
    if (index == 0) {
      _returnToStrategy();
    } else if (index == 1) {
      _openContractDetails();
    } else if (index == 2) {
      _openContractingStatus();
    }
  }

  void _returnToStrategy() {
    Navigator.of(context).popUntil(
      (route) => route.settings.name == 'ContractingStrategyScreen' || route.isFirst,
    );
  }

  void _openContractDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'ContractDetailsScreen'),
        builder: (_) => const ContractDetailsScreen(),
      ),
    );
  }

  void _openContractingStatus() {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'ContractingStatusScreen'),
        builder: (_) => const ContractingStatusScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 24 : 48;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Contract'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isMobile ? 28 : 48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StrategyHeader(onBack: () => Navigator.of(context).maybePop()),
                        SizedBox(height: isMobile ? 24 : 36),
                        _StrategyStepPills(selectedIndex: 3, onStepTap: _handleStepTap),
                        SizedBox(height: isMobile ? 24 : 32),
                        const _ContractingSummaryOverviewCard(),
                        SizedBox(height: isMobile ? 24 : 32),
                        const _ContractingSummaryImpactsRow(),
                        SizedBox(height: isMobile ? 24 : 32),
                        const _ContractingSummaryWarrantyCard(),
                        SizedBox(height: isMobile ? 24 : 32),
                        const _ContractingSummaryHighlightsRow(),
                        SizedBox(height: isMobile ? 80 : 120),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                  const AdminEditToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractingSummaryOverviewCard extends StatelessWidget {
  const _ContractingSummaryOverviewCard();

  static final List<_SummaryTableRowData> _rows = [
    _SummaryTableRowData(
      contract: 'Engineering Services Contract',
      contractor: 'Engineering Consultants Ltd.',
      method: 'Bidding / Lump Sum',
      estimatedValue: '\$90,000',
      duration: '90 days',
      statusLabel: 'Behind Schedule',
      statusColor: const Color(0xFFEF4444),
    ),
    _SummaryTableRowData(
      contract: 'Contract 1',
      contractor: 'TBD',
      method: 'Bidding / Reimbursable',
      estimatedValue: '\$17,000',
      duration: '0 days',
      statusLabel: 'Behind Schedule',
      statusColor: const Color(0xFFF97316),
    ),
    _SummaryTableRowData(
      contract: 'Total',
      contractor: '',
      method: '',
      estimatedValue: '\$102,000',
      duration: '90 days (critical path)',
      isTotals: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0C0F172A), blurRadius: 20, offset: Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contracting Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Summary of all contracts with cost and timeline impact.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                    child: Row(
                      children: const [
                        _SummaryTableHeaderCell(label: 'Contract', flex: 20),
                        _SummaryTableHeaderCell(label: 'Contractor', flex: 20),
                        _SummaryTableHeaderCell(label: 'Contracting Method', flex: 20),
                        _SummaryTableHeaderCell(label: 'Estimated Value', flex: 16),
                        _SummaryTableHeaderCell(label: 'Duration', flex: 14),
                        _SummaryTableHeaderCell(label: 'Status', flex: 10),
                      ],
                    ),
                  ),
                  for (int i = 0; i < _rows.length; i++) ...[
                    _SummaryTableRow(data: _rows[i]),
                    if (i != _rows.length - 1) const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTableHeaderCell extends StatelessWidget {
  const _SummaryTableHeaderCell({required this.label, required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
      ),
    );
  }
}

class _SummaryTableRow extends StatelessWidget {
  const _SummaryTableRow({required this.data});

  final _SummaryTableRowData data;

  @override
  Widget build(BuildContext context) {
    final TextStyle primaryStyle = TextStyle(
      fontSize: 13,
      fontWeight: data.isTotals ? FontWeight.w700 : FontWeight.w600,
      color: const Color(0xFF111827),
    );
    final TextStyle secondaryStyle = TextStyle(
      fontSize: 13,
      fontWeight: data.isTotals ? FontWeight.w600 : FontWeight.w500,
      color: data.isTotals ? const Color(0xFF111827) : const Color(0xFF4B5563),
    );

    String placeholderIfNeeded(String value) {
      if (value.isEmpty && !data.isTotals) {
        return '—';
      }
      return value;
    }

    return Container(
      color: data.isTotals ? const Color(0xFFF9FAFB) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 20, child: Text(data.contract, style: primaryStyle)),
          Expanded(flex: 20, child: Text(placeholderIfNeeded(data.contractor), style: secondaryStyle)),
          Expanded(flex: 20, child: Text(placeholderIfNeeded(data.method), style: secondaryStyle)),
          Expanded(flex: 16, child: Text(data.estimatedValue, style: secondaryStyle)),
          Expanded(flex: 14, child: Text(data.duration, style: secondaryStyle)),
          Expanded(
            flex: 10,
            child: data.statusLabel != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: _ContractStatusChip(
                      label: data.statusLabel!,
                      color: data.statusColor ?? const Color(0xFFEF4444),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SummaryTableRowData {
  const _SummaryTableRowData({
    required this.contract,
    required this.contractor,
    required this.method,
    required this.estimatedValue,
    required this.duration,
    this.statusLabel,
    this.statusColor,
    this.isTotals = false,
  });

  final String contract;
  final String contractor;
  final String method;
  final String estimatedValue;
  final String duration;
  final String? statusLabel;
  final Color? statusColor;
  final bool isTotals;
}

class _ContractingSummaryImpactsRow extends StatelessWidget {
  const _ContractingSummaryImpactsRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 960) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _ContractingSummaryBudgetImpactCard(),
              SizedBox(height: 24),
              _ContractingSummaryScheduleImpactCard(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(child: _ContractingSummaryBudgetImpactCard()),
            SizedBox(width: 24),
            Expanded(child: _ContractingSummaryScheduleImpactCard()),
          ],
        );
      },
    );
  }
}

class _ContractingSummaryBudgetImpactCard extends StatelessWidget {
  const _ContractingSummaryBudgetImpactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0C0F172A), blurRadius: 18, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Budget Impact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 14),
          const Text(
            'The total contract value of \$102,000 has been automatically added to the project cost estimate.',
            style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 18),
          const _ImpactStatRow(label: 'Original Budget', value: '\$200,000'),
          const SizedBox(height: 10),
          const _ImpactStatRow(label: 'Current Estimate', value: '\$102,000'),
          const SizedBox(height: 10),
          const _ImpactStatRow(label: 'Variance', value: '\$98,000 (-49%)', valueColor: Color(0xFFDC2626)),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              alignment: Alignment.centerLeft,
            ),
            child: const Text('View Cost Estimates'),
          ),
        ],
      ),
    );
  }
}

class _ContractingSummaryScheduleImpactCard extends StatelessWidget {
  const _ContractingSummaryScheduleImpactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0C0F172A), blurRadius: 18, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Schedule Impact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 14),
          const Text(
            'Contract durations have been incorporated into the project schedule. The longest contract duration is on the critical path.',
            style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 18),
          const _ImpactStatRow(label: 'Project Start', value: 'April 1, 2025'),
          const SizedBox(height: 10),
          const _ImpactStatRow(label: 'Contracting Finish', value: 'June 30, 2025'),
          const SizedBox(height: 10),
          const _ImpactStatRow(label: 'Total Duration', value: '90 days'),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              alignment: Alignment.centerLeft,
            ),
            child: const Text('View Project Schedule'),
          ),
        ],
      ),
    );
  }
}

class _ImpactStatRow extends StatelessWidget {
  const _ImpactStatRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF111827)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ContractingSummaryWarrantyCard extends StatelessWidget {
  const _ContractingSummaryWarrantyCard();

  static final List<_WarrantyRowData> _rows = [
    _WarrantyRowData(
      contract: 'Engineering Services Contract',
      warrantyPeriod: 'TBD',
      supportType: 'TBD',
      contactInformation: 'TBD',
      documentLabel: 'View here',
    ),
    _WarrantyRowData(
      contract: 'Contract 1',
      warrantyPeriod: 'TBD',
      supportType: 'TBD',
      contactInformation: 'TBD',
      documentLabel: 'View Here',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0C0F172A), blurRadius: 18, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Warranty & Support Documentation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep track of warranties, maintenance agreements, and support contacts for all contracts.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                    child: Row(
                      children: const [
                        _WarrantyTableHeaderCell(label: 'Contract', flex: 24),
                        _WarrantyTableHeaderCell(label: 'Warranty Period', flex: 18),
                        _WarrantyTableHeaderCell(label: 'Support Type', flex: 18),
                        _WarrantyTableHeaderCell(label: 'Contact Information', flex: 24),
                        _WarrantyTableHeaderCell(label: 'Documents', flex: 16),
                      ],
                    ),
                  ),
                  for (int i = 0; i < _rows.length; i++) ...[
                    _WarrantyTableRow(data: _rows[i]),
                    if (i != _rows.length - 1) const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarrantyTableHeaderCell extends StatelessWidget {
  const _WarrantyTableHeaderCell({required this.label, required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
      ),
    );
  }
}

class _WarrantyTableRow extends StatelessWidget {
  const _WarrantyTableRow({required this.data});

  final _WarrantyRowData data;

  @override
  Widget build(BuildContext context) {
    const TextStyle primaryStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827));
    const TextStyle secondaryStyle = TextStyle(fontSize: 13, color: Color(0xFF4B5563));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 24, child: Text(data.contract, style: primaryStyle)),
          Expanded(flex: 18, child: Text(data.warrantyPeriod, style: secondaryStyle)),
          Expanded(flex: 18, child: Text(data.supportType, style: secondaryStyle)),
          Expanded(flex: 24, child: Text(data.contactInformation, style: secondaryStyle)),
          Expanded(
            flex: 16,
            child: data.documentLabel != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      child: Text(data.documentLabel!),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _WarrantyRowData {
  const _WarrantyRowData({
    required this.contract,
    required this.warrantyPeriod,
    required this.supportType,
    required this.contactInformation,
    this.documentLabel,
  });

  final String contract;
  final String warrantyPeriod;
  final String supportType;
  final String contactInformation;
  final String? documentLabel;
}

class _ContractingSummaryHighlightsRow extends StatelessWidget {
  const _ContractingSummaryHighlightsRow();

  static final List<_SummaryHighlightCardData> _cards = [
    _SummaryHighlightCardData(
      title: 'Contract Summary',
      items: [
        '2 Contracts Planned',
        '0 Contract In-Progress',
        '0 Contracts Completed',
      ],
    ),
    _SummaryHighlightCardData(
      title: 'Timeline Status',
      items: [
        '2 Contracts Behind Schedule.',
        '0 Contracts On Schedule.',
        '30 Days to Next Milestone',
      ],
    ),
    _SummaryHighlightCardData(
      title: 'Budget Impact',
      items: [
        '\$102,000 Total Contract Value.',
        '\$200,000 Budgeted.',
        '\$98,000 Variance (-49%)',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_cards.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index == _cards.length - 1 ? 0 : 20),
                child: _SummaryHighlightCard(data: _cards[index]),
              );
            }),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < _cards.length; i++) ...[
              Expanded(child: _SummaryHighlightCard(data: _cards[i])),
              if (i != _cards.length - 1) const SizedBox(width: 20),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryHighlightCard extends StatelessWidget {
  const _SummaryHighlightCard({required this.data});

  final _SummaryHighlightCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0C0F172A), blurRadius: 18, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < data.items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == data.items.length - 1 ? 0 : 12),
              child: _SummaryHighlightBullet(text: data.items[i]),
            ),
        ],
      ),
    );
  }
}

class _SummaryHighlightCardData {
  const _SummaryHighlightCardData({required this.title, required this.items});

  final String title;
  final List<String> items;
}

class _SummaryHighlightBullet extends StatelessWidget {
  const _SummaryHighlightBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF2563EB)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _ContractStatusOverview extends StatelessWidget {
  const _ContractStatusOverview({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _ContractStatusTimelineCard(),
          SizedBox(height: 24),
          _ContractStatusSummaryCard(),
          SizedBox(height: 20),
          _ContractStatusRecentActivityCard(),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _ContractStatusTimelineCard(),
              SizedBox(height: 24),
              _ContractStatusSummaryCard(),
              SizedBox(height: 20),
              _ContractStatusRecentActivityCard(),
            ],
          );
        }

        final double rightColumnWidth = 300;
        final double spacing = 24;
        final double timelineWidth = constraints.maxWidth - rightColumnWidth - spacing;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: timelineWidth, child: const _ContractStatusTimelineCard()),
            SizedBox(width: spacing),
            SizedBox(
              width: rightColumnWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  _ContractStatusSummaryCard(),
                  SizedBox(height: 20),
                  _ContractStatusRecentActivityCard(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ContractStatusTimelineCard extends StatelessWidget {
  const _ContractStatusTimelineCard();

  static const List<String> _months = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'];

  static const List<_StatusTimelineRowData> _rows = [
    _StatusTimelineRowData(
      label: 'All Contract Awards Complete',
      cells: [
        _StatusTimelineCellData(status: _TimelineStatusState.complete),
        _StatusTimelineCellData(status: _TimelineStatusState.complete),
        _StatusTimelineCellData(status: _TimelineStatusState.complete),
        _StatusTimelineCellData(status: _TimelineStatusState.inProgress),
        _StatusTimelineCellData(status: _TimelineStatusState.inProgress),
        _StatusTimelineCellData(status: _TimelineStatusState.notStarted),
        _StatusTimelineCellData(status: _TimelineStatusState.notStarted),
      ],
    ),
    _StatusTimelineRowData(
      label: 'Equipment Delivery',
      cells: [
        _StatusTimelineCellData(status: _TimelineStatusState.notStarted),
        _StatusTimelineCellData(status: _TimelineStatusState.notStarted),
        _StatusTimelineCellData(status: _TimelineStatusState.inProgress),
        _StatusTimelineCellData(status: _TimelineStatusState.inProgress),
        _StatusTimelineCellData(status: _TimelineStatusState.complete),
        _StatusTimelineCellData(status: _TimelineStatusState.complete),
        _StatusTimelineCellData(status: _TimelineStatusState.complete),
      ],
    ),
    _StatusTimelineRowData(
      label: 'Software Integration Complete',
      cells: [
        _StatusTimelineCellData(status: _TimelineStatusState.notStarted),
        _StatusTimelineCellData(status: _TimelineStatusState.notStarted),
        _StatusTimelineCellData(status: _TimelineStatusState.notStarted),
        _StatusTimelineCellData(status: _TimelineStatusState.inProgress),
        _StatusTimelineCellData(status: _TimelineStatusState.behindSchedule),
        _StatusTimelineCellData(status: _TimelineStatusState.inProgress),
        _StatusTimelineCellData(status: _TimelineStatusState.inProgress),
      ],
    ),
    _StatusTimelineRowData(
      label: 'Project Handover',
      cells: [
        _StatusTimelineCellData(status: _TimelineStatusState.notStarted),
        _StatusTimelineCellData(status: _TimelineStatusState.notStarted),
        _StatusTimelineCellData(status: _TimelineStatusState.notStarted),
        _StatusTimelineCellData(status: _TimelineStatusState.notStarted),
        _StatusTimelineCellData(status: _TimelineStatusState.notStarted),
        _StatusTimelineCellData(status: _TimelineStatusState.inProgress),
        _StatusTimelineCellData(status: _TimelineStatusState.inProgress),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0C0F172A), blurRadius: 20, offset: Offset(0, 16))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Contract Status Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  SizedBox(height: 6),
                  Text('Complete | In Progress | Not Started | Behind Schedule', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
              const _TimelineLegend(),
            ],
          ),
          const SizedBox(height: 22),
          _TimelineHeader(months: _months),
          const Divider(height: 32, color: Color(0xFFE5E7EB)),
          for (int i = 0; i < _rows.length; i++) ...[
            _TimelineRow(row: _rows[i]),
            if (i != _rows.length - 1) const SizedBox(height: 18),
          ],
          const SizedBox(height: 28),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          const Text('Overall Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.5,
              minHeight: 10,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC233)),
            ),
          ),
          const SizedBox(height: 10),
          const Text('50% complete', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({required this.months});

  final List<String> months;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          const Expanded(
            flex: 32,
            child: Text('Contract', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          ),
          for (final month in months)
            Expanded(
              flex: 12,
              child: Text(month, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)), textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.row});

  final _StatusTimelineRowData row;

  Color _colorForStatus(_TimelineStatusState status) {
    switch (status) {
      case _TimelineStatusState.complete:
        return const Color(0xFF22C55E);
      case _TimelineStatusState.inProgress:
        return const Color(0xFF2563EB);
      case _TimelineStatusState.behindSchedule:
        return const Color(0xFFF59E0B);
      case _TimelineStatusState.notStarted:
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 32,
            child: Text(
              row.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
            ),
          ),
          for (final cell in row.cells)
            Expanded(
              flex: 12,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: _colorForStatus(cell.status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineLegend extends StatelessWidget {
  const _TimelineLegend();

  static const List<_TimelineLegendItem> _items = [
    _TimelineLegendItem(label: 'Complete', color: Color(0xFF22C55E)),
    _TimelineLegendItem(label: 'In Progress', color: Color(0xFF2563EB)),
    _TimelineLegendItem(label: 'Not Started', color: Color(0xFFE5E7EB)),
    _TimelineLegendItem(label: 'Behind Schedule', color: Color(0xFFF59E0B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(item.label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _ContractStatusSummaryCard extends StatelessWidget {
  const _ContractStatusSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0C0F172A), blurRadius: 20, offset: Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contract Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 18),
          const Text('Average Bid Value', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          const Text('\$2,874,000', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          _SummaryStat(label: 'Total Contractors', value: '5'),
          const SizedBox(height: 10),
          _SummaryStat(label: 'Milestone Progress', value: '2/4 Complete'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Status', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              _StatusPill(label: 'Bid Evaluation', color: Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
      ],
    );
  }
}

class _ContractStatusRecentActivityCard extends StatelessWidget {
  const _ContractStatusRecentActivityCard();

  static const List<_RecentActivityData> _activities = [
    _RecentActivityData(description: 'BuildTech Engineering Corp submitted bid', date: '8/21/2025'),
    _RecentActivityData(description: 'MetroStructural Solutions status updated', date: '8/17/2025'),
    _RecentActivityData(description: 'Prime Construction Group status updated', date: '8/10/2025'),
    _RecentActivityData(description: 'TechBuild Systems Inc status updated', date: '8/02/2025'),
    _RecentActivityData(description: 'Apex Engineering Services submitted bid', date: '7/21/2025'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0C0F172A), blurRadius: 20, offset: Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 18),
          ..._activities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.description, style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937))),
                        const SizedBox(height: 4),
                        Text(activity.date, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
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

class _ContractorsDirectorySection extends StatelessWidget {
  const _ContractorsDirectorySection({required this.isMobile, required this.selectedStatus, required this.onStatusChanged});

  final bool isMobile;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  static const List<String> _statusFilters = [
    'All Status',
    'Bid Submitted',
    'Under Review',
    'Shortlisted',
    'Awarded',
  ];

  static final List<_ContractorRowData> _rows = [
    _ContractorRowData(
      name: 'BuildTech Engineering Corp',
      role: 'General Contractor',
      location: 'New York, NY',
      bidAmount: r'$2,850,000',
      statusLabel: 'Bid Submitted',
      statusColor: Color(0xFFF59E0B),
      submissionDate: '8/15/2024',
      score: 92,
      scoreColor: Color(0xFF22C55E),
    ),
    _ContractorRowData(
      name: 'MetroStructural Solutions',
      role: 'Structural Engineering',
      location: 'Chicago, IL',
      bidAmount: r'$2,720,000',
      statusLabel: 'Under Review',
      statusColor: Color(0xFFF59E0B),
      submissionDate: '8/18/2024',
      score: 89,
      scoreColor: Color(0xFFF59E0B),
    ),
    _ContractorRowData(
      name: 'Prime Construction Group',
      role: 'General Contractor',
      location: 'Los Angeles, CA',
      bidAmount: r'$3,200,000',
      statusLabel: 'Shortlisted',
      statusColor: Color(0xFFF59E0B),
      submissionDate: '8/12/2024',
      score: 85,
      scoreColor: Color(0xFFF59E0B),
    ),
    _ContractorRowData(
      name: 'TechBuild Systems Inc',
      role: 'MEP Engineering',
      location: 'Seattle, WA',
      bidAmount: r'$2,650,000',
      statusLabel: 'Awarded',
      statusColor: Color(0xFF22C55E),
      submissionDate: '8/20/2024',
      score: 95,
      scoreColor: Color(0xFF22C55E),
    ),
    _ContractorRowData(
      name: 'Apex Engineering Services',
      role: 'Civil Engineering',
      location: 'Dallas, TX',
      bidAmount: r'$2,950,000',
      statusLabel: 'Bid Submitted',
      statusColor: Color(0xFFF59E0B),
      submissionDate: '8/16/2024',
      score: 87,
      scoreColor: Color(0xFFF59E0B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32, vertical: isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0C0F172A), blurRadius: 22, offset: Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Contractors for Engineering Services Contract',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                SizedBox(height: 12),
                _ContractComparisonsButton(fullWidth: true),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Contractors for Engineering Services Contract',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                ),
                const SizedBox(width: 16),
                const _ContractComparisonsButton(),
              ],
            ),
          SizedBox(height: isMobile ? 20 : 24),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ContractorSearchField(),
                const SizedBox(height: 12),
                _ContractorStatusDropdown(selectedStatus: selectedStatus, onChanged: onStatusChanged),
              ],
            )
          else
            Row(
              children: [
                const Expanded(child: _ContractorSearchField()),
                const SizedBox(width: 16),
                SizedBox(width: 180, child: _ContractorStatusDropdown(selectedStatus: selectedStatus, onChanged: onStatusChanged)),
              ],
            ),
          const SizedBox(height: 24),
          _ContractorsTable(rows: _rows, isMobile: isMobile),
        ],
      ),
    );
  }
}

class _ContractorSearchField extends StatelessWidget {
  const _ContractorSearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search contractors...',
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
        ),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
    );
  }
}

class _ContractorStatusDropdown extends StatelessWidget {
  const _ContractorStatusDropdown({required this.selectedStatus, required this.onChanged});

  final String selectedStatus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedStatus,
      items: _ContractorsDirectorySection._statusFilters
          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
        ),
      ),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
    );
  }
}

class _ContractorsTable extends StatelessWidget {
  const _ContractorsTable({required this.rows, required this.isMobile});

  final List<_ContractorRowData> rows;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final Widget table = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            children: const [
              _ContractorsHeaderCell(label: 'CONTRACTOR', flex: 32),
              _ContractorsHeaderCell(label: 'LOCATION', flex: 18),
              _ContractorsHeaderCell(label: 'BID AMOUNT', flex: 16),
              _ContractorsHeaderCell(label: 'STATUS', flex: 16),
              _ContractorsHeaderCell(label: 'SUBMISSION DATE', flex: 14),
              _ContractorsHeaderCell(label: 'SCORE', flex: 14),
              _ContractorsHeaderCell(label: 'ACTIONS', flex: 12, textAlign: TextAlign.right),
            ],
          ),
        ),
        ...List.generate(rows.length, (index) {
          final _ContractorRowData data = rows[index];
          return Column(
            children: [
              _ContractorTableRow(data: data),
              if (index != rows.length - 1) const Divider(height: 24, color: Color(0xFFE5E7EB)),
            ],
          );
        }),
      ],
    );

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 960),
          child: table,
        ),
      );
    }

    return table;
  }
}

class _ContractorTableRow extends StatelessWidget {
  const _ContractorTableRow({required this.data});

  final _ContractorRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 32,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFE5E7EB),
                  child: Icon(Icons.apartment_rounded, size: 20, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      const SizedBox(height: 4),
                      Text(data.role, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(data.location, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
          ),
          Expanded(
            flex: 16,
            child: Text(data.bidAmount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          ),
          Expanded(
            flex: 16,
            child: _ContractStatusChip(label: data.statusLabel, color: data.statusColor),
          ),
          Expanded(
            flex: 14,
            child: Text(data.submissionDate, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
          ),
          Expanded(
            flex: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data.score}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: data.score / 100,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(data.scoreColor),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 12,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('View Details'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractorsHeaderCell extends StatelessWidget {
  const _ContractorsHeaderCell({required this.label, required this.flex, this.textAlign = TextAlign.left});

  final String label;
  final int flex;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.3),
        textAlign: textAlign,
      ),
    );
  }
}

class _ContractStatusChip extends StatelessWidget {
  const _ContractStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}

class _ContractComparisonsButton extends StatelessWidget {
  const _ContractComparisonsButton({this.fullWidth = false});

  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final Widget button = ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFC233),
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: const Text('Contract Comparisons'),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

class _ContractorRowData {
  const _ContractorRowData({
    required this.name,
    required this.role,
    required this.location,
    required this.bidAmount,
    required this.statusLabel,
    required this.statusColor,
    required this.submissionDate,
    required this.score,
    required this.scoreColor,
  });

  final String name;
  final String role;
  final String location;
  final String bidAmount;
  final String statusLabel;
  final Color statusColor;
  final String submissionDate;
  final int score;
  final Color scoreColor;
}

class _StatusViewPlaceholder extends StatelessWidget {
  const _StatusViewPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0C0F172A), blurRadius: 18, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          const Text(
            'Content for this section is coming soon. We are keeping navigation consistent while designs finalize.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ContractStatusMilestonesCard extends StatelessWidget {
  const _ContractStatusMilestonesCard();

  static const List<_MilestoneEntry> _entries = [
    _MilestoneEntry(label: 'All Contract Awards Complete', date: '5/15/2024', statusColor: Color(0xFF22C55E)),
    _MilestoneEntry(label: 'Equipment Delivery', date: '7/15/2024', statusColor: Color(0xFF2563EB)),
    _MilestoneEntry(label: 'Software Integration Complete', date: '9/15/2024', statusColor: Color(0xFFF59E0B)),
    _MilestoneEntry(label: 'Project Handover', date: '11/15/2024', statusColor: Color(0xFFE5E7EB)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0C0F172A), blurRadius: 18, offset: Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Key Milestone Dates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 20),
          ..._entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.label, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                  ),
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: entry.statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text(entry.date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    ],
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

class _ContractExecutionSection extends StatelessWidget {
  const _ContractExecutionSection({required this.selectedContract, required this.onContractChanged});

  final String selectedContract;
  final ValueChanged<String> onContractChanged;

  static const List<_ExecutionStepData> _steps = [
    _ExecutionStepData(
      title: 'Request for Quote (RFQ)',
      description: 'Create and distribute RFQ documents to potential vendors',
      statusDetail: 'calendar today Not scheduled',
      highlightAction: true,
    ),
    _ExecutionStepData(
      title: 'Bidding',
      description: 'Vendors submit their proposals and quotes',
      statusDetail: 'calendar today Not scheduled',
    ),
    _ExecutionStepData(
      title: 'Clarifications',
      description: 'Request additional information from vendors',
      statusDetail: 'calendar today Not scheduled',
    ),
    _ExecutionStepData(
      title: 'Review Quotes',
      description: 'Analyze and compare vendor proposals',
      statusDetail: 'calendar today Not scheduled',
    ),
    _ExecutionStepData(
      title: 'Award',
      description: 'Select vendor and finalize contract',
      statusDetail: 'calendar today Not scheduled',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0C0F172A), blurRadius: 18, offset: Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Contract Execution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedContract,
                  onChanged: (value) => onContractChanged(value ?? selectedContract),
                  items: const [
                    DropdownMenuItem(value: 'Engineering Services Contract', child: Text('Engineering Services Contract')),
                    DropdownMenuItem(value: 'IT Support Contract', child: Text('IT Support Contract')),
                    DropdownMenuItem(value: 'Infrastructure Contract', child: Text('Infrastructure Contract')),
                  ],
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Column(
            children: List.generate(
              _steps.length,
              (index) => _ExecutionTimelineRow(
                data: _steps[index],
                isFirst: index == 0,
                isLast: index == _steps.length - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExecutionTimelineRow extends StatelessWidget {
  const _ExecutionTimelineRow({required this.data, required this.isFirst, required this.isLast});

  final _ExecutionStepData data;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    height: 14,
                    width: 2,
                    color: const Color(0xFFE5E7EB),
                  ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isFirst ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    data.shortCode,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isFirst ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    height: 70,
                    width: 2,
                    color: const Color(0xFFE5E7EB),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text(data.description, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                const SizedBox(height: 6),
                Text(data.statusDetail, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                if (data.highlightAction) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0987FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Start Request for Quote (RFQ)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineLegendItem {
  const _TimelineLegendItem({required this.label, required this.color});

  final String label;
  final Color color;
}

class _StatusTimelineRowData {
  const _StatusTimelineRowData({required this.label, required this.cells});

  final String label;
  final List<_StatusTimelineCellData> cells;
}

class _StatusTimelineCellData {
  const _StatusTimelineCellData({required this.status});

  final _TimelineStatusState status;
}

enum _TimelineStatusState { complete, inProgress, notStarted, behindSchedule }

class _MilestoneEntry {
  const _MilestoneEntry({required this.label, required this.date, required this.statusColor});

  final String label;
  final String date;
  final Color statusColor;
}

class _RecentActivityData {
  const _RecentActivityData({required this.description, required this.date});

  final String description;
  final String date;
}

class _ExecutionStepData {
  const _ExecutionStepData({required this.title, required this.description, required this.statusDetail, this.highlightAction = false});

  final String title;
  final String description;
  final String statusDetail;
  final bool highlightAction;

  String get shortCode => title.isNotEmpty ? title[0].toUpperCase() : '?';
}

class _AdditionalInfoField extends StatelessWidget {
  const _AdditionalInfoField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 16, offset: Offset(0, 10))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: TextField(
        controller: controller,
        maxLines: 4,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Any additional information about this contract',
          hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      ),
    );
  }
}

class _ContractOverviewSummaryCard extends StatelessWidget {
  const _ContractOverviewSummaryCard();

  static const List<_ContractMilestoneData> _milestones = [
    _ContractMilestoneData(
      title: 'Published Date',
      value: 'July 22, 2025',
      accentColor: Color(0xFF2563EB),
    ),
    _ContractMilestoneData(
      title: 'Clarification Deadline',
      value: 'August 5, 2025',
      accentColor: Color(0xFF2563EB),
    ),
    _ContractMilestoneData(
      title: 'Submission Deadline',
      value: 'August 20, 2025 (5:00 PM CAT)',
      accentColor: Color(0xFFEF4444),
      emphasize: true,
    ),
    _ContractMilestoneData(
      title: 'Bid Opening',
      value: 'August 22, 2025',
      accentColor: Color(0xFF2563EB),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0D0F172A), blurRadius: 24, offset: Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Downtown Office Tower Construction',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Contract ID:',
                          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'DT-2025-001',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const _StatusPill(label: 'Open for Bidding', color: Color(0xFF22C55E)),
            ],
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool stack = constraints.maxWidth < 720;
              if (stack) {
                return Column(
                  children: _milestones
                      .map(
                        (milestone) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ContractMilestoneCard(data: milestone),
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: List.generate(_milestones.length, (index) {
                  final Widget card = _ContractMilestoneCard(data: _milestones[index]);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == _milestones.length - 1 ? 0 : 18),
                      child: card,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ContractMilestoneCard extends StatelessWidget {
  const _ContractMilestoneCard({required this.data});

  final _ContractMilestoneData data;

  @override
  Widget build(BuildContext context) {
    final Color background = data.emphasize ? const Color(0xFFFFF5F5) : data.accentColor.withOpacity(0.08);
    final Color textColor = data.emphasize ? const Color(0xFFB91C1C) : const Color(0xFF1F2937);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: data.accentColor)),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ContractMilestoneData {
  const _ContractMilestoneData({required this.title, required this.value, required this.accentColor, this.emphasize = false});

  final String title;
  final String value;
  final Color accentColor;
  final bool emphasize;
}

class _ContractDetailsContent extends StatelessWidget {
  const _ContractDetailsContent({required this.selectedIndex, required this.onTabSelected});

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stack = constraints.maxWidth < 1120;
        const double sidebarWidth = 300;

        if (stack || constraints.maxWidth < sidebarWidth + 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContractDetailsTabBlock(selectedIndex: selectedIndex, onTabSelected: onTabSelected),
              const SizedBox(height: 24),
              const _ContractDetailsSidebar(),
            ],
          );
        }

        final double contentWidth = constraints.maxWidth - sidebarWidth - 24;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: contentWidth,
              child: _ContractDetailsTabBlock(selectedIndex: selectedIndex, onTabSelected: onTabSelected),
            ),
            const SizedBox(width: 24),
            const SizedBox(width: sidebarWidth, child: _ContractDetailsSidebar()),
          ],
        );
      },
    );
  }
}

class _ContractDetailsTabBlock extends StatelessWidget {
  const _ContractDetailsTabBlock({required this.selectedIndex, required this.onTabSelected});

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ContractDetailsTabCard(selectedIndex: selectedIndex, onTabSelected: onTabSelected),
        const SizedBox(height: 24),
        const _UploadBidDocumentsCard(),
      ],
    );
  }
}

class _ContractDetailsTabCard extends StatelessWidget {
  const _ContractDetailsTabCard({required this.selectedIndex, required this.onTabSelected});

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C0F172A), blurRadius: 20, offset: Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ContractDetailsTabBar(selectedIndex: selectedIndex, onTabSelected: onTabSelected),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: _ContractDetailsTabContent(selectedIndex: selectedIndex),
          ),
        ],
      ),
    );
  }
}

class _ContractDetailsTabBar extends StatelessWidget {
  const _ContractDetailsTabBar({required this.selectedIndex, required this.onTabSelected});

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  static const List<String> _labels = ['Description', 'Contract Documents', 'Information for Bidders'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Row(
        children: List.generate(_labels.length, (index) {
          final bool isSelected = index == selectedIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTabSelected(index),
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _labels[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ContractDetailsTabContent extends StatelessWidget {
  const _ContractDetailsTabContent({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return const _DescriptionTabContent();
      case 1:
        return const _ContractDocumentsTabContent();
      case 2:
        return const _InformationForBiddersTabContent();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _DescriptionTabContent extends StatelessWidget {
  const _DescriptionTabContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Project Overview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        SizedBox(height: 12),
        Text(
          'The City of Lusaka invites sealed bids for the construction of a new 20-story office tower located at the corner of Independence Avenue and Cairo Road. This landmark project aims to provide modern, sustainable office space to support the city\'s growing commercial sector. The project includes the complete construction from foundation to finishing, including all mechanical, electrical, and plumbing (MEP) systems, landscaping, and associated infrastructure.',
          style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF4B5563)),
        ),
        SizedBox(height: 22),
        Text(
          'Scope of Work',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        SizedBox(height: 12),
        _BulletItem(text: 'Site preparation, excavation, and foundation work.'),
        _BulletItem(text: 'Structural steel and concrete framework construction.'),
        _BulletItem(text: 'Curtain wall and facade installation.'),
        _BulletItem(text: 'Complete interior fit-out, including walls, flooring, and ceilings.'),
        _BulletItem(text: 'Installation of all MEP systems (HVAC, electrical, plumbing, fire suppression).'),
        _BulletItem(text: 'Installation of elevators and building management systems.'),
        _BulletItem(text: 'Landscaping and external works, including parking facilities.'),
      ],
    );
  }
}

class _ContractDocumentsTabContent extends StatelessWidget {
  const _ContractDocumentsTabContent();

  static const List<_ContractDocumentData> _documents = [
    _ContractDocumentData(
      title: 'Architectural Drawings - Full Set',
      details: 'PDF, 45.2 MB',
      accentColor: Color(0xFFEF4444),
      icon: Icons.picture_as_pdf_outlined,
    ),
    _ContractDocumentData(
      title: 'Technical Specifications',
      details: 'DOCX, 2.1 MB',
      accentColor: Color(0xFF6366F1),
      icon: Icons.description_outlined,
    ),
    _ContractDocumentData(
      title: 'Bill of Quantities',
      details: 'XLSX, 850 KB',
      accentColor: Color(0xFF22C55E),
      icon: Icons.table_chart_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Required Documents',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Download All (.zip)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Column(
          children: _documents
              .map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ContractDocumentRow(data: doc),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _InformationForBiddersTabContent extends StatelessWidget {
  const _InformationForBiddersTabContent();

  static const List<_BidderInfoData> _info = [
    _BidderInfoData(
      title: 'Eligibility',
      description:
          'Bidders must be registered with the National Council for Construction (NCC) in Grade 1, Category B or higher. A valid Tax Clearance Certificate is mandatory.',
    ),
    _BidderInfoData(
      title: 'Bid Security',
      description: 'A bid security of 2% of the bid price in the form of a bank guarantee is required.',
    ),
    _BidderInfoData(
      title: 'Evaluation Criteria',
      description:
          'Bids will be evaluated based on 70% technical compliance and 30% financial proposal. Past performance on similar projects will be considered.',
    ),
    _BidderInfoData(
      title: 'Submission',
      description:
          'All bids must be submitted electronically through this portal. No physical submissions will be accepted. Ensure all required documents are uploaded in the correct format.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _info
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _BidderInfoRow(data: item),
            ),
          )
          .toList(),
    );
  }
}

class _ContractDetailsSidebar extends StatelessWidget {
  const _ContractDetailsSidebar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _ActionsSidebarCard(),
        SizedBox(height: 20),
        _ContactSidebarCard(),
        SizedBox(height: 20),
        _PreBidMeetingSidebarCard(),
      ],
    );
  }
}

class _ActionsSidebarCard extends StatelessWidget {
  const _ActionsSidebarCard();

  @override
  Widget build(BuildContext context) {
    return _SidebarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Submit Final Bid', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4B5563),
                backgroundColor: const Color(0xFFF9FAFB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save as Draft', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSidebarCard extends StatelessWidget {
  const _ContactSidebarCard();

  @override
  Widget build(BuildContext context) {
    return _SidebarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact for Inquiries', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('PK', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Precious Kaluba', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  SizedBox(height: 4),
                  Text('Procurement Officer', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  SizedBox(height: 4),
                  Text('p.kaluba@lusaka-city.gov.zm', style: TextStyle(fontSize: 13, color: Color(0xFF2563EB))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreBidMeetingSidebarCard extends StatelessWidget {
  const _PreBidMeetingSidebarCard();

  @override
  Widget build(BuildContext context) {
    return _SidebarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pre-Bid Meeting', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          const _SidebarInfoRow(label: 'Date', value: 'August 1, 2025'),
          const SizedBox(height: 10),
          const _SidebarInfoRow(label: 'Time', value: '10:00 AM CAT'),
          const SizedBox(height: 10),
          const _SidebarInfoRow(label: 'Location', value: 'Virtual (Link will be sent to registered bidders)'),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Register for Meeting', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarCard extends StatelessWidget {
  const _SidebarCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C0F172A), blurRadius: 18, offset: Offset(0, 12)),
        ],
      ),
      child: child,
    );
  }
}

class _SidebarInfoRow extends StatelessWidget {
  const _SidebarInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937), height: 1.4)),
      ],
    );
  }
}

class _UploadBidDocumentsCard extends StatelessWidget {
  const _UploadBidDocumentsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 14, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(Icons.cloud_upload_outlined, size: 44, color: Color(0xFF2563EB)),
          SizedBox(height: 16),
          Text(
            'Upload Your Bid Documents',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Drag & drop files here or ', style: TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                TextSpan(text: 'click to browse', style: TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Max file size: 100MB. Supported formats: PDF, DOCX, XLSX',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ContractDocumentRow extends StatelessWidget {
  const _ContractDocumentRow({required this.data});

  final _ContractDocumentData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.accentColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(data.details, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              minimumSize: const Size(0, 0),
            ),
            child: const Text('Download', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ContractDocumentData {
  const _ContractDocumentData({required this.title, required this.details, required this.accentColor, required this.icon});

  final String title;
  final String details;
  final Color accentColor;
  final IconData icon;
}

class _BidderInfoRow extends StatelessWidget {
  const _BidderInfoRow({required this.data});

  final _BidderInfoData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${data.title}:', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 8),
        Text(data.description, style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF4B5563))),
      ],
    );
  }
}

class _BidderInfoData {
  const _BidderInfoData({required this.title, required this.description});

  final String title;
  final String description;
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF4B5563)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractMetricData {
  const _ContractMetricData({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color accentColor;
}

class _ContractRecord {
  const _ContractRecord({
    required this.name,
    required this.code,
    required this.owner,
    required this.value,
    required this.status,
    required this.statusColor,
    required this.effectiveDate,
    required this.renewalDate,
    required this.lastUpdated,
    required this.highlights,
  });

  final String name;
  final String code;
  final String owner;
  final String value;
  final String status;
  final Color statusColor;
  final String effectiveDate;
  final String renewalDate;
  final String lastUpdated;
  final List<String> highlights;
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
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

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFF0987FF) : Colors.transparent, width: 1.4),
            boxShadow: isSelected
                ? const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineStepData {
  const _TimelineStepData({
    required this.number,
    required this.title,
    required this.description,
    required this.estimate,
    required this.status,
  });

  final int number;
  final String title;
  final String description;
  final String estimate;
  final _TimelineStatus status;
}

enum _TimelineStatus { current, upcoming }
