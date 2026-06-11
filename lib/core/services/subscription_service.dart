import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

// ══════════════════════════════════════════════════════════════
//  SUBSCRIPTION SERVICE — RevenueCat Production Integration
//
//  RevenueCat is the SINGLE SOURCE OF TRUTH for all entitlements.
//  Firestore isPremium/planTier fields are only used for admin
//  grants (server-side). Never trust local flags alone.
//
//  ── Setup checklist ───────────────────────────────────────
//  1. Replace _kAndroidApiKey / _kIosApiKey with real RC keys
//  2. Create entitlements in RC dashboard:
//       lunar_plus     (attached to lunar_plus_monthly + annual)
//       lunar_premium  (attached to lunar_premium_monthly + annual)
//  3. Create a Default offering with 4 packages:
//       lunar_plus_monthly    $4.99/mo
//       lunar_plus_annual     $39.99/yr
//       lunar_premium_monthly $9.99/mo
//       lunar_premium_annual  $79.99/yr
//  4. Create products in Play Console / App Store Connect
//     using the product IDs above, then attach in RC.
// ══════════════════════════════════════════════════════════════

abstract final class SubscriptionService {
  // ── RevenueCat API Keys ─────────────────────────────────
  // TODO: Replace placeholders with real keys from dashboard.revenuecat.com
  static const _kAndroidApiKey = 'goog_REPLACE_WITH_YOUR_ANDROID_KEY';
  static const _kIosApiKey     = 'appl_REPLACE_WITH_YOUR_IOS_KEY';

  // ── RC Entitlement IDs — must match RC dashboard exactly ─
  static const kEntitlementPlus    = 'lunar_plus';
  static const kEntitlementPremium = 'lunar_premium';

  // ── RC Offering ID ─────────────────────────────────────
  static const kOfferingDefault = 'default';

  // ── Product IDs ────────────────────────────────────────
  static const kPlusMonthly      = 'lunar_plus_monthly';
  static const kPlusAnnual       = 'lunar_plus_annual';
  static const kPremiumMonthly   = 'lunar_premium_monthly';
  static const kPremiumAnnual    = 'lunar_premium_annual';

  // ── Pricing display strings ─────────────────────────────
  static const kPlusMonthlyPrice     = r'$4.99';
  static const kPlusAnnualPrice      = r'$39.99';
  static const kPremiumMonthlyPrice  = r'$9.99';
  static const kPremiumAnnualPrice   = r'$79.99';
  static const kPlusAnnualMonthly    = r'$3.33';  // ÷12
  static const kPremiumAnnualMonthly = r'$6.67';  // ÷12

