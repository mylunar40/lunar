import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/lunar_data_provider.dart';
import 'core/providers/chat_provider.dart';
import 'core/providers/community_provider.dart';
import 'core/data/local_cache.dart';
import 'screen/home_dashboard.dart';
import 'screen/calendar_screen.dart';
import 'screen/community_screen.dart';
import 'screen/pregnancy_screen.dart';
import 'screen/ai_voice_screen.dart';
import 'screen/profile_screen.dart';
import 'screen/auth/welcome_screen.dart';
import 'screen/splash/lunar_splash_screen.dart';
import 'screen/onboarding/onboarding_flow.dart';
import 'user_provider.dart';

// ── TEMPORARY DEV BYPASS — set false before release ────────
// ignore: constant_identifier_names
const bool isDevelopmentMode = false;

// ── Lunar global design tokens ────────────────────────────
const Color kLunarBg = Color(0xFF0A0118);
const Color kLunarPurple = Color(0xFFAB5CF2);
const Color kLunarPink = Color(0xFFFF69B4);
const Color kLunarDeep = Color(0xFF5C2DB8);
const Color kLunarGold = Color(0xFFFFD700);
const Color kLunarWarm = Color(0xFFFFB74D);
const Color kLunarSurface = Color(0xFF160330);
const Color kLunarIndigo = Color(0xFF7986CB);
const Color kLunarTeal = Color(0xFF4FC3F7);
const Color kLunarGreen = Color(0xFF66BB6A);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0120),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ── Local cache init (always) ──────────────────────────────
  await LocalCache.init();

  // ── Firebase Init (gracefully handled if not yet configured) ──
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Crashlytics — only in release builds
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
    debugPrint('[Lunar] Firebase initialised successfully.');
  } catch (e) {
    // App runs in demo/offline mode when Firebase is not configured.
    // Run `flutterfire configure` and replace firebase_options.dart to enable.
    debugPrint('[Lunar] Firebase not configured — running in demo mode.\n$e');
  }

  // ── Lunar data (pre-loaded from cache) ─────────────────────
  final lunarData = LunarDataProvider();
  await lunarData.init();

  // ── App state provider (pre-loaded from cache) ─────────────
  final appProvider = AppProvider();
  await appProvider.init();

  // ── Chat / AI provider (pre-loaded from cache) ──────────────
  final chatProvider = ChatProvider();
  await chatProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LunarAuthProvider()),
        ChangeNotifierProvider<LunarDataProvider>.value(
            value: lunarData),
        ChangeNotifierProvider<AppProvider>.value(value: appProvider),
        ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
      ],
      child: const LunarApp(),
    ),
  );
}

