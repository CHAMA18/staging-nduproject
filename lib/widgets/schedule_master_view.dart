import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/theme.dart';

class ScheduleMasterView extends StatelessWidget {
  const ScheduleMasterView({
    super.key,
    required this.workPackages,
    required this.scheduleActivities,
    this.onWorkPackageTap,
    this.onActivityTap,
  });

  final List<WorkPackage> workPackages;
  final List<ScheduleActivity> scheduleActivities;
  final ValueChanged<WorkPackage>? onWorkPackageTap;
  final ValueChanged<ScheduleActivity>? onActivityTap;

  @override
  Widget build(BuildContext context) {
    final byWbsLevel2 = <String, List<WorkPackage>>{};
    for (final wp in workPackages) {
      final key = wp.wbsLevel2Id.isNotEmpty ? wp.wbsLevel2Id : 'unassigned';
      byWbsLevel2.putIfAbsent(key, () => []).add(wp);
    }

    final wbsLevel2Titles = <String, String>{};
    for (final wp in workPackages) {
      if (wp.wbsLevel2Id.isNotEmpty && wp.wbsLevel2Title.isNotEmpty) {
        wbsLevel2Titles[wp.wbsLevel2Id] = wp.wbsLevel2Title;
      }
    }

    final activitiesByWp = <String, List<ScheduleActivity>>{};
    for (final activity in scheduleActivities) {
      if (activity.workPackageId.isNotEmpty) {
        activitiesByWp
            .putIfAbsent(activity.workPackageId, () => [])
            .add(activity);
      }
    }

    final unassignedWps = byWbsLevel2.remove('unassigned') ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Master Schedule - WBS Level 2',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (byWbsLevel2.isEmpty && unassignedWps.isEmpty)
            const _EmptyMasterView()
          else
            ...byWbsLevel2.entries.map((entry) {
              final title = wbsLevel2Titles[entry.key] ?? 'Untitled Phase';
              return _WbsLevel2Section(
                wbsLevel2Id: entry.key,
                title: title,
                workPackages: entry.value,
                activitiesByWp: activitiesByWp,
                onWorkPackageTap: onWorkPackageTap,
                onActivityTap: onActivityTap,
              );
            }),
          if (unassignedWps.isNotEmpty) ...[
            const SizedBox(height: 16),
            _WbsLevel2Section(
              wbsLevel2Id: 'unassigned',
              title: 'Unassigned Work Packages',
              workPackages: unassignedWps,
              activitiesByWp: activitiesByWp,
              onWorkPackageTap: onWorkPackageTap,
              onActivityTap: onActivityTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _WbsLevel2Section extends StatelessWidget {
  const _WbsLevel2Section({
    required this.wbsLevel2Id,
    required this.title,
    required this.workPackages,
    required this.activitiesByWp,
    this.onWorkPackageTap,
    this.onActivityTap,
  });

  final String wbsLevel2Id;
  final String title;
  final List<WorkPackage> workPackages;
  final Map<String, List<ScheduleActivity>> activitiesByWp;
  final ValueChanged<WorkPackage>? onWorkPackageTap;
  final ValueChanged<ScheduleActivity>? onActivityTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder, size: 18, color: Color(0xFF4B5563)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${workPackages.length} WP',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...workPackages.map((wp) {
            final activities = activitiesByWp[wp.id] ?? [];
            return _WorkPackageTile(
              workPackage: wp,
              activities: activities,
              onTap: onWorkPackageTap,
              onActivityTap: onActivityTap,
            );
          }),
        ],
      ),
    );
  }
}

class _WorkPackageTile extends StatelessWidget {
  const _WorkPackageTile({
    required this.workPackage,
    required this.activities,
    this.onTap,
    this.onActivityTap,
  });

  final WorkPackage workPackage;
  final List<ScheduleActivity> activities;
  final ValueChanged<WorkPackage>? onTap;
  final ValueChanged<ScheduleActivity>? onActivityTap;

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'complete':
        return const Color(0xFF10B981);
      case 'blocked':
      case 'on_hold':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(workPackage.status);
    final progress = workPackage.budgetedCost > 0
        ? (workPackage.actualCost / workPackage.budgetedCost).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => onTap?.call(workPackage),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppSemanticColors.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    workPackage.title.isNotEmpty
                        ? workPackage.title
                        : 'Untitled Work Package',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    workPackage.type.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (workPackage.description.isNotEmpty)
              Text(
                workPackage.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _phaseIcon(workPackage.phase),
                  size: 14,
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  workPackage.phase.isNotEmpty
                      ? workPackage.phase.toUpperCase()
                      : 'N/A',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.person_outline,
                    size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(
                  workPackage.owner.isNotEmpty
                      ? workPackage.owner
                      : 'Unassigned',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${workPackage.budgetedCost.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            if (activities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Activities (${activities.length}):',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              ...activities.take(3).map((activity) {
                return GestureDetector(
                  onTap: () => onActivityTap?.call(activity),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppSemanticColors.border),
                    ),
                    child: Row(
                      children: [
                        if (activity.isCriticalPath)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CP',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            activity.title.isNotEmpty
                                ? activity.title
                                : 'Untitled Activity',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF374151),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(activity.progress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (activities.length > 3)
                Text(
                  '+ ${activities.length - 3} more...',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _phaseIcon(String phase) {
    switch (phase) {
      case 'design':
        return Icons.brush_outlined;
      case 'execution':
        return Icons.build_outlined;
      case 'launch':
        return Icons.rocket_launch_outlined;
      default:
        return Icons.help_outline;
    }
  }
}

class _EmptyMasterView extends StatelessWidget {
  const _EmptyMasterView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 48,
            color: const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Work Packages Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create work packages and link them to schedule activities '
            'to see the master schedule view.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
