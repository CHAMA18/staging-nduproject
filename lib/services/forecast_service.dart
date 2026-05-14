/// Represents a risk factor from the risk register that can be quantified
/// for risk-adjusted forecasting.
class RiskFactor {
  final String id;
  final String title;
  final double probability; // 0-1
  final double costImpact;  // dollar impact if risk materializes
  final int scheduleImpactDays; // schedule impact if risk materializes
  final String category; // 'schedule' | 'cost' | 'scope' | 'quality'

  const RiskFactor({
    required this.id,
    required this.title,
    this.probability = 0.5,
    this.costImpact = 0,
    this.scheduleImpactDays = 0,
    this.category = 'cost',
  });

  /// Expected Monetary Value (EMV) = probability × costImpact
  double get emv => probability * costImpact;
}

class ForecastResult {
  final double eac;
  final double etc;
  final double vac;
  final double tcpii;
  final double tcpis;
  final String methodology;
  final DateTime forecastDate;
  final double confidenceLevel;

  // ── P2.4: Enhanced forecast result fields ──
  /// EAC lower bound (optimistic scenario).
  final double eacLow;
  /// EAC upper bound (pessimistic scenario).
  final double eacHigh;
  /// Composite EAC using CPI×SPI formula for schedule-critical projects.
  final double eacComposite;
  /// Risk-adjusted EAC incorporating risk register quantification.
  final double eacRiskAdjusted;
  /// Total Expected Monetary Value from risk factors.
  final double totalRiskEmv;
  /// Independent Estimate at Completion (IEAC) — statistical regression.
  final double ieac;

  ForecastResult({
    required this.eac,
    required this.etc,
    required this.vac,
    required this.tcpii,
    required this.tcpis,
    required this.methodology,
    required this.forecastDate,
    required this.confidenceLevel,
    this.eacLow = 0,
    this.eacHigh = 0,
    this.eacComposite = 0,
    this.eacRiskAdjusted = 0,
    this.totalRiskEmv = 0,
    this.ieac = 0,
  });
}

