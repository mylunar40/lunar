import 'dart:ui';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//  SHARED AUTH WIDGETS
//  Imported by login_screen.dart, signup_screen.dart,
//  and forgot_password_screen.dart.
// ══════════════════════════════════════════════════════════════

// ── Internal design tokens ────────────────────────────────────
const _kBg = Color(0xFF0A0118);
const _kPurple = Color(0xFFAB5CF2);
const _kPink = Color(0xFFFF69B4);

// ══════════════════════════════════════════════════════════════
//  AuthBackground — gradient + blob background
// ══════════════════════════════════════════════════════════════

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.5),
          radius: 1.3,
          colors: [Color(0xFF2D0B5C), Color(0xFF18063A), _kBg],
        ),
      ),
      child: Stack(children: [
        _blob(-70, null, 260, const Color(0xFF9B59B6), 0.25, top: -60),
        _blob(null, -60, 220, const Color(0xFFE91E8C), 0.15, top: 80),
        _blob(-50, null, 240, const Color(0xFF6C3FC8), 0.18, bottom: 100),
      ]),
    );
  }

  Widget _blob(double? left, double? right, double d, Color color,
      double opacity,
      {double? top, double? bottom}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [color.withOpacity(opacity), Colors.transparent]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  AuthCard — glassmorphism card container
// ══════════════════════════════════════════════════════════════

class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(
                color: _kPurple.withOpacity(0.28), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withOpacity(0.12),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  AuthField — styled text form field
// ══════════════════════════════════════════════════════════════

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
        prefixIcon: Icon(icon, color: _kPurple.withOpacity(0.70), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _kPurple.withOpacity(0.22)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _kPurple.withOpacity(0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _kPink.withOpacity(0.7), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kPink, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _kPink, fontSize: 11),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  AuthPrimaryButton — gradient CTA button
// ══════════════════════════════════════════════════════════════

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(colors: [_kPurple, _kPink]),
          boxShadow: [
            BoxShadow(
              color: _kPurple.withOpacity(0.48),
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
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  AuthSocialButton — glass social login button
// ══════════════════════════════════════════════════════════════

class AuthSocialButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onTap;

  const AuthSocialButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Colors.white.withOpacity(0.07),
              border: Border.all(
                  color: Colors.white.withOpacity(0.18), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  AuthLoadingDots — circular progress placeholder
// ══════════════════════════════════════════════════════════════

class AuthLoadingDots extends StatelessWidget {
  const AuthLoadingDots({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 54,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(_kPurple),
          ),
        ),
      ),
    );
  }
}
