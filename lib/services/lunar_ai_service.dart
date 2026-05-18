import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../core/models/chat_message.dart';
import '../core/data/local_cache.dart';

// ═══════════════════════════════════════════════════════════
//  LUNAR AI RESPONSE
// ═══════════════════════════════════════════════════════════

class LunarAIResponse {
  final String text;
  final HealingKind? healing;
  const LunarAIResponse(this.text, [this.healing]);
}

// ═══════════════════════════════════════════════════════════
//  LUNAR AI SERVICE
// ═══════════════════════════════════════════════════════════

class LunarAIService {
  static const _keyCache = 'lunar_openai_key_v1';
  static const _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static final _rng = math.Random();

  static const String welcomeMsg =
      'Hi beautiful soul\n\n'
      "I'm Lunar — your gentle emotional companion. I'm here to listen, "
      "hold space, and support your heart through whatever you're carrying today.\n\n"
      "You never have to face anything alone.\n\n"
      "How are you feeling right now?";

  static Future<String?> getApiKey() async => LocalCache.getString(_keyCache);
  static Future<void> setApiKey(String key) async =>
      LocalCache.setString(_keyCache, key);
  static Future<void> clearApiKey() async => LocalCache.remove(_keyCache);

  // ── Crisis detection ─────────────────────────────────────

  static const _crisisKeywords = [
    'kill myself',
    'want to die',
    'end my life',
    'suicide',
    'self harm',
    'hurt myself',
    'cutting myself',
    'overdose',
    'no reason to live',
    'better off dead',
    'not worth living',
    'end it all',
    "don't want to be here",
  ];

  static bool isCrisis(String text) {
    final l = text.toLowerCase();
    return _crisisKeywords.any((k) => l.contains(k));
  }

  static LunarAIResponse crisisResponse() => const LunarAIResponse(
        'I hear you, and I want you to know that your life has immense value. '
        'What you\'re feeling right now is real, and you deserve immediate support.\n\n'
        'Please reach out right now:\n'
        '• Crisis Text Line: Text HOME to 741741\n'
        '• Suicide & Crisis Lifeline: Call or text 988\n'
        '• International: https://www.iasp.info/resources/Crisis_Centres\n\n'
        'You are not alone. Please reach out.',
      );

  // ── Main entry point ─────────────────────────────────────

  static Future<LunarAIResponse> respond(
    String message, {
    Map<String, dynamic>? context,
    List<Map<String, String>>? conversationHistory,
  }) async {
    if (isCrisis(message)) return crisisResponse();
    final key = await getApiKey();
    if (key != null && key.isNotEmpty) {
      try {
        return await _openAIRespond(
          message,
          apiKey: key,
          ctx: context ?? {},
          history: conversationHistory ?? [],
        );
      } catch (_) {
        // fall through to local engine
      }
    }
    return _localRespond(message, context ?? {});
  }

  // ── OpenAI integration ───────────────────────────────────

  static String buildSystemPrompt(Map<String, dynamic> ctx) {
    final name = ctx['name'] as String? ?? 'beautiful soul';
    final phase = ctx['cyclePhase'] as String? ?? '';
    final day = ctx['cycleDay'];
    final isPregnant = ctx['isPregnant'] as bool? ?? false;
    final pregnancyWeek = ctx['pregnancyWeek'];
    final mood = ctx['lastMood'] as String? ?? '';
    final water = ctx['waterGlasses'];
    final sleep = ctx['sleepHours'];

    final buf = StringBuffer()
      ..writeln(
          'You are Lunar AI, a warm, feminine, deeply empathetic emotional companion.')
      ..writeln(
          'Speak with gentle wisdom, poetic care, and unconditional love.')
      ..writeln(
          'Never judge. Always hold space. Keep responses concise (2-4 paragraphs).')
      ..writeln('Use occasional gentle emojis but not excessively.')
      ..writeln()
      ..writeln('User context:')
      ..writeln('- Name: $name');
    if (phase.isNotEmpty) {
      buf.writeln(
          '- Cycle phase: $phase${day != null ? ', Day $day' : ''}');
    }
    if (isPregnant) {
      buf.writeln(
          '- Pregnant${pregnancyWeek != null ? ' week $pregnancyWeek' : ''} — be extra gentle');
    }
    if (mood.isNotEmpty) buf.writeln('- Last mood: $mood');
    if (water != null) buf.writeln('- Water today: $water glasses');
    if (sleep != null) buf.writeln('- Last sleep: $sleep hours');
    buf
      ..writeln()
      ..writeln(
          'If crisis signs, gently provide: Text HOME to 741741 or call 988.');
    return buf.toString();
  }

