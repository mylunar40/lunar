// ═══════════════════════════════════════════════════════════
//  ✨ GLOW — Beauty, Wellness & Lifestyle Hub
//  Lunar Premium · Glassmorphism · Purple Gradient Design
// ═══════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/premium_provider.dart';
import '../core/data/local_cache.dart';
import '../screen/paywall/paywall_screen.dart';

// ── Design tokens ─────────────────────────────────────────
const Color _kBg = Color(0xFF0A0118);
const Color _kSurf = Color(0xFF14022E);
const Color _kPurple = Color(0xFFAB5CF2);
const Color _kPink = Color(0xFFFF69B4);
const Color _kGold = Color(0xFFFFD700);
const Color _kDeep = Color(0xFF5C2DB8);
const Color _kTeal = Color(0xFF4FC3F7);
const Color _kGreen = Color(0xFF66BB6A);
const Color _kWarm = Color(0xFFFFB74D);
const Color _kLavender = Color(0xFFBA68C8);

// ── Cache keys ────────────────────────────────────────────
const _kStreakKey = 'glow_streak_v1';
const _kLastDateKey = 'glow_last_date_v1';
const _kTasksKey = 'glow_tasks_v1';

// ─────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────

class _GlowCategory {
  final String emoji, title, subtitle;
  final Color color;
  final List<String> tips;
  const _GlowCategory({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tips,
  });
}

class _RoutineTask {
  final String emoji, label, session;
  bool done;
  _RoutineTask({
    required this.emoji,
    required this.label,
    required this.session,
    this.done = false,
  });
}

