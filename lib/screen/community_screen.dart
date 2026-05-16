import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════
//  LUNAR COMMUNITY — Safe Space Screen
// ═══════════════════════════════════════════════════════════

// ── Design tokens ─────────────────────────────────────────
const Color _cBg     = Color(0xFF0A0118);
const Color _cPurple = Color(0xFFAB5CF2);
const Color _cPink   = Color(0xFFFF69B4);
const Color _cDeep   = Color(0xFF5C2DB8);
const Color _cGold   = Color(0xFFFFD700);
const Color _cTeal   = Color(0xFF4FC3F7);
const Color _cGreen  = Color(0xFF66BB6A);
const Color _cIndigo = Color(0xFF7986CB);

// ═══════════════════════════════════════════════════════════
//  ENUMS
// ═══════════════════════════════════════════════════════════

enum _CCat {
  all, periodTalk, pregnancy, emotionalHealing,
  relationships, anxietySupport, selfCare, sleepWellness,
}

extension _CCatX on _CCat {
  String get label => const {
    _CCat.all:              'All',
    _CCat.periodTalk:       'Period Talk',
    _CCat.pregnancy:        'Pregnancy',
    _CCat.emotionalHealing: 'Emotional Healing',
    _CCat.relationships:    'Relationships',
    _CCat.anxietySupport:   'Anxiety Support',
    _CCat.selfCare:         'Self Care',
    _CCat.sleepWellness:    'Sleep & Wellness',
  }[this]!;

  String get emoji => const {
    _CCat.all:              '🌸',
    _CCat.periodTalk:       '🩸',
    _CCat.pregnancy:        '🤰',
    _CCat.emotionalHealing: '💜',
    _CCat.relationships:    '💞',
    _CCat.anxietySupport:   '🌬️',
    _CCat.selfCare:         '🌿',
    _CCat.sleepWellness:    '🌙',
  }[this]!;

  Color get color => const {
    _CCat.all:              _cPink,
    _CCat.periodTalk:       Color(0xFFE53935),
    _CCat.pregnancy:        _cGold,
    _CCat.emotionalHealing: _cPurple,
    _CCat.relationships:    Color(0xFFEC407A),
    _CCat.anxietySupport:   _cTeal,
    _CCat.selfCare:         _cGreen,
    _CCat.sleepWellness:    _cIndigo,
  }[this]!;
}

enum _CRxn { support, sendingLove, youreStrong, hugs, healingEnergy }

extension _CRxnX on _CRxn {
  String get emoji => const {
    _CRxn.support:       '💜',
    _CRxn.sendingLove:   '💌',
    _CRxn.youreStrong:   '💪',
    _CRxn.hugs:          '🤗',
    _CRxn.healingEnergy: '✨',
  }[this]!;

  String get label => const {
    _CRxn.support:       'Support',
    _CRxn.sendingLove:   'Sending Love',
    _CRxn.youreStrong:   'You\'re Strong',
    _CRxn.hugs:          'Hugs',
    _CRxn.healingEnergy: 'Healing Energy',
  }[this]!;
}

// ═══════════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════════

class _CPost {
  final String id, pseudonym, avatarEmoji;
  final Color avatarColor;
  final bool isAnonymous;
  final _CCat category;
  final String content;
  final List<String> tags;
  final Map<_CRxn, int> reactions;
  final int commentsCount;
  final DateTime createdAt;
  final bool isSensitive;
  bool isBlurred;
  bool isReported = false;
  final Set<_CRxn> myReactions = {};

  _CPost({
    required this.id,
    required this.pseudonym,
    required this.avatarEmoji,
    required this.avatarColor,
    this.isAnonymous = true,
    required this.category,
    required this.content,
    this.tags = const [],
    Map<_CRxn, int>? reactions,
    this.commentsCount = 0,
    required this.createdAt,
    this.isSensitive = false,
  })  : reactions = Map<_CRxn, int>.from(reactions ?? {}),
        isBlurred = isSensitive;
}

class _CStory {
  final String name, emoji, mood;
  final Color color;
  final bool isAI;
  const _CStory({
    required this.name,
    required this.emoji,
    required this.color,
    required this.mood,
    this.isAI = false,
  });
}

// ═══════════════════════════════════════════════════════════
//  SEED DATA
// ═══════════════════════════════════════════════════════════

const List<_CStory> _kStories = [
  _CStory(name: 'Lunar AI',  emoji: '🌙', color: _cPurple,              mood: 'Here for you ✨',       isAI: true),
  _CStory(name: 'MoonRose',  emoji: '🌸', color: _cPink,                mood: 'Feeling hopeful 🌷'),
  _CStory(name: 'StarLight', emoji: '⭐', color: _cGold,                mood: 'Grateful today 💛'),
  _CStory(name: 'Violet',    emoji: '🦋', color: _cPurple,              mood: 'Healing gently 💜'),
  _CStory(name: 'BlueWave',  emoji: '🌊', color: _cTeal,                mood: 'Finding calm 🌊'),
  _CStory(name: 'Ember',     emoji: '🌺', color: Color(0xFFEC407A),     mood: 'Processing 🌿'),
  _CStory(name: 'Aurora',    emoji: '✨', color: Color(0xFF7B39BD),     mood: 'Empowered ✨'),
  _CStory(name: 'Fern',      emoji: '🍀', color: _cGreen,               mood: 'Self care day 🌱'),
];

