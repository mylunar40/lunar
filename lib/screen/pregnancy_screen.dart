import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/lunar_data_provider.dart';

// ═══════════════════════════════════════════════════════════
//  LUNAR PREGNANCY COMPANION — Warm Emotional Journey
// ═══════════════════════════════════════════════════════════

// ── Design tokens ─────────────────────────────────────────
const Color _pBg = Color(0xFF0A0118);
const Color _pPurple = Color(0xFFAB5CF2);
const Color _pPink = Color(0xFFFF69B4);
const Color _pDeep = Color(0xFF5C2DB8);
const Color _pGold = Color(0xFFFFD700);
const Color _pWarm = Color(0xFFFFB74D);

// ═══════════════════════════════════════════════════════════
//  GROWTH DATA MODEL
// ═══════════════════════════════════════════════════════════

class _PWeekData {
  final String fruit,
      fruitEmoji,
      sizeDesc,
      lengthCm,
      weightG,
      milestone,
      emotionalMsg;
  const _PWeekData({
    required this.fruit,
    required this.fruitEmoji,
    required this.sizeDesc,
    required this.lengthCm,
    required this.weightG,
    required this.milestone,
    required this.emotionalMsg,
  });
}

// ═══════════════════════════════════════════════════════════
//  PREGNANCY GROWTH ENGINE
// ═══════════════════════════════════════════════════════════

