import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_model.dart';
import '../models/sleep_model.dart';
import '../models/mood_model.dart';
import '../data/local_cache.dart';

// ══════════════════════════════════════════════════════════════
//  HEALTH REPOSITORY
// ══════════════════════════════════════════════════════════════

abstract final class HealthRepository {
  static const _kHealthKey = 'health_today_v2';
  static const _kSleepKey = 'sleep_logs_v1';
  static const _kMoodKey = 'mood_logs_v1';

  // ── Today's health log ─────────────────────────────────────

  static Future<void> saveTodayHealth(HealthLog log) =>
      LocalCache.setJson(_kHealthKey, {
        'date': log.date.toIso8601String(),
        'waterGlasses': log.waterGlasses,
        'weightKg': log.weightKg,
        'tempC': log.tempC,
        'energyLevel': log.energyLevel,
        'symptoms': log.symptoms,
      });

  static HealthLog loadTodayHealth() {
    final json = LocalCache.getJson(_kHealthKey);
    if (json == null) return _freshToday();
    try {
      final date = DateTime.parse(json['date'] as String);
      if (!_sameDay(date, DateTime.now())) return _freshToday();
      return HealthLog(
        id: _todayKey(),
        date: date,
        waterGlasses: (json['waterGlasses'] as int?) ?? 0,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        tempC: (json['tempC'] as num?)?.toDouble(),
        energyLevel: json['energyLevel'] as String?,
        symptoms: List<String>.from(json['symptoms'] ?? []),
      );
    } catch (_) {
      return _freshToday();
    }
  }

  // ── Sleep logs ─────────────────────────────────────────────

  static Future<void> saveSleepLogs(List<SleepLog> logs) {
    final list = logs.take(30).map((l) => {
          'id': l.id,
          'date': l.date.toIso8601String(),
          'hoursSlept': l.hoursSlept,
          'quality': l.quality,
        }).toList();
    return LocalCache.setJsonList(_kSleepKey, list);
  }

  static List<SleepLog> loadSleepLogs() {
    final raw = LocalCache.getJsonList(_kSleepKey) ?? [];
    return raw.map((m) {
      try {
        return SleepLog(
          id: (m['id'] as String?) ?? '',
          date: DateTime.parse(m['date'] as String),
          hoursSlept:
              (m['hoursSlept'] as num?)?.toDouble() ?? 7.0,
          quality: (m['quality'] as String?) ?? 'good',
        );
      } catch (_) {
        return null;
      }
    }).whereType<SleepLog>().toList();
  }

  // ── Mood logs ──────────────────────────────────────────────

  static Future<void> saveMoodEntries(List<MoodEntry> entries) {
    final list = entries.take(90).map((e) => {
          'id': e.id,
          'date': e.date.toIso8601String(),
          'level': e.level.name,
          'emoji': e.emoji,
          'label': e.label,
          'note': e.note,
          'emotions': e.emotions,
          'cycleDay': e.cycleDay,
        }).toList();
    return LocalCache.setJsonList(_kMoodKey, list);
  }

  static List<MoodEntry> loadMoodEntries() {
    final raw = LocalCache.getJsonList(_kMoodKey) ?? [];
    return raw.map((m) {
      try {
        return MoodEntry(
          id: (m['id'] as String?) ?? '',
          date: DateTime.parse(m['date'] as String),
          level: MoodLevel.values.firstWhere(
            (e) => e.name == m['level'],
            orElse: () => MoodLevel.neutral,
          ),
          emoji: (m['emoji'] as String?) ?? '😊',
          label: (m['label'] as String?) ?? 'Okay',
          note: m['note'] as String?,
          emotions: List<String>.from(m['emotions'] ?? []),
          cycleDay: m['cycleDay'] as int?,
        );
      } catch (_) {
        return null;
      }
    }).whereType<MoodEntry>().toList();
  }

  // ── Firestore sync ─────────────────────────────────────────

  static Future<void> pushHealthToFirestore(
      String uid, HealthLog log) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('health_logs')
          .doc(log.id)
          .set(log.toMap(), SetOptions(merge: true));
    } catch (_) {}
  }

  // ── Private helpers ────────────────────────────────────────

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static HealthLog _freshToday() =>
      HealthLog(id: _todayKey(), date: DateTime.now());

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