class LunarApp extends StatelessWidget {
  const LunarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lunar',
      theme: ThemeData(
        scaffoldBackgroundColor: kLunarBg,
        colorScheme: const ColorScheme.dark(
          primary: kLunarPurple,
          secondary: kLunarPink,
          surface: kLunarSurface,
        ),
        fontFamily: 'Roboto',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: Consumer2<LunarAuthProvider, AppProvider>(
        builder: (context, auth, app, _) {
          Widget child;
          // ── DEV BYPASS: skip auth + onboarding entirely ──────
          if (isDevelopmentMode) {
            child = const MainNavigation(key: ValueKey('main'));
          } else if (auth.isLoading) {
            child = const LunarSplashScreen(key: ValueKey('splash'));
          } else if (!auth.isAuthenticated) {
            child = const WelcomeScreen(key: ValueKey('welcome'));
          } else if (!app.onboardingComplete) {
            child = const OnboardingFlow(key: ValueKey('onboarding'));
          } else {
            child = const MainNavigation(key: ValueKey('main'));
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 550),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: child,
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MAIN NAVIGATION  — Lunar AI-Centered Premium Ecosystem
// ═══════════════════════════════════════════════════════════
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // 0=Community  1=Calendar  2=LunarAI  3=Pregnancy  4=Home
  int _currentIndex = 4;

  static const List<Widget> _screens = [
    CommunityScreen(),  // 0 — Community
    CalendarScreen(),   // 1 — Calendar
    AIVoiceScreen(),    // 2 — Lunar AI  ★ center identity
    PregnancyScreen(),  // 3 — Pregnancy
    HomeDashboard(),    // 4 — Home (default)
  ];

  void _onTap(int i) {
    if (i == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLunarBg,
      body: Stack(
        children: [
          // ── Page with smooth fade + float transition ──────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 340),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: CurvedAnimation(
                  parent: anim, curve: Curves.easeOut),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.035),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: _screens[_currentIndex],
            ),
          ),
          // ── DEV badge ─────────────────────────────────────
          if (isDevelopmentMode)
            const Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(top: 6, right: 10),
                  child: _DevModeBadge(),
                ),
              ),
            ),
          // ── Floating profile avatar — always top-right ────
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 16),
                child: _FloatingProfileAvatar(),
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _LunarPremiumNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  DEV MODE BADGE
// ─────────────────────────────────────────────────────────
class _DevModeBadge extends StatelessWidget {
  const _DevModeBadge();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.92),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Text(
          'DEV MODE',
          style: TextStyle(
            color: Colors.black,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  FLOATING PROFILE AVATAR  (top-right, always visible)
// ─────────────────────────────────────────────────────────
class _FloatingProfileAvatar extends StatefulWidget {
  const _FloatingProfileAvatar();
  @override
  State<_FloatingProfileAvatar> createState() =>
      _FloatingProfileAvatarState();
}

class _FloatingProfileAvatarState extends State<_FloatingProfileAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _ring = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _showMenu(BuildContext ctx) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ProfileMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: AnimatedBuilder(
        animation: _ring,
        builder: (_, child) => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [kLunarPurple, kLunarPink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: kLunarPurple.withOpacity(0.60 * _ring.value),
                blurRadius: 20 * _ring.value,
                spreadRadius: 2 * _ring.value,
              ),
              BoxShadow(
                color: kLunarPink.withOpacity(0.28 * _ring.value),
                blurRadius: 12,
              ),
            ],
          ),
          child: child,
        ),
        child: const Icon(
            Icons.person_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PROFILE MENU BOTTOM SHEET
// ─────────────────────────────────────────────────────────
class _ProfileMenuSheet extends StatelessWidget {
  const _ProfileMenuSheet();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            color: const Color(0xFF0D0120).withOpacity(0.94),
            border: Border.all(
                color: kLunarPurple.withOpacity(0.30), width: 1),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(context).padding.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kLunarPurple.withOpacity(0.40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Lunar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your personal wellness space',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.50),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              _menuTile(
                context,
                Icons.person_rounded,
                'Profile',
                kLunarPurple,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                      context, _lunarFadeRoute(const ProfileScreen()));
                },
              ),
              _menuTile(
                context,
                Icons.settings_rounded,
                'Settings',
                kLunarIndigo,
                () => Navigator.pop(context),
              ),
              _menuTile(
                context,
                Icons.auto_awesome,
                'Lunar Premium',
                kLunarGold,
                () => Navigator.pop(context),
              ),
              _menuTile(
                context,
                Icons.account_circle_outlined,
                'Account',
                kLunarTeal,
                () => Navigator.pop(context),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile(BuildContext ctx, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.08),
          border:
              Border.all(color: color.withOpacity(0.22), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.90),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.30), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PREMIUM LUNAR NAV BAR
// ─────────────────────────────────────────────────────────
class _LunarPremiumNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _LunarPremiumNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_LunarPremiumNavBar> createState() =>
      _LunarPremiumNavBarState();
}

