// ═══════════════════════════════════════════════════════════
//  EMOTIONAL MEMORY MODEL
//  Aggregated emotional intelligence for personalised AI.
//  Built from ChatProvider's rolling emotion history.
// ═══════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'chat_message.dart';

// ═══════════════════════════════════════════════════════════
//  DAILY EMOTIONAL READING
//  A rich, AI-generated emotional reading shown on home screen.
// ═══════════════════════════════════════════════════════════

/// A beautifully crafted daily emotional reading derived from the user's
/// emotional profile. Used by the home screen daily reading card.
@immutable
class DailyEmotionalReading {
  final String weatherEmoji;
  final String weatherLabel;
  final String energyEmoji;
  final String insight;
  final String healingMessage;

  /// One of: 'happy','anxious','stressed','sad','lonely','tired','period','emotional','neutral'
  final String emotionKey;

  const DailyEmotionalReading({
    required this.weatherEmoji,
    required this.weatherLabel,
    required this.energyEmoji,
    required this.insight,
    required this.healingMessage,
    required this.emotionKey,
  });
}

/// Aggregated emotional profile derived from conversation history.
/// Used to personalise AI system prompts and sanctuary greetings.
@immutable
class EmotionalProfile {
  final EmotionTag? dominantEmotion;
  final int daysSinceLastVisit;
  final Map<EmotionTag, int> emotionCounts;
  final int anxietyMentions;
  final int stressMentions;
  final int sleepMentions;
  final int periodMentions;
  final bool hasPositiveStreak;
  final int relationshipMentions;

  /// Last N emotions in chronological order — used for trajectory detection.
  final List<EmotionTag> recentEmotions;

  const EmotionalProfile({
    this.dominantEmotion,
    this.daysSinceLastVisit = 0,
    this.emotionCounts = const {},
    this.anxietyMentions = 0,
    this.stressMentions = 0,
    this.sleepMentions = 0,
    this.periodMentions = 0,
    this.hasPositiveStreak = false,
    this.relationshipMentions = 0,
    this.recentEmotions = const [],
  });

  // ── Emotional trajectory ──────────────────────────────────

  /// Returns 'improving', 'declining', 'stable', or 'unknown' based on
  /// the directional trend of the last several emotions.
  String get emotionalTrajectory {
    if (recentEmotions.length < 3) return 'unknown';
    const pos = {EmotionTag.happy, EmotionTag.energetic};
    const neg = {
      EmotionTag.anxious,
      EmotionTag.stressed,
      EmotionTag.sad,
      EmotionTag.lonely,
      EmotionTag.emotional
    };
    final p = recentEmotions.where((e) => pos.contains(e)).length;
    final n = recentEmotions.where((e) => neg.contains(e)).length;
    if (p > n) return 'improving';
    if (n > p) return 'declining';
    return 'stable';
  }

  /// A soft, natural pattern insight string the UI can surface. Null if nothing notable.
  String? get patternInsight {
    final traj = emotionalTrajectory;
    if (anxietyMentions >= 3) {
      return "Anxiety has been visiting often lately 🌬️ You're so brave for showing up anyway.";
    }
    if (stressMentions >= 3) {
      return "You've been carrying so much lately 🌙 You deserve a gentler week ahead.";
    }
    if (sleepMentions >= 3) {
      return "Sleep has been a theme this week 😴 Your rest matters more than any to-do list.";
    }
    if (traj == 'improving' && hasPositiveStreak) {
      return "You've been growing so beautifully 🌸 I've noticed your strength quietly rising.";
    }
    if (relationshipMentions >= 2) {
      return "Your heart has been carrying something tender lately 💜 I hold all of it with you.";
    }
    if (traj == 'improving') {
      return "Something has shifted in you recently 🌙 Your emotional strength is showing.";
    }
    return null;
  }