class _DiscoveryItem {
  final String emoji, title, tag;
  final Color color;
  const _DiscoveryItem({
    required this.emoji,
    required this.title,
    required this.tag,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────
//  STATIC DATA
// ─────────────────────────────────────────────────────────

const _kCategories = <_GlowCategory>[
  _GlowCategory(
    emoji: '✨',
    title: 'Skin Care',
    subtitle: 'Glow from within',
    color: _kPink,
    tips: [
      'Cleanse, tone and moisturise morning and night.',
      'Apply SPF 30+ every morning — no exceptions.',
      'Hydrated skin is glowing skin. Drink more water.',
      'Remove makeup fully before sleep.',
      'Exfoliate gently 1–2 times per week.',
    ],
  ),
  _GlowCategory(
    emoji: '💇',
    title: 'Hair Care',
    subtitle: 'Strong & healthy hair',
    color: _kWarm,
    tips: [
      'Deep-condition weekly for soft, strong hair.',
      'Limit heat styling — embrace natural texture.',
      'Eat protein-rich foods to support hair growth.',
      'Scalp massage daily for better circulation.',
      'Trim every 8–10 weeks to prevent split ends.',
    ],
  ),
  _GlowCategory(
    emoji: '💄',
    title: 'Beauty',
    subtitle: 'Feel confident every day',
    color: _kLavender,
    tips: [
      'A consistent skincare base makes makeup look better.',
      'Less is more — focus on skin, not heavy coverage.',
      'Highlighter on cheekbones creates instant glow.',
      'Tinted lip balm is your best everyday ally.',
      'Beauty starts with how you feel inside.',
    ],
  ),
  _GlowCategory(
    emoji: '🥗',
    title: 'Nutrition',
    subtitle: 'Beauty starts with food',
    color: _kGreen,
    tips: [
      'Eat the rainbow — colourful vegetables daily.',
      'Omega-3 fatty acids keep skin supple and glowing.',
      'Green tea is packed with skin-loving antioxidants.',
      'Cut sugar to reduce inflammation and breakouts.',
      'Berries, avocado and nuts are beauty superfoods.',
    ],
  ),
  _GlowCategory(
    emoji: '😴',
    title: 'Sleep',
    subtitle: 'Your natural beauty sleep',
    color: _kDeep,
    tips: [
      'Aim for 7–9 hours of quality sleep each night.',
      'Silk pillowcases reduce hair breakage and creases.',
      'Sleep on your back to prevent facial compression.',
      'Apply a night cream or facial oil before bed.',
      'Consistent sleep time regulates your skin cycle.',
    ],
  ),
  _GlowCategory(
    emoji: '❤️',
    title: 'Self Care',
    subtitle: 'You come first',
    color: _kPurple,
    tips: [
      'Schedule non-negotiable "me time" every day.',
      'A warm bath with essential oils is true self care.',
      'Protect your energy — it reflects on your skin.',
      'Celebrate small wins every day without guilt.',
      'Rest is productive. Never feel guilty for it.',
    ],
  ),
  _GlowCategory(
    emoji: '💧',
    title: 'Hydration',
    subtitle: 'Water is beauty',
    color: _kTeal,
    tips: [
      'Start every morning with a full glass of water.',
      'Dehydration shows first on your skin — drink up.',
      'Infuse water with lemon, mint or cucumber.',
      'Herbal teas count toward your daily intake.',
      'Eat water-rich foods: cucumber, watermelon, celery.',
    ],
  ),
  _GlowCategory(
    emoji: '📝',
    title: 'Journal',
    subtitle: 'Reflect & manifest',
    color: _kGold,
    tips: [
      'Write 3 gratitude points every morning.',
      'Reflect on your beauty wins — big and small.',
      'Set intentions for how you want to feel today.',
      'Track habits and watch your glow improve.',
      'Re-read old entries to see how far you\'ve come.',
    ],
  ),
];

// Routines
List<_RoutineTask> _buildDefaultTasks() => [
      _RoutineTask(emoji: '🌊', label: 'Cleanse face', session: 'Morning'),
      _RoutineTask(emoji: '☀️', label: 'Apply SPF', session: 'Morning'),
      _RoutineTask(
          emoji: '💧', label: 'Drink water (8 oz)', session: 'Morning'),
      _RoutineTask(emoji: '🥗', label: 'Healthy breakfast', session: 'Morning'),
      _RoutineTask(
          emoji: '💦', label: 'Hydrate (midday)', session: 'Afternoon'),
      _RoutineTask(emoji: '🧴', label: 'Reapply SPF', session: 'Afternoon'),
      _RoutineTask(emoji: '🚶', label: 'Short walk', session: 'Afternoon'),
      _RoutineTask(emoji: '🌙', label: 'Remove makeup', session: 'Night'),
      _RoutineTask(emoji: '✨', label: 'Night cream', session: 'Night'),
      _RoutineTask(emoji: '📝', label: 'Journal 3 lines', session: 'Night'),
      _RoutineTask(emoji: '😴', label: 'Sleep by 10 PM', session: 'Night'),
    ];

const _kDiscovery = <_DiscoveryItem>[
  _DiscoveryItem(
      emoji: '🌸',
      title: 'Morning Glow Routine',
      tag: 'Skin Care',
      color: _kPink),
  _DiscoveryItem(
      emoji: '🌙',
      title: 'Night Skin Ritual',
      tag: 'Skin Care',
      color: _kPurple),
  _DiscoveryItem(
      emoji: '💆',
      title: 'Scalp Health Guide',
      tag: 'Hair Care',
      color: _kWarm),
  _DiscoveryItem(
      emoji: '🥑', title: 'Glow Foods List', tag: 'Nutrition', color: _kGreen),
  _DiscoveryItem(
      emoji: '💎', title: 'Glass Skin Method', tag: 'Beauty', color: _kTeal),
  _DiscoveryItem(
      emoji: '🌿',
      title: 'Natural Beauty Tips',
      tag: 'Lifestyle',
      color: _kLavender),
];

const _kMotivations = <String>[
  'You are your own kind of beautiful ✨',
  'Consistency is the secret to glowing skin 🌸',
  'Small daily rituals create extraordinary beauty 💜',
  'Nourish yourself from the inside out 🥗',
  'Rest, hydrate and glow — that\'s the formula 💧',
];

// ═══════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════

class GlowScreen extends StatefulWidget {
  const GlowScreen({super.key});
  @override
  State<GlowScreen> createState() => _GlowScreenState();
}

class _GlowScreenState extends State<GlowScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  // Glow Assistant input
  final TextEditingController _assistCtrl = TextEditingController();
  final FocusNode _assistFocus = FocusNode();
  bool _assistHasText = false;

  // Categories
  String? _expanded;

  // Routine
  late List<_RoutineTask> _tasks;
  String _activeSession = 'Morning';
  int _streak = 0;

  // UI
  late int _motIdx;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _assistCtrl.addListener(() {
      final has = _assistCtrl.text.trim().isNotEmpty;
      if (has != _assistHasText && mounted)
        setState(() => _assistHasText = has);
    });

    _motIdx = math.Random().nextInt(_kMotivations.length);
    _tasks = _buildDefaultTasks();
    _loadRoutineState();

    // Set active session by time of day
    final h = DateTime.now().hour;
    _activeSession = h < 12 ? 'Morning' : (h < 18 ? 'Afternoon' : 'Night');
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _assistCtrl.dispose();
    _assistFocus.dispose();
    super.dispose();
  }

  // ── Persist routine & streak ──────────────────────────────
  void _loadRoutineState() {
    final today = _todayStr();
    final last = LocalCache.getString(_kLastDateKey) ?? '';
    _streak = int.tryParse(LocalCache.getString(_kStreakKey) ?? '0') ?? 0;

    if (last != today) {
      // New day — check if yesterday's was completed
      final yesterday =
          _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      if (last == yesterday) {
        _streak++;
      } else if (last.isNotEmpty && last != yesterday) {
        _streak = 0;
      }
      LocalCache.setString(_kLastDateKey, today);
      LocalCache.setString(_kStreakKey, '$_streak');
      // Reset tasks for new day
      _saveTasks([]);
    } else {
      final saved = LocalCache.getString(_kTasksKey) ?? '';
      if (saved.isNotEmpty) {
        final doneSet = Set<String>.from(saved.split(','));
        for (final t in _tasks) {
          t.done = doneSet.contains('${t.session}:${t.label}');
        }
      }
    }
  }

  void _saveTasks(List<String>? override) {
    final keys = override ??
        _tasks
            .where((t) => t.done)
            .map((t) => '${t.session}:${t.label}')
            .toList();
    LocalCache.setString(_kTasksKey, keys.join(','));
  }

  void _toggleTask(_RoutineTask task) {
    HapticFeedback.selectionClick();
    setState(() => task.done = !task.done);
    _saveTasks(null);
  }

  String _todayStr() => _dateStr(DateTime.now());
  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Glow score ────────────────────────────────────────────
  int get _glowScore {
    final done = _tasks.where((t) => t.done).length;
    final total = _tasks.length;
    if (total == 0) return 0;
    return (done / total * 100).round();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌸';
    return 'Good Evening 🌙';
  }

  List<_RoutineTask> get _sessionTasks =>
      _tasks.where((t) => t.session == _activeSession).toList();

  // ── Send to Glow Assistant ────────────────────────────────
  void _sendToAssistant(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final premium = context.read<PremiumProvider>();
    final chat = context.read<ChatProvider>();
    if (!chat.canSendAiMessage(premium.isPaid)) {
      PaywallGate.show(context, featureHint: 'Glow AI Assistant');
      return;
    }
    final prompt =
        'You are Glow AI, a personal beauty and wellness assistant specialising '
        'in skin care, hair care, nutrition for beauty, self care and healthy '
        'lifestyle. Answer the following question. Do NOT discuss pregnancy, '
        'menstrual cycle, medical diagnosis or mental health therapy.\n\n'
        'Question: $t';
    _assistCtrl.clear();
    _assistFocus.unfocus();
    chat.send(prompt, context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Glow AI is thinking ✨',
          style: TextStyle(color: Colors.white)),
      backgroundColor: _kDeep,
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ═════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.55),
                radius: 1.1,
                colors: [_kPurple.withOpacity(0.09), _kBg],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildHero()),
                SliverToBoxAdapter(child: _buildAssistant()),
                SliverToBoxAdapter(
                    child: _buildSectionLabel('Wellness & Beauty')),
                SliverToBoxAdapter(child: _buildCategories()),
                SliverToBoxAdapter(
                    child: _buildSectionLabel('Today\'s Routine')),
                SliverToBoxAdapter(child: _buildRoutine()),
                SliverToBoxAdapter(
                    child: _buildSectionLabel('✨ Glow Discovery')),
                SliverToBoxAdapter(child: _buildDiscovery()),
                SliverToBoxAdapter(child: _buildSectionLabel('Coming Soon')),
                SliverToBoxAdapter(child: _buildComingSoon()),
                SliverToBoxAdapter(child: _buildSectionLabel('Glow Store')),
                SliverToBoxAdapter(child: _buildGlowStore()),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPurple.withOpacity(0.12),
                border: Border.all(
                    color: _kPurple.withOpacity(_glowAnim.value * 0.4)),
              ),
              child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 18))),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Glow',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3),
          ),
          const Spacer(),
          // Streak badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _kGold.withOpacity(0.15),
              border: Border.all(color: _kGold.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '$_streak day${_streak == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: _kGold,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kPurple.withOpacity(0.22),
            _kDeep.withOpacity(0.38),
            _kPink.withOpacity(0.12),
          ],
        ),
        border: Border.all(color: _kPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Score orb
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kPurple.withOpacity(0.6), _kDeep.withOpacity(0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPurple.withOpacity(_glowAnim.value * 0.5),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                    color: _kPurple.withOpacity(_glowAnim.value * 0.55),
                    width: 1.5),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_glowScore',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1)),
                    Text('score',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                const Text('Today\'s Glow Score',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    _kMotivations[_motIdx],
                    key: ValueKey(_motIdx),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12.5,
                        height: 1.4),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => setState(
                      () => _motIdx = (_motIdx + 1) % _kMotivations.length),
                  child: Text('New inspiration ✨',
                      style: TextStyle(
                          color: _kPurple.withOpacity(0.8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Glow Assistant ────────────────────────────────────────
  Widget _buildAssistant() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPink.withOpacity(0.14), _kPurple.withOpacity(0.10)],
        ),
        border: Border.all(color: _kPink.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      _kPink.withOpacity(0.6),
                      _kPurple.withOpacity(0.6)
                    ]),
                  ),
                  child: const Center(
                      child: Text('💄', style: TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Glow Assistant',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text('Beauty • Skin • Hair • Wellness',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 11)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _kPink.withOpacity(0.18),
                  ),
                  child: const Text('AI',
                      style: TextStyle(
                          color: _kPink,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          // Quick prompts
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                'Oily skin tips',
                'Hair fall routine',
                'Dark circles',
                'Glow foods',
                'Night skin care',
              ]
                  .map((q) => GestureDetector(
                        onTap: () => _sendToAssistant(q),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: _kPurple.withOpacity(0.12),
                            border:
                                Border.all(color: _kPurple.withOpacity(0.22)),
                          ),
                          alignment: Alignment.center,
                          child: Text(q,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Input row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _assistCtrl,
                      focusNode: _assistFocus,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13.5),
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      cursorColor: _kPurple,
                      decoration: InputDecoration(
                        hintText: 'Ask about beauty, skin, hair…',
                        hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.28),
                            fontSize: 13.5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: _sendToAssistant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _assistHasText
                      ? () => _sendToAssistant(_assistCtrl.text)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _assistHasText
                            ? [_kPink, _kPurple]
                            : [
                                _kPink.withOpacity(0.4),
                                _kPurple.withOpacity(0.4)
                              ],
                      ),
                      boxShadow: _assistHasText
                          ? [
                              BoxShadow(
                                  color: _kPurple.withOpacity(0.35),
                                  blurRadius: 10,
                                  spreadRadius: 1)
                            ]
                          : null,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────
  Widget _buildSectionLabel(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        child: Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4)),
      );

  // ── Categories ────────────────────────────────────────────
  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _kCategories.map((cat) {
          final isExp = _expanded == cat.title;
          return _CategoryCard(
            cat: cat,
            isExpanded: isExp,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = isExp ? null : cat.title);
            },
          );
        }).toList(),
      ),
    );
  }

  // ── Today's Routine ───────────────────────────────────────
  Widget _buildRoutine() {
    final sessionTasks = _sessionTasks;
    final doneCount = sessionTasks.where((t) => t.done).length;
    return Column(
      children: [
        // Session tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['Morning', 'Afternoon', 'Night'].map((s) {
              final isActive = _activeSession == s;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeSession = s);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isActive
                          ? _kPurple.withOpacity(0.22)
                          : Colors.white.withOpacity(0.04),
                      border: Border.all(
                          color: isActive
                              ? _kPurple.withOpacity(0.45)
                              : Colors.white.withOpacity(0.07)),
                    ),
                    child: Text(
                      s,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isActive
                            ? _kPurple
                            : Colors.white.withOpacity(0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: sessionTasks.isEmpty
                        ? 0
                        : doneCount / sessionTasks.length,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(_kPurple),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$doneCount/${sessionTasks.length}',
                style: TextStyle(
                    color: _kPurple.withOpacity(0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Task list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: sessionTasks
                .map((task) => _RoutineTaskTile(
                      task: task,
                      onToggle: () => _toggleTask(task),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── Glow Discovery ────────────────────────────────────────
  Widget _buildDiscovery() {
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _kDiscovery.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _DiscoveryTile(item: _kDiscovery[i]),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _placeholderBanner(
            '🔮',
            'More beauty guides, expert tips and wellness articles coming soon!',
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Coming Soon ───────────────────────────────────────────
  Widget _buildComingSoon() {
    const items = [
      ('🔬', 'AI Skin Scan', 'Analyse your skin with AI', _kPink),
      ('💇', 'AI Hair Scan', 'Diagnose hair issues instantly', _kWarm),
      ('🛍', 'Product Recommender', 'Personalised beauty picks', _kLavender),
      (
        '👩‍⚕️',
        'Dermatologist Connect',
        'Expert skin advice on demand',
        _kTeal
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: items.map((it) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: it.$4.withOpacity(0.07),
              border: Border.all(color: it.$4.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: it.$4.withOpacity(0.15)),
                  child: Center(
                      child: Text(it.$1, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.$2,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      Text(it.$3,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11.5)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: it.$4.withOpacity(0.15),
                  ),
                  child: Text('Soon',
                      style: TextStyle(
                          color: it.$4.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Glow Store ────────────────────────────────────────────
  Widget _buildGlowStore() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          _placeholderBanner('🛍',
              'Glow Store — curated beauty & wellness products coming soon.'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _storeTile('🤝', 'Brand Partnerships', _kPurple)),
              const SizedBox(width: 8),
              Expanded(child: _storeTile('💎', 'Affiliate Picks', _kGold)),
            ],
          ),
          const SizedBox(height: 8),
          _storeTile('🎁', 'Personalised Product Recommendations', _kPink,
              fullWidth: true),
        ],
      ),
    );
  }

  Widget _storeTile(String emoji, String label, Color color,
      {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.07),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: color.withOpacity(0.15),
            ),
            child: Text('Soon',
                style: TextStyle(
                    color: color.withOpacity(0.9),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _placeholderBanner(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CATEGORY CARD
// ═══════════════════════════════════════════════════════════

class _CategoryCard extends StatelessWidget {
  final _GlowCategory cat;
  final bool isExpanded;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.cat,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isExpanded
              ? cat.color.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: isExpanded
                ? cat.color.withOpacity(0.36)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cat.color.withOpacity(0.16)),
                  child: Center(
                      child: Text(cat.emoji,
                          style: const TextStyle(fontSize: 19))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      Text(cat.subtitle,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.44),
                              fontSize: 12)),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: isExpanded
                          ? cat.color
                          : Colors.white.withOpacity(0.24),
                      size: 22),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              ...cat.tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 5, right: 10),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cat.color.withOpacity(0.7)),
                        ),
                        Expanded(
                          child: Text(tip,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 13,
                                  height: 1.45)),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ROUTINE TASK TILE
// ═══════════════════════════════════════════════════════════

class _RoutineTaskTile extends StatelessWidget {
  final _RoutineTask task;
  final VoidCallback onToggle;
  const _RoutineTaskTile({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: task.done
              ? _kPurple.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: task.done
                ? _kPurple.withOpacity(0.35)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Row(
          children: [
            Text(task.emoji, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.label,
                style: TextStyle(
                  color: task.done
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white.withOpacity(0.82),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  decoration: task.done ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white.withOpacity(0.35),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.done ? _kPurple : Colors.transparent,
                border: Border.all(
                  color: task.done ? _kPurple : Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: task.done
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DISCOVERY TILE
// ═══════════════════════════════════════════════════════════

class _DiscoveryTile extends StatelessWidget {
  final _DiscoveryItem item;
  const _DiscoveryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.color.withOpacity(0.18),
              item.color.withOpacity(0.05)
            ],
          ),
          border: Border.all(color: item.color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: item.color.withOpacity(0.2)),
              child: Center(
                  child:
                      Text(item.emoji, style: const TextStyle(fontSize: 18))),
            ),
            const Spacer(),
            Text(item.title,
                maxLines: 2,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: item.color.withOpacity(0.18),
              ),
              child: Text(item.tag,
                  style: TextStyle(
                      color: item.color.withOpacity(0.9),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
