// ═══════════════════════════════════════════════════════════
//  CHECK-IN PROVIDER
//  Manages daily mood check-ins, healing streak, milestone
//  detection, Firestore sync, and AI personalisation helpers.
// ═══════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../models/check_in_model.dart';
import '../models/user_intent.dart';
import '../data/local_cache.dart';

class CheckInProvider extends ChangeNotifier {
  // ── Cache keys ─────────────────────────────────────────────
  static const _kTodayDate = 'checkin_today_date_v1';
  static const _kTodayMood = 'checkin_today_mood_v1';
  static const _kTodaySecondary = 'checkin_today_secondary_v1';
  static const _kStreakCurrent = 'checkin_streak_current_v1';
  static const _kStreakLongest = 'checkin_streak_longest_v1';
  static const _kLastDate = 'checkin_streak_last_date_v1';
  static const _kMilestonesEarned = 'checkin_milestones_earned_v1';

  // ── State ──────────────────────────────────────────────────
  CheckInEntry? _todayEntry;
  int _streakDays = 0;
  int _longestStreak = 0;
  DateTime? _lastCheckInDate;
  List<String> _earnedMilestoneIds = [];
  CheckInMilestone? _newMilestone; // shown once then cleared
  String? _firestoreUid;

  // ── Public Getters ─────────────────────────────────────────
  CheckInEntry? get todayEntry => _todayEntry;
  bool get hasTodayCheckIn => _todayEntry != null;
  int get streakDays => _streakDays;
  int get longestStreak => _longestStreak;
  DateTime? get lastCheckIn => _lastCheckInDate;
  CheckInMilestone? get newMilestone => _newMilestone;
  List<String> get earnedMilestoneIds => List.unmodifiable(_earnedMilestoneIds);

  // ── AI personalisation helpers ─────────────────────────────
  /// Current mood state (null if no check-in today).
  CheckInMood? get currentMood => _todayEntry?.mood;

  /// Human-readable streak label for greeting personalisation.
  String get streakLabel => _streakDays > 0 ? '$_streakDays-Day' : '';

  // ── Init ────────────────────────────────────────────────────
  Future<void> init() async {
    final todayKey = _dateKey(DateTime.now());
    final storedDate = LocalCache.getString(_kTodayDate);
    if (storedDate == todayKey) {
      // Already checked in today — restore
      final mood = CheckInMood.fromString(LocalCache.getString(_kTodayMood));
      if (mood != null) {
        _todayEntry = CheckInEntry(
          date: DateTime.now(),
          mood: mood,
          secondaryReason: LocalCache.getString(_kTodaySecondary),
        );
      }
    }
    _streakDays = LocalCache.getInt(_kStreakCurrent) ?? 0;
    _longestStreak = LocalCache.getInt(_kStreakLongest) ?? 0;
    final lastDateStr = LocalCache.getString(_kLastDate);
    _lastCheckInDate =
        lastDateStr != null ? DateTime.tryParse(lastDateStr) : null;
    _earnedMilestoneIds = _loadEarnedIds();
    notifyListeners();
  }

  /// Called by ChangeNotifierProxyProvider when auth state changes.
  void setUser(String? uid) {
    if (uid == _firestoreUid) return;
    _firestoreUid = uid;
  }

  // ── Submit Check-In ─────────────────────────────────────────
  /// Primary action: record today's mood.
  /// [secondary] can be added afterward via [updateSecondary].
  Future<CheckInMilestone?> submitCheckIn(
    CheckInMood mood, {
    UserIntent? intent,
  }) async {
    final now = DateTime.now();
    final todayKey = _dateKey(now);

    // Idempotent — already checked in today
    if (_dateKey(now) == LocalCache.getString(_kTodayDate)) {
      return null;
    }

    _todayEntry = CheckInEntry(date: now, mood: mood);

    // Persist mood
    await LocalCache.setString(_kTodayDate, todayKey);
    await LocalCache.setString(_kTodayMood, mood.name);

    // Update streak (2-day grace)
    final prevStreak = _streakDays;
    _updateStreak(now);

    // Milestone check
    _newMilestone = _checkMilestone(_streakDays);

    // Save last check-in date
    _lastCheckInDate = now;
    await LocalCache.setString(_kLastDate, now.toIso8601String());

    notifyListeners();

    // Analytics (best-effort)
    _logAnalytics('check_in_completed', {
      'mood': mood.name,
      'streak_days': _streakDays,
      if (intent != null) 'intent': intent.name,
    });

    if (prevStreak == 0 && _streakDays == 1) {
      _logAnalytics('streak_started', {'intent': intent?.name ?? ''});
    }

    if (_newMilestone != null) {
      _logAnalytics('milestone_reached', {
        'milestone_id': _newMilestone!.id,
        'streak_days': _streakDays,
      });
    }

    // Firestore sync (best-effort)
    _syncToFirestore(todayKey, mood, null);

    return _newMilestone;
  }

  /// Update secondary reason after initial check-in.
  Future<void> updateSecondary(String reason) async {
    if (_todayEntry == null) return;
    _todayEntry = CheckInEntry(
      date: _todayEntry!.date,
      mood: _todayEntry!.mood,
      secondaryReason: reason,
    );
    await LocalCache.setString(_kTodaySecondary, reason);
    notifyListeners();

    // Sync updated secondary to Firestore
    final todayKey = _dateKey(DateTime.now());
    _syncToFirestore(todayKey, _todayEntry!.mood, reason);
  }

  /// Call after the milestone celebration card has been shown.
  void clearNewMilestone() {
    _newMilestone = null;
    notifyListeners();
  }

