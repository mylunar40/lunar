import 'package:flutter/foundation.dart';
import '../models/cycle_model.dart';
import '../models/mood_model.dart';
import '../models/health_model.dart';
import '../models/sleep_model.dart';
import '../models/insight_model.dart';
import '../models/pregnancy_model.dart';
import '../models/journal_model.dart';
import '../engine/cycle_engine.dart';
import '../engine/mood_engine.dart';
import '../engine/insight_engine.dart';
import '../repositories/cycle_repository.dart';
import '../repositories/health_repository.dart';
import '../data/local_cache.dart';

// ══════════════════════════════════════════════════════════════
//  LUNAR DATA PROVIDER
//  Single source of truth for all wellness data in the app.
//  - Loads from local cache instantly on startup
//  - Persists all mutations locally (SharedPreferences)
//  - Syncs to Firestore when uid is available
//  - Exposes computed analytics via CycleEngine, MoodEngine,
//    InsightEngine
// ══════════════════════════════════════════════════════════════

class LunarDataProvider extends ChangeNotifier {
  // ── Cycle ─────────────────────────────────────────────────
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;
  List<CycleLog> _cycleLogs = [];
  CycleAnalysis _cycleAnalysis = const CycleAnalysis();

  // ── Health (today) ────────────────────────────────────────
  HealthLog _todayHealth =
      HealthLog(id: 'today', date: DateTime.now());

  // ── Sleep ─────────────────────────────────────────────────
  List<SleepLog> _sleepLogs = [];

  // ── Mood ──────────────────────────────────────────────────
  List<MoodEntry> _moodEntries = [];
  MoodTrend _moodTrend = const MoodTrend();

  // ── Insights ──────────────────────────────────────────────
  List<AIInsight> _insights = [];

  // ── Pregnancy ─────────────────────────────────────────────
  PregnancyData? _pregnancyData;

  // ── Journals ──────────────────────────────────────────────
  List<JournalEntry> _journalEntries = [];

  // ── State ─────────────────────────────────────────────────
  bool _isLoaded = false;

  // ═══════════════════════════════════════════════════════════
  //  GETTERS — Cycle
  // ═══════════════════════════════════════════════════════════

  DateTime? get lastPeriodDate => _lastPeriodDate;
  int get cycleLength => _cycleLength;
  List<CycleLog> get cycleLogs => List.unmodifiable(_cycleLogs);
  CycleAnalysis get cycleAnalysis => _cycleAnalysis;
  LunarCyclePhase get currentPhase => _cycleAnalysis.currentPhase;
  int get currentCycleDay => _cycleAnalysis.currentCycleDay;
  DateTime? get nextPeriodDate => _cycleAnalysis.nextPeriodDate;
  bool get isInFertileWindow => _cycleAnalysis.isInFertileWindow;
  bool get isInPmsWindow => _cycleAnalysis.isInPmsWindow;
  bool get isIrregular => _cycleAnalysis.isIrregular;

  int get daysUntilNextPeriod => _lastPeriodDate == null
      ? 0
      : CycleEngine.daysUntilNextPeriod(
          _lastPeriodDate!, _cycleLength);

  // ═══════════════════════════════════════════════════════════
  //  GETTERS — Health
  // ═══════════════════════════════════════════════════════════

  HealthLog get todayHealth => _todayHealth;
  int get todayWaterGlasses => _todayHealth.waterGlasses;
  double get lastWeightKg => _todayHealth.weightKg ?? 58.0;
  double get lastTempC => _todayHealth.tempC ?? 36.6;
  String get energyLevel => _todayHealth.energyLevel ?? 'medium';

  // ═══════════════════════════════════════════════════════════
  //  GETTERS — Sleep
  // ═══════════════════════════════════════════════════════════

  List<SleepLog> get sleepLogs => List.unmodifiable(_sleepLogs);
  SleepLog? get lastSleepLog =>
      _sleepLogs.isNotEmpty ? _sleepLogs.first : null;
  double get lastSleepHours =>
      _sleepLogs.isNotEmpty ? _sleepLogs.first.hoursSlept : 7.5;

  // ═══════════════════════════════════════════════════════════
  //  GETTERS — Mood
  // ═══════════════════════════════════════════════════════════

