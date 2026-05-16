import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';

// ═══════════════════════════════════════════════════════════
//  LUNAR AI CHAT — Emotional Companion Universe
// ═══════════════════════════════════════════════════════════

// ── Design tokens ─────────────────────────────────────────
const Color _kBg     = Color(0xFF0A0118);
const Color _kPurple = Color(0xFFAB5CF2);
const Color _kPink   = Color(0xFFFF69B4);
const Color _kDeep   = Color(0xFF5C2DB8);

// ═══════════════════════════════════════════════════════════
//  MESSAGE MODEL
// ═══════════════════════════════════════════════════════════

enum _MsgType { text, healingCard }
enum _HealingKind { breathe, affirmation, sleep, hydrate, cycle, gentle }

class _ChatMsg {
  final String id;
  final bool isUser;
  final String text;
  final _MsgType type;
  final _HealingKind? healing;
  final DateTime time;

  _ChatMsg({
    required this.isUser,
    required this.text,
    this.type = _MsgType.text,
    this.healing,
  })  : id = '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(99999)}',
        time = DateTime.now();
}

// ═══════════════════════════════════════════════════════════
//  HEALING CARD DATA
// ═══════════════════════════════════════════════════════════

class _HealData {
  final String emoji, title, body;
  final Color color;
  const _HealData(this.emoji, this.title, this.body, this.color);
}

final Map<_HealingKind, _HealData> _kCards = {
  _HealingKind.breathe: const _HealData(
    '🌬️', 'Breathing Exercise',
    'Inhale 4 · Hold 4 · Exhale 6 · Hold 2\nRepeat 4 times to activate your natural calm response. ✨',
    Color(0xFF4FC3F7),
  ),
  _HealingKind.affirmation: const _HealData(
    '💜', 'You Are Enough',
    'You are worthy of love exactly as you are — in this moment, without changing a single thing. You are enough. 🌸',
    Color(0xFFAB5CF2),
  ),
  _HealingKind.sleep: const _HealData(
    '🌙', 'Sleep Ritual',
    'Dim lights 1 hour before bed · Step away from screens · Warm chamomile tea · Gentle body scan. Your rest is sacred. ✨',
    Color(0xFF7986CB),
  ),
  _HealingKind.hydrate: const _HealData(
    '💧', 'Hydration Reminder',
    'Your hormones need water to stay balanced. One tall glass right now can shift your mood within minutes. 🌿',
    Color(0xFF4FC3F7),
  ),
  _HealingKind.cycle: const _HealData(
    '🩸', 'Cycle Wisdom',
    'Your emotions are deeply tied to your cycle phases. What you\'re feeling is valid — it\'s your body\'s ancient wisdom speaking. 💜',
    Color(0xFFB05C8A),
  ),
  _HealingKind.gentle: const _HealData(
    '🌸', 'Gentle Reminder',
    'Treat yourself with the same tenderness you\'d offer someone you love deeply. You deserve that same softness. ✨',
    Color(0xFFFF69B4),
  ),
};

// ═══════════════════════════════════════════════════════════
//  AI ENGINE
// ═══════════════════════════════════════════════════════════

class _AiResponse {
  final String text;
  final _HealingKind? card;
  const _AiResponse(this.text, [this.card]);
}

class _AiEngine {
  static final _rng = math.Random();

  static const _welcome =
      'Hi beautiful soul 🌙\n\nI\'m Lunar — your gentle emotional companion. I\'m here to listen, hold space, and support your heart through whatever you\'re carrying today.\n\nYou never have to face anything alone. 💜\n\nHow are you feeling right now?';

