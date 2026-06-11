import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/premium_provider.dart';
import '../../core/services/subscription_service.dart';

// ══════════════════════════════════════════════════════════════
//  PAYWALL SCREEN
//  Shown as a modal sheet from PaywallGate.show().
//  Displays the three Lunar plans with feature comparison and
//  CTA buttons wired to SubscriptionService stubs.
// ══════════════════════════════════════════════════════════════

const _kBg     = Color(0xFF0A0118);
const _kPurple = Color(0xFFAB5CF2);
const _kPink   = Color(0xFFFF69B4);
const _kGold   = Color(0xFFFFD700);
const _kTeal   = Color(0xFF4FC3F7);
const _kDeep   = Color(0xFF5C2DB8);

// ── Outcome benefit lists — emotional, not feature-first ───
const List<(String, String, String)> _kPlusBenefits = [
  ('💜', 'Support whenever you need it', '100 AI conversations every day'),
  ('📓', 'Never lose your thoughts', 'Unlimited journals — capture everything'),
  ('🎙️', 'Speak your heart freely', 'Voice input — express yourself naturally'),
  ('📊', 'Track your emotional journey', '90 days of mood history & patterns'),
  ('🤰', 'Guided pregnancy care', 'Trimester tracking & milestone support'),
];

const List<(String, String, String)> _kPremiumBenefits = [
  ('✨', 'Always there — never limited', 'Unlimited AI conversations, every day'),
  ('🔊', 'Hear Lunar\'s guidance', 'Voice responses — feel truly heard'),
  ('📅', 'A full year of your story', '365 days of emotional history, always yours'),
  ('💡', 'Deep insights that grow with you', 'Analytics you can export and keep'),
  ('🌙', 'Predictive cycle wisdom', 'AI-powered insights, uniquely yours'),
];

// ── PaywallGate static helper ─────────────────────────────
class PaywallGate {
  PaywallGate._();

  /// Shows the paywall as a full-screen modal bottom sheet.
  /// [featureHint] is an optional phrase shown in the header:
  /// "Unlock Voice AI" / "Unlock Unlimited Journals" etc.
  static Future<void> show(
    BuildContext context, {
    String featureHint = 'Your full emotional companion',
  }) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (_) => _PaywallSheet(featureHint: featureHint),
    );
  }
}

// ── Sheet ─────────────────────────────────────────────────
class _PaywallSheet extends StatefulWidget {
  final String featureHint;
  const _PaywallSheet({required this.featureHint});
  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _slideAnim;
  late Animation<double> _glowAnim;

  // Selected plan tab: 0=monthly, 1=annual
  int _billingTab = 1; // default to annual (better value)
  // Selected plan to highlight: 1=Plus, 2=Premium
  int _selectedPlan = 2;
  bool _restoring = false;
  bool _purchasing = false;
  bool _tableExpanded = false;

