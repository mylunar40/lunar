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
import 'core/providers/memory_provider.dart';
import 'core/providers/weather_provider.dart';
import 'core/providers/community_provider.dart';
import 'core/providers/community_activity_provider.dart';
import 'core/providers/avatar_provider.dart';
import 'core/providers/connection_provider.dart';
import 'models/avatar_model.dart';
import 'widgets/lunar_avatar_widget.dart';
import 'core/data/local_cache.dart';
import 'core/services/fcm_service.dart';
import 'core/services/subscription_service.dart';
import 'core/providers/premium_provider.dart';
import 'screen/home_dashboard.dart';
import 'screen/glow_screen.dart';
import 'screen/community_tabs_screen.dart';
import 'screen/pregnancy_screen.dart';
import 'screen/ai_voice_screen.dart';
import 'screen/profile_screen.dart';
import 'screen/auth/welcome_screen.dart';
import 'screen/auth/email_verification_screen.dart';
import 'screen/splash/lunar_splash_screen.dart';
import 'screen/onboarding/onboarding_flow.dart';
import 'screen/onboarding/intent_selection_screen.dart';
import 'core/providers/check_in_provider.dart';
import 'user_provider.dart';

// ── TEMPORARY DEV BYPASS — set false before release ────────
// ignore: constant_identifier_names
const bool isDevelopmentMode = false;