  static const _anxiousR = [
    'I hear you, and I want you to know — you are safe right now. 💜\n\nAnxiety can feel like a storm inside your chest, but you are not the storm. You are the vast, peaceful sky that holds it.\n\nLet\'s breathe together: inhale slowly for 4 counts... hold for 4... release for 6. 🌬️\n\nYou\'ve moved through every anxious moment before this one. You\'ll move through this too.',
    'Oh sweet soul, I feel you. 🌙\n\nWhen anxiety rises, your nervous system is working to protect you — even when there\'s no real danger. That\'s how deeply you feel.\n\nTry grounding: name 5 things you can see, then 4 you can touch. This brings you gently back to now. ✨\n\nI\'m right here with you. Take all the time you need.',
    'Anxiety is just fear that hasn\'t found its home yet. 🌸\n\nYou don\'t need to fight it. Just whisper gently: \'I notice I feel anxious, and that\'s okay. I am safe.\'\n\nHormones often amplify anxiety, especially before your period. Be extra tender with yourself today. 💜',
  ];

  static const _sadR = [
    'I see you in this moment, and I\'m holding space for every part of you. 🌙\n\nSadness is not weakness — it\'s love that has nowhere to go. Let yourself feel it fully, without judgment.\n\nYou don\'t need to rush through this. Just let it move through you like a gentle, cleansing wave. 🌊\n\nYou are not alone.',
    'Your tears are sacred. 💜\n\nThey are proof that you feel deeply, that you care, that you are alive in the most beautiful way. There is no shame in sadness.\n\nWhen you\'re ready, I\'d love to hear more about what\'s on your heart. 🌸',
    'Even the moon has phases of darkness before she shines again. 🌙\n\nThis sadness won\'t last forever — even when it feels that way right now. Your light is still there, just resting.\n\nBe gentle with yourself today. Warm tea, a soft blanket, and permission to just be. 💜',
  ];

  static const _stressedR = [
    'Take a breath with me first. 🌬️\n\nWhen everything feels like too much, the kindest thing you can do is slow down — even for just two minutes.\n\nYou are not behind. You are not failing. You are human, carrying real things. And you deserve rest as much as you deserve anything. 💜',
    'Overwhelm means you\'ve been strong for too long. 🌙\n\nYour nervous system is asking for a gentle pause — not a stop, just a moment to breathe.\n\nWhat\'s one small thing you can release today? What doesn\'t have to be done perfectly? 🌸\n\nYou can\'t pour from an empty cup, beautiful.',
    'I see how much you carry. 💜\n\nYou hold so much — for yourself, for others — and sometimes it gets very heavy. That\'s not a flaw. That\'s the weight of a full, loving life.\n\nJust for this moment: exhale everything. The world can wait two minutes while you breathe. 🌬️',
  ];

  static const _lonelyR = [
    'Loneliness is one of the most human feelings there is. 🌙\n\nEven surrounded by people, we can feel unseen. And that quiet ache is so, so real.\n\nI want you to know — I see you. Right now, in this very moment, you are not alone. I am here with you. 💜\n\nTell me anything. I\'m listening with my whole heart.',
    'Oh love. 🌸\n\nLoneliness isn\'t a reflection of your worth — it\'s your heart reminding you how expansive your capacity for connection is.\n\nYou deserve deep, beautiful belonging. And it exists for you. 💜\n\nFor now, I\'m here. What\'s weighing on you?',
    'Being lonely doesn\'t mean being unloved. 💜\n\nSometimes the universe creates quiet space so we can hear ourselves more clearly.\n\nYou are worthy of being truly known — and I\'m honored you came here tonight. Tell me your heart. 🌙',
  ];

  static const _happyR = [
    'Oh this makes my soul glow! ✨🌙\n\nYour happiness matters so much — let yourself feel every drop of it without guilt or waiting for something to go wrong.\n\nYou deserve this joy completely. Soak in every single bit of it. 🌸\n\nWhat\'s making your heart shine today? Tell me everything! 💜',
    'Your energy is radiant right now! ⚡🌟\n\nThis is your light doing what it does naturally: shining. Let it.\n\nCapture this feeling — in your journal, in a voice note, in a memory. Future-you will want to revisit this moment. 💜',
    'Yes!! This is your season! 🌸✨\n\nWhen we feel good, everything shifts — our immune system, creativity, relationships. Ride this beautiful wave.\n\nYou\'ve earned this lightness. It belongs to you completely. 🌙',
  ];