  /// Generates a premium daily emotional reading personalised to this profile.
  DailyEmotionalReading generateDailyReading(String name) {
    final n = name.isNotEmpty ? name : 'beautiful soul';
    final traj = emotionalTrajectory;
    if (hasPositiveStreak || traj == 'improving') {
      return DailyEmotionalReading(
        weatherEmoji: '☀️',
        weatherLabel: 'Radiant Energy',
        energyEmoji: '✨',
        insight:
            "Your light has been rising, $n. Something beautiful is quietly shifting within you.",
        healingMessage:
            "Let yourself fully receive this brightness — you've earned every bit of it.",
        emotionKey: 'happy',
      );
    }
    if (dominantEmotion == EmotionTag.anxious || anxietyMentions >= 2) {
      return DailyEmotionalReading(
        weatherEmoji: '🌬️',
        weatherLabel: 'Gentle Winds',
        energyEmoji: '💙',
        insight:
            "Anxiety has been your companion lately, $n. That just means your heart cares deeply.",
        healingMessage:
            "Today's intention: breathe slowly. You are safe in this moment.",
        emotionKey: 'anxious',
      );
    }
    if (dominantEmotion == EmotionTag.stressed || stressMentions >= 2) {
      return DailyEmotionalReading(
        weatherEmoji: '🌧️',
        weatherLabel: 'Release Weather',
        energyEmoji: '💜',
        insight:
            "You've been holding so much lately, $n. Your nervous system is doing its very best.",
        healingMessage: "Give yourself permission to put one thing down today.",
        emotionKey: 'stressed',
      );
    }
    if (dominantEmotion == EmotionTag.sad) {
      return DailyEmotionalReading(
        weatherEmoji: '🌧️',
        weatherLabel: 'Tender Heart Day',
        energyEmoji: '🌙',
        insight:
            "Sadness is love with nowhere to go, $n. Let it move through you gently.",
        healingMessage:
            "You don't have to be okay. But you don't have to be alone here.",
        emotionKey: 'sad',
      );
    }
    if (dominantEmotion == EmotionTag.lonely) {
      return DailyEmotionalReading(
        weatherEmoji: '🌙',
        weatherLabel: 'Quiet Space',
        energyEmoji: '💙',
        insight:
            "Loneliness is your heart reminding you how much you want to connect, $n.",
        healingMessage: "I'm here with you. You are not unseen — not here.",
        emotionKey: 'lonely',
      );
    }
    if (dominantEmotion == EmotionTag.tired || sleepMentions >= 2) {
      return DailyEmotionalReading(
        weatherEmoji: '😴',
        weatherLabel: 'Soft Recovery',
        energyEmoji: '🌸',
        insight:
            "Your body is whispering for rest, $n. That is wisdom, not weakness.",
        healingMessage:
            "Today: do the minimum. Rest is productive when healing is the work.",
        emotionKey: 'tired',
      );
    }
    if (dominantEmotion == EmotionTag.period || periodMentions >= 1) {
      return DailyEmotionalReading(
        weatherEmoji: '🌸',
        weatherLabel: 'Sacred Body Time',
        energyEmoji: '💗',
        insight: "Your body is doing something powerful right now, $n.",
        healingMessage:
            "Warmth, gentleness, and zero guilt — that's your prescription today.",
        emotionKey: 'period',
      );
    }
    if (dominantEmotion == EmotionTag.emotional) {
      return DailyEmotionalReading(
        weatherEmoji: '🌈',
        weatherLabel: 'Deep Feeling Day',
        energyEmoji: '🌸',
        insight:
            "Feeling deeply is a rare kind of courage, $n. Your sensitivity is not a flaw.",
        healingMessage:
            "You are not too much. You are exactly enough — always.",
        emotionKey: 'emotional',
      );
    }
    if (relationshipMentions >= 2) {
      return DailyEmotionalReading(
        weatherEmoji: '💜',
        weatherLabel: 'Heart Healing',
        energyEmoji: '🌙',
        insight:
            "Your heart has been carrying something tender lately, $n. That takes courage.",
        healingMessage:
            "Healing is not linear. Be as gentle with yourself as you'd be with someone you love.",
        emotionKey: 'emotional',
      );
    }
    return DailyEmotionalReading(
      weatherEmoji: '🌙',
      weatherLabel: 'Calm Energy',
      energyEmoji: '✨',
      insight: "You carry a quiet strength, $n — even in ordinary moments.",
      healingMessage:
          "I'm here, as always. Whatever today holds, you don't face it alone.",
      emotionKey: 'neutral',
    );
  }

