import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CommunityActivityItem {
  final String id;
  final String type;
  final String text;
  final String actorUid;
  final String? postId;
  final String? storyId;
  final DateTime createdAt;
  final bool read;

  const CommunityActivityItem({
    required this.id,
    required this.type,
    required this.text,
    required this.actorUid,
    this.postId,
    this.storyId,
    required this.createdAt,
    required this.read,
  });

  factory CommunityActivityItem.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommunityActivityItem(
      id: doc.id,
      type: data['type'] as String? ?? 'activity',
      text: data['text'] as String? ?? 'New community activity',
      actorUid: data['actorUid'] as String? ?? '',
      postId: data['postId'] as String?,
      storyId: data['storyId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
    );
  }

  String get icon {
    switch (type) {
      case 'like':
        return '❤️';
      case 'comment':
        return '💬';
      case 'storyView':
        return '👀';
      case 'friendRequest':
        return '🤝';
      case 'requestAccepted':
        return '✅';
      case 'messageRequest':
        return '📨';
      case 'storyReaction':
        return '🌙';
      case 'mention':
        return '✨';
      case 'reply':
        return '↩';
      default:
        return '🌙';
    }
  }
}

class CommunityActivityProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  String? _uid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<CommunityActivityItem> _items = [];
  bool _loading = false;

  CommunityActivityProvider({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  List<CommunityActivityItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;

  void load(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _sub?.cancel();
    _items = [];
    if (uid == null || uid.isEmpty) {
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    _sub = _db
        .collection('community_activity')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((snap) {
      _items = snap.docs.map(CommunityActivityItem.fromDoc).toList();
      _loading = false;
      notifyListeners();
    }, onError: (_) {
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> markRead(String id) async {
    final uid = _uid;
    if (uid == null || id.isEmpty) return;
    await _db.collection('community_activity').doc(id).set({
      'uid': uid,
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
