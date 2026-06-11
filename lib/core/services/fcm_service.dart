import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';

// ══════════════════════════════════════════════════════════════
//  FCM SERVICE
//  Handles Firebase Cloud Messaging for Lunar:
//  - Permission request
//  - Token registration & refresh
//  - Foreground notification banner (in-app SnackBar)
//  - Background message handler
//  - Notification tap routing (data['screen'] key)
// ══════════════════════════════════════════════════════════════

/// Top-level background handler — MUST be a top-level function.
@pragma('vm:entry-point')
Future<void> _onFcmBackground(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

abstract final class FCMService {
  static final _messaging = FirebaseMessaging.instance;

  /// NavigatorKey threaded from MaterialApp — used to show foreground banners
  /// and handle notification taps without a BuildContext dependency.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Tracks the active onTokenRefresh subscription so it can be cancelled
  /// and replaced on subsequent sign-ins (prevents duplicate listeners).
  static StreamSubscription<String>? _tokenRefreshSub;

  // ── Init ──────────────────────────────────────────────────

  /// Call once after Firebase.initializeApp().
  /// Sets up background handler, permission request, and message listeners.
  /// Token storage is deferred to [registerToken] (called on auth sign-in).
  static Future<void> init() async {
    try {
      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_onFcmBackground);

      // Request OS permission (no-op on Android < 13, prompt on iOS/Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

      // Foreground message → in-app banner
      FirebaseMessaging.onMessage.listen(_handleForeground);

      // Notification tap while app is in background (not killed)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      // Notification tap that launched the app from terminated state
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _handleTap(initial);
    } catch (e) {
      debugPrint('[FCM] Init error (non-fatal): $e');
    }
  }

  // ── Token ─────────────────────────────────────────────────

  /// Register (or refresh) the FCM token for the signed-in [uid].
  /// Safe to call on every sign-in — token is stored with merge semantics.
  static Future<void> registerToken(String uid) async {
    try {
      // On iOS, APNs token must be available before FCM token is issued.
      if (Platform.isIOS) {
        await _messaging.getAPNSToken();
      }
      final token = await _messaging.getToken();
      if (token != null) {
        await FirestoreService.saveFcmToken(uid, token);
        debugPrint('[FCM] Token stored for $uid');
      }
      // Cancel the previous refresh listener before creating a new one.
      // Without this, each sign-in adds a new subscription, causing
      // duplicate writes and stale-uid writes after sign-out/sign-in.
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
        FirestoreService.saveFcmToken(uid, newToken)
            .catchError((e) => debugPrint('[FCM] Token refresh error: $e'));
      });
    } catch (e) {
      debugPrint('[FCM] registerToken error (non-fatal): $e');
    }
  }

  // ── Handlers ──────────────────────────────────────────────

  static void _handleForeground(RemoteMessage message) {
    final title = message.notification?.title ?? 'Lunar 🌙';
    final body  = message.notification?.body ?? '';
    final ctx   = navigatorKey?.currentContext;
    if (ctx == null || body.isEmpty) return;

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(body,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF5C2DB8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void _handleTap(RemoteMessage message) {
    final screen = message.data['screen'] as String?;
    debugPrint('[FCM] Notification tap — screen hint: $screen');
    // Future: navigate to screen based on message.data['screen'] value.
    // Currently logs for analytics; the app opens to home by default.
  }
}
