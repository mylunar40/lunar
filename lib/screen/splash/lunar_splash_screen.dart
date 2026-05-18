import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//  LUNAR SPLASH SCREEN
//  Premium animated splash shown while auth state resolves.
//  Animations: moon float + glow pulse + star particles +
//  staggered text reveal + breathing progress indicator.
// ══════════════════════════════════════════════════════════════

class LunarSplashScreen extends StatefulWidget {
  const LunarSplashScreen({super.key});

  @override
  State<LunarSplashScreen> createState() => _LunarSplashScreenState();
}

class _LunarSplashScreenState extends State<LunarSplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────
  late AnimationController _floatCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _orbitCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _particleCtrl;

  // ── Animations ─────────────────────────────────────────────
  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _entryAnim;
  late Animation<double> _textSlideAnim;

  // ── Particles ──────────────────────────────────────────────
  final List<_SplashStar> _stars = [];
  final math.Random _rng = math.Random();

  // ── Design tokens ──────────────────────────────────────────
  static const _kBg = Color(0xFF0A0118);
  static const _kPurple = Color(0xFFAB5CF2);
  static const _kPink = Color(0xFFFF69B4);
  static const _kGold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10.0, end: 10.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _orbitCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();
    _entryAnim = CurvedAnimation(
        parent: _entryCtrl, curve: Curves.easeOutCubic);
    _textSlideAnim = Tween<double>(begin: 30.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.3, 1.0,
                curve: Curves.easeOutCubic)));

    for (int i = 0; i < 50; i++) {
      _stars.add(_SplashStar(rng: _rng));
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _orbitCtrl.dispose();
    _particleCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.5,
                colors: [
                  Color(0xFF3D0D70),
                  Color(0xFF1A0540),
                  _kBg,
                ],
              ),
            ),
          ),

          // ── Floating particles ───────────────────────────
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _SplashParticlePainter(
                  stars: _stars,
                  progress: _particleCtrl.value,
                  orbitProgress: _orbitCtrl.value,
                ),
              ),
            ),
          ),

          // ── Moon glow blobs ──────────────────────────────
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Stack(children: [
              // Top glow
              Positioned(
                top: size.height * 0.15,
                left: size.width * 0.5 - 130,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _kPurple.withOpacity(0.28 * _glowAnim.value),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              // Pink accent glow
              Positioned(
                top: size.height * 0.25,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _kPink.withOpacity(0.15 * _glowAnim.value),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ]),
          ),

          // ── Central content ──────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Moon with orbit ring
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_floatAnim, _glowAnim, _orbitCtrl]),
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              _kGold.withOpacity(
                                  0.20 * _glowAnim.value),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                        // Orbit ring
                        Transform.rotate(
                          angle:
                              _orbitCtrl.value * 2 * math.pi,
                          child: CustomPaint(
                            size: const Size(120, 120),
                            painter: _OrbitRingPainter(
                              color: _kPurple
                                  .withOpacity(0.35),
                            ),
                          ),
                        ),
                        // Moon circle
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1A0540),
                            border: Border.all(
                              color: _kGold.withOpacity(
                                  0.55 * _glowAnim.value),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kGold.withOpacity(
                                    0.30 * _glowAnim.value),
                                blurRadius: 32,
                                spreadRadius: 8,
                              ),
                              BoxShadow(
                                color: _kPurple.withOpacity(
                                    0.40 * _glowAnim.value),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🌙',
                                style:
                                    TextStyle(fontSize: 36)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Staggered text reveal
                AnimatedBuilder(
                  animation: _entryAnim,
                  builder: (_, __) => Opacity(
                    opacity: _entryAnim.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, _textSlideAnim.value),
                      child: Column(
                        children: [
                          // App name
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFFDDB6FF),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'LUNAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tagline
                          Text(
                            'your emotional wellness companion',
                            style: TextStyle(
                              color:
                                  Colors.white.withOpacity(0.45),
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 56),

                // Breathing progress dots
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final delay = i * 0.33;
                      final opacity = (((_glowCtrl.value +
                                          delay) %
                                      1.0 *
                                  math.pi)
                              .abs()
                              .clamp(0.25, 1.0));
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kPurple.withOpacity(opacity),
                        ),
                      );
                    }),
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

// ══════════════════════════════════════════════════════════════
//  SPLASH STAR PARTICLE
// ══════════════════════════════════════════════════════════════

class _SplashStar {
  final double x, y;
  final double size;
  final double speed;
  final double opacity;
  final double phase;

  _SplashStar({required math.Random rng})
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        size = rng.nextDouble() * 2.5 + 0.8,
        speed = rng.nextDouble() * 0.3 + 0.1,
        opacity = rng.nextDouble() * 0.6 + 0.2,
        phase = rng.nextDouble() * math.pi * 2;
}

// ══════════════════════════════════════════════════════════════
//  SPLASH PARTICLE PAINTER
// ══════════════════════════════════════════════════════════════

class _SplashParticlePainter extends CustomPainter {
  final List<_SplashStar> stars;
  final double progress;
  final double orbitProgress;

  _SplashParticlePainter({
    required this.stars,
    required this.progress,
    required this.orbitProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final star in stars) {
      final t = (progress * star.speed + star.phase / (2 * math.pi)) % 1.0;
      final yOffset = math.sin(t * math.pi * 2 + star.phase) * 0.03;
      final px = star.x * size.width;
      final py = (star.y + yOffset) * size.height;
      final twinkle = 0.4 +
          0.6 *
              math.sin(
                  progress * math.pi * 4 * star.speed + star.phase);
      paint.color = const Color(0xFFFFFFFF)
          .withOpacity((star.opacity * twinkle).clamp(0.05, 0.9));
      canvas.drawCircle(Offset(px, py), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(_SplashParticlePainter old) =>
      old.progress != progress;
}

// ══════════════════════════════════════════════════════════════
//  ORBIT RING PAINTER
// ══════════════════════════════════════════════════════════════

class _OrbitRingPainter extends CustomPainter {
  final Color color;
  _OrbitRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dashed orbit ring
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, paint);

    // Two bright dots on the ring
    final dotPaint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx + radius, center.dy), 3, dotPaint);
    canvas.drawCircle(Offset(center.dx - radius, center.dy), 2, dotPaint);
  }

  @override
  bool shouldRepaint(_OrbitRingPainter old) => false;
}
