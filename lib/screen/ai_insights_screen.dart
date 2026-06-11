import 'dart:math' as math;
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../user_provider.dart';

// ═══════════════════════════════════════════════════════════
//  LUNAR AI INSIGHTS — Emotional Intelligence Universe
// ═══════════════════════════════════════════════════════════

// ── Design tokens ─────────────────────────────────────────
const Color _iKBg     = Color(0xFF0A0118);
const Color _iKPurple = Color(0xFFAB5CF2);
const Color _iKPink   = Color(0xFFFF69B4);
const Color _iKDeep   = Color(0xFF5C2DB8);

// ═══════════════════════════════════════════════════════════
//  INSIGHT MODEL
// ═══════════════════════════════════════════════════════════

enum _InsightType { pattern, trend, recommendation, healing }

class _Insight {
  final String icon;
  final String title;
  final String body;
  final Color accent;
  final _InsightType type;
  final String badge;
  const _Insight({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.type,
    required this.badge,
  });
}

// ═══════════════════════════════════════════════════════════
//  PREDICTION MODEL
// ═══════════════════════════════════════════════════════════

class _AIPrediction {
  final String emoji;
  final String title;
  final String subtitle;
  final String timeframe;
  final Color color;
  const _AIPrediction(
      this.emoji, this.title, this.subtitle, this.timeframe, this.color);
}

// ═══════════════════════════════════════════════════════════
//  HEALING SPACE MODEL
// ═══════════════════════════════════════════════════════════

class _HealingOption {
  final String emoji;
  final String title;
  final String desc;
  final Color color;
  final List<String> steps;
  const _HealingOption(this.emoji, this.title, this.desc, this.color, this.steps);
}

// ═══════════════════════════════════════════════════════════
//  LUNAR ANALYTICS ENGINE  (local intelligence, API-ready)
// ═══════════════════════════════════════════════════════════

class _LunarAnalytics {
  // ── Cycle phase ─────────────────────────────────────────
  static int _cycleDay(UserProvider u) {
    if (u.lastPeriodDate == null) return 14;
    return DateTime.now().difference(u.lastPeriodDate!).inDays + 1;
  }

  static String cyclePhase(UserProvider u) {
    final d = _cycleDay(u);
    if (d <= 5)  return 'menstrual';
    if (d <= 13) return 'follicular';
    if (d <= 16) return 'ovulation';
    if (d <= 28) return 'luteal';
    return 'unknown';
  }

  // ── Daily summary ───────────────────────────────────────
  static String dailySummary(UserProvider u) {
    final h = DateTime.now().hour;
    final phase = cyclePhase(u);
    if (h >= 22 || h < 6) {
      return 'Time to rest and restore — your body does its deepest healing at night 🌙';
    }
    switch (phase) {
      case 'menstrual':
        return 'Honour your softness today. Rest is productive — your body is working hard 🌸';
      case 'follicular':
        return 'Your energy is rising beautifully. Today is perfect for new intentions ✨';
      case 'ovulation':
        return 'You\'re glowing with high-frequency energy. Express, connect, and shine 🌟';
      case 'luteal':
        return 'Your intuition is heightened. Honour your feelings — they carry wisdom 💜';
      default:
        return 'You are exactly where you need to be. Trust your journey 💫';
    }
  }

