// ─────────────────────────────────────────────────────────────────────────────
//  LUNAR CONNECTION SERVICE
//  All Firestore operations for the Healing Connections system.
//  Collections: connection_requests · connections · blocked_users
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/connection_model.dart';

class ConnectionService {
  ConnectionService._();

  static final _db = FirebaseFirestore.instance;

  static const _requests = 'connection_requests';
  static const _conns = 'connections';
  static const _blocked = 'blocked_users';

  // ── Eligibility ──────────────────────────────────────────────────────────

  /// Returns true when both conditions pass:
  ///   • user's account was created ≥ 7 days ago
  ///   • user has an active premium subscription (checked via userModel on client)
  /// Email-verified check is done client-side via LunarAuthProvider.isEmailVerified.
  static bool accountIsOldEnough(DateTime createdAt) {
    return DateTime.now().difference(createdAt).inDays >= 7;
  }

  // ── Send Request ─────────────────────────────────────────────────────────

  /// Sends a healing connection request from [fromUid] to [toUid].
  /// Throws if a pending request already exists in either direction, or if
  /// they are already connected, or if [toUid] has blocked [fromUid].
  static Future<void> sendRequest({
    required String fromUid,
    required String toUid,
    required String fromPseudonym,
    required String fromAvatarEmoji,
    required String fromAvatarColorHex,
    required String toPseudonym,
  }) async {
    // Guard: cannot send to yourself
    if (fromUid == toUid) throw Exception('Cannot connect with yourself.');

    // Guard: check if blocked (either direction)
    final blockedId1 = BlockedUser.makeId(fromUid, toUid);
    final blockedId2 = BlockedUser.makeId(toUid, fromUid);
    final b1 = await _db.collection(_blocked).doc(blockedId1).get();
    final b2 = await _db.collection(_blocked).doc(blockedId2).get();
    if (b1.exists || b2.exists) throw Exception('Cannot send request.');

    // Guard: already connected
    final connId = LunarConnection.makeId(fromUid, toUid);
    final conn = await _db.collection(_conns).doc(connId).get();
    if (conn.exists) throw Exception('Already connected.');

    // Guard: existing pending request in this direction
    final existing = await _db
        .collection(_requests)
        .where('fromUid', isEqualTo: fromUid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('You already have a pending request to this person.');
    }

    final request = ConnectionRequest(
      id: '',
      fromUid: fromUid,
      toUid: toUid,
      fromPseudonym: fromPseudonym,
      fromAvatarEmoji: fromAvatarEmoji,
      fromAvatarColorHex: fromAvatarColorHex,
      toPseudonym: toPseudonym,
      status: ConnectionRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    await _db.collection(_requests).add(request.toMap());
    await _createActivity(
      uid: toUid,
      actorUid: fromUid,
      type: 'friendRequest',
      text: '$fromPseudonym sent you a friend request',
    );
    debugPrint('[ConnectionService] Request sent $fromUid → $toUid');
  }

  // ── Accept Request ────────────────────────────────────────────────────────

  /// Accepts [requestId] and creates a connection document atomically.
  static Future<void> acceptRequest(String requestId) async {
    final doc = await _db.collection(_requests).doc(requestId).get();
    if (!doc.exists) throw Exception('Request not found.');

    final req = ConnectionRequest.fromMap(doc.id, doc.data()!);
    if (req.status != ConnectionRequestStatus.pending) {
      throw Exception('Request is no longer pending.');
    }

    final batch = _db.batch();

    // Update request status
    batch.update(_db.collection(_requests).doc(requestId), {
      'status': 'accepted',
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Create connection document (canonical id)
    final connId = LunarConnection.makeId(req.fromUid, req.toUid);
    final sorted = [req.fromUid, req.toUid]..sort();
    final connection = LunarConnection(
      id: connId,
      uid1: sorted[0],
      uid2: sorted[1],
      connectedAt: DateTime.now(),
    );
    batch.set(_db.collection(_conns).doc(connId), connection.toMap());

    final now = FieldValue.serverTimestamp();
    batch.set(_db.collection('community_activity').doc(), {
      'uid': req.fromUid,
      'actorUid': req.toUid,
      'type': 'requestAccepted',
      'text': '${req.toPseudonym} accepted your friend request',
      'read': false,
      'createdAt': now,
    });

    await batch.commit();
    debugPrint('[ConnectionService] Accepted: $requestId → connection $connId');
  }

  // ── Reject Request ────────────────────────────────────────────────────────

  static Future<void> rejectRequest(String requestId) async {
    await _db.collection(_requests).doc(requestId).update({
      'status': 'rejected',
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
    debugPrint('[ConnectionService] Rejected: $requestId');
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  /// Removes the connection between two users. Does NOT block.
  static Future<void> disconnect(String uid1, String uid2) async {
    final connId = LunarConnection.makeId(uid1, uid2);
    await _db.collection(_conns).doc(connId).delete();
    debugPrint('[ConnectionService] Disconnected: $connId');
  }

  // ── Block User ────────────────────────────────────────────────────────────

  /// Blocks [blockedUid] and removes any existing connection / pending requests.
  static Future<void> blockUser({
    required String blockerUid,
    required String blockedUid,
  }) async {
    final batch = _db.batch();

    // Create block record
    final blockId = BlockedUser.makeId(blockerUid, blockedUid);
    final block = BlockedUser(
      id: blockId,
      blockerUid: blockerUid,
      blockedUid: blockedUid,
      blockedAt: DateTime.now(),
    );
    batch.set(_db.collection(_blocked).doc(blockId), block.toMap());

    // Delete connection if it exists
    final connId = LunarConnection.makeId(blockerUid, blockedUid);
    batch.delete(_db.collection(_conns).doc(connId));

    await batch.commit();

    // Cancel any pending requests between the two users (non-batch for safety)
    try {
      final sentReqs = await _db
          .collection(_requests)
          .where('fromUid', isEqualTo: blockerUid)
          .where('toUid', isEqualTo: blockedUid)
          .where('status', isEqualTo: 'pending')
          .get();
      for (final d in sentReqs.docs) {
        await d.reference.update({'status': 'rejected'});
      }
      final receivedReqs = await _db
          .collection(_requests)
          .where('fromUid', isEqualTo: blockedUid)
          .where('toUid', isEqualTo: blockerUid)
          .where('status', isEqualTo: 'pending')
          .get();
      for (final d in receivedReqs.docs) {
        await d.reference.update({'status': 'rejected'});
      }
    } catch (e) {
      debugPrint('[ConnectionService] Cleanup requests after block: $e');
    }

    debugPrint('[ConnectionService] Blocked: $blockerUid → $blockedUid');
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Live stream of pending incoming requests for [uid].
  static Stream<List<ConnectionRequest>> incomingRequestsStream(String uid) {
    return _db
        .collection(_requests)
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ConnectionRequest.fromMap(d.id, d.data()))
            .where((r) => !r.isExpired)
            .toList());
  }

  /// Live stream of connections where [uid] is uid1 (use with uid2 stream in provider).
  static Stream<List<LunarConnection>> connectionsStream(String uid) {
    return _db.collection(_conns).where('uid1', isEqualTo: uid).snapshots().map(
        (snap) => snap.docs
            .map((d) => LunarConnection.fromMap(d.id, d.data()))
            .toList());
  }

  /// Fetch a single snapshot of all connections where uid is uid1 or uid2.
  static Future<List<LunarConnection>> getConnections(String uid) async {
    final results = await Future.wait([
      _db.collection(_conns).where('uid1', isEqualTo: uid).get(),
      _db.collection(_conns).where('uid2', isEqualTo: uid).get(),
    ]);
    final all = <LunarConnection>[];
    for (final snap in results) {
      all.addAll(snap.docs.map((d) => LunarConnection.fromMap(d.id, d.data())));
    }
    return all;
  }

  // ── Point-in-time status ──────────────────────────────────────────────────

  /// Returns the current [ConnectionStatus] between [myUid] and [otherUid].
  static Future<ConnectionStatus> getStatus(
      String myUid, String otherUid) async {
    // Blocked by me?
    final bMe = await _db
        .collection(_blocked)
        .doc(BlockedUser.makeId(myUid, otherUid))
        .get();
    if (bMe.exists) return ConnectionStatus.blocked;

    // Blocked by them?
    final bThem = await _db
        .collection(_blocked)
        .doc(BlockedUser.makeId(otherUid, myUid))
        .get();
    if (bThem.exists) return ConnectionStatus.blocked;

    // Connected?
    final conn = await _db
        .collection(_conns)
        .doc(LunarConnection.makeId(myUid, otherUid))
        .get();
    if (conn.exists) return ConnectionStatus.connected;

    // Sent request?
    final sent = await _db
        .collection(_requests)
        .where('fromUid', isEqualTo: myUid)
        .where('toUid', isEqualTo: otherUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (sent.docs.isNotEmpty) return ConnectionStatus.pendingSent;

    // Received request?
    final received = await _db
        .collection(_requests)
        .where('fromUid', isEqualTo: otherUid)
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (received.docs.isNotEmpty) return ConnectionStatus.pendingReceived;

    return ConnectionStatus.none;
  }

  /// Returns the pending request id sent from [otherUid] to [myUid] (if any).
  static Future<String?> getIncomingRequestId(
      String myUid, String otherUid) async {
    final snap = await _db
        .collection(_requests)
        .where('fromUid', isEqualTo: otherUid)
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty ? snap.docs.first.id : null;
  }

  static Future<void> _createActivity({
    required String uid,
    required String actorUid,
    required String type,
    required String text,
  }) {
    return _db.collection('community_activity').add({
      'uid': uid,
      'actorUid': actorUid,
      'type': type,
      'text': text,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
