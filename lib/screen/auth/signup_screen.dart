import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../user_provider.dart';
import 'login_screen.dart';
import 'auth_widgets.dart';

// ── Design tokens ────────────────────────────────────────
const _kPurple = Color(0xFFAB5CF2);
const _kBg = Color(0xFF0A0118);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      _showError('Please accept the terms to continue.');
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    FocusScope.of(context).unfocus();

    final auth = context.read<LunarAuthProvider>();
    final userProvider = context.read<UserProvider>();
    final ok = await auth.signUpWithEmail(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      userProvider: userProvider,
    );
    debugPrint('[SignupScreen] signUpWithEmail result: $ok | error: ${auth.error}');

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (auth.error != null) {
      _showError(auth.error!);
      auth.clearError();
    }
  }

  Future<void> _googleSignUp() async {
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    final auth = context.read<LunarAuthProvider>();
    debugPrint('[SignupScreen] Attempting Google sign-up...');
    final ok = await auth.signInWithGoogle();
    debugPrint('[SignupScreen] Google sign-up result: $ok | error: ${auth.error}');

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (auth.error != null) {
      _showError(auth.error!);
      auth.clearError();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF5C2DB8),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _entryAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.12)),
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('✨',
                        style: TextStyle(fontSize: 46)),
                    const SizedBox(height: 14),
                    const Text(
                      'Create your account',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Begin your Lunar journey today 🌸',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.50),
                          fontSize: 14),
                    ),
                    const SizedBox(height: 30),
                    AuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            AuthField(
                              controller: _nameCtrl,
                              label: 'Your name',
                              icon: Icons.person_outline_rounded,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Please enter your name'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            AuthField(
                              controller: _emailCtrl,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  (v == null || !v.contains('@'))
                                      ? 'Enter a valid email'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            AuthField(
                              controller: _passCtrl,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscure,
                              suffixIcon: GestureDetector(
                                onTap: () =>
                                    setState(() => _obscure = !_obscure),
                                child: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _kPurple.withOpacity(0.7),
                                  size: 20,
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.length < 6)
                                      ? 'Minimum 6 characters'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            AuthField(
                              controller: _confirmCtrl,
                              label: 'Confirm password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscureConfirm,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                child: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _kPurple.withOpacity(0.7),
                                  size: 20,
                                ),
                              ),
                              validator: (v) =>
                                  v != _passCtrl.text
                                      ? 'Passwords do not match'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            // Terms checkbox
                            GestureDetector(
                              onTap: () => setState(
                                  () => _acceptedTerms = !_acceptedTerms),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      color: _acceptedTerms
                                          ? _kPurple.withOpacity(0.30)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: _acceptedTerms
                                            ? _kPurple
                                            : Colors.white.withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _acceptedTerms
                                        ? const Icon(Icons.check,
                                            size: 14, color: _kPurple)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'I agree to the Terms of Service & Privacy Policy',
                                      style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(0.55),
                                          fontSize: 12.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            _loading
                                ? const AuthLoadingDots()
                                : AuthPrimaryButton(
                                    label: 'Create Account 🌙',
                                    onTap: _signUp,
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: Divider(
                              color: Colors.white.withOpacity(0.14))),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 13)),
                      ),
                      Expanded(
                          child: Divider(
                              color: Colors.white.withOpacity(0.14))),
                    ]),
                    const SizedBox(height: 20),
                    AuthSocialButton(
                      icon: '🇬',
                      label: 'Continue with Google',
                      onTap: _loading ? null : _googleSignUp,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                                color: _kPurple,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
