import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Firestore data layer — all collections managed here.
///
/// Firestore Structure:
///   users/{uid}          — profile + cycle settings
///   cycles/{docId}       — cycle log entries  (uid field)
///   moods/{docId}        — mood log entries   (uid field)
///   journals/{docId}     — journal entries    (uid field)
///   pregnancy/{uid}      — pregnancy journey  (uid == docId)
///   community/{docId}    — community posts    (uid field)
///   ai_memory/{uid}      — AI conversation memory
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── User Profile ────────────────────────────────────────
  static Future<void> createUser(LunarUserModel user) =>
      _db.collection('users').doc(user.uid).set(user.toMap());

  static Future<LunarUserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return LunarUserModel.fromMap(doc.data()!, doc.id);
  }

  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      final projectId = _db.app.options.projectId ?? 'unknown';
      final collectionPath = 'users';
      debugPrint('[FirestoreService.updateUser] Starting write:');
      debugPrint('  Firebase Project ID: $projectId');
      debugPrint('  Current UID: $uid');
      debugPrint('  Collection: $collectionPath');
      debugPrint('  Document ID: $uid');
      debugPrint('  Data keys: ${data.keys.toList()}');

      await _db.collection('users').doc(uid).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[FirestoreService.updateUser] Write succeeded.');
    } catch (e) {
      debugPrint('[FirestoreService.updateUser] Write FAILED');
      debugPrint('  Exception type: ${e.runtimeType}');
      debugPrint('  Exception message: $e');
      debugPrint('  Full exception: $e');
      debugPrint('  Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  static Stream<LunarUserModel?> userStream(String uid) =>
      _db.collection('users').doc(uid).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return LunarUserModel.fromMap(doc.data()!, doc.id);
      });

  // ── Cycle Logs ──────────────────────────────────────────
  // NOTE: These two methods write/read the top-level `cycles` collection.
  // They are NEVER called by any screen or provider. All active cycle
  // persistence goes through CycleRepository, which uses the subcollection
  // path: users/{uid}/cycles — do NOT call these methods.
  // They are kept here only to avoid breaking any potential future callers
  // and will be removed in the next cleanup pass.
  @Deprecated(
      'Use CycleRepository.pushToFirestore() — writes users/{uid}/cycles subcollection')
  static Future<DocumentReference> saveCycleLog({
    required String uid,
    required DateTime periodDate,
    required int cycleLength,
    String? notes,
  }) =>
      _db.collection('cycles').add({
        'uid': uid,
        'periodDate': Timestamp.fromDate(periodDate),
        'cycleLength': cycleLength,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      });

  @Deprecated(
      'Use CycleRepository.fetchFromFirestore() — reads users/{uid}/cycles subcollection')
  static Stream<QuerySnapshot<Map<String, dynamic>>> cycleStream(String uid) =>
      _db
          .collection('cycles')
          .where('uid', isEqualTo: uid)
          .orderBy('periodDate', descending: true)
          .limit(12)
          .snapshots();

  // ── Mood Logs ───────────────────────────────────────────
  static Future<DocumentReference> saveMoodLog({
    required String uid,
    required String mood,
    required int intensity,
    List<String>? symptoms,
    String? note,
  }) =>
      _db.collection('moods').add({
        'uid': uid,
        'mood': mood,
        'intensity': intensity,
        'symptoms': symptoms ?? [],
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });

  static Stream<QuerySnapshot<Map<String, dynamic>>> moodStream(String uid) =>
      _db
          .collection('moods')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots();

  // ── Journals ────────────────────────────────────────────
  static Future<DocumentReference> saveJournal({
    required String uid,
    required String title,
    required String content,
    required String mood,
    List<String>? tags,
  }) =>
      _db.collection('journals').add({
        'uid': uid,
        'title': title,
        'content': content,
        'mood': mood,
        'tags': tags ?? [],
        'createdAt': FieldValue.serverTimestamp(),
      });

  static Future<void> updateJournal(String docId, Map<String, dynamic> data) =>
      _db.collection('journals').doc(docId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static Future<void> deleteJournal(String docId) =>
      _db.collection('journals').doc(docId).delete();

  static Stream<QuerySnapshot<Map<String, dynamic>>> journalStream(
          String uid) =>
      _db
          .collection('journals')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots();

  // ── Pregnancy ───────────────────────────────────────────
  static Future<void> updatePregnancyData(
          String uid, Map<String, dynamic> data) =>
      _db.collection('pregnancy').doc(uid).set(
          {...data, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

  static Future<Map<String, dynamic>?> getPregnancyData(String uid) async {
    final doc = await _db.collection('pregnancy').doc(uid).get();
    return doc.data();
  }

  /// Saves a pregnancy memory journal entry (bump note, milestone, etc.)
  /// to the `pregnancy_journals` sub-collection.
  static Future<DocumentReference> savePregnancyJournal({
    required String uid,
    required Map<String, dynamic> data,
  }) =>
      _db.collection('pregnancy_journals').add({
        'uid': uid,
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });

  static Stream<QuerySnapshot<Map<String, dynamic>>> pregnancyJournalStream(
          String uid) =>
      _db
          .collection('pregnancy_journals')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots();

  // ── AI Memory ───────────────────────────────────────────
  static Future<void> saveAIMemory(String uid, Map<String, dynamic> data) =>
      _db.collection('ai_memory').doc(uid).set(
          {...data, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

  static Future<Map<String, dynamic>> getAIMemory(String uid) async {
    final doc = await _db.collection('ai_memory').doc(uid).get();
    return doc.data() ?? {};
  }

  // ── Community ───────────────────────────────────────────
  static Future<DocumentReference> postToCommunity({
    required String uid,
    required String displayName,
    required String content,
    List<String>? tags,
  }) =>
      _db.collection('community').add({
        'uid': uid,
        'displayName': displayName,
        'content': content,
        'tags': tags ?? [],
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

  // Full community post with all Lunar fields
  static Future<DocumentReference> createCommunityPost({
    required String uid,
    required String pseudonym,
    required String avatarEmoji,
    required String avatarColorHex,
    required bool isAnonymous,
    required String category,
    required String content,
    required List<String> tags,
    bool isSensitive = false,
    String postType = 'regular',
  }) =>
      _db.collection('community_posts').add({
        'uid': uid,
        'pseudonym': pseudonym,
        'avatarEmoji': avatarEmoji,
        'avatarColorHex': avatarColorHex,
        'isAnonymous': isAnonymous,
        'category': category,
        'content': content,
        'tags': tags,
        'isSensitive': isSensitive,
        'postType': postType,
        'reactions': <String, int>{},
        'commentsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

  static Stream<QuerySnapshot<Map<String, dynamic>>> communityFeedStream(
      {String? category, int limit = 30}) {
    var q = _db
        .collection('community_posts')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (category != null && category != 'all') {
      q = _db
          .collection('community_posts')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    }
    return q.snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> communityStream() => _db
      .collection('community')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots();

  static Future<void> toggleCommunityReaction({
    required String postId,
    required String uid,
    required String reaction,
    required bool add,
  }) async {
    final ref = _db.collection('community_posts').doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final rxns = Map<String, dynamic>.from((data['reactions'] as Map?) ?? {});
      final current = (rxns[reaction] as int?) ?? 0;
      rxns[reaction] = add ? current + 1 : (current - 1).clamp(0, 99999);
      tx.update(ref, {'reactions': rxns});
    });
  }

  static Future<void> toggleBookmark({
    required String uid,
    required String postId,
    required bool add,
  }) =>
      _db.collection('community_bookmarks').doc('${uid}_$postId').set({
        'uid': uid,
        'postId': postId,
        'savedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: !add)).then((_) => add
          ? null
          : _db
              .collection('community_bookmarks')
              .doc('${uid}_$postId')
              .delete());

  static Stream<QuerySnapshot<Map<String, dynamic>>> bookmarkStream(
          String uid) =>
      _db
          .collection('community_bookmarks')
          .where('uid', isEqualTo: uid)
          .snapshots();

  static Future<DocumentReference> addCommunityComment({
    required String postId,
    required String uid,
    required String pseudonym,
    required String avatarEmoji,
    required bool isAnonymous,
    required String content,
  }) async {
    final ref = await _db.collection('community_comments').add({
      'postId': postId,
      'uid': uid,
      'pseudonym': pseudonym,
      'avatarEmoji': avatarEmoji,
      'isAnonymous': isAnonymous,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db
        .collection('community_posts')
        .doc(postId)
        .update({'commentsCount': FieldValue.increment(1)});
    return ref;
  }

  static Future<DocumentReference> createCommunityActivity({
    required String uid,
    required String actorUid,
    required String type,
    required String text,
    String? postId,
    String? storyId,
  }) {
    return _db.collection('community_activity').add({
      'uid': uid,
      'actorUid': actorUid,
      'type': type,
      'text': text,
      if (postId != null) 'postId': postId,
      if (storyId != null) 'storyId': storyId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(
          String postId) =>
      _db
          .collection('community_comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .limit(50)
          .snapshots();

  static Future<void> reportCommunityPost({
    required String postId,
    required String uid,
    required String reason,
  }) =>
      _db.collection('community_reports').add({
        'postId': postId,
        'reportedBy': uid,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      }).then((_) => _db
          .collection('community_posts')
          .doc(postId)
          .update({'isReported': true}));

  // ── Batch Sync (cloud backup) ───────────────────────────
  /// Sync local UserProvider data to Firestore (called after login).
  static Future<void> syncLocalData({
    required String uid,
    DateTime? lastPeriodDate,
    int? cycleLength,
  }) async {
    final updates = <String, dynamic>{
      if (lastPeriodDate != null)
        'lastPeriodDate': Timestamp.fromDate(lastPeriodDate),
      if (cycleLength != null) 'cycleLength': cycleLength,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (updates.length > 1) {
      await _db
          .collection('users')
          .doc(uid)
          .set(updates, SetOptions(merge: true));
    }
  }

  // ── FCM Token ───────────────────────────────────────────
  /// Stores the device FCM token on the user document (merge, no overwrite).
  /// Called on every sign-in so the token stays current after rotation.
  static Future<void> saveFcmToken(String uid, String token) =>
      _db.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  // ── Account Deletion (GDPR) ─────────────────────────────
  /// Deletes ALL Firestore documents that belong to [uid].
  /// Call this BEFORE deleting the Firebase Auth account so that
  /// security rules still allow the write.
  ///
  /// Collections with uid-keyed documents (single doc per user):
  ///   users, pregnancy, ai_memory, avatars
  ///
  /// Collections with uid-field documents (multiple docs per user):
  ///   moods, journals, pregnancy_journals, community_posts,
  ///   community_comments, community_bookmarks
  ///
  /// Sub-collections:
  ///   users/{uid}/cycles
  ///
  /// Note: community_reports are kept for audit/safety purposes.
  static Future<void> deleteUserData(String uid) async {
    // 1. Single-doc collections (uid == docId)
    final singleDocCollections = [
      'users',
      'pregnancy',
      'ai_memory',
      'avatars',
      'chatHistory',
    ];
    for (final col in singleDocCollections) {
      try {
        await _db.collection(col).doc(uid).delete();
      } catch (_) {}
    }

    // 2. users/{uid}/cycles subcollection
    try {
      final cyclesSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('cycles')
          .limit(200)
          .get();
      for (final doc in cyclesSnap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    // 3. Multi-doc collections filtered by uid field
    // Processed in batches of 100 to stay within Firestore limits.
    final multiDocCollections = [
      'moods',
      'journals',
      'pregnancy_journals',
      'community_posts',
      'community_comments',
      'community_bookmarks',
    ];
    for (final col in multiDocCollections) {
      try {
        QuerySnapshot snap;
        do {
          snap = await _db
              .collection(col)
              .where('uid', isEqualTo: uid)
              .limit(100)
              .get();
          final batch = _db.batch();
          for (final doc in snap.docs) {
            batch.delete(doc.reference);
          }
          if (snap.docs.isNotEmpty) await batch.commit();
        } while (snap.docs.length == 100);
      } catch (_) {}
    }
  }
}
