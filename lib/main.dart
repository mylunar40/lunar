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
import 'core/data/local_cache.dart';
import 'screen/home_dashboard.dart';
import 'screen/calendar_screen.dart';
import 'screen/health_screen.dart';
import 'screen/ai_voice_screen.dart';
import 'screen/profile_screen.dart';
import 'screen/auth/welcome_screen.dart';
import 'screen/splash/lunar_splash_screen.dart';
import 'screen/onboarding/onboarding_flow.dart';
import 'user_provider.dart';

// ── TEMPORARY DEV BYPASS — set false before release ────────
// ignore: constant_identifier_names
const bool isDevelopmentMode = true;

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

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _tabAnim;

  static const List<Widget> _screens = [
    HomeDashboard(),
    CalendarScreen(),
    HealthScreen(),
    AIVoiceScreen(),
    ProfileScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem(Icons.calendar_month_rounded, Icons.calendar_month_outlined,
        'Calendar'),
    _NavItem(Icons.favorite_rounded, Icons.favorite_border_rounded, 'Health'),
    _NavItem(Icons.auto_awesome, Icons.auto_awesome_outlined, 'AI'),
    _NavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _tabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _tabAnim.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (i == _currentIndex) return;
    HapticFeedback.selectionClick();
    _tabAnim.forward(from: 0);
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLunarBg,
      body: isDevelopmentMode
          ? Stack(
              children: [
                _screens[_currentIndex],
                // ── DEV MODE badge — remove when isDevelopmentMode = false ──
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
              ],
            )
          : _screens[_currentIndex],
      extendBody: true,
      bottomNavigationBar: _LunarNavBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: _onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  DEV MODE BADGE  (visible only when isDevelopmentMode = true)
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
//  LUNAR BOTTOM NAV BAR
// ─────────────────────────────────────────────────────────

// _LunarSplash replaced by LunarSplashScreen (lib/screen/splash/lunar_splash_screen.dart)

// ─────────────────────────────────────────────────────────
//  NAV ITEM DATA
// ─────────────────────────────────────────────────────────
class _NavItem {
  final IconData activeIcon, inactiveIcon;
  final String label;
  const _NavItem(this.activeIcon, this.inactiveIcon, this.label);
}

class _LunarNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  const _LunarNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.transparent,
      height: 88 + bottom,
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: kLunarPurple.withOpacity(0.22),
              blurRadius: 32,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.42),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: const Color(0xFF0D0120).withOpacity(0.88),
                border: Border.all(
                  color: kLunarPurple.withOpacity(0.34),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final active = i == currentIndex;
                  final item = items[i];
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: active
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  kLunarPurple.withOpacity(0.32),
                                  kLunarPink.withOpacity(0.16),
                                ],
                              ),
                              border: Border.all(
                                  color: kLunarPurple.withOpacity(0.52),
                                  width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: kLunarPurple.withOpacity(0.30),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                )
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
                              active ? item.activeIcon : item.inactiveIcon,
                              key: ValueKey(active),
                              color: active
                                  ? kLunarPurple
                                  : Colors.white.withOpacity(0.38),
                              size: active ? 26 : 23,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: active
                                  ? kLunarPurple
                                  : Colors.white.withOpacity(0.35),
                              fontSize: active ? 10.5 : 10,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