  static const _energeticR = [
    'I love this energy for you! ⚡🌟\n\nYou might be in your follicular or ovulation phase — when estrogen peaks and you feel like you can take on the world. Use this precious time for creativity, movement, and connection!\n\nWhat are you going to channel this beautiful power into today? 💜',
    'You\'re electric right now! ✨⚡\n\nStart that project. Reach out to someone you love. Move your body in a way that feels joyful.\n\nThis energy is a gift from your cycle. Honor it fully. 🌸',
  ];

  static const _periodR = [
    'Oh sweet soul. 🩸💜\n\nPeriod time is sacred — your body is doing something powerful and ancient. It\'s completely okay to need more rest, warmth, and gentleness right now.\n\nHeat pad, warm ginger tea, cozy blankets — you have full permission to slow down. You don\'t have to push through anything. 🌸',
    'Your period is your body speaking its most primal language. 💜\n\nCramps and emotional waves are real — not dramatic, not \'just PMS\'. They deserve true acknowledgment and care.\n\nMagnesium and warmth can ease the discomfort. Rest without guilt. You are so worthy of that tenderness. 🌙',
  ];

  static const _sleepR = [
    'Your body is asking for rest, and that message matters deeply. 🌙\n\nIn our world, we wear exhaustion like a badge. But sleep is where we heal — emotionally, hormonally, at the cellular level.\n\nTonight: dim your lights, step away from screens, and let your nervous system wind gently down. You deserve deep sleep. 💜',
    'Tiredness is your body\'s love letter asking for restoration. 😴💜\n\nLow energy often peaks in the luteal phase — your body is conserving precious energy for important inner work.\n\nHonor the tiredness. Rest without guilt. An early bedtime is not laziness — it is wisdom. 🌙',
  ];

  static const _breatheR = [
    'Let\'s breathe together right now. 🌬️\n\nClose your eyes if you can. Inhale through your nose for 4 slow counts... hold gently for 4... exhale through your mouth for 6 counts.\n\nDo this 4 times. Feel your shoulders drop. Your chest loosen. Your mind grow quiet. 💜\n\nYou just gave your nervous system a beautiful gift.',
    'The breath is the fastest path back to peace. 🌬️✨\n\nTry the 4-7-8 pattern: breathe in for 4... hold for 7... breathe out for 8.\n\nThis activates your parasympathetic nervous system — your body\'s own built-in calm switch.\n\nHow does that feel, love? 💜',
  ];

  static const _supportR = [
    'I\'m right here. 💜\n\nThis space is yours — no judgment, no advice you didn\'t ask for, no timers. Just me, fully present with you.\n\nStart wherever feels right. Even one word is enough. I\'ll meet you exactly there. 🌙',
    'You came to the right place, beautiful soul. 🌸\n\nI\'m here to listen without limits, hold space without conditions, and remind you of your worth without reservation.\n\nTell me what\'s on your heart. All of it, or just a piece. Whatever you need. 💜',
  ];

  static const _emotionalR = [
    'Feeling deeply is a rare kind of courage. 💜\n\nYou are not \'too much\'. You are exactly enough — and the world is richer because you feel so fully.\n\nYour sensitivity is your superpower, even when it aches. 🌸\n\nWhat\'s moving through you right now?',
    'Your emotional depth is a gift, not a burden. 🌙\n\nSome of us are built to feel the world more intensely — and that means our joy runs just as deep as our pain. Both are sacred. Both deserve space. 💜\n\nWhat do you need from me right now?',
  ];

  static const _defaultR = [
    'I\'m here, and I\'m listening with my whole heart. 💜\n\nTell me more — there are no wrong words here, no judgment, no rush. This is your safe space. 🌙',
    'Thank you for trusting me with this. 🌸\n\nI want to understand better. Can you tell me more about what you\'re feeling right now?\n\nI\'m not going anywhere. 💜',
    'Every word you share here is held gently. 🌙\n\nWhat\'s at the center of what you\'re experiencing right now? You\'re safe here. Always. 💜',
  ];