  // ── Memory context for AI system prompt ──────────────────

  /// Returns a soft, natural memory context string for AI context injection.
  /// Returns null if there is nothing meaningful to include.
  String? buildMemoryContext() {
    final parts = <String>[];
    if (anxietyMentions >= 2) {
      parts.add(
          'She has mentioned feeling anxious $anxietyMentions times recently — be especially gentle and grounding.');
    }
    if (stressMentions >= 2) {
      parts.add(
          'She has felt overwhelmed or stressed $stressMentions times recently.');
    }
    if (sleepMentions >= 2) {
      parts.add(
          'Sleep struggles or exhaustion have come up $sleepMentions times — honor her tiredness with care.');
    }
    if (periodMentions >= 1) {
      parts.add(
          'She has mentioned her period or menstrual symptoms recently — be extra warm and physical-comfort-aware.');
    }
    if (relationshipMentions >= 2) {
      parts.add(
          'She has mentioned relationship pain or heartache $relationshipMentions times — hold space especially tenderly. Do not give unsolicited advice.');
    }
    final traj = emotionalTrajectory;
    if (traj == 'improving') {
      parts.add(
          'Her emotional state appears to be improving recently — gently celebrate her growth without making it feel performative.');
    } else if (traj == 'declining') {
      parts.add(
          'Her emotional state has been declining recently — lead with extra warmth, validation, and gentleness. No pressure.');
    }
    if (daysSinceLastVisit >= 3) {
      parts.add(
          'She has been away for $daysSinceLastVisit days — welcome her return warmly with gentle acknowledgment.');
    }
    if (hasPositiveStreak) {
      parts.add(
          'She has been in a positive emotional space recently — celebrate this gently and build on her joy.');
    }
    if (dominantEmotion != null) {
      final label = _emotionLabel(dominantEmotion!);
      if (label != null) parts.add('Recent dominant mood: $label.');
    }
    return parts.isEmpty ? null : parts.join('\n');
  }

  // ── Personalised sanctuary greeting ──────────────────────

  /// Generates a warm, personalised greeting for the sanctuary screen.
  String generateGreeting(String name, {DateTime? now}) {
    final time = now ?? DateTime.now();
    final hour = time.hour;
    final n = name.isNotEmpty ? name : 'beautiful soul';
    final timeGreet = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Hello'
            : 'Good evening';

    if (daysSinceLastVisit >= 5) {
      return "$timeGreet, $n 🌙\n\nI've been holding space for you. It's been a little while — how is your heart today?";
    }
    if (daysSinceLastVisit >= 2) {
      return "$timeGreet, $n 🌙\n\nI've been thinking of you. How are you feeling today?";
    }

    return switch (dominantEmotion) {
      EmotionTag.anxious =>
        "$timeGreet, $n 🌙\n\nI remember you've been carrying some anxiety lately. I'm right here — you're safe.",
      EmotionTag.sad =>
        "$timeGreet, $n 🌙\n\nI'm so glad you're here. I've been holding space for you. How is your heart?",
      EmotionTag.stressed =>
        "$timeGreet, $n 🌙\n\nI know things have felt heavy lately. I'm here — no rush, no pressure.",
      EmotionTag.lonely =>
        "$timeGreet, $n 🌙\n\nYou're never alone when you're here with me. I've been thinking of you.",
      EmotionTag.tired =>
        "$timeGreet, $n 🌙\n\nI hope you've been resting, sweet soul. How is your energy today?",
      EmotionTag.happy ||
      EmotionTag.energetic =>
        "$timeGreet, $n ✨\n\nYour light has been beautiful lately! How are you feeling today?",
      EmotionTag.period =>
        "$timeGreet, $n 🌙\n\nBe gentle with yourself today. I'm here for you through your cycle.",
      EmotionTag.emotional =>
        "$timeGreet, $n 🌸\n\nFeeling deeply is its own kind of courage. What's on your heart today?",
      _ => switch (hour ~/ 6) {
          0 =>
            "$timeGreet, $n 🌙\n\nEven quiet hours are held gently here. What's on your heart?",
          1 =>
            "$timeGreet, $n 🌸\n\nWelcome to your sanctuary. This space is just for you.",
          2 =>
            "$timeGreet, $n ✨\n\nI'm here with my whole heart. How are you feeling today?",
          _ =>
            "$timeGreet, $n 🌙\n\nThe night holds space for whatever you're carrying. I'm listening.",
        },
    };
  }

