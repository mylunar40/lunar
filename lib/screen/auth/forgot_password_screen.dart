import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import 'auth_widgets.dart';

const _kPurple = Color(0xFFAB5CF2);
const _kPink = Color(0xFFFF69B4);
const _kBg = Color(0xFF0A0118);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  bool _loading = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    FocusScope.of(context).unfocus();

    final auth = context.read<LunarAuthProvider>();
    final ok = await auth.sendPasswordReset(_emailCtrl.text.trim());

    if (mounted) {
      setState(() {
        _loading = false;
        _sent = ok;
      });
      if (!ok && auth.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(auth.error!,
              style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF5C2DB8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        auth.clearError();
      }
    }
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
                    const SizedBox(height: 48),
                    const Text('🔑',
                        style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 18),
                    const Text(
                      'Reset password',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sent
                          ? 'Check your inbox 💌\nA reset link has been sent.'
                          : "Enter your email and we'll\nsend you a reset link.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.50),
                          fontSize: 14,
                          height: 1.55),
                    ),
                    const SizedBox(height: 36),
                    if (_sent) ...[
                      // Success state
                      _SuccessCard(
                        email: _emailCtrl.text.trim(),
                        onBack: () => Navigator.pop(context),
                      ),
                    ] else ...[
                      AuthCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AuthField(
                                controller: _emailCtrl,
                                label: 'Email address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) =>
                                    (v == null || !v.contains('@'))
                                        ? 'Enter a valid email'
                                        : null,
                              ),
                              const SizedBox(height: 22),
                              _loading
                                  ? SizedBox(
                                      height: 54,
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(_kPurple),
                                          ),
                                        ),
                                      ),
                                    )
                                  : AuthPrimaryButton(
                                      label: 'Send Reset Link ✨',
                                      onTap: _sendReset,
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _SuccessCard extends StatelessWidget {
  final String email;
  final VoidCallback onBack;
  const _SuccessCard({required this.email, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.06),
            border:
                Border.all(color: _kPurple.withOpacity(0.30), width: 1.2),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPurple.withOpacity(0.18),
                  border: Border.all(
                      color: _kPurple.withOpacity(0.45), width: 1.5),
                ),
                child: const Icon(Icons.check_rounded,
                    color: _kPurple, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'Reset link sent to',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55), fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                        colors: [_kPurple, _kPink]),
                    boxShadow: [
                      BoxShadow(
                          color: _kPurple.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2)
                    ],
                  ),
                  child: const Text(
                    'Back to Sign In',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
