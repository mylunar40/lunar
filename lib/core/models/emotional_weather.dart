import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//  EMOTIONAL WEATHER MODEL
//  Daily personalised emotional weather states, readings,
//  3-day forecast, and shareable card data.
// ══════════════════════════════════════════════════════════════

// ── 8 Emotional Weather States ────────────────────────────────

enum EmotionalWeatherState {
  calmMoon, // 🌙 peaceful, grounded, low stress
  healingEnergy, // ✨ recovering, positive trajectory
  emotionalTide, // 🌊 mixed emotions, luteal phase
  emotionalStorm, // ☁️ high anxiety / overwhelm
  selfLoveDay, // 💜 nurturing, confidence building
  gentleHeartDay, // 🌸 tender, period, grief, sensitivity
  radiantDay, // 🌟 peak energy, victories, ovulation
  releaseWeather, // 🌧️ sadness, processing, letting go
}

extension EmotionalWeatherStateX on EmotionalWeatherState {
  String get emoji {
    switch (this) {
      case EmotionalWeatherState.calmMoon:
        return '🌙';
      case EmotionalWeatherState.healingEnergy:
        return '✨';
      case EmotionalWeatherState.emotionalTide:
        return '🌊';
      case EmotionalWeatherState.emotionalStorm:
        return '☁️';
      case EmotionalWeatherState.selfLoveDay:
        return '💜';
      case EmotionalWeatherState.gentleHeartDay:
        return '🌸';
      case EmotionalWeatherState.radiantDay:
        return '🌟';
      case EmotionalWeatherState.releaseWeather:
        return '🌧️';
    }
  }

  String get label {
    switch (this) {
      case EmotionalWeatherState.calmMoon:
        return 'Calm Moon';
      case EmotionalWeatherState.healingEnergy:
        return 'Healing Energy';
      case EmotionalWeatherState.emotionalTide:
        return 'Emotional Tide';
      case EmotionalWeatherState.emotionalStorm:
        return 'Emotional Storm';
      case EmotionalWeatherState.selfLoveDay:
        return 'Self-Love Day';
      case EmotionalWeatherState.gentleHeartDay:
        return 'Gentle Heart Day';
      case EmotionalWeatherState.radiantDay:
        return 'Radiant Day';
      case EmotionalWeatherState.releaseWeather:
        return 'Release Weather';
    }
  }

  String get subtitle {
    switch (this) {
      case EmotionalWeatherState.calmMoon:
        return 'Peaceful and grounded';
      case EmotionalWeatherState.healingEnergy:
        return 'You\'re rising again';
      case EmotionalWeatherState.emotionalTide:
        return 'Waves of feeling, all valid';
      case EmotionalWeatherState.emotionalStorm:
        return 'You are safe inside yourself';
      case EmotionalWeatherState.selfLoveDay:
        return 'You deserve your own gentleness';
      case EmotionalWeatherState.gentleHeartDay:
        return 'Tenderness is sacred today';
      case EmotionalWeatherState.radiantDay:
        return 'You are at your peak';
      case EmotionalWeatherState.releaseWeather:
        return 'Letting go is its own kind of strength';
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case EmotionalWeatherState.calmMoon:
        return [const Color(0xFF5C2DB8), const Color(0xFF7986CB)];
      case EmotionalWeatherState.healingEnergy:
        return [const Color(0xFFAB5CF2), const Color(0xFF66BB6A)];
      case EmotionalWeatherState.emotionalTide:
        return [const Color(0xFF4FC3F7), const Color(0xFF7986CB)];
      case EmotionalWeatherState.emotionalStorm:
        return [const Color(0xFF546E7A), const Color(0xFF7986CB)];
      case EmotionalWeatherState.selfLoveDay:
        return [const Color(0xFFAB5CF2), const Color(0xFF9575CD)];
      case EmotionalWeatherState.gentleHeartDay:
        return [const Color(0xFFFF69B4), const Color(0xFFAB5CF2)];
      case EmotionalWeatherState.radiantDay:
        return [const Color(0xFFFFD700), const Color(0xFFFF69B4)];
      case EmotionalWeatherState.releaseWeather:
        return [const Color(0xFF7986CB), const Color(0xFF5C6BC0)];
    }
  }

  Color get accentColor => gradientColors.first;

  /// Short UI label for forecast chips.
  String get shortLabel {
    switch (this) {
      case EmotionalWeatherState.calmMoon:
        return 'Calm';
      case EmotionalWeatherState.healingEnergy:
        return 'Healing';
      case EmotionalWeatherState.emotionalTide:
        return 'Tidal';
      case EmotionalWeatherState.emotionalStorm:
        return 'Stormy';
      case EmotionalWeatherState.selfLoveDay:
        return 'Self-Love';
      case EmotionalWeatherState.gentleHeartDay:
        return 'Gentle';
      case EmotionalWeatherState.radiantDay:
        return 'Radiant';
      case EmotionalWeatherState.releaseWeather:
        return 'Release';
    }
  }
}

// ── Daily Weather Entry ────────────────────────────────────

class DayWeather {
  /// ISO date string — 'YYYY-MM-DD' — cache key.
  final String date;
  final EmotionalWeatherState state;

  /// Main 2-3 sentence personal reading.
  final String reading;

  /// Pattern-based unique insight. E.g. "You tend to feel stronger after sleep."
  final String insight;

  /// Daily healing intention / action.
  final String healingIntention;

  /// True when generated from real user data.
  final bool isPersonalized;

  /// Optional: label for forecast day display (Today / Tomorrow / Thursday).
  final String? dayLabel;

  const DayWeather({
    required this.date,
    required this.state,
    required this.reading,
    required this.insight,
    required this.healingIntention,
    this.isPersonalized = false,
    this.dayLabel,
  });

  // ── Convenience pass-throughs ──────────────────────────────
  String get emoji => state.emoji;
  String get label => state.label;
  List<Color> get gradientColors => state.gradientColors;
  Color get accentColor => state.accentColor;

  /// Text used in shareable card + clipboard copy.
  String buildShareText() {
    return 'My Emotional Weather Today 🌙\n\n'
        '${state.emoji} ${state.label}\n\n'
        '$reading\n\n'
        'Today\'s intention: $healingIntention\n\n'
        '— Lunar AI 🌙 Your emotional wellness companion';
  }

  // ── Serialization ──────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'date': date,
        'state': state.name,
        'reading': reading,
        'insight': insight,
        'healingIntention': healingIntention,
        'isPersonalized': isPersonalized,
      };

  factory DayWeather.fromJson(Map<String, dynamic> j) => DayWeather(
        date: (j['date'] as String?) ?? '',
        state: EmotionalWeatherState.values.firstWhere(
          (e) => e.name == j['state'],
          orElse: () => EmotionalWeatherState.calmMoon,
        ),
        reading: (j['reading'] as String?) ?? '',
        insight: (j['insight'] as String?) ?? '',
        healingIntention: (j['healingIntention'] as String?) ?? '',
        isPersonalized: (j['isPersonalized'] as bool?) ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DayWeather && date == other.date;

  @override
  int get hashCode => date.hashCode;
}

// ── 3-Day Forecast ─────────────────────────────────────────

class WeatherForecast {
  final DayWeather today;
  final DayWeather tomorrow;
  final DayWeather dayAfterTomorrow;

  const WeatherForecast({
    required this.today,
    required this.tomorrow,
    required this.dayAfterTomorrow,
  });

  List<DayWeather> get days => [today, tomorrow, dayAfterTomorrow];
}