List<_CPost> _buildSeedPosts() {
  final now = DateTime.now();
  return [
    _CPost(
      id: 'p1', pseudonym: 'MoonRose', avatarEmoji: '🌸', avatarColor: _cPink,
      category: _CCat.emotionalHealing,
      content: 'Today was unexpectedly hard. I cried in the shower and that\'s okay. Sometimes we just need to feel it all. To anyone else carrying something heavy right now — you are not alone 💜',
      tags: ['Processing', 'Need Support'],
      reactions: {_CRxn.support: 47, _CRxn.sendingLove: 31, _CRxn.hugs: 28},
      commentsCount: 14, createdAt: now.subtract(const Duration(minutes: 23)),
    ),
    _CPost(
      id: 'p2', pseudonym: 'StarLight', avatarEmoji: '⭐', avatarColor: _cGold,
      category: _CCat.pregnancy,
      content: 'Week 22 and I just felt the first real kick! Not the little flutters but an actual KICK. I burst into tears of joy. She\'s so real and so alive 🌟 Third trimester, here we come! 🤰',
      tags: ['Celebrating', 'Grateful'],
      reactions: {_CRxn.support: 89, _CRxn.sendingLove: 64, _CRxn.youreStrong: 41, _CRxn.healingEnergy: 33},
      commentsCount: 29, createdAt: now.subtract(const Duration(hours: 1)),
    ),
    _CPost(
      id: 'p3', pseudonym: 'Anonymous 🌙', avatarEmoji: '🌙', avatarColor: _cPurple,
      isAnonymous: true, category: _CCat.anxietySupport,
      content: 'Does anyone else\'s anxiety peak right before their period? I feel like a different person for those 3 days. Racing thoughts, doom spirals, crying at absolutely nothing. Hormones are so wild. You\'re not broken if this is you too 🌬️',
      tags: ['Anxious', 'Struggling'],
      reactions: {_CRxn.support: 112, _CRxn.hugs: 78, _CRxn.youreStrong: 55},
      commentsCount: 41, createdAt: now.subtract(const Duration(hours: 2, minutes: 14)),
    ),
    _CPost(
      id: 'p4', pseudonym: 'Violet', avatarEmoji: '🦋', avatarColor: Color(0xFF7B39BD),
      category: _CCat.selfCare,
      content: 'My Sunday ritual: lavender bath, no phone, just me and my favourite playlist. It took me years to believe I deserved this kind of gentleness from myself. You deserve it too 🌸✨',
      tags: ['Healing', 'Empowered'],
      reactions: {_CRxn.support: 73, _CRxn.sendingLove: 49, _CRxn.healingEnergy: 61},
      commentsCount: 18, createdAt: now.subtract(const Duration(hours: 4)),
    ),
    _CPost(
      id: 'p5', pseudonym: 'Anonymous 💫', avatarEmoji: '💫', avatarColor: Color(0xFFBA68C8),
      isAnonymous: true, category: _CCat.periodTalk,
      content: 'Cycle day 2 and I\'m horizontal on the couch with a heating pad and I\'m calling it productivity. No explanation needed. Solidarity to everyone bleeding with me right now 🩸❤️',
      tags: ['Struggling', 'Finding Peace'],
      reactions: {_CRxn.support: 204, _CRxn.hugs: 156, _CRxn.sendingLove: 93},
      commentsCount: 67, createdAt: now.subtract(const Duration(hours: 5, minutes: 40)),
    ),
    _CPost(
      id: 'p6', pseudonym: 'Aurora', avatarEmoji: '✨', avatarColor: Color(0xFF7B39BD),
      category: _CCat.relationships,
      content: 'It took me 6 months but I finally told my partner how PMS affects my emotions. The conversation was scary but she held my hand through the whole thing. Communication is everything 💞',
      tags: ['Empowered', 'Grateful'],
      reactions: {_CRxn.support: 58, _CRxn.sendingLove: 82, _CRxn.healingEnergy: 44},
      commentsCount: 22, createdAt: now.subtract(const Duration(hours: 7)),
    ),
    _CPost(
      id: 'p7', pseudonym: 'Fern', avatarEmoji: '🍀', avatarColor: _cGreen,
      category: _CCat.sleepWellness,
      content: 'Sleep hack that changed my luteal phase completely: no screens 90 minutes before bed, magnesium glycinate, and a consistent wake time even on weekends. My mood is dramatically better 🌙',
      tags: ['Healing', 'Feeling Hopeful'],
      reactions: {_CRxn.support: 91, _CRxn.healingEnergy: 67, _CRxn.sendingLove: 38},
      commentsCount: 34, createdAt: now.subtract(const Duration(hours: 9)),
    ),
    _CPost(
      id: 'p8', pseudonym: 'Anonymous 🌺', avatarEmoji: '🌺', avatarColor: Color(0xFFEC407A),
      isAnonymous: true, category: _CCat.emotionalHealing,
      content: 'Healing confession: I\'m not okay some days and that\'s the most honest thing I\'ve said in weeks. If you\'re also pretending to be fine — this is a safe space. You can just be where you are 💜',
      tags: ['Vulnerable', 'Processing'],
      reactions: {_CRxn.support: 187, _CRxn.hugs: 142, _CRxn.sendingLove: 118},
      commentsCount: 53, createdAt: now.subtract(const Duration(hours: 11)),
    ),
    _CPost(
      id: 'p9', pseudonym: 'BlueWave', avatarEmoji: '🌊', avatarColor: _cTeal,
      category: _CCat.anxietySupport,
      content: 'Box breathing before stressful situations has genuinely saved me this month. 4-4-4-4. Inhale for 4, hold for 4, out for 4, hold for 4. Your nervous system will thank you 🌬️ Try it right now.',
      tags: ['Healing', 'Empowered'],
      reactions: {_CRxn.support: 76, _CRxn.healingEnergy: 91, _CRxn.youreStrong: 44},
      commentsCount: 19, createdAt: now.subtract(const Duration(hours: 13)),
    ),
    _CPost(
      id: 'p10', pseudonym: 'Anonymous ❄️', avatarEmoji: '❄️', avatarColor: Color(0xFF80DEEA),
      isAnonymous: true, category: _CCat.pregnancy,
      content: 'Miscarriage at 9 weeks. I don\'t have words yet. I\'m just sitting here feeling the weight of it. If you\'ve been here, I\'d love to hear that it gets gentler. Not easier — just gentler.',
      tags: ['Vulnerable', 'Need Support'],
      reactions: {_CRxn.support: 312, _CRxn.hugs: 267, _CRxn.sendingLove: 241, _CRxn.youreStrong: 189},
      commentsCount: 98, createdAt: now.subtract(const Duration(hours: 16)), isSensitive: true,
    ),
    _CPost(
      id: 'p11', pseudonym: 'MoonRose', avatarEmoji: '🌸', avatarColor: _cPink,
      category: _CCat.selfCare,
      content: 'Reminder that "self care" doesn\'t have to be a spa day. Today mine was drinking enough water and getting dressed. Small acts of care count. You\'re doing the best you can 🌸',
      tags: ['Feeling Hopeful', 'Healing'],
      reactions: {_CRxn.support: 143, _CRxn.sendingLove: 107, _CRxn.healingEnergy: 88},
      commentsCount: 31, createdAt: now.subtract(const Duration(hours: 18)),
    ),
    _CPost(
      id: 'p12', pseudonym: 'Ember', avatarEmoji: '🌺', avatarColor: Color(0xFFEC407A),
      category: _CCat.periodTalk,
      content: 'Just tracked my 12th consecutive cycle on Lunar 🩸 The patterns I\'ve discovered about my mood, energy, and creativity across the cycle are genuinely mind-blowing. We are cyclical beings 💜',
      tags: ['Empowered', 'Celebrating'],
      reactions: {_CRxn.support: 64, _CRxn.healingEnergy: 53, _CRxn.sendingLove: 29},
      commentsCount: 21, createdAt: now.subtract(const Duration(hours: 22)),
    ),
  ];
}

