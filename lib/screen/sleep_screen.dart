import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/lunar_data_provider.dart';

// ═══════════════════════════════════════════════════════════
//  LUNAR SLEEP + NIGHT WELLNESS — Peaceful Night Sanctuary
// ═══════════════════════════════════════════════════════════

// ── Design tokens ─────────────────────────────────────────
const Color _sBg       = Color(0xFF050114);
const Color _sPurple   = Color(0xFFAB5CF2);
const Color _sPink     = Color(0xFFFF69B4);
const Color _sDeep     = Color(0xFF5C2DB8);
const Color _sGold     = Color(0xFFFFD700);
const Color _sTeal     = Color(0xFF4FC3F7);
const Color _sIndigo   = Color(0xFF7986CB);

// ═══════════════════════════════════════════════════════════
//  ENUMS + EXTENSIONS
// ═══════════════════════════════════════════════════════════

enum _SSleepQuality { poor, fair, good, excellent, deep }

extension _SSleepQualityX on _SSleepQuality {
  String get label => const {
    _SSleepQuality.poor:      'Poor',
    _SSleepQuality.fair:      'Fair',
    _SSleepQuality.good:      'Good',
    _SSleepQuality.excellent: 'Excellent',
    _SSleepQuality.deep:      'Deep Rest',
  }[this]!;

  String get emoji => const {
    _SSleepQuality.poor:      '😟',
    _SSleepQuality.fair:      '😐',
    _SSleepQuality.good:      '🌙',
    _SSleepQuality.excellent: '✨',
    _SSleepQuality.deep:      '💜',
  }[this]!;

  Color get color => const {
    _SSleepQuality.poor:      Color(0xFFEF5350),
    _SSleepQuality.fair:      Color(0xFFFFB74D),
    _SSleepQuality.good:      _sTeal,
    _SSleepQuality.excellent: _sPurple,
    _SSleepQuality.deep:      _sPink,
  }[this]!;

  double get score => const {
    _SSleepQuality.poor:      0.18,
    _SSleepQuality.fair:      0.44,
    _SSleepQuality.good:      0.67,
    _SSleepQuality.excellent: 0.84,
    _SSleepQuality.deep:      0.96,
  }[this]!;
}

enum _SSleepMood { anxious, restless, neutral, calm, peaceful }

extension _SSleepMoodX on _SSleepMood {
  String get label => const {
    _SSleepMood.anxious:  'Anxious',
    _SSleepMood.restless: 'Restless',
    _SSleepMood.neutral:  'Neutral',
    _SSleepMood.calm:     'Calm',
    _SSleepMood.peaceful: 'Peaceful',
  }[this]!;

  String get emoji => const {
    _SSleepMood.anxious:  '😰',
    _SSleepMood.restless: '😤',
    _SSleepMood.neutral:  '😌',
    _SSleepMood.calm:     '🌙',
    _SSleepMood.peaceful: '💜',
  }[this]!;

  Color get color => const {
    _SSleepMood.anxious:  Color(0xFFEF5350),
    _SSleepMood.restless: Color(0xFFFFB74D),
    _SSleepMood.neutral:  _sTeal,
    _SSleepMood.calm:     _sPurple,
    _SSleepMood.peaceful: _sPink,
  }[this]!;
}

enum _SJournalType { dream, emotion, anxiety, thoughts }

extension _SJournalTypeX on _SJournalType {
  String get label => const {
    _SJournalType.dream:    'Dream',
    _SJournalType.emotion:  'Emotion',
    _SJournalType.anxiety:  'Anxiety',
    _SJournalType.thoughts: 'Thoughts',
  }[this]!;

  String get emoji => const {
    _SJournalType.dream:    '🌙',
    _SJournalType.emotion:  '💜',
    _SJournalType.anxiety:  '🌊',
    _SJournalType.thoughts: '✨',
  }[this]!;

  Color get color => const {
    _SJournalType.dream:    _sIndigo,
    _SJournalType.emotion:  _sPurple,
    _SJournalType.anxiety:  _sTeal,
    _SJournalType.thoughts: _sPink,
  }[this]!;
}

// ═══════════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════════

class _SSleepEntry {
  final String id;
  final double hours, deepHours, energyScore;
  final int interruptions;
  final _SSleepQuality quality;
  final _SSleepMood mood;
  final DateTime date;

  _SSleepEntry({
    required this.hours,
    required this.deepHours,
    required this.interruptions,
    required this.quality,
    required this.mood,
    required this.date,
    required this.energyScore,
  }) : id = '${date.microsecondsSinceEpoch}';
}

class _SNightEntry {
  final String id, note;
  final _SJournalType type;
  final double anxietyLevel;
  final DateTime createdAt;

  _SNightEntry({
    required this.note,
    required this.type,
    this.anxietyLevel = 2.5,
  })  : id = '${DateTime.now().microsecondsSinceEpoch}',
        createdAt = DateTime.now();
}

class _SSound {
  final String emoji, name, description;
  final Color color;
  const _SSound({
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
  });
}

class _SMedCard {
  final String title, emoji, subtitle, duration, type;
  final Color color;
  const _SMedCard({
    required this.title,
    required this.emoji,
    required this.subtitle,
    required this.duration,
    required this.type,
    required this.color,
  });
}

class _SReminder {
  final String emoji, title, subtitle;
  final Color color;
  bool enabled;
  _SReminder({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    this.enabled = true,
  });
}

// ═══════════════════════════════════════════════════════════
//  SEED DATA
// ═══════════════════════════════════════════════════════════

