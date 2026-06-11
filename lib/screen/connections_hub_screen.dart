// ─────────────────────────────────────────────────────────────────────────────
//  CONNECTIONS HUB SCREEN
//  Full-featured healing connections experience.
//  Sections: Incoming Requests · Sent Requests · My Connections · Discover
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/connection_provider.dart';
import '../models/connection_model.dart';
import 'community_profile_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const Color _kBg     = Color(0xFF0A0118);
const Color _kSurf   = Color(0xFF160330);
const Color _kPurple = Color(0xFFAB5CF2);
const Color _kPink   = Color(0xFFFF69B4);
const Color _kGold   = Color(0xFFFFD700);
const Color _kGreen  = Color(0xFF66BB6A);
const Color _kRed    = Color(0xFFEF5350);
const Color _kTeal   = Color(0xFF4FC3F7);

// ── Suggested member model (derived from Firestore community_posts) ────────────
class _SuggestedMember {
  final String uid;
  final String pseudonym;
  final String avatarEmoji;
  final String avatarColorHex;
  final bool isPremium;
  final bool isVerified;
  final List<String> allTopics;      // every category they've posted in
  final List<String> sharedTopics;   // intersection with my own posted topics
  final int postCount;
  final String lastPostPreview;      // truncated first line of most recent post
  final DateTime? lastPostDate;
  final DateTime? memberSince;       // earliest post date — proxy for join date

  bool get isActiveThisWeek =>
      lastPostDate != null &&
      DateTime.now().difference(lastPostDate!).inDays <= 7;

  String get memberSinceLabel {
    if (memberSince == null) return '';
    final months = DateTime.now().difference(memberSince!).inDays ~/ 30;
    if (months < 1) return 'New member';
    if (months == 1) return 'Member 1 month';
    if (months < 12) return 'Member $months months';
    final years = months ~/ 12;
    return 'Member ${years}y';
  }