class _PGrowthEngine {
  static const Map<int, _PWeekData> _weeks = {
    4: _PWeekData(
        fruit: 'Poppy Seed',
        fruitEmoji: '🌸',
        sizeDesc: 'Poppy seed size',
        lengthCm: '0.1',
        weightG: '<1',
        milestone: 'Neural tube forming',
        emotionalMsg:
            'A tiny miracle is beginning. Your body already knows exactly what to do 💜'),
    5: _PWeekData(
        fruit: 'Apple Seed',
        fruitEmoji: '🍎',
        sizeDesc: 'Apple seed size',
        lengthCm: '0.13',
        weightG: '<1',
        milestone: 'Heart begins to beat',
        emotionalMsg:
            'That tiny flicker is a heartbeat. Love in its very first form 🌙'),
    6: _PWeekData(
        fruit: 'Sweet Pea',
        fruitEmoji: '🫛',
        sizeDesc: 'Sweet pea size',
        lengthCm: '0.6',
        weightG: '<1',
        milestone: 'Brain & spine forming',
        emotionalMsg:
            'Your baby\'s brain is waking up. You are growing a universe 🌟'),
    7: _PWeekData(
        fruit: 'Blueberry',
        fruitEmoji: '🫐',
        sizeDesc: 'Blueberry size',
        lengthCm: '1.3',
        weightG: '<1',
        milestone: 'Hands & feet forming',
        emotionalMsg:
            'Tiny hands are starting to form — ones that will hold yours forever 🌸'),
    8: _PWeekData(
        fruit: 'Raspberry',
        fruitEmoji: '🍓',
        sizeDesc: 'Raspberry size',
        lengthCm: '1.6',
        weightG: '1',
        milestone: 'Eyes forming',
        emotionalMsg:
            'Eyes that will look at you with pure wonder are forming now ✨'),
    9: _PWeekData(
        fruit: 'Grape',
        fruitEmoji: '🍇',
        sizeDesc: 'Grape size',
        lengthCm: '2.3',
        weightG: '2',
        milestone: 'Fingerprints forming',
        emotionalMsg:
            'Fingerprints — unique to your baby alone — are being etched this week 💜'),
    10: _PWeekData(
        fruit: 'Kumquat',
        fruitEmoji: '🍊',
        sizeDesc: 'Kumquat size',
        lengthCm: '3.1',
        weightG: '4',
        milestone: 'Organs almost complete',
        emotionalMsg:
            'All organs are nearly formed. You are nourishing something extraordinary 🌙'),
    11: _PWeekData(
        fruit: 'Fig',
        fruitEmoji: '🌿',
        sizeDesc: 'Fig size',
        lengthCm: '4.1',
        weightG: '7',
        milestone: 'Hiccups beginning',
        emotionalMsg:
            'Your baby is practising hiccups — getting ready for the big beautiful world 🌸'),
    12: _PWeekData(
        fruit: 'Lime',
        fruitEmoji: '🍋',
        sizeDesc: 'Lime size',
        lengthCm: '5.4',
        weightG: '14',
        milestone: 'End of first trimester',
        emotionalMsg:
            'First trimester complete! You have been incredible. Your strength is breathtaking 💫'),
    13: _PWeekData(
        fruit: 'Lemon',
        fruitEmoji: '🍋',
        sizeDesc: 'Lemon size',
        lengthCm: '7.4',
        weightG: '23',
        milestone: 'Fingerprints complete',
        emotionalMsg:
            'You\'ve crossed into the second trimester. The energy shift is coming 🌟'),
    14: _PWeekData(
        fruit: 'Peach',
        fruitEmoji: '🍑',
        sizeDesc: 'Peach size',
        lengthCm: '8.7',
        weightG: '43',
        milestone: 'Baby can squint & frown',
        emotionalMsg:
            'Your baby is making expressions — practising for all the smiles ahead ✨'),
    15: _PWeekData(
        fruit: 'Apple',
        fruitEmoji: '🍎',
        sizeDesc: 'Apple size',
        lengthCm: '10.1',
        weightG: '70',
        milestone: 'Baby hears your voice',
        emotionalMsg:
            'Talk, sing, whisper — your baby can hear you now. Your voice is their first lullaby 💜'),
    16: _PWeekData(
        fruit: 'Avocado',
        fruitEmoji: '🥑',
        sizeDesc: 'Avocado size',
        lengthCm: '11.6',
        weightG: '100',
        milestone: 'First movements!',
        emotionalMsg:
            'Tiny flutters you feel? That is your baby dancing to the sound of your heartbeat 🌙'),
    17: _PWeekData(
        fruit: 'Turnip',
        fruitEmoji: '🌱',
        sizeDesc: 'Turnip size',
        lengthCm: '13.0',
        weightG: '140',
        milestone: 'Swallowing practice',
        emotionalMsg:
            'Your baby is swallowing amniotic fluid — tasting the world you\'ve created 🌸'),
    18: _PWeekData(
        fruit: 'Bell Pepper',
        fruitEmoji: '🫑',
        sizeDesc: 'Bell pepper size',
        lengthCm: '14.2',
        weightG: '190',
        milestone: 'Kicks getting stronger',
        emotionalMsg:
            'Those little kicks are love notes in the only language baby knows right now 💜'),
    19: _PWeekData(
        fruit: 'Mango',
        fruitEmoji: '🥭',
        sizeDesc: 'Mango size',
        lengthCm: '15.3',
        weightG: '240',
        milestone: 'Sleep cycles begin',
        emotionalMsg:
            'Your baby is dreaming now — growing peacefully inside your warmth 🌟'),
    20: _PWeekData(
        fruit: 'Banana',
        fruitEmoji: '🍌',
        sizeDesc: 'Banana size',
        lengthCm: '16.4',
        weightG: '300',
        milestone: 'Halfway there! 🎉',
        emotionalMsg:
            'Halfway! Halfway to meeting the greatest love of your life. You are doing beautifully ✨'),
    21: _PWeekData(
        fruit: 'Carrot',
        fruitEmoji: '🥕',
        sizeDesc: 'Carrot size',
        lengthCm: '26.7',
        weightG: '360',
        milestone: 'Eyebrows forming',
        emotionalMsg:
            'Those tiny eyebrows will raise at everything new and wonderful they discover 🌸'),
    22: _PWeekData(
        fruit: 'Coconut',
        fruitEmoji: '🥥',
        sizeDesc: 'Coconut weight',
        lengthCm: '27.8',
        weightG: '430',
        milestone: 'Lanugo appears',
        emotionalMsg:
            'A soft coat of downy hair protects your baby — nature\'s tender design 💜'),
    23: _PWeekData(
        fruit: 'Grapefruit',
        fruitEmoji: '🍊',
        sizeDesc: 'Grapefruit size',
        lengthCm: '28.9',
        weightG: '500',
        milestone: 'Sense of touch develops',
        emotionalMsg:
            'Your baby is feeling, sensing, and growing more aware of your loving presence 🌙'),
    24: _PWeekData(
        fruit: 'Corn',
        fruitEmoji: '🌽',
        sizeDesc: 'Corn on the cob',
        lengthCm: '30.0',
        weightG: '600',
        milestone: 'Viability milestone',
        emotionalMsg:
            'A huge milestone — baby is now viable. Every day is a gift of becoming 🌟'),
    25: _PWeekData(
        fruit: 'Cauliflower',
        fruitEmoji: '🥦',
        sizeDesc: 'Cauliflower size',
        lengthCm: '34.6',
        weightG: '660',
        milestone: 'Nostrils opening',
        emotionalMsg:
            'Your baby is preparing to take their first breath — the breath that will change everything ✨'),
    26: _PWeekData(
        fruit: 'Lettuce',
        fruitEmoji: '🥬',
        sizeDesc: 'Lettuce head',
        lengthCm: '35.6',
        weightG: '760',
        milestone: 'Eyes opening',
        emotionalMsg:
            'Those precious eyes are opening for the very first time. Light is entering their world 💜'),
    27: _PWeekData(
        fruit: 'Rutabaga',
        fruitEmoji: '🟣',
        sizeDesc: 'Rutabaga size',
        lengthCm: '36.6',
        weightG: '875',
        milestone: 'Third trimester begins',
        emotionalMsg:
            'Final stretch, beautiful mama. Every day now is a step closer to the most magical meeting 🌸'),
    28: _PWeekData(
        fruit: 'Eggplant',
        fruitEmoji: '🍆',
        sizeDesc: 'Eggplant size',
        lengthCm: '37.6',
        weightG: '1005',
        milestone: 'Brain folds forming',
        emotionalMsg:
            'Your baby\'s brain is creating folds and connections — intelligence blossoming 🌙'),
    29: _PWeekData(
        fruit: 'Squash',
        fruitEmoji: '🎃',
        sizeDesc: 'Butternut squash',
        lengthCm: '38.6',
        weightG: '1150',
        milestone: 'Fat layers forming',
        emotionalMsg:
            'Soft baby fat is forming — those gorgeous chubby cheeks are on their way 💫'),
    30: _PWeekData(
        fruit: 'Cabbage',
        fruitEmoji: '🥬',
        sizeDesc: 'Cabbage size',
        lengthCm: '39.9',
        weightG: '1300',
        milestone: 'Bone marrow active',
        emotionalMsg:
            'Your baby is making its own blood now. Life supporting life — extraordinary 🌟'),
    31: _PWeekData(
        fruit: 'Pineapple',
        fruitEmoji: '🍍',
        sizeDesc: 'Pineapple size',
        lengthCm: '41.1',
        weightG: '1500',
        milestone: 'Rapid brain growth',
        emotionalMsg:
            'Their brain is developing at an incredible pace. You are growing a brilliant mind ✨'),
    32: _PWeekData(
        fruit: 'Squash',
        fruitEmoji: '🎃',
        sizeDesc: 'Large squash',
        lengthCm: '42.4',
        weightG: '1700',
        milestone: 'Fingernails complete',
        emotionalMsg:
            'Ten perfect tiny nails are nearly complete — every detail is being perfected 💜'),
    33: _PWeekData(
        fruit: 'Pineapple',
        fruitEmoji: '🍍',
        sizeDesc: 'Large pineapple',
        lengthCm: '43.7',
        weightG: '1900',
        milestone: 'Bones hardening',
        emotionalMsg:
            'Growing stronger every single day. You have created the most resilient love 🌸'),
    34: _PWeekData(
        fruit: 'Butternut',
        fruitEmoji: '🧡',
        sizeDesc: 'Butternut squash',
        lengthCm: '45.0',
        weightG: '2100',
        milestone: 'Immune system boosting',
        emotionalMsg:
            'You are gifting your baby an immune shield through your own body. Pure mother magic 🌙'),
    35: _PWeekData(
        fruit: 'Melon',
        fruitEmoji: '🍈',
        sizeDesc: 'Honeydew melon',
        lengthCm: '46.2',
        weightG: '2400',
        milestone: 'Lungs maturing',
        emotionalMsg:
            'Lungs are preparing for that first cry — the most beautiful sound you\'ll ever hear 🌟'),
    36: _PWeekData(
        fruit: 'Papaya',
        fruitEmoji: '🍈',
        sizeDesc: 'Papaya size',
        lengthCm: '47.4',
        weightG: '2600',
        milestone: 'Baby descending',
        emotionalMsg:
            'Baby is moving into position — your bodies are dancing toward the same beautiful moment ✨'),
    37: _PWeekData(
        fruit: 'Winter Melon',
        fruitEmoji: '🍈',
        sizeDesc: 'Swiss chard bunch',
        lengthCm: '48.6',
        weightG: '2900',
        milestone: 'Full term milestone',
        emotionalMsg:
            'Full term! The end is the most glorious beginning. You are almost there, brave mama 💜'),
    38: _PWeekData(
        fruit: 'Leek',
        fruitEmoji: '🌿',
        sizeDesc: 'Leek length',
        lengthCm: '49.8',
        weightG: '3100',
        milestone: 'Ready for the world',
        emotionalMsg:
            'Your baby is fully ready. What an extraordinary journey you have taken together 🌸'),
    39: _PWeekData(
        fruit: 'Watermelon',
        fruitEmoji: '🍉',
        sizeDesc: 'Mini watermelon',
        lengthCm: '50.7',
        weightG: '3300',
        milestone: 'Final growth complete',
        emotionalMsg:
            'Any day now. That love you\'ve been carrying is almost ready to be held 🌙'),
    40: _PWeekData(
        fruit: 'Watermelon',
        fruitEmoji: '🍉',
        sizeDesc: 'Full watermelon',
        lengthCm: '51.2',
        weightG: '3400',
        milestone: 'Due date has arrived!',
        emotionalMsg:
            'You made it, incredible mama. The greatest adventure of your life is about to begin 💫'),
  };

