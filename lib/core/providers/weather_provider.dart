import 'package:flutter/foundation.dart';
import '../models/emotional_weather.dart';
import '../models/emotional_memory.dart';
import '../models/chat_message.dart' show EmotionTag;
import '../models/deep_memory.dart';
import '../models/cycle_model.dart';
import '../data/local_cache.dart';
import 'memory_provider.dart';
import 'lunar_data_provider.dart';

// ══════════════════════════════════════════════════════════════
//  WEATHER PROVIDER
//  Generates, caches, and exposes daily emotional weather.
//  Local-only — no Firestore usage for performance.
// ══════════════════════════════════════════════════════════════

class WeatherProvider extends ChangeNotifier {
  static const _kTodayKey = 'lunar_daily_weather_v1';
  static const _kHistoryKey = 'lunar_weather_history_v1';
  static const _kMaxHistory = 30;

  DayWeather? _todayWeather;
  List<DayWeather> _history = [];

  // Stored for forecast projection.
  EmotionalProfile? _lastProfile;
  LunarDataProvider? _lastLunarData;
  MemoryProvider? _lastMemory;
  String _lastUserName = '';

  // ── Public getters ─────────────────────────────────────────

  DayWeather get todayWeather =>
      _todayWeather ?? _defaultWeather(_todayDateKey());

  bool get isGeneratedToday => _todayWeather?.date == _todayDateKey();

  /// 3-day forecast: [today, tomorrow, day after tomorrow].
  WeatherForecast get forecast {
    final today = todayWeather;
    final tomorrow = _projectDay(1);
    final dayAfter = _projectDay(2);
    return WeatherForecast(
      today: today,
      tomorrow: tomorrow,
      dayAfterTomorrow: dayAfter,
    );
  }

  /// Last 14 days of readings, newest first.
  List<DayWeather> get recentHistory => _history.reversed.take(14).toList();

  // ── Init ───────────────────────────────────────────────────

  Future<void> init() async {
    await _loadFromCache();
  }

  // ── Main refresh ───────────────────────────────────────────

  /// Generate today's weather (idempotent — skips if already done today).
  void refresh({
    required EmotionalProfile profile,
    required MemoryProvider memory,
    required LunarDataProvider lunarData,
    required String userName,
  }) {
    final todayKey = _todayDateKey();

    // Store context for forecast projection.
    _lastProfile = profile;
    _lastLunarData = lunarData;
    _lastMemory = memory;
    _lastUserName = userName;

    // Skip if already generated today.
    if (_todayWeather?.date == todayKey) return;

    _todayWeather = _generate(
      dateKey: todayKey,
      dayOffset: 0,
      profile: profile,
      memory: memory,
      lunarData: lunarData,
      userName: userName,
      dayLabel: 'Today',
    );

    // Add to history (deduplicated).
    if (!_history.any((h) => h.date == todayKey)) {
      _history.add(_todayWeather!);
      if (_history.length > _kMaxHistory) {
        _history = _history.sublist(_history.length - _kMaxHistory);
      }
    }

    notifyListeners();
    _saveToCache();
  }

  // ── Generation algorithm ───────────────────────────────────

  DayWeather _generate({
    required String dateKey,
    required int dayOffset,
    required EmotionalProfile profile,
    required MemoryProvider memory,
    required LunarDataProvider lunarData,
    required String userName,
    String? dayLabel,
  }) {
    final state = _determineState(
      dayOffset: dayOffset,
      profile: profile,
      memory: memory,
      lunarData: lunarData,
    );

    final name = userName.isNotEmpty ? userName : 'beautiful soul';
    final reading =
        _buildReading(state, profile, lunarData, memory, name, dayOffset);
    final insight = _buildInsight(profile, memory, lunarData, dayOffset);
    final intention = _buildIntention(state, dayOffset);

    return DayWeather(
      date: dateKey,
      state: state,
      reading: reading,
      insight: insight,
      healingIntention: intention,
      isPersonalized: true,
      dayLabel: dayLabel,
    );
  }

  // ── State determination ────────────────────────────────────

