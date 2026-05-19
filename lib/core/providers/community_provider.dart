import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

// ═══════════════════════════════════════════════════════════
//  COMMUNITY PROVIDER
//  Manages live Firestore community feed, reactions,
//  bookmarks, post creation, and moderation state.
// ═══════════════════════════════════════════════════════════

enum CommunityLoadState { idle, loading, loaded, error }

class CommunityPost {
  final String id;
  final String uid;
  final String pseudonym;
  final String avatarEmoji;
  final String avatarColorHex;
  final bool isAnonymous;
  final String category;
  final String content;
  final List<String> tags;
  final Map<String, int> reactions;
  final int commentsCount;
  final DateTime? createdAt;
  final bool isSensitive;
  bool isBlurred;
  bool isReported;

  CommunityPost({
    required this.id,
    required this.uid,
    required this.pseudonym,
    required this.avatarEmoji,
    required this.avatarColorHex,
    required this.isAnonymous,
    required this.category,
    required this.content,
    required this.tags,
    required this.reactions,
    required this.commentsCount,
    this.createdAt,
    this.isSensitive = false,
    bool? isBlurred,
    this.isReported = false,
  }) : isBlurred = isBlurred ?? isSensitive;

  factory CommunityPost.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final ts = d['createdAt'] as Timestamp?;
    final rxnRaw = d['reactions'] as Map<String, dynamic>? ?? {};
    return CommunityPost(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      pseudonym: d['pseudonym'] as String? ?? 'Anonymous 🌙',
      avatarEmoji: d['avatarEmoji'] as String? ?? '🌙',
      avatarColorHex: d['avatarColorHex'] as String? ?? 'AB5CF2',
      isAnonymous: d['isAnonymous'] as bool? ?? true,
      category: d['category'] as String? ?? 'all',
      content: d['content'] as String? ?? '',
      tags: List<String>.from(d['tags'] as List? ?? []),
      reactions: rxnRaw.map((k, v) => MapEntry(k, (v as num).toInt())),
      commentsCount: (d['commentsCount'] as num?)?.toInt() ?? 0,
      createdAt: ts?.toDate(),
      isSensitive: d['isSensitive'] as bool? ?? false,
      isReported: d['isReported'] as bool? ?? false,
    );
  }
}

class CommunityProvider extends ChangeNotifier {
  // ── State ───────────────────────────────────────────────
  CommunityLoadState _loadState = CommunityLoadState.idle;
  List<CommunityPost> _posts = [];
  Set<String> _myReactions = {}; // 'postId:reaction'
  Set<String> _bookmarks = {};
  String _activeCategory = 'all';
  String? _uid;
  StreamSubscription<QuerySnapshot>? _feedSub;
  StreamSubscription<QuerySnapshot>? _bookmarkSub;

  // ── Getters ─────────────────────────────────────────────
  CommunityLoadState get loadState => _loadState;
  List<CommunityPost> get posts => List.unmodifiable(_posts);
  Set<String> get bookmarks => Set.unmodifiable(_bookmarks);
  String get activeCategory => _activeCategory;

  bool hasReacted(String postId, String reaction) =>
      _myReactions.contains('$postId:$reaction');

  bool isBookmarked(String postId) => _bookmarks.contains(postId);

  List<CommunityPost> get filteredPosts => _activeCategory == 'all'
      ? _posts
      : _posts.where((p) => p.category == _activeCategory).toList();

  // ── Init / Auth ─────────────────────────────────────────
  void init(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _startFeedStream();
    if (uid != null) _startBookmarkStream(uid);
  }

  void _startFeedStream() {
    _feedSub?.cancel();
    _loadState = CommunityLoadState.loading;
    notifyListeners();

    _feedSub = FirestoreService.communityFeedStream(
      category: _activeCategory == 'all' ? null : _activeCategory,
    ).listen(
      (snap) {
        _posts = snap.docs
            .map((d) => CommunityPost.fromFirestore(
                d as DocumentSnapshot<Map<String, dynamic>>))
            .where((p) => !p.isReported)
            .toList();
        _loadState = CommunityLoadState.loaded;
        notifyListeners();
      },
      onError: (_) {
        _loadState = CommunityLoadState.error;
        notifyListeners();
      },
    );
  }

  void _startBookmarkStream(String uid) {
    _bookmarkSub?.cancel();
    _bookmarkSub = FirestoreService.bookmarkStream(uid).listen((snap) {
      _bookmarks = snap.docs
          .map((d) => d.data()['postId'] as String)
          .toSet();
      notifyListeners();
    });
  }