  // ── Initialise RevenueCat ────────────────────────────────
  /// Call once from main() after Firebase.initializeApp().
  /// Safe to call multiple times — guards against double-init.
  static bool _initialised = false;
  static Future<void> init() async {
    if (_initialised) return;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint('[SubscriptionService] RC: unsupported platform — skipping.');
        return;
      }
      final apiKey = Platform.isAndroid ? _kAndroidApiKey : _kIosApiKey;
      final config = PurchasesConfiguration(apiKey)
        ..appUserID = null;   // anonymous until logIn() is called
      await Purchases.configure(config);
      if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);
      _initialised = true;
      debugPrint('[SubscriptionService] RevenueCat initialised.');
    } catch (e) {
      debugPrint('[SubscriptionService] RC init failed (non-fatal): $e');
    }
  }

  // ── User Identity ───────────────────────────────────────
  /// Link the RC anonymous user to the Firebase UID on sign-in.
  /// Must be called AFTER Firebase auth state is confirmed.
  static Future<void> logIn(String uid) async {
    if (!_initialised) return;
    try {
      final result = await Purchases.logIn(uid);
      debugPrint(
        '[SubscriptionService] RC logIn → uid: $uid | '
        'created: ${result.created} | '
        'tier: ${_tierFromCustomerInfo(result.customerInfo)}',
      );
    } catch (e) {
      debugPrint('[SubscriptionService] RC logIn failed (non-fatal): $e');
    }
  }

  /// Revert to anonymous RC user on sign-out.
  /// No-op for guest/anonymous sessions — RC does not allow logOut for anonymous users.
  static Future<void> logOut() async {
    if (!_initialised) return;
    try {
      final info = await Purchases.getCustomerInfo();
      // RC prohibits logOut() when already anonymous — skip it
      if (info.originalAppUserId.startsWith(r'$RCAnonymousID')) return;
      await Purchases.logOut();
      debugPrint('[SubscriptionService] RC logOut complete.');
    } catch (e) {
      debugPrint('[SubscriptionService] RC logOut failed (non-fatal): $e');
    }
  }

  // ── Purchase ─────────────────────────────────────────────
  /// Initiates a purchase for [productId].
  /// Returns a [SubscriptionPurchaseResult] with success/tier/error fields.
  static Future<SubscriptionPurchaseResult> purchase(String productId) async {
    if (!_initialised) {
      return const SubscriptionPurchaseResult(
        success: false,
        error: 'Store not available. Please try again.',
      );
    }
    try {
      final offerings = await Purchases.getOfferings();
      final offering =
          offerings.current ?? offerings.all[kOfferingDefault];
      if (offering == null) {
        return const SubscriptionPurchaseResult(
          success: false,
          error:
              'No plans available right now. Please check your connection.',
        );
      }
      final package = _findPackage(offering, productId);
      if (package == null) {
        return SubscriptionPurchaseResult(
          success: false,
          error: 'Plan not found: $productId. '
              'Please contact support if this persists.',
        );
      }
      final customerInfo =
          (await Purchases.purchase(PurchaseParams.package(package)))
              .customerInfo;
      final tier = _tierFromCustomerInfo(customerInfo);
      debugPrint('[SubscriptionService] purchase succeeded → tier: $tier');
      return SubscriptionPurchaseResult(success: true, tier: tier);
    } on PurchasesError catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError) {
        return const SubscriptionPurchaseResult(
            success: false, cancelled: true);
      }
      debugPrint('[SubscriptionService] purchase PurchasesError: ${e.code}');
      return SubscriptionPurchaseResult(
        success: false,
        error: _friendlyRcError(e.code),
      );
    } catch (e) {
      debugPrint('[SubscriptionService] purchase unknown error: $e');
      return const SubscriptionPurchaseResult(
        success: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  // ── Restore ──────────────────────────────────────────────
  /// Restores previous purchases (App Store / Play Store requirement).
  static Future<SubscriptionRestoreResult> restorePurchases() async {
    if (!_initialised) {
      return const SubscriptionRestoreResult(
        success: false,
        error: 'Store not available. Please try again.',
      );
    }
    try {
      final customerInfo = await Purchases.restorePurchases();
      final tier = _tierFromCustomerInfo(customerInfo);
      debugPrint('[SubscriptionService] restore → tier: $tier');
      return SubscriptionRestoreResult(
        success: true,
        tier: tier,
        hadPurchases: tier != PlanTier.free,
      );
    } on PurchasesError catch (e) {
      debugPrint('[SubscriptionService] restore PurchasesError: ${e.code}');
      return SubscriptionRestoreResult(
        success: false,
        error: _friendlyRcError(e.code),
      );
    } catch (e) {
      debugPrint('[SubscriptionService] restore unknown error: $e');
      return const SubscriptionRestoreResult(
        success: false,
        error: 'Could not restore purchases. Please check your connection.',
      );
    }
  }

  // ── Fetch current entitlements (foreground refresh) ──────
  /// Fetches the latest CustomerInfo from RC.
  /// Call on app foregrounding / after a network recovery.
  static Future<PlanTier> getCurrentTier() async {
    if (!_initialised) return PlanTier.free;
    try {
      final info = await Purchases.getCustomerInfo();
      return _tierFromCustomerInfo(info);
    } catch (e) {
      debugPrint('[SubscriptionService] getCurrentTier error: $e');
      return PlanTier.free; // fail-safe: default to free
    }
  }

  // ── Customer info listener ───────────────────────────────
  /// Registers a callback that fires whenever RC updates CustomerInfo.
  /// Fires after: purchase, restore, subscription expiry, grace period.
  /// Call once in main() before runApp() with a reference to PremiumProvider.
  static void addCustomerInfoListener(
      void Function(PlanTier tier) onUpdate) {
    if (!_initialised) return;
    Purchases.addCustomerInfoUpdateListener((info) {
      final tier = _tierFromCustomerInfo(info);
      debugPrint(
          '[SubscriptionService] customerInfo updated → tier: $tier');
      onUpdate(tier);
    });
  }

  // ── Admin helper (server-side / Firebase Functions only) ─
  static Future<void> adminGrantPremium({
    required String uid,
    required PlanTier tier,
    required DateTime expiresAt,
  }) async {
    await FirestoreService.updateUser(uid, {
      'isPremium': true,
      'planTier': tier.name,
      'premiumExpiresAt': expiresAt.toIso8601String(),
    });
    debugPrint(
        '[SubscriptionService] adminGrantPremium → $uid | tier: ${tier.name}');
  }

  // ── Helpers ──────────────────────────────────────────────
  /// Maps active RC entitlements to a PlanTier.
  /// Premium entitlement takes priority over Plus.
  static PlanTier _tierFromCustomerInfo(CustomerInfo info) {
    if (info.entitlements.active.containsKey(kEntitlementPremium)) {
      return PlanTier.premium;
    }
    if (info.entitlements.active.containsKey(kEntitlementPlus)) {
      return PlanTier.plus;
    }
    return PlanTier.free;
  }

  static Package? _findPackage(Offering offering, String productId) {
    for (final pkg in offering.availablePackages) {
      if (pkg.storeProduct.identifier == productId) return pkg;
    }
    return null;
  }

  static String _friendlyRcError(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.networkError:
        return 'No connection. Please check your network and try again.';
      case PurchasesErrorCode.storeProblemError:
        return 'The store is temporarily unavailable. Please try again later.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'This plan is not available in your region.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are not allowed on this device.';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'This subscription is already linked to another account. '
            'Use Restore Purchases below.';
      case PurchasesErrorCode.invalidCredentialsError:
        return 'Store credentials are invalid. Please sign out and try again.';
      case PurchasesErrorCode.insufficientPermissionsError:
        return 'You don\'t have permission to make purchases on this device.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static PlanTier tierForProductId(String productId) {
    if (productId.contains('premium')) return PlanTier.premium;
    if (productId.contains('plus')) return PlanTier.plus;
    return PlanTier.free;
  }

  static bool isAnnual(String productId) => productId.contains('annual');
}

// ── Typed result objects ────────────────────────────────────
// Named with 'Subscription' prefix to avoid collision with
// purchases_flutter's own PurchaseResult class.

class SubscriptionPurchaseResult {
  final bool success;
  final bool cancelled;
  final String? error;
  final PlanTier tier;

  const SubscriptionPurchaseResult({
    required this.success,
    this.cancelled = false,
    this.error,
    this.tier = PlanTier.free,
  });
}

class SubscriptionRestoreResult {
  final bool success;
  final bool hadPurchases;
  final String? error;
  final PlanTier tier;

  const SubscriptionRestoreResult({
    required this.success,
    this.hadPurchases = false,
    this.error,
    this.tier = PlanTier.free,
  });
}

