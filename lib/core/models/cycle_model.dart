import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════
//  CYCLE PHASE ENUM
// ══════════════════════════════════════════════════════════════

enum LunarCyclePhase { period, follicular, ovulation, luteal, unknown }

// ══════════════════════════════════════════════════════════════
//  CYCLE LOG — a single recorded period start
// ══════════════════════════════════════════════════════════════

class CycleLog {
  final String id;
  final DateTime periodStartDate;
  final int cycleLength;    // days to next period
  final int periodDuration; // how many days flow lasted
  final String flow;        // 'light' | 'normal' | 'heavy'
  final DateTime? createdAt;

  const CycleLog({
    required this.id,
    required this.periodStartDate,
    this.cycleLength = 28,
    this.periodDuration = 5,
    this.flow = 'normal',
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'periodStartDate': Timestamp.fromDate(periodStartDate),
        'cycleLength': cycleLength,
        'periodDuration': periodDuration,
        'flow': flow,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  factory CycleLog.fromMap(Map<String, dynamic> map, String docId) => CycleLog(
        id: docId,
        periodStartDate:
            (map['periodStartDate'] as Timestamp).toDate(),
        cycleLength: (map['cycleLength'] as int?) ?? 28,
        periodDuration: (map['periodDuration'] as int?) ?? 5,
        flow: (map['flow'] as String?) ?? 'normal',
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : null,
      );

  CycleLog copyWith({
    int? cycleLength,
    int? periodDuration,
    String? flow,
  }) =>
      CycleLog(
        id: id,
        periodStartDate: periodStartDate,
        cycleLength: cycleLength ?? this.cycleLength,
        periodDuration: periodDuration ?? this.periodDuration,
        flow: flow ?? this.flow,
        createdAt: createdAt,
      );
}

// ══════════════════════════════════════════════════════════════
//  CYCLE ANALYSIS — computed result from CycleEngine
// ══════════════════════════════════════════════════════════════

class CycleAnalysis {
  final int averageCycleLength;
  final int averagePeriodDuration;
  final bool isIrregular;
  final int regularityScore; // 0–100
  final DateTime? nextPeriodDate;
  final DateTime? ovulationDate;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final int currentCycleDay;
  final LunarCyclePhase currentPhase;
  final bool isInPmsWindow;
  final bool isInFertileWindow;

  const CycleAnalysis({
    this.averageCycleLength = 28,
    this.averagePeriodDuration = 5,
    this.isIrregular = false,
    this.regularityScore = 80,
    this.nextPeriodDate,
    this.ovulationDate,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    this.currentCycleDay = 0,
    this.currentPhase = LunarCyclePhase.unknown,
    this.isInPmsWindow = false,
    this.isInFertileWindow = false,
  });
}