  // Outcome-mapped headline from featureHint context
  (String, String) get _outcomeHeadline {
    final hint = widget.featureHint.toLowerCase();
    if (hint.contains('message') ||
        hint.contains('support') ||
        hint.contains('limit')) {
      return ('Support whenever\nyou need it',
          'Lunar is here — every day, every moment 💜');
    } else if (hint.contains('voice') || hint.contains('express')) {
      return ('Express yourself\nfreely',
          'Speak your heart — Lunar will listen 🎙️');
    } else if (hint.contains('journal') ||
        hint.contains('progress') ||
        hint.contains('lose')) {
      return ('Never lose your\nprogress',
          'Your story, preserved and always with you 🌙');
    } else if (hint.contains('insight') || hint.contains('analytic')) {
      return ('Understand yourself\nmore deeply',
          'Patterns, insights, guidance — uniquely yours ✨');
    } else if (hint.contains('cycle') || hint.contains('pregnan')) {
      return ('Guidance through\nevery phase',
          'From cycle to pregnancy — supported throughout 🌸');
    } else {
      return ('Your full\nemotional companion',
          'Go deeper with Lunar — understand yourself fully ✨');
    }
  }

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480))
      ..forward();
    _slideAnim = Tween<double>(begin: 80.0, end: 0.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Purchase logic ────────────────────────────────────────
  Future<void> _purchase() async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    HapticFeedback.mediumImpact();

    final productId = _productIdForSelection();
    final result = await SubscriptionService.purchase(productId);

    if (!mounted) return;
    setState(() => _purchasing = false);

    if (result.cancelled) return;

    if (result.success) {
      Navigator.pop(context);
      HapticFeedback.lightImpact();
      final isPrem = result.tier == PlanTier.premium;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPrem
                ? 'Welcome to Lunar Premium! You\'re fully supported ✨'
                : 'Welcome to Lunar Plus! Your deeper journey begins 🌙',
          ),
          backgroundColor: _kDeep,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Something went wrong.'),
          backgroundColor: const Color(0xFF3D1060),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _restore() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    HapticFeedback.lightImpact();

    final result = await SubscriptionService.restorePurchases();
    if (!mounted) return;
    setState(() => _restoring = false);

    if (result.success && result.hadPurchases) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.tier == PlanTier.premium
                ? 'Lunar Premium restored! Welcome back ✨'
                : 'Lunar Plus restored! Welcome back 🌙',
          ),
          backgroundColor: _kDeep,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (result.success && !result.hadPurchases) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No previous purchases found for this account.'),
          backgroundColor: _kDeep,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Could not restore purchases.'),
          backgroundColor: const Color(0xFF3D1060),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _productIdForSelection() {
    final isAnnual = _billingTab == 1;
    if (_selectedPlan == 2) {
      return isAnnual
          ? SubscriptionService.kPremiumAnnual
          : SubscriptionService.kPremiumMonthly;
    }
    return isAnnual
        ? SubscriptionService.kPlusAnnual
        : SubscriptionService.kPlusMonthly;
  }

  String _priceLabel(int plan) {
    final isAnnual = _billingTab == 1;
    if (plan == 1) {
      return isAnnual
          ? '${SubscriptionService.kPlusAnnualMonthly}/mo'
          : '${SubscriptionService.kPlusMonthlyPrice}/mo';
    }
    return isAnnual
        ? '${SubscriptionService.kPremiumAnnualMonthly}/mo'
        : '${SubscriptionService.kPremiumMonthlyPrice}/mo';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: DraggableScrollableSheet(
          initialChildSize: 0.93,
          minChildSize: 0.5,
          maxChildSize: 0.97,
          expand: false,
          builder: (_, scrollCtrl) => ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A0535),
                      _kBg,
                    ],
                  ),
                  border: Border(
                      top: BorderSide(
                          color: _kPurple.withOpacity(0.35), width: 1)),
                ),
                child: ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.zero,
                  children: [
                    _handle(),
                    _header(),
                    const SizedBox(height: 16),
                    _socialProof(),
                    const SizedBox(height: 20),
                    _billingToggle(),
                    const SizedBox(height: 20),
                    _planCards(),
                    const SizedBox(height: 22),
                    _benefitsList(),
                    const SizedBox(height: 20),
                    _trustBar(),
                    const SizedBox(height: 18),
                    _ctaButton(),
                    const SizedBox(height: 14),
                    _featureTableToggle(),
                    const SizedBox(height: 10),
                    _restoreRow(),
                    const SizedBox(height: 12),
                    _legalRow(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Handle ────────────────────────────────────────────────
  Widget _handle() => Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withOpacity(0.18),
            ),
          ),
        ),
      );

  // ── Header — outcome-focused ──────────────────────────────
  Widget _header() {
    final (headline, subline) = _outcomeHeadline;
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(children: [
          // Lunar Orb — brand identity, not a crown
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.22 * _glowAnim.value),
                  _kPurple.withOpacity(0.88),
                  _kDeep,
                ],
                stops: const [0.0, 0.45, 1.0],
                center: const Alignment(-0.25, -0.30),
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPurple.withOpacity(_glowAnim.value * 0.55),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: _kPink.withOpacity(_glowAnim.value * 0.25),
                  blurRadius: 18,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.18 * _glowAnim.value),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Text('🌙', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.20,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subline,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13.5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }

  // ── Social proof pill ─────────────────────────────────────
  Widget _socialProof() => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _kPurple.withOpacity(0.12),
            border: Border.all(
                color: _kPurple.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded,
                  color: _kPink.withOpacity(0.75), size: 13),
              const SizedBox(width: 6),
              Text(
                'Trusted by 50,000+ women on their wellness journey',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.60),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  // ── Billing toggle (monthly / annual) ─────────────────────
  Widget _billingToggle() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withOpacity(0.06),
          ),
          child: Row(children: [
            _tab('Pay monthly', 0),
            _tab('Best value  ·  Save 33% 💜', 1),
          ]),
        ),
      );

  Widget _tab(String label, int idx) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _billingTab = idx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: _billingTab == idx
                  ? LinearGradient(colors: [_kPurple, _kDeep])
                  : null,
              color: _billingTab != idx ? Colors.transparent : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: _billingTab == idx
                    ? Colors.white
                    : Colors.white.withOpacity(0.45),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );

  // ── Plan cards ────────────────────────────────────────────
  Widget _planCards() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          _planCard(
            plan: 0,
            title: 'Free',
            emoji: '🌱',
            price: 'Free',
            tagline: 'Begin your story',
            color: Colors.white.withOpacity(0.25),
          ),
          const SizedBox(width: 10),
          _planCard(
            plan: 1,
            title: 'Plus',
            emoji: '🌙',
            price: _priceLabel(1),
            tagline: 'Go deeper, anytime',
            color: _kTeal,
            badge: 'POPULAR',
          ),
          const SizedBox(width: 10),
          _planCard(
            plan: 2,
            title: 'Premium',
            emoji: '✨',
            price: _priceLabel(2),
            tagline: 'Your full companion',
            color: _kGold,
            badge: 'BEST VALUE',
          ),
        ]),
      );

  Widget _planCard({
    required int plan,
    required String title,
    required String emoji,
    required String price,
    required String tagline,
    required Color color,
    String? badge,
  }) {
    final selected = _selectedPlan == plan;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = plan),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                        color.withOpacity(0.28),
                        _kDeep.withOpacity(0.72),
                      ])
                : null,
            color: selected ? null : Colors.white.withOpacity(0.04),
            border: Border.all(
              color: selected
                  ? color.withOpacity(0.65)
                  : Colors.white.withOpacity(0.08),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(children: [
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: color.withOpacity(0.25),
                ),
                child: Text(badge,
                    style: TextStyle(
                        color: color,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
              )
            else
              const SizedBox(height: 17),
            const SizedBox(height: 6),
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(price,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(tagline,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 9),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  // ── Feature table — collapsible ───────────────────────────
  Widget _featureTableToggle() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            GestureDetector(
              onTap: () =>
                  setState(() => _tableExpanded = !_tableExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.04),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _tableExpanded
                          ? 'Hide full comparison'
                          : 'Compare all features',
                      style: TextStyle(
                          color: _kPurple.withOpacity(0.75),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _tableExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _kPurple.withOpacity(0.65),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (_tableExpanded) ...[
              const SizedBox(height: 14),
              _featureTable(),
            ],
          ],
        ),
      );

  // ── Feature comparison table ──────────────────────────────
  Widget _featureTable() {
    const rows = [
      ('Daily AI conversations', '20', '100', 'Unlimited'),
      ('Journal entries', '30 max', 'Unlimited', 'Unlimited'),
      ('Emotional history', '7 days', '90 days', '365 days'),
      ('Voice input', '✗', '✓', '✓'),
      ('Voice responses (TTS)', '✗', '✗', '✓'),
      ('Pregnancy tracking', '✗', '✓', '✓'),
      ('Emotional analytics', 'Basic', 'Full', 'Deep + Export'),
      ('Predictive cycle insights', '✗', '✗', '✓'),
      ('Community posts/day', '5', 'Unlimited', '+ Priority badge'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(
                  color: _kPurple.withOpacity(0.18), width: 1),
            ),
            child: Column(
              children: [
                _tableHeader(),
                const Divider(
                    height: 1, color: Color(0x18FFFFFF)),
                ...rows.map((r) => _tableRow(r.$1, r.$2, r.$3, r.$4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tableHeader() => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        child: Row(children: [
          const Expanded(child: SizedBox()),
          _colLabel('Free', Colors.white38),
          _colLabel('Plus 🌙', _kTeal),
          _colLabel('Prem ✨', _kGold),
        ]),
      );

  Widget _colLabel(String t, Color c) => SizedBox(
        width: 72,
        child: Text(t,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: c,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3)),
      );

  Widget _tableRow(
      String feature, String free, String plus, String prem) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(children: [
        Expanded(
          child: Text(feature,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12)),
        ),
        SizedBox(
          width: 72,
          child: Text(free,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11)),
        ),
        SizedBox(
          width: 72,
          child: Text(plus,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: plus == '✗'
                      ? Colors.white24
                      : _kTeal.withOpacity(0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          width: 72,
          child: Text(prem,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: prem == '✗'
                      ? Colors.white24
                      : _kGold.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  // ── CTA button ────────────────────────────────────────────
  Widget _ctaButton() {
    if (_selectedPlan == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.07),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            alignment: Alignment.center,
            child: const Text('Continue with Free',
                style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    final isPremiumPlan = _selectedPlan == 2;
    final ctaColor = isPremiumPlan ? _kGold : _kTeal;
    final ctaLabel = isPremiumPlan
        ? 'Start feeling fully supported ✨'
        : 'Start your deeper journey 🌙';
    final subLabel = _billingTab == 1
        ? (isPremiumPlan
            ? '${SubscriptionService.kPremiumAnnualPrice}/year · cancel anytime'
            : '${SubscriptionService.kPlusAnnualPrice}/year · cancel anytime')
        : (isPremiumPlan
            ? '${SubscriptionService.kPremiumMonthlyPrice}/month · cancel anytime'
            : '${SubscriptionService.kPlusMonthlyPrice}/month · cancel anytime');

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(
          onTap: _purchasing ? null : _purchase,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                  colors: isPremiumPlan
                      ? [
                          _kGold.withOpacity(0.85),
                          _kPurple,
                          _kDeep,
                        ]
                      : [
                          _kTeal.withOpacity(0.85),
                          _kPurple,
                          _kDeep,
                        ]),
              boxShadow: [
                BoxShadow(
                    color:
                        ctaColor.withOpacity(_glowAnim.value * 0.4),
                    blurRadius: 20,
                    spreadRadius: 2),
              ],
            ),
            alignment: Alignment.center,
            child: _purchasing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ctaLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16.5)),
                      const SizedBox(height: 4),
                      Text(subLabel,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Benefit bullets for selected plan ────────────────────
  Widget _benefitsList() {
    if (_selectedPlan == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s included with Free:',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.50),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3),
            ),
            const SizedBox(height: 12),
            _benefitRow('🌱', '20 daily conversations with Lunar', Colors.white),
            _benefitRow('📓', 'Up to 30 journal entries', Colors.white),
            _benefitRow('📊', '7 days of mood history', Colors.white),
          ],
        ),
      );
    }
    final benefits =
        _selectedPlan == 2 ? _kPremiumBenefits : _kPlusBenefits;
    final accentColor = _selectedPlan == 2 ? _kGold : _kTeal;
    final planLabel = _selectedPlan == 2 ? 'Premium' : 'Plus';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Lunar $planLabel gives you:',
            style: TextStyle(
                color: accentColor.withOpacity(0.75),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 14),
          ...benefits.map(
              (b) => _benefitRow(b.$1, '${b.$2} — ${b.$3}', accentColor)),
        ],
      ),
    );
  }

  Widget _benefitRow(String emoji, String label, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.10),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 15)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 13,
                        height: 1.3)),
              ),
            ),
          ],
        ),
      );

  // ── Trust bar ─────────────────────────────────────────────
  Widget _trustBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(
                color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _trustItem(Icons.lock_outline_rounded, 'Private'),
              _trustDivider(),
              _trustItem(Icons.cancel_outlined, 'Cancel anytime'),
              _trustDivider(),
              _trustItem(Icons.verified_user_outlined, 'Secure'),
            ],
          ),
        ),
      );

  Widget _trustItem(IconData icon, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.35), size: 16),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.40),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      );

  Widget _trustDivider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withOpacity(0.08),
      );

  // ── Restore row ───────────────────────────────────────────
  Widget _restoreRow() => Center(
        child: GestureDetector(
          onTap: _restoring ? null : _restore,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _restoring
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPurple),
                  )
                : Column(
                    children: [
                      Text('Already subscribed?',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.32),
                              fontSize: 11)),
                      const SizedBox(height: 2),
                      Text('Restore Purchases',
                          style: TextStyle(
                              color: _kPurple.withOpacity(0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
      );

  // ── Legal row ─────────────────────────────────────────────
  Widget _legalRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          'Subscriptions renew automatically. Cancel any time in your device settings — '
          'no questions asked. By subscribing you agree to our Terms of Service and Privacy Policy. '
          'Your emotional data stays private and is never sold.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.28),
              fontSize: 10,
              height: 1.55),
          textAlign: TextAlign.center,
        ),
      );
}
