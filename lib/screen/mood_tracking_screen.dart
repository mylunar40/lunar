import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';

// ═══════════════════════════════════════════════════════════
//  MOOD TRACKING — Lunar AI Emotional Universe
// ═══════════════════════════════════════════════════════════

class MoodTrackingScreen extends StatefulWidget {
  const MoodTrackingScreen({super.key});

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingState();
}

class _MoodTrackingState extends State<MoodTrackingScreen>
    with TickerProviderStateMixin {
  // ─── Animation controllers ────────────────────────────────
  late AnimationController _glowCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _orbitCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;

  // ─── Particle system ──────────────────────────────────────
  final List<_MStarParticle> _particles = [];
  final math.Random _rng = math.Random();

  // ─── UI state ─────────────────────────────────────────────
  String? _activeMood;
  String? _tappingMood;
  final Set<String> _triggers = {};
  bool? _wantsSupport;
  final TextEditingController _noteCtrl = TextEditingController();
  List<String> _moodHistory = [];
  int _affirmIdx = 0;

  // ─── Design tokens ────────────────────────────────────────
  static const _kBg = Color(0xFF0A0118);
  static const _kPurple = Color(0xFFAB5CF2);
  static const _kPink = Color(0xFFFF69B4);

  // ─── Mood catalogue ───────────────────────────────────────
  static const List<_MEntry> _moodList = [
    _MEntry('happy',     '😊', 'Happy',     Color(0xFFFFD700)),
    _MEntry('calm',      '😌', 'Calm',      Color(0xFF7986CB)),
    _MEntry('emotional', '🥺', 'Emotional', Color(0xFF81D4FA)),
    _MEntry('sad',       '😢', 'Sad',       Color(0xFF64B5F6)),
    _MEntry('anxious',   '😰', 'Anxious',   Color(0xFFFF7043)),
    _MEntry('tired',     '😴', 'Tired',     Color(0xFF9575CD)),
    _MEntry('energetic', '⚡', 'Energetic', Color(0xFF66BB6A)),
    _MEntry('angry',     '😤', 'Angry',     Color(0xFFEF5350)),
  ];

  static const List<String> _kTriggerOpts = [
    'Work', 'Sleep', 'Cycle', 'Love', 'Health', 'Weather', 'Family',
    'Self-Care',
  ];

  static const Map<String, double> _kMoodScore = {
    'happy': 5.0, 'energetic': 4.8, 'calm': 4.2, 'emotional': 3.0,
    'tired': 2.5, 'anxious': 2.0, 'sad': 1.5, 'angry': 1.0,
  };

  static const List<String> _kAffirmations = [
    'You are worthy of love and peace 💜',
    'Your feelings are valid and beautiful 🌸',
    'Every emotion is a messenger, not an enemy ✨',
    'You are stronger than you know 🌙',
    "Healing is not linear — and that's okay 💫",
    'You radiate light even on your darkest days 🌟',
    'Your sensitivity is your superpower 💜',
    'Be gentle with yourself today 🌸',
  ];

  // ─── Lifecycle ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _affirmIdx = DateTime.now().day % _kAffirmations.length;

    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _floatCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _orbitCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 8),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 5),
    )..repeat();

    for (int i = 0; i < 24; i++) {
      _particles.add(_MStarParticle(rng: _rng));
    }

    _loadHistory();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    _particleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ─── Data ─────────────────────────────────────────────────
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _moodHistory = prefs.getStringList('mood_history') ?? [];
      });
    }
  }

  Future<void> _saveMoodEntry() async {
    if (_activeMood == null) return;
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('mood_history') ?? [];
    history.add(_activeMood!);
    if (history.length > 30) {
      history.removeRange(0, history.length - 30);
    }
    await prefs.setStringList('mood_history', history);
    if (mounted) setState(() => _moodHistory = history);
  }

  // ─── Helpers ──────────────────────────────────────────────
  Color _moodColor(String? key) {
    if (key == null) return _kPurple;
    try {
      return _moodList.firstWhere((m) => m.key == key).color;
    } catch (_) {
      return _kPurple;
    }
  }

  _MEntry? _moodEntry(String? key) {
    if (key == null) return null;
    try {
      return _moodList.firstWhere((m) => m.key == key);
    } catch (_) {
      return null;
    }
  }

  String _moodMessage() {
    switch (_activeMood) {
      case 'happy':     return 'Your happiness is a gift to the world 🌟\nLet it shine freely today.';
      case 'calm':      return 'This inner peace is precious 🌿\nYou are exactly where you need to be.';
      case 'emotional': return 'Feeling deeply is a rare kind of strength 💜\nGive yourself permission to feel.';
      case 'sad':       return 'Sadness is the heart\'s way of healing 🌸\nBe gentle. You are held.';
      case 'anxious':   return 'Your nervous system is working hard 🌬️\nBreathe — this moment will pass.';
      case 'tired':     return 'Rest is not laziness — it\'s wisdom 🌙\nYour body deserves this grace.';
      case 'energetic': return 'You are electric today ⚡\nHarness this beautiful energy!';
      case 'angry':     return 'Anger is a signal, not a flaw 🔥\nHonor it — then release it.';
      default:          return 'Every emotion carries wisdom 💫';
    }
  }

  List<String> _getInsights(UserProvider user) {
    final h = DateTime.now().hour;
    final List<String> base;

    switch (_activeMood) {
      case 'happy':
        base = ['Happiness boosts immune function 🌟', 'Share your joy — it multiplies ✨', 'Your energy radiates outward today 💫'];
        break;
      case 'calm':
        base = ['Calm is your superpower today 🌿', 'Serenity supports deep cellular healing ✨', 'Ideal time for journaling and reflection 💜'];
        break;
      case 'sad':
        base = ['Tears release emotional toxins 🌸', 'Sadness is love with nowhere to go — honor it 💜', 'Gentle movement may lift your spirit 🌙'];
        break;
      case 'anxious':
        base = ['Breathe deep — anxiety peaks for ~90 seconds 🌬️', 'Grounding helps: name 5 things you can see 🌿', 'Stress may peak before your period 🌙'];
        break;
      case 'tired':
        base = ['Your body is asking for rest — listen 😴', 'Low energy often peaks in the luteal phase 🌙', 'Magnesium-rich foods may help tonight 💜'];
        break;
      case 'energetic':
        base = ['Peak energy often aligns with ovulation ✨', 'Channel this power — start something new 🌟', 'Exercise now for mood-boosting endorphins ⚡'];
        break;
      case 'emotional':
        base = ['Emotional depth is a gift, not a weakness 💜', 'Estrogen shifts affect emotional sensitivity 🌸', 'Your feelings deserve space and grace ✨'];
        break;
      case 'angry':
        base = ['Anger signals a violated boundary — notice it 🔥', 'Physical movement transforms anger energy 💪', 'Pre-period hormone shifts may amplify this 🌙'];
        break;
      default:
        base = ['Track your mood daily to discover patterns 🌙', 'Emotions and cycle are deeply connected ✨', 'Awareness is the first step to emotional mastery 💜'];
    }

    final result = List<String>.from(base);
    if (h >= 21) result[2] = 'Rest is medicine — honor your tiredness tonight 🌙';
    return result;
  }

  List<FlSpot> _chartSpots() {
    final filled = List<String>.filled(7, 'calm');
    final start = math.max(0, _moodHistory.length - 7);
    final recent = _moodHistory.sublist(start);
    for (int i = 0; i < recent.length; i++) {
      filled[7 - recent.length + i] = recent[i];
    }
    return List.generate(
      7,
      (i) => FlSpot(i.toDouble(), _kMoodScore[filled[i]] ?? 3.0),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          _MDreamyBg(size: size),
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _MParticlePainter(
                particles: _particles,
                progress: _particleCtrl.value,
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
                  const SizedBox(height: 26),
                  _moodPicker(),
                  if (_activeMood != null) ...[
                    const SizedBox(height: 26),
                    _energyOrb(),
                  ],
                  const SizedBox(height: 26),
                  _checkIn(),
                  const SizedBox(height: 26),
                  _emotionalNotes(),
                  const SizedBox(height: 26),
                  _aiInsights(user),
                  const SizedBox(height: 26),
                  _healingSection(),
                  const SizedBox(height: 26),
                  _analyticsChart(),
                  const SizedBox(height: 26),
                  _emotionalPatterns(),
                  const SizedBox(height: 40),
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
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emotional Universe 🌙',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'How is your soul today?',
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
            offset: Offset(0, _floatAnim.value * 0.45),
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _kPurple.withOpacity(0.16),
                  border: Border.all(
                    color: _kPurple.withOpacity(0.45 * _glowAnim.value),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kPurple.withOpacity(0.2 * _glowAnim.value),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Text(
                  '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
  //  MOOD PICKER
  // ─────────────────────────────────────────────────────────
  Widget _moodPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Choose Your Mood'),
        const SizedBox(height: 5),
        Text(
          'Tap how you feel right now',
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.88,
          ),
          itemCount: _moodList.length,
          itemBuilder: (_, i) {
            final m = _moodList[i];
            final isActive = _activeMood == m.key;
            final isTapping = _tappingMood == m.key;

            return GestureDetector(
              onTapDown: (_) =>
                  setState(() => _tappingMood = m.key),
              onTapUp: (_) {
                setState(() {
                  _tappingMood = null;
                  _activeMood = isActive ? null : m.key;
                });
                if (!isActive) _saveMoodEntry();
              },
              onTapCancel: () =>
                  setState(() => _tappingMood = null),
              child: AnimatedScale(
                scale: isTapping ? 0.88 : (isActive ? 1.06 : 1.0),
                duration: const Duration(milliseconds: 150),
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isActive
                          ? m.color.withOpacity(0.22)
                          : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: isActive
                            ? m.color.withOpacity(
                                0.80 * _glowAnim.value)
                            : Colors.white.withOpacity(0.12),
                        width: isActive ? 1.5 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: m.color.withOpacity(
                                    0.45 * _glowAnim.value),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          m.emoji,
                          style: TextStyle(
                              fontSize: isActive ? 32 : 26),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.label,
                          style: TextStyle(
                            color: isActive
                                ? m.color
                                : Colors.white.withOpacity(0.65),
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  EMOTIONAL ENERGY ORB
  // ─────────────────────────────────────────────────────────
  Widget _energyOrb() {
    final mc = _moodColor(_activeMood);
    final entry = _moodEntry(_activeMood);
    final score = _kMoodScore[_activeMood] ?? 3.0;
    final pct = score / 5.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Emotional Energy'),
        const SizedBox(height: 13),
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(
                    color: mc.withOpacity(0.38 * _glowAnim.value),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: mc.withOpacity(0.14 * _glowAnim.value),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Orb
                    Center(
                      child: SizedBox(
                        width: 190,
                        height: 190,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: Listenable.merge(
                                  [_pulseCtrl, _orbitCtrl]),
                              builder: (_, __) => CustomPaint(
                                size: const Size(190, 190),
                                painter: _EnergyOrbPainter(
                                  moodColor: mc,
                                  pulse: _pulseAnim.value,
                                  rotation: _orbitCtrl.value *
                                      2 *
                                      math.pi,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  entry?.emoji ?? '🌙',
                                  style: const TextStyle(
                                      fontSize: 46),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  entry?.label ?? '',
                                  style: TextStyle(
                                    color: mc,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Mood message
                    Text(
                      _moodMessage(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 14,
                        height: 1.55,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Energy bar
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Emotional Energy Level',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.52),
                            fontSize: 11.5,
                          ),
                        ),
                        Text(
                          '${(pct * 100).round()}%',
                          style: TextStyle(
                            color: mc,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => LinearProgressIndicator(
                          value: pct *
                              (0.95 + 0.05 * _pulseAnim.value),
                          minHeight: 8,
                          backgroundColor:
                              Colors.white.withOpacity(0.10),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              mc.withOpacity(0.85)),
                        ),
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

  // ─────────────────────────────────────────────────────────
  //  DAILY CHECK-IN
  // ─────────────────────────────────────────────────────────
  Widget _checkIn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Daily Check-In'),
        const SizedBox(height: 13),
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question 1 — triggers
              Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'What affected your mood today?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kTriggerOpts.map((t) {
                  final isSel = _triggers.contains(t);
                  return GestureDetector(
                    onTap: () => setState(() {
                      isSel
                          ? _triggers.remove(t)
                          : _triggers.add(t);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isSel
                            ? _kPurple.withOpacity(0.26)
                            : Colors.white.withOpacity(0.07),
                        border: Border.all(
                          color: isSel
                              ? _kPurple.withOpacity(0.75)
                              : Colors.white.withOpacity(0.13),
                          width: isSel ? 1.5 : 1,
                        ),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color:
                                      _kPurple.withOpacity(0.28),
                                  blurRadius: 10,
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: isSel
                              ? _kPurple
                              : Colors.white.withOpacity(0.62),
                          fontSize: 12.5,
                          fontWeight: isSel
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              // Question 2 — support
              Row(
                children: [
                  const Text('💜', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Do you need emotional support today?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _supportBtn('Yes, I do 💜', true),
                  const SizedBox(width: 12),
                  _supportBtn("I'm okay ✨", false),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _supportBtn(String label, bool value) {
    final isSel = _wantsSupport == value;
    final col =
        value ? _kPink : const Color(0xFF66BB6A);
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            setState(() => _wantsSupport = isSel ? null : value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSel
                ? col.withOpacity(0.22)
                : Colors.white.withOpacity(0.06),
            border: Border.all(
              color: isSel
                  ? col.withOpacity(0.70)
                  : Colors.white.withOpacity(0.13),
              width: isSel ? 1.5 : 1,
            ),
            boxShadow: isSel
                ? [
                    BoxShadow(
                        color: col.withOpacity(0.30),
                        blurRadius: 12)
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSel
                    ? col
                    : Colors.white.withOpacity(0.62),
                fontSize: 12.5,
                fontWeight:
                    isSel ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  EMOTIONAL NOTES
  // ─────────────────────────────────────────────────────────
  Widget _emotionalNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Emotional Notes'),
        const SizedBox(height: 5),
        Text(
          'A private space just for you',
          style: TextStyle(
              color: Colors.white.withOpacity(0.42), fontSize: 12.5),
        ),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withOpacity(0.05),
                border: Border.all(
                    color: Colors.white.withOpacity(0.10), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('✍️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'Write your heart out',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 4,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 14,
                      height: 1.6,
                    ),
                    cursorColor: _kPurple,
                    decoration: InputDecoration(
                      hintText:
                          'Today I feel... my heart is saying... I noticed that...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.27),
                        fontSize: 13,
                        height: 1.5,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      if (_noteCtrl.text.trim().isNotEmpty) {
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            content: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF5C2DB8),
                                      Color(0xFFAB5CF2),
                                    ]),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          _kPurple.withOpacity(0.5),
                                      blurRadius: 14)
                                ],
                              ),
                              child: const Text(
                                'Note saved to your emotional diary 💜',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        );
                        _noteCtrl.clear();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              _kPurple.withOpacity(
                                  0.80 + 0.20 * _glowAnim.value),
                              _kPink.withOpacity(
                                  0.80 + 0.20 * _glowAnim.value),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: _kPurple.withOpacity(0.38),
                                blurRadius: 16)
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Save to Diary ✨',
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
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  AI EMOTIONAL INSIGHTS
  // ─────────────────────────────────────────────────────────
  Widget _aiInsights(UserProvider user) {
    final insights = _getInsights(user);
    final gradients = [
      [const Color(0xFF5C2DB8), const Color(0xFFAB5CF2)],
      [const Color(0xFF8B2DB8), const Color(0xFFFF69B4)],
      [const Color(0xFF2D5CB8), const Color(0xFF7986CB)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('AI Emotional Insights ✨'),
        const SizedBox(height: 13),
        ...insights.asMap().entries.map((entry) {
          final g = gradients[entry.key % gradients.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      g[0].withOpacity(0.42),
                      g[1].withOpacity(0.24),
                    ],
                  ),
                  border: Border.all(
                    color:
                        g[1].withOpacity(0.28 * _glowAnim.value),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: g[1].withOpacity(0.9), size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.84),
                          fontSize: 13,
                          height: 1.38,
                        ),
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
  //  EMOTIONAL HEALING
  // ─────────────────────────────────────────────────────────
  Widget _healingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Emotional Healing 🌸'),
        const SizedBox(height: 13),
        _breathingCard(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _affirmCard()),
            const SizedBox(width: 12),
            Expanded(child: _supportCard2()),
          ],
        ),
        const SizedBox(height: 12),
        _calmSoundsCard(),
      ],
    );
  }

  Widget _breathingCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _pulseCtrl]),
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4FC3F7).withOpacity(0.18),
                  const Color(0xFF7986CB).withOpacity(0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF4FC3F7)
                    .withOpacity(0.38 * _glowAnim.value),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4FC3F7)
                        .withOpacity(0.15 + 0.10 * _pulseAnim.value),
                    border: Border.all(
                      color: const Color(0xFF4FC3F7)
                          .withOpacity(0.55 * _pulseAnim.value),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4FC3F7)
                            .withOpacity(0.30 * _pulseAnim.value),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Center(
                      child: Text('🌬️',
                          style: TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Box Breathing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '4 counts in → hold → 4 out\nReduces anxiety in under 90 seconds ✨',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.60),
                          fontSize: 12,
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

  Widget _affirmCard() {
    return AnimatedBuilder(
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
                colors: [
                  _kPink.withOpacity(0.16),
                  _kPurple.withOpacity(0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: _kPink.withOpacity(0.35 * _glowAnim.value),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💜', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                const Text(
                  'Daily Affirmation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _kAffirmations[_affirmIdx],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 11.5,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _supportCard2() {
    return AnimatedBuilder(
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
                colors: [
                  _kPurple.withOpacity(0.20),
                  const Color(0xFF5C2DB8).withOpacity(0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: _kPurple.withOpacity(0.38 * _glowAnim.value),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🤗', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                const Text(
                  'AI Support',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your companion is ready to listen whenever you need 💜',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _calmSoundsCard() {
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
                  const Color(0xFF7B68EE).withOpacity(0.18),
                  _kPurple.withOpacity(0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF7B68EE)
                    .withOpacity(0.38 * _glowAnim.value),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Text('🎵', style: TextStyle(fontSize: 34)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calm Sounds',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rain  •  Ocean  •  Binaural Beats  •  Forest\nRestore emotional balance through sound 🌊',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.58),
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7B68EE).withOpacity(0.22),
                    border: Border.all(
                      color: const Color(0xFF7B68EE).withOpacity(0.55),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B68EE).withOpacity(
                            0.30 * _glowAnim.value),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ANALYTICS CHART
  // ─────────────────────────────────────────────────────────
  Widget _analyticsChart() {
    final spots = _moodHistory.length >= 3
        ? _chartSpots()
        : const [
            FlSpot(0, 3.5), FlSpot(1, 4.2), FlSpot(2, 2.8),
            FlSpot(3, 4.5), FlSpot(4, 3.8), FlSpot(5, 4.1),
            FlSpot(6, 4.3),
          ];

    const dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Weekly Mood Trend'),
        const SizedBox(height: 13),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOut,
          builder: (_, animVal, __) => AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.fromLTRB(16, 20, 16, 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF5C2DB8).withOpacity(0.55),
                        const Color(0xFFAB5CF2).withOpacity(0.35),
                        const Color(0xFF4A00E0).withOpacity(0.22),
                      ],
                    ),
                    border: Border.all(
                      color: _kPurple
                          .withOpacity(0.38 * _glowAnim.value),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kPurple
                            .withOpacity(0.18 * _glowAnim.value),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'This Week',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(10),
                              color: Colors.white.withOpacity(0.12),
                            ),
                            child: Text(
                              _moodHistory.isEmpty
                                  ? 'Sample'
                                  : 'Live',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 138,
                        child: LineChart(
                          LineChartData(
                            gridData:
                                const FlGridData(show: false),
                            titlesData:
                                const FlTitlesData(show: false),
                            borderData:
                                FlBorderData(show: false),
                            minX: 0,
                            maxX: 6,
                            minY: 0,
                            maxY: 6,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots
                                    .map((s) => FlSpot(
                                        s.x, s.y * animVal))
                                    .toList(),
                                isCurved: true,
                                color: Colors.white,
                                barWidth: 3,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, _,
                                          __, ___) =>
                                      FlDotCirclePainter(
                                    radius: 4.5,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: _kPurple,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(
                                          0.22),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: dayLabels
                            .map((d) => Text(
                                  d,
                                  style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.42),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ))
                            .toList(),
                      ),
                      if (_moodHistory.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _moodChartLegend(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _moodChartLegend() {
    final recent = _moodHistory.reversed
        .take(4)
        .toSet()
        .map((k) {
          try {
            return _moodList.firstWhere((m) => m.key == k);
          } catch (_) {
            return _moodList[0];
          }
        })
        .take(4)
        .toList();
    return Wrap(
      spacing: 12,
      children: recent
          .map((m) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: m.color.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    m.label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.52),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ))
          .toList(),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  EMOTIONAL PATTERNS
  // ─────────────────────────────────────────────────────────
  Widget _emotionalPatterns() {
    final patterns = [
      (
        '🌙',
        'Sleep Impact',
        'Better sleep → 72% more positive moods',
        const Color(0xFF7986CB),
      ),
      (
        '🩸',
        'Cycle Link',
        'Emotional dips align with pre-period phase',
        const Color(0xFFB05C8A),
      ),
      (
        '⚡',
        'Energy Peak',
        'You feel strongest during mid-cycle ovulation',
        const Color(0xFF66BB6A),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Emotional Patterns'),
        const SizedBox(height: 13),
        ...patterns.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: p.$4.withOpacity(0.10),
                    border: Border.all(
                      color: p.$4
                          .withOpacity(0.32 * _glowAnim.value),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(p.$1,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.$2,
                              style: TextStyle(
                                color: p.$4,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              p.$3,
                              style: TextStyle(
                                color: Colors.white
                                    .withOpacity(0.60),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(
                color: Colors.white.withOpacity(0.10), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      );
}

// ═══════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════

class _MEntry {
  final String key, emoji, label;
  final Color color;
  const _MEntry(this.key, this.emoji, this.label, this.color);
}

// ═══════════════════════════════════════════════════════════
//  DREAMY BACKGROUND  (mood-scoped)
// ═══════════════════════════════════════════════════════════

class _MDreamyBg extends StatelessWidget {
  final Size size;
  const _MDreamyBg({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.38),
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
              top: -70,
              left: -55,
              child: _blob(310, const Color(0xFF9B59B6), 0.30)),
          Positioned(
              top: 90,
              right: -70,
              child: _blob(255, const Color(0xFFE91E8C), 0.18)),
          Positioned(
              top: size.height * 0.38,
              left: size.width * 0.5 - 135,
              child: _blob(275, const Color(0xFF7B2FF7), 0.15)),
          Positioned(
              bottom: 70,
              left: -65,
              child: _blob(295, const Color(0xFF6C3FC8), 0.22)),
          Positioned(
              bottom: 0,
              right: -45,
              child: _blob(245, const Color(0xFFFF69B4), 0.14)),
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
              colors: [c.withOpacity(o), Colors.transparent]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════
//  PARTICLE SYSTEM  (mood-scoped)
// ═══════════════════════════════════════════════════════════

class _MStarParticle {
  late double x, y, speed, size, opacity, angle;

  _MStarParticle({required math.Random rng}) {
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

class _MParticlePainter extends CustomPainter {
  final List<_MStarParticle> particles;
  final double progress;

  _MParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x =
          (p.x + math.cos(p.angle) * p.speed * progress * 120) % 1.0;
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
      }
    }
  }

  @override
  bool shouldRepaint(_MParticlePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════
//  ENERGY ORB PAINTER
// ═══════════════════════════════════════════════════════════

class _EnergyOrbPainter extends CustomPainter {
  final Color moodColor;
  final double pulse; // 0.6 → 1.0
  final double rotation;

  _EnergyOrbPainter({
    required this.moodColor,
    required this.pulse,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.42;

    // ── Outer atmosphere rings (fades outward) ──────────────
    for (int i = 3; i >= 1; i--) {
      final r = maxR * (0.82 + 0.14 * i) * (1.0 + 0.04 * pulse);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = moodColor.withOpacity(0.05 * i * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }

    // ── Core orb radial gradient ─────────────────────────────
    final orbR = maxR * 0.60 * (1.0 + 0.04 * pulse);
    canvas.drawCircle(
      c,
      orbR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            moodColor.withOpacity(0.78),
            moodColor.withOpacity(0.38),
            moodColor.withOpacity(0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.40, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: orbR)),
    );

    // ── Bright inner core ────────────────────────────────────
    canvas.drawCircle(
      c,
      orbR * 0.26,
      Paint()
        ..color = moodColor.withOpacity(0.55 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── Orbit ring ───────────────────────────────────────────
    final ringR = maxR * 0.82;
    canvas.drawCircle(
      c,
      ringR,
      Paint()
        ..color = moodColor.withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ── 3 Orbit dots ─────────────────────────────────────────
    for (int i = 0; i < 3; i++) {
      final angle = rotation + i * math.pi * 2 / 3;
      final dx = c.dx + ringR * math.cos(angle);
      final dy = c.dy + ringR * math.sin(angle);
      final dotR = 3.5 + 2.0 * pulse;

      canvas.drawCircle(
        Offset(dx, dy),
        dotR,
        Paint()
          ..color = Colors.white.withOpacity(0.88)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotR),
      );
      canvas.drawCircle(
          Offset(dx, dy), dotR * 0.45, Paint()..color = Colors.white);
    }

    // ── Sparkle stars around orb ────────────────────────────
    final sparkPaint = Paint()
      ..color = Colors.white.withOpacity(0.42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (int i = 0; i < 6; i++) {
      final a = rotation * 0.55 + i * math.pi / 3;
      final sr = maxR * 0.96;
      canvas.drawCircle(
        Offset(c.dx + sr * math.cos(a), c.dy + sr * math.sin(a)),
        1.6,
        sparkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_EnergyOrbPainter old) =>
      old.pulse != pulse ||
      old.rotation != rotation ||
      old.moodColor != moodColor;
}
