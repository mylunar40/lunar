import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screen/auth/signup_screen.dart';
import '../screen/auth/login_screen.dart';

// ═══════════════════════════════════════════════════════════
//  GUEST GATE  — Dreamy restriction modal
//  Show whenever a guest tries to access a signed-in feature.
//  Usage: GuestGate.show(context, feature: 'post in the community')
// ═══════════════════════════════════════════════════════════

const Color _ggBg     = Color(0xFF0A0118);
const Color _ggPurple = Color(0xFFAB5CF2);
const Color _ggPink   = Color(0xFFFF69B4);
const Color _ggGold   = Color(0xFFFFD700);

class GuestGate {
  GuestGate._();

  /// Shows the dreamy sign-up prompt modal.
  /// [feature] is an optional phrase like "share posts" describing
  /// the action that is gated, so the copy feels contextual.
  static Future<void> show(
    BuildContext context, {
    String feature = 'access this feature',
  }) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => _GuestGateSheet(feature: feature),
    );
  }
}

// ── Private Sheet Widget ──────────────────────────────────

class _GuestGateSheet extends StatefulWidget {
  final String feature;
  const _GuestGateSheet({required this.feature});

  @override
  State<_GuestGateSheet> createState() => _GuestGateSheetState();
}

class _GuestGateSheetState extends State<_GuestGateSheet>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 60.0, end: 0.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: _buildSheet(context),
        ),
      ),
    );
  }

  Widget _buildSheet(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A0535).withOpacity(0.98),
                  const Color(0xFF0D0120).withOpacity(0.98),
                ],
              ),
              border: Border(
                top: BorderSide(
                    color: _ggPurple.withOpacity(
                        0.45 + 0.25 * _glowAnim.value),
                    width: 1.5),
                left: BorderSide(
                    color: _ggPurple.withOpacity(0.15), width: 1),
                right: BorderSide(
                    color: _ggPurple.withOpacity(0.15), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                    color: _ggPurple.withOpacity(
                        0.28 * _glowAnim.value),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, -4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),

                // Moon glow orb
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _ggGold.withOpacity(
                          _glowAnim.value * 0.35),
                      _ggPurple.withOpacity(0.25),
                      Colors.transparent,
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: _ggPurple.withOpacity(
                              _glowAnim.value * 0.5),
                          blurRadius: 30,
                          spreadRadius: 4),
                      BoxShadow(
                          color: _ggGold.withOpacity(
                              _glowAnim.value * 0.3),
                          blurRadius: 18,
                          spreadRadius: 2),
                    ],
                  ),
                  child: const Center(
                    child: Text('🌙',
                        style: TextStyle(fontSize: 36)),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'Save Your Lunar Journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                // Emotional subtitle
                Text(
                  'Create your free Lunar account to\n${widget.feature} and sync your emotional journey 🌸',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),

                const SizedBox(height: 24),

                // Feature teasers
                _featureRow('☁️', 'Cloud sync across all your devices'),
                const SizedBox(height: 8),
                _featureRow('💜', 'Post & connect in the community'),
                const SizedBox(height: 8),
                _featureRow('🔔', 'Personalized cycle reminders'),
                const SizedBox(height: 8),
                _featureRow('📊', 'Full mood & wellness history'),

                const SizedBox(height: 28),

                // CTA — Create account
                _GlowCTAButton(
                  label: 'Create Free Account ✨',
                  gradient: LinearGradient(colors: [
                    _ggPurple,
                    _ggPink,
                  ]),
                  glowColor: _ggPurple,
                  glow: _glowAnim.value,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      _fadeSlideRoute(const SignupScreen()),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Sign in link
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      _fadeSlideRoute(const LoginScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                        color: _ggPurple.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: _ggPurple.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Dismiss — stay as guest
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Continue exploring as guest',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.28),
                        fontSize: 12,
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

  Widget _featureRow(String emoji, String text) => Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13,
                height: 1.3),
          ),
        ],
      );

  PageRoute<T> _fadeSlideRoute<T>(Widget page) => PageRouteBuilder(
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

// ── Glow CTA Button ───────────────────────────────────────

class _GlowCTAButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final Color glowColor;
  final double glow;
  final VoidCallback onTap;

  const _GlowCTAButton({
    required this.label,
    required this.gradient,
    required this.glowColor,
    required this.glow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
                color: glowColor.withOpacity(glow * 0.55),
                blurRadius: 20,
                spreadRadius: 2),
            BoxShadow(
                color: glowColor.withOpacity(glow * 0.25),
                blurRadius: 36,
                spreadRadius: 6),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
