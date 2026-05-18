import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/providers/lunar_data_provider.dart';
import '../../core/models/pregnancy_model.dart';
import '../../user_provider.dart';

// ── Design tokens ─────────────────────────────────────────────
const _kBg = Color(0xFF0A0118);
const _kPurple = Color(0xFFAB5CF2);
const _kPink = Color(0xFFFF69B4);
const _kGold = Color(0xFFFFD700);
const _kTeal = Color(0xFF4FC3F7);

// ══════════════════════════════════════════════════════════════
//  ONBOARDING FLOW  (7 pages)
//  Page 0 — Welcome + name
//  Page 1 — Cycle setup (last period + length)
//  Page 2 — Pregnancy selection
//  Page 3 — Wellness goals (water + sleep)
//  Page 4 — Mood preferences
//  Page 5 — Reminders
//  Page 6 — Meet Lunar AI (final CTA)
// ══════════════════════════════════════════════════════════════

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  // ── Navigation ────────────────────────────────────────────
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  static const int _totalPages = 7;
  bool _completing = false;

  // ── Animations ────────────────────────────────────────────
  late AnimationController _particleCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  // ── Particles ─────────────────────────────────────────────
  final List<_OBStar> _stars = [];
  final math.Random _rng = math.Random();

  // ── Collected data ────────────────────────────────────────
  String _name = '';
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;
  bool _isPregnant = false;
  DateTime? _dueDate;
  int _waterGoal = 8;
  double _sleepGoal = 8.0;
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  final Set<String> _selectedEmotions = {};

  // ── Page meta ─────────────────────────────────────────────
  static const _pageEmojis = [
    '🌙', '🌸', '🤱', '💜', '✨', '🔔', '🤖'
  ];
  static const _pageTitles = [
    'Welcome to Lunar',
    'Your Cycle Story',
    'Pregnancy Mode',
    'Wellness Goals',
    'Your Emotions',
    'Stay on Track',
    'Meet Lunar AI',
  ];
  static const _pageSubtitles = [
    'Your emotional wellness companion',
    'Help us personalise your journey',
    'Track your pregnancy journey',
    'Set your daily wellness targets',
    'Tell us how you feel',
    'Never miss a wellness moment',
    'Your intelligent companion is ready',
  ];

  @override
  void initState() {
    super.initState();

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 7))
      ..repeat();

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    for (int i = 0; i < 45; i++) {
      _stars.add(_OBStar(rng: _rng));
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _particleCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  //  NAVIGATION
  // ══════════════════════════════════════════════════════════

  void _next() {
    // Skip pregnancy page if not relevant
    if (_currentPage == 1 && !_isPregnant) {
      // We still show page 2 so user can choose; don't skip
    }
    if (_currentPage < _totalPages - 1) {
      HapticFeedback.lightImpact();
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      HapticFeedback.selectionClick();
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _complete() async {
    if (_completing) return;
    setState(() => _completing = true);
    HapticFeedback.heavyImpact();

    final lunarData = context.read<LunarDataProvider>();
    final appProvider = context.read<AppProvider>();
    final userProvider = context.read<UserProvider>();

    // Save name
    if (_name.trim().isNotEmpty) {
      await appProvider.setUserName(_name.trim());
    }

    // Save cycle data
    if (_lastPeriodDate != null) {
      await lunarData.logPeriodStart(
        date: _lastPeriodDate,
        cycleLength: _cycleLength,
      );
      userProvider.updatePeriodDate(_lastPeriodDate!);
      userProvider.updateCycleLength(_cycleLength);
    }

    // Save pregnancy
    if (_isPregnant && _dueDate != null) {
      lunarData.setPregnancyData(
        PregnancyData(id: 'main', dueDate: _dueDate!),
      );
      await appProvider.setPregnancyMode(true);
    }

    // Save goals
    await appProvider.setWaterGoal(_waterGoal);
    await appProvider.setSleepGoal(_sleepGoal);
    await appProvider.setReminderEnabled(_remindersEnabled);
    await appProvider.setReminderTime(
        _reminderTime.hour, _reminderTime.minute);

    // Mark onboarding done — Consumer in main.dart rebuilds
    await appProvider.completeOnboarding();
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.5,
                colors: [Color(0xFF2D0B5C), Color(0xFF18063A), _kBg],
              ),
            ),
          ),
          // Particles
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _OBStarPainter(
                    stars: _stars, progress: _particleCtrl.value),
              ),
            ),
          ),
          // Ambient glow blobs
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Stack(children: [
              Positioned(
                top: -60,
                left: -60,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _kPurple.withOpacity(0.22 * _glowAnim.value),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                right: -40,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _kPink.withOpacity(0.15 * _glowAnim.value),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ]),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Progress bar
                _buildProgressBar(),
                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) =>
                        setState(() => _currentPage = i),
                    children: [
                      _buildPage0_Welcome(),
                      _buildPage1_Cycle(),
                      _buildPage2_Pregnancy(),
                      _buildPage3_Goals(),
                      _buildPage4_Mood(),
                      _buildPage5_Reminders(),
                      _buildPage6_Final(),
                    ],
                  ),
                ),
                // Navigation buttons (all pages except last)
                if (_currentPage < _totalPages - 1)
                  _buildNavBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Row(
        children: List.generate(_totalPages, (i) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              height: 3.5,
              margin:
                  EdgeInsets.only(right: i < _totalPages - 1 ? 5 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i <= _currentPage
                    ? _kPurple
                    : Colors.white.withOpacity(0.12),
                boxShadow: i == _currentPage
                    ? [
                        BoxShadow(
                            color: _kPurple.withOpacity(0.7),
                            blurRadius: 8,
                            spreadRadius: 1)
                      ]
                    : [],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Nav buttons ───────────────────────────────────────────
  Widget _buildNavBar() {
    final isLast = _currentPage == _totalPages - 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Row(
        children: [
          // Back button
          if (_currentPage > 0)
            GestureDetector(
              onTap: _back,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.15)),
                ),
                child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16),
              ),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          // Skip link
          if (_currentPage > 0 && _currentPage < 5)
            GestureDetector(
              onTap: _next,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Text(
                  'Skip',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 13),
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Next button
          GestureDetector(
            onTap: _next,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                    colors: [_kPurple, _kPink]),
                boxShadow: [
                  BoxShadow(
                    color: _kPurple.withOpacity(0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                isLast ? 'Almost there ✨' : 'Continue →',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  PAGE 0 — WELCOME + NAME
  // ══════════════════════════════════════════════════════════

  Widget _buildPage0_Welcome() {
    return _OBPageShell(
      emoji: _pageEmojis[0],
      title: _pageTitles[0],
      subtitle: _pageSubtitles[0],
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What should I call you? 💜',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                  fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            _lunarField(
              hint: 'Your name...',
              onChanged: (v) => setState(() => _name = v),
              initialValue: _name,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            // Affirmation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _kPurple.withOpacity(0.10),
                border: Border.all(
                    color: _kPurple.withOpacity(0.20)),
              ),
              child: Text(
                '"Your body is wise. Your emotions are valid.\nYou are enough." 💜',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  PAGE 1 — CYCLE SETUP
  // ══════════════════════════════════════════════════════════

  Widget _buildPage1_Cycle() {
    return _OBPageShell(
      emoji: _pageEmojis[1],
      title: _pageTitles[1],
      subtitle: _pageSubtitles[1],
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last period date
            _sectionLabel('When did your last period start?'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _lastPeriodDate ?? DateTime.now(),
                  firstDate: DateTime.now()
                      .subtract(const Duration(days: 90)),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) =>
                      _datePickerTheme(ctx, child!),
                );
                if (picked != null && mounted) {
                  setState(() => _lastPeriodDate = picked);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: _lastPeriodDate != null
                        ? _kPurple
                        : Colors.white.withOpacity(0.20),
                    width: _lastPeriodDate != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: _lastPeriodDate != null
                          ? _kPurple
                          : Colors.white.withOpacity(0.35),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _lastPeriodDate != null
                          ? '${_lastPeriodDate!.day}/${_lastPeriodDate!.month}/${_lastPeriodDate!.year}'
                          : 'Tap to select date',
                      style: TextStyle(
                        color: _lastPeriodDate != null
                            ? Colors.white
                            : Colors.white.withOpacity(0.35),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            // Cycle length
            _sectionLabel(
                'Average cycle length: $_cycleLength days'),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _kPurple,
                inactiveTrackColor:
                    Colors.white.withOpacity(0.12),
                thumbColor: _kPurple,
                thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10),
                overlayColor: _kPurple.withOpacity(0.15),
                trackHeight: 4,
              ),
              child: Slider(
                value: _cycleLength.toDouble(),
                min: 21,
                max: 35,
                divisions: 14,
                onChanged: (v) =>
                    setState(() => _cycleLength = v.round()),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('21 days',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11)),
                Text('35 days',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You can always adjust this later 🌸',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.40),
                  fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  PAGE 2 — PREGNANCY SELECTION
  // ══════════════════════════════════════════════════════════

  Widget _buildPage2_Pregnancy() {
    return _OBPageShell(
      emoji: _pageEmojis[2],
      title: _pageTitles[2],
      subtitle: _pageSubtitles[2],
      child: _glassCard(
        child: Column(
          children: [
            // Selection cards
            Row(
              children: [
                Expanded(
                  child: _selectionCard(
                    emoji: '🌸',
                    label: 'Not pregnant',
                    selected: !_isPregnant,
                    onTap: () =>
                        setState(() => _isPregnant = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _selectionCard(
                    emoji: '🤱',
                    label: 'I\'m pregnant',
                    selected: _isPregnant,
                    onTap: () =>
                        setState(() => _isPregnant = true),
                  ),
                ),
              ],
            ),
            // Due date picker (when pregnant)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _sectionLabel('When is your due date?'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ??
                            DateTime.now()
                                .add(const Duration(days: 180)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 290)),
                        builder: (ctx, child) =>
                            _datePickerTheme(ctx, child!),
                      );
                      if (picked != null && mounted) {
                        setState(() => _dueDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: _dueDate != null
                              ? _kPink
                              : Colors.white.withOpacity(0.20),
                          width: _dueDate != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_outline_rounded,
                            color: _dueDate != null
                                ? _kPink
                                : Colors.white
                                    .withOpacity(0.35),
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _dueDate != null
                                ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                : 'Select due date',
                            style: TextStyle(
                              color: _dueDate != null
                                  ? Colors.white
                                  : Colors.white
                                      .withOpacity(0.35),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              crossFadeState: _isPregnant
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  PAGE 3 — WELLNESS GOALS
  // ══════════════════════════════════════════════════════════

  Widget _buildPage3_Goals() {
    return _OBPageShell(
      emoji: _pageEmojis[3],
      title: _pageTitles[3],
      subtitle: _pageSubtitles[3],
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Water goal
            Row(
              children: [
                const Text('💧', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily water goal',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 12.5),
                    ),
                    Text(
                      '$_waterGoal glasses',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _kTeal,
                inactiveTrackColor:
                    Colors.white.withOpacity(0.12),
                thumbColor: _kTeal,
                thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10),
                overlayColor: _kTeal.withOpacity(0.15),
                trackHeight: 4,
              ),
              child: Slider(
                value: _waterGoal.toDouble(),
                min: 4,
                max: 12,
                divisions: 8,
                onChanged: (v) =>
                    setState(() => _waterGoal = v.round()),
              ),
            ),
            const SizedBox(height: 20),
            // Sleep goal
            Row(
              children: [
                const Text('😴', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily sleep goal',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 12.5),
                    ),
                    Text(
                      '${_sleepGoal.toStringAsFixed(1)} hours',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF7986CB),
                inactiveTrackColor:
                    Colors.white.withOpacity(0.12),
                thumbColor: const Color(0xFF7986CB),
                thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10),
                overlayColor:
                    const Color(0xFF7986CB).withOpacity(0.15),
                trackHeight: 4,
              ),
              child: Slider(
                value: _sleepGoal,
                min: 5,
                max: 10,
                divisions: 10,
                onChanged: (v) =>
                    setState(() => _sleepGoal = (v * 2).round() / 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  PAGE 4 — MOOD PREFERENCES
  // ══════════════════════════════════════════════════════════

  Widget _buildPage4_Mood() {
    const emotions = [
      ('😊', 'Happy'),
      ('😌', 'Calm'),
      ('😰', 'Anxious'),
      ('😴', 'Tired'),
      ('😢', 'Emotional'),
      ('⚡', 'Energetic'),
      ('😤', 'Moody'),
      ('🌿', 'Peaceful'),
      ('💪', 'Motivated'),
      ('🌧️', 'Melancholy'),
      ('🥰', 'Loved'),
      ('😤', 'Frustrated'),
    ];

    return _OBPageShell(
      emoji: _pageEmojis[4],
      title: _pageTitles[4],
      subtitle: _pageSubtitles[4],
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select all that apply to you 💜',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emotions.map((e) {
                final selected =
                    _selectedEmotions.contains(e.$2);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (selected) {
                        _selectedEmotions.remove(e.$2);
                      } else {
                        _selectedEmotions.add(e.$2);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      color: selected
                          ? _kPurple.withOpacity(0.28)
                          : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: selected
                            ? _kPurple
                            : Colors.white.withOpacity(0.18),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '${e.$1} ${e.$2}',
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.55),
                        fontSize: 12.5,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  PAGE 5 — REMINDERS
  // ══════════════════════════════════════════════════════════

  Widget _buildPage5_Reminders() {
    return _OBPageShell(
      emoji: _pageEmojis[5],
      title: _pageTitles[5],
      subtitle: _pageSubtitles[5],
      child: _glassCard(
        child: Column(
          children: [
            // Toggle row
            Row(
              children: [
                const Text('🔔',
                    style: TextStyle(fontSize: 26)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily reminders',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Log moods, water & sleep daily',
                        style: TextStyle(
                            color:
                                Colors.white.withOpacity(0.45),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _remindersEnabled,
                  onChanged: (v) =>
                      setState(() => _remindersEnabled = v),
                  activeColor: _kPurple,
                  activeTrackColor: _kPurple.withOpacity(0.35),
                  inactiveThumbColor:
                      Colors.white.withOpacity(0.4),
                  inactiveTrackColor:
                      Colors.white.withOpacity(0.12),
                ),
              ],
            ),
            // Time picker (when enabled)
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 4),
              secondChild: Column(
                children: [
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                        builder: (ctx, child) =>
                            _datePickerTheme(ctx, child!),
                      );
                      if (picked != null && mounted) {
                        setState(() => _reminderTime = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(
                            color: _kPurple.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              color: _kPurple, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            _formatTime(_reminderTime),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            'Tap to change',
                            style: TextStyle(
                                color: Colors.white
                                    .withOpacity(0.35),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              crossFadeState: _remindersEnabled
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            const SizedBox(height: 12),
            Text(
              'You can change this anytime in settings 🌸',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  PAGE 6 — MEET LUNAR AI (final)
  // ══════════════════════════════════════════════════════════

  Widget _buildPage6_Final() {
    final appName = _name.trim().isNotEmpty
        ? _name.trim()
        : 'beautiful';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Large moon illustration
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF3D0D70), Color(0xFF1A0540)]),
              border: Border.all(
                  color: _kGold.withOpacity(0.55), width: 2),
              boxShadow: [
                BoxShadow(
                    color: _kGold.withOpacity(0.30),
                    blurRadius: 40,
                    spreadRadius: 8),
                BoxShadow(
                    color: _kPurple.withOpacity(0.40),
                    blurRadius: 30,
                    spreadRadius: 4),
              ],
            ),
            child: const Center(
              child: Text('🌙', style: TextStyle(fontSize: 50)),
            ),
          ),
          const SizedBox(height: 28),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFDDB6FF)],
            ).createShader(b),
            child: Text(
              'Hi, $appName! 💜',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your Lunar AI companion is ready.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 15),
          ),
          const SizedBox(height: 28),
          // Feature cards
          ..._featureItems.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter:
                        ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(
                            color:
                                Colors.white.withOpacity(0.10)),
                      ),
                      child: Row(
                        children: [
                          Text(f.$1,
                              style:
                                  const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(f.$2,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                            FontWeight.w600,
                                        fontSize: 13.5)),
                                Text(f.$3,
                                    style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.45),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 28),
          // Begin button
          _completing
              ? SizedBox(
                  height: 56,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                                _kPurple),
                      ),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _complete,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                          colors: [_kPurple, _kPink]),
                      boxShadow: [
                        BoxShadow(
                          color: _kPurple.withOpacity(0.55),
                          blurRadius: 28,
                          spreadRadius: 3,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Begin my journey ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static const _featureItems = [
    ('🌙', 'Cycle Intelligence', 'Predicts phases, ovulation & PMS window'),
    ('💜', 'Mood Tracking', 'Detects emotional patterns over time'),
    ('✨', 'AI Insights', 'Personalised wellness wisdom every day'),
    ('💧', 'Health Logging', 'Water, sleep, weight & temperature'),
  ];

  // ══════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ══════════════════════════════════════════════════════════

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(
                color: _kPurple.withOpacity(0.28), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withOpacity(0.10),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
            color: Colors.white.withOpacity(0.65), fontSize: 13),
      );

  Widget _lunarField({
    required String hint,
    required ValueChanged<String> onChanged,
    String? initialValue,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      textInputAction: textInputAction,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.25), fontSize: 15),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: _kPurple.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: _kPurple, width: 1.5),
        ),
      ),
    );
  }

  Widget _selectionCard({
    required String emoji,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
            vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? _kPurple.withOpacity(0.22)
              : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: selected
                ? _kPurple
                : Colors.white.withOpacity(0.15),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: _kPurple.withOpacity(0.25),
                      blurRadius: 16,
                      spreadRadius: 2)
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.white.withOpacity(0.55),
                fontSize: 13,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePickerTheme(BuildContext ctx, Widget child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: _kPurple,
          onPrimary: Colors.white,
          surface: Color(0xFF160330),
          onSurface: Colors.white,
        ),
        dialogBackgroundColor: const Color(0xFF0D0120),
      ),
      child: child,
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

// ══════════════════════════════════════════════════════════════
//  PAGE SHELL — reusable header wrapper for each onboarding page
// ══════════════════════════════════════════════════════════════

class _OBPageShell extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Widget child;

  const _OBPageShell({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.48),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          child,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STAR PARTICLE SYSTEM
// ══════════════════════════════════════════════════════════════

class _OBStar {
  final double x, y, size, speed, opacity, phase;
  _OBStar({required math.Random rng})
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        size = rng.nextDouble() * 2.2 + 0.6,
        speed = rng.nextDouble() * 0.25 + 0.08,
        opacity = rng.nextDouble() * 0.55 + 0.15,
        phase = rng.nextDouble() * math.pi * 2;
}

class _OBStarPainter extends CustomPainter {
  final List<_OBStar> stars;
  final double progress;

  const _OBStarPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final yOff =
          math.sin(progress * math.pi * 2 * s.speed + s.phase) * 0.025;
      final twinkle = 0.4 +
          0.6 *
              math.sin(progress * math.pi * 3 * s.speed + s.phase).abs();
      paint.color = const Color(0xFFFFFFFF)
          .withOpacity((s.opacity * twinkle).clamp(0.05, 0.85));
      canvas.drawCircle(
        Offset(s.x * size.width, (s.y + yOff) * size.height),
        s.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OBStarPainter old) => old.progress != progress;
}
