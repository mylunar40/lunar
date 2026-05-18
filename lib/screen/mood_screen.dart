import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════
//  LUNAR MOOD CHECK — Emotional Heart Space
// ═══════════════════════════════════════════════════════════

const Color _mBg = Color(0xFF0A0118);
const Color _mPurple = Color(0xFFAB5CF2);
const Color _mPink = Color(0xFFFF69B4);
const Color _mGold = Color(0xFFFFD700);
const Color _mGreen = Color(0xFF66BB6A);
const Color _mIndigo = Color(0xFF7986CB);

// ═══════════════════════════════════════════════════════════
//  MOOD SCREEN
// ═══════════════════════════════════════════════════════════
class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────
  late AnimationController _glowCtrl, _floatCtrl, _pulseCtrl, _particleCtrl;
  late Animation<double> _glowAnim, _floatAnim, _pulseAnim;
  final List<_MStar> _stars = [];
  final math.Random _rng = math.Random();

  String? _selectedMood;
  bool _saved = false;

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
    _floatAnim = Tween<double>(begin: -7.0, end: 7.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.94, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _particleCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
    for (int i = 0; i < 22; i++) _stars.add(_MStar(rng: _rng));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  // ── SAVE MOOD ─────────────────────────────────────────────
  Future<void> saveMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> moods = prefs.getStringList('mood_history') ?? [];
    moods.add(mood);
    await prefs.setStringList('mood_history', moods);
  }

  // ── AI MESSAGE ────────────────────────────────────────────
  String getMoodMessage() {
    switch (_selectedMood) {
      case 'happy':
        return "Your joy is radiant today. Let it flow through everything you do. Keep spreading that beautiful light. ✨";
      case 'sad':
        return "It's okay to feel sad. Every emotion has wisdom in it. I'm here, holding space for you with all my heart. 💜";
      case 'angry':
        return "Take a slow breath with me. Your feelings are completely valid. Let's find your calm together. 🌬️";
      case 'loving':
        return "Love is your superpower. When you feel this deeply, you touch the world in ways you can't even see. 🌸";
      default:
        return "";
    }
  }

  // ── MOOD DATA ─────────────────────────────────────────────
  static const Map<String, ({String emoji, String label, Color color})> _moods =
      {
    'happy': (emoji: '😊', label: 'Happy', color: Color(0xFFFFD700)),
    'sad': (emoji: '😔', label: 'Sad', color: Color(0xFF7986CB)),
    'angry': (emoji: '😡', label: 'Angry', color: Color(0xFFFF5252)),
    'loving': (emoji: '🥰', label: 'Loving', color: Color(0xFFFF69B4)),
  };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _mBg,
      body: Stack(
        children: [
          _MBackground(size: size),
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter:
                  _MStarPainter(stars: _stars, progress: _particleCtrl.value),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      children: [
                        _headerRow(),
                        const SizedBox(height: 32),
                        _questionOrb(),
                        const SizedBox(height: 36),
                        _moodGrid(),
                        const SizedBox(height: 28),
                        if (_selectedMood != null) ...[
                          _aiMessageCard(),
                          const SizedBox(height: 24),
                        ],
                        _analyticsButton(),
                        const Spacer(),
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mood Check',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2)),
          const SizedBox(height: 4),
          Text('Your emotions are valid and welcome here',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.48), fontSize: 13)),
        ])),
        AnimatedBuilder(
          animation: Listenable.merge([_glowAnim, _floatAnim]),
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _floatAnim.value * 0.4),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _mPink.withOpacity(_glowAnim.value * 0.7),
                  _mPink.withOpacity(0.05),
                ]),
                boxShadow: [
                  BoxShadow(
                      color: _mPink.withOpacity(_glowAnim.value * 0.5),
                      blurRadius: 20,
                      spreadRadius: 2)
                ],
              ),
              child: const Center(
                  child: Text('💜', style: TextStyle(fontSize: 22))),
            ),
          ),
        ),
      ]);

  Widget _questionOrb() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _pulseAnim]),
      builder: (_, __) => Transform.scale(
        scale: _selectedMood != null ? _pulseAnim.value : 1.0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _mPurple.withOpacity(_glowAnim.value * 0.35),
              _mPink.withOpacity(0.12),
              Colors.transparent,
            ]),
            border: Border.all(
                color: _mPurple.withOpacity(_glowAnim.value * 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: _mPurple.withOpacity(_glowAnim.value * 0.25),
                  blurRadius: 32,
                  spreadRadius: 4)
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                _selectedMood != null ? _moods[_selectedMood]!.emoji : '🌸',
                key: ValueKey(_selectedMood),
                style: const TextStyle(fontSize: 64),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                _selectedMood != null
                    ? _moods[_selectedMood]!.label
                    : 'How are you feeling?',
                key: ValueKey(_selectedMood ?? 'q'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _selectedMood != null
                      ? _moods[_selectedMood]!.color
                      : Colors.white,
                  fontSize: _selectedMood != null ? 22 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _moodGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _moods.entries.map((entry) {
        final moodKey = entry.key;
        final mood = entry.value;
        final isSelected = _selectedMood == moodKey;
        return GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedMood = moodKey;
              _saved = false;
            });
            await saveMood(moodKey);
            setState(() => _saved = true);
          },
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: 72,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                            mood.color.withOpacity(0.38),
                            mood.color.withOpacity(0.16)
                          ])
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: isSelected
                      ? mood.color.withOpacity(_glowAnim.value * 0.9)
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color:
                                mood.color.withOpacity(_glowAnim.value * 0.35),
                            blurRadius: 16,
                            spreadRadius: 2)
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child:
                        Text(mood.emoji, style: const TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(height: 6),
                  Text(mood.label,
                      style: TextStyle(
                          color: isSelected
                              ? mood.color
                              : Colors.white.withOpacity(0.55),
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _aiMessageCard() {
    if (_selectedMood == null) return const SizedBox.shrink();
    final mood = _moods[_selectedMood]!;
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
                  mood.color.withOpacity(0.22),
                  _mPurple.withOpacity(0.12),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              border: Border.all(
                  color: mood.color.withOpacity(_glowAnim.value * 0.55),
                  width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: mood.color.withOpacity(_glowAnim.value * 0.18),
                    blurRadius: 24,
                    spreadRadius: 2)
              ],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _mPurple.withOpacity(0.5),
                    _mPurple.withOpacity(0.1),
                  ]),
                  border:
                      Border.all(color: _mPurple.withOpacity(0.5), width: 1),
                ),
                child: const Center(
                    child: Text('🌙', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      const Text('Lunar AI',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      if (_saved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _mGreen.withOpacity(0.22),
                            border: Border.all(
                                color: _mGreen.withOpacity(0.5), width: 1),
                          ),
                          child: Text('Saved ✓',
                              style: TextStyle(
                                  color: _mGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ]),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Text(getMoodMessage(),
                          key: ValueKey(_selectedMood),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              height: 1.55)),
                    ),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _analyticsButton() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, "/moodAnalytics");
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [
              _mPurple.withOpacity(0.55),
              _mPink.withOpacity(0.35),
            ]),
            border: Border.all(
                color: _mPurple.withOpacity(_glowAnim.value * 0.7), width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: _mPurple.withOpacity(_glowAnim.value * 0.28),
                  blurRadius: 20,
                  spreadRadius: 2)
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('📊', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Text('View Mood Analytics',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  STAR PARTICLES
// ─────────────────────────────────────────────────────────

class _MStar {
  late double x, y, speed, size, opacity, angle;
  _MStar({required math.Random rng}) {
    x = rng.nextDouble();
    y = rng.nextDouble();
    speed = 0.0001 + rng.nextDouble() * 0.0002;
    size = 0.5 + rng.nextDouble() * 1.6;
    opacity = 0.12 + rng.nextDouble() * 0.4;
    angle = rng.nextDouble() * math.pi * 2;
  }
}

class _MStarPainter extends CustomPainter {
  final List<_MStar> stars;
  final double progress;
  _MStarPainter({required this.stars, required this.progress});

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
  bool shouldRepaint(_MStarPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────
//  BACKGROUND
// ─────────────────────────────────────────────────────────

class _MBackground extends StatelessWidget {
  final Size size;
  const _MBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.45),
          radius: 1.3,
          colors: [Color(0xFF2D0B5C), Color(0xFF18063A), _mBg],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -80, left: -60, child: _blob(300, _mPurple, 0.18)),
        Positioned(top: 90, right: -70, child: _blob(240, _mPink, 0.14)),
        Positioned(bottom: 80, right: -40, child: _blob(220, _mGold, 0.09)),
        Positioned(bottom: 0, left: -50, child: _blob(260, _mIndigo, 0.12)),
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