  const _SuggestedMember({
    required this.uid,
    required this.pseudonym,
    required this.avatarEmoji,
    required this.avatarColorHex,
    required this.isPremium,
    required this.isVerified,
    required this.allTopics,
    required this.sharedTopics,
    required this.postCount,
    required this.lastPostPreview,
    this.lastPostDate,
    this.memberSince,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class ConnectionsHubScreen extends StatefulWidget {
  const ConnectionsHubScreen({super.key});

  @override
  State<ConnectionsHubScreen> createState() => _ConnectionsHubScreenState();
}

class _ConnectionsHubScreenState extends State<ConnectionsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<_SuggestedMember> _suggestions = [];
  bool _suggestionsLoading = true;
  Set<String> _myTopics = {};

  // Discover filters
  bool _filterVerified   = false;
  bool _filterPremium    = false;
  bool _filterActiveWeek = false;
  bool _filterMyTopics   = false;

  // Per-card loading state for send button
  final Set<String> _sendingTo = {};

  // Sent requests (outgoing) — fetched once and cached
  List<ConnectionRequest> _sentRequests = [];
  bool _sentLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSuggestions();
      _loadSentRequests();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Data Loading ────────────────────────────────────────────────────────────

  Future<void> _loadSuggestions() async {
    final auth = context.read<LunarAuthProvider>();
    final myUid = auth.firebaseUser?.uid;
    if (myUid == null) return;

    try {
      // ── Step 1: Load my own topics ─────────────────────────────────
      final myPostsSnap = await FirebaseFirestore.instance
          .collection('community_posts')
          .where('uid', isEqualTo: myUid)
          .where('isAnonymous', isEqualTo: false)
          .limit(20)
          .get();
      final myTopics = <String>{};
      for (final d in myPostsSnap.docs) {
        final cat = d.data()['category'] as String? ?? '';
        if (cat.isNotEmpty) myTopics.add(cat);
      }

      // ── Step 2: Fetch recent non-anonymous posts ────────────────────
      final snap = await FirebaseFirestore.instance
          .collection('community_posts')
          .where('isAnonymous', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(80)
          .get();

      // ── Step 3: Aggregate per uid ──────────────────────────────────
      // Map uid → list of post data maps (most recent first)
      final byUid = <String, List<Map<String, dynamic>>>{};
      for (final doc in snap.docs) {
        final d = doc.data();
        final uid = d['uid'] as String? ?? '';
        if (uid.isEmpty || uid == myUid) continue;
        byUid.putIfAbsent(uid, () => []).add(d);
      }

      // ── Step 4: Build enriched member objects ──────────────────────
      final cp = context.read<ConnectionProvider>();
      final suggestions = <_SuggestedMember>[];

      for (final entry in byUid.entries) {
        final uid = entry.key;
        if (cp.isConnected(uid)) continue;

        final posts = entry.value; // already desc-sorted by Firestore
        final latest = posts.first;

        // Collect all topics this member has posted in
        final allTopics = posts
            .map((p) => p['category'] as String? ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();

        // Shared topics = intersection with my topics
        final sharedTopics =
            allTopics.where((t) => myTopics.contains(t)).toList();

        // Last post preview — strip newlines, cap at 90 chars
        final rawContent = latest['content'] as String? ?? '';
        final preview = rawContent.replaceAll('\n', ' ').trim();
        final lastPostPreview = preview.length > 90
            ? '${preview.substring(0, 87)}…'
            : preview;

        // Latest post date
        final ts = latest['createdAt'] as Timestamp?;
        final lastPostDate = ts?.toDate();

        // Member since — use earliest post as proxy
        final oldest = posts.last;
        final oldestTs = oldest['createdAt'] as Timestamp?;
        final memberSince = oldestTs?.toDate();

        suggestions.add(_SuggestedMember(
          uid:             uid,
          pseudonym:       latest['pseudonym'] as String? ?? 'Lunar Member',
          avatarEmoji:     latest['avatarEmoji'] as String? ?? '🌙',
          avatarColorHex:  latest['avatarColorHex'] as String? ?? 'AB5CF2',
          isPremium:       latest['isPremium'] as bool? ?? false,
          isVerified:      latest['isVerified'] as bool? ?? false,
          allTopics:       allTopics,
          sharedTopics:    sharedTopics,
          postCount:       posts.length,
          lastPostPreview: lastPostPreview,
          lastPostDate:    lastPostDate,
          memberSince:     memberSince,
        ));

        if (suggestions.length >= 20) break;
      }

      // ── Step 5: Sort — verified+premium first, then by shared topics ─
      suggestions.sort((a, b) {
        // Trust score: verified=2, premium=1 each
        final aScore = (a.isVerified ? 2 : 0) + (a.isPremium ? 1 : 0);
        final bScore = (b.isVerified ? 2 : 0) + (b.isPremium ? 1 : 0);
        if (bScore != aScore) return bScore.compareTo(aScore);
        // Then by shared topics count
        return b.sharedTopics.length.compareTo(a.sharedTopics.length);
      });

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _myTopics = myTopics;
          _suggestionsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ConnectionsHub] suggestions error: $e');
      if (mounted) setState(() => _suggestionsLoading = false);
    }
  }

  Future<void> _loadSentRequests() async {
    final auth = context.read<LunarAuthProvider>();
    final myUid = auth.firebaseUser?.uid;
    if (myUid == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('connection_requests')
          .where('fromUid', isEqualTo: myUid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final list = snap.docs
          .map((d) => ConnectionRequest.fromMap(d.id, d.data()))
          .where((r) => !r.isExpired)
          .toList();

      if (mounted) setState(() {
        _sentRequests = list;
        _sentLoading = false;
      });
    } catch (e) {
      debugPrint('[ConnectionsHub] sent requests error: $e');
      if (mounted) setState(() => _sentLoading = false);
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _accept(ConnectionRequest req) async {
    HapticFeedback.lightImpact();
    final err = await context.read<ConnectionProvider>().acceptRequest(req.id);
    if (!mounted) return;
    _snack(err == null ? 'Connected 💜 Healing together.' : err, isError: err != null);
  }

  Future<void> _reject(ConnectionRequest req) async {
    HapticFeedback.lightImpact();
    final err = await context.read<ConnectionProvider>().rejectRequest(req.id);
    if (!mounted) return;
    if (err == null) {
      _snack('Request declined.');
    } else {
      _snack(err, isError: true);
    }
  }

  Future<void> _cancelSent(ConnectionRequest req) async {
    try {
      await FirebaseFirestore.instance
          .collection('connection_requests')
          .doc(req.id)
          .update({'status': 'rejected', 'respondedAt': Timestamp.now()});
      if (mounted) {
        setState(() => _sentRequests.removeWhere((r) => r.id == req.id));
        _snack('Request cancelled.');
      }
    } catch (e) {
      _snack('Failed to cancel request.', isError: true);
    }
  }

  Future<void> _disconnect(LunarConnection conn) async {
    final auth = context.read<LunarAuthProvider>();
    final myUid = auth.firebaseUser?.uid ?? '';
    final confirm = await _showConfirm(
      'Disconnect?',
      'You will no longer be healing connections with ${conn.otherUid(myUid)}.',
      'Disconnect',
    );
    if (confirm != true || !mounted) return;
    final err = await context.read<ConnectionProvider>().disconnect(conn.otherUid(myUid));
    if (mounted && err != null) _snack(err, isError: true);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _kRed : _kPurple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<bool?> _showConfirm(String title, String msg, String confirm) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.65))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.45)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirm, style: const TextStyle(color: _kRed, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ConnectionProvider>();

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        _buildHeader(cp.incomingCount),
        _buildTabBar(cp.incomingCount),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildIncomingTab(cp),
              _buildSentTab(),
              _buildConnectionsTab(cp),
              _buildDiscoverTab(cp),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(int incomingCount) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _kPurple.withOpacity(0.18),
            _kBg,
          ],
        ),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Healing Connections',
                  style: TextStyle(color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              if (incomingCount > 0) ...[
                const SizedBox(width: 10),
                _countBadge(incomingCount, _kPurple),
              ],
            ]),
            const SizedBox(height: 3),
            Text('Connect with premium members on your journey',
                style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
          ]),
        ),
        // Refresh button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _suggestionsLoading = true;
              _sentLoading = true;
            });
            _loadSuggestions();
            _loadSentRequests();
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Icon(Icons.refresh_rounded,
                color: Colors.white.withOpacity(0.5), size: 18),
          ),
        ),
      ]),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar(int incomingCount) {
    return Container(
      color: _kBg,
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: _kPurple,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.white.withOpacity(0.07),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        labelColor: _kPurple,
        unselectedLabelColor: Colors.white.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          _tab('Requests', incomingCount),
          _tab('Sent', 0),
          _tab('Connected', 0),
          _tab('Discover', 0),
        ],
      ),
    );
  }

  Tab _tab(String label, int badge) {
    return Tab(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        if (badge > 0) ...[
          const SizedBox(width: 6),
          _countBadge(badge, _kPink),
        ],
      ]),
    );
  }

  // ── INCOMING REQUESTS TAB ───────────────────────────────────────────────────

  Widget _buildIncomingTab(ConnectionProvider cp) {
    final incoming = cp.incomingRequests;

    if (cp.loading && incoming.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kPurple, strokeWidth: 2));
    }

    if (incoming.isEmpty) {
      return _emptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No Pending Requests',
        subtitle: 'When someone sends you a healing connection\nrequest, it will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: incoming.length,
      itemBuilder: (_, i) => _incomingCard(incoming[i]),
    );
  }

  Widget _incomingCard(ConnectionRequest req) {
    final avatarColor = _hexToColor(req.fromAvatarColorHex);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: _kPurple.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Member row
              Row(children: [
                GestureDetector(
                  onTap: () => _openProfile(
                    uid: req.fromUid,
                    pseudonym: req.fromPseudonym,
                    avatarEmoji: req.fromAvatarEmoji,
                    avatarColorHex: req.fromAvatarColorHex,
                  ),
                  child: _avatarCircle(req.fromAvatarEmoji, avatarColor, 48),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GestureDetector(
                      onTap: () => _openProfile(
                        uid: req.fromUid,
                        pseudonym: req.fromPseudonym,
                        avatarEmoji: req.fromAvatarEmoji,
                        avatarColorHex: req.fromAvatarColorHex,
                      ),
                      child: Text(req.fromPseudonym,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.favorite_rounded, color: _kPurple.withOpacity(0.7), size: 12),
                      const SizedBox(width: 4),
                      Text('Sent you a Healing Request',
                          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                    ]),
                  ]),
                ),
                Text(_timeAgo(req.createdAt),
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
              ]),
              const SizedBox(height: 14),
              // Actions
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _accept(req),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                            colors: [_kPurple, _kPink]),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Accept',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _reject(req),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.07),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Center(
                        child: Text('Decline',
                            style: TextStyle(color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w500, fontSize: 13)),
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ── SENT REQUESTS TAB ───────────────────────────────────────────────────────

  Widget _buildSentTab() {
    if (_sentLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPurple, strokeWidth: 2));
    }

    if (_sentRequests.isEmpty) {
      return _emptyState(
        icon: Icons.send_rounded,
        title: 'No Sent Requests',
        subtitle: 'Healing requests you\'ve sent will appear here\nuntil they\'re accepted or declined.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _sentRequests.length,
      itemBuilder: (_, i) => _sentCard(_sentRequests[i]),
    );
  }

  Widget _sentCard(ConnectionRequest req) {
    final avatarColor = _hexToColor(req.fromAvatarColorHex);
    final expiresIn = req.expiresAt.difference(DateTime.now()).inDays;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        _avatarCircle(req.fromAvatarEmoji, avatarColor, 44),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(req.toPseudonym,
              style: const TextStyle(color: Colors.white,
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.schedule_rounded, color: _kGold, size: 12),
            const SizedBox(width: 4),
            Text('Awaiting response · expires in ${expiresIn}d',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ]),
        ])),
        GestureDetector(
          onTap: () => _cancelSent(req),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text('Cancel',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ),
      ]),
    );
  }

  // ── MY CONNECTIONS TAB ──────────────────────────────────────────────────────

  Widget _buildConnectionsTab(ConnectionProvider cp) {
    final conns = cp.connections;
    final auth = context.read<LunarAuthProvider>();
    final myUid = auth.firebaseUser?.uid ?? '';

    if (cp.loading && conns.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kPurple, strokeWidth: 2));
    }

    if (conns.isEmpty) {
      return _emptyState(
        icon: Icons.people_outline_rounded,
        title: 'No Healing Connections Yet',
        subtitle: 'Accept a request or discover members\nwho share your healing journey.',
        actionLabel: 'Discover Members',
        onAction: () => _tabCtrl.animateTo(3),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: conns.length,
      itemBuilder: (_, i) => _connectionCard(conns[i], myUid),
    );
  }

  Widget _connectionCard(LunarConnection conn, String myUid) {
    final otherUid = conn.otherUid(myUid);
    final connectedDays = DateTime.now().difference(conn.connectedAt).inDays;
    final daysLabel = connectedDays == 0
        ? 'Connected today'
        : connectedDays == 1
            ? 'Connected 1 day ago'
            : 'Connected ${connectedDays}d ago';

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('community_posts')
          .where('uid', isEqualTo: otherUid)
          .where('isAnonymous', isEqualTo: false)
          .limit(1)
          .get()
          .then((s) => s.docs.isNotEmpty
              ? s.docs.first
              : throw Exception('no post')),
      builder: (ctx, snap) {
        // Fallback values if no post found
        String pseudonym = 'Lunar Member';
        String emoji = '🌙';
        String colorHex = 'AB5CF2';
        bool isPremium = false;
        bool isVerified = false;

        if (snap.hasData) {
          final d = snap.data!.data()!;
          pseudonym = d['pseudonym'] as String? ?? pseudonym;
          emoji     = d['avatarEmoji'] as String? ?? emoji;
          colorHex  = d['avatarColorHex'] as String? ?? colorHex;
          isPremium = d['isPremium'] as bool? ?? false;
          isVerified = d['isVerified'] as bool? ?? false;
        }

        final avatarColor = _hexToColor(colorHex);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _openProfile(
              uid: otherUid,
              pseudonym: pseudonym,
              avatarEmoji: emoji,
              avatarColorHex: colorHex,
              isPremium: isPremium,
              isVerified: isVerified,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: _kPurple.withOpacity(0.15)),
              ),
              child: Row(children: [
                Stack(children: [
                  _avatarCircle(emoji, avatarColor, 52),
                  // Connected indicator dot
                  Positioned(bottom: 2, right: 2,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kGreen,
                        border: Border.all(color: _kBg, width: 2),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(pseudonym,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: _kTeal, size: 14),
                    ],
                    if (isPremium) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.diamond_rounded, color: _kPurple, size: 13),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.favorite_rounded, color: _kPurple.withOpacity(0.6), size: 11),
                    const SizedBox(width: 4),
                    Text(daysLabel,
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  ]),
                ])),
                GestureDetector(
                  onTap: () => _disconnect(conn),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.more_vert_rounded,
                        color: Colors.white.withOpacity(0.25), size: 18),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  // ── Discover filter getter ──────────────────────────────────────────────────

  List<_SuggestedMember> get _filteredSuggestions {
    var list = _suggestions;
    if (_filterVerified)   list = list.where((m) => m.isVerified).toList();
    if (_filterPremium)    list = list.where((m) => m.isPremium).toList();
    if (_filterActiveWeek) list = list.where((m) => m.isActiveThisWeek).toList();
    if (_filterMyTopics && _myTopics.isNotEmpty) {
      list = list.where((m) => m.sharedTopics.isNotEmpty).toList();
    }
    return list;
  }

  // ── DISCOVER TAB ────────────────────────────────────────────────────────────

  Widget _buildDiscoverTab(ConnectionProvider cp) {
    final auth = context.read<LunarAuthProvider>();
    final isEligible = _checkEligible(auth);
    final filtered = _filteredSuggestions;
    final anyFilterActive =
        _filterVerified || _filterPremium || _filterActiveWeek || _filterMyTopics;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: const SizedBox(height: 12)),

        // Eligibility Banner
        if (!isEligible)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _eligibilityBanner(auth),
            ),
          ),

        // ── Filter chips ──────────────────────────────────────────────
        SliverToBoxAdapter(child: _discoverFilterBar()),

        SliverToBoxAdapter(child: const SizedBox(height: 12)),

        // ── Header row ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPurple.withOpacity(0.18),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: _kPurple, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                anyFilterActive
                    ? '${filtered.length} member${filtered.length == 1 ? '' : 's'} match your filters'
                    : 'Suggested for You — ${filtered.length} members',
                style: const TextStyle(color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ),

        // ── Loading ───────────────────────────────────────────────────
        if (_suggestionsLoading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Column(children: [
                const CircularProgressIndicator(color: _kPurple, strokeWidth: 2),
                const SizedBox(height: 12),
                Text('Finding members on similar journeys…',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 13)),
              ])),
            ),
          )

        // ── No results ────────────────────────────────────────────────
        else if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: _emptyState(
              icon: anyFilterActive
                  ? Icons.filter_list_off_rounded
                  : Icons.search_off_rounded,
              title: anyFilterActive
                  ? 'No Members Match Filters'
                  : 'No Suggestions Yet',
              subtitle: anyFilterActive
                  ? 'Try removing some filters to see more members.'
                  : 'Engage more in the community feed\nto receive member suggestions.',
              actionLabel: anyFilterActive ? 'Clear Filters' : null,
              onAction: anyFilterActive
                  ? () => setState(() {
                        _filterVerified   = false;
                        _filterPremium    = false;
                        _filterActiveWeek = false;
                        _filterMyTopics   = false;
                      })
                  : null,
            ),
          )

        // ── Cards ─────────────────────────────────────────────────────
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _suggestionCard(filtered[i], cp, isEligible),
              ),
              childCount: filtered.length,
            ),
          ),

        SliverToBoxAdapter(child: const SizedBox(height: 80)),
      ],
    );
  }

  Widget _discoverFilterBar() {
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip(
            label: '✓ Verified',
            active: _filterVerified,
            color: _kTeal,
            onTap: () => setState(() => _filterVerified = !_filterVerified),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: '💎 Premium',
            active: _filterPremium,
            color: _kPurple,
            onTap: () => setState(() => _filterPremium = !_filterPremium),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: '🔥 Active This Week',
            active: _filterActiveWeek,
            color: _kPink,
            onTap: () => setState(() => _filterActiveWeek = !_filterActiveWeek),
          ),
          if (_myTopics.isNotEmpty) ...[  
            const SizedBox(width: 8),
            _filterChip(
              label: '🌸 My Topics',
              active: _filterMyTopics,
              color: _kGold,
              onTap: () => setState(() => _filterMyTopics = !_filterMyTopics),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active ? color.withOpacity(0.22) : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: active ? color.withOpacity(0.6) : Colors.white.withOpacity(0.12),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? color : Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _suggestionCard(_SuggestedMember member, ConnectionProvider cp, bool isEligible) {
    final avatarColor = _hexToColor(member.avatarColorHex);
    final alreadyConnected = cp.isConnected(member.uid);
    final incomingFromThis = cp.incomingFrom(member.uid) != null;
    final isSending = _sendingTo.contains(member.uid);

    return GestureDetector(
      onTap: () => _openProfile(
        uid:            member.uid,
        pseudonym:      member.pseudonym,
        avatarEmoji:    member.avatarEmoji,
        avatarColorHex: member.avatarColorHex,
        isPremium:      member.isPremium,
        isVerified:     member.isVerified,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: alreadyConnected
              ? _kPurple.withOpacity(0.06)
              : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: alreadyConnected
                ? _kPurple.withOpacity(0.28)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: Avatar + name + badges ──────────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _avatarCircle(member.avatarEmoji, avatarColor, 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + trust badges
                      Row(children: [
                        Flexible(
                          child: Text(
                            member.pseudonym,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (member.isVerified) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded,
                              color: _kTeal, size: 15),
                        ],
                        if (member.isPremium) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.diamond_rounded,
                              color: _kPurple, size: 14),
                        ],
                      ]),
                      const SizedBox(height: 5),
                      // Trust signals row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (member.isActiveThisWeek)
                            _trustSignal('🔥 Active this week', _kPink),
                          if (member.memberSinceLabel.isNotEmpty)
                            _trustSignal('📅 ${member.memberSinceLabel}',
                                Colors.white.withOpacity(0.4)),
                          _trustSignal(
                              '${member.postCount} post${member.postCount == 1 ? '' : 's'}',
                              Colors.white.withOpacity(0.35)),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),

              // ── Why Match section ─────────────────────────────────────
              if (member.sharedTopics.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _kPurple.withOpacity(0.07),
                    border: Border.all(
                        color: _kPurple.withOpacity(0.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.favorite_rounded,
                          color: _kPurple, size: 13),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Shares your topics: ',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11),
                            ),
                            ...member.sharedTopics.take(3).map((t) =>
                                _topicChip(
                                    _topicLabel(t), _topicColor(t))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (member.allTopics.isNotEmpty) ...[
                // Show their topics even if none overlap mine
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Heals in: ',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 11)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: member.allTopics.take(3).map((t) =>
                            _topicChip(
                                _topicLabel(t), _topicColor(t))).toList(),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Last post preview ─────────────────────────────────────
              if (member.lastPostPreview.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote_rounded,
                        color: Colors.white.withOpacity(0.2), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        member.lastPostPreview,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // ── Action row ────────────────────────────────────────────
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: alreadyConnected
                      ? _miniChip('Connected 💜', _kPurple)
                      : incomingFromThis
                          ? _miniChip('Request Received ✓', _kGold)
                          : isEligible
                              ? _sendButton(member, isSending)
                              : _lockedButton(),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trustSignal(String label, Color color) {
    return Text(label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w500));
  }

  Widget _sendButton(_SuggestedMember member, bool isSending) {
    return GestureDetector(
      onTap: isSending
          ? null
          : () async {
              HapticFeedback.lightImpact();
              setState(() => _sendingTo.add(member.uid));
              final auth = context.read<LunarAuthProvider>();
              final myPseudonym = auth.userModel?.name ?? 'Lunar Member';
              final err =
                  await context.read<ConnectionProvider>().sendRequest(
                        toUid:              member.uid,
                        fromPseudonym:      myPseudonym,
                        fromAvatarEmoji:    '🌙',
                        fromAvatarColorHex: 'AB5CF2',
                        toPseudonym:        member.pseudonym,
                      );
              if (mounted) {
                setState(() => _sendingTo.remove(member.uid));
                _snack(
                    err == null ? 'Healing request sent 💜' : err,
                    isError: err != null);
                if (err == null) {
                  _loadSentRequests();
                  setState(() {});
                }
              }
            },
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: LinearGradient(
            colors: isSending
                ? [_kPurple.withOpacity(0.4), _kPink.withOpacity(0.4)]
                : [_kPurple, _kPink],
          ),
        ),
        child: Center(
          child: isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Send Healing Request',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _lockedButton() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: _kGold.withOpacity(0.3)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, color: _kGold, size: 15),
            const SizedBox(width: 6),
            Text('Upgrade to Connect',
                style: TextStyle(
                    color: _kGold.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _eligibilityBanner(LunarAuthProvider auth) {
    String message;
    if (!auth.isActivePremium) {
      message = '💜 Upgrade to Lunar Premium to send healing connections';
    } else if (!auth.isEmailVerified) {
      message = '✉️ Verify your email to send healing connections';
    } else {
      final created = auth.userModel?.createdAt;
      final days = created != null ? DateTime.now().difference(created).inDays : 0;
      final remaining = 7 - days;
      message = '🌙 Account needs $remaining more day${remaining == 1 ? '' : 's'} to unlock connections';
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _kGold.withOpacity(0.08),
          border: Border.all(color: _kGold.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: _kGold, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.5))),
        ]),
      ),
    );
  }

  // ── Small shared components ──────────────────────────────────────────────────

  Widget _avatarCircle(String emoji, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          color.withOpacity(0.85),
          color.withOpacity(0.25),
        ]),
        border: Border.all(color: color.withOpacity(0.45), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 10)],
      ),
      child: Center(child: Text(emoji,
          style: TextStyle(fontSize: size * 0.44))),
    );
  }

  Widget _countBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color,
      ),
      child: Text('$count',
          style: const TextStyle(color: Colors.white, fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _topicChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.14),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: _kPurple.withOpacity(0.4), size: 52),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white,
              fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(colors: [_kPurple, _kPink]),
                ),
                child: Text(actionLabel,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _openProfile({
    required String uid,
    required String pseudonym,
    required String avatarEmoji,
    required String avatarColorHex,
    bool isPremium = false,
    bool isVerified = false,
  }) {
    HapticFeedback.lightImpact();
    Navigator.push<void>(
      context,
      CommunityProfileScreen.route(
        targetUid:      uid,
        pseudonym:      pseudonym,
        avatarEmoji:    avatarEmoji,
        avatarColorHex: avatarColorHex,
        isPremium:      isPremium,
        isVerified:     isVerified,
      ),
    );
  }

  // ── Utilities ────────────────────────────────────────────────────────────────

  bool _checkEligible(LunarAuthProvider auth) {
    if (!auth.isAuthenticated || auth.isGuest) return false;
    if (!auth.isActivePremium) return false;
    if (!auth.isEmailVerified) return false;
    final created = auth.userModel?.createdAt;
    if (created == null) return false;
    return DateTime.now().difference(created).inDays >= 7;
  }

  static Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return _kPurple;
    }
  }

  static String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  static String _topicLabel(String id) {
    const map = {
      'periodTalk': 'Period Talk',
      'pregnancy': 'Pregnancy',
      'emotionalHealing': 'Emotional Healing',
      'relationships': 'Relationships',
      'anxietySupport': 'Anxiety',
      'selfCare': 'Self Care',
      'sleepWellness': 'Sleep',
    };
    return map[id] ?? id;
  }

  static Color _topicColor(String id) {
    const map = {
      'periodTalk':       Color(0xFFE53935),
      'pregnancy':        Color(0xFFFFD700),
      'emotionalHealing': Color(0xFFAB5CF2),
      'relationships':    Color(0xFFEC407A),
      'anxietySupport':   Color(0xFF4FC3F7),
      'selfCare':         Color(0xFF66BB6A),
      'sleepWellness':    Color(0xFF7986CB),
    };
    return map[id] ?? _kPurple;
  }
}
