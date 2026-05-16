import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// ═══════════════════════════════════════════════════════════
//  LUNAR PROFILE — Your Wellness Story
// ═══════════════════════════════════════════════════════════

const Color _prBg = Color(0xFF0A0118);
const Color _prPurple = Color(0xFFAB5CF2);
const Color _prPink = Color(0xFFFF69B4);
const Color _prGold = Color(0xFFFFD700);
const Color _prTeal = Color(0xFF4FC3F7);
const Color _prGreen = Color(0xFF66BB6A);
const Color _prIndigo = Color(0xFF7986CB);
const Color _prWarm = Color(0xFFFFB74D);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl, _floatCtrl, _particleCtrl;
  late Animation<double> _glowAnim, _floatAnim;
  final List<_PrStar> _stars = [];
  final math.Random _rng = math.Random();

  File? profileImage;

  String name = "Zaheer Khan";
  String email = "user@email.com";

  int moodEntries = 18;
  int journalEntries = 10;
  int healthScore = 78;

  int journalStreak = 5;
  int moodStreak = 7;

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
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _particleCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
    for (int i = 0; i < 22; i++) _stars.add(_PrStar(rng: _rng));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  Future pickImage() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => profileImage = File(image.path));
    }
  }

  void editName() {
    HapticFeedback.lightImpact();
    final controller = TextEditingController(text: name);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A0535),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: _prPurple.withOpacity(0.4), width: 1),
          ),
          title: const Text('Edit Name',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            cursorColor: _prPurple,
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: _prPurple.withOpacity(0.35), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _prPurple, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
            GestureDetector(
              onTap: () {
                setState(() => name = controller.text);
                Navigator.pop(context);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(colors: [
                    _prPurple.withOpacity(0.7),
                    _prPink.withOpacity(0.4),
                  ]),
                ),
                child: const Text('Save',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _prBg,
      body: Stack(
        children: [
          _PrBackground(size: size),
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter:
                  _PrStarPainter(stars: _stars, progress: _particleCtrl.value),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header title ──────────────────────
                        _pageHeader(),
                        const SizedBox(height: 28),
                        // ── Profile card ──────────────────────
                        _profileCard(),
                        const SizedBox(height: 24),
                        // ── Stats ─────────────────────────────
                        _sectionLabel('Your Journey', '🌸'),
                        const SizedBox(height: 14),
                        _statsRow(),
                        const SizedBox(height: 24),
                        // ── Streaks ───────────────────────────
                        _sectionLabel('Streaks', '🔥'),
                        const SizedBox(height: 14),
                        _streakCards(),
                        const SizedBox(height: 24),
                        // ── Quick access ──────────────────────
                        _sectionLabel('Quick Access', '⚡'),
                        const SizedBox(height: 14),
                        _quickAccessCard(),
                        const SizedBox(height: 24),
                        // ── Settings ──────────────────────────
                        _sectionLabel('Settings', '⚙️'),
                        const SizedBox(height: 14),
                        _settingsCard(),
                        const SizedBox(height: 24),
                        // ── Logout ────────────────────────────
                        _logoutButton(),
                        const SizedBox(height: 100),
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

  // ── PAGE HEADER ───────────────────────────────────────────
  Widget _pageHeader() => Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('My Profile',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2)),
          const SizedBox(height: 4),
          Text('Your personal wellness universe',
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
                  _prPurple.withOpacity(_glowAnim.value * 0.7),
                  _prPurple.withOpacity(0.05),
                ]),
                boxShadow: [
                  BoxShadow(
                      color: _prPurple.withOpacity(_glowAnim.value * 0.5),
                      blurRadius: 20,
                      spreadRadius: 2)
                ],
              ),
              child: const Center(
                  child: Text('🌙', style: TextStyle(fontSize: 22))),
            ),
          ),
        ),
      ]);

  // ── PROFILE CARD ──────────────────────────────────────────
  Widget _profileCard() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _prPurple.withOpacity(0.28),
                  _prPink.withOpacity(0.14),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              border: Border.all(
                  color: _prPurple.withOpacity(_glowAnim.value * 0.6),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: _prPurple.withOpacity(_glowAnim.value * 0.25),
                    blurRadius: 32,
                    spreadRadius: 3)
              ],
            ),
            child: Row(children: [
              // ── Avatar ────────────────────────────────────
              GestureDetector(
                onTap: pickImage,
                child: Stack(children: [
                  AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: profileImage == null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                    _prPurple.withOpacity(0.6),
                                    _prPink.withOpacity(0.4),
                                  ])
                            : null,
                        border: Border.all(
                            color: _prPurple.withOpacity(_glowAnim.value * 0.8),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  _prPurple.withOpacity(_glowAnim.value * 0.4),
                              blurRadius: 18,
                              spreadRadius: 2)
                        ],
                        image: profileImage != null
                            ? DecorationImage(
                                image: FileImage(profileImage!),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: profileImage == null
                          ? const Center(
                              child: Text('🌸', style: TextStyle(fontSize: 34)))
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _prPurple,
                        border: Border.all(color: _prBg, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 18),
              // ── Name & email ──────────────────────────────
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    GestureDetector(
                      onTap: editName,
                      child: Row(children: [
                        Flexible(
                          child: Text(name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.edit_outlined,
                            color: _prPurple.withOpacity(0.7), size: 15),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text(email,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: _prGold.withOpacity(0.14),
                        border: Border.all(
                            color: _prGold.withOpacity(0.45), width: 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('⭐', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Text('Premium Member',
                            style: TextStyle(
                                color: _prGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }

  // ── STATS ROW ─────────────────────────────────────────────
  Widget _statsRow() => Row(children: [
        _statCard('😊', 'Mood\nEntries', '$moodEntries', _prPink),
        const SizedBox(width: 12),
        _statCard('📓', 'Journal\nEntries', '$journalEntries', _prIndigo),
        const SizedBox(width: 12),
        _statCard('💚', 'Health\nScore', '$healthScore%', _prGreen),
      ]);

  Widget _statCard(String emoji, String label, String value, Color color) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: color.withOpacity(0.07),
                border: Border.all(
                    color: color.withOpacity(_glowAnim.value * 0.45), width: 1),
              ),
              child: Column(children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 8),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10.5,
                        height: 1.3)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── STREAK CARDS ──────────────────────────────────────────
  Widget _streakCards() => Column(children: [
        _streakTile(
            '🔥', 'Journal Streak', '$journalStreak days in a row', _prWarm),
        const SizedBox(height: 10),
        _streakTile(
            '💜', 'Mood Check Streak', '$moodStreak days in a row', _prPurple),
      ]);

  Widget _streakTile(String emoji, String title, String sub, Color color) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: color.withOpacity(0.07),
              border: Border.all(
                  color: color.withOpacity(_glowAnim.value * 0.4), width: 1),
            ),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color.withOpacity(0.35), width: 1),
                ),
                child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(sub,
                        style: TextStyle(
                            color: color,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ])),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withOpacity(0.18),
                  border: Border.all(color: color.withOpacity(0.4), width: 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('🔥', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                      title.contains('Journal')
                          ? '$journalStreak'
                          : '$moodStreak',
                      style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── QUICK ACCESS CARD ─────────────────────────────────────
  Widget _quickAccessCard() {
    return _glassCard(
        child: Column(children: [
      _accessTile('📊', 'Mood Analytics', _prPink, () {}),
      _divider(),
      _accessTile('📖', 'Journal History', _prIndigo, () {}),
      _divider(),
      _accessTile('🩸', 'Period History', _prPurple, () {}),
    ]));
  }

  // ── SETTINGS CARD ─────────────────────────────────────────
  Widget _settingsCard() {
    return _glassCard(
        child: Column(children: [
      _accessTile('🔔', 'Notifications', _prTeal, () {}),
      _divider(),
      _accessTile('🌙', 'Dark Mode', _prIndigo, () {}),
    ]));
  }

  Widget _accessTile(
      String emoji, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.25), size: 14),
        ]),
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        color: Colors.white.withOpacity(0.07),
      );

  // ── LOGOUT BUTTON ─────────────────────────────────────────
  Widget _logoutButton() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => GestureDetector(
        onTap: () => HapticFeedback.lightImpact(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(
                color: Colors.white.withOpacity(_glowAnim.value * 0.18),
                width: 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.logout_rounded,
                color: Colors.white.withOpacity(0.5), size: 18),
            const SizedBox(width: 8),
            Text('Log Out',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────
  Widget _glassCard({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.05),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: child,
          ),
        ),
      );

  Widget _sectionLabel(String t, String emoji) => Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(t,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2)),
      ]);
}

