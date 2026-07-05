import 'package:flutter/foundation.dart';
import '../data/local_cache.dart';
import '../services/firestore_service.dart';

// ══════════════════════════════════════════════════════════════
//  APP PROVIDER
//  Manages global app-level state that persists across sessions:
//  - Onboarding completion status
//  - First-launch flag
//  - Pregnancy mode
//  - User wellness goals (water, sleep)
//  - Reminder preferences
// ══════════════════════════════════════════════════════════════

class AppProvider extends ChangeNotifier {
  // ── Cache keys ─────────────────────────────────────────────
  static const _kOnboarding = 'onboarding_complete_v1';
  static const _kFirstLaunch = 'first_launch_v1';
  static const _kPregnancyMode = 'pregnancy_mode_v1';
  static const _kWaterGoal = 'water_goal_v1';
  static const _kSleepGoal = 'sleep_goal_v1';
  static const _kReminders = 'reminders_enabled_v1';
  static const _kReminderHour = 'reminder_hour_v1';
  static const _kReminderMin = 'reminder_min_v1';
  static const _kUserName = 'user_display_name_v1';
  static const _kEmotionalIntent = 'emotional_intent_v1';

  // ── State ──────────────────────────────────────────────────
  bool _onboardingComplete = false;
  bool _isFirstLaunch = true;
  bool _pregnancyMode = false;
  int _waterGoal = 8;
  double _sleepGoal = 8.0;
  bool _remindersEnabled = false;
  int _reminderHour = 9;
  int _reminderMinute = 0;
  String _userName = '';
  String _emotionalIntent = '';
  bool _isReady = false;

  // ═══════════════════════════════════════════════════════════
  //  GETTERS
  // ═══════════════════════════════════════════════════════════

  bool get onboardingComplete => _onboardingComplete;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get pregnancyMode => _pregnancyMode;
  int get waterGoal => _waterGoal;
  double get sleepGoal => _sleepGoal;
  bool get remindersEnabled => _remindersEnabled;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  String get userName => _userName;
  String get emotionalIntent => _emotionalIntent;
  bool get isReady => _isReady;

  // ═══════════════════════════════════════════════════════════
  //  INIT  (call after LocalCache.init())
  // ═══════════════════════════════════════════════════════════

  Future<void> init() async {
    _onboardingComplete =
        LocalCache.getBool(_kOnboarding) ?? false;
    _isFirstLaunch = LocalCache.getBool(_kFirstLaunch) ?? true;
    _pregnancyMode = LocalCache.getBool(_kPregnancyMode) ?? false;
    _waterGoal = LocalCache.getInt(_kWaterGoal) ?? 8;
    _sleepGoal = LocalCache.getDouble(_kSleepGoal) ?? 8.0;
    _remindersEnabled = LocalCache.getBool(_kReminders) ?? false;
    _reminderHour = LocalCache.getInt(_kReminderHour) ?? 9;
    _reminderMinute = LocalCache.getInt(_kReminderMin) ?? 0;
    _userName = LocalCache.getString(_kUserName) ?? '';
    _emotionalIntent = LocalCache.getString(_kEmotionalIntent) ?? '';
    _isReady = true;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  ONBOARDING
  // ═══════════════════════════════════════════════════════════

  /// Called when user finishes the onboarding flow.
  /// Saves to both local cache and Firestore (if authenticated).
  /// [uid] is optional — if provided, saves to Firestore for cross-device persistence.
  Future<void> completeOnboarding({String? uid}) async {
    _onboardingComplete = true;
    _isFirstLaunch = false;
    await LocalCache.setBool(_kOnboarding, true);
    await LocalCache.setBool(_kFirstLaunch, false);
    
    // Save to Firestore for authenticated users (source of truth for launch flow)
    if (uid != null && uid.isNotEmpty) {
      try {
        await FirestoreService.updateUser(uid, {
          'onboardingCompleted': true,
        });
      } catch (e) {
        debugPrint('[AppProvider] Failed to save onboarding to Firestore: $e');
        // Non-fatal: local cache is still valid
      }
    }
    
    notifyListeners();
  }

  /// Reset onboarding (dev / account reset).
  Future<void> resetOnboarding() async {
    _onboardingComplete = false;
    _isFirstLaunch = true;
    await LocalCache.setBool(_kOnboarding, false);
    await LocalCache.setBool(_kFirstLaunch, true);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  USER PREFERENCES
  // ═══════════════════════════════════════════════════════════

  Future<void> setUserName(String name) async {
    _userName = name;
    await LocalCache.setString(_kUserName, name);
    notifyListeners();
  }

  Future<void> setEmotionalIntent(String intent) async {
    _emotionalIntent = intent;
    await LocalCache.setString(_kEmotionalIntent, intent);
    notifyListeners();
  }

  Future<void> setPregnancyMode(bool value) async {
    _pregnancyMode = value;
    await LocalCache.setBool(_kPregnancyMode, value);
    notifyListeners();
  }

  Future<void> setWaterGoal(int glasses) async {
    _waterGoal = glasses;
    await LocalCache.setInt(_kWaterGoal, glasses);
    notifyListeners();
  }

  Future<void> setSleepGoal(double hours) async {
    _sleepGoal = hours;
    await LocalCache.setDouble(_kSleepGoal, hours);
    notifyListeners();
  }

  Future<void> setReminderEnabled(bool value) async {
    _remindersEnabled = value;
    await LocalCache.setBool(_kReminders, value);
    notifyListeners();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    _reminderHour = hour;
    _reminderMinute = minute;
    await LocalCache.setInt(_kReminderHour, hour);
    await LocalCache.setInt(_kReminderMin, minute);
    notifyListeners();
  }
}
