import 'package:flutter/foundation.dart';
import 'chat_message.dart';

// ══════════════════════════════════════════════════════════════
//  DEEP MEMORY — persistent emotional memory model
//  Stores meaningful emotional moments across sessions/weeks/months
// ══════════════════════════════════════════════════════════════

enum MemoryCategory {
  anxiety,
  stress,
  relationship,
  breakup,
  sleep,
  confidence,
  pregnancy,
  victory,
  grief,
  family,
  work,
  loneliness,
  health,
  general,
}

extension MemoryCategoryX on MemoryCategory {
  String get emoji {
    switch (this) {
      case MemoryCategory.anxiety:
        return '💙';
      case MemoryCategory.stress:
        return '🌧️';
      case MemoryCategory.relationship:
        return '💔';
      case MemoryCategory.breakup:
        return '💔';
      case MemoryCategory.sleep:
        return '😴';
      case MemoryCategory.confidence:
        return '🌱';
      case MemoryCategory.pregnancy:
        return '🌸';
      case MemoryCategory.victory:
        return '✨';
      case MemoryCategory.grief:
        return '🕊️';
      case MemoryCategory.family:
        return '🏠';
      case MemoryCategory.work:
        return '💼';
      case MemoryCategory.loneliness:
        return '🌙';
      case MemoryCategory.health:
        return '💗';
      case MemoryCategory.general:
        return '💜';
    }
  }

  String get label {
    switch (this) {
      case MemoryCategory.anxiety:
        return 'Anxiety';
      case MemoryCategory.stress:
        return 'Stress';
      case MemoryCategory.relationship:
        return 'Relationship';
      case MemoryCategory.breakup:
        return 'Heartbreak';
      case MemoryCategory.sleep:
        return 'Sleep';
      case MemoryCategory.confidence:
        return 'Self-Worth';
      case MemoryCategory.pregnancy:
        return 'Pregnancy';
      case MemoryCategory.victory:
        return 'Victory';
      case MemoryCategory.grief:
        return 'Grief';
      case MemoryCategory.family:
        return 'Family';
      case MemoryCategory.work:
        return 'Work';
      case MemoryCategory.loneliness:
        return 'Loneliness';
      case MemoryCategory.health:
        return 'Health';
      case MemoryCategory.general:
        return 'Feeling';
    }
  }
}

// ── Main memory entry ────────────────────────────────────────

@immutable
class DeepMemory {
  final String id;
  final MemoryCategory category;

  /// Short natural-language summary of what happened (e.g. "Went through a breakup").
  final String summary;

  /// Original trimmed user text (max 300 chars).
  final String rawText;
  final DateTime timestamp;
  final EmotionTag emotionTag;

  /// 0.0–1.0 — how emotionally significant this moment is.
  final double significance;

  /// True when user has indicated they have healed/improved from this.
  final bool isResolved;

  const DeepMemory({
    required this.id,
    required this.category,
    required this.summary,
    required this.rawText,
    required this.timestamp,
    required this.emotionTag,
    this.significance = 0.5,
    this.isResolved = false,
  });

  DeepMemory copyWith({
    String? summary,
    bool? isResolved,
  }) =>
      DeepMemory(
        id: id,
        category: category,
        summary: summary ?? this.summary,
        rawText: rawText,
        timestamp: timestamp,
        emotionTag: emotionTag,
        significance: significance,
        isResolved: isResolved ?? this.isResolved,
      );

  // ── Serialization ──────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'summary': summary,
        'rawText': rawText,
        'timestamp': timestamp.toIso8601String(),
        'emotionTag': emotionTag.name,
        'significance': significance,
        'isResolved': isResolved,
      };

  factory DeepMemory.fromJson(Map<String, dynamic> j) => DeepMemory(
        id: (j['id'] as String?) ?? '',
        category: MemoryCategory.values.firstWhere(
          (e) => e.name == j['category'],
          orElse: () => MemoryCategory.general,
        ),
        summary: (j['summary'] as String?) ?? '',
        rawText: (j['rawText'] as String?) ?? '',
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ??
            DateTime.now(),
        emotionTag: EmotionTag.values.firstWhere(
          (e) => e.name == j['emotionTag'],
          orElse: () => EmotionTag.neutral,
        ),
        significance: (j['significance'] as num?)?.toDouble() ?? 0.5,
        isResolved: (j['isResolved'] as bool?) ?? false,
      );

  // ── Display helpers ────────────────────────────────────────

  /// e.g. "3 days ago", "2 weeks ago"
  String get timeAgoLabel {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 14) return 'Last week';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()} weeks ago';
    if (diff.inDays < 60) return 'Last month';
    if (diff.inDays < 365) return '${(diff.inDays / 30).round()} months ago';
    return '${(diff.inDays / 365).round()} year(s) ago';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DeepMemory && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
