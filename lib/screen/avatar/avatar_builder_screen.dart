// -----------------------------------------------------------------------------
//  LUNAR AVATAR STUDIO  � World-class avatar customisation
//  Layout: immersive full-screen preview � floating scan CTA �
//          Snap-style bottom panel with live preview updates
// -----------------------------------------------------------------------------

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/avatar_model.dart';
import '../../core/providers/avatar_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/selfie_avatar_service.dart';
import '../../widgets/lunar_avatar_widget.dart';

// -- Colour tokens -------------------------------------------------------------
const _kBg      = Color(0xFF07010F);
const _kPurple  = Color(0xFFAB5CF2);
const _kPink    = Color(0xFFFF69B4);
const _kGold    = Color(0xFFFFD700);
const _kSurface = Color(0xFF130228);
const _kCard    = Color(0xFF1C0538);

// -- Editor categories ---------------------------------------------------------
enum _Category { selfie, face, hair, outfit, accessories, aura }

extension _CategoryX on _Category {
  String get label {
    switch (this) {
      case _Category.selfie:      return 'Scan';
      case _Category.face:        return 'Face';
      case _Category.hair:        return 'Hair';
      case _Category.outfit:      return 'Outfit';
      case _Category.accessories: return 'Extras';
      case _Category.aura:        return 'Aura';
    }
  }
  IconData get icon {
    switch (this) {
      case _Category.selfie:      return Icons.camera_alt_rounded;
      case _Category.face:        return Icons.face_retouching_natural_rounded;
      case _Category.hair:        return Icons.auto_awesome_rounded;
      case _Category.outfit:      return Icons.checkroom_rounded;
      case _Category.accessories: return Icons.stars_rounded;
      case _Category.aura:        return Icons.blur_circular_rounded;
    }
  }
}

// -----------------------------------------------------------------------------
class AvatarBuilderScreen extends StatefulWidget {
  const AvatarBuilderScreen({super.key});
  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen>
    with TickerProviderStateMixin {

  _Category _category = _Category.selfie;
  AvatarModel? _draft;
  bool _scanning = false;

  // animations
  late AnimationController _bgCtrl;
  late Animation<double>    _bgAnim;
  late AnimationController _previewCtrl;
  late Animation<double>    _previewAnim;
  late AnimationController _scanCtrl;
  late Animation<double>    _scanAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _previewCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _previewAnim = CurvedAnimation(parent: _previewCtrl, curve: Curves.elasticOut);

    _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _scanAnim = CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ap   = context.read<AvatarProvider>();
      final auth = context.read<LunarAuthProvider>();

      if (ap.avatar != null) {
        // Already loaded — use it directly
        setState(() => _draft = ap.avatar);
      } else if (!ap.loading) {
        // Not loaded yet — trigger load; also set a default immediately so UI
        // doesn't get stuck on spinner
        final uid = auth.firebaseUser?.uid ?? 'guest';
        setState(() => _draft = AvatarModel.defaultFor(uid));
        if (auth.isAuthenticated) {
          ap.load(auth).then((_) {
            if (mounted && ap.avatar != null && _draft?.uid == uid) {
              // Replace default with real data once loaded
              setState(() => _draft = ap.avatar);
            }
          });
        }
      }
      _previewCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _previewCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  void _update(AvatarModel updated) {
    setState(() => _draft = updated);
    _previewCtrl.reset();
    _previewCtrl.forward();
  }

  Future<void> _save() async {
    if (_draft == null) return;
    HapticFeedback.mediumImpact();
    final ap   = context.read<AvatarProvider>();
    final auth = context.read<LunarAuthProvider>();
    await ap.update(_draft!, auth);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _scanSelfie() async {
    if (_scanning) return;
    HapticFeedback.heavyImpact();
    setState(() => _scanning = true);

    final result = await SelfieAvatarService.scanAndBuild(
        currentAvatar: _draft ?? context.read<AvatarProvider>().avatar);

    if (!mounted) return;
    setState(() => _scanning = false);

    switch (result.status) {
      case SelfieAvatarStatus.success:
        final uid = (_draft ?? context.read<AvatarProvider>().avatar)?.uid ?? '';
        _update(result.avatar!.copyWith(uid: uid.isEmpty ? null : uid));
        setState(() => _category = _Category.face);
        _showToast('? Avatar scanned! Fine-tune below.', success: true);
      case SelfieAvatarStatus.noFaceFound:
        _showToast(result.message ?? 'No face detected. Try better lighting.', success: false);
      case SelfieAvatarStatus.permissionDenied:
        _showToast('Camera permission needed � enable in Settings.', success: false);
      case SelfieAvatarStatus.cancelled:
        break;
      case SelfieAvatarStatus.error:
        _showToast(result.message ?? 'Something went wrong.', success: false);
    }
  }

  void _showToast(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: success ? const Color(0xFF2A0A4A) : const Color(0xFF5A1020),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AvatarProvider>();
    final av = _draft ?? ap.avatar;

    // Only show spinner while Firestore is actively loading
    if (av == null && ap.loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kPurple)),
      );
    }

