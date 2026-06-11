// ─────────────────────────────────────────────────────────────────────────────
//  COMMUNITY PROFILE SCREEN
//  Shows a community member's profile with healing connection actions.
//  Features: connection request · accept/reject · disconnect · block
//  Eligibility: Premium + Email verified + Account ≥ 7 days
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/connection_provider.dart';
import '../models/connection_model.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const Color _kBg     = Color(0xFF0A0118);
const Color _kSurf   = Color(0xFF160330);
const Color _kPurple = Color(0xFFAB5CF2);
const Color _kPink   = Color(0xFFFF69B4);
const Color _kGold   = Color(0xFFFFD700);
const Color _kGreen  = Color(0xFF66BB6A);
const Color _kRed    = Color(0xFFEF5350);

// ─────────────────────────────────────────────────────────────────────────────

class CommunityProfileScreen extends StatefulWidget {
  /// The uid of the community member being viewed.
  final String targetUid;
  final String pseudonym;
  final String avatarEmoji;
  final String avatarColorHex;

  /// Whether the target is a premium member (sourced from post metadata).
  final bool isPremium;

  /// Whether the target has a verified account.
  final bool isVerified;

  const CommunityProfileScreen({
    super.key,
    required this.targetUid,
    required this.pseudonym,
    required this.avatarEmoji,
    required this.avatarColorHex,
    this.isPremium = false,
    this.isVerified = false,
  });

  static Route<void> route({
    required String targetUid,
    required String pseudonym,
    required String avatarEmoji,
    required String avatarColorHex,
    bool isPremium = false,
    bool isVerified = false,
  }) {
    return MaterialPageRoute(
      builder: (_) => CommunityProfileScreen(
        targetUid:      targetUid,
        pseudonym:      pseudonym,
        avatarEmoji:    avatarEmoji,
        avatarColorHex: avatarColorHex,
        isPremium:      isPremium,
        isVerified:     isVerified,
      ),
    );
  }

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen>
    with SingleTickerProviderStateMixin {
  ConnectionStatus _status = ConnectionStatus.none;
  String? _incomingRequestId;
  bool _statusLoading = true;
  bool _actionLoading = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadStatus();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final cp = context.read<ConnectionProvider>();
    final incoming = cp.incomingFrom(widget.targetUid);
    final status = await cp.getConnectionStatus(widget.targetUid);
    if (!mounted) return;
    setState(() {
      _status = status;
      _incomingRequestId = incoming?.id;
      _statusLoading = false;
    });
  }

  // ── Eligibility ────────────────────────────────────────────────────────────