const List<_SSound> _kSounds = [
  _SSound(emoji: '🌧️', name: 'Gentle Rain',  description: 'Soft rainfall on leaves',  color: _sTeal),
  _SSound(emoji: '🌊', name: 'Ocean Waves',   description: 'Rhythmic night tide',       color: Color(0xFF0288D1)),
  _SSound(emoji: '🎵', name: 'Sleep Music',   description: 'Dreamy lullabies',          color: _sPurple),
  _SSound(emoji: '⬜', name: 'White Noise',   description: 'Pure calming hum',          color: Color(0xFF78909C)),
  _SSound(emoji: '🌿', name: 'Forest Wind',   description: 'Whispering pines',          color: Color(0xFF66BB6A)),
  _SSound(emoji: '🔥', name: 'Fireplace',     description: 'Warm crackling fire',       color: Color(0xFFFF8A65)),
];

const List<_SMedCard> _kMedCards = [
  _SMedCard(title: '4-7-8 Breathing',  emoji: '🌬️', subtitle: 'Activate calm',      duration: '5 min',  type: 'breathing',   color: _sTeal),
  _SMedCard(title: 'Body Scan',         emoji: '✨',  subtitle: 'Melt into sleep',   duration: '10 min', type: 'visual',      color: _sPurple),
  _SMedCard(title: 'Sleep Affirmations',emoji: '💜',  subtitle: 'Emotional reset',   duration: '3 min',  type: 'affirmation', color: _sPink),
  _SMedCard(title: 'Anxiety Release',   emoji: '🌊',  subtitle: 'Let it all go',     duration: '7 min',  type: 'anxiety',     color: _sIndigo),
  _SMedCard(title: 'Moon Visualisation',emoji: '🌙',  subtitle: 'Drift to the moon', duration: '8 min',  type: 'visual',      color: Color(0xFF7B39BD)),
];

const List<String> _kSleepAffirms = [
  'I release the day and welcome peaceful, healing rest 🌙',
  'My body knows exactly how to restore itself as I sleep 💜',
  'I am safe, warm, and completely held right now ✨',
  'Tomorrow\'s worries are for tomorrow. Tonight I simply rest 🌸',
  'My mind grows still like a calm, moonlit sea 🌊',
  'I deserve this deep, restorative, sacred sleep 💫',
  'With every breath I sink deeper into calm 🌬️',
  'My dreams carry me gently through the night 🌙',
  'I wake tomorrow renewed, restored, and at peace ✨',
  'Sleep is my most beautiful act of self-love tonight 💜',
];

const List<(String, String)> _kAIInsights = [
  ('🌙', 'You sleep better after calm, screen-free evenings.'),
  ('💜', 'Stress this week may be shortening your deep sleep cycles.'),
  ('✨', 'Your emotional recovery score is steadily improving — keep going.'),
  ('🌊', 'Ocean sounds helped you fall asleep 18% faster last week.'),
  ('🌸', 'Your best sleep follows days with morning sunlight and gentle movement.'),
  ('🌬️', '4-7-8 breathing before bed is linked to fewer night interruptions.'),
  ('💫', 'Your sleep mood tracks closely with your menstrual cycle phase.'),
];

List<_SSleepEntry> _buildSeedEntries() {
  final now = DateTime.now();
  final rng = math.Random(42);
  final qualities = _SSleepQuality.values;
  final moods = _SSleepMood.values;
  return List.generate(7, (i) {
    final q = qualities[rng.nextInt(qualities.length)];
    return _SSleepEntry(
      hours:         6.0 + rng.nextDouble() * 2.5,
      deepHours:     1.5 + rng.nextDouble() * 1.5,
      interruptions: rng.nextInt(4),
      quality:       q,
      mood:          moods[rng.nextInt(moods.length)],
      date:          now.subtract(Duration(days: 6 - i)),
      energyScore:   5.0 + rng.nextDouble() * 5.0,
    );
  });
}

// ═══════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepState();
}

class _SleepState extends State<SleepScreen> with TickerProviderStateMixin {
  late AnimationController _glowCtrl, _floatCtrl, _moonCtrl,
      _particleCtrl, _breathCtrl;
  late Animation<double> _glowAnim, _floatAnim;

  final List<_SStar> _stars = [];
  final math.Random  _rng   = math.Random();

  // ── Sleep state ──────────────────────────────────────────
  late List<_SSleepEntry> _weekEntries;
  double         _sleepHours    = 7.2;
  double         _deepSleep     = 2.1;
  int            _interruptions = 2;
  _SSleepQuality _quality       = _SSleepQuality.good;
  _SSleepMood    _sleepMood     = _SSleepMood.calm;
  double         _energyScore   = 7.4;

  // ── UI state ─────────────────────────────────────────────
  int      _affirmIdx        = 0;
  _SSound? _activeSound;
  bool     _soundPlaying     = false;
  bool     _breathingActive  = false;
  int      _activeJournalType = 0;
  double   _anxietyLevel     = 2.5;

  final List<_SNightEntry>    _entries     = [];
  final TextEditingController _journalCtrl = TextEditingController();
  late  List<_SReminder>      _reminders;

  // ── Provider seed flag ──────────────────────────────────
  bool _loadedFromProvider = false;

  // ── Computed ─────────────────────────────────────────────
  int get _sleepScore => ((
    _quality.score * 0.40 +
    (_sleepHours / 9.0).clamp(0.0, 1.0) * 0.30 +
    (1.0 - (_interruptions / 5.0)).clamp(0.0, 1.0) * 0.15 +
    (_deepSleep / 3.0).clamp(0.0, 1.0) * 0.15
  ) * 100).round();

