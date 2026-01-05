import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/screens/execution_plan_interface_management_overview_screen.dart';
import 'package:ndu_project/widgets/ai_suggesting_textfield.dart';
import 'package:ndu_project/widgets/ai_diagram_panel.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

class ExecutionPlanScreen extends StatefulWidget {
  const ExecutionPlanScreen({super.key});

  @override
  State<ExecutionPlanScreen> createState() => _ExecutionPlanScreenState();
}

class _ExecutionPlanScreenState extends State<ExecutionPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final pid = provider?.projectData.projectId;
      if (pid != null && pid.isNotEmpty) {
        // Save this page as the last visited page for the project
        await ProjectNavigationService.instance.saveLastPage(pid, 'execution_plan');
      }
    });
  }

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionPlanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Executive Plan Outline'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(),
                    const SizedBox(height: 28),
                    _ExecutionPlanForm(
                      hintText: 'Describe the sequential, and overall, thought process for executing the project',
                      noteKey: 'execution_plan_outline',
                    ),
                    const SizedBox(height: 48),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.end,
                        children: [
                          const _InfoBadge(),
                          const _AiTipCard(),
                          _YellowActionButton(
                            label: 'Next',
                            onPressed: () => ExecutionPlanSolutionsScreen.open(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExecutionPlanHeader extends StatelessWidget {
  const _ExecutionPlanHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
              const SizedBox(width: 12),
              _CircleIconButton(icon: Icons.arrow_forward_ios_rounded),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Execution Plan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const _CurrentUserProfileChip(),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            children: [
              _GhostActionButton(
                icon: Icons.file_download_outlined,
                label: 'Import',
                onPressed: () {},
              ),
              _GhostActionButton(
                icon: Icons.description_outlined,
                label: 'Content',
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _CurrentUserProfileChip extends StatelessWidget {
  const _CurrentUserProfileChip();

  String _initials(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r"\s+"));
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return trimmed.substring(0, 1).toUpperCase();
  }

  String _roleFor(User? user) {
    if (user == null) return 'Guest';
    final email = user.email?.toLowerCase() ?? '';
    // Basic role mapping; can be enhanced to read Firestore role if available
    if (email.endsWith('@nduproject.com')) return 'Owner';
    return 'Member';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final role = _roleFor(user);
    final photoUrl = user?.photoURL;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE5E7EB),
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(
                    _initials(displayName),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              Text(
                role,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GhostActionButton extends StatelessWidget {
  const _GhostActionButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: const Color(0xFF111827)),
      label: Text(
        label,
        style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        foregroundColor: const Color(0xFF111827),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({this.title = 'Executive Plan Outline'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Outline the strategy and actions for the implementation phase.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _ExecutionPlanForm extends StatefulWidget {
  const _ExecutionPlanForm({
    this.title = 'Executive Plan Outline',
    required this.hintText,
    this.showFieldLabel = true,
    this.noteKey,
  });

  final String title;
  final String hintText;
  final bool showFieldLabel;
  final String? noteKey;

  @override
  State<_ExecutionPlanForm> createState() => _ExecutionPlanFormState();
}

class _ExecutionPlanFormState extends State<_ExecutionPlanForm> {
  String _currentText = '';
  Timer? _saveDebounce;
  DateTime? _lastSavedAt;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _currentText = value;
    final noteKey = widget.noteKey;
    if (noteKey == null || noteKey.trim().isEmpty) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () async {
      final trimmed = value.trim();
      final success = await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'planning_$noteKey',
        dataUpdater: (data) => data.copyWith(
          planningNotes: {
            ...data.planningNotes,
            noteKey: trimmed,
          },
        ),
        showSnackbar: false,
      );
      if (mounted && success) {
        setState(() => _lastSavedAt = DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final noteKey = widget.noteKey;
    if (noteKey != null && _currentText.isEmpty) {
      final saved = ProjectDataHelper.getData(context).planningNotes[noteKey] ?? '';
      if (saved.trim().isNotEmpty) {
        _currentText = saved;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AiSuggestingTextField(
          fieldLabel: widget.title,
          hintText: widget.hintText,
          sectionLabel: 'Execution Plan',
          showLabel: widget.showFieldLabel,
          initialText: noteKey == null ? null : ProjectDataHelper.getData(context).planningNotes[noteKey],
          autoGenerate: true,
          autoGenerateSection: widget.title,
          onChanged: _handleChanged,
        ),
        if (_lastSavedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Saved ${TimeOfDay.fromDateTime(_lastSavedAt!).format(context)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        AiDiagramPanel(
          sectionLabel: widget.title,
          currentTextProvider: () => _currentText,
          title: 'Generate ${widget.title} Diagram',
        ),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFDAE9FF),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
    );
  }
}

class _AiTipCard extends StatelessWidget {
  const _AiTipCard({this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE1EEFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AiBadge(),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              text ?? 'Focus on major risks associated with each potential solution.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.auto_awesome, size: 16, color: Color(0xFFF59E0B)),
          SizedBox(width: 6),
          Text(
            'AI',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}

class _YellowActionButton extends StatelessWidget {
  const _YellowActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class ExecutionPlanSolutionsScreen extends StatelessWidget {
  const ExecutionPlanSolutionsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionPlanSolutionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Executive Plan Strategy'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 24),
                    const _TeamSummaryCard(),
                    const SizedBox(height: 28),
                    const _SectionIntro(title: 'Executive Plan Strategy'),
                    const SizedBox(height: 28),
                    _ExecutionPlanForm(
                      title: 'Executive Plan Strategy',
                      hintText: 'Input your notes here...',
                      noteKey: 'execution_plan_strategy',
                    ),
                    const SizedBox(height: 28),
                    const _ExecutionPlanTable(),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _AddSolutionButton(onPressed: () {}),
                    ),
                    const SizedBox(height: 44),
                    Wrap(
                      spacing: 20,
                      runSpacing: 16,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const _InfoBadge(),
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.end,
                          children: [
                            const _AiTipCard(),
                            _YellowActionButton(
                              label: 'Next',
                              onPressed: () => ExecutionPlanDetailsScreen.open(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamSummaryCard extends StatelessWidget {
  const _TeamSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_rounded, color: Color(0xFF4B5563)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'StackOne',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '12 Members',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExecutionPlanTable extends StatelessWidget {
  const _ExecutionPlanTable();

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF111827),
    );
    const cellStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF4B5563),
      height: 1.5,
    );

    Widget buildCell(String text, {bool isHeader = false, TextAlign align = TextAlign.left}) {
      return Container(
        color: isHeader ? const Color(0xFFF3F4F6) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Text(
          text,
          textAlign: align,
          style: isHeader ? headerStyle : cellStyle,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(70),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(3),
          3: FlexColumnWidth(2),
          4: FlexColumnWidth(2),
        },
        border: const TableBorder(
          horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
          verticalInside: BorderSide(color: Color(0xFFE5E7EB)),
          top: BorderSide(color: Color(0xFFE5E7EB)),
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
          left: BorderSide(color: Color(0xFFE5E7EB)),
          right: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        children: [
          TableRow(
            children: [
              buildCell('No', isHeader: true, align: TextAlign.center),
              buildCell('Execution Tool', isHeader: true),
              buildCell('Description', isHeader: true),
              buildCell('Source', isHeader: true),
              buildCell('Comments', isHeader: true),
            ],
          ),
          TableRow(
            children: [
              buildCell('1', align: TextAlign.center),
              buildCell('Lorem ipsum'),
              buildCell('Lorem ipsum Lorem ipsum  Lorem ipsum Lorem ipsum  Lorem ipsum Lorem ipsum'),
              buildCell('Lorem ipsum Lorem ipsum'),
              buildCell('Lorem ipsum Lorem ipsum  Lorem ipsum Lorem ipsum'),
            ],
          ),
          TableRow(
            children: [
              buildCell('2', align: TextAlign.center),
              buildCell('Lorem ipsum'),
              buildCell('Lorem ipsum Lorem ipsum  Lorem ipsum Lorem ipsum  Lorem ipsum Lorem ipsum'),
              buildCell('Lorem ipsum Lorem ipsum'),
              buildCell('Lorem ipsum Lorem ipsum  Lorem ipsum Lorem ipsum'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddSolutionButton extends StatelessWidget {
  const _AddSolutionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, color: Color(0xFF111827)),
      label: const Text(
        'Add Solution',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class ExecutionPlanDetailsScreen extends StatelessWidget {
  const ExecutionPlanDetailsScreen({
    super.key,
    this.activeItemLabel = 'Execution Plan Details',
    this.showPlanDetails = true,
    this.showEarlyWorks = false,
  });

  final String activeItemLabel;
  final bool showPlanDetails;
  final bool showEarlyWorks;

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ExecutionPlanDetailsScreen(
          activeItemLabel: 'Execution Plan Details',
          showPlanDetails: true,
          showEarlyWorks: false,
        ),
      ),
    );
  }

  static void openEarlyWorks(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ExecutionPlanDetailsScreen(
          activeItemLabel: 'Execution Early Works',
          showPlanDetails: false,
          showEarlyWorks: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: InitiationLikeSidebar(activeItemLabel: activeItemLabel),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    if (showPlanDetails) ...[
                      const _SectionIntro(title: 'Execution Plan Details'),
                      const SizedBox(height: 28),
                      _ExecutionPlanForm(
                        title: 'Execution Plan Details',
                        hintText: 'Input your notes here...',
                        noteKey: 'execution_plan_details',
                      ),
                      const SizedBox(height: 40),
                    ],
                    if (showPlanDetails && !showEarlyWorks) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.end,
                          children: [
                            const _InfoBadge(),
                            const _AiTipCard(),
                            _YellowActionButton(
                              label: 'Next',
                              onPressed: () => ExecutionPlanDetailsScreen.openEarlyWorks(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 56),
                    ],
                    if (showEarlyWorks) ...[
                      const _SectionIntro(title: 'Execution Early Works'),
                      const SizedBox(height: 24),
                      const _ExecutionPlanForm(
                        title: 'Execution Early Works',
                        hintText: 'Outline early works scope, sequencing, and handoffs.',
                        noteKey: 'execution_early_works',
                      ),
                      const SizedBox(height: 32),
                      const _EarlyWorksSection(),
                      const SizedBox(height: 56),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarlyWorksSection extends StatelessWidget {
  const _EarlyWorksSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Early Works',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        const _EarlyWorksTable(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: _AddSolutionButton(onPressed: () {}),
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileEarlyWorksActions()
        else
          const _DesktopEarlyWorksActions(),
      ],
    );
  }
}

class _EarlyWorksTable extends StatelessWidget {
  const _EarlyWorksTable();

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF111827),
    );
    const cellStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF4B5563),
      height: 1.5,
    );

    Widget buildCell(String text, {bool isHeader = false, TextAlign align = TextAlign.left}) {
      return Container(
        color: isHeader ? const Color(0xFFF3F4F6) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Text(
          text,
          textAlign: align,
          style: isHeader ? headerStyle : cellStyle,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(70),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(3),
          3: FlexColumnWidth(2),
          4: FlexColumnWidth(2),
        },
        border: const TableBorder(
          horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
          verticalInside: BorderSide(color: Color(0xFFE5E7EB)),
          top: BorderSide(color: Color(0xFFE5E7EB)),
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
          left: BorderSide(color: Color(0xFFE5E7EB)),
          right: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        children: [
          TableRow(
            children: [
              buildCell('No', isHeader: true, align: TextAlign.center),
              buildCell('Execution Tool', isHeader: true),
              buildCell('Description', isHeader: true),
              buildCell('Cost', isHeader: true),
              buildCell('Comments', isHeader: true),
            ],
          ),
          TableRow(
            children: [
              buildCell('1', align: TextAlign.center),
              buildCell('Lorem ipsum Lorem ipsum  Lore'),
              buildCell('Lorem ipsum Lorem ipsum   Lorem ipsum Lorem ipsum  Lorem ipsum Lorem ipsum'),
              buildCell('Lorem ipsum Lorem ipsum  Lorem'),
              buildCell('Lorem ipsum Lorem ipsum  Lorem ipsum Lorem ipsum'),
            ],
          ),
          TableRow(
            children: [
              buildCell('2', align: TextAlign.center),
              buildCell('Lorem ipsum Lorem ipsum  Lore'),
              buildCell('Lorem ipsum Lorem ipsum   Lorem ipsum Lorem ipsum  Lorem ipsum Lorem ipsum'),
              buildCell('Lorem ipsum Lorem ipsum  Lorem'),
              buildCell('Lorem ipsum Lorem ipsum  Lorem ipsum Lorem ipsum'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopEarlyWorksActions extends StatelessWidget {
  const _DesktopEarlyWorksActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionEnablingWorkPlanScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileEarlyWorksActions extends StatelessWidget {
  const _MobileEarlyWorksActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionEnablingWorkPlanScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionEnablingWorkPlanScreen extends StatelessWidget {
  const ExecutionEnablingWorkPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionEnablingWorkPlanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Execution Enabling Work Plan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Enabling Work Plan'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Enabling Work Plan',
                      hintText: 'Capture enabling works, dependencies, and resourcing needs.',
                      noteKey: 'execution_enabling_work_plan',
                    ),
                    const SizedBox(height: 32),
                    const _EnablingWorksPlanSection(),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnablingWorksPlanSection extends StatelessWidget {
  const _EnablingWorksPlanSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enabling Works Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        const _EnablingWorksPlanTable(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: _AddRowButton(onPressed: () {}),
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileEnablingWorksActions()
        else
          const _DesktopEnablingWorksActions(),
      ],
    );
  }
}

class _EnablingWorksPlanTable extends StatelessWidget {
  const _EnablingWorksPlanTable();

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF111827),
    );
    const cellStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF4B5563),
      height: 1.5,
    );

    Widget buildCell(String text, {bool isHeader = false, TextAlign align = TextAlign.left}) {
      return Container(
        color: isHeader ? const Color(0xFFF3F4F6) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Text(
          text,
          textAlign: align,
          style: isHeader ? headerStyle : cellStyle,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(70),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2.5),
          3: FlexColumnWidth(2),
          4: FlexColumnWidth(2),
          5: FlexColumnWidth(2),
        },
        border: const TableBorder(
          horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
          verticalInside: BorderSide(color: Color(0xFFE5E7EB)),
          top: BorderSide(color: Color(0xFFE5E7EB)),
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
          left: BorderSide(color: Color(0xFFE5E7EB)),
          right: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        children: [
          TableRow(
            children: [
              buildCell('No', isHeader: true, align: TextAlign.center),
              buildCell('Enabling work Aspect', isHeader: true),
              buildCell('Description', isHeader: true),
              buildCell('Duration', isHeader: true),
              buildCell('Cost', isHeader: true),
              buildCell('Comments', isHeader: true),
            ],
          ),
          TableRow(
            children: [
              buildCell('1', align: TextAlign.center),
              buildCell('Lorem ipsum Lorem ipsum  Lore'),
              buildCell('Lorem ipsum Lorem ipsum   Lorem ipsum Lorem ipsum'),
              buildCell('Lorem ipsum Lorem ipsum  Lore'),
              buildCell('Lorem ipsum Lore ipsum   Lorem ipsum'),
              buildCell('Lorem ipsum Lore ipsum   Lorem ipsum'),
            ],
          ),
          TableRow(
            children: [
              buildCell('2', align: TextAlign.center),
              buildCell('Lorem ipsum Lorem ipsum  Lore'),
              buildCell('Lorem ipsum Lorem ipsum   Lorem ipsum Lorem ipsum'),
              buildCell('Lorem ipsum Lorem ipsum  Lore'),
              buildCell('Lorem ipsum Lore ipsum   Lorem ipsum'),
              buildCell('Lorem ipsum Lore ipsum   Lorem ipsum'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddRowButton extends StatelessWidget {
  const _AddRowButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, color: Color(0xFF111827)),
      label: const Text(
        'Add Row',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _DesktopEnablingWorksActions extends StatelessWidget {
  const _DesktopEnablingWorksActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionIssueManagementScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileEnablingWorksActions extends StatelessWidget {
  const _MobileEnablingWorksActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionIssueManagementScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionIssueManagementScreen extends StatelessWidget {
  const ExecutionIssueManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionIssueManagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Execution Issue Management'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Issue Management'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Issue Management',
                      hintText: 'Summarize issue tracking, escalation paths, and mitigation cadence.',
                      noteKey: 'execution_issue_management',
                    ),
                    const SizedBox(height: 32),
                    const _IssuesManagementSection(),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssuesManagementSection extends StatelessWidget {
  const _IssuesManagementSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Issues Management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        const _IssuesManagementTable(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: _AddRowButton(onPressed: () {}),
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileIssueManagementActions()
        else
          const _DesktopIssueManagementActions(),
      ],
    );
  }
}

class _IssuesManagementTable extends StatelessWidget {
  const _IssuesManagementTable();

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF111827),
    );
    const cellStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF4B5563),
      height: 1.5,
    );

    Widget buildCell(String text, {bool isHeader = false, TextAlign align = TextAlign.left}) {
      return Container(
        color: isHeader ? const Color(0xFFF3F4F6) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Text(
          text,
          textAlign: align,
          style: isHeader ? headerStyle : cellStyle,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(70),
            1: FixedColumnWidth(140),
            2: FixedColumnWidth(160),
            3: FixedColumnWidth(130),
            4: FixedColumnWidth(130),
            5: FixedColumnWidth(130),
            6: FixedColumnWidth(130),
            7: FixedColumnWidth(130),
            8: FixedColumnWidth(150),
          },
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
            verticalInside: BorderSide(color: Color(0xFFE5E7EB)),
            top: BorderSide(color: Color(0xFFE5E7EB)),
            bottom: BorderSide(color: Color(0xFFE5E7EB)),
            left: BorderSide(color: Color(0xFFE5E7EB)),
            right: BorderSide(color: Color(0xFFE5E7EB)),
          ),
          children: [
            TableRow(
              children: [
                buildCell('No', isHeader: true, align: TextAlign.center),
                buildCell('Issue Topic', isHeader: true),
                buildCell('Description', isHeader: true),
                buildCell('Discipline', isHeader: true),
                buildCell('Raised by', isHeader: true),
                buildCell('Schedule In', isHeader: true),
                buildCell('Cost Impact', isHeader: true),
                buildCell('Approved?', isHeader: true),
                buildCell('Comments', isHeader: true),
              ],
            ),
            TableRow(
              children: [
                buildCell('1', align: TextAlign.center),
                buildCell('Lorem ipsum\nLorem ipsum'),
                buildCell('Lorem ipsum\nLorem ipsum'),
                buildCell('Lorem ipsum\nLorem ipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
              ],
            ),
            TableRow(
              children: [
                buildCell('1', align: TextAlign.center),
                buildCell('Lorem ipsum\nLorem ipsum'),
                buildCell('Lorem ipsum\nLorem ipsum'),
                buildCell('Lorem ipsum\nLorem ipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopIssueManagementActions extends StatelessWidget {
  const _DesktopIssueManagementActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text: 'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanLessonsLearnedScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileIssueManagementActions extends StatelessWidget {
  const _MobileIssueManagementActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanLessonsLearnedScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanLessonsLearnedScreen extends StatelessWidget {
  const ExecutionPlanLessonsLearnedScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionPlanLessonsLearnedScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Execution Plan - Lesson Learned'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Plan - Lesson Learned'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Lesson Learned',
                      hintText: 'Capture lessons learned and how they influence execution.',
                      noteKey: 'execution_lessons_learned',
                    ),
                    const SizedBox(height: 32),
                    const _LessonsLearnedSection(),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonsLearnedSection extends StatelessWidget {
  const _LessonsLearnedSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lessons Learned',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        const _LessonsLearnedTable(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: _AddRowButton(onPressed: () {}),
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileLessonsLearnedActions()
        else
          const _DesktopLessonsLearnedActions(),
      ],
    );
  }
}

class _LessonsLearnedTable extends StatelessWidget {
  const _LessonsLearnedTable();

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF111827),
    );
    const cellStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF4B5563),
      height: 1.5,
    );

    Widget buildCell(String text, {bool isHeader = false, TextAlign align = TextAlign.left}) {
      return Container(
        color: isHeader ? const Color(0xFFF3F4F6) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Text(
          text,
          textAlign: align,
          style: isHeader ? headerStyle : cellStyle,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(70),
            1: FixedColumnWidth(130),
            2: FixedColumnWidth(120),
            3: FixedColumnWidth(130),
            4: FixedColumnWidth(130),
            5: FixedColumnWidth(130),
            6: FixedColumnWidth(130),
            7: FixedColumnWidth(130),
            8: FixedColumnWidth(130),
            9: FixedColumnWidth(150),
          },
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
            verticalInside: BorderSide(color: Color(0xFFE5E7EB)),
            top: BorderSide(color: Color(0xFFE5E7EB)),
            bottom: BorderSide(color: Color(0xFFE5E7EB)),
            left: BorderSide(color: Color(0xFFE5E7EB)),
            right: BorderSide(color: Color(0xFFE5E7EB)),
          ),
          children: [
            TableRow(
              children: [
                buildCell('No', isHeader: true, align: TextAlign.center),
                buildCell('Topic', isHeader: true),
                buildCell('LL or BP?', isHeader: true),
                buildCell('Discipline', isHeader: true),
                buildCell('Impacted', isHeader: true),
                buildCell('Raised by', isHeader: true),
                buildCell('Schedule', isHeader: true),
                buildCell('Cost Impact', isHeader: true),
                buildCell('Approved?', isHeader: true),
                buildCell('Comments', isHeader: true),
              ],
            ),
            TableRow(
              children: [
                buildCell('1', align: TextAlign.center),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
              ],
            ),
            TableRow(
              children: [
                buildCell('2', align: TextAlign.center),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
              ],
            ),
            TableRow(
              children: [
                buildCell('3', align: TextAlign.center),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopLessonsLearnedActions extends StatelessWidget {
  const _DesktopLessonsLearnedActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text: 'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanBestPracticesScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileLessonsLearnedActions extends StatelessWidget {
  const _MobileLessonsLearnedActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanBestPracticesScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanBestPracticesScreen extends StatelessWidget {
  const ExecutionPlanBestPracticesScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionPlanBestPracticesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Execution Plan - Best Practices'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Plan - Best Practices'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Best Practices',
                      hintText: 'Document the best practices to follow during execution.',
                      noteKey: 'execution_best_practices',
                    ),
                    const SizedBox(height: 32),
                    const _BestPracticesSection(),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BestPracticesSection extends StatelessWidget {
  const _BestPracticesSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Best Practices',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        const _BestPracticesTable(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: _AddRowButton(onPressed: () {}),
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileBestPracticesActions()
        else
          const _DesktopBestPracticesActions(),
      ],
    );
  }
}

class _BestPracticesTable extends StatelessWidget {
  const _BestPracticesTable();

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF111827),
    );
    const cellStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF4B5563),
      height: 1.5,
    );

    Widget buildCell(String text, {bool isHeader = false, TextAlign align = TextAlign.left}) {
      return Container(
        color: isHeader ? const Color(0xFFF3F4F6) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Text(
          text,
          textAlign: align,
          style: isHeader ? headerStyle : cellStyle,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(70),
            1: FixedColumnWidth(130),
            2: FixedColumnWidth(120),
            3: FixedColumnWidth(130),
            4: FixedColumnWidth(130),
            5: FixedColumnWidth(130),
            6: FixedColumnWidth(130),
            7: FixedColumnWidth(130),
            8: FixedColumnWidth(130),
            9: FixedColumnWidth(150),
          },
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
            verticalInside: BorderSide(color: Color(0xFFE5E7EB)),
            top: BorderSide(color: Color(0xFFE5E7EB)),
            bottom: BorderSide(color: Color(0xFFE5E7EB)),
            left: BorderSide(color: Color(0xFFE5E7EB)),
            right: BorderSide(color: Color(0xFFE5E7EB)),
          ),
          children: [
            TableRow(
              children: [
                buildCell('No', isHeader: true, align: TextAlign.center),
                buildCell('Topic', isHeader: true),
                buildCell('LL or BP?', isHeader: true),
                buildCell('Discipline', isHeader: true),
                buildCell('Impacted', isHeader: true),
                buildCell('Raised by', isHeader: true),
                buildCell('Schedule', isHeader: true),
                buildCell('Cost Impact', isHeader: true),
                buildCell('Approved?', isHeader: true),
                buildCell('Comments', isHeader: true),
              ],
            ),
            TableRow(
              children: [
                buildCell('1', align: TextAlign.center),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
              ],
            ),
            TableRow(
              children: [
                buildCell('2', align: TextAlign.center),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
              ],
            ),
            TableRow(
              children: [
                buildCell('3', align: TextAlign.center),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
                buildCell('Lorem\nipsum'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopBestPracticesActions extends StatelessWidget {
  const _DesktopBestPracticesActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text: 'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanConstructionPlanScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileBestPracticesActions extends StatelessWidget {
  const _MobileBestPracticesActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanConstructionPlanScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanConstructionPlanScreen extends StatelessWidget {
  const ExecutionPlanConstructionPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionPlanConstructionPlanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Execution Plan - Construction Plan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Plan - Construction Plan'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Construction Plan',
                      hintText: 'Summarize construction sequencing, logistics, and safety constraints.',
                      noteKey: 'execution_construction_plan',
                    ),
                    const SizedBox(height: 32),
                    const _ConstructionPlanSection(),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstructionPlanSection extends StatelessWidget {
  const _ConstructionPlanSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Construction Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        const _ConstructionPlanCard(),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileConstructionPlanActions()
        else
          const _DesktopConstructionPlanActions(),
      ],
    );
  }
}

class _ConstructionPlanCard extends StatelessWidget {
  const _ConstructionPlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      decoration: BoxDecoration(
        color: const Color(0xFFBBBBBB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            'Will construction work be done by this project?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _ConstructionOptionButton(
                label: 'YES',
                color: const Color(0xFF22C55E),
                onPressed: () {},
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ConstructionOptionButton(
                    label: 'NO',
                    color: const Color(0xFFF59E0B),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No, but managed externally',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              _ConstructionOptionButton(
                label: 'NO',
                color: const Color(0xFFEF4444),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConstructionOptionButton extends StatelessWidget {
  const _ConstructionOptionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DesktopConstructionPlanActions extends StatelessWidget {
  const _DesktopConstructionPlanActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text: 'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInfrastructurePlanScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileConstructionPlanActions extends StatelessWidget {
  const _MobileConstructionPlanActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInfrastructurePlanScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanInfrastructurePlanScreen extends StatelessWidget {
  const ExecutionPlanInfrastructurePlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionPlanInfrastructurePlanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Execution Plan - Infrastructure Plan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Plan - Infrastructure Plan'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Infrastructure Plan',
                      hintText: 'Outline infrastructure dependencies, scope, and delivery approach.',
                      noteKey: 'execution_infrastructure_plan',
                    ),
                    const SizedBox(height: 32),
                    const _InfrastructurePlanSection(),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfrastructurePlanSection extends StatelessWidget {
  const _InfrastructurePlanSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Infrastructure Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        const _InfrastructurePlanCard(),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileInfrastructurePlanActions()
        else
          const _DesktopInfrastructurePlanActions(),
      ],
    );
  }
}

class _InfrastructurePlanCard extends StatelessWidget {
  const _InfrastructurePlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      decoration: BoxDecoration(
        color: const Color(0xFFBBBBBB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            'Will Infrastructure work be done by this project?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _ConstructionOptionButton(
                label: 'YES',
                color: const Color(0xFF22C55E),
                onPressed: () {},
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ConstructionOptionButton(
                    label: 'NO',
                    color: const Color(0xFFF59E0B),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No, but managed externally',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              _ConstructionOptionButton(
                label: 'NO',
                color: const Color(0xFFEF4444),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopInfrastructurePlanActions extends StatelessWidget {
  const _DesktopInfrastructurePlanActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text: 'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanStakeholderIdentificationScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileInfrastructurePlanActions extends StatelessWidget {
  const _MobileInfrastructurePlanActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanStakeholderIdentificationScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanAgileDeliveryPlanScreen extends StatelessWidget {
  const ExecutionPlanAgileDeliveryPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionPlanAgileDeliveryPlanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Execution Plan - Agile Delivery Plan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Plan - Agile Delivery Plan'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Agile Delivery Plan',
                      hintText: 'Outline sprint cadence, release waves, and backlog governance.',
                      noteKey: 'execution_agile_delivery_plan',
                    ),
                    const SizedBox(height: 32),
                    const _AgileDeliveryPlanSection(),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgileDeliveryPlanSection extends StatelessWidget {
  const _AgileDeliveryPlanSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agile Delivery Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            _AgileDeliveryMetricCard(title: 'Cadence', value: '2-week sprints'),
            _AgileDeliveryMetricCard(title: 'Release Waves', value: '4 major drops'),
            _AgileDeliveryMetricCard(title: 'Backlog Health', value: '78% ready'),
            _AgileDeliveryMetricCard(title: 'Sprint Goals', value: '12 mapped'),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Guardrails',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 12),
              const _AgileDeliveryBullet(text: 'Definition of Done enforced across all squads.'),
              const _AgileDeliveryBullet(text: 'Release criteria reviewed in weekly governance.'),
              const _AgileDeliveryBullet(text: 'Scope change requests prioritized in backlog grooming.'),
              const _AgileDeliveryBullet(text: 'Velocity trends monitored to protect milestones.'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: isMobile ? Alignment.centerLeft : Alignment.centerRight,
          child: const _InfoBadge(),
        ),
      ],
    );
  }
}

class _AgileDeliveryMetricCard extends StatelessWidget {
  const _AgileDeliveryMetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }
}

class _AgileDeliveryBullet extends StatelessWidget {
  const _AgileDeliveryBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class ExecutionPlanStakeholderIdentificationScreen extends StatelessWidget {
  const ExecutionPlanStakeholderIdentificationScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionPlanStakeholderIdentificationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Execution Plan - Stakeholder Identification'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Plan - Stakeholder Identification'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Stakeholder Identification',
                      hintText: 'Capture stakeholder groups, engagement strategies, and key concerns.',
                      noteKey: 'execution_stakeholder_identification',
                    ),
                    const SizedBox(height: 32),
                    const _StakeholderIdentificationSection(),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StakeholderIdentificationSection extends StatefulWidget {
  const _StakeholderIdentificationSection();

  @override
  State<_StakeholderIdentificationSection> createState() => _StakeholderIdentificationSectionState();
}

class _StakeholderIdentificationSectionState extends State<_StakeholderIdentificationSection> {
  final List<Map<String, String>> _rows = [];

  void _addRow() {
    setState(() {
      _rows.add({
        'stakeholderGroup': '',
        'category': '',
        'influence': '',
        'keyConcerns': '',
        'engagementStrategy': '',
        'comments': '',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stakeholder Identification',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        _StakeholderIdentificationTable(rows: _rows),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: _AddRowButton(onPressed: _addRow),
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileStakeholderIdentificationActions()
        else
          const _DesktopStakeholderIdentificationActions(),
      ],
    );
  }
}

class _StakeholderIdentificationTable extends StatelessWidget {
  const _StakeholderIdentificationTable({required this.rows});

  final List<Map<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF111827),
    );
    const cellStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF4B5563),
      height: 1.5,
    );

    Widget buildCell(String text, {bool isHeader = false, TextAlign align = TextAlign.left}) {
      return Container(
        color: isHeader ? const Color(0xFFF3F4F6) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Text(
          text,
          textAlign: align,
          style: isHeader ? headerStyle : cellStyle,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(70),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2),
          4: FlexColumnWidth(2),
          5: FlexColumnWidth(2),
          6: FlexColumnWidth(2),
        },
        border: const TableBorder(
          horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
          verticalInside: BorderSide(color: Color(0xFFE5E7EB)),
          top: BorderSide(color: Color(0xFFE5E7EB)),
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
          left: BorderSide(color: Color(0xFFE5E7EB)),
          right: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        children: [
          TableRow(
            children: [
              buildCell('No', isHeader: true, align: TextAlign.center),
              buildCell('Stakeholder Group', isHeader: true),
              buildCell('Category', isHeader: true),
              buildCell('Influence', isHeader: true),
              buildCell('Key Concerns', isHeader: true),
              buildCell('Engagement Strategy', isHeader: true),
              buildCell('Comments', isHeader: true),
            ],
          ),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return TableRow(
              children: [
                buildCell('${index + 1}', align: TextAlign.center),
                buildCell(row['stakeholderGroup'] ?? ''),
                buildCell(row['category'] ?? ''),
                buildCell(row['influence'] ?? ''),
                buildCell(row['keyConcerns'] ?? ''),
                buildCell(row['engagementStrategy'] ?? ''),
                buildCell(row['comments'] ?? ''),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DesktopStakeholderIdentificationActions extends StatelessWidget {
  const _DesktopStakeholderIdentificationActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text: 'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInterfaceManagementScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileStakeholderIdentificationActions extends StatelessWidget {
  const _MobileStakeholderIdentificationActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInterfaceManagementScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanInterfaceManagementScreen extends StatelessWidget {
  const ExecutionPlanInterfaceManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionPlanInterfaceManagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Execution Plan - Interface Management'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Plan - Interface Management'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Interface Management',
                      hintText: 'Summarize interface dependencies, coordination protocols, and governance.',
                      noteKey: 'execution_interface_management',
                    ),
                    const SizedBox(height: 32),
                    const _InterfaceManagementSection(),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterfaceManagementSection extends StatelessWidget {
  const _InterfaceManagementSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interface management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 200),
        if (isMobile)
          _MobileInterfaceManagementActions()
        else
          const _DesktopInterfaceManagementActions(),
      ],
    );
  }
}

class _DesktopInterfaceManagementActions extends StatelessWidget {
  const _DesktopInterfaceManagementActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text: 'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanCommunicationPlanScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileInterfaceManagementActions extends StatelessWidget {
  const _MobileInterfaceManagementActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanCommunicationPlanScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanCommunicationPlanScreen extends StatelessWidget {
  const ExecutionPlanCommunicationPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionPlanCommunicationPlanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Execution Plan - Communication Plan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Plan - Communication Plan'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Communication Plan',
                      hintText: 'Outline communication cadence, channels, and stakeholder updates.',
                      noteKey: 'execution_communication_plan',
                    ),
                    const SizedBox(height: 32),
                    const _CommunicationPlanSection(),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunicationPlanSection extends StatelessWidget {
  const _CommunicationPlanSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Communication Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 200),
        if (isMobile)
          _MobileCommunicationPlanActions()
        else
          const _DesktopCommunicationPlanActions(),
      ],
    );
  }
}

class _DesktopCommunicationPlanActions extends StatelessWidget {
  const _DesktopCommunicationPlanActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text: 'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInterfaceManagementPlanScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileCommunicationPlanActions extends StatelessWidget {
  const _MobileCommunicationPlanActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInterfaceManagementPlanScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanInterfaceManagementPlanScreen extends StatelessWidget {
  const ExecutionPlanInterfaceManagementPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionPlanInterfaceManagementPlanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Execution Plan - Interface Management Plan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Plan - Interface Management Plan'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Interface Management Plan',
                      hintText: 'Summarize interface management plan objectives and control points.',
                      noteKey: 'execution_interface_management_plan',
                    ),
                    const SizedBox(height: 32),
                    const _InterfaceManagementPlanForm(),
                    const SizedBox(height: 48),
                    const _InterfaceManagementPlanSection(),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterfaceManagementPlanForm extends StatelessWidget {
  const _InterfaceManagementPlanForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interface Management Plan Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Text(
            'Stakeholder identification process systematically identifies all parties who may be affected by or can influence the project, analyzing their interests, influence levels, and developing appropriate engagement strategies.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _InterfaceManagementPlanSection extends StatelessWidget {
  const _InterfaceManagementPlanSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interface Management Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 200),
        if (isMobile)
          _MobileInterfaceManagementPlanActions()
        else
          const _DesktopInterfaceManagementPlanActions(),
      ],
    );
  }
}

class _DesktopInterfaceManagementPlanActions extends StatelessWidget {
  const _DesktopInterfaceManagementPlanActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text: 'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInterfaceManagementOverviewScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileInterfaceManagementPlanActions extends StatelessWidget {
  const _MobileInterfaceManagementPlanActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInterfaceManagementOverviewScreen.open(context),
        ),
      ],
    );
  }
}