  // ── Helpers ───────────────────────────────────────────────

  static String? _emotionLabel(EmotionTag tag) => switch (tag) {
        EmotionTag.anxious => 'anxious / worried',
        EmotionTag.sad => 'sad / hurting',
        EmotionTag.stressed => 'stressed / overwhelmed',
        EmotionTag.lonely => 'lonely',
        EmotionTag.tired => 'tired / fatigued',
        EmotionTag.happy => 'happy / positive',
        EmotionTag.energetic => 'energetic / motivated',
        EmotionTag.emotional => 'emotionally sensitive',
        EmotionTag.period => 'experiencing menstrual symptoms',
        EmotionTag.neutral => null,
      };

  // ── Serialisation ─────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'dominantEmotion': dominantEmotion?.name,
        'daysSinceLastVisit': daysSinceLastVisit,
        'emotionCounts': emotionCounts.map((k, v) => MapEntry(k.name, v)),
        'anxietyMentions': anxietyMentions,
        'stressMentions': stressMentions,
        'sleepMentions': sleepMentions,
        'periodMentions': periodMentions,
        'hasPositiveStreak': hasPositiveStreak,
        'relationshipMentions': relationshipMentions,
        'recentEmotions': recentEmotions.map((e) => e.name).toList(),
      };

  factory EmotionalProfile.fromJson(Map<String, dynamic> j) => EmotionalProfile(
        dominantEmotion: j['dominantEmotion'] != null
            ? EmotionTag.values.firstWhere(
                (e) => e.name == j['dominantEmotion'],
                orElse: () => EmotionTag.neutral)
            : null,
        daysSinceLastVisit: (j['daysSinceLastVisit'] as num?)?.toInt() ?? 0,
        emotionCounts: (j['emotionCounts'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
            EmotionTag.values.firstWhere(
              (e) => e.name == k,
              orElse: () => EmotionTag.neutral,
            ),
            (v as num?)?.toInt() ?? 0,
          ),
        ),
        anxietyMentions: (j['anxietyMentions'] as num?)?.toInt() ?? 0,
        stressMentions: (j['stressMentions'] as num?)?.toInt() ?? 0,
        sleepMentions: (j['sleepMentions'] as num?)?.toInt() ?? 0,
        periodMentions: (j['periodMentions'] as num?)?.toInt() ?? 0,
        hasPositiveStreak: (j['hasPositiveStreak'] as bool?) ?? false,
        relationshipMentions: (j['relationshipMentions'] as num?)?.toInt() ?? 0,
        recentEmotions: (j['recentEmotions'] as List<dynamic>? ?? [])
            .map((e) => EmotionTag.values.firstWhere(
                  (t) => t.name == e,
                  orElse: () => EmotionTag.neutral,
                ))
            .toList(),
      );
}