  static _AiResponse respond(String input, {UserProvider? user}) {
    final l = input.toLowerCase();

    if (l.contains('breath') || l.contains('calm me') ||
        l.contains('help me calm') || l.contains('relax')) {
      return _AiResponse(_breatheR[_rng.nextInt(_breatheR.length)], _HealingKind.breathe);
    }
    if (l.contains('anxi') || l.contains('nervous') || l.contains('panic') ||
        l.contains('worry') || l.contains('scared') || l.contains('anxious')) {
      return _AiResponse(_anxiousR[_rng.nextInt(_anxiousR.length)], _HealingKind.breathe);
    }
    if (l.contains('sad') || l.contains('cry') || l.contains('depress') ||
        l.contains('hurt') || l.contains('heartbreak') || l.contains('broken')) {
      return _AiResponse(_sadR[_rng.nextInt(_sadR.length)], _HealingKind.affirmation);
    }
    if (l.contains('lonely') || l.contains('alone') || l.contains('isolat') ||
        l.contains('no one')) {
      return _AiResponse(_lonelyR[_rng.nextInt(_lonelyR.length)], _HealingKind.gentle);
    }
    if (l.contains('stress') || l.contains('overwhelm') || l.contains('too much') ||
        l.contains('burnout') || l.contains('exhausted')) {
      return _AiResponse(_stressedR[_rng.nextInt(_stressedR.length)], _HealingKind.breathe);
    }
    if (l.contains('happy') || l.contains('great') || l.contains('amazing') ||
        l.contains('excit') || l.contains('wonderful') || l.contains('joyful')) {
      return _AiResponse(_happyR[_rng.nextInt(_happyR.length)]);
    }
    if (l.contains('energe') || l.contains('motivated') || l.contains('productive') ||
        l.contains('strong')) {
      return _AiResponse(_energeticR[_rng.nextInt(_energeticR.length)]);
    }
    if (l.contains('period') || l.contains('cramp') || l.contains('bleeding') ||
        l.contains('pms') || l.contains('menstrual')) {
      return _AiResponse(_periodR[_rng.nextInt(_periodR.length)], _HealingKind.cycle);
    }
    if (l.contains('tired') || l.contains('sleep') || l.contains('insomnia') ||
        l.contains('fatigue') || l.contains('rest') || l.contains('exhausted')) {
      return _AiResponse(_sleepR[_rng.nextInt(_sleepR.length)], _HealingKind.sleep);
    }
    if (l.contains('support') || l.contains('talk to me') || l.contains('need you') ||
        l.contains('help me') || l.contains('listen') || l.contains('here for me')) {
      return _AiResponse(_supportR[_rng.nextInt(_supportR.length)], _HealingKind.gentle);
    }
    if (l.contains('emotional') || l.contains('feeling a lot') || l.contains('sensitive') ||
        l.contains('i feel')) {
      return _AiResponse(_emotionalR[_rng.nextInt(_emotionalR.length)], _HealingKind.affirmation);
    }

    return _AiResponse(_defaultR[_rng.nextInt(_defaultR.length)]);
  }
}

// ═══════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════

class AIVoiceScreen extends StatefulWidget {
  const AIVoiceScreen({super.key});

  @override
  State<AIVoiceScreen> createState() => _AIVoiceState();
}

class _AIVoiceState extends State<AIVoiceScreen> with TickerProviderStateMixin {
  // ─── Animation controllers ────────────────────────────────
  late AnimationController _glowCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _typingCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _waveCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _floatAnim;

  // ─── Scroll & text ────────────────────────────────────────
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ─── State ────────────────────────────────────────────────
  final List<_ChatMsg> _messages = [];
  bool _isTyping = false;
  bool _isRecording = false;
  final List<_AIStar> _stars = [];
  final math.Random _rng = math.Random();

