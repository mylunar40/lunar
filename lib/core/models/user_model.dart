import 'package:cloud_firestore/cloud_firestore.dart';

/// Lunar AI user model — synced to Firestore `users/{uid}` document.
class LunarUserModel {
  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;
  final int cycleLength;
  final DateTime? lastPeriodDate;
  final bool pregnancyMode;
  final bool isPremium;
  final bool isAnonymous;
  final String? authProvider; // 'email' | 'google' | 'apple' | 'anonymous'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LunarUserModel({
    required this.uid,
    this.name,
    this.email,
    this.photoUrl,
    this.cycleLength = 28,
    this.lastPeriodDate,
    this.pregnancyMode = false,
    this.isPremium = false,
    this.isAnonymous = false,
    this.authProvider,
    required this.createdAt,
    this.updatedAt,
  });

  // ── Serialisation ───────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'cycleLength': cycleLength,
        'lastPeriodDate': lastPeriodDate != null
            ? Timestamp.fromDate(lastPeriodDate!)
            : null,
        'pregnancyMode': pregnancyMode,
        'isPremium': isPremium,
        'isAnonymous': isAnonymous,
        'authProvider': authProvider,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  factory LunarUserModel.fromMap(Map<String, dynamic> map, String docId) {
    return LunarUserModel(
      uid: docId,
      name: map['name'] as String?,
      email: map['email'] as String?,
      photoUrl: map['photoUrl'] as String?,
      cycleLength: (map['cycleLength'] as int?) ?? 28,
      lastPeriodDate: map['lastPeriodDate'] != null
          ? (map['lastPeriodDate'] as Timestamp).toDate()
          : null,
      pregnancyMode: (map['pregnancyMode'] as bool?) ?? false,
      isPremium: (map['isPremium'] as bool?) ?? false,
      isAnonymous: (map['isAnonymous'] as bool?) ?? false,
      authProvider: map['authProvider'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  LunarUserModel copyWith({
    String? name,
    String? photoUrl,
    int? cycleLength,
    DateTime? lastPeriodDate,
    bool? pregnancyMode,
    bool? isPremium,
  }) =>
      LunarUserModel(
        uid: uid,
        name: name ?? this.name,
        email: email,
        photoUrl: photoUrl ?? this.photoUrl,
        cycleLength: cycleLength ?? this.cycleLength,
        lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
        pregnancyMode: pregnancyMode ?? this.pregnancyMode,
        isPremium: isPremium ?? this.isPremium,
        isAnonymous: isAnonymous,
        authProvider: authProvider,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
