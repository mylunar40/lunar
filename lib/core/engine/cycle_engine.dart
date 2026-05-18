import '../models/cycle_model.dart';

// ══════════════════════════════════════════════════════════════
//  CYCLE ENGINE — pure, stateless cycle mathematics
// ══════════════════════════════════════════════════════════════

abstract final class CycleEngine {
  // ── Day & Phase ────────────────────────────────────────────

  /// Returns 1-based cycle day relative to [lastPeriodDate].
  static int cycleDay(DateTime lastPeriodDate) {
    final diff =
        DateTime.now().difference(lastPeriodDate).inDays + 1;
    return diff.clamp(1, 35);
  }

  /// Returns the current phase given last period and avg cycle length.
  static LunarCyclePhase currentPhase(
      DateTime lastPeriodDate, int cycleLength) {
    final day = cycleDay(lastPeriodDate);
    if (day <= 5) return LunarCyclePhase.period;
    if (day <= 12) return LunarCyclePhase.follicular;
    final ovDay = _ovulationDay(cycleLength);
    if (day >= ovDay - 1 && day <= ovDay + 1) {
      return LunarCyclePhase.ovulation;
    }
    if (day <= cycleLength) return LunarCyclePhase.luteal;
    return LunarCyclePhase.unknown;
  }

  // ── Date Predictions ───────────────────────────────────────

  static DateTime nextPeriodDate(
          DateTime lastPeriodDate, int avgCycleLength) =>
      lastPeriodDate.add(Duration(days: avgCycleLength));

  static int daysUntilNextPeriod(
      DateTime lastPeriodDate, int avgCycleLength) {
    final diff = nextPeriodDate(lastPeriodDate, avgCycleLength)
        .difference(DateTime.now())
        .inDays;
    return diff < 0 ? 0 : diff;
  }

  static DateTime ovulationDate(
          DateTime lastPeriodDate, int cycleLength) =>
      lastPeriodDate
          .add(Duration(days: _ovulationDay(cycleLength) - 1));

  static DateTime fertileWindowStart(
          DateTime lastPeriodDate, int cycleLength) =>
      lastPeriodDate
          .add(Duration(days: _ovulationDay(cycleLength) - 5));

  static DateTime fertileWindowEnd(
          DateTime lastPeriodDate, int cycleLength) =>
      lastPeriodDate
          .add(Duration(days: _ovulationDay(cycleLength) + 1));

  static bool isInFertileWindow(
      DateTime lastPeriodDate, int cycleLength) {
    final now = DateTime.now();
    return now.isAfter(
            fertileWindowStart(lastPeriodDate, cycleLength)) &&
        now.isBefore(fertileWindowEnd(lastPeriodDate, cycleLength));
  }

  // ── PMS Window ─────────────────────────────────────────────

  /// PMS typically starts 7–10 days before period.
  static bool isInPmsWindow(
      DateTime lastPeriodDate, int cycleLength) {
    final day = cycleDay(lastPeriodDate);
    return day >= (cycleLength - 10) && day < cycleLength;
  }

  // ── Regularity ─────────────────────────────────────────────

  /// True if max deviation between cycle lengths > 7 days.
  static bool isIrregular(List<CycleLog> logs) {
    if (logs.length < 3) return false;
    final lengths = logs.map((l) => l.cycleLength).toList();
    final avg =
        lengths.reduce((a, b) => a + b) / lengths.length;
    final maxDev = lengths
        .map((l) => (l - avg).abs())
        .reduce((a, b) => a > b ? a : b);
    return maxDev > 7;
  }

  static int averageCycleLength(List<CycleLog> logs) {
    if (logs.isEmpty) return 28;
    return (logs.fold(0, (s, l) => s + l.cycleLength) /
            logs.length)
        .round();
  }

  /// Regularity score 0–100 (higher = more regular).
  static int regularityScore(List<CycleLog> logs) {
    if (logs.length < 2) return 80;
    final lengths =
        logs.map((l) => l.cycleLength.toDouble()).toList();
    final avg = lengths.reduce((a, b) => a + b) / lengths.length;
    final variance = lengths
            .map((l) => (l - avg) * (l - avg))
            .reduce((a, b) => a + b) /
        lengths.length;
    final std = _sqrt(variance);
    return (100 - (std * 10)).clamp(0.0, 100.0).round();
  }

  // ── Full Analysis ──────────────────────────────────────────

  static CycleAnalysis analyze(
    DateTime? lastPeriodDate,
    int cycleLength,
    List<CycleLog> logs,
  ) {
    if (lastPeriodDate == null) {
      return const CycleAnalysis(
          currentPhase: LunarCyclePhase.unknown);
    }
    final avgLen =
        logs.isNotEmpty ? averageCycleLength(logs) : cycleLength;
    final day = cycleDay(lastPeriodDate);
    final phase = currentPhase(lastPeriodDate, avgLen);
    final avgDuration = logs.isNotEmpty
        ? (logs.fold(0, (s, l) => s + l.periodDuration) /
                logs.length)
            .round()
        : 5;

    return CycleAnalysis(
      averageCycleLength: avgLen,
      averagePeriodDuration: avgDuration,
      isIrregular: isIrregular(logs),
      regularityScore: regularityScore(logs),
      nextPeriodDate: nextPeriodDate(lastPeriodDate, avgLen),
      ovulationDate: ovulationDate(lastPeriodDate, avgLen),
      fertileWindowStart:
          fertileWindowStart(lastPeriodDate, avgLen),
      fertileWindowEnd: fertileWindowEnd(lastPeriodDate, avgLen),
      currentCycleDay: day,
      currentPhase: phase,
      isInPmsWindow: isInPmsWindow(lastPeriodDate, avgLen),
      isInFertileWindow: isInFertileWindow(lastPeriodDate, avgLen),
    );
  }

  // ── Private helpers ────────────────────────────────────────

  static int _ovulationDay(int cycleLength) => cycleLength - 14;

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double g = x / 2;
    for (int i = 0; i < 20; i++) {
      g = (g + x / g) / 2;
    }
    return g;
  }
}
