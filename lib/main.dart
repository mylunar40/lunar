import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screen/home_dashboard.dart';
import 'screen/calendar_screen.dart';
import 'screen/health_screen.dart';
import 'screen/ai_voice_screen.dart';
import 'screen/profile_screen.dart';
import 'user_provider.dart';
import 'package:provider/provider.dart';

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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0120),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
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
      home: const MainNavigation(),
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
      body: _screens[_currentIndex],
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
//  LUNAR BOTTOM NAV BAR
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72 + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
            left: 8,
            right: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0120).withOpacity(0.92),
            border: const Border(
              top: BorderSide(color: Color(0x28AB5CF2), width: 1),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: active
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [
                              kLunarPurple.withOpacity(0.28),
                              kLunarPink.withOpacity(0.14),
                            ],
                          ),
                          border: Border.all(
                              color: kLunarPurple.withOpacity(0.45), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: kLunarPurple.withOpacity(0.22),
                              blurRadius: 16,
                              spreadRadius: 1,
                            )
                          ],
                        )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: child,
                        ),
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
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
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
    );
  }
}
