import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../user_provider.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'auth_widgets.dart';

// ── Design tokens ────────────────────────────────────────
const _kBg = Color(0xFF0A0118);
const _kPurple = Color(0xFFAB5CF2);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  bool _obscure = true;
  bool _loading = false;

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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    FocusScope.of(context).unfocus();

    final auth = context.read<LunarAuthProvider>();
    final userProvider = context.read<UserProvider>();
    debugPrint('[LoginScreen] Attempting email sign-in: ${_emailCtrl.text.trim()}');
    final ok = await auth.signInWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      userProvider: userProvider,
    );
    debugPrint('[LoginScreen] signInWithEmail result: $ok | error: ${auth.error}');

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      // LoginScreen is pushed on top of the root route. Pop back to root so
      // main.dart's AnimatedSwitcher (now showing MainNavigation) becomes visible.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (auth.error != null) {
      _showError(auth.error!);
      auth.clearError();
    }
  }

  Future<void> _googleSignIn() async {
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    final auth = context.read<LunarAuthProvider>();
    debugPrint('[LoginScreen] Attempting Google sign-in...');
    final ok = await auth.signInWithGoogle();
    debugPrint('[LoginScreen] Google sign-in result: $ok | error: ${auth.error}');

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5C2DB8),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Background
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
                    // Back button
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
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('🌙',
                        style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to continue your journey',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.50),
                          fontSize: 14),
                    ),
                    const SizedBox(height: 36),
                    // ── Glass Card ─────────────────────────
                    AuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
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
                            const SizedBox(height: 16),
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
                                      ? 'Password too short'
                                      : null,
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen()),
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                      color: _kPurple,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _loading
                                ? const AuthLoadingDots()
                                : AuthPrimaryButton(
                                    label: 'Sign In ✨',
                                    onTap: _signIn,
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── Divider ────────────────────────────
                    Row(children: [
                      Expanded(
                          child: Divider(
                              color: Colors.white.withOpacity(0.14))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    // ── Google ─────────────────────────────
                    AuthSocialButton(
                      icon: '🇬',
                      label: 'Continue with Google',
                      onTap: _loading ? null : _googleSignIn,
                    ),
                    const SizedBox(height: 28),
                    // ── Sign up link ───────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen()),
                          ),
                          child: const Text(
                            'Sign Up',
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

// Shared auth widgets (AuthBackground, AuthCard, AuthField, etc.) are in auth_widgets.dart
