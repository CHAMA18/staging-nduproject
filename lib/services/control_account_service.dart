import 'package:ndu_project/models/control_account_model.dart';
import 'package:ndu_project/models/project_data_model.dart';

class ControlAccountService {
  /// Recalculate EVM metrics for all control accounts based on work package data.
  ///
  /// **P1.5 Fix**: Earned Value now uses the standard EVM formula:
  ///   EV = percentComplete × budgetedCost  (for in_progress work packages)
  ///   EV = budgetedCost                    (for complete work packages)
  /// Previously, EV for in_progress WPs used actualCost/budgetedCost ratio,
  /// which conflates actual cost with earned value — a violation of standard EVM.
  static List<ControlAccount> recalculateAll({
    required List<ControlAccount> accounts,
    required List<WorkPackage> workPackages,
    required List<ScheduleActivity> activities,
    required List<CostEstimateItem> costItems,
  }) {
    return accounts.map((account) {
      final filteredWps = workPackages
          .where((wp) => wp.controlAccountId == account.id)
          .toList();
      final filteredActivities = activities
          .where((a) => a.controlAccountId == account.id)
          .toList();
      final filteredCosts = costItems
          .where((c) => c.controlAccountId == account.id)
          .toList();

      return _recalculateOne(
        account: account,
        workPackages: filteredWps,
        activities: filteredActivities,
        costItems: filteredCosts,
      );
    }).toList();
  }

  /// Recalculate a single control account's EVM from its linked items.
  ///
  /// Uses standard EVM formulas per the Integrated Project Controls guide:
  /// - BAC = Σ(WP.budgetedCost)
  /// - EV = Σ(WP.percentComplete × WP.budgetedCost)  [standard earned value]
  /// - AC = Σ(WP.actualCost)
  /// - PV = Σ(plannedValueByPeriod up to current month)
  /// - CPI = EV / AC
  /// - SPI = EV / PV
  /// - EAC = BAC / CPI  (CPI-based; composite formula available via ForecastService)
  /// - ETC = EAC - AC
  /// - VAC = BAC - EAC
  /// - CV  = EV - AC
  /// - SV  = EV - PV
  /// - TCPI(BAC) = (BAC - EV) / (BAC - AC)
  /// - TCPI(EAC) = (BAC - EV) / (EAC - AC)
  static ControlAccount _recalculateOne({
    required ControlAccount account,
    required List<WorkPackage> workPackages,
    required List<ScheduleActivity> activities,
    required List<CostEstimateItem> costItems,
  }) {
    final double bac =
        workPackages.fold<double>(0, (s, wp) => s + wp.budgetedCost);

    // ── P1.5 Fix: Standard EV calculation using percentComplete × BAC ──
    double ev = 0;
    for (final wp in workPackages) {
      if (wp.status == 'complete') {
        ev += wp.budgetedCost;
      } else if (wp.status == 'in_progress') {
        // Standard EVM: EV = % complete × BAC for this work package
        // Use percentComplete if available (> 0), otherwise fall back to
        // a conservative 50/50 rule for legacy data without percentComplete.
        if (wp.percentComplete > 0) {
          ev += wp.percentComplete.clamp(0, 1) * wp.budgetedCost;
        } else {
          // 50/50 rule: 50% earned when started, 100% when complete
          ev += wp.budgetedCost * 0.5;
        }
      }
      // 'planned' status: EV = 0 (no work done yet)
    }

    final double ac =
        workPackages.fold<double>(0, (s, wp) => s + wp.actualCost);

    final double pvAtNow = computePlannedValueToDate(
      account.plannedValueByPeriod,
    );

    final double cpi = ac > 0 ? ev / ac : 1.0;
    final double spi = pvAtNow > 0 ? ev / pvAtNow : 1.0;
    final double eac = cpi > 0 ? bac / cpi : bac;
    final double etc = eac - ac;
    final double vac = bac - eac;
    final double cv = ev - ac;
    final double sv = ev - pvAtNow;
    final double tcpii = (bac - ac) > 0 ? (bac - ev) / (bac - ac) : 1.0;
    final double tcpis = (eac - ac) > 0 ? (bac - ev) / (eac - ac) : 1.0;

    return account.copyWith(
      budgetAtCompletion: bac,
      earnedValue: ev,
      actualCost: ac,
      cpi: cpi,
      spi: spi,
      eac: eac,
      etc: etc,
      vac: vac,
      cv: cv,
      sv: sv,
      tcpii: tcpii,
      tcpis: tcpis,
      lastRecalculated: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Sum planned values for periods up to the current month.
  ///
  /// Public so it can be used by [BaselineManagementService] and other
  /// services that need PV-to-date without a full [recalculateAll].
  static double computePlannedValueToDate(Map<String, double> pvByPeriod) {
    final now = DateTime.now();
    final currentKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    double total = 0;
    for (final entry in pvByPeriod.entries) {
      if (entry.key.compareTo(currentKey) <= 0) {
        total += entry.value;
      }
    }
    return total;
  }

  /// Sum planned values across all control accounts up to the current month.
  /// Convenience method that applies [computePlannedValueToDate] to each
  /// control account's [plannedValueByPeriod] and returns the aggregate.
  static double computeAggregatePlannedValueToDate(
      List<ControlAccount> accounts) {
    double total = 0;
    for (final account in accounts) {
      total += computePlannedValueToDate(account.plannedValueByPeriod);
    }
    return total;
  }

  /// Compute CPI (Cost Performance Index).
  static double computeCpi(double earnedValue, double actualCost) {
    return actualCost > 0 ? earnedValue / actualCost : 1.0;
  }

  /// Compute SPI (Schedule Performance Index).
  static double computeSpi(double earnedValue, double plannedValue) {
    return plannedValue > 0 ? earnedValue / plannedValue : 1.0;
  }

  /// Compute EAC (Estimate at Completion) using CPI-based formula.
  static double computeEac(double bac, double cpi) {
    return cpi > 0 ? bac / cpi : bac;
  }

  /// Compute EAC using composite CPI×SPI formula for schedule-critical projects.
  /// EAC = AC + [(BAC - EV) / (CPI × SPI)]
  static double computeEacComposite(double bac, double ev, double ac, double cpi, double spi) {
    final denominator = cpi * spi;
    return denominator > 0 ? ac + ((bac - ev) / denominator) : bac;
  }

  /// Compute ETC (Estimate to Complete).
  static double computeEtc(double eac, double actualCost) {
    return eac - actualCost;
  }

  /// Compute VAC (Variance at Completion).
  static double computeVac(double bac, double eac) {
    return bac - eac;
  }

  /// Compute CV (Cost Variance = EV - AC).
  static double computeCv(double earnedValue, double actualCost) {
    return earnedValue - actualCost;
  }

  /// Compute SV (Schedule Variance = EV - PV).
  static double computeSv(double earnedValue, double plannedValue) {
    return earnedValue - plannedValue;
  }

  /// TCPI based on BAC (to-complete performance index).
  static double computeTcpii(double bac, double ev, double ac) {
    return (bac - ac) > 0 ? (bac - ev) / (bac - ac) : 1.0;
  }

  /// TCPI based on EAC (to-complete performance index using EAC).
  static double computeTcpis(double bac, double ev, double eac, double ac) {
    return (eac - ac) > 0 ? (bac - ev) / (eac - ac) : 1.0;
  }

  /// Compute risk-adjusted EAC using risk adjustment factor.
  /// EAC_risk = EAC × (1 + riskAdjustment)
  static double computeRiskAdjustedEac(double eac, double riskAdjustment) {
    return eac * (1 + riskAdjustment);
  }
}
