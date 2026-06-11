import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────
//  EMAIL VERIFICATION SCREEN
//  Shown after email sign-up until the user verifies their
//  address. Allows resending the verification email and
//  checking verification status after the user clicks the link.
// ─────────────────────────────────────────────────────────

const _kBg     = Color(0xFF0A0118);
const _kPurple = Color(0xFFAB5CF2);
const _kPink   = Color(0xFFFF69B4);

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});
  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  bool _resendLoading = false;
  bool _checkLoading  = false;
  bool _resentSuccess = false;

  Future<void> _resend() async {
    setState(() { _resendLoading = true; _resentSuccess = false; });
    final auth = context.read<LunarAuthProvider>();
    final ok = await auth.sendEmailVerification();
    if (!mounted) return;
    setState(() {
      _resendLoading = false;
      _resentSuccess = ok;
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification email sent! Check your inbox 💜'),
          backgroundColor: _kPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _checkLoading = true);
    final auth = context.read<LunarAuthProvider>();
    await auth.reloadUser();
    if (!mounted) return;
    setState(() => _checkLoading = false);
    if (!auth.isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email not verified yet — check your inbox and click the link 🌙',
          ),
          backgroundColor: Color(0xFF3D1060),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // On success, routing in main.dart detects isEmailVerified == true
    // and automatically navigates away from this screen.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<LunarAuthProvider>();
    final email = auth.firebaseUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Subtle background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.4),
                radius: 1.0,
                colors: [
                  _kPurple.withOpacity(0.18),
                  _kBg,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Back / sign-out row
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => auth.signOut(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.06),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout_rounded,
                                color: Colors.white.withOpacity(0.5),
                                size: 14),
                            const SizedBox(width: 6),
                            Text('Sign out',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: _kPurple.withOpacity(0.18),
                          border: Border.all(
                              color: _kPurple.withOpacity(0.4), width: 1.5),
                        ),
                        child: const Icon(Icons.mark_email_unread_rounded,
                            color: _kPurple, size: 44),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Verify your email',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'We sent a verification link to\n$email\n\nClick the link in that email to activate your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 14,
                        height: 1.6),
                  ),

                  const SizedBox(height: 40),

                  // "I've verified" primary button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _checkLoading ? null : _checkVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPurple,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _checkLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Text("I've verified my email ✨",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Resend link
                  GestureDetector(
                    onTap: _resendLoading ? null : _resend,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      alignment: Alignment.center,
                      child: _resendLoading
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _kPink.withOpacity(0.7)),
                            )
                          : Text(
                              _resentSuccess
                                  ? 'Email sent! ✅'
                                  : 'Resend verification email',
                              style: TextStyle(
                                  color: _kPink.withOpacity(0.85),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
