import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/models/community_models.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/community_provider.dart';
import '../widgets/guest_gate.dart';
import '../core/providers/avatar_provider.dart';
import '../core/providers/connection_provider.dart';
import '../models/connection_model.dart';
import '../widgets/lunar_avatar_widget.dart';
import 'community_profile_screen.dart';
import 'connections_hub_screen.dart';

// ═══════════════════════════════════════════════════════════
//  LUNAR COMMUNITY — Safe Space Screen
// ═══════════════════════════════════════════════════════════

// ── Design tokens ─────────────────────────────────────────
const Color _cBg = Color(0xFF0A0118);
const Color _cPurple = Color(0xFFAB5CF2);
const Color _cPink = Color(0xFFFF69B4);
const Color _cDeep = Color(0xFF5C2DB8);
const Color _cGold = Color(0xFFFFD700);
const Color _cTeal = Color(0xFF4FC3F7);
const Color _cGreen = Color(0xFF66BB6A);
const Color _cIndigo = Color(0xFF7986CB);

// ═══════════════════════════════════════════════════════════
//  ENUMS
// ═══════════════════════════════════════════════════════════

enum _CCat {
  all,
  periodTalk,
  pregnancy,
  emotionalHealing,
  relationships,
  anxietySupport,
  selfCare,
  sleepWellness,
}

extension _CCatX on _CCat {
  String get id => const {
        _CCat.all: 'all',
        _CCat.periodTalk: 'periodTalk',
        _CCat.pregnancy: 'pregnancy',
        _CCat.emotionalHealing: 'emotionalHealing',
        _CCat.relationships: 'relationships',
        _CCat.anxietySupport: 'anxietySupport',
        _CCat.selfCare: 'selfCare',
        _CCat.sleepWellness: 'sleepWellness',
      }[this]!;

  String get label => const {
        _CCat.all: 'All',
        _CCat.periodTalk: 'Period Talk',
        _CCat.pregnancy: 'Pregnancy',
        _CCat.emotionalHealing: 'Emotional Healing',
        _CCat.relationships: 'Relationships',
        _CCat.anxietySupport: 'Anxiety Support',
        _CCat.selfCare: 'Self Care',
        _CCat.sleepWellness: 'Sleep & Wellness',
      }[this]!;

  String get emoji => const {
        _CCat.all: '🌸',
        _CCat.periodTalk: '🩸',
        _CCat.pregnancy: '🤰',
        _CCat.emotionalHealing: '💜',
        _CCat.relationships: '💞',
        _CCat.anxietySupport: '🌬️',
        _CCat.selfCare: '🌿',
        _CCat.sleepWellness: '🌙',
      }[this]!;

  Color get color => const {
        _CCat.all: _cPink,
        _CCat.periodTalk: Color(0xFFE53935),
        _CCat.pregnancy: _cGold,
        _CCat.emotionalHealing: _cPurple,
        _CCat.relationships: Color(0xFFEC407A),
        _CCat.anxietySupport: _cTeal,
        _CCat.selfCare: _cGreen,
        _CCat.sleepWellness: _cIndigo,
      }[this]!;
}

enum _CRxn { support, sendingLove, youreStrong, hugs, healingEnergy }

extension _CRxnX on _CRxn {
  String get id => const {
        _CRxn.support: 'support',
        _CRxn.sendingLove: 'sendingLove',
        _CRxn.youreStrong: 'youreStrong',
        _CRxn.hugs: 'hugs',
        _CRxn.healingEnergy: 'healingEnergy',
      }[this]!;

  String get emoji => const {
        _CRxn.support: '🤍',
        _CRxn.sendingLove: '💜',
        _CRxn.youreStrong: '🌙',
        _CRxn.hugs: '🌸',
        _CRxn.healingEnergy: '✨',
      }[this]!;