  static _PWeekData forWeek(int week) {
    final clamped = week.clamp(4, 40);
    int best = 4;
    for (final k in _weeks.keys) {
      if (k <= clamped) best = k;
    }
    return _weeks[best]!;
  }

  static String trimester(int week) {
    if (week <= 13) return 'First Trimester';
    if (week <= 26) return 'Second Trimester';
    return 'Third Trimester';
  }

  static Color trimesterColor(int week) {
    if (week <= 13) return _pPink;
    if (week <= 26) return _pPurple;
    return _pGold;
  }

  static List<(String, String, Color)> insights(int week) {
    return [
      if (week <= 12) ...[
        (
          '🌿',
          'Folic acid is vital right now. Your baby\'s neural tube is still forming.',
          const Color(0xFF66BB6A)
        ),
        (
          '😴',
          'First trimester fatigue is completely normal. Rest is productive — honour it.',
          const Color(0xFF7986CB)
        ),
        (
          '💧',
          'Staying hydrated reduces morning sickness. Sip water with lemon or ginger.',
          const Color(0xFF4FC3F7)
        ),
      ],
      if (week > 12 && week <= 26) ...[
        (
          '⚡',
          'Second trimester energy rise! Use this beautiful window for gentle movement.',
          const Color(0xFF66BB6A)
        ),
        (
          '🌸',
          'Baby can hear you now — talk, sing, and share your heart freely.',
          _pPink
        ),
        (
          '💧',
          'Blood volume is increasing. Hydration supports your circulation beautifully.',
          const Color(0xFF4FC3F7)
        ),
      ],
      if (week > 26) ...[
        (
          '🌙',
          'Your body may need more rest today. Sleep is building your baby\'s immune system.',
          const Color(0xFF7986CB)
        ),
        (
          '🧘‍♀️',
          'Pelvic floor exercises now will support your recovery journey beautifully.',
          _pPurple
        ),
        (
          '💜',
          'Third trimester emotions are real and valid. You are allowed to feel everything.',
          _pPurple
        ),
      ],
      (
        '✨',
        'Baby growth is progressing beautifully this week. Trust your body\'s wisdom.',
        _pGold
      ),
      (
        '🌸',
        'Your emotional wellbeing directly nourishes your baby. Tend to your heart today.',
        _pPink
      ),
    ];
  }