  String get _sleepScoreLabel {
    final s = _sleepScore;
    if (s >= 85) return 'Deeply Restored';
    if (s >= 70) return 'Well Rested';
    if (s >= 55) return 'Fairly Rested';
    if (s >= 40) return 'Lightly Rested';
    return 'Rest Needed';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedFromProvider) return;
    _loadedFromProvider = true;
    final last = context.read<LunarDataProvider>().lastSleepLog;
    if (last != null) {
      _sleepHours = last.hoursSlept;
      _quality = _SSleepQuality.values.firstWhere(
        (q) => q.name == last.quality,
        orElse: () => _SSleepQuality.good,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _affirmIdx   = DateTime.now().day % _kSleepAffirms.length;
    _weekEntries = _buildSeedEntries();
    _reminders = [
      _SReminder(emoji: '🌙', title: 'Bedtime Reminder',    subtitle: 'Wind down at 10:00 PM',      color: _sPurple),
      _SReminder(emoji: '💧', title: 'Hydration Reminder',  subtitle: 'Last glass before bed',       color: _sTeal,   enabled: false),
      _SReminder(emoji: '📱', title: 'Screen-Time Warning', subtitle: 'Reduce blue light at 9 PM',   color: _sPink),
      _SReminder(emoji: '💜', title: 'Emotional Check-In',  subtitle: 'Journal before you sleep',    color: _sIndigo, enabled: false),
    ];

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10.0, end: 10.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _moonCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    _breathCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 19));

