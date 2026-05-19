import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/models/chat_message.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/app_provider.dart';
import '../core/providers/lunar_data_provider.dart';
import '../core/models/cycle_model.dart';

// ===========================================================
//  LUNAR AI CHAT SCREEN
//  Emotional companion experience - premium, warm, intelligent
// ===========================================================

// -- Design tokens -------------------------------------------
const Color _kBg     = Color(0xFF0A0118);
const Color _kPurple = Color(0xFFAB5CF2);
const Color _kPink   = Color(0xFFFF69B4);
const Color _kDeep   = Color(0xFF5C2DB8);
const Color _kGold   = Color(0xFFFFD700);



// ===========================================================
//  HEALING CARD DATA  (UI-scoped display data)
// ===========================================================

class _HealData {
  final String emoji, title, body;
  final Color color;
  const _HealData(this.emoji, this.title, this.body, this.color);
}

const Map<HealingKind, _HealData> _kCards = {
  HealingKind.breathe: _HealData(
    '\u{1F32C}\u{FE0F}', 'Breathing Exercise',
    'Inhale 4 \u00B7 Hold 4 \u00B7 Exhale 6 \u00B7 Hold 2\nRepeat 4 times to activate your natural calm response. \u2728',
    Color(0xFF4FC3F7),
  ),
  HealingKind.affirmation: _HealData(
    '\u{1F49C}', 'You Are Enough',
    'You are worthy of love exactly as you are \u2014 in this moment, without changing a single thing. You are enough. \u{1F338}',
    Color(0xFFAB5CF2),
  ),
  HealingKind.sleep: _HealData(
    '\u{1F319}', 'Sleep Ritual',
    'Dim lights 1 hour before bed \u00B7 Step away from screens \u00B7 Warm chamomile tea \u00B7 Gentle body scan. Your rest is sacred. \u2728',
    Color(0xFF7986CB),
  ),
  HealingKind.hydrate: _HealData(
    '\u{1F4A7}', 'Hydration Reminder',
    'Your hormones need water to stay balanced. One tall glass right now can shift your mood within minutes. \u{1F33F}',
    Color(0xFF4FC3F7),
  ),
  HealingKind.cycle: _HealData(
    '\u{1FA78}', 'Cycle Wisdom',
    'Your emotions are deeply tied to your cycle phases. What you\'re feeling is valid \u2014 it\'s your body\'s ancient wisdom speaking. \u{1F49C}',
    Color(0xFFB05C8A),
  ),
  HealingKind.gentle: _HealData(
    '\u{1F338}', 'Gentle Reminder',
    'Treat yourself with the same tenderness you\'d offer someone you love deeply. You deserve that same softness. \u2728',
    Color(0xFFFF69B4),
  ),
};

// -- Phase display config ------------------------------------
const Map<LunarCyclePhase, Map<String, dynamic>> _kPhaseConfig = {
  LunarCyclePhase.period: {
    'emoji': '\u{1FA78}',
    'label': 'Menstrual Phase',
    'color': Color(0xFFB05C8A),
    'tip': 'Rest deeply. You deserve it.',
  },
  LunarCyclePhase.follicular: {
    'emoji': '\u{1F331}',
    'label': 'Follicular Phase',
    'color': Color(0xFF66BB6A),
    'tip': 'Energy rising. Perfect for new starts.',
  },
  LunarCyclePhase.ovulation: {
    'emoji': '\u2728',
    'label': 'Ovulation Phase',
    'color': Color(0xFFFFD700),
    'tip': 'You\'re glowing at your peak.',
  },
  LunarCyclePhase.luteal: {
    'emoji': '\u{1F319}',
    'label': 'Luteal Phase',
    'color': Color(0xFF7986CB),
    'tip': 'Honor your emotions. They\'re valid.',
  },
};

// -- Sanctuary: rotating emotional insights -----------------
const List<String> _kInsights = [
  'You seem emotionally sensitive today 🌙',
  'Your energy feels beautifully calm tonight ✨',
  "You've been so strong this week 💜",
  'Rest is productive. You deserve peace 🌸',
  'Your feelings are wisdom, not weakness 💫',
  'Breathe. You are exactly where you need to be 🌿',
  'Your body speaks truth. Listen softly 🩸',
  'Every emotion you feel is valid and seen 🌙',
];

// -- Sanctuary: quick healing actions -----------------------
const List<(String, String, Color, String)> _kSanctuaryActions = [
  ('🌬️', 'Calm\nAnxiety',     Color(0xFF4FC3F7), 'Help me calm my anxiety right now'),
  ('💤', 'Sleep\nSupport',    Color(0xFF7986CB), 'I need help falling asleep tonight'),
  ('💜', 'Emotional\nReset',  Color(0xFFAB5CF2), 'I need an emotional reset'),
  ('🌸', 'Affirmation',       Color(0xFFFF69B4), 'Give me a powerful affirmation'),
  ('📝', 'Journal\nFeelings', Color(0xFF66BB6A), 'Help me journal my feelings'),
  ('🌙', 'Breathing\nSession',Color(0xFFFFB74D), 'Guide me through a breathing session'),
];

