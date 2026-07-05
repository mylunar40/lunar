import 'package:flutter/foundation.dart';
import '../data/local_cache.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

// ══════════════════════════════════════════════════════════════
//  PREMIUM PROVIDER — Centralized Entitlement Engine
//
//  Source-of-truth priority (highest → lowest):
//    1. RevenueCat entitlements  (live store validation)
//    2. Firestore admin grant    (server-side override)
//    3. Free tier               (default / fail-safe)
//
//  RevenueCat calls updateFromRevenueCat() directly via the
//  listener wired in main.dart. Firestore data calls
//  updateFromAuth() via ChangeNotifierProxyProvider.
//  Both paths are combined by _effectiveTier.
//
//  ─── Subscription Tiers ───────────────────────────────────
//
//  FREE
//  • 20 AI messages / day
//  • 30 journal entries (total stored)
//  • 7 days mood history shown
//  • Community: read + post (max 5/day)
//  • Basic cycle tracking
//  • No voice AI recording
//  • No pregnancy tracking
//  • Basic emotional insights only
//
//  LUNAR PLUS  ($4.99/mo · $39.99/yr)
//  • 100 AI messages / day
//  • Unlimited journal entries
//  • 90 days mood history
//  • Community: unlimited posts + reply reactions
//  • Voice AI input (speech-to-text to AI)
//  • Pregnancy tracking
//  • Full emotional insights + cycle correlation
//  • Avatar customisation
//
//  LUNAR PREMIUM  ($9.99/mo · $79.99/yr)
//  • Unlimited AI messages
//  • Unlimited journal entries
//  • Full history (365+ days)
//  • Community: premium badge + priority visibility
//  • Full voice AI (TTS responses + STT input)
//  • Full pregnancy monitoring
//  • Deep emotional analytics (PDF export)
//  • Predictive cycle insights (AI-powered)
//  • Priority AI response time
// ══════════════════════════════════════════════════════════════

class PremiumProvider extends ChangeNotifier {
  // ── LocalCache key — fast-restore before RC/Firestore loads ──
  static const _kTierKey = 'lunar_premium_tier_v1';

  // ── Plan limits ───────────────────────────────────────────
  static const int freeAiDailyLimit     = 20;
  static const int plusAiDailyLimit     = 100;
  static const int premiumAiDailyLimit  = 999999; // effectively unlimited

  static const int freeJournalLimit     = 30;   // total stored entries
  static const int plusJournalLimit     = 999999;
  static const int premiumJournalLimit  = 999999;

  static const int freeMoodHistoryDays    = 7;
  static const int plusMoodHistoryDays    = 90;
  static const int premiumMoodHistoryDays = 365;

  static const int freeCommunityPostsPerDay = 5;
  static const int plusCommunityPostsPerDay = 999999;

  // ── Dual-source tier tracking ─────────────────────────────
  // RC entitlements (live store validation — highest priority)
  PlanTier _rcTier        = PlanTier.free;
  // Firestore admin grants (server-side override)
  PlanTier _firestoreTier = PlanTier.free;

  // ── Constructor — pre-warm from LocalCache ────────────────
  // Reads the last-known tier from SharedPreferences so there's
  // no "free flash" while RC or Firestore loads on startup.
  PremiumProvider() {
    final cached = LocalCache.getString(_kTierKey);
    if (cached != null) {
      final t = PlanTier.values.firstWhere(
        (e) => e.name == cached,
        orElse: () => PlanTier.free,
      );
      if (t != PlanTier.free) {
        _rcTier = t; // temporary pre-warm — RC will confirm/override
        debugPrint('[PremiumProvider] Pre-warmed from cache → $t');
      }
    }
  }

  // Computed effective tier: always take the highest granted tier
  PlanTier get _effectiveTier {
    if (_rcTier == PlanTier.premium ||
        _firestoreTier == PlanTier.premium) {
      return PlanTier.premium;
    }
    if (_rcTier == PlanTier.plus || _firestoreTier == PlanTier.plus) {
      return PlanTier.plus;
    }
    return PlanTier.free;
  }

  // ── Getters — Plan ────────────────────────────────────────
  PlanTier get tier    => _effectiveTier;
  bool get isFree      => _effectiveTier == PlanTier.free;
  bool get isPlus      => _effectiveTier == PlanTier.plus;
  bool get isPremium   => _effectiveTier == PlanTier.premium;
  bool get isPaid      => _effectiveTier != PlanTier.free;