const Map<_CCat, (String, String)> _kAISuggestions = {
  _CCat.all:              ('💜', 'Lunar AI is here — this is a safe, gentle space for all of you.'),
  _CCat.periodTalk:       ('🩸', 'Cycle awareness is self-knowledge. Your body has so much wisdom to share.'),
  _CCat.pregnancy:        ('🤰', 'Every pregnancy is a unique sacred story. You\'re exactly where you need to be.'),
  _CCat.emotionalHealing: ('💜', 'Healing isn\'t linear. Coming here is already a brave act of self-care.'),
  _CCat.relationships:    ('💞', 'Communicating our cycle to loved ones builds deeper, more honest connection.'),
  _CCat.anxietySupport:   ('🌬️', 'You are safe right now. Take a breath. This community holds space for you.'),
  _CCat.selfCare:         ('🌿', 'Tending to yourself is the most radical, beautiful thing you can do.'),
  _CCat.sleepWellness:    ('🌙', 'Rest is not laziness. Your body does its deepest healing while you sleep.'),
};

const List<(String, Color)> _kAvatars = [
  ('🌙', _cPurple),
  ('🌸', _cPink),
  ('⭐', _cGold),
  ('🦋', Color(0xFF4FC3F7)),
  ('🌊', Color(0xFF0288D1)),
  ('🌺', Color(0xFFE53935)),
  ('✨', Color(0xFF7B39BD)),
  ('🍀', _cGreen),
  ('💫', Color(0xFFBA68C8)),
  ('🌻', Color(0xFFFDD835)),
  ('❄️', Color(0xFF80DEEA)),
  ('🌈', Color(0xFFFF7043)),
];

const List<String> _kEmotionalTags = [
  'Feeling Hopeful', 'Need Support', 'Grateful', 'Anxious',
  'Processing', 'Healing', 'Celebrating', 'Struggling',
  'Overwhelmed', 'Finding Peace', 'Empowered', 'Vulnerable',
];

// ═══════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityState();
}

