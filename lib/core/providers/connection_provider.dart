// ─────────────────────────────────────────────────────────────────────────────
//  LUNAR CONNECTION PROVIDER
//  State management for the Healing Connections system.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/connection_model.dart';
import '../services/connection_service.dart';

class ConnectionProvider extends ChangeNotifier {
  static final _db = FirebaseFirestore.instance;

  String? _myUid;
  List<ConnectionRequest> _incoming = [];
  List<LunarConnection> _connections = [];
  bool _loading = false;
  String? _error;

  StreamSubscription<List<ConnectionRequest>>? _incomingSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _connSub1;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _connSub2;

  List<LunarConnection> _uid1List = [];
  List<LunarConnection> _uid2List = [];

  // ── Getters ─────────────────────────────────────────────────────────────
  List<ConnectionRequest> get incomingRequests => List.unmodifiable(_incoming);
  List<LunarConnection>   get connections      => List.unmodifiable(_connections);
  int                     get incomingCount    => _incoming.length;
  bool                    get loading          => _loading;
  String?                 get error            => _error;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  void load(String uid) {
    if (_myUid == uid) return;
    _myUid = uid;
    _cancelSubs();
    _loading = true;
    notifyListeners();

    // Incoming pending requests
    _incomingSub = ConnectionService.incomingRequestsStream(uid).listen(
      (list) {
        _incoming = list;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[ConnectionProvider] incoming: $e');
        _loading = false;
        notifyListeners();
      },
    );

    // Connections where I am uid1
    _connSub1 = _db
        .collection('connections')
        .where('uid1', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      _uid1List = snap.docs
          .map((d) => LunarConnection.fromMap(d.id, d.data()))
          .toList();
      _mergeConnections();
    }, onError: (e) => debugPrint('[ConnectionProvider] conn1: $e'));

    // Connections where I am uid2
    _connSub2 = _db
        .collection('connections')
        .where('uid2', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      _uid2List = snap.docs
          .map((d) => LunarConnection.fromMap(d.id, d.data()))
          .toList();
      _mergeConnections();
    }, onError: (e) => debugPrint('[ConnectionProvider] conn2: $e'));
  }

  void reset() {
    _myUid = null;
    _incoming = [];
    _connections = [];
    _uid1List = [];
    _uid2List = [];
    _error = null;
    _loading = false;
    _cancelSubs();
    notifyListeners();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Returns null on success, error message on failure.
  Future<String?> sendRequest({
    required String toUid,
    required String fromPseudonym,
    required String fromAvatarEmoji,
    required String fromAvatarColorHex,
    required String toPseudonym,
  }) async {
    if (_myUid == null) return 'Not authenticated.';
    _error = null;
    try {
      await ConnectionService.sendRequest(
        fromUid:            _myUid!,
        toUid:              toUid,
        fromPseudonym:      fromPseudonym,
        fromAvatarEmoji:    fromAvatarEmoji,
        fromAvatarColorHex: fromAvatarColorHex,
        toPseudonym:        toPseudonym,
      );
      return null;
    } catch (e) {
      _error = _clean(e);
      notifyListeners();
      return _error;
    }
  }

  Future<String?> acceptRequest(String requestId) async {
    _error = null;
    try {
      await ConnectionService.acceptRequest(requestId);
      _incoming.removeWhere((r) => r.id == requestId);
      notifyListeners();
      return null;
    } catch (e) {
      _error = _clean(e);
      notifyListeners();
      return _error;
    }
  }

  Future<String?> rejectRequest(String requestId) async {
    _error = null;
    try {
      await ConnectionService.rejectRequest(requestId);
      _incoming.removeWhere((r) => r.id == requestId);
      notifyListeners();
      return null;
    } catch (e) {
      _error = _clean(e);
      notifyListeners();
      return _error;
    }
  }

  Future<String?> disconnect(String otherUid) async {
    if (_myUid == null) return 'Not authenticated.';
    _error = null;
    try {
      await ConnectionService.disconnect(_myUid!, otherUid);
      return null;
    } catch (e) {
      _error = _clean(e);
      notifyListeners();
      return _error;
    }
  }

  Future<String?> blockUser(String blockedUid) async {
    if (_myUid == null) return 'Not authenticated.';
    _error = null;
    try {
      await ConnectionService.blockUser(
          blockerUid: _myUid!, blockedUid: blockedUid);
      _incoming.removeWhere((r) => r.fromUid == blockedUid);
      notifyListeners();
      return null;
    } catch (e) {
      _error = _clean(e);
      notifyListeners();
      return _error;
    }
  }

  // ── Computed helpers ─────────────────────────────────────────────────────

  bool isConnected(String otherUid) {
    if (_myUid == null) return false;
    return _connections.any((c) => c.involves(otherUid));
  }

  /// Returns pending request from [otherUid] to me, if any.
  ConnectionRequest? incomingFrom(String otherUid) {
    try {
      return _incoming.firstWhere((r) => r.fromUid == otherUid);
    } catch (_) {
      return null;
    }
  }

  /// Full live connection status between me and [otherUid].
  /// Queries Firestore — suitable for a profile screen.
  Future<ConnectionStatus> getConnectionStatus(String otherUid) async {
    if (_myUid == null) return ConnectionStatus.none;
    return ConnectionService.getStatus(_myUid!, otherUid);
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  void _mergeConnections() {
    final seen = <String>{};
    _connections = [
      ..._uid1List,
      ..._uid2List,
    ].where((c) => seen.add(c.id)).toList();
    _loading = false;
    notifyListeners();
  }

  void _cancelSubs() {
    _incomingSub?.cancel();
    _connSub1?.cancel();
    _connSub2?.cancel();
    _incomingSub = null;
    _connSub1 = null;
    _connSub2 = null;
  }

  static String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  @override
  void dispose() {
    _cancelSubs();
    super.dispose();
  }
}
