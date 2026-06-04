import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
//  COMMUNITY MODELS — Phase 5: Emotional Safe-Space
//  All enums, models, and constants for the community module.
// ═══════════════════════════════════════════════════════════

// ── SAFE-SPACE CIRCLES ──────────────────────────────────────

enum SafeSpaceCircle {
  anxietyCircle,
  breakupHealing,
  selfLove,
  pregnancySupport,
  womensWellness,
  emotionalRecovery,
}

extension SafeSpaceCircleX on SafeSpaceCircle {
  String get id {
    switch (this) {
      case SafeSpaceCircle.anxietyCircle:
        return 'anxietySupport';
      case SafeSpaceCircle.breakupHealing:
        return 'relationships';
      case SafeSpaceCircle.selfLove:
        return 'selfCare';
      case SafeSpaceCircle.pregnancySupport:
        return 'pregnancy';
      case SafeSpaceCircle.womensWellness:
        return 'periodTalk';
      case SafeSpaceCircle.emotionalRecovery:
        return 'emotionalHealing';
    }
  }

  String get label {
    switch (this) {
      case SafeSpaceCircle.anxietyCircle:
        return 'Anxiety Circle';
      case SafeSpaceCircle.breakupHealing:
        return 'Breakup Healing';
      case SafeSpaceCircle.selfLove:
        return 'Self-Love';
      case SafeSpaceCircle.pregnancySupport:
        return 'Pregnancy Support';
      case SafeSpaceCircle.womensWellness:
        return "Women's Wellness";
      case SafeSpaceCircle.emotionalRecovery:
        return 'Emotional Recovery';
    }
  }

  String get emoji {
    switch (this) {
      case SafeSpaceCircle.anxietyCircle:
        return '🌿';
      case SafeSpaceCircle.breakupHealing:
        return '💔';
      case SafeSpaceCircle.selfLove:
        return '🤍';
      case SafeSpaceCircle.pregnancySupport:
        return '🤰';
      case SafeSpaceCircle.womensWellness:
        return '🌸';
      case SafeSpaceCircle.emotionalRecovery:
        return '🌙';
    }
  }

  String get description {
    switch (this) {
      case SafeSpaceCircle.anxietyCircle:
        return 'A gentle space to breathe and be heard.';
      case SafeSpaceCircle.breakupHealing:
        return 'Healing hearts, one day at a time.';
      case SafeSpaceCircle.selfLove:
        return 'Reclaim your worth and inner light.';
      case SafeSpaceCircle.pregnancySupport:
        return 'Journey together, mama to mama.';
      case SafeSpaceCircle.womensWellness:
        return 'Honour every phase of your cycle.';
      case SafeSpaceCircle.emotionalRecovery:
        return 'Rise gently from the dark places.';
    }
  }

  Color get color {
    switch (this) {
      case SafeSpaceCircle.anxietyCircle:
        return const Color(0xFF4FC3F7); // teal
      case SafeSpaceCircle.breakupHealing:
        return const Color(0xFFFF69B4); // pink
      case SafeSpaceCircle.selfLove:
        return const Color(0xFFAB5CF2); // purple
      case SafeSpaceCircle.pregnancySupport:
        return const Color(0xFFFFD700); // gold
      case SafeSpaceCircle.womensWellness:
        return const Color(0xFFFF8A65); // warm orange
      case SafeSpaceCircle.emotionalRecovery:
        return const Color(0xFF7986CB); // indigo
    }
  }

  List<Color> get gradientColors => [
        color.withOpacity(0.85),
        color.withOpacity(0.40),
      ];
}

// ── HEALING REACTIONS ───────────────────────────────────────

enum HealingReaction {
  iUnderstand,
  sendingSupport,
  stayStrong,
  youAreNotAlone,
}

extension HealingReactionX on HealingReaction {
  String get id {
    switch (this) {
      case HealingReaction.iUnderstand:
        return 'iUnderstand';
      case HealingReaction.sendingSupport:
        return 'sendingSupport';
      case HealingReaction.stayStrong:
        return 'stayStrong';
      case HealingReaction.youAreNotAlone:
        return 'youAreNotAlone';
    }
  }