  bool _isEligible(LunarAuthProvider auth) {
    if (!auth.isAuthenticated || auth.isGuest) return false;
    if (!auth.isActivePremium) return false;
    if (!auth.isEmailVerified) return false;
    final createdAt = auth.userModel?.createdAt;
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt).inDays >= 7;
  }

  String? _eligibilityMessage(LunarAuthProvider auth) {
    if (!auth.isAuthenticated || auth.isGuest) return 'Sign in to connect.';
    if (!auth.isActivePremium) return 'Upgrade to Lunar Premium to send healing connections.';
    if (!auth.isEmailVerified) return 'Verify your email to send healing connections.';
    final createdAt = auth.userModel?.createdAt;
    if (createdAt == null) return 'Account not ready.';
    final daysOld = DateTime.now().difference(createdAt).inDays;
    if (daysOld < 7) {
      final remaining = 7 - daysOld;
      return 'Your account needs to be $remaining more day${remaining == 1 ? '' : 's'} old to connect.';
    }
    return null;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _sendRequest(LunarAuthProvider auth) async {
    setState(() => _actionLoading = true);
    final cp = context.read<ConnectionProvider>();
    final myPseudonym = auth.userModel?.name ?? 'Lunar Member';
    final err = await cp.sendRequest(
      toUid:              widget.targetUid,
      fromPseudonym:      myPseudonym,
      fromAvatarEmoji:    '🌙',
      fromAvatarColorHex: 'AB5CF2',
      toPseudonym:        widget.pseudonym,
    );
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (err == null) {
      setState(() => _status = ConnectionStatus.pendingSent);
      _showSnack('Healing request sent 💜');
    } else {
      _showSnack(err, isError: true);
    }
  }

  Future<void> _acceptRequest() async {
    if (_incomingRequestId == null) return;
    setState(() => _actionLoading = true);
    final err = await context.read<ConnectionProvider>().acceptRequest(_incomingRequestId!);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (err == null) {
      setState(() => _status = ConnectionStatus.connected);
      _showSnack('Connected 💜 Healing together.');
    } else {
      _showSnack(err, isError: true);
    }
  }

  Future<void> _rejectRequest() async {
    if (_incomingRequestId == null) return;
    setState(() => _actionLoading = true);
    final err = await context.read<ConnectionProvider>().rejectRequest(_incomingRequestId!);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (err == null) {
      setState(() => _status = ConnectionStatus.none);
      _showSnack('Request declined.');
    } else {
      _showSnack(err, isError: true);
    }
  }

  Future<void> _disconnect() async {
    final confirm = await _showConfirmDialog(
        title:   'Disconnect?',
        message: 'You will no longer be healing connections with ${widget.pseudonym}.',
        confirm: 'Disconnect');
    if (confirm != true || !mounted) return;
    setState(() => _actionLoading = true);
    final err = await context.read<ConnectionProvider>().disconnect(widget.targetUid);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (err == null) {
      setState(() => _status = ConnectionStatus.none);
      _showSnack('Disconnected.');
    } else {
      _showSnack(err, isError: true);
    }
  }

  Future<void> _block() async {
    final confirm = await _showConfirmDialog(
        title:   'Block ${widget.pseudonym}?',
        message: 'They won\'t be able to send you requests. You won\'t see their posts in your feed.',
        confirm: 'Block',
        isDestructive: true);
    if (confirm != true || !mounted) return;
    setState(() => _actionLoading = true);
    final err = await context.read<ConnectionProvider>().blockUser(widget.targetUid);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (err == null) {
      setState(() => _status = ConnectionStatus.blocked);
      _showSnack('User blocked.');
    } else {
      _showSnack(err, isError: true);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _kRed : _kPurple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirm,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(message,
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirm,
                style: TextStyle(color: isDestructive ? _kRed : _kPurple,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<LunarAuthProvider>();
    final avatarColor = _hexToColor(widget.avatarColorHex);
    final eligible = _isEligible(auth);
    final ineligibleMsg = _eligibilityMessage(auth);

    return Scaffold(
      backgroundColor: _kBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kSurf.withOpacity(0.8),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        actions: [
          if (_status != ConnectionStatus.blocked)
            GestureDetector(
              onTap: () => _showMoreOptions(),
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kSurf.withOpacity(0.8),
                ),
                child: Icon(Icons.more_horiz_rounded,
                    color: Colors.white.withOpacity(0.7), size: 20),
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header(avatarColor)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                const SizedBox(height: 24),
                // ── Connection action area ──────────────────────────────
                _buildConnectionSection(auth, eligible, ineligibleMsg),
                const SizedBox(height: 32),
                // ── Info card ──────────────────────────────────────────
                _infoCard(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(Color avatarColor) {
    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    avatarColor.withOpacity(0.35),
                    _kBg,
                  ],
                ),
              ),
            ),
          ),
          // Blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: const SizedBox.shrink(),
            ),
          ),
          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Avatar
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: _pulse.value,
                    child: child,
                  ),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        avatarColor.withOpacity(0.9),
                        avatarColor.withOpacity(0.3),
                      ]),
                      border: Border.all(color: avatarColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                            color: avatarColor.withOpacity(0.5),
                            blurRadius: 24,
                            spreadRadius: 4),
                      ],
                    ),
                    child: Center(
                      child: Text(widget.avatarEmoji,
                          style: const TextStyle(fontSize: 44)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Name + badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.pseudonym,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5),
                    ),
                    if (widget.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF4FC3F7), size: 20),
                    ],
                    if (widget.isPremium) ...[
                      const SizedBox(width: 6),
                      _badge('💜 Premium', _kPurple),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Community Member',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 13),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSection(
      LunarAuthProvider auth, bool eligible, String? ineligibleMsg) {
    if (_statusLoading) {
      return const Center(
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPurple)));
    }

    if (_status == ConnectionStatus.blocked) {
      return _glassCard(
        child: Column(children: [
          Icon(Icons.block_rounded, color: _kRed.withOpacity(0.8), size: 36),
          const SizedBox(height: 12),
          const Text('User Blocked',
              style: TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('You have blocked this member.',
              style: TextStyle(color: Colors.white.withOpacity(0.45),
                  fontSize: 13)),
        ]),
      );
    }

    return Column(children: [
      if (_status == ConnectionStatus.pendingReceived) ...[
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _kPurple.withOpacity(0.8),
                        _kPurple.withOpacity(0.2),
                      ])),
                  child: Center(
                      child: Text(widget.avatarEmoji,
                          style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        '${widget.pseudonym} sent you a Healing Request',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text('Would you like to connect?',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 12)),
                    ])),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _actionButton(
                    label: 'Accept',
                    color: _kPurple,
                    icon: Icons.favorite_rounded,
                    onTap: _acceptRequest,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    label: 'Decline',
                    color: Colors.white.withOpacity(0.1),
                    textColor: Colors.white.withOpacity(0.6),
                    icon: Icons.close_rounded,
                    onTap: _rejectRequest,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ] else if (_status == ConnectionStatus.connected) ...[
        _connectionBadge(),
        const SizedBox(height: 16),
        _actionButton(
          label: 'Disconnect',
          color: Colors.white.withOpacity(0.07),
          textColor: Colors.white.withOpacity(0.55),
          icon: Icons.link_off_rounded,
          onTap: _disconnect,
        ),
      ] else if (_status == ConnectionStatus.pendingSent) ...[
        _glassCard(
          child: Row(children: [
            const Icon(Icons.schedule_rounded, color: _kGold, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Healing Request Sent',
                      style: TextStyle(color: Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Waiting for ${widget.pseudonym} to respond…',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12)),
                ])),
          ]),
        ),
      ] else ...[
        // None — show send button or eligibility gate
        if (!eligible && ineligibleMsg != null)
          _glassCard(
            child: Column(children: [
              const Icon(Icons.lock_outline_rounded, color: _kGold, size: 36),
              const SizedBox(height: 12),
              const Text('Healing Connections',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                ineligibleMsg,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55), fontSize: 13),
              ),
            ]),
          )
        else
          _actionButton(
            label: 'Send Healing Request',
            color: _kPurple,
            icon: Icons.favorite_border_rounded,
            onTap: () => _sendRequest(auth),
            large: true,
          ),
      ],
    ]);
  }

  Widget _connectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        gradient: LinearGradient(colors: [
          _kPurple.withOpacity(0.25),
          _kPink.withOpacity(0.15),
        ]),
        border: Border.all(color: _kPurple.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.favorite_rounded, color: _kPurple, size: 16),
        const SizedBox(width: 8),
        const Text('Healing Connection',
            style: TextStyle(
                color: _kPurple,
                fontSize: 13.5,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _infoCard() {
    return _glassCard(
      child: Column(children: [
        _infoRow(
            icon: Icons.shield_outlined,
            label: 'Safe Space',
            value: 'Lunar community member'),
        const SizedBox(height: 12),
        _infoRow(
            icon: Icons.visibility_off_outlined,
            label: 'Privacy',
            value: 'Identity never shared'),
        const SizedBox(height: 12),
        _infoRow(
            icon: Icons.favorite_outline_rounded,
            label: 'Focus',
            value: 'Healing and support only'),
      ]),
    );
  }

  Widget _infoRow(
      {required IconData icon, required String label, required String value}) {
    return Row(children: [
      Icon(icon, color: _kPurple.withOpacity(0.7), size: 18),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w500)),
      ]),
    ]);
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
    bool large = false,
  }) {
    final fg = textColor ?? Colors.white;
    return GestureDetector(
      onTap: _actionLoading ? null : () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: large ? 52 : 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color,
        ),
        child: _actionLoading
            ? Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: fg.withOpacity(0.8))))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: fg, size: 18),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        color: fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ]),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.18),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kSurf,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.block_rounded, color: _kRed.withOpacity(0.8)),
            title: Text('Block ${widget.pseudonym}',
                style: TextStyle(color: _kRed.withOpacity(0.9),
                    fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              _block();
            },
          ),
        ]),
      ),
    );
  }

  static Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return _kPurple;
    }
  }
}