  static List<(String, String, String, Color)> appointments(int week) {
    return [
      if (week <= 13)
        ('🩺', 'First Prenatal Visit', 'Book by week 10 if not done', _pPink),
      if (week >= 10 && week <= 14)
        (
          '🧬',
          'First Trimester Screening',
          'Nuchal translucency scan',
          const Color(0xFF7986CB)
        ),
      if (week >= 18 && week <= 22)
        ('👁️', 'Anatomy Ultrasound', 'Detailed scan around week 20', _pPurple),
      if (week >= 24 && week <= 28)
        (
          '🍬',
          'Glucose Tolerance Test',
          'Gestational diabetes screening',
          _pWarm
        ),
      if (week >= 35)
        (
          '🏥',
          'Birth Plan Discussion',
          'Review your birth preferences',
          _pGold
        ),
      (
        '💊',
        'Prenatal Vitamins',
        'Take daily with breakfast',
        const Color(0xFF66BB6A)
      ),
      (
        '💧',
        'Water Reminder',
        'Aim for 8–10 glasses today',
        const Color(0xFF4FC3F7)
      ),
      (
        '🌙',
        'Sleep by 10 PM',
        'Optimal for hormonal restoration',
        const Color(0xFF7986CB)
      ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════
//  WELLNESS ITEM
// ═══════════════════════════════════════════════════════════

class _PWellnessItem {
  final String icon, label;
  final Color color;
  final List<String> options;
  String? selected;
  _PWellnessItem(this.icon, this.label, this.color, this.options);
}

// ═══════════════════════════════════════════════════════════
//  JOURNAL ENTRY
// ═══════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════
//  AFFIRMATIONS
// ═══════════════════════════════════════════════════════════

const List<String> _kPregnancyAffirms = [
  'My body was made for this sacred journey 🌸',
  'Every day I am growing stronger and more ready 💜',
  'I trust my body and my baby to guide us both 🌙',
  'I am surrounded by love in every heartbeat ✨',
  'I am calm, safe, and deeply supported 🌿',
  'My love for this baby is the most powerful force 💫',
  'I welcome each wave with grace and courage 🌊',
  'My baby feels my joy, my peace, and my love 🌸',
  'I am exactly the mother my baby needs 💜',
  'This journey is the most beautiful thing I have ever done ✨',
];

// ═══════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════

class PregnancyScreen extends StatefulWidget {
  const PregnancyScreen({super.key});

  @override
  State<PregnancyScreen> createState() => _PregnancyState();
}

// ═══════════════════════════════════════════════════════════
//  NEW PREMIUM STATE
// ═══════════════════════════════════════════════════════════

class _PregnancyState extends State<PregnancyScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl,
      _floatCtrl,
      _pulseCtrl,
      _orbCtrl,
      _particleCtrl;
  late Animation<double> _glowAnim, _floatAnim, _pulseAnim;

  final List<_PStar> _stars = [];
  final List<_PHeart> _hearts = [];
  final math.Random _rng = math.Random();

  int _week = 16;
  bool _weekInitialized = false;
  int _affirmIdx = 0;
  bool _showJournalInput = false;
  int _activeJournalType = 0;

  final List<_PWellnessItem> _wellness = [
    _PWellnessItem('😊', 'Mood', _pPink, [
      'Joyful 😊',
      'Calm 😌',
      'Tired 😴',
      'Anxious 😰',
      'Emotional 🥺',
      'Grateful 💜'
    ]),
    _PWellnessItem('😴', 'Sleep', const Color(0xFF7986CB),
        ['Excellent ✨', 'Good 😊', 'Restless 😤', 'Poor 😔', 'Insomnia 😟']),
    _PWellnessItem('💧', 'Hydration', const Color(0xFF4FC3F7),
        ['Great 💧', '8 glasses', '6 glasses', '4 glasses', 'Need more 😬']),
    _PWellnessItem('🍟', 'Cravings', _pWarm,
        ['Sweet 🍫', 'Salty 🍟', 'Sour 🍋', 'Spicy 🌶️', 'None 😌']),
    _PWellnessItem('⚡', 'Energy', const Color(0xFF66BB6A),
        ['High ⚡', 'Good ✨', 'Medium 🌤️', 'Low 😴', 'Very low 😔']),
  ];

  final TextEditingController _journalCtrl = TextEditingController();

  static const List<(String, String, Color)> _kJournalTypes = [
    ('🤰', 'Bump Note', _pPink),
    ('💌', 'Baby Memory', _pPurple),
    ('📓', 'Feelings', Color(0xFF7986CB)),
    ('🎯', 'Milestone', _pGold),
  ];

  @override
  void initState() {
    super.initState();
    _affirmIdx = DateTime.now().day % _kPregnancyAffirms.length;

    _glowCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _floatCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.94, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _orbCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();

    _particleCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();

    for (int i = 0; i < 28; i++) _stars.add(_PStar(rng: _rng));
    for (int i = 0; i < 12; i++) _hearts.add(_PHeart(rng: _rng));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_weekInitialized) {
      _weekInitialized = true;
      final ld = Provider.of<LunarDataProvider>(context, listen: false);
      _week = ld.currentPregnancyWeek;
      // Sync wellness selections from provider
      final w = ld.pregWellness;
      for (final item in _wellness) {
        final val = w[item.label.toLowerCase()];
        if (val != null) item.selected = val;
      }
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _orbCtrl.dispose();
    _particleCtrl.dispose();
    _journalCtrl.dispose();
    super.dispose();
  }

  DateTime get _dueDate => DateTime.now().add(Duration(days: (40 - _week) * 7));

  int get _daysLeft => _dueDate.difference(DateTime.now()).inDays.clamp(0, 280);

  String get _dueDateStr {
    final d = _dueDate;
    const m = [
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
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final lunarData = context.watch<LunarDataProvider>();
    final auth = context.read<LunarAuthProvider>();
    // Keep local _week in sync when provider changes externally
    final providerWeek = lunarData.currentPregnancyWeek;
    if (_weekInitialized && providerWeek != _week && _week == 16) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _week = providerWeek));
    }
    final data = _PGrowthEngine.forWeek(_week);
    final tc = _PGrowthEngine.trimesterColor(_week);

    return Scaffold(
      backgroundColor: _pBg,
      body: Stack(
        children: [
          _PBackground(size: size, week: _week),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _PPainter(
                    stars: _stars,
                    hearts: _hearts,
                    progress: _particleCtrl.value),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        _headerBar(tc),
                        const SizedBox(height: 24),
                        _pregnancyOrb(data, tc),
                        const SizedBox(height: 20),
                        _trimesterTimeline(lunarData, auth),
                        const SizedBox(height: 26),
                        _babyGrowthCard(data, tc),
                        const SizedBox(height: 26),
                        _sectionLabel('Baby Kicks', '👣'),
                        const SizedBox(height: 14),
                        _kickCounterCard(lunarData, auth),
                        const SizedBox(height: 26),
                        _sectionLabel('Your Wellness', '💜'),
                        const SizedBox(height: 14),
                        _wellnessGrid(lunarData, auth),
                        const SizedBox(height: 26),
                        _sectionLabel('AI Pregnancy Insights', '✨'),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _insightCards()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 26),
                        _sectionLabel('Pregnancy Journal', '📓'),
                        const SizedBox(height: 14),
                        _journalSection(lunarData),
                        const SizedBox(height: 26),
                        _sectionLabel('Care & Reminders', '🩺'),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _appointmentCards()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 26),
                        _sectionLabel('Emotional Support', '🌸'),
                        const SizedBox(height: 14),
                        _emotionalSupport(),
                        const SizedBox(height: 26),
                        _partnerCard(),
                        const SizedBox(height: 26),
                        _affirmationCard(),
                        const SizedBox(height: 38),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showJournalInput) _journalOverlay(context, lunarData, auth),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────
  Widget _headerBar(Color tc) => Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.maybePop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.14), width: 1)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pregnancy Journey',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2)),
              Text('Week $_week · $_daysLeft days to go',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 12.5)),
            ],
          )),
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _floatAnim.value * 0.5),
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: tc.withOpacity(0.10),
                    border: Border.all(
                      color: tc.withOpacity(
                          0.28 + _glowAnim.value * 0.22),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            tc.withOpacity(_glowAnim.value * 0.18),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lunar mini-orb
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.22),
                              tc.withOpacity(0.80),
                              _pDeep,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                            center: const Alignment(-0.2, -0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: tc.withOpacity(
                                  0.40 + _glowAnim.value * 0.30),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                            child: Text('🌙',
                                style: TextStyle(fontSize: 11))),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Lunar',
                        style: TextStyle(
                          color: tc.withOpacity(0.82),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  // ── PREGNANCY ORB ─────────────────────────────────────────
  Widget _pregnancyOrb(_PWeekData data, Color tc) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _orbCtrl]),
      builder: (_, __) => SizedBox(
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(280, 280),
              painter: _POrbPainter(
                progress: _week / 40.0,
                rotation: _orbCtrl.value * 2 * math.pi,
                glow: _glowAnim.value,
                color: tc,
              ),
            ),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 138,
                  height: 138,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      tc.withOpacity(0.9),
                      tc.withOpacity(0.6),
                      _pDeep.withOpacity(0.35)
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: tc.withOpacity(_glowAnim.value * 0.9),
                          blurRadius: 48,
                          spreadRadius: 14),
                      BoxShadow(
                          color: _pPink.withOpacity(_glowAnim.value * 0.5),
                          blurRadius: 22,
                          spreadRadius: 5),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(data.fruitEmoji,
                          style: const TextStyle(fontSize: 36)),
                      const SizedBox(height: 4),
                      Text('Week $_week',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      Text(_PGrowthEngine.trimester(_week),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
                top: 18,
                child: _floatingPill(
                    '$_daysLeft days left', Icons.favorite_rounded, _pPink)),
            Positioned(
                bottom: 14,
                child: _floatingPill(
                    _dueDateStr, Icons.calendar_today_rounded, tc)),
          ],
        ),
      ),
    );
  }

  Widget _floatingPill(String t, IconData ic, Color c) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: c.withOpacity(0.18),
                border: Border.all(color: c.withOpacity(0.45), width: 1)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(ic, color: c, size: 13),
              const SizedBox(width: 5),
              Text(t,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      );

  // ── TRIMESTER TIMELINE ────────────────────────────────────
  Widget _trimesterTimeline(LunarDataProvider lunarData, LunarAuthProvider auth) => _glassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🗓️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('Pregnancy Journey',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            _miniPill('$_week / 40 weeks', _pPurple),
          ]),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _PGrowthEngine.trimesterColor(_week),
              inactiveTrackColor: Colors.white.withOpacity(0.12),
              thumbColor: _PGrowthEngine.trimesterColor(_week),
              overlayColor:
                  _PGrowthEngine.trimesterColor(_week).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 5,
            ),
            child: Slider(
              value: _week.toDouble(),
              min: 4,
              max: 40,
              divisions: 36,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _week = v.round());
              },
              onChangeEnd: (v) {
                lunarData.setPregnancyWeek(
                    v.round(), uid: auth.firebaseUser?.uid);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _phaseLabel('T1\n1–13', _week <= 13),
              _phaseLabel('T2\n14–26', _week >= 14 && _week <= 26),
              _phaseLabel('T3\n27–40', _week >= 27),
            ],
          ),
        ]),
      );

  Widget _phaseLabel(String t, bool active) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active
              ? _pPurple.withOpacity(0.28)
              : Colors.white.withOpacity(0.06),
          border: Border.all(
              color: active ? _pPurple.withOpacity(0.65) : Colors.transparent,
              width: 1),
        ),
        child: Text(t,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: active ? Colors.white : Colors.white.withOpacity(0.38),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3)),
      );

  // ── BABY GROWTH CARD ──────────────────────────────────────
  Widget _babyGrowthCard(_PWeekData data, Color tc) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tc.withOpacity(0.32),
                    _pPink.withOpacity(0.18),
                    Colors.white.withOpacity(0.04)
                  ]),
              border: Border.all(
                  color: tc.withOpacity(_glowAnim.value * 0.65), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: tc.withOpacity(_glowAnim.value * 0.35),
                    blurRadius: 38,
                    spreadRadius: 4)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnim.value * 0.5 + 0.5,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            tc.withOpacity(0.85),
                            tc.withOpacity(0.35),
                            Colors.transparent
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color: tc.withOpacity(_glowAnim.value * 0.7),
                                blurRadius: 24,
                                spreadRadius: 4)
                          ],
                        ),
                        child: Center(
                            child: Text(data.fruitEmoji,
                                style: const TextStyle(fontSize: 34))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Week $_week — ${data.fruit}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(data.sizeDesc,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(children: [
                        _statPill('📏 ${data.lengthCm} cm', tc),
                        const SizedBox(width: 8),
                        _statPill('⚖️ ${data.weightG} g', _pPink),
                      ]),
                    ],
                  )),
                ]),
                const SizedBox(height: 16),
                Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.white.withOpacity(0.12)),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('✨', style: TextStyle(fontSize: 16, color: tc)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Milestone',
                          style: TextStyle(
                              color: tc,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(data.milestone,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  )),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1), width: 1)),
                  child: Text(data.emotionalMsg,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 14,
                          height: 1.55,
                          fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statPill(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: c.withOpacity(0.18),
            border: Border.all(color: c.withOpacity(0.4), width: 1)),
        child: Text(t,
            style:
                TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  // ── KICK COUNTER CARD ─────────────────────────────────────
  Widget _kickCounterCard(
      LunarDataProvider lunarData, LunarAuthProvider auth) {
    final kicks = lunarData.pregnancyKickCount;
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: [
                _pPink.withOpacity(0.16),
                _pPurple.withOpacity(0.10),
              ]),
              border: Border.all(
                  color: _pPink.withOpacity(_glowAnim.value * 0.55),
                  width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: _pPink.withOpacity(0.12 * _glowAnim.value),
                    blurRadius: 22)
              ],
            ),
            child: Column(children: [
              Row(children: [
                const Text('👣', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Baby Kicks Today',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      Text('Track movements to feel connected',
                          style: TextStyle(
                              color: Color(0x80FFFFFF), fontSize: 11.5)),
                    ])),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    lunarData.resetPregnancyKicks(
                        uid: auth.firebaseUser?.uid);
                  },
                  child: Text('Reset',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    lunarData.addPregnancyKick(uid: auth.firebaseUser?.uid);
                  },
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _pPink.withOpacity(0.9),
                            _pPink.withOpacity(0.5),
                            _pPurple.withOpacity(0.2),
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    _pPink.withOpacity(_glowAnim.value * 0.7),
                                blurRadius: 28,
                                spreadRadius: 6),
                          ],
                        ),
                        child: const Center(
                            child: Text('👣', style: TextStyle(fontSize: 38))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                Column(children: [
                  Text('$kicks',
                      style: TextStyle(
                          color: _pPink,
                          fontSize: 48,
                          fontWeight: FontWeight.w900)),
                  Text(kicks == 1 ? 'kick today' : 'kicks today',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  const SizedBox(height: 8),
                  if (kicks >= 10)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _pPink.withOpacity(0.18),
                        border: Border.all(
                            color: _pPink.withOpacity(0.45), width: 1),
                      ),
                      child: const Text('✨ Active baby!',
                          style: TextStyle(
                              color: Color(0xFFFF69B4),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    )
                  else if (kicks >= 6)
                    Text('Baby is moving well 💜',
                        style: TextStyle(
                            color: _pPurple.withOpacity(0.8), fontSize: 11.5))
                  else
                    Text('Tap the foot to count',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11)),
                ]),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ── WELLNESS GRID ─────────────────────────────────────────
  Widget _wellnessGrid(LunarDataProvider lunarData, LunarAuthProvider auth) => Column(
        children: _wellness
            .map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: GestureDetector(
                    onTap: () => _showWellnessSheet(w, lunarData, auth),
                    child: AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: w.color.withOpacity(0.08),
                                border: Border.all(
                                    color: w.selected != null
                                        ? w.color.withOpacity(0.55)
                                        : w.color.withOpacity(0.25),
                                    width: 1)),
                            child: Row(children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: w.color.withOpacity(0.18),
                                    border: Border.all(
                                        color: w.color.withOpacity(0.4),
                                        width: 1)),
                                child: Center(
                                    child: Text(w.icon,
                                        style: const TextStyle(fontSize: 22))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(w.label,
                                      style: TextStyle(
                                          color: w.color,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Text(w.selected ?? 'Tap to track',
                                      style: TextStyle(
                                          color: w.selected != null
                                              ? Colors.white.withOpacity(0.8)
                                              : Colors.white.withOpacity(0.35),
                                          fontSize: 13)),
                                ],
                              )),
                              Icon(
                                w.selected != null
                                    ? Icons.check_circle_rounded
                                    : Icons.add_circle_outline_rounded,
                                color: w.selected != null
                                    ? w.color
                                    : w.color.withOpacity(0.4),
                                size: 22,
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      );

  void _showWellnessSheet(
      _PWellnessItem item,
      LunarDataProvider lunarData,
      LunarAuthProvider auth) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFF1A0535),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: item.color.withOpacity(0.4), width: 1)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2))),
          const SizedBox(height: 18),
          Text('How is your ${item.label.toLowerCase()}?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: item.options.map((opt) {
              final sel = item.selected == opt;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => item.selected = opt);
                  lunarData.setPregWellness(
                      item.label.toLowerCase(), opt,
                      uid: auth.firebaseUser?.uid);
                  Navigator.pop(context);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: sel
                          ? LinearGradient(colors: [
                              item.color.withOpacity(0.7),
                              item.color.withOpacity(0.45)
                            ])
                          : null,
                      color: sel ? null : Colors.white.withOpacity(0.07),
                      border: Border.all(
                          color:
                              sel ? item.color : Colors.white.withOpacity(0.15),
                          width: 1)),
                  child: Text(opt,
                      style: TextStyle(
                          color: sel
                              ? Colors.white
                              : Colors.white.withOpacity(0.65),
                          fontSize: 13.5,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ── INSIGHT CARDS ─────────────────────────────────────────
  Widget _insightCards() {
    final ins = _PGrowthEngine.insights(_week);
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: ins.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final (emoji, text, color) = ins[i];
          return AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.22),
                            color.withOpacity(0.06)
                          ]),
                      border: Border.all(
                          color: color.withOpacity(_glowAnim.value * 0.6),
                          width: 1.2)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(text,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12.5,
                                  height: 1.5))),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── JOURNAL ───────────────────────────────────────────────
  Widget _journalSection(LunarDataProvider lunarData) => Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _kJournalTypes.asMap().entries.map((e) {
                final i = e.key;
                final (emoji, label, color) = e.value;
                final active = _activeJournalType == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _activeJournalType = i;
                        _showJournalInput = true;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: active
                              ? LinearGradient(colors: [
                                  color.withOpacity(0.6),
                                  color.withOpacity(0.35)
                                ])
                              : null,
                          color: active ? null : Colors.white.withOpacity(0.06),
                          border: Border.all(
                              color: active
                                  ? color
                                  : Colors.white.withOpacity(0.12),
                              width: 1)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 7),
                        Text(label,
                            style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.55),
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (lunarData.pregnancyJournals.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...lunarData.pregnancyJournals.take(3).map((e) {
              final dateStr = e['date'] as String? ?? '';
              String ds = '';
              if (dateStr.isNotEmpty) {
                try {
                  final d = DateTime.parse(dateStr);
                  const ms = [
                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                  ];
                  ds = '${ms[d.month - 1]} ${d.day}';
                } catch (_) {}
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _glassCard(
                    child: Row(children: [
                  Text(e['emoji'] as String? ?? '📝',
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(e['type'] as String? ?? '',
                            style: const TextStyle(
                                color: _pPurple,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(ds,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 11)),
                      ]),
                      const SizedBox(height: 4),
                      Text(e['note'] as String? ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 13,
                              height: 1.4)),
                    ],
                  )),
                ])),
              );
            }),
          ] else ...[
            const SizedBox(height: 14),
            _glassCard(
                child: Column(children: [
              Text(_kJournalTypes[_activeJournalType].$1,
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 10),
              Text('No entries yet',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 14)),
              const SizedBox(height: 4),
              Text('Tap a type above to write your first entry 💜',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 12)),
            ])),
          ],
        ],
      );

  Widget _journalOverlay(BuildContext context, LunarDataProvider lunarData,
      LunarAuthProvider auth) {
    final (emoji, label, color) = _kJournalTypes[_activeJournalType];
    return GestureDetector(
      onTap: () {
        setState(() => _showJournalInput = false);
        FocusScope.of(context).unfocus();
      },
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: const Color(0xFF1A0535).withOpacity(0.95),
                      border:
                          Border.all(color: color.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 4)
                      ]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 10),
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    Text('Week $_week · ${_PGrowthEngine.trimester(_week)}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12)),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withOpacity(0.06),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.12), width: 1)),
                      child: TextField(
                        controller: _journalCtrl,
                        maxLines: 5,
                        autofocus: true,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14.5,
                            height: 1.5),
                        decoration: InputDecoration(
                            hintText: 'Write freely, beautifully, honestly...',
                            hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.28),
                                fontSize: 14),
                            contentPadding: const EdgeInsets.all(16),
                            border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: GestureDetector(
                        onTap: () {
                          setState(() => _showJournalInput = false);
                          _journalCtrl.clear();
                          FocusScope.of(context).unfocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: Colors.white.withOpacity(0.07),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.15))),
                          child: const Text('Cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                        ),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: GestureDetector(
                        onTap: () {
                          if (_journalCtrl.text.trim().isEmpty) return;
                          HapticFeedback.lightImpact();
                          final entry = {
                            'type': label,
                            'emoji': emoji,
                            'note': _journalCtrl.text.trim(),
                            'week': _week,
                            'date': DateTime.now().toIso8601String(),
                          };
                          lunarData.addPregnancyJournal(entry,
                              uid: auth.firebaseUser?.uid);
                          setState(() => _showJournalInput = false);
                          _journalCtrl.clear();
                          FocusScope.of(context).unfocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: LinearGradient(colors: [
                                color.withOpacity(0.85),
                                color.withOpacity(0.55)
                              ]),
                              boxShadow: [
                                BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 16)
                              ]),
                          child: const Text('Save 💜',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                      )),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── APPOINTMENTS ──────────────────────────────────────────
  Widget _appointmentCards() {
    final appts = _PGrowthEngine.appointments(_week);
    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: appts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final (emoji, title, sub, color) = appts[i];
          return AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 170,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(colors: [
                        color.withOpacity(0.22),
                        color.withOpacity(0.07)
                      ]),
                      border: Border.all(
                          color: color.withOpacity(_glowAnim.value * 0.55),
                          width: 1.1)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 8),
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Expanded(
                          child: Text(sub,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11.5,
                                  height: 1.35))),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── EMOTIONAL SUPPORT ─────────────────────────────────────
  Widget _emotionalSupport() {
    final cards = [
      (
        '🌬️',
        'Pregnancy Breathing',
        'Inhale 4 · Hold 4 · Exhale 6. Soothes anxiety and reduces tension. Baby feels your calm.',
        const Color(0xFF4FC3F7)
      ),
      (
        '💜',
        'You Are Doing Beautifully',
        'There is no perfect way to do this. Every day you show up is enough. You are extraordinary.',
        _pPurple
      ),
      (
        '🌊',
        'Ride the Wave',
        'Whatever you\'re feeling — joy, fear, wonder, overwhelm — all of it is part of the sacred journey.',
        const Color(0xFF7986CB)
      ),
      (
        '🌸',
        'Self-Compassion Practice',
        'Place both hands on your belly. Breathe. Your baby feels your love through every cell right now.',
        _pPink
      ),
    ];
    return Column(
        children: cards.map((c) {
      final (emoji, title, body, color) = c;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: color.withOpacity(0.08),
                  border: Border.all(color: color.withOpacity(0.3), width: 1)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.18),
                        border: Border.all(
                            color: color.withOpacity(0.45), width: 1)),
                    child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(body,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.62),
                              fontSize: 12.5,
                              height: 1.45)),
                    ],
                  )),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList());
  }

  // ── PARTNER CARD ──────────────────────────────────────────
  Widget _partnerCard() => AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _pGold.withOpacity(0.18),
                        _pWarm.withOpacity(0.12),
                        _pPink.withOpacity(0.1)
                      ]),
                  border: Border.all(
                      color: _pGold.withOpacity(_glowAnim.value * 0.55),
                      width: 1.2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Text('👨‍👩‍👧', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Text('Share This Journey',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 14),
                  _shareItem('🌟', 'Today\'s Milestone',
                      'Share week $_week — ${_PGrowthEngine.forWeek(_week).fruit} stage'),
                  const SizedBox(height: 10),
                  _shareItem('💓', 'Baby Heartbeat Memory',
                      'Add a heartbeat recording or photo memory'),
                  const SizedBox(height: 10),
                  _shareItem('💜', 'Partner Support',
                      'Let your support person know how you\'re feeling today'),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _shareItem(String emoji, String title, String sub) => Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          Text(sub,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 12)),
        ])),
        Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white.withOpacity(0.25), size: 14),
      ]);

  // ── AFFIRMATION CARD ──────────────────────────────────────
  Widget _affirmationCard() => AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _affirmIdx = (_affirmIdx + 1) % _kPregnancyAffirms.length;
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _pPink.withOpacity(0.22),
                          _pPurple.withOpacity(0.15),
                          Colors.white.withOpacity(0.03)
                        ]),
                    border: Border.all(
                        color: _pPink.withOpacity(_glowAnim.value * 0.6),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: _pPink.withOpacity(_glowAnim.value * 0.22),
                          blurRadius: 32,
                          spreadRadius: 3)
                    ]),
                child: Column(children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnim.value,
                      child: const Text('🌸', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Text(_kPregnancyAffirms[_affirmIdx],
                        key: ValueKey(_affirmIdx),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                            height: 1.55)),
                  ),
                  const SizedBox(height: 14),
                  Text('Tap for a new mama affirmation 🌸',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.38), fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
      );

  // ── HELPERS ───────────────────────────────────────────────
  Widget _glassCard({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.06),
                border:
                    Border.all(color: Colors.white.withOpacity(0.1), width: 1)),
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

  Widget _miniPill(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: c.withOpacity(0.18),
            border: Border.all(color: c.withOpacity(0.4), width: 1)),
        child: Text(t,
            style:
                TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w500)),
      );
}

