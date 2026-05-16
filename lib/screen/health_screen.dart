import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════
//  LUNAR HEALTH — Daily Wellness Universe
// ═══════════════════════════════════════════════════════════

const Color _hBg = Color(0xFF0A0118);
const Color _hPurple = Color(0xFFAB5CF2);
const Color _hPink = Color(0xFFFF69B4);
const Color _hGold = Color(0xFFFFD700);
const Color _hTeal = Color(0xFF4FC3F7);
const Color _hGreen = Color(0xFF66BB6A);
const Color _hIndigo = Color(0xFF7986CB);

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl, _floatCtrl, _particleCtrl;
  late Animation<double> _glowAnim, _floatAnim;
  final List<_HStar> _stars = [];
  final math.Random _rng = math.Random();

  int water = 0;
  int sleep = 7;
  int steps = 4200;

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
    for (int i = 0; i < 24; i++) _stars.add(_HStar(rng: _rng));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  void addWater() {
    HapticFeedback.lightImpact();
    setState(() {
      if (water < 12) water++;
    });
  }

  void addSteps() {
    HapticFeedback.lightImpact();
    setState(() {
      steps += 500;
    });
  }

  void addSleep() {
    HapticFeedback.lightImpact();
    setState(() {
      if (sleep < 12) sleep++;
    });
  }

  String _waterInsight() {
    if (water < 3)
      return 'Your body is thirsty, love. Hydration balances hormones and lifts mood. 💧';
    if (water < 6)
      return 'Halfway there! Water supports your cycle and clears brain fog. 🌊';
    if (water < 8)
      return 'Almost at your goal! Your skin, energy and mood will thank you. ✨';
    return 'Beautifully hydrated! Your cells are glowing and your hormones are happy. 🌸';
  }

  String _sleepInsight() {
    if (sleep < 6)
      return 'Rest is sacred. Short sleep disrupts cortisol and amplifies emotional waves. 🌙';
    if (sleep < 7)
      return 'Getting closer to optimal. Your body heals and restores deeply during sleep. 💫';
    if (sleep < 9)
      return 'Beautiful sleep pattern! Deep rest supports your cycle recovery. ✨';
    return 'You\'re honouring your rest deeply. This is where real healing happens. 💜';
  }

  String _stepsInsight() {
    if (steps < 2000)
      return 'Even a short walk outside can shift your mood and reduce tension. 🌿';
    if (steps < 5000)
      return 'Gentle movement is perfect for today. Your body appreciates the care. 🌸';
    if (steps < 8000)
      return 'You\'re moving beautifully! Activity boosts serotonin naturally. ⚡';
    return 'Amazing movement today! Your endorphins are dancing. Keep glowing. 🌟';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _hBg,
      body: Stack(
        children: [
          _HBackground(size: size),
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter:
                  _HStarPainter(stars: _stars, progress: _particleCtrl.value),
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
                        _headerRow(),
                        const SizedBox(height: 28),
                        _dailyRingsRow(),
                        const SizedBox(height: 28),
                        _sectionLabel('Daily Trackers', '📊'),
                        const SizedBox(height: 16),
                        _trackerCard(
                          emoji: '💧',
                          title: 'Water Intake',
                          value: water,
                          max: 8,
                          unit: 'glasses',
                          color: _hTeal,
                          insight: _waterInsight(),
                          onAdd: addWater,
                          addLabel: 'Drink a glass',
                        ),
                        const SizedBox(height: 14),
                        _trackerCard(
                          emoji: '😴',
                          title: 'Sleep',
                          value: sleep,
                          max: 8,
                          unit: 'hours',
                          color: _hIndigo,
                          insight: _sleepInsight(),
                          onAdd: addSleep,
                          addLabel: 'Add an hour',
                        ),
                        const SizedBox(height: 14),
                        _trackerCard(
                          emoji: '👟',
                          title: 'Daily Steps',
                          value: steps,
                          max: 10000,
                          unit: 'steps',
                          color: _hGreen,
                          insight: _stepsInsight(),
                          onAdd: addSteps,
                          addLabel: 'Log 500 steps',
                        ),
                        const SizedBox(height: 28),
                        _sectionLabel('Wellness Wisdom', '🌿'),
                        const SizedBox(height: 16),
                        _wellnessTipCard(
                          emoji: '💊',
                          title: 'Cycle Nutrition',
                          body:
                              'Drink enough water and maintain a regular sleep schedule. It helps balance mood and hormones throughout your cycle.',
                          color: _hPink,
                        ),
                        const SizedBox(height: 12),
                        _aiInsightCard(),
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

  Widget _headerRow() => Row(children: [
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
          animation: _floatAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _floatAnim.value * 0.4),
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _hPurple.withOpacity(_glowAnim.value * 0.7),
                    _hPurple.withOpacity(0.05),
                  ]),
                  boxShadow: [
                    BoxShadow(
                        color: _hPurple.withOpacity(_glowAnim.value * 0.55),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                ),
                child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 22))),
              ),
            ),
          ),
        ),
      ]);

  Widget _dailyRingsRow() => Row(children: [
        _miniRing('💧', 'Water', water, 8, _hTeal),
        const SizedBox(width: 12),
        _miniRing('😴', 'Sleep', sleep, 8, _hIndigo),
        const SizedBox(width: 12),
        _miniRing('👟', 'Steps', steps, 10000, _hGreen),
      ]);

  Widget _miniRing(
      String emoji, String label, num value, num max, Color color) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Expanded(
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: color.withOpacity(0.07),
                border: Border.all(
                    color: color.withOpacity(_glowAnim.value * 0.45), width: 1),
              ),
              child: Column(children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CustomPaint(
                    painter: _RingPainter(
                        progress: pct, color: color, glow: _glowAnim.value),
                    child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 18))),
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

  Widget _trackerCard({
    required String emoji,
    required String title,
    required num value,
    required num max,
    required String unit,
    required Color color,
    required String insight,
    required VoidCallback onAdd,
    required String addLabel,
  }) {
    final pct = (value / max).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: color.withOpacity(0.07),
              border: Border.all(
                  color: color.withOpacity(_glowAnim.value * 0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(_glowAnim.value * 0.18),
                    blurRadius: 24,
                    spreadRadius: 2)
              ],
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.15),
                    border: Border.all(color: color.withOpacity(0.4), width: 1),
                  ),
                  child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('$value / $max $unit',
                      style: TextStyle(
                          color: color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ]),
                const Spacer(),
                _miniPill('${(pct * 100).round()}%', color),
              ]),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 7,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: color.withOpacity(0.08),
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✨', style: TextStyle(fontSize: 13, color: color)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(insight,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 12.5,
                                  height: 1.45))),
                    ]),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(colors: [
                      color.withOpacity(0.45),
                      color.withOpacity(0.25),
                    ]),
                    border: Border.all(color: color.withOpacity(0.5), width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 1)
                    ],
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(addLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

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
              border: Border.all(
                  color: color.withOpacity(_glowAnim.value * 0.4), width: 1),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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

  Widget _aiInsightCard() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _hPurple.withOpacity(0.22),
                  _hPink.withOpacity(0.12),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              border: Border.all(
                  color: _hPurple.withOpacity(_glowAnim.value * 0.55),
                  width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: _hPurple.withOpacity(_glowAnim.value * 0.2),
                    blurRadius: 28,
                    spreadRadius: 2)
              ],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _hPurple.withOpacity(0.5),
                    _hPurple.withOpacity(0.1),
                  ]),
                  border:
                      Border.all(color: _hPurple.withOpacity(0.5), width: 1),
                ),
                child: const Center(
                    child: Text('🌙', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Lunar AI Health Insight',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'Your activity looks moderate today. A short walk or 5-minute meditation can improve emotional balance and support your cycle phase. 🌸',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.68),
                          fontSize: 12.5,
                          height: 1.5),
                    ),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }

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

  Widget _miniPill(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: c.withOpacity(0.18),
          border: Border.all(color: c.withOpacity(0.4), width: 1),
        ),
        child: Text(t,
            style:
                TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// ═══════════════════════════════════════════════════════════
//  RING PAINTER
// ═══════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  final double progress, glow;
  final Color color;
  _RingPainter(
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

// ═══════════════════════════════════════════════════════════
//  STAR PARTICLE SYSTEM
// ═══════════════════════════════════════════════════════════

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
  _HStarPainter({required this.stars, required this.progress});

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

// ═══════════════════════════════════════════════════════════
//  DREAMY BACKGROUND
// ═══════════════════════════════════════════════════════════

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
        Positioned(top: -70, left: -50, child: _blob(280, _hTeal, 0.1)),
        Positioned(top: 80, right: -60, child: _blob(240, _hPink, 0.12)),
        Positioned(bottom: 60, left: -50, child: _blob(260, _hPurple, 0.14)),
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