// ═══════════════════════════════════════════════════════════
//  STAR PARTICLES
// ═══════════════════════════════════════════════════════════

class _PrStar {
  late double x, y, speed, size, opacity, angle;
  _PrStar({required math.Random rng}) {
    x = rng.nextDouble();
    y = rng.nextDouble();
    speed = 0.0001 + rng.nextDouble() * 0.0002;
    size = 0.5 + rng.nextDouble() * 1.6;
    opacity = 0.12 + rng.nextDouble() * 0.4;
    angle = rng.nextDouble() * math.pi * 2;
  }
}

class _PrStarPainter extends CustomPainter {
  final List<_PrStar> stars;
  final double progress;
  _PrStarPainter({required this.stars, required this.progress});

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
  bool shouldRepaint(_PrStarPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════
//  BACKGROUND
// ═══════════════════════════════════════════════════════════

class _PrBackground extends StatelessWidget {
  final Size size;
  const _PrBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.45),
          radius: 1.3,
          colors: [Color(0xFF2D0B5C), Color(0xFF18063A), _prBg],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -80, left: -60, child: _blob(300, _prPurple, 0.18)),
        Positioned(top: 90, right: -70, child: _blob(240, _prPink, 0.14)),
        Positioned(bottom: 80, left: -50, child: _blob(260, _prIndigo, 0.12)),
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