    for (int i = 0; i < 42; i++) _stars.add(_SStar(rng: _rng));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _moonCtrl.dispose();
    _particleCtrl.dispose();
    _breathCtrl.dispose();
    _journalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _sBg,
        body: Stack(
          children: [
            _SBackground(size: size),
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _SParticlePainter(
                    stars: _stars, progress: _particleCtrl.value),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(children: [
                        const SizedBox(height: 14),
                        _headerBar(),
                        const SizedBox(height: 28),
                        _sleepOrbSection(),
                        const SizedBox(height: 24),
                        _sleepMetricsRow(),
                        const SizedBox(height: 24),
                        _aiInsightsStrip(),
                        const SizedBox(height: 24),
                        _sectionTitle('🌿', 'Night Wellness', _sTeal),
                        const SizedBox(height: 14),
                        _nightWellnessCards(),
                        const SizedBox(height: 24),
                        _sectionTitle('🌬️', 'Calm Audio', _sPurple),
                        const SizedBox(height: 14),
                        _calmAudioSection(),
                        const SizedBox(height: 24),
                        _breathingCard(),
                        const SizedBox(height: 24),
                        _sectionTitle('🌙', 'Night Meditation', _sPink),
                        const SizedBox(height: 14),
                      ]),
                    ),
                  ),
                  SliverToBoxAdapter(child: _meditationCardsRow()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(children: [
                        const SizedBox(height: 24),
                        _affirmationCard(),
                        const SizedBox(height: 24),
                        _sectionTitle('📊', 'Sleep Tracker', _sIndigo),
                        const SizedBox(height: 14),
                        _sleepTrackerCard(),
                        const SizedBox(height: 24),
                        _sectionTitle('💜', 'Night Journal', _sPurple),
                        const SizedBox(height: 14),
                        _journalSection(),
                        const SizedBox(height: 24),
                        _sectionTitle('🔔', 'Smart Reminders', _sTeal),
                        const SizedBox(height: 14),
                        _remindersSection(),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _headerBar() => Row(
    children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.07),
            border: Border.all(color: _sPurple.withOpacity(0.3)),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Night Sanctuary',
              style: TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          Text('Sleep + Emotional Wellness',
              style: TextStyle(color: _sPurple.withOpacity(0.8), fontSize: 12)),
        ]),
      ),
      _glassIconBtn(Icons.add_outlined, _sTeal, () => _showLogSleepSheet()),
      const SizedBox(width: 8),
      _glassIconBtn(Icons.settings_outlined, _sPurple, () => _showSettingsSheet()),
    ],
  );

  Widget _glassIconBtn(IconData icon, Color c, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: c.withOpacity(0.3)),
              ),
              child: Icon(icon, color: c, size: 18),
            ),
          ),
        ),
      );

  // ── Sleep Orb ─────────────────────────────────────────────
  Widget _sleepOrbSection() => AnimatedBuilder(
    animation: Listenable.merge([_glowCtrl, _floatCtrl]),
    builder: (_, __) => Transform.translate(
      offset: Offset(0, _floatAnim.value),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          Container(
            width: 220, height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _sPurple.withOpacity(0.22 * _glowAnim.value),
                    blurRadius: 90, spreadRadius: 30),
                BoxShadow(
                    color: _sPink.withOpacity(0.12 * _glowAnim.value),
                    blurRadius: 130, spreadRadius: 55),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _moonCtrl,
            builder: (_, __) => CustomPaint(
              size: const Size(210, 210),
              painter: _SOrbRingPainter(
                  progress: _moonCtrl.value, color: _sPurple),
            ),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: 170, height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _sDeep.withOpacity(0.88),
                    _sBg.withOpacity(0.82),
                  ]),
                  border: Border.all(
                    color: _sPurple.withOpacity(0.45 * _glowAnim.value),
                    width: 1.5,
                  ),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text('🌙',
                      style: TextStyle(fontSize: 38 + 5 * _glowAnim.value)),
                  const SizedBox(height: 2),
                  Text('$_sleepScore',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 36, fontWeight: FontWeight.w800,
                          height: 1.0)),
                  Text(_sleepScoreLabel,
                      style: TextStyle(
                          color: _sPurple.withOpacity(0.9), fontSize: 10.5,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Text("Last Night's Rest",
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 13)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _pillBadge(_quality.emoji, _quality.label, _quality.color),
          const SizedBox(width: 10),
          _pillBadge(_sleepMood.emoji, _sleepMood.label, _sleepMood.color),
        ]),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _showLogSleepSheet(),
          child: AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(colors: [
                  _sPurple.withOpacity(0.8), _sPink.withOpacity(0.7)]),
                boxShadow: [BoxShadow(
                    color: _sPurple.withOpacity(0.3 * _glowAnim.value),
                    blurRadius: 20)],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('🌙', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text('Log Tonight\'s Sleep',
                    style: TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ]),
    ),
  );

  Widget _pillBadge(String emoji, String label, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: c.withOpacity(0.15),
      border: Border.all(color: c.withOpacity(0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
          color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  // ── Metrics Row ───────────────────────────────────────────
  Widget _sleepMetricsRow() => Row(children: [
    Expanded(child: _metricTile('⏱', 'Duration',
        '${_sleepHours.toStringAsFixed(1)}h', _sPurple)),
    const SizedBox(width: 10),
    Expanded(child: _metricTile('💜', 'Deep Sleep',
        '${_deepSleep.toStringAsFixed(1)}h', _sPink)),
    const SizedBox(width: 10),
    Expanded(child: _metricTile('😴', 'Woke Up',
        '${_interruptions}x', _sTeal)),
    const SizedBox(width: 10),
    Expanded(child: _metricTile('⚡', 'Energy',
        _energyScore.toStringAsFixed(1), _sGold)),
  ]);

  Widget _metricTile(String emoji, String label, String value, Color c) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: c.withOpacity(0.22)),
            ),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 5),
              Text(value, style: TextStyle(
                  color: c, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(
                  color: Colors.white.withOpacity(0.42), fontSize: 9.5),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );

  // ── AI Insights ───────────────────────────────────────────
  Widget _aiInsightsStrip() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('✨', 'Lunar AI Insights', _sGold),
      const SizedBox(height: 12),
      SizedBox(
        height: 86,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _kAIInsights.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final insight = _kAIInsights[i];
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _sDeep.withOpacity(0.72),
                        _sBg.withOpacity(0.82),
                      ],
                    ),
                    border: Border.all(color: _sPurple.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Text(insight.$1,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(insight.$2,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12, height: 1.45)),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  // ── Night Wellness Cards ──────────────────────────────────
  Widget _nightWellnessCards() {
    const items = [
      ('🌙', 'Bedtime Routine',      'Wind down rituals for better rest',   _sPurple),
      ('💆', 'Emotional Relaxation', 'Release the day\'s tension gently',   _sPink),
      ('🌊', 'Stress Release',       'Let today dissolve with the tide',     _sTeal),
    ];
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => _showWellnessSheet(item.$2, item.$1, item.$4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(color: item.$4.withOpacity(0.22)),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.$4.withOpacity(0.15)),
                    child: Center(child: Text(item.$1,
                        style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item.$2, style: const TextStyle(
                        color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(item.$3, style: TextStyle(
                        color: Colors.white.withOpacity(0.46),
                        fontSize: 12)),
                  ])),
                  Icon(Icons.chevron_right_rounded,
                      color: item.$4.withOpacity(0.55), size: 20),
                ]),
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  // ── Calm Audio ────────────────────────────────────────────
  Widget _calmAudioSection() => Column(children: [
    GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: _kSounds.length,
      itemBuilder: (_, i) => _soundTile(_kSounds[i]),
    ),
    if (_activeSound != null && _soundPlaying) ...[
      const SizedBox(height: 14),
      _nowPlayingBar(),
    ],
  ]);

  Widget _soundTile(_SSound s) {
    final isActive = _activeSound?.name == s.name && _soundPlaying;
    return GestureDetector(
      onTap: () => setState(() {
        if (isActive) {
          _soundPlaying = false;
          _activeSound  = null;
        } else {
          _activeSound  = s;
          _soundPlaying = true;
        }
      }),
      child: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isActive
                    ? LinearGradient(colors: [
                        s.color.withOpacity(0.35 + 0.15 * _glowAnim.value),
                        _sDeep.withOpacity(0.72),
                      ])
                    : null,
                color: isActive ? null : Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: isActive
                      ? s.color.withOpacity(0.6 + 0.3 * _glowAnim.value)
                      : s.color.withOpacity(0.15),
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(s.name, style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.65),
                      fontSize: 10.5, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                  if (isActive) ...[
                    const SizedBox(height: 5),
                    _waveIndicator(s.color),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _waveIndicator(Color c) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(4, (i) => AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) {
        final h = 4.0 +
            6.0 * math.sin(_glowCtrl.value * math.pi * 2 + i * 1.1).abs();
        return Container(
          width: 3, height: h,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
              color: c, borderRadius: BorderRadius.circular(2)),
        );
      },
    )),
  );

  Widget _nowPlayingBar() => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [
            _sDeep.withOpacity(0.85), _sBg.withOpacity(0.9)]),
          border: Border.all(color: _sPurple.withOpacity(0.3)),
        ),
        child: Row(children: [
          Text(_activeSound!.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_activeSound!.name, style: const TextStyle(
                color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w600)),
            Text(_activeSound!.description, style: TextStyle(
                color: Colors.white.withOpacity(0.45), fontSize: 11)),
          ])),
          GestureDetector(
            onTap: () => setState(() {
              _soundPlaying = false;
              _activeSound  = null;
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _sPurple.withOpacity(0.2),
                border: Border.all(color: _sPurple.withOpacity(0.4)),
              ),
              child: const Icon(Icons.stop_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ]),
      ),
    ),
  );

  // ── Breathing Card ────────────────────────────────────────
  Widget _breathingCard() => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_sDeep.withOpacity(0.75), _sBg.withOpacity(0.85)]),
          border: Border.all(color: _sTeal.withOpacity(0.3)),
        ),
        child: Column(children: [
          Row(children: [
            const Text('🌬️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('4-7-8 Breathing', style: TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700)),
                Text('Calms the nervous system',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ]),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _breathingActive = !_breathingActive;
                if (_breathingActive) {
                  _breathCtrl.repeat();
                } else {
                  _breathCtrl.stop();
                  _breathCtrl.reset();
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: [_sTeal, _sPurple]),
                ),
                child: Text(_breathingActive ? 'Stop' : 'Start',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 22),
          AnimatedBuilder(
            animation: _breathCtrl,
            builder: (_, __) {
              // 4s inhale | 7s hold | 8s exhale = 19s total
              final t = _breathCtrl.value;
              const inhaleEnd = 4.0 / 19.0;
              const holdEnd   = 11.0 / 19.0;

              String phaseLabel;
              double scale;
              Color  ringColor;

              if (!_breathingActive) {
                phaseLabel = '🌙';
                scale      = 0.75;
                ringColor  = _sTeal;
              } else if (t < inhaleEnd) {
                phaseLabel = 'Inhale';
                scale      = 0.55 + 0.45 * (t / inhaleEnd);
                ringColor  = _sTeal;
              } else if (t < holdEnd) {
                phaseLabel = 'Hold';
                scale      = 1.0;
                ringColor  = _sPurple;
              } else {
                phaseLabel = 'Exhale';
                scale      = 1.0 - 0.45 * ((t - holdEnd) / (1.0 - holdEnd));
                ringColor  = _sPink;
              }

              return Column(children: [
                SizedBox(
                  width: 140, height: 140,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: ringColor.withOpacity(0.18), width: 1),
                      ),
                    ),
                    Container(
                      width: 100 * scale, height: 100 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          ringColor.withOpacity(0.55),
                          ringColor.withOpacity(0.08),
                        ]),
                        boxShadow: [BoxShadow(
                            color: ringColor.withOpacity(0.3),
                            blurRadius: 30, spreadRadius: 4)],
                      ),
                    ),
                    Text(phaseLabel, style: TextStyle(
                        color: Colors.white,
                        fontSize: _breathingActive ? 13.0 : 32.0,
                        fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 14),
                Text(
                  _breathingActive
                      ? 'Activating your parasympathetic nervous system…'
                      : 'Tap Start to begin your calming breath cycle',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.52),
                      fontSize: 12, height: 1.5),
                ),
              ]);
            },
          ),
        ]),
      ),
    ),
  );

  // ── Meditation Cards Row ──────────────────────────────────
  Widget _meditationCardsRow() => SizedBox(
    height: 152,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _kMedCards.length,
      itemBuilder: (_, i) {
        final card = _kMedCards[i];
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _showMeditationSheet(card),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          card.color.withOpacity(0.3),
                          _sDeep.withOpacity(0.72),
                        ]),
                    border: Border.all(color: card.color.withOpacity(0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.emoji,
                          style: const TextStyle(fontSize: 28)),
                      const Spacer(),
                      Text(card.title, style: const TextStyle(
                          color: Colors.white, fontSize: 11.5,
                          fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(card.subtitle, style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10)),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: card.color.withOpacity(0.2)),
                        child: Text(card.duration, style: TextStyle(
                            color: card.color, fontSize: 9.5,
                            fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  // ── Affirmation Card ──────────────────────────────────────
  Widget _affirmationCard() => GestureDetector(
    onTap: () => setState(() =>
        _affirmIdx = (_affirmIdx + 1) % _kSleepAffirms.length),
    child: AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _sPurple.withOpacity(0.18 + 0.08 * _glowAnim.value),
                    _sDeep.withOpacity(0.82),
                  ]),
              border: Border.all(
                  color: _sPurple.withOpacity(0.28 + 0.15 * _glowAnim.value)),
            ),
            child: Column(children: [
              const Text('💜', style: TextStyle(fontSize: 28)),
              const SizedBox(height: 12),
              Text(_kSleepAffirms[_affirmIdx],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 15.5, height: 1.65,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 14),
              Text('Tap for another affirmation 🌙',
                  style: TextStyle(
                      color: _sPurple.withOpacity(0.58), fontSize: 11)),
            ]),
          ),
        ),
      ),
    ),
  );

  // ── Sleep Tracker ─────────────────────────────────────────
  Widget _sleepTrackerCard() => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: _sIndigo.withOpacity(0.25)),
        ),
        child: Column(children: [
          Row(children: [
            Expanded(child: _trackStat('😴', 'Avg Sleep',
                '${(_weekEntries.map((e) => e.hours).reduce((a, b) => a + b) / 7).toStringAsFixed(1)}h',
                _sPurple)),
            const SizedBox(width: 12),
            Expanded(child: _trackStat('💜', 'Deep Avg',
                '${(_weekEntries.map((e) => e.deepHours).reduce((a, b) => a + b) / 7).toStringAsFixed(1)}h',
                _sPink)),
            const SizedBox(width: 12),
            Expanded(child: _trackStat('⚡', 'Avg Energy',
                (_weekEntries.map((e) => e.energyScore).reduce((a, b) => a + b) / 7).toStringAsFixed(1),
                _sGold)),
          ]),
          const SizedBox(height: 22),
          SizedBox(
            height: 88,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_weekEntries.length, (i) {
                final entry   = _weekEntries[i];
                final frac    = (entry.hours / 9.0).clamp(0.0, 1.0);
                final isToday = i == _weekEntries.length - 1;
                const days    = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Expanded(child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(child: FractionallySizedBox(
                      heightFactor: frac,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isToday
                                ? [_sPurple, _sPink]
                                : [_sIndigo.withOpacity(0.65),
                                    _sDeep.withOpacity(0.5)],
                          ),
                        ),
                      ),
                    )),
                    const SizedBox(height: 6),
                    Text(days[i % 7], style: TextStyle(
                        color: isToday
                            ? _sPurple
                            : Colors.white.withOpacity(0.35),
                        fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ));
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: _sPurple)),
            const SizedBox(width: 6),
            Expanded(child: Text(
                'Your mood score improves significantly on 7+ hour nights 🌙',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.42),
                    fontSize: 11, fontStyle: FontStyle.italic))),
          ]),
        ]),
      ),
    ),
  );

  Widget _trackStat(String emoji, String label, String value, Color c) =>
      Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
            color: c, fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(
            color: Colors.white.withOpacity(0.38), fontSize: 10)),
      ]);

  // ── Night Journal ─────────────────────────────────────────
  Widget _journalSection() => Column(children: [
    SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _SJournalType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t  = _SJournalType.values[i];
          final on = _activeJournalType == i;
          return GestureDetector(
            onTap: () => setState(() => _activeJournalType = i),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: on
                    ? t.color.withOpacity(0.25)
                    : Colors.white.withOpacity(0.05),
                border: Border.all(
                    color: on
                        ? t.color.withOpacity(0.55)
                        : Colors.white.withOpacity(0.08)),
              ),
              child: Text('${t.emoji} ${t.label}',
                  style: TextStyle(
                      color: on ? t.color : Colors.white.withOpacity(0.48),
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    ),
    const SizedBox(height: 12),
    ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: _sPurple.withOpacity(0.2)),
          ),
          child: Column(children: [
            TextField(
              controller: _journalCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _hintForType(
                    _SJournalType.values[_activeJournalType]),
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.28), fontSize: 13),
                border: InputBorder.none,
              ),
            ),
            if (_SJournalType.values[_activeJournalType] ==
                _SJournalType.anxiety) ...[
              const SizedBox(height: 8),
              Row(children: [
                Text('Anxiety level: ', style: TextStyle(
                    color: Colors.white.withOpacity(0.52), fontSize: 12)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      thumbColor: _sTeal,
                      activeTrackColor: _sTeal,
                      inactiveTrackColor: _sTeal.withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7),
                      trackHeight: 3,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: _anxietyLevel, min: 0, max: 5,
                      onChanged: (v) => setState(() => _anxietyLevel = v),
                    ),
                  ),
                ),
                Text(_anxietyLevel.toStringAsFixed(1),
                    style: const TextStyle(color: _sTeal, fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _submitJournalEntry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(colors: [_sPurple, _sPink]),
                  ),
                  child: const Text('Save Entry 🌙',
                      style: TextStyle(color: Colors.white,
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ),
      ),
    ),
    if (_entries.isNotEmpty) ...[
      const SizedBox(height: 14),
      ..._entries.reversed.take(4).map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _entryCard(e),
      )),
    ],
  ]);

  String _hintForType(_SJournalType t) => switch (t) {
    _SJournalType.dream    => 'Describe your dream… 🌙',
    _SJournalType.emotion  => 'How are you feeling tonight? 💜',
    _SJournalType.anxiety  => 'What\'s weighing on your mind? 🌊',
    _SJournalType.thoughts => 'Last gentle thoughts before sleep… ✨',
  };

  void _submitJournalEntry() {
    final text = _journalCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _entries.add(_SNightEntry(
        note:         text,
        type:         _SJournalType.values[_activeJournalType],
        anxietyLevel: _anxietyLevel,
      ));
      _journalCtrl.clear();
    });
    HapticFeedback.lightImpact();
  }

  Widget _entryCard(_SNightEntry e) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: e.type.color.withOpacity(0.22)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.type.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.note, style: const TextStyle(
                color: Colors.white, fontSize: 12.5, height: 1.45),
                maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(_timeAgo(e.createdAt), style: TextStyle(
                color: Colors.white.withOpacity(0.32), fontSize: 10)),
          ])),
        ]),
      ),
    ),
  );

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1)  return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24)   return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  // ── Reminders ─────────────────────────────────────────────
  Widget _remindersSection() => Column(
    children: _reminders.map((r) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: r.color.withOpacity(0.22)),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: r.color.withOpacity(0.15)),
                child: Center(child: Text(r.emoji,
                    style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(r.title, style: const TextStyle(
                    color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(r.subtitle, style: TextStyle(
                    color: Colors.white.withOpacity(0.42), fontSize: 11)),
              ])),
              Switch(
                value: r.enabled,
                activeColor: r.color,
                inactiveThumbColor: Colors.white.withOpacity(0.3),
                inactiveTrackColor: Colors.white.withOpacity(0.08),
                onChanged: (v) => setState(() => r.enabled = v),
              ),
            ]),
          ),
        ),
      ),
    )).toList(),
  );

  // ── Section Title ─────────────────────────────────────────
  Widget _sectionTitle(String emoji, String title, Color c) =>
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 17)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: c.withOpacity(0.22))),
      ]);

  // ── Bottom Sheets ─────────────────────────────────────────
  void _showLogSleepSheet() {
    double tmpHours   = _sleepHours;
    double tmpDeep    = _deepSleep;
    int    tmpWakeups = _interruptions;
    _SSleepQuality tmpQual = _quality;
    _SSleepMood    tmpMood = _sleepMood;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => _glassSheet(
          title: '🌙  Log Tonight\'s Sleep',
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetSlider('⏱ Sleep hours',
                '${tmpHours.toStringAsFixed(1)}h',
                tmpHours, 4.0, 10.0, _sPurple,
                (v) => setS(() => tmpHours = v)),
            const SizedBox(height: 14),
            _sheetSlider('💜 Deep sleep',
                '${tmpDeep.toStringAsFixed(1)}h',
                tmpDeep, 0.5, 4.0, _sPink,
                (v) => setS(() => tmpDeep = v)),
            const SizedBox(height: 14),
            Row(children: [
              Text('😴 Wake-ups:', style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 13)),
              const SizedBox(width: 10),
              ...List.generate(6, (i) => GestureDetector(
                onTap: () => setS(() => tmpWakeups = i),
                child: Container(
                  width: 32, height: 32,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tmpWakeups == i
                        ? _sTeal.withOpacity(0.3)
                        : Colors.white.withOpacity(0.06),
                    border: Border.all(
                        color: tmpWakeups == i
                            ? _sTeal : Colors.white.withOpacity(0.1)),
                  ),
                  child: Center(child: Text('$i',
                      style: TextStyle(
                          color: tmpWakeups == i
                              ? _sTeal : Colors.white54,
                          fontSize: 12))),
                ),
              )),
            ]),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('✨ Quality', style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Row(
              children: _SSleepQuality.values.map((q) => Expanded(
                child: GestureDetector(
                  onTap: () => setS(() => tmpQual = q),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: tmpQual == q
                          ? q.color.withOpacity(0.25)
                          : Colors.white.withOpacity(0.04),
                      border: Border.all(
                          color: tmpQual == q
                              ? q.color.withOpacity(0.5)
                              : Colors.white.withOpacity(0.07)),
                    ),
                    child: Column(children: [
                      Text(q.emoji, style: const TextStyle(fontSize: 14)),
                      Text(q.label, style: TextStyle(
                          color: tmpQual == q ? q.color : Colors.white38,
                          fontSize: 8.5),
                          textAlign: TextAlign.center),
                    ]),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('💜 Sleep mood', style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Row(
              children: _SSleepMood.values.map((m) => Expanded(
                child: GestureDetector(
                  onTap: () => setS(() => tmpMood = m),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: tmpMood == m
                          ? m.color.withOpacity(0.25)
                          : Colors.white.withOpacity(0.04),
                      border: Border.all(
                          color: tmpMood == m
                              ? m.color.withOpacity(0.5)
                              : Colors.white.withOpacity(0.07)),
                    ),
                    child: Column(children: [
                      Text(m.emoji, style: const TextStyle(fontSize: 14)),
                      Text(m.label, style: TextStyle(
                          color: tmpMood == m ? m.color : Colors.white38,
                          fontSize: 8.5),
                          textAlign: TextAlign.center),
                    ]),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                setState(() {
                  _sleepHours    = tmpHours;
                  _deepSleep     = tmpDeep;
                  _interruptions = tmpWakeups;
                  _quality       = tmpQual;
                  _sleepMood     = tmpMood;
                  _energyScore   = (tmpQual.score * 10.0).clamp(0.0, 10.0);
                  _weekEntries[_weekEntries.length - 1] = _SSleepEntry(
                    hours:         tmpHours,
                    deepHours:     tmpDeep,
                    interruptions: tmpWakeups,
                    quality:       tmpQual,
                    mood:          tmpMood,
                    date:          DateTime.now(),
                    energyScore:   tmpQual.score * 10.0,
                  );
                });
                // Persist to LunarDataProvider → HealthRepository → SharedPreferences
                context.read<LunarDataProvider>().logSleep(
                  hours: tmpHours,
                  quality: tmpQual.name,
                  note: tmpMood.label,
                );
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(colors: [_sPurple, _sPink]),
                ),
                child: const Text('Save Sleep Log 🌙',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sheetSlider(String label, String val,
      double current, double min, double max, Color c,
      ValueChanged<double> onChange) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: TextStyle(
              color: Colors.white.withOpacity(0.7), fontSize: 13)),
          const Spacer(),
          Text(val, style: TextStyle(
              color: c, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        SliderTheme(
          data: SliderThemeData(
            thumbColor: c, activeTrackColor: c,
            inactiveTrackColor: c.withOpacity(0.18),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 3,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
              value: current, min: min, max: max, onChanged: onChange),
        ),
      ]);

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _glassSheet(
        title: '⚙️  Sleep Settings',
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _settingTile('💤', 'Sleep Goal',         '8 hours per night',              _sPurple),
          const SizedBox(height: 10),
          _settingTile('📊', 'Wearable Sync',      'Connect a device (coming soon)', _sTeal),
          const SizedBox(height: 10),
          _settingTile('🔔', 'Smart Reminders',    'Configured in Reminders section',_sPink),
          const SizedBox(height: 10),
          _settingTile('🌙', 'Cycle Integration',  'Sleep tied to your cycle phase', _sGold),
          const SizedBox(height: 10),
          _settingTile('💜', 'Emotional Analytics','Recovery tracking enabled',      _sIndigo),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _settingTile(String emoji, String title, String sub, Color c) =>
      Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: c.withOpacity(0.15)),
          child: Center(child: Text(emoji,
              style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white,
              fontSize: 13, fontWeight: FontWeight.w600)),
          Text(sub, style: TextStyle(
              color: Colors.white.withOpacity(0.43), fontSize: 11)),
        ])),
        Icon(Icons.chevron_right_rounded,
            color: c.withOpacity(0.5), size: 18),
      ]);

  void _showWellnessSheet(String title, String emoji, Color c) {
    final Map<String, List<String>> tips = {
      'Bedtime Routine': [
        '🕯️  Dim every light in your space 60 minutes before bed',
        '📵  Place your phone face-down or in another room at 9 PM',
        '🛁  A warm bath lowers your core temperature — key to deep sleep',
        '📖  Read fiction — it quiets analytical thought beautifully',
        '🫖  Chamomile or magnesium glycinate tea is deeply calming',
      ],
      'Emotional Relaxation': [
        '📓  Write tomorrow\'s worries down — then gently close the book',
        '💜  Name three things you\'re grateful for right now',
        '🤗  Give yourself a slow, intentional self-hug',
        '🎵  Listen to music at 60 BPM or slower — it matches rest rhythms',
        '🌸  Forgive yourself for today\'s imperfections with tenderness',
      ],
      'Stress Release': [
        '🌊  Progressive muscle relaxation: tense each body part, then release',
        '🌬️  4-7-8 breathing: inhale 4, hold 7, exhale 8 — three rounds',
        '✍️  Brain-dump everything on your mind onto paper, then put it away',
        '🙏  A 5-minute body scan meditation dissolves physical tension',
        '💜  Remind yourself softly: this day is complete. You did enough.',
      ],
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _glassSheet(
        title: '$emoji  $title',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: (tips[title] ?? []).map((tip) {
            final parts = tip.split('  ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(parts.first, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                    parts.length > 1 ? parts.last : tip,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 13, height: 1.5))),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMeditationSheet(_SMedCard card) {
    const Map<String, String> scripts = {
      'breathing':
          'Close your eyes. Inhale through your nose for 4 counts… Hold gently for 7… '
          'Now exhale completely through your mouth for 8. Feel the tension dissolving with every exhale. '
          'Your nervous system is calming. You are safe. You are held. 🌬️',
      'visual':
          'Imagine floating gently on a still, moonlit lake. The water is warm. '
          'Stars reflect all around you. With every breath, you drift further from the shore of the day. '
          'Your body is weightless. Your mind grows beautifully quiet. 🌙',
      'affirmation':
          'I release this day with love. I am exactly where I need to be. '
          'My body is a sanctuary of healing. Tonight I rest deeply. Tomorrow I rise renewed. '
          'I am worthy of this peace. I am completely, lovingly held. 💜',
      'anxiety':
          'Place one hand gently on your heart. Notice it beating — steady, faithful, yours. '
          'Every worry you carry tonight can rest here beside you. '
          'You don\'t have to solve anything right now. You are allowed to just breathe, just be, just rest. 🌊',
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _glassSheet(
        title: '${card.emoji}  ${card.title}',
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: card.color.withOpacity(0.15),
            ),
            child: Text(card.duration, style: TextStyle(
                color: card.color, fontSize: 12,
                fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 18),
          Text(scripts[card.type] ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14, height: 1.75)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                    colors: [card.color, _sDeep]),
              ),
              child: const Text('Drift to sleep 🌙',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _glassSheet({required String title, required Widget child}) =>
      ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28)),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _sDeep.withOpacity(0.9),
                    _sBg.withOpacity(0.96),
                  ]),
              border: Border(top: BorderSide(
                  color: _sPurple.withOpacity(0.25), width: 1)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 18),
              Text(title, style: const TextStyle(color: Colors.white,
                  fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              child,
            ]),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════
//  DREAMY NIGHT BACKGROUND
// ═══════════════════════════════════════════════════════════

class _SBackground extends StatelessWidget {
  final Size size;
  const _SBackground({required this.size});

  @override
  Widget build(BuildContext context) =>
      SizedBox.expand(child: CustomPaint(painter: _SBgPainter()));
}

class _SBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF050114), Color(0xFF07021C), Color(0xFF0A0330)],
      ).createShader(rect));
    final blobs = [
      (size.width * 0.15, size.height * 0.08, 160.0, const Color(0xFF2D0B5C)),
      (size.width * 0.82, size.height * 0.22, 140.0, const Color(0xFF1A0A3B)),
      (size.width * 0.50, size.height * 0.48, 190.0, const Color(0xFF1C0540)),
      (size.width * 0.08, size.height * 0.72, 120.0, const Color(0xFF0D1B4B)),
      (size.width * 0.88, size.height * 0.88, 155.0, const Color(0xFF260A50)),
    ];
    for (final b in blobs) {
      canvas.drawCircle(
        Offset(b.$1, b.$2), b.$3,
        Paint()
          ..shader = RadialGradient(
            colors: [b.$4.withOpacity(0.5), Colors.transparent],
          ).createShader(
              Rect.fromCircle(center: Offset(b.$1, b.$2), radius: b.$3))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );
    }
  }

  @override
  bool shouldRepaint(_SBgPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
//  STAR PARTICLE SYSTEM
// ═══════════════════════════════════════════════════════════

class _SStar {
  final double x, y, size, speed, twinkleOffset;
  _SStar({required math.Random rng})
      : x             = rng.nextDouble(),
        y             = rng.nextDouble(),
        size          = 0.7 + rng.nextDouble() * 2.4,
        speed         = 0.002 + rng.nextDouble() * 0.003,
        twinkleOffset = rng.nextDouble();
}

class _SParticlePainter extends CustomPainter {
  final List<_SStar> stars;
  final double       progress;
  const _SParticlePainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final drift   = (progress * s.speed * size.height) % size.height;
      final dy      = (s.y * size.height + drift) % size.height;
      final twinkle = 0.3 + 0.7 *
          math.sin((progress + s.twinkleOffset) * math.pi * 2).abs();
      final paint = Paint()
        ..color = Colors.white.withOpacity(twinkle * 0.7)
        ..strokeWidth = s.size * 0.55
        ..style = PaintingStyle.stroke;
      final cx = s.x * size.width, r = s.size;
      canvas.drawLine(Offset(cx - r, dy), Offset(cx + r, dy), paint);
      canvas.drawLine(Offset(cx, dy - r), Offset(cx, dy + r), paint);
    }
  }

  @override
  bool shouldRepaint(_SParticlePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════
//  ORBITAL RING PAINTER
// ═══════════════════════════════════════════════════════════

class _SOrbRingPainter extends CustomPainter {
  final double progress;
  final Color  color;
  const _SOrbRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r  = size.width / 2 - 8;

    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = color.withOpacity(0.12));

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [color.withOpacity(0.85), color.withOpacity(0.0)],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      progress * math.pi * 2,
      math.pi * 1.3,
      false,
      arcPaint,
    );

    final dotAngle = progress * math.pi * 2;
    canvas.drawCircle(
      Offset(cx + r * math.cos(dotAngle), cy + r * math.sin(dotAngle)),
      3.5,
      Paint()..color = color.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(_SOrbRingPainter old) => old.progress != progress;
}