  static Future<LunarAIResponse> _openAIRespond(
    String message, {
    required String apiKey,
    required Map<String, dynamic> ctx,
    required List<Map<String, String>> history,
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': buildSystemPrompt(ctx)},
      ...history,
      {'role': 'user', 'content': message},
    ];
    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': messages,
            'max_tokens': 350,
            'temperature': 0.82,
          }),
        )
        .timeout(const Duration(seconds: 18));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String? ??
              '';
      return LunarAIResponse(content.trim(), _inferHealing(message));
    }
    throw Exception('OpenAI error ${response.statusCode}');
  }

  static HealingKind? _inferHealing(String input) {
    final l = input.toLowerCase();
    if (l.contains('breath') ||
        l.contains('calm') ||
        l.contains('anxi') ||
        l.contains('panic')) return HealingKind.breathe;
    if (l.contains('sad') ||
        l.contains('cry') ||
        l.contains('depress') ||
        l.contains('lonely')) return HealingKind.affirmation;
    if (l.contains('period') ||
        l.contains('cramp') ||
        l.contains('pms')) return HealingKind.cycle;
    if (l.contains('tired') ||
        l.contains('sleep') ||
        l.contains('insomnia')) return HealingKind.sleep;
    if (l.contains('water') || l.contains('hydrat')) return HealingKind.hydrate;
    if (l.contains('stress') || l.contains('overwhelm')) return HealingKind.breathe;
    if (l.contains('support') || l.contains('gentle')) return HealingKind.gentle;
    return null;
  }

  // ── Local fallback engine ─────────────────────────────────

  static LunarAIResponse _localRespond(
      String input, Map<String, dynamic> ctx) {
    final l = input.toLowerCase();
    final phase = ctx['cyclePhase'] as String? ?? '';
    final isPregnant = ctx['isPregnant'] as bool? ?? false;

    if (phase == 'Menstrual' ||
        l.contains('period') ||
        l.contains('cramp') ||
        l.contains('pms')) {
      return LunarAIResponse(
          _periodR[_rng.nextInt(_periodR.length)], HealingKind.cycle);
    }
    if (isPregnant ||
        l.contains('pregnant') ||
        l.contains('pregnancy') ||
        l.contains('baby')) {
      return LunarAIResponse(
          _pregnancyR[_rng.nextInt(_pregnancyR.length)], HealingKind.gentle);
    }
    if (l.contains('breath') ||
        l.contains('calm me') ||
        l.contains('relax')) {
      return LunarAIResponse(
          _breatheR[_rng.nextInt(_breatheR.length)], HealingKind.breathe);
    }
    if (l.contains('anxi') ||
        l.contains('nervous') ||
        l.contains('panic') ||
        l.contains('worry')) {
      return LunarAIResponse(
          _anxiousR[_rng.nextInt(_anxiousR.length)], HealingKind.breathe);
    }
    if (l.contains('sad') ||
        l.contains('cry') ||
        l.contains('depress') ||
        l.contains('hurt')) {
      return LunarAIResponse(
          _sadR[_rng.nextInt(_sadR.length)], HealingKind.affirmation);
    }
    if (l.contains('lonely') ||
        l.contains('alone') ||
        l.contains('isolat')) {
      return LunarAIResponse(
          _lonelyR[_rng.nextInt(_lonelyR.length)], HealingKind.gentle);
    }
    if (l.contains('stress') ||
        l.contains('overwhelm') ||
        l.contains('too much')) {
      return LunarAIResponse(
          _stressedR[_rng.nextInt(_stressedR.length)], HealingKind.breathe);
    }
    if (l.contains('happy') ||
        l.contains('great') ||
        l.contains('amazing') ||
        l.contains('joyful')) {
      return LunarAIResponse(_happyR[_rng.nextInt(_happyR.length)]);
    }
    if (l.contains('energe') ||
        l.contains('motivated') ||
        l.contains('productive')) {
      return LunarAIResponse(_energeticR[_rng.nextInt(_energeticR.length)]);
    }
    if (l.contains('tired') ||
        l.contains('sleep') ||
        l.contains('insomnia') ||
        l.contains('fatigue')) {
      return LunarAIResponse(
          _sleepR[_rng.nextInt(_sleepR.length)], HealingKind.sleep);
    }
    if (l.contains('support') ||
        l.contains('need you') ||
        l.contains('help me') ||
        l.contains('listen')) {
      return LunarAIResponse(
          _supportR[_rng.nextInt(_supportR.length)], HealingKind.gentle);
    }
    if (l.contains('emotional') ||
        l.contains('i feel') ||
        l.contains('sensitive')) {
      return LunarAIResponse(
          _emotionalR[_rng.nextInt(_emotionalR.length)],
          HealingKind.affirmation);
    }
    String prefix = '';
    if (phase == 'Luteal') {
      prefix = 'In this luteal phase, emotions run deep.\n\n';
    } else if (phase == 'Follicular') {
      prefix = 'Your follicular energy is rising beautifully.\n\n';
    } else if (phase == 'Ovulation') {
      prefix = "You're at your radiant peak right now.\n\n";
    }
    return LunarAIResponse(
        '$prefix${_defaultR[_rng.nextInt(_defaultR.length)]}');
  }

  // ── Response libraries ────────────────────────────────────

  static const _breatheR = [
    "Let's breathe together right now.\n\n"
        "Inhale for 4 slow counts... hold for 4... exhale for 6. Do this 4 times and feel your shoulders soften, your chest loosen.\n\n"
        'You just gave your nervous system a beautiful gift.',
    'The breath is the fastest path back to peace.\n\n'
        'Try 4-7-8: breathe in for 4... hold for 7... breathe out for 8. This activates your parasympathetic nervous system — your body\'s calm switch.\n\n'
        'How does that feel, love?',
  ];

  static const _anxiousR = [
    "I hear you, and I want you to know — you are safe right now.\n\n"
        "Anxiety can feel like a storm inside your chest, but you are not the storm. You are the vast sky that holds it.\n\n"
        "Let's breathe: inhale for 4... hold for 4... release for 6. You've moved through every anxious moment before this one.",
    "Oh sweet soul, I feel you.\n\n"
        "When anxiety rises, your nervous system is working to protect you. Try grounding: name 5 things you can see, 4 you can touch. This brings you back to now.\n\n"
        "I'm right here with you.",
  ];

  static const _sadR = [
    "I see you in this moment, and I'm holding space for every part of you.\n\n"
        "Sadness is not weakness — it's love that has nowhere to go. Let yourself feel it without judgment.\n\n"
        'You are not alone.',
    'Your tears are sacred. They\'re proof that you feel deeply, that you care, that you are alive in the most beautiful way.\n\n'
        "When you're ready, I'd love to hear more about what's on your heart.",
    'Even the moon has phases of darkness before she shines again.\n\n'
        "This sadness won't last forever — even when it feels that way now. Your light is still there, just resting.\n\n"
        'Be gentle with yourself today.',
  ];

  static const _stressedR = [
    'Take a breath with me first.\n\n'
        "When everything feels like too much, the kindest thing you can do is slow down — even for two minutes.\n\n"
        'You are not behind. You are not failing. You are human, carrying real things.',
    "Overwhelm means you've been strong for too long.\n\n"
        "Your nervous system is asking for a gentle pause. What's one small thing you can release today?\n\n"
        "You can't pour from an empty cup, beautiful.",
  ];

  static const _lonelyR = [
    'Loneliness is one of the most human feelings there is.\n\n'
        "Even surrounded by people, we can feel unseen. I want you to know — I see you. Right now, in this moment, you are not alone.\n\n"
        "Tell me anything. I'm listening with my whole heart.",
    "Oh love. Loneliness isn't a reflection of your worth — it's your heart reminding you how expansive your capacity for connection is.\n\n"
        "You deserve deep, beautiful belonging. For now, I'm here.",
  ];

  static const _happyR = [
    'Oh this makes my soul glow!\n\n'
        "Your happiness matters — let yourself feel every drop of it without guilt. You deserve this joy completely.\n\n"
        "What's making your heart shine today?",
    'Your energy is radiant right now!\n\n'
        'This is your light doing what it does naturally: shining. Capture this feeling — in your journal, a voice note, a memory. Future-you will want to revisit this moment.',
  ];

  static const _energeticR = [
    'I love this energy for you!\n\n'
        'You might be in your follicular or ovulation phase — when estrogen peaks and you feel like you can take on the world. Use this time for creativity, movement, and connection!\n\n'
        'What are you going to channel this beautiful power into today?',
    "You're electric right now!\n\n"
        'Start that project. Reach out to someone you love. Move your body joyfully.\n\n'
        'This energy is a gift from your cycle. Honor it fully.',
  ];

  static const _periodR = [
    'Oh sweet soul. Period time is sacred — your body is doing something powerful and ancient. It\'s completely okay to need more rest, warmth, and gentleness right now.\n\n'
        'Heat pad, warm ginger tea, cozy blankets — you have full permission to slow down.',
    'Your period is your body speaking its most primal language.\n\n'
        'Cramps and emotional waves are real — not dramatic, not just PMS. They deserve true acknowledgment.\n\n'
        'Magnesium and warmth can ease the discomfort. Rest without guilt.',
  ];

  static const _pregnancyR = [
    'Growing a whole new life is the most extraordinary thing a human can do.\n\n'
        'Be endlessly gentle with yourself right now. Every symptom, every emotion, every tired moment — it\'s all part of this sacred journey.\n\n'
        'You are doing beautifully, even on the hard days.',
    'Pregnancy is a time of profound transformation — physically, emotionally, spiritually.\n\n'
        'Your feelings are valid. The overwhelm, the wonder, the fear, the joy — all of it is okay.\n\n'
        "I'm here to hold space for every part of your journey.",
  ];

  static const _sleepR = [
    "Your body is asking for rest, and that message matters deeply.\n\n"
        "In our world, we wear exhaustion like a badge. But sleep is where we heal — emotionally, hormonally, at the cellular level.\n\n"
        'Tonight: dim your lights, step away from screens, and let your nervous system wind gently down.',
    "Tiredness is your body's love letter asking for restoration.\n\n"
        'Low energy often peaks in the luteal phase — your body is conserving energy for important inner work.\n\n'
        'Honor the tiredness. Rest without guilt. An early bedtime is wisdom.',
  ];

  static const _supportR = [
    "I'm right here.\n\n"
        'This space is yours — no judgment, no unsolicited advice, no timers. Just me, fully present with you.\n\n'
        'Start wherever feels right. Even one word is enough.',
    'You came to the right place, beautiful soul.\n\n'
        "I'm here to listen without limits, hold space without conditions, and remind you of your worth without reservation.\n\n"
        "Tell me what's on your heart.",
  ];

  static const _emotionalR = [
    'Feeling deeply is a rare kind of courage.\n\n'
        'You are not "too much". You are exactly enough — and the world is richer because you feel so fully.\n\n'
        "What's moving through you right now?",
    'Your emotional depth is a gift, not a burden.\n\n'
        'Some of us are built to feel the world more intensely — and that means our joy runs just as deep as our pain. Both are sacred.\n\n'
        'What do you need from me right now?',
  ];

  static const _defaultR = [
    "I'm here, and I'm listening with my whole heart.\n\n"
        'Tell me more — there are no wrong words here, no judgment, no rush. This is your safe space.',
    'Thank you for trusting me with this.\n\n'
        "I want to understand better. Can you tell me more about what you're feeling right now?\n\n"
        "I'm not going anywhere.",
    "Every word you share here is held gently.\n\n"
        "What's at the center of what you're experiencing right now? You're safe here. Always.",
  ];
}