  String get emoji {
    switch (this) {
      case HealingReaction.iUnderstand:
        return '💜';
      case HealingReaction.sendingSupport:
        return '🌙';
      case HealingReaction.stayStrong:
        return '✨';
      case HealingReaction.youAreNotAlone:
        return '🤍';
    }
  }

  String get label {
    switch (this) {
      case HealingReaction.iUnderstand:
        return 'I Understand';
      case HealingReaction.sendingSupport:
        return 'Sending Support';
      case HealingReaction.stayStrong:
        return 'Stay Strong';
      case HealingReaction.youAreNotAlone:
        return 'You Are Not Alone';
    }
  }

  String get shortLabel {
    switch (this) {
      case HealingReaction.iUnderstand:
        return 'Understand';
      case HealingReaction.sendingSupport:
        return 'Support';
      case HealingReaction.stayStrong:
        return 'Strong';
      case HealingReaction.youAreNotAlone:
        return 'Not Alone';
    }
  }

  Color get color {
    switch (this) {
      case HealingReaction.iUnderstand:
        return const Color(0xFFAB5CF2);
      case HealingReaction.sendingSupport:
        return const Color(0xFF4FC3F7);
      case HealingReaction.stayStrong:
        return const Color(0xFFFFD700);
      case HealingReaction.youAreNotAlone:
        return const Color(0xFFFF69B4);
    }
  }
}

// ── POST TYPE ───────────────────────────────────────────────

enum CommunityPostType {
  regular,
  checkIn,
  healingStory,
  voiceVent,
  anonymousShare,
}

extension CommunityPostTypeX on CommunityPostType {
  String get id {
    switch (this) {
      case CommunityPostType.regular:
        return 'regular';
      case CommunityPostType.checkIn:
        return 'checkIn';
      case CommunityPostType.healingStory:
        return 'healingStory';
      case CommunityPostType.voiceVent:
        return 'voiceVent';
      case CommunityPostType.anonymousShare:
        return 'anonymousShare';
    }
  }

  String get label {
    switch (this) {
      case CommunityPostType.regular:
        return 'Sharing';
      case CommunityPostType.checkIn:
        return 'Check-In';
      case CommunityPostType.healingStory:
        return 'Healing Story';
      case CommunityPostType.voiceVent:
        return 'Voice Vent';
      case CommunityPostType.anonymousShare:
        return 'Anonymous Share';
    }
  }

  String get emoji {
    switch (this) {
      case CommunityPostType.regular:
        return '💭';
      case CommunityPostType.checkIn:
        return '📋';
      case CommunityPostType.healingStory:
        return '🌟';
      case CommunityPostType.voiceVent:
        return '🎤';
      case CommunityPostType.anonymousShare:
        return '🌙';
    }
  }

  static CommunityPostType fromId(String id) {
    return CommunityPostType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => CommunityPostType.regular,
    );
  }
}

// ── DAILY CHECK-IN PROMPTS ──────────────────────────────────

class CheckInPrompt {
  final String id;
  final String question;
  final String emoji;
  final String circle;

  const CheckInPrompt({
    required this.id,
    required this.question,
    required this.emoji,
    required this.circle,
  });
}