  String get label => const {
        _CRxn.support: 'Support',
        _CRxn.sendingLove: 'Sending Love',
        _CRxn.youreStrong: 'You\'re Strong',
        _CRxn.hugs: 'Warm Hugs',
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
  _CStory(
      name: 'Lunar AI',
      emoji: '🌙',
      color: _cPurple,
      mood: 'Here for you ✨',
      isAI: true),
  _CStory(
      name: 'MoonRose', emoji: '🌸', color: _cPink, mood: 'Feeling hopeful 🌷'),
  _CStory(
      name: 'StarLight', emoji: '⭐', color: _cGold, mood: 'Grateful today 💛'),
  _CStory(
      name: 'Violet', emoji: '🦋', color: _cPurple, mood: 'Healing gently 💜'),
  _CStory(
      name: 'BlueWave', emoji: '🌊', color: _cTeal, mood: 'Finding calm 🌊'),
  _CStory(
      name: 'Ember',
      emoji: '🌺',
      color: Color(0xFFEC407A),
      mood: 'Processing 🌿'),
  _CStory(
      name: 'Aurora',
      emoji: '✨',
      color: Color(0xFF7B39BD),
      mood: 'Empowered ✨'),
  _CStory(name: 'Fern', emoji: '🍀', color: _cGreen, mood: 'Self care day 🌱'),
];

List<_CPost> _buildSeedPosts() {
  final now = DateTime.now();
  return [
    _CPost(
      id: 'p1',
      pseudonym: 'MoonRose',
      avatarEmoji: '🌸',
      avatarColor: _cPink,
      category: _CCat.emotionalHealing,
      content:
          'Today was unexpectedly hard. I cried in the shower and that\'s okay. Sometimes we just need to feel it all. To anyone else carrying something heavy right now — you are not alone 💜',
      tags: ['Processing', 'Need Support'],
      reactions: {_CRxn.support: 47, _CRxn.sendingLove: 31, _CRxn.hugs: 28},
      commentsCount: 14,
      createdAt: now.subtract(const Duration(minutes: 23)),
    ),
    _CPost(
      id: 'p2',
      pseudonym: 'StarLight',
      avatarEmoji: '⭐',
      avatarColor: _cGold,
      category: _CCat.pregnancy,
      content:
          'Week 22 and I just felt the first real kick! Not the little flutters but an actual KICK. I burst into tears of joy. She\'s so real and so alive 🌟 Third trimester, here we come! 🤰',
      tags: ['Celebrating', 'Grateful'],
      reactions: {
        _CRxn.support: 89,
        _CRxn.sendingLove: 64,
        _CRxn.youreStrong: 41,
        _CRxn.healingEnergy: 33
      },
      commentsCount: 29,
      createdAt: now.subtract(const Duration(hours: 1)),
    ),
    _CPost(
      id: 'p3',
      pseudonym: 'Anonymous 🌙',
      avatarEmoji: '🌙',
      avatarColor: _cPurple,
      isAnonymous: true,
      category: _CCat.anxietySupport,
      content:
          'Does anyone else\'s anxiety peak right before their period? I feel like a different person for those 3 days. Racing thoughts, doom spirals, crying at absolutely nothing. Hormones are so wild. You\'re not broken if this is you too 🌬️',
      tags: ['Anxious', 'Struggling'],
      reactions: {_CRxn.support: 112, _CRxn.hugs: 78, _CRxn.youreStrong: 55},
      commentsCount: 41,
      createdAt: now.subtract(const Duration(hours: 2, minutes: 14)),
    ),
    _CPost(
      id: 'p4',
      pseudonym: 'Violet',
      avatarEmoji: '🦋',
      avatarColor: Color(0xFF7B39BD),
      category: _CCat.selfCare,
      content:
          'My Sunday ritual: lavender bath, no phone, just me and my favourite playlist. It took me years to believe I deserved this kind of gentleness from myself. You deserve it too 🌸✨',
      tags: ['Healing', 'Empowered'],
      reactions: {
        _CRxn.support: 73,
        _CRxn.sendingLove: 49,
        _CRxn.healingEnergy: 61
      },
      commentsCount: 18,
      createdAt: now.subtract(const Duration(hours: 4)),
    ),
    _CPost(
      id: 'p5',
      pseudonym: 'Anonymous 💫',
      avatarEmoji: '💫',
      avatarColor: Color(0xFFBA68C8),
      isAnonymous: true,
      category: _CCat.periodTalk,
      content:
          'Cycle day 2 and I\'m horizontal on the couch with a heating pad and I\'m calling it productivity. No explanation needed. Solidarity to everyone bleeding with me right now 🩸❤️',
      tags: ['Struggling', 'Finding Peace'],
      reactions: {_CRxn.support: 204, _CRxn.hugs: 156, _CRxn.sendingLove: 93},
      commentsCount: 67,
      createdAt: now.subtract(const Duration(hours: 5, minutes: 40)),
    ),
    _CPost(
      id: 'p6',
      pseudonym: 'Aurora',
      avatarEmoji: '✨',
      avatarColor: Color(0xFF7B39BD),
      category: _CCat.relationships,
      content:
          'It took me 6 months but I finally told my partner how PMS affects my emotions. The conversation was scary but she held my hand through the whole thing. Communication is everything 💞',
      tags: ['Empowered', 'Grateful'],
      reactions: {
        _CRxn.support: 58,
        _CRxn.sendingLove: 82,
        _CRxn.healingEnergy: 44
      },
      commentsCount: 22,
      createdAt: now.subtract(const Duration(hours: 7)),
    ),
    _CPost(
      id: 'p7',
      pseudonym: 'Fern',
      avatarEmoji: '🍀',
      avatarColor: _cGreen,
      category: _CCat.sleepWellness,
      content:
          'Sleep hack that changed my luteal phase completely: no screens 90 minutes before bed, magnesium glycinate, and a consistent wake time even on weekends. My mood is dramatically better 🌙',
      tags: ['Healing', 'Feeling Hopeful'],
      reactions: {
        _CRxn.support: 91,
        _CRxn.healingEnergy: 67,
        _CRxn.sendingLove: 38
      },
      commentsCount: 34,
      createdAt: now.subtract(const Duration(hours: 9)),
    ),
    _CPost(
      id: 'p8',
      pseudonym: 'Anonymous 🌺',
      avatarEmoji: '🌺',
      avatarColor: Color(0xFFEC407A),
      isAnonymous: true,
      category: _CCat.emotionalHealing,
      content:
          'Healing confession: I\'m not okay some days and that\'s the most honest thing I\'ve said in weeks. If you\'re also pretending to be fine — this is a safe space. You can just be where you are 💜',
      tags: ['Vulnerable', 'Processing'],
      reactions: {_CRxn.support: 187, _CRxn.hugs: 142, _CRxn.sendingLove: 118},
      commentsCount: 53,
      createdAt: now.subtract(const Duration(hours: 11)),
    ),
    _CPost(
      id: 'p9',
      pseudonym: 'BlueWave',
      avatarEmoji: '🌊',
      avatarColor: _cTeal,
      category: _CCat.anxietySupport,
      content:
          'Box breathing before stressful situations has genuinely saved me this month. 4-4-4-4. Inhale for 4, hold for 4, out for 4, hold for 4. Your nervous system will thank you 🌬️ Try it right now.',
      tags: ['Healing', 'Empowered'],
      reactions: {
        _CRxn.support: 76,
        _CRxn.healingEnergy: 91,
        _CRxn.youreStrong: 44
      },
      commentsCount: 19,
      createdAt: now.subtract(const Duration(hours: 13)),
    ),
    _CPost(
      id: 'p10',
      pseudonym: 'Anonymous ❄️',
      avatarEmoji: '❄️',
      avatarColor: Color(0xFF80DEEA),
      isAnonymous: true,
      category: _CCat.pregnancy,
      content:
          'Miscarriage at 9 weeks. I don\'t have words yet. I\'m just sitting here feeling the weight of it. If you\'ve been here, I\'d love to hear that it gets gentler. Not easier — just gentler.',
      tags: ['Vulnerable', 'Need Support'],
      reactions: {
        _CRxn.support: 312,
        _CRxn.hugs: 267,
        _CRxn.sendingLove: 241,
        _CRxn.youreStrong: 189
      },
      commentsCount: 98,
      createdAt: now.subtract(const Duration(hours: 16)),
      isSensitive: true,
    ),
    _CPost(
      id: 'p11',
      pseudonym: 'MoonRose',
      avatarEmoji: '🌸',
      avatarColor: _cPink,
      category: _CCat.selfCare,
      content:
          'Reminder that "self care" doesn\'t have to be a spa day. Today mine was drinking enough water and getting dressed. Small acts of care count. You\'re doing the best you can 🌸',
      tags: ['Feeling Hopeful', 'Healing'],
      reactions: {
        _CRxn.support: 143,
        _CRxn.sendingLove: 107,
        _CRxn.healingEnergy: 88
      },
      commentsCount: 31,
      createdAt: now.subtract(const Duration(hours: 18)),
    ),
    _CPost(
      id: 'p12',
      pseudonym: 'Ember',
      avatarEmoji: '🌺',
      avatarColor: Color(0xFFEC407A),
      category: _CCat.periodTalk,
      content:
          'Just tracked my 12th consecutive cycle on Lunar 🩸 The patterns I\'ve discovered about my mood, energy, and creativity across the cycle are genuinely mind-blowing. We are cyclical beings 💜',
      tags: ['Empowered', 'Celebrating'],
      reactions: {
        _CRxn.support: 64,
        _CRxn.healingEnergy: 53,
        _CRxn.sendingLove: 29
      },
      commentsCount: 21,
      createdAt: now.subtract(const Duration(hours: 22)),
    ),
  ];
}

const Map<_CCat, (String, String)> _kAISuggestions = {
  _CCat.all: (
    '💜',
    'Lunar AI is here — this is a safe, gentle space for all of you.'
  ),
  _CCat.periodTalk: (
    '🩸',
    'Cycle awareness is self-knowledge. Your body has so much wisdom to share.'
  ),
  _CCat.pregnancy: (
    '🤰',
    'Every pregnancy is a unique sacred story. You\'re exactly where you need to be.'
  ),
  _CCat.emotionalHealing: (
    '💜',
    'Healing isn\'t linear. Coming here is already a brave act of self-care.'
  ),
  _CCat.relationships: (
    '💞',
    'Communicating our cycle to loved ones builds deeper, more honest connection.'
  ),
  _CCat.anxietySupport: (
    '🌬️',
    'You are safe right now. Take a breath. This community holds space for you.'
  ),
  _CCat.selfCare: (
    '🌿',
    'Tending to yourself is the most radical, beautiful thing you can do.'
  ),
  _CCat.sleepWellness: (
    '🌙',
    'Rest is not laziness. Your body does its deepest healing while you sleep.'
  ),
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

const List<String> _kHealingQuotes = [
  'You are never alone here 🌙',
  'A soft space for healing and connection ✨',
  'Every voice here is sacred and loved 💜',
  'Your feelings are valid. Your voice matters 🌸',
  'Healing is not linear — and that is okay 🌿',
  'You are loved exactly as you are 🤍',
  'This community holds you with care 🌙',
  'Be kind · No judgment · You belong here 💜',
];

const List<(String, String, Color)> _kHealingCircles = [
  ('🩸', 'Period\nSupport', Color(0xFFE53935)),
  ('🤰', 'Pregnancy\nCircle', _cGold),
  ('💜', 'Emotional\nHealing', _cPurple),
  ('🌬️', 'Anxiety\nRelief', _cTeal),
  ('🌙', 'Sleep\nWellness', _cIndigo),
  ('🌿', 'Self\nLove', _cGreen),
];

const List<String> _kEmotionalTags = [
  'Feeling Hopeful',
  'Need Support',
  'Grateful',
  'Anxious',
  'Processing',
  'Healing',
  'Celebrating',
  'Struggling',
  'Overwhelmed',
  'Finding Peace',
  'Empowered',
  'Vulnerable',
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

  final List<_CStar> _stars = [];
  final math.Random _rng = math.Random();

  _CCat _activeCat = _CCat.all;
  bool _showCompose = false;
  final Set<String> _viewedStories = {};

  // Compose state
  bool _composeAnon = true;
  int _composeAvatarIdx = 0;
  _CCat _composeCat = _CCat.emotionalHealing;
  CommunityPostType _composePostType = CommunityPostType.regular;
  final Set<String> _composeTags = {};
  final TextEditingController _composeCtrl = TextEditingController();
  bool _providerInitialized = false;
  int _quoteIdx = 0;
  Timer? _quoteTimer;

  // Phase 5: AI support suggestions per post
  final Map<String, String> _aiSuggestions = {};
  final Set<String> _loadingAiFor = {};

  // Phase 5: pagination scroll
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();

    _glowCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _floatCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _particleCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 7))
          ..repeat();