class ForecastService {
  /// Calculate EAC (Estimate at Completion) and related metrics using standard EVM formulas.
  ///
  /// [methodology] can be:
  ///   - 'formula' (default): EAC = BAC / CPI
  ///   - 'manual': user-supplied EAC override
  ///   - 'riskBased': incorporates risk register quantification (P2.4 — now fully implemented)
  ///   - 'composite': EAC = AC + [(BAC - EV) / (CPI × SPI)] for schedule-critical projects
  static ForecastResult calculateEac({
    required double bac,
    required double ev,
    required double ac,
    required double pv,
    String methodology = 'formula',
    double? manualEac,
    List<RiskFactor>? riskFactors,
  }) {
    final cpi = ac > 0 ? ev / ac : 1.0;
    final spi = pv > 0 ? ev / pv : 1.0;

    // Standard CPI-based EAC
    final eacCpi = cpi > 0 ? bac / cpi : bac;

    // Composite EAC (CPI × SPI) for schedule-critical projects
    final compositeDenom = cpi * spi;
    final eacComposite = compositeDenom > 0
        ? ac + ((bac - ev) / compositeDenom)
        : bac;

    // ── P2.4: Risk-based EAC calculation ──
    double totalRiskEmv = 0;
    if (riskFactors != null && riskFactors.isNotEmpty) {
      for (final risk in riskFactors) {
        totalRiskEmv += risk.emv;
      }
    }
    // Risk-adjusted EAC = CPI-based EAC + total risk EMV
    final eacRiskAdjusted = eacCpi + totalRiskEmv;

    // Confidence range: ±15% for formula, ±25% for risk-based
    final rangeFactor = methodology == 'riskBased' ? 0.25 : 0.15;
    final eacLow = eacCpi * (1 - rangeFactor);
    final eacHigh = eacRiskAdjusted * (1 + rangeFactor);

    // IEAC (Independent Estimate at Completion) — simple statistical:
    // Average of CPI-based and composite EAC
    final ieac = (eacCpi + eacComposite) / 2;

    // Enhanced confidence: considers CPI/SPI deviation AND risk exposure
    final baseConfidence = _computeConfidence(cpi, spi);
    final riskPenalty = totalRiskEmv > 0
        ? (totalRiskEmv / bac).clamp(0, 0.3) // Max 30% confidence penalty from risk
        : 0;
    final confidence = (baseConfidence - riskPenalty).clamp(0, 1);

    if (methodology == 'manual' && manualEac != null) {
      final eac = manualEac;
      return ForecastResult(
        eac: eac,
        etc: eac - ac,
        vac: bac - eac,
        tcpii: _computeTcpii(bac, ev, ac),
        tcpis: _computeTcpis(bac, ev, eac, ac),
        methodology: 'manual',
        forecastDate: DateTime.now(),
        confidenceLevel: 0.5,
        eacLow: eac * 0.9,
        eacHigh: eac * 1.1,
        eacComposite: eacComposite,
        eacRiskAdjusted: eacRiskAdjusted,
        totalRiskEmv: totalRiskEmv,
        ieac: ieac,
      );
    }

    if (methodology == 'riskBased') {
      // ── P2.4: Risk-based forecasting now fully implemented ──
      final eac = eacRiskAdjusted;
      return ForecastResult(
        eac: eac,
        etc: eac - ac,
        vac: bac - eac,
        tcpii: _computeTcpii(bac, ev, ac),
        tcpis: _computeTcpis(bac, ev, eac, ac),
        methodology: 'riskBased',
        forecastDate: DateTime.now(),
        confidenceLevel: confidence,
        eacLow: eacLow,
        eacHigh: eacHigh,
        eacComposite: eacComposite,
        eacRiskAdjusted: eacRiskAdjusted,
        totalRiskEmv: totalRiskEmv,
        ieac: ieac,
      );
    }

    if (methodology == 'composite') {
      return ForecastResult(
        eac: eacComposite,
        etc: eacComposite - ac,
        vac: bac - eacComposite,
        tcpii: _computeTcpii(bac, ev, ac),
        tcpis: _computeTcpis(bac, ev, eacComposite, ac),
        methodology: 'composite',
        forecastDate: DateTime.now(),
        confidenceLevel: confidence,
        eacLow: eacLow,
        eacHigh: eacHigh,
        eacComposite: eacComposite,
        eacRiskAdjusted: eacRiskAdjusted,
        totalRiskEmv: totalRiskEmv,
        ieac: ieac,
      );
    }

    // Default: CPI-based formula
    final eac = eacCpi;
    return ForecastResult(
      eac: eac,
      etc: eac - ac,
      vac: bac - eac,
      tcpii: _computeTcpii(bac, ev, ac),
      tcpis: _computeTcpis(bac, ev, eac, ac),
      methodology: methodology,
      forecastDate: DateTime.now(),
      confidenceLevel: confidence,
      eacLow: eacLow,
      eacHigh: eacHigh,
      eacComposite: eacComposite,
      eacRiskAdjusted: eacRiskAdjusted,
      totalRiskEmv: totalRiskEmv,
      ieac: ieac,
    );
  }

  static double _computeTcpii(double bac, double ev, double ac) {
    return (bac - ac) > 0 ? (bac - ev) / (bac - ac) : 1.0;
  }

  static double _computeTcpis(double bac, double ev, double eac, double ac) {
    return (eac - ac) > 0 ? (bac - ev) / (eac - ac) : 1.0;
  }

  /// Enhanced confidence heuristic: considers CPI/SPI deviation.
  /// Closer to 1.0 = higher confidence.
  static double _computeConfidence(double cpi, double spi) {
    final cpiConf = 1.0 - (cpi - 1.0).abs();
    final spiConf = 1.0 - (spi - 1.0).abs();
    return ((cpiConf + spiConf) / 2).clamp(0, 1);
  }
}