  // ── AI Insights ─────────────────────────────────────────
  static List<_Insight> insights(UserProvider u) {
    final phase = cyclePhase(u);
    final h = DateTime.now().hour;
    final insights = <_Insight>[];

    // Pattern insights
    if (phase == 'luteal') {
      insights.add(const _Insight(
        icon: '🌙', badge: 'Pattern',
        title: 'Stress peaks before your period',
        body: 'Your emotional sensitivity rises in the luteal phase. This is biological wisdom, not weakness.',
        accent: Color(0xFF7B68EE), type: _InsightType.pattern,
      ));
    }
    if (phase == 'follicular' || phase == 'ovulation') {
      insights.add(const _Insight(
        icon: '⚡', badge: 'Trend',
        title: 'Energy levels are improving',
        body: 'Oestrogen rise is boosting your mood and vitality. This is your power window — use it beautifully.',
        accent: Color(0xFF66BB6A), type: _InsightType.trend,
      ));
    }
    if (phase == 'menstrual') {
      insights.add(const _Insight(
        icon: '🩸', badge: 'Phase',
        title: 'Rest restores your hormones',
        body: 'During menstruation, iron and magnesium drop. Gentle movement and warm food will support your energy.',
        accent: Color(0xFFB05C8A), type: _InsightType.recommendation,
      ));
    }

    // Universal insights
    insights.addAll([
      const _Insight(
        icon: '😴', badge: 'Sleep',
        title: 'Sleep quality affects your mood',
        body: 'Less than 7 hours disrupts cortisol balance and amplifies emotional reactivity. Prioritise your rest tonight.',
        accent: Color(0xFF7986CB), type: _InsightType.trend,
      ),
      const _Insight(
        icon: '💧', badge: 'Hydration',
        title: 'Hydration is lower than usual',
        body: 'Even mild dehydration triggers anxiety-like feelings. A glass of water can shift your mood within minutes.',
        accent: Color(0xFF4FC3F7), type: _InsightType.recommendation,
      ),
      const _Insight(
        icon: '💜', badge: 'Emotional',
        title: 'Your emotional balance is stabilising',
        body: 'Consistent check-ins are helping you understand your emotional patterns. Keep going — you\'re doing beautifully.',
        accent: _iKPurple, type: _InsightType.pattern,
      ),
      _Insight(
        icon: h >= 20 ? '🌙' : '🌤️', badge: 'Today',
        title: h >= 20
            ? 'Ideal evening for journaling'
            : 'Creative energy is available today',
        body: h >= 20
            ? 'Processing emotions through writing before sleep reduces overthinking and improves sleep quality.'
            : 'Your mind is clear and receptive right now. Capture any insights or feelings in your journal.',
        accent: _iKPink, type: _InsightType.healing,
      ),
      const _Insight(
        icon: '🌸', badge: 'Cycle',
        title: 'Cycle patterns reveal your rhythms',
        body: 'Every phase brings unique gifts. Tracking your emotions alongside your cycle unlocks deep self-awareness.',
        accent: Color(0xFFB05C8A), type: _InsightType.pattern,
      ),
    ]);

    return insights;
  }

  // ── Trend data (7-day simulated, ready for real data) ──
  static List<FlSpot> moodTrend() => [
    const FlSpot(0, 3.2), const FlSpot(1, 3.8), const FlSpot(2, 2.9),
    const FlSpot(3, 4.1), const FlSpot(4, 3.5), const FlSpot(5, 4.4),
    const FlSpot(6, 4.0),
  ];

  static List<FlSpot> stressTrend() => [
    const FlSpot(0, 3.8), const FlSpot(1, 4.2), const FlSpot(2, 4.5),
    const FlSpot(3, 3.6), const FlSpot(4, 3.2), const FlSpot(5, 2.8),
    const FlSpot(6, 3.0),
  ];

  static List<FlSpot> energyTrend() => [
    const FlSpot(0, 2.8), const FlSpot(1, 3.2), const FlSpot(2, 3.9),
    const FlSpot(3, 4.2), const FlSpot(4, 4.6), const FlSpot(5, 4.3),
    const FlSpot(6, 4.8),
  ];

  static List<FlSpot> sleepTrend() => [
    const FlSpot(0, 3.5), const FlSpot(1, 3.0), const FlSpot(2, 4.0),
    const FlSpot(3, 3.8), const FlSpot(4, 4.2), const FlSpot(5, 3.9),
    const FlSpot(6, 4.5),
  ];

  // ── Predictions ─────────────────────────────────────────
  static List<_AIPrediction> predictions(UserProvider u) {
    final d = _cycleDay(u);
    return [
      _AIPrediction(
        '🌙',
        d >= 20 ? 'Emotional sensitivity incoming' : 'Emotional stability ahead',
        d >= 20
            ? 'PMS window approaching. Soften your schedule and lean into self-care.'
            : 'Your luteal phase is a few days away. Use this clarity while it lasts.',
        d >= 20 ? 'In ~${28 - d} days' : 'You have ~${20 - d} days',
        const Color(0xFF7B68EE),
      ),
      const _AIPrediction(
        '⚡', 'High-energy window',
        'Follicular and ovulation phases bring peak motivation. Schedule important tasks here.',
        'Days 6 – 16', Color(0xFF66BB6A),
      ),
      _AIPrediction(
        '🩸', 'Next period estimate',
        'Your body will need gentleness, warmth, and extra rest during this time.',
        'In ${u.daysUntilNext} days', const Color(0xFFB05C8A),
      ),
      const _AIPrediction(
        '💜', 'Emotional sensitivity peak',
        'Days 21–28 often bring heightened emotions. Plan rest, connection, and journaling.',
        'Days 21 – 28', _iKPurple,
      ),
    ];
  }