// ═══════════════════════════════════════════════════════════
//  DREAMY BACKGROUND
// ═══════════════════════════════════════════════════════════

class _PBackground extends StatelessWidget {
  final Size size;
  final int week;
  const _PBackground({required this.size, required this.week});

  @override
  Widget build(BuildContext context) {
    final tc = _PGrowthEngine.trimesterColor(week);
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
          gradient: RadialGradient(
              center: Alignment(0, -0.45),
              radius: 1.3,
              colors: [Color(0xFF2D0B5C), Color(0xFF18063A), _pBg])),
      child: Stack(children: [
        Positioned(top: -80, left: -60, child: _blob(320, tc, 0.22)),
        Positioned(top: 70, right: -75, child: _blob(260, _pPink, 0.16)),
        Positioned(
            top: size.height * 0.36,
            left: size.width * 0.48 - 140,
            child: _blob(280, _pWarm, 0.1)),
        Positioned(bottom: 70, left: -60, child: _blob(290, _pPurple, 0.18)),
        Positioned(bottom: 0, right: -50, child: _blob(240, _pGold, 0.1)),
      ]),
    );
  }

  Widget _blob(double s, Color c, double o) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                RadialGradient(colors: [c.withOpacity(o), Colors.transparent])),
      );
}

// ═══════════════════════════════════════════════════════════
//  ORBITAL PROGRESS PAINTER
// ═══════════════════════════════════════════════════════════

