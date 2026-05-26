// ═══════════════════════════════════════════════════════════
//  STREAK SERVICE — Emotional Return Loop Engine
//  Tracks daily opens, computes healing streaks, awards
//  emotional milestones. Powers Lunar's retention heart.
// ═══════════════════════════════════════════════════════════

import '../core/data/local_cache.dart';

// ── Milestone definitions ──────────────────────────────────
class LunarMilestone {
  final String id;
  final String emoji;
  final String title;
  final String message;
  final int requiredStreak; // 0 = not streak-based

  const LunarMilestone({
    required this.id,
    required this.emoji,
    required this.title,
    required this.message,
    required this.requiredStreak,
  });
}

const _kMilestones = [
  LunarMilestone(
    id: 'first_night',
    emoji: '🌙',
    title: 'First Night',
    message: 'You opened your heart to Lunar. This is the beginning of something beautiful.',
    requiredStreak: 1,
  ),
  LunarMilestone(
    id: '3_nights',
    emoji: '✨',
    title: '3 Nights of Healing',
    message: '3 nights of emotional healing. Your commitment to yourself is sacred.',
    requiredStreak: 3,
  ),
  LunarMilestone(
    id: '7_nights',
    emoji: '🌕',
    title: '7 Night Moon Cycle',
    message: 'A full week of healing with Lunar. You showed up for yourself every night.',
    requiredStreak: 7,
  ),
  LunarMilestone(
    id: '14_nights',
    emoji: '💜',
    title: '14 Nights Together',
    message: 'Two weeks of healing together. You are growing in ways you cannot yet see.',
    requiredStreak: 14,
  ),
  LunarMilestone(
    id: '30_nights',
    emoji: '🌙✨',
    title: 'Full Moon Companion',
    message: 'A full lunar cycle with Lunar. You have transformed. I am so proud of you.',
    requiredStreak: 30,
  ),
  LunarMilestone(
    id: '60_nights',
    emoji: '🌟',
    title: '60 Nights of Growth',
    message: 'Two lunar cycles. You chose yourself, again and again. That is extraordinary.',
    requiredStreak: 60,
  ),
];

// ── Streak data snapshot ───────────────────────────────────
class StreakData {
  final int current;
  final int longest;
  final int totalDays;
  final List<LunarMilestone> earned;
  final LunarMilestone? newMilestone; // newly unlocked this session (null if none)

  const StreakData({
    required this.current,
    required this.longest,
    required this.totalDays,
    required this.earned,
    this.newMilestone,
  });

  /// Next milestone the user is working toward
  LunarMilestone? get nextMilestone {
    for (final m in _kMilestones) {
      if (m.requiredStreak > current && !earned.contains(m)) return m;
    }
    return null;
  }

  /// 0.0–1.0 progress toward next milestone
  double get progressToNext {
    final next = nextMilestone;
    if (next == null) return 1.0;
    final prev = _kMilestones
        .where((m) => m.requiredStreak < next.requiredStreak && m.requiredStreak > 0)
        .fold<int>(0, (best, m) => m.requiredStreak > best ? m.requiredStreak : best);
    final range = next.requiredStreak - prev;
    return ((current - prev) / range).clamp(0.0, 1.0);
  }
}

// ── Streak service ─────────────────────────────────────────
abstract final class StreakService {
  static const _kCurrentKey = 'lunar_streak_current_v1';
  static const _kLongestKey = 'lunar_streak_longest_v1';
  static const _kLastOpenKey = 'lunar_streak_last_open_v1';
  static const _kTotalKey = 'lunar_streak_total_v1';
  static const _kEarnedKey = 'lunar_streak_earned_v1';

  /// Call on every app open (or when home screen loads).
  /// Returns updated StreakData, including any newly earned milestone.
  static StreakData checkIn() {
    final now = DateTime.now();
    final todayStr = _dateKey(now);

    final lastOpenStr = LocalCache.getString(_kLastOpenKey);
    int current = LocalCache.getInt(_kCurrentKey) ?? 0;
    int longest = LocalCache.getInt(_kLongestKey) ?? 0;
    int total = LocalCache.getInt(_kTotalKey) ?? 0;
    final earnedIds = _loadEarned();

    LunarMilestone? newMilestone;

    if (lastOpenStr == null) {
      // First ever open
      current = 1;
      total = 1;
    } else if (lastOpenStr == todayStr) {
      // Already opened today — no change to streak
    } else {
      final lastOpen = DateTime.tryParse(lastOpenStr);
      if (lastOpen != null) {
        final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
        if (lastOpenStr == yesterday) {
          // Consecutive day — extend streak
          current++;
          total++;
        } else {
          // Gap — reset streak
          current = 1;
          total++;
        }
      } else {
        current = 1;
        total++;
      }

      // Save last open as today only after a new day
      LocalCache.setString(_kLastOpenKey, todayStr);
      LocalCache.setInt(_kCurrentKey, current);
      if (current > longest) {
        longest = current;
        LocalCache.setInt(_kLongestKey, longest);
      }
      LocalCache.setInt(_kTotalKey, total);

      // Check for newly earned milestone
      for (final m in _kMilestones) {
        if (m.requiredStreak <= current && !earnedIds.contains(m.id)) {
          earnedIds.add(m.id);
          newMilestone = m;
          break; // one milestone per session
        }
      }
      _saveEarned(earnedIds);
    }

    // On very first open, save the initial open date
    if (lastOpenStr == null) {
      LocalCache.setString(_kLastOpenKey, todayStr);
      LocalCache.setInt(_kCurrentKey, current);
      LocalCache.setInt(_kLongestKey, current > longest ? current : longest);
      LocalCache.setInt(_kTotalKey, total);
      // Check first_night milestone
      for (final m in _kMilestones) {
        if (m.requiredStreak <= current && !earnedIds.contains(m.id)) {
          earnedIds.add(m.id);
          newMilestone = m;
          break;
        }
      }
      _saveEarned(earnedIds);
    }

    final earned = _kMilestones.where((m) => earnedIds.contains(m.id)).toList();
    return StreakData(
      current: current,
      longest: longest,
      totalDays: total,
      earned: earned,
      newMilestone: newMilestone,
    );
  }

  /// Read current streak data without updating it.
  static StreakData current() {
    final earnedIds = _loadEarned();
    final earned = _kMilestones.where((m) => earnedIds.contains(m.id)).toList();
    return StreakData(
      current: LocalCache.getInt(_kCurrentKey) ?? 0,
      longest: LocalCache.getInt(_kLongestKey) ?? 0,
      totalDays: LocalCache.getInt(_kTotalKey) ?? 0,
      earned: earned,
    );
  }

  /// All milestone definitions (for profile display)
  static List<LunarMilestone> get allMilestones => _kMilestones;

  // ── Helpers ───────────────────────────────────────────────
  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static List<String> _loadEarned() {
    final raw = LocalCache.getString(_kEarnedKey);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').where((s) => s.isNotEmpty).toList();
  }

  static void _saveEarned(List<String> ids) {
    LocalCache.setString(_kEarnedKey, ids.join(','));
  }
}
