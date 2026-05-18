import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════
//  MOOD LEVEL
// ══════════════════════════════════════════════════════════════

enum MoodLevel { veryLow, low, neutral, good, great }

// ══════════════════════════════════════════════════════════════
//  MOOD ENTRY — a single mood log
// ══════════════════════════════════════════════════════════════

class MoodEntry {
  final String id;
  final DateTime date;
  final MoodLevel level;
  final String emoji;
  final String label;
  final String? note;
  final List<String> emotions;
  final int? cycleDay;

  const MoodEntry({
    required this.id,
    required this.date,
    required this.level,
    required this.emoji,
    required this.label,
    this.note,
    this.emotions = const [],
    this.cycleDay,
  });

  int get score {
    switch (level) {
      case MoodLevel.veryLow:
        return 1;
      case MoodLevel.low:
        return 2;
      case MoodLevel.neutral:
        return 3;
      case MoodLevel.good:
        return 4;
      case MoodLevel.great:
        return 5;
    }
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'level': level.name,
        'emoji': emoji,
        'label': label,
        'note': note,
        'emotions': emotions,
        'cycleDay': cycleDay,
      };

  factory MoodEntry.fromMap(Map<String, dynamic> map, String docId) =>
      MoodEntry(
        id: docId,
        date: (map['date'] as Timestamp).toDate(),
        level: MoodLevel.values.firstWhere(
          (e) => e.name == map['level'],
          orElse: () => MoodLevel.neutral,
        ),
        emoji: (map['emoji'] as String?) ?? '😊',
        label: (map['label'] as String?) ?? 'Okay',
        note: map['note'] as String?,
        emotions: List<String>.from(map['emotions'] ?? []),
        cycleDay: map['cycleDay'] as int?,
      );
}

// ══════════════════════════════════════════════════════════════
//  MOOD TREND — computed analysis from MoodEngine
// ══════════════════════════════════════════════════════════════

class MoodTrend {
  final double averageScore; // 1–5
  final MoodLevel dominantMood;
  final String pattern; // 'stable' | 'improving' | 'declining' | 'fluctuating'
  final List<MoodEntry> recentEntries;
  final Map<int, double> moodByCycleDay; // cycleDay → avg score
  final bool hasPreMenstrualDip;

  const MoodTrend({
    this.averageScore = 3.0,
    this.dominantMood = MoodLevel.neutral,
    this.pattern = 'stable',
    this.recentEntries = const [],
    this.moodByCycleDay = const {},
    this.hasPreMenstrualDip = false,
  });
}