  List<MoodEntry> get moodEntries =>
      List.unmodifiable(_moodEntries);
  MoodTrend get moodTrend => _moodTrend;

  // ═══════════════════════════════════════════════════════════
  //  GETTERS — Insights
  // ═══════════════════════════════════════════════════════════

  List<AIInsight> get insights => List.unmodifiable(_insights);
  AIInsight? get topInsight =>
      _insights.isNotEmpty ? _insights.first : null;

  // ═══════════════════════════════════════════════════════════
  //  GETTERS — Pregnancy
  // ═══════════════════════════════════════════════════════════

  PregnancyData? get pregnancyData => _pregnancyData;
  bool get isPregnant => _pregnancyData != null;

  // ═══════════════════════════════════════════════════════════
  //  GETTERS — Journal
  // ═══════════════════════════════════════════════════════════

  List<JournalEntry> get journalEntries =>
      List.unmodifiable(_journalEntries);

  // ═══════════════════════════════════════════════════════════
  //  GETTERS — Meta
  // ═══════════════════════════════════════════════════════════

  bool get isLoaded => _isLoaded;

  // ═══════════════════════════════════════════════════════════
  //  INIT
  // ═══════════════════════════════════════════════════════════

  /// Call once (in main.dart) before runApp, after LocalCache.init().
  Future<void> init() async {
    await LocalCache.init();
    _loadFromCache();
    _refreshAnalytics();
    _isLoaded = true;
    notifyListeners();
  }