const List<CheckInPrompt> kDailyCheckInPrompts = [
  CheckInPrompt(
    id: 'p01',
    question: 'How are you feeling right now, honestly?',
    emoji: '🌙',
    circle: 'all',
  ),
  CheckInPrompt(
    id: 'p02',
    question: 'What challenged you emotionally today?',
    emoji: '🌿',
    circle: 'emotionalHealing',
  ),
  CheckInPrompt(
    id: 'p03',
    question: 'One thing you are proud of yourself for this week?',
    emoji: '✨',
    circle: 'selfCare',
  ),
  CheckInPrompt(
    id: 'p04',
    question: 'What emotion have you been carrying without telling anyone?',
    emoji: '💜',
    circle: 'emotionalHealing',
  ),
  CheckInPrompt(
    id: 'p05',
    question: 'How is your body feeling today?',
    emoji: '🌸',
    circle: 'periodTalk',
  ),
  CheckInPrompt(
    id: 'p06',
    question: 'If your heart could speak right now, what would it say?',
    emoji: '🤍',
    circle: 'relationships',
  ),
  CheckInPrompt(
    id: 'p07',
    question: 'What do you need most from yourself today?',
    emoji: '🌟',
    circle: 'selfCare',
  ),
  CheckInPrompt(
    id: 'p08',
    question: 'What fear did you face this week?',
    emoji: '🌿',
    circle: 'anxietySupport',
  ),
  CheckInPrompt(
    id: 'p09',
    question: 'How are you growing through this season of your life?',
    emoji: '🌙',
    circle: 'emotionalHealing',
  ),
  CheckInPrompt(
    id: 'p10',
    question: 'What kindness did you give or receive today?',
    emoji: '💜',
    circle: 'all',
  ),
  CheckInPrompt(
    id: 'p11',
    question: 'How is your inner voice speaking to you lately?',
    emoji: '✨',
    circle: 'selfCare',
  ),
  CheckInPrompt(
    id: 'p12',
    question: 'What would healing look like for you today?',
    emoji: '🌸',
    circle: 'emotionalHealing',
  ),
  CheckInPrompt(
    id: 'p13',
    question: 'What are you allowing yourself to let go of?',
    emoji: '🤍',
    circle: 'relationships',
  ),
  CheckInPrompt(
    id: 'p14',
    question: 'How are you being gentle with yourself today?',
    emoji: '🌙',
    circle: 'selfCare',
  ),
];

// ── VOICE VENT (Future-Ready Architecture) ──────────────────

class VoiceVentData {
  final String postId;
  final String? audioUrl;
  final int durationSeconds;
  final bool isAvailable;

  const VoiceVentData({
    required this.postId,
    this.audioUrl,
    this.durationSeconds = 0,
    this.isAvailable = false,
  });

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'audioUrl': audioUrl,
        'durationSeconds': durationSeconds,
        'isAvailable': isAvailable,
      };

  factory VoiceVentData.fromJson(Map<String, dynamic> json) => VoiceVentData(
        postId: json['postId'] as String? ?? '',
        audioUrl: json['audioUrl'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        isAvailable: json['isAvailable'] as bool? ?? false,
      );
}

// ── COMMUNITY AWARD ─────────────────────────────────────────

enum CommunityAward {
  kindHeart,
  healingPresence,
  lunarGuide,
  moonkeeper,
}

extension CommunityAwardX on CommunityAward {
  String get emoji {
    switch (this) {
      case CommunityAward.kindHeart:
        return '💜';
      case CommunityAward.healingPresence:
        return '🌙';
      case CommunityAward.lunarGuide:
        return '✨';
      case CommunityAward.moonkeeper:
        return '🌟';
    }
  }

  String get label {
    switch (this) {
      case CommunityAward.kindHeart:
        return 'Kind Heart';
      case CommunityAward.healingPresence:
        return 'Healing Presence';
      case CommunityAward.lunarGuide:
        return 'Lunar Guide';
      case CommunityAward.moonkeeper:
        return 'Moonkeeper';
    }
  }

  String get description {
    switch (this) {
      case CommunityAward.kindHeart:
        return 'You have started spreading warmth.';
      case CommunityAward.healingPresence:
        return 'Your support touches many hearts.';
      case CommunityAward.lunarGuide:
        return 'You are a beacon of light here.';
      case CommunityAward.moonkeeper:
        return 'You hold this safe space with love.';
    }
  }

  Color get color {
    switch (this) {
      case CommunityAward.kindHeart:
        return const Color(0xFFAB5CF2);
      case CommunityAward.healingPresence:
        return const Color(0xFF4FC3F7);
      case CommunityAward.lunarGuide:
        return const Color(0xFFFFD700);
      case CommunityAward.moonkeeper:
        return const Color(0xFFFF69B4);
    }
  }

  static CommunityAward forCount(int n) {
    if (n >= 100) return CommunityAward.moonkeeper;
    if (n >= 30) return CommunityAward.lunarGuide;
    if (n >= 10) return CommunityAward.healingPresence;
    return CommunityAward.kindHeart;
  }
}
