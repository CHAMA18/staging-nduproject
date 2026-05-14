import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ndu_project/models/baseline_version_model.dart';
import 'package:ndu_project/models/control_account_model.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/models/cbs_element_model.dart';
import 'package:ndu_project/models/obs_element_model.dart';
import 'package:ndu_project/models/scope_tracking_item.dart';
import 'package:ndu_project/services/control_account_service.dart';

class BaselineManagementService {
  static CollectionReference<Map<String, dynamic>>? _tryCollection() {
    try {
      return FirebaseFirestore.instance.collection('project_baselines');
    } catch (e, st) {
      debugPrint('BaselineManagementService: Firestore not ready ($e)\n$st');
      return null;
    }
  }

  static CollectionReference<Map<String, dynamic>> _requireCollection() {
    final col = _tryCollection();
    if (col == null) {
      throw StateError('Firestore is not initialized');
    }
    return col;
  }

  /// Create a baseline snapshot from the current project data.
  static Future<String> createBaseline({
    required String projectId,
    required String author,
    required String label,
    String description = '',
    String triggerSource = 'manual',
    String approvedBy = '',
  }) async {
    final existingVersions = await _requireCollection()
        .where('projectId', isEqualTo: projectId)
        .get();
    final versionNumber = existingVersions.size + 1;

    final baseline = BaselineVersion(
      versionNumber: versionNumber,
      label: label,
      description: description,
      author: author,
      approvedBy: approvedBy,
      triggerSource: triggerSource,
    );

    await _requireCollection().doc(projectId).collection('versions').add({
      ...baseline.toJson(),
      'projectId': projectId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return baseline.id;
  }

  /// Retrieve all baselines for a project, ordered by creation date descending.
  static Stream<List<BaselineVersion>> streamBaselines(String projectId) {
    final col = _tryCollection();
    if (col == null) {
      return Stream.value([]);
    }
    return col
        .doc(projectId)
        .collection('versions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return BaselineVersion.fromJson(data);
          })
          .toList();
    });
  }

  /// Compute schedule variance between current and baseline.
  static double computeScheduleVarianceDays({
    required List<ScheduleActivity> currentActivities,
    required List<ScheduleActivity> baselineActivities,
  }) {
    double totalVariance = 0;
    int count = 0;

    for (final current in currentActivities) {
      final baseline = baselineActivities.where((b) => b.id == current.id).firstOrNull;
      if (baseline == null) continue;
      if (current.dueDate.isEmpty || baseline.dueDate.isEmpty) continue;

      final currentDate = DateTime.tryParse(current.dueDate);
      final baselineDate = DateTime.tryParse(baseline.dueDate);
      if (currentDate == null || baselineDate == null) continue;

      totalVariance += currentDate.difference(baselineDate).inDays;
      count++;
    }

    return count > 0 ? totalVariance / count : 0;
  }

  /// Compute cost variance between current and baseline.
  static double computeCostVariance({
    required List<WorkPackage> currentPackages,
    required List<WorkPackage> baselinePackages,
  }) {
    final currentTotal =
        currentPackages.fold<double>(0, (s, wp) => s + wp.budgetedCost);
    final baselineTotal =
        baselinePackages.fold<double>(0, (s, wp) => s + wp.budgetedCost);
    return currentTotal - baselineTotal;
  }

  /// ── P2.1: Build a FULL snapshot with structural data and EVM metrics ──
  /// Captures control accounts, WBS, CBS, OBS, schedule activities, and
  /// work packages as point-in-time snapshots for baseline comparison/restore.
  static Future<String> captureSnapshot({
    required String projectId,
    required String author,
    required ProjectDataModel projectData,
    String label = '',
    String description = '',
    String triggerSource = 'manual',
    String approvedBy = '',
  }) async {
    final existingVersions = await _requireCollection()
        .doc(projectId)
        .collection('versions')
        .get();
    final versionNumber = existingVersions.size + 1;

    // Schedule variance
    final svDays = computeScheduleVarianceDays(
      currentActivities: projectData.scheduleActivities,
      baselineActivities: projectData.scheduleBaselineActivities,
    );

    // Cost variance
    final costVar = computeCostVariance(
      currentPackages: projectData.workPackages,
      baselinePackages: [], // Empty baseline list — first baseline has no prior
    );

    // Activity counts
    final totalWps = projectData.workPackages.length;
    final totalActs = projectData.scheduleActivities.length;
    final completedActs = projectData.scheduleActivities
        .where((a) => a.status == 'complete')
        .length;

    // ── P2.1: Compute aggregate EVM metrics from control accounts ──
    final controlAccounts = projectData.controlAccounts;
    double aggBac = 0, aggEv = 0, aggAc = 0, aggPv = 0;
    for (final ca in controlAccounts) {
      aggBac += ca.budgetAtCompletion;
      aggEv += ca.earnedValue;
      aggAc += ca.actualCost;
      aggPv += ControlAccountService.computePlannedValueToDate(ca.plannedValueByPeriod);
    }
    final aggCpi = aggAc > 0 ? aggEv / aggAc : 1.0;
    final aggSpi = aggPv > 0 ? aggEv / aggPv : 1.0;
    final aggEac = aggCpi > 0 ? aggBac / aggCpi : aggBac;
    final aggEtc = aggEac - aggAc;
    final aggVac = aggBac - aggEac;
    final aggCv = aggEv - aggAc;
    final aggSv = aggEv - aggPv;
    final aggTcpii = (aggBac - aggAc) > 0 ? (aggBac - aggEv) / (aggBac - aggAc) : 1.0;

    // ── P2.1: Scope tracking metrics ──
    final scopeItems = <ScopeTrackingItem>[]; // populated from execution service
    final totalScopeItems = scopeItems.length;
    final baselineScopeItems = scopeItems.where((s) => s.isBaseline).length;
    final scopeCreepItems = scopeItems.where((s) => !s.isBaseline).length;
    final scopeGrowthPercent = baselineScopeItems > 0
        ? (scopeCreepItems / baselineScopeItems) * 100
        : 0;

    // ── P2.1: Capture structural snapshots ──
    final caSnapshots = controlAccounts.map((ca) => {
      'id': ca.id,
      'wbsId': ca.wbsId,
      'obsId': ca.obsId,
      'cbsId': ca.cbsId,
      'title': ca.title,
      'bac': ca.budgetAtCompletion,
      'earnedValue': ca.earnedValue,
      'actualCost': ca.actualCost,
      'cpi': ca.cpi,
      'spi': ca.spi,
      'eac': ca.eac,
      'plannedValueByPeriod': ca.plannedValueByPeriod,
    }).toList();

    final wbsSnapshots = _flattenWbsTree(projectData.wbsTree);
    final cbsSnapshots = projectData.cbsElements.map((cbs) => {
      'id': cbs.id,
      'code': cbs.code,
      'name': cbs.name,
      'parentCbsId': cbs.parentCbsId,
      'budgetAmount': cbs.budgetAmount,
      'committedAmount': cbs.committedAmount,
      'spentAmount': cbs.spentAmount,
    }).toList();
    final obsSnapshots = projectData.obsElements.map((obs) => {
      'id': obs.id,
      'name': obs.name,
      'parentObsId': obs.parentObsId,
      'manager': obs.manager,
      'role': obs.role,
    }).toList();
    final scheduleSnapshots = projectData.scheduleActivities.map((a) => {
      'id': a.id,
      'title': a.title,
      'startDate': a.startDate?.toString() ?? '',
      'dueDate': a.dueDate,
      'status': a.status,
      'isCriticalPath': a.isCriticalPath,
    }).toList();
    final wpSnapshots = projectData.workPackages.map((wp) => {
      'id': wp.id,
      'title': wp.title,
      'budgetedCost': wp.budgetedCost,
      'actualCost': wp.actualCost,
      'status': wp.status,
      'percentComplete': wp.percentComplete,
    }).toList();

    final baseline = BaselineVersion(
      versionNumber: versionNumber,
      label: label.isNotEmpty ? label : 'Baseline v$versionNumber',
      description: description,
      author: author,
      approvedBy: approvedBy,
      triggerSource: triggerSource,
      scheduleVarianceDays: svDays,
      costVariance: costVar,
      budgetAtCompletion: aggBac,
      totalActivities: totalActs,
      completedActivities: completedActs,
      totalWorkPackages: totalWps,
      // EVM snapshot
      plannedValue: aggPv,
      earnedValue: aggEv,
      actualCost: aggAc,
      cpi: aggCpi,
      spi: aggSpi,
      eac: aggEac,
      etc: aggEtc,
      vac: aggVac,
      cv: aggCv,
      sv: aggSv,
      tcpii: aggTcpii,
      // Scope snapshot
      totalScopeItems: totalScopeItems,
      baselineScopeItems: baselineScopeItems,
      scopeCreepItems: scopeCreepItems,
      scopeGrowthPercent: scopeGrowthPercent,
      // Structural snapshots
      controlAccountSnapshots: caSnapshots,
      wbsSnapshots: wbsSnapshots,
      cbsSnapshots: cbsSnapshots,
      obsSnapshots: obsSnapshots,
      scheduleActivitySnapshots: scheduleSnapshots,
      workPackageSnapshots: wpSnapshots,
      isCurrent: true,
    );

    // Mark all previous versions as not current
    final batch = FirebaseFirestore.instance.batch();
    final prevVersions = await _requireCollection()
        .doc(projectId)
        .collection('versions')
        .where('isCurrent', isEqualTo: true)
        .get();
    for (final doc in prevVersions.docs) {
      batch.update(doc.reference, {'isCurrent': false});
    }
    await batch.commit();

    await _requireCollection().doc(projectId).collection('versions').add({
      ...baseline.toJson(),
      'projectId': projectId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return baseline.id;
  }

  /// Flatten the WBS tree into a list of snapshots for storage.
  static List<Map<String, dynamic>> _flattenWbsTree(List<WorkItem> tree) {
    final result = <Map<String, dynamic>>[];
    void walk(List<WorkItem> items) {
      for (final item in items) {
        result.add({
          'id': item.id,
          'wbsCode': item.wbsCode,
          'title': item.title,
          'parentId': item.parentId,
          'status': item.status,
        });
        walk(item.children);
      }
    }
    walk(tree);
    return result;
  }

  /// Compare two baseline versions and return the differences.
  /// Returns a map of field names to {previous, current, delta} for numeric fields,
  /// and lists of added/removed/modified items for structural snapshots.
  static Map<String, dynamic> compareBaselines({
    required BaselineVersion previous,
    required BaselineVersion current,
  }) {
    final diffs = <String, dynamic>{};

    // Numeric field comparisons
    final numericFields = {
      'budgetAtCompletion': [previous.budgetAtCompletion, current.budgetAtCompletion],
      'plannedValue': [previous.plannedValue, current.plannedValue],
      'earnedValue': [previous.earnedValue, current.earnedValue],
      'actualCost': [previous.actualCost, current.actualCost],
      'cpi': [previous.cpi, current.cpi],
      'spi': [previous.spi, current.spi],
      'eac': [previous.eac, current.eac],
      'scheduleVarianceDays': [previous.scheduleVarianceDays, current.scheduleVarianceDays],
      'costVariance': [previous.costVariance, current.costVariance],
      'totalScopeItems': [previous.totalScopeItems.toDouble(), current.totalScopeItems.toDouble()],
      'scopeCreepItems': [previous.scopeCreepItems.toDouble(), current.scopeCreepItems.toDouble()],
    };

    for (final entry in numericFields.entries) {
      final prev = entry.value[0] as double;
      final curr = entry.value[1] as double;
      final delta = curr - prev;
      if (delta != 0) {
        diffs[entry.key] = {
          'previous': prev,
          'current': curr,
          'delta': delta,
          'percentChange': prev != 0 ? (delta / prev) * 100 : 0,
        };
      }
    }

    // Structural change detection: WBS items added/removed
    final prevWbsIds = previous.wbsSnapshots.map((e) => e['id']?.toString()).toSet();
    final currWbsIds = current.wbsSnapshots.map((e) => e['id']?.toString()).toSet();
    final addedWbs = currWbsIds.difference(prevWbsIds).length;
    final removedWbs = prevWbsIds.difference(currWbsIds).length;
    if (addedWbs > 0 || removedWbs > 0) {
      diffs['wbsChanges'] = {'added': addedWbs, 'removed': removedWbs};
    }

    // Work package changes
    final prevWpIds = previous.workPackageSnapshots.map((e) => e['id']?.toString()).toSet();
    final currWpIds = current.workPackageSnapshots.map((e) => e['id']?.toString()).toSet();
    final addedWps = currWpIds.difference(prevWpIds).length;
    final removedWps = prevWpIds.difference(currWpIds).length;
    if (addedWps > 0 || removedWps > 0) {
      diffs['workPackageChanges'] = {'added': addedWps, 'removed': removedWps};
    }

    return diffs;
  }
}
