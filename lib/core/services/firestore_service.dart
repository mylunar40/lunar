import 'package:cloud_firestore/cloud_firestore.dart';
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

  static Future<void> updateUser(
          String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static Stream<LunarUserModel?> userStream(String uid) =>
      _db.collection('users').doc(uid).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return LunarUserModel.fromMap(doc.data()!, doc.id);
      });

  // ── Cycle Logs ──────────────────────────────────────────
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

  static Future<void> updateJournal(
          String docId, Map<String, dynamic> data) =>
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

  // ── AI Memory ───────────────────────────────────────────
  static Future<void> saveAIMemory(
          String uid, Map<String, dynamic> data) =>
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

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      communityStream() =>
          _db
              .collection('community')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots();

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
}
