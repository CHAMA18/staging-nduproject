import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/premium_edit_dialog.dart';

class TeamTrainingAndBuildingScreen extends StatelessWidget {
  const TeamTrainingAndBuildingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          DraggableSidebar(
            openWidth: sidebarWidth,
            child: const InitiationLikeSidebar(
                activeItemLabel: 'Team Training and Team Building'),
          ),
          Expanded(child: _buildMain(context)),
        ],
      ),
    );
  }

  Widget _buildMain(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _circleIconButton(Icons.arrow_back_ios,
                    onTap: () => Navigator.maybePop(context)),
                const SizedBox(width: 12),
                _circleIconButton(Icons.arrow_forward_ios, onTap: () async {
                  final navIndex =
                      PlanningPhaseNavigation.getPageIndex('team_training');
                  if (navIndex != -1 &&
                      navIndex < PlanningPhaseNavigation.pages.length - 1) {
                    final nextPage =
                        PlanningPhaseNavigation.pages[navIndex + 1];
                    Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: nextPage.builder));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('No next screen available')));
                  }
                }),
                const SizedBox(width: 16),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Team Training and Team Building',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827)),
                    ),
                  ),
                ),
                _profileCluster(context),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                _yellowButton(
                  label: 'Onboarding Template',
                  icon: Icons.auto_awesome,
                  onPressed: () => _addOnboardingTemplate(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.only(left: 6.0),
              child: Text(
                'Identify team training opportunities and team building intervals',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 16),
            const PlanningAiNotesCard(
              title: 'Notes',
              sectionLabel: 'Team Training and Team Building',
              noteKey: 'planning_team_training_notes',
              checkpoint: 'team_training',
              description:
                  'Outline training themes, cadence, and team-building priorities.',
            ),
            const SizedBox(height: 16),
            // Main overview card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Team Development Overview',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Identify team training opportunities and team building intervals to boost team spirit and collaboration. Could be team shares (like safety moments).',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Onboarding
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Onboarding',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(width: 12),
                                _yellowButton(
                                  label: 'Add Onboarding',
                                  icon: Icons.checklist_rtl,
                                  onPressed: () async {
                                    final newActivity = TrainingActivity(
                                        title: 'New Onboarding',
                                        category: 'Onboarding',
                                        isMandatory: true);
                                    await ProjectDataHelper.saveAndNavigate(
                                      context: context,
                                      checkpoint: 'team_training',
                                      nextScreenBuilder: () =>
                                          const TeamTrainingAndBuildingScreen(),
                                      dataUpdater: (d) => d.copyWith(
                                          trainingActivities: [
                                            ...d.trainingActivities,
                                            newActivity
                                          ]),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mandatory steps to integrate new project members.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 12),
                            _UpcomingTrainingList(
                              activities: ProjectDataHelper.getData(context)
                                  .trainingActivities
                                  .where((a) => a.category == 'Onboarding')
                                  .toList(),
                              accent: Colors.green,
                              onEdit: (activity) =>
                                  _editActivity(context, activity),
                              onDelete: (activity) =>
                                  _deleteActivity(context, activity),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Discipline-Specific
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Discipline-Specific',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(width: 12),
                                _yellowButton(
                                  label: 'Add Discipline Training',
                                  icon: Icons.school_outlined,
                                  onPressed: () async {
                                    final newActivity = TrainingActivity(
                                        title: 'New Training',
                                        category: 'Discipline-Specific');
                                    await ProjectDataHelper.saveAndNavigate(
                                      context: context,
                                      checkpoint: 'team_training',
                                      nextScreenBuilder: () =>
                                          const TeamTrainingAndBuildingScreen(),
                                      dataUpdater: (d) => d.copyWith(
                                          trainingActivities: [
                                            ...d.trainingActivities,
                                            newActivity
                                          ]),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Technical training tailored to specific roles and tasks.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 12),
                            _UpcomingTrainingList(
                              activities: ProjectDataHelper.getData(context)
                                  .trainingActivities
                                  .where((a) =>
                                      a.category == 'Discipline-Specific' ||
                                      (a.category == 'Training' &&
                                          a.category != 'Onboarding'))
                                  .toList(),
                              accent: Colors.blue,
                              onEdit: (activity) =>
                                  _editActivity(context, activity),
                              onDelete: (activity) =>
                                  _deleteActivity(context, activity),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Team Building
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Team Building',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(width: 12),
                                _yellowButton(
                                  label: 'Add Team Building',
                                  icon: Icons.favorite_outline,
                                  onPressed: () async {
                                    final newActivity = TrainingActivity(
                                        title: 'New Event',
                                        category: 'Team Building');
                                    await ProjectDataHelper.saveAndNavigate(
                                      context: context,
                                      checkpoint: 'team_training',
                                      nextScreenBuilder: () =>
                                          const TeamTrainingAndBuildingScreen(),
                                      dataUpdater: (d) => d.copyWith(
                                          trainingActivities: [
                                            ...d.trainingActivities,
                                            newActivity
                                          ]),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Strengthen relationships and improve communication.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 12),
                            _UpcomingTrainingList(
                              activities: ProjectDataHelper.getData(context)
                                  .trainingActivities
                                  .where((a) => a.category == 'Team Building')
                                  .toList(),
                              accent: Colors.purple,
                              heart: true,
                              onEdit: (activity) =>
                                  _editActivity(context, activity),
                              onDelete: (activity) =>
                                  _deleteActivity(context, activity),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Benefits row
            Row(
              children: const [
                Expanded(
                    child: _BenefitCard(
                        icon: Icons.lightbulb_outline,
                        title: 'Skill Development',
                        subtitle:
                            'Enhance technical and soft skills through structured learning')),
                SizedBox(width: 12),
                Expanded(
                    child: _BenefitCard(
                        icon: Icons.favorite_border,
                        title: 'Team Cohesion',
                        subtitle:
                            'Build stronger relationships and mutual trust')),
                SizedBox(width: 12),
                Expanded(
                    child: _BenefitCard(
                        icon: Icons.speed_outlined,
                        title: 'Improved Performance',
                        subtitle:
                            'Boost productivity and quality of deliverables')),
                SizedBox(width: 12),
                Expanded(
                    child: _BenefitCard(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Innovation',
                        subtitle:
                            'Enhance technical and soft skills through structured learning')),
              ],
            ),

            const SizedBox(height: 20),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _editActivity(BuildContext context, TrainingActivity activity) {
    final rootContext = context;
    final titleController = TextEditingController(text: activity.title);
    final dateController = TextEditingController(text: activity.date);
    final durationController = TextEditingController(text: activity.duration);
    bool isMandatory = activity.isMandatory;
    String category = activity.category;
    if (category == 'Training')
      category = 'Discipline-Specific'; // Cleanup legacy

    showDialog(
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => PremiumEditDialog(
          title: 'Edit Activity',
          icon: category == 'Onboarding'
              ? Icons.checklist_rtl
              : (category == 'Team Building'
                  ? Icons.favorite_border
                  : Icons.school_outlined),
          onSave: () async {
            final updated = List<TrainingActivity>.from(
                ProjectDataHelper.getProvider(rootContext)
                    .projectData
                    .trainingActivities);
            final index = updated.indexWhere((a) => a.id == activity.id);
            if (index != -1) {
              updated[index] = activity.copyWith(
                title: titleController.text.trim(),
                date: dateController.text.trim(),
                duration: durationController.text.trim(),
                isMandatory: isMandatory,
                category: category,
              );
            }
            Navigator.pop(dialogContext);
            await ProjectDataHelper.saveAndNavigate(
              context: rootContext,
              checkpoint: 'team_training',
              nextScreenBuilder: () => const TeamTrainingAndBuildingScreen(),
              dataUpdater: (d) => d.copyWith(trainingActivities: updated),
            );
          },
          children: [
            PremiumEditDialog.fieldLabel('Title'),
            PremiumEditDialog.textField(
                controller: titleController, hint: 'Activity name...'),
            const SizedBox(height: 16),
            PremiumEditDialog.fieldLabel('Category'),
            DropdownButtonFormField<String>(
              value: category,
              items: ['Onboarding', 'Discipline-Specific', 'Team Building']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setDialogState(() => category = v!),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Mandatory Requirement',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              value: isMandatory,
              onChanged: (v) => setDialogState(() => isMandatory = v!),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PremiumEditDialog.fieldLabel('Date'),
                      PremiumEditDialog.textField(
                          controller: dateController, hint: 'e.g. Q3 2024'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PremiumEditDialog.fieldLabel('Duration / Interval'),
                      PremiumEditDialog.textField(
                          controller: durationController, hint: 'e.g. 2 hours'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editActivity(
      BuildContext context, TrainingActivity activity) async {
    final rootContext = context;
    final titleController = TextEditingController(text: activity.title);
    final descriptionController =
        TextEditingController(text: activity.description);
    final dateController = TextEditingController(text: activity.date);
    final durationController = TextEditingController(text: activity.duration);

    bool isMandatory = activity.isMandatory;
    bool isCompleted = activity.isCompleted;
    String category = _normalizeCategory(activity.category);
    String? attachedFile = activity.attachedFile;
    String? attachedFileUrl = activity.attachedFileUrl;
    String? attachedFileStoragePath = activity.attachedFileStoragePath;
    String? selectedExistingDocUrl = attachedFileUrl;
    final manualUrlController =
        TextEditingController(text: attachedFileUrl ?? '');
    bool uploading = false;

    showDialog(
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final existingDocs = _sectionDocuments(
            rootContext,
            category: category,
            excludeActivityId: activity.id,
          );

          return PremiumEditDialog(
            title: 'Edit Activity',
            icon: category == 'Onboarding'
                ? Icons.checklist_rtl
                : category == 'Team Building'
                    ? Icons.favorite_border
                    : Icons.school_outlined,
            onSave: () async {
              final updated = List<TrainingActivity>.from(
                ProjectDataHelper.getProvider(rootContext)
                    .projectData
                    .trainingActivities,
              );
              final index = updated.indexWhere((a) => a.id == activity.id);
              final manualUrl = manualUrlController.text.trim();
              if (index != -1) {
                updated[index] = TrainingActivity(
                  id: activity.id,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  date: dateController.text.trim(),
                  duration: durationController.text.trim(),
                  category: _normalizeCategory(category),
                  status: activity.status,
                  isMandatory: isMandatory,
                  attachedFile: attachedFile ??
                      (manualUrl.isNotEmpty ? _baseName(manualUrl) : null),
                  attachedFileUrl:
                      manualUrl.isNotEmpty ? manualUrl : attachedFileUrl,
                  attachedFileStoragePath: attachedFileStoragePath,
                  isCompleted: isCompleted,
                );
              }
              Navigator.pop(dialogContext);
              await _saveActivities(rootContext, updated);
            },
            children: [
              PremiumEditDialog.fieldLabel('Title'),
              PremiumEditDialog.textField(
                controller: titleController,
                hint: 'Activity name...',
              ),
              const SizedBox(height: 16),
              PremiumEditDialog.fieldLabel('Template / Notes'),
              TextField(
                controller: descriptionController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText:
                      'Store onboarding/training notes, plan details, or checklist.',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _downloadTemplatePdf(
                    rootContext,
                    title: titleController.text.trim().isEmpty
                        ? 'training_template'
                        : titleController.text.trim(),
                    category: category,
                    templateText: descriptionController.text.trim(),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Download Template PDF'),
                ),
              ),
              const SizedBox(height: 16),
              PremiumEditDialog.fieldLabel('Category'),
              DropdownButtonFormField<String>(
                value: category,
                items: const [
                  DropdownMenuItem(
                      value: 'Onboarding', child: Text('Onboarding')),
                  DropdownMenuItem(
                    value: 'Discipline-Specific',
                    child: Text('Discipline-Specific'),
                  ),
                  DropdownMenuItem(
                    value: 'Team Building',
                    child: Text('Team Building'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setDialogState(() {
                    category = v;
                    selectedExistingDocUrl = null;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text(
                  'Mandatory Requirement',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                value: isMandatory,
                onChanged: (v) =>
                    setDialogState(() => isMandatory = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text(
                  'Completed / Read',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                value: isCompleted,
                onChanged: (v) =>
                    setDialogState(() => isCompleted = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              PremiumEditDialog.fieldLabel('Attachment'),
              if (attachedFile != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _baseName(attachedFile!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: Colors.blue[900], fontSize: 13),
                        ),
                      ),
                      if ((attachedFileUrl ?? '').trim().isNotEmpty)
                        IconButton(
                          tooltip: 'Download',
                          onPressed: () =>
                              _downloadAttachment(rootContext, attachedFileUrl),
                          icon: const Icon(Icons.download_outlined,
                              size: 18, color: Colors.blue),
                        ),
                      IconButton(
                        tooltip: 'Remove attachment',
                        onPressed: () => setDialogState(() {
                          attachedFile = null;
                          attachedFileUrl = null;
                          attachedFileStoragePath = null;
                          selectedExistingDocUrl = null;
                          manualUrlController.text = '';
                        }),
                        icon: const Icon(Icons.close,
                            size: 16, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: uploading
                        ? null
                        : () async {
                            setDialogState(() => uploading = true);
                            final uploaded = await _pickAndUploadAttachment(
                              rootContext,
                              folder: 'team_training',
                            );
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              uploading = false;
                              if (uploaded != null) {
                                attachedFile = uploaded.name;
                                attachedFileUrl = uploaded.url;
                                attachedFileStoragePath = uploaded.storagePath;
                                selectedExistingDocUrl = uploaded.url;
                                manualUrlController.text = uploaded.url;
                              }
                            });
                          },
                    icon: uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file, size: 16),
                    label: Text(uploading ? 'Uploading...' : 'Upload'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if ((attachedFileUrl ?? '').trim().isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () =>
                          _downloadAttachment(rootContext, attachedFileUrl),
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('Download'),
                    ),
                ],
              ),
              if (existingDocs.isNotEmpty) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedExistingDocUrl != null &&
                          existingDocs
                              .any((doc) => doc.url == selectedExistingDocUrl)
                      ? selectedExistingDocUrl
                      : null,
                  items: existingDocs
                      .map(
                        (doc) => DropdownMenuItem(
                          value: doc.url,
                          child: Text(
                            doc.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    final doc = existingDocs.firstWhere((d) => d.url == v);
                    setDialogState(() {
                      selectedExistingDocUrl = v;
                      attachedFile = doc.name;
                      attachedFileUrl = doc.url;
                      attachedFileStoragePath = doc.storagePath;
                      manualUrlController.text = doc.url;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Select Existing Document In This Section',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: manualUrlController,
                decoration: InputDecoration(
                  labelText: 'Or Paste Existing Download URL',
                  hintText:
                      'https://firebasestorage.googleapis.com/... (fallback if browser upload is blocked)',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PremiumEditDialog.fieldLabel('Date'),
                        PremiumEditDialog.textField(
                          controller: dateController,
                          hint: 'e.g. Q3 2026',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PremiumEditDialog.fieldLabel('Duration / Interval'),
                        PremiumEditDialog.textField(
                          controller: durationController,
                          hint: 'e.g. 2 hours',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showResourceDialog(
      BuildContext context, _ResourceButtonSpec spec) async {
    final rootContext = context;
    final data = ProjectDataHelper.getData(rootContext);
    final templateController =
        TextEditingController(text: _buildTemplateForButton(spec, data));
    final titleController = TextEditingController(text: '${spec.label} Plan');
    final dateController = TextEditingController();
    final durationController =
        TextEditingController(text: spec.defaultDuration);

    String category = spec.category;
    bool confirmedRead = false;
    bool mandatory = spec.mandatory;
    String? attachedFile;
    String? attachedFileUrl;
    String? attachedFileStoragePath;
    String? selectedExistingDocUrl;
    final manualUrlController = TextEditingController();
    bool uploading = false;

    showDialog(
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final existingDocs =
              _sectionDocuments(rootContext, category: category);

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(spec.label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Text(
                        spec.description,
                        style: TextStyle(color: Colors.blue[900], fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Activity Title',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: const [
                        DropdownMenuItem(
                            value: 'Onboarding', child: Text('Onboarding')),
                        DropdownMenuItem(
                          value: 'Discipline-Specific',
                          child: Text('Discipline-Specific'),
                        ),
                        DropdownMenuItem(
                          value: 'Team Building',
                          child: Text('Team Building'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setDialogState(() {
                          category = v;
                          selectedExistingDocUrl = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Link To Section',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: templateController,
                      maxLines: 14,
                      decoration: InputDecoration(
                        labelText: 'Template (Editable)',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadTemplatePdf(
                          rootContext,
                          title: titleController.text.trim().isEmpty
                              ? spec.label
                              : titleController.text.trim(),
                          category: category,
                          templateText: templateController.text.trim(),
                        ),
                        icon:
                            const Icon(Icons.picture_as_pdf_outlined, size: 16),
                        label: const Text('Download Template PDF'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Resource File',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (attachedFile != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _baseName(attachedFile!),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.blue[900], fontSize: 13),
                              ),
                            ),
                            if ((attachedFileUrl ?? '').trim().isNotEmpty)
                              IconButton(
                                tooltip: 'Download',
                                onPressed: () => _downloadAttachment(
                                    rootContext, attachedFileUrl),
                                icon: const Icon(Icons.download_outlined,
                                    size: 18, color: Colors.blue),
                              ),
                            IconButton(
                              tooltip: 'Remove',
                              onPressed: () => setDialogState(() {
                                attachedFile = null;
                                attachedFileUrl = null;
                                attachedFileStoragePath = null;
                                selectedExistingDocUrl = null;
                                manualUrlController.text = '';
                              }),
                              icon: const Icon(Icons.close,
                                  size: 16, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: uploading
                              ? null
                              : () async {
                                  setDialogState(() => uploading = true);
                                  final uploaded =
                                      await _pickAndUploadAttachment(
                                    rootContext,
                                    folder: 'team_training',
                                  );
                                  if (!dialogContext.mounted) return;
                                  setDialogState(() {
                                    uploading = false;
                                    if (uploaded != null) {
                                      attachedFile = uploaded.name;
                                      attachedFileUrl = uploaded.url;
                                      attachedFileStoragePath =
                                          uploaded.storagePath;
                                      selectedExistingDocUrl = uploaded.url;
                                      manualUrlController.text = uploaded.url;
                                    }
                                  });
                                },
                          icon: uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.upload_file, size: 16),
                          label: Text(uploading ? 'Uploading...' : 'Upload'),
                          style: ElevatedButton.styleFrom(elevation: 0),
                        ),
                        const SizedBox(width: 8),
                        if ((attachedFileUrl ?? '').trim().isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => _downloadAttachment(
                                rootContext, attachedFileUrl),
                            icon: const Icon(Icons.download_outlined, size: 16),
                            label: const Text('Download'),
                          ),
                      ],
                    ),
                    if (existingDocs.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedExistingDocUrl != null &&
                                existingDocs.any(
                                    (doc) => doc.url == selectedExistingDocUrl)
                            ? selectedExistingDocUrl
                            : null,
                        items: existingDocs
                            .map(
                              (doc) => DropdownMenuItem(
                                value: doc.url,
                                child: Text(
                                  doc.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          final doc =
                              existingDocs.firstWhere((d) => d.url == v);
                          setDialogState(() {
                            selectedExistingDocUrl = v;
                            attachedFile = doc.name;
                            attachedFileUrl = doc.url;
                            attachedFileStoragePath = doc.storagePath;
                            manualUrlController.text = doc.url;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Select Existing Document In This Section',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: manualUrlController,
                      decoration: InputDecoration(
                        labelText: 'Or Paste Existing Download URL',
                        hintText:
                            'https://firebasestorage.googleapis.com/... (fallback if browser upload is blocked)',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dateController,
                            decoration: InputDecoration(
                              labelText: 'Date',
                              hintText: 'e.g. Weekly / Q2 2026',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: durationController,
                            decoration: InputDecoration(
                              labelText: 'Duration / Interval',
                              hintText: 'e.g. 60 mins',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: mandatory,
                      onChanged: (v) =>
                          setDialogState(() => mandatory = v == true),
                      title: const Text('Mandatory Requirement'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: confirmedRead,
                      onChanged: (v) =>
                          setDialogState(() => confirmedRead = v == true),
                      title: const Text('Confirm Read / Completed'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () => _downloadTemplatePdf(
                  rootContext,
                  title: titleController.text.trim().isEmpty
                      ? spec.label
                      : titleController.text.trim(),
                  category: category,
                  templateText: templateController.text.trim(),
                ),
                child: const Text('Template PDF'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _scrollToSection(category);
                },
                child: const Text('Go To Section'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final manualUrl = manualUrlController.text.trim();
                  final title = titleController.text.trim().isEmpty
                      ? spec.label
                      : titleController.text.trim();
                  final newActivity = TrainingActivity(
                    title: title,
                    description: templateController.text.trim(),
                    category: _normalizeCategory(category),
                    date: dateController.text.trim(),
                    duration: durationController.text.trim(),
                    attachedFile: attachedFile ??
                        (manualUrl.isNotEmpty ? _baseName(manualUrl) : null),
                    attachedFileUrl:
                        manualUrl.isNotEmpty ? manualUrl : attachedFileUrl,
                    attachedFileStoragePath: attachedFileStoragePath,
                    isCompleted: confirmedRead,
                    isMandatory: mandatory,
                  );

                  final updated = List<TrainingActivity>.from(
                    ProjectDataHelper.getProvider(rootContext)
                        .projectData
                        .trainingActivities,
                  )..add(newActivity);

                  Navigator.pop(dialogContext);
                  await _saveActivities(rootContext, updated);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Link to Overview'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_UploadedDoc?> _pickAndUploadAttachment(
    BuildContext context, {
    required String folder,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in is required before uploading attachments.'),
        ),
      );
      return null;
    }

    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select a project before uploading files.')),
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
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read file bytes.')),
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
      );
    } on FirebaseException catch (error) {
      if (!mounted) return null;
      _showStorageUploadError(context, error.toString());
      return null;
    } catch (error) {
      if (!mounted) return null;
      _showStorageUploadError(context, error.toString());
      return null;
    }
  }

  Future<void> _downloadAttachment(BuildContext context, String? url) async {
    final cleanUrl = (url ?? '').trim();
    if (cleanUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No downloadable file linked.')),
      );
      return;
    }

    final uri = Uri.tryParse(cleanUrl);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid download URL.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open attachment URL.')),
      );
    }
  }

  Future<void> _downloadTemplatePdf(
    BuildContext context, {
    required String title,
    required String category,
    required String templateText,
  }) async {
    final now = DateTime.now();
    final cleanTitle =
        title.trim().isEmpty ? 'training_template' : title.trim();
    final cleanCategory =
        category.trim().isEmpty ? 'training' : _normalizeCategory(category);
    final body = templateText.trim().isEmpty
        ? 'No template content entered yet.'
        : templateText.trim();
    final filename =
        '${_safeFileToken(cleanTitle)}_${_safeFileToken(cleanCategory)}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';

    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (_) => [
            pw.Text(
              cleanTitle,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Category: $cleanCategory',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              'Generated: ${now.toIso8601String().split('T').first}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              body,
              style: const pw.TextStyle(fontSize: 11),
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
        SnackBar(content: Text('Template PDF ready: $filename')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create PDF: $error')),
      );
    }
  }

  void _showStorageUploadError(BuildContext context, String rawError) {
    final lower = rawError.toLowerCase();
    final bucket = FirebaseStorage.instance.app.options.storageBucket;
    final isCorsIssue = lower.contains('cors') ||
        lower.contains('preflight') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('net::err_failed');
    final isPermissionIssue =
        lower.contains('permission') || lower.contains('unauthorized');

    String message;
    if (isCorsIssue) {
      message =
          'Upload blocked by browser CORS for bucket "$bucket". Apply bucket CORS config, then retry. You can paste a download URL meanwhile.';
    } else if (isPermissionIssue) {
      message =
          'Upload blocked by Storage rules/permissions for bucket "$bucket". Check Firebase Storage rules for authenticated writes.';
    } else {
      message = 'Failed to upload file: $rawError';
    }

    debugPrint('Storage upload error: $rawError');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _safeFileToken(String value) {
    final token = value.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final trimmed = token.replaceAll(RegExp(r'_+'), '_').replaceAll(
          RegExp(r'^_|_$'),
          '',
        );
    return trimmed.isEmpty ? 'template' : trimmed.toLowerCase();
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
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  List<_SectionDocumentRef> _sectionDocuments(
    BuildContext context, {
    required String category,
    String? excludeActivityId,
  }) {
    final normalized = _normalizeCategory(category);
    final seen = <String>{};
    final docs = <_SectionDocumentRef>[];

    for (final activity
        in ProjectDataHelper.getData(context).trainingActivities) {
      if (excludeActivityId != null && activity.id == excludeActivityId) {
        continue;
      }
      if (_normalizeCategory(activity.category) != normalized) {
        continue;
      }

      final url = (activity.attachedFileUrl ?? '').trim();
      if (url.isEmpty) continue;
      if (!seen.add(url)) continue;

      final name = (activity.attachedFile ?? '').trim().isNotEmpty
          ? activity.attachedFile!.trim()
          : _baseName(url);

      docs.add(
        _SectionDocumentRef(
          name: name,
          url: url,
          storagePath: activity.attachedFileStoragePath,
        ),
      );
    }

    docs.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return docs;
  }

  String _normalizeCategory(String category) {
    if (category == 'Training') return 'Discipline-Specific';
    return category;
  }

  String _baseName(String raw) {
    final withoutQuery = raw.split('?').first;
    return withoutQuery.split('/').last.split('\\').last;
  }

  void _scrollToSection(String category) {
    final key = _keyForCategory(_normalizeCategory(category));
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  GlobalKey _keyForCategory(String category) {
    switch (category) {
      case 'Onboarding':
        return _onboardingSectionKey;
      case 'Team Building':
        return _teamBuildingSectionKey;
      case 'Discipline-Specific':
      default:
        return _disciplineSectionKey;
    }
  }

  _ProjectContextSnapshot _buildContextSnapshot(ProjectDataModel data) {
    return _ProjectContextSnapshot(
      projectName: _firstNonEmpty(
        [data.projectName, data.solutionTitle],
        fallback: 'TBD Project',
      ),
      objective: _firstNonEmpty(
        [data.projectObjective, data.businessCase, data.solutionDescription],
        fallback: 'Objective not captured yet',
      ),
      framework: _firstNonEmpty(
        [data.overallFramework ?? '', data.potentialSolution],
        fallback: 'Framework pending',
      ),
      location: _firstNonEmpty(
        [data.charterOrganizationalUnit],
        fallback: 'Location not set',
      ),
      manager: _firstNonEmpty(
        [data.charterProjectManagerName],
        fallback: 'Project manager not set',
      ),
      sponsor: _firstNonEmpty(
        [data.charterProjectSponsorName],
        fallback: 'Project sponsor not set',
      ),
      roleLines: _collectRoleLines(data),
      goalLines: _collectGoalLines(data),
      milestoneLines: _collectMilestoneLines(data),
      noteHighlights: _collectPlanningNoteHighlights(data),
    );
  }

  String _buildTemplateForButton(
      _ResourceButtonSpec spec, ProjectDataModel data) {
    final snapshot = _buildContextSnapshot(data);
    final rolesText = snapshot.roleLines.isEmpty
        ? '- Add role owners and back-up owners.'
        : snapshot.roleLines.map((r) => '- $r').join('\n');
    final goalsText = snapshot.goalLines.isEmpty
        ? '- Add project goals and measurable outcomes.'
        : snapshot.goalLines.map((g) => '- $g').join('\n');
    final milestonesText = snapshot.milestoneLines.isEmpty
        ? '- Add milestone checkpoints and target dates.'
        : snapshot.milestoneLines.map((m) => '- $m').join('\n');
    final notesText = snapshot.noteHighlights.isEmpty
        ? '- No prior planning notes found.'
        : snapshot.noteHighlights.map((n) => '- $n').join('\n');

    switch (spec.id) {
      case 'welcome':
        return '''
WELCOME TEMPLATE
Purpose: standardize first-day orientation and reduce onboarding gaps.

Project Context
- Project: ${snapshot.projectName}
- Objective: ${snapshot.objective}
- Location/Org: ${snapshot.location}
- Project Manager: ${snapshot.manager}
- Sponsor: ${snapshot.sponsor}

Phased Checklist
- Pre-start: access request, tool setup, compliance docs, first-week agenda.
- Day 1: mission, scope, success criteria, and working model briefing.
- Week 1: expectations, buddy assignment, escalation path, and communication norms.
- Day 30: onboarding check, blockers review, and onboarding effectiveness check.

Completion Criteria
- New member can explain project scope and first sprint priorities.
- Read/completion confirmed.
''';
      case 'project_onboarding':
        return '''
PROJECT ONBOARDING TEMPLATE
Purpose: give every team member one consistent project brief.

Core Project Summary
- Project: ${snapshot.projectName}
- Objective: ${snapshot.objective}
- Framework: ${snapshot.framework}

Goals
$goalsText

Milestones
$milestonesText

Required Sections
- Scope in/out and assumptions.
- Key deliverables and acceptance criteria.
- Tools, repositories, and document locations.
- Risks, dependencies, and escalation flow.

Relevant Prior Notes
$notesText
''';
      case 'team_vacation':
        return '''
TEAM & VACATION TEMPLATE
Purpose: keep role coverage clear while preserving PTO and continuity.

Role and Ownership Matrix
$rolesText

Coverage Plan
- Primary owner per role.
- Backup owner per role.
- Handoff notes location.
- Vacation blackout windows (if any).
- Weekly capacity update and rebalancing rules.

Vacation Workflow
- Submit PTO at least 2 weeks in advance.
- Handoff checklist completed before leave.
- Critical tasks reassigned and acknowledged.
- Return-to-work sync scheduled.
''';
      case 'meetings':
        return '''
MEETINGS TEMPLATE
Purpose: establish recurring, timeboxed meetings with clear outcomes.

Recommended Core Cadence
- Daily sync / standup: 15 minutes.
- Sprint planning (if agile): up to 8 hours for a 1-month sprint.
- Sprint review (if agile): up to 4 hours for a 1-month sprint.
- Sprint retrospective (if agile): up to 3 hours for a 1-month sprint.

Meeting Catalog
- Name and cadence.
- Required attendees.
- Agenda owner.
- Expected output (decision, action list, blocker resolution).
- Notes repository and follow-up SLA.
''';
      case 'trainings':
        return '''
TRAINING PLAN TEMPLATE
Purpose: align mandatory learning with project needs.

Project and Objective
- Project: ${snapshot.projectName}
- Objective: ${snapshot.objective}

Training Plan Structure
- Need/skill gap.
- SMART learning objective.
- Delivery mode (workshop, simulation, peer session, self-paced).
- Owner and due date.
- Evidence of completion (quiz/demo/observation).

Evaluation Checklist
- Knowledge check completed.
- On-the-job application reviewed after 2-4 weeks.
- Training impact logged against delivery quality or cycle time.
''';
      case 'team_building':
        return '''
TEAM BUILDING TEMPLATE
Purpose: improve trust, communication, and team cohesion during delivery.

Team Context
- Project: ${snapshot.projectName}
- Manager: ${snapshot.manager}
- Sponsor: ${snapshot.sponsor}

Monthly Rhythm
- Weekly check-in ritual (10-15 mins).
- Bi-weekly collaboration exercise.
- Monthly team-building activity.
- Retro action follow-up and recognition moment.

Activity Backlog
- Ice breaker before key meetings.
- Cross-team shadowing pairs.
- Peer recognition board.
- Problem-solving session on a live project challenge.
''';
      default:
        return '''
RESOURCE TEMPLATE
- Project: ${snapshot.projectName}
- Objective: ${snapshot.objective}
- Context notes:
$notesText
''';
    }
  }

  List<String> _collectRoleLines(ProjectDataModel data) {
    final lines = <String>[];
    final seen = <String>{};

    for (final member in data.teamMembers) {
      final name = member.name.trim();
      final role = member.role.trim();
      if (name.isEmpty && role.isEmpty) continue;
      final line =
          role.isNotEmpty && name.isNotEmpty ? '$role - $name' : '$role$name';
      if (line.trim().isEmpty) continue;
      if (seen.add(line.toLowerCase())) lines.add(line);
    }

    for (final role in data.projectRoles) {
      final title = role.title.trim();
      final owner = role.workstream.trim();
      if (title.isEmpty && owner.isEmpty) continue;
      final line = owner.isNotEmpty && title.isNotEmpty
          ? '$title ($owner)'
          : '$title$owner';
      if (line.trim().isEmpty) continue;
      if (seen.add(line.toLowerCase())) lines.add(line);
    }

    for (final staffing in data.staffingRequirements) {
      final role = staffing.title.trim();
      final person = staffing.personName.trim();
      if (role.isEmpty && person.isEmpty) continue;
      final line = person.isNotEmpty && role.isNotEmpty
          ? '$role - $person'
          : '$role$person';
      if (line.trim().isEmpty) continue;
      if (seen.add(line.toLowerCase())) lines.add(line);
    }

    return lines.take(8).toList();
  }

  List<String> _collectGoalLines(ProjectDataModel data) {
    final lines = <String>[];
    for (final goal in data.projectGoals) {
      final name = goal.name.trim();
      final desc = goal.description.trim();
      if (name.isEmpty && desc.isEmpty) continue;
      lines.add(name.isNotEmpty
          ? '$name: ${_truncate(desc, 90)}'
          : _truncate(desc, 90));
    }
    for (final goal in data.planningGoals) {
      final name = goal.title.trim();
      final desc = goal.description.trim();
      if (name.isEmpty && desc.isEmpty) continue;
      final label = name.isEmpty ? 'Goal ${goal.goalNumber}' : name;
      lines.add('$label: ${_truncate(desc, 90)}');
    }
    return lines.take(6).toList();
  }

  List<String> _collectMilestoneLines(ProjectDataModel data) {
    final lines = <String>[];
    for (final milestone in data.keyMilestones) {
      final name = milestone.name.trim();
      final due = milestone.dueDate.trim();
      final discipline = milestone.discipline.trim();
      if (name.isEmpty && due.isEmpty && discipline.isEmpty) continue;
      final label = name.isEmpty ? 'Milestone' : name;
      final suffix = [
        if (due.isNotEmpty) 'Due: $due',
        if (discipline.isNotEmpty) discipline,
      ].join(' | ');
      lines.add(suffix.isEmpty ? label : '$label | $suffix');
    }
    return lines.take(6).toList();
  }

  List<String> _collectPlanningNoteHighlights(ProjectDataModel data) {
    if (data.planningNotes.isEmpty) return [];

    final prioritized = data.planningNotes.entries.where((entry) {
      final key = entry.key.toLowerCase();
      return key.contains('project') ||
          key.contains('summary') ||
          key.contains('team') ||
          key.contains('personnel') ||
          key.contains('organization') ||
          key.contains('meeting');
    }).toList();

    final source =
        prioritized.isEmpty ? data.planningNotes.entries.toList() : prioritized;

    return source
        .where((entry) => entry.value.trim().isNotEmpty)
        .take(4)
        .map((entry) => '${entry.key}: ${_truncate(entry.value.trim(), 100)}')
        .toList();
  }

  String _firstNonEmpty(List<String> values, {required String fallback}) {
    for (final value in values) {
      final v = value.trim();
      if (v.isNotEmpty) return v;
    }
    return fallback;
  }

  String _truncate(String text, int maxLength) {
    final value = text.trim();
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 3)}...';
  }

  Future<void> _addOnboardingTemplate(BuildContext context) async {
    final data = ProjectDataHelper.getData(context);
    final welcomeSpec =
        _resourceButtons.firstWhere((button) => button.id == 'welcome');
    final projectSpec = _resourceButtons
        .firstWhere((button) => button.id == 'project_onboarding');
    final teamSpec =
        _resourceButtons.firstWhere((button) => button.id == 'team_vacation');
    final meetingsSpec =
        _resourceButtons.firstWhere((button) => button.id == 'meetings');

    final template = [
      TrainingActivity(
        title: 'Welcome Orientation',
        description: _buildTemplateForButton(welcomeSpec, data),
        category: 'Onboarding',
        isMandatory: true,
        duration: '30 mins',
      ),
      TrainingActivity(
        title: 'Project Overview & Objectives',
        description: _buildTemplateForButton(projectSpec, data),
        category: 'Onboarding',
        isMandatory: true,
        duration: '60 mins',
      ),
      TrainingActivity(
        title: 'Roles, Responsibilities, and Vacation Coverage',
        description: _buildTemplateForButton(teamSpec, data),
        category: 'Onboarding',
        isMandatory: true,
        duration: '45 mins',
      ),
      TrainingActivity(
        title: 'Meeting Cadence and Communication Channels',
        description: _buildTemplateForButton(meetingsSpec, data),
        category: 'Onboarding',
        isMandatory: true,
        duration: '30 mins',
      ),
    ];

    final existing = data.trainingActivities;
    final retained = existing
        .where(
            (activity) => _normalizeCategory(activity.category) != 'Onboarding')
        .toList();
    final updated = [...retained, ...template];
    await _saveActivities(context, updated);
  }

  Future<void> _deleteActivity(
      BuildContext context, TrainingActivity activity) async {
    final rootContext = context;
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final updated = List<TrainingActivity>.from(
                  ProjectDataHelper.getProvider(rootContext)
                      .projectData
                      .trainingActivities);
              updated.removeWhere((a) => a.id == activity.id);
              Navigator.pop(dialogContext);
              await ProjectDataHelper.saveAndNavigate(
                context: rootContext,
                checkpoint: 'team_training',
                nextScreenBuilder: () => const TeamTrainingAndBuildingScreen(),
                dataUpdater: (d) => d.copyWith(trainingActivities: updated),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _yellowButton(
      {required String label,
      required IconData icon,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _circleIconButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, size: 16, color: Colors.grey[700]),
      ),
    );
  }

  Widget _profileCluster(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final email = user?.email ?? '';
    final name = displayName.isNotEmpty
        ? displayName
        : (email.isNotEmpty ? email : 'User');
    final photoUrl = user?.photoURL ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<bool>(
          stream: UserService.watchAdminStatus(),
          builder: (context, snapshot) {
            final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
            final role = isAdmin ? 'Admin' : 'Member';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue[400],
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(role,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey[700], size: 18),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[600]),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ]),
        ],
      ),
    );
  }
}

class _UpcomingTrainingList extends StatelessWidget {
  final List<TrainingActivity> activities;
  final Color accent;
  final bool heart;
  final ValueChanged<TrainingActivity>? onEdit;
  final ValueChanged<TrainingActivity>? onDelete;

  const _UpcomingTrainingList({
    required this.activities,
    required this.accent,
    this.heart = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(heart ? Icons.favorite_border : Icons.auto_awesome,
                    color: accent),
                const SizedBox(width: 8),
                Text(heart ? 'Upcoming Events' : 'Upcoming Training',
                    style:
                        TextStyle(color: accent, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No upcoming activities.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          else
            ...activities.map<Widget>((a) => Column(
                  children: [
                    _trainingItem(a),
                    if (a != activities.last) const Divider(height: 1),
                  ],
                )),
        ],
      ),
    );
  }

  Widget _trainingItem(TrainingActivity activity) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Text(activity.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (activity.isMandatory) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('MANDATORY',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.red[700])),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.event_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(activity.date.isEmpty ? 'TBD' : activity.date,
                    style: const TextStyle(color: Colors.black87)),
                const SizedBox(width: 12),
                const Icon(Icons.schedule_outlined,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(activity.duration.isEmpty ? 'TBD' : activity.duration,
                    style: const TextStyle(color: Colors.black87)),
              ]),
            ]),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: () => onEdit!(activity),
              icon:
                  const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => onDelete!(activity),
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Color(0xFFEF4444)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _BenefitCard(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              child: Icon(icon, color: Colors.blueGrey[700])),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
