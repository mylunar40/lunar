import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

// ── Lunar design tokens (local copy to avoid circular imports) ──
const _kBg = Color(0xFF0A0118);
const _kPurple = Color(0xFFAB5CF2);
const _kPink = Color(0xFFFF69B4);
const _kGold = Color(0xFFFFD700);

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _orbitCtrl;

  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _entryAnim;

  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();
  bool _guestLoading = false;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10.0, end: 10.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _orbitCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entryCtrl.forward();

    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(_rng));
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _entryCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  Future<void> _continueAsGuest() async {
    if (_guestLoading) return;
    setState(() => _guestLoading = true);
    final auth = context.read<LunarAuthProvider>();
    final ok = await auth.signInAsGuest();
    if (!mounted) return;
    setState(() => _guestLoading = false);
    if (!ok) {
      final msg = auth.error ?? 'Unable to continue as guest. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF3D1060),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    // On success, navigation handled automatically by auth state listener in main.dart
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Background ─────────────────────────────────
          _WelcomeBackground(size: size),
          // ── Particles ──────────────────────────────────
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _ParticlePainter(
                    _particles, _orbitCtrl.value),
              ),
            ),
          ),
          // ── Content ────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _entryAnim,
              child: SlideTransition(
                position: Tween(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero)
                    .animate(_entryAnim),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    // Moon orb
                    AnimatedBuilder(
                      animation: Listenable.merge(
                          [_floatAnim, _glowAnim]),
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: _MoonOrb(glow: _glowAnim.value),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Brand title
                    const Text(
                      'Lunar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your cycle. Your wellness. Your universe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.4,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(flex: 2),
                    // ── Buttons ───────────────────────────
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          _GlowButton(
                            label: 'Get Started ✨',
                            gradient: const LinearGradient(colors: [
                              _kPurple,
                              _kPink,
                            ]),
                            onTap: () => Navigator.push(
                              context,
                              _slideRoute(const SignupScreen()),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _OutlineButton(
                            label: 'I already have an account',
                            onTap: () => Navigator.push(
                              context,
                              _slideRoute(const LoginScreen()),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: _guestLoading ? null : _continueAsGuest,
                            child: _guestLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white38,
                                    ),
                                  )
                                : Text(
                                    'Continue as Guest',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.42),
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          Colors.white.withOpacity(0.25),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'By continuing you agree to our Terms & Privacy Policy',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 10.5),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PageRoute<T> _slideRoute<T>(Widget page) => PageRouteBuilder(
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
                    begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: anim, curve: Curves.easeOutCubic)),
            child: page,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      );
}

// ══════════════════════════════════════════════════════════════
// MOON ORB
// ══════════════════════════════════════════════════════════════
class _MoonOrb extends StatelessWidget {
  final double glow;
  const _MoonOrb({required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          _kGold.withOpacity(glow * 0.45),
          _kPurple.withOpacity(0.35),
          Colors.transparent,
        ]),
        boxShadow: [
          BoxShadow(
            color: _kGold.withOpacity(glow * 0.5),
            blurRadius: 60,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: _kPurple.withOpacity(glow * 0.35),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Text('🌙', style: TextStyle(fontSize: 68)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BACKGROUND
// ══════════════════════════════════════════════════════════════
class _WelcomeBackground extends StatelessWidget {
  final Size size;
  const _WelcomeBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.4,
          colors: [Color(0xFF2D0B5C), Color(0xFF18063A), _kBg],
        ),
      ),
      child: Stack(children: [
        _blob(size, -70, -50, 280, const Color(0xFF9B59B6), 0.30),
        _blob(size, null, -60, 240, const Color(0xFFE91E8C), 0.18,
            top: 60),
        _blob(size, -60, null, 260, const Color(0xFF6C3FC8), 0.20,
            bottom: 80),
        _blob(size, null, -40, 220, const Color(0xFFFF69B4), 0.14,
            bottom: 0),
        // Moon glow top-right
        _blob(size, null, -40, 200, _kGold, 0.09, top: -30),
      ]),
    );
  }

  Widget _blob(Size size, double? left, double? right, double diameter,
      Color color, double opacity,
      {double? top, double? bottom}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// REUSABLE BUTTON WIDGETS
// ══════════════════════════════════════════════════════════════
class _GlowButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _GlowButton({
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: _kPurple.withOpacity(0.50),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white.withOpacity(0.07),
          border: Border.all(
              color: _kPurple.withOpacity(0.45), width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PARTICLE SYSTEM (lightweight)
// ══════════════════════════════════════════════════════════════
class _Particle {
  final double x, y, size, opacity, speed;
  _Particle(math.Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        size = 0.7 + r.nextDouble() * 2.0,
        opacity = 0.2 + r.nextDouble() * 0.5,
        speed = 0.00012 + r.nextDouble() * 0.0002;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y =
          (p.y - p.speed * progress * 300) % 1.0;
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        Paint()
          ..color = Colors.white.withOpacity(p.opacity * 0.7)
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress;
}
