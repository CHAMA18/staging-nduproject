import 'package:flutter/material.dart';
import 'package:ndu_project/models/control_account_model.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/control_account_service.dart';
import 'package:ndu_project/services/evm_snapshot_service.dart';
import 'package:ndu_project/providers/project_data_provider.dart';

/// Provider that manages control account EVM state and ensures
/// recalculated metrics flow back to [ProjectDataProvider] for persistence.
///
/// **Persistence Gap Fix (G1/G2):** Previously, [recalculateAll] computed EVM
/// metrics but never wrote them back to [ProjectDataModel], so the values
/// were lost on navigation or app restart. Now, after each recalculation,
/// the updated accounts are written to [ProjectDataProvider.updateField],
/// [computeAggregateEvm] is called to roll up project-level metrics, and
/// [EvmSnapshotService.captureSnapshot] is invoked to record the trend point.
class ControlAccountProvider extends ChangeNotifier {
  List<ControlAccount> _accounts = [];
  bool _isRecalculating = false;

  /// Reference to the [ProjectDataProvider] for write-back persistence.
  ProjectDataProvider? _projectDataProvider;

  List<ControlAccount> get accounts => _accounts;
  bool get isRecalculating => _isRecalculating;

  /// Set the [ProjectDataProvider] reference so that recalculated data
  /// can be persisted back to Firestore. Call this once after both providers
  /// are created (e.g. in [MultiProvider] setup or via [Provider.context]).
  void setProjectDataProvider(ProjectDataProvider provider) {
    _projectDataProvider = provider;
  }

  /// Load accounts from a ProjectDataModel.
  void loadFromProjectData(ProjectDataModel projectData) {
    _accounts = List<ControlAccount>.from(projectData.controlAccounts);
    notifyListeners();
  }

  /// Recalculate all accounts after scope/cost/schedule changes.
  ///
  /// **Persistence Gap Fix (G1/G2):** After recomputing EVM metrics, the
  /// updated control accounts are written back to [ProjectDataModel] via
  /// [ProjectDataProvider.updateField]. Then [computeAggregateEvm] is
  /// called to update project-level aggregate metrics (BAC, CPI, SPI, EAC,
  /// etc.), and an EVM snapshot is captured for trend analysis.
  Future<void> recalculateAll(ProjectDataModel projectData) async {
    _isRecalculating = true;
    notifyListeners();

    _accounts = ControlAccountService.recalculateAll(
      accounts: _accounts,
      workPackages: projectData.workPackages,
      activities: projectData.scheduleActivities,
      costItems: projectData.costEstimateItems,
    );

    _isRecalculating = false;
    notifyListeners();

    // ── G1 Fix: Write recalculated accounts back to ProjectDataProvider ──
    if (_projectDataProvider != null) {
      _projectDataProvider!.updateField((data) {
        return data
            .copyWith(controlAccounts: _accounts)
            .computeAggregateEvm(); // G2 Fix: roll up project-level EVM
      });

      // ── G3 Fix: Capture an EVM snapshot for trend charts ──
      final projectId = _projectDataProvider!.projectData.projectId;
      if (projectId != null && projectId.isNotEmpty) {
        try {
          final updatedData = _projectDataProvider!.projectData;
          await EvmSnapshotService.captureSnapshot(
            projectId: projectId,
            data: updatedData,
            source: 'auto_recalc',
          );
        } catch (e) {
          debugPrint('EvmSnapshotService.captureSnapshot failed: $e');
          // Non-critical — don't block the recalculation flow
        }
      }
    }
  }

  /// CRUD operations — each now writes back to ProjectDataProvider.
  void addAccount(ControlAccount account) {
    _accounts.add(account);
    _syncToProjectData();
    notifyListeners();
  }

  void updateAccount(ControlAccount account) {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      _accounts[index] = account;
      _syncToProjectData();
      notifyListeners();
    }
  }

  void removeAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);
    _syncToProjectData();
    notifyListeners();
  }

  ControlAccount? getAccount(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ControlAccount> getAccountsByWbs(String wbsId) {
    return _accounts.where((a) => a.wbsId == wbsId).toList();
  }

  List<ControlAccount> getAccountsByObs(String obsId) {
    return _accounts.where((a) => a.obsId == obsId).toList();
  }

  double get totalBudgetAtCompletion =>
      _accounts.fold<double>(0, (s, a) => s + a.budgetAtCompletion);

  double get totalEarnedValue =>
      _accounts.fold<double>(0, (s, a) => s + a.earnedValue);

  double get totalActualCost =>
      _accounts.fold<double>(0, (s, a) => s + a.actualCost);

  double get overallCpi {
    final ac = totalActualCost;
    return ac > 0 ? totalEarnedValue / ac : 1.0;
  }

  double get overallSpi {
    final pv = _accounts.fold<double>(0, (s, a) {
      final now = DateTime.now();
      final currentKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      double total = 0;
      for (final entry in a.plannedValueByPeriod.entries) {
        if (entry.key.compareTo(currentKey) <= 0) {
          total += entry.value;
        }
      }
      return s + total;
    });
    return pv > 0 ? totalEarnedValue / pv : 1.0;
  }

  void reset() {
    _accounts = [];
    _isRecalculating = false;
    notifyListeners();
  }

  // ── Private: Sync current accounts list to ProjectDataProvider ──
  void _syncToProjectData() {
    if (_projectDataProvider == null) return;
    _projectDataProvider!.updateField((data) {
      return data
          .copyWith(controlAccounts: _accounts)
          .computeAggregateEvm();
    });
  }
}
