// ══════════════════════════════════════════════════════════════
//  INSIGHT CATEGORY + PRIORITY
// ══════════════════════════════════════════════════════════════

enum InsightCategory {
  cycle,
  mood,
  sleep,
  hydration,
  nutrition,
  pregnancy,
  general,
}

enum InsightPriority { low, medium, high }

// ══════════════════════════════════════════════════════════════
//  AI INSIGHT
// ══════════════════════════════════════════════════════════════

class AIInsight {
  final String id;
  final String icon;
  final String title;
  final String body;
  final InsightCategory category;
  final InsightPriority priority;
  final DateTime generatedAt;
  final bool isPersonalized;

  const AIInsight({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
    required this.category,
    this.priority = InsightPriority.medium,
    required this.generatedAt,
    this.isPersonalized = true,
  });
}
