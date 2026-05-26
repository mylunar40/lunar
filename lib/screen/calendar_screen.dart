import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import '../core/providers/lunar_data_provider.dart';
import '../core/models/mood_model.dart';

// ═══════════════════════════════════════════════════════════
//  CALENDAR SCREEN — Lunar AI Premium Cycle Universe
// ═══════════════════════════════════════════════════════════

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  // ─── Animation controllers ────────────────────────────────
  late AnimationController _glowController;
  late AnimationController _floatController;
  late AnimationController _particleController;
  late AnimationController _breatheCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _ringRotCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _breatheAnim;
  late Animation<double> _pulseAnim;

  // ─── Particle system ──────────────────────────────────────
  final List<_CStarParticle> _particles = [];
  final math.Random _rng = math.Random();

  // ─── Calendar state ───────────────────────────────────────
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;
  int _monthSwitchDir = 1; // for slide animation direction
  int _forecastIdx = 0;
  Timer? _forecastTimer;

  // ─── Log state ────────────────────────────────────────────
  String? _selectedMood;
  final Set<String> _selectedSymptoms = {};
  final Map<String, String> _loggedMoods = {};
  final Map<String, Set<String>> _loggedSymptoms = {};

  // ─── Design tokens ────────────────────────────────────────
  static const _kBg = Color(0xFF0A0118);
  static const _kPurple = Color(0xFFAB5CF2);
  static const _kPink = Color(0xFFFF69B4);
  static const _kGold = Color(0xFFFFD700);
  static const _kGreen = Color(0xFF66BB6A);
  static const _kIndigo = Color(0xFF7986CB);
  static const _kWarm = Color(0xFFFFB74D);

  // ─── Mood options ─────────────────────────────────────────
  static const List<_MoodOpt> _moods = [
    _MoodOpt('😊', 'Happy', Color(0xFFFFD700)),
    _MoodOpt('😌', 'Calm', Color(0xFF7986CB)),
    _MoodOpt('😢', 'Emotional', Color(0xFF4FC3F7)),
    _MoodOpt('😴', 'Tired', Color(0xFF9C27B0)),
    _MoodOpt('😰', 'Anxious', Color(0xFFFF7043)),
    _MoodOpt('⚡', 'Energetic', Color(0xFF66BB6A)),
  ];

  // ─── Symptom options ──────────────────────────────────────
  static const List<_SymptomOpt> _symptoms = [
    _SymptomOpt('🩸', 'Cramps'),
    _SymptomOpt('🤕', 'Headache'),
    _SymptomOpt('😤', 'Mood Swings'),
    _SymptomOpt('✨', 'Acne'),
    _SymptomOpt('🍫', 'Cravings'),
    _SymptomOpt('😪', 'Fatigue'),
    _SymptomOpt('💧', 'Bloating'),
    _SymptomOpt('🌡️', 'Temp'),
    _SymptomOpt('😟', 'Anxiety'),
    _SymptomOpt('😴', 'Poor Sleep'),
    _SymptomOpt('🫀', 'Back Pain'),
    _SymptomOpt('🌿', 'Nausea'),
  ];

  // ─── Phase emotional identity ─────────────────────────────
  static const Map<String, String> _phaseEmotionalLabel = {
    'Menstrual': 'Soft Recovery Phase 🌙',
    'Follicular': 'Rising Light Energy ✨',
    'Ovulation': 'High Glow Window 🌟',
    'Luteal': 'Emotional Reflection Time 💜',
    'Unknown': 'Lunar Cycle Beginning 💫',
  };

  static const Map<String, String> _phaseEnergy = {
    'Menstrual': 'Low — rest & restore',
    'Follicular': 'Building — creative & social',
    'Ovulation': 'Peak — magnetic & confident',
    'Luteal': 'Declining — introspective & tender',
    'Unknown': 'Log your cycle to unlock insights',
  };

  // ─── Phase descriptions ───────────────────────────────────
  static const Map<String, String> _phaseDescs = {
    'Menstrual':
        'Your body is releasing the uterine lining. Rest, warmth and self-care are essential now 🌸',
    'Follicular':
        'Estrogen is rising. Energy increases and creativity blooms — perfect for new beginnings ✨',
    'Ovulation':
        'Peak fertility window. You radiate natural magnetism and confidence this week 🌟',
    'Luteal':
        'Progesterone peaks. Intuition deepens — honor your emotional needs and slow down 💜',
    'Unknown':
        'Log your period start date to unlock full cycle intelligence 🌙',
  };

  static const Map<String, String> _phaseEmojis = {
    'Menstrual': '🌸',
    'Follicular': '🌱',
    'Ovulation': '🌟',
    'Luteal': '🌙',
    'Unknown': '💫',
  };

  // ─── AI Forecast messages (per phase) ────────────────────
  static const Map<String, List<String>> _kAIForecasts = {
    'Menstrual': [
      'Rest and warmth are your medicine right now 🌸',
      'Your body is doing powerful work — be gentle with yourself 🌙',
      'Light movement may ease discomfort gently ✨',
      'Iron-rich foods support your energy today 💜',
    ],
    'Follicular': [
      'Ovulation energy is rising 🌸',
      'Creative ideas will flow freely today ✨',
      'Your confidence is quietly growing — trust it 🌱',
      'Social energy builds beautifully in this phase 💫',
    ],
    'Ovulation': [
      'You are at your magnetic peak today 🌟',
      'Peak confidence energy — speak your truth 💜',
      'Natural glow is undeniable right now ✨',
      'This is your most creative window of the cycle 🌸',
    ],
    'Luteal': [
      'You may feel emotionally softer tomorrow 🌙',
      'Intuition is your greatest gift this week 💜',
      'Nourish yourself deeply — you deserve it 🌿',
      'Emotional sensitivity is a superpower, not a flaw ✨',
    ],
    'Unknown': [
      'Log your cycle to unlock personalized forecasts 🌙',
      'Your wellness journey starts with one data point 💜',
      'Lunar AI is ready to learn your unique cycle 🌸',
    ],
  };

  // ─── Rotating cycle intelligence quotes ──────────────────
  static const List<String> _kRotatingInsights = [
    'Sleep improved your mood this week ✨',
    'Stress patterns increase before PMS 🌙',
    'Hydration reduces fatigue significantly 💧',
    'Your cycle consistency is strong this month 🌸',
    'Emotional peaks align with your ovulation window 🌟',
    'Rest during menstruation improves follicular energy 💜',
    'Your energy typically dips 2 days before your period 🌙',
    'Magnesium-rich foods ease PMS symptoms measurably 🌿',
  ];

  // ─── Lifecycle ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _ringRotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    for (int i = 0; i < 28; i++) {
      _particles.add(_CStarParticle(rng: _rng));
    }
    _forecastTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) setState(() => _forecastIdx++);
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _floatController.dispose();
    _particleController.dispose();
    _breatheCtrl.dispose();
    _pulseCtrl.dispose();
    _ringRotCtrl.dispose();
    _forecastTimer?.cancel();
    super.dispose();
  }

  // ─── Cycle logic ──────────────────────────────────────────
  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns moon phase emoji for the given date.
  String _moonPhaseEmoji(DateTime date) {
    const ref = Duration(days: 0); // anchor below
    final reference = DateTime(2000, 1, 6); // known new moon
    final daysSinceRef = date.difference(reference).inDays % 30;
    final phase = (daysSinceRef < 0 ? daysSinceRef + 30 : daysSinceRef) / 29.53;
    if (phase < 0.0625 || phase >= 0.9375) return '🌑';
    if (phase < 0.1875) return '🌒';
    if (phase < 0.3125) return '🌓';
    if (phase < 0.4375) return '🌔';
    if (phase < 0.5625) return '🌕';
    if (phase < 0.6875) return '🌖';
    if (phase < 0.8125) return '🌗';
    return '🌘';
  }

  bool _isPeriodDay(DateTime day, UserProvider user) {
    if (user.lastPeriodDate == null) return false;
    final diff = day.difference(user.lastPeriodDate!).inDays;
    return diff >= 0 && diff < 5;
  }

  bool _isOvulationDay(DateTime day, UserProvider user) {
    if (user.lastPeriodDate == null) return false;
    final ov = user.lastPeriodDate!.add(const Duration(days: 14));
    return _sameDay(day, ov);
  }

  bool _isFertileDay(DateTime day, UserProvider user) {
    if (user.lastPeriodDate == null) return false;
    final ov = user.lastPeriodDate!.add(const Duration(days: 14));
    final diff = day.difference(ov).inDays;
    return diff >= -4 && diff <= 1 && !_isOvulationDay(day, user);
  }

  bool _isPmsDay(DateTime day, UserProvider user) {
    if (user.lastPeriodDate == null) return false;
    final diff = day.difference(user.lastPeriodDate!).inDays;
    return diff >= 21 && diff <= 27;
  }

  int _cycleDay(UserProvider user) {
    if (user.lastPeriodDate == null) return 0;
    return DateTime.now().difference(user.lastPeriodDate!).inDays + 1;
  }

  String _phaseLabel(UserProvider user) {
    final d = _cycleDay(user);
    if (d <= 0) return 'Unknown';
    if (d <= 5) return 'Menstrual';
    if (d <= 13) return 'Follicular';
    if (d <= 16) return 'Ovulation';
    if (d <= 28) return 'Luteal';
    return 'Unknown';
  }

  Color _phaseColor(UserProvider user) {
    switch (_phaseLabel(user)) {
      case 'Menstrual':
        return const Color(0xFFB05C8A);
      case 'Follicular':
        return const Color(0xFF9B59B6);
      case 'Ovulation':
        return _kPink;
      case 'Luteal':
        return const Color(0xFF7B68EE);
      default:
        return _kPurple;
    }
  }

  String _fertilityStr(UserProvider user) {
    final d = _cycleDay(user);
    if (d >= 10 && d <= 16) return 'High ✨';
    if (d >= 7 && d <= 9) return 'Medium';
    if (d >= 17 && d <= 18) return 'Low';
    if (d <= 0) return '—';
    return 'Very Low';
  }

  String _ovulationStr(UserProvider user) {
    if (user.lastPeriodDate == null) return '—';
    final ov = user.lastPeriodDate!.add(const Duration(days: 14));
    return '${_mName(ov.month)} ${ov.day}';
  }

  String _nextPeriodStr(UserProvider user) {
    if (user.lastPeriodDate == null) return '—';
    final next = user.lastPeriodDate!.add(const Duration(days: 28));
    return '${_mName(next.month)} ${next.day}';
  }

  String _mName(int m) {
    const n = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return n[m - 1];
  }

  void _prevMonth() => setState(() {
        _monthSwitchDir = -1;
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _monthSwitchDir = 1;
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      });

  // ─── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final lunarData = Provider.of<LunarDataProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          _CalDreamyBg(size: size),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _CParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  _header(user),
                  const SizedBox(height: 18),
                  _cycleHeroCard(user),
                  const SizedBox(height: 24),
                  _orbitalCycleRing(user),
                  const SizedBox(height: 28),
                  _monthCalendar(user, lunarData),
                  const SizedBox(height: 26),
                  _smartPredictions(user),
                  const SizedBox(height: 26),
                  _cycleIntelligence(user),
                  const SizedBox(height: 26),
                  _dynamicInsightCards(user, lunarData),
                  const SizedBox(height: 26),
                  _moodSelector(lunarData),
                  const SizedBox(height: 26),
                  _symptomLogger(lunarData),
                  const SizedBox(height: 26),
                  _statsCards(user, lunarData),
                  const SizedBox(height: 26),
                  _rotatingInsightsBanner(),
                  const SizedBox(height: 26),
                  _analyticsSection(user, lunarData),
                  const SizedBox(height: 26),
                  _aiCompanionCard(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────────
  Widget _header(UserProvider user) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cycle Calendar 🌙',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_phaseLabel(user)} Phase ✨',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _floatAnim.value * 0.5),
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _phaseColor(user).withOpacity(0.18),
                  border: Border.all(
                    color:
                        _phaseColor(user).withOpacity(0.55 * _glowAnim.value),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          _phaseColor(user).withOpacity(0.3 * _glowAnim.value),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Text(
                  _cycleDay(user) > 0 ? 'Day ${_cycleDay(user)}' : '–',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ORBITAL CYCLE RING  (28-day circular hormone map)
  // ─────────────────────────────────────────────────────────
  Widget _orbitalCycleRing(UserProvider user) {
    final cd = _cycleDay(user);
    final phase = _phaseLabel(user);
    final color = _phaseColor(user);
    final emotLabel = _phaseEmotionalLabel[phase] ?? phase;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Cycle Universe 🌌'),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer atmospheric glow
                AnimatedBuilder(
                  animation: _breatheAnim,
                  builder: (_, __) => Container(
                    width: 280 * _breatheAnim.value,
                    height: 280 * _breatheAnim.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        color.withOpacity(0),
                        color.withOpacity(0),
                        color.withOpacity(0.12 * _glowAnim.value),
                        Colors.transparent,
                      ], stops: const [
                        0,
                        0.6,
                        0.82,
                        1.0
                      ]),
                    ),
                  ),
                ),
                // Cycle ring painter
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_glowAnim, _pulseAnim]),
                    builder: (_, __) => CustomPaint(
                      size: const Size(270, 270),
                      painter: _CycleRingPainter(
                        currentDay: cd.toDouble(),
                        glow: _glowAnim.value,
                        pulse: _pulseAnim.value,
                        phaseColor: color,
                      ),
                    ),
                  ),
                ),
                // Center orb
                AnimatedBuilder(
                  animation: Listenable.merge([_glowAnim, _breatheAnim]),
                  builder: (_, __) => Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        color.withOpacity(0.45),
                        const Color(0xFF2D0B5C).withOpacity(0.85),
                        const Color(0xFF0A0118),
                      ]),
                      border: Border.all(
                        color: color.withOpacity(_glowAnim.value * 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(_glowAnim.value * 0.45),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cd > 0 ? 'Day $cd' : '✨',
                          style: TextStyle(
                            color: color,
                            fontSize: cd > 0 ? 22 : 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (cd > 0)
                          Text(
                            'of 28',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Phase label row
        Center(
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(colors: [
                  color.withOpacity(0.22),
                  color.withOpacity(0.08),
                ]),
                border: Border.all(
                    color: color.withOpacity(_glowAnim.value * 0.45), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.2 * _glowAnim.value),
                      blurRadius: 14)
                ],
              ),
              child: Text(
                emotLabel,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Phase legend row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ringLegend(const Color(0xFFB05C8A), 'Period'),
            _ringLegend(const Color(0xFF9B59B6), 'Follicular'),
            _ringLegend(_kGold, 'Ovulation'),
            _ringLegend(const Color(0xFF7B68EE), 'Luteal'),
          ],
        ),
      ],
    );
  }

  Widget _ringLegend(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.48), fontSize: 10.5)),
        ],
      );

  // ─────────────────────────────────────────────────────────
  //  MONTH CALENDAR
  // ─────────────────────────────────────────────────────────
  Widget _monthCalendar(UserProvider user, LunarDataProvider lunarData) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                color: Colors.white.withOpacity(0.11),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPurple.withOpacity(0.10 * _glowAnim.value),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              children: [
                _monthNav(),
                const SizedBox(height: 16),
                _weekdayHeaders(),
                const SizedBox(height: 8),
                _calendarGrid(user, lunarData),
                const SizedBox(height: 14),
                _legend(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _navBtn(Icons.chevron_left, _prevMonth),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(_monthSwitchDir * 0.25, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Text(
            '${_mName(_focusedMonth.month)} ${_focusedMonth.year}',
            key: ValueKey(_focusedMonth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _navBtn(Icons.chevron_right, _nextMonth),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.14), width: 1),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 22),
      ),
    );
  }

  Widget _weekdayHeaders() {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return Row(
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _calendarGrid(UserProvider user, LunarDataProvider lunarData) {
    final today = DateTime.now();
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final offset = first.weekday - 1; // Mon=0
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final rows = ((offset + daysInMonth) / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (col) {
              final idx = row * 7 + col;
              final dayNum = idx - offset + 1;

              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }

              final date =
                  DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
              final isToday = _sameDay(date, today);
              final isSel =
                  _selectedDay != null && _sameDay(date, _selectedDay!);
              final isPeriod = _isPeriodDay(date, user);
              final isOv = _isOvulationDay(date, user);
              final isFert = _isFertileDay(date, user);
              final isPms = _isPmsDay(date, user);
              final key = _dateKey(date);
              final hasMood = _loggedMoods.containsKey(key);
              final hasSym = _loggedSymptoms.containsKey(key);
              final moonEmoji = _moonPhaseEmoji(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDay = isSel ? null : date);
                    if (!isSel) _showDaySheet(date, user, lunarData);
                  },
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) {
                      Color? bgColor;
                      if (isSel) {
                        bgColor = _kPurple.withOpacity(0.72);
                      } else if (isPeriod) {
                        bgColor = const Color(0xFFB05C8A).withOpacity(0.52);
                      } else if (isOv) {
                        bgColor = _kGold.withOpacity(0.40);
                      } else if (isFert) {
                        bgColor = _kPurple.withOpacity(0.20);
                      } else if (isPms) {
                        bgColor = _kIndigo.withOpacity(0.18);
                      }

                      Border? border;
                      if (isToday) {
                        border = Border.all(
                          color:
                              Colors.white.withOpacity(0.80 * _glowAnim.value),
                          width: 2,
                        );
                      } else if (isOv) {
                        border = Border.all(
                            color: _kGold.withOpacity(0.7), width: 1.5);
                      } else if (isFert) {
                        border = Border.all(
                            color: _kPurple.withOpacity(0.45), width: 1);
                      } else if (isPms && !isSel) {
                        border = Border.all(
                            color: _kIndigo.withOpacity(0.38 * _glowAnim.value),
                            width: 1);
                      }

                      List<BoxShadow>? shadows;
                      if (isOv) {
                        shadows = [
                          BoxShadow(
                              color: _kGold.withOpacity(0.45 * _glowAnim.value),
                              blurRadius: 12)
                        ];
                      } else if (isPeriod) {
                        shadows = [
                          BoxShadow(
                              color: const Color(0xFFB05C8A)
                                  .withOpacity(0.35 * _glowAnim.value),
                              blurRadius: 10)
                        ];
                      } else if (isSel) {
                        shadows = [
                          BoxShadow(
                              color: _kPurple.withOpacity(0.55), blurRadius: 14)
                        ];
                      } else if (isToday) {
                        shadows = [
                          BoxShadow(
                              color: Colors.white
                                  .withOpacity(0.20 * _glowAnim.value),
                              blurRadius: 8)
                        ];
                      }

                      Color textColor;
                      if (isSel || isToday) {
                        textColor = Colors.white;
                      } else if (isPeriod) {
                        textColor = const Color(0xFFFFB3D1);
                      } else if (isOv) {
                        textColor = _kGold;
                      } else if (isFert) {
                        textColor = const Color(0xFFD8A8FF);
                      } else if (isPms) {
                        textColor = _kIndigo;
                      } else {
                        textColor = Colors.white.withOpacity(0.72);
                      }

                      return Container(
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bgColor,
                          border: border,
                          boxShadow: shadows,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: isSel || isToday
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            if ((hasMood || hasSym) && !isSel)
                              Positioned(
                                bottom: 5,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hasMood
                                        ? _kGold.withOpacity(0.85)
                                        : _kPink.withOpacity(0.85),
                                  ),
                                ),
                              ),
                            if (!isSel)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Text(
                                  moonEmoji,
                                  style: const TextStyle(fontSize: 7),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _legend() {
    final items = <(Color, String)>[
      (const Color(0xFFB05C8A), 'Period'),
      (_kGold, 'Ovulation'),
      (_kPurple, 'Fertile'),
      (_kIndigo, 'PMS'),
      (Colors.white, 'Today'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.$1.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.48),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ))
          .toList(),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  CYCLE INTELLIGENCE
  // ─────────────────────────────────────────────────────────
  Widget _cycleIntelligence(UserProvider user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Cycle Intelligence'),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: _intelCard(
                '🗓️',
                'Cycle Day',
                _cycleDay(user) > 0 ? '${_cycleDay(user)}' : '—',
                'of 28',
                const Color(0xFFAB5CF2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _intelCard(
                '🩸',
                'Next Period',
                _nextPeriodStr(user),
                '',
                const Color(0xFFB05C8A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _intelCard(
                '🥚',
                'Ovulation',
                _ovulationStr(user),
                '',
                _kGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _intelCard(
                '✨',
                'Fertility',
                _fertilityStr(user),
                '',
                const Color(0xFF66BB6A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _phaseCard(user),
      ],
    );
  }

  Widget _intelCard(
      String icon, String label, String value, String sub, Color accent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: accent.withOpacity(0.32), width: 1),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.10 * _glowAnim.value),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.50),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: accent,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.38),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _phaseCard(UserProvider user) {
    final phase = _phaseLabel(user);
    final color = _phaseColor(user);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.22),
                  color.withOpacity(0.07),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: color.withOpacity(0.50 * _glowAnim.value),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.18 * _glowAnim.value),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _phaseEmotionalLabel[phase] ?? phase,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Energy: ${_phaseEnergy[phase] ?? '—'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.50),
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _phaseDescs[phase] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_floatAnim, _breatheAnim, _glowAnim]),
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _floatAnim.value * 0.4),
                    child: Transform.scale(
                      scale: _breatheAnim.value,
                      child: Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            color.withOpacity(0.35),
                            color.withOpacity(0.10),
                          ]),
                          border: Border.all(
                              color: color.withOpacity(0.55), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.45 * _glowAnim.value),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _phaseEmojis[phase] ?? '💫',
                            style: const TextStyle(fontSize: 30),
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
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SMART PREDICTIONS
  // ─────────────────────────────────────────────────────────
  Widget _smartPredictions(UserProvider user) {
    final cd = _cycleDay(user);

    // Fertile window (days 10-16)
    String fertileWindow = '—';
    String pmsPrediction = '—';
    String fertileCountdown = '';
    if (user.lastPeriodDate != null) {
      final fertStart = user.lastPeriodDate!.add(const Duration(days: 10));
      final fertEnd = user.lastPeriodDate!.add(const Duration(days: 16));
      final pmsStart = user.lastPeriodDate!.add(const Duration(days: 21));
      final pmsEnd = user.lastPeriodDate!.add(const Duration(days: 28));
      fertileWindow =
          '${_mName(fertStart.month)} ${fertStart.day}–${fertEnd.day}';
      pmsPrediction = '${_mName(pmsStart.month)} ${pmsStart.day}–${pmsEnd.day}';
      if (cd > 0 && cd < 10) {
        fertileCountdown = 'In ${10 - cd} days';
      } else if (cd >= 10 && cd <= 16) {
        fertileCountdown = 'Active now ✨';
      }
    }

    final predictions = [
      _PredCard(
          '🩸',
          'Next Period',
          _nextPeriodStr(user),
          cd > 0 ? '${28 - cd} days away' : 'Log cycle to predict',
          const Color(0xFFB05C8A)),
      _PredCard(
          '🥚',
          'Ovulation Day',
          _ovulationStr(user),
          cd > 0 && cd <= 14
              ? 'In ${14 - cd} days'
              : cd >= 14 && cd <= 16
                  ? 'Active now 🌟'
                  : 'Next cycle',
          _kGold),
      _PredCard(
          '✨',
          'Fertile Window',
          fertileWindow,
          fertileCountdown.isNotEmpty ? fertileCountdown : 'Track cycle',
          _kGreen),
      _PredCard(
          '💜',
          'PMS Window',
          pmsPrediction,
          cd >= 21
              ? 'In phase now — be gentle'
              : cd > 0
                  ? 'In ${21 - cd} days'
                  : 'Log cycle',
          _kIndigo),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Smart Predictions 🔮'),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: predictions
                .map((p) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: AnimatedBuilder(
                            animation: _glowAnim,
                            builder: (_, __) => Container(
                              width: 158,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    p.color.withOpacity(0.20),
                                    p.color.withOpacity(0.06)
                                  ],
                                ),
                                border: Border.all(
                                    color: p.color
                                        .withOpacity(_glowAnim.value * 0.45),
                                    width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: p.color
                                        .withOpacity(0.15 * _glowAnim.value),
                                    blurRadius: 18,
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: p.color.withOpacity(0.2),
                                        border: Border.all(
                                            color: p.color.withOpacity(0.35),
                                            width: 1),
                                      ),
                                      child: Center(
                                          child: Text(p.icon,
                                              style: const TextStyle(
                                                  fontSize: 16))),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(p.label,
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.55),
                                                fontSize: 11))),
                                  ]),
                                  const SizedBox(height: 10),
                                  Text(p.value,
                                      style: TextStyle(
                                          color: p.color,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(p.sub,
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.48),
                                          fontSize: 10.5,
                                          height: 1.3)),
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
  //  DYNAMIC AI INSIGHTS  (data-reactive cards)
  // ─────────────────────────────────────────────────────────
  Widget _dynamicInsightCards(UserProvider user, LunarDataProvider lunarData) {
    final phase = _phaseLabel(user);
    final hasLogged =
        _loggedMoods.isNotEmpty || lunarData.moodEntries.isNotEmpty;
    final hasCramps = _loggedSymptoms.values.any((s) => s.contains('Cramps'));
    final hasTired = _loggedMoods.values.contains('😴') ||
        lunarData.moodEntries.any((e) => e.emoji == '😴');
    final hasAnxious = _loggedMoods.values.contains('😰') ||
        lunarData.moodEntries.any((e) => e.emoji == '😰');

    final List<_AIInsight> insights = [];

    // Phase-specific dynamic insights
    if (phase == 'Menstrual') {
      insights.add(_AIInsight(
          '🌡️',
          'Warmth helps cramps',
          'Heat therapy on your lower abdomen can reduce cramp intensity by up to 47%.',
          const Color(0xFFB05C8A)));
      insights.add(_AIInsight(
          '💧',
          'Hydration is key today',
          'Your iron levels are lower during your period. Hydration supports circulation.',
          const Color(0xFF4FC3F7)));
    } else if (phase == 'Ovulation') {
      insights.add(_AIInsight(
          '🌟',
          'Peak energy window',
          'Your natural magnetism is highest right now. Perfect for important meetings or social events.',
          _kGold));
    } else if (phase == 'Luteal') {
      insights.add(_AIInsight(
          '💜',
          'Emotional sensitivity elevated',
          'Progesterone peaks now. Emotional responses may feel stronger — this is completely normal.',
          _kIndigo));
    } else if (phase == 'Follicular') {
      insights.add(_AIInsight(
          '✨',
          'Creativity is rising',
          'Estrogen builds new neural connections. Ideal for creative work and learning something new.',
          _kPurple));
    }

    // Data-reactive insights
    if (hasCramps) {
      insights.add(_AIInsight(
          '🩸',
          'Cramps logged today',
          'Try magnesium-rich foods like dark chocolate or leafy greens to ease cramp intensity.',
          _kPink));
    }
    if (hasTired) {
      insights.add(_AIInsight(
          '😴',
          'Fatigue pattern detected',
          'Low energy is common in the ${phase.toLowerCase()} phase. Prioritize 7–9 hours tonight.',
          const Color(0xFF7986CB)));
    }
    if (hasAnxious) {
      insights.add(_AIInsight(
          '😟',
          'Anxiety noted',
          'Slow breathing exercises for 5 minutes can reduce anxiety hormones measurably.',
          _kWarm));
    }
    if (!hasLogged) {
      insights.add(_AIInsight(
          '🌙',
          'Start tracking today',
          'Logging your mood and symptoms helps Lunar AI personalize your cycle intelligence.',
          _kPurple));
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Lunar AI Insights ✨'),
        const SizedBox(height: 13),
        ...insights.map((ins) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(colors: [
                          ins.color.withOpacity(0.18),
                          ins.color.withOpacity(0.06),
                        ]),
                        border: Border.all(
                            color:
                                ins.color.withOpacity(_glowAnim.value * 0.38),
                            width: 1),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ins.color.withOpacity(0.2),
                            boxShadow: [
                              BoxShadow(
                                color: ins.color
                                    .withOpacity(_glowAnim.value * 0.35),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: Center(
                              child: Text(ins.icon,
                                  style: const TextStyle(fontSize: 18))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ins.title,
                                style: TextStyle(
                                    color: ins.color,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(ins.body,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.68),
                                    fontSize: 12,
                                    height: 1.4)),
                          ],
                        )),
                      ]),
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  MoodLevel _emojiToLevel(String emoji) {
    switch (emoji) {
      case '😊':
        return MoodLevel.great;
      case '⚡':
        return MoodLevel.great;
      case '😌':
        return MoodLevel.good;
      case '😴':
        return MoodLevel.low;
      case '😢':
        return MoodLevel.low;
      case '😰':
        return MoodLevel.veryLow;
      default:
        return MoodLevel.neutral;
    }
  }

  // ─────────────────────────────────────────────────────────
  //  MOOD SELECTOR
  // ─────────────────────────────────────────────────────────
  Widget _moodSelector(LunarDataProvider lunarData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('How are you feeling? 💜'),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withOpacity(0.05),
                border:
                    Border.all(color: Colors.white.withOpacity(0.10), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _moods.map((mood) {
                  final isSel = _selectedMood == mood.emoji;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = isSel ? null : mood.emoji;
                        if (!isSel) {
                          final k = _dateKey(_selectedDay ?? DateTime.now());
                          _loggedMoods[k] = mood.emoji;
                          final targetDate = _selectedDay ?? DateTime.now();
                          lunarData.logMood(MoodEntry(
                            id: '${targetDate.toIso8601String()}_mood',
                            date: targetDate,
                            level: _emojiToLevel(mood.emoji),
                            emoji: mood.emoji,
                            label: mood.label,
                          ));
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSel
                            ? mood.color.withOpacity(0.32)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSel
                              ? mood.color
                              : Colors.white.withOpacity(0.10),
                          width: isSel ? 2 : 1,
                        ),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                    color: mood.color.withOpacity(0.45),
                                    blurRadius: 14)
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mood.emoji,
                            style: TextStyle(fontSize: isSel ? 28 : 24),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            mood.label,
                            style: TextStyle(
                              color: isSel
                                  ? mood.color
                                  : Colors.white.withOpacity(0.42),
                              fontSize: 9,
                              fontWeight:
                                  isSel ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SYMPTOM LOGGER
  // ─────────────────────────────────────────────────────────
  Widget _symptomLogger(LunarDataProvider lunarData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Log Symptoms'),
        const SizedBox(height: 13),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _symptoms.map((s) {
            final isSel = _selectedSymptoms.contains(s.label);
            return GestureDetector(
              onTap: () => setState(() {
                isSel
                    ? _selectedSymptoms.remove(s.label)
                    : _selectedSymptoms.add(s.label);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isSel
                      ? _kPink.withOpacity(0.22)
                      : Colors.white.withOpacity(0.06),
                  border: Border.all(
                    color: isSel
                        ? _kPink.withOpacity(0.72)
                        : Colors.white.withOpacity(0.14),
                    width: isSel ? 1.5 : 1,
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                              color: _kPink.withOpacity(0.25), blurRadius: 10)
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      s.label,
                      style: TextStyle(
                        color: isSel ? _kPink : Colors.white.withOpacity(0.68),
                        fontSize: 12.5,
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedSymptoms.isNotEmpty) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              final k = _dateKey(_selectedDay ?? DateTime.now());
              setState(() {
                _loggedSymptoms[k] = Set.from(_selectedSymptoms);
                _selectedSymptoms.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  behavior: SnackBarBehavior.floating,
                  content: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [
                        Color(0xFF5C2DB8),
                        Color(0xFFAB5CF2),
                      ]),
                      boxShadow: [
                        BoxShadow(
                            color: _kPurple.withOpacity(0.5), blurRadius: 14)
                      ],
                    ),
                    child: const Text(
                      'Symptoms logged successfully ✨',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            },
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      _kPurple.withOpacity(0.8 + 0.2 * _glowAnim.value),
                      _kPink.withOpacity(0.8 + 0.2 * _glowAnim.value),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(color: _kPurple.withOpacity(0.40), blurRadius: 18)
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Log Symptoms ✨',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  STATS CARDS
  // ─────────────────────────────────────────────────────────
  Widget _statsCards(UserProvider user, LunarDataProvider lunarData) {
    final sleepHours = lunarData.lastSleepHours;
    final water = lunarData.todayWaterGlasses;
    final energy = lunarData.energyLevel;
    final energyDisplay = energy[0].toUpperCase() + energy.substring(1);
    final recentMood = lunarData.moodEntries.isNotEmpty
        ? lunarData.moodEntries.first.emoji
        : '—';
    final stats = [
      _CStatItem('🗓️', 'Cycle', '28 days', _kPurple),
      _CStatItem('😊', 'Mood', recentMood, _kGold),
      _CStatItem('😴', 'Sleep', '${sleepHours.toStringAsFixed(1)}h',
          const Color(0xFF7986CB)),
      _CStatItem('💧', 'Water', '$water/8', const Color(0xFF4FC3F7)),
      _CStatItem('⚡', 'Energy', energyDisplay, _phaseColor(user)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Your Stats'),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: stats
                .map((s) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: AnimatedBuilder(
                            animation: _glowAnim,
                            builder: (_, __) => Container(
                              width: 92,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withOpacity(0.06),
                                border: Border.all(
                                    color: s.color.withOpacity(0.32), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: s.color
                                        .withOpacity(0.10 * _glowAnim.value),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.icon,
                                      style: const TextStyle(fontSize: 20)),
                                  const SizedBox(height: 8),
                                  Text(
                                    s.value,
                                    style: TextStyle(
                                      color: s.color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    s.label,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.48),
                                      fontSize: 10.5,
                                    ),
                                  ),
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
  //  ANALYTICS SECTION
  // ─────────────────────────────────────────────────────────
  Widget _analyticsSection(UserProvider user, LunarDataProvider lunarData) {
    final cd = _cycleDay(user);
    final phase = _phaseLabel(user);
    final color = _phaseColor(user);

    final cycleProgress = cd > 0 ? (cd / 28.0).clamp(0.0, 1.0) : 0.0;
    final moodScore = lunarData.moodEntries.isNotEmpty
        ? (lunarData.moodTrend.averageScore / 5.0).clamp(0.0, 1.0)
        : 0.65;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Cycle Analytics 📊'),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withOpacity(0.04),
                  border:
                      Border.all(color: _kPurple.withOpacity(0.20), width: 1),
                ),
                child: Column(
                  children: [
                    // Cycle progress bar
                    _analyticsBar(
                      'Cycle Progress',
                      '${(cycleProgress * 100).toStringAsFixed(0)}%',
                      cycleProgress,
                      color,
                      _glowAnim.value,
                    ),
                    const SizedBox(height: 14),
                    _analyticsBar(
                      'Mood Balance',
                      '${(moodScore * 100).toStringAsFixed(0)}%',
                      moodScore,
                      _kGold,
                      _glowAnim.value,
                    ),
                    const SizedBox(height: 14),
                    _analyticsBar(
                      'Phase Awareness',
                      cd > 0 ? 'Active' : 'Not tracking',
                      cd > 0 ? 0.82 : 0.0,
                      _kGreen,
                      _glowAnim.value,
                    ),
                    const SizedBox(height: 18),
                    // Phase arc row
                    Row(
                      children: [
                        _phaseArcChip('🌸', 'Period', const Color(0xFFB05C8A),
                            phase == 'Menstrual'),
                        const SizedBox(width: 8),
                        _phaseArcChip('🌱', 'Rising', const Color(0xFF9B59B6),
                            phase == 'Follicular'),
                        const SizedBox(width: 8),
                        _phaseArcChip(
                            '🌟', 'Peak', _kGold, phase == 'Ovulation'),
                        const SizedBox(width: 8),
                        _phaseArcChip('🌙', 'Luteal', const Color(0xFF7B68EE),
                            phase == 'Luteal'),
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

  Widget _analyticsBar(
      String label, String valueStr, double value, Color accent, double glow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.60), fontSize: 12)),
          Text(valueStr,
              style: TextStyle(
                  color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Stack(children: [
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: accent.withOpacity(0.12),
            ),
          ),
          FractionallySizedBox(
            widthFactor: value,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient:
                    LinearGradient(colors: [accent.withOpacity(0.8), accent]),
                boxShadow: [
                  BoxShadow(
                      color: accent.withOpacity(0.4 * glow), blurRadius: 8)
                ],
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _phaseArcChip(String emoji, String label, Color color, bool active) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active ? color.withOpacity(0.22) : color.withOpacity(0.06),
          border: Border.all(
            color: active ? color.withOpacity(0.65) : color.withOpacity(0.18),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: active ? 18 : 15)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  color: active ? color : Colors.white.withOpacity(0.38),
                  fontSize: 9.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  AI COMPANION CARD
  // ─────────────────────────────────────────────────────────
  Widget _aiCompanionCard(BuildContext ctx) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF5C2DB8).withOpacity(0.65),
                  const Color(0xFFAB5CF2).withOpacity(0.42),
                  const Color(0xFFE91E8C).withOpacity(0.28),
                ],
              ),
              border: Border.all(
                color: _kPurple.withOpacity(_glowAnim.value * 0.62),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPurple.withOpacity(0.24 * _glowAnim.value),
                  blurRadius: 32,
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
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        "Would you like emotional support today?\nI'm here to listen 💜",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => HapticFeedback.lightImpact(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 11),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(colors: [
                              Color(0xFFAB5CF2),
                              Color(0xFFFF69B4),
                            ]),
                            boxShadow: [
                              BoxShadow(
                                color: _kPurple.withOpacity(0.45),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Talk to Lunar ✨',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _floatAnim.value * 0.5),
                    child: const Text(
                      '🤖',
                      style: TextStyle(fontSize: 55),
                    ),
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
  //  CYCLE HERO CARD  (premium emotional forecast)
  // ─────────────────────────────────────────────────────────
  Widget _cycleHeroCard(UserProvider user) {
    final phase = _phaseLabel(user);
    final color = _phaseColor(user);
    final cd = _cycleDay(user);
    final forecasts = _kAIForecasts[phase] ?? _kAIForecasts['Unknown']!;
    final forecast = forecasts[_forecastIdx % forecasts.length];

    String nextEventChip = '';
    if (user.lastPeriodDate != null && cd > 0) {
      if (cd < 10) {
        nextEventChip = '${10 - cd}d to Fertile Window';
      } else if (cd >= 10 && cd <= 13) {
        nextEventChip = '${14 - cd}d to Ovulation';
      } else if (cd >= 14 && cd <= 16) {
        nextEventChip = 'Ovulation Active 🌟';
      } else if (cd >= 17 && cd <= 20) {
        nextEventChip = '${21 - cd}d to PMS Window';
      } else if (cd >= 21 && cd <= 27) {
        nextEventChip = 'PMS Window — be gentle 💜';
      } else {
        nextEventChip = '${28 - cd}d to Next Period';
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowAnim, _breatheAnim]),
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.30),
                  const Color(0xFF2D0B5C).withOpacity(0.65),
                  _kPink.withOpacity(0.10),
                ],
              ),
              border: Border.all(
                color: color.withOpacity(_glowAnim.value * 0.58),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(_glowAnim.value * 0.24),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lunar Phase Orb with rotating shimmer ring
                Column(
                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge(
                          [_floatAnim, _breatheAnim, _glowAnim, _ringRotCtrl]),
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, _floatAnim.value * 0.35),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer atmosphere pulse
                            Container(
                              width: 90 * _breatheAnim.value,
                              height: 90 * _breatheAnim.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    color.withOpacity(0),
                                    color.withOpacity(0.14 * _glowAnim.value),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.5, 0.82, 1.0],
                                ),
                              ),
                            ),
                            // Rotating dashed orbit ring
                            Transform.rotate(
                              angle: _ringRotCtrl.value * 2 * math.pi,
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  size: const Size(86, 86),
                                  painter: _ShimmerRingPainter(
                                    color: color,
                                    glow: _glowAnim.value,
                                  ),
                                ),
                              ),
                            ),
                            // Phase orb
                            Transform.scale(
                              scale: _breatheAnim.value,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [
                                    color.withOpacity(0.55),
                                    const Color(0xFF2D0B5C).withOpacity(0.85),
                                  ]),
                                  border: Border.all(
                                    color: color
                                        .withOpacity(_glowAnim.value * 0.65),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color
                                          .withOpacity(_glowAnim.value * 0.52),
                                      blurRadius: 22,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _phaseEmojis[phase] ?? '💫',
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      cd > 0 ? 'Day $cd' : '—',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                // Right: phase + rotating AI forecast + next event chip
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _phaseEmotionalLabel[phase] ?? phase,
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _phaseEnergy[phase] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Rotating AI emotional forecast
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 750),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: CurvedAnimation(
                              parent: anim, curve: Curves.easeOut),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: anim, curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                        ),
                        child: Container(
                          key: ValueKey(_forecastIdx),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: color.withOpacity(0.12),
                            border: Border.all(
                              color: color.withOpacity(0.30),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            forecast,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      if (nextEventChip.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: color.withOpacity(0.16),
                            border: Border.all(
                              color: color.withOpacity(0.40),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '⏱ $nextEventChip',
                            style: TextStyle(
                              color: color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
  //  ROTATING INSIGHTS BANNER  (cycle intelligence feed)
  // ─────────────────────────────────────────────────────────
  Widget _rotatingInsightsBanner() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: [
                const Color(0xFF5C2DB8).withOpacity(0.38),
                const Color(0xFFAB5CF2).withOpacity(0.18),
              ]),
              border: Border.all(
                color: _kPurple.withOpacity(_glowAnim.value * 0.45),
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
                    gradient: RadialGradient(colors: [
                      _kPurple.withOpacity(0.70 + 0.30 * _glowAnim.value),
                      _kPurple.withOpacity(0.30),
                    ]),
                    boxShadow: [
                      BoxShadow(
                        color: _kPurple.withOpacity(_glowAnim.value * 0.50),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Center(
                      child: Text('🔮', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(
                          'Cycle Intelligence',
                          style: TextStyle(
                            color: _kPurple.withOpacity(0.85),
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
                            color: _kGreen,
                            boxShadow: [
                              BoxShadow(
                                  color: _kGreen.withOpacity(0.7),
                                  blurRadius: 4)
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 750),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: CurvedAnimation(
                              parent: anim, curve: Curves.easeOut),
                          child: child,
                        ),
                        child: Text(
                          _kRotatingInsights[
                              _forecastIdx % _kRotatingInsights.length],
                          key: ValueKey('ins_$_forecastIdx'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.80),
                            fontSize: 12.5,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
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

  // ─── Helper ───────────────────────────────────────────────
  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      );

  // ─────────────────────────────────────────────────────────
  //  DAILY DETAIL SHEET
  // ─────────────────────────────────────────────────────────
  void _showDaySheet(
      DateTime date, UserProvider user, LunarDataProvider lunarData) {
    final key = _dateKey(date);
    final mood = _loggedMoods[key];
    final symptoms = _loggedSymptoms[key]?.toList() ?? [];
    final isPeriod = _isPeriodDay(date, user);
    final isOv = _isOvulationDay(date, user);
    final isFert = _isFertileDay(date, user);
    final isPms = _isPmsDay(date, user);
    final phase = isPeriod
        ? 'Menstrual'
        : isOv
            ? 'Ovulation'
            : isFert
                ? 'Follicular'
                : isPms
                    ? 'Luteal'
                    : 'Follicular';
    final phaseColor = _phaseColor(user);
    final isToday = _sameDay(date, DateTime.now());

    // Cycle-day intelligence tip
    final Map<String, String> tips = {
      'Menstrual': 'Rest, warmth, and gentle movement support you now 🌸',
      'Follicular': 'Your energy is rising — perfect for new beginnings ✨',
      'Ovulation': 'Peak magnetism and creativity — embrace it fully 🌟',
      'Luteal': 'Nourish yourself deeply; emotions are your compass 💜',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2D0B5C).withOpacity(0.92),
                  const Color(0xFF0A0118).withOpacity(0.97),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: phaseColor.withOpacity(0.45),
                  width: 1.5,
                ),
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag pill
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white.withOpacity(0.22),
                      ),
                    ),
                  ),
                  // Date header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            phaseColor.withOpacity(0.42),
                            phaseColor.withOpacity(0.12),
                          ]),
                          border: Border.all(
                              color: phaseColor.withOpacity(0.65), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: phaseColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_mName(date.month)} ${date.day}, ${date.year}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: phaseColor.withOpacity(0.18),
                                  border: Border.all(
                                      color: phaseColor.withOpacity(0.50),
                                      width: 1),
                                ),
                                child: Text(
                                  '${_phaseEmojis[phase] ?? '💫'} $phase',
                                  style: TextStyle(
                                    color: phaseColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                  child: const Text(
                                    'Today',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Phase tip
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: [
                        phaseColor.withOpacity(0.16),
                        phaseColor.withOpacity(0.06),
                      ]),
                      border: Border.all(
                          color: phaseColor.withOpacity(0.30), width: 1),
                    ),
                    child: Text(
                      tips[phase] ?? 'Tune in to how you feel today 💜',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Mood logged
                  Row(children: [
                    _sheetChip(
                      mood != null ? '$mood Mood' : 'No mood logged',
                      mood != null ? _kGold : Colors.white.withOpacity(0.25),
                    ),
                    const SizedBox(width: 10),
                    if (isToday) ...[
                      _sheetChip(
                        '⚡ ${lunarData.energyLevel[0].toUpperCase()}${lunarData.energyLevel.substring(1)} energy',
                        _kGreen,
                      ),
                    ],
                  ]),
                  if (symptoms.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Logged Symptoms',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          symptoms.map((s) => _sheetChip(s, _kPink)).toList(),
                    ),
                  ],
                  if (isToday) ...[
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(
                          child: _sheetInfoTile(
                              '😴',
                              'Sleep',
                              '${lunarData.lastSleepHours.toStringAsFixed(1)}h',
                              const Color(0xFF7986CB))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _sheetInfoTile(
                              '💧',
                              'Water',
                              '${lunarData.todayWaterGlasses}/8',
                              const Color(0xFF4FC3F7))),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  // AI Cycle Insight for this day
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(colors: [
                            const Color(0xFF5C2DB8).withOpacity(0.32),
                            phaseColor.withOpacity(0.12),
                          ]),
                          border: Border.all(
                              color: _kPurple.withOpacity(0.38), width: 1),
                        ),
                        child: Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                _kPurple.withOpacity(0.7),
                                _kPurple.withOpacity(0.25),
                              ]),
                            ),
                            child: const Center(
                                child:
                                    Text('🔮', style: TextStyle(fontSize: 16))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lunar AI Insight',
                                  style: TextStyle(
                                    color: _kPurple.withOpacity(0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (_kAIForecasts[phase] ??
                                          _kAIForecasts['Unknown']!)
                                      .first,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Close
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.14), width: 1),
                      ),
                      child: const Center(
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _sheetChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.14),
          border: Border.all(color: color.withOpacity(0.50), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color == Colors.white.withOpacity(0.25)
                ? Colors.white.withOpacity(0.50)
                : color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _sheetInfoTile(String icon, String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.10),
          border: Border.all(color: color.withOpacity(0.30), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.48),
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════

class _MoodOpt {
  final String emoji, label;
  final Color color;
  const _MoodOpt(this.emoji, this.label, this.color);
}

class _SymptomOpt {
  final String icon, label;
  const _SymptomOpt(this.icon, this.label);
}

class _CStatItem {
  final String icon, label, value;
  final Color color;
  _CStatItem(this.icon, this.label, this.value, this.color);
}

// ═══════════════════════════════════════════════════════════
//  DREAMY BACKGROUND  (calendar-scoped)
// ═══════════════════════════════════════════════════════════

class _CalDreamyBg extends StatelessWidget {
  final Size size;
  const _CalDreamyBg({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.40),
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
              top: size.height * 0.40,
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
          // Extra nebula depth
          Positioned(
              top: size.height * 0.20,
              right: -30,
              child: _blob(180, const Color(0xFF4FC3F7), 0.07)),
          Positioned(
              top: size.height * 0.62,
              left: -20,
              child: _blob(200, const Color(0xFFFFD700), 0.06)),
          Positioned(
              top: size.height * 0.78,
              right: -40,
              child: _blob(160, const Color(0xFFAB5CF2), 0.09)),
        ],
      ),
    );
  }

  Widget _blob(double s, Color c, double o) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              RadialGradient(colors: [c.withOpacity(o), Colors.transparent]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════
//  PARTICLE SYSTEM  (calendar-scoped)
// ═══════════════════════════════════════════════════════════

class _CStarParticle {
  late double x, y, speed, size, opacity, angle;

  _CStarParticle({required math.Random rng}) {
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

class _CParticlePainter extends CustomPainter {
  final List<_CStarParticle> particles;
  final double progress;

  _CParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
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
        canvas.drawLine(Offset(cx - 5, cy), Offset(cx + 5, cy), sp);
        canvas.drawLine(Offset(cx, cy - 5), Offset(cx, cy + 5), sp);
        if (p.size > 2.8) {
          final diag = Paint()
            ..color = const Color(0xFFFF69B4).withOpacity(p.opacity * 0.25)
            ..strokeWidth = 0.5;
          canvas.drawLine(Offset(cx - 3, cy - 3), Offset(cx + 3, cy + 3), diag);
          canvas.drawLine(Offset(cx + 3, cy - 3), Offset(cx - 3, cy + 3), diag);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CParticlePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════
//  CYCLE RING PAINTER  (28-day orbital hormone map)
// ═══════════════════════════════════════════════════════════

class _CycleRingPainter extends CustomPainter {
  final double currentDay;
  final double glow;
  final double pulse;
  final Color phaseColor;

  _CycleRingPainter({
    required this.currentDay,
    required this.glow,
    required this.pulse,
    required this.phaseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 18;
    const total = 28.0;

    // Background ring
    _arc(canvas, c, r, 0, math.pi * 2,
        const Color(0xFF2D0B5C).withOpacity(0.55), 12);

    // Phase arcs
    _arc(canvas, c, r, -math.pi / 2, 2 * math.pi * 5 / total,
        const Color(0xFFB05C8A), 8); // Menstrual
    _arc(canvas, c, r, -math.pi / 2 + 2 * math.pi * 5 / total,
        2 * math.pi * 8 / total, const Color(0xFF9B59B6), 7); // Follicular
    _arc(canvas, c, r, -math.pi / 2 + 2 * math.pi * 13 / total,
        2 * math.pi * 3 / total, const Color(0xFFFFD700), 10); // Ovulation
    _arc(canvas, c, r, -math.pi / 2 + 2 * math.pi * 16 / total,
        2 * math.pi * 12 / total, const Color(0xFF7B68EE), 7); // Luteal

    // Fertile window glow aura (days 10–16)
    _arc(
        canvas,
        c,
        r - 1,
        -math.pi / 2 + 2 * math.pi * 10 / total,
        2 * math.pi * 6 / total,
        const Color(0xFFFFD700).withOpacity(0.22 + 0.12 * glow),
        16,
        blur: 10);

    // PMS window subtle ring (days 21–27)
    _arc(
        canvas,
        c,
        r + 1,
        -math.pi / 2 + 2 * math.pi * 21 / total,
        2 * math.pi * 6 / total,
        const Color(0xFF7986CB).withOpacity(0.18 + 0.10 * glow),
        14,
        blur: 8);

    // Tick marks for each day
    for (int i = 0; i < 28; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / total;
      final innerR = r - 7;
      final outerR = r + 7;
      final inner = Offset(
          c.dx + innerR * math.cos(angle), c.dy + innerR * math.sin(angle));
      final outer = Offset(
          c.dx + outerR * math.cos(angle), c.dy + outerR * math.sin(angle));
      canvas.drawLine(
          inner,
          outer,
          Paint()
            ..color = Colors.white.withOpacity(0.08)
            ..strokeWidth = 0.5);
    }

    // Current day dot
    if (currentDay > 0 && currentDay <= 28) {
      final angle = -math.pi / 2 + 2 * math.pi * (currentDay - 1) / total;
      final dx = c.dx + r * math.cos(angle);
      final dy = c.dy + r * math.sin(angle);
      final pos = Offset(dx, dy);

      // Outer glow pulse
      canvas.drawCircle(
          pos,
          14 * pulse,
          Paint()
            ..color = phaseColor.withOpacity(0.18 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      // Glow ring
      canvas.drawCircle(pos, 9 * (0.9 + 0.1 * glow),
          Paint()..color = phaseColor.withOpacity(0.55));
      // White core
      canvas.drawCircle(pos, 4.5, Paint()..color = Colors.white);
    }
  }

  void _arc(Canvas canvas, Offset c, double r, double start, double sweep,
      Color color, double w,
      {double blur = 0}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), start, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_CycleRingPainter old) =>
      old.currentDay != currentDay ||
      old.glow != glow ||
      old.pulse != pulse ||
      old.phaseColor != phaseColor;
}

// ═══════════════════════════════════════════════════════════
//  EXTRA DATA MODELS
// ═══════════════════════════════════════════════════════════

class _PredCard {
  final String icon, label, value, sub;
  final Color color;
  _PredCard(this.icon, this.label, this.value, this.sub, this.color);
}

class _AIInsight {
  final String icon, title, body;
  final Color color;
  _AIInsight(this.icon, this.title, this.body, this.color);
}

// ═══════════════════════════════════════════════════════════
//  SHIMMER RING PAINTER  (rotating orbit around hero orb)
// ═══════════════════════════════════════════════════════════

class _ShimmerRingPainter extends CustomPainter {
  final Color color;
  final double glow;
  const _ShimmerRingPainter({required this.color, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 5;
    const segments = 24;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < segments; i++) {
      if (i % 2 != 0) continue;
      paint.color = color.withOpacity(0.30 + 0.20 * glow);
      final start = 2 * math.pi * i / segments;
      final sweep = 2 * math.pi / segments * 0.65;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r), start, sweep, false, paint);
    }
    // Bright spark at top of ring
    canvas.drawCircle(
      Offset(c.dx, c.dy - r),
      2.8,
      Paint()
        ..color = color.withOpacity(0.90 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_ShimmerRingPainter old) =>
      old.glow != glow || old.color != color;
}
