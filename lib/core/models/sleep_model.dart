import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════
//  SLEEP LOG
// ══════════════════════════════════════════════════════════════

class SleepLog {
  final String id;
  final DateTime date;
  final double hoursSlept;
  final String quality; // 'poor' | 'fair' | 'good' | 'excellent'
  final DateTime? bedTime;
  final DateTime? wakeTime;
  final String? note;

  const SleepLog({
    required this.id,
    required this.date,
    required this.hoursSlept,
    this.quality = 'good',
    this.bedTime,
    this.wakeTime,
    this.note,
  });

  int get qualityScore {
    switch (quality) {
      case 'poor':
        return 1;
      case 'fair':
        return 2;
      case 'good':
        return 3;
      case 'excellent':
        return 4;
      default:
        return 2;
    }
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'hoursSlept': hoursSlept,
        'quality': quality,
        'bedTime':
            bedTime != null ? Timestamp.fromDate(bedTime!) : null,
        'wakeTime':
            wakeTime != null ? Timestamp.fromDate(wakeTime!) : null,
        'note': note,
      };

  factory SleepLog.fromMap(Map<String, dynamic> map, String docId) =>
      SleepLog(
        id: docId,
        date: (map['date'] as Timestamp).toDate(),
        hoursSlept:
            (map['hoursSlept'] as num?)?.toDouble() ?? 7.0,
        quality: (map['quality'] as String?) ?? 'good',
        bedTime: map['bedTime'] != null
            ? (map['bedTime'] as Timestamp).toDate()
            : null,
        wakeTime: map['wakeTime'] != null
            ? (map['wakeTime'] as Timestamp).toDate()
            : null,
        note: map['note'] as String?,
      );
}