class _POrbPainter extends CustomPainter {
  final double progress, rotation, glow;
  final Color color;
  _POrbPainter(
      {required this.progress,
      required this.rotation,
      required this.glow,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const r1 = 120.0;
    const r2 = 100.0;

    _ring(canvas, c, r1, Colors.white.withOpacity(0.1), 1.0);
    _arc(canvas, c, r1, -math.pi / 2, progress * 2 * math.pi, color, 4.0);
    _ring(canvas, c, r2, Colors.white.withOpacity(0.07), 1.0);

    _dot(canvas, c, r1, rotation, _pGold, 7);
    _dot(canvas, c, r2, rotation + math.pi, _pPink, 5);
    _dot(canvas, c, r1, rotation + math.pi * 1.5, Colors.white, 3.5);

    // Progress cap glow
    final ea = -math.pi / 2 + progress * 2 * math.pi;
    final cap = Offset(c.dx + r1 * math.cos(ea), c.dy + r1 * math.sin(ea));
    canvas.drawCircle(
        cap,
        7,
        Paint()
          ..color = color.withOpacity(glow * 0.9)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(cap, 4, Paint()..color = Colors.white);

    // Stars
    final sp = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    for (final o in const [
      Offset(-92, -60),
      Offset(88, -80),
      Offset(-78, 88),
      Offset(105, 42),
      Offset(-42, -118),
      Offset(54, 112),
    ]) {
      canvas.drawCircle(c + o, 1.8, sp);
    }
  }

  void _ring(Canvas canvas, Offset c, double r, Color col, double w) =>
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..color = col
            ..style = PaintingStyle.stroke
            ..strokeWidth = w);

  void _arc(Canvas canvas, Offset c, double r, double start, double sweep,
      Color col, double w) {
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = col.withOpacity(glow * 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 2));
    canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.6
          ..strokeCap = StrokeCap.round);
  }

  void _dot(
      Canvas canvas, Offset c, double r, double angle, Color col, double s) {
    final pos = Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));
    canvas.drawCircle(
        pos,
        s,
        Paint()
          ..color = col.withOpacity(0.8)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 1.4));
    canvas.drawCircle(pos, s * 0.45, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_POrbPainter old) =>
      old.progress != progress ||
      old.rotation != rotation ||
      old.glow != glow ||
      old.color != color;
}

