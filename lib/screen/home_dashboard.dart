// ═══════════════════════════════════════════════════════════
//  🏠 HOME DASHBOARD — Lunar Command Centre
//  Clean · Minimal · Premium · Apple-level elegance
// ═══════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import '../core/providers/app_provider.dart';
import '../core/providers/lunar_data_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/avatar_provider.dart';
import '../widgets/lunar_avatar_widget.dart';
import '../services/streak_service.dart';
import '../core/data/local_cache.dart';
// ignore: unused_import
import '../user_provider.dart';

// ── Design tokens ─────────────────────────────────────────
const Color _hBg = Color(0xFF0A0118);
const Color _hSurf = Color(0xFF14022E);
const Color _hPurple = Color(0xFFAB5CF2);
const Color _hPink = Color(0xFFFF69B4);
const Color _hGold = Color(0xFFFFD700);
const Color _hDeep = Color(0xFF5C2DB8);
const Color _hTeal = Color(0xFF4FC3F7);
const Color _hGreen = Color(0xFF66BB6A);

// ── Cache keys ────────────────────────────────────────────
const _kFocusKey = 'home_focus_v1';
const _kMoodKey = 'home_mood_v1';

// ── Static insights ───────────────────────────────────────
const _kInsights = <String>[
  'Stay consistent — small steps build great habits ✨',
  'Your sleep pattern shows improvement this week 😴',
  'Drinking more water today will boost your energy 💧',
  'Your wellness streak is building momentum 🔥',
  'Consistency with your routine is your superpower 💜',
  'Your body is doing amazing things — trust the process 🌸',
];

const _kFocusDefaults = <String>[
  'Drink 8 glasses of water 💧',
  'Complete your Glow routine ✨',
  'Mood check-in 😊',
];