  EmotionalWeatherState _determineState({
    required int dayOffset,
    required EmotionalProfile profile,
    required MemoryProvider memory,
    required LunarDataProvider lunarData,
  }) {
    // Project cycle day forward.
    final cycleDay = lunarData.currentCycleDay > 0
        ? (lunarData.currentCycleDay + dayOffset)
        : 0;

    // Derive projected phase from cycle day.
    final projectedPhase = _projectPhase(cycleDay, lunarData);

    // High-priority explicit states.
    if (dayOffset == 0) {
      // Today — use real emotional data.
      if (memory.hasRecurringAnxiety &&
          (profile.anxietyMentions >= 3 ||
              profile.dominantEmotion == EmotionTag.anxious)) {
        return EmotionalWeatherState.emotionalStorm;
      }
      if (profile.dominantEmotion == EmotionTag.sad ||
          (memory.memoriesByCategory[MemoryCategory.breakup]?.isNotEmpty ??
              false)) {
        return EmotionalWeatherState.releaseWeather;
      }
      if (memory.hasConfidencePattern) {
        return EmotionalWeatherState.selfLoveDay;
      }
      if (memory.hasEmotionalImprovement ||
          profile.emotionalTrajectory == 'improving') {
        return EmotionalWeatherState.healingEnergy;
      }
      if (lunarData.lastSleepHours < 6.0) {
        return EmotionalWeatherState.gentleHeartDay;
      }
    } else {
      // Forecast days — use pattern + cycle projection.
      if (memory.hasRecurringAnxiety) {
        return EmotionalWeatherState.emotionalStorm;
      }
      if (memory.hasEmotionalImprovement) {
        return EmotionalWeatherState.healingEnergy;
      }
    }

    // Phase-based defaults.
    switch (projectedPhase) {
      case LunarCyclePhase.period:
        return EmotionalWeatherState.gentleHeartDay;
      case LunarCyclePhase.follicular:
        return dayOffset > 0
            ? EmotionalWeatherState.healingEnergy
            : EmotionalWeatherState.calmMoon;
      case LunarCyclePhase.ovulation:
        return EmotionalWeatherState.radiantDay;
      case LunarCyclePhase.luteal:
        return EmotionalWeatherState.emotionalTide;
      default:
        // Time-of-day based fallback.
        final hour = DateTime.now().hour;
        if (hour >= 21 || hour < 6) return EmotionalWeatherState.calmMoon;
        return EmotionalWeatherState.healingEnergy;
    }
  }

  LunarCyclePhase _projectPhase(int cycleDay, LunarDataProvider lunarData) {
    if (lunarData.isPregnant) return LunarCyclePhase.period; // tender mode
    if (cycleDay <= 0) return lunarData.currentPhase;
    final d = cycleDay % 28;
    if (d <= 5) return LunarCyclePhase.period;
    if (d <= 13) return LunarCyclePhase.follicular;
    if (d <= 16) return LunarCyclePhase.ovulation;
    return LunarCyclePhase.luteal;
  }

  // ── Reading text builder ───────────────────────────────────

