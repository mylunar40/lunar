import '../models/mood_model.dart';

// ══════════════════════════════════════════════════════════════
//  MOOD ENGINE — pure emotional pattern analysis
// ══════════════════════════════════════════════════════════════

abstract final class MoodEngine {
  /// Compute a full [MoodTrend] from a list of logged entries.
  static MoodTrend analyze(List<MoodEntry> entries) {
    if (entries.isEmpty) return const MoodTrend();

    // Sort descending
    final sorted = [...entries]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = sorted.take(14).toList();

    // Average score
    final avgScore =
        recent.map((e) => e.score).reduce((a, b) => a + b) /
            recent.length;

    // Dominant mood
    final counts = <MoodLevel, int>{};
    for (final e in recent) {
      counts[e.level] = (counts[e.level] ?? 0) + 1;
    }
    final dominant = counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    // Pattern
    final pattern = _detectPattern(recent);

    // Mood by cycle day
    final byCycleDay = <int, List<double>>{};
    for (final e in entries) {
      if (e.cycleDay != null) {
        byCycleDay
            .putIfAbsent(e.cycleDay!, () => [])
            .add(e.score.toDouble());
      }
    }
    final moodByCycleDay = byCycleDay.map((day, scores) =>
        MapEntry(
            day, scores.reduce((a, b) => a + b) / scores.length));

    final pmsDip = _hasPreMenstrualDip(moodByCycleDay);

    return MoodTrend(
      averageScore: avgScore,
      dominantMood: dominant,
      pattern: pattern,
      recentEntries: recent,
      moodByCycleDay: moodByCycleDay,
      hasPreMenstrualDip: pmsDip,
    );
  }

  /// True if moods on days 21–28 are notably lower than days 7–14.
  static bool _hasPreMenstrualDip(Map<int, double> moodByCycleDay) {
    if (moodByCycleDay.isEmpty) return false;
    final early = <double>[], late = <double>[];
    moodByCycleDay.forEach((day, score) {
      if (day >= 7 && day <= 14) early.add(score);
      if (day >= 21 && day <= 28) late.add(score);
    });
    if (early.isEmpty || late.isEmpty) return false;
    final earlyAvg = early.reduce((a, b) => a + b) / early.length;
    final lateAvg = late.reduce((a, b) => a + b) / late.length;
    return earlyAvg - lateAvg > 0.8;
  }

  static String _detectPattern(List<MoodEntry> recent) {
    if (recent.length < 4) return 'stable';
    final half = recent.length ~/ 2;
    final older = recent.skip(half).map((e) => e.score);
    final newer = recent.take(half).map((e) => e.score);
    final olderAvg =
        older.reduce((a, b) => a + b) / older.length;
    final newerAvg =
        newer.reduce((a, b) => a + b) / newer.length;
    final diff = newerAvg - olderAvg;
    if (diff > 0.5) return 'improving';
    if (diff < -0.5) return 'declining';
    // Check variance for fluctuating
    final scores =
        recent.map((e) => e.score.toDouble()).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores
            .map((s) => (s - avg) * (s - avg))
            .reduce((a, b) => a + b) /
        scores.length;
    if (variance > 1.5) return 'fluctuating';
    return 'stable';
  }
}
