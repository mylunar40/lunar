/// Represents the user's primary emotional/wellness journey focus.
/// Stored in Firestore as the enum [name] string (e.g. 'breakupRecovery').
enum UserIntent {
  breakupRecovery,
  anxietyStress,
  selfLove,
  relationshipSupport,
  pregnancyJourney,
  cycleWellness,
  emotionalGrowth;

  /// Display label shown in the UI.
  String get label {
    switch (this) {
      case UserIntent.breakupRecovery:
        return 'Breakup Recovery';
      case UserIntent.anxietyStress:
        return 'Anxiety & Stress';
      case UserIntent.selfLove:
        return 'Self-Love Journey';
      case UserIntent.relationshipSupport:
        return 'Relationship Support';
      case UserIntent.pregnancyJourney:
        return 'Pregnancy Journey';
      case UserIntent.cycleWellness:
        return 'Cycle Wellness';
      case UserIntent.emotionalGrowth:
        return 'Emotional Growth';
    }
  }

  /// Emoji associated with this intent.
  String get emoji {
    switch (this) {
      case UserIntent.breakupRecovery:
        return '💔';
      case UserIntent.anxietyStress:
        return '🌬️';
      case UserIntent.selfLove:
        return '💜';
      case UserIntent.relationshipSupport:
        return '🤝';
      case UserIntent.pregnancyJourney:
        return '🌸';
      case UserIntent.cycleWellness:
        return '🌙';
      case UserIntent.emotionalGrowth:
        return '🌱';
    }
  }

  /// Short description shown below the card label.
  String get description {
    switch (this) {
      case UserIntent.breakupRecovery:
        return 'Heal and rediscover yourself';
      case UserIntent.anxietyStress:
        return 'Calm your mind, ease your body';
      case UserIntent.selfLove:
        return 'Reconnect with your worth';
      case UserIntent.relationshipSupport:
        return 'Nurture your connections';
      case UserIntent.pregnancyJourney:
        return 'Support through every trimester';
      case UserIntent.cycleWellness:
        return 'Honor your natural rhythm';
      case UserIntent.emotionalGrowth:
        return 'Grow through every feeling';
    }
  }

  /// Value stored in Firestore (enum name string).
  String get firestoreValue => name;

  /// Parse from Firestore string. Returns null if unrecognised.
  static UserIntent? fromString(String? value) {
    if (value == null) return null;
    try {
      return UserIntent.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}
