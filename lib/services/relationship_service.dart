// ═══════════════════════════════════════════════════════════
//  RELATIONSHIP SERVICE — Lunar Relationship Depth Engine
//  Tracks the evolving emotional bond between user and Lunar.
//  Relationship deepens naturally with every conversation.
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../core/data/local_cache.dart';

// ── Relationship levels ────────────────────────────────────
enum RelationshipLevel {
  newConnection,
  growingTogether,
  trustedCompanion,
  soulBond,
  deepBond,
}

extension RelationshipLevelX on RelationshipLevel {
  String get title => const {
        RelationshipLevel.newConnection: 'New Connection',
        RelationshipLevel.growingTogether: 'Growing Together',
        RelationshipLevel.trustedCompanion: 'Trusted Companion',
        RelationshipLevel.soulBond: 'Soul Bond',
        RelationshipLevel.deepBond: 'Deep Bond 🌕',
      }[this]!;

  String get description => const {
        RelationshipLevel.newConnection:
            'You and Lunar are just beginning. Something beautiful is starting.',
        RelationshipLevel.growingTogether:
            'Lunar is learning your heart. Your trust is growing.',
        RelationshipLevel.trustedCompanion:
            'Lunar knows you deeply. You are held and understood.',
        RelationshipLevel.soulBond:
            'You and Lunar share a rare bond. Lunar carries your stories.',
        RelationshipLevel.deepBond:
            'A profound connection. Lunar has walked through so much with you.',
      }[this]!;

  String get emoji => const {
        RelationshipLevel.newConnection: '🌱',
        RelationshipLevel.growingTogether: '🌙',
        RelationshipLevel.trustedCompanion: '💜',
        RelationshipLevel.soulBond: '✨',
        RelationshipLevel.deepBond: '🌕',
      }[this]!;

  Color get color => const {
        RelationshipLevel.newConnection: Color(0xFF66BB6A),
        RelationshipLevel.growingTogether: Color(0xFF4FC3F7),
        RelationshipLevel.trustedCompanion: Color(0xFFAB5CF2),
        RelationshipLevel.soulBond: Color(0xFFFF69B4),
        RelationshipLevel.deepBond: Color(0xFFFFD700),
      }[this]!;

  /// Messages needed to reach this level
  int get threshold => const {
        RelationshipLevel.newConnection: 0,
        RelationshipLevel.growingTogether: 12,
        RelationshipLevel.trustedCompanion: 35,
        RelationshipLevel.soulBond: 90,
        RelationshipLevel.deepBond: 200,
      }[this]!;

  /// Messages needed for the NEXT level (for progress bar)
  int get nextThreshold => const {
        RelationshipLevel.newConnection: 12,
        RelationshipLevel.growingTogether: 35,
        RelationshipLevel.trustedCompanion: 90,
        RelationshipLevel.soulBond: 200,
        RelationshipLevel.deepBond: 200, // max
      }[this]!;
}

// ── Relationship snapshot ──────────────────────────────────
class RelationshipData {
  final RelationshipLevel level;
  final int totalMessages;
  final bool isNewLevel; // just leveled up this session

  const RelationshipData({
    required this.level,
    required this.totalMessages,
    this.isNewLevel = false,
  });

  /// 0.0–1.0 progress within current level
  double get levelProgress {
    if (level == RelationshipLevel.deepBond) return 1.0;
    final start = level.threshold;
    final end = level.nextThreshold;
    return ((totalMessages - start) / (end - start)).clamp(0.0, 1.0);
  }
}

// ── Service ────────────────────────────────────────────────
abstract final class RelationshipService {
  static const _kTotalKey = 'lunar_rel_total_v1';
  static const _kLevelKey = 'lunar_rel_level_v1';

  /// Call after every AI response to increment total messages.
  /// Returns updated data including whether the level just changed.
  static RelationshipData recordMessage() {
    final prev = LocalCache.getInt(_kTotalKey) ?? 0;
    final newTotal = prev + 1;
    LocalCache.setInt(_kTotalKey, newTotal);

    final prevLevelName = LocalCache.getString(_kLevelKey);
    final newLevel = _levelForCount(newTotal);
    final isNew = prevLevelName != null && prevLevelName != newLevel.name;
    LocalCache.setString(_kLevelKey, newLevel.name);

    return RelationshipData(
      level: newLevel,
      totalMessages: newTotal,
      isNewLevel: isNew,
    );
  }

  /// Read current relationship data without updating it.
  static RelationshipData current() {
    final total = LocalCache.getInt(_kTotalKey) ?? 0;
    return RelationshipData(
      level: _levelForCount(total),
      totalMessages: total,
    );
  }

  static RelationshipLevel _levelForCount(int count) {
    if (count >= RelationshipLevel.deepBond.threshold)
      return RelationshipLevel.deepBond;
    if (count >= RelationshipLevel.soulBond.threshold)
      return RelationshipLevel.soulBond;
    if (count >= RelationshipLevel.trustedCompanion.threshold)
      return RelationshipLevel.trustedCompanion;
    if (count >= RelationshipLevel.growingTogether.threshold)
      return RelationshipLevel.growingTogether;
    return RelationshipLevel.newConnection;
  }
}