// ═══════════════════════════════════════════════════════════
//  PARTICLE SYSTEM
// ═══════════════════════════════════════════════════════════

class _PStar {
  late double x, y, speed, size, opacity, angle;
  _PStar({required math.Random rng}) {
    _r(rng);
  }
  void _r(math.Random rng) {
    x = rng.nextDouble();
    y = rng.nextDouble();
    speed = 0.00012 + rng.nextDouble() * 0.00022;
    size = 0.7 + rng.nextDouble() * 2.2;
    opacity = 0.2 + rng.nextDouble() * 0.5;
    angle = rng.nextDouble() * math.pi * 2;
  }
}

class _PHeart {
  late double x, y, speed, size, opacity, phase;
  _PHeart({required math.Random rng}) {
    _r(rng);
  }
  void _r(math.Random rng) {
    x = rng.nextDouble();
    y = 0.7 + rng.nextDouble() * 0.3;
    speed = 0.00005 + rng.nextDouble() * 0.0001;
    size = 3.5 + rng.nextDouble() * 5.0;
    opacity = 0.12 + rng.nextDouble() * 0.25;
    phase = rng.nextDouble() * math.pi * 2;
  }
}

class _PPainter extends CustomPainter {
  final List<_PStar> stars;
  final List<_PHeart> hearts;
  final double progress;
  _PPainter(
      {required this.stars, required this.hearts, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in stars) {
      final x = (p.x + math.cos(p.angle) * p.speed * progress * 120) % 1.0;
      final y = (p.y - p.speed * progress * 240) % 1.0;
      canvas.drawCircle(
          Offset(x * size.width, y * size.height),
          p.size,
          Paint()
            ..color = Colors.white.withOpacity(p.opacity * 0.7)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1));
      if (p.size > 2.0) {
        final sp = Paint()
          ..color = _pPurple.withOpacity(p.opacity * 0.4)
          ..strokeWidth = 0.55;
        final cx = x * size.width;
        final cy = y * size.height;
        canvas.drawLine(Offset(cx - 4.5, cy), Offset(cx + 4.5, cy), sp);
        canvas.drawLine(Offset(cx, cy - 4.5), Offset(cx, cy + 4.5), sp);
      }
    }
    for (final h in hearts) {
      final wb = math.sin(h.phase + progress * math.pi * 2) * 0.012;
      final x = (h.x + wb) % 1.0;
      final y = (h.y - h.speed * progress * 280) % 1.0;
      final fa = (h.opacity *
              (0.45 + 0.55 * math.sin(progress * math.pi * 2 + h.phase)))
          .clamp(0.0, 1.0);
      _heart(canvas, Offset(x * size.width, y * size.height), h.size,
          _pPink.withOpacity(fa));
    }
  }

  void _heart(Canvas canvas, Offset c, double s, Color col) {
    final p = Paint()
      ..color = col
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.5);
    final r = s * 0.38;
    canvas.drawCircle(Offset(c.dx - r * 0.55, c.dy - r * 0.25), r, p);
    canvas.drawCircle(Offset(c.dx + r * 0.55, c.dy - r * 0.25), r, p);
    canvas.drawPath(
        Path()
          ..moveTo(c.dx - s * 0.75, c.dy - r * 0.2)
          ..lineTo(c.dx, c.dy + s * 0.55)
          ..lineTo(c.dx + s * 0.75, c.dy - r * 0.2)
          ..close(),
        p);
  }

  @override
  bool shouldRepaint(_PPainter old) => old.progress != progress;
}
