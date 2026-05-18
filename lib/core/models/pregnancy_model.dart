import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════
//  PREGNANCY DATA
// ══════════════════════════════════════════════════════════════

class PregnancyData {
  final String id;
  final DateTime dueDate;
  final bool isActive;
  final String? note;

  const PregnancyData({
    required this.id,
    required this.dueDate,
    this.isActive = true,
    this.note,
  });

  int get weeksPregnant {
    final conception = dueDate.subtract(const Duration(days: 280));
    return DateTime.now().difference(conception).inDays ~/ 7;
  }

  int get daysRemaining =>
      dueDate.difference(DateTime.now()).inDays.clamp(0, 280);

  String get trimester {
    final w = weeksPregnant;
    if (w <= 13) return 'First';
    if (w <= 26) return 'Second';
    return 'Third';
  }

  String get babySize {
    final w = weeksPregnant;
    if (w < 6) return 'Poppy seed 🌱';
    if (w < 8) return 'Blueberry 🫐';
    if (w < 10) return 'Raspberry 🍇';
    if (w < 12) return 'Lime 🍋';
    if (w < 14) return 'Lemon 🍋';
    if (w < 16) return 'Avocado 🥑';
    if (w < 18) return 'Mango 🥭';
    if (w < 20) return 'Banana 🍌';
    if (w < 22) return 'Coconut 🥥';
    if (w < 24) return 'Corn 🌽';
    if (w < 26) return 'Rutabaga 🧅';
    if (w < 28) return 'Eggplant 🍆';
    if (w < 30) return 'Butternut squash 🎃';
    if (w < 32) return 'Pineapple 🍍';
    if (w < 34) return 'Cantaloupe 🍈';
    if (w < 36) return 'Honeydew 🍈';
    if (w < 38) return 'Head of lettuce 🥬';
    return 'Watermelon 🍉';
  }

  Map<String, dynamic> toMap() => {
        'dueDate': Timestamp.fromDate(dueDate),
        'isActive': isActive,
        'note': note,
      };

  factory PregnancyData.fromMap(
          Map<String, dynamic> map, String docId) =>
      PregnancyData(
        id: docId,
        dueDate: (map['dueDate'] as Timestamp).toDate(),
        isActive: (map['isActive'] as bool?) ?? true,
        note: map['note'] as String?,
      );
}

// ══════════════════════════════════════════════════════════════
//  PREGNANCY MILESTONE
// ══════════════════════════════════════════════════════════════

class PregnancyMilestone {
  final int week;
  final String title;
  final String description;
  final String emoji;

  const PregnancyMilestone({
    required this.week,
    required this.title,
    required this.description,
    required this.emoji,
  });

  /// Standard development milestones
  static List<PregnancyMilestone> defaults() => const [
        PregnancyMilestone(
          week: 8,
          title: 'Heartbeat detectable',
          description: 'Baby\'s heart is beating at 150–170 bpm.',
          emoji: '🫀',
        ),
        PregnancyMilestone(
          week: 12,
          title: 'End of first trimester',
          description: 'Risk of miscarriage drops significantly.',
          emoji: '🌟',
        ),
        PregnancyMilestone(
          week: 20,
          title: 'Anatomy scan',
          description: 'Major anatomy scan — often when gender is revealed.',
          emoji: '🔮',
        ),
        PregnancyMilestone(
          week: 24,
          title: 'Viability milestone',
          description: 'Baby could survive with medical support if born now.',
          emoji: '💪',
        ),
        PregnancyMilestone(
          week: 28,
          title: 'Third trimester begins',
          description: 'Baby gains most weight from here. Rest is essential.',
          emoji: '🌙',
        ),
        PregnancyMilestone(
          week: 36,
          title: 'Full term approaching',
          description: 'Baby is considered early term. Prepare your bag!',
          emoji: '👜',
        ),
        PregnancyMilestone(
          week: 40,
          title: 'Due date',
          description: 'Your journey of 40 weeks — a miracle in itself.',
          emoji: '🌸',
        ),
      ];
}
