import '../models/user_intent.dart';

/// Provides intent-aware personalized greetings and prompts for the
/// home dashboard hero card.
class IntentGreetingService {
  IntentGreetingService._();

  /// Returns a short personalized greeting based on the user's intent.
  /// Falls back to a generic greeting when intent is null.
  static String getGreeting(UserIntent? intent) {
    final h = DateTime.now().hour;
    if (intent == null) return _timeGreeting(h);
    switch (intent) {
      case UserIntent.breakupRecovery:
        return h < 12
            ? 'Healing takes courage. You have it 💜'
            : 'Each day is a step forward 🌱';
      case UserIntent.anxietyStress:
        return h < 12
            ? 'Breathe in calm, breathe out tension 🌬️'
            : 'You are safe. You are enough ✨';
      case UserIntent.selfLove:
        return h < 12
            ? 'You deserve all the love you give others 💜'
            : 'Your worth is not up for debate 🌸';
      case UserIntent.relationshipSupport:
        return h < 12
            ? 'Connection starts within 🤝'
            : 'Your heart is big. Honor it 💜';
      case UserIntent.pregnancyJourney:
        return h < 12
            ? 'Growing life is extraordinary 🌸'
            : 'You are doing beautifully 💫';
      case UserIntent.cycleWellness:
        return h < 12
            ? 'Your cycle is your compass 🌙'
            : 'Honor every phase, every day ✨';
      case UserIntent.emotionalGrowth:
        return h < 12
            ? 'Every feeling is information 🌱'
            : 'Growth is not linear — and that is okay 💜';
    }
  }

  /// Returns an intent-specific action prompt / micro-nudge.
  static String getNudge(UserIntent? intent) {
    if (intent == null) return 'How are you feeling today?';
    switch (intent) {
      case UserIntent.breakupRecovery:
        return 'Write one thing you love about yourself today';
      case UserIntent.anxietyStress:
        return 'Try a 2-minute breathing exercise';
      case UserIntent.selfLove:
        return 'Give yourself one genuine compliment';
      case UserIntent.relationshipSupport:
        return 'Reach out to someone who matters to you';
      case UserIntent.pregnancyJourney:
        return 'Log how you\'re feeling right now';
      case UserIntent.cycleWellness:
        return 'Check in with your body\'s energy today';
      case UserIntent.emotionalGrowth:
        return 'Journal one emotion you noticed recently';
    }
  }

  static String _timeGreeting(int hour) {
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    if (hour < 21) return 'Good evening 🌙';
    return 'Winding down 🌛';
  }
}