  String get planName {
    switch (_effectiveTier) {
      case PlanTier.premium: return 'Lunar Premium';
      case PlanTier.plus:    return 'Lunar Plus';
      case PlanTier.free:    return 'Free';
    }
  }

  String get planEmoji {
    switch (_effectiveTier) {
      case PlanTier.premium: return '✨';
      case PlanTier.plus:    return '🌙';
      case PlanTier.free:    return '🌱';
    }
  }

  // ── Getters — Feature gates ───────────────────────────────
  int get aiDailyLimit => _effectiveTier == PlanTier.premium
      ? premiumAiDailyLimit
      : _effectiveTier == PlanTier.plus
          ? plusAiDailyLimit
          : freeAiDailyLimit;

  int get journalLimit => isFree ? freeJournalLimit : 999999;
  int get moodHistoryDays => _effectiveTier == PlanTier.premium
      ? premiumMoodHistoryDays
      : _effectiveTier == PlanTier.plus
          ? plusMoodHistoryDays
          : freeMoodHistoryDays;

  bool get canUseVoiceInput    => !isFree;   // Plus + Premium
  bool get canUseTtsResponse   => isPremium; // Premium only
  bool get canAccessPregnancy  => !isFree;   // Plus + Premium
  bool get canExportData       => isPremium; // Premium only
  bool get canUsePredictive    => isPremium; // Premium only
  bool get hasPremiumBadge     => isPremium; // Premium only
  bool get hasFullAnalytics    => !isFree;   // Plus + Premium

  // ── Module-specific gates — ONE check per feature ─────────
  // All modules MUST use these. Never check isPaid/isPremium directly.
  bool get canAccessAiThemes            => isPaid;     // Plus + Premium
  bool get canAccessCommunityThemes     => isPaid;     // Plus + Premium
  bool get canAccessPremiumThemes       => isPaid;     // AI + Community themes
  bool get canAccessProfilePremium      => isPaid;     // Avatar frame, accents
  bool get canAccessCommunityBadge      => isPremium;  // Premium only
  bool get canAccessCommunityPremiumChat => isPremium; // Premium only
  bool get canAccessPregnancyPremium    => !isFree;    // Plus + Premium
  bool get canAccessJournalPremium      => !isFree;    // Plus + Premium
  bool get canAccessMoodPremium         => !isFree;    // Plus + Premium
  bool get canAccessSleepPremium        => !isFree;    // Plus + Premium
  bool get canAccessLongMemory          => isPremium;  // Premium only

  int get communityPostsPerDay => isFree
      ? freeCommunityPostsPerDay
      : plusCommunityPostsPerDay;

  // ── RC sync — called by SubscriptionService listener ─────
  /// Called from the RevenueCat CustomerInfo listener in main.dart.
  /// Fires after every purchase, restore, expiry, or grace-period change.
  void updateFromRevenueCat(PlanTier tier) {
    if (_rcTier == tier) return; // no change — skip rebuild
    _rcTier = tier;
    LocalCache.setString(_kTierKey, _effectiveTier.name); // persist
    debugPrint('[PremiumProvider] RC tier → $_rcTier | effective: $_effectiveTier');
    notifyListeners();
  }

  // ── Firestore sync — called by ChangeNotifierProxyProvider ─
  /// Called whenever LunarAuthProvider notifies (Firestore user model updated).
  /// Only propagates Firestore admin-granted premiums, NOT store purchases.
  void updateFromAuth(LunarAuthProvider auth) {
    final model = auth.userModel;
    final newFirestoreTier = (model != null && model.isActivePremium)
        ? model.planTier
        : PlanTier.free;
    if (_firestoreTier == newFirestoreTier) return; // no change
    _firestoreTier = newFirestoreTier;
    LocalCache.setString(_kTierKey, _effectiveTier.name); // persist
    debugPrint(
        '[PremiumProvider] Firestore tier → $_firestoreTier | effective: $_effectiveTier');
    notifyListeners();
  }

  // ── Reset on sign-out ─────────────────────────────────────
  /// Clears both tier sources. Called from signOut flow.
  void reset() {
    _rcTier = PlanTier.free;
    _firestoreTier = PlanTier.free;
    LocalCache.setString(_kTierKey, PlanTier.free.name); // clear cache on sign-out
    notifyListeners();
  }

  /// Check a journal limit — returns true when the user can add more entries.
  bool canAddJournalEntry(int currentCount) {
    if (!isFree) return true;
    return currentCount < freeJournalLimit;
  }
}