  // ── Streak Logic (2-day grace) ──────────────────────────────
  void _updateStreak(DateTime now) {
    if (_lastCheckInDate == null) {
      // First ever check-in
      _streakDays = 1;
    } else {
      final diff = _daysBetween(_lastCheckInDate!, now);
      if (diff <= 2) {
        // 0 = same day (shouldn't happen), 1 = yesterday, 2 = grace day
        _streakDays++;
      } else {
        // 2+ days missed → reset
        if (_streakDays > 1) {
          _logAnalytics('streak_lost', {'streak_days': _streakDays});
        }
        _streakDays = 1;
      }
    }

    if (_streakDays > _longestStreak) {
      _longestStreak = _streakDays;
      LocalCache.setInt(_kStreakLongest, _longestStreak);
    }
    LocalCache.setInt(_kStreakCurrent, _streakDays);
  }

  CheckInMilestone? _checkMilestone(int days) {
    for (final m in kCheckInMilestones) {
      if (m.requiredDays == days && !_earnedMilestoneIds.contains(m.id)) {
        _earnedMilestoneIds.add(m.id);
        _saveEarnedIds();
        return m;
      }
    }
    return null;
  }

  // ── Firestore Sync (best-effort) ────────────────────────────
  void _syncToFirestore(
      String dateKey, CheckInMood mood, String? secondary) async {
    final uid = _firestoreUid;
    if (uid == null || uid.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('check_ins')
          .doc(uid)
          .collection('entries')
          .doc(dateKey)
          .set({
        'mood': mood.name,
        'secondaryReason': secondary,
        'streakDays': _streakDays,
        'date': Timestamp.fromDate(DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[CheckIn] Firestore sync error (non-blocking): $e');
    }
  }

  // ── Analytics (best-effort) ─────────────────────────────────
  void _logAnalytics(
      String eventName, Map<String, Object> parameters) async {
    try {
      await FirebaseAnalytics.instance
          .logEvent(name: eventName, parameters: parameters);
    } catch (e) {
      debugPrint('[CheckIn] Analytics error (non-blocking): $e');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────
  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static int _daysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  List<String> _loadEarnedIds() {
    final raw = LocalCache.getString(_kMilestonesEarned);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').where((s) => s.isNotEmpty).toList();
  }

  void _saveEarnedIds() {
    LocalCache.setString(_kMilestonesEarned, _earnedMilestoneIds.join(','));
  }

  // ── Intent-aware secondary questions ────────────────────────
  static String secondaryQuestion(UserIntent? intent) {
    switch (intent) {
      case UserIntent.breakupRecovery:
        return 'What is helping you most today?';
      case UserIntent.anxietyStress:
        return 'How is your mind feeling?';
      case UserIntent.selfLove:
        return 'What feels true about yourself today?';
      case UserIntent.relationshipSupport:
        return 'What feels heavy today?';
      case UserIntent.pregnancyJourney:
        return 'How are you and baby feeling today?';
      case UserIntent.cycleWellness:
        return 'How is your energy today?';
      case UserIntent.emotionalGrowth:
        return 'What is alive in you today?';
      default:
        return 'What feels most true right now?';
    }
  }

  static List<String> secondaryOptions(UserIntent? intent) {
    switch (intent) {
      case UserIntent.breakupRecovery:
        return ['Being alone', 'Talking to someone', 'Keeping busy', 'Just coping'];
      case UserIntent.anxietyStress:
        return ['Racing thoughts', 'Pretty calm', 'Tense body', 'Just tired'];
      case UserIntent.selfLove:
        return ['I\'m doing okay', 'Being hard on myself', 'I feel strong', 'Not sure'];
      case UserIntent.relationshipSupport:
        return ['Missing them', 'Feeling disconnected', 'Wanting support', 'I\'m okay'];
      case UserIntent.pregnancyJourney:
        return ['Excited', 'Tired', 'Anxious', 'Content'];
      case UserIntent.cycleWellness:
        return ['High energy', 'Low energy', 'Balanced', 'Hormonal waves'];
      case UserIntent.emotionalGrowth:
        return ['Hope', 'Heaviness', 'Clarity', 'Confusion'];
      default:
        return ['I\'m managing', 'I need support', 'I feel strong', 'I\'m unsure'];
    }
  }

  // ── Intent-aware encouragement (post-check-in) ──────────────
  static String encouragement(UserIntent? intent, CheckInMood mood) {
    if (mood == CheckInMood.struggling) {
      switch (intent) {
        case UserIntent.breakupRecovery:
          return 'Broken hearts still beat. You\'re here.';
        case UserIntent.anxietyStress:
          return 'Small calm moments matter. You made one today.';
        case UserIntent.pregnancyJourney:
          return 'Growing life is hard. You\'re doing it anyway.';
        case UserIntent.cycleWellness:
          return 'Listening to your body is progress.';
        default:
          return 'Showing up when it\'s hard — that\'s strength.';
      }
    }
    switch (intent) {
      case UserIntent.breakupRecovery:
        return 'You showed up for yourself today. 💜';
      case UserIntent.anxietyStress:
        return 'Small calm moments matter.';
      case UserIntent.pregnancyJourney:
        return 'Every day is part of your journey.';
      case UserIntent.cycleWellness:
        return 'Listening to your body is progress.';
      case UserIntent.selfLove:
        return 'Choosing yourself — one day at a time.';
      case UserIntent.relationshipSupport:
        return 'Connection starts with how you show up for you.';
      case UserIntent.emotionalGrowth:
        return 'Every feeling you honor makes you stronger.';
      default:
        return 'You showed up. That always matters. 💜';
    }
  }
}
