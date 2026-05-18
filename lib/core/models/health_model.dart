import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════
//  HEALTH LOG — daily health snapshot
// ══════════════════════════════════════════════════════════════

class HealthLog {
  final String id;
  final DateTime date;
  final int waterGlasses;
  final double? weightKg;
  final double? tempC;
  final String? energyLevel; // 'low' | 'medium' | 'high'
  final List<String> symptoms;

  const HealthLog({
    required this.id,
    required this.date,
    this.waterGlasses = 0,
    this.weightKg,
    this.tempC,
    this.energyLevel,
    this.symptoms = const [],
  });

  HealthLog copyWith({
    int? waterGlasses,
    double? weightKg,
    double? tempC,
    String? energyLevel,
    List<String>? symptoms,
  }) =>
      HealthLog(
        id: id,
        date: date,
        waterGlasses: waterGlasses ?? this.waterGlasses,
        weightKg: weightKg ?? this.weightKg,
        tempC: tempC ?? this.tempC,
        energyLevel: energyLevel ?? this.energyLevel,
        symptoms: symptoms ?? this.symptoms,
      );

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'waterGlasses': waterGlasses,
        'weightKg': weightKg,
        'tempC': tempC,
        'energyLevel': energyLevel,
        'symptoms': symptoms,
      };

  factory HealthLog.fromMap(Map<String, dynamic> map, String docId) =>
      HealthLog(
        id: docId,
        date: (map['date'] as Timestamp).toDate(),
        waterGlasses: (map['waterGlasses'] as int?) ?? 0,
        weightKg: (map['weightKg'] as num?)?.toDouble(),
        tempC: (map['tempC'] as num?)?.toDouble(),
        energyLevel: map['energyLevel'] as String?,
        symptoms: List<String>.from(map['symptoms'] ?? []),
      );
}