    for (int i = 0; i < 32; i++) _stars.add(_CStar(rng: _rng));
    _quoteTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted)
        setState(() => _quoteIdx = (_quoteIdx + 1) % _kHealingQuotes.length);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    // No-op: pagination hook ready for future backend implementation
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_providerInitialized) {
      _providerInitialized = true;
      final auth = Provider.of<LunarAuthProvider>(context, listen: false);
      final community = Provider.of<CommunityProvider>(context, listen: false);
      community.init(auth.firebaseUser?.uid);
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _particleCtrl.dispose();
    _composeCtrl.dispose();
    _scrollCtrl.dispose();
    _quoteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final community = Provider.of<CommunityProvider>(context);
    final auth = Provider.of<LunarAuthProvider>(context, listen: false);
    final posts = community.filteredPosts;

    return Scaffold(
      backgroundColor: _cBg,
      body: Stack(
        children: [
          _CBackground(size: size),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _CParticlePainter(
                    stars: _stars, progress: _particleCtrl.value),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(children: [
                      const SizedBox(height: 14),
                      _emotionalHeader(community),
                      const SizedBox(height: 18),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(child: _storiesRow()),
                SliverToBoxAdapter(child: const SizedBox(height: 16)),
                // Phase 5: Daily Check-In Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _dailyCheckInCard(community.todayCheckInPrompt),
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _anonymousSafetyCard(),
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 18)),
                // Phase 5: Functional Healing Circles
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _healingCirclesRow(community),
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 16)),
                SliverToBoxAdapter(child: _categoryTabs(community)),
                SliverToBoxAdapter(child: const SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _aiCompanionCard(community.activeCategory),
                  ),
                ),
                // Phase 5: Healing Stories Section
                if (community.healingStories.isNotEmpty) ...[
                  SliverToBoxAdapter(child: const SizedBox(height: 14)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _healingStoriesSection(community.healingStories),
                    ),
                  ),
                ],
                SliverToBoxAdapter(child: const SizedBox(height: 14)),
                if (community.loadState == CommunityLoadState.loading &&
                    posts.isEmpty)
                  SliverToBoxAdapter(child: _loadingShimmer()),
                ...posts.map((post) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: RepaintBoundary(
                            child: _postCard(post, community, auth)),
                      ),
                    )),
                // Seed posts shown when Firestore is empty
                if (community.loadState == CommunityLoadState.loaded &&
                    posts.isEmpty)
                  ..._buildSeedPosts().map((post) => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: RepaintBoundary(child: _seedPostCard(post)),
                        ),
                      )),
                if (community.loadState == CommunityLoadState.loaded &&
                    posts.isEmpty &&
                    _buildSeedPosts().isEmpty)
                  SliverToBoxAdapter(child: _emptyState()),
                SliverToBoxAdapter(child: const SizedBox(height: 110)),
              ],
            ),
          ),
          Positioned(right: 20, bottom: 28, child: _composeFAB()),
          if (_showCompose) _composeOverlay(context, community, auth),
        ],
      ),
    );
  }

  // ── EMOTIONAL HEADER ──────────────────────────────────────
  Widget _emotionalHeader(CommunityProvider community) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: back + title + floating orb
        Row(
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
                    const Text('Safe Space 🌸',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text('A gentle community for every woman',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12)),
                      if (community.supportCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: community.communityAward.color
                                  .withOpacity(0.18),
                              border: Border.all(
                                  color: community.communityAward.color
                                      .withOpacity(0.45))),
                          child: Text(
                            '${community.communityAward.emoji} ${community.communityAward.label}',
                            style: TextStyle(
                                color: community.communityAward.color,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ]),
                  ]),
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_floatAnim, _glowAnim]),
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _floatAnim.value * 0.4),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _cPurple.withOpacity(_glowAnim.value * 0.85),
                      Colors.transparent
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: _cPurple.withOpacity(_glowAnim.value * 0.5),
                          blurRadius: 20,
                          spreadRadius: 2)
                    ],
                  ),
                  child: const Text('🌸', style: TextStyle(fontSize: 22)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // ── Connections button with badge ───────────────
            Consumer<ConnectionProvider>(
              builder: (_, cp, __) => GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConnectionsHubScreen()),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _cPurple.withOpacity(0.30),
                            _cPink.withOpacity(0.20),
                          ],
                        ),
                        border: Border.all(
                            color: _cPurple.withOpacity(0.45), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: _cPurple.withOpacity(0.25),
                              blurRadius: 12),
                        ],
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: _cPurple, size: 18),
                    ),
                    if (cp.incomingCount > 0)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _cPink,
                          ),
                          child: Center(
                            child: Text(
                              cp.incomingCount > 9
                                  ? '9+'
                                  : '${cp.incomingCount}',
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
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Rotating healing quote card with glassmorphism
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _cDeep.withOpacity(0.55),
                      _cPurple.withOpacity(0.28),
                      _cPink.withOpacity(0.12),
                    ],
                  ),
                  border: Border.all(
                      color: _cPurple.withOpacity(_glowAnim.value * 0.52),
                      width: 1.2),
                  boxShadow: [
                    BoxShadow(
                        color: _cPurple.withOpacity(_glowAnim.value * 0.18),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                ),
                child: Row(
                  children: [
                    // Moon orb icon
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          _cPurple.withOpacity(0.8 + 0.2 * _glowAnim.value),
                          _cPink.withOpacity(0.35),
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  _cPurple.withOpacity(_glowAnim.value * 0.60),
                              blurRadius: 16,
                              spreadRadius: 2)
                        ],
                      ),
                      child: const Center(
                          child: Text('🌙', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Community Spirit',
                                style: TextStyle(
                                  color: _cPurple.withOpacity(0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: _cGreen.withOpacity(0.14),
                                  border: Border.all(
                                      color: _cGreen.withOpacity(0.42),
                                      width: 1),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _cGreen,
                                              boxShadow: [
                                                BoxShadow(
                                                    color: _cGreen
                                                        .withOpacity(0.7),
                                                    blurRadius: 4,
                                                    spreadRadius: 1)
                                              ])),
                                      const SizedBox(width: 4),
                                      Text('Safe',
                                          style: TextStyle(
                                              color: _cGreen,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600)),
                                    ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 800),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: CurvedAnimation(
                                  parent: anim, curve: Curves.easeOut),
                              child: SlideTransition(
                                position: Tween<Offset>(
                                        begin: const Offset(0, 0.2),
                                        end: Offset.zero)
                                    .animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic)),
                                child: child,
                              ),
                            ),
                            child: Text(
                              _kHealingQuotes[_quoteIdx],
                              key: ValueKey(_quoteIdx),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 13,
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
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
  }

  // ── HEALING CIRCLES ROW (Phase 5: Functional) ────────────
  Widget _healingCirclesRow(CommunityProvider community) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Healing Circles',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a circle to enter your safe space',
          style: TextStyle(
              color: Colors.white.withOpacity(0.38),
              fontSize: 11.5),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: SafeSpaceCircle.values.map((circle) {
              final isActive = community.activeCategory == circle.id;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    community.setCategory(
                        isActive ? 'all' : circle.id);
                    _scrollCtrl.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          width: 92,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isActive
                                  ? [
                                      circle.color.withOpacity(0.5),
                                      circle.color.withOpacity(0.22),
                                    ]
                                  : [
                                      circle.color.withOpacity(0.16),
                                      circle.color.withOpacity(0.05),
                                    ],
                            ),
                            border: Border.all(
                                color: circle.color.withOpacity(
                                    isActive
                                        ? 0.75
                                        : _glowAnim.value * 0.42),
                                width: isActive ? 1.5 : 1),
                            boxShadow: [
                              BoxShadow(
                                  color: circle.color.withOpacity(
                                      isActive
                                          ? 0.28
                                          : _glowAnim.value * 0.12),
                                  blurRadius: 14,
                                  spreadRadius: isActive ? 2 : 0),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [
                                    circle.color.withOpacity(
                                        isActive ? 0.75 : 0.50),
                                    circle.color.withOpacity(0.12),
                                  ]),
                                  boxShadow: [
                                    BoxShadow(
                                        color: circle.color.withOpacity(
                                            _glowAnim.value * 0.40),
                                        blurRadius: 10,
                                        spreadRadius: 1),
                                  ],
                                ),
                                child: Center(
                                    child: Text(circle.emoji,
                                        style:
                                            const TextStyle(fontSize: 20))),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                circle.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isActive
                                      ? circle.color
                                      : Colors.white.withOpacity(0.70),
                                  fontSize: 10.5,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── DAILY CHECK-IN CARD (Phase 5) ────────────────────────
  Widget _dailyCheckInCard(CheckInPrompt prompt) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _cTeal.withOpacity(0.14),
                  _cPurple.withOpacity(0.08),
                ],
              ),
              border: Border.all(
                  color: _cTeal.withOpacity(_glowAnim.value * 0.4), width: 1),
            ),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _cTeal.withOpacity(0.45),
                    _cPurple.withOpacity(0.18),
                  ]),
                ),
                child: Center(
                    child: Text(prompt.emoji,
                        style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today\'s Check-In',
                          style: TextStyle(
                              color: _cTeal,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(
                        prompt.question,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13.5,
                            height: 1.4),
                      ),
                    ]),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _showCompose = true;
                    _composeCtrl.text = '${prompt.emoji} ${prompt.question}\n\n';
                    _composePostType = CommunityPostType.checkIn;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(colors: [
                      _cTeal.withOpacity(0.55),
                      _cPurple.withOpacity(0.4),
                    ]),
                  ),
                  child: const Text('Check In',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── HEALING STORIES SECTION (Phase 5) ────────────────────
  Widget _healingStoriesSection(List<CommunityPost> stories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('🌟',
              style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          const Text(
            'Healing Journeys',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _cGold.withOpacity(0.16),
                border: Border.all(color: _cGold.withOpacity(0.4))),
            child: Text('${stories.length}',
                style: TextStyle(
                    color: _cGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          'Stories of growth, courage & recovery',
          style: TextStyle(
              color: Colors.white.withOpacity(0.38), fontSize: 11.5),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: stories.take(5).map((post) {
              final totalReactions =
                  post.reactions.values.fold(0, (a, b) => a + b);
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _cGold.withOpacity(0.13),
                              _cPurple.withOpacity(0.08),
                            ],
                          ),
                          border: Border.all(
                              color: _cGold.withOpacity(
                                  _glowAnim.value * 0.45),
                              width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _cGold.withOpacity(0.22)),
                                child: Center(
                                    child: Text(post.avatarEmoji,
                                        style: const TextStyle(
                                            fontSize: 14))),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  post.pseudonym,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Text('🌟',
                                  style: TextStyle(fontSize: 12)),
                            ]),
                            const SizedBox(height: 8),
                            Text(
                              post.content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 12,
                                  height: 1.45),
                            ),
                            if (totalReactions > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                '$totalReactions people found healing here',
                                style: TextStyle(
                                    color: _cGold.withOpacity(0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _loadingShimmer() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          const SizedBox(height: 20),
          Text('Loading safe space...',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 14)),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _cPurple.withOpacity(_glowAnim.value * 0.6),
                      blurRadius: 20,
                      spreadRadius: 4),
                ],
              ),
              child: const Text('🌙',
                  style: TextStyle(fontSize: 32), textAlign: TextAlign.center),
            ),
          ),
        ]),
      );

  // ── HEADER ────────────────────────────────────────────────
  Widget _headerBar() => Row(
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Safe Space 🌸',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2)),
              Text('You are safe here. You belong here.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ]),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_floatAnim, _glowAnim]),
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _floatAnim.value * 0.4),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _cPurple.withOpacity(_glowAnim.value * 0.85),
                      Colors.transparent
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: _cPurple.withOpacity(_glowAnim.value * 0.5),
                          blurRadius: 20,
                          spreadRadius: 2)
                    ]),
                child: const Text('🌸', style: TextStyle(fontSize: 22)),
              ),
            ),
          ),
        ],
      );

  // ── ANONYMOUS EMOTIONAL SAFETY CARD ──────────────────────
  Widget _anonymousSafetyCard() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => GestureDetector(
        onTap: () => _showAnonymousShareModal(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    _cPurple.withOpacity(0.18),
                    _cPink.withOpacity(0.10),
                    Colors.white.withOpacity(0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: _cPurple.withOpacity(0.38 * _glowAnim.value),
                    width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _cPurple.withOpacity(0.10 * _glowAnim.value),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(children: [
                // Soft moon icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _cPink.withOpacity(0.30),
                      _cPurple.withOpacity(0.15),
                      Colors.transparent,
                    ]),
                    border:
                        Border.all(color: _cPink.withOpacity(0.35), width: 1),
                  ),
                  child: const Center(
                      child: Text('🌙', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'I just need to say this...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Say it anonymously. No name. No judgment. Just release.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.48),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(colors: [
                      _cPurple.withOpacity(0.60),
                      _cPink.withOpacity(0.40),
                    ]),
                  ),
                  child: const Text(
                    'Speak',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showAnonymousShareModal() {
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A0540),
                    const Color(0xFF0A0118),
                  ],
                ),
                border: Border.all(color: _cPurple.withOpacity(0.28), width: 1),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('🌙', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 10),
                const Text(
                  'Say it. Let it go.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Completely anonymous. Just you and the moon.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.06),
                    border:
                        Border.all(color: _cPurple.withOpacity(0.28), width: 1),
                  ),
                  child: TextField(
                    controller: textCtrl,
                    maxLines: 5,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.5),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      hintText:
                          'Whatever is in your heart right now... say it here. No one will know it was you.',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.28),
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withOpacity(0.07),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.12), width: 1),
                        ),
                        child: const Center(
                            child: Text('Maybe later',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 13.5))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (textCtrl.text.trim().isEmpty) return;
                        // Post as anonymous community post
                        final community = context.read<CommunityProvider>();
                        community.createPost(
                          pseudonym: 'Anonymous 🌙',
                          avatarEmoji: '🌙',
                          avatarColorHex: '#AB5CF2',
                          isAnonymous: true,
                          category: _CCat.emotionalHealing.id,
                          content: textCtrl.text.trim(),
                          tags: ['Vulnerable', 'Need Support'],
                          postType: CommunityPostType.anonymousShare,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: _cPurple.withOpacity(0.85),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            content: const Text(
                              'Released to the universe 🌙 You\'ve been heard.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(colors: [
                            _cPurple,
                            _cPink.withOpacity(0.80),
                          ]),
                        ),
                        child: const Center(
                            child: Text('Release it 🌙',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ))),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── SAFETY BANNER ─────────────────────────────────────────
  Widget _safetyBanner() => AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(colors: [
                    _cPurple.withOpacity(0.16),
                    _cPink.withOpacity(0.09)
                  ]),
                  border: Border.all(
                      color: _cPurple.withOpacity(_glowAnim.value * 0.45))),
              child: Row(children: [
                const Text('💜', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('This is a safe, anonymous space',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text('Be kind · No judgment · You belong here',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11.5)),
                    ])),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _cGreen.withOpacity(0.15),
                      border: Border.all(
                          color: _cGreen.withOpacity(0.45), width: 1)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _cGreen,
                            boxShadow: [
                              BoxShadow(
                                  color: _cGreen.withOpacity(0.7),
                                  blurRadius: 4,
                                  spreadRadius: 1)
                            ])),
                    const SizedBox(width: 5),
                    Text('Safe',
                        style: TextStyle(
                            color: _cGreen,
                            fontSize: 11,
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
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: viewed
                            ? null
                            : SweepGradient(colors: [
                                s.isAI ? _cPurple : s.color,
                                s.isAI ? _cPink : s.color.withOpacity(0.35),
                                s.isAI ? _cGold : s.color,
                              ]),
                        color: viewed ? Colors.white.withOpacity(0.08) : null,
                        boxShadow: viewed
                            ? null
                            : [
                                BoxShadow(
                                    color: s.color.withOpacity(
                                        s.isAI ? _glowAnim.value * 0.7 : 0.35),
                                    blurRadius: s.isAI ? 22 : 12,
                                    spreadRadius: s.isAI ? 3 : 1)
                              ],
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: Container(
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: _cBg),
                        child: Center(
                            child: Text(s.emoji,
                                style: const TextStyle(fontSize: 27))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(s.name,
                      style: TextStyle(
                          color: viewed
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white.withOpacity(0.8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
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
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [s.color.withOpacity(0.35), _cBg]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: s.color.withOpacity(0.4), width: 1)),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2))),
          const SizedBox(height: 28),
          Text(s.emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          Text(s.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(s.mood,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 16)),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: s.isAI
                ? Text(
                    'Lunar AI is gently watching over this space. Every story is safe, every voice matters. You are never alone here 💜',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: 15,
                        height: 1.6,
                        fontStyle: FontStyle.italic),
                  )
                : Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.06),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.12))),
                    child: Text('"${s.mood}"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            height: 1.5)),
                  ),
          ),
        ]),
      ),
    );
  }

  // ── CATEGORY TABS ─────────────────────────────────────────
  Widget _categoryTabs(CommunityProvider community) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _CCat.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final cat = _CCat.values[i];
            final active = community.activeCategory == cat.id;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                community.setCategory(cat.id);
                setState(() => _activeCat = cat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: active
                      ? LinearGradient(colors: [
                          cat.color.withOpacity(0.72),
                          cat.color.withOpacity(0.45)
                        ])
                      : null,
                  color: active ? null : Colors.white.withOpacity(0.07),
                  border: Border.all(
                      color:
                          active ? cat.color : Colors.white.withOpacity(0.12),
                      width: 1),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: cat.color.withOpacity(0.32),
                              blurRadius: 12)
                        ]
                      : null,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(cat.label,
                      style: TextStyle(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.52),
                          fontSize: 12.5,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400)),
                ]),
              ),
            );
          },
        ),
      );

  // ── AI COMPANION CARD ─────────────────────────────────────
  Widget _aiCompanionCard(String activeCategoryId) {
    final activeCat = _CCat.values
        .firstWhere((c) => c.id == activeCategoryId, orElse: () => _CCat.all);
    final (emoji, msg) =
        _kAISuggestions[activeCat] ?? _kAISuggestions[_CCat.all]!;
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
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _cDeep.withOpacity(0.55),
                      _cPurple.withOpacity(0.25),
                      _cPink.withOpacity(0.12)
                    ]),
                border: Border.all(
                    color: _cPurple.withOpacity(_glowAnim.value * 0.6),
                    width: 1.2),
                boxShadow: [
                  BoxShadow(
                      color: _cPurple.withOpacity(_glowAnim.value * 0.22),
                      blurRadius: 24,
                      spreadRadius: 2)
                ]),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _cPurple.withOpacity(0.85),
                      _cPink.withOpacity(0.4)
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: _cPurple.withOpacity(0.5), blurRadius: 12)
                    ]),
                child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Lunar AI 🌙',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(msg,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontSize: 12.5,
                            height: 1.4)),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }

  // ── POST CARD ─────────────────────────────────────────────
  // ── LIVE FIRESTORE POST CARD ───────────────────────────────
  Widget _postCard(
      CommunityPost post, CommunityProvider community, LunarAuthProvider auth) {
    final cat = _CCat.values.firstWhere((c) => c.id == post.category,
        orElse: () => _CCat.emotionalHealing);
    final avatarColor = _colorFromHex(post.avatarColorHex);
    final isBookmarked = community.isBookmarked(post.id);

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
                    color: cat.color.withOpacity(_glowAnim.value * 0.28),
                    width: 1)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              _livePostHeader(
                  post, cat, avatarColor, isBookmarked, community, auth),
              const SizedBox(height: 12),
              // Content
              _livePostContent(post, community),
              // Tags
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: post.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: cat.color.withOpacity(0.13),
                                  border: Border.all(
                                      color: cat.color.withOpacity(0.32),
                                      width: 1)),
                              child: Text(t,
                                  style: TextStyle(
                                      color: cat.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                            ))
                        .toList()),
              ],
              const SizedBox(height: 14),
              Container(height: 1, color: Colors.white.withOpacity(0.07)),
              const SizedBox(height: 12),
              _liveReactionBar(post, community),
              const SizedBox(height: 10),
              _livePostFooter(post),
              // Phase 5: AI support suggestion for vulnerable posts
              if (cat == _CCat.emotionalHealing ||
                  cat == _CCat.relationships ||
                  cat == _CCat.anxietySupport) ...[
                const SizedBox(height: 10),
                _aiSupportRow(post),
              ],
              // Phase 5: Shareable moment badge for popular posts
              if (post.reactions.values.fold(0, (a, b) => a + b) >= 20) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _cPurple.withOpacity(0.10),
                      border: Border.all(
                          color: _cPurple.withOpacity(0.25), width: 1),
                    ),
                    child: Text('Someone needed this today 🌙',
                        style: TextStyle(
                            color: _cPurple.withOpacity(0.8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
              ],
              // Healing circle comfort for vulnerable posts
              if (cat == _CCat.emotionalHealing ||
                  cat == _CCat.relationships ||
                  cat == _CCat.anxietySupport) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: cat.color.withOpacity(0.08),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('💜', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 6),
                    Text('You are not alone here',
                        style: TextStyle(
                            color: cat.color.withOpacity(0.75),
                            fontSize: 11,
                            fontStyle: FontStyle.italic)),
                  ]),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  // ── AI SUPPORT SUGGESTION ROW (Phase 5) ──────────────────
  Widget _aiSupportRow(CommunityPost post) {
    final suggestion = _aiSuggestions[post.id];
    final isLoading = _loadingAiFor.contains(post.id);

    if (suggestion != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _cPurple.withOpacity(0.12),
              _cPink.withOpacity(0.06),
            ],
          ),
          border:
              Border.all(color: _cPurple.withOpacity(0.28), width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('✨', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 5),
            Text('AI Supportive Reply',
                style: TextStyle(
                    color: _cPurple,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Text(suggestion,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 12.5,
                  height: 1.5,
                  fontStyle: FontStyle.italic)),
        ]),
      );
    }

    return GestureDetector(
      onTap: isLoading ? null : () => _generateAiSuggestion(post),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.04),
          border:
              Border.all(color: Colors.white.withOpacity(0.10), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (isLoading)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: _cPurple.withOpacity(0.7)),
            )
          else
            Text('✨', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            isLoading ? 'Generating support...' : 'Suggest a supportive reply',
            style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ]),
      ),
    );
  }

  Future<void> _generateAiSuggestion(CommunityPost post) async {
    if (_loadingAiFor.contains(post.id)) return;
    setState(() => _loadingAiFor.add(post.id));
    try {
      final community =
          context.read<CommunityProvider>();
      final response =
          await community.generateAISupportResponse(post.content);
      if (mounted) {
        setState(() {
          _aiSuggestions[post.id] = response ??
              'You are so brave for sharing this. Sending you gentle love and understanding. 💜';
          _loadingAiFor.remove(post.id);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiSuggestions[post.id] =
              'You are so brave for sharing this. Sending you gentle love and understanding. 💜';
          _loadingAiFor.remove(post.id);
        });
      }
    }
  }

  Widget _livePostHeader(CommunityPost post, _CCat cat, Color avatarColor,
      bool isBookmarked, CommunityProvider community, LunarAuthProvider auth) {
    // Show the Lunar avatar for the current user's own (non-anonymous) posts.
    final avatarProvider = context.read<AvatarProvider>();
    final myUid = auth.firebaseUser?.uid;
    final isOwnPost = !post.isAnonymous &&
        myUid != null &&
        avatarProvider.avatar != null &&
        (post.pseudonym.startsWith('You'));

    // Tap handler — navigate to profile (only for non-anonymous posts by others)
    final canViewProfile = !post.isAnonymous && !isOwnPost && post.uid.isNotEmpty;
    void onProfileTap() {
      if (!canViewProfile) return;
      HapticFeedback.lightImpact();
      Navigator.push<void>(
        context,
        CommunityProfileScreen.route(
          targetUid:      post.uid,
          pseudonym:      post.pseudonym,
          avatarEmoji:    post.avatarEmoji,
          avatarColorHex: post.avatarColorHex,
          isPremium:      post.isPremium,
          isVerified:     post.isVerified,
        ),
      );
    }

    // Quick connection status from provider (no-async, cached)
    final cp = context.read<ConnectionProvider>();
    final isConnected = canViewProfile && cp.isConnected(post.uid);
    final hasIncoming = canViewProfile && cp.incomingFrom(post.uid) != null;

    return Row(children: [
      // ── Avatar circle ────────────────────────────────────
      GestureDetector(
        onTap: canViewProfile ? onProfileTap : null,
        child: isOwnPost
            ? ClipOval(
                child: Container(
                  width: 44,
                  height: 44,
                  color: const Color(0xFF160330),
                  child: LunarAvatarWidget(
                    avatar: avatarProvider.avatar!,
                    size: 44,
                    animate: false,
                    showAura: false,
                  ),
                ),
              )
            : Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      avatarColor.withOpacity(0.85),
                      avatarColor.withOpacity(0.3)
                    ]),
                    border: Border.all(
                        color: avatarColor.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: avatarColor.withOpacity(0.28), blurRadius: 10)
                    ]),
                child: Center(
                    child: Text(post.avatarEmoji,
                        style: const TextStyle(fontSize: 22))),
              ),
      ),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: canViewProfile ? onProfileTap : null,
            child: Text(post.pseudonym,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
          ),
          // Connection indicator
          if (isConnected) ...[const SizedBox(width: 5), const _ConnectionDot()],
          if (hasIncoming && !isConnected) ...[const SizedBox(width: 5), const _RequestDot()],
          // Verified / Premium badges
          if (!post.isAnonymous && post.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified_rounded, color: Color(0xFF4FC3F7), size: 13),
          ],
          if (!post.isAnonymous && post.isPremium) ...[
            const SizedBox(width: 3),
            const Icon(Icons.diamond_rounded, color: _cPurple, size: 12),
          ],
          if (post.isAnonymous) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _cPurple.withOpacity(0.18),
                  border: Border.all(color: _cPurple.withOpacity(0.38))),
              child: Text('anon',
                  style: TextStyle(
                      color: _cPurple,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ]),
        const SizedBox(height: 3),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: cat.color.withOpacity(0.16),
                border: Border.all(color: cat.color.withOpacity(0.38))),
            child: Text('${cat.emoji} ${cat.label}',
                style: TextStyle(
                    color: cat.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ),
          // Phase 5: Post type badge
          if (post.postType != CommunityPostType.regular) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFFFD700).withOpacity(0.14),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.35))),
              child: Text(
                  '${post.postType.emoji} ${post.postType.label}',
                  style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(width: 8),
          Text(post.createdAt != null ? _timeAgo(post.createdAt!) : 'just now',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3), fontSize: 11)),
        ]),
      ])),
      GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          community.toggleBookmark(post.id);
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: isBookmarked ? _cPurple : Colors.white.withOpacity(0.28),
            size: 20,
          ),
        ),
      ),
      GestureDetector(
        onTap: () => _showLivePostOptions(post, community, auth),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.more_horiz_rounded,
              color: Colors.white.withOpacity(0.28), size: 20),
        ),
      ),
    ]);
  }

  Widget _livePostContent(CommunityPost post, CommunityProvider community) {
    if (post.isSensitive && post.isBlurred) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          community.revealSensitivePost(post.id);
        },
        child: Stack(children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Text(post.content,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 14.5,
                    height: 1.55)),
          ),
          Positioned.fill(
              child: Center(
                  child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withOpacity(0.55),
                border: Border.all(color: Colors.white.withOpacity(0.18))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.visibility_off_rounded,
                  color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text('Sensitive content — tap to read',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.78), fontSize: 12)),
            ]),
          ))),
        ]),
      );
    }
    return Text(post.content,
        style: TextStyle(
            color: Colors.white.withOpacity(0.82),
            fontSize: 14.5,
            height: 1.55));
  }

  Widget _liveReactionBar(CommunityPost post, CommunityProvider community) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: HealingReaction.values.map((rxn) {
          final count = (post.reactions[rxn.id] ?? 0) +
              (community.hasReacted(post.id, rxn.id) ? 1 : 0);
          final isMine = community.hasReacted(post.id, rxn.id);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                community.toggleReaction(postId: post.id, reaction: rxn.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isMine
                      ? LinearGradient(colors: [
                          rxn.color.withOpacity(0.62),
                          rxn.color.withOpacity(0.32),
                        ])
                      : null,
                  color: isMine ? null : Colors.white.withOpacity(0.06),
                  border: Border.all(
                      color: isMine
                          ? rxn.color.withOpacity(0.75)
                          : Colors.white.withOpacity(0.1),
                      width: 1),
                  boxShadow: isMine
                      ? [
                          BoxShadow(
                              color: rxn.color.withOpacity(0.35),
                              blurRadius: 10)
                        ]
                      : null,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(rxn.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(rxn.shortLabel,
                      style: TextStyle(
                          color: isMine
                              ? Colors.white
                              : Colors.white.withOpacity(0.52),
                          fontSize: 11,
                          fontWeight:
                              isMine ? FontWeight.w600 : FontWeight.w400)),
                  if (count > 0) ...[
                    const SizedBox(width: 5),
                    Text('$count',
                        style: TextStyle(
                            color: isMine
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _livePostFooter(CommunityPost post) => Row(children: [
        Icon(Icons.chat_bubble_outline_rounded,
            color: Colors.white.withOpacity(0.28), size: 15),
        const SizedBox(width: 5),
        Text('${post.commentsCount} replies',
            style:
                TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
        const Spacer(),
        GestureDetector(
          onTap: _showKindnessReminder,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _cPink.withOpacity(0.08),
                border: Border.all(color: _cPink.withOpacity(0.22))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🌸', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text('Reply with care',
                  style: TextStyle(
                      color: _cPink.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ]);

  void _showLivePostOptions(
      CommunityPost post, CommunityProvider community, LunarAuthProvider auth) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFF1A0535),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.09))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2))),
          const SizedBox(height: 20),
          _optionTile(Icons.flag_outlined, 'Report Post',
              'Not safe or hurtful content', const Color(0xFFE53935), () {
            community.reportPost(post.id);
            Navigator.pop(context);
            _showSafetyAck();
          }),
          const SizedBox(height: 10),
          _optionTile(Icons.visibility_off_outlined, 'Hide Post',
              'I don\'t want to see this', Colors.white54, () {
            community.hidePost(post.id);
            Navigator.pop(context);
          }),
          // Phase 5: Block user
          if (!post.isAnonymous && post.uid.isNotEmpty) ...[
            const SizedBox(height: 10),
            _optionTile(Icons.block_rounded, 'Block User',
                'Stop seeing posts from this person', Colors.orange.shade300,
                () {
              community.blockUser(post.uid);
              Navigator.pop(context);
            }),
          ],
          const SizedBox(height: 10),
          _optionTile(Icons.favorite_border_rounded, 'Send Healing',
              'Share warmth with this person', _cPink, () {
            Navigator.pop(context);
            _showKindnessReminder();
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── SEED POST CARD (shown when Firestore feed is empty) ────
  // ── SEED POST SUB-WIDGETS (_CPost) ────────────────────────
  Widget _postHeader(_CPost post) => Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                post.avatarColor.withOpacity(0.9),
                post.avatarColor.withOpacity(0.4)
              ])),
          child: Center(
              child:
                  Text(post.avatarEmoji, style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(post.pseudonym,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            if (post.isAnonymous) ...[
              const SizedBox(width: 6),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.08)),
                  child: Text('Anonymous',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 10))),
            ],
          ]),
          Text(_timeAgo(post.createdAt),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.38), fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: post.category.color.withOpacity(0.15),
              border: Border.all(color: post.category.color.withOpacity(0.35))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(post.category.emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(post.category.label,
                style: TextStyle(
                    color: post.category.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ]);

  Widget _postContent(_CPost post) {
    if (post.isBlurred) {
      return Stack(children: [
        ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Text(post.content,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5))),
        Positioned.fill(
            child: GestureDetector(
          onTap: () => setState(() => post.isBlurred = false),
          child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withOpacity(0.3)),
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🌸', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text('Sensitive Content — Tap to Reveal',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ]))),
        )),
      ]);
    }
    return Text(post.content,
        style: TextStyle(
            color: Colors.white.withOpacity(0.85), fontSize: 14, height: 1.5));
  }

  Widget _reactionBar(_CPost post) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _CRxn.values.map((rxn) {
          final count = post.reactions[rxn] ?? 0;
          final reacted = post.myReactions.contains(rxn);
          return GestureDetector(
            onTap: () => setState(() {
              if (reacted) {
                post.myReactions.remove(rxn);
                if (count > 0) post.reactions[rxn] = count - 1;
              } else {
                post.myReactions.add(rxn);
                post.reactions[rxn] = count + 1;
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: reacted
                      ? _cPurple.withOpacity(0.25)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                      color: reacted
                          ? _cPurple.withOpacity(0.6)
                          : Colors.white.withOpacity(0.1))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(rxn.emoji, style: const TextStyle(fontSize: 14)),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Text('$count',
                      style: TextStyle(
                          color: reacted
                              ? _cPurple
                              : Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ]),
            ),
          );
        }).toList(),
      );

  Widget _postFooter(_CPost post) => Row(children: [
        Icon(Icons.chat_bubble_outline_rounded,
            color: Colors.white.withOpacity(0.35), size: 15),
        const SizedBox(width: 5),
        Text('${post.commentsCount} comments',
            style:
                TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
        const Spacer(),
        Text('🤍 be kind',
            style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 11,
                fontStyle: FontStyle.italic)),
      ]);

  Widget _seedPostCard(_CPost post) {
    if (post.isReported) return const SizedBox.shrink();
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
                    color:
                        post.category.color.withOpacity(_glowAnim.value * 0.28),
                    width: 1)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _postHeader(post),
              const SizedBox(height: 12),
              _postContent(post),
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: post.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: post.category.color.withOpacity(0.13),
                                  border: Border.all(
                                      color:
                                          post.category.color.withOpacity(0.32),
                                      width: 1)),
                              child: Text(t,
                                  style: TextStyle(
                                      color: post.category.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                            ))
                        .toList()),
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

  Widget _optionTile(
          IconData ic, String title, String sub, Color c, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: c.withOpacity(0.08),
              border: Border.all(color: c.withOpacity(0.2))),
          child: Row(children: [
            Icon(ic, color: c, size: 20),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: c, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(sub,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.38), fontSize: 12)),
            ]),
          ]),
        ),
      );

  void _showSafetyAck() {
    showDialog(
        context: context,
        builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(colors: [
                          _cGreen.withOpacity(0.2),
                          _cDeep.withOpacity(0.9)
                        ]),
                        border: Border.all(color: _cGreen.withOpacity(0.4))),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('✅', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 14),
                      const Text('Thank You 💜',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(
                          'Your report helps keep this space safe and healing for everyone. Every report is reviewed with care.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.62),
                              fontSize: 13.5,
                              height: 1.5)),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(colors: [
                                  _cGreen.withOpacity(0.7),
                                  _cGreen.withOpacity(0.45)
                                ])),
                            child: const Text('Close',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600))),
                      ),
                    ]),
                  )),
            )));
  }

  void _showKindnessReminder() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_cPurple.withOpacity(0.28), _cBg]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: _cPurple.withOpacity(0.3))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2))),
          const SizedBox(height: 20),
          const Text('🌸', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          const Text('Kindness Is Medicine',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
              'Your presence in this space matters. Before you reply, take a breath and lead with compassion. Your words can be the gentlest thing someone experiences today 💜',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 14,
                  height: 1.55)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Text('"Be the healing you wish to feel in the world"',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _cPurple,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500)),
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
          onTap: () {
            final auth = Provider.of<LunarAuthProvider>(context, listen: false);
            if (auth.isGuest) {
              GuestGate.show(context, feature: 'share posts in the community');
              return;
            }
            HapticFeedback.lightImpact();
            setState(() => _showCompose = true);
          },
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_cPurple, _cPink]),
                boxShadow: [
                  BoxShadow(
                      color: _cPurple.withOpacity(_glowAnim.value * 0.8),
                      blurRadius: 24,
                      spreadRadius: 4),
                  BoxShadow(
                      color: _cPink.withOpacity(_glowAnim.value * 0.45),
                      blurRadius: 14,
                      spreadRadius: 2),
                ]),
            child:
                const Icon(Icons.edit_rounded, color: Colors.white, size: 26),
          ),
        ),
      );

  // ── COMPOSE OVERLAY ───────────────────────────────────────
  Widget _composeOverlay(
      BuildContext ctx, CommunityProvider community, LunarAuthProvider auth) {
    return GestureDetector(
      onTap: () {
        setState(() => _showCompose = false);
        FocusScope.of(ctx).unfocus();
      },
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: const Color(0xFF1A0535).withOpacity(0.95),
                      border: Border.all(
                          color: _cPurple.withOpacity(0.45), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: _cPurple.withOpacity(0.28),
                            blurRadius: 40,
                            spreadRadius: 4)
                      ]),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─ Header
                          Row(children: [
                            const Text('✍️', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            const Text('Share Your Heart',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            GestureDetector(
                                onTap: () {
                                  setState(() => _showCompose = false);
                                  FocusScope.of(ctx).unfocus();
                                },
                                child: Icon(Icons.close_rounded,
                                    color: Colors.white.withOpacity(0.38),
                                    size: 22)),
                          ]),
                          const SizedBox(height: 4),
                          Text('This space holds you with care 💜',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 12)),
                          const SizedBox(height: 20),

                          // ─ Identity
                          _label('Identity'),
                          const SizedBox(height: 10),
                          Row(children: [
                            _anonBtn(true, '🌙 Anonymous', 'Name never shown'),
                            const SizedBox(width: 10),
                            _anonBtn(
                                false, '🌸 Pseudonym', 'Choose avatar below'),
                          ]),
                          const SizedBox(height: 16),

                          // ─ Avatar picker
                          _label('Your Avatar'),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                                children: _kAvatars.asMap().entries.map((e) {
                              final sel = _composeAvatarIdx == e.key;
                              final (emoji, color) = e.value;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _composeAvatarIdx = e.key);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: sel
                                            ? RadialGradient(colors: [
                                                color.withOpacity(0.9),
                                                color.withOpacity(0.4)
                                              ])
                                            : null,
                                        color: sel
                                            ? null
                                            : Colors.white.withOpacity(0.06),
                                        border: Border.all(
                                            color: sel
                                                ? color
                                                : Colors.white
                                                    .withOpacity(0.14),
                                            width: sel ? 2 : 1),
                                        boxShadow: sel
                                            ? [
                                                BoxShadow(
                                                    color:
                                                        color.withOpacity(0.5),
                                                    blurRadius: 12)
                                              ]
                                            : null),
                                    child: Center(
                                        child: Text(emoji,
                                            style:
                                                const TextStyle(fontSize: 22))),
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
                            child: Row(
                                children: _CCat.values
                                    .where((c) => c != _CCat.all)
                                    .map((cat) {
                              final sel = _composeCat == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _composeCat = cat);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: sel
                                            ? LinearGradient(colors: [
                                                cat.color.withOpacity(0.65),
                                                cat.color.withOpacity(0.4)
                                              ])
                                            : null,
                                        color: sel
                                            ? null
                                            : Colors.white.withOpacity(0.06),
                                        border: Border.all(
                                            color: sel
                                                ? cat.color
                                                : Colors.white
                                                    .withOpacity(0.11))),
                                    child: Text('${cat.emoji} ${cat.label}',
                                        style: TextStyle(
                                            color: sel
                                                ? Colors.white
                                                : Colors.white
                                                    .withOpacity(0.52),
                                            fontSize: 12,
                                            fontWeight: sel
                                                ? FontWeight.w600
                                                : FontWeight.w400)),
                                  ),
                                ),
                              );
                            }).toList()),
                          ),
                          const SizedBox(height: 16),

                          // ─ Post Type (Phase 5)
                          _label('Share as'),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(children: [
                              ...([
                                CommunityPostType.regular,
                                CommunityPostType.checkIn,
                                CommunityPostType.healingStory,
                                CommunityPostType.anonymousShare,
                              ].map((type) {
                                final sel = _composePostType == type;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(
                                          () => _composePostType = type);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: sel
                                              ? _cPurple.withOpacity(0.42)
                                              : Colors.white.withOpacity(0.06),
                                          border: Border.all(
                                              color: sel
                                                  ? _cPurple.withOpacity(0.75)
                                                  : Colors.white
                                                      .withOpacity(0.11))),
                                      child: Text(
                                          '${type.emoji} ${type.label}',
                                          style: TextStyle(
                                              color: sel
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withOpacity(0.52),
                                              fontSize: 12,
                                              fontWeight: sel
                                                  ? FontWeight.w600
                                                  : FontWeight.w400)),
                                    ),
                                  ),
                                );
                              })),
                              // Voice Vent: future-ready disabled button
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Opacity(
                                  opacity: 0.4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        color:
                                            Colors.white.withOpacity(0.04),
                                        border: Border.all(
                                            color: Colors.white
                                                .withOpacity(0.11))),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('🎤',
                                              style:
                                                  TextStyle(fontSize: 12)),
                                          const SizedBox(width: 5),
                                          Text('Voice Vent',
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.52),
                                                  fontSize: 12)),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                color: _cGold
                                                    .withOpacity(0.25)),
                                            child: Text('Soon',
                                                style: TextStyle(
                                                    color: _cGold,
                                                    fontSize: 8.5,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ),
                                        ]),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 16),

                          // ─ Emotional tags
                          _label('How are you feeling? (up to 3)'),
                          const SizedBox(height: 10),
                          Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _kEmotionalTags.map((t) {
                                final sel = _composeTags.contains(t);
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (sel)
                                        _composeTags.remove(t);
                                      else if (_composeTags.length < 3)
                                        _composeTags.add(t);
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: sel
                                            ? LinearGradient(colors: [
                                                _cPink.withOpacity(0.55),
                                                _cPurple.withOpacity(0.4)
                                              ])
                                            : null,
                                        color: sel
                                            ? null
                                            : Colors.white.withOpacity(0.06),
                                        border: Border.all(
                                            color: sel
                                                ? _cPink
                                                : Colors.white
                                                    .withOpacity(0.11))),
                                    child: Text(t,
                                        style: TextStyle(
                                            color: sel
                                                ? Colors.white
                                                : Colors.white
                                                    .withOpacity(0.52),
                                            fontSize: 12,
                                            fontWeight: sel
                                                ? FontWeight.w500
                                                : FontWeight.w400)),
                                  ),
                                );
                              }).toList()),
                          const SizedBox(height: 16),

                          // ─ Emotional prompt starters
                          _label('Start with a prompt (optional)'),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                "I've been feeling anxious about…",
                                "I just went through a breakup and…",
                                "I need some support with…",
                                "Today was really hard because…",
                                "Something I'm proud of myself for…",
                                "I've been struggling with…",
                                "A small win I had today…",
                              ]
                                  .map((prompt) => GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          if (_composeCtrl.text.isEmpty) {
                                            _composeCtrl.text = prompt;
                                            _composeCtrl.selection =
                                                TextSelection.fromPosition(
                                                    TextPosition(
                                                        offset: prompt.length));
                                          }
                                        },
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 7),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            gradient: LinearGradient(colors: [
                                              _cPurple.withOpacity(0.20),
                                              _cPink.withOpacity(0.12),
                                            ]),
                                            border: Border.all(
                                                color:
                                                    _cPurple.withOpacity(0.35),
                                                width: 0.8),
                                          ),
                                          child: Text(
                                            prompt.length > 28
                                                ? '${prompt.substring(0, 26)}…'
                                                : prompt,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.62),
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ─ Text field
                          _label('Your words'),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withOpacity(0.05),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.11))),
                            child: TextField(
                              controller: _composeCtrl,
                              maxLines: 5,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.84),
                                  fontSize: 14.5,
                                  height: 1.5),
                              decoration: InputDecoration(
                                  hintText:
                                      'Speak from your heart. You are safe here, and you are heard 🌙',
                                  hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.24),
                                      fontSize: 14),
                                  contentPadding: const EdgeInsets.all(16),
                                  border: InputBorder.none),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Your story matters. Be gentle with yourself and others 💜',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.28),
                                  fontSize: 11)),
                          const SizedBox(height: 18),

                          // ─ Post button
                          GestureDetector(
                            onTap: _submitPost,
                            child: AnimatedBuilder(
                              animation: _glowAnim,
                              builder: (_, __) => Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _cPurple.withOpacity(_glowAnim.value),
                                          _cPink.withOpacity(_glowAnim.value)
                                        ]),
                                    boxShadow: [
                                      BoxShadow(
                                          color: _cPurple.withOpacity(
                                              _glowAnim.value * 0.5),
                                          blurRadius: 20,
                                          spreadRadius: 2)
                                    ]),
                                child: const Text('Share with the Community 💜',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
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
      style: TextStyle(
          color: Colors.white.withOpacity(0.52),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3));

  Widget _anonBtn(bool isAnon, String label, String sub) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _composeAnon = isAnon),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: (_composeAnon == isAnon)
                    ? LinearGradient(colors: [
                        _cPurple.withOpacity(0.55),
                        _cPink.withOpacity(0.35)
                      ])
                    : null,
                color: (_composeAnon == isAnon)
                    ? null
                    : Colors.white.withOpacity(0.05),
                border: Border.all(
                    color: (_composeAnon == isAnon)
                        ? _cPurple.withOpacity(0.7)
                        : Colors.white.withOpacity(0.11))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      color: (_composeAnon == isAnon)
                          ? Colors.white
                          : Colors.white.withOpacity(0.58),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(sub,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.32), fontSize: 11)),
            ]),
          ),
        ),
      );

  void _submitPost() {
    if (_composeCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    final community = Provider.of<CommunityProvider>(context, listen: false);
    final (emoji, color) = _kAvatars[_composeAvatarIdx];
    final colorHex = color.value.toRadixString(16).substring(2).toUpperCase();
    final pseudonym = _composeAnon ? 'Anonymous $emoji' : 'You $emoji';
    community.createPost(
      pseudonym: pseudonym,
      avatarEmoji: emoji,
      avatarColorHex: colorHex,
      isAnonymous: _composeAnon,
      category: _composeCat.id,
      content: _composeCtrl.text.trim(),
      tags: _composeTags.toList(),
      postType: _composePostType,
    );
    setState(() {
      _showCompose = false;
      _composeTags.clear();
      _composePostType = CommunityPostType.regular;
    });
    _composeCtrl.clear();
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
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4)),
          const SizedBox(height: 10),
          Text('This space is waiting for your voice 🌸',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.38), fontSize: 13)),
        ]),
      );

  // ── HELPERS ───────────────────────────────────────────────
  Color _colorFromHex(String hex) {
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return _cPurple;
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
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
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
            gradient: RadialGradient(
                center: Alignment(0.0, -0.4),
                radius: 1.35,
                colors: [Color(0xFF2D0B5C), Color(0xFF18063A), _cBg])),
        child: Stack(children: [
          Positioned(top: -80, left: -60, child: _blob(310, _cPurple, 0.22)),
          Positioned(top: 50, right: -65, child: _blob(260, _cPink, 0.16)),
          Positioned(top: 320, left: -20, child: _blob(240, _cTeal, 0.08)),
          Positioned(bottom: 90, right: -45, child: _blob(285, _cDeep, 0.2)),
          Positioned(bottom: 0, left: -50, child: _blob(220, _cGold, 0.09)),
          // Moon haze overlays
          Positioned(top: -30, right: -30, child: _blob(200, _cGold, 0.09)),
          Positioned(
              top: size.height * 0.40,
              left: size.width * 0.5 - 120,
              child: _blob(240, _cPurple, 0.06)),
          Positioned(bottom: 180, left: -40, child: _blob(180, _cPink, 0.07)),
          // Animated nebula depth layer
          RepaintBoundary(child: _CAnimatedNebula(size: size)),
        ]),
      );

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
//  PARTICLE PAINTER
// ═══════════════════════════════════════════════════════════

