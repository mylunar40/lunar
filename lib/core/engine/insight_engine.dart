import '../models/insight_model.dart';
import '../models/cycle_model.dart';
import '../models/mood_model.dart';
import '../models/health_model.dart';
import '../models/sleep_model.dart';

// ══════════════════════════════════════════════════════════════
//  INSIGHT ENGINE — local AI-like intelligence
//  Generates personalised wellness insights from user data
// ══════════════════════════════════════════════════════════════

abstract final class InsightEngine {
  static List<AIInsight> generate({
    required CycleAnalysis cycle,
    required MoodTrend mood,
    required HealthLog? todayHealth,
    required SleepLog? lastSleep,
    required bool isPregnant,
  }) {
    final now = DateTime.now();
    final insights = <AIInsight>[];

    // ── CYCLE ───────────────────────────────────────────────
    switch (cycle.currentPhase) {
      case LunarCyclePhase.period:
        insights.add(AIInsight(
          id: 'cycle_period',
          icon: '🌸',
          title: 'Rest & restore',
          body:
              'Your body is doing powerful work. Warmth, gentle movement, and iron-rich foods support you now.',
          category: InsightCategory.cycle,
          priority: InsightPriority.high,
          generatedAt: now,
        ));
        break;
      case LunarCyclePhase.follicular:
        insights.add(AIInsight(
          id: 'cycle_follicular',
          icon: '🌱',
          title: 'Energy is rising',
          body:
              'Estrogen is building — perfect for creativity, social energy, and new beginnings.',
          category: InsightCategory.cycle,
          priority: InsightPriority.medium,
          generatedAt: now,
        ));
        break;
      case LunarCyclePhase.ovulation:
        insights.add(AIInsight(
          id: 'cycle_ovulation',
          icon: '✨',
          title: 'Peak radiance window',
          body:
              'You are at your most magnetic and confident. Channel this energy into what matters most.',
          category: InsightCategory.cycle,
          priority: InsightPriority.high,
          generatedAt: now,
        ));
        break;
      case LunarCyclePhase.luteal:
        insights.add(AIInsight(
          id: 'cycle_luteal',
          icon: '💜',
          title: 'Emotional tides',
          body:
              'Progesterone peaks now. Emotional sensitivity is wisdom — honor your needs and rest deeply.',
          category: InsightCategory.cycle,
          priority: InsightPriority.medium,
          generatedAt: now,
        ));
        if (cycle.isInPmsWindow) {
          insights.add(AIInsight(
            id: 'pms_window',
            icon: '🌙',
            title: 'PMS window approaching',
            body:
                'Expect emotional tenderness in the coming days. Self-compassion and gentle routines help enormously.',
            category: InsightCategory.cycle,
            priority: InsightPriority.high,
            generatedAt: now,
          ));
        }
        break;
      case LunarCyclePhase.unknown:
        insights.add(AIInsight(
          id: 'cycle_unknown',
          icon: '🌙',
          title: 'Start tracking',
          body:
              'Log your period start date to unlock fully personalised cycle and wellness intelligence.',
          category: InsightCategory.cycle,
          priority: InsightPriority.high,
          generatedAt: now,
        ));
        break;
    }

    // ── FERTILE WINDOW ──────────────────────────────────────
    if (cycle.isInFertileWindow) {
      insights.add(AIInsight(
        id: 'fertile_window',
        icon: '🥚',
        title: 'Fertile window is open',
        body:
            'You are in your highest fertility window. Your natural glow and energy are at their peak.',
        category: InsightCategory.cycle,
        priority: InsightPriority.high,
        generatedAt: now,
      ));
    }

    // ── HYDRATION ───────────────────────────────────────────
    if (todayHealth != null) {
      if (todayHealth.waterGlasses < 4) {
        insights.add(AIInsight(
          id: 'hydration_low',
          icon: '💧',
          title: 'Hydration matters',
          body:
              '${todayHealth.waterGlasses} glasses so far. '
              '${8 - todayHealth.waterGlasses} more can ease hormonal symptoms and reduce fatigue.',
          category: InsightCategory.hydration,
          priority: InsightPriority.high,
          generatedAt: now,
        ));
      } else if (todayHealth.waterGlasses >= 8) {
        insights.add(AIInsight(
          id: 'hydration_great',
          icon: '💧',
          title: 'Perfectly hydrated',
          body:
              'Amazing hydration today! Your hormones and energy levels are being well supported.',
          category: InsightCategory.hydration,
          priority: InsightPriority.low,
          generatedAt: now,
        ));
      }
    }

    // ── SLEEP ───────────────────────────────────────────────
    if (lastSleep != null) {
      if (lastSleep.hoursSlept < 6.5) {
        insights.add(AIInsight(
          id: 'sleep_low',
          icon: '😴',
          title: 'Rest deficit detected',
          body:
              'Only ${lastSleep.hoursSlept.toStringAsFixed(1)} hours last night. '
              'Short sleep amplifies hormonal fluctuations — aim for 7–9 hours tonight.',
          category: InsightCategory.sleep,
          priority: InsightPriority.high,
          generatedAt: now,
        ));
      } else if (lastSleep.hoursSlept >= 7.5) {
        insights.add(AIInsight(
          id: 'sleep_great',
          icon: '✨',
          title: 'Beautiful sleep',
          body:
              '${lastSleep.hoursSlept.toStringAsFixed(1)} hours of rest. '
              'Consistent sleep like this supports hormonal balance and emotional resilience.',
          category: InsightCategory.sleep,
          priority: InsightPriority.low,
          generatedAt: now,
        ));
      }
    }

    // ── MOOD PATTERN ────────────────────────────────────────
    if (mood.recentEntries.isNotEmpty) {
      if (mood.hasPreMenstrualDip) {
        insights.add(AIInsight(
          id: 'mood_pms_pattern',
          icon: '🌙',
          title: 'Mood pattern detected',
          body:
              'Your mood consistently dips before your period. This is PMS/PMDD pattern — tracking it helps you prepare with nurturing rituals.',
          category: InsightCategory.mood,
          priority: InsightPriority.high,
          generatedAt: now,
          isPersonalized: true,
        ));
      }
      if (mood.pattern == 'improving') {
        insights.add(AIInsight(
          id: 'mood_improving',
          icon: '📈',
          title: 'Emotional upswing',
          body:
              'Your mood has been rising over the past 2 weeks. Keep nurturing what\'s working for you.',
          category: InsightCategory.mood,
          priority: InsightPriority.medium,
          generatedAt: now,
        ));
      } else if (mood.pattern == 'declining') {
        insights.add(AIInsight(
          id: 'mood_declining',
          icon: '💜',
          title: 'Gentle self-care time',
          body:
              'Your emotional energy has been lower recently. This is data, not failure — be deeply kind to yourself.',
          category: InsightCategory.mood,
          priority: InsightPriority.high,
          generatedAt: now,
        ));
      }
    }

    // ── PREGNANCY ───────────────────────────────────────────
    if (isPregnant) {
      insights.add(AIInsight(
        id: 'pregnancy_general',
        icon: '🤱',
        title: 'Pregnancy wellness',
        body:
            'Stay hydrated, rest when needed, and honor every emotion. Your body is doing extraordinary work.',
        category: InsightCategory.pregnancy,
        priority: InsightPriority.high,
        generatedAt: now,
      ));
    }

    // Sort by priority (high first), deduplicate, cap at 6
    insights.sort(
        (a, b) => b.priority.index.compareTo(a.priority.index));
    return insights.take(6).toList();
  }
}
