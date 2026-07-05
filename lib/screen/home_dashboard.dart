import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import '../core/providers/app_provider.dart';
import '../core/providers/lunar_data_provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/models/chat_message.dart' show EmotionTag;
import '../services/streak_service.dart';
import '../services/lunar_ai_service.dart';
import '../services/relationship_service.dart';
import 'mood_tracking_screen.dart';
import 'journal_screen.dart';
import 'cycle_tracker_screen.dart';
import 'period_screen.dart';
import 'ai_voice_screen.dart';
import 'ai_insights_screen.dart';
import 'community_tabs_screen.dart';
import 'sleep_screen.dart';
import 'pregnancy_screen.dart';
import '../core/providers/weather_provider.dart';
import '../core/providers/memory_provider.dart';
import '../core/models/emotional_weather.dart';
import '../core/models/emotional_memory.dart' show EmotionalProfile;
import 'emotional_weather_screen.dart';
import 'profile_screen.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/check_in_provider.dart';
import '../core/models/check_in_model.dart';
import '../core/services/intent_greeting_service.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/intent_greeting_service.dart';

// ── Local design tokens ─────────────────────────────────────
const Color _hBg = Color(0xFF0A0118);
const Color _hPurple = Color(0xFFAB5CF2);
const Color _hPink = Color(0xFFFF69B4);
const Color _hGold = Color(0xFFFFD700);
const Color _hTeal = Color(0xFF4FC3F7);
const Color _hGreen = Color(0xFF66BB6A);
const Color _hIndigo = Color(0xFF7986CB);
const Color _hWarm = Color(0xFFFFB74D);

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _orbitController;
  late AnimationController _particleController;
  late AnimationController _breatheCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _entryCtrl;

  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _breatheAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;

  int _aiSubtitleIdx = 0;
  Timer? _subtitleTimer;

  final List<_StarParticle> _particles = [];
  final List<_HeartParticle> _hearts = [];
  final math.Random _rng = math.Random();

  int waterGlasses = 5;
  double sleepHours = 7.5;
  double weightKg = 58.0;
  double tempC = 36.6;

  final Set<int> _careCompleted = {};
  int? _pressedAction;

  // ── Sacred entry veil ────────────────────────────────────
  bool _entryVeilDone = false;

  // ── Streak & milestone ────────────────────────────────────
  StreakData? _streakData;
  bool _milestoneVisible = false;
  late AnimationController _milestoneCtrl;
  late Animation<double> _milestoneAnim;

  static const _aiSubtitles = [
    'Your emotional wellness companion ✨',
    'Always listening, always caring 💜',
    'Powered by lunar intelligence 🌙',
    'Here to support your journey 🌸',
    'Ask me anything about your cycle 🔮',
  ];

  static const _affirmations = [
    '"Your body is wise. Your emotions are valid. You are enough." 💜',
    '"Every phase of your cycle is sacred. Honor them all." 🌙',
    '"You carry magic in your cells. Rest is not weakness." ✨',
    '"Your softness is your power. Your sensitivity is your gift." 🌸',
    '"You are not behind. You are exactly where you need to be." 💫',
  ];

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
        CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _entryCtrl.forward();

    // Shimmer – kept for unused section methods, not displayed in build
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _orbitController, curve: Curves.linear),
    );

    _subtitleTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted)
        setState(
            () => _aiSubtitleIdx = (_aiSubtitleIdx + 1) % _aiSubtitles.length);
    });

    // ── Streak check-in ──────────────────────────────────────
    _milestoneCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _milestoneAnim =
        CurvedAnimation(parent: _milestoneCtrl, curve: Curves.easeOutCubic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final chat = context.read<ChatProvider>();
        final lunarData = context.read<LunarDataProvider>();
        final memory = context.read<MemoryProvider>();
        final app = context.read<AppProvider>();
        context.read<WeatherProvider>().refresh(
              profile: chat.emotionalProfile,
              memory: memory,
              lunarData: lunarData,
              userName: app.userName,
            );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = StreakService.checkIn();
      if (mounted) {
        setState(() => _streakData = data);
        if (data.newMilestone != null) {
          _milestoneVisible = true;
          _milestoneCtrl.forward();
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              _milestoneCtrl.reverse().then((_) {
                if (mounted) setState(() => _milestoneVisible = false);
              });
            }
          });
        }
      }
    });

    for (int i = 0; i < 10; i++) _particles.add(_StarParticle(rng: _rng));
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    _orbitController.dispose();
    _particleController.dispose();
    _breatheCtrl.dispose();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _milestoneCtrl.dispose();
    _subtitleTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  SMART LOGIC
  // ─────────────────────────────────────────────────────────

  /// Cycle + time + phase aware emotional greeting
  String _greeting(UserProvider user) {
    final h = DateTime.now().hour;
    final d = DateTime.now().day;
    final phase = _phaseOf(user);
    if (phase == _CyclePhase.period) {
      const opts = [
        'You deserve a gentle day today 🌙',
        'Rest is sacred right now 💜',
        'Be soft with yourself today 🌸'
      ];
      return opts[d % opts.length];
    }
    if (phase == _CyclePhase.ovulation) {
      const opts = [
        'Your energy feels stronger today ✨',
        'High glow day — own it! 🌟',
        'You are radiant right now 💫'
      ];
      return opts[d % opts.length];
    }
    if (phase == _CyclePhase.luteal) {
      const opts = [
        'Take extra care tonight 💜',
        'Emotions are data, not weakness 🌙',
        'Honor your inner rhythm 💜'
      ];
      return opts[d % opts.length];
    }
    if (phase == _CyclePhase.follicular) {
      const opts = [
        'Your light is rising 🌸',
        'New cycle, new energy ✨',
        'Fresh beginnings today 🌱'
      ];
      return opts[d % opts.length];
    }
    if (h >= 5 && h < 12) {
      const opts = [
        'You deserve a beautiful day ☀️',
        'Rise and glow 🌸',
        'Morning magic is yours ✨'
      ];
      return opts[d % opts.length];
    } else if (h >= 12 && h < 17) {
      const opts = [
        'Keep shining bright 💫',
        'Midday glow ✨',
        'Your light is beautiful 🌻'
      ];
      return opts[d % opts.length];
    } else if (h >= 17 && h < 21) {
      const opts = [
        'Golden hour — you glowed today 🧡',
        'The evening holds magic 🌙',
        'Wind down gently 💜'
      ];
      return opts[d % opts.length];
    } else {
      const opts = [
        'Rest well, you deserve it 🌛',
        'Let the moon hold you 💜',
        'Stars are with you 🌙'
      ];
      return opts[d % opts.length];
    }
  }

  /// Emotional weather label based on cycle phase + health data
  String _emotionalWeather(UserProvider user) {
    if (waterGlasses < 4) return 'Hydration Day 💧';
    if (sleepHours < 6.5) return 'Soft Recovery Mode 😴';
    switch (_phaseOf(user)) {
      case _CyclePhase.period:
        return 'Soft Energy Day 🌸';
      case _CyclePhase.follicular:
        return 'Rising Glow Energy ✨';
      case _CyclePhase.ovulation:
        return 'High Glow Day 🌟';
      case _CyclePhase.luteal:
        return 'Emotional Tide Tonight 💜';
      default:
        final h = DateTime.now().hour;
        if (h >= 21 || h < 5) return 'Dreamy Mood 🌙';
        return 'Calm Energy ✨';
    }
  }

  /// Accent color matched to current emotional weather
  Color _weatherColor(UserProvider user) {
    if (waterGlasses < 4) return _hTeal;
    if (sleepHours < 6.5) return _hIndigo;
    switch (_phaseOf(user)) {
      case _CyclePhase.period:
        return _hPink;
      case _CyclePhase.follicular:
        return _hPurple;
      case _CyclePhase.ovulation:
        return _hGold;
      case _CyclePhase.luteal:
        return _hIndigo;
      default:
        return _hPurple;
    }
  }

  /// Dynamic AI insight based on health data + phase
  String _aiInsight(UserProvider user) {
    if (waterGlasses < 4)
      return 'You need more hydration. Try ${8 - waterGlasses} more glasses today 💧';
    if (sleepHours < 6.5)
      return 'Short sleep detected. Low energy expected — be gentle today 😴';
    switch (_phaseOf(user)) {
      case _CyclePhase.period:
        return 'During menstruation, warmth and rest are powerful healers 🌸';
      case _CyclePhase.ovulation:
        return 'You are at peak energy right now. Your body is radiant and magnetic ✨';
      case _CyclePhase.luteal:
        return 'Emotional shifts are normal. You are not too much — you are human 💜';
      case _CyclePhase.follicular:
        return 'Energy is rebuilding. A wonderful time to start something new 🌱';
      default:
        break;
    }
    if (DateTime.now().hour >= 21)
      return 'Wind down gently. Sleep is when your body does its deepest healing 🌙';
    if (sleepHours >= 7.5)
      return 'Beautiful sleep this week. Your hormones thank you ✨';
    return "I'm here with you, always. How are you feeling right now? 🌙";
  }

  /// Cycle day text for orbital center
  String _cycleDayLabel(UserProvider user) {
    if (user.lastPeriodDate == null) return 'Cycle Day –';
    final day = DateTime.now().difference(user.lastPeriodDate!).inDays + 1;
    return 'Cycle Day $day';
  }

  /// Phase label for orbital center
  String _phaseLabel(UserProvider user) {
    switch (_phaseOf(user)) {
      case _CyclePhase.period:
        return 'Menstrual\nPhase';
      case _CyclePhase.follicular:
        return 'Follicular\nPhase';
      case _CyclePhase.ovulation:
        return 'Fertile\nWindow';
      case _CyclePhase.luteal:
        return 'Luteal\nPhase';
      default:
        return 'Cycle\nTracker';
    }
  }

  /// Core gradient colors for each phase
  List<Color> _phaseColors(UserProvider user) {
    switch (_phaseOf(user)) {
      case _CyclePhase.period:
        return [
          const Color(0xFFB05C8A).withOpacity(0.9),
          const Color(0xFF8B3A6A).withOpacity(0.7),
          const Color(0xFF5C1A4A).withOpacity(0.3)
        ];
      case _CyclePhase.follicular:
        return [
          const Color(0xFF9B59B6).withOpacity(0.9),
          const Color(0xFF8E2DE2).withOpacity(0.7),
          const Color(0xFF4A00E0).withOpacity(0.3)
        ];
      case _CyclePhase.ovulation:
        return [
          const Color(0xFFFF69B4).withOpacity(0.92),
          const Color(0xFFAB5CF2).withOpacity(0.72),
          const Color(0xFF5C2DB8).withOpacity(0.3)
        ];
      case _CyclePhase.luteal:
        return [
          const Color(0xFF7B68EE).withOpacity(0.9),
          const Color(0xFF6A5ACD).withOpacity(0.7),
          const Color(0xFF483D8B).withOpacity(0.3)
        ];
      default:
        return [
          const Color(0xFFFF69B4).withOpacity(0.92),
          const Color(0xFFAB5CF2).withOpacity(0.72),
          const Color(0xFF5C2DB8).withOpacity(0.3)
        ];
    }
  }

  /// Primary accent color for each phase (ring/glow color)
  Color _phaseRingColor(UserProvider user) {
    switch (_phaseOf(user)) {
      case _CyclePhase.period:
        return const Color(0xFFB05C8A);
      case _CyclePhase.follicular:
        return const Color(0xFF9B59B6);
      case _CyclePhase.ovulation:
        return const Color(0xFFFF69B4);
      case _CyclePhase.luteal:
        return const Color(0xFF7B68EE);
      default:
        return const Color(0xFFAB5CF2);
    }
  }

  /// Determine cycle phase from last period date
  _CyclePhase _phaseOf(UserProvider user) {
    if (user.lastPeriodDate == null) return _CyclePhase.unknown;
    final day = DateTime.now().difference(user.lastPeriodDate!).inDays + 1;
    if (day <= 5) return _CyclePhase.period;
    if (day <= 13) return _CyclePhase.follicular;
    if (day <= 16) return _CyclePhase.ovulation;
    if (day <= 28) return _CyclePhase.luteal;
    return _CyclePhase.unknown;
  }

  /// Maps the user's dominant chat emotion to an orb glow color.
  /// Blended additively into the hero orb boxShadow for emotional reactivity.
  Color _emotionOrbColor(EmotionTag? emotion) => switch (emotion) {
        EmotionTag.anxious => const Color(0xFF4FC3F7), // calming teal
        EmotionTag.sad => const Color(0xFF7986CB), // soft indigo
        EmotionTag.lonely => const Color(0xFF9575CD), // violet
        EmotionTag.stressed => const Color(0xFF7986CB), // indigo calm
        EmotionTag.happy => const Color(0xFFFFD700), // warm gold
        EmotionTag.energetic => const Color(0xFF66BB6A), // vibrant green
        EmotionTag.emotional => const Color(0xFFFF69B4), // rose pink
        EmotionTag.tired => const Color(0xFF5C6BC0), // muted blue-indigo
        EmotionTag.period => const Color(0xFFB05C8A), // warm mauve
        _ => const Color(0xFFAB5CF2), // default lunar purple
      };

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final lunarData = context.watch<LunarDataProvider>();
    final chat = context.watch<ChatProvider>();
    final weatherProv = context.watch<WeatherProvider>();
    final size = MediaQuery.of(context).size;

    // ── Override static health vars with real live data ───────────────
    waterGlasses = lunarData.todayWaterGlasses;
    sleepHours = lunarData.lastSleepHours;
    weightKg = lunarData.lastWeightKg;
    tempC = lunarData.lastTempC;

    return Scaffold(
      backgroundColor: _hBg,
      body: Stack(
        children: [
          _DreamyBackground(size: size),
          // Emotion-reactive atmosphere layer — shifts hue based on mood/time
          _EmotionAtmosphereLayer(
            size: size,
            emotion: chat.dominantEmotion,
            hour: DateTime.now().hour,
            isPregnant: lunarData.isPregnant,
            isSleepDeprived: sleepHours < 6.0,
            animation: _glowAnim,
          ),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  particles: _particles,
                  hearts: _hearts,
                  progress: _particleController.value,
                ),
              ),
            ),
          ),
          // Sacred entry veil — soft moon-white light that gently fades on first open
          if (!_entryVeilDone)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 0.0),
              duration: const Duration(milliseconds: 1800),
              curve: Curves.easeOutCubic,
              onEnd: () => setState(() => _entryVeilDone = true),
              builder: (_, opacity, __) => IgnorePointer(
                child: Container(
                  color: const Color(0xFFD8A8FF).withOpacity(opacity * 0.28),
                ),
              ),
            ),
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
                        const SizedBox(height: 18),
                        // ── Greeting bar ─────────────────────────────────────
                        _staggeredSection(
                            _emotionalCommandBar(user, chat, weatherProv), 0),
                        const SizedBox(height: 22),
                        // ── Orb Hero — the emotional center ──────────────────
                        _staggeredSection(_heroSection(user, chat), 0),
                        const SizedBox(height: 24),
                        // ── Single primary CTA ────────────────────────────────
                        _staggeredSection(_primaryCTAButton(context), 1),
                        const SizedBox(height: 22),
                        // ── Today's insight card ──────────────────────────────
                        _staggeredSection(
                            _aiInsightOfDay(chat, weatherProv), 1),
                        const SizedBox(height: 16),
                        // ── Intent-personalised nudge card ────────────────────
                        _staggeredSection(_intentHeroCard(), 2),
                        const SizedBox(height: 20),
                        // ── Wellness snapshot — 4 compact tiles ───────────────
                        _staggeredSection(
                            _wellnessSnapshot(context, lunarData, user), 2),
                        const SizedBox(height: 18),
                        // ── Streak ribbon (conditional) ───────────────────────
                        if (_streakData != null &&
                            _streakData!.current > 0) ...[
                          _staggeredSection(_streakRibbon(_streakData!), 2),
                          const SizedBox(height: 16),
                        ],
                        // ── Daily check-in ritual ─────────────────────────────
                        _staggeredSection(_healingCheckInCard(context), 3),
                        const SizedBox(height: 18),
                        // ── Pregnancy journey entry point ─────────────────────
                        _staggeredSection(_pregnancyCard(context), 3),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Milestone achievement overlay ──────────────────
          if (_milestoneVisible && _streakData?.newMilestone != null)
            _milestoneOverlay(_streakData!.newMilestone!),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  INTENT HERO CARD — Personalised greeting based on journey focus
  // ─────────────────────────────────────────────────────────
  Widget _intentHeroCard() {
    return Consumer<LunarAuthProvider>(
      builder: (context, auth, _) {
        final intent = auth.userIntent;
        if (intent == null) return const SizedBox.shrink();
        final greeting = IntentGreetingService.getGreeting(intent);
        final nudge = IntentGreetingService.getNudge(intent);
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _hPurple.withOpacity(0.18),
                    _hPink.withOpacity(0.10),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
                border: Border.all(
                  color: _hPurple.withOpacity(0.28),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    intent.emoji,
                    style: const TextStyle(fontSize: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nudge,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.55),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  //  STREAK RIBBON — Emotional return loop display
  // ─────────────────────────────────────────────────────────
  Widget _streakRibbon(StreakData streak) {
    final isFireStreak = streak.current >= 7;
    final emoji = streak.current >= 30
        ? '🌕'
        : streak.current >= 14
            ? '💜'
            : streak.current >= 7
                ? '🌙'
                : streak.current >= 3
                    ? '✨'
                    : '🌱';
    final label = streak.current == 1
        ? 'First night with Lunar'
        : '${streak.current} night healing streak';
    final nextM = streak.nextMilestone;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: isFireStreak
                    ? [
                        _hGold.withOpacity(0.22),
                        _hPurple.withOpacity(0.15),
                        _hPink.withOpacity(0.08)
                      ]
                    : [
                        _hPurple.withOpacity(0.18),
                        _hPink.withOpacity(0.10),
                        Colors.white.withOpacity(0.03)
                      ],
              ),
              border: Border.all(
                color: isFireStreak
                    ? _hGold.withOpacity(0.45 * _glowAnim.value)
                    : _hPurple.withOpacity(0.35 * _glowAnim.value),
                width: 1.0,
              ),
            ),
            child: Row(children: [
              // Animated orb
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      isFireStreak
                          ? _hGold.withOpacity(0.7 * _pulseAnim.value)
                          : _hPurple.withOpacity(0.7 * _pulseAnim.value),
                      Colors.transparent,
                    ]),
                    boxShadow: [
                      BoxShadow(
                        color: isFireStreak
                            ? _hGold.withOpacity(0.35 * _pulseAnim.value)
                            : _hPurple.withOpacity(0.35 * _pulseAnim.value),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 18))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(label,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                    if (nextM != null) ...[
                      const SizedBox(height: 5),
                      Row(children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: streak.progressToNext,
                              minHeight: 3,
                              backgroundColor: Colors.white.withOpacity(0.10),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  isFireStreak ? _hGold : _hPurple),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${nextM.emoji} ${nextM.requiredStreak}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.40),
                                fontSize: 10.5)),
                      ]),
                    ],
                  ])),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${streak.current}',
                    style: TextStyle(
                        color: isFireStreak ? _hGold : _hPurple,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                Text('nights',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.38), fontSize: 10)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  MILESTONE OVERLAY — Unlocked achievement toast
  // ─────────────────────────────────────────────────────────
  Widget _milestoneOverlay(LunarMilestone milestone) {
    return Positioned(
      bottom: 90,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _milestoneAnim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
              .animate(_milestoneAnim),
          child: GestureDetector(
            onTap: () {
              _milestoneCtrl.reverse().then((_) {
                if (mounted) setState(() => _milestoneVisible = false);
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _hGold.withOpacity(0.28 * _glowAnim.value),
                          _hPurple.withOpacity(0.22),
                          _hPink.withOpacity(0.12),
                        ],
                      ),
                      border: Border.all(
                          color: _hGold.withOpacity(0.5 * _glowAnim.value),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: _hGold.withOpacity(0.25 * _glowAnim.value),
                            blurRadius: 30,
                            spreadRadius: 4),
                      ],
                    ),
                    child: Row(children: [
                      // Glowing emoji orb
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              _hGold.withOpacity(0.5 * _pulseAnim.value),
                              _hPurple.withOpacity(0.3),
                              Colors.transparent,
                            ]),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    _hGold.withOpacity(0.4 * _pulseAnim.value),
                                blurRadius: 16,
                                spreadRadius: 3,
                              )
                            ],
                          ),
                          child: Center(
                              child: Text(
                                  milestone.emoji.length <= 2
                                      ? milestone.emoji
                                      : milestone.emoji.substring(0, 2),
                                  style: const TextStyle(fontSize: 24))),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Milestone Unlocked ✨',
                                style: TextStyle(
                                    color: _hGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text(milestone.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 5),
                            Text(milestone.message,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.68),
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4)),
                          ])),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  HEALING CHECK-IN â€” Mood picker + streak display
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _healingCheckInCard(BuildContext ctx) {
    return Consumer2<CheckInProvider, LunarAuthProvider>(
      builder: (context, checkIn, auth, _) {
        final intent = auth.userIntent;

        if (checkIn.hasTodayCheckIn) {
          // Post-check-in: streak + encouragement card
          final streak = checkIn.streakDays;
          final encouragement =
              CheckInProvider.encouragement(intent, checkIn.currentMood!);
          final streakEmoji = streak >= 30
              ? 'ðŸŒ•'
              : streak >= 14
                  ? 'ðŸ’œ'
                  : streak >= 7
                      ? 'ðŸ”¥'
                      : streak >= 3
                          ? 'âœ¨'
                          : 'ðŸŒ±';
          return AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _hPurple.withOpacity(0.20 * _glowAnim.value),
                        _hGold.withOpacity(0.10),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                    border: Border.all(
                      color: _hPurple.withOpacity(0.32 * _glowAnim.value),
                      width: 1.0,
                    ),
                  ),
                  child: Row(children: [
                    Text(streakEmoji,
                        style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (streak > 1) ...[
                            Text(
                              '$streak-Day Healing Streak',
                              style: TextStyle(
                                color: _hGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],
                          Text(
                            encouragement,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      checkIn.currentMood!.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ]),
                ),
              ),
            ),
          );
        }

        // Not checked in: mood picker card
        return AnimatedBuilder(
          animation: Listenable.merge([_glowAnim, _pulseAnim]),
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _hPurple.withOpacity(0.18 * _glowAnim.value),
                      _hPink.withOpacity(0.10),
                      Colors.white.withOpacity(0.03),
                    ],
                  ),
                  border: Border.all(
                    color: _hPurple.withOpacity(0.35 * _glowAnim.value),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hPurple.withOpacity(0.10 * _glowAnim.value),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              _hPurple.withOpacity(
                                  0.55 * _pulseAnim.value),
                              _hPurple.withOpacity(0.18),
                              Colors.transparent,
                            ]),
                          ),
                          child: const Center(
                              child: Text('ðŸŒ™',
                                  style: TextStyle(fontSize: 18))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Check-In',
                              style: TextStyle(
                                color: _hPurple.withOpacity(0.80),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'How are you feeling today?',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: CheckInMood.values.map((mood) {
                        return GestureDetector(
                          onTap: () =>
                              _onMoodSelected(ctx, mood, checkIn, auth),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(mood.emoji,
                                  style: const TextStyle(fontSize: 32)),
                              const SizedBox(height: 6),
                              Text(
                                mood.label,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onMoodSelected(BuildContext ctx, CheckInMood mood,
      CheckInProvider checkIn, LunarAuthProvider auth) async {
    HapticFeedback.mediumImpact();
    if (ctx.mounted) {
      ctx.read<ChatProvider>().markCheckInToday();
    }
    final milestone =
        await checkIn.submitCheckIn(mood, intent: auth.userIntent);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _SecondaryQuestionSheet(
        question: CheckInProvider.secondaryQuestion(auth.userIntent),
        options: CheckInProvider.secondaryOptions(auth.userIntent),
        onSelected: (reason) {
          checkIn.updateSecondary(reason);
          Navigator.of(sheetCtx).pop();
        },
        onSkip: () => Navigator.of(sheetCtx).pop(),
      ),
    );
    if (!mounted) return;
    if (milestone != null) {
      await showModalBottomSheet<void>(
        context: ctx,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetCtx) => _CheckInMilestoneSheet(
          milestone: milestone,
          onDismiss: () => Navigator.of(sheetCtx).pop(),
        ),
      );
    }
  }
  //  LUNAR'S NOTE TONIGHT — Daily AI message that feels alive
  // ─────────────────────────────────────────────────────────
  Widget _lunarNoteCard() {
    final note = LunarAIService.getTodayNote();

    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _breatheAnim]),
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _hPurple.withOpacity(0.14 * _breatheAnim.value),
                  _hPink.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              border: Border.all(
                  color: _hPurple.withOpacity(0.28 * _glowAnim.value),
                  width: 1.0),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _hPurple.withOpacity(0.55 * _pulseAnim.value),
                      Colors.transparent,
                    ]),
                  ),
                  child: const Center(
                      child: Text('🌙', style: TextStyle(fontSize: 16))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Lunar\'s Note Tonight',
                        style: TextStyle(
                            color: _hPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3)),
                    const SizedBox(height: 6),
                    Text(note,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 13.5,
                            fontStyle: FontStyle.italic,
                            height: 1.55)),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  TOP BAR
  // ─────────────────────────────────────────────────────────
  Widget _topBar(UserProvider user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile tap — slim, non-competing with the Orb
        GestureDetector(
          onTap: () => _nav(context, ProfileScreen()),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
              border: Border.all(
                color: const Color(0xFFAB5CF2).withOpacity(0.30),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFFD8A8FF),
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerGreeting(user),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  _greeting(user),
                  key: ValueKey(_greeting(user)),
                  style: TextStyle(
                    color: const Color(0xFFD8A8FF).withOpacity(0.82),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                _pill('Cycle: 28 days', const Color(0xFFAB5CF2),
                    const Color(0xFFD8A8FF)),
                const SizedBox(width: 6),
                _liveStatusPill(),
              ]),
            ],
          ),
        ),
        // Breathing moon companion orb
        AnimatedBuilder(
          animation: Listenable.merge([_floatAnim, _breatheAnim, _glowAnim]),
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _floatAnim.value * 0.55),
            child: Transform.scale(
              scale: _breatheAnim.value,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFFFFD700).withOpacity(_glowAnim.value * 0.9),
                    const Color(0xFFAB5CF2).withOpacity(0.35),
                    Colors.transparent,
                  ]),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700)
                          .withOpacity(_glowAnim.value * 0.55),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFFAB5CF2)
                          .withOpacity(_glowAnim.value * 0.35),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                    child: Text('🌙', style: TextStyle(fontSize: 26))),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  EMOTIONAL MEMORY CARD — AI remembers you
  // ─────────────────────────────────────────────────────────
  Widget _emotionalMemoryCard(ChatProvider chat) {
    final profile = chat.emotionalProfile;
    // Only show if we have meaningful emotional history
    if (profile.dominantEmotion == null &&
        profile.daysSinceLastVisit < 1 &&
        profile.anxietyMentions == 0 &&
        profile.stressMentions == 0) {
      return const SizedBox.shrink();
    }

    String memoryText;
    Color memoryColor;
    String memoryIcon;

    if (profile.daysSinceLastVisit >= 3) {
      memoryText =
          "I've been holding space for you 🌙 It's been ${profile.daysSinceLastVisit} days — welcome back.";
      memoryColor = _hPurple;
      memoryIcon = '🌙';
    } else if (profile.anxietyMentions >= 2) {
      memoryText =
          "I remember you've been carrying some anxiety lately. I'm right here with you 💜";
      memoryColor = _hIndigo;
      memoryIcon = '🌬️';
    } else if (profile.stressMentions >= 2) {
      memoryText =
          "You've felt overwhelmed recently. Take a breath — you're allowed to rest 🌸";
      memoryColor = _hPink;
      memoryIcon = '🌸';
    } else if (profile.sleepMentions >= 2) {
      memoryText =
          "Sleep has been hard lately. Your tiredness is valid — be gentle with yourself 😴";
      memoryColor = _hIndigo;
      memoryIcon = '😴';
    } else if (profile.hasPositiveStreak) {
      memoryText =
          "You've been in such a beautiful space lately ✨ I love seeing you flourish.";
      memoryColor = _hGold;
      memoryIcon = '✨';
    } else {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowAnim, _pulseAnim]),
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  memoryColor.withOpacity(0.18),
                  memoryColor.withOpacity(0.07),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              border: Border.all(
                color: memoryColor.withOpacity(0.38 * _glowAnim.value),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: memoryColor.withOpacity(0.14 * _glowAnim.value),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                // Memory orb
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: memoryColor.withOpacity(0.18),
                    border: Border.all(
                        color: memoryColor.withOpacity(0.40 * _glowAnim.value),
                        width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: memoryColor.withOpacity(0.22 * _pulseAnim.value),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                      child: Text(memoryIcon,
                          style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Lunar Remembers',
                            style: TextStyle(
                              color: memoryColor.withOpacity(0.85),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const Spacer(),
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, __) => Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: memoryColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: memoryColor
                                        .withOpacity(_pulseAnim.value * 0.8),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memoryText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 12.5,
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
    );
  }

  // ─────────────────────────────────────────────────────────
  //  DAILY EMOTIONAL READING CARD — premium daily wow moment
  // ─────────────────────────────────────────────────────────
  Widget _dailyReadingCard(WeatherProvider weatherProv) {
    final today = weatherProv.todayWeather;
    final accent = today.accentColor;
    final forecast = weatherProv.forecast;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EmotionalWeatherScreen(),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedBuilder(
            animation: Listenable.merge([_glowAnim, _pulseAnim]),
            builder: (_, __) => Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withOpacity(0.22),
                    accent.withOpacity(0.09),
                    _hPurple.withOpacity(0.06),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
                border: Border.all(
                  color: accent.withOpacity(0.42 * _glowAnim.value),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.18 * _glowAnim.value),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              accent.withOpacity(0.38),
                              accent.withOpacity(0.12),
                            ]),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    accent.withOpacity(0.30 * _pulseAnim.value),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(today.emoji,
                                style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Reading',
                              style: TextStyle(
                                color: accent.withOpacity(0.80),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              today.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: accent.withOpacity(0.5)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        accent.withOpacity(0.35),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Reading text
                  Text(
                    today.reading.split('\n\n').first,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13.5,
                      height: 1.55,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Healing intention
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: accent.withOpacity(0.10),
                      border: Border.all(
                          color: accent.withOpacity(0.22), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Text('💜', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            today.healingIntention,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Mini 3-day forecast strip
                  Row(
                    children: forecast.days.asMap().entries.map((e) {
                      final d = e.value;
                      final isT = e.key == 0;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: e.key < 2 ? 6 : 0),
                          padding: const EdgeInsets.symmetric(
                              vertical: 7, horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: d.accentColor.withOpacity(isT ? 0.18 : 0.08),
                            border: Border.all(
                              color:
                                  d.accentColor.withOpacity(isT ? 0.4 : 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(d.emoji,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                d.dayLabel ??
                                    (isT
                                        ? 'Today'
                                        : e.key == 1
                                            ? 'Tmrw'
                                            : '+2'),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Share row
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showWeatherShareSheet(context, today);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.share_outlined,
                            size: 13, color: accent.withOpacity(0.55)),
                        const SizedBox(width: 4),
                        Text(
                          'Share this reading',
                          style: TextStyle(
                            color: accent.withOpacity(0.55),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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

  /// Share sheet for the weather reading card on the home dashboard.
  void _showWeatherShareSheet(BuildContext ctx, DayWeather today) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HomeWeatherShareSheet(today: today),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  EMOTIONAL HEALING JOURNEY — evolution story card
  // ─────────────────────────────────────────────────────────
  Widget _healingJourneyCard(ChatProvider chat) {
    final profile = chat.emotionalProfile;
    final trajectory = profile.emotionalTrajectory;
    final rel = RelationshipService.current();

    // Build a meaningful healing story sentence based on context
    String journeyTitle;
    String journeyMessage;
    String journeyEmoji;
    Color journeyColor;

    final totalMsgs = rel.totalMessages;
    final isImproving = trajectory == 'improving';
    final isDeclining = trajectory == 'declining';

    if (totalMsgs < 3) {
      // Too early to show — only show once there's meaningful history
      return const SizedBox.shrink();
    }

    if (isImproving && totalMsgs >= 20) {
      journeyEmoji = '🌱';
      journeyColor = const Color(0xFF66BB6A);
      journeyTitle = 'Something is shifting in you';
      journeyMessage =
          'The way you talk about your feelings has changed. There\'s more gentleness in it now — more permission to feel without judgment. That\'s growth, even if it doesn\'t feel dramatic.';
    } else if (isDeclining) {
      journeyEmoji = '🌙';
      journeyColor = _hIndigo;
      journeyTitle = 'Tender season';
      journeyMessage =
          'You\'ve been in a harder place lately, and I want you to know — that doesn\'t erase the progress you\'ve made. Healing isn\'t a straight line. Coming back here is the whole point.';
    } else if (profile.anxietyMentions >= 3 && isImproving) {
      journeyEmoji = '🌬️';
      journeyColor = _hTeal;
      journeyTitle = 'Your anxiety is becoming more familiar';
      journeyMessage =
          'You\'ve been sitting with anxiety more honestly lately — naming it, not just running from it. That is a profound kind of bravery, even when it doesn\'t feel like it.';
    } else if (profile.relationshipMentions >= 2) {
      journeyEmoji = '💜';
      journeyColor = _hPurple;
      journeyTitle = 'Your heart is doing the work';
      journeyMessage =
          'Processing heartache takes more courage than most people realize. The fact that you keep showing up — keep talking about it, keep feeling it — that is healing in motion.';
    } else if (totalMsgs >= 50) {
      journeyEmoji = '✨';
      journeyColor = _hGold;
      journeyTitle = 'Look how far you\'ve come';
      journeyMessage =
          'You\'ve been on this journey for a while now. The moments of vulnerability, the hard days you named, the joy you let yourself feel — they all matter. You are not the same person who first opened Lunar.';
    } else if (totalMsgs >= 12) {
      journeyEmoji = '🌸';
      journeyColor = _hPink;
      journeyTitle = 'You keep coming back';
      journeyMessage =
          'Every time you return to this space, you\'re choosing yourself. Choosing to feel, to process, to be cared for. That choice, made again and again, is what healing is built from.';
    } else {
      journeyEmoji = '🌙';
      journeyColor = _hPurple;
      journeyTitle = 'Your healing has begun';
      journeyMessage =
          'You showed up. That\'s where every healing story starts — not with certainty or readiness, but with simply appearing.';
    }

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  journeyColor.withOpacity(0.16),
                  journeyColor.withOpacity(0.07),
                  _hPurple.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              border: Border.all(
                color: journeyColor.withOpacity(0.32 * _glowAnim.value),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: journeyColor.withOpacity(0.10 * _glowAnim.value),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header row
              Row(children: [
                // Pulsing journey orb
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        journeyColor.withOpacity(0.55 * _pulseAnim.value),
                        journeyColor.withOpacity(0.18),
                        Colors.transparent,
                      ]),
                      boxShadow: [
                        BoxShadow(
                          color:
                              journeyColor.withOpacity(0.25 * _pulseAnim.value),
                          blurRadius: 14,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Center(
                        child: Text(journeyEmoji,
                            style: const TextStyle(fontSize: 20))),
                  ),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'Your Healing Journey',
                    style: TextStyle(
                      color: journeyColor.withOpacity(0.70),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    journeyTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ]),
              ]),
              const SizedBox(height: 14),
              Text(
                journeyMessage,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic,
                  height: 1.60,
                ),
              ),
              const SizedBox(height: 14),
              // Soft divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    journeyColor.withOpacity(0.30),
                    Colors.transparent,
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Text(
                  '${rel.totalMessages} conversations with Lunar',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.30),
                    fontSize: 10.5,
                  ),
                ),
                const Spacer(),
                Text(
                  rel.level.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  DAILY EMOTIONAL RITUAL CARD — time-aware intention
  // ─────────────────────────────────────────────────────────
  Widget _dailyRitualCard(BuildContext ctx) {
    final hour = DateTime.now().hour;
    final (emoji, heading, prompt, accent) = switch (hour) {
      >= 5 && < 12 => (
          '🌅',
          'Morning Energy Ritual',
          'How do you want to feel today, love?',
          const Color(0xFFFFB74D),
        ),
      >= 12 && < 17 => (
          '☀️',
          'Midday Soul Check-In',
          'How are you really holding up right now?',
          const Color(0xFFFFD700),
        ),
      >= 17 && < 22 => (
          '🌙',
          'Evening Reflection',
          'What was the emotional theme of your day?',
          const Color(0xFFAB5CF2),
        ),
      _ => (
          '✨',
          'Moonlight Release',
          'What are you ready to let go of tonight?',
          const Color(0xFF4FC3F7),
        ),
    };

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            ctx,
            PageRouteBuilder(
              pageBuilder: (_, anim, __) => FadeTransition(
                opacity: anim,
                child: const AIVoiceScreen(),
              ),
              transitionDuration: const Duration(milliseconds: 420),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withOpacity(0.18),
                    accent.withOpacity(0.08),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
                border: Border.all(
                    color: accent.withOpacity(0.35 * _glowAnim.value),
                    width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.12 * _glowAnim.value),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(children: [
                // Pulsing emoji orb
                AnimatedBuilder(
                  animation: _breatheAnim,
                  builder: (_, __) => Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        accent.withOpacity(0.55 * _breatheAnim.value),
                        accent.withOpacity(0.15),
                        Colors.transparent,
                      ]),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.25 * _breatheAnim.value),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 22))),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(heading,
                          style: TextStyle(
                              color: accent,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2)),
                      const SizedBox(height: 5),
                      Text(prompt,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.68),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              height: 1.4)),
                    ])),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: accent.withOpacity(0.55), size: 22),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  EMOTIONAL WEATHER BANNER (enhanced — Phase 3)
  // ─────────────────────────────────────────────────────────
  Widget _weatherBanner(WeatherProvider weatherProv) {
    final today = weatherProv.todayWeather;
    final forecast = weatherProv.forecast;
    final color = today.accentColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: [
                color.withOpacity(0.16),
                color.withOpacity(0.06),
              ]),
              border: Border.all(
                  color: color.withOpacity(_glowAnim.value * 0.5), width: 1),
            ),
            child: Row(children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(_pulseAnim.value * 0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('Forecast: ',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.48), fontSize: 12)),
              Text('${today.emoji} ${today.state.shortLabel}',
                  style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              // Mini 3-day chips
              ...forecast.days.asMap().entries.map((e) {
                final d = e.value;
                return Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: d.accentColor.withOpacity(e.key == 0 ? 0.22 : 0.1),
                    border: Border.all(
                        color: d.accentColor.withOpacity(0.3), width: 0.6),
                  ),
                  child: Text(d.emoji, style: const TextStyle(fontSize: 11)),
                );
              }),
            ]),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  PHASE 4 — EMOTIONAL COMMAND CENTER WIDGETS
  // ══════════════════════════════════════════════════════

  // ─────────────────────────────────────────────────────────
  //  EMOTIONAL COMMAND BAR — first thing users see
  // ─────────────────────────────────────────────────────────
  Widget _emotionalCommandBar(
      UserProvider user, ChatProvider chat, WeatherProvider weather) {
    final app = context.read<AppProvider>();
    final rawName = app.userName;
    final firstName = rawName.isNotEmpty ? rawName.split(' ').first : '';
    final h = DateTime.now().hour;
    final greeting = h < 6
        ? '🌙 Good night'
        : h < 12
            ? '🌸 Good morning'
            : h < 17
                ? '✨ Good afternoon'
                : '🌙 Good evening';
    final today = weather.todayWeather;
    final profile = chat.emotionalProfile;
    final traj = profile.emotionalTrajectory;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              today.gradientColors.first.withOpacity(0.20 * _glowAnim.value),
              _hPurple.withOpacity(0.10),
              Colors.transparent,
            ],
          ),
          border: Border.all(
            color: today.accentColor.withOpacity(0.28 * _glowAnim.value),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstName.isNotEmpty ? '$greeting, $firstName' : greeting,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _emotionalContextLine(profile, today),
                    style: TextStyle(
                      color: today.accentColor.withOpacity(0.80),
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: today.accentColor.withOpacity(0.16),
                    border: Border.all(
                        color: today.accentColor.withOpacity(0.38), width: 0.8),
                  ),
                  child: Text(
                    '${today.emoji} ${today.state.shortLabel}',
                    style: TextStyle(
                      color: today.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (traj != 'unknown') ...[
                  const SizedBox(height: 5),
                  Text(
                    traj == 'improving'
                        ? '↑ Growing'
                        : traj == 'declining'
                            ? '→ Tender'
                            : '~ Steady',
                    style: TextStyle(
                      color: traj == 'improving'
                          ? _hGreen
                          : Colors.white.withOpacity(0.42),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _emotionalContextLine(EmotionalProfile profile, DayWeather weather) {
    if (profile.daysSinceLastVisit >= 7) {
      return "It's been a while — Lunar has missed you";
    }
    if (profile.daysSinceLastVisit >= 3) {
      return 'Welcome back. How have you been?';
    }
    if (profile.emotionalTrajectory == 'improving') {
      return 'Your energy has been rising lately';
    }
    if (profile.anxietyMentions >= 3) {
      return "You've been carrying a lot — you're safe here";
    }
    if (profile.hasPositiveStreak) {
      return "You've been doing beautifully";
    }
    switch (weather.state) {
      case EmotionalWeatherState.radiantDay:
        return 'Your energy feels luminous today';
      case EmotionalWeatherState.gentleHeartDay:
        return 'Today calls for tenderness and rest';
      case EmotionalWeatherState.emotionalStorm:
        return "Turbulent energy — you're not alone";
      case EmotionalWeatherState.releaseWeather:
        return 'Some things want to be let go today';
      case EmotionalWeatherState.calmMoon:
        return 'A peaceful presence fills the air';
      case EmotionalWeatherState.healingEnergy:
        return 'Healing is quietly happening';
      case EmotionalWeatherState.selfLoveDay:
        return 'You deserve your own gentleness today';
      case EmotionalWeatherState.emotionalTide:
        return 'Emotions are moving — let them';
    }
  }

  // ─────────────────────────────────────────────────────────
  //  AI INSIGHT OF THE DAY
  // ─────────────────────────────────────────────────────────
  Widget _aiInsightOfDay(ChatProvider chat, WeatherProvider weather) {
    final profile = chat.emotionalProfile;
    final insight = profile.patternInsight ?? weather.todayWeather.insight;

    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _breatheAnim]),
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _hPurple.withOpacity(0.22 * _breatheAnim.value),
                  _hPink.withOpacity(0.09),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              border: Border.all(
                  color: _hPurple.withOpacity(0.32 * _glowAnim.value),
                  width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: _hPurple.withOpacity(0.10 * _glowAnim.value),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _hPurple.withOpacity(0.60 * _pulseAnim.value),
                        Colors.transparent,
                      ]),
                    ),
                    child: const Center(
                        child: Text('🌙', style: TextStyle(fontSize: 18))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LUNAR INSIGHT',
                        style: TextStyle(
                          color: _hPurple.withOpacity(0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        insight,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          height: 1.55,
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
    );
  }

  // ─────────────────────────────────────────────────────────
  //  EMOTIONAL ENERGY PANEL
  // ─────────────────────────────────────────────────────────
  Widget _emotionalEnergyPanel(ChatProvider chat, LunarDataProvider lunarData) {
    final m = _computeEnergy(chat, lunarData);

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _hIndigo.withOpacity(0.18),
                  _hPurple.withOpacity(0.10),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              border: Border.all(
                  color: _hIndigo.withOpacity(0.32 * _glowAnim.value),
                  width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'EMOTIONAL ENERGY',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _overallEnergyColor(m.overall).withOpacity(0.20),
                        border: Border.all(
                            color: _overallEnergyColor(m.overall)
                                .withOpacity(0.45),
                            width: 0.8),
                      ),
                      child: Text(
                        '${m.overall}',
                        style: TextStyle(
                          color: _overallEnergyColor(m.overall),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _energyBar(
                    'Emotional Balance',
                    m.balance / 100,
                    _hPurple,
                    m.balance >= 65
                        ? 'Centred'
                        : m.balance >= 45
                            ? 'Wavering'
                            : 'Fragile'),
                const SizedBox(height: 12),
                _energyBar(
                    'Stress Load',
                    1 - m.stressLoad / 100,
                    m.stressLoad > 65
                        ? _hWarm
                        : m.stressLoad > 40
                            ? _hIndigo
                            : _hGreen,
                    m.stressLoad < 35
                        ? 'Low'
                        : m.stressLoad < 60
                            ? 'Moderate'
                            : 'High'),
                const SizedBox(height: 12),
                _energyBar(
                    'Recovery Power',
                    m.recovery / 100,
                    _hTeal,
                    m.recovery >= 65
                        ? 'Strong'
                        : m.recovery >= 45
                            ? 'Building'
                            : 'Low'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _energyBar(
      String label, double value, Color color, String statusLabel) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              statusLabel,
              style: TextStyle(
                color: color.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 7,
                color: Colors.white.withOpacity(0.07),
              ),
              FractionallySizedBox(
                widthFactor: value.clamp(0.04, 1.0),
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient:
                        LinearGradient(colors: [color.withOpacity(0.7), color]),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.40), blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _overallEnergyColor(int score) {
    if (score >= 75) return _hGreen;
    if (score >= 55) return _hPurple;
    if (score >= 40) return _hIndigo;
    return _hWarm;
  }

  _EnergyMetrics _computeEnergy(
      ChatProvider chat, LunarDataProvider lunarData) {
    final profile = chat.emotionalProfile;

    int balance = 58;
    if (profile.emotionalTrajectory == 'improving')
      balance += 18;
    else if (profile.emotionalTrajectory == 'declining') balance -= 15;
    if (profile.hasPositiveStreak) balance += 10;
    if (profile.dominantEmotion == EmotionTag.happy ||
        profile.dominantEmotion == EmotionTag.energetic) balance += 12;
    if (profile.dominantEmotion == EmotionTag.sad ||
        profile.dominantEmotion == EmotionTag.lonely) balance -= 12;

    int stressLoad = 18;
    stressLoad += (profile.anxietyMentions * 9).clamp(0, 36);
    stressLoad += (profile.stressMentions * 7).clamp(0, 28);
    if (profile.dominantEmotion == EmotionTag.anxious) stressLoad += 14;
    if (profile.dominantEmotion == EmotionTag.stressed) stressLoad += 11;

    int recovery = 48;
    if (lunarData.lastSleepHours >= 7.5)
      recovery += 22;
    else if (lunarData.lastSleepHours >= 6.5)
      recovery += 10;
    else if (lunarData.lastSleepHours < 5.5) recovery -= 18;
    if (lunarData.todayWaterGlasses >= 7) recovery += 10;
    if (lunarData.todayWaterGlasses >= 5) recovery += 5;
    if (profile.sleepMentions >= 2 && lunarData.lastSleepHours >= 7.0) {
      recovery += 8;
    }

    return _EnergyMetrics(
      balance.clamp(8, 98),
      stressLoad.clamp(5, 95),
      recovery.clamp(8, 98),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  TODAY'S EMOTIONAL FOCUS
  // ─────────────────────────────────────────────────────────
  Widget _todaysFocusCard(ChatProvider chat, UserProvider user) {
    final focus = _computeTodaysFocus(chat, user);
    final color = focus.color;

    return GestureDetector(
      onTap: () => _nav(context, const AIVoiceScreen()),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [
              color.withOpacity(0.18 * _glowAnim.value),
              color.withOpacity(0.07),
            ]),
            border: Border.all(
                color: color.withOpacity(0.32 * _glowAnim.value), width: 1),
          ),
          child: Row(
            children: [
              Text(focus.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S FOCUS",
                      style: TextStyle(
                        color: color.withOpacity(0.75),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      focus.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      focus.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: color.withOpacity(0.45)),
            ],
          ),
        ),
      ),
    );
  }

  _FocusData _computeTodaysFocus(ChatProvider chat, UserProvider user) {
    final profile = chat.emotionalProfile;
    final phase = _phaseOf(user);

    if (profile.dominantEmotion == EmotionTag.anxious ||
        profile.anxietyMentions >= 3) {
      return _FocusData(
          '🍃', 'Breathe & Ground', 'Let anxiety pass through you', _hTeal);
    }
    if (profile.dominantEmotion == EmotionTag.sad ||
        profile.dominantEmotion == EmotionTag.lonely) {
      return _FocusData(
          '💜', 'Gentle Healing', 'Hold yourself softly today', _hPurple);
    }
    if (profile.stressMentions >= 3 ||
        profile.dominantEmotion == EmotionTag.stressed) {
      return _FocusData(
          '🌿', 'Simplify & Release', 'One thing at a time', _hGreen);
    }
    if (phase == _CyclePhase.period) {
      return _FocusData(
          '🌸', 'Rest & Restore', 'Your body needs warmth now', _hPink);
    }
    if (phase == _CyclePhase.ovulation) {
      return _FocusData(
          '🌟', 'Express Yourself', 'Your energy is at its peak', _hGold);
    }
    if (phase == _CyclePhase.luteal) {
      return _FocusData(
          '🌊', 'Turn Inward', 'Honour your inner rhythm', _hIndigo);
    }
    if (profile.emotionalTrajectory == 'improving' ||
        profile.hasPositiveStreak) {
      return _FocusData(
          '✨', 'Momentum Day', 'Channel this rising energy', _hGold);
    }
    if (profile.dominantEmotion == EmotionTag.happy ||
        profile.dominantEmotion == EmotionTag.energetic) {
      return _FocusData(
          '💫', 'Radiant Energy', 'Share your light today', _hGold);
    }
    if (profile.sleepMentions >= 2) {
      return _FocusData(
          '😴', 'Rest First', 'Sleep is an act of self-love', _hIndigo);
    }
    return _FocusData(
        '🌙', 'Open Heart Day', 'Stay curious about your feelings', _hPurple);
  }

  // ─────────────────────────────────────────────────────────
  //  MOOD TREND CARD — 7-day emotional sparkline
  // ─────────────────────────────────────────────────────────
  Widget _moodTrendCard(WeatherProvider weather) {
    final history = weather.recentHistory.take(7).toList().reversed.toList();

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  _hPurple.withOpacity(0.14),
                  _hPink.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              border: Border.all(
                  color: _hPurple.withOpacity(0.25 * _glowAnim.value),
                  width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '7-DAY MOOD JOURNEY',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      history.isNotEmpty ? history.last.emoji : '🌙',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (history.length >= 2)
                  SizedBox(
                    height: 68,
                    child: CustomPaint(
                      size: const Size(double.infinity, 68),
                      painter: _MoodSparklinePainter(
                        history: history,
                        lineColor: _hPurple,
                        glowColor: _hPink,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 68,
                    child: Center(
                      child: Text(
                        'Keep journaling — your mood pattern will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.38),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                if (history.length >= 2) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: history.map((d) {
                      final isToday = d == history.last;
                      return Text(
                        d.emoji,
                        style: TextStyle(fontSize: isToday ? 16 : 12),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  QUICK EMOTIONAL ACTIONS — 4 focused CTA buttons
  // ─────────────────────────────────────────────────────────
  Widget _quickEmotionalActions(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT DO YOU NEED?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.38),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _emotionalActionBtn(
                emoji: '🌙',
                label: 'Talk to\nLunar',
                color: _hPurple,
                isPrimary: true,
                onTap: () => _nav(ctx, const AIVoiceScreen()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _emotionalActionBtn(
                emoji: '📓',
                label: 'Write in\nJournal',
                color: _hPink,
                isPrimary: false,
                onTap: () => _nav(ctx, const JournalScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _emotionalActionBtn(
                emoji: '🌤️',
                label: "Today's\nReading",
                color: _hTeal,
                isPrimary: false,
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) => const EmotionalWeatherScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _emotionalActionBtn(
                emoji: '💜',
                label: 'Community\nSupport',
                color: _hIndigo,
                isPrimary: false,
                onTap: () => _nav(ctx, const CommunityTabsScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _emotionalActionBtn({
    required String emoji,
    required String label,
    required Color color,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isPrimary
                ? LinearGradient(colors: [
                    color.withOpacity(0.85 * _glowAnim.value),
                    _hPink.withOpacity(0.65 * _glowAnim.value),
                  ])
                : LinearGradient(colors: [
                    color.withOpacity(0.16),
                    color.withOpacity(0.07),
                  ]),
            border: Border.all(
              color: color.withOpacity(isPrimary ? 0.80 : 0.30),
              width: isPrimary ? 1.2 : 0.8,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.38 * _glowAnim.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color:
                      isPrimary ? Colors.white : Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  MOON COMPANION ROW
  // ─────────────────────────────────────────────────────────
  Widget _moonCompanionRow(UserProvider user) {
    const companionMsgs = {
      _CyclePhase.period: 'Rest deeply. I am watching over you 🌸',
      _CyclePhase.follicular: 'You are blooming. I see your light ✨',
      _CyclePhase.ovulation: 'Peak energy. You are magnetic right now 🌟',
      _CyclePhase.luteal: 'Feeling tender? That is okay. I am here 💜',
    };
    final msg =
        companionMsgs[_phaseOf(user)] ?? "I am here with you, always 🌙";

    // BackdropFilter is OUTSIDE AnimatedBuilder to avoid per-frame blur recomputation
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowAnim, _breatheAnim]),
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF5C2DB8).withOpacity(0.55),
                  const Color(0xFFAB5CF2).withOpacity(0.3),
                  const Color(0xFFFF69B4).withOpacity(0.15),
                ],
              ),
              border: Border.all(
                color:
                    const Color(0xFFAB5CF2).withOpacity(_glowAnim.value * 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFAB5CF2)
                      .withOpacity(_glowAnim.value * 0.18),
                  blurRadius: 22,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Row(children: [
              // Animated moon companion
              Stack(alignment: Alignment.center, children: [
                Container(
                  width: 70 * _breatheAnim.value,
                  height: 70 * _breatheAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFFAB5CF2).withOpacity(0),
                      const Color(0xFFAB5CF2)
                          .withOpacity(_glowAnim.value * 0.22),
                      Colors.transparent,
                    ]),
                  ),
                ),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700)
                            .withOpacity(_glowAnim.value * 0.5),
                        blurRadius: 22,
                        spreadRadius: 4,
                      )
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _floatAnim.value * 0.3),
                    child: const Text('🌙', style: TextStyle(fontSize: 44)),
                  ),
                ),
              ]),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lunar AI',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 5),
                  Text(msg,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                          height: 1.4)),
                  const SizedBox(height: 10),
                  Row(children: [
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hGreen,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  _hGreen.withOpacity(_pulseAnim.value * 0.9),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Always here for you',
                        style: TextStyle(
                            color: _hGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ]),
                ],
              )),
            ]),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ORBITAL TRACKER
  // ─────────────────────────────────────────────────────────
  Widget _orbitalTracker(UserProvider user) {
    return Column(
      children: [
        SizedBox(
          height: 290,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _orbitController,
                  builder: (_, __) => CustomPaint(
                    size: const Size(290, 290),
                    painter: _OrbitalPainter(
                      rotation: _orbitController.value * 2 * math.pi,
                      glow: _glowAnim.value,
                      phaseColor: _phaseRingColor(user),
                    ),
                  ),
                ),
              ),
              // Fertility aura breathing ring
              AnimatedBuilder(
                animation: _breatheAnim,
                builder: (_, __) => Container(
                  width: 168 * _breatheAnim.value,
                  height: 168 * _breatheAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _phaseRingColor(user).withOpacity(0.0),
                        _phaseRingColor(user).withOpacity(0.0),
                        _phaseRingColor(user)
                            .withOpacity(0.18 * _glowAnim.value),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 0.78, 1.0],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: _phaseColors(user)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700)
                            .withOpacity(_glowAnim.value * 0.35),
                        blurRadius: 32,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF69B4)
                            .withOpacity(_glowAnim.value * 0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _cycleDayLabel(user),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _phaseLabel(user),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withOpacity(0.18),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _glassCard(
                child: Row(
                  children: [
                    const Text('🩸', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Next Period',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11)),
                        Text(
                          '${user.daysUntilNext} days',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _glassCard(
                child: Row(
                  children: [
                    const Text('🥚', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fertility',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11)),
                        const Text(
                          'High ✨',
                          style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PREGNANCY JOURNEY CARD  (featured discovery card)
  // ─────────────────────────────────────────────────────────
  Widget _pregnancyCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: const PregnancyScreen(),
              ),
            ),
            transitionDuration: const Duration(milliseconds: 420),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowAnim, _pulseAnim]),
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _hWarm.withOpacity(0.18),
                    _hPink.withOpacity(0.16),
                    _hPurple.withOpacity(0.12),
                    Colors.white.withOpacity(0.03),
                  ],
                  stops: const [0.0, 0.35, 0.70, 1.0],
                ),
                border: Border.all(
                  color: _hWarm.withOpacity(_glowAnim.value * 0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _hPink.withOpacity(_glowAnim.value * 0.20),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: _hWarm.withOpacity(_glowAnim.value * 0.12),
                    blurRadius: 44,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Row(children: [
                // Pulsing orb icon
                Transform.scale(
                  scale: 0.96 + 0.04 * _pulseAnim.value,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _hWarm.withOpacity(0.40 + 0.15 * _glowAnim.value),
                        _hPink.withOpacity(0.22),
                        _hPurple.withOpacity(0.08),
                      ], stops: const [
                        0.0,
                        0.55,
                        1.0
                      ]),
                      border: Border.all(
                        color: _hWarm.withOpacity(0.55 * _glowAnim.value),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _hWarm.withOpacity(0.35 * _glowAnim.value),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🤰', style: TextStyle(fontSize: 30)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('Pregnancy Journey',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(colors: [
                            _hWarm.withOpacity(0.35),
                            _hPink.withOpacity(0.25),
                          ]),
                          border: Border.all(
                              color: _hWarm.withOpacity(0.5), width: 1),
                        ),
                        child: const Text('NEW',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                    ]),
                    const SizedBox(height: 5),
                    Text(
                      'Baby growth tracking, wellness insights & emotional support',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.60),
                          fontSize: 12,
                          height: 1.45),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      _pregnancyFeaturePill('🌱 Growth'),
                      const SizedBox(width: 6),
                      _pregnancyFeaturePill('💜 Insights'),
                      const SizedBox(width: 6),
                      _pregnancyFeaturePill('🌙 Wellness'),
                    ]),
                  ],
                )),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.35), size: 14),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pregnancyFeaturePill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withOpacity(0.07),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: Text(text,
            style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      );

  // ─────────────────────────────────────────────────────────
  //  QUICK ACTIONS
  // ─────────────────────────────────────────────────────────
  Widget _quickActions(BuildContext context) {
    final actions = [
      _QuickAction(
          '🩸', 'Log Period', () => _nav(context, const PeriodScreen())),
      _QuickAction(
          '😊', 'Mood', () => _nav(context, const MoodTrackingScreen())),
      _QuickAction(
          '💊', 'Symptoms', () => _nav(context, const CycleTrackerScreen())),
      _QuickAction('📓', 'Journal', () => _nav(context, const JournalScreen())),
      _QuickAction('🤖', 'Lunar AI', () => _nav(context, const AIVoiceScreen()),
          isHighlight: true),
      _QuickAction(
          '🌸', 'Community', () => _nav(context, const CommunityTabsScreen())),
      _QuickAction('🌙', 'Sleep', () => _nav(context, const SleepScreen())),
      _QuickAction(
          '🤰', 'Pregnancy', () => _nav(context, const PregnancyScreen())),
      _QuickAction('💧', 'Water', () {
        HapticFeedback.lightImpact();
        context.read<LunarDataProvider>().addWaterGlass();
      }),
      _QuickAction(
          '🧘‍♀️', 'Meditate', () => _nav(context, const SleepScreen())),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Quick Actions'),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: actions.asMap().entries.map((entry) {
              final idx = entry.key;
              final a = entry.value;
              final pressed = _pressedAction == idx;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _pressedAction = idx),
                  onTapUp: (_) {
                    HapticFeedback.lightImpact();
                    setState(() => _pressedAction = null);
                    a.onTap();
                  },
                  onTapCancel: () => setState(() => _pressedAction = null),
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => AnimatedScale(
                      scale: pressed ? 0.91 : 1.0,
                      duration: const Duration(milliseconds: 110),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: a.isHighlight
                              ? LinearGradient(colors: [
                                  const Color(0xFFAB5CF2)
                                      .withOpacity(_glowAnim.value),
                                  const Color(0xFFFF69B4)
                                      .withOpacity(_glowAnim.value),
                                ])
                              : pressed
                                  ? LinearGradient(colors: [
                                      _hPurple.withOpacity(0.3),
                                      _hPink.withOpacity(0.2),
                                    ])
                                  : null,
                          color: (a.isHighlight || pressed)
                              ? null
                              : Colors.white.withOpacity(0.07),
                          border: Border.all(
                            color: a.isHighlight
                                ? const Color(0xFFAB5CF2)
                                    .withOpacity(_glowAnim.value)
                                : pressed
                                    ? _hPurple.withOpacity(0.55)
                                    : Colors.white.withOpacity(0.14),
                            width: 1,
                          ),
                          boxShadow: (a.isHighlight || pressed)
                              ? [
                                  BoxShadow(
                                    color: _hPurple.withOpacity(pressed
                                        ? 0.55
                                        : _glowAnim.value * 0.55),
                                    blurRadius: pressed ? 30 : 22,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: Column(children: [
                          Text(a.icon, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 7),
                          Text(a.label,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.88),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  INSIGHT CAROUSEL
  // ─────────────────────────────────────────────────────────
  Widget _insightCarousel(UserProvider user) {
    final cards = [
      _InsightCard(
        icon: '🔮',
        title: 'Cycle Prediction',
        body: user.daysUntilNext == 0
            ? 'Your period may start soon — stay prepared 🩸'
            : 'Next period in ${user.daysUntilNext} days. Stay hydrated and rested.',
        color: _hPurple,
      ),
      _InsightCard(
        icon: '💧',
        title: 'Hydration',
        body: waterGlasses >= 6
            ? 'Great hydration today! Your body is glowing 💧'
            : 'You have had $waterGlasses/8 glasses. Try ${8 - waterGlasses} more today.',
        color: _hTeal,
      ),
      _InsightCard(
        icon: '😴',
        title: 'Sleep Analysis',
        body: sleepHours >= 7.5
            ? 'Excellent sleep quality. Hormones are balanced ✨'
            : 'At ${sleepHours}hrs you may feel sluggish. Aim for 7–9 hrs tonight.',
        color: _hIndigo,
      ),
      _InsightCard(
        icon: '💜',
        title: 'Emotional Wellness',
        body: _aiInsight(user),
        color: _hPink,
      ),
      _InsightCard(
        icon: '🌡️',
        title: 'Basal Temp',
        body:
            'Your temp (${tempC}°C) is within normal range. Great sign for your cycle.',
        color: _hWarm,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Smart Insights'),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: cards
                .map((card) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      // BackdropFilter outside AnimatedBuilder to avoid per-frame blur
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: AnimatedBuilder(
                            animation: _glowAnim,
                            builder: (_, __) => Container(
                              width: 210,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    card.color.withOpacity(0.22),
                                    card.color.withOpacity(0.07),
                                  ],
                                ),
                                border: Border.all(
                                  color: card.color
                                      .withOpacity(_glowAnim.value * 0.45),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: card.color
                                        .withOpacity(_glowAnim.value * 0.15),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: card.color.withOpacity(0.2),
                                        border: Border.all(
                                            color: card.color.withOpacity(0.35),
                                            width: 1),
                                      ),
                                      child: Center(
                                          child: Text(card.icon,
                                              style: const TextStyle(
                                                  fontSize: 18))),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(card.title,
                                            style: TextStyle(
                                                color: card.color,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700))),
                                  ]),
                                  const SizedBox(height: 10),
                                  Text(card.body,
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.72),
                                          fontSize: 12,
                                          height: 1.45)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HEALTH SNAPSHOT
  // ─────────────────────────────────────────────────────────
  Widget _healthSnapshot() {
    final lunarData = context.read<LunarDataProvider>();
    final energyLabel = lunarData.energyLevel == 'high'
        ? 'High'
        : lunarData.energyLevel == 'low'
            ? 'Low'
            : 'Medium';
    final energyProgress = lunarData.energyLevel == 'high'
        ? 0.90
        : lunarData.energyLevel == 'low'
            ? 0.35
            : 0.60;
    final items = [
      _HealthItem('💧', 'Water', '$waterGlasses/8', 'glasses',
          progress: (waterGlasses / 8).clamp(0.0, 1.0), accentColor: _hTeal),
      _HealthItem('😴', 'Sleep', sleepHours.toStringAsFixed(1), 'hrs',
          progress: (sleepHours / 9).clamp(0.0, 1.0), accentColor: _hIndigo),
      _HealthItem('⚖️', 'Weight', weightKg.toStringAsFixed(1), 'kg',
          progress: 0.72, accentColor: _hWarm),
      _HealthItem('🌡️', 'Temp', tempC.toStringAsFixed(1), '°C',
          progress: 0.80, accentColor: _hPink),
      _HealthItem('💜', 'Energy', energyLabel, '',
          progress: energyProgress, accentColor: _hPurple),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Health Snapshot'),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: items.map((item) {
              final isWater = item.label == 'Water';
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: isWater
                      ? () {
                          HapticFeedback.lightImpact();
                          context.read<LunarDataProvider>().addWaterGlass();
                        }
                      : null,
                  child: _glassCard(
                    width: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 8),
                        Text(
                          item.value,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                        if (item.unit.isNotEmpty)
                          Text(item.unit,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 10)),
                        const SizedBox(height: 5),
                        Text(
                          item.label,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: item.progress),
                          duration: const Duration(milliseconds: 1100),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: v,
                              minHeight: 3.5,
                              backgroundColor: Colors.white.withOpacity(0.07),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  item.accentColor.withOpacity(0.82)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  AI CARD
  // ─────────────────────────────────────────────────────────
  Widget _aiCard(BuildContext context, UserProvider user) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF5C2DB8).withOpacity(0.65),
                  const Color(0xFFAB5CF2).withOpacity(0.45),
                  const Color(0xFFE91E8C).withOpacity(0.32),
                ],
              ),
              border: Border.all(
                color:
                    const Color(0xFFAB5CF2).withOpacity(_glowAnim.value * 0.65),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFAB5CF2)
                      .withOpacity(_glowAnim.value * 0.32),
                  blurRadius: 34,
                  spreadRadius: 3,
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
                        const Text(
                          'Lunar AI 🌙',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: _hGreen.withOpacity(0.18),
                              border: Border.all(
                                  color: _hGreen.withOpacity(0.5), width: 1),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _hGreen,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _hGreen
                                          .withOpacity(_pulseAnim.value * 0.9),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text('Online',
                                  style: TextStyle(
                                      color: _hGreen,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(
                                    begin: const Offset(0, 0.15),
                                    end: Offset.zero)
                                .animate(CurvedAnimation(
                                    parent: anim, curve: Curves.easeOut)),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _aiSubtitles[_aiSubtitleIdx],
                          key: ValueKey(_aiSubtitleIdx),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.52),
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _TypewriterText(
                        text: _aiInsight(user),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                            height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _nav(context, const AIVoiceScreen()),
                              child: AnimatedBuilder(
                                animation: _shimmerAnim,
                                builder: (_, __) => ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 13),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFFAB5CF2),
                                        Color(0xFFFF69B4),
                                      ]),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFAB5CF2)
                                              .withOpacity(0.5),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Text(
                                          'Talk to Lunar ✨',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                        Positioned.fill(
                                          child: OverflowBox(
                                            maxWidth: double.infinity,
                                            child: Transform.translate(
                                              offset: Offset(
                                                  _shimmerAnim.value * 60, 0),
                                              child: Container(
                                                width: 60,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white
                                                          .withOpacity(0.0),
                                                      Colors.white
                                                          .withOpacity(0.22),
                                                      Colors.white
                                                          .withOpacity(0.0),
                                                    ],
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                  ),
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  _nav(context, const AIInsightsScreen()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 13),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.white.withOpacity(0.08),
                                  border: Border.all(
                                    color: const Color(0xFFAB5CF2)
                                        .withOpacity(0.55),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'AI Insights 🧠',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _floatAnim.value * 0.6),
                    child: const Text('🤖', style: TextStyle(fontSize: 58)),
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
  //  DAILY CARE  (interactive)
  // ─────────────────────────────────────────────────────────
  Widget _dailyCare() {
    final tips = [
      _CareTip(
          '💧',
          'Drink Water',
          'Tap to log a glass. Your body thrives on hydration.',
          const Color(0xFF4FC3F7)),
      _CareTip(
          '🧘‍♀️',
          'Relax Tonight',
          '5 minutes of deep breathing reduces stress by 40%.',
          const Color(0xFFAB5CF2)),
      _CareTip(
          '🌙',
          'Sleep Suggestion',
          'Wind down by 10 PM for optimal hormonal balance.',
          const Color(0xFF7986CB)),
      _CareTip(
          '💜',
          'Emotional Support',
          'You are doing amazing. Trust your body and your journey.',
          const Color(0xFFFF69B4)),
      _CareTip('🌸', 'Daily Affirmation',
          _affirmations[DateTime.now().day % _affirmations.length], _hWarm),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Daily Care'),
        const SizedBox(height: 13),
        ...tips.asMap().entries.map((entry) {
          final i = entry.key;
          final tip = entry.value;
          final done = _careCompleted.contains(i);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  // Water card: increment glasses each tap
                  if (i == 0 && waterGlasses < 8) waterGlasses++;
                  if (done) {
                    _careCompleted.remove(i);
                  } else {
                    _careCompleted.add(i);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: done
                      ? tip.color.withOpacity(0.12)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: done
                        ? tip.color.withOpacity(0.65)
                        : tip.color.withOpacity(0.3),
                    width: done ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tip.color.withOpacity(done ? 0.28 : 0.14),
                        border: Border.all(
                            color: tip.color.withOpacity(0.4), width: 1),
                      ),
                      child: Center(
                          child: Text(tip.icon,
                              style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  // Water card shows live count
                                  i == 0
                                      ? '${tip.title}  $waterGlasses/8 💧'
                                      : tip.title,
                                  style: TextStyle(
                                      color: tip.color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              // Animated checkmark badge
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: done
                                    ? Container(
                                        key: const ValueKey('check'),
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: tip.color.withOpacity(0.25),
                                          border: Border.all(
                                              color: tip.color, width: 1.5),
                                        ),
                                        child: Icon(Icons.check,
                                            size: 13, color: tip.color),
                                      )
                                    : SizedBox(
                                        key: const ValueKey('empty'),
                                        width: 24,
                                        height: 24,
                                        child: Icon(Icons.add_circle_outline,
                                            size: 18,
                                            color: tip.color.withOpacity(0.4)),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tip.desc,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.58),
                                fontSize: 12,
                                height: 1.45),
                          ),
                          // Breathing progress bar (only for relax card)
                          if (i == 1 && done) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 1.0,
                                minHeight: 4,
                                backgroundColor: tip.color.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    tip.color.withOpacity(0.7)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Session complete ✓',
                                style: TextStyle(
                                    color: tip.color.withOpacity(0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────
  Widget _glassCard({required Widget child, double? width}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.07),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bg.withOpacity(0.18),
        border: Border.all(color: bg.withOpacity(0.4), width: 1),
      ),
      child: Text(text,
          style: TextStyle(
              color: fg, fontSize: 11.5, fontWeight: FontWeight.w500)),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2),
      );

  Widget _liveStatusPill() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _hGreen.withOpacity(0.15),
          border: Border.all(color: _hGreen.withOpacity(0.4), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hGreen,
              boxShadow: [
                BoxShadow(
                  color: _hGreen.withOpacity(_pulseAnim.value),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text('Live',
              style: TextStyle(
                  color: _hGreen, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _staggeredSection(Widget child, int index) {
    final start = (index * 0.12).clamp(0.0, 0.88);
    final end = (start + 0.45).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position:
            Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  void _nav(BuildContext ctx, Widget screen) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));

  // ─────────────────────────────────────────────────────────
  //  HEADER GREETING WITH USER NAME
  // ─────────────────────────────────────────────────────────
  Widget _headerGreeting(UserProvider user) {
    final app = context.read<AppProvider>();
    final name = app.userName.isNotEmpty ? app.userName : null;
    final timeLabel = _timeOfDayShort();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -14,
          top: -8,
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              width: 220,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFAB5CF2).withOpacity(_glowAnim.value * 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontFamily: 'Roboto'),
            children: [
              TextSpan(
                text: name != null ? '$timeLabel, $name ' : '$timeLabel ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.15,
                  height: 1.3,
                ),
              ),
              const TextSpan(
                text: '🌙',
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _timeOfDayShort() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good Morning';
    if (h >= 12 && h < 17) return 'Good Afternoon';
    if (h >= 17 && h < 21) return 'Good Evening';
    return 'Good Night';
  }

  // ─────────────────────────────────────────────────────────
  //  LUNAR ENERGY CARD
  // ─────────────────────────────────────────────────────────
  Widget _lunarEnergyCard(UserProvider user, LunarDataProvider lunarData) {
    final phaseColor = _phaseRingColor(user);
    final energyLevel = lunarData.energyLevel == 'high'
        ? 0.88
        : lunarData.energyLevel == 'low'
            ? 0.32
            : 0.62;
    final energyLabel = lunarData.energyLevel == 'high'
        ? 'High'
        : lunarData.energyLevel == 'low'
            ? 'Low'
            : 'Balanced';
    final moodDesc = sleepHours < 6.5
        ? 'Tired 😴'
        : waterGlasses < 4
            ? 'Drained 💧'
            : lunarData.energyLevel == 'high'
                ? 'Radiant 😊'
                : lunarData.energyLevel == 'low'
                    ? 'Gentle 🌸'
                    : 'Calm 😌';
    final stressLabel = sleepHours < 6.5
        ? 'Elevated 🌊'
        : waterGlasses < 4
            ? 'Moderate 💧'
            : 'Low ✨';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Lunar Energy'),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: AnimatedBuilder(
              animation: Listenable.merge([_glowAnim, _shimmerAnim]),
              builder: (_, __) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      phaseColor.withOpacity(0.30),
                      const Color(0xFF1A0835).withOpacity(0.80),
                      phaseColor.withOpacity(0.14),
                    ],
                  ),
                  border: Border.all(
                    color: phaseColor.withOpacity(_glowAnim.value * 0.70),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: phaseColor.withOpacity(_glowAnim.value * 0.32),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Shimmer sweep
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: OverflowBox(
                          maxWidth: double.infinity,
                          child: Transform.translate(
                            offset: Offset(_shimmerAnim.value * 220, 0),
                            child: Container(
                              width: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(0.06),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Floating tiny stars
                    ...List.generate(5, (i) {
                      final baseX = 36.0 + i * 52.0;
                      final baseY = 6.0 + (i % 2) * 20.0;
                      final twinkle = (0.2 +
                              0.65 *
                                  math.sin(_shimmerAnim.value * math.pi * 2 +
                                      i * 1.3))
                          .clamp(0.0, 1.0);
                      return Positioned(
                        left: baseX,
                        top: baseY,
                        child: Opacity(
                          opacity: twinkle,
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                    color: phaseColor.withOpacity(0.9),
                                    blurRadius: 5),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Phase badge + label
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: phaseColor.withOpacity(0.22),
                              border: Border.all(
                                  color: phaseColor.withOpacity(0.55),
                                  width: 1),
                            ),
                            child: Text(
                              _phaseLabel(user).replaceAll('\n', ' '),
                              style: TextStyle(
                                  color: phaseColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Spacer(),
                          Text('Lunar Energy',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 11)),
                        ]),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Circular energy ring
                            SizedBox(
                              width: 86,
                              height: 86,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  RepaintBoundary(
                                    child: TweenAnimationBuilder<double>(
                                      tween:
                                          Tween(begin: 0.0, end: energyLevel),
                                      duration:
                                          const Duration(milliseconds: 1500),
                                      curve: Curves.easeOutCubic,
                                      builder: (_, v, __) => CustomPaint(
                                        size: const Size(86, 86),
                                        painter: _EnergyRingPainter(
                                          progress: v,
                                          color: phaseColor,
                                          glow: _glowAnim.value,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${(energyLevel * 100).toInt()}%',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800),
                                      ),
                                      Text(
                                        energyLabel,
                                        style: TextStyle(
                                            color: phaseColor,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _energyStat(
                                      '😌', 'Mood', moodDesc, phaseColor),
                                  const SizedBox(height: 10),
                                  _energyStat(
                                      '⚡', 'Stress', stressLabel, _hTeal),
                                  const SizedBox(height: 10),
                                  _energyStat('💧', 'Hydration',
                                      '$waterGlasses/8 glasses', _hTeal),
                                  const SizedBox(height: 10),
                                  _energyStat(
                                      '😴',
                                      'Sleep',
                                      '${sleepHours.toStringAsFixed(1)} hrs',
                                      _hIndigo),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _energyStat(String icon, String label, String value, Color color) {
    return Row(children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 6),
      Text('$label: ',
          style:
              TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 11)),
      Expanded(
        child: Text(value,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────
  //  TODAY OVERVIEW
  // ─────────────────────────────────────────────────────────
  Widget _todayOverview(UserProvider user, LunarDataProvider lunarData) {
    final phaseColor = _phaseRingColor(user);
    final cycleDay = user.lastPeriodDate == null
        ? '–'
        : '${DateTime.now().difference(user.lastPeriodDate!).inDays + 1}';
    final phaseName = _phaseLabel(user).replaceAll('\n', ' ');
    final energyLabel = lunarData.energyLevel == 'high'
        ? 'High ⚡'
        : lunarData.energyLevel == 'low'
            ? 'Low 🌿'
            : 'Balanced ✨';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Today'),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedBuilder(
              animation: Listenable.merge([_glowAnim, _breatheAnim]),
              builder: (_, __) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      phaseColor.withOpacity(0.22),
                      const Color(0xFF1A0835).withOpacity(0.75),
                      const Color(0xFF0A0118).withOpacity(0.45),
                    ],
                  ),
                  border: Border.all(
                    color: phaseColor.withOpacity(_glowAnim.value * 0.60),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: phaseColor.withOpacity(_glowAnim.value * 0.25),
                      blurRadius: 36,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'Cycle Day ',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 13),
                              ),
                              Text(
                                cycleDay,
                                style: TextStyle(
                                  color: phaseColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            phaseName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _todayBadge('Energy', energyLabel, _hGold),
                              _todayBadge(
                                  'Mood', _moodPrediction(user), phaseColor),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white.withOpacity(0.05),
                              border: Border.all(
                                  color: phaseColor.withOpacity(0.28),
                                  width: 1),
                            ),
                            child: Row(children: [
                              const Text('💜', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selfCareSuggestion(user),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.80),
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _circularPhaseIndicator(user),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _todayBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.14),
        border: Border.all(color: color.withOpacity(0.42), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.48),
                  fontSize: 9.5,
                  letterSpacing: 0.3)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _circularPhaseIndicator(UserProvider user) {
    final progress = _phaseProgress(user);
    final phaseColor = _phaseRingColor(user);
    final phaseIcon = _phaseIcon(user);
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _breatheAnim]),
      builder: (_, __) => SizedBox(
        width: 92,
        height: 92,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Breathing glow aura
            Container(
              width: 92 * _breatheAnim.value,
              height: 92 * _breatheAnim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    phaseColor.withOpacity(0),
                    phaseColor.withOpacity(_glowAnim.value * 0.22),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.65, 1.0],
                ),
              ),
            ),
            // Progress ring
            RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 1600),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => CustomPaint(
                  size: const Size(92, 92),
                  painter: _EnergyRingPainter(
                    progress: v,
                    color: phaseColor,
                    glow: _glowAnim.value,
                  ),
                ),
              ),
            ),
            // Center content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(phaseIcon, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 2),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                      color: phaseColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _phaseProgress(UserProvider user) {
    if (user.lastPeriodDate == null) return 0.0;
    final day = DateTime.now().difference(user.lastPeriodDate!).inDays + 1;
    return (day / 28).clamp(0.0, 1.0);
  }

  String _phaseIcon(UserProvider user) {
    switch (_phaseOf(user)) {
      case _CyclePhase.period:
        return '🩸';
      case _CyclePhase.follicular:
        return '🌱';
      case _CyclePhase.ovulation:
        return '🌸';
      case _CyclePhase.luteal:
        return '🌙';
      default:
        return '🔮';
    }
  }

  String _moodPrediction(UserProvider user) {
    if (sleepHours < 6.5) return 'Tired 😴';
    if (waterGlasses < 4) return 'Drained 💧';
    switch (_phaseOf(user)) {
      case _CyclePhase.period:
        return 'Tender 🌸';
      case _CyclePhase.follicular:
        return 'Rising ✨';
      case _CyclePhase.ovulation:
        return 'Confident 💫';
      case _CyclePhase.luteal:
        return 'Reflective 💜';
      default:
        final h = DateTime.now().hour;
        if (h < 10) return 'Fresh 🌤️';
        if (h < 16) return 'Focused 🎯';
        return 'Winding Down 🌙';
    }
  }

  String _selfCareSuggestion(UserProvider user) {
    if (sleepHours < 6.5)
      return 'Wind down early — rest rebalances your entire hormonal system.';
    if (waterGlasses < 4)
      return 'Sip water now. Hydration lifts mood and energy within minutes.';
    switch (_phaseOf(user)) {
      case _CyclePhase.period:
        return 'Warmth and rest are powerful healers right now. Take it slow.';
      case _CyclePhase.follicular:
        return 'Start something new today. Your creative energy is rising.';
      case _CyclePhase.ovulation:
        return 'Connect with someone you love. Your magnetism is at its peak.';
      case _CyclePhase.luteal:
        return 'Journal your emotions tonight — clarity comes from reflection.';
      default:
        return 'Take a moment to breathe and honor how far you\'ve come.';
    }
  }

  // ─────────────────────────────────────────────────────────
  //  MOOD FORECAST
  // ─────────────────────────────────────────────────────────
  Widget _moodForecast(UserProvider user) {
    final moods = _moodCards(user);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Mood Forecast'),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: moods.asMap().entries.map((entry) {
              final i = entry.key;
              final mood = entry.value;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_glowAnim, _shimmerAnim]),
                      builder: (_, __) => Container(
                        width: 112,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              mood.color.withOpacity(0.28),
                              mood.color.withOpacity(0.08),
                            ],
                          ),
                          border: Border.all(
                            color:
                                mood.color.withOpacity(_glowAnim.value * 0.55),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: mood.color
                                  .withOpacity(_glowAnim.value * 0.20),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Tiny floating star particles
                            ...List.generate(3, (j) {
                              final px = j * 28.0 + 6.0;
                              final py = j % 2 == 0 ? 4.0 : 14.0;
                              final twinkle = (0.25 +
                                      0.65 *
                                          math.sin(
                                              _shimmerAnim.value * math.pi * 2 +
                                                  i * 0.9 +
                                                  j * 1.1))
                                  .clamp(0.0, 1.0);
                              return Positioned(
                                left: px,
                                top: py,
                                child: Opacity(
                                  opacity: twinkle,
                                  child: Container(
                                    width: 2.5,
                                    height: 2.5,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: mood.color.withOpacity(0.20),
                                    border: Border.all(
                                        color: mood.color.withOpacity(0.40),
                                        width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: mood.color.withOpacity(
                                            _glowAnim.value * 0.35),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(mood.emoji,
                                        style: const TextStyle(fontSize: 20)),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  mood.label,
                                  style: TextStyle(
                                    color: mood.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  mood.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.50),
                                    fontSize: 10,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<_MoodCard> _moodCards(UserProvider user) {
    switch (_phaseOf(user)) {
      case _CyclePhase.period:
        return [
          _MoodCard('😌', 'Tender', 'softness', _hPink),
          _MoodCard('🌙', 'Dreamy', 'inward', _hIndigo),
          _MoodCard('🌸', 'Gentle', 'nurture', const Color(0xFFE98BC8)),
          _MoodCard('💧', 'Emotional', 'flowing', _hTeal),
          _MoodCard('🕯️', 'Still', 'peaceful', _hWarm),
        ];
      case _CyclePhase.follicular:
        return [
          _MoodCard('🌱', 'Rising', 'fresh start', _hGreen),
          _MoodCard('✨', 'Curious', 'exploring', _hPurple),
          _MoodCard('🎨', 'Creative', 'inspired', _hPink),
          _MoodCard('🌤️', 'Optimistic', 'hopeful', _hGold),
          _MoodCard('⚡', 'Energized', 'moving', _hTeal),
        ];
      case _CyclePhase.ovulation:
        return [
          _MoodCard('💫', 'Confident', 'radiant', _hGold),
          _MoodCard('🌟', 'Magnetic', 'glowing', _hPink),
          _MoodCard('💃', 'Social', 'connected', _hPurple),
          _MoodCard('🔥', 'Bold', 'powerful', const Color(0xFFFF7043)),
          _MoodCard('💕', 'Romantic', 'warm', const Color(0xFFE91E8C)),
        ];
      case _CyclePhase.luteal:
        return [
          _MoodCard('💜', 'Emotional', 'deep', _hPurple),
          _MoodCard('🌊', 'Reflective', 'inward', _hIndigo),
          _MoodCard('🍂', 'Sensitive', 'tender', _hWarm),
          _MoodCard('🌙', 'Intuitive', 'aware', const Color(0xFF9C8FDB)),
          _MoodCard('📖', 'Thoughtful', 'introspective', _hTeal),
        ];
      default:
        return [
          _MoodCard('😊', 'Calm', 'peaceful', _hPurple),
          _MoodCard('✨', 'Present', 'grounded', _hTeal),
          _MoodCard('🌸', 'Gentle', 'kind', _hPink),
          _MoodCard('💫', 'Hopeful', 'bright', _hGold),
          _MoodCard('🌙', 'Dreamy', 'flowing', _hIndigo),
        ];
    }
  }

  // ─────────────────────────────────────────────────────────
  //  WELLNESS SCORE
  // ─────────────────────────────────────────────────────────
  int _calcWellnessScore(LunarDataProvider lunarData) {
    int score = 0;
    final sleep = lunarData.lastSleepHours;
    if (sleep >= 8) {
      score += 30;
    } else if (sleep >= 7) {
      score += 25;
    } else if (sleep >= 6) {
      score += 18;
    } else if (sleep >= 5) {
      score += 10;
    } else {
      score += 5;
    }
    score += ((lunarData.todayWaterGlasses / 8) * 30).round().clamp(0, 30);
    if (lunarData.energyLevel == 'high') {
      score += 25;
    } else if (lunarData.energyLevel == 'medium') {
      score += 18;
    } else {
      score += 10;
    }
    final temp = lunarData.lastTempC;
    score += (temp >= 36.0 && temp <= 37.2) ? 15 : 8;
    return score.clamp(0, 100);
  }

  Widget _wellnessScore(LunarDataProvider lunarData) {
    final score = _calcWellnessScore(lunarData);
    final scoreColor = score >= 80
        ? _hGreen
        : score >= 60
            ? _hGold
            : score >= 40
                ? _hWarm
                : _hPink;
    final scoreLabel = score >= 80
        ? 'Excellent'
        : score >= 60
            ? 'Good'
            : score >= 40
                ? 'Fair'
                : 'Low';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Wellness Score'),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scoreColor.withOpacity(0.20),
                      const Color(0xFF0D0120).withOpacity(0.78),
                      scoreColor.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(
                    color: scoreColor.withOpacity(_glowAnim.value * 0.55),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withOpacity(_glowAnim.value * 0.22),
                      blurRadius: 32,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Animated score ring with counter
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RepaintBoundary(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: score / 100),
                              duration: const Duration(milliseconds: 1600),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => CustomPaint(
                                size: const Size(92, 92),
                                painter: _EnergyRingPainter(
                                  progress: v,
                                  color: scoreColor,
                                  glow: _glowAnim.value,
                                ),
                              ),
                            ),
                          ),
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: score),
                            duration: const Duration(milliseconds: 1600),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$v%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  scoreLabel,
                                  style: TextStyle(
                                      color: scoreColor,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _scoreBar(
                              '😴',
                              'Sleep',
                              (lunarData.lastSleepHours / 9).clamp(0.0, 1.0),
                              _hIndigo),
                          const SizedBox(height: 10),
                          _scoreBar(
                              '💧',
                              'Hydration',
                              (lunarData.todayWaterGlasses / 8).clamp(0.0, 1.0),
                              _hTeal),
                          const SizedBox(height: 10),
                          _scoreBar(
                              '⚡',
                              'Energy',
                              lunarData.energyLevel == 'high'
                                  ? 0.88
                                  : lunarData.energyLevel == 'low'
                                      ? 0.35
                                      : 0.62,
                              _hGold),
                          const SizedBox(height: 10),
                          _scoreBar(
                              '🌡️',
                              'Temp',
                              lunarData.lastTempC >= 36.0 &&
                                      lunarData.lastTempC <= 37.2
                                  ? 0.90
                                  : 0.55,
                              _hWarm),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scoreBar(String icon, String label, double value, Color color) {
    return Row(children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 5),
      SizedBox(
        width: 46,
        child: Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 10)),
      ),
      Expanded(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: value),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor:
                  AlwaysStoppedAnimation<Color>(color.withOpacity(0.82)),
            ),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        '${(value * 100).toInt()}%',
        style:
            TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w600),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────
  //  AI SUGGESTION CHIPS
  // ─────────────────────────────────────────────────────────
  Widget _aiSuggestionChips(UserProvider user, LunarDataProvider lunarData) {
    final chips = _generateChips(user, lunarData);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Suggestions for You'),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: chips.asMap().entries.map((entry) {
              final i = entry.key;
              final chip = entry.value;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_floatAnim, _glowAnim]),
                  builder: (_, __) => Transform.translate(
                    offset: Offset(
                        0, _floatAnim.value * 0.20 * (i % 2 == 0 ? 1.0 : -1.0)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(colors: [
                              chip.color.withOpacity(0.24),
                              chip.color.withOpacity(0.08),
                            ]),
                            border: Border.all(
                              color: chip.color
                                  .withOpacity(_glowAnim.value * 0.52),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: chip.color
                                    .withOpacity(_glowAnim.value * 0.18),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(chip.emoji,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 7),
                              Text(chip.label,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.88),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<_SuggestionChip> _generateChips(
      UserProvider user, LunarDataProvider lunarData) {
    final chips = <_SuggestionChip>[];
    if (lunarData.todayWaterGlasses < 5) {
      chips.add(_SuggestionChip('💧', 'Drink more water', _hTeal));
    }
    if (lunarData.lastSleepHours < 7) {
      chips.add(_SuggestionChip('✨', 'Sleep earlier tonight', _hIndigo));
    }
    switch (_phaseOf(user)) {
      case _CyclePhase.period:
        chips.add(_SuggestionChip('🌸', 'Use a heat pad', _hPink));
        chips.add(_SuggestionChip('🧘\u200d♀️', 'Rest & breathe', _hPurple));
        break;
      case _CyclePhase.follicular:
        chips.add(_SuggestionChip('🎯', 'Plan your goals', _hGreen));
        chips.add(_SuggestionChip('🌱', 'Start something new', _hTeal));
        break;
      case _CyclePhase.ovulation:
        chips.add(_SuggestionChip('💌', 'Connect with loved ones', _hPink));
        chips.add(_SuggestionChip('🌟', 'Shine today', _hGold));
        break;
      case _CyclePhase.luteal:
        chips.add(_SuggestionChip('📖', 'Journal emotions', _hPurple));
        chips.add(_SuggestionChip('🌙', 'Wind down early', _hIndigo));
        break;
      default:
        chips.add(_SuggestionChip('🌙', 'Try deep breathing', _hPurple));
    }
    chips.add(_SuggestionChip('💜', 'Journal your emotions', _hPink));
    return chips;
  }

  // ─────────────────────────────────────────────────────────
  //  HERO SECTION — Cinematic premium hero with large orb
  // ─────────────────────────────────────────────────────────
  Widget _heroSection(UserProvider user, ChatProvider chat) {
    final app = context.read<AppProvider>();
    final name = app.userName.isNotEmpty ? app.userName : 'beautiful soul';
    final phaseColor = _phaseRingColor(user);
    final phaseColors = _phaseColors(user);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top greeting row: avatar + name + live status
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerGreeting(user),
                  const SizedBox(height: 3),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 700),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Text(
                      _aiSubtitles[_aiSubtitleIdx],
                      key: ValueKey(_aiSubtitleIdx),
                      style: TextStyle(
                        color: const Color(0xFFD8A8FF).withOpacity(0.72),
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _liveStatusPill(),
          ],
        ),
        const SizedBox(height: 30),
        // LIVING LUNAR ORB — emotionally alive, breathing, reactive
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge(
                [_glowAnim, _breatheAnim, _floatAnim, _pulseAnim]),
            builder: (_, child) {
              final glow = _glowAnim.value;
              final pulse = _pulseAnim.value;
              final float = _floatAnim.value * 0.55;
              final dominantEmotion = chat.dominantEmotion;
              final emotionColor = _emotionOrbColor(dominantEmotion);
              // Weather-reactive third glow layer (Phase 4)
              final weatherOrb = context.read<WeatherProvider>();
              final weatherAccent = weatherOrb.todayWeather.accentColor;

              // Emotion-reactive breathing — faster for anxiety, slower for sadness
              final breatheSpeed = dominantEmotion == EmotionTag.anxious
                  ? 0.97 + 0.035 * _breatheAnim.value
                  : dominantEmotion == EmotionTag.sad ||
                          dominantEmotion == EmotionTag.tired
                      ? 0.974 + 0.022 * _breatheAnim.value
                      : dominantEmotion == EmotionTag.happy ||
                              dominantEmotion == EmotionTag.energetic
                          ? 0.97 + 0.040 * _breatheAnim.value
                          : 0.968 + 0.030 * _breatheAnim.value;

              // Emotion-reactive glow intensity
              final emotionGlowStrength = dominantEmotion == EmotionTag.sad ||
                      dominantEmotion == EmotionTag.lonely
                  ? 0.18 // softer for pain states
                  : dominantEmotion == EmotionTag.happy ||
                          dominantEmotion == EmotionTag.energetic
                      ? 0.40 // brighter for joy
                      : 0.28;

              return Transform.translate(
                offset: Offset(0, float),
                child: SizedBox(
                  width: 252,
                  height: 252,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer atmospheric haze rings — breathe with the orb
                      ...List.generate(3, (i) {
                        final ringSize = 210.0 + i * 26;
                        final opacity =
                            (0.16 - i * 0.045).clamp(0.0, 1.0) * glow;
                        return Container(
                          width: ringSize * breatheSpeed,
                          height: ringSize * breatheSpeed,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: phaseColor.withOpacity(opacity),
                              width: 1.2,
                            ),
                          ),
                        );
                      }),
                      // Emotion-reactive nebula wisp layer
                      if (dominantEmotion != null)
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment(
                                  0.3 * math.sin(pulse * math.pi * 2),
                                  -0.3 * math.cos(pulse * math.pi * 2)),
                              radius: 0.85,
                              colors: [
                                emotionColor
                                    .withOpacity(emotionGlowStrength * glow),
                                emotionColor.withOpacity(
                                    emotionGlowStrength * 0.4 * glow),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      // Weather-reactive outer halo (Phase 4)
                      Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(0.0, -0.4),
                            radius: 1.0,
                            colors: [
                              Colors.transparent,
                              weatherAccent.withOpacity(0.10 * glow),
                              Colors.transparent,
                            ],
                            stops: const [0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                      // Soft ambient phase glow behind orb
                      Container(
                        width: 212,
                        height: 212,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              phaseColor.withOpacity(0.0),
                              phaseColor.withOpacity(glow * 0.15),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                      // Main orb — breathing scale, phase gradient
                      Transform.scale(
                        scale: breatheSpeed,
                        child: Container(
                          width: 174,
                          height: 174,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: phaseColors,
                              center: const Alignment(-0.2, -0.3),
                            ),
                            boxShadow: [
                              // Phase core glow
                              BoxShadow(
                                color: phaseColor.withOpacity(glow * 0.55),
                                blurRadius: 44,
                                spreadRadius: 12,
                              ),
                              // Emotion-reactive outer aura
                              BoxShadow(
                                color: emotionColor
                                    .withOpacity(glow * emotionGlowStrength),
                                blurRadius: 36,
                                spreadRadius: 8,
                              ),
                              // Weather-reactive glow (Phase 4)
                              BoxShadow(
                                color: weatherAccent.withOpacity(glow * 0.18),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                              // Soft pink inner warmth
                              BoxShadow(
                                color: _hPink.withOpacity(glow * 0.22),
                                blurRadius: 22,
                                spreadRadius: 4,
                              ),
                              // Deep shadow for depth
                              BoxShadow(
                                color: Colors.black.withOpacity(0.42),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22 * glow),
                              width: 1.5,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      // Heartbeat pulse ring — appears briefly every ~4s
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) {
                          final pulsePhase = (_pulseAnim.value * 2) % 1.0;
                          final pulsing = pulsePhase < 0.25;
                          final pulseScale =
                              1.0 + (pulsing ? pulsePhase * 4 * 0.22 : 0.0);
                          return IgnorePointer(
                            child: Transform.scale(
                              scale: pulseScale,
                              child: Container(
                                width: 182,
                                height: 182,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: phaseColor.withOpacity(pulsing
                                        ? (0.25 * (1.0 - pulsePhase * 4.0))
                                            .clamp(0.0, 1.0)
                                        : 0.0),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🌙', style: TextStyle(fontSize: 54)),
                const SizedBox(height: 4),
                Text(
                  _cycleDayLabel(user),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _phaseLabel(user).replaceAll('\n', ' '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Emotional greeting beneath orb — powered by AI memory
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
          child: Text(
            chat.emotionalProfile.dominantEmotion != null ||
                    chat.emotionalProfile.daysSinceLastVisit >= 2
                ? chat.generateGreeting(name).split('\n\n').last
                : _greeting(user),
            key: ValueKey(chat.emotionalProfile.dominantEmotion),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFD8A8FF).withOpacity(0.80),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Phase + today badge row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pill(_phaseLabel(user).replaceAll('\n', ' '), _hPurple,
                const Color(0xFFD8A8FF)),
            const SizedBox(width: 8),
            _pill(_cycleDayLabel(user), _hPink, Colors.white),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  LIVE AI INSIGHT BANNER — Rotating shimmer intelligence card
  // ─────────────────────────────────────────────────────────
  Widget _liveAIInsightBanner(UserProvider user) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowAnim, _shimmerAnim, _pulseAnim]),
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF5C2DB8).withOpacity(0.52),
                  const Color(0xFFAB5CF2).withOpacity(0.28),
                  const Color(0xFFFF69B4).withOpacity(0.15),
                ],
              ),
              border: Border.all(
                color: _hPurple.withOpacity(_glowAnim.value * 0.52),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hPurple.withOpacity(_glowAnim.value * 0.20),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Shimmer sweep
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: OverflowBox(
                      maxWidth: double.infinity,
                      child: Transform.translate(
                        offset: Offset(_shimmerAnim.value * 200, 0),
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.04),
                              Colors.white.withOpacity(0.0),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Orb icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          _hGold.withOpacity(0.32 + 0.14 * _glowAnim.value),
                          _hPurple.withOpacity(0.18),
                        ]),
                        border: Border.all(
                          color: _hGold.withOpacity(0.55 * _glowAnim.value),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _hGold.withOpacity(0.28 * _glowAnim.value),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                          child: Text('🔮', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Lunar Intelligence',
                                style: TextStyle(
                                  color: _hPurple.withOpacity(0.82),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _hGreen,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _hGreen
                                          .withOpacity(_pulseAnim.value * 0.9),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Live',
                                style: TextStyle(
                                  color: _hGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 700),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: CurvedAnimation(
                                  parent: anim, curve: Curves.easeOut),
                              child: SlideTransition(
                                position: Tween<Offset>(
                                        begin: const Offset(0, 0.2),
                                        end: Offset.zero)
                                    .animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic)),
                                child: child,
                              ),
                            ),
                            child: Text(
                              _aiInsight(user),
                              key: ValueKey(_aiInsight(user)),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.80),
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  WELLNESS RINGS — Apple Health-inspired animated ring row
  // ─────────────────────────────────────────────────────────
  Widget _wellnessRingsRow(LunarDataProvider lunarData) {
    final rings = [
      _RingData('💧', 'Hydration',
          (lunarData.todayWaterGlasses / 8).clamp(0.0, 1.0), _hTeal),
      _RingData('😴', 'Sleep', (lunarData.lastSleepHours / 9).clamp(0.0, 1.0),
          _hIndigo),
      _RingData(
          '⚡',
          'Energy',
          lunarData.energyLevel == 'high'
              ? 0.88
              : lunarData.energyLevel == 'low'
                  ? 0.32
                  : 0.62,
          _hGold),
      _RingData(
          '🌸',
          'Balance',
          lunarData.lastTempC >= 36.0 && lunarData.lastTempC <= 37.2
              ? 0.90
              : 0.55,
          _hPink),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Wellness Rings'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: rings.map(_wellnessRingItem).toList(),
        ),
      ],
    );
  }

  Widget _wellnessRingItem(_RingData ring) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Column(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Track ring (background)
                CustomPaint(
                  size: const Size(74, 74),
                  painter: _EnergyRingPainter(
                    progress: 1.0,
                    color: ring.color.withOpacity(0.12),
                    glow: 0,
                  ),
                ),
                // Animated progress arc
                RepaintBoundary(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: ring.progress),
                    duration: const Duration(milliseconds: 1600),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => CustomPaint(
                      size: const Size(74, 74),
                      painter: _EnergyRingPainter(
                        progress: v,
                        color: ring.color
                            .withOpacity(0.78 + 0.22 * _glowAnim.value),
                        glow: _glowAnim.value,
                      ),
                    ),
                  ),
                ),
                // Center emoji
                Text(ring.emoji, style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            ring.label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${(ring.progress * 100).toInt()}%',
            style: TextStyle(
              color: ring.color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PRIMARY CTA BUTTON — Single hero call-to-action
  // ─────────────────────────────────────────────────────────
  Widget _primaryCTAButton(BuildContext ctx) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _breatheAnim, _shimmerAnim]),
      builder: (_, __) => GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _nav(ctx, const AIVoiceScreen());
        },
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5C2DB8),
                Color(0xFFAB5CF2),
                Color(0xFFFF69B4)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFAB5CF2)
                    .withOpacity(0.28 + _glowAnim.value * 0.28),
                blurRadius: 22 + _glowAnim.value * 14,
                spreadRadius: _breatheAnim.value * 2.5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    child: Transform.translate(
                      offset: Offset(_shimmerAnim.value * 160, 0),
                      child: Container(
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.18),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white
                            .withOpacity(0.12 + _pulseAnim.value * 0.08),
                      ),
                      child: const Center(
                          child:
                              Text('🌙', style: TextStyle(fontSize: 17))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Talk to Lunar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.70),
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  WELLNESS SNAPSHOT — 4 compact tappable tiles
  // ─────────────────────────────────────────────────────────
  Widget _wellnessSnapshot(
      BuildContext ctx, LunarDataProvider lunarData, UserProvider user) {
    final phaseColor = _phaseRingColor(user);
    final cycleDay = user.lastPeriodDate == null
        ? 'Set up'
        : 'Day ${DateTime.now().difference(user.lastPeriodDate!).inDays + 1}';
    final moodValue =
        lunarData.moodEntries.isNotEmpty ? 'Logged ✓' : 'Log today';
    final sleepValue = '${lunarData.lastSleepHours.toStringAsFixed(1)} hrs';
    final journalCount = lunarData.journalEntries.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY AT A GLANCE',
          style: TextStyle(
            color: Colors.white.withOpacity(0.38),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _snapshotCard(
                emoji: '😊',
                label: 'Mood',
                value: moodValue,
                color: _hPink,
                onTap: () => _nav(ctx, const MoodTrackingScreen()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _snapshotCard(
                emoji: '😴',
                label: 'Sleep',
                value: sleepValue,
                color: _hIndigo,
                onTap: () => _nav(ctx, const SleepScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _snapshotCard(
                emoji: '🌙',
                label: 'Cycle',
                value: cycleDay,
                color: phaseColor,
                onTap: () => _nav(ctx, const CycleTrackerScreen()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _snapshotCard(
                emoji: '📓',
                label: 'Journal',
                value: journalCount > 0
                    ? '$journalCount entries'
                    : 'Write today',
                color: _hGold,
                onTap: () => _nav(ctx, const JournalScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _snapshotCard({
    required String emoji,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.18),
                    color.withOpacity(0.06),
                  ],
                ),
                border: Border.all(
                  color: color.withOpacity(0.3 + _glowAnim.value * 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(_glowAnim.value * 0.12),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.16),
                      border: Border.all(
                          color: color.withOpacity(0.35), width: 1),
                    ),
                    child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 19))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: color.withOpacity(0.45), size: 16),
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
//  DREAMY BACKGROUND
// ═══════════════════════════════════════════════════════════
class _DreamyBackground extends StatelessWidget {
  final Size size;
  const _DreamyBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.45),
          radius: 1.3,
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
              top: -80,
              left: -60,
              child: _blob(320, const Color(0xFF9B59B6), 0.28)),
          Positioned(
              top: 80,
              right: -80,
              child: _blob(260, const Color(0xFFE91E8C), 0.18)),
          Positioned(
              top: size.height * 0.35,
              left: size.width * 0.5 - 140,
              child: _blob(280, const Color(0xFF7B2FF7), 0.14)),
          Positioned(
              bottom: 60,
              left: -70,
              child: _blob(300, const Color(0xFF6C3FC8), 0.22)),
          Positioned(
              bottom: 0,
              right: -50,
              child: _blob(250, const Color(0xFFFF69B4), 0.15)),
          // Moon glow — top-right ambient
          Positioned(
              top: -40,
              right: -50,
              child: _blob(240, const Color(0xFFFFD700), 0.12)),
          Positioned(
              top: 10,
              right: 0,
              child: _blob(110, const Color(0xFFFFF8DC), 0.08)),
          // Cloud depth layers
          Positioned(
              top: size.height * 0.18,
              left: -80,
              child: _blob(200, const Color(0xFF7B2FF7), 0.09)),
          Positioned(
              top: size.height * 0.60,
              right: -90,
              child: _blob(230, const Color(0xFF9B59B6), 0.07)),
          Positioned(
              top: size.height * 0.26,
              left: size.width * 0.5 - 95,
              child: _blob(190, const Color(0xFFFF69B4), 0.05)),
          // Animated nebula glow layer
          RepaintBoundary(
            child: _AnimatedNebula(size: size),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [color.withOpacity(opacity), Colors.transparent]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════
//  ORBITAL PAINTER
// ═══════════════════════════════════════════════════════════
class _OrbitalPainter extends CustomPainter {
  final double rotation;
  final double glow;
  final Color phaseColor;

  _OrbitalPainter(
      {required this.rotation, required this.glow, required this.phaseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    _ring(canvas, c, 132, phaseColor.withOpacity(0.28 * glow), 1.5);
    _ring(
        canvas, c, 112, const Color(0xFFFF69B4).withOpacity(0.35 * glow), 1.2);
    _ring(canvas, c, 96, const Color(0xFFAB5CF2).withOpacity(0.18 * glow), 0.8);

    _orbitDot(canvas, c, 132, rotation, const Color(0xFFFFD700), 6);
    _orbitDot(
        canvas, c, 112, rotation + math.pi * 0.65, const Color(0xFFFF69B4), 4);
    _orbitDot(canvas, c, 132, rotation + math.pi * 1.4, Colors.white, 3);
    _orbitDot(
        canvas, c, 96, rotation + math.pi * 0.9, const Color(0xFFAB5CF2), 3.5);

    final starPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    const offsets = [
      Offset(-105, -55),
      Offset(95, -88),
      Offset(-82, 98),
      Offset(112, 48),
      Offset(-38, -122),
      Offset(52, 118),
      Offset(125, -28),
      Offset(-118, 30),
    ];
    for (final o in offsets) {
      canvas.drawCircle(c + o, 1.8, starPaint);
    }
  }

  void _ring(Canvas canvas, Offset c, double r, Color color, double w) {
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 2.5));
  }

  void _orbitDot(
      Canvas canvas, Offset c, double r, double angle, Color color, double s) {
    final pos = Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));
    canvas.drawCircle(
        pos,
        s,
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 1.5));
    canvas.drawCircle(pos, s * 0.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_OrbitalPainter old) =>
      old.rotation != rotation ||
      old.glow != glow ||
      old.phaseColor != phaseColor;
}

// ═══════════════════════════════════════════════════════════
//  PARTICLE SYSTEM
// ═══════════════════════════════════════════════════════════
class _StarParticle {
  late double x, y, speed, size, opacity, angle;

  _StarParticle({required math.Random rng}) {
    reset(rng);
  }

  void reset(math.Random rng) {
    x = rng.nextDouble();
    y = rng.nextDouble();
    speed = 0.00015 + rng.nextDouble() * 0.00025;
    size = 0.8 + rng.nextDouble() * 2.2;
    opacity = 0.25 + rng.nextDouble() * 0.55;
    angle = rng.nextDouble() * math.pi * 2;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_StarParticle> particles;
  final List<_HeartParticle> hearts;
  final double progress;

  _ParticlePainter(
      {required this.particles, required this.hearts, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // ── Star / dust particles ──
    for (final p in particles) {
      final x = (p.x + math.cos(p.angle) * p.speed * progress * 120) % 1.0;
      final y = (p.y - p.speed * progress * 240) % 1.0;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        Paint()
          ..color = Colors.white.withOpacity(p.opacity * 0.72)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );

      if (p.size > 2.0) {
        final sp = Paint()
          ..color = const Color(0xFFAB5CF2).withOpacity(p.opacity * 0.45)
          ..strokeWidth = 0.6;
        final cx = x * size.width;
        final cy = y * size.height;
        // Horizontal + vertical cross
        canvas.drawLine(Offset(cx - 5, cy), Offset(cx + 5, cy), sp);
        canvas.drawLine(Offset(cx, cy - 5), Offset(cx, cy + 5), sp);
        // Diagonal sparkle lines for larger stars
        if (p.size > 2.8) {
          final diag = Paint()
            ..color = const Color(0xFFFF69B4).withOpacity(p.opacity * 0.28)
            ..strokeWidth = 0.5;
          canvas.drawLine(Offset(cx - 3, cy - 3), Offset(cx + 3, cy + 3), diag);
          canvas.drawLine(Offset(cx + 3, cy - 3), Offset(cx - 3, cy + 3), diag);
        }
      }
    }

    // ── Floating hearts ──
    for (final h in hearts) {
      final wobble = math.sin(h.phase + progress * math.pi * 2) * 0.012;
      final x = (h.x + wobble) % 1.0;
      final y = (h.y - h.speed * progress * 280) % 1.0;
      final fade = h.opacity *
          (0.45 + 0.55 * math.sin(progress * math.pi * 2 + h.phase));

      _drawHeart(
        canvas,
        Offset(x * size.width, y * size.height),
        h.size,
        const Color(0xFFFF69B4).withOpacity(fade.clamp(0.0, 1.0)),
      );
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.55);
    final r = size * 0.38;
    canvas.drawCircle(
        Offset(center.dx - r * 0.55, center.dy - r * 0.25), r, paint);
    canvas.drawCircle(
        Offset(center.dx + r * 0.55, center.dy - r * 0.25), r, paint);
    final path = Path()
      ..moveTo(center.dx - size * 0.75, center.dy - r * 0.2)
      ..lineTo(center.dx, center.dy + size * 0.55)
      ..lineTo(center.dx + size * 0.75, center.dy - r * 0.2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════
class _QuickAction {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool isHighlight;
  _QuickAction(this.icon, this.label, this.onTap, {this.isHighlight = false});
}

class _InsightCard {
  final String icon, title, body;
  final Color color;
  _InsightCard(
      {required this.icon,
      required this.title,
      required this.body,
      required this.color});
}

class _HealthItem {
  final String icon, label, value, unit;
  final double progress;
  final Color accentColor;
  _HealthItem(this.icon, this.label, this.value, this.unit,
      {this.progress = 0.5, this.accentColor = const Color(0xFFAB5CF2)});
}

class _CareTip {
  final String icon, title, desc;
  final Color color;
  _CareTip(this.icon, this.title, this.desc, this.color);
}

// ═══════════════════════════════════════════════════════════
//  HEART PARTICLE
// ═══════════════════════════════════════════════════════════
class _HeartParticle {
  late double x, y, speed, size, opacity, phase;

  _HeartParticle({required math.Random rng}) {
    reset(rng);
  }

  void reset(math.Random rng) {
    x = rng.nextDouble();
    y = 0.75 + rng.nextDouble() * 0.25; // start near bottom
    speed = 0.00006 + rng.nextDouble() * 0.0001;
    size = 3.5 + rng.nextDouble() * 4.5;
    opacity = 0.15 + rng.nextDouble() * 0.3;
    phase = rng.nextDouble() * math.pi * 2;
  }
}

// ═══════════════════════════════════════════════════════════
//  MOOD CARD DATA MODEL
// ═══════════════════════════════════════════════════════════
class _MoodCard {
  final String emoji, label, subtitle;
  final Color color;
  const _MoodCard(this.emoji, this.label, this.subtitle, this.color);
}

// ═══════════════════════════════════════════════════════════
//  SUGGESTION CHIP DATA MODEL
// ═══════════════════════════════════════════════════════════
class _SuggestionChip {
  final String emoji, label;
  final Color color;
  const _SuggestionChip(this.emoji, this.label, this.color);
}

// ═══════════════════════════════════════════════════════════
//  RING DATA MODEL
// ═══════════════════════════════════════════════════════════
class _RingData {
  final String emoji, label;
  final double progress;
  final Color color;
  const _RingData(this.emoji, this.label, this.progress, this.color);
}

// ═══════════════════════════════════════════════════════════
//  CYCLE PHASE ENUM
// ═══════════════════════════════════════════════════════════
enum _CyclePhase { period, follicular, ovulation, luteal, unknown }

// ═══════════════════════════════════════════════════════════
//  TYPEWRITER TEXT WIDGET
// ═══════════════════════════════════════════════════════════
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _TypewriterText({required this.text, required this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  int _visibleChars = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  @override
  void didUpdateWidget(_TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _timer?.cancel();
      _visibleChars = 0;
      _startTypewriter();
    }
  }

  void _startTypewriter() {
    _timer = Timer.periodic(const Duration(milliseconds: 35), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_visibleChars < widget.text.length) {
          _visibleChars++;
        } else {
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text.substring(0, _visibleChars),
      style: widget.style,
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ENERGY RING PAINTER
// ═══════════════════════════════════════════════════════════
class _EnergyRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glow;

  const _EnergyRingPainter(
      {required this.progress, required this.color, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 7;

    // Background ring
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color.withOpacity(0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Glow ring
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color.withOpacity(0.08 * glow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Progress arc
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0 * glow),
    );

    // Bright tip dot
    if (progress > 0.02) {
      final tipAngle = -math.pi / 2 + sweep;
      final tipPos =
          Offset(c.dx + r * math.cos(tipAngle), c.dy + r * math.sin(tipAngle));
      canvas.drawCircle(
        tipPos,
        4,
        Paint()
          ..color = Colors.white
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * glow),
      );
    }
  }

  @override
  bool shouldRepaint(_EnergyRingPainter old) =>
      old.progress != progress || old.glow != glow;
}

// ═══════════════════════════════════════════════════════════
//  ANIMATED NEBULA
// ═══════════════════════════════════════════════════════════
class _AnimatedNebula extends StatefulWidget {
  final Size size;
  const _AnimatedNebula({required this.size});

  @override
  State<_AnimatedNebula> createState() => _AnimatedNebulaState();
}

class _AnimatedNebulaState extends State<_AnimatedNebula>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 7))
          ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: widget.size,
        painter: _NebulaPainter(t: _anim.value),
      ),
    );
  }
}

class _NebulaPainter extends CustomPainter {
  final double t;
  const _NebulaPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w * 0.28, h * 0.12),
      130,
      Paint()
        ..color = const Color(0xFF7B2FF7).withOpacity(0.055 + 0.035 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 55),
    );

    canvas.drawCircle(
      Offset(w * 0.78, h * 0.30),
      110,
      Paint()
        ..color = const Color(0xFFFF69B4).withOpacity(0.04 + 0.03 * (1 - t))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70),
    );

    canvas.drawCircle(
      Offset(w * 0.18, h * 0.62),
      150,
      Paint()
        ..color = const Color(0xFF4A00E0).withOpacity(0.045 + 0.025 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 65),
    );

    canvas.drawCircle(
      Offset(w * 0.65, h * 0.72),
      100,
      Paint()
        ..color = const Color(0xFFAB5CF2).withOpacity(0.035 + 0.02 * (1 - t))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );
  }

  @override
  bool shouldRepaint(_NebulaPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════
//  HOME WEATHER SHARE SHEET
//  Minimal share sheet used from home_dashboard _dailyReadingCard.
//  Copies weather reading text to clipboard.
// ══════════════════════════════════════════════════════════════

class _HomeWeatherShareSheet extends StatelessWidget {
  final DayWeather today;

  const _HomeWeatherShareSheet({required this.today});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: Color(0xFF12022B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(today.emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(
                  today.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  today.reading.split('\n\n').first,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13.5,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                // Copy button
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: today.buildShareText()),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Reading copied! Share it with someone you love 🌙',
                        ),
                        backgroundColor: today.accentColor.withOpacity(0.9),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          today.accentColor.withOpacity(0.85),
                          today.accentColor.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Copy Reading',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 14,
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
}

// ═══════════════════════════════════════════════════════════
//  EMOTION ATMOSPHERE LAYER
//  Overlays a living, mood-reactive hue wash over the background.
//  Reacts to: dominant emotion, time of day, pregnancy, sleep.
// ═══════════════════════════════════════════════════════════
class _EmotionAtmosphereLayer extends StatelessWidget {
  final Size size;
  final EmotionTag? emotion;
  final int hour;
  final bool isPregnant;
  final bool isSleepDeprived;
  final Animation<double> animation;

  const _EmotionAtmosphereLayer({
    required this.size,
    required this.animation,
    this.emotion,
    this.hour = 12,
    this.isPregnant = false,
    this.isSleepDeprived = false,
  });

  Color get _emotionColor => switch (emotion) {
        EmotionTag.anxious => const Color(0xFF4FC3F7), // calming teal mist
        EmotionTag.sad => const Color(0xFF3D5AFE), // deep contemplative blue
        EmotionTag.lonely => const Color(0xFF7C4DFF), // soft violet presence
        EmotionTag.happy ||
        EmotionTag.energetic =>
          const Color(0xFFFFB300), // warm golden sunrise
        EmotionTag.tired => const Color(0xFF5C6BC0), // muted twilight blue
        EmotionTag.emotional => const Color(0xFFFF69B4), // tender rose
        EmotionTag.period => const Color(0xFFE91E8C), // sacred crimson
        EmotionTag.stressed => const Color(0xFF651FFF), // deep grounding indigo
        _ => const Color(0xFF9B59B6), // default lunar violet
      };

  bool get _isNight => hour >= 21 || hour < 5;
  bool get _isMorning => hour >= 5 && hour < 10;
  bool get _isEvening => hour >= 17 && hour < 21;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final glow = animation.value;
        final color = isPregnant ? const Color(0xFFFF8A80) : _emotionColor;

        // Intensity multipliers per context
        final topOpacity = 0.055 * glow * (emotion != null ? 1.0 : 0.5);
        final bottomOpacity = 0.04 * glow * (emotion != null ? 1.0 : 0.3);
        final nightOpacity = _isNight ? 0.18 : 0.0;
        final morningOpacity = _isMorning ? (0.05 * glow) : 0.0;
        final eveningOpacity = _isEvening ? (0.06 * glow) : 0.0;
        final sleepOpacity = isSleepDeprived ? 0.08 : 0.0;

        return IgnorePointer(
          child: Stack(
            children: [
              // ─── Emotion top radial wash ────────────────
              if (emotion != null || isPregnant)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: size.height * 0.55,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.1, -0.5),
                        radius: 1.1,
                        colors: [
                          color.withOpacity(topOpacity * 1.4),
                          color.withOpacity(topOpacity * 0.6),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

              // ─── Emotion bottom counter-glow ───────────
              if (emotion != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: size.height * 0.30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          color.withOpacity(bottomOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // ─── Night mode: darker blue overlay ───────
              if (_isNight)
                Container(
                  color: const Color(0xFF00002E).withOpacity(nightOpacity),
                ),

              // ─── Sleep-deprived: muted cool mist ───────
              if (isSleepDeprived)
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.5,
                      colors: [
                        const Color(0xFF0D1B2A).withOpacity(sleepOpacity),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

              // ─── Morning: soft amber top glow ──────────
              if (_isMorning)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: size.height * 0.28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFFFB300).withOpacity(morningOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // ─── Evening: warm purple-gold blend ───────
              if (_isEvening)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: size.height * 0.38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF6A1B9A).withOpacity(eveningOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // ─── Pregnancy: warm rose overlay ──────────
              if (isPregnant)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: size.height * 0.40,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.0,
                        colors: [
                          const Color(0xFFFF8A80).withOpacity(0.07 * glow),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PHASE 4 DATA CLASSES
// ═══════════════════════════════════════════════════════════

class _EnergyMetrics {
  final int balance;
  final int stressLoad;
  final int recovery;

  const _EnergyMetrics(this.balance, this.stressLoad, this.recovery);

  int get overall => ((balance + (100 - stressLoad) + recovery) / 3).round();
}

class _FocusData {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _FocusData(this.emoji, this.title, this.subtitle, this.color);
}

// ═══════════════════════════════════════════════════════════
//  MOOD SPARKLINE PAINTER
// ═══════════════════════════════════════════════════════════

class _MoodSparklinePainter extends CustomPainter {
  final List<DayWeather> history;
  final Color lineColor;
  final Color glowColor;

  const _MoodSparklinePainter({
    required this.history,
    required this.lineColor,
    required this.glowColor,
  });

  static double _stateValue(EmotionalWeatherState state) {
    switch (state) {
      case EmotionalWeatherState.radiantDay:
        return 92;
      case EmotionalWeatherState.healingEnergy:
        return 78;
      case EmotionalWeatherState.selfLoveDay:
        return 72;
      case EmotionalWeatherState.calmMoon:
        return 68;
      case EmotionalWeatherState.emotionalTide:
        return 52;
      case EmotionalWeatherState.gentleHeartDay:
        return 45;
      case EmotionalWeatherState.releaseWeather:
        return 35;
      case EmotionalWeatherState.emotionalStorm:
        return 20;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    final values = history.map((d) => _stateValue(d.state)).toList();
    final minV = values.reduce((a, b) => a < b ? a : b) - 5;
    final maxV = values.reduce((a, b) => a > b ? a : b) + 5;
    final range = (maxV - minV).clamp(1.0, 100.0);

    Offset toPoint(int i, double v) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((v - minV) / range) * size.height;
      return Offset(x, y);
    }

    final points = List.generate(values.length, (i) => toPoint(i, values[i]));

    // Glow fill beneath the line
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 =
          Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      fillPath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withOpacity(0.28),
            lineColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Glow stroke
    final glowPath = Path();
    glowPath.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 =
          Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      glowPath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }

    canvas.drawPath(
      glowPath,
      Paint()
        ..color = glowColor.withOpacity(0.35)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main line
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dot at each data point
    for (int i = 0; i < points.length; i++) {
      final isLast = i == points.length - 1;
      canvas.drawCircle(
        points[i],
        isLast ? 4.5 : 2.5,
        Paint()..color = isLast ? lineColor : lineColor.withOpacity(0.65),
      );
      if (isLast) {
        canvas.drawCircle(
          points[i],
          8,
          Paint()
            ..color = lineColor.withOpacity(0.20)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MoodSparklinePainter old) => old.history != history;
}

// ═══════════════════════════════════════════════════════════
//  SECONDARY QUESTION SHEET
//  Intent-aware follow-up shown after mood selection.
// ═══════════════════════════════════════════════════════════
class _SecondaryQuestionSheet extends StatefulWidget {
  const _SecondaryQuestionSheet({
    required this.question,
    required this.options,
    required this.onSelected,
    required this.onSkip,
  });
  final String question;
  final List<String> options;
  final void Function(String) onSelected;
  final VoidCallback onSkip;

  @override
  State<_SecondaryQuestionSheet> createState() =>
      _SecondaryQuestionSheetState();
}

class _SecondaryQuestionSheetState extends State<_SecondaryQuestionSheet> {
  String? _selected;

  static const _bg = Color(0xFF0A0118);
  static const _surface = Color(0xFF160330);
  static const _purple = Color(0xFFAB5CF2);
  static const _pink = Color(0xFFFF69B4);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            widget.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          ...widget.options.map((opt) {
            final isSelected = _selected == opt;
            return GestureDetector(
              onTap: () => setState(() => _selected = opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: isSelected
                      ? LinearGradient(colors: [
                          _purple.withOpacity(0.30),
                          _pink.withOpacity(0.15),
                        ])
                      : null,
                  color: isSelected ? null : _surface,
                  border: Border.all(
                    color: isSelected
                        ? _purple.withOpacity(0.70)
                        : Colors.white.withOpacity(0.08),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.70),
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onSkip,
                child: Center(
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AnimatedOpacity(
                opacity: _selected != null ? 1.0 : 0.38,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _selected != null
                      ? () => widget.onSelected(_selected!)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [_purple, _pink],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CHECK-IN MILESTONE SHEET
//  Celebration card shown when a streak milestone is earned.
// ═══════════════════════════════════════════════════════════
class _CheckInMilestoneSheet extends StatelessWidget {
  const _CheckInMilestoneSheet({
    required this.milestone,
    required this.onDismiss,
  });
  final CheckInMilestone milestone;
  final VoidCallback onDismiss;

  static const _bg = Color(0xFF0A0118);
  static const _gold = Color(0xFFFFD700);
  static const _purple = Color(0xFFAB5CF2);
  static const _pink = Color(0xFFFF69B4);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            milestone.emoji,
            style: const TextStyle(fontSize: 52),
          ),
          const SizedBox(height: 16),
          Text(
            'Milestone Reached',
            style: TextStyle(
              color: _gold,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            milestone.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            milestone.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [_purple, _pink],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: const Center(
                child: Text(
                  'Keep Going 💜',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