  // ── Recommendations (phase-aware) ───────────────────────
  static List<(String, String, String, Color)> recommendations(UserProvider u) {
    final phase = cyclePhase(u);
    final h = DateTime.now().hour;
    return [
      if (phase == 'menstrual' || phase == 'luteal')
        ('🧘‍♀️', 'Yin Yoga Tonight',
         'Gentle floor stretches relieve cramps and lower cortisol. Even 10 minutes is transformative.',
         const Color(0xFFAB5CF2)),
      if (phase == 'follicular' || phase == 'ovulation')
        ('🏃‍♀️', 'Movement Boosts Your Glow',
         'Higher oestrogen means faster muscle recovery. Try a walk, dance, or light workout.',
         const Color(0xFF66BB6A)),
      ('🌬️', 'Box Breathing',
       'Inhale 4 · Hold 4 · Exhale 4 · Hold 4. Repeat 4 times to activate calm immediately.',
       const Color(0xFF4FC3F7)),
      ('💧', 'Hydrate Right Now',
       'Your cycle and emotions both benefit deeply from consistent hydration. Aim for 8 glasses today.',
       const Color(0xFF29B6F6)),
      if (h >= 18)
        ('🌙', 'Evening Wind-Down',
         'Dim lights, step away from screens, and let your nervous system exhale. You\'ve done enough today.',
         const Color(0xFF7986CB))
      else
        ('📓', 'Capture Your Feelings',
         'Spend 5 minutes writing freely. No filter, no judgement — just honest expression.',
         _iKPink),
      ('🎵', 'Sound Healing',
       '432 Hz music has been shown to reduce anxiety and promote emotional release. Try it while resting.',
       const Color(0xFF9575CD)),
    ];
  }
}

// ═══════════════════════════════════════════════════════════
//  HEALING OPTIONS
// ═══════════════════════════════════════════════════════════

const List<_HealingOption> _kHealingOptions = [
  _HealingOption(
    '🌸', 'Affirmations',
    'Gentle truths to anchor you',
    Color(0xFFAB5CF2),
    [
      'I am worthy of love exactly as I am 💜',
      'My emotions are valid and beautiful 🌸',
      'I trust my body\'s wisdom ✨',
      'I am healing, growing, and becoming 🌙',
      'My sensitivity is my superpower 💫',
      'I choose gentleness with myself today 🌿',
    ],
  ),
  _HealingOption(
    '🧘‍♀️', 'Meditation',
    'Moments of sacred stillness',
    Color(0xFF7986CB),
    [
      'Find a comfortable position and close your eyes gently 🌙',
      'Take 3 slow deep breaths, releasing any tension 🌬️',
      'Visualise a warm golden light filling your chest with each inhale ✨',
      'As you exhale, let go of anything weighing on you 🍃',
      'Rest here for as long as you need. You are safe 💜',
    ],
  ),
  _HealingOption(
    '🌬️', 'Breathing',
    'Return to your breath, return to peace',
    Color(0xFF4FC3F7),
    [
      'Sit comfortably with your spine tall 🪷',
      'Inhale slowly for 4 counts through your nose 🌬️',
      'Hold gently for 4 counts ✨',
      'Exhale fully for 6 counts through your mouth 🍃',
      'Pause for 2 counts before the next breath 💜',
      'Repeat 5 times — feel your nervous system soften 🌙',
    ],
  ),
  _HealingOption(
    '💜', 'Emotional Release',
    'Safe space to feel and heal',
    Color(0xFFFF69B4),
    [
      'Place one hand on your heart and one on your belly 🌸',
      'Acknowledge: "I feel _____ and that is completely okay" 💜',
      'Breathe into that feeling without trying to fix it ✨',
      'Ask gently: "What does this feeling need right now?" 🌙',
      'Offer yourself kindness — a warm drink, a journal, a hug 🌿',
      'You are safe to feel everything. Emotions are not permanent 💫',
    ],
  ),
];

