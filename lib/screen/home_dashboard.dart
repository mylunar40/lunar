import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import 'mood_screen.dart';
import 'mood_tracking_screen.dart';
import 'journal_screen.dart';
import 'cycle_tracker_screen.dart';
import 'period_screen.dart';
import 'ai_voice_screen.dart';
import 'ai_insights_screen.dart';
import 'community_screen.dart';
import 'sleep_screen.dart';
import 'pregnancy_screen.dart';

// ── Local design tokens ─────────────────────────────────────
const Color _hBg = Color(0xFF0A0118);
const Color _hPurple = Color(0xFFAB5CF2);
const Color _hPink = Color(0xFFFF69B4);
const Color _hDeep = Color(0xFF5C2DB8);
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

  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _breatheAnim;
  late Animation<double> _pulseAnim;

  final List<_StarParticle> _particles = [];
  final List<_HeartParticle> _hearts = [];
  final math.Random _rng = math.Random();

  int waterGlasses = 5;
  double sleepHours = 7.5;
  double weightKg = 58.0;
  double tempC = 36.6;

  final Set<int> _careCompleted = {};
  bool _breathingActive = false;
  int? _pressedAction;

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

    for (int i = 0; i < 28; i++) _particles.add(_StarParticle(rng: _rng));
    for (int i = 0; i < 12; i++) _hearts.add(_HeartParticle(rng: _rng));
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    _orbitController.dispose();
    _particleController.dispose();
    _breatheCtrl.dispose();
    _pulseCtrl.dispose();
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

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _hBg,
      body: Stack(
        children: [
          _DreamyBackground(size: size),
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
                        _topBar(user),
                        const SizedBox(height: 12),
                        _emotionalWeatherStrip(user),
                        const SizedBox(height: 26),
                        _orbitalTracker(user),
                        const SizedBox(height: 20),
                        _moonCompanionRow(user),
                        const SizedBox(height: 26),
                        _quickActions(context),
                        const SizedBox(height: 22),
                        _pregnancyCard(context),
                        const SizedBox(height: 26),
                        _insightCarousel(user),
                        const SizedBox(height: 26),
                        _healthSnapshot(),
                        const SizedBox(height: 26),
                        _aiCard(context, user),
                        const SizedBox(height: 26),
                        _dailyCare(),
                        const SizedBox(height: 100),
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
  //  TOP BAR
  // ─────────────────────────────────────────────────────────
  Widget _topBar(UserProvider user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                Color.lerp(const Color(0xFFAB5CF2), const Color(0xFFFF69B4),
                    _glowAnim.value)!,
                const Color(0xFFFF69B4),
                Color.lerp(const Color(0xFFAB5CF2), const Color(0xFFFF69B4),
                    _glowAnim.value)!,
              ]),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFAB5CF2)
                      .withOpacity(_glowAnim.value * 0.7),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFF1E0A3C),
              child: Icon(Icons.person_rounded,
                  color: Color(0xFFD8A8FF), size: 26),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(user),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              _pill('Cycle: 28 days', const Color(0xFFAB5CF2),
                  const Color(0xFFD8A8FF)),
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
  //  EMOTIONAL WEATHER STRIP
  // ─────────────────────────────────────────────────────────
  Widget _emotionalWeatherStrip(UserProvider user) {
    final color = _weatherColor(user);
    final label = _emotionalWeather(user);
    // BackdropFilter is OUTSIDE AnimatedBuilder to avoid per-frame blur recomputation
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
              Text('Emotional Weather: ',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.48), fontSize: 12)),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Icon(Icons.auto_awesome_rounded,
                  color: color.withOpacity(0.6), size: 14),
            ]),
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
                      .withOpacity(_glowAnim.value * 0.28),
                  blurRadius: 30,
                  spreadRadius: 3,
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
                        color: _phaseRingColor(user)
                            .withOpacity(_glowAnim.value * 0.85),
                        blurRadius: 48,
                        spreadRadius: 14,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF69B4)
                            .withOpacity(_glowAnim.value * 0.55),
                        blurRadius: 22,
                        spreadRadius: 4,
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
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
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
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _hWarm.withOpacity(0.40 + 0.15 * _glowAnim.value),
                        _hPink.withOpacity(0.22),
                        _hPurple.withOpacity(0.08),
                      ], stops: const [0.0, 0.55, 1.0]),
                      border: Border.all(
                        color: _hWarm.withOpacity(0.55 * _glowAnim.value),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _hWarm.withOpacity(0.35 * _glowAnim.value),
                          blurRadius: 20, spreadRadius: 3,
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
                Expanded(child: Column(
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
                          fontSize: 12, height: 1.45),
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
          '🌸', 'Community', () => _nav(context, const CommunityScreen())),
      _QuickAction('🌙', 'Sleep', () => _nav(context, const SleepScreen())),
      _QuickAction('🤰', 'Pregnancy', () => _nav(context, const PregnancyScreen())),
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
    final items = [
      _HealthItem('💧', 'Water', '$waterGlasses/8', 'glasses'),
      _HealthItem('😴', 'Sleep', '$sleepHours', 'hrs'),
      _HealthItem('⚖️', 'Weight', '$weightKg', 'kg'),
      _HealthItem('🌡️', 'Temp', '$tempC', '°C'),
      _HealthItem('💜', 'Energy', 'High', ''),
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
              return Padding(
                padding: const EdgeInsets.only(right: 12),
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
                    ],
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
                      const Text(
                        'Lunar AI 🌙',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _aiInsight(user),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 14,
                            height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _nav(context, const AIVoiceScreen()),
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
                                child: const Text(
                                  'Talk to Lunar ✨',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
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

  void _nav(BuildContext ctx, Widget screen) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
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
  _HealthItem(this.icon, this.label, this.value, this.unit);
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
//  CYCLE PHASE ENUM
// ═══════════════════════════════════════════════════════════
enum _CyclePhase { period, follicular, ovulation, luteal, unknown }
