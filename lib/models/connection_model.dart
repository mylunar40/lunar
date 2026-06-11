// ─────────────────────────────────────────────────────────────────────────────
//  LUNAR CONNECTION MODEL
//  Data classes for the Healing Connections system.
//  Collections: connection_requests · connections · blocked_users
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ── Request Status ─────────────────────────────────────────────────────────────
enum ConnectionRequestStatus { pending, accepted, rejected }

extension ConnectionRequestStatusX on ConnectionRequestStatus {
  String get name {
    switch (this) {
      case ConnectionRequestStatus.pending:  return 'pending';
      case ConnectionRequestStatus.accepted: return 'accepted';
      case ConnectionRequestStatus.rejected: return 'rejected';
    }
  }

  static ConnectionRequestStatus fromString(String? s) {
    switch (s) {
      case 'accepted': return ConnectionRequestStatus.accepted;
      case 'rejected': return ConnectionRequestStatus.rejected;
      default:         return ConnectionRequestStatus.pending;
    }
  }
}

// ── Connection Status (derived, for UI) ───────────────────────────────────────
enum ConnectionStatus { none, pendingSent, pendingReceived, connected, blocked }

// ─────────────────────────────────────────────────────────────────────────────
//  CONNECTION REQUEST
// ─────────────────────────────────────────────────────────────────────────────
class ConnectionRequest {
  final String id;
  final String fromUid;
  final String toUid;

  /// Display alias of the sender (pseudonym used in community).
  final String fromPseudonym;
  final String fromAvatarEmoji;
  final String fromAvatarColorHex;

  /// Display alias of the receiver.
  final String toPseudonym;

  final ConnectionRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  /// Request expires after 30 days if not responded to.
  DateTime get expiresAt => createdAt.add(const Duration(days: 30));
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  const ConnectionRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.fromPseudonym,
    required this.fromAvatarEmoji,
    required this.fromAvatarColorHex,
    required this.toPseudonym,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory ConnectionRequest.fromMap(String id, Map<String, dynamic> map) {
    return ConnectionRequest(
      id: id,
      fromUid: map['fromUid'] as String? ?? '',
      toUid: map['toUid'] as String? ?? '',
      fromPseudonym: map['fromPseudonym'] as String? ?? 'Lunar Member',
      fromAvatarEmoji: map['fromAvatarEmoji'] as String? ?? '🌙',
      fromAvatarColorHex: map['fromAvatarColorHex'] as String? ?? 'AB5CF2',
      toPseudonym: map['toPseudonym'] as String? ?? 'Lunar Member',
      status: ConnectionRequestStatusX.fromString(map['status'] as String?),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'fromUid':           fromUid,
    'toUid':             toUid,
    'fromPseudonym':     fromPseudonym,
    'fromAvatarEmoji':   fromAvatarEmoji,
    'fromAvatarColorHex': fromAvatarColorHex,
    'toPseudonym':       toPseudonym,
    'status':            status.name,
    'createdAt':         Timestamp.fromDate(createdAt),
    'respondedAt':       respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
  };

  ConnectionRequest copyWith({ConnectionRequestStatus? status, DateTime? respondedAt}) {
    return ConnectionRequest(
      id:                 id,
      fromUid:            fromUid,
      toUid:              toUid,
      fromPseudonym:      fromPseudonym,
      fromAvatarEmoji:    fromAvatarEmoji,
      fromAvatarColorHex: fromAvatarColorHex,
      toPseudonym:        toPseudonym,
      status:             status ?? this.status,
      createdAt:          createdAt,
      respondedAt:        respondedAt ?? this.respondedAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONNECTION  (accepted pair)
// ─────────────────────────────────────────────────────────────────────────────
class LunarConnection {
  /// Doc id is always "${uid1}_${uid2}" with uid1 < uid2 (alphabetical order).
  final String id;
  final String uid1;
  final String uid2;
  final DateTime connectedAt;

  const LunarConnection({
    required this.id,
    required this.uid1,
    required this.uid2,
    required this.connectedAt,
  });

  /// The other user's uid given the current user's uid.
  String otherUid(String myUid) => myUid == uid1 ? uid2 : uid1;

  /// Whether a given uid is part of this connection.
  bool involves(String uid) => uid1 == uid || uid2 == uid;

  factory LunarConnection.fromMap(String id, Map<String, dynamic> map) {
    return LunarConnection(
      id: id,
      uid1: map['uid1'] as String? ?? '',
      uid2: map['uid2'] as String? ?? '',
      connectedAt: (map['connectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid1':         uid1,
    'uid2':         uid2,
    'connectedAt':  Timestamp.fromDate(connectedAt),
  };

  /// Canonical doc id: sorted uid pair with underscore separator.
  static String makeId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BLOCKED USER
// ─────────────────────────────────────────────────────────────────────────────
class BlockedUser {
  /// Doc id is "${blockerUid}_${blockedUid}".
  final String id;
  final String blockerUid;
  final String blockedUid;
  final DateTime blockedAt;

  const BlockedUser({
    required this.id,
    required this.blockerUid,
    required this.blockedUid,
    required this.blockedAt,
  });

  factory BlockedUser.fromMap(String id, Map<String, dynamic> map) {
    return BlockedUser(
      id:         id,
      blockerUid: map['blockerUid'] as String? ?? '',
      blockedUid: map['blockedUid'] as String? ?? '',
      blockedAt:  (map['blockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'blockerUid': blockerUid,
    'blockedUid': blockedUid,
    'blockedAt':  Timestamp.fromDate(blockedAt),
  };

  static String makeId(String blockerUid, String blockedUid) =>
      '${blockerUid}_$blockedUid';
}
