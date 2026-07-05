// ─────────────────────────────────────────────────────────────────────────────
//  LUNAR COMMUNITY — Premium Social Network (Tab-Based)
//  Feed | Stories | Connections | Explore
//  Inspired by Instagram, Facebook, WhatsApp
//  Designed with Lunar's purple branding + glassmorphism
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/data/local_cache.dart';
import '../core/providers/community_activity_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/connection_provider.dart';
import 'community_screen.dart';
import 'community_profile_screen.dart';
import 'connections_hub_screen.dart';

// ── Design tokens ─────────────────────────────────────────
const Color _cBg = Color(0xFF0A0118);
const Color _cPurple = Color(0xFFAB5CF2);
const Color _cPink = Color(0xFFFF69B4);
const Color _cDeep = Color(0xFF5C2DB8);
const Color _cGreen = Color(0xFF66BB6A);
const Color _cTeal = Color(0xFF4FC3F7);
const Color _cGold = Color(0xFFFFD700);

class _CommunityStory {
  final String id;
  final String uid;
  final String authorName;
  final String? authorPhotoUrl;
  final String mediaUrl;
  final String mediaType;
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> seenBy;

  const _CommunityStory({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.mediaUrl,
    required this.mediaType,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.seenBy,
  });

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  factory _CommunityStory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return _CommunityStory(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Lunar Member',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      mediaUrl: data['mediaUrl'] as String? ?? '',
      mediaType: data['mediaType'] as String? ?? 'image',
      caption: data['caption'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seenBy: List<String>.from(data['seenBy'] as List? ?? const []),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MAIN COMMUNITY TABS SCREEN
// ═══════════════════════════════════════════════════════════

class CommunityTabsScreen extends StatefulWidget {
  final int initialTabIndex;

  const CommunityTabsScreen({
    super.key,
    this.initialTabIndex = 0, // Default to Feed tab
  });

  @override
  State<CommunityTabsScreen> createState() => _CommunityTabsScreenState();
}

class _CommunityTabsScreenState extends State<CommunityTabsScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  final ImagePicker _storyPicker = ImagePicker();
  bool _creatingStory = false;
  String? _selectedCommunityTheme;

  static const _kCommunityThemeKey = 'lunar_community_theme_v1';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    )..addListener(() {
        if (!mounted) return;
        setState(() {});
      });

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Restore saved community theme
    final saved = LocalCache.getString(_kCommunityThemeKey);
    if (saved != null && saved.isNotEmpty) {
      _selectedCommunityTheme = saved;
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<LunarAuthProvider>();
    final communityTheme = _selectedCommunityTheme ?? auth.communityTheme;

    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Premium Top Bar (Add | Title | Profile) ──────
            _buildPremiumHeader(auth),

            // ── Tab Content ──────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  TabBarView(
                    controller: _tabCtrl,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      CommunityScreen(communityThemeOverride: communityTheme),
                      _buildStoriesTab(),
                      const ConnectionsHubScreen(),
                      ConnectionsHubScreen(
                        showMessagesOnly: true,
                        communityThemeOverride: communityTheme,
                      ),
                      _buildActivityTab(),
                    ],
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: _buildBottomNavigation(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final connectionBadge = context.watch<ConnectionProvider>().incomingCount;
    final activityBadge = context
        .watch<CommunityActivityProvider>()
        .items
        .where((item) => !item.read)
        .length;
    final premiumLocked = !context.watch<LunarAuthProvider>().isActivePremium;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: _cBg.withOpacity(0.78),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: _cPurple.withOpacity(0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildBottomNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Feed',
                ),
              ),
              Expanded(
                child: _buildBottomNavItem(
                  index: 1,
                  icon: Icons.menu_book_rounded,
                  label: 'Stories',
                ),
              ),
              Expanded(
                child: _buildBottomNavItem(
                  index: 2,
                  icon: Icons.handshake_rounded,
                  label: 'Connections',
                  badgeCount: connectionBadge,
                ),
              ),
              Expanded(
                child: _buildBottomNavItem(
                  index: 3,
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chats',
                  premiumLocked: premiumLocked,
                ),
              ),
              Expanded(
                child: _buildBottomNavItem(
                  index: 4,
                  icon: Icons.notifications_rounded,
                  label: 'Activity',
                  badgeCount: activityBadge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
    bool premiumLocked = false,
  }) {
    final isActive = _tabCtrl.index == index;
    return GestureDetector(
      onTap: () {
        _tabCtrl.animateTo(index);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isActive ? _cPurple.withOpacity(0.22) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 220),
              scale: isActive ? 1.08 : 1,
              curve: Curves.easeOutCubic,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.45),
                    size: 20,
                  ),
                  if (badgeCount > 0 || premiumLocked)
                    Positioned(
                      right: -8,
                      top: -7,
                      child: Container(
                        constraints:
                            const BoxConstraints(minWidth: 14, minHeight: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: badgeCount > 0
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius:
                              badgeCount > 0 ? BorderRadius.circular(99) : null,
                          color: premiumLocked ? _cGold : _cPink,
                        ),
                        child: Center(
                          child: Text(
                            premiumLocked
                                ? '★'
                                : badgeCount > 9
                                    ? '9+'
                                    : '$badgeCount',
                            style: TextStyle(
                              color: premiumLocked ? _cBg : Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.45),
                fontSize: 9.6,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isActive ? 18 : 4,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: isActive ? _cPurple : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(LunarAuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40, height: 40),

          // ── Center: Title ───────────────────────────────────
          const Expanded(
            child: Text(
              '🌙 Lunar Community',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),

          // ── Right: Profile Avatar ───────────────────────────
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final uid = auth.firebaseUser?.uid;
              if (uid == null) return;
              Navigator.push(
                context,
                CommunityProfileScreen.route(
                  targetUid: uid,
                  pseudonym: auth.displayName ?? 'Lunar Member',
                  avatarEmoji: '🌙',
                  avatarColorHex: 'AB5CF2',
                  isPremium: auth.isActivePremium,
                  isVerified: auth.isEmailVerified,
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_cPurple.withOpacity(0.6), _cPink.withOpacity(0.4)],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: auth.photoUrl != null && auth.photoUrl!.isNotEmpty
                  ? Image.network(auth.photoUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.person_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showStoryCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _cBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create Story',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _buildMenuOption('📷 Image Story', () {
                  Navigator.pop(context);
                  _createStory(ImageSource.gallery, 'image');
                }),
                const SizedBox(height: 12),
                _buildMenuOption('🎥 Video Story', () {
                  Navigator.pop(context);
                  _createStory(ImageSource.gallery, 'video');
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createStory(ImageSource source, String mediaType) async {
    if (_creatingStory) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picked = mediaType == 'video'
        ? await _storyPicker.pickVideo(source: source)
        : await _storyPicker.pickImage(
            source: source,
            imageQuality: 88,
            maxWidth: 1600,
          );
    if (picked == null) return;

    final caption = await _askStoryCaption();
    if (!mounted) return;

    setState(() => _creatingStory = true);
    try {
      final now = DateTime.now();
      final ext = picked.name.split('.').last;
      final ref = FirebaseStorage.instance.ref(
          'community_stories/${user.uid}/${now.millisecondsSinceEpoch}.$ext');
      await ref.putFile(File(picked.path));
      final mediaUrl = await ref.getDownloadURL();
      final auth = context.read<LunarAuthProvider>();

      await FirebaseFirestore.instance.collection('community_stories').add({
        'uid': user.uid,
        'authorName': auth.displayName,
        'authorPhotoUrl': auth.photoUrl,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'caption': caption ?? '',
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
        'seenBy': <String>[],
        'archived': false,
      });

      if (mounted) _tabCtrl.animateTo(1);
    } finally {
      if (mounted) setState(() => _creatingStory = false);
    }
  }

  Future<String?> _askStoryCaption() async {
    final ctrl = TextEditingController();
    final caption = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: _cBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Story Caption',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                maxLength: 120,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a gentle caption...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                  counterStyle:
                      TextStyle(color: Colors.white.withOpacity(0.35)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cPurple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Share Story'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    ctrl.dispose();
    return caption;
  }

  Widget _buildMenuOption(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return Consumer<CommunityActivityProvider>(
      builder: (_, activity, __) {
        if (activity.loading && activity.items.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: _cPurple, strokeWidth: 2),
          );
        }
        if (activity.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _cPurple.withOpacity(0.22),
                        _cPink.withOpacity(0.12),
                      ],
                    ),
                    border: Border.all(color: _cPurple.withOpacity(0.24)),
                  ),
                  child: const Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                const Text('Quiet right now',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Likes, comments, story views, and requests will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.42), fontSize: 13),
                ),
              ]),
            ),
          );
        }
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 112),
          itemCount: activity.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final item = activity.items[index];
            return GestureDetector(
              onTap: () => activity.markRead(item.id),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: item.read
                      ? Colors.white.withOpacity(0.035)
                      : _cPurple.withOpacity(0.08),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(children: [
                  Text(item.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                  ),
                  Text(_shortTime(item.createdAt),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35), fontSize: 11)),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  String _shortTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Widget _buildStoriesTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final now = Timestamp.fromDate(DateTime.now());
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('community_stories')
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final stories = (snapshot.data?.docs ?? [])
            .map(_CommunityStory.fromDoc)
            .where((story) => !story.isExpired)
            .toList();
        final myStories = stories.where((story) => story.uid == uid).toList();
        final friendStories =
            stories.where((story) => story.uid != uid).toList();
        final seenStories = friendStories
            .where((story) => uid != null && story.seenBy.contains(uid))
            .toList();
        final unseenStories = friendStories
            .where((story) => uid == null || !story.seenBy.contains(uid))
            .toList();

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 112),
          children: [
            _storySectionTitle('Your Story'),
            const SizedBox(height: 10),
            SizedBox(
              height: 106,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: myStories.isEmpty
                    ? [_yourEmptyStoryTile()]
                    : myStories
                        .map((story) => _storyTile(story, isMine: true))
                        .toList(),
              ),
            ),
            const SizedBox(height: 18),
            _storySectionTitle('Friends\' Stories'),
            const SizedBox(height: 10),
            SizedBox(
              height: 106,
              child: unseenStories.isEmpty
                  ? _quietStoriesEmpty('No new stories right now')
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: unseenStories.map(_storyTile).toList(),
                    ),
            ),
            const SizedBox(height: 18),
            _storySectionTitle('Seen Stories'),
            const SizedBox(height: 10),
            SizedBox(
              height: 106,
              child: seenStories.isEmpty
                  ? _quietStoriesEmpty('Seen stories will appear here')
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: seenStories
                          .map((story) => _storyTile(story, seen: true))
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _storySectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      );

  Widget _yourEmptyStoryTile() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showStoryCreateMenu(context);
      },
      child: SizedBox(
        width: 82,
        child: Column(children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: _cPurple.withOpacity(0.42), width: 1.4),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 9),
          const Text('Your Story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _storyTile(_CommunityStory story,
      {bool isMine = false, bool seen = false}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _openStoryViewer(story);
      },
      onLongPress: isMine ? () => _deleteStory(story) : null,
      child: Container(
        width: 82,
        margin: const EdgeInsets.only(right: 12),
        child: Column(children: [
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, child) => Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: seen
                      ? [
                          Colors.white.withOpacity(0.28),
                          Colors.white.withOpacity(0.1),
                        ]
                      : [_cPurple, _cPink.withOpacity(_glowAnim.value)],
                ),
              ),
              child: child,
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  story.mediaType == 'video'
                      ? Container(
                          color: _cDeep.withOpacity(0.8),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 28),
                        )
                      : Image.network(story.mediaUrl, fit: BoxFit.cover),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('${story.seenBy.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(isMine ? 'Your Story' : story.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.84),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _quietStoriesEmpty(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style:
                TextStyle(color: Colors.white.withOpacity(0.42), fontSize: 13)),
      );

  Future<void> _openStoryViewer(_CommunityStory story) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && story.uid != uid && !story.seenBy.contains(uid)) {
      FirebaseFirestore.instance
          .collection('community_stories')
          .doc(story.id)
          .update({
        'seenBy': FieldValue.arrayUnion([uid])
      });
    }

    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: _cBg,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AspectRatio(
                aspectRatio: 9 / 14,
                child: story.mediaType == 'video'
                    ? Container(
                        color: _cDeep,
                        child: const Center(
                          child: Icon(Icons.play_circle_fill_rounded,
                              color: Colors.white, size: 58),
                        ),
                      )
                    : Image.network(story.mediaUrl, fit: BoxFit.cover),
              ),
              if (story.caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(story.caption,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteStory(_CommunityStory story) async {
    await FirebaseFirestore.instance
        .collection('community_stories')
        .doc(story.id)
        .update({'expiresAt': Timestamp.fromDate(DateTime.now())});
  }

  Widget _buildExploreTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore Healing Circles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Join conversations that matter to you',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              children: [
                _buildExploreCircle(
                    '🩸', 'Period\nSupport', const Color(0xFFE53935)),
                _buildExploreCircle('🤰', 'Pregnancy\nCircle', _cGold),
                _buildExploreCircle('💜', 'Emotional\nHealing', _cPurple),
                _buildExploreCircle('🌬️', 'Anxiety\nRelief', _cTeal),
                _buildExploreCircle(
                    '🌙', 'Sleep\nWellness', const Color(0xFF7986CB)),
                _buildExploreCircle('🌿', 'Self\nLove', _cGreen),
                _buildExploreCircle('💞', 'Relationships', _cPink),
                _buildExploreCircle('✨', 'Mindfulness', _cGold),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Featured Members',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect with members sharing similar topics',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.04),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Feature coming soon! 🌟',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover and connect with members in your healing circles',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreCircle(String emoji, String label, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: color.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Text(
              'Entering $label...',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.25),
                  color.withOpacity(0.08),
                ],
              ),
              border: Border.all(
                color: color.withOpacity(0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
