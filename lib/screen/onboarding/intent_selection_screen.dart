import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_intent.dart';
import '../../core/providers/auth_provider.dart';

/// First-run intent selection screen — lets authenticated users choose their
/// primary emotional/wellness journey focus. Fires once, then writes to
/// Firestore and lets the startup gate advance to MainNavigation.
class IntentSelectionScreen extends StatefulWidget {
  const IntentSelectionScreen({super.key});

  @override
  State<IntentSelectionScreen> createState() => _IntentSelectionScreenState();
}

class _IntentSelectionScreenState extends State<IntentSelectionScreen>
    with SingleTickerProviderStateMixin {
  UserIntent? _selected;
  bool _saving = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Design tokens (match Lunar's purple-dark theme) ──────
  static const Color _bg = Color(0xFF0A0118);
  static const Color _purple = Color(0xFFAB5CF2);
  static const Color _pink = Color(0xFFFF69B4);
  static const Color _surface = Color(0xFF160330);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_selected == null || _saving) return;
    setState(() => _saving = true);
    final auth = context.read<LunarAuthProvider>();
    await auth.setUserIntent(_selected!);
    // setUserIntent writes onboardingIntentCompleted=true → Firestore stream
    // updates _userModel → notifyListeners() → main.dart gate re-evaluates
    // automatically. No manual navigation needed here.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // ── Header ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      'What brings you\nto Lunar? 🌙',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose what matters most right now.\nYou can always change this later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.55),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // ── Intent grid ─────────────────────────────────
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: UserIntent.values.length,
                  itemBuilder: (context, i) {
                    final intent = UserIntent.values[i];
                    final isSelected = _selected == intent;
                    return _IntentCard(
                      intent: intent,
                      isSelected: isSelected,
                      onTap: _saving
                          ? null
                          : () => setState(() => _selected = intent),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // ── Continue button ──────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                child: AnimatedOpacity(
                  opacity: _selected != null ? 1.0 : 0.38,
                  duration: const Duration(milliseconds: 250),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: _selected != null
                            ? const LinearGradient(
                                colors: [_purple, _pink],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: _selected == null ? _surface : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _selected != null && !_saving
                              ? _onContinue
                              : null,
                          child: Center(
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Begin My Journey',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────
//  Intent Card
// ─────────────────────────────────────────────────────────
class _IntentCard extends StatelessWidget {
  const _IntentCard({
    required this.intent,
    required this.isSelected,
    required this.onTap,
  });

  final UserIntent intent;
  final bool isSelected;
  final VoidCallback? onTap;

  static const Color _bg = Color(0xFF0A0118);
  static const Color _purple = Color(0xFFAB5CF2);
  static const Color _pink = Color(0xFFFF69B4);
  static const Color _surface = Color(0xFF160330);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _purple.withOpacity(0.35),
                    _pink.withOpacity(0.18),
                  ],
                )
              : LinearGradient(
                  colors: [
                    _surface,
                    _surface.withOpacity(0.85),
                  ],
                ),
          border: Border.all(
            color: isSelected
                ? _purple.withOpacity(0.85)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    intent.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    intent.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.75),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    intent.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isSelected
                          ? Colors.white.withOpacity(0.70)
                          : Colors.white.withOpacity(0.40),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