class _CStar {
  late double x, y, speed, size, opacity, angle;
  _CStar({required math.Random rng}) {
    _r(rng);
  }
  void _r(math.Random rng) {
    x = rng.nextDouble();
    y = rng.nextDouble();
    speed = 0.00010 + rng.nextDouble() * 0.00020;
    size = 0.6 + rng.nextDouble() * 2.1;
    opacity = 0.18 + rng.nextDouble() * 0.5;
    angle = rng.nextDouble() * math.pi * 2;
  }
}

class _CParticlePainter extends CustomPainter {
  final List<_CStar> stars;
  final double progress;
  _CParticlePainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in stars) {
      final x = (p.x + math.cos(p.angle) * p.speed * progress * 85) % 1.0;
      final y = (p.y - p.speed * progress * 210) % 1.0;
      canvas.drawCircle(
          Offset(x * size.width, y * size.height),
          p.size,
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

// ═══════════════════════════════════════════════════════════
//  ANIMATED NEBULA — Soft emotional atmosphere layer
// ═══════════════════════════════════════════════════════════

class _CAnimatedNebula extends StatefulWidget {
  final Size size;
  const _CAnimatedNebula({required this.size});

  @override
  State<_CAnimatedNebula> createState() => _CAnimatedNebulaState();
}

class _CAnimatedNebulaState extends State<_CAnimatedNebula>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => CustomPaint(
          size: widget.size,
          painter: _CNebulaP(t: _anim.value),
        ),
      );
}