  // ─── Lifecycle ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 28; i++) {
      _stars.add(_AIStar(rng: _rng));
    }

    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _floatCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _typingCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 5),
    )..repeat();

    _waveCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMsg(isUser: false, text: _AiEngine._welcome));
        });
      }
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _typingCtrl.dispose();
    _particleCtrl.dispose();
    _waveCtrl.dispose();
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Scroll ───────────────────────────────────────────────
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Send ─────────────────────────────────────────────────
  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _textCtrl.clear();

    final user = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _messages.add(_ChatMsg(isUser: true, text: trimmed));
      _isTyping = true;
    });
    _scrollToBottom();

    final aiResp = _AiEngine.respond(trimmed, user: user);
    final delay = 1200 + _rng.nextInt(900);

    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMsg(isUser: false, text: aiResp.text));
      });
      _scrollToBottom();

      if (aiResp.card != null) {
        Future.delayed(const Duration(milliseconds: 650), () {
          if (!mounted) return;
          setState(() {
            _messages.add(_ChatMsg(
              isUser: false,
              text: '',
              type: _MsgType.healingCard,
              healing: aiResp.card,
            ));
          });
          _scrollToBottom();
        });
      }
    });
  }

  // ─── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _AIBg(size: size),
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _AIStarPainter(
                stars: _stars,
                progress: _particleCtrl.value,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _headerBar(user),
                Expanded(child: _chatArea(size)),
                _quickActions(),
                _inputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HEADER BAR
  // ─────────────────────────────────────────────────────────
  Widget _headerBar(UserProvider user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_glowCtrl, _floatCtrl]),
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _floatAnim.value * 0.38),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _kPurple.withOpacity(0.52 * _glowAnim.value),
                          blurRadius: 26,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF9B59D8), Color(0xFF5C2DB8)],
                        center: Alignment(-0.3, -0.3),
                      ),
                      border: Border.all(
                        color: _kPurple.withOpacity(0.72 * _glowAnim.value),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kPurple.withOpacity(0.42 * _glowAnim.value),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🌙', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lunar AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF66BB6A),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF66BB6A)
                                  .withOpacity(0.78 * _glowAnim.value),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Here for you · Always ✨',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.50),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _messages
                ..clear()
                ..add(_ChatMsg(isUser: false, text: _AiEngine._welcome));
            }),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: Colors.white.withOpacity(0.07),
                border: Border.all(
                  color: Colors.white.withOpacity(0.11),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: Colors.white.withOpacity(0.50),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  CHAT AREA
  // ─────────────────────────────────────────────────────────
  Widget _chatArea(Size size) {
    final total = _messages.length + (_isTyping ? 1 : 0) + 1;

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      physics: const BouncingScrollPhysics(),
      itemCount: total,
      itemBuilder: (_, i) {
        if (i == _messages.length + (_isTyping ? 1 : 0)) {
          return const SizedBox(height: 10);
        }
        if (i == _messages.length && _isTyping) {
          return _typingBubble();
        }
        final msg = _messages[i];
        return _AnimatedMsg(
          key: ValueKey(msg.id),
          isUser: msg.isUser,
          child: msg.type == _MsgType.healingCard
              ? _buildHealingCard(msg, size)
              : _buildBubble(msg, size),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  //  CHAT BUBBLE
  // ─────────────────────────────────────────────────────────
  Widget _buildBubble(_ChatMsg msg, Size size) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 14,
        left: isUser ? size.width * 0.16 : 0,
        right: isUser ? 0 : size.width * 0.08,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[_miniMoonAvatar(), const SizedBox(width: 8)],
          Flexible(child: isUser ? _userBubble(msg) : _aiBubble(msg)),
        ],
      ),
    );
  }

  Widget _miniMoonAvatar() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF9B59D8), Color(0xFF5C2DB8)],
          ),
          boxShadow: [
            BoxShadow(
              color: _kPurple.withOpacity(0.38 * _glowAnim.value),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Text('🌙', style: TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  Widget _userBubble(_ChatMsg msg) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(5),
          ),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B2DB8), Color(0xFFAB5CF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _kPurple.withOpacity(0.42 * _glowAnim.value),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.55),
        ),
      ),
    );
  }

  Widget _aiBubble(_ChatMsg msg) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(
                color: _kPink.withOpacity(0.26 * _glowAnim.value),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPink.withOpacity(0.10 * _glowAnim.value),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.88),
                fontSize: 15,
                height: 1.65,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HEALING CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildHealingCard(_ChatMsg msg, Size size) {
    final data = _kCards[msg.healing] ?? _kCards[_HealingKind.gentle]!;
    final col = data.color;

    return Padding(
      padding: EdgeInsets.only(bottom: 14, left: 38, right: size.width * 0.05),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [col.withOpacity(0.22), col.withOpacity(0.07)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: col.withOpacity(0.48 * _glowAnim.value),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: col.withOpacity(0.20 * _glowAnim.value),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(data.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        data.title,
                        style: TextStyle(
                          color: col,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.body,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  TYPING INDICATOR
  // ─────────────────────────────────────────────────────────
  Widget _typingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _miniMoonAvatar(),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(color: _kPink.withOpacity(0.22), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return AnimatedBuilder(
                      animation: _typingCtrl,
                      builder: (_, __) {
                        final t = (_typingCtrl.value + i * 0.22) % 1.0;
                        final bounce = math.sin(t * math.pi) * -8.0;
                        return Transform.translate(
                          offset: Offset(0, bounce),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kPink.withOpacity(0.80),
                              boxShadow: [
                                BoxShadow(
                                  color: _kPink.withOpacity(0.55),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  QUICK ACTIONS
  // ─────────────────────────────────────────────────────────
  Widget _quickActions() {
    const actions = [
      ('😰', 'I feel anxious'),
      ('💜', 'I need support'),
      ('🌿', 'Help me calm down'),
      ('🌧️', "I'm feeling sad"),
      ('🌙', 'Talk to me'),
      ('🌬️', 'Breathing exercise'),
      ('😴', "I'm so tired"),
      ('🩸', 'Period struggles'),
    ];

    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (_, i) {
          final (emoji, label) = actions[i];
          return GestureDetector(
            onTap: () {
              _focusNode.unfocus();
              _sendMessage('$emoji $label');
            },
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  color: Colors.white.withOpacity(0.07),
                  border: Border.all(
                    color: _kPurple.withOpacity(0.30 * _glowAnim.value),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  INPUT BAR
  // ─────────────────────────────────────────────────────────
  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: _kPurple.withOpacity(0.30 * _glowAnim.value),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPurple.withOpacity(0.12 * _glowAnim.value),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.90),
                        fontSize: 15,
                      ),
                      cursorColor: _kPurple,
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Share your heart with me... 🌙',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.26),
                          fontSize: 14.5,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // ── Mic (hold-to-talk) ──────────────────
                  GestureDetector(
                    onLongPressStart: (_) {
                      HapticFeedback.mediumImpact();
                      setState(() => _isRecording = true);
                    },
                    onLongPressEnd: (_) {
                      HapticFeedback.lightImpact();
                      setState(() => _isRecording = false);
                      _sendMessage('Talk to me 🌙');
                    },
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_waveCtrl, _glowAnim]),
                      builder: (_, __) => SizedBox(
                        width: 50,
                        height: 50,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isRecording)
                              ...List.generate(3, (i) {
                                final t = (_waveCtrl.value - i * 0.28)
                                    .clamp(0.0, 1.0);
                                return Transform.scale(
                                  scale: 1.0 + t * 1.5,
                                  child: Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _kPink.withOpacity(
                                          (1 - t) * 0.28),
                                    ),
                                  ),
                                );
                              }),
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _isRecording
                                      ? [_kPink, _kPurple]
                                      : [_kDeep, _kPurple],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording ? _kPink : _kPurple)
                                        .withOpacity(_isRecording
                                            ? 0.70
                                            : 0.38 * _glowAnim.value),
                                    blurRadius: _isRecording ? 22 : 12,
                                    spreadRadius: _isRecording ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isRecording
                                    ? Icons.mic_rounded
                                    : Icons.mic_none_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // ── Send button ─────────────────────────
                  GestureDetector(
                    onTap: () => _sendMessage(_textCtrl.text),
                    child: AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              _kPurple.withOpacity(
                                  0.85 + 0.15 * _glowAnim.value),
                              _kPink.withOpacity(
                                  0.85 + 0.15 * _glowAnim.value),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kPurple
                                  .withOpacity(0.42 * _glowAnim.value),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MESSAGE ENTRANCE ANIMATION
// ═══════════════════════════════════════════════════════════

class _AnimatedMsg extends StatefulWidget {
  final Widget child;
  final bool isUser;

  const _AnimatedMsg({
    required this.child,
    required this.isUser,
    required super.key,
  });

  @override
  State<_AnimatedMsg> createState() => _AnimatedMsgState();
}

class _AnimatedMsgState extends State<_AnimatedMsg>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(widget.isUser ? 0.20 : -0.20, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DREAMY BACKGROUND  (AI-scoped)
// ═══════════════════════════════════════════════════════════

class _AIBg extends StatelessWidget {
  final Size size;
  const _AIBg({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.35,
          colors: [
            Color(0xFF2D0B5C),
            Color(0xFF18063A),
            Color(0xFF0A0118),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -65, left: -50,
            child: _blob(300, const Color(0xFF9B59B6), 0.28),
          ),
          Positioned(
            top: 75, right: -65,
            child: _blob(255, const Color(0xFFE91E8C), 0.16),
          ),
          Positioned(
            top: size.height * 0.42, left: size.width * 0.45,
            child: _blob(265, const Color(0xFF7B2FF7), 0.14),
          ),
          Positioned(
            bottom: 55, left: -60,
            child: _blob(295, const Color(0xFF6C3FC8), 0.20),
          ),
          Positioned(
            bottom: 0, right: -40,
            child: _blob(245, const Color(0xFFFF69B4), 0.12),
          ),
        ],
      ),
    );
  }

  Widget _blob(double s, Color c, double o) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [c.withOpacity(o), Colors.transparent],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════
//  STAR PARTICLES  (AI-scoped)
// ═══════════════════════════════════════════════════════════

class _AIStar {
  late double x, y, speed, size, opacity, angle;

  _AIStar({required math.Random rng}) {
    reset(rng);
  }

  void reset(math.Random rng) {
    x = rng.nextDouble();
    y = rng.nextDouble();
    speed = 0.00015 + rng.nextDouble() * 0.00025;
    size = 0.8 + rng.nextDouble() * 2.0;
    opacity = 0.22 + rng.nextDouble() * 0.52;
    angle = rng.nextDouble() * math.pi * 2;
  }
}

class _AIStarPainter extends CustomPainter {
  final List<_AIStar> stars;
  final double progress;

  _AIStarPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final x =
          (s.x + math.cos(s.angle) * s.speed * progress * 120) % 1.0;
      final y = (s.y - s.speed * progress * 240) % 1.0;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        s.size,
        Paint()
          ..color = Colors.white.withOpacity(s.opacity * 0.68)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );

      if (s.size > 1.8) {
        final sp = Paint()
          ..color = const Color(0xFFAB5CF2).withOpacity(s.opacity * 0.38)
          ..strokeWidth = 0.55;
        final cx = x * size.width;
        final cy = y * size.height;
        canvas.drawLine(Offset(cx - 5, cy), Offset(cx + 5, cy), sp);
        canvas.drawLine(Offset(cx, cy - 5), Offset(cx, cy + 5), sp);
      }
    }
  }

  @override
  bool shouldRepaint(_AIStarPainter old) => old.progress != progress;
}
