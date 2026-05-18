import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════
//  SYMPTOM LOG
// ══════════════════════════════════════════════════════════════

class SymptomLog {
  final String id;
  final DateTime date;
  final List<String> symptoms;
  final int severity; // 1–5
  final String? note;
  final int? cycleDay;

  const SymptomLog({
    required this.id,
    required this.date,
    required this.symptoms,
    this.severity = 3,
    this.note,
    this.cycleDay,
  });

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'symptoms': symptoms,
        'severity': severity,
        'note': note,
        'cycleDay': cycleDay,
      };

  factory SymptomLog.fromMap(
          Map<String, dynamic> map, String docId) =>
      SymptomLog(
        id: docId,
        date: (map['date'] as Timestamp).toDate(),
        symptoms: List<String>.from(map['symptoms'] ?? []),
        severity: (map['severity'] as int?) ?? 3,
        note: map['note'] as String?,
        cycleDay: map['cycleDay'] as int?,
      );
}

// ══════════════════════════════════════════════════════════════
//  SYMPTOM ANALYSIS — recurring pattern summary
// ══════════════════════════════════════════════════════════════

class SymptomAnalysis {
  /// symptom name → how often it appears (0.0–1.0 fraction of logged days)
  final Map<String, double> frequencyMap;

  /// symptom name → avg cycle day it appears on
  final Map<String, double> cycleDayMap;

  /// top recurring symptoms in order
  final List<String> topSymptoms;

  const SymptomAnalysis({
    this.frequencyMap = const {},
    this.cycleDayMap = const {},
    this.topSymptoms = const [],
  });
}