    // If avatar is still null (not loading either), build a default on the fly
    final avatarModel = av ??
        AvatarModel.defaultFor(
            context.read<LunarAuthProvider>().firebaseUser?.uid ?? 'guest');

    // Ensure _draft is always set so saves work correctly
    if (_draft == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) { if (mounted) setState(() => _draft = avatarModel); });
    }

    return Scaffold(
      backgroundColor: _kBg,
      extendBodyBehindAppBar: true,
      appBar: _appBar(),
      floatingActionButton: _saveFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          _previewPane(avatarModel),
          _categoryRail(),
          Expanded(child: _optionPanel(avatarModel)),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(15),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
      ),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text('Avatar Studio',
      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    centerTitle: true,
  );

  Widget _saveFab() => Container(
    height: 48,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_kPurple, _kPink]),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [BoxShadow(color: _kPurple.withAlpha(110), blurRadius: 18, spreadRadius: 1)],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _save,
        borderRadius: BorderRadius.circular(28),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _previewPane(AvatarModel av) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: Listenable.merge([_bgAnim, _previewAnim]),
      builder: (_, child) => Container(
        height: h * 0.44,
        width: w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              av.auraStyle.primaryColor.withAlpha((40 + 20 * _bgAnim.value).round()),
              _kPurple.withAlpha((25 + 15 * _bgAnim.value).round()),
              _kBg,
            ],
          ),
        ),
        child: child,
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _bgAnim,
              builder: (_, __) => Container(
                width: w * 0.65, height: w * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: _kPurple.withAlpha((25 + 20 * _bgAnim.value).round()),
                    blurRadius: 80, spreadRadius: 20,
                  )],
                ),
              ),
            ),
            ScaleTransition(
              scale: Tween<double>(begin: 0.80, end: 1.0).animate(_previewAnim),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(parent: _previewCtrl, curve: const Interval(0, 0.6))),
                child: LunarAvatarWidget(avatar: av, size: w * 0.46, animate: true, showAura: true),
              ),
            ),
            Positioned(
              top: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _pill('${av.emotionalState.emoji} ${av.emotionalState.label}'),
                  const SizedBox(width: 8),
                  _pill('${av.auraStyle.emoji} ${av.auraStyle.label}', color: av.auraStyle.primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, {Color? color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: (color ?? Colors.white).withAlpha(20),
            border: Border.all(color: (color ?? Colors.white).withAlpha(40)),
          ),
          child: Text(text,
            style: TextStyle(color: color ?? Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _categoryRail() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(
          top:    BorderSide(color: _kPurple.withAlpha(30)),
          bottom: BorderSide(color: Colors.white.withAlpha(8)),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: _Category.values.map((cat) {
          final active   = cat == _category;
          final isCamera = cat == _Category.selfie;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _category = cat);
              if (isCamera) _scanSelfie();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: active
                    ? (isCamera
                        ? const LinearGradient(colors: [Color(0xFF00C8FF), Color(0xFF7B2FFF)])
                        : const LinearGradient(colors: [_kPurple, _kPink]))
                    : null,
                color: active ? null : Colors.white.withAlpha(8),
                border: Border.all(
                  color: active ? Colors.transparent
                      : (isCamera ? const Color(0xFF00C8FF).withAlpha(60) : Colors.white.withAlpha(18)),
                  width: 1.2,
                ),
                boxShadow: active
                    ? [BoxShadow(
                        color: (isCamera ? const Color(0xFF00C8FF) : _kPurple).withAlpha(80),
                        blurRadius: 12)]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat.icon, size: 18,
                    color: active ? Colors.white
                        : (isCamera ? const Color(0xFF00C8FF).withAlpha(180) : Colors.white54)),
                  const SizedBox(height: 3),
                  Text(cat.label,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white54,
                      fontSize: 10.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _optionPanel(AvatarModel av) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: _kSurface.withAlpha(200),
          child: _category == _Category.selfie
              ? _selfiePanel()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: _buildOptions(av),
                ),
        ),
      ),
    );
  }

  Widget _selfiePanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _scanSelfie,
            child: AnimatedBuilder(
              animation: _scanAnim,
              builder: (_, child) => Container(
                width: double.infinity,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C8FF), Color(0xFF7B2FFF), Color(0xFFFF69B4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF7B2FFF).withAlpha(
                        _scanning ? 40 : (60 + 50 * _scanAnim.value).round()),
                    blurRadius: _scanning ? 12 : 24 + 16 * _scanAnim.value,
                    spreadRadius: _scanning ? 0 : 2,
                  )],
                ),
                child: child,
              ),
              child: Center(
                child: _scanning
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 28, height: 28,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                          SizedBox(height: 8),
                          Text('Scanning your face...',
                            style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                        ])
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
                          SizedBox(height: 6),
                          Text('Scan My Face',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                          SizedBox(height: 2),
                          Text('AI detects skin, hair & features',
                            style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ]),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _howItWorks(),
          const SizedBox(height: 20),
          _scanTips(),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    final steps = [
      (Icons.camera_front_rounded,              'Front camera opens',           const Color(0xFF00C8FF)),
      (Icons.face_retouching_natural_rounded,   'AI reads your features',       _kPurple),
      (Icons.auto_fix_high_rounded,             'Avatar instantly matches you', _kPink),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How it works',
          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        ...steps.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.$3.withAlpha(25),
                border: Border.all(color: s.$3.withAlpha(60)),
              ),
              child: Icon(s.$1, color: s.$3, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(s.$2,
              style: const TextStyle(color: Colors.white60, fontSize: 12.5))),
          ]),
        )),
      ],
    );
  }

  Widget _scanTips() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withAlpha(6),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.tips_and_updates_rounded, color: _kGold, size: 14),
            SizedBox(width: 6),
            Text('Tips for best results',
              style: TextStyle(color: _kGold, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          for (final tip in [
            'Look directly at the camera',
            'Good lighting (natural light is best)',
            'Remove glasses for accurate detection',
          ])
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(children: [
                const Icon(Icons.circle, color: Colors.white30, size: 5),
                const SizedBox(width: 8),
                Text(tip, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
              ]),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(AvatarModel av) {
    switch (_category) {
      case _Category.selfie:      return [];
      case _Category.face:        return _faceOptions(av);
      case _Category.hair:        return _hairOptions(av);
      case _Category.outfit:      return _outfitOptions(av);
      case _Category.accessories: return _accessoryOptions(av);
      case _Category.aura:        return _auraOptions(av);
    }
  }

  List<Widget> _faceOptions(AvatarModel av) => [
    _sectionLabel('Skin Tone'), _skinToneRow(av), const SizedBox(height: 18),
    _sectionLabel('Avatar Style'),
    _chipRow<AvatarGender>(items: AvatarGender.values, selected: av.gender,
      label: (g) => g.label, color: (_) => _kPurple, onTap: (g) => _update(av.copyWith(gender: g))),
    const SizedBox(height: 18),
    _sectionLabel('Face Shape'),
    _chipRow<FaceShape>(items: FaceShape.values, selected: av.faceShape,
      label: (f) => f.label, color: (_) => _kPurple, onTap: (f) => _update(av.copyWith(faceShape: f))),
    const SizedBox(height: 18),
    _sectionLabel('Eye Style'),
    _chipRow<EyeStyle>(items: EyeStyle.values, selected: av.eyeStyle,
      label: (e) => e.label, color: (_) => _kPink, onTap: (e) => _update(av.copyWith(eyeStyle: e))),
    const SizedBox(height: 18),
    _sectionLabel('Eye Colour'),
    _colorRow<EyeColor>(items: EyeColor.values, selected: av.eyeColor,
      color: (e) => e.color, label: (e) => e.label, onTap: (e) => _update(av.copyWith(eyeColor: e))),
    const SizedBox(height: 18),
    _sectionLabel('Eyebrows'),
    _chipRow<BrowStyle>(items: BrowStyle.values, selected: av.browStyle,
      label: (b) => b.label, color: (_) => _kPurple, onTap: (b) => _update(av.copyWith(browStyle: b))),
    const SizedBox(height: 18),
    _sectionLabel('Lip Style'),
    _chipRow<LipStyle>(items: LipStyle.values, selected: av.lipStyle,
      label: (l) => l.label, color: (_) => _kPink, onTap: (l) => _update(av.copyWith(lipStyle: l))),
    const SizedBox(height: 18),
    _sectionLabel('Lip Colour'),
    _colorRow<LipColor>(items: LipColor.values, selected: av.lipColor,
      color: (l) => l.color, label: (l) => l.label, onTap: (l) => _update(av.copyWith(lipColor: l))),
    const SizedBox(height: 18),
    _sectionLabel('Blush'),
    _chipRow<BlushLevel>(items: BlushLevel.values, selected: av.blush,
      label: (b) => b.label, color: (_) => _kPink, onTap: (b) => _update(av.copyWith(blush: b))),
    const SizedBox(height: 18),
    _sectionLabel('Emotional State'),
    _chipRow<EmotionalState>(items: EmotionalState.values, selected: av.emotionalState,
      label: (e) => '${e.emoji} ${e.label}', color: (_) => _kPurple,
      onTap: (e) => _update(av.copyWith(emotionalState: e))),
    const SizedBox(height: 18),
    _toggleTile(label: 'Show freckles', value: av.freckles, onChanged: (v) => _update(av.copyWith(freckles: v))),
  ];

  List<Widget> _hairOptions(AvatarModel av) => [
    _sectionLabel('Hair Style'), _hairStyleGrid(av), const SizedBox(height: 18),
    _sectionLabel('Hair Colour'),
    _colorRow<HairColor>(items: HairColor.values, selected: av.hairColor,
      color: (h) => h.color, label: (h) => h.label, onTap: (h) => _update(av.copyWith(hairColor: h))),
  ];

  Widget _hairStyleGrid(AvatarModel av) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 1.9, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: HairStyle.values.length,
      itemBuilder: (_, i) {
        final s      = HairStyle.values[i];
        final active = s == av.hairStyle;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); _update(av.copyWith(hairStyle: s)); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: active ? LinearGradient(colors: [_kPurple.withAlpha(200), _kPink.withAlpha(160)]) : null,
              color: active ? null : Colors.white.withAlpha(8),
              border: Border.all(color: active ? _kPurple : Colors.white.withAlpha(18), width: 1.2),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(s.label, textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white60, fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
            ]),
          ),
        );
      },
    );
  }

  List<Widget> _outfitOptions(AvatarModel av) => [
    _sectionLabel('Mood Outfit'),
    GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 2.6, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: OutfitMood.values.length,
      itemBuilder: (_, i) {
        final mood   = OutfitMood.values[i];
        final active = mood == av.outfitMood;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); _update(av.copyWith(outfitMood: mood)); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: active
                  ? [mood.gradient[0], mood.gradient[1]]
                  : [mood.gradient[0].withAlpha(50), mood.gradient[1].withAlpha(35)]),
              border: Border.all(
                color: active ? mood.gradient[0].withAlpha(200) : Colors.white.withAlpha(12),
                width: active ? 1.5 : 1),
            ),
            child: Center(child: Text(mood.label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white60, fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400))),
          ),
        );
      },
    ),
  ];

  List<Widget> _accessoryOptions(AvatarModel av) => [
    _sectionLabel('Accessories'),
    Text('Tap to toggle � Mix & match freely',
      style: TextStyle(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic)),
    const SizedBox(height: 14),
    Wrap(
      spacing: 8, runSpacing: 8,
      children: AccessoryType.values.map((acc) {
        final active = av.accessories.contains(acc);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            final list = List<AccessoryType>.from(av.accessories);
            active ? list.remove(acc) : list.add(acc);
            _update(av.copyWith(accessories: list));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: active ? const LinearGradient(colors: [_kGold, _kPink]) : null,
              color: active ? null : Colors.white.withAlpha(8),
              border: Border.all(color: active ? _kGold : Colors.white.withAlpha(22)),
              boxShadow: active ? [BoxShadow(color: _kGold.withAlpha(80), blurRadius: 10)] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(acc.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(acc.label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54, fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
            ]),
          ),
        );
      }).toList(),
    ),
  ];

  List<Widget> _auraOptions(AvatarModel av) => [
    _sectionLabel('Emotional Aura'),
    Text('Your aura reflects your inner energy � auto-syncs with your mood data.',
      style: TextStyle(color: Colors.white30, fontSize: 11.5, fontStyle: FontStyle.italic)),
    const SizedBox(height: 14),
    ...AuraStyle.values.map((aura) {
      final active = aura == av.auraStyle;
      return GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); _update(av.copyWith(auraStyle: aura)); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: active ? LinearGradient(colors: [
              aura.primaryColor.withAlpha(100), aura.secondaryColor.withAlpha(55)]) : null,
            color: active ? null : Colors.white.withAlpha(7),
            border: Border.all(
              color: active ? aura.primaryColor.withAlpha(180) : Colors.white.withAlpha(15)),
            boxShadow: active ? [BoxShadow(color: aura.primaryColor.withAlpha(60), blurRadius: 14)] : null,
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  aura.primaryColor.withAlpha(220), aura.secondaryColor.withAlpha(120)]),
              ),
              child: Center(child: Text(aura.emoji, style: const TextStyle(fontSize: 15))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(aura.label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54, fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
              if (active) Text('Currently active',
                style: TextStyle(color: aura.primaryColor, fontSize: 10.5)),
            ])),
            if (active)
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: aura.primaryColor.withAlpha(40)),
                child: Icon(Icons.check_rounded, color: aura.primaryColor, size: 14),
              ),
          ]),
        ),
      );
    }),
  ];

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text,
      style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
  );

  Widget _skinToneRow(AvatarModel av) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: SkinTone.values.map((tone) {
          final active = tone == av.skinTone;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); _update(av.copyWith(skinTone: tone)); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 10),
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tone.base,
                border: Border.all(
                  color: active ? Colors.white : Colors.white.withAlpha(20), width: 2.5),
                boxShadow: active
                    ? [BoxShadow(color: tone.base.withAlpha(160), blurRadius: 12, spreadRadius: 2)]
                    : null,
              ),
              child: active
                  ? Center(child: Icon(Icons.check_rounded,
                      color: tone.base.computeLuminance() > 0.5 ? Colors.black54 : Colors.white,
                      size: 16))
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chipRow<T>({
    required List<T> items, required T selected,
    required String Function(T) label, required Color Function(T) color, required void Function(T) onTap,
  }) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items.map((item) {
          final active = item == selected;
          final c = color(item);
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onTap(item); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: active ? LinearGradient(colors: [c, _kPink],
                    begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                color: active ? null : Colors.white.withAlpha(8),
                border: Border.all(color: active ? c : Colors.white.withAlpha(18)),
              ),
              child: Text(label(item),
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54, fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _colorRow<T>({
    required List<T> items, required T selected,
    required Color Function(T) color, required String Function(T) label, required void Function(T) onTap,
  }) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items.map((item) {
          final active = item == selected;
          final c = color(item);
          return Tooltip(
            message: label(item),
            child: GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); onTap(item); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(right: 10),
                width: 38, height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c,
                  border: Border.all(
                    color: active ? Colors.white : Colors.transparent, width: 2.5),
                  boxShadow: active
                      ? [BoxShadow(color: c.withAlpha(160), blurRadius: 12, spreadRadius: 2)]
                      : null,
                ),
                child: active
                    ? Center(child: Icon(Icons.check_rounded,
                        color: c.computeLuminance() > 0.5 ? Colors.black54 : Colors.white,
                        size: 15))
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _toggleTile({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withAlpha(7),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(children: [
        Expanded(child: Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 13.5))),
        Switch.adaptive(value: value,
          onChanged: (v) { HapticFeedback.selectionClick(); onChanged(v); },
          activeColor: _kPurple,
          inactiveThumbColor: Colors.white30,
          inactiveTrackColor: Colors.white10),
      ]),
    );
  }
}
