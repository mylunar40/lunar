import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/user_intent.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/fcm_service.dart';
import '../services/subscription_service.dart';
import '../../user_provider.dart';

/// Authentication + user state manager.
/// Exposes auth state to the entire widget tree via Provider.
class LunarAuthProvider extends ChangeNotifier {
  User? _firebaseUser;
  LunarUserModel? _userModel;
  bool _isLoading = true;
  bool _firebaseAvailable = true;
  String? _error;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<LunarUserModel?>? _userSub;

  // ── Public Getters ──────────────────────────────────────
  User? get firebaseUser => _firebaseUser;
  LunarUserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get firebaseAvailable => _firebaseAvailable;
  String? get error => _error;

  /// True only when a real Firebase user is signed in.
  bool get isAuthenticated => _firebaseUser != null;

  /// True when Firebase could not be initialised (offline / demo mode).
  bool get isDemoMode => !_firebaseAvailable;

  bool get isGuest => _firebaseUser?.isAnonymous ?? false;

  /// True when the signed-in email account has been verified.
  /// Google / Apple accounts always return true.
  /// Anonymous (guest) users always return false — use [isGuest] to distinguish.
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;

  /// True when the user has an active, non-expired premium subscription.
  bool get isActivePremium => _userModel?.isActivePremium ?? false;

  String get displayName =>
      _userModel?.name ??
      _firebaseUser?.displayName ??
      (_firebaseUser?.isAnonymous == true ? 'Guest' : 'Lunar User');

  String? get photoUrl =>
      _userModel?.photoUrl ?? _firebaseUser?.photoURL;

  /// The user's parsed journey intent. Null if not yet selected.
  UserIntent? get userIntent => UserIntent.fromString(_userModel?.userIntent);

  /// True when the user has completed the intent onboarding flow.
  bool get hasCompletedIntentOnboarding =>
      _userModel?.onboardingIntentCompleted ?? false;

  // ── Init ────────────────────────────────────────────────
  LunarAuthProvider() {
    _init();
  }

