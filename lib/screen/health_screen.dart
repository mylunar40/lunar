import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/lunar_data_provider.dart';
import '../core/models/insight_model.dart';

// ═══════════════════════════════════════════════════════════
//  LUNAR HEALTH — Premium Wellness Universe
// ═══════════════════════════════════════════════════════════

const Color _hBg     = Color(0xFF0A0118);
const Color _hPurple = Color(0xFFAB5CF2);
const Color _hPink   = Color(0xFFFF69B4);
const Color _hTeal   = Color(0xFF4FC3F7);
const Color _hIndigo = Color(0xFF7986CB);
const Color _hGold   = Color(0xFFFFD700);

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with TickerProviderStateMixin {
  // --- Animation controllers ---
  late AnimationController _glowCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _breatheCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _breatheAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;

  // --- Particles ---
  final List<_HStar> _stars = [];
  final math.Random _rng = math.Random();

  // --- Local UI state ---
  final Set<int> _completedTasks = {};
  double _displaySleepHours = 7.0;
  bool _sleepPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _floatCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _particleCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();

    _breatheCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3800))
      ..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
        CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    for (int i = 0; i < 20; i++) {
      _stars.add(_HStar(rng: _rng));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final d = Provider.of<LunarDataProvider>(context, listen: false);
    _displaySleepHours = d.lastSleepHours.clamp(1.0, 12.0);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _particleCtrl.dispose();
    _breatheCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // --- Wellness score (0-100) ---
  int _dailyScore(LunarDataProvider d) {
    int s = 0;
    s += ((d.todayWaterGlasses / 8.0) * 25).round().clamp(0, 25);
    s += ((d.lastSleepHours / 8.0) * 25).round().clamp(0, 25);
    s += ((_completedTasks.length / 5.0) * 25).round().clamp(0, 25);
    s += d.moodEntries.isNotEmpty
        ? ((d.moodTrend.averageScore / 5.0) * 25).round().clamp(0, 25)
        : 15;
    return s.clamp(0, 100);
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Radiant';
    if (score >= 60) return 'Balanced';
    if (score >= 40) return 'Nurturing';
    return 'Rest Mode';
  }

  Color _scoreColor(int score) {
    if (score >= 80) return _hGold;
    if (score >= 60) return _hPurple;
    if (score >= 40) return _hPink;
    return _hIndigo;
  }

  String _waterInsight(int w) {
    if (w < 3) return 'Your body is thirsty, love. Hydration balances hormones and lifts mood.';
    if (w < 6) return 'Halfway there! Water supports your cycle and clears brain fog.';
    if (w < 8) return 'Almost at your goal! Your skin, energy and mood will thank you.';
    return 'Beautifully hydrated! Your cells are glowing and your hormones are happy.';
  }

  String _sleepInsight(double h) {
    if (h < 6) return 'Rest is sacred. Short sleep disrupts cortisol and amplifies emotional waves.';
    if (h < 7) return 'Getting closer to optimal. Your body heals and restores deeply during sleep.';
    if (h < 9) return 'Beautiful sleep pattern! Deep rest supports your cycle recovery.';
    return 'You\'re honouring your rest deeply. This is where real healing happens.';
  }

  String _energyLabel(String level) {
    switch (level) {
      case 'high': return 'High';
      case 'low': return 'Low';
      default: return 'Moderate';
    }
  }

  Color _energyColor(String level) {
    switch (level) {
      case 'high': return _hGold;
      case 'low': return _hIndigo;
      default: return _hPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lunarData = Provider.of<LunarDataProvider>(context);
    final size = MediaQuery.of(context).size;
    final score = _dailyScore(lunarData);
    final scoreColor = _scoreColor(score);

    return Scaffold(
      backgroundColor: _hBg,
      body: Stack(
        children: [
          _HBackground(size: size),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _HStarPainter(stars: _stars, progress: _particleCtrl.value),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _headerRow(lunarData, score, scoreColor),
                        const SizedBox(height: 20),
                        _emotionalStatusBar(lunarData, score, scoreColor),
                        const SizedBox(height: 28),
                        _dailyRingsRow(lunarData),
                        const SizedBox(height: 28),
                        _sectionLabel('Hydration', '💧'),
                        const SizedBox(height: 16),
                        _hydrationCard(lunarData),
                        const SizedBox(height: 28),
                        _sectionLabel('Sleep Recovery', '🌙'),
                        const SizedBox(height: 16),
                        _sleepCard(lunarData),
                        const SizedBox(height: 28),
                        _sectionLabel('Wellness Pulse', '⚡'),
                        const SizedBox(height: 16),
                        _wellnessCardsRow(lunarData),
                        const SizedBox(height: 28),
                        _sectionLabel('Daily Healing Tasks', '🌿'),
                        const SizedBox(height: 16),
                        _healingTasks(),
                        const SizedBox(height: 28),
                        _sectionLabel('Breathing Moment', '🌬️'),
                        const SizedBox(height: 16),
                        _breathingCard(),
                        const SizedBox(height: 28),
                        _sectionLabel('Lunar AI Insights', '✨'),
                        const SizedBox(height: 16),
                        _aiInsightsSection(lunarData),
                        const SizedBox(height: 28),
                        _sectionLabel('Wellness Wisdom', '🌿'),
                        const SizedBox(height: 16),
                        _wellnessTipCard(
                          emoji: '💊',
                          title: 'Cycle Nutrition',
                          body: 'Drink enough water and maintain a regular sleep schedule. It helps balance mood and hormones throughout your cycle.',
                          color: _hPink,
                        ),
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

  // --- HEADER ROW ---
  Widget _headerRow(LunarDataProvider lunarData, int score, Color scoreColor) {
    return Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Wellness',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2)),
            const SizedBox(height: 4),
            Text('Nourish your body, honour your soul',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.48), fontSize: 13)),
          ],
        ),
      ),
      AnimatedBuilder(
        animation: Listenable.merge([_floatAnim, _breatheAnim, _glowAnim]),
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _floatAnim.value * 0.35),
          child: Transform.scale(
            scale: _breatheAnim.value,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  scoreColor.withOpacity(0.55 * _glowAnim.value),
                  scoreColor.withOpacity(0.08),
                ]),
                boxShadow: [
                  BoxShadow(
                    color: scoreColor.withOpacity(_glowAnim.value * 0.6),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
                ],
                border: Border.all(color: scoreColor.withOpacity(0.55), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$score',
                      style: TextStyle(
                          color: scoreColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  Text('%',
                      style: TextStyle(
                          color: scoreColor.withOpacity(0.7), fontSize: 9)),
                ],
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  // --- EMOTIONAL STATUS BAR ---
  Widget _emotionalStatusBar(LunarDataProvider lunarData, int score, Color scoreColor) {
    final energy = lunarData.energyLevel;
    final water = lunarData.todayWaterGlasses;
    String statusMsg;
    if (score >= 75) {
      statusMsg = 'Your body is glowing with vitality today';
    } else if (water < 4) {
      statusMsg = 'Your body needs gentle hydration care today';
    } else if (lunarData.lastSleepHours < 6) {
      statusMsg = 'Rest and restore — sleep is your healing power';
    } else {
      statusMsg = 'You\'re doing beautifully. Keep nurturing yourself';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: [
                scoreColor.withOpacity(0.16),
                scoreColor.withOpacity(0.05),
              ]),
              border: Border.all(
                  color: scoreColor.withOpacity(0.40 * _glowAnim.value), width: 1),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withOpacity(0.18),
                ),
                child: Center(
                  child: Text(
                    score >= 75 ? '🌟' : score >= 50 ? '🌙' : '🌿',
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wellness Energy: ${_scoreLabel(score)}',
                        style: TextStyle(
                            color: scoreColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(statusMsg,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontSize: 12,
                            height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_energyLabel(energy),
                      style: TextStyle(
                          color: _energyColor(energy),
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  Text('energy',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.38), fontSize: 10)),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // --- DAILY RINGS ROW ---
  Widget _dailyRingsRow(LunarDataProvider lunarData) {
    final waterPct = (lunarData.todayWaterGlasses / 8.0).clamp(0.0, 1.0);
    final sleepPct = (lunarData.lastSleepHours / 8.0).clamp(0.0, 1.0);
    final energyPct = lunarData.energyLevel == 'high'
        ? 1.0
        : lunarData.energyLevel == 'medium'
            ? 0.65
            : 0.35;
    return Row(children: [
      _miniRing('💧', 'Water', waterPct, _hTeal),
      const SizedBox(width: 12),
      _miniRing('🌙', 'Sleep', sleepPct, _hIndigo),
      const SizedBox(width: 12),
      _miniRing('⚡', 'Energy', energyPct, _hGold),
    ]);
  }

  Widget _miniRing(String emoji, String label, double pct, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: color.withOpacity(0.07),
                border: Border.all(
                    color: color.withOpacity(_glowAnim.value * 0.45), width: 1),
              ),
              child: Column(children: [
                RepaintBoundary(
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: CustomPaint(
                      painter: _RingPainter(
                          progress: pct, color: color, glow: _glowAnim.value),
                      child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 18))),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${(pct * 100).round()}%',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 10)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // --- HYDRATION CARD ---
  Widget _hydrationCard(LunarDataProvider lunarData) {
    final water = lunarData.todayWaterGlasses;
    final pct = (water / 8.0).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: _hTeal.withOpacity(0.06),
              border: Border.all(
                  color: _hTeal.withOpacity(_glowAnim.value * 0.55), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: _hTeal.withOpacity(_glowAnim.value * 0.18),
                    blurRadius: 28,
                    spreadRadius: 2),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_breatheAnim, _glowAnim, _pulseAnim]),
                    builder: (_, __) => Transform.scale(
                      scale: _breatheAnim.value,
                      child: RepaintBoundary(
                        child: SizedBox(
                          width: 86,
                          height: 86,
                          child: CustomPaint(
                            painter: _WaterOrbPainter(
                              fill: pct,
                              glow: _glowAnim.value,
                              pulse: _pulseAnim.value,
                              color: _hTeal,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('💧', style: TextStyle(fontSize: 22)),
                                  Text('${(pct * 100).round()}%',
                                      style: TextStyle(
                                          color: _hTeal,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('$water',
                              style: TextStyle(
                                  color: _hTeal,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 4),
                          Text('/ 8 glasses',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.50),
                                  fontSize: 13)),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                          water >= 8 ? 'Fully hydrated today!' : '${8 - water} more to glow',
                          style: TextStyle(
                              color: _hTeal.withOpacity(0.85),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: Listenable.merge([_shimmerAnim, _pulseAnim]),
                          builder: (_, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(children: [
                              Container(
                                height: 7,
                                width: double.infinity,
                                color: _hTeal.withOpacity(0.10),
                              ),
                              FractionallySizedBox(
                                widthFactor: pct,
                                child: Container(
                                  height: 7,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: LinearGradient(colors: [
                                      _hTeal.withOpacity(0.70),
                                      _hTeal,
                                      Colors.white.withOpacity(
                                          0.28 * math.sin(_shimmerAnim.value * math.pi)),
                                    ]),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _hTeal.withOpacity(0.45 * _pulseAnim.value),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(8, (i) {
                    final filled = i < water;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? _hTeal.withOpacity(0.28)
                            : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: filled
                              ? _hTeal.withOpacity(0.80)
                              : Colors.white.withOpacity(0.12),
                          width: filled ? 1.5 : 1,
                        ),
                        boxShadow: filled
                            ? [
                                BoxShadow(
                                  color: _hTeal.withOpacity(0.40 * _glowAnim.value),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          filled ? '💧' : '○',
                          style: TextStyle(
                            fontSize: filled ? 11 : 9,
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _hTeal.withOpacity(0.08),
                    border: Border.all(color: _hTeal.withOpacity(0.20), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_waterInsight(water),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: 12.5,
                                height: 1.45)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (lunarData.todayWaterGlasses < 12) {
                      lunarData.addWaterGlass();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(colors: [
                          _hTeal.withOpacity(0.45 + 0.15 * _glowAnim.value),
                          _hTeal.withOpacity(0.25),
                        ]),
                        border: Border.all(color: _hTeal.withOpacity(0.5), width: 1),
                        boxShadow: [
                          BoxShadow(
                              color: _hTeal.withOpacity(0.25 * _glowAnim.value),
                              blurRadius: 14),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.water_drop_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Drink a Glass',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700)),
                        ],
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

  // --- SLEEP CARD ---
  Widget _sleepCard(LunarDataProvider lunarData) {
    final sleepHours = lunarData.lastSleepHours;
    final pct = (sleepHours / 8.0).clamp(0.0, 1.0);
    final quality = sleepHours >= 8
        ? 'Excellent'
        : sleepHours >= 7
            ? 'Good'
            : sleepHours >= 6
                ? 'Fair'
                : 'Poor';

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: _hIndigo.withOpacity(0.07),
              border: Border.all(
                  color: _hIndigo.withOpacity(_glowAnim.value * 0.50), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: _hIndigo.withOpacity(_glowAnim.value * 0.16),
                    blurRadius: 24),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_breatheAnim, _glowAnim]),
                      builder: (_, __) => Transform.scale(
                        scale: _breatheAnim.value,
                        child: SizedBox(
                          width: 78,
                          height: 78,
                          child: CustomPaint(
                            painter: _SleepRingPainter(
                              progress: pct,
                              glow: _glowAnim.value,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🌙', style: TextStyle(fontSize: 22)),
                                  Text('${sleepHours.toStringAsFixed(1)}h',
                                      style: TextStyle(
                                          color: _hIndigo,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(sleepHours.toStringAsFixed(1),
                              style: TextStyle(
                                  color: _hIndigo,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 4),
                          Text('/ 8h',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.50),
                                  fontSize: 13)),
                        ]),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _hIndigo.withOpacity(0.16),
                            border: Border.all(
                                color: _hIndigo.withOpacity(0.45), width: 1),
                          ),
                          child: Text('$quality Sleep',
                              style: TextStyle(
                                  color: _hIndigo,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _shimmerAnim,
                    builder: (_, __) => CustomPaint(
                      size: const Size(double.infinity, 40),
                      painter: _SleepWavePainter(
                        progress: _shimmerAnim.value,
                        fillLevel: pct,
                        color: _hIndigo,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _hIndigo.withOpacity(0.08),
                    border: Border.all(color: _hIndigo.withOpacity(0.20), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_sleepInsight(sleepHours),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: 12.5,
                                height: 1.45)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_sleepPanelOpen) ...[
                  Text(
                    'Log tonight\'s sleep: ${_displaySleepHours.toStringAsFixed(1)}h',
                    style: TextStyle(
                        color: _hIndigo, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _hIndigo,
                      inactiveTrackColor: _hIndigo.withOpacity(0.18),
                      thumbColor: _hIndigo,
                      overlayColor: _hIndigo.withOpacity(0.18),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                    ),
                    child: Slider(
                      value: _displaySleepHours,
                      min: 1.0,
                      max: 12.0,
                      divisions: 22,
                      onChanged: (v) => setState(() => _displaySleepHours = v),
                      onChangeEnd: (v) {
                        lunarData.logSleep(
                          hours: v,
                          quality: v >= 8
                              ? 'excellent'
                              : v >= 7
                                  ? 'good'
                                  : v >= 6
                                      ? 'fair'
                                      : 'poor',
                        );
                        setState(() => _sleepPanelOpen = false);
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _sleepPanelOpen = !_sleepPanelOpen);
                  },
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(colors: [
                          _hIndigo.withOpacity(0.45 + 0.15 * _glowAnim.value),
                          _hIndigo.withOpacity(0.25),
                        ]),
                        border: Border.all(color: _hIndigo.withOpacity(0.5), width: 1),
                        boxShadow: [
                          BoxShadow(
                              color: _hIndigo.withOpacity(0.22 * _glowAnim.value),
                              blurRadius: 14),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _sleepPanelOpen ? 'Done' : 'Log Sleep Hours',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700),
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

  // --- WELLNESS CARDS ROW ---
  Widget _wellnessCardsRow(LunarDataProvider lunarData) {
    final energy = lunarData.energyLevel;
    final moodPct = lunarData.moodEntries.isNotEmpty
        ? (lunarData.moodTrend.averageScore / 5.0).clamp(0.0, 1.0)
        : 0.65;
    final waterPct = (lunarData.todayWaterGlasses / 8.0).clamp(0.0, 1.0);
    final sleepPct = (lunarData.lastSleepHours / 8.0).clamp(0.0, 1.0);
    final taskPct = (_completedTasks.length / 5.0).clamp(0.0, 1.0);

    final cards = [
      _WCard('⚡', 'Body Energy', _energyLabel(energy), _energyColor(energy),
          energy == 'high' ? 1.0 : energy == 'medium' ? 0.65 : 0.35),
      _WCard('💜', 'Emotional\nBalance', '${(moodPct * 100).round()}%', _hPurple, moodPct),
      _WCard('💧', 'Hydration', '${(waterPct * 100).round()}%', _hTeal, waterPct),
      _WCard('🌙', 'Sleep\nRecovery', '${(sleepPct * 100).round()}%', _hIndigo, sleepPct),
      _WCard('🌸', 'Self-Care', '${(taskPct * 100).round()}%', _hPink, taskPct),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, __) => Container(
                          width: 128,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                card.color.withOpacity(0.18),
                                card.color.withOpacity(0.06),
                              ],
                            ),
                            border: Border.all(
                                color: card.color.withOpacity(_glowAnim.value * 0.48),
                                width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: card.color.withOpacity(0.12 * _glowAnim.value),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: card.color.withOpacity(0.18),
                                  border: Border.all(
                                      color: card.color.withOpacity(0.40), width: 1),
                                ),
                                child: Center(
                                    child: Text(card.icon,
                                        style: const TextStyle(fontSize: 16))),
                              ),
                              const SizedBox(height: 10),
                              Text(card.label,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.50),
                                      fontSize: 10.5,
                                      height: 1.3)),
                              const SizedBox(height: 4),
                              Text(card.value,
                                  style: TextStyle(
                                      color: card.color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Stack(children: [
                                  Container(
                                      height: 4,
                                      color: card.color.withOpacity(0.10)),
                                  FractionallySizedBox(
                                    widthFactor: card.progress.clamp(0.0, 1.0),
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: card.color,
                                        boxShadow: [
                                          BoxShadow(
                                            color: card.color
                                                .withOpacity(0.45 * _glowAnim.value),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ]),
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
    );
  }

  // --- DAILY HEALING TASKS ---
  Widget _healingTasks() {
    const tasks = [
      ('💧', 'Drink a glass of water'),
      ('🌬️', 'Take 5 deep breaths'),
      ('🧘', '5-min meditation'),
      ('🤸', 'Stretch for 3 minutes'),
      ('📓', 'Write 3 gratitudes'),
      ('🌿', 'Walk 10 minutes outside'),
      ('🍵', 'Nourish yourself well'),
      ('🌙', 'Phone-free wind down'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: _hPurple.withOpacity(0.20), width: 1),
          ),
          child: Column(
            children: List.generate(tasks.length, (i) {
              final done = _completedTasks.contains(i);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    if (done) {
                      _completedTasks.remove(i);
                    } else {
                      _completedTasks.add(i);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: done
                        ? _hPurple.withOpacity(0.16)
                        : Colors.white.withOpacity(0.04),
                    border: Border.all(
                      color: done
                          ? _hPurple.withOpacity(0.65)
                          : Colors.white.withOpacity(0.10),
                      width: done ? 1.5 : 1,
                    ),
                    boxShadow: done
                        ? [
                            BoxShadow(
                              color: _hPurple.withOpacity(0.28),
                              blurRadius: 12,
                            )
                          ]
                        : null,
                  ),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? _hPurple.withOpacity(0.30)
                            : Colors.white.withOpacity(0.06),
                        border: Border.all(
                          color: done ? _hPurple : Colors.white.withOpacity(0.22),
                          width: 1.5,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(tasks[i].$1, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tasks[i].$2,
                        style: TextStyle(
                          color: done ? Colors.white : Colors.white.withOpacity(0.68),
                          fontSize: 13.5,
                          fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                          decoration: done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: _hPurple.withOpacity(0.55),
                        ),
                      ),
                    ),
                    if (done)
                      Text('✨',
                          style: TextStyle(
                              fontSize: 14, color: _hGold.withOpacity(0.85))),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // --- BREATHING CARD ---
  Widget _breathingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedBuilder(
          animation: Listenable.merge([_breatheAnim, _glowAnim]),
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: [
                _hPink.withOpacity(0.14),
                _hPurple.withOpacity(0.07),
              ]),
              border: Border.all(
                  color: _hPink.withOpacity(0.40 * _glowAnim.value), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: _hPink.withOpacity(0.15 * _glowAnim.value),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Row(children: [
              Transform.scale(
                scale: _breatheAnim.value,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _hPink.withOpacity(
                          0.28 + 0.22 * (_breatheAnim.value - 0.90) * 10),
                      _hPink.withOpacity(0.06),
                    ]),
                    border: Border.all(color: _hPink.withOpacity(0.55), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _hPink.withOpacity(0.35 * _glowAnim.value),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌬️', style: TextStyle(fontSize: 22)),
                      Text(
                        _breatheAnim.value > 0.97
                            ? 'Hold'
                            : _breatheAnim.value > 0.93
                                ? 'Exhale'
                                : 'Inhale',
                        style: TextStyle(
                            color: _hPink, fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('4-7-8 Breathing',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'Inhale for 4 counts, hold for 7, exhale for 8. This activates your parasympathetic nervous system.',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.62),
                          fontSize: 12.5,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // --- AI WELLNESS INSIGHTS ---
  Widget _aiInsightsSection(LunarDataProvider lunarData) {
    final providerInsights = lunarData.insights
        .where((ins) =>
            ins.category == InsightCategory.sleep ||
            ins.category == InsightCategory.hydration ||
            ins.category == InsightCategory.mood ||
            ins.category == InsightCategory.general)
        .take(2)
        .toList();

    final water = lunarData.todayWaterGlasses;
    final sleepH = lunarData.lastSleepHours;
    final List<_WellnessInsight> insights = [];

    if (water >= 6) {
      insights.add(const _WellnessInsight(
        '💧',
        'Hydration is lifting your mood',
        'You sleep better after calm evenings with good hydration. Keep it up!',
        _hTeal,
      ));
    } else {
      insights.add(const _WellnessInsight(
        '💧',
        'Hydration boosts mood',
        'Even 2 more glasses of water today can reduce fatigue by up to 30%.',
        _hTeal,
      ));
    }

    if (sleepH >= 7) {
      insights.add(const _WellnessInsight(
        '🌙',
        'Sleep is your superpower',
        'Your body repairs hormones during deep sleep. You\'re doing beautifully.',
        _hIndigo,
      ));
    } else {
      insights.add(const _WellnessInsight(
        '😴',
        'Your energy drops before your cycle',
        'Prioritizing 7-9 hours of sleep supports hormonal balance throughout your cycle.',
        _hIndigo,
      ));
    }

    if (_completedTasks.length >= 3) {
      insights.add(const _WellnessInsight(
        '✨',
        'Self-care momentum building',
        'Completing wellness tasks consistently lifts your emotional baseline over time.',
        _hPurple,
      ));
    }

    for (final ins in providerInsights) {
      insights
          .add(_WellnessInsight(ins.icon, ins.title, ins.body, _categoryColor(ins.category)));
    }

    return Column(
      children: insights
          .take(4)
          .map((ins) => Padding(
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
                            ins.color.withOpacity(0.16),
                            ins.color.withOpacity(0.05),
                          ]),
                          border: Border.all(
                              color: ins.color.withOpacity(_glowAnim.value * 0.38),
                              width: 1),
                        ),
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ins.color.withOpacity(0.18),
                              boxShadow: [
                                BoxShadow(
                                  color: ins.color
                                      .withOpacity(_glowAnim.value * 0.30),
                                  blurRadius: 10,
                                ),
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
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Color _categoryColor(InsightCategory cat) {
    switch (cat) {
      case InsightCategory.sleep:
        return _hIndigo;
      case InsightCategory.hydration:
        return _hTeal;
      case InsightCategory.mood:
        return _hPurple;
      case InsightCategory.cycle:
        return _hPink;
      default:
        return _hPurple;
    }
  }

  // --- WELLNESS TIP CARD ---
  Widget _wellnessTipCard({
    required String emoji,
    required String title,
    required String body,
    required Color color,
  }) {
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
              color: color.withOpacity(0.07),
              border:
                  Border.all(color: color.withOpacity(_glowAnim.value * 0.4), width: 1),
            ),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.15),
                      border: Border.all(color: color.withOpacity(0.35), width: 1),
                    ),
                    child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        Text(body,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.62),
                                fontSize: 12.5,
                                height: 1.5)),
                      ])),
                ]),
          ),
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _sectionLabel(String t, String emoji) => Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(t,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2)),
      ]);
}

// =============================================================
//  DATA MODELS
// =============================================================

class _WCard {
  final String icon, label, value;
  final Color color;
  final double progress;
  const _WCard(this.icon, this.label, this.value, this.color, this.progress);
}

class _WellnessInsight {
  final String icon, title, body;
  final Color color;
  const _WellnessInsight(this.icon, this.title, this.body, this.color);
}

// =============================================================
//  WATER ORB PAINTER
// =============================================================

class _WaterOrbPainter extends CustomPainter {
  final double fill, glow, pulse;
  final Color color;
  const _WaterOrbPainter(
      {required this.fill,
      required this.glow,
      required this.pulse,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;

    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.white.withOpacity(0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);

    canvas.drawCircle(
        c,
        r * (0.96 + 0.04 * pulse),
        Paint()
          ..color = color.withOpacity(0.15 * glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    if (fill > 0) {
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          -math.pi / 2,
          fill * 2 * math.pi,
          false,
          Paint()
            ..color = color.withOpacity(glow * 0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          -math.pi / 2,
          fill * 2 * math.pi,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_WaterOrbPainter old) =>
      old.fill != fill || old.glow != glow || old.pulse != pulse;
}

// =============================================================
//  SLEEP RING PAINTER
// =============================================================

class _SleepRingPainter extends CustomPainter {
  final double progress, glow;
  const _SleepRingPainter({required this.progress, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 5;
    const color = Color(0xFF7986CB);

    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);

    if (progress > 0) {
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          -math.pi / 2,
          progress * 2 * math.pi,
          false,
          Paint()
            ..color = color.withOpacity(glow * 0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          -math.pi / 2,
          progress * 2 * math.pi,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_SleepRingPainter old) =>
      old.progress != progress || old.glow != glow;
}

// =============================================================
//  SLEEP WAVE PAINTER
// =============================================================

class _SleepWavePainter extends CustomPainter {
  final double progress, fillLevel;
  final Color color;
  const _SleepWavePainter(
      {required this.progress, required this.fillLevel, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * (1 - fillLevel * 0.7) +
          math.sin(
                  (x / size.width * 2 * math.pi) + progress * 2 * math.pi) *
              8;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * (1 - fillLevel * 0.7) +
          math.sin((x / size.width * 2 * math.pi) +
                  (progress + 0.3) * 2 * math.pi) *
              5 +
          6;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_SleepWavePainter old) =>
      old.progress != progress || old.fillLevel != fillLevel;
}

// =============================================================
//  RING PAINTER (mini rings)
// =============================================================

class _RingPainter extends CustomPainter {
  final double progress, glow;
  final Color color;
  const _RingPainter(
      {required this.progress, required this.color, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    if (progress > 0) {
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          -math.pi / 2,
          progress * 2 * math.pi,
          false,
          Paint()
            ..color = color.withOpacity(glow * 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          -math.pi / 2,
          progress * 2 * math.pi,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.glow != glow || old.color != color;
}

// =============================================================
//  STAR PARTICLE SYSTEM
// =============================================================

class _HStar {
  late double x, y, speed, size, opacity, angle;
  _HStar({required math.Random rng}) {
    x = rng.nextDouble();
    y = rng.nextDouble();
    speed = 0.0001 + rng.nextDouble() * 0.0002;
    size = 0.6 + rng.nextDouble() * 1.8;
    opacity = 0.15 + rng.nextDouble() * 0.45;
    angle = rng.nextDouble() * math.pi * 2;
  }
}

class _HStarPainter extends CustomPainter {
  final List<_HStar> stars;
  final double progress;
  const _HStarPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in stars) {
      final x = (p.x + math.cos(p.angle) * p.speed * progress * 80) % 1.0;
      final y = (p.y - p.speed * progress * 200) % 1.0;
      canvas.drawCircle(
          Offset(x * size.width, y * size.height),
          p.size,
          Paint()
            ..color = Colors.white.withOpacity(p.opacity * 0.65)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2));
    }
  }

  @override
  bool shouldRepaint(_HStarPainter old) => old.progress != progress;
}

// =============================================================
//  DREAMY BACKGROUND
// =============================================================

class _HBackground extends StatelessWidget {
  final Size size;
  const _HBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.45),
          radius: 1.3,
          colors: [Color(0xFF2D0B5C), Color(0xFF18063A), _hBg],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -70, left: -50, child: _blob(300, _hTeal, 0.09)),
        Positioned(top: 80, right: -60, child: _blob(260, _hPink, 0.10)),
        Positioned(
            top: size.height * 0.35,
            left: size.width * 0.5 - 130,
            child: _blob(260, _hPurple, 0.08)),
        Positioned(bottom: 60, left: -50, child: _blob(280, _hIndigo, 0.11)),
        Positioned(bottom: 0, right: -40, child: _blob(220, _hPink, 0.09)),
      ]),
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