  static const _readingTemplates =
      <EmotionalWeatherState, List<_ReadingTemplate>>{
    EmotionalWeatherState.calmMoon: [
      _ReadingTemplate(
        reading:
            'There\'s a quiet softness in the air today — the kind that asks you to slow down and breathe. Your nervous system is resting, and that is an act of courage in a world that glorifies busy.\n\nLet yourself stay in this calm. It doesn\'t have to be earned.',
        personalise: false,
      ),
      _ReadingTemplate(
        reading:
            'Today feels unusually still — like the space between heartbeats. This is your body asking for presence, not productivity.\n\nSomething gentle wants to be felt today. Let it.',
        personalise: false,
      ),
    ],
    EmotionalWeatherState.healingEnergy: [
      _ReadingTemplate(
        reading:
            'Something is quietly shifting. A lightness that wasn\'t there before — subtle, but real. Your emotional system is rebuilding, thread by thread.\n\nDon\'t rush it. Just notice it. That noticing is part of the healing.',
        personalise: false,
      ),
      _ReadingTemplate(
        reading:
            'The heaviness that has been visiting you is beginning to lift — not all at once, but in small, tender increments. This is what healing actually looks like.\n\nYou are doing better than you think.',
        personalise: false,
      ),
    ],
    EmotionalWeatherState.emotionalTide: [
      _ReadingTemplate(
        reading:
            'Emotions are moving through you in waves today — some bigger than expected. This is not a sign that something is wrong. Tides are meant to move.\n\nYour only job is to stay grounded while the water moves. You are the shore, not the wave.',
        personalise: false,
      ),
      _ReadingTemplate(
        reading:
            'Today may feel emotionally unpredictable — like the weather changed without warning. Give yourself full permission to feel all of it without needing to explain or justify.\n\nYour depth of feeling is not a flaw. It is how you love.',
        personalise: false,
      ),
    ],
    EmotionalWeatherState.emotionalStorm: [
      _ReadingTemplate(
        reading:
            'The storm feels close today — anxiety or overwhelm circling the edges. This is your nervous system being very, very honest with you.\n\nYou don\'t have to calm the storm. You just have to remember: you have survived every storm before this one.',
        personalise: false,
      ),
      _ReadingTemplate(
        reading:
            'There is a lot pressing on you right now, and your body knows it. The tightness in your chest, the racing thoughts — that is your system saying "I am carrying too much."\n\nYou are allowed to put something down today.',
        personalise: false,
      ),
    ],
    EmotionalWeatherState.selfLoveDay: [
      _ReadingTemplate(
        reading:
            'Your inner critic has been louder than usual lately. Today is a day to turn down that voice — just a little — and replace it with something quieter and kinder.\n\nYou are worthy of your own gentleness. Not someday. Today.',
        personalise: false,
      ),
      _ReadingTemplate(
        reading:
            'Today, the most radical thing you can do is speak to yourself the way you would speak to someone you deeply love. With patience. With understanding. With zero expectation of perfection.\n\nYou have been doing the best you can. That is enough.',
        personalise: false,
      ),
    ],
    EmotionalWeatherState.gentleHeartDay: [
      _ReadingTemplate(
        reading:
            'Your heart is in a tender place today — raw in the way that softness can be raw. This is not weakness. This is your heart staying open, even when closing would be easier.\n\nBe extraordinarily gentle with yourself today. You deserve it.',
        personalise: false,
      ),
      _ReadingTemplate(
        reading:
            'Today asks for quietness and warmth. Your body and heart need more care than usual — and giving that care to yourself is not indulgent.\n\nRest without guilt. Feel without fixing. Be without performing.',
        personalise: false,
      ),
    ],
    EmotionalWeatherState.radiantDay: [
      _ReadingTemplate(
        reading:
            'There is something luminous in you today — a clarity and vitality that wants to be expressed. Your energy is high, your intuition sharp, your presence magnetic.\n\nLet yourself be seen. This version of you is beautiful.',
        personalise: false,
      ),
      _ReadingTemplate(
        reading:
            'Today you are at a peak — the kind of peak where you feel both powerful and at ease. This is your natural state, even when it\'s hard to remember.\n\nUse this energy for something that matters. Or simply enjoy feeling this way. Both are valid.',
        personalise: false,
      ),
    ],
    EmotionalWeatherState.releaseWeather: [
      _ReadingTemplate(
        reading:
            'Something wants to be released today — a feeling, a thought, a grief you have been carrying quietly. Letting go is not forgetting. It is choosing to carry less.\n\nIf tears want to come, let them. They are not a sign of falling apart. They are a sign of healing.',
        personalise: false,
      ),
      _ReadingTemplate(
        reading:
            'The rain is here for a reason. Grief, sadness, or a heaviness you can\'t name — these are not problems to be solved. They are experiences to be moved through.\n\nYou are allowed to be exactly where you are right now.',
        personalise: false,
      ),
    ],
  };

  String _buildReading(
    EmotionalWeatherState state,
    EmotionalProfile profile,
    LunarDataProvider lunarData,
    MemoryProvider memory,
    String name,
    int dayOffset,
  ) {
    final templates = _readingTemplates[state] ?? [];
    if (templates.isEmpty) return state.subtitle;

    // Pick based on date seed for consistency within a day.
    final seed = _dateSeed(dayOffset);
    final t = templates[seed % templates.length];

    var text = t.reading;

    // Personalise: inject name naturally when appropriate.
    if (dayOffset == 0 && name != 'beautiful soul') {
      // Occasionally add name to make it feel personal.
      if (seed % 3 == 0) {
        text = '$name... $text';
      }
    }

    // Personalise: add cycle context if applicable.
    if (dayOffset == 0) {
      final phase = lunarData.currentPhase;
      final isPregnant = lunarData.isPregnant;
      if (isPregnant) {
        text +=
            '\n\nYour body is creating life right now — every emotion you feel is amplified and sacred.';
      } else if (phase == LunarCyclePhase.period &&
          state == EmotionalWeatherState.gentleHeartDay) {
        final day = lunarData.currentCycleDay;
        text +=
            '\n\n${day > 0 ? 'Day $day of your cycle' : 'Your period'} is here — warmth and rest are the prescription today.';
      } else if (phase == LunarCyclePhase.luteal) {
        text +=
            '\n\nYour luteal phase naturally amplifies emotions right now. What you are feeling is real — and your sensitivity is wisdom, not weakness.';
      }
    }

    return text;
  }