class _CommunityState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl, _floatCtrl, _particleCtrl;
  late Animation<double> _glowAnim, _floatAnim;

  final List<_CStar>  _stars = [];
  final math.Random   _rng   = math.Random();

  _CCat _activeCat = _CCat.all;
  bool  _showCompose = false;
  late  List<_CPost> _posts;
  final Set<String>  _viewedStories = {};

  // Compose state
  bool   _composeAnon      = true;
  int    _composeAvatarIdx = 0;
  _CCat  _composeCat       = _CCat.emotionalHealing;
  final  Set<String> _composeTags = {};
  final  TextEditingController _composeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _posts = _buildSeedPosts();

    _glowCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _particleCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 7))..repeat();

    for (int i = 0; i < 32; i++) _stars.add(_CStar(rng: _rng));
  }

  @override
  void dispose() {
    _glowCtrl.dispose(); _floatCtrl.dispose(); _particleCtrl.dispose();
    _composeCtrl.dispose();
    super.dispose();
  }

  List<_CPost> get _filtered => _activeCat == _CCat.all
      ? _posts
      : _posts.where((p) => p.category == _activeCat).toList();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _cBg,
      body: Stack(
        children: [
          _CBackground(size: size),
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _CParticlePainter(stars: _stars, progress: _particleCtrl.value),
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
                      const SizedBox(height: 18),
                      _safetyBanner(),
                      const SizedBox(height: 18),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(child: _storiesRow()),
                SliverToBoxAdapter(child: const SizedBox(height: 18)),
                SliverToBoxAdapter(child: _categoryTabs()),
                SliverToBoxAdapter(child: const SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _aiCompanionCard(),
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 14)),
                ..._filtered.map((post) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _postCard(post),
                  ),
                )),
                if (_filtered.isEmpty)
                  SliverToBoxAdapter(child: _emptyState()),
                SliverToBoxAdapter(child: const SizedBox(height: 110)),
              ],
            ),
          ),
          Positioned(right: 20, bottom: 28, child: _composeFAB()),
          if (_showCompose) _composeOverlay(context),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────
  Widget _headerBar() => Row(
    children: [
      GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); Navigator.maybePop(context); },
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.07),
            border: Border.all(color: Colors.white.withOpacity(0.14), width: 1)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Safe Space 🌸',
              style: TextStyle(color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w800, letterSpacing: 0.2)),
          Text('A gentle community for every woman',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ]),
      ),
      AnimatedBuilder(
        animation: Listenable.merge([_floatAnim, _glowAnim]),
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _floatAnim.value * 0.4),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _cPurple.withOpacity(_glowAnim.value * 0.85), Colors.transparent]),
              boxShadow: [BoxShadow(color: _cPurple.withOpacity(_glowAnim.value * 0.5),
                  blurRadius: 20, spreadRadius: 2)]),
            child: const Text('🌸', style: TextStyle(fontSize: 22)),
          ),
        ),
      ),
    ],
  );

  // ── SAFETY BANNER ─────────────────────────────────────────
  Widget _safetyBanner() => AnimatedBuilder(
    animation: _glowAnim,
    builder: (_, __) => ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [
              _cPurple.withOpacity(0.16), _cPink.withOpacity(0.09)]),
            border: Border.all(color: _cPurple.withOpacity(_glowAnim.value * 0.45))),
          child: Row(children: [
            const Text('💜', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('This is a safe, anonymous space',
                  style: TextStyle(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text('Be kind · No judgment · You belong here',
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11.5)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                color: _cGreen.withOpacity(0.15),
                border: Border.all(color: _cGreen.withOpacity(0.45), width: 1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _cGreen,
                    boxShadow: [BoxShadow(color: _cGreen.withOpacity(0.7),
                        blurRadius: 4, spreadRadius: 1)])),
                const SizedBox(width: 5),
                Text('Safe', style: TextStyle(color: _cGreen, fontSize: 11,
                    fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
      ),
    ),
  );

  // ── STORIES ROW ───────────────────────────────────────────
  Widget _storiesRow() => SizedBox(
    height: 100,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _kStories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (_, i) {
        final s = _kStories[i];
        final viewed = _viewedStories.contains(s.name);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _viewedStories.add(s.name));
            _showStorySheet(s);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  width: 66, height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: viewed ? null : SweepGradient(colors: [
                      s.isAI ? _cPurple : s.color,
                      s.isAI ? _cPink   : s.color.withOpacity(0.35),
                      s.isAI ? _cGold   : s.color,
                    ]),
                    color: viewed ? Colors.white.withOpacity(0.08) : null,
                    boxShadow: viewed ? null : [BoxShadow(
                      color: s.color.withOpacity(s.isAI ? _glowAnim.value * 0.7 : 0.35),
                      blurRadius: s.isAI ? 22 : 12, spreadRadius: s.isAI ? 3 : 1)],
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: _cBg),
                    child: Center(child: Text(s.emoji,
                        style: const TextStyle(fontSize: 27))),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(s.name,
                  style: TextStyle(
                    color: viewed ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.8),
                    fontSize: 10.5, fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    ),
  );

  void _showStorySheet(_CStory s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [s.color.withOpacity(0.35), _cBg]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: s.color.withOpacity(0.4), width: 1)),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2))),
          const SizedBox(height: 28),
          Text(s.emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 22,
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(s.mood, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16)),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: s.isAI
                ? Text(
              'Lunar AI is gently watching over this space. Every story is safe, every voice matters. You are never alone here 💜',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.68), fontSize: 15,
                  height: 1.6, fontStyle: FontStyle.italic),
            )
                : Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white.withOpacity(0.12))),
              child: Text('"${s.mood}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 16,
                      fontStyle: FontStyle.italic, height: 1.5)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── CATEGORY TABS ─────────────────────────────────────────
  Widget _categoryTabs() => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _CCat.values.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final cat = _CCat.values[i];
        final active = _activeCat == cat;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _activeCat = cat); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: active ? LinearGradient(colors: [
                cat.color.withOpacity(0.72), cat.color.withOpacity(0.45)]) : null,
              color: active ? null : Colors.white.withOpacity(0.07),
              border: Border.all(
                  color: active ? cat.color : Colors.white.withOpacity(0.12), width: 1),
              boxShadow: active ? [BoxShadow(color: cat.color.withOpacity(0.32),
                  blurRadius: 12)] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(cat.emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(cat.label, style: TextStyle(
                  color: active ? Colors.white : Colors.white.withOpacity(0.52),
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
            ]),
          ),
        );
      },
    ),
  );

  // ── AI COMPANION CARD ─────────────────────────────────────
  Widget _aiCompanionCard() {
    final (emoji, msg) = _kAISuggestions[_activeCat] ?? _kAISuggestions[_CCat.all]!;
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [_cDeep.withOpacity(0.55), _cPurple.withOpacity(0.25),
                    _cPink.withOpacity(0.12)]),
              border: Border.all(
                  color: _cPurple.withOpacity(_glowAnim.value * 0.6), width: 1.2),
              boxShadow: [BoxShadow(color: _cPurple.withOpacity(_glowAnim.value * 0.22),
                  blurRadius: 24, spreadRadius: 2)]),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _cPurple.withOpacity(0.85), _cPink.withOpacity(0.4)]),
                  boxShadow: [BoxShadow(color: _cPurple.withOpacity(0.5), blurRadius: 12)]),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Lunar AI 🌙', style: TextStyle(color: Colors.white,
                    fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.62),
                    fontSize: 12.5, height: 1.4)),
              ])),
            ]),
          ),
        ),
      ),
    );
  }

  // ── POST CARD ─────────────────────────────────────────────
  Widget _postCard(_CPost post) {
    if (post.isReported) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: Colors.white.withOpacity(0.07))),
          child: Row(children: [
            Icon(Icons.flag_rounded, color: Colors.white.withOpacity(0.25), size: 16),
            const SizedBox(width: 8),
            Text('This post has been reported and is under review.',
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12.5)),
          ]),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(
                  color: post.category.color.withOpacity(_glowAnim.value * 0.28), width: 1)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _postHeader(post),
              const SizedBox(height: 12),
              _postContent(post),
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 7, runSpacing: 7,
                  children: post.tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                      color: post.category.color.withOpacity(0.13),
                      border: Border.all(color: post.category.color.withOpacity(0.32), width: 1)),
                    child: Text(t, style: TextStyle(color: post.category.color,
                        fontSize: 11, fontWeight: FontWeight.w500)),
                  )).toList()),
              ],
              const SizedBox(height: 14),
              Container(height: 1, color: Colors.white.withOpacity(0.07)),
              const SizedBox(height: 12),
              _reactionBar(post),
              const SizedBox(height: 10),
              _postFooter(post),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _postHeader(_CPost post) => Row(children: [
    Container(
      width: 44, height: 44,
      decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          post.avatarColor.withOpacity(0.85), post.avatarColor.withOpacity(0.3)]),
        border: Border.all(color: post.avatarColor.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: post.avatarColor.withOpacity(0.28), blurRadius: 10)]),
      child: Center(child: Text(post.avatarEmoji, style: const TextStyle(fontSize: 22))),
    ),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(post.pseudonym, style: const TextStyle(color: Colors.white,
            fontSize: 13.5, fontWeight: FontWeight.w600)),
        if (post.isAnonymous) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
              color: _cPurple.withOpacity(0.18),
              border: Border.all(color: _cPurple.withOpacity(0.38))),
            child: Text('anon', style: TextStyle(color: _cPurple, fontSize: 9.5,
                fontWeight: FontWeight.w500)),
          ),
        ],
      ]),
      const SizedBox(height: 3),
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
            color: post.category.color.withOpacity(0.16),
            border: Border.all(color: post.category.color.withOpacity(0.38))),
          child: Text('${post.category.emoji} ${post.category.label}',
              style: TextStyle(color: post.category.color, fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        Text(_timeAgo(post.createdAt),
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
      ]),
    ])),
    GestureDetector(
      onTap: () => _showPostOptions(post),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(Icons.more_horiz_rounded,
            color: Colors.white.withOpacity(0.28), size: 20),
      ),
    ),
  ]);

  Widget _postContent(_CPost post) {
    if (post.isSensitive && post.isBlurred) {
      return GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); setState(() => post.isBlurred = false); },
        child: Stack(children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Text(post.content,
                style: TextStyle(color: Colors.white.withOpacity(0.75),
                    fontSize: 14.5, height: 1.55)),
          ),
          Positioned.fill(child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
              color: Colors.black.withOpacity(0.55),
              border: Border.all(color: Colors.white.withOpacity(0.18))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.visibility_off_rounded, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text('Sensitive content — tap to read',
                  style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12)),
            ]),
          ))),
        ]),
      );
    }
    return Text(post.content, style: TextStyle(color: Colors.white.withOpacity(0.82),
        fontSize: 14.5, height: 1.55));
  }

  Widget _reactionBar(_CPost post) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _CRxn.values.map((rxn) {
          final base     = post.reactions[rxn] ?? 0;
          final isMine   = post.myReactions.contains(rxn);
          final count    = base + (isMine ? 1 : 0);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (isMine) post.myReactions.remove(rxn);
                  else        post.myReactions.add(rxn);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isMine ? LinearGradient(colors: [
                    _cPurple.withOpacity(0.62), _cPink.withOpacity(0.42)]) : null,
                  color: isMine ? null : Colors.white.withOpacity(0.06),
                  border: Border.all(
                      color: isMine ? _cPurple.withOpacity(0.7) : Colors.white.withOpacity(0.1),
                      width: 1),
                  boxShadow: isMine ? [BoxShadow(color: _cPurple.withOpacity(0.35),
                      blurRadius: 10)] : null,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(rxn.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(rxn.label, style: TextStyle(
                      color: isMine ? Colors.white : Colors.white.withOpacity(0.52),
                      fontSize: 11,
                      fontWeight: isMine ? FontWeight.w600 : FontWeight.w400)),
                  if (count > 0) ...[
                    const SizedBox(width: 5),
                    Text('$count', style: TextStyle(
                        color: isMine ? Colors.white : Colors.white.withOpacity(0.4),
                        fontSize: 10.5, fontWeight: FontWeight.w600)),
                  ],
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _postFooter(_CPost post) => Row(children: [
    Icon(Icons.chat_bubble_outline_rounded,
        color: Colors.white.withOpacity(0.28), size: 15),
    const SizedBox(width: 5),
    Text('${post.commentsCount} replies',
        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
    const Spacer(),
    GestureDetector(
      onTap: _showKindnessReminder,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          color: _cPink.withOpacity(0.08),
          border: Border.all(color: _cPink.withOpacity(0.22))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🌸', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text('Reply with care', style: TextStyle(color: _cPink.withOpacity(0.7),
              fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    ),
  ]);

  // ── POST OPTIONS ──────────────────────────────────────────
  void _showPostOptions(_CPost post) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0535),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.09))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2))),
          const SizedBox(height: 20),
          _optionTile(Icons.flag_outlined, 'Report Post', 'Not safe or hurtful content',
              const Color(0xFFE53935), () {
                setState(() => post.isReported = true);
                Navigator.pop(context); _showSafetyAck();
              }),
          const SizedBox(height: 10),
          _optionTile(Icons.visibility_off_outlined, 'Hide Post', 'I don\'t want to see this',
              Colors.white54, () { setState(() => _posts.remove(post)); Navigator.pop(context); }),
          const SizedBox(height: 10),
          _optionTile(Icons.favorite_border_rounded, 'Send Healing',
              'Share warmth with this person', _cPink, () { Navigator.pop(context); _showKindnessReminder(); }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _optionTile(IconData ic, String title, String sub, Color c, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
            color: c.withOpacity(0.08),
            border: Border.all(color: c.withOpacity(0.2))),
          child: Row(children: [
            Icon(ic, color: c, size: 20),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 12)),
            ]),
          ]),
        ),
      );

  void _showSafetyAck() {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: [
                _cGreen.withOpacity(0.2), _cDeep.withOpacity(0.9)]),
              border: Border.all(color: _cGreen.withOpacity(0.4))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('✅', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 14),
              const Text('Thank You 💜', style: TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('Your report helps keep this space safe and healing for everyone. Every report is reviewed with care.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.62),
                      fontSize: 13.5, height: 1.5)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(colors: [
                      _cGreen.withOpacity(0.7), _cGreen.withOpacity(0.45)])),
                  child: const Text('Close', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              ),
            ]),
          )),
    )));
  }

  void _showKindnessReminder() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_cPurple.withOpacity(0.28), _cBg]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: _cPurple.withOpacity(0.3))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2))),
          const SizedBox(height: 20),
          const Text('🌸', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          const Text('Kindness Is Medicine',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Your presence in this space matters. Before you reply, take a breath and lead with compassion. Your words can be the gentlest thing someone experiences today 💜',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.62),
                  fontSize: 14, height: 1.55)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Text('"Be the healing you wish to feel in the world"',
                textAlign: TextAlign.center,
                style: TextStyle(color: _cPurple, fontSize: 14,
                    fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ── COMPOSE FAB ───────────────────────────────────────────
  Widget _composeFAB() => AnimatedBuilder(
    animation: _glowAnim,
    builder: (_, __) => GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); setState(() => _showCompose = true); },
      child: Container(
        width: 62, height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_cPurple, _cPink]),
          boxShadow: [
            BoxShadow(color: _cPurple.withOpacity(_glowAnim.value * 0.8), blurRadius: 24, spreadRadius: 4),
            BoxShadow(color: _cPink.withOpacity(_glowAnim.value * 0.45), blurRadius: 14, spreadRadius: 2),
          ]),
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 26),
      ),
    ),
  );

  // ── COMPOSE OVERLAY ───────────────────────────────────────
  Widget _composeOverlay(BuildContext ctx) {
    return GestureDetector(
      onTap: () { setState(() => _showCompose = false); FocusScope.of(ctx).unfocus(); },
      child: Container(
        color: Colors.black.withOpacity(0.72),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: const Color(0xFF1A0535).withOpacity(0.95),
                    border: Border.all(color: _cPurple.withOpacity(0.45), width: 1.5),
                    boxShadow: [BoxShadow(color: _cPurple.withOpacity(0.28),
                        blurRadius: 40, spreadRadius: 4)]),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(22),
                    child: Column(mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // ─ Header
                      Row(children: [
                        const Text('✍️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        const Text('Share Your Heart', style: TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () { setState(() => _showCompose = false); FocusScope.of(ctx).unfocus(); },
                          child: Icon(Icons.close_rounded,
                              color: Colors.white.withOpacity(0.38), size: 22)),
                      ]),
                      const SizedBox(height: 4),
                      Text('This space holds you with care 💜',
                          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
                      const SizedBox(height: 20),

                      // ─ Identity
                      _label('Identity'),
                      const SizedBox(height: 10),
                      Row(children: [
                        _anonBtn(true,  '🌙 Anonymous', 'Name never shown'),
                        const SizedBox(width: 10),
                        _anonBtn(false, '🌸 Pseudonym',  'Choose avatar below'),
                      ]),
                      const SizedBox(height: 16),

                      // ─ Avatar picker
                      _label('Your Avatar'),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(children: _kAvatars.asMap().entries.map((e) {
                          final sel = _composeAvatarIdx == e.key;
                          final (emoji, color) = e.value;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () { HapticFeedback.selectionClick(); setState(() => _composeAvatarIdx = e.key); },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 46, height: 46,
                                decoration: BoxDecoration(shape: BoxShape.circle,
                                  gradient: sel ? RadialGradient(colors: [
                                    color.withOpacity(0.9), color.withOpacity(0.4)]) : null,
                                  color: sel ? null : Colors.white.withOpacity(0.06),
                                  border: Border.all(
                                      color: sel ? color : Colors.white.withOpacity(0.14),
                                      width: sel ? 2 : 1),
                                  boxShadow: sel ? [BoxShadow(color: color.withOpacity(0.5),
                                      blurRadius: 12)] : null),
                                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                              ),
                            ),
                          );
                        }).toList()),
                      ),
                      const SizedBox(height: 16),

                      // ─ Category
                      _label('Category'),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(children: _CCat.values.where((c) => c != _CCat.all).map((cat) {
                          final sel = _composeCat == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () { HapticFeedback.selectionClick(); setState(() => _composeCat = cat); },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                                  gradient: sel ? LinearGradient(colors: [
                                    cat.color.withOpacity(0.65), cat.color.withOpacity(0.4)]) : null,
                                  color: sel ? null : Colors.white.withOpacity(0.06),
                                  border: Border.all(
                                      color: sel ? cat.color : Colors.white.withOpacity(0.11))),
                                child: Text('${cat.emoji} ${cat.label}', style: TextStyle(
                                    color: sel ? Colors.white : Colors.white.withOpacity(0.52),
                                    fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                              ),
                            ),
                          );
                        }).toList()),
                      ),
                      const SizedBox(height: 16),

                      // ─ Emotional tags
                      _label('How are you feeling? (up to 3)'),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: _kEmotionalTags.map((t) {
                        final sel = _composeTags.contains(t);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (sel) _composeTags.remove(t);
                              else if (_composeTags.length < 3) _composeTags.add(t);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                              gradient: sel ? LinearGradient(colors: [
                                _cPink.withOpacity(0.55), _cPurple.withOpacity(0.4)]) : null,
                              color: sel ? null : Colors.white.withOpacity(0.06),
                              border: Border.all(
                                  color: sel ? _cPink : Colors.white.withOpacity(0.11))),
                            child: Text(t, style: TextStyle(
                                color: sel ? Colors.white : Colors.white.withOpacity(0.52),
                                fontSize: 12, fontWeight: sel ? FontWeight.w500 : FontWeight.w400)),
                          ),
                        );
                      }).toList()),
                      const SizedBox(height: 16),

                      // ─ Text field
                      _label('Your words'),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(color: Colors.white.withOpacity(0.11))),
                        child: TextField(
                          controller: _composeCtrl, maxLines: 5,
                          style: TextStyle(color: Colors.white.withOpacity(0.84),
                              fontSize: 14.5, height: 1.5),
                          decoration: InputDecoration(
                            hintText: 'Speak freely. This is your safe space...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.24), fontSize: 14),
                            contentPadding: const EdgeInsets.all(16),
                            border: InputBorder.none),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Be kind to yourself and others 🌸',
                          style: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 11)),
                      const SizedBox(height: 18),

                      // ─ Post button
                      GestureDetector(
                        onTap: _submitPost,
                        child: AnimatedBuilder(
                          animation: _glowAnim,
                          builder: (_, __) => Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _cPurple.withOpacity(_glowAnim.value),
                                  _cPink.withOpacity(_glowAnim.value)]),
                              boxShadow: [BoxShadow(
                                  color: _cPurple.withOpacity(_glowAnim.value * 0.5),
                                  blurRadius: 20, spreadRadius: 2)]),
                            child: const Text('Share with the Community 💜',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(color: Colors.white.withOpacity(0.52),
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3));

  Widget _anonBtn(bool isAnon, String label, String sub) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _composeAnon = isAnon),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: (_composeAnon == isAnon) ? LinearGradient(colors: [
            _cPurple.withOpacity(0.55), _cPink.withOpacity(0.35)]) : null,
          color: (_composeAnon == isAnon) ? null : Colors.white.withOpacity(0.05),
          border: Border.all(
              color: (_composeAnon == isAnon) ? _cPurple.withOpacity(0.7) : Colors.white.withOpacity(0.11))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
              color: (_composeAnon == isAnon) ? Colors.white : Colors.white.withOpacity(0.58),
              fontSize: 13, fontWeight: FontWeight.w600)),
          Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.32), fontSize: 11)),
        ]),
      ),
    ),
  );

  void _submitPost() {
    if (_composeCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    final (emoji, color) = _kAvatars[_composeAvatarIdx];
    final pseudonym = _composeAnon
        ? 'Anonymous $emoji'
        : 'You $emoji';
    setState(() {
      _posts.insert(0, _CPost(
        id: 'u_${DateTime.now().microsecondsSinceEpoch}',
        pseudonym: pseudonym,
        avatarEmoji: emoji, avatarColor: color,
        isAnonymous: _composeAnon,
        category: _composeCat,
        content: _composeCtrl.text.trim(),
        tags: _composeTags.toList(),
        createdAt: DateTime.now(),
      ));
      _showCompose = false;
      _composeTags.clear();
      _composeCtrl.clear();
    });
    FocusScope.of(context).unfocus();
  }

  // ── EMPTY STATE ───────────────────────────────────────────
  Widget _emptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 40),
    child: Column(children: [
      Text(_activeCat.emoji, style: const TextStyle(fontSize: 52)),
      const SizedBox(height: 16),
      Text('Be the first to share\nin ${_activeCat.label}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 18,
              fontWeight: FontWeight.w600, height: 1.4)),
      const SizedBox(height: 10),
      Text('This space is waiting for your voice 🌸',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 13)),
    ]),
  );

  // ── HELPERS ───────────────────────────────────────────────
  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1)  return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours   < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// ═══════════════════════════════════════════════════════════
