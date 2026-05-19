// ─────────────────────────────────────────────────────────────────────────────
// LUNAR AI — Firebase Options
// ─────────────────────────────────────────────────────────────────────────────
//
// SETUP REQUIRED — run the following command to auto-generate this file:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Then replace this file with the generated output.
//
// Manual setup:
//   1. Create a Firebase project at https://console.firebase.google.com
//   2. Add Android app → download google-services.json → place in android/app/
//   3. Add iOS app → download GoogleService-Info.plist → place in ios/Runner/
//   4. Enable Authentication, Firestore, Storage, Analytics, Crashlytics
//   5. Run: flutterfire configure
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.\n'
          'Run: flutterfire configure',
        );
    }
  }

  // ── TODO: Replace all placeholder values below with your Firebase project ──
  // After running `flutterfire configure`, this file will be auto-filled.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDOKtvoJhy_mMqafXA2mNs0Vhdc5q_EkQ',
    appId: '1:795015095091:android:df0518fa92d2ea0aebd446',
    messagingSenderId: '795015095091',
    projectId: 'lunar-ai-8e8dc',
    storageBucket: 'lunar-ai-8e8dc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'YOUR_BUNDLE_ID',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId: 'YOUR_MACOS_CLIENT_ID',
    iosBundleId: 'YOUR_MACOS_BUNDLE_ID',
  );
}
