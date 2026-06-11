import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/premium_provider.dart';
import '../screen/paywall/paywall_screen.dart';

// ══════════════════════════════════════════════════════════════
//  PREMIUM GATE
//
//  A transparent wrapper that overlays a lock UI on top of
//  any widget when the current plan doesn't allow the feature.
//
//  Usage (widget wrapping):
//    PremiumGate(
//      locked: !premium.canUseVoiceInput,
//      featureHint: 'Unlock Voice AI',
//      child: YourWidget(),
//    )
//
//  Usage (action gating — callback pattern):
//    PremiumGate.check(
//      context,
//      locked: !premium.canUseVoiceInput,
//      featureHint: 'Unlock Voice AI',
//      onAllowed: () => _startRecording(),
//    )
// ══════════════════════════════════════════════════════════════

class PremiumGate extends StatelessWidget {
  final bool locked;
  final String featureHint;
  final Widget child;
  final double? lockedOpacity;

  const PremiumGate({
    super.key,
    required this.locked,
    required this.featureHint,
    required this.child,
    this.lockedOpacity = 0.38,
  });

  /// Convenience method for action gating (no widget wrapping needed).
  /// If [locked], shows the paywall. Otherwise calls [onAllowed].
  static void check(
    BuildContext context, {
    required bool locked,
    required String featureHint,
    required VoidCallback onAllowed,
  }) {
    if (!locked) {
      onAllowed();
      return;
    }
    PaywallGate.show(context, featureHint: featureHint);
  }

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    return Stack(
      children: [
        // Dimmed underlying widget
        Opacity(opacity: lockedOpacity ?? 0.38, child: child),
        // Lock overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () =>
                PaywallGate.show(context, featureHint: featureHint),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter:
                    ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.black.withOpacity(0.25),
                    border: Border.all(
                        color: const Color(0xFFAB5CF2)
                            .withOpacity(0.25),
                        width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFAB5CF2)
                              .withOpacity(0.18),
                          border: Border.all(
                              color: const Color(0xFFAB5CF2)
                                  .withOpacity(0.4),
                              width: 1.2),
                        ),
                        child: const Icon(
                            Icons.lock_rounded,
                            color: Color(0xFFAB5CF2),
                            size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        featureHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to unlock with Lunar Plus ✨',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  AI USAGE INDICATOR
//  Small pill shown near the AI send button / header showing
//  remaining daily messages for free-tier users.
// ══════════════════════════════════════════════════════════════

class AiUsageIndicator extends StatelessWidget {
  /// Current count of AI messages sent today.
  final int usedToday;

  /// Whether the indicator should be hidden (premium users).
  final bool hidden;

  const AiUsageIndicator({
    super.key,
    required this.usedToday,
    this.hidden = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hidden) return const SizedBox.shrink();
    final premium = context.watch<PremiumProvider>();
    final limit = premium.aiDailyLimit;
    final remaining = (limit - usedToday).clamp(0, limit);
    final pct = (remaining / limit).clamp(0.0, 1.0);
    final Color barColor = pct > 0.4
        ? const Color(0xFF66BB6A)
        : pct > 0.15
            ? const Color(0xFFFFB74D)
            : const Color(0xFFEF5350);

    return GestureDetector(
      onTap: () => PaywallGate.show(context,
          featureHint: 'Support whenever you need it'),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(
              color: barColor.withOpacity(0.3), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bolt_rounded, color: barColor, size: 13),
          const SizedBox(width: 4),
          Text('$remaining left',
              style: TextStyle(
                  color: barColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
