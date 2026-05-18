import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cycle_model.dart';
import '../data/local_cache.dart';

// ══════════════════════════════════════════════════════════════
//  CYCLE REPOSITORY
//  All public methods are safe even without Firebase configured.
// ══════════════════════════════════════════════════════════════

abstract final class CycleRepository {
  static const _kLogsKey = 'cycle_logs_v1';
  static const _kLastPeriod = 'last_period_date_v1';
  static const _kCycleLen = 'cycle_length_v1';

  // ── Local persistence ──────────────────────────────────────

  static Future<void> saveLastPeriodDate(DateTime date) =>
      LocalCache.setString(_kLastPeriod, date.toIso8601String());

  static DateTime? loadLastPeriodDate() {
    final raw = LocalCache.getString(_kLastPeriod);
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCycleLength(int length) =>
      LocalCache.setInt(_kCycleLen, length);

  static int loadCycleLength() =>
      LocalCache.getInt(_kCycleLen) ?? 28;

  static Future<void> saveCycleLogs(List<CycleLog> logs) {
    final list = logs
        .map((l) => {
              'id': l.id,
              'periodStartDate':
                  l.periodStartDate.toIso8601String(),
              'cycleLength': l.cycleLength,
              'periodDuration': l.periodDuration,
              'flow': l.flow,
            })
        .toList();
    return LocalCache.setJsonList(_kLogsKey, list);
  }

  static List<CycleLog> loadCycleLogs() {
    final raw = LocalCache.getJsonList(_kLogsKey) ?? [];
    return raw.map((m) {
      try {
        return CycleLog(
          id: (m['id'] as String?) ?? '',
          periodStartDate:
              DateTime.parse(m['periodStartDate'] as String),
          cycleLength: (m['cycleLength'] as int?) ?? 28,
          periodDuration: (m['periodDuration'] as int?) ?? 5,
          flow: (m['flow'] as String?) ?? 'normal',
        );
      } catch (_) {
        return null;
      }
    }).whereType<CycleLog>().toList();
  }

  // ── Firestore sync ─────────────────────────────────────────

  static Future<void> pushToFirestore(
      String uid, CycleLog log) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cycles')
          .doc(log.id.isEmpty ? null : log.id)
          .set(log.toMap(), SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<List<CycleLog>> fetchFromFirestore(
      String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cycles')
          .orderBy('periodStartDate', descending: true)
          .limit(24)
          .get();
      return snap.docs
          .map((d) => CycleLog.fromMap(d.data(), d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
