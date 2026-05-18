// ═══════════════════════════════════════════════════════════
//  CHAT MESSAGE MODEL
//  Serialisable model for Lunar AI chat history persistence.
// ═══════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

// ── Message type ──────────────────────────────────────────
enum ChatMsgType { text, healingCard }

// ── Healing card kind ─────────────────────────────────────
enum HealingKind { breathe, affirmation, sleep, hydrate, cycle, gentle }

// ── Emotion tags (for memory system) ─────────────────────
enum EmotionTag {
  anxious,
  sad,
  lonely,
  stressed,
  happy,
  energetic,
  tired,
  emotional,
  period,
  neutral,
}

// ── Message model ─────────────────────────────────────────
@immutable
class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final ChatMsgType type;
  final HealingKind? healing;
  final DateTime timestamp;
  final EmotionTag? emotionTag;

  const ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.type = ChatMsgType.text,
    this.healing,
    required this.timestamp,
    this.emotionTag,
  });

  // ── Factories ──────────────────────────────────────────

  factory ChatMessage.user(String text, {EmotionTag? emotionTag}) {
    return ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}_u',
      isUser: true,
      text: text,
      timestamp: DateTime.now(),
      emotionTag: emotionTag,
    );
  }

  factory ChatMessage.ai(String text,
      {HealingKind? healing, EmotionTag? emotionTag}) {
    return ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}_a',
      isUser: false,
      text: text,
      healing: healing,
      timestamp: DateTime.now(),
      emotionTag: emotionTag,
    );
  }

  factory ChatMessage.healingCard(HealingKind kind) {
    return ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}_h',
      isUser: false,
      text: '',
      type: ChatMsgType.healingCard,
      healing: kind,
      timestamp: DateTime.now(),
    );
  }

  // ── Serialisation ──────────────────────────────────────

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      isUser: json['isUser'] as bool,
      text: json['text'] as String,
      type: ChatMsgType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatMsgType.text,
      ),
      healing: json['healing'] == null
          ? null
          : HealingKind.values.firstWhere(
              (e) => e.name == json['healing'],
              orElse: () => HealingKind.gentle,
            ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      emotionTag: json['emotionTag'] == null
          ? null
          : EmotionTag.values.firstWhere(
              (e) => e.name == json['emotionTag'],
              orElse: () => EmotionTag.neutral,
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'isUser': isUser,
        'text': text,
        'type': type.name,
        if (healing != null) 'healing': healing!.name,
        'timestamp': timestamp.toIso8601String(),
        if (emotionTag != null) 'emotionTag': emotionTag!.name,
      };
}