// ===========================================================
//  MAIN SCREEN WIDGET
// ===========================================================

class AIVoiceScreen extends StatefulWidget {
  const AIVoiceScreen({super.key});

  @override
  State<AIVoiceScreen> createState() => _AIVoiceState();
}

class _AIVoiceState extends State<AIVoiceScreen> with TickerProviderStateMixin {
  // -- Animation controllers ----------------------------------
  late AnimationController _glowCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _typingCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _shimmerAnim;
  late AnimationController _auraCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _pulseAnim;

  // -- UI state -----------------------------------------------
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;
  bool _apiNudgeDismissed = false;
  int _tappedChipIdx = -1;
  bool _showApiKeySheet = false;
  final TextEditingController _apiKeyCtrl = TextEditingController();
  bool _apiKeyObscured = true;

  // -- Sanctuary state ----------------------------------------
  bool _inSanctuary = true;
  int _insightIdx = 0;
  Timer? _insightTimer;

  // -- Particles ----------------------------------------------
  final List<_AIStar> _stars = [];
  final math.Random _rng = math.Random();

  // -- Lifecycle ----------------------------------------------
  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 22; i++) {
      _stars.add(_AIStar(rng: _rng));
    }

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _typingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear),
    );

    _auraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.93, end: 1.07).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _insightTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _inSanctuary) {
        setState(() => _insightIdx = (_insightIdx + 1) % _kInsights.length);
      }
    });

    // Auto-skip sanctuary if chat has ongoing conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chat = context.read<ChatProvider>();
      if (chat.messages.length > 1) setState(() => _inSanctuary = false);
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _typingCtrl.dispose();
    _particleCtrl.dispose();
    _waveCtrl.dispose();
    _shimmerCtrl.dispose();
    _auraCtrl.dispose();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _insightTimer?.cancel();
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  // -- Helpers ------------------------------------------------
  // Returns dynamic emotional status based on context
  String _emotionalStatus(bool isTyping) {
    if (isTyping) return 'Feeling your words... \u2728';
    final h = DateTime.now().hour;
    if (h >= 5 && h < 10) return 'Good morning, love \u{1F338}';
    if (h >= 10 && h < 14) return 'Here with you \u{1F49C}';
    if (h >= 14 && h < 18) return 'Listening softly \u{1F319}';
    if (h >= 18 && h < 22) return 'Here for you tonight \u2728';
    return 'Your space to feel \u{1F319}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _textCtrl.clear();
    _focusNode.unfocus();
    context.read<ChatProvider>().send(t, context);
    _scrollToBottom();
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyCtrl.text.trim();
    if (key.isEmpty) return;
    await context.read<ChatProvider>().saveApiKey(key);
    _apiKeyCtrl.clear();
    if (mounted) setState(() => _showApiKeySheet = false);
    HapticFeedback.lightImpact();
  }

  void _showClearConfirm() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0535),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Chat? \u{1F319}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will clear your conversation history and emotional memory from this session.',
          style: TextStyle(color: Colors.white.withOpacity(0.65), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep', style: TextStyle(color: Colors.white.withOpacity(0.50))),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().clearHistory();
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
            },
            child: const Text('Clear', style: TextStyle(color: Color(0xFFFF69B4))),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  BUILD  — routes to sanctuary or chat
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final lunarData = context.watch<LunarDataProvider>();
    final size = MediaQuery.of(context).size;

    if (!_inSanctuary && chat.messages.isNotEmpty) _scrollToBottom();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: _inSanctuary
          ? KeyedSubtree(
              key: const ValueKey('sanctuary'),
              child: _buildSanctuary(chat, lunarData, size),
            )
          : KeyedSubtree(
              key: const ValueKey('chat'),
              child: _buildChat(chat, size),
            ),
    );
  }

  // ===========================================================
  //  CHAT SCAFFOLD  (existing experience, untouched logic)
  // ===========================================================
  Widget _buildChat(ChatProvider chat, Size size) {
    return Scaffold(
      backgroundColor: _kBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _AIBg(size: size),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _AIStarPainter(
                    stars: _stars, progress: _particleCtrl.value),
              ),
            ),
          ),
          if (_showApiKeySheet) _apiKeyOverlay(chat),
          SafeArea(
            child: Column(
              children: [
                // Slim sanctuary-back row
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _inSanctuary = true);
                  },
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kPurple.withOpacity(0.06),
                        border: Border(
                          bottom: BorderSide(
                              color: _kPurple
                                  .withOpacity(0.18 * _glowAnim.value),
                              width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              color: _kPurple.withOpacity(0.65),
                              size: 12),
                          const SizedBox(width: 5),
                          Text(
                            '← Back to Sanctuary',
                            style: TextStyle(
                              color: _kPurple.withOpacity(0.65),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _headerBar(chat),
                _phaseBanner(context),
                if (!chat.apiKeyConfigured && !_apiNudgeDismissed)
                  _apiNudge(),
                Expanded(child: _chatArea(chat, size)),
                _quickActions(chat),
                _inputBar(chat),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  HEADER BAR
  // ===========================================================
  Widget _headerBar(ChatProvider chat) {
    final app = context.watch<AppProvider>();
    final name = app.userName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        children: [
          // Avatar with orbital dots + breathing glow
          AnimatedBuilder(
            animation: Listenable.merge([_glowCtrl, _floatCtrl, _particleCtrl]),
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _floatAnim.value * 0.38),
              child: SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow — pulses stronger when AI is typing
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _kPurple.withOpacity(
                              chat.isTyping
                                  ? 0.72 * _glowAnim.value
                                  : 0.52 * _glowAnim.value,
                            ),
                            blurRadius: chat.isTyping ? 36 : 26,
                            spreadRadius: chat.isTyping ? 8 : 6,
                          ),
                        ],
                      ),
                    ),
                    // Moon avatar
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
                      ),
                      child: const Center(
                        child: Text('\u{1F319}', style: TextStyle(fontSize: 26)),
                      ),
                    ),
                    // Orbital dots
                    ...List.generate(3, (i) {
                      final angle = _particleCtrl.value * math.pi * 2 +
                          i * (math.pi * 2 / 3);
                      final r = 28.0;
                      final ox = math.cos(angle) * r + 34;
                      final oy = math.sin(angle) * r + 34;
                      final twinkle =
                          (0.4 + 0.6 * math.sin(angle + i)).clamp(0.0, 1.0);
                      return Positioned(
                        left: ox - 3,
                        top: oy - 3,
                        child: Opacity(
                          opacity: twinkle,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == 0
                                  ? _kPink.withOpacity(0.85)
                                  : i == 1
                                      ? _kPurple.withOpacity(0.85)
                                      : _kGold.withOpacity(0.70),
                              boxShadow: [
                                BoxShadow(
                                  color: (i == 0
                                      ? _kPink
                                      : i == 1
                                          ? _kPurple
                                          : _kGold)
                                      .withOpacity(0.55),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Lunar AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (name.isNotEmpty)
                        TextSpan(
                          text: '  \u2736  $name',
                          style: TextStyle(
                            color: _kPurple.withOpacity(0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
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
                          color: chat.isTyping
                              ? _kPink
                              : const Color(0xFF66BB6A),
                          boxShadow: [
                            BoxShadow(
                              color: (chat.isTyping
                                  ? _kPink
                                  : const Color(0xFF66BB6A))
                                  .withOpacity(0.78 * _glowAnim.value),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _emotionalStatus(chat.isTyping),
                        key: ValueKey(_emotionalStatus(chat.isTyping)),
                        style: TextStyle(
                          color: chat.isTyping
                              ? _kPink.withOpacity(0.72)
                              : Colors.white.withOpacity(0.50),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              _headerBtn(
                Icons.key_rounded,
                chat.apiKeyConfigured
                    ? const Color(0xFF66BB6A)
                    : Colors.white.withOpacity(0.40),
                () => setState(() => _showApiKeySheet = !_showApiKeySheet),
              ),
              const SizedBox(width: 8),
              _headerBtn(
                Icons.refresh_rounded,
                Colors.white.withOpacity(0.40),
                _showClearConfirm,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: Colors.white.withOpacity(0.07),
          border: Border.all(color: Colors.white.withOpacity(0.11)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ===========================================================
  //  CYCLE PHASE BANNER
  // ===========================================================
  Widget _phaseBanner(BuildContext context) {
    final lunarData = context.watch<LunarDataProvider>();
    final phase = lunarData.currentPhase;
    final cfg = _kPhaseConfig[phase];
    if (cfg == null) return const SizedBox.shrink();

    final cycleDay = lunarData.currentCycleDay;
    final dayLabel = cycleDay > 0 ? '\u00B7 Day $cycleDay' : '';

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: (cfg['color'] as Color).withOpacity(0.12),
          border: Border.all(
            color: (cfg['color'] as Color).withOpacity(0.28 * _glowAnim.value),
          ),
        ),
        child: Row(
          children: [
            Text(cfg['emoji'] as String, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cfg['label']} $dayLabel',
                    style: TextStyle(
                      color: cfg['color'] as Color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    cfg['tip'] as String,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (lunarData.isPregnant)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _kPink.withOpacity(0.18),
                ),
                child: Text(
                  '\u{1F930} Pregnant',
                  style: TextStyle(
                    color: _kPink.withOpacity(0.90),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  //  API NUDGE BANNER
  // ===========================================================
  Widget _apiNudge() {
    return GestureDetector(
      onTap: () => setState(() => _showApiKeySheet = true),
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              _kGold.withOpacity(0.12),
              _kPink.withOpacity(0.08),
            ],
          ),
          border: Border.all(color: _kGold.withOpacity(0.30)),
        ),
        child: Row(
          children: [
            const Text('\u2728', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add your OpenAI key for intelligent AI responses \u2014 tap to connect',
                style: TextStyle(
                  color: _kGold.withOpacity(0.85),
                  fontSize: 11.5,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _apiNudgeDismissed = true),
              child: Icon(Icons.close_rounded,
                  color: Colors.white.withOpacity(0.35), size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  //  API KEY OVERLAY
  // ===========================================================
  Widget _apiKeyOverlay(ChatProvider chat) {
    return GestureDetector(
      onTap: () => setState(() => _showApiKeySheet = false),
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0535).withOpacity(0.96),
                    border: Border.all(color: _kPurple.withOpacity(0.25)),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _kPurple.withOpacity(0.18),
                            ),
                            child: const Text('\u2728', style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Connect OpenAI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Enable intelligent AI responses',
                                  style: TextStyle(
                                    color: Color(0xFF9B59D8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Your API key is stored only on this device and never shared. '
                        'Get your key at platform.openai.com',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withOpacity(0.06),
                              border: Border.all(color: _kPurple.withOpacity(0.28)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _apiKeyCtrl,
                                    obscureText: _apiKeyObscured,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    cursorColor: _kPurple,
                                    decoration: InputDecoration(
                                      hintText: 'sk-...',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.25),
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _apiKeyObscured
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.white.withOpacity(0.40),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _apiKeyObscured = !_apiKeyObscured),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (chat.apiKeyConfigured)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF66BB6A), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'OpenAI key connected \u2728',
                                style: TextStyle(
                                  color: const Color(0xFF66BB6A).withOpacity(0.85),
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () async {
                                  await context.read<ChatProvider>().removeApiKey();
                                },
                                child: Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: _kPink.withOpacity(0.75),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      GestureDetector(
                        onTap: _saveApiKey,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B2DB8), Color(0xFFAB5CF2)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kPurple.withOpacity(0.40),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Save Key \u2728',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  //  CHAT AREA
  // ===========================================================
  Widget _chatArea(ChatProvider chat, Size size) {
    final msgs = chat.messages;
    final total = msgs.length + (chat.isTyping ? 1 : 0) + 1;

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      physics: const BouncingScrollPhysics(),
      cacheExtent: 800,
      itemCount: total,
      itemBuilder: (_, i) {
        if (i == msgs.length + (chat.isTyping ? 1 : 0)) {
          return const SizedBox(height: 12);
        }
        if (i == msgs.length && chat.isTyping) {
          return _typingBubble();
        }
        final msg = msgs[i];
        return _AnimatedMsg(
          key: ValueKey(msg.id),
          isUser: msg.isUser,
          child: msg.type == ChatMsgType.healingCard
              ? _buildHealingCard(msg, size)
              : _buildBubble(msg, size),
        );
      },
    );
  }

  // -- Chat bubble ---------------------------------------------
  Widget _buildBubble(ChatMessage msg, Size size) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 14,
        left: msg.isUser ? size.width * 0.16 : 0,
        right: msg.isUser ? 0 : size.width * 0.08,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[_miniMoonAvatar(), const SizedBox(width: 8)],
          Flexible(child: msg.isUser ? _userBubble(msg) : _aiBubble(msg)),
        ],
      ),
    );
  }

  Widget _miniMoonAvatar() {
    return RepaintBoundary(
      child: AnimatedBuilder(
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
            child: Text('\u{1F319}', style: TextStyle(fontSize: 14)),
          ),
        ),
      ),
    );
  }

  Widget _userBubble(ChatMessage msg) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _shimmerAnim]),
      builder: (_, __) {
        // Shimmer travels left-to-right as a highlight edge
        final shimmerPos = _shimmerAnim.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(5),
            ),
            gradient: LinearGradient(
              colors: const [Color(0xFF8B2DB8), Color(0xFFAB5CF2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withOpacity(0.42 * _glowAnim.value),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
              // Shimmer edge glow
              BoxShadow(
                color: _kPink.withOpacity(
                    0.22 * math.sin(shimmerPos * math.pi).clamp(0.0, 1.0)),
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, height: 1.55),
          ),
        );
      },
    );
  }

  Widget _aiBubble(ChatMessage msg) {
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _kPink.withOpacity(0.10),
                  Colors.white.withOpacity(0.05),
                  _kPurple.withOpacity(0.08),
                ],
              ),
              border: Border.all(
                color: _kPink.withOpacity(0.30 * _glowAnim.value),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPink.withOpacity(0.12 * _glowAnim.value),
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

  // -- Healing card --------------------------------------------
  Widget _buildHealingCard(ChatMessage msg, Size size) {
    final data = _kCards[msg.healing] ?? _kCards[HealingKind.gentle]!;
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

  // -- Typing indicator ----------------------------------------
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
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(color: _kPink.withOpacity(0.22), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
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
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: _shimmerAnim,
                      builder: (_, __) {
                        final shimmer = (0.35 +
                                0.45 * math.sin(_shimmerAnim.value * math.pi * 2))
                            .clamp(0.0, 1.0);
                        return Text(
                          'Lunar is with you... \u{1F319}',
                          style: TextStyle(
                            color: _kPurple.withOpacity(shimmer),
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  QUICK ACTIONS
  // ===========================================================
  Widget _quickActions(ChatProvider chat) {
    final lunarData = context.watch<LunarDataProvider>();
    final phase = lunarData.currentPhase;

    final List<(String, String)> actions = [
      if (phase == LunarCyclePhase.period) ('\u{1FA78}', 'Period support'),
      if (phase == LunarCyclePhase.luteal) ('\u{1F319}', 'I feel emotional'),
      if (phase == LunarCyclePhase.ovulation) ('\u2728', 'I feel amazing'),
      if (phase == LunarCyclePhase.follicular) ('\u{1F331}', 'I feel energetic'),
      if (lunarData.isPregnant) ('\u{1F930}', 'Pregnancy support'),
      ('\u{1F630}', 'I feel anxious'),
      ('\u{1F49C}', 'I need support'),
      ('\u{1F33F}', 'Help me calm down'),
      ('\u{1F327}\u{FE0F}', 'I\'m feeling sad'),
      ('\u{1F32C}\u{FE0F}', 'Breathe with me'),
      ('\u{1F634}', 'I\'m so tired'),
      ('\u{1F4A7}', 'Drink water reminder'),
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
          final isHighlighted = i == 0 && (
            phase == LunarCyclePhase.period ||
            phase == LunarCyclePhase.luteal ||
            phase == LunarCyclePhase.ovulation ||
            phase == LunarCyclePhase.follicular ||
            lunarData.isPregnant
          );
          return GestureDetector(
            onTapDown: (_) => setState(() => _tappedChipIdx = i),
            onTapUp: (_) {
              chat.sendQuickAction('$emoji $label', context);
              Future.delayed(const Duration(milliseconds: 320),
                  () { if (mounted) setState(() => _tappedChipIdx = -1); });
            },
            onTapCancel: () => setState(() => _tappedChipIdx = -1),
            child: AnimatedBuilder(
              animation: Listenable.merge([_glowAnim, _floatCtrl]),
              builder: (_, __) {
                final isTapped = _tappedChipIdx == i;
                return Transform.translate(
                  offset: Offset(
                      0, _floatAnim.value * 0.18 * (i % 2 == 0 ? 1.0 : -1.0)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(23),
                      color: isHighlighted || isTapped
                          ? _kPurple.withOpacity(0.22)
                          : Colors.white.withOpacity(0.07),
                      border: Border.all(
                        color: isTapped
                            ? _kPink.withOpacity(0.75)
                            : isHighlighted
                                ? _kPurple.withOpacity(0.50 * _glowAnim.value)
                                : _kPurple.withOpacity(0.25 * _glowAnim.value),
                      ),
                      boxShadow: isTapped
                          ? [
                              BoxShadow(
                                color: _kPink.withOpacity(0.40),
                                blurRadius: 16,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: TextStyle(
                            color: isHighlighted || isTapped
                                ? Colors.white.withOpacity(0.92)
                                : Colors.white.withOpacity(0.72),
                            fontSize: 12.5,
                            fontWeight: isHighlighted || isTapped
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ===========================================================
  //  INPUT BAR
  // ===========================================================
  Widget _inputBar(ChatProvider chat) {
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
                      onSubmitted: _send,
                      enabled: !chat.isTyping,
                      decoration: InputDecoration(
                        hintText: chat.isTyping
                            ? 'Lunar is thinking... \u{1F319}'
                            : 'Share your heart with me... \u{1F319}',
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
                  GestureDetector(
                    onLongPressStart: (_) {
                      HapticFeedback.mediumImpact();
                      setState(() => _isRecording = true);
                    },
                    onLongPressEnd: (_) {
                      HapticFeedback.lightImpact();
                      setState(() => _isRecording = false);
                      _send('Talk to me \u{1F319}');
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
                                      color: _kPink.withOpacity((1 - t) * 0.28),
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
                  GestureDetector(
                    onTap: () => _send(_textCtrl.text),
                    child: AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              _kPurple.withOpacity(0.85 + 0.15 * _glowAnim.value),
                              _kPink.withOpacity(0.85 + 0.15 * _glowAnim.value),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kPurple.withOpacity(0.42 * _glowAnim.value),
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

  // ===========================================================
  //  SANCTUARY SCAFFOLD
  // ===========================================================
  Widget _buildSanctuary(
      ChatProvider chat, LunarDataProvider lunarData, Size size) {
    return Scaffold(
      backgroundColor: _kBg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _AIBg(size: size),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _AIStarPainter(
                    stars: _stars, progress: _particleCtrl.value),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _sanctuaryHeader(lunarData),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _heroOrb(chat, lunarData, size),
                        const SizedBox(height: 22),
                        _emotionalStatusDisplay(chat, lunarData),
                        const SizedBox(height: 24),
                        _emotionalEnergyBar(lunarData),
                        const SizedBox(height: 24),
                        _memoryInsightCard(chat, lunarData),
                        const SizedBox(height: 24),
                        _sanctuaryHealingCards(chat),
                        const SizedBox(height: 24),
                        _sanctuaryAffirmation(lunarData),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _talkToLunarBtn(size),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  SANCTUARY HEADER
  // ===========================================================
  Widget _sanctuaryHeader(LunarDataProvider lunarData) {
    final phase = lunarData.currentPhase;
    final cfg = _kPhaseConfig[phase];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lunar AI \u2728',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Your emotional sanctuary',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.42), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          if (cfg != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (cfg['color'] as Color).withOpacity(0.14),
                border: Border.all(
                    color: (cfg['color'] as Color).withOpacity(0.34)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cfg['emoji'] as String,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    cfg['label'] as String,
                    style: TextStyle(
                      color: cfg['color'] as Color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _inSanctuary = false);
            },
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.07),
                border: Border.all(color: _kPurple.withOpacity(0.28)),
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: _kPurple.withOpacity(0.78), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  HERO ORB
  // ===========================================================
  Widget _heroOrb(
      ChatProvider chat, LunarDataProvider lunarData, Size size) {
    final phase = lunarData.currentPhase;
    final cfg = _kPhaseConfig[phase];
    final orbColor = cfg != null ? cfg['color'] as Color : _kPurple;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation:
            Listenable.merge([_pulseCtrl, _glowCtrl, _floatCtrl, _auraCtrl]),
        builder: (_, child) {
          final float = _floatAnim.value;
          final pulse = _pulseAnim.value;
          final glow = _glowAnim.value;
          final auraProgress = _auraCtrl.value;
          return Transform.translate(
            offset: Offset(0, float * 0.65),
            child: Transform.scale(
              scale: pulse,
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(3, (i) {
                      final pv = (auraProgress * 1.8 + i * 0.33) % 1.0;
                      return Opacity(
                        opacity: (1 - pv) * 0.20 * glow,
                        child: Container(
                          width: 140 + pv * 78,
                          height: 140 + pv * 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: orbColor, width: 1.2),
                          ),
                        ),
                      );
                    }),
                    CustomPaint(
                      size: const Size(220, 220),
                      painter: _OrbAuraPainter(
                        progress: auraProgress,
                        color: orbColor,
                        glowIntensity: glow,
                        isActive: chat.isTyping,
                      ),
                    ),
                    Container(
                      width: 136,
                      height: 136,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.26),
                            orbColor.withOpacity(0.84),
                            _kDeep,
                            const Color(0xFF0D0130),
                          ],
                          stops: const [0.0, 0.35, 0.70, 1.0],
                          center: const Alignment(-0.25, -0.30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: orbColor.withOpacity(
                                chat.isTyping ? 0.82 * glow : 0.58 * glow),
                            blurRadius: chat.isTyping ? 52 : 36,
                            spreadRadius: chat.isTyping ? 8 : 5,
                          ),
                          BoxShadow(
                              color: _kPink.withOpacity(0.26 * glow),
                              blurRadius: 28,
                              spreadRadius: 2),
                          BoxShadow(
                              color: Colors.black.withOpacity(0.50),
                              blurRadius: 20,
                              offset: const Offset(0, 8)),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18 * glow),
                          width: 1.5,
                        ),
                      ),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\ud83c\udf19', style: TextStyle(fontSize: 46)),
            const SizedBox(height: 4),
            Text(
              'Lunar AI',
              style: TextStyle(
                color: Colors.white.withOpacity(0.86),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  //  EMOTIONAL STATUS DISPLAY
  // ===========================================================
  Widget _emotionalStatusDisplay(
      ChatProvider chat, LunarDataProvider lunarData) {
    final insight = _kInsights[_insightIdx % _kInsights.length];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 650),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity:
              CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.30),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        child: Text(
          chat.isTyping ? 'Feeling your energy... \u2728' : insight,
          key: ValueKey(chat.isTyping ? 'typing' : insight),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.76),
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
            height: 1.52,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  // ===========================================================
  //  AI MEMORY INSIGHT CARD
  // ===========================================================
  Widget _memoryInsightCard(
      ChatProvider chat, LunarDataProvider lunarData) {
    final insight = _getMemoryInsight(chat, lunarData);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    _kPurple.withOpacity(0.13),
                    _kPink.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _kPurple.withOpacity(0.26 * _glowAnim.value),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kPurple.withOpacity(0.18),
                    ),
                    child: const Center(
                      child: Text('\ud83d\udcad',
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lunar remembers',
                          style: TextStyle(
                            color: _kPurple.withOpacity(0.78),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          insight,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.70),
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                      ],
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

  String _getMemoryInsight(
      ChatProvider chat, LunarDataProvider lunarData) {
    final msgs = chat.sessionMessageCount;
    final phase = lunarData.currentPhase;
    final day = lunarData.currentCycleDay;
    if (msgs > 5) {
      return switch (chat.dominantEmotion) {
        EmotionTag.anxious =>
          "You've shared anxiety today \u2014 that takes courage \ud83d\udc9c",
        EmotionTag.sad =>
          "You've been carrying heaviness. I see you \ud83c\udf19",
        EmotionTag.stressed =>
          "You've been under stress. Your nervous system needs care \u2728",
        EmotionTag.lonely =>
          "You haven't been alone in this \u2014 I've been listening \ud83c\udf38",
        EmotionTag.tired =>
          "You've been exhausted. Rest is medicine \ud83d\udca4",
        _ => "You've been beautifully open with me today \ud83c\udf38",
      };
    }
    if (lunarData.isPregnant) {
      return 'Your body is creating life. Every emotion is sacred \ud83e\udd30';
    }
    if (phase == LunarCyclePhase.period && day > 0) {
      return 'Day $day of your cycle \u2014 rest is sacred right now \ud83e\ude78';
    }
    if (phase == LunarCyclePhase.luteal) {
      return "Your luteal phase amplifies emotions. That's your body's wisdom \ud83c\udf19";
    }
    if (phase == LunarCyclePhase.ovulation) {
      return 'You\'re in your peak phase \u2014 you radiate energy right now \u2728';
    }
    return 'Your emotional journey is being honored here \ud83d\udc9c';
  }

  // ===========================================================
  //  EMOTIONAL ENERGY BAR
  // ===========================================================
  Widget _emotionalEnergyBar(LunarDataProvider lunarData) {
    final phase = lunarData.currentPhase;
    final int activeIdx;
    if (lunarData.isPregnant) {
      activeIdx = 1;
    } else {
      activeIdx = switch (phase) {
        LunarCyclePhase.ovulation => 3,
        LunarCyclePhase.follicular => 1,
        LunarCyclePhase.period => 2,
        LunarCyclePhase.luteal => 0,
        _ => 1,
      };
    }
    const energyStates = [
      ('\ud83c\udf0a', 'Calm', Color(0xFF4FC3F7)),
      ('\ud83d\udcab', 'Balanced', Color(0xFF66BB6A)),
      ('\ud83c\udf19', 'Sensitive', Color(0xFF7986CB)),
      ('\u26a1', 'High\nEnergy', Color(0xFFFFD700)),
      ('\ud83c\udf00', 'Over-\nwhelmed', Color(0xFFFF69B4)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emotional Energy',
            style: TextStyle(
              color: Colors.white.withOpacity(0.50),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(energyStates.length, (i) {
              final (emoji, label, color) = energyStates[i];
              final isActive = i == activeIdx;
              return AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      width: isActive ? 52 : 42,
                      height: isActive ? 52 : 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? color.withOpacity(0.20)
                            : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: isActive
                              ? color.withOpacity(0.62 * _glowAnim.value)
                              : Colors.white.withOpacity(0.10),
                          width: isActive ? 1.5 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: color
                                      .withOpacity(0.40 * _glowAnim.value),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: TextStyle(
                                fontSize: isActive ? 22 : 17)),
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 280),
                      style: TextStyle(
                        color: isActive
                            ? color
                            : Colors.white.withOpacity(0.28),
                        fontSize: 9.5,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                        height: 1.3,
                      ),
                      child: Text(label, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  SANCTUARY HEALING CARDS
  // ===========================================================
  Widget _sanctuaryHealingCards(ChatProvider chat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 12),
          child: Text(
            'Healing Experiences',
            style: TextStyle(
              color: Colors.white.withOpacity(0.50),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 108,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _kSanctuaryActions.length,
            itemBuilder: (_, i) {
              final (emoji, label, color, prompt) =
                  _kSanctuaryActions[i];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  chat.sendQuickAction(prompt, context);
                  setState(() => _inSanctuary = false);
                },
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.17),
                          color.withOpacity(0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color:
                            color.withOpacity(0.36 * _glowAnim.value),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.12),
                            blurRadius: 12),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji,
                            style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================
  //  SANCTUARY AFFIRMATION
  // ===========================================================
  Widget _sanctuaryAffirmation(LunarDataProvider lunarData) {
    final h = DateTime.now().hour;
    final affirmation = h < 12
        ? '\u201cYou wake with the moon\'s grace.\nToday is entirely yours. \ud83c\udf19\u201d'
        : h < 18
            ? '\u201cYour sensitivity is your superpower.\nFeel it all, beautifully. \ud83d\udc9c\u201d'
            : '\u201cRest, beautiful soul.\nThe stars hold you tonight. \u2728\u201d';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    _kPink.withOpacity(0.11),
                    _kPurple.withOpacity(0.07),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _kPink.withOpacity(0.22 * _glowAnim.value),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '\ud83c\udf38 Today\'s Affirmation',
                    style: TextStyle(
                      color: _kPink.withOpacity(0.72),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    affirmation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.80),
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      height: 1.58,
                      letterSpacing: 0.1,
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

  // ===========================================================
  //  TALK TO LUNAR CTA BUTTON
  // ===========================================================
  Widget _talkToLunarBtn(Size size) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                _kBg.withOpacity(0.82),
                _kBg.withOpacity(0.97),
              ],
            ),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(context).padding.bottom + 18),
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _inSanctuary = false);
              },
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8E24AA),
                      Color(0xFFAB5CF2),
                      Color(0xFFE040FB),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kPurple.withOpacity(
                          0.52 + 0.26 * _glowAnim.value),
                      blurRadius: 28,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: _kPink.withOpacity(0.18 * _glowAnim.value),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Talk to Lunar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================
//  MESSAGE ENTRANCE ANIMATION
// ===========================================================

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

// ===========================================================
//  DREAMY BACKGROUND
// ===========================================================

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
            child: _blob(255, const Color(0xFFE91E8C), 0.14),
          ),
          Positioned(
            top: size.height * 0.42, left: size.width * 0.45,
            child: _blob(265, const Color(0xFF7B2FF7), 0.12),
          ),
          Positioned(
            bottom: 55, left: -60,
            child: _blob(295, const Color(0xFF6C3FC8), 0.18),
          ),
          Positioned(
            bottom: 0, right: -40,
            child: _blob(245, const Color(0xFFFF69B4), 0.10),
          ),
          // Soft central nebula glow for depth
          Positioned(
            top: size.height * 0.25, left: size.width * 0.15,
            child: _blob(200, const Color(0xFFAB5CF2), 0.09),
          ),
          Positioned(
            top: size.height * 0.60, left: size.width * 0.30,
            child: _blob(180, const Color(0xFFFF69B4), 0.07),
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

// ===========================================================
//  STAR PARTICLES
// ===========================================================

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
      final x = (s.x + math.cos(s.angle) * s.speed * progress * 120) % 1.0;
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

// ===========================================================
//  ORB AURA PAINTER
// ===========================================================
class _OrbAuraPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glowIntensity;
  final bool isActive;

  const _OrbAuraPainter({
    required this.progress,
    required this.color,
    required this.glowIntensity,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final boost = isActive ? 1.4 : 1.0;
    _drawSegmentedRing(canvas, cx, cy, 82,
        progress * math.pi * 2, color, 0.38 * glowIntensity * boost, 6);
    _drawSegmentedRing(canvas, cx, cy, 98,
        -progress * math.pi * 1.4, _kPink, 0.22 * glowIntensity * boost, 4);
  }

  void _drawSegmentedRing(Canvas canvas, double cx, double cy,
      double radius, double startAngle, Color col, double opacity,
      int segments) {
    final paint = Paint()
      ..color = col.withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final sweepAngle = (math.pi * 2 / segments) * 0.42;
    for (int i = 0; i < segments; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle + (i / segments) * math.pi * 2,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbAuraPainter old) =>
      old.progress != progress ||
      old.glowIntensity != glowIntensity ||
      old.isActive != isActive;
}
