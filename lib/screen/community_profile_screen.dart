// ─────────────────────────────────────────────────────────────────────────────
//  COMMUNITY PROFILE SCREEN
//  Shows a community member's profile with healing connection actions.
//  Features: connection request · accept/reject · disconnect · block
//  Eligibility: Premium + Email verified + Account ≥ 7 days
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/connection_provider.dart';
import '../core/services/firestore_service.dart';
import '../models/connection_model.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF0A0118);
const Color _kSurf = Color(0xFF160330);
const Color _kPurple = Color(0xFFAB5CF2);
const Color _kPink = Color(0xFFFF69B4);
const Color _kGold = Color(0xFFFFD700);
const Color _kGreen = Color(0xFF66BB6A);
const Color _kRed = Color(0xFFEF5350);

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
        targetUid: targetUid,
        pseudonym: pseudonym,
        avatarEmoji: avatarEmoji,
        avatarColorHex: avatarColorHex,
        isPremium: isPremium,
        isVerified: isVerified,
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
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _profilePhoto;
  String? _profilePhotoUrl;
  bool _photoUploading = false;
  String _bio = '';
  String? _displayName;
  String? _username;
  DateTime? _joinedAt;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadStatus();
    _loadProfile();
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

  Future<void> _loadProfile() async {
    final auth = context.read<LunarAuthProvider>();
    final uid =
        widget.targetUid.isNotEmpty ? widget.targetUid : auth.firebaseUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (!mounted || data == null) return;
      setState(() {
        _displayName = (data['name'] as String?)?.trim();
        _username = (data['username'] as String?)?.trim();
        _bio = (data['bio'] as String?)?.trim() ?? '';
        _profilePhotoUrl = data['photoUrl'] as String? ?? _profilePhotoUrl;
        _joinedAt = (data['createdAt'] as Timestamp?)?.toDate();
      });
    } catch (_) {}
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
    if (!auth.isActivePremium)
      return 'Upgrade to Lunar Premium to send healing connections.';
    if (!auth.isEmailVerified)
      return 'Verify your email to send healing connections.';
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
      toUid: widget.targetUid,
      fromPseudonym: myPseudonym,
      fromAvatarEmoji: '🌙',
      fromAvatarColorHex: 'AB5CF2',
      toPseudonym: widget.pseudonym,
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
    final err = await context
        .read<ConnectionProvider>()
        .acceptRequest(_incomingRequestId!);
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
    final err = await context
        .read<ConnectionProvider>()
        .rejectRequest(_incomingRequestId!);
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
        title: 'Disconnect?',
        message:
            'You will no longer be healing connections with ${widget.pseudonym}.',
        confirm: 'Disconnect');
    if (confirm != true || !mounted) return;
    setState(() => _actionLoading = true);
    final err =
        await context.read<ConnectionProvider>().disconnect(widget.targetUid);
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
        title: 'Block ${widget.pseudonym}?',
        message:
            'They won\'t be able to send you requests. You won\'t see their posts in your feed.',
        confirm: 'Block',
        isDestructive: true);
    if (confirm != true || !mounted) return;
    setState(() => _actionLoading = true);
    final err =
        await context.read<ConnectionProvider>().blockUser(widget.targetUid);
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
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(message,
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirm,
                style: TextStyle(
                    color: isDestructive ? _kRed : _kPurple,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _showPhotoSheet() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kSurf,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 18),
            _sheetOption(Icons.photo_camera_rounded, 'Take Photo', () {
              Navigator.pop(context);
              _pickPhoto(ImageSource.camera);
            }),
            _sheetOption(Icons.photo_library_rounded, 'Choose From Gallery',
                () {
              Navigator.pop(context);
              _pickPhoto(ImageSource.gallery);
            }),
            _sheetOption(Icons.delete_outline_rounded, 'Remove Current Photo',
                () {
              Navigator.pop(context);
              _removePhoto();
            }, color: _kRed),
            _sheetOption(Icons.close_rounded, 'Cancel', () {
              Navigator.pop(context);
            }),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final auth = context.read<LunarAuthProvider>();
      final uid = auth.firebaseUser?.uid;
      if (uid == null || auth.isGuest) {
        _showSnack('Sign in to update your profile photo.', isError: true);
        return;
      }
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (!mounted || picked == null) return;
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 88,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: _kBg,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: _kPurple,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (!mounted || cropped == null) return;
      setState(() {
        _profilePhoto = XFile(cropped.path);
        _photoUploading = true;
      });
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/$uid/community_profile.jpg');
      await ref.putFile(File(cropped.path));
      final url = await ref.getDownloadURL();
      await FirestoreService.updateUser(uid, {'photoUrl': url});
      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = url;
        _photoUploading = false;
      });
      _showSnack('Profile photo updated.');
    } catch (_) {
      if (mounted) setState(() => _photoUploading = false);
      _showSnack('Unable to open photo picker.', isError: true);
    }
  }

  Future<void> _removePhoto() async {
    final auth = context.read<LunarAuthProvider>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null || auth.isGuest) {
      _showSnack('Sign in to update your profile photo.', isError: true);
      return;
    }
    setState(() => _photoUploading = true);
    try {
      await FirestoreService.updateUser(uid, {'photoUrl': null});
      await FirebaseStorage.instance
          .ref()
          .child('profile_images/$uid/community_profile.jpg')
          .delete()
          .catchError((_) {});
      if (!mounted) return;
      setState(() {
        _profilePhoto = null;
        _profilePhotoUrl = null;
        _photoUploading = false;
      });
      _showSnack('Profile photo removed.');
    } catch (_) {
      if (mounted) setState(() => _photoUploading = false);
      _showSnack('Unable to remove photo.', isError: true);
    }
  }

  Widget _sheetOption(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    final itemColor = color ?? Colors.white;
    return ListTile(
      minLeadingWidth: 24,
      leading: Icon(icon, color: itemColor.withOpacity(0.9)),
      title: Text(label,
          style: TextStyle(
              color: itemColor.withOpacity(0.92),
              fontSize: 15,
              fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Future<void> _editBio() async {
    final ctrl = TextEditingController(text: _bio);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Bio',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLength: 150,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tell the community about yourself...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            counterStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _kPurple),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save',
                style: TextStyle(color: _kPurple, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (!mounted || result == null) return;
    final bio = result.length > 150 ? result.substring(0, 150) : result;
    final auth = context.read<LunarAuthProvider>();
    final uid = auth.firebaseUser?.uid;
    if (uid != null && uid == widget.targetUid) {
      await FirestoreService.updateUser(uid, {'bio': bio});
    }
    if (!mounted) return;
    setState(() => _bio = bio);
  }

  Future<void> _editProfile() async {
    final auth = context.read<LunarAuthProvider>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null || uid != widget.targetUid || auth.isGuest) {
      _showSnack('You can edit only your own profile.', isError: true);
      return;
    }

    final nameCtrl = TextEditingController(
      text: (_displayName?.isNotEmpty == true
              ? _displayName
              : auth.userModel?.name ?? widget.pseudonym) ??
          '',
    );
    final usernameCtrl = TextEditingController(
      text: _username ??
          widget.pseudonym.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), ''),
    );
    final bioCtrl = TextEditingController(text: _bio);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _profileTextField(nameCtrl, 'Display name', 40),
            const SizedBox(height: 12),
            _profileTextField(usernameCtrl, 'Username', 24),
            const SizedBox(height: 12),
            _profileTextField(bioCtrl, 'Bio', 150, maxLines: 4),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, {
              'name': nameCtrl.text.trim(),
              'username': usernameCtrl.text.trim(),
              'bio': bioCtrl.text.trim(),
            }),
            child: const Text('Save',
                style: TextStyle(color: _kPurple, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    usernameCtrl.dispose();
    bioCtrl.dispose();
    if (!mounted || result == null) return;

    final username = result['username']!
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    await FirestoreService.updateUser(uid, {
      'name': result['name'],
      'username': username,
      'bio': result['bio'],
    });
    if (!mounted) return;
    setState(() {
      _displayName = result['name'];
      _username = username;
      _bio = result['bio']!;
    });
    _showSnack('Profile updated.');
  }

  Widget _profileTextField(
      TextEditingController ctrl, String label, int maxLength,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLength: maxLength,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
        counterStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _kPurple),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '☾';
    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts.last.characters.first : '';
    return (first + second).toUpperCase();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<LunarAuthProvider>();
    final avatarColor = _hexToColor(widget.avatarColorHex);

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
        actions: const [],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header(auth, avatarColor)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(children: [
                const SizedBox(height: 14),
                _bioSection(),
                const SizedBox(height: 14),
                _profileStats(),
                const SizedBox(height: 14),
                _profileContentCards(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(LunarAuthProvider auth, Color avatarColor) {
    final name = _displayName?.trim().isNotEmpty == true
        ? _displayName!.trim()
        : auth.userModel?.name?.trim().isNotEmpty == true
            ? auth.userModel!.name!.trim()
            : widget.pseudonym;
    _profilePhotoUrl ??= auth.photoUrl;
    final username =
        '@${(_username?.isNotEmpty == true ? _username! : widget.pseudonym.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), ''))}';
    final joinedLabel = _joinedAt == null
        ? null
        : 'Joined ${_joinedAt!.month}/${_joinedAt!.year}';

    return SizedBox(
      height: 330,
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
                GestureDetector(
                  onTap: _showPhotoSheet,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) => Transform.scale(
                      scale: _pulse.value,
                      child: child,
                    ),
                    child: _profileAvatar(avatarColor, name),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5),
                        ),
                      ),
                      if (widget.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF4FC3F7), size: 20),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  username,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _badge('🌙 Peaceful', _kPurple),
                    _badge('🔥 7 day streak', _kGold),
                    if (joinedLabel != null) _badge(joinedLabel, _kGreen),
                    if (widget.isPremium) _badge('💜 Premium', _kPurple),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileAvatar(Color avatarColor, String name) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          avatarColor.withOpacity(0.9),
          _kPurple.withOpacity(0.28),
        ]),
        border: Border.all(color: avatarColor, width: 2.5),
        boxShadow: [
          BoxShadow(
              color: avatarColor.withOpacity(0.5),
              blurRadius: 24,
              spreadRadius: 4),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _profilePhoto != null
          ? Image.file(File(_profilePhoto!.path), fit: BoxFit.cover)
          : _profilePhotoUrl != null
              ? Image.network(_profilePhotoUrl!, fit: BoxFit.cover)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Text(_initials(name),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800)),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 10,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kBg.withOpacity(0.76),
                          border: Border.all(color: _kGold.withOpacity(0.75)),
                        ),
                        child: const Icon(Icons.nightlight_round,
                            color: _kGold, size: 14),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _bioSection() {
    return _glassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Profile Bio',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          GestureDetector(
            onTap: _editProfile,
            child: Text('Edit Profile',
                style: TextStyle(
                    color: _kPurple.withOpacity(0.95),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          _bio.isEmpty ? 'Tell the community about yourself...' : _bio,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: Colors.white.withOpacity(_bio.isEmpty ? 0.42 : 0.78),
              fontSize: 13.5,
              height: 1.45),
        ),
      ]),
    );
  }

  Widget _profileStats() {
    return _glassCard(
      child: Row(children: [
        _statItem('Healing', '7d'),
        _divider(),
        _statItem('Saved', '0'),
        _divider(),
        _statItem('Stories', '0'),
      ]),
    );
  }

  Widget _profileContentCards() {
    return Column(
      children: [
        _profileSection(
          'My Content',
          [
            ('✍️', 'My Posts'),
            ('🌙', 'My Stories'),
            ('🗂', 'Story Archive'),
            ('🔖', 'Saved Posts'),
          ],
        ),
        const SizedBox(height: 14),
        _profileSection(
          'Premium',
          [
            ('🎨', 'Profile Theme'),
            ('💎', 'Avatar Frame'),
            ('✨', 'Accent Color'),
          ],
          premium: true,
        ),
        const SizedBox(height: 14),
        _profileSection(
          'Privacy',
          [
            ('🛡', 'Privacy Settings'),
            ('🚫', 'Blocked Users'),
            ('🔕', 'Muted Users'),
            ('🤝', 'Who can send Friend Requests'),
            ('💬', 'Who can message me'),
          ],
        ),
      ],
    );
  }

  Widget _profileSection(String title, List<(String, String)> items,
      {bool premium = false}) {
    return _glassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ),
          if (premium) _badge(widget.isPremium ? 'Premium' : 'Locked', _kGold),
        ]),
        const SizedBox(height: 10),
        for (var i = 0; i < items.length; i++) ...[
          _profileRow(items[i].$1, items[i].$2),
          if (i != items.length - 1)
            Divider(height: 14, color: Colors.white.withOpacity(0.08)),
        ],
      ]),
    );
  }

  Widget _profileRow(String emoji, String title) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.lightImpact();
        if (title == 'Profile Theme' ||
            title == 'Avatar Frame' ||
            title == 'Accent Color') {
          _showCommunityThemeSheet(initialSetting: title);
          return;
        }
        _showSnack('$title coming soon');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.28), size: 20),
        ]),
      ),
    );
  }

  Widget _profileCard(String emoji, String title) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (title == 'Community Preferences') {
          _showCommunityThemeSheet();
          return;
        }
        _showSnack('$title coming soon');
      },
      child: _glassCard(
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.35), size: 22),
        ]),
      ),
    );
  }

  void _showCommunityThemeSheet({String initialSetting = 'Profile Theme'}) {
    final auth = context.read<LunarAuthProvider>();
    if (!auth.isActivePremium) {
      _showSnack('Profile themes are for Premium members.', isError: true);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(initialSetting,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _themeOption('profileTheme', 'lunar', 'Lunar Purple', _kPurple),
              _themeOption('profileTheme', 'rose', 'Rose Healing', _kPink),
              _themeOption('avatarFrame', 'gold', 'Gold Avatar Frame', _kGold),
              _themeOption('accentColor', 'aurora', 'Aurora Accent', _kGreen),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _themeOption(String field, String id, String label, Color color) {
    final selected = field == 'profileTheme' &&
        context.read<LunarAuthProvider>().communityTheme == id;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      title: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: _kPurple)
          : Icon(Icons.circle_outlined, color: Colors.white.withOpacity(0.28)),
      onTap: () async {
        final uid = context.read<LunarAuthProvider>().firebaseUser?.uid;
        if (uid == null) return;
        await FirestoreService.updateUser(uid, {
          field: id,
          if (field == 'profileTheme') 'communityTheme': id,
        });
        if (!mounted) return;
        Navigator.pop(context);
        _showSnack('$label updated.');
      },
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Column(children: [
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.white.withOpacity(0.42), fontSize: 11.5)),
      ]),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 34,
        color: Colors.white.withOpacity(0.08),
      );

  Widget _buildConnectionSection(
      LunarAuthProvider auth, bool eligible, String? ineligibleMsg) {
    if (_statusLoading) {
      return const Center(
          child: SizedBox(
              width: 24,
              height: 24,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPurple)));
    }

    if (_status == ConnectionStatus.blocked) {
      return _glassCard(
        child: Column(children: [
          Icon(Icons.block_rounded, color: _kRed.withOpacity(0.8), size: 36),
          const SizedBox(height: 12),
          const Text('User Blocked',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('You have blocked this member.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 13)),
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
        Row(children: [
          Expanded(
            child: _actionButton(
              label: 'Disconnect',
              color: Colors.white.withOpacity(0.07),
              textColor: Colors.white.withOpacity(0.55),
              icon: Icons.link_off_rounded,
              onTap: _disconnect,
            ),
          ),
        ]),
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
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Waiting for ${widget.pseudonym} to respond…',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45), fontSize: 12)),
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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
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
                color: _kPurple, fontSize: 13.5, fontWeight: FontWeight.w600)),
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
            style:
                TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
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
      onTap: _actionLoading
          ? null
          : () {
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
                        color: fg, fontSize: 14, fontWeight: FontWeight.w600)),
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
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
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
                style: TextStyle(
                    color: _kRed.withOpacity(0.9),
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