// ── TEMPORARY DEV BYPASS — Email Verification (set true before Beta launch) ────────
// ignore: constant_identifier_names
const bool kRequireEmailVerification = false;

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
// ── Navigator key (shared with FCMService for in-app banners) ──────
final _navigatorKey = GlobalKey<NavigatorState>();
// ── Navigator observer for avatar visibility ──────────────
final _avatarObserver = _LunarAvatarObserver();

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
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    debugPrint('[Lunar] Firebase initialised successfully.');
    // FCM: set up background handler, request permissions, init listeners
    await FCMService.init();
    // RevenueCat — must init after Firebase, before any purchase call
    await SubscriptionService.init();
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

  // ── Memory provider (pre-loaded from local cache) ──────────
  final memoryProvider = MemoryProvider();
  await memoryProvider.init();
  // ── Weather provider (pre-loaded from local cache) ─────
  final weatherProvider = WeatherProvider();
  await weatherProvider.init();

  // ── CheckIn provider (pre-loaded from cache) ───────────────
  final checkInProvider = CheckInProvider();
  await checkInProvider.init();

  // ── Wire UserProvider → LunarDataProvider sync bridge ──────
  // UserProvider is legacy. This bridge ensures any screen that still calls
  // userProvider.updatePeriodDate() also propagates the change into
  // LunarDataProvider, eliminating split-brain cycle state.
  final userProviderInstance = UserProvider()
    ..attachLunarDataProvider(lunarData);

  // ── PremiumProvider — created upfront so RC listener can reference it ──
  final premiumProvider = PremiumProvider();

  // ── Wire RC → PremiumProvider: no app restart required ────
  // Fires after every purchase, restore, subscription expiry, or
  // grace-period change. Updates the provider in-place.
  SubscriptionService.addCustomerInfoListener(
    (tier) => premiumProvider.updateFromRevenueCat(tier),
  );

  // Give FCMService the navigator key BEFORE runApp so that the
  // getInitialMessage handler (called inside FCMService.init()) has a
  // valid key reference if a notification launches the app from terminated state.
  FCMService.navigatorKey = _navigatorKey;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: userProviderInstance),
        ChangeNotifierProvider(create: (_) => LunarAuthProvider()),
        ChangeNotifierProvider<LunarDataProvider>.value(value: lunarData),
        ChangeNotifierProvider<AppProvider>.value(value: appProvider),
        // ChatProvider syncs Firestore uid whenever auth state changes
        ChangeNotifierProxyProvider<LunarAuthProvider, ChatProvider>(
          create: (_) => chatProvider,
          update: (_, auth, chat) {
            if (auth.isAuthenticated && !auth.isGuest) {
              chat!.setUser(auth.firebaseUser?.uid);
            }
            return chat!;
          },
        ),
        // MemoryProvider syncs Firestore uid whenever auth state changes
        ChangeNotifierProxyProvider<LunarAuthProvider, MemoryProvider>(
          create: (_) => memoryProvider,
          update: (_, auth, memory) {
            if (auth.isAuthenticated && !auth.isGuest) {
              memory!.setUser(auth.firebaseUser?.uid);
            }
            return memory!;
          },
        ),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProxyProvider<LunarAuthProvider,
            CommunityActivityProvider>(
          create: (_) => CommunityActivityProvider(),
          update: (_, auth, activity) {
            activity!.load(auth.isAuthenticated && !auth.isGuest
                ? auth.firebaseUser?.uid
                : null);
            return activity;
          },
        ),
        ChangeNotifierProvider(create: (_) => AvatarProvider()),
        // ConnectionProvider — loads/resets when auth state changes
        ChangeNotifierProxyProvider<LunarAuthProvider, ConnectionProvider>(
          create: (_) => ConnectionProvider(),
          update: (_, auth, conn) {
            final uid = auth.firebaseUser?.uid;
            if (uid != null && auth.isAuthenticated && !auth.isGuest) {
              conn!.load(uid);
            } else {
              conn!.reset();
            }
            return conn;
          },
        ),
        ChangeNotifierProvider<WeatherProvider>.value(value: weatherProvider),
        // CheckInProvider — syncs Firestore uid when auth changes
        ChangeNotifierProxyProvider<LunarAuthProvider, CheckInProvider>(
          create: (_) => checkInProvider,
          update: (_, auth, ci) {
            ci!.setUser(auth.isAuthenticated && !auth.isGuest
                ? auth.firebaseUser?.uid
                : null);
            return ci;
          },
        ),
        // PremiumProvider — proxied from LunarAuthProvider so it updates
        // whenever the user model is refreshed from Firestore.
        // RC listener above also feeds into it directly.
        ChangeNotifierProxyProvider<LunarAuthProvider, PremiumProvider>(
          create: (_) => premiumProvider,
          update: (_, auth, premium) {
            premium!.updateFromAuth(auth);
            return premium;
          },
        ),
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
      navigatorKey: _navigatorKey,
      navigatorObservers: [_avatarObserver],
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
            // Firebase auth state is loading — show splash
            child = const LunarSplashScreen(key: ValueKey('splash'));
          } else if (auth.isDemoMode) {
            // Firebase unavailable — run in local demo mode (read-only, no auth)
            child = const MainNavigation(key: ValueKey('main'));
          } else if (!auth.isAuthenticated) {
            // Not logged in — show login
            child = const WelcomeScreen(key: ValueKey('welcome'));
          } else if (kRequireEmailVerification &&
              !auth.isEmailVerified &&
              !auth.isGuest) {
            // Email accounts must verify before accessing the app.
            // [kRequireEmailVerification] = false bypasses this screen for development.
            // Google / anonymous accounts are pre-verified (emailVerified == true).
            child = const EmailVerificationScreen(key: ValueKey('verify'));
          } else if (!auth.hasCompletedOnboarding && !auth.isGuest) {
            // Logged in but onboarding not complete — resume onboarding
            // Source of truth: Firestore user model (cross-device persistent)
            child = const OnboardingFlow(key: ValueKey('onboarding'));
          } else if (!auth.hasCompletedIntentOnboarding && !auth.isGuest) {
            // Logged in + onboarding complete, but intent not selected yet
            child = const IntentSelectionScreen(key: ValueKey('intent'));
          } else {
            // Logged in + onboarding complete + intent selected → home
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
  // 0=Community  1=Glow  2=LunarAI  3=Pregnancy  4=Home
  int _currentIndex = 4;

  static const List<Widget> _screens = [
    CommunityTabsScreen(), // 0 — Community
    GlowScreen(), // 1 — Glow
    AIVoiceScreen(), // 2 — Lunar AI  ★ center identity
    PregnancyScreen(), // 3 — Pregnancy
    HomeDashboard(), // 4 — Home (default)
  ];

  void _onTap(int i) {
    if (i == 0) {
      HapticFeedback.selectionClick();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const CommunityTabsScreen(),
        ),
      );
      return;
    }
    if (i == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = i);
    // Avatar only on Home Dashboard (index 4)
    _avatarObserver.onTabChanged(i);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back from closing the app when on any non-Home tab
      canPop: _currentIndex == 4,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Back pressed on any non-Home tab → go to Home, no state reset
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = 4);
          _avatarObserver.onTabChanged(4);
        }
      },
      child: Scaffold(
        backgroundColor: kLunarBg,
        body: Stack(
          children: [
            // ── IndexedStack keeps all screens alive — no state reset on tab switch ──
            IndexedStack(
              index: _currentIndex,
              children: _screens,
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
            // ── Floating profile avatar — main tabs only ────
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 16),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _avatarObserver.showAvatar,
                    builder: (_, visible, child) => AnimatedOpacity(
                      opacity: visible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: IgnorePointer(
                        ignoring: !visible,
                        child: child,
                      ),
                    ),
                    child: const _FloatingProfileAvatar(),
                  ),
                ),
              ),
            ),
          ],
        ),
        extendBody:
            _currentIndex == 1 || _currentIndex == 2 || _currentIndex == 3,
        bottomNavigationBar:
            (_currentIndex == 2 || _currentIndex == 1 || _currentIndex == 3)
                ? null
                : Consumer<ConnectionProvider>(
                    builder: (_, cp, __) => _LunarPremiumNavBar(
                      currentIndex: _currentIndex,
                      onTap: _onTap,
                      connectionBadge: cp.incomingCount,
                    ),
                  ),
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
  State<_FloatingProfileAvatar> createState() => _FloatingProfileAvatarState();
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
    // Trigger avatar load on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<LunarAuthProvider>();
      final ap = context.read<AvatarProvider>();
      if (auth.isAuthenticated && !ap.hasAvatar && !ap.loading) {
        ap.load(auth);
      }
    });
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
    final av = context.watch<AvatarProvider>().avatar;
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: AnimatedBuilder(
        animation: _ring,
        builder: (_, child) => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: av == null
                ? const LinearGradient(
                    colors: [kLunarPurple, kLunarPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: av != null ? const Color(0xFF160330) : null,
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
        child: ClipOval(
          child: av != null
              ? LunarAvatarWidget(
                  avatar: av,
                  size: 44,
                  animate: false,
                  showAura: false,
                )
              : const Icon(Icons.person_rounded, color: Colors.white, size: 22),
        ),
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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            color: const Color(0xFF0D0120).withOpacity(0.94),
            border: Border.all(color: kLunarPurple.withOpacity(0.30), width: 1),
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

  Widget _menuTile(BuildContext ctx, IconData icon, String label, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.22), width: 1),
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
  final int connectionBadge;

  const _LunarPremiumNavBar({
    required this.currentIndex,
    required this.onTap,
    this.connectionBadge = 0,
  });

  @override
  State<_LunarPremiumNavBar> createState() => _LunarPremiumNavBarState();
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
        .animate(CurvedAnimation(parent: _breathe, curve: Curves.easeInOut));
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
                color: kLunarPurple.withOpacity(0.16),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.38),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
                      badge: widget.connectionBadge,
                      onTap: () => widget.onTap(0),
                    ),
                    // ── Glow (1) ──────────────────────────
                    _NavTile(
                      icon: Icons.auto_awesome_rounded,
                      inactiveIcon: Icons.auto_awesome_outlined,
                      label: 'Glow',
                      color: kLunarPurple,
                      isActive: widget.currentIndex == 1,
                      onTap: () => widget.onTap(1),
                    ),
                    // ── CENTER: Lunar AI Orb (2) ──────────
                    _LunarAIOrbButton(
                      isActive: widget.currentIndex == 2,
                      breatheAnim: _breatheAnim,
                      onTap: () => widget.onTap(2),
                    ),
                    // ── Bloom (3) ────────────────────────
                    _NavTile(
                      icon: Icons.favorite_rounded,
                      inactiveIcon: Icons.favorite_border_rounded,
                      label: 'Bloom',
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
  final int badge;

  const _NavTile({
    required this.icon,
    required this.inactiveIcon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.26),
                    color.withOpacity(0.10),
                  ],
                ),
                border: Border.all(color: color.withOpacity(0.44), width: 1),
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? icon : inactiveIcon,
                    key: ValueKey(isActive),
                    color: isActive ? color : Colors.white.withOpacity(0.34),
                    size: isActive ? 25 : 22,
                  ),
                  if (badge > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF69B4),
                        ),
                        child: Center(
                          child: Text(
                            badge > 9 ? '9+' : '$badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive ? color : Colors.white.withOpacity(0.34),
                fontSize: isActive ? 9.5 : 9.0,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
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
                    color: kLunarPurple.withOpacity(isActive ? 0.82 : 0.48),
                    blurRadius: isActive ? 34 : 20,
                    spreadRadius: isActive ? 5 : 2,
                  ),
                  BoxShadow(
                    color: kLunarPink.withOpacity(isActive ? 0.48 : 0.20),
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
                  color: Colors.white.withOpacity(isActive ? 0.36 : 0.14),
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
              color: Colors.white.withOpacity(isActive ? 1.0 : 0.72),
              size: isActive ? 26 : 22,
            ),
            const SizedBox(height: 1),
            Text(
              'Lunar AI',
              style: TextStyle(
                color: Colors.white.withOpacity(isActive ? 1.0 : 0.62),
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
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );

// ─────────────────────────────────────────────────────────
//  AVATAR VISIBILITY OBSERVER
// ─────────────────────────────────────────────────────────
/// Tracks Navigator route depth to show/hide the floating
/// profile avatar — visible only on the 5 main tab screens.
class _LunarAvatarObserver extends NavigatorObserver {
  final showAvatar = ValueNotifier<bool>(true);
  int _depth = 0;
  // Avatar visible only on Home Dashboard tab (index 4)
  bool _onHomeTab = true;

  void onTabChanged(int tabIndex) {
    _onHomeTab = tabIndex == 4;
    _update();
  }

  void _update() {
    showAvatar.value = _depth == 0 && _onHomeTab;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _depth++;
      _update();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_depth > 0) {
      _depth--;
      _update();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_depth > 0) {
      _depth--;
      _update();
    }
  }
}
