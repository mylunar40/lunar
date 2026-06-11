/// The four mood states a user can select during daily check-in.
enum CheckInMood {
  struggling,
  okay,
  good,
  better;

  String get emoji {
    switch (this) {
      case CheckInMood.struggling:
        return '😢';
      case CheckInMood.okay:
        return '😐';
      case CheckInMood.good:
        return '😊';
      case CheckInMood.better:
        return '🤗';
    }
  }

  String get label {
    switch (this) {
      case CheckInMood.struggling:
        return 'Struggling';
      case CheckInMood.okay:
        return 'Okay';
      case CheckInMood.good:
        return 'Good';
      case CheckInMood.better:
        return 'Better';
    }
  }

  static CheckInMood? fromString(String? value) {
    if (value == null) return null;
    try {
      return CheckInMood.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}

/// Lightweight representation of a single daily check-in entry.
class CheckInEntry {
  final DateTime date;
  final CheckInMood mood;
  final String? secondaryReason;

  const CheckInEntry({
    required this.date,
    required this.mood,
    this.secondaryReason,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'mood': mood.name,
        'secondaryReason': secondaryReason,
      };

  factory CheckInEntry.fromJson(Map<String, dynamic> json) => CheckInEntry(
        date: DateTime.parse(json['date'] as String),
        mood: CheckInMood.fromString(json['mood'] as String?) ??
            CheckInMood.okay,
        secondaryReason: json['secondaryReason'] as String?,
      );
}

/// Milestone definitions for the healing streak system.
class CheckInMilestone {
  final String id;
  final int requiredDays;
  final String emoji;
  final String title;
  final String message;

  const CheckInMilestone({
    required this.id,
    required this.requiredDays,
    required this.emoji,
    required this.title,
    required this.message,
  });
}

const kCheckInMilestones = [
  CheckInMilestone(
    id: 'day_7',
    requiredDays: 7,
    emoji: '🌙',
    title: 'One Week of Healing',
    message: 'You showed up for yourself every day this week. That takes courage.',
  ),
  CheckInMilestone(
    id: 'day_21',
    requiredDays: 21,
    emoji: '✨',
    title: 'Three Weeks Strong',
    message: 'Your resilience is becoming visible. Keep going.',
  ),
  CheckInMilestone(
    id: 'day_60',
    requiredDays: 60,
    emoji: '🌟',
    title: 'Two Months of Growth',
    message: 'You\'re not "over it" yet — and that\'s okay. You\'re moving.',
  ),
  CheckInMilestone(
    id: 'day_90',
    requiredDays: 90,
    emoji: '💜',
    title: 'Ready for the Next Chapter',
    message: 'Ninety days of showing up. Here\'s what you\'ve built: you.',
  ),
];