class _CNebulaP extends CustomPainter {
  final double t;
  const _CNebulaP({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w * 0.25, h * 0.14),
      140,
      Paint()
        ..color = const Color(0xFF7B2FF7).withOpacity(0.055 + 0.03 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 55),
    );
    canvas.drawCircle(
      Offset(w * 0.80, h * 0.30),
      112,
      Paint()
        ..color = const Color(0xFFFF69B4).withOpacity(0.04 + 0.025 * (1 - t))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 65),
    );
    canvas.drawCircle(
      Offset(w * 0.15, h * 0.62),
      148,
      Paint()
        ..color = const Color(0xFF4A00E0).withOpacity(0.04 + 0.02 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
    canvas.drawCircle(
      Offset(w * 0.68, h * 0.76),
      105,
      Paint()
        ..color = const Color(0xFFAB5CF2).withOpacity(0.035 + 0.015 * (1 - t))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48),
    );
  }

  @override
  bool shouldRepaint(_CNebulaP old) => old.t != t;
}

// ═══════════════════════════════════════════════════════════
//  CONNECTION STATUS INDICATOR DOTS
// ═══════════════════════════════════════════════════════════

/// Small purple dot shown next to a pseudonym when you are connected.
class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Healing Connection',
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFAB5CF2),
        ),
      ),
    );
  }
}

/// Small gold dot shown when a pending request exists from this user.
class _RequestDot extends StatelessWidget {
  const _RequestDot();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Healing Request Pending',
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFD700),
        ),
      ),
    );
  }
}
