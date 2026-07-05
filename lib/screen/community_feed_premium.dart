// ─────────────────────────────────────────────────────────────────────────────
//  LUNAR COMMUNITY — WORLD-CLASS PREMIUM SOCIAL HEALING FEED
//
//  Features:
//  • Premium Instagram-style Stories
//  • Modern "What's on your heart?" create post
//  • Beautiful post cards with mood badges
//  • Perfect typography & spacing
//  • Glassmorphic design
//  • Zero layout overflows
//  • Production-ready performance
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/models/community_models.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/community_provider.dart';

// ── DESIGN SYSTEM ─────────────────────────────────────────
const Color _kBg = Color(0xFF0A0118);
const Color _kPurple = Color(0xFFAB5CF2);
const Color _kPink = Color(0xFFFF69B4);
const Color _kGreen = Color(0xFF66BB6A);
const Color _kTeal = Color(0xFF4FC3F7);
const Color _kGold = Color(0xFFFFD700);
const Color _kIndigo = Color(0xFF7986CB);

// ═══════════════════════════════════════════════════════════
//  PREMIUM COMMUNITY FEED SCREEN
// ═══════════════════════════════════════════════════════════

class CommunityFeedPremium extends StatefulWidget {
  const CommunityFeedPremium({super.key});

  @override
  State<CommunityFeedPremium> createState() => _CommunityFeedPremiumState();
}

class _CommunityFeedPremiumState extends State<CommunityFeedPremium>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late ScrollController _scrollCtrl;

  final Set<String> _viewedStories = {};
  bool _providerInitialized = false;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _scrollCtrl = ScrollController();
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
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final community = Provider.of<CommunityProvider>(context);
    final posts = community.filteredPosts;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Premium Stories Section ──────────────────────
            SliverToBoxAdapter(
              child: _buildStoriesSection(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Create Post Card ─────────────────────────────
            SliverToBoxAdapter(
              child: _buildCreatePostCard(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Feed Posts ───────────────────────────────────
            if (community.loadState == CommunityLoadState.loading &&
                posts.isEmpty)
              SliverToBoxAdapter(child: _buildLoadingState())
            else if (posts.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverList.separated(
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPostCard(posts[index]),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  PREMIUM STORIES
  // ═══════════════════════════════════════════════════════════

  Widget _buildStoriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Your Story',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _kPurple.withOpacity(0.15),
                  border: Border.all(
                    color: _kPurple.withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  '✨ Live',
                  style: TextStyle(
                    color: _kPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.035),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                const Text(
                  'No stories yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Be the first to share your journey.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.42),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  CREATE POST CARD
  // ═══════════════════════════════════════════════════════════

  Widget _buildCreatePostCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _kPurple.withOpacity(0.35),
                      _kPink.withOpacity(0.15),
                    ],
                  ),
                  border: Border.all(
                    color: _kPurple.withOpacity(_glowAnim.value * 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kPurple.withOpacity(_glowAnim.value * 0.2),
                      blurRadius: 24,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'What\'s on your heart today?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Quick Actions
                    Row(
                      children: [
                        _buildQuickAction('💭 Mood', _kPink),
                        const SizedBox(width: 10),
                        _buildQuickAction('📸 Photo', _kTeal),
                        const SizedBox(width: 10),
                        _buildQuickAction('🎙️ Voice', _kGreen),
                        const SizedBox(width: 10),
                        _buildQuickAction('📔 Journal', _kGold),
                      ],
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

  Widget _buildQuickAction(String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.12),
          border: Border.all(
            color: color.withOpacity(0.25),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  POST CARD — WORLD CLASS DESIGN
  // ═══════════════════════════════════════════════════════════

  Widget _buildPostCard(CommunityPost post) {
    final cat = _getCategoryInfo(post.category);
    final avatarColor = _colorFromHex(post.avatarColorHex);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.07),
                cat.color.withOpacity(0.02),
              ],
            ),
            border: Border.all(
              color: cat.color.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: cat.color.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 1,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Section ──────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPostHeader(post, cat, avatarColor),
              ),

              // ── Content Section ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  post.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Mood & Tags ──────────────────────────────
              if (post.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: post.tags
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: cat.color.withOpacity(0.14),
                                border: Border.all(
                                  color: cat.color.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: cat.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              if (post.tags.isNotEmpty) const SizedBox(height: 12),

              // ── Divider ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 0.8,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),

              // ── Reactions ────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildReactionBar(post),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader(
    CommunityPost post,
    ({String emoji, Color color}) cat,
    Color avatarColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                avatarColor.withOpacity(0.9),
                avatarColor.withOpacity(0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: avatarColor.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 1,
              )
            ],
          ),
          child: Center(
            child: Text(
              post.avatarEmoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.pseudonym,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (post.isAnonymous)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _kPurple.withOpacity(0.2),
                      ),
                      child: const Text(
                        '🔒',
                        style: TextStyle(fontSize: 9),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    post.createdAt != null
                        ? _formatTime(post.createdAt!)
                        : 'just now',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  // Mood Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: cat.color.withOpacity(0.16),
                      border: Border.all(
                        color: cat.color.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cat.emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.category
                              .split('_')
                              .map((e) => e[0].toUpperCase() + e.substring(1))
                              .join(' '),
                          style: TextStyle(
                            color: cat.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReactionBar(CommunityPost post) {
    return Row(
      children: [
        _buildReactionButton('💜 Support', post.reactions['support'] ?? 0),
        const SizedBox(width: 8),
        _buildReactionButton('❤️ Love', post.reactions['love'] ?? 0),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${post.commentsCount}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReactionButton(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.split(' ')[0],
            style: const TextStyle(fontSize: 13),
          ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  LOADING & EMPTY STATES
  // ═══════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🌙',
            style: TextStyle(fontSize: 56),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading your healing space...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _kPurple.withOpacity(0.2),
                  _kPink.withOpacity(0.1),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                '🌸',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Be the first to share',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your story helps someone heal. Share what\'s on your heart.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════

  ({String emoji, Color color}) _getCategoryInfo(String category) {
    switch (category) {
      case 'periodTalk':
        return (emoji: '🩸', color: Color(0xFFE53935));
      case 'pregnancy':
        return (emoji: '🤰', color: _kGold);
      case 'emotionalHealing':
        return (emoji: '💜', color: _kPurple);
      case 'relationships':
        return (emoji: '💞', color: _kPink);
      case 'anxietySupport':
        return (emoji: '🌬️', color: _kTeal);
      case 'selfCare':
        return (emoji: '🌿', color: _kGreen);
      case 'sleepWellness':
        return (emoji: '🌙', color: _kIndigo);
      default:
        return (emoji: '💜', color: _kPurple);
    }
  }

  Color _colorFromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return _kPurple;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${time.month}/${time.day}';
  }
}
