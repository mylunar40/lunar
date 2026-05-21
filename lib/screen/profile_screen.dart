import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/lunar_data_provider.dart';
import '../core/providers/app_provider.dart';
import '../core/services/firestore_service.dart';
import '../widgets/guest_gate.dart';
import '../models/avatar_model.dart';
import '../core/providers/avatar_provider.dart';
import '../widgets/lunar_avatar_widget.dart';
import 'avatar/avatar_builder_screen.dart';

// ═══════════════════════════════════════════════════════════
//  LUNAR PROFILE — Premium Wellness Identity
// ═══════════════════════════════════════════════════════════

const Color _prBg = Color(0xFF0A0118);
const Color _prPurple = Color(0xFFAB5CF2);
const Color _prPink = Color(0xFFFF69B4);
const Color _prGold = Color(0xFFFFD700);
const Color _prTeal = Color(0xFF4FC3F7);
const Color _prGreen = Color(0xFF66BB6A);
const Color _prIndigo = Color(0xFF7986CB);
const Color _prWarm = Color(0xFFFFB74D);

// ─── Theme palettes ────────────────────────────────────────
const _kThemes = [
  [Color(0xFF2D0B5C), Color(0xFF18063A), Color(0xFF0A0118)], // Cosmic Night
  [Color(0xFF1A054A), Color(0xFF0E0330), Color(0xFF060118)], // Dreamy Purple
  [Color(0xFF3A0828), Color(0xFF200516), Color(0xFF0D0208)], // Soft Pink
  [Color(0xFF0D1545), Color(0xFF070D2A), Color(0xFF020510)], // Moonlight
];
const _kThemeNames = [
  'Cosmic Night',
  'Dreamy Purple',
  'Soft Pink',
  'Moonlight'
];
const _kThemeEmojis = ['🌌', '💜', '🌸', '🌙'];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  // ─── Animation controllers ────────────────────────────────
  late AnimationController _glowCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;
  final List<_PrStar> _stars = [];
  final math.Random _rng = math.Random();

  // ─── UI State ──────────────────────────────────────────────
  File? _pickedImage;
  bool _loggingOut = false;
  bool _uploading = false;
  int _selectedTheme = 0;
  bool _waterGoalOpen = false;
  bool _sleepGoalOpen = false;
  double _localSleepGoal = 8.0;
  int _localWaterGoal = 8;

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
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));
    for (int i = 0; i < 22; i++) _stars.add(_PrStar(rng: _rng));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = Provider.of<AppProvider>(context, listen: false);
    _localSleepGoal = app.sleepGoal;
    _localWaterGoal = app.waterGoal;
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ─── Computed helpers ──────────────────────────────────────
  int _wellnessScore(LunarDataProvider d) {
    int s = 0;
    s += ((d.todayWaterGlasses / 8.0) * 34).round().clamp(0, 34);
    s += ((d.lastSleepHours / 8.0) * 33).round().clamp(0, 33);
    s += d.moodEntries.isNotEmpty
        ? ((d.moodTrend.averageScore / 5.0) * 33).round().clamp(0, 33)
        : 20;
    return s.clamp(0, 100);
  }

  int _moodStreak(LunarDataProvider d) {
    if (d.moodEntries.isEmpty) return 0;
    final sorted = [...d.moodEntries]..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime check = DateTime.now();
    for (final e in sorted) {
      final diff = check.difference(e.date).inDays.abs();
      if (diff <= 1) {
        streak++;
        check = e.date;
      } else {
        break;
      }
    }
    return streak;
  }

  int _journalStreak(LunarDataProvider d) {
    if (d.journalEntries.isEmpty) return 0;
    final sorted = [...d.journalEntries]
      ..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime check = DateTime.now();
    for (final e in sorted) {
      final diff = check.difference(e.date).inDays.abs();
      if (diff <= 1) {
        streak++;
        check = e.date;
      } else {
        break;
      }
    }
    return streak;
  }

  String _emotionalStatus(LunarDataProvider d) {
    final score = _wellnessScore(d);
    if (score >= 80) return 'Glowing with radiant energy today';
    if (score >= 60) return 'Your healing journey continues';
    if (score >= 40) return 'Growing stronger every day';
    return 'Resting and restoring beautifully';
  }

  // ─── Profile photo pick + upload ──────────────────────────
  Future<void> _pickAndUploadImage(LunarAuthProvider auth) async {
    if (auth.isGuest) {
      GuestGate.show(context, feature: 'set a profile photo');
      return;
    }
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final xFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (xFile == null) return;
    final file = File(xFile.path);
    setState(() {
      _pickedImage = file;
      _uploading = true;
    });
    try {
      final uid = auth.firebaseUser?.uid;
      if (uid != null) {
        final ref =
            FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        await FirestoreService.updateUser(uid, {'photoUrl': url});
      }
    } catch (e) {
      debugPrint('[Profile] Photo upload error: $e');
    }
    if (mounted) setState(() => _uploading = false);
  }

  // ─── Edit name ─────────────────────────────────────────────
  void _editName(LunarAuthProvider auth, AppProvider appProvider) {
    HapticFeedback.lightImpact();
    final controller = TextEditingController(
        text: auth.displayName == 'Lunar User' || auth.displayName == 'Guest'
            ? ''
            : auth.displayName);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => BackdropFilter(
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
            autofocus: true,
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
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
            GestureDetector(
              onTap: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  await appProvider.setUserName(newName);
                  final uid = auth.firebaseUser?.uid;
                  if (uid != null) {
                    await FirestoreService.updateUser(uid, {'name': newName});
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
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

  // ─── Logout ────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    final auth = context.read<LunarAuthProvider>();
    final isGuest = auth.isGuest;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A0535),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: _prPurple.withOpacity(0.4), width: 1),
          ),
          title: Text(isGuest ? 'Leave Guest Mode?' : 'Log Out',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          content: Text(
              isGuest
                  ? 'Your guest session will end. Any unsaved local data will be lost. Create an account first to save your journey 🌙'
                  : 'Are you sure you want to log out?',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isGuest ? 'Leave' : 'Log Out',
                  style: const TextStyle(
                      color: Color(0xFFAB5CF2), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _loggingOut = true);
    try {
      await context.read<LunarAuthProvider>().signOut();
    } catch (e) {
      debugPrint('[ProfileScreen] Logout error: $e');
    }
    if (mounted) setState(() => _loggingOut = false);
  }

  // ──────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<LunarAuthProvider>(context);
    final lunarData = Provider.of<LunarDataProvider>(context);
    final appProvider = Provider.of<AppProvider>(context);
    final size = MediaQuery.of(context).size;
    final theme = _kThemes[_selectedTheme];
    final moodStreak = _moodStreak(lunarData);
    final journalStreak = _journalStreak(lunarData);
    final wellnessScore = _wellnessScore(lunarData);

    return Scaffold(
      backgroundColor: theme[2],
      body: Stack(
        children: [
          _PrBackground(size: size, theme: theme),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _PrStarPainter(
                    stars: _stars, progress: _particleCtrl.value),
              ),
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
                        _pageHeader(auth, lunarData),
                        const SizedBox(height: 24),
                        _profileCard(auth, appProvider, lunarData),
                        const SizedBox(height: 14),
                        _syncStatusBar(auth),
                        const SizedBox(height: 16),
                        _lunarAvatarCard(context, auth),
                        const SizedBox(height: 28),
                        _sectionLabel('Wellness Stats', '✨'),
                        const SizedBox(height: 14),
                        _wellnessStatsRow(lunarData, wellnessScore),
                        const SizedBox(height: 28),
                        _sectionLabel('Your Journey', '🌸'),
                        const SizedBox(height: 14),
                        _statsRow(lunarData, wellnessScore),
                        const SizedBox(height: 24),
                        _sectionLabel('Streaks', '🔥'),
                        const SizedBox(height: 14),
                        _streakCards(lunarData, moodStreak, journalStreak),
                        const SizedBox(height: 28),
                        _sectionLabel('Healing Journey', '🌿'),
                        const SizedBox(height: 14),
                        _healingJourneyCard(
                            lunarData, moodStreak, journalStreak),
                        const SizedBox(height: 28),
                        _sectionLabel('Appearance', '🎨'),
                        const SizedBox(height: 14),
                        _themeSelector(),
                        const SizedBox(height: 28),
                        _sectionLabel('Wellness Goals', '🎯'),
                        const SizedBox(height: 14),
                        _wellnessGoalsCard(appProvider),
                        const SizedBox(height: 24),
                        _sectionLabel('Settings', '⚙️'),
                        const SizedBox(height: 14),
                        _settingsCard(appProvider),
                        const SizedBox(height: 24),
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

  // ──────────────────────────────────────────────────────────
  //  PAGE HEADER
  // ──────────────────────────────────────────────────────────
  Widget _pageHeader(LunarAuthProvider auth, LunarDataProvider lunarData) {
    final status = _emotionalStatus(lunarData);
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('My Profile',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2)),
          const SizedBox(height: 4),
          Text(status,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 13)),
        ]),
      ),
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
            child:
                const Center(child: Text('🌙', style: TextStyle(fontSize: 22))),
          ),
        ),
      ),
    ]);
  }

  // ──────────────────────────────────────────────────────────
  //  PROFILE CARD — real Firebase Auth data
  // ──────────────────────────────────────────────────────────
  Widget _profileCard(LunarAuthProvider auth, AppProvider appProvider,
      LunarDataProvider lunarData) {
    final displayName = appProvider.userName.isNotEmpty
        ? appProvider.userName
        : auth.displayName;
    final email = auth.firebaseUser?.email ??
        auth.firebaseUser?.providerData.firstOrNull?.email ??
        '';
    final networkPhotoUrl = auth.photoUrl;
    final isPremium = auth.userModel?.isPremium ?? false;

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
              // ── Avatar ──────────────────────────────────
              GestureDetector(
                onTap: () => _pickAndUploadImage(auth),
                child: Stack(children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_glowAnim, _pulseAnim]),
                    builder: (_, __) => Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            _pickedImage == null && networkPhotoUrl == null
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                        _prPurple.withOpacity(0.6),
                                        _prPink.withOpacity(0.4),
                                      ])
                                : null,
                        border: Border.all(
                            color: _prPurple.withOpacity(
                                _glowAnim.value * 0.8 + 0.1 * _pulseAnim.value),
                            width: 2.5),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  _prPurple.withOpacity(_glowAnim.value * 0.45),
                              blurRadius: 22,
                              spreadRadius: 3),
                          BoxShadow(
                              color:
                                  _prPink.withOpacity(_glowAnim.value * 0.20),
                              blurRadius: 30,
                              spreadRadius: 5),
                        ],
                        image: _pickedImage != null
                            ? DecorationImage(
                                image: FileImage(_pickedImage!),
                                fit: BoxFit.cover)
                            : networkPhotoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(networkPhotoUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: (_pickedImage == null && networkPhotoUrl == null)
                          ? const Center(
                              child: Text('🌸', style: TextStyle(fontSize: 34)))
                          : null,
                    ),
                  ),
                  if (_uploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.45),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _prPurple),
                          ),
                        ),
                      ),
                    ),
                  if (!_uploading)
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
              // ── Name & email ────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _editName(auth, appProvider),
                      child: Row(children: [
                        Flexible(
                          child: Text(displayName,
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
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(email,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12.5)),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: auth.isGuest
                            ? const Color(0xFF4FC3F7).withOpacity(0.10)
                            : isPremium
                                ? _prGold.withOpacity(0.14)
                                : Colors.white.withOpacity(0.07),
                        border: Border.all(
                            color: auth.isGuest
                                ? const Color(0xFF4FC3F7).withOpacity(0.35)
                                : isPremium
                                    ? _prGold.withOpacity(0.45)
                                    : Colors.white.withOpacity(0.15),
                            width: 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                            auth.isGuest
                                ? '🌙'
                                : isPremium
                                    ? '⭐'
                                    : '🌙',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Text(
                          auth.isGuest
                              ? 'Guest Mode'
                              : isPremium
                                  ? 'Premium Member'
                                  : 'Lunar Member',
                          style: TextStyle(
                              color: auth.isGuest
                                  ? const Color(0xFF4FC3F7)
                                  : isPremium
                                      ? _prGold
                                      : Colors.white.withOpacity(0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  LUNAR AVATAR CARD
  // ──────────────────────────────────────────────────────────
  Widget _lunarAvatarCard(BuildContext context, LunarAuthProvider auth) {
    final avatarProvider = context.watch<AvatarProvider>();
    final av = avatarProvider.avatar;

    // Ensure default avatar exists
    if (av == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final uid = auth.firebaseUser?.uid;
        if (uid != null) {
          context.read<AvatarProvider>()..ensureDefault(uid);
          if (!auth.isGuest) {
            context.read<AvatarProvider>().load(auth);
          }
        }
      });
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AvatarBuilderScreen(),
          transitionDuration: const Duration(milliseconds: 380),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
        ),
      ),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _prPurple.withOpacity(0.18),
                    _prPink.withOpacity(0.08),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
                border: Border.all(
                    color: _prPurple.withOpacity(_glowAnim.value * 0.5 + 0.1),
                    width: 1.2),
              ),
              child: Row(children: [
                // Avatar preview
                ClipOval(
                  child: Container(
                    width: 64,
                    height: 64,
                    color: const Color(0xFF160330),
                    child: av != null
                        ? LunarAvatarWidget(
                            avatar: av,
                            size: 64,
                            animate: false,
                            showAura: false,
                          )
                        : const Center(
                            child: Text('🌙', style: TextStyle(fontSize: 28))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lunar Avatar',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        av != null
                            ? '${av.emotionalState.emoji} ${av.emotionalState.label} · ${av.auraStyle.label}'
                            : 'Personalise your emotional identity',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(colors: [
                      _prPurple.withOpacity(0.8),
                      _prPink.withOpacity(0.6)
                    ]),
                  ),
                  child: const Text('Edit',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  SYNC STATUS BAR
  // ──────────────────────────────────────────────────────────
  Widget _syncStatusBar(LunarAuthProvider auth) {
    final Color syncColor;
    final String syncMsg;
    final String syncIcon;
    final bool isOnline;
    if (auth.isGuest) {
      isOnline = false;
      syncColor = const Color(0xFF4FC3F7);
      syncMsg = 'Guest mode — create an account to save your journey';
      syncIcon = '🌙';
    } else {
      isOnline = auth.firebaseUser != null;
      syncColor = isOnline ? _prGreen : _prWarm;
      syncMsg = isOnline ? 'Synced to cloud' : 'Offline — local data only';
      syncIcon = isOnline ? '☁️' : '📴';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: syncColor.withOpacity(0.06),
              border: Border.all(
                  color: syncColor.withOpacity(0.30 * _glowAnim.value),
                  width: 1),
            ),
            child: Row(children: [
              Text(syncIcon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(syncMsg,
                    style: TextStyle(
                        color: syncColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              if (isOnline)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _prGreen,
                    boxShadow: [
                      BoxShadow(
                          color: _prGreen.withOpacity(0.6 * _glowAnim.value),
                          blurRadius: 8,
                          spreadRadius: 1)
                    ],
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  WELLNESS STATS (horizontal scroll)
  // ──────────────────────────────────────────────────────────
  Widget _wellnessStatsRow(LunarDataProvider d, int wellnessScore) {
    final waterPct = (d.todayWaterGlasses / 8.0).clamp(0.0, 1.0);
    final sleepPct = (d.lastSleepHours / 8.0).clamp(0.0, 1.0);
    final moodPct = d.moodEntries.isNotEmpty
        ? (d.moodTrend.averageScore / 5.0).clamp(0.0, 1.0)
        : 0.6;
    final cyclePct = d.cycleLogs.length >= 3 ? 0.82 : d.cycleLogs.length / 3.0;

    final stats = [
      _StatItem('🌟', 'Wellness\nScore', '$wellnessScore%', _prPurple,
          wellnessScore / 100),
      _StatItem(
          '💧', 'Hydration', '${(waterPct * 100).round()}%', _prTeal, waterPct),
      _StatItem('🌙', 'Sleep\nQuality', '${(sleepPct * 100).round()}%',
          _prIndigo, sleepPct),
      _StatItem('😊', 'Mood\nBalance', '${(moodPct * 100).round()}%', _prPink,
          moodPct),
      _StatItem('🔄', 'Cycle\nTracking', '${(cyclePct * 100).round()}%',
          _prGold, cyclePct),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: stats
            .map((s) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, __) => Container(
                          width: 110,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                s.color.withOpacity(0.18),
                                s.color.withOpacity(0.06),
                              ],
                            ),
                            border: Border.all(
                                color:
                                    s.color.withOpacity(_glowAnim.value * 0.50),
                                width: 1),
                            boxShadow: [
                              BoxShadow(
                                  color: s.color
                                      .withOpacity(0.12 * _glowAnim.value),
                                  blurRadius: 14),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.emoji,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(height: 8),
                              Text(s.value,
                                  style: TextStyle(
                                      color: s.color,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(s.label,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.50),
                                      fontSize: 10,
                                      height: 1.3)),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Stack(children: [
                                  Container(
                                      height: 3,
                                      color: s.color.withOpacity(0.10)),
                                  FractionallySizedBox(
                                    widthFactor: s.pct.clamp(0.0, 1.0),
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: s.color,
                                        boxShadow: [
                                          BoxShadow(
                                              color: s.color.withOpacity(
                                                  0.5 * _glowAnim.value),
                                              blurRadius: 5)
                                        ],
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  STATS ROW (3 cards)
  // ──────────────────────────────────────────────────────────
  Widget _statsRow(LunarDataProvider d, int wellnessScore) => Row(children: [
        _statCard('😊', 'Mood\nEntries', '${d.moodEntries.length}', _prPink),
        const SizedBox(width: 12),
        _statCard(
            '📓', 'Journal\nEntries', '${d.journalEntries.length}', _prIndigo),
        const SizedBox(width: 12),
        _statCard('💚', 'Wellness\nScore', '$wellnessScore%', _prGreen),
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

  // ──────────────────────────────────────────────────────────
  //  STREAK CARDS — real data
  // ──────────────────────────────────────────────────────────
  Widget _streakCards(LunarDataProvider d, int moodStreak, int journalStreak) =>
      Column(children: [
        _streakTile(
            '🔥',
            'Journal Streak',
            '$journalStreak ${journalStreak == 1 ? "day" : "days"} in a row',
            journalStreak,
            _prWarm),
        const SizedBox(height: 10),
        _streakTile(
            '💜',
            'Mood Check Streak',
            '$moodStreak ${moodStreak == 1 ? "day" : "days"} in a row',
            moodStreak,
            _prPurple),
      ]);

  Widget _streakTile(
      String emoji, String title, String sub, int count, Color color) {
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
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withOpacity(0.18),
                  border: Border.all(color: color.withOpacity(0.4), width: 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('🔥', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('$count',
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

  // ──────────────────────────────────────────────────────────
  //  HEALING JOURNEY CARD
  // ──────────────────────────────────────────────────────────
  Widget _healingJourneyCard(
      LunarDataProvider d, int moodStreak, int journalStreak) {
    final moodPct = d.moodEntries.isNotEmpty
        ? (d.moodTrend.averageScore / 5.0).clamp(0.0, 1.0)
        : 0.5;
    final totalEntries = d.moodEntries.length + d.journalEntries.length;
    final milestones = [
      (totalEntries >= 1, 'First entry logged', '🌱'),
      (totalEntries >= 7, '7 entries milestone', '🌿'),
      (totalEntries >= 21, '21-day challenge', '🌸'),
      (moodStreak >= 3, '3-day mood streak', '🔥'),
      (journalStreak >= 5, '5-day journal streak', '✨'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: [
                _prPurple.withOpacity(0.14),
                _prPink.withOpacity(0.07),
              ]),
              border: Border.all(
                  color: _prPurple.withOpacity(0.35 * _glowAnim.value),
                  width: 1),
              boxShadow: [
                BoxShadow(
                    color: _prPurple.withOpacity(0.12 * _glowAnim.value),
                    blurRadius: 22),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mood trend bar
                Row(children: [
                  const Text('💜', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Mood Trend',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            Text('${(moodPct * 100).round()}%',
                                style: TextStyle(
                                    color: _prPurple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(children: [
                            Container(
                                height: 5, color: _prPurple.withOpacity(0.10)),
                            AnimatedBuilder(
                              animation: _shimmerAnim,
                              builder: (_, __) => FractionallySizedBox(
                                widthFactor: moodPct,
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: LinearGradient(colors: [
                                      _prPurple.withOpacity(0.7),
                                      _prPink,
                                      Colors.white.withOpacity(0.25 *
                                          math.sin(
                                              _shimmerAnim.value * math.pi)),
                                    ]),
                                    boxShadow: [
                                      BoxShadow(
                                          color: _prPurple.withOpacity(
                                              0.45 * _glowAnim.value),
                                          blurRadius: 6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                // Milestones
                Text('Milestones',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: milestones.map((m) {
                    final achieved = m.$1;
                    final label = m.$2;
                    final mEmoji = m.$3;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: achieved
                            ? _prPurple.withOpacity(0.22)
                            : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: achieved
                              ? _prPurple.withOpacity(0.60)
                              : Colors.white.withOpacity(0.10),
                          width: achieved ? 1.5 : 1,
                        ),
                        boxShadow: achieved
                            ? [
                                BoxShadow(
                                    color: _prPurple.withOpacity(0.22),
                                    blurRadius: 10)
                              ]
                            : null,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(achieved ? mEmoji : '○',
                            style: TextStyle(
                                fontSize: achieved ? 13 : 10,
                                color: Colors.white.withOpacity(0.30))),
                        const SizedBox(width: 6),
                        Text(label,
                            style: TextStyle(
                              color: achieved
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.40),
                              fontSize: 11,
                              fontWeight:
                                  achieved ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ]),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  THEME SELECTOR
  // ──────────────────────────────────────────────────────────
  Widget _themeSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('App Theme',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 14),
              Row(
                children: List.generate(4, (i) {
                  final selected = _selectedTheme == i;
                  final t = _kThemes[i];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTheme = i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [t[0], t[1]]),
                          border: Border.all(
                            color: selected
                                ? Colors.white.withOpacity(0.8)
                                : Colors.white.withOpacity(0.12),
                            width: selected ? 2 : 1,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                      color: t[0].withOpacity(0.50),
                                      blurRadius: 14,
                                      spreadRadius: 1),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_kThemeEmojis[i],
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(height: 5),
                            Text(_kThemeNames[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(selected ? 1.0 : 0.55),
                                  fontSize: 9,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  height: 1.3,
                                )),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  WELLNESS GOALS CARD
  // ──────────────────────────────────────────────────────────
  Widget _wellnessGoalsCard(AppProvider appProvider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
          ),
          child: Column(
            children: [
              // Water goal
              _goalTile(
                '💧',
                'Daily Water Goal',
                '${appProvider.waterGoal} glasses',
                _prTeal,
                _waterGoalOpen,
                () => setState(() => _waterGoalOpen = !_waterGoalOpen),
              ),
              if (_waterGoalOpen) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Goal: $_localWaterGoal glasses',
                              style: TextStyle(
                                  color: _prTeal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          GestureDetector(
                            onTap: () async {
                              await appProvider.setWaterGoal(_localWaterGoal);
                              setState(() => _waterGoalOpen = false);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: _prTeal.withOpacity(0.18),
                                border: Border.all(
                                    color: _prTeal.withOpacity(0.45), width: 1),
                              ),
                              child: Text('Save',
                                  style: TextStyle(
                                      color: _prTeal,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _prTeal,
                          inactiveTrackColor: _prTeal.withOpacity(0.18),
                          thumbColor: _prTeal,
                          overlayColor: _prTeal.withOpacity(0.18),
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 9),
                        ),
                        child: Slider(
                          value: _localWaterGoal.toDouble(),
                          min: 4,
                          max: 16,
                          divisions: 12,
                          onChanged: (v) =>
                              setState(() => _localWaterGoal = v.round()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              _divider(),
              // Sleep goal
              _goalTile(
                '🌙',
                'Daily Sleep Goal',
                '${appProvider.sleepGoal.toStringAsFixed(1)}h',
                _prIndigo,
                _sleepGoalOpen,
                () => setState(() => _sleepGoalOpen = !_sleepGoalOpen),
              ),
              if (_sleepGoalOpen) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Goal: ${_localSleepGoal.toStringAsFixed(1)}h',
                              style: TextStyle(
                                  color: _prIndigo,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          GestureDetector(
                            onTap: () async {
                              await appProvider.setSleepGoal(_localSleepGoal);
                              setState(() => _sleepGoalOpen = false);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: _prIndigo.withOpacity(0.18),
                                border: Border.all(
                                    color: _prIndigo.withOpacity(0.45),
                                    width: 1),
                              ),
                              child: Text('Save',
                                  style: TextStyle(
                                      color: _prIndigo,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _prIndigo,
                          inactiveTrackColor: _prIndigo.withOpacity(0.18),
                          thumbColor: _prIndigo,
                          overlayColor: _prIndigo.withOpacity(0.18),
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 9),
                        ),
                        child: Slider(
                          value: _localSleepGoal,
                          min: 4,
                          max: 12,
                          divisions: 16,
                          onChanged: (v) => setState(() => _localSleepGoal = v),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              _divider(),
              // Pregnancy mode toggle
              _toggleTile(
                '🤰',
                'Pregnancy Mode',
                'Tailors cycle tracking & insights',
                _prPink,
                appProvider.pregnancyMode,
                (v) => appProvider.setPregnancyMode(v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalTile(String emoji, String label, String value, Color color,
      bool open, VoidCallback onTap) {
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          AnimatedRotation(
            turns: open ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.25), size: 14),
          ),
        ]),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  SETTINGS CARD — categorised with real toggles
  // ──────────────────────────────────────────────────────────
  Widget _settingsCard(AppProvider appProvider) {
    return Column(children: [
      // Notifications
      _settingsGroup(
        title: 'Notifications',
        icon: '🔔',
        child: _toggleTile(
          '⏰',
          'Daily Reminders',
          appProvider.remindersEnabled
              ? 'Enabled — ${appProvider.reminderHour.toString().padLeft(2, '0')}:${appProvider.reminderMinute.toString().padLeft(2, '0')}'
              : 'Tap to enable',
          _prTeal,
          appProvider.remindersEnabled,
          (v) => appProvider.setReminderEnabled(v),
        ),
      ),
      const SizedBox(height: 12),
      // Account
      _settingsGroup(
        title: 'Account',
        icon: '👤',
        child: Column(children: [
          _accessTile('📧', 'Manage Account', _prPurple, () {}),
          _divider(),
          _accessTile('📊', 'Mood Analytics', _prPink, () {}),
          _divider(),
          _accessTile('📖', 'Journal History', _prIndigo, () {}),
          _divider(),
          _accessTile('🩸', 'Period History', _prPurple, () {}),
        ]),
      ),
      const SizedBox(height: 12),
      // Privacy + AI
      _settingsGroup(
        title: 'Privacy & AI',
        icon: '🔒',
        child: Column(children: [
          _accessTile('🤖', 'AI Personality Settings', _prGold, () {}),
          _divider(),
          _accessTile('🔒', 'Data & Privacy', _prIndigo, () {}),
          _divider(),
          _accessTile('📤', 'Export My Data', _prTeal, () {}),
        ]),
      ),
    ]);
  }

  Widget _settingsGroup({
    required String title,
    required String icon,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.09), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(children: [
                  Text(icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 7),
                  Text(title,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ]),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: child,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleTile(String emoji, String label, String sub, Color color,
      bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child:
              Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text(sub,
                style: TextStyle(
                    color: color.withOpacity(0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(!value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              width: 46,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: value
                    ? color.withOpacity(0.35 + 0.15 * _glowAnim.value)
                    : Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: value
                      ? color.withOpacity(0.7)
                      : Colors.white.withOpacity(0.18),
                  width: 1.5,
                ),
                boxShadow: value
                    ? [
                        BoxShadow(
                            color: color.withOpacity(0.30 * _glowAnim.value),
                            blurRadius: 8)
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value ? color : Colors.white.withOpacity(0.40),
                      boxShadow: [
                        BoxShadow(
                            color: (value ? color : Colors.white)
                                .withOpacity(0.35),
                            blurRadius: 6)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
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

  // ──────────────────────────────────────────────────────────
  //  LOGOUT BUTTON
  // ──────────────────────────────────────────────────────────
  Widget _logoutButton() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => GestureDetector(
        onTap: _loggingOut ? null : _handleLogout,
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
          child: _loggingOut
              ? const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFAB5CF2),
                    ),
                  ),
                )
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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

  // ──────────────────────────────────────────────────────────
  //  HELPERS
  // ──────────────────────────────────────────────────────────
  Widget _divider() => Container(
        height: 1,
        color: Colors.white.withOpacity(0.07),
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
//  DATA MODELS
// ═══════════════════════════════════════════════════════════

class _StatItem {
  final String emoji, label, value;
  final Color color;
  final double pct;
  const _StatItem(this.emoji, this.label, this.value, this.color, this.pct);
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
  const _PrStarPainter({required this.stars, required this.progress});

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
  final List<Color> theme;
  const _PrBackground({required this.size, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.45),
          radius: 1.3,
          colors: [theme[0], theme[1], theme[2]],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -80, left: -60, child: _blob(300, _prPurple, 0.18)),
        Positioned(top: 90, right: -70, child: _blob(240, _prPink, 0.14)),
        Positioned(
            top: size.height * 0.40,
            left: size.width * 0.5 - 120,
            child: _blob(240, _prIndigo, 0.10)),
        Positioned(bottom: 80, left: -50, child: _blob(260, _prIndigo, 0.12)),
        Positioned(bottom: 0, right: -40, child: _blob(200, _prPink, 0.09)),
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