//  DREAMY BACKGROUND
// ═══════════════════════════════════════════════════════════

class _CBackground extends StatelessWidget {
  final Size size;
  const _CBackground({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size.width, height: size.height,
    decoration: const BoxDecoration(
      gradient: RadialGradient(center: Alignment(0.0, -0.4), radius: 1.35,
          colors: [Color(0xFF2D0B5C), Color(0xFF18063A), _cBg])),
    child: Stack(children: [
      Positioned(top: -80,  left: -60,  child: _blob(310, _cPurple, 0.22)),
      Positioned(top: 50,   right: -65, child: _blob(260, _cPink,   0.16)),
      Positioned(top: 320,  left: -20,  child: _blob(240, _cTeal,   0.08)),
      Positioned(bottom: 90, right: -45,child: _blob(285, _cDeep,   0.2)),
      Positioned(bottom: 0,  left: -50, child: _blob(220, _cGold,   0.09)),
    ]),
  );

  Widget _blob(double s, Color c, double o) => Container(
    width: s, height: s,
    decoration: BoxDecoration(shape: BoxShape.circle,
      gradient: RadialGradient(colors: [c.withOpacity(o), Colors.transparent])),
  );
}

// ═══════════════════════════════════════════════════════════
//  PARTICLE PAINTER
// ═══════════════════════════════════════════════════════════

class _CStar {
  late double x, y, speed, size, opacity, angle;
  _CStar({required math.Random rng}) { _r(rng); }
  void _r(math.Random rng) {
    x = rng.nextDouble(); y = rng.nextDouble();
    speed   = 0.00010 + rng.nextDouble() * 0.00020;
    size    = 0.6 + rng.nextDouble() * 2.1;
    opacity = 0.18 + rng.nextDouble() * 0.5;
    angle   = rng.nextDouble() * math.pi * 2;
  }
}

class _CParticlePainter extends CustomPainter {
  final List<_CStar> stars;
  final double       progress;
  _CParticlePainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in stars) {
      final x = (p.x + math.cos(p.angle) * p.speed * progress * 85) % 1.0;
      final y = (p.y - p.speed * progress * 210) % 1.0;
      canvas.drawCircle(
          Offset(x * size.width, y * size.height), p.size,
          Paint()
            ..color = Colors.white.withOpacity(p.opacity * 0.65)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1));
      if (p.size > 1.5) {
        final sp = Paint()
          ..color = _cPurple.withOpacity(p.opacity * 0.38)
          ..strokeWidth = 0.5;
        final cx = x * size.width;
        final cy = y * size.height;
        canvas.drawLine(Offset(cx - 4, cy), Offset(cx + 4, cy), sp);
        canvas.drawLine(Offset(cx, cy - 4), Offset(cx, cy + 4), sp);
      }
    }
  }

  @override
  bool shouldRepaint(_CParticlePainter o) => o.progress != progress;
}