  void setCategory(String category) {
    if (_activeCategory == category) return;
    _activeCategory = category;
    _startFeedStream();
  }

  // ── Post Actions ─────────────────────────────────────────
  Future<void> createPost({
    required String pseudonym,
    required String avatarEmoji,
    required String avatarColorHex,
    required bool isAnonymous,
    required String category,
    required String content,
    required List<String> tags,
  }) async {
    if (_uid == null) return;
    // Moderation: check for toxic keywords
    if (_containsToxicContent(content)) return;

    // Optimistic insert
    final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
    final tempPost = CommunityPost(
      id: tempId,
      uid: _uid!,
      pseudonym: pseudonym,
      avatarEmoji: avatarEmoji,
      avatarColorHex: avatarColorHex,
      isAnonymous: isAnonymous,
      category: category,
      content: content,
      tags: tags,
      reactions: {},
      commentsCount: 0,
      createdAt: DateTime.now(),
    );
    _posts.insert(0, tempPost);
    notifyListeners();

    try {
      await FirestoreService.createCommunityPost(
        uid: _uid!,
        pseudonym: pseudonym,
        avatarEmoji: avatarEmoji,
        avatarColorHex: avatarColorHex,
        isAnonymous: isAnonymous,
        category: category,
        content: content,
        tags: tags,
        isSensitive: _isSensitiveTopic(content),
      );
      // Stream will refresh from Firestore; remove temp
      _posts.removeWhere((p) => p.id == tempId);
      notifyListeners();
    } catch (_) {
      _posts.removeWhere((p) => p.id == tempId);
      notifyListeners();
    }
  }

  Future<void> toggleReaction({
    required String postId,
    required String reaction,
  }) async {
    if (_uid == null) return;
    final key = '$postId:$reaction';
    final adding = !_myReactions.contains(key);

    // Optimistic update
    setState(() {
      if (adding) {
        _myReactions.add(key);
      } else {
        _myReactions.remove(key);
      }
      final idx = _posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final post = _posts[idx];
        final current = post.reactions[reaction] ?? 0;
        post.reactions[reaction] =
            adding ? current + 1 : (current - 1).clamp(0, 99999);
      }
    });

    try {
      await FirestoreService.toggleCommunityReaction(
        postId: postId,
        uid: _uid!,
        reaction: reaction,
        add: adding,
      );
    } catch (_) {
      // Revert on failure
      setState(() {
        if (adding) {
          _myReactions.remove(key);
        } else {
          _myReactions.add(key);
        }
      });
    }
  }

  Future<void> toggleBookmark(String postId) async {
    if (_uid == null) return;
    final wasBookmarked = _bookmarks.contains(postId);
    setState(() {
      if (wasBookmarked) {
        _bookmarks.remove(postId);
      } else {
        _bookmarks.add(postId);
      }
    });
    try {
      await FirestoreService.toggleBookmark(
        uid: _uid!,
        postId: postId,
        add: !wasBookmarked,
      );
    } catch (_) {
      setState(() {
        if (wasBookmarked) {
          _bookmarks.add(postId);
        } else {
          _bookmarks.remove(postId);
        }
      });
    }
  }

  void hidePost(String postId) {
    _posts.removeWhere((p) => p.id == postId);
    notifyListeners();
  }

  void revealSensitivePost(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _posts[idx].isBlurred = false;
      notifyListeners();
    }
  }

  Future<void> reportPost(String postId) async {
    if (_uid == null) return;
    hidePost(postId);
    try {
      await FirestoreService.reportCommunityPost(
        postId: postId,
        uid: _uid!,
        reason: 'user_report',
      );
    } catch (_) {}
  }

  // ── Moderation ───────────────────────────────────────────
  static const _toxicKeywords = [
    'hate', 'kill', 'die', 'ugly', 'stupid', 'idiot',
    'loser', 'worthless', 'shut up',
  ];

  static const _sensitiveTopics = [
    'miscarriage', 'loss', 'grief', 'trauma', 'abuse',
    'assault', 'suicide', 'depression', 'self harm',
  ];

  bool _containsToxicContent(String text) {
    final lower = text.toLowerCase();
    return _toxicKeywords.any((kw) => lower.contains(kw));
  }

  bool _isSensitiveTopic(String text) {
    final lower = text.toLowerCase();
    return _sensitiveTopics.any((kw) => lower.contains(kw));
  }

  bool get hasToxicWarning => false; // Exposed for UI checks

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    _bookmarkSub?.cancel();
    super.dispose();
  }
}
