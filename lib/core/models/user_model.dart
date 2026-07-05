import 'package:cloud_firestore/cloud_firestore.dart';

// ── Subscription tier ─────────────────────────────────────
/// Tracks which paid plan the user is on.
/// [free] = no subscription, [plus] = Lunar Plus, [premium] = Lunar Premium.
enum PlanTier { free, plus, premium }

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

  /// Which paid tier the user is on. Defaults to [PlanTier.free].
  final PlanTier planTier;

  /// When the premium subscription expires. `null` = no expiry (lifetime grant).
  /// Use [isActivePremium] to check combined isPremium + non-expired state.
  final DateTime? premiumExpiresAt;
  final bool isAnonymous;
  final String? authProvider; // 'email' | 'google' | 'apple' | 'anonymous'
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// User's selected journey focus, stored as [UserIntent.name] string.
  final String? userIntent;
  final DateTime? intentSelectedAt;
  final String communityTheme;
  final bool onboardingIntentCompleted;

  /// True when the user has completed the main onboarding flow (cycle setup, goals, etc.).
  /// Stored in Firestore for cross-device persistence.
  final bool onboardingCompleted;

  const LunarUserModel({
    required this.uid,
    this.name,
    this.email,
    this.photoUrl,
    this.cycleLength = 28,
    this.lastPeriodDate,
    this.pregnancyMode = false,
    this.isPremium = false,
    this.planTier = PlanTier.free,
    this.premiumExpiresAt,
    this.isAnonymous = false,
    this.authProvider,
    required this.createdAt,
    this.updatedAt,
    this.userIntent,
    this.intentSelectedAt,
    this.communityTheme = 'lunar',
    this.onboardingIntentCompleted = false,
    this.onboardingCompleted = false,
  });

  /// True when isPremium is set AND the subscription has not yet expired.
  bool get isActivePremium =>
      isPremium &&
      (premiumExpiresAt == null || premiumExpiresAt!.isAfter(DateTime.now()));

  // ── Serialisation ───────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'cycleLength': cycleLength,
        'lastPeriodDate':
            lastPeriodDate != null ? Timestamp.fromDate(lastPeriodDate!) : null,
        'pregnancyMode': pregnancyMode,
        'isPremium': isPremium,
        'planTier': planTier.name,
        'premiumExpiresAt': premiumExpiresAt != null
            ? Timestamp.fromDate(premiumExpiresAt!)
            : null,
        'isAnonymous': isAnonymous,
        'authProvider': authProvider,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'userIntent': userIntent,
        'intentSelectedAt': intentSelectedAt != null
            ? Timestamp.fromDate(intentSelectedAt!)
            : null,
        'communityTheme': communityTheme,
        'onboardingIntentCompleted': onboardingIntentCompleted,
        'onboardingCompleted': onboardingCompleted,
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
      planTier: PlanTier.values.firstWhere(
        (t) => t.name == (map['planTier'] as String?),
        orElse: () => (map['isPremium'] as bool?) == true
            ? PlanTier.premium
            : PlanTier.free,
      ),
      premiumExpiresAt: map['premiumExpiresAt'] != null
          ? (map['premiumExpiresAt'] as Timestamp).toDate()
          : null,
      isAnonymous: (map['isAnonymous'] as bool?) ?? false,
      authProvider: map['authProvider'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      userIntent: map['userIntent'] as String?,
      intentSelectedAt: map['intentSelectedAt'] != null
          ? (map['intentSelectedAt'] as Timestamp).toDate()
          : null,
      communityTheme: map['communityTheme'] as String? ?? 'lunar',
      onboardingIntentCompleted:
          (map['onboardingIntentCompleted'] as bool?) ?? false,
      onboardingCompleted: (map['onboardingCompleted'] as bool?) ?? false,
    );
  }

  LunarUserModel copyWith({
    String? name,
    String? photoUrl,
    int? cycleLength,
    DateTime? lastPeriodDate,
    bool? pregnancyMode,
    bool? isPremium,
    PlanTier? planTier,
    DateTime? premiumExpiresAt,
    String? userIntent,
    DateTime? intentSelectedAt,
    String? communityTheme,
    bool? onboardingIntentCompleted,
    bool? onboardingCompleted,
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
        planTier: planTier ?? this.planTier,
        premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
        isAnonymous: isAnonymous,
        authProvider: authProvider,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        userIntent: userIntent ?? this.userIntent,
        intentSelectedAt: intentSelectedAt ?? this.intentSelectedAt,
        communityTheme: communityTheme ?? this.communityTheme,
        onboardingIntentCompleted:
            onboardingIntentCompleted ?? this.onboardingIntentCompleted,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      );
}