  void _init() {
    try {
      _authSub = AuthService.authStateChanges.listen(
        _onAuthChanged,
        onError: (e) {
          debugPrint('[LunarAuth] Auth stream error: $e');
          _firebaseAvailable = false;
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[LunarAuth] Firebase unavailable: $e');
      _firebaseAvailable = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    _error = null;

    if (user != null && !user.isAnonymous) {
      await _fetchUserModel(user.uid);
      // Register FCM token for push notifications (best-effort)
      FCMService.registerToken(user.uid)
          .catchError((e) => debugPrint('[LunarAuth] FCM token error: $e'));
      // Identify user in RevenueCat so purchases are linked to their account
      await SubscriptionService.logIn(user.uid);
    } else {
      _userModel = null;
      _userSub?.cancel();
      // Revert RC to anonymous user on sign-out / guest sign-in
      await SubscriptionService.logOut();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchUserModel(String uid) async {
    try {
      _userSub?.cancel();
      _userSub = FirestoreService.userStream(uid).listen(
        (model) {
          _userModel = model;
          notifyListeners();
        },
        onError: (e) => debugPrint('[LunarAuth] User stream error: $e'),
      );
    } catch (e) {
      debugPrint('[LunarAuth] Firestore error: $e');
    }
  }

  // ── Sign Up ─────────────────────────────────────────────
  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    UserProvider? userProvider,
  }) async {
    _setLoading(true);
    try {
      debugPrint('[LunarAuth] signUpWithEmail — attempting for $email');
      final cred = await AuthService.signUpWithEmail(
        email: email,
        password: password,
        displayName: name,
      );
      debugPrint('[LunarAuth] Firebase Auth user created: ${cred.user?.uid}');
      // Firestore profile creation is best-effort: auth success is enough to
      // proceed. A failure here (e.g. missing security rules) must NOT block
      // the user from entering the app.
      if (cred.user != null) {
        try {
          final model = LunarUserModel(
            uid: cred.user!.uid,
            name: name,
            email: email,
            authProvider: 'email',
            isAnonymous: false,
            cycleLength: 28,
            lastPeriodDate: userProvider?.lastPeriodDate,
            createdAt: DateTime.now(),
          );
          await FirestoreService.createUser(model);
          debugPrint('[LunarAuth] Firestore user document created.');
        } catch (firestoreErr) {
          debugPrint('[LunarAuth] Firestore createUser failed (non-blocking): $firestoreErr');
        }
        // Send email verification (best-effort — does not block sign-in)
        try {
          await cred.user!.sendEmailVerification();
          debugPrint('[LunarAuth] Verification email sent to $email');
        } catch (verifyErr) {
          debugPrint('[LunarAuth] sendEmailVerification failed (non-blocking): $verifyErr');
        }
      }
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('[LunarAuth] signUpWithEmail failed: $e');
      _error = AuthService.friendlyError(e);
      _setLoading(false);
      return false;
    }
  }

  // ── Sign In ─────────────────────────────────────────────
  Future<bool> signInWithEmail({
    required String email,
    required String password,
    UserProvider? userProvider,
  }) async {
    _setLoading(true);
    try {
      await AuthService.signInWithEmail(email: email, password: password);
      if (userProvider != null && _userModel?.lastPeriodDate != null) {
        userProvider.updatePeriodDate(_userModel!.lastPeriodDate!);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _error = AuthService.friendlyError(e);
      _setLoading(false);
      return false;
    }
  }

  // ── Google ──────────────────────────────────────────────
  Future<bool> signInWithGoogle({UserProvider? userProvider}) async {
    _setLoading(true);
    try {
      final cred = await AuthService.signInWithGoogle();
      if (cred == null) {
        _setLoading(false);
        return false;
      }
      // Create Firestore document if new user
      if (cred.additionalUserInfo?.isNewUser == true && cred.user != null) {
        final model = LunarUserModel(
          uid: cred.user!.uid,
          name: cred.user!.displayName,
          email: cred.user!.email,
          photoUrl: cred.user!.photoURL,
          authProvider: 'google',
          createdAt: DateTime.now(),
        );
        await FirestoreService.createUser(model);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _error = AuthService.friendlyError(e);
      _setLoading(false);
      return false;
    }
  }

  // ── Guest ───────────────────────────────────────────────
  Future<bool> signInAsGuest() async {
    _setLoading(true);
    try {
      await AuthService.signInAsGuest();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = AuthService.friendlyError(e);
      _setLoading(false);
      return false;
    }
  }

  // ── Password Reset ──────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _error = null;
    try {
      await AuthService.sendPasswordReset(email);
      return true;
    } catch (e) {
      _error = AuthService.friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Email Verification ──────────────────────────────────

  /// Resend the verification email. Call from EmailVerificationScreen.
  Future<bool> sendEmailVerification() async {
    try {
      await _firebaseUser?.sendEmailVerification();
      return true;
    } catch (e) {
      debugPrint('[LunarAuth] sendEmailVerification error: $e');
      _error = 'Could not send verification email. Try again later.';
      notifyListeners();
      return false;
    }
  }

  /// Reload Firebase Auth user to pick up fresh emailVerified status.
  /// Call when the user taps "I've verified" on the verification screen.
  Future<void> reloadUser() async {
    try {
      await _firebaseUser?.reload();
      _firebaseUser = AuthService.currentUser;
      notifyListeners();
    } catch (e) {
      debugPrint('[LunarAuth] reloadUser error: $e');
    }
  }

  // ── Sign Out ─────────────────────────────────────────────
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await AuthService.signOut();
    } catch (e) {
      debugPrint('[LunarAuth] Sign out error: $e');
    }
    _setLoading(false);
  }

  // ── Delete Account (GDPR) ───────────────────────────────
  /// Permanently removes the Firebase Auth account THEN purges all
  /// Firestore documents for the user.
  ///
  /// ORDER MATTERS: Auth is deleted first so that if it throws
  /// `requires-recent-login`, Firestore data is never touched and
  /// no irrecoverable data loss occurs.
  ///
  /// Returns true on success, false on failure (with [error] set).
  Future<bool> deleteAccount() async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return false;
    _setLoading(true);
    try {
      // Step 1: Delete the Firebase Auth account.
      // This may throw 'requires-recent-login' — if so, Firestore is untouched.
      await AuthService.deleteAccount();
      debugPrint('[LunarAuth] Firebase Auth account deleted for $uid');

      // Step 2: Best-effort Firestore purge.
      // User is now unauthenticated; security rules may deny sub-collection
      // deletes. Orphaned data is cleaned by a scheduled Cloud Function.
      try {
        await FirestoreService.deleteUserData(uid);
        debugPrint('[LunarAuth] Firestore user data deleted for $uid');
      } catch (firestoreErr) {
        debugPrint('[LunarAuth] Firestore cleanup incomplete (non-fatal): $firestoreErr');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('[LunarAuth] deleteAccount failed: $e');
      _error = AuthService.friendlyError(e);
      _setLoading(false);
      return false;
    }
  }

  // ── Intent Onboarding ────────────────────────────────────
  /// Saves the selected journey intent and marks onboarding complete.
  Future<void> setUserIntent(UserIntent intent) async {
    final uid = _firebaseUser?.uid;
    if (uid == null || isGuest) return;
    try {
      await FirestoreService.updateUser(uid, {
        'userIntent': intent.firestoreValue,
        'intentSelectedAt': Timestamp.fromDate(DateTime.now()),
        'onboardingIntentCompleted': true,
      });
    } catch (e) {
      debugPrint('[LunarAuth] setUserIntent error: $e');
    }
  }

  // ── Cloud Sync ──────────────────────────────────────────
  /// Push local UserProvider data to Firestore.
  Future<void> syncToCloud(UserProvider userProvider) async {
    final uid = _firebaseUser?.uid;
    if (uid == null || isGuest) return;
    try {
      await FirestoreService.syncLocalData(
        uid: uid,
        lastPeriodDate: userProvider.lastPeriodDate,
        cycleLength: 28,
      );
    } catch (e) {
      debugPrint('[LunarAuth] Sync error: $e');
    }
  }

  /// Pull Firestore data into local UserProvider.
  void syncToUserProvider(UserProvider userProvider) {
    if (_userModel?.lastPeriodDate != null) {
      userProvider.updatePeriodDate(_userModel!.lastPeriodDate!);
    }
  }

  // ── Helpers ─────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
