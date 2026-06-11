import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Static wrapper around FirebaseAuth + GoogleSignIn.
/// All methods are static for easy, provider-free usage.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _google = GoogleSignIn();

  // ── State ──────────────────────────────────────────────
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  // ── Email / Password ───────────────────────────────────
  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.isNotEmpty) {
      await cred.user?.updateDisplayName(displayName);
    }
    return cred;
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  // ── Google ─────────────────────────────────────────────
  /// Returns null if user cancelled the sign-in flow.
  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  // ── Apple (structure ready — requires iOS entitlement) ─
  // static Future<UserCredential?> signInWithApple() async { ... }

  // ── Anonymous / Guest ──────────────────────────────────
  static Future<UserCredential> signInAsGuest() =>
      _auth.signInAnonymously();

  // ── Password Reset ─────────────────────────────────────
  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ── Sign Out ───────────────────────────────────────────
  static Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  // ── Delete Account ─────────────────────────────────────
  static Future<void> deleteAccount() => _auth.currentUser!.delete();

  // ── Error Helpers ──────────────────────────────────────
  static String friendlyError(dynamic e) {
    debugPrint('[AuthService] Error type: ${e.runtimeType}');
    if (e is FirebaseAuthException) {
      debugPrint('[AuthService] FirebaseAuthException — code: ${e.code} | message: ${e.message}');
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Try signing in.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect password. Please try again.';
        case 'requires-recent-login':
          return 'For security, please sign out and sign back in before deleting your account.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait and try again.';
        case 'network-request-failed':
          return 'No internet connection. Please check your network.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled. Please contact support.';
        case 'admin-restricted-operation':
          return 'Guest sign-in is not enabled. Please enable Anonymous Authentication in Firebase Console.';
        default:
          return e.message ?? 'Authentication error. Please try again.';
      }
    }
    if (e is FirebaseException) {
      debugPrint('[AuthService] FirebaseException — code: ${e.code} | message: ${e.message} | plugin: ${e.plugin}');
      switch (e.code) {
        case 'permission-denied':
          return 'Account created! Please log in to continue.';
        case 'unavailable':
          return 'Service temporarily unavailable. Please try again.';
        case 'not-found':
          return 'Data not found. Please try again.';
        default:
          return e.message ?? 'A Firebase error occurred. Please try again.';
      }
    }
    debugPrint('[AuthService] Unknown error: $e');
    return 'An unexpected error occurred. Please try again.';
  }
}