class _LunarPremiumNavBarState extends State<_LunarPremiumNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathe;
  late Animation<double> _breatheAnim;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 0.88, end: 1.0)
        .animate(
            CurvedAnimation(parent: _breathe, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.transparent,
      height: 96 + bottom,
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottom + 8),
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: kLunarPurple.withOpacity(0.26),
                blurRadius: 38,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.48),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  color: const Color(0xFF0D0120).withOpacity(0.90),
                  border: Border.all(
                    color: kLunarPurple.withOpacity(0.28),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Community (0) ─────────────────────
                    _NavTile(
                      icon: Icons.people_alt_rounded,
                      inactiveIcon: Icons.people_alt_outlined,
                      label: 'Community',
                      color: kLunarPurple,
                      isActive: widget.currentIndex == 0,
                      onTap: () => widget.onTap(0),
                    ),
                    // ── Calendar (1) ──────────────────────
                    _NavTile(
                      icon: Icons.calendar_month_rounded,
                      inactiveIcon: Icons.calendar_month_outlined,
                      label: 'Calendar',
                      color: kLunarIndigo,
                      isActive: widget.currentIndex == 1,
                      onTap: () => widget.onTap(1),
                    ),
                    // ── CENTER: Lunar AI Orb (2) ──────────
                    _LunarAIOrbButton(
                      isActive: widget.currentIndex == 2,
                      breatheAnim: _breatheAnim,
                      onTap: () => widget.onTap(2),
                    ),
                    // ── Pregnancy (3) ─────────────────────
                    _NavTile(
                      icon: Icons.favorite_rounded,
                      inactiveIcon: Icons.favorite_border_rounded,
                      label: 'Pregnancy',
                      color: kLunarPink,
                      isActive: widget.currentIndex == 3,
                      onTap: () => widget.onTap(3),
                    ),
                    // ── Home (4) ──────────────────────────
                    _NavTile(
                      icon: Icons.home_rounded,
                      inactiveIcon: Icons.home_outlined,
                      label: 'Home',
                      color: kLunarTeal,
                      isActive: widget.currentIndex == 4,
                      onTap: () => widget.onTap(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  NAV TILE  (regular 4 items)
// ─────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData icon, inactiveIcon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.inactiveIcon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.26),
                    color.withOpacity(0.10),
                  ],
                ),
                border: Border.all(
                    color: color.withOpacity(0.44), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.26),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isActive ? icon : inactiveIcon,
                key: ValueKey(isActive),
                color: isActive
                    ? color
                    : Colors.white.withOpacity(0.34),
                size: isActive ? 25 : 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive
                    ? color
                    : Colors.white.withOpacity(0.34),
                fontSize: isActive ? 9.5 : 9.0,
                fontWeight: isActive
                    ? FontWeight.w700
                    : FontWeight.w400,
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: isActive ? 4 : 0,
              height: isActive ? 4 : 0,
              margin: EdgeInsets.only(top: isActive ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.9),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  LUNAR AI ORB BUTTON  (center identity)
// ─────────────────────────────────────────────────────────
class _LunarAIOrbButton extends StatelessWidget {
  final bool isActive;
  final Animation<double> breatheAnim;
  final VoidCallback onTap;

  const _LunarAIOrbButton({
    required this.isActive,
    required this.breatheAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: breatheAnim,
        builder: (_, child) {
          final scale = isActive
              ? breatheAnim.value
              : 0.90 + (breatheAnim.value - 0.90).clamp(0.0, 0.08);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 66,
              height: 66,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isActive
                      ? [
                          const Color(0xFFE040FB),
                          kLunarPurple,
                          kLunarDeep,
                        ]
                      : [
                          const Color(0xFF9C27B0),
                          const Color(0xFF5C2DB8),
                          const Color(0xFF180336),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: kLunarPurple.withOpacity(
                        isActive ? 0.82 : 0.48),
                    blurRadius: isActive ? 34 : 20,
                    spreadRadius: isActive ? 5 : 2,
                  ),
                  BoxShadow(
                    color: kLunarPink
                        .withOpacity(isActive ? 0.48 : 0.20),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: Colors.black38,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white
                      .withOpacity(isActive ? 0.36 : 0.14),
                  width: 1.5,
                ),
              ),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.white
                  .withOpacity(isActive ? 1.0 : 0.72),
              size: isActive ? 26 : 22,
            ),
            const SizedBox(height: 1),
            Text(
              'Lunar AI',
              style: TextStyle(
                color: Colors.white
                    .withOpacity(isActive ? 1.0 : 0.62),
                fontSize: 8.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  ROUTE HELPERS
// ─────────────────────────────────────────────────────────
Route<T> _lunarFadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity:
            CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
