// ═══════════════════════════════════════════════════════════
//  EMOTIONAL MEMORY MODEL
//  Aggregated emotional intelligence for personalised AI.
//  Built from ChatProvider's rolling emotion history.
// ═══════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'chat_message.dart';

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

  const EmotionalProfile({
    this.dominantEmotion,
    this.daysSinceLastVisit = 0,
    this.emotionCounts = const {},
    this.anxietyMentions = 0,
    this.stressMentions = 0,
    this.sleepMentions = 0,
    this.periodMentions = 0,
    this.hasPositiveStreak = false,
  });

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
      EmotionTag.happy || EmotionTag.energetic =>
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
        'emotionCounts':
            emotionCounts.map((k, v) => MapEntry(k.name, v)),
        'anxietyMentions': anxietyMentions,
        'stressMentions': stressMentions,
        'sleepMentions': sleepMentions,
        'periodMentions': periodMentions,
        'hasPositiveStreak': hasPositiveStreak,
      };

  factory EmotionalProfile.fromJson(Map<String, dynamic> j) =>
      EmotionalProfile(
        dominantEmotion: j['dominantEmotion'] != null
            ? EmotionTag.values.firstWhere(
                (e) => e.name == j['dominantEmotion'],
                orElse: () => EmotionTag.neutral)
            : null,
        daysSinceLastVisit: (j['daysSinceLastVisit'] as num?)?.toInt() ?? 0,
        emotionCounts:
            (j['emotionCounts'] as Map<String, dynamic>? ?? {}).map(
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
      );
}