  void _loadFromCache() {
    _lastPeriodDate = CycleRepository.loadLastPeriodDate();
    _cycleLength = CycleRepository.loadCycleLength();
    _cycleLogs = CycleRepository.loadCycleLogs();
    _todayHealth = HealthRepository.loadTodayHealth();

    _sleepLogs = HealthRepository.loadSleepLogs()
      ..sort((a, b) => b.date.compareTo(a.date));

    _moodEntries = HealthRepository.loadMoodEntries()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  void _refreshAnalytics() {
    _cycleAnalysis = CycleEngine.analyze(
        _lastPeriodDate, _cycleLength, _cycleLogs);
    _moodTrend = MoodEngine.analyze(_moodEntries);
    _insights = InsightEngine.generate(
      cycle: _cycleAnalysis,
      mood: _moodTrend,
      todayHealth: _todayHealth,
      lastSleep: lastSleepLog,
      isPregnant: isPregnant,
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  CYCLE ACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> logPeriodStart({
    DateTime? date,
    int? cycleLength,
    String flow = 'normal',
  }) async {
    final start = date ?? DateTime.now();
    if (cycleLength != null) _cycleLength = cycleLength;

    // Compute the previous cycle length if possible
    int computedCycleLen = _cycleLength;
    if (_lastPeriodDate != null) {
      computedCycleLen =
          start.difference(_lastPeriodDate!).inDays.clamp(21, 35);
    }

    _lastPeriodDate = start;
    await CycleRepository.saveLastPeriodDate(start);
    await CycleRepository.saveCycleLength(_cycleLength);

    final log = CycleLog(
      id: start.toIso8601String(),
      periodStartDate: start,
      cycleLength: computedCycleLen,
      flow: flow,
    );
    _cycleLogs = [log, ..._cycleLogs].take(24).toList();
    await CycleRepository.saveCycleLogs(_cycleLogs);

    _refreshAnalytics();
    notifyListeners();
  }

  Future<void> updateCycleLength(int length) async {
    _cycleLength = length;
    await CycleRepository.saveCycleLength(length);
    _refreshAnalytics();
    notifyListeners();
  }

  /// Sync UserProvider date changes (backward compat bridge).
  void syncPeriodDateFrom(DateTime? date, int length) {
    bool changed = false;
    if (date != _lastPeriodDate) {
      _lastPeriodDate = date;
      changed = true;
    }
    if (length != _cycleLength) {
      _cycleLength = length;
      changed = true;
    }
    if (changed) {
      _refreshAnalytics();
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  HEALTH ACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> addWaterGlass() async {
    _todayHealth = _todayHealth
        .copyWith(waterGlasses: _todayHealth.waterGlasses + 1);
    await HealthRepository.saveTodayHealth(_todayHealth);
    _refreshAnalytics();
    notifyListeners();
  }

  Future<void> removeWaterGlass() async {
    if (_todayHealth.waterGlasses <= 0) return;
    _todayHealth = _todayHealth
        .copyWith(waterGlasses: _todayHealth.waterGlasses - 1);
    await HealthRepository.saveTodayHealth(_todayHealth);
    _refreshAnalytics();
    notifyListeners();
  }

  Future<void> setWaterGlasses(int count) async {
    _todayHealth =
        _todayHealth.copyWith(waterGlasses: count.clamp(0, 20));
    await HealthRepository.saveTodayHealth(_todayHealth);
    _refreshAnalytics();
    notifyListeners();
  }

  Future<void> updateWeight(double kg) async {
    _todayHealth = _todayHealth.copyWith(weightKg: kg);
    await HealthRepository.saveTodayHealth(_todayHealth);
    notifyListeners();
  }

  Future<void> updateTemperature(double tempC) async {
    _todayHealth = _todayHealth.copyWith(tempC: tempC);
    await HealthRepository.saveTodayHealth(_todayHealth);
    notifyListeners();
  }

  Future<void> updateEnergyLevel(String level) async {
    _todayHealth = _todayHealth.copyWith(energyLevel: level);
    await HealthRepository.saveTodayHealth(_todayHealth);
    _refreshAnalytics();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  SLEEP ACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> logSleep({
    required double hours,
    String quality = 'good',
    DateTime? bedTime,
    DateTime? wakeTime,
    String? note,
  }) async {
    final log = SleepLog(
      id: DateTime.now().toIso8601String(),
      date: DateTime.now(),
      hoursSlept: hours,
      quality: quality,
      bedTime: bedTime,
      wakeTime: wakeTime,
      note: note,
    );
    _sleepLogs = [log, ..._sleepLogs].take(30).toList();
    await HealthRepository.saveSleepLogs(_sleepLogs);
    _refreshAnalytics();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  MOOD ACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> logMood(MoodEntry entry) async {
    _moodEntries = [entry, ..._moodEntries].take(90).toList();
    await HealthRepository.saveMoodEntries(_moodEntries);
    _moodTrend = MoodEngine.analyze(_moodEntries);
    _refreshAnalytics();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  PREGNANCY ACTIONS
  // ═══════════════════════════════════════════════════════════

  void setPregnancyData(PregnancyData? data) {
    _pregnancyData = data;
    _refreshAnalytics();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  JOURNAL ACTIONS
  // ═══════════════════════════════════════════════════════════

  void addJournalEntry(JournalEntry entry) {
    _journalEntries = [entry, ..._journalEntries].take(365).toList();
    notifyListeners();
  }

  void updateJournalEntry(JournalEntry updated) {
    _journalEntries = _journalEntries
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    notifyListeners();
  }

  void deleteJournalEntry(String id) {
    _journalEntries =
        _journalEntries.where((e) => e.id != id).toList();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  CLOUD SYNC
  // ═══════════════════════════════════════════════════════════

  Future<void> syncFromCloud(String uid) async {
    try {
      final cloudLogs =
          await CycleRepository.fetchFromFirestore(uid);
      if (cloudLogs.isNotEmpty) {
        _cycleLogs = cloudLogs;
        await CycleRepository.saveCycleLogs(_cycleLogs);
        _refreshAnalytics();
        notifyListeners();
      }
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════
  //  APP MEMORY — contextual wellness summary string
//  Used by AI card and insight carousel in home dashboard
  // ═══════════════════════════════════════════════════════════

  /// Returns a short personalised awareness string for the AI card.
  String get appMemorySummary {
    final parts = <String>[];
    if (_lastPeriodDate != null) {
      parts.add('cycle day ${_cycleAnalysis.currentCycleDay}');
    }
    if (_todayHealth.waterGlasses > 0) {
      parts.add('${_todayHealth.waterGlasses} glasses of water');
    }
    if (lastSleepLog != null) {
      parts.add(
          '${lastSleepLog!.hoursSlept.toStringAsFixed(1)}h sleep');
    }
    if (_moodEntries.isNotEmpty) {
      parts.add(
          'mood: ${_moodEntries.first.label.toLowerCase()}');
    }
    if (parts.isEmpty) return 'Start logging to unlock insights';
    return 'I remember: ${parts.join(', ')} 💜';
  }
}