  // ── Insight builder ────────────────────────────────────────

  String _buildInsight(
    EmotionalProfile profile,
    MemoryProvider memory,
    LunarDataProvider lunarData,
    int dayOffset,
  ) {
    if (dayOffset > 0) {
      return _forecastInsight(dayOffset, profile, lunarData);
    }

    // Today: use real patterns.
    if (profile.sleepMentions >= 2 && lunarData.lastSleepHours >= 7.5) {
      return 'You tend to feel emotionally stronger after good sleep. Your rest last night shows in your energy today.';
    }
    if (profile.anxietyMentions >= 3) {
      return 'Anxiety has been a recurring visitor. Noticing it is the first step to gentling it.';
    }
    if (profile.stressMentions >= 3) {
      return 'Stress has been building over time. Your nervous system remembers — and right now, it needs permission to rest.';
    }
    if (memory.hasEmotionalImprovement) {
      return 'Your emotional trajectory has been quietly improving. Something is shifting — trust it.';
    }
    if (profile.hasPositiveStreak) {
      return 'You have been in a genuinely positive emotional space. Your nervous system is in a rare and beautiful state of ease.';
    }
    final phase = lunarData.currentPhase;
    if (phase == LunarCyclePhase.luteal) {
      return 'Emotions tend to peak in your luteal phase. Knowing this is power — you can meet the waves before they arrive.';
    }
    if (phase == LunarCyclePhase.follicular) {
      return 'Your follicular phase brings rising clarity and energy. This is a good time to start things you\'ve been putting off.';
    }
    if (profile.dominantEmotion == EmotionTag.anxious) {
      return 'Anxiety has been your most frequent emotional visitor. Lunar has noticed — and is holding that gently.';
    }
    return 'Your emotional patterns are being gently tracked. Lunar learns your rhythms to serve you better each day.';
  }

  String _forecastInsight(
      int dayOffset, EmotionalProfile profile, LunarDataProvider lunarData) {
    if (dayOffset == 1) {
      if (profile.emotionalTrajectory == 'improving') {
        return 'Based on your recent pattern, tomorrow looks emotionally brighter.';
      }
      if (profile.emotionalTrajectory == 'declining') {
        return 'Tomorrow may still carry some emotional weight — be extra gentle.';
      }
      return 'Tomorrow\'s emotional forecast is based on your cycle and recent patterns.';
    }
    if (dayOffset == 2) {
      return 'By day 3, your cycle phase projects a shift in emotional energy.';
    }
    return 'Emotional forecast based on your cycle and patterns.';
  }

  // ── Intention builder ──────────────────────────────────────

