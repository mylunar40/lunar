// ─────────────────────────────────────────────────────────────────────────────
//  LUNAR AVATAR BUILDER SCREEN
//  Premium emotional avatar customisation studio.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/avatar_model.dart';
import '../../core/providers/avatar_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/lunar_avatar_widget.dart';

// ── Colour tokens (duplicated locally to avoid circular imports) ─────────────
const _kBg      = Color(0xFF0A0118);
const _kPurple  = Color(0xFFAB5CF2);
const _kPink    = Color(0xFFFF69B4);
const _kGold    = Color(0xFFFFD700);
const _kSurface = Color(0xFF160330);

// ── Editor category tabs ──────────────────────────────────────────────────────
enum _Category { gender, face, hair, outfit, accessories, aura }

extension _CategoryX on _Category {
  String get label {
    switch (this) {
      case _Category.gender:      return 'Style';
      case _Category.face:        return 'Face';
      case _Category.hair:        return 'Hair';
      case _Category.outfit:      return 'Outfit';
      case _Category.accessories: return 'Extras';
      case _Category.aura:        return 'Aura';
    }
  }
  String get emoji {
    switch (this) {
      case _Category.gender:      return '🌙';
      case _Category.face:        return '👁';
      case _Category.hair:        return '✨';
      case _Category.outfit:      return '👗';
      case _Category.accessories: return '📿';
      case _Category.aura:        return '💫';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────────────────────
class AvatarBuilderScreen extends StatefulWidget {
  const AvatarBuilderScreen({super.key});

  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen>
    with TickerProviderStateMixin {
  _Category _category = _Category.face;

  late AnimationController _bgCtrl;
  late Animation<double> _bgAnim;
  late AnimationController _previewCtrl;
  late Animation<double> _previewAnim;

  // Working copy of the avatar — updated live, saved on "Done"
  AvatarModel? _draft;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _previewCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _previewAnim = CurvedAnimation(parent: _previewCtrl, curve: Curves.easeOutCubic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final av = context.read<AvatarProvider>().avatar;
      if (av != null) setState(() => _draft = av);
      _previewCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _previewCtrl.dispose();
    super.dispose();
  }

  // ── save draft & close ───────────────────────────────────────────────────
  Future<void> _save() async {
    if (_draft == null) return;
    HapticFeedback.lightImpact();
    final ap = context.read<AvatarProvider>();
    final auth = context.read<LunarAuthProvider>();
    await ap.update(_draft!, auth);
    if (mounted) Navigator.pop(context);
  }

  // ── live draft update (no Firestore call) ─────────────────────────────────
  void _update(AvatarModel updated) {
    setState(() => _draft = updated);
    _previewCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final av = _draft ?? context.watch<AvatarProvider>().avatar;
    if (av == null) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: CircularProgressIndicator(color: _kPurple),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      extendBodyBehindAppBar: true,
      appBar: _appBar(),
      body: Column(children: [
        _previewSection(av),
        _categoryTabs(),
        Expanded(
          child: _optionPanel(av),
        ),
      ]),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.close_rounded, color: Colors.white70),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      'Lunar Avatar',
      style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5),
    ),
    actions: [
      GestureDetector(
        onTap: _save,
        child: Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_kPurple, _kPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text('Save',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5)),
          ),
        ),
      ),
    ],
  );

  // ── Preview section ───────────────────────────────────────────────────────
  Widget _previewSection(AvatarModel av) {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (_, child) => Container(
        height: MediaQuery.of(context).size.height * 0.34,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              _kPurple.withAlpha((50 + 30 * _bgAnim.value).round()),
              _kPink.withAlpha((20 + 15 * _bgAnim.value).round()),
              _kBg,
            ],
          ),
        ),
        child: child,
      ),
      child: SafeArea(
        bottom: false,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(_previewAnim),
          child: FadeTransition(
            opacity: _previewAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emotional state badge
                _emotionalBadge(av),
                const SizedBox(height: 10),
                // Avatar
                LunarAvatarWidget(
                  avatar: av,
                  size: MediaQuery.of(context).size.width * 0.38,
                  animate: true,
                  showAura: true,
                ),
                const SizedBox(height: 12),
                // Aura label
                Text(
                  av.auraStyle.emoji + ' ' + av.auraStyle.label,
                  style: TextStyle(
                      color: av.auraStyle.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emotionalBadge(AvatarModel av) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _kPurple.withAlpha(28),
        border: Border.all(color: _kPurple.withAlpha(60)),
      ),
      child: Text(
        '${av.emotionalState.emoji} ${av.emotionalState.label}',
        style: const TextStyle(color: Colors.white70, fontSize: 11.5),
      ),
    );
  }

  // ── Category tabs ─────────────────────────────────────────────────────────
  Widget _categoryTabs() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _kSurface.withAlpha(200),
        border: Border(top: BorderSide(color: _kPurple.withAlpha(40))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _Category.values.length,
        itemBuilder: (_, i) {
          final cat = _Category.values[i];
          final active = cat == _category;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _category = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: active
                    ? const LinearGradient(
                        colors: [_kPurple, _kPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                color: active ? null : Colors.white.withAlpha(10),
                border: Border.all(
                    color: active
                        ? Colors.transparent
                        : Colors.white.withAlpha(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(cat.label,
                      style: TextStyle(
                          color: active ? Colors.white : Colors.white54,
                          fontSize: 12.5,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Option panel ──────────────────────────────────────────────────────────
  Widget _optionPanel(AvatarModel av) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: _kSurface.withAlpha(180),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: _buildOptions(av),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptions(AvatarModel av) {
    switch (_category) {
      case _Category.gender:
        return _genderOptions(av);
      case _Category.face:
        return _faceOptions(av);
      case _Category.hair:
        return _hairOptions(av);
      case _Category.outfit:
        return _outfitOptions(av);
      case _Category.accessories:
        return _accessoryOptions(av);
      case _Category.aura:
        return _auraOptions(av);
    }
  }

  // ── Gender / style ────────────────────────────────────────────────────────
  List<Widget> _genderOptions(AvatarModel av) => [
    _sectionLabel('Avatar Style'),
    _chipRow<AvatarGender>(
      items: AvatarGender.values,
      selected: av.gender,
      label: (g) => g.label,
      color: (g) => _kPurple,
      onTap: (g) => _update(av.copyWith(gender: g)),
    ),
  ];

  // ── Face ──────────────────────────────────────────────────────────────────
  List<Widget> _faceOptions(AvatarModel av) => [
    _sectionLabel('Skin Tone'),
    _skinToneRow(av),
    const SizedBox(height: 16),
    _sectionLabel('Face Shape'),
    _chipRow<FaceShape>(
      items: FaceShape.values,
      selected: av.faceShape,
      label: (f) => f.label,
      color: (_) => _kPurple,
      onTap: (f) => _update(av.copyWith(faceShape: f)),
    ),
    const SizedBox(height: 16),
    _sectionLabel('Eye Style'),
    _chipRow<EyeStyle>(
      items: EyeStyle.values,
      selected: av.eyeStyle,
      label: (e) => e.label,
      color: (_) => _kPink,
      onTap: (e) => _update(av.copyWith(eyeStyle: e)),
    ),
    const SizedBox(height: 16),
    _sectionLabel('Eye Colour'),
    _colorRow<EyeColor>(
      items: EyeColor.values,
      selected: av.eyeColor,
      color: (e) => e.color,
      label: (e) => e.label,
      onTap: (e) => _update(av.copyWith(eyeColor: e)),
    ),
    const SizedBox(height: 16),
    _sectionLabel('Eyebrows'),
    _chipRow<BrowStyle>(
      items: BrowStyle.values,
      selected: av.browStyle,
      label: (b) => b.label,
      color: (_) => _kPurple,
      onTap: (b) => _update(av.copyWith(browStyle: b)),
    ),
    const SizedBox(height: 16),
    _sectionLabel('Lip Style'),
    _chipRow<LipStyle>(
      items: LipStyle.values,
      selected: av.lipStyle,
      label: (l) => l.label,
      color: (_) => _kPink,
      onTap: (l) => _update(av.copyWith(lipStyle: l)),
    ),
    const SizedBox(height: 16),
    _sectionLabel('Lip Colour'),
    _colorRow<LipColor>(
      items: LipColor.values,
      selected: av.lipColor,
      color: (l) => l.color,
      label: (l) => l.label,
      onTap: (l) => _update(av.copyWith(lipColor: l)),
    ),
    const SizedBox(height: 16),
    _sectionLabel('Blush'),
    _chipRow<BlushLevel>(
      items: BlushLevel.values,
      selected: av.blush,
      label: (b) => b.label,
      color: (_) => _kPink,
      onTap: (b) => _update(av.copyWith(blush: b)),
    ),
    const SizedBox(height: 16),
    _sectionLabel('Freckles'),
    _toggleTile(
      label: 'Show freckles',
      value: av.freckles,
      onChanged: (v) => _update(av.copyWith(freckles: v)),
    ),
  ];

  // ── Hair ──────────────────────────────────────────────────────────────────
  List<Widget> _hairOptions(AvatarModel av) => [
    _sectionLabel('Hair Style'),
    _hairStyleGrid(av),
    const SizedBox(height: 16),
    _sectionLabel('Hair Colour'),
    _colorRow<HairColor>(
      items: HairColor.values,
      selected: av.hairColor,
      color: (h) => h.color,
      label: (h) => h.label,
      onTap: (h) => _update(av.copyWith(hairColor: h)),
    ),
  ];

  Widget _hairStyleGrid(AvatarModel av) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: HairStyle.values.length,
      itemBuilder: (_, i) {
        final s = HairStyle.values[i];
        final active = s == av.hairStyle;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _update(av.copyWith(hairStyle: s));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: active
                  ? LinearGradient(
                      colors: [_kPurple.withAlpha(180), _kPink.withAlpha(140)])
                  : null,
              color: active ? null : Colors.white.withAlpha(8),
              border: Border.all(
                  color: active ? _kPurple : Colors.white.withAlpha(20)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 3),
              Text(s.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontSize: 10,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400)),
            ]),
          ),
        );
      },
    );
  }

  // ── Outfit ────────────────────────────────────────────────────────────────
  List<Widget> _outfitOptions(AvatarModel av) => [
    _sectionLabel('Mood Outfit'),
    GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: OutfitMood.values.length,
      itemBuilder: (_, i) {
        final mood = OutfitMood.values[i];
        final active = mood == av.outfitMood;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _update(av.copyWith(outfitMood: mood));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: active
                    ? [mood.gradient[0], mood.gradient[1]]
                    : [
                        mood.gradient[0].withAlpha(60),
                        mood.gradient[1].withAlpha(40),
                      ],
              ),
              border: Border.all(
                color: active
                    ? mood.gradient[0].withAlpha(200)
                    : Colors.white.withAlpha(15),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                mood.label,
                style: TextStyle(
                    color: active ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w400),
              ),
            ),
          ),
        );
      },
    ),
  ];

  // ── Accessories ───────────────────────────────────────────────────────────
  List<Widget> _accessoryOptions(AvatarModel av) {
    return [
      _sectionLabel('Accessories'),
      Text(
        'Tap to toggle accessories on your avatar.',
        style: TextStyle(
            color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: AccessoryType.values.map((acc) {
          final active = av.accessories.contains(acc);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              final list = List<AccessoryType>.from(av.accessories);
              if (active) {
                list.remove(acc);
              } else {
                list.add(acc);
              }
              _update(av.copyWith(accessories: list));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: active
                    ? const LinearGradient(colors: [_kGold, _kPink])
                    : null,
                color: active ? null : Colors.white.withAlpha(10),
                border: Border.all(
                    color: active ? _kGold : Colors.white.withAlpha(25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(acc.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(acc.label,
                      style: TextStyle(
                          color: active ? Colors.white : Colors.white60,
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ];
  }

  // ── Aura ──────────────────────────────────────────────────────────────────
  List<Widget> _auraOptions(AvatarModel av) => [
    _sectionLabel('Emotional Aura'),
    Text(
      'Your aura reflects your energy. It can also auto-update from your wellness data.',
      style: TextStyle(
          color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
    ),
    const SizedBox(height: 14),
    ...AuraStyle.values.map((aura) {
      final active = aura == av.auraStyle;
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _update(av.copyWith(auraStyle: aura));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: active
                ? LinearGradient(colors: [
                    aura.primaryColor.withAlpha(120),
                    aura.secondaryColor.withAlpha(60),
                  ])
                : null,
            color: active ? null : Colors.white.withAlpha(8),
            border: Border.all(
                color: active
                    ? aura.primaryColor.withAlpha(180)
                    : Colors.white.withAlpha(18)),
          ),
          child: Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  aura.primaryColor.withAlpha(200),
                  aura.secondaryColor.withAlpha(100),
                ]),
              ),
              child: Center(
                  child: Text(aura.emoji,
                      style: const TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(aura.label,
                  style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontSize: 14,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w400)),
            ),
            if (active)
              const Icon(Icons.check_circle_rounded,
                  color: _kPurple, size: 20),
          ]),
        ),
      );
    }),
  ];

  // ── Shared helper widgets ─────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text,
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3)),
  );

  Widget _skinToneRow(AvatarModel av) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: SkinTone.values.map((tone) {
          final active = tone == av.skinTone;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _update(av.copyWith(skinTone: tone));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 10),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tone.base,
                border: Border.all(
                    color: active ? _kPurple : Colors.transparent,
                    width: 2.5),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: _kPurple.withAlpha(120),
                            blurRadius: 10,
                            spreadRadius: 2)
                      ]
                    : null,
              ),
              child: active
                  ? Center(
                      child: Icon(Icons.check_rounded,
                          color: tone.base.computeLuminance() > 0.5
                              ? Colors.black54
                              : Colors.white70,
                          size: 16))
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chipRow<T>({
    required List<T> items,
    required T selected,
    required String Function(T) label,
    required Color Function(T) color,
    required void Function(T) onTap,
  }) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items.map((item) {
          final active = item == selected;
          final c = color(item);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(item);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: active
                    ? LinearGradient(
                        colors: [c, _kPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                color: active ? null : Colors.white.withAlpha(10),
                border: Border.all(
                    color: active ? c : Colors.white.withAlpha(20)),
              ),
              child: Text(
                label(item),
                style: TextStyle(
                    color: active ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _colorRow<T>({
    required List<T> items,
    required T selected,
    required Color Function(T) color,
    required String Function(T) label,
    required void Function(T) onTap,
  }) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items.map((item) {
          final active = item == selected;
          final c = color(item);
          return Tooltip(
            message: label(item),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(item);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(right: 10),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c,
                  border: Border.all(
                      color: active ? Colors.white : Colors.transparent,
                      width: 2.5),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: c.withAlpha(140),
                              blurRadius: 10,
                              spreadRadius: 2)
                        ]
                      : null,
                ),
                child: active
                    ? Center(
                        child: Icon(Icons.check_rounded,
                            color: c.computeLuminance() > 0.5
                                ? Colors.black54
                                : Colors.white,
                            size: 15))
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _toggleTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withAlpha(8),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Row(children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
        ),
        Switch.adaptive(
          value: value,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
          activeColor: _kPurple,
          inactiveThumbColor: Colors.white30,
          inactiveTrackColor: Colors.white10,
        ),
      ]),
    );
  }
}