// ═══════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsState();
}

class _AIInsightsState extends State<AIInsightsScreen>
    with TickerProviderStateMixin {

  // ─── Animation controllers ────────────────────────────────
  late AnimationController _glowCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;

  // ─── Particles ────────────────────────────────────────────
  final List<_IStar> _particles = [];
  final math.Random _rng = math.Random();

  // ─── UI state ─────────────────────────────────────────────
  int? _expandedHealing;
  List<String> _moodHistory = [];

  // ─── Affirmation rotation ─────────────────────────────────
  late int _affirmIdx;

  static const List<String> _kAffirms = [
    'You are worthy of love exactly as you are 💜',
    'Your feelings are valid and beautiful 🌸',
    'Every emotion is a messenger, not an enemy ✨',
    'You are stronger than you know 🌙',
    "Healing is not linear — and that's okay 💫",
    'You radiate light even on your darkest days 🌟',
    'Your sensitivity is your superpower 💜',
    'Be gentle with yourself today 🌸',
    'Your body is wise and working in your favour 🌿',
    'This feeling is temporary — you will rise again 💜',
  ];

  // ─── Lifecycle ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _affirmIdx = DateTime.now().day % _kAffirms.length;

    _glowCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _particleCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 5))..repeat();

    _shimmerCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat();

    for (int i = 0; i < 32; i++) {
      _particles.add(_IStar(rng: _rng));
    }

    _loadMoodHistory();
  }

  Future<void> _loadMoodHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _moodHistory = prefs.getStringList('mood_history') ?? [];
      });
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _iKBg,
      body: Stack(
        children: [
          // Background
          _IBackground(size: size),
          // Particle system
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _IParticlePainter(
                  particles: _particles, progress: _particleCtrl.value),
            ),
          ),
          // Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        _headerBar(user),
                        const SizedBox(height: 22),
                        _dailySummaryCard(user),
                        const SizedBox(height: 26),
                        _sectionTitle('AI Insights', '✨'),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                // Horizontal insight cards
                SliverToBoxAdapter(child: _insightCards(user)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        _sectionTitle('Emotional Trends', '💜'),
                        const SizedBox(height: 14),
                        _trendGraphs(),
                        const SizedBox(height: 28),
                        _sectionTitle('AI Predictions', '🔮'),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                // Prediction cards
                SliverToBoxAdapter(child: _predictionCards(user)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        _sectionTitle('Recommendations', '🌿'),
                        const SizedBox(height: 14),
                        _recommendationCards(user),
                        const SizedBox(height: 28),
                        _sectionTitle('Healing Space', '🌸'),
                        const SizedBox(height: 14),
                        _healingSpace(),
                        const SizedBox(height: 28),
                        _affirmationCard(),
                        const SizedBox(height: 38),
                      ],
                    ),
                  ),
                ),
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
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.maybePop(context);
          },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
              border: Border.all(color: Colors.white.withOpacity(0.14), width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Insights',
                style: TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w800, letterSpacing: 0.2),
              ),
              Text(
                'Emotional Intelligence • ${_LunarAnalytics.cyclePhase(user).replaceFirst(
                    _LunarAnalytics.cyclePhase(user)[0],
                    _LunarAnalytics.cyclePhase(user)[0].toUpperCase())} Phase',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12.5),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _floatAnim.value * 0.55),
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.20),
                      _iKPurple.withOpacity(0.80),
                      const Color(0xFF5C2DB8),
                    ],
                    stops: const [0.0, 0.40, 1.0],
                    center: const Alignment(-0.2, -0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _iKPurple.withOpacity(_glowAnim.value * 0.55),
                      blurRadius: 20, spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF69B4)
                          .withOpacity(_glowAnim.value * 0.18),
                      blurRadius: 14,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white
                        .withOpacity(0.15 * _glowAnim.value),
                    width: 1.2,
                  ),
                ),
                child: const Center(
                    child: Text('🌙', style: TextStyle(fontSize: 22))),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  DAILY SUMMARY CARD
  // ─────────────────────────────────────────────────────────
  Widget _dailySummaryCard(UserProvider user) {
    final phase = _LunarAnalytics.cyclePhase(user);
    final phaseColors = <String, List<Color>>{
      'menstrual':  [const Color(0xFFB05C8A), const Color(0xFF8B3A6A)],
      'follicular': [const Color(0xFF9B59B6), const Color(0xFF8E2DE2)],
      'ovulation':  [const Color(0xFFFF69B4), const Color(0xFFAB5CF2)],
      'luteal':     [const Color(0xFF7B68EE), const Color(0xFF6A5ACD)],
    };
    final colors = phaseColors[phase] ?? [_iKPurple, _iKDeep];

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  colors[0].withOpacity(0.55),
                  colors[1].withOpacity(0.35),
                  _iKPink.withOpacity(0.18),
                ],
              ),
              border: Border.all(
                  color: colors[0].withOpacity(_glowAnim.value * 0.7),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(_glowAnim.value * 0.38),
                  blurRadius: 36, spreadRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF69F0AE)),
                              ),
                              const SizedBox(width: 5),
                              const Text('AI Active',
                                  style: TextStyle(color: Colors.white,
                                      fontSize: 11, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      const Text('Today\'s Insight',
                          style: TextStyle(
                              color: Colors.white, fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                        _LunarAnalytics.dailySummary(user),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14.5, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      _miniPill(
                          '${_moodHistory.length} moods tracked this cycle', _iKPurple),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _floatAnim.value * 0.7),
                    child: const Text('🌙', style: TextStyle(fontSize: 52)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  INSIGHT CARDS  (horizontal scroll)
  // ─────────────────────────────────────────────────────────
  Widget _insightCards(UserProvider user) {
    final insights = _LunarAnalytics.insights(user);
    return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: insights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _insightCard(insights[i], i),
      ),
    );
  }

  Widget _insightCard(_Insight ins, int idx) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 210,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  ins.accent.withOpacity(0.22),
                  ins.accent.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              border: Border.all(
                  color: ins.accent.withOpacity(_glowAnim.value * 0.65),
                  width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: ins.accent.withOpacity(_glowAnim.value * 0.22),
                  blurRadius: 24, spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(ins.icon, style: const TextStyle(fontSize: 24)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: ins.accent.withOpacity(0.22),
                    ),
                    child: Text(ins.badge,
                        style: TextStyle(
                            color: ins.accent, fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(ins.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14.5,
                        fontWeight: FontWeight.w700, height: 1.25)),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(ins.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.62),
                          fontSize: 12, height: 1.45)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  TREND GRAPHS
  // ─────────────────────────────────────────────────────────
  Widget _trendGraphs() {
    final metrics = [
      (name: 'Mood Stability',  color: _iKPurple,             spots: _LunarAnalytics.moodTrend(),   icon: '😊'),
      (name: 'Stress Level',    color: const Color(0xFFFF7043), spots: _LunarAnalytics.stressTrend(), icon: '😰'),
      (name: 'Energy Trend',    color: const Color(0xFF66BB6A), spots: _LunarAnalytics.energyTrend(), icon: '⚡'),
      (name: 'Sleep Quality',   color: const Color(0xFF7986CB), spots: _LunarAnalytics.sleepTrend(),  icon: '💤'),
    ];

    return Column(
      children: [
        // 2×2 grid
        Row(
          children: [
            Expanded(child: _singleGraph(metrics[0].name, metrics[0].color,
                metrics[0].spots, metrics[0].icon)),
            const SizedBox(width: 12),
            Expanded(child: _singleGraph(metrics[1].name, metrics[1].color,
                metrics[1].spots, metrics[1].icon)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _singleGraph(metrics[2].name, metrics[2].color,
                metrics[2].spots, metrics[2].icon)),
            const SizedBox(width: 12),
            Expanded(child: _singleGraph(metrics[3].name, metrics[3].color,
                metrics[3].spots, metrics[3].icon)),
          ],
        ),
      ],
    );
  }

  Widget _singleGraph(String name, Color color, List<FlSpot> spots, String icon) {
    final last = spots.last.y;
    final prev = spots[spots.length - 2].y;
    final isUp = last >= prev;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 148,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(name,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
                Icon(
                  isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: isUp ? const Color(0xFF69F0AE) : const Color(0xFFFF7043),
                  size: 16,
                ),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, anim, __) {
                    final animSpots = spots.map((s) =>
                        FlSpot(s.x, s.y * anim)).toList();
                    return LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minY: 0, maxY: 5,
                        lineBarsData: [
                          LineChartBarData(
                            spots: animSpots,
                            isCurved: true,
                            curveSmoothness: 0.4,
                            color: color,
                            barWidth: 2.2,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (s, _, __, ___) =>
                                  FlDotCirclePainter(
                                      radius: s == spots.last ? 3.5 : 0,
                                      color: color,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  color.withOpacity(0.28),
                                  color.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PREDICTION CARDS  (horizontal scroll)
  // ─────────────────────────────────────────────────────────
  Widget _predictionCards(UserProvider user) {
    final preds = _LunarAnalytics.predictions(user);
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: preds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _predictionCard(preds[i]),
      ),
    );
  }

  Widget _predictionCard(_AIPrediction p) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  p.color.withOpacity(0.25),
                  p.color.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                  color: p.color.withOpacity(_glowAnim.value * 0.6),
                  width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: p.color.withOpacity(_glowAnim.value * 0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 22)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: p.color.withOpacity(0.2),
                    ),
                    child: Text(p.timeframe,
                        style: TextStyle(
                            color: p.color, fontSize: 9.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(p.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13.5,
                        fontWeight: FontWeight.w700, height: 1.2)),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(p.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.58),
                          fontSize: 11.5, height: 1.4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  RECOMMENDATIONS
  // ─────────────────────────────────────────────────────────
  Widget _recommendationCards(UserProvider user) {
    final recs = _LunarAnalytics.recommendations(user);
    return Column(
      children: recs.map((r) {
        final (icon, title, desc, color) = r;
        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
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
                    color: color.withOpacity(0.08),
                    border: Border.all(
                        color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.18),
                          border: Border.all(
                              color: color.withOpacity(0.45), width: 1),
                        ),
                        child: Center(
                            child: Text(icon,
                                style: const TextStyle(fontSize: 21))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: TextStyle(
                                    color: color, fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(desc,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12.5, height: 1.4)),
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
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HEALING SPACE
  // ─────────────────────────────────────────────────────────
  Widget _healingSpace() {
    return Column(
      children: _kHealingOptions.asMap().entries.map((e) {
        final i = e.key;
        final opt = e.value;
        final isExpanded = _expandedHealing == i;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _expandedHealing = isExpanded ? null : i;
              });
            },
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isExpanded
                            ? [
                                opt.color.withOpacity(0.32),
                                opt.color.withOpacity(0.14),
                                Colors.white.withOpacity(0.04),
                              ]
                            : [
                                opt.color.withOpacity(0.1),
                                Colors.white.withOpacity(0.03),
                              ],
                      ),
                      border: Border.all(
                        color: isExpanded
                            ? opt.color.withOpacity(_glowAnim.value * 0.75)
                            : opt.color.withOpacity(0.28),
                        width: isExpanded ? 1.5 : 1,
                      ),
                      boxShadow: isExpanded
                          ? [
                              BoxShadow(
                                color: opt.color
                                    .withOpacity(_glowAnim.value * 0.28),
                                blurRadius: 28, spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: opt.color.withOpacity(
                                    isExpanded ? 0.28 : 0.15),
                                border: Border.all(
                                    color: opt.color.withOpacity(0.45),
                                    width: 1),
                              ),
                              child: Center(
                                  child: Text(opt.emoji,
                                      style: const TextStyle(fontSize: 22))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(opt.title,
                                      style: TextStyle(
                                          color: opt.color, fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                  Text(opt.desc,
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.55),
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(Icons.expand_more_rounded,
                                  color: opt.color.withOpacity(0.7), size: 22),
                            ),
                          ],
                        ),
                        // Expanded steps
                        if (isExpanded) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: opt.color.withOpacity(0.2),
                          ),
                          const SizedBox(height: 14),
                          ...opt.steps.asMap().entries.map((se) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 22, height: 22,
                                    margin: const EdgeInsets.only(
                                        top: 1, right: 10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: opt.color.withOpacity(0.18),
                                      border: Border.all(
                                          color: opt.color.withOpacity(0.45),
                                          width: 1),
                                    ),
                                    child: Center(
                                      child: Text('${se.key + 1}',
                                          style: TextStyle(
                                              color: opt.color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(se.value,
                                        style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.75),
                                            fontSize: 13.5,
                                            height: 1.45)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  AFFIRMATION CARD
  // ─────────────────────────────────────────────────────────
  Widget _affirmationCard() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _affirmIdx = (_affirmIdx + 1) % _kAffirms.length;
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [
                    _iKPink.withOpacity(0.22),
                    _iKPurple.withOpacity(0.18),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
                border: Border.all(
                    color: _iKPink.withOpacity(_glowAnim.value * 0.65),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _iKPink.withOpacity(_glowAnim.value * 0.22),
                    blurRadius: 32, spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnim.value,
                      child: const Text('💜', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim, child: child),
                    child: Text(
                      _kAffirms[_affirmIdx],
                      key: ValueKey(_affirmIdx),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16.5,
                          fontWeight: FontWeight.w600, height: 1.55),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Tap for a new affirmation ✨',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String t, String emoji) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 20)),
    const SizedBox(width: 8),
    Text(t,
        style: const TextStyle(
            color: Colors.white, fontSize: 18,
            fontWeight: FontWeight.w700, letterSpacing: 0.2)),
  ]);

  Widget _miniPill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: color.withOpacity(0.18),
      border: Border.all(color: color.withOpacity(0.4), width: 1),
    ),
    child: Text(text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w500)),
  );
}

// ═══════════════════════════════════════════════════════════
//  DREAMY BACKGROUND
// ═══════════════════════════════════════════════════════════

class _IBackground extends StatelessWidget {
  final Size size;
  const _IBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.25,
          colors: [Color(0xFF2D0B5C), Color(0xFF180640), _iKBg],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -90, left: -55,
            child: _blob(300, const Color(0xFF9B59B6), 0.26)),
        Positioned(top: 60, right: -75,
            child: _blob(260, const Color(0xFFE91E8C), 0.16)),
        Positioned(top: size.height * 0.38, left: size.width * 0.45 - 140,
            child: _blob(290, const Color(0xFF7B2FF7), 0.13)),
        Positioned(bottom: 80, left: -60,
            child: _blob(280, const Color(0xFF6C3FC8), 0.2)),
        Positioned(bottom: 0, right: -50,
            child: _blob(230, _iKPink, 0.14)),
      ]),
    );
  }

  Widget _blob(double s, Color c, double o) => Container(
    width: s, height: s,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
          colors: [c.withOpacity(o), Colors.transparent]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  PARTICLE SYSTEM
// ═══════════════════════════════════════════════════════════

class _IStar {
  late double x, y, speed, size, opacity, angle;
  _IStar({required math.Random rng}) { _reset(rng); }
  void _reset(math.Random rng) {
    x       = rng.nextDouble();
    y       = rng.nextDouble();
    speed   = 0.00012 + rng.nextDouble() * 0.00022;
    size    = 0.7 + rng.nextDouble() * 2.3;
    opacity = 0.22 + rng.nextDouble() * 0.5;
    angle   = rng.nextDouble() * math.pi * 2;
  }
}

class _IParticlePainter extends CustomPainter {
  final List<_IStar> particles;
  final double progress;
  _IParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = (p.x + math.cos(p.angle) * p.speed * progress * 120) % 1.0;
      final y = (p.y - p.speed * progress * 220) % 1.0;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        Paint()
          ..color = Colors.white.withOpacity(p.opacity * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );

      if (p.size > 2.0) {
        final sp = Paint()
          ..color = _iKPurple.withOpacity(p.opacity * 0.4)
          ..strokeWidth = 0.55;
        final cx = x * size.width;
        final cy = y * size.height;
        canvas.drawLine(Offset(cx - 4.5, cy), Offset(cx + 4.5, cy), sp);
        canvas.drawLine(Offset(cx, cy - 4.5), Offset(cx, cy + 4.5), sp);
      }
    }
  }

  @override
  bool shouldRepaint(_IParticlePainter old) => old.progress != progress;
}