  static const _intentions = <EmotionalWeatherState, List<String>>{
    EmotionalWeatherState.calmMoon: [
      'Do one slow thing today — without rushing.',
      'Let stillness be enough. You don\'t have to fill every quiet moment.',
      'Today\'s intention: arrive. Just fully arrive where you are.',
    ],
    EmotionalWeatherState.healingEnergy: [
      'Acknowledge one small way you have grown recently.',
      'Let yourself receive what is good today without deflecting it.',
      'Today\'s intention: notice what feels lighter than it used to.',
    ],
    EmotionalWeatherState.emotionalTide: [
      'When the wave comes, breathe. Let it pass without needing to explain.',
      'Today\'s intention: feel without fixing. Experience without controlling.',
      'Give yourself permission to be emotionally complex today.',
    ],
    EmotionalWeatherState.emotionalStorm: [
      'Breathe first. Everything else can wait 30 seconds.',
      'Today\'s intention: choose one small safe thing and anchor to it.',
      'You don\'t have to calm the storm — just wait it out with kindness.',
    ],
    EmotionalWeatherState.selfLoveDay: [
      'Say one genuinely kind thing to yourself before this day ends.',
      'Today\'s intention: treat yourself with the care you give to others.',
      'Notice when you are being hard on yourself. Then gently choose otherwise.',
    ],
    EmotionalWeatherState.gentleHeartDay: [
      'Rest without guilt. Your body is asking for less, not more.',
      'Today\'s intention: warmth, softness, and zero pressure.',
      'Give yourself the care you would give a dear friend who was hurting.',
    ],
    EmotionalWeatherState.radiantDay: [
      'Use your energy for something that genuinely matters to you today.',
      'Today\'s intention: let yourself shine without apologising.',
      'Share this brightness with someone who needs it — it won\'t dim you.',
    ],
    EmotionalWeatherState.releaseWeather: [
      'Let something go today. Even one small thing. That\'s enough.',
      'Today\'s intention: cry if you need to. Feel fully. Release gently.',
      'What is one thing you\'ve been holding that is ready to be set down?',
    ],
  };

  String _buildIntention(EmotionalWeatherState state, int dayOffset) {
    final list = _intentions[state] ?? ['Be gentle with yourself today.'];
    return list[_dateSeed(dayOffset) % list.length];
  }

  // ── Forecast projection ────────────────────────────────────

  DayWeather _projectDay(int offset) {
    final profile = _lastProfile;
    final lunarData = _lastLunarData;
    final memory = _lastMemory;

    final date = DateTime.now().add(Duration(days: offset));
    final dateKey = _dateKeyFromDate(date);

    if (profile == null || lunarData == null || memory == null) {
      return _defaultWeather(dateKey, dayLabel: _dayLabel(offset));
    }

    return _generate(
      dateKey: dateKey,
      dayOffset: offset,
      profile: profile,
      memory: memory,
      lunarData: lunarData,
      userName: _lastUserName,
      dayLabel: _dayLabel(offset),
    );
  }

  String _dayLabel(int offset) {
    if (offset == 0) return 'Today';
    if (offset == 1) return 'Tomorrow';
    final date = DateTime.now().add(Duration(days: offset));
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  // ── Cache ──────────────────────────────────────────────────

  Future<void> _loadFromCache() async {
    try {
      // Today's weather.
      final todayJson = LocalCache.getJson(_kTodayKey);
      if (todayJson != null) {
        final weather = DayWeather.fromJson(todayJson);
        if (weather.date == _todayDateKey()) {
          _todayWeather = weather;
        }
      }

      // History.
      final historyJson = LocalCache.getJsonList(_kHistoryKey) ?? [];
      _history = historyJson
          .map((j) {
            try {
              return DayWeather.fromJson(j);
            } catch (_) {
              return null;
            }
          })
          .whereType<DayWeather>()
          .toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveToCache() async {
    try {
      if (_todayWeather != null) {
        await LocalCache.setJson(_kTodayKey, _todayWeather!.toJson());
      }
      await LocalCache.setJsonList(
        _kHistoryKey,
        _history.map((h) => h.toJson()).toList(),
      );
    } catch (_) {}
  }

  // ── Helpers ────────────────────────────────────────────────

  static String _todayDateKey() => _dateKeyFromDate(DateTime.now());

  static String _dateKeyFromDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Deterministic seed based on the date for consistent daily reading.
  int _dateSeed(int dayOffset) {
    final d = DateTime.now().add(Duration(days: dayOffset));
    return d.year * 366 + d.month * 31 + d.day;
  }

  DayWeather _defaultWeather(String dateKey, {String? dayLabel}) => DayWeather(
        date: dateKey,
        state: EmotionalWeatherState.calmMoon,
        reading:
            'Today is a gentle beginning. Whatever you\'re feeling, this is a safe space to just be.\n\nLunar is here with you.',
        insight: 'Your emotional journey is unique and personal.',
        healingIntention: 'Be gentle with yourself today.',
        isPersonalized: false,
        dayLabel: dayLabel,
      );
}

// ── Internal helpers ───────────────────────────────────────

class _ReadingTemplate {
  final String reading;
  final bool personalise;
  const _ReadingTemplate({required this.reading, required this.personalise});
}