// ═══════════════════════════════════════════════════════════
//  MAIN WIDGET
// ═══════════════════════════════════════════════════════════

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;
  late AnimationController _orbPulseCtrl;
  late Animation<double> _orbPulseAnim;

  StreakData? _streak;
  int _insightIdx = 0;
  bool _summaryVisible = false;

  // Focus task completions
  final Set<int> _focusDone = {};

  // Today mood (0-4: 😊😐😔😤😴)
  int _moodIdx = -1;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _orbPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _orbPulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _orbPulseCtrl, curve: Curves.easeInOut));

    _insightIdx = math.Random().nextInt(_kInsights.length);

    // Load streak
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = StreakService.checkIn();
      setState(() => _streak = s);

      // Restore mood
      final saved = LocalCache.getString(_kMoodKey);
      if (saved != null) {
        final v = int.tryParse(saved);
        if (v != null) setState(() => _moodIdx = v);
      }
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _orbPulseCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _dateStr {
    final d = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  void _toggleFocus(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_focusDone.contains(i)) {
        _focusDone.remove(i);
      } else {
        _focusDone.add(i);
      }
    });
  }

  void _setMood(int idx) {
    HapticFeedback.selectionClick();
    setState(() => _moodIdx = idx);
    LocalCache.setString(_kMoodKey, '$idx');
  }

  void _showSummary(BuildContext ctx) {
    HapticFeedback.mediumImpact();
    final lunarData = context.read<LunarDataProvider>();
    final app = context.read<AppProvider>();
    final streak = _streak?.current ?? 0;

    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AiSummarySheet(
        glowScore: (_focusDone.length / _kFocusDefaults.length * 100).round(),
        bloomStatus: lunarData.isPregnant || app.pregnancyMode
            ? 'Week ${lunarData.currentPregnancyWeek}'
            : 'Day ${lunarData.currentCycleDay}',
        mood: _moodIdx >= 0
            ? [
                'Happy 😊',
                'Neutral 😐',
                'Sad 😔',
                'Stressed 😤',
                'Tired 😴'
              ][_moodIdx]
            : 'Not logged',
        streak: streak,
        insight: _kInsights[_insightIdx],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<LunarAuthProvider>();
    final name = auth.displayName.split(' ').first;

    final lunarData = context.watch<LunarDataProvider>();
    final app = context.watch<AppProvider>();
    final streak = _streak?.current ?? 0;
    // Derived values
    final glowScore = _focusDone.length == _kFocusDefaults.length
        ? 80
        : 45 + _focusDone.length * 15;
    final bloomVal = lunarData.isPregnant || app.pregnancyMode
        ? (lunarData.currentPregnancyWeek / 40.0).clamp(0.0, 1.0)
        : (lunarData.currentCycleDay / 28.0).clamp(0.0, 1.0);
    final wellnessVal =
        ((_focusDone.length + (streak > 0 ? 1 : 0)) / 4.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _hBg,
      body: Stack(
        children: [
          // Background radial
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.2,
                colors: [_hPurple.withOpacity(0.1), _hBg],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────
                SliverToBoxAdapter(child: _buildHeader(name)),
                // ── Orb Hero ───────────────────────────────
                SliverToBoxAdapter(child: _buildOrbHero()),
                // ── Today Summary ──────────────────────────
                SliverToBoxAdapter(
                    child: _buildSummaryCard(
                        lunarData: lunarData, app: app, streak: streak)),
                // ── Mood Check ─────────────────────────────
                SliverToBoxAdapter(child: _buildMoodRow()),
                // ── Today's Focus ──────────────────────────
                SliverToBoxAdapter(child: _buildFocusSection()),
                // ── Progress Rings ─────────────────────────
                SliverToBoxAdapter(
                    child: _buildProgressSection(
                  glowScore: glowScore,
                  bloomVal: bloomVal,
                  wellnessVal: wellnessVal,
                  streak: streak,
                )),
                // ── AI Insight ─────────────────────────────
                SliverToBoxAdapter(child: _buildInsight()),
                // ── Streak ─────────────────────────────────
                SliverToBoxAdapter(child: _buildStreakCard(streak)),
                // ── Notifications ──────────────────────────
                SliverToBoxAdapter(child: _buildNotifications()),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateStr,
                  style: TextStyle(
                    color: _hPurple.withOpacity(0.75),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Small avatar
          Consumer<AvatarProvider>(builder: (_, av, __) {
            return Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_hPurple.withOpacity(0.5), _hDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border:
                    Border.all(color: _hPurple.withOpacity(0.4), width: 1.5),
              ),
              child: ClipOval(
                child: av.hasAvatar
                    ? LunarAvatarWidget(avatar: av.avatar!, size: 44)
                    : const Center(
                        child: Text('🌙', style: TextStyle(fontSize: 20))),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Orb Hero ──────────────────────────────────────────────
  Widget _buildOrbHero() {
    return GestureDetector(
      onTap: () => _showSummary(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_floatAnim, _glowAnim, _orbPulseAnim]),
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: ScaleTransition(
                scale: _orbPulseAnim,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _hPurple.withOpacity(0.65),
                        _hDeep.withOpacity(0.85),
                        _hBg,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _hPurple.withOpacity(_glowAnim.value * 0.55),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: _hPink.withOpacity(_glowAnim.value * 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: _hPurple.withOpacity(_glowAnim.value * 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌙', style: TextStyle(fontSize: 34)),
                      const SizedBox(height: 4),
                      Text(
                        'Tap for summary',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Today Summary ─────────────────────────────────────────
  Widget _buildSummaryCard({
    required LunarDataProvider lunarData,
    required AppProvider app,
    required int streak,
  }) {
    final isPregnant = lunarData.isPregnant || app.pregnancyMode;
    final cycleInfo = isPregnant
        ? 'Week ${lunarData.currentPregnancyWeek} 🤰'
        : 'Day ${lunarData.currentCycleDay} 🌸';
    final moodLabel =
        _moodIdx >= 0 ? ['😊', '😐', '😔', '😤', '😴'][_moodIdx] : '—';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_hPurple.withOpacity(0.18), _hDeep.withOpacity(0.28)],
        ),
        border: Border.all(color: _hPurple.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s Overview',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryItem(
                  '✨', 'Glow', '${45 + _focusDone.length * 15}%', _hPink),
              _vDivider(),
              _summaryItem(
                  '🌸', isPregnant ? 'Bloom' : 'Cycle', cycleInfo, _hPurple),
              _vDivider(),
              _summaryItem('😊', 'Mood', moodLabel, _hTeal),
              _vDivider(),
              _summaryItem('🔥', 'Streak', '$streak d', _hGold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String emoji, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: Colors.white.withOpacity(0.1),
      );

  // ── Mood Row ──────────────────────────────────────────────
  Widget _buildMoodRow() {
    const moods = ['😊', '😐', '😔', '😤', '😴'];
    const labels = ['Happy', 'Neutral', 'Sad', 'Stressed', 'Tired'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling?',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final isSelected = _moodIdx == i;
              return GestureDetector(
                onTap: () => _setMood(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected
                        ? _hPurple.withOpacity(0.22)
                        : Colors.white.withOpacity(0.04),
                    border: Border.all(
                      color: isSelected
                          ? _hPurple.withOpacity(0.55)
                          : Colors.white.withOpacity(0.07),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(moods[i], style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 3),
                      Text(labels[i],
                          style: TextStyle(
                            color: isSelected
                                ? _hPurple
                                : Colors.white.withOpacity(0.4),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Today's Focus ─────────────────────────────────────────
  Widget _buildFocusSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Today's Focus",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4)),
              const Spacer(),
              Text('${_focusDone.length}/${_kFocusDefaults.length}',
                  style: TextStyle(
                      color: _hPurple.withOpacity(0.8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ..._kFocusDefaults.asMap().entries.map((e) {
            final done = _focusDone.contains(e.key);
            return GestureDetector(
              onTap: () => _toggleFocus(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 7),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: done
                      ? _hPurple.withOpacity(0.12)
                      : Colors.white.withOpacity(0.04),
                  border: Border.all(
                    color: done
                        ? _hPurple.withOpacity(0.35)
                        : Colors.white.withOpacity(0.07),
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? _hPurple : Colors.transparent,
                        border: Border.all(
                          color:
                              done ? _hPurple : Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 13)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: done
                              ? Colors.white.withOpacity(0.45)
                              : Colors.white.withOpacity(0.82),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Progress Rings ────────────────────────────────────────
  Widget _buildProgressSection({
    required int glowScore,
    required double bloomVal,
    required double wellnessVal,
    required int streak,
  }) {
    final streakVal = (streak / 30.0).clamp(0.0, 1.0);
    final items = [
      ('✨', 'Glow', glowScore / 100.0, _hPink),
      ('🌸', 'Bloom', bloomVal, _hPurple),
      ('💚', 'Wellness', wellnessVal, _hGreen),
      ('🔥', 'Streak', streakVal, _hGold),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Progress',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items
                .map((it) => _ProgressRing(
                      emoji: it.$1,
                      label: it.$2,
                      value: it.$3,
                      color: it.$4,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── AI Insight ────────────────────────────────────────────
  Widget _buildInsight() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _hPurple.withOpacity(0.07),
        border: Border.all(color: _hPurple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hPurple.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: _hPurple.withOpacity(_glowAnim.value * 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Center(
                  child: Text('🌙', style: TextStyle(fontSize: 16))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lunar Insight',
                    style: TextStyle(
                        color: _hPurple.withOpacity(0.8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4)),
                const SizedBox(height: 3),
                Text(
                  _kInsights[_insightIdx],
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13.5,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Streak Card ───────────────────────────────────────────
  Widget _buildStreakCard(int streak) {
    final next = _streak?.nextMilestone;
    final progress = _streak?.progressToNext ?? 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_hGold.withOpacity(0.15), _hWarm.withOpacity(0.08)],
        ),
        border: Border.all(color: _hGold.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$streak Day Streak',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  Text(
                      streak == 0
                          ? 'Start your streak today!'
                          : 'Keep going — you\'re on fire 🔥',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(_hGold),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${next.emoji} ${next.title}',
                    style: TextStyle(
                      color: _hGold.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Notifications ─────────────────────────────────────────
  Widget _buildNotifications() {
    final items = [
      ('💊', 'Medicine Reminder', 'Take your evening supplement', _hPink),
      ('🌙', 'Evening Check-in', 'How was your day?', _hPurple),
      ('⏰', 'Glow Routine', 'Night routine starts in 1 hr', _hTeal),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reminders',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
          const SizedBox(height: 10),
          ...items.map((it) => Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: it.$4.withOpacity(0.15),
                      ),
                      child: Center(
                          child: Text(it.$1,
                              style: const TextStyle(fontSize: 16))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.$2,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700)),
                          Text(it.$3,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(0.2), size: 18),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PROGRESS RING WIDGET
// ═══════════════════════════════════════════════════════════

class _ProgressRing extends StatelessWidget {
  final String emoji, label;
  final double value;
  final Color color;

  const _ProgressRing({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 4,
                    backgroundColor: color.withOpacity(0.14),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(emoji, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600)),
          Text('${(value * 100).round()}%',
              style: TextStyle(
                  color: color.withOpacity(0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  AI SUMMARY BOTTOM SHEET
// ═══════════════════════════════════════════════════════════

class _AiSummarySheet extends StatelessWidget {
  final int glowScore;
  final String bloomStatus;
  final String mood;
  final int streak;
  final String insight;

  const _AiSummarySheet({
    required this.glowScore,
    required this.bloomStatus,
    required this.mood,
    required this.streak,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF14022E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border:
            Border(top: BorderSide(color: _hPurple.withOpacity(0.2), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🌙', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text("Today's Summary",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            _summaryRow('✨', 'Glow Score', '$glowScore%', _hPink),
            _summaryRow('🌸', 'Bloom', bloomStatus, _hPurple),
            _summaryRow('😊', 'Mood', mood, _hTeal),
            _summaryRow('🔥', 'Streak', '$streak days', _hGold),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _hPurple.withOpacity(0.08),
                border: Border.all(color: _hPurple.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(insight,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String emoji, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color.withOpacity(0.15)),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Missing color constant ────────────────────────────────
const Color _hWarm = Color(0xFFFFB74D);
