// ─────────────────────────────────────────────────────────────────────────────
//  LUNAR AVATAR WIDGET
//  Semi-realistic emotional avatar rendered via CustomPainter.
//  Layered drawing: aura → body → neck → hair-back → head → face → hair-front
//                 → accessories
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/avatar_model.dart';

// ── Public Widget ─────────────────────────────────────────────────────────────

/// Renders a Lunar emotional avatar at the given [size].
/// Wraps the painter in a [RepaintBoundary] and a gentle pulse animation
/// when an aura is active.
class LunarAvatarWidget extends StatefulWidget {
  final AvatarModel avatar;
  final double size;
  final bool animate;
  final bool showAura;

  const LunarAvatarWidget({
    super.key,
    required this.avatar,
    this.size = 120,
    this.animate = true,
    this.showAura = true,
  });

  @override
  State<LunarAvatarWidget> createState() => _LunarAvatarWidgetState();
}

class _LunarAvatarWidgetState extends State<LunarAvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _auraAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _auraAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.animate &&
        widget.showAura &&
        widget.avatar.auraStyle != AuraStyle.none) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LunarAvatarWidget old) {
    super.didUpdateWidget(old);
    if (widget.animate && widget.showAura &&
        widget.avatar.auraStyle != AuraStyle.none) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _auraAnim,
        builder: (_, __) => CustomPaint(
          size: Size(widget.size, widget.size * 1.25),
          painter: _AvatarPainter(
            avatar: widget.avatar,
            auraIntensity: widget.showAura ? _auraAnim.value : 0,
          ),
        ),
      ),
    );
  }
}

// ── Tiny circular avatar (for community posts, comments) ─────────────────────

class LunarAvatarCircle extends StatelessWidget {
  final AvatarModel avatar;
  final double radius;
  final bool showAura;

  const LunarAvatarCircle({
    super.key,
    required this.avatar,
    this.radius = 22,
    this.showAura = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: LunarAvatarWidget(
          avatar: avatar,
          size: radius * 2,
          animate: showAura,
          showAura: showAura,
        ),
      ),
    );
  }
}

// ── Avatar Painter ────────────────────────────────────────────────────────────

class _AvatarPainter extends CustomPainter {
  final AvatarModel avatar;
  final double auraIntensity;

  const _AvatarPainter({required this.avatar, required this.auraIntensity});

  // ── Proportions (all relative to canvas size) ──────────────────────────
  // Canvas aspect ratio = 1 : 1.25 (width : height)
  //   e.g. 120 wide × 150 tall
  //
  //  Head centre:     (0.50, 0.28)
  //  Head rx/ry:       0.21 / 0.26  × w/h  (oval)
  //  Left eye:        (0.36, 0.27)
  //  Right eye:       (0.64, 0.27)
  //  Nose:            (0.50, 0.34)
  //  Mouth:           (0.50, 0.41)
  //  Neck top:        (0.44–0.56, 0.52)
  //  Shoulders top:    y = 0.62
  //  Body bottom:      y = 1.00

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (auraIntensity > 0) _drawAura(canvas, w, h);
    _drawBody(canvas, w, h);
    _drawNeck(canvas, w, h);
    _drawHairBack(canvas, w, h);
    _drawHead(canvas, w, h);
    _drawEars(canvas, w, h);
    _drawBrows(canvas, w, h);
    _drawEyes(canvas, w, h);
    _drawNose(canvas, w, h);
    _drawMouth(canvas, w, h);
    _drawBlush(canvas, w, h);
    if (avatar.freckles) _drawFreckles(canvas, w, h);
    _drawHairFront(canvas, w, h);
    _drawAccessories(canvas, w, h);
  }

  // ── Aura ─────────────────────────────────────────────────────────────────
  void _drawAura(Canvas canvas, double w, double h) {
    final style = avatar.auraStyle;
    if (style == AuraStyle.none) return;

    final cx = w * 0.50;
    final cy = h * 0.35;
    final radius = w * 0.60 * auraIntensity;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          style.primaryColor.withAlpha((150 * auraIntensity).round()),
          style.secondaryColor.withAlpha((60 * auraIntensity).round()),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.14);

    canvas.drawCircle(Offset(cx, cy), radius, paint);
  }

  // ── Body / Outfit ─────────────────────────────────────────────────────────
  void _drawBody(Canvas canvas, double w, double h) {
    final colors = avatar.outfitMood.gradient;
    final top = h * 0.60;

    // Shoulders curve
    final shoulderPath = Path()
      ..moveTo(w * 0.08, h)
      ..lineTo(w * 0.08, top + h * 0.04)
      ..quadraticBezierTo(w * 0.10, top, w * 0.22, top)
      ..lineTo(w * 0.78, top)
      ..quadraticBezierTo(w * 0.90, top, w * 0.92, top + h * 0.04)
      ..lineTo(w * 0.92, h)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, top, w, h - top));

    canvas.drawPath(shoulderPath, paint);

    // Subtle collar/neckline highlight
    final collarPaint = Paint()
      ..color = Colors.white.withAlpha(18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final collarPath = Path()
      ..moveTo(w * 0.38, top)
      ..quadraticBezierTo(w * 0.50, top + h * 0.04, w * 0.62, top);
    canvas.drawPath(collarPath, collarPaint);
  }

  // ── Neck ──────────────────────────────────────────────────────────────────
  void _drawNeck(Canvas canvas, double w, double h) {
    final skin = avatar.skinTone.base;
    final shadow = avatar.skinTone.shadow;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.43, h * 0.51, w * 0.57, h * 0.63),
      const Radius.circular(4),
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [shadow.withAlpha(200), skin, shadow.withAlpha(200)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTRB(w * 0.43, h * 0.51, w * 0.57, h * 0.63));

    canvas.drawRRect(rect, paint);
  }

  // ── Head ──────────────────────────────────────────────────────────────────
  void _drawHead(Canvas canvas, double w, double h) {
    final skin = avatar.skinTone.base;
    final shadow = avatar.skinTone.shadow;

    final (cx, cy, rx, ry) = _headOval(w, h);
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: rx * 2, height: ry * 2);

    // Soft skin gradient (lighter centre, gentle shadow at edges)
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.1, -0.2),
        radius: 0.85,
        colors: [
          _lighten(skin, 0.10),
          skin,
          shadow.withAlpha(220),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);

    canvas.drawOval(rect, paint);

    // Subtle jaw shadow
    final shadowPaint = Paint()
      ..color = shadow.withAlpha(50)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + ry * 0.15),
          width: rx * 1.8,
          height: ry * 1.4),
      shadowPaint,
    );
  }

  // ── Ears ──────────────────────────────────────────────────────────────────
  void _drawEars(Canvas canvas, double w, double h) {
    // Only visible for pixie / short-bob styles
    if (!_earsVisible) return;
    final skin = avatar.skinTone.base;
    final shadow = avatar.skinTone.shadow;
    final (cx, cy, rx, _) = _headOval(w, h);

    for (final side in [-1.0, 1.0]) {
      final ex = cx + side * (rx - w * 0.01);
      final ey = cy + h * 0.02;
      final earRect = Rect.fromCenter(
          center: Offset(ex, ey), width: w * 0.06, height: h * 0.07);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [skin, shadow],
        ).createShader(earRect);
      canvas.drawOval(earRect, paint);
    }
  }

  bool get _earsVisible =>
      avatar.hairStyle == HairStyle.pixie ||
      avatar.hairStyle == HairStyle.shortBob ||
      avatar.hairStyle == HairStyle.bun;

  // ── Eyes ──────────────────────────────────────────────────────────────────
  void _drawEyes(Canvas canvas, double w, double h) {
    final (lx, ly) = (w * 0.36, h * 0.268);
    final (rx, ry) = (w * 0.64, h * 0.268);

    _drawSingleEye(canvas, lx, ly, w, h, mirrorX: false);
    _drawSingleEye(canvas, rx, ry, w, h, mirrorX: true);
  }

  void _drawSingleEye(
      Canvas canvas, double cx, double cy, double w, double h,
      {required bool mirrorX}) {
    final ew = w * 0.115;
    final eh = h * 0.052;
    final irisColor = avatar.eyeColor.color;
    final isSleepy = avatar.eyeStyle == EyeStyle.sleepy ||
        avatar.emotionalState == EmotionalState.sleepy;
    final isBright = avatar.eyeStyle == EyeStyle.bright ||
        avatar.emotionalState == EmotionalState.glowing;

    canvas.save();
    canvas.translate(cx, cy);
    if (mirrorX) canvas.scale(-1, 1);

    final eyePath = _eyePath(ew, eh, isSleepy: isSleepy);

    // White of eye
    canvas.drawPath(
      eyePath,
      Paint()
        ..color = const Color(0xFFF5F0EC)
        ..style = PaintingStyle.fill,
    );

    // Iris with radial gradient
    final irisRect = Rect.fromCenter(
        center: Offset(0, 0), width: ew * 0.72, height: eh * (isSleepy ? 0.55 : 0.88));
    canvas.save();
    canvas.clipPath(eyePath);
    canvas.drawOval(
      irisRect,
      Paint()
        ..shader = RadialGradient(
          colors: [_lighten(irisColor, 0.25), irisColor, _darken(irisColor, 0.25)],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(irisRect),
    );

    // Pupil
    final pupilRadius = ew * 0.17;
    canvas.drawCircle(
      Offset(0, 0),
      pupilRadius,
      Paint()..color = const Color(0xFF0D0A08),
    );

    // Highlight (top-left sparkle)
    canvas.drawCircle(
      Offset(-pupilRadius * 0.6, -pupilRadius * 0.6),
      pupilRadius * (isBright ? 0.6 : 0.4),
      Paint()..color = Colors.white.withAlpha(230),
    );

    // Extra glow highlight for 'glowing' state
    if (isBright) {
      canvas.drawCircle(
        Offset(pupilRadius * 0.4, -pupilRadius * 0.3),
        pupilRadius * 0.3,
        Paint()..color = Colors.white.withAlpha(160),
      );
    }
    canvas.restore();

    // Eyelid outline / lash line
    final lashPaint = Paint()
      ..color = const Color(0xFF1A1010)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(eyePath, lashPaint);

    // Upper lash
    _drawLashes(canvas, ew, eh, isSleepy: isSleepy);

    canvas.restore();
  }

  Path _eyePath(double ew, double eh, {bool isSleepy = false}) {
    final style = avatar.eyeStyle;
    final path = Path();

    switch (style) {
      case EyeStyle.round:
        path.addOval(Rect.fromCenter(
            center: Offset.zero, width: ew, height: eh * 1.1));

      case EyeStyle.almond:
        path
          ..moveTo(-ew / 2, 0)
          ..quadraticBezierTo(-ew * 0.1, -eh * 0.95, ew / 2, 0)
          ..quadraticBezierTo(ew * 0.1, eh * 0.72, -ew / 2, 0)
          ..close();

      case EyeStyle.upturned:
        path
          ..moveTo(-ew / 2, eh * 0.1)
          ..quadraticBezierTo(0, -eh * 0.95, ew / 2, -eh * 0.2)
          ..quadraticBezierTo(ew * 0.1, eh * 0.68, -ew / 2, eh * 0.1)
          ..close();

      case EyeStyle.sleepy:
        path
          ..moveTo(-ew / 2, 0)
          ..quadraticBezierTo(0, -eh * 0.55, ew / 2, 0)
          ..quadraticBezierTo(0, eh * 0.55, -ew / 2, 0)
          ..close();

      case EyeStyle.bright:
        path.addOval(Rect.fromCenter(
            center: Offset.zero, width: ew * 1.1, height: eh * 1.2));

      case EyeStyle.soft:
        path
          ..moveTo(-ew / 2, 0)
          ..quadraticBezierTo(0, -eh * 0.80, ew / 2, 0)
          ..quadraticBezierTo(0, eh * 0.65, -ew / 2, 0)
          ..close();
    }

    // Sleepy state overrides with drooping lid
    if (isSleepy && style != EyeStyle.sleepy) {
      final p2 = Path()
        ..moveTo(-ew / 2, 0)
        ..quadraticBezierTo(0, -eh * 0.45, ew / 2, 0)
        ..quadraticBezierTo(0, eh * 0.45, -ew / 2, 0)
        ..close();
      return p2;
    }

    return path;
  }

  void _drawLashes(Canvas canvas, double ew, double eh,
      {bool isSleepy = false}) {
    final lashPaint = Paint()
      ..color = const Color(0xFF0D0808)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ew * 0.065
      ..strokeCap = StrokeCap.round;

    final lashCount = isSleepy ? 3 : 5;
    for (int i = 0; i < lashCount; i++) {
      final t = -0.35 + i * (0.70 / (lashCount - 1));
      final startX = ew * t;
      final startY = isSleepy ? -eh * 0.25 : -eh * 0.48;
      final endY = startY - eh * 0.28;
      final curve = (i - lashCount / 2).abs() * 0.03;
      canvas.drawLine(Offset(startX, startY),
          Offset(startX + ew * curve, endY), lashPaint);
    }
  }

  // ── Eyebrows ──────────────────────────────────────────────────────────────
  void _drawBrows(Canvas canvas, double w, double h) {
    final browColor = _darken(avatar.hairColor.color, 0.1);
    final browPaint = Paint()
      ..color = browColor.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.018;

    final isBold = avatar.browStyle == BrowStyle.bold;
    if (isBold) browPaint.strokeWidth = w * 0.026;
    if (avatar.browStyle == BrowStyle.thin) browPaint.strokeWidth = w * 0.012;

    for (final side in [-1.0, 1.0]) {
      final bx = w * (side < 0 ? 0.36 : 0.64);
      final by = h * 0.218;
      final bw = w * 0.095;

      canvas.save();
      canvas.translate(bx, by);
      if (side > 0) canvas.scale(-1, 1);

      final path = _browPath(bw, h, side: side);
      canvas.drawPath(path, browPaint);
      canvas.restore();
    }
  }

  Path _browPath(double bw, double h, {double side = -1}) {
    final bh = h * 0.018;
    switch (avatar.browStyle) {
      case BrowStyle.straight:
        return Path()
          ..moveTo(-bw / 2, 0)
          ..lineTo(bw / 2, 0);

      case BrowStyle.arched:
        return Path()
          ..moveTo(-bw / 2, bh * 0.5)
          ..quadraticBezierTo(0, -bh * 1.8, bw / 2, bh * 0.3);

      case BrowStyle.natural:
      case BrowStyle.softArch:
        return Path()
          ..moveTo(-bw / 2, bh * 0.3)
          ..quadraticBezierTo(0, -bh * 1.0, bw / 2, bh * 0.3);

      case BrowStyle.thin:
        return Path()
          ..moveTo(-bw / 2, 0)
          ..quadraticBezierTo(0, -bh * 0.8, bw / 2, 0);

      case BrowStyle.bold:
        return Path()
          ..moveTo(-bw / 2, bh * 0.4)
          ..quadraticBezierTo(0, -bh * 1.2, bw / 2, bh * 0.4);
    }
  }

  // ── Nose ──────────────────────────────────────────────────────────────────
  void _drawNose(Canvas canvas, double w, double h) {
    final shadow = avatar.skinTone.shadow;
    final nosePaint = Paint()
      ..color = shadow.withAlpha(140)
      ..strokeWidth = w * 0.01
      ..style = PaintingStyle.fill;

    // Two subtle nostril dots
    final nx = w * 0.50;
    final ny = h * 0.345;
    final dotR = w * 0.018;
    canvas.drawCircle(Offset(nx - w * 0.025, ny), dotR, nosePaint);
    canvas.drawCircle(Offset(nx + w * 0.025, ny), dotR, nosePaint);
  }

  // ── Mouth ─────────────────────────────────────────────────────────────────
  void _drawMouth(Canvas canvas, double w, double h) {
    final lipColor = avatar.lipColor.color;
    final mx = w * 0.50;
    final my = h * 0.415;
    final mw = w * 0.11;

    // Emotional state modifiers
    final isHappy = avatar.emotionalState == EmotionalState.happy ||
        avatar.emotionalState == EmotionalState.glowing;
    final isLow = avatar.emotionalState == EmotionalState.low;
    final curvature = isHappy ? 0.022 : (isLow ? -0.014 : 0.010);

    // Upper lip
    final upperPath = Path()
      ..moveTo(mx - mw, my)
      ..quadraticBezierTo(mx - mw * 0.5, my - h * 0.014, mx, my - h * 0.006)
      ..quadraticBezierTo(mx + mw * 0.5, my - h * 0.014, mx + mw, my);

    // Lower lip
    final lowerPath = Path()
      ..moveTo(mx - mw * 0.85, my + h * 0.003)
      ..quadraticBezierTo(mx, my + h * curvature * 1.6, mx + mw * 0.85, my + h * 0.003);

    // Fill lower lip
    final fullLipPath = Path()
      ..addPath(upperPath, Offset.zero)
      ..lineTo(mx + mw * 0.85, my + h * 0.003)
      ..quadraticBezierTo(mx, my + h * curvature * 1.6, mx - mw * 0.85, my + h * 0.003)
      ..close();

    canvas.drawPath(
      fullLipPath,
      Paint()
        ..color = lipColor
        ..style = PaintingStyle.fill,
    );

    // Lip highlight
    canvas.drawPath(
      upperPath,
      Paint()
        ..color = Colors.white.withAlpha(35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.008
        ..strokeCap = StrokeCap.round,
    );

    // Lip line
    canvas.drawPath(
      upperPath,
      Paint()
        ..color = _darken(lipColor, 0.15).withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.007
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── Blush ─────────────────────────────────────────────────────────────────
  void _drawBlush(Canvas canvas, double w, double h) {
    final opacity = avatar.blush.opacity;
    if (opacity == 0) return;

    final blushColor = const Color(0xFFFF9EB5).withAlpha((255 * opacity).round());
    final blushPaint = Paint()
      ..color = blushColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.06);

    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.285, h * 0.315),
            width: w * 0.11,
            height: h * 0.055),
        blushPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.715, h * 0.315),
            width: w * 0.11,
            height: h * 0.055),
        blushPaint);
  }

  // ── Freckles ──────────────────────────────────────────────────────────────
  void _drawFreckles(Canvas canvas, double w, double h) {
    final color = avatar.skinTone.shadow.withAlpha(100);
    final paint = Paint()..color = color;
    final positions = [
      (0.34, 0.295), (0.41, 0.285), (0.47, 0.300),
      (0.53, 0.300), (0.59, 0.285), (0.66, 0.295),
      (0.38, 0.310), (0.62, 0.310), (0.44, 0.320), (0.56, 0.320),
    ];
    for (final (fx, fy) in positions) {
      canvas.drawCircle(Offset(w * fx, h * fy), w * 0.008, paint);
    }
  }

  // ── Hair (back layer, behind head) ────────────────────────────────────────
  void _drawHairBack(Canvas canvas, double w, double h) {
    final style = avatar.hairStyle;
    final hairColor = avatar.hairColor.color;
    final highlight = avatar.hairColor.highlight;
    final (cx, cy, rx, ry) = _headOval(w, h);

    // Shared gradient paint factory
    Paint _hairPaint(Rect rect) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [highlight, hairColor, _darken(hairColor, 0.12)],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    switch (style) {
      case HairStyle.longStraight:
        final rect = Rect.fromLTRB(cx - rx * 1.08, cy - ry * 0.95, cx + rx * 1.08, h);
        final path = Path()
          ..moveTo(cx - rx * 1.08, cy + ry * 0.15)
          ..quadraticBezierTo(cx - rx * 1.20, cy + ry * 0.5, cx - rx * 1.10, h)
          ..lineTo(cx + rx * 1.10, h)
          ..quadraticBezierTo(cx + rx * 1.20, cy + ry * 0.5, cx + rx * 1.08, cy + ry * 0.15)
          ..arcTo(rect, math.pi * 0.85, -math.pi * 0.70, false)
          ..close();
        canvas.drawPath(path, _hairPaint(rect));

      case HairStyle.longWavy:
        final rect = Rect.fromLTRB(cx - rx * 1.12, cy - ry * 0.95, cx + rx * 1.12, h);
        final path = Path()
          ..moveTo(cx - rx * 1.12, cy + ry * 0.20)
          ..quadraticBezierTo(cx - rx * 1.30, cy + ry * 0.6, cx - rx * 1.15, cy + ry * 1.1)
          ..quadraticBezierTo(cx - rx * 1.00, cy + ry * 1.5, cx - rx * 1.20, h)
          ..lineTo(cx + rx * 1.20, h)
          ..quadraticBezierTo(cx + rx * 1.00, cy + ry * 1.5, cx + rx * 1.15, cy + ry * 1.1)
          ..quadraticBezierTo(cx + rx * 1.30, cy + ry * 0.6, cx + rx * 1.12, cy + ry * 0.20)
          ..arcTo(rect, math.pi * 0.82, -math.pi * 0.64, false)
          ..close();
        canvas.drawPath(path, _hairPaint(rect));

      case HairStyle.curlySoft:
        final rect = Rect.fromLTRB(cx - rx * 1.22, cy - ry * 1.10, cx + rx * 1.22, h);
        // Draw several overlapping curly ovals on sides
        for (int i = 0; i < 5; i++) {
          final t = i / 4.0;
          final sideOval = Rect.fromCenter(
              center: Offset(cx - rx * 1.10, cy + ry * (-0.5 + t * 2.0)),
              width: rx * 0.60,
              height: ry * 0.55);
          canvas.drawOval(sideOval, _hairPaint(rect));
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(cx + rx * 1.10, cy + ry * (-0.5 + t * 2.0)),
                  width: rx * 0.60,
                  height: ry * 0.55),
              _hairPaint(rect));
        }

      case HairStyle.shortBob:
        final rect = Rect.fromLTRB(cx - rx * 1.06, cy - ry * 0.90, cx + rx * 1.06, cy + ry * 1.6);
        final path = Path()
          ..moveTo(cx - rx * 1.06, cy + ry * 0.20)
          ..quadraticBezierTo(cx - rx * 1.14, cy + ry * 0.8, cx - rx * 0.90, cy + ry * 1.55)
          ..lineTo(cx + rx * 0.90, cy + ry * 1.55)
          ..quadraticBezierTo(cx + rx * 1.14, cy + ry * 0.8, cx + rx * 1.06, cy + ry * 0.20)
          ..arcTo(rect, math.pi * 0.85, -math.pi * 0.70, false)
          ..close();
        canvas.drawPath(path, _hairPaint(rect));

      case HairStyle.braids:
        final rect = Rect.fromLTRB(cx - rx * 0.95, cy, cx + rx * 0.95, h);
        for (final side in [-1.0, 1.0]) {
          final bx = cx + side * rx * 0.72;
          final path = Path()
            ..moveTo(bx - w * 0.04, cy + ry * 0.8)
            ..lineTo(bx - w * 0.04, h)
            ..lineTo(bx + w * 0.04, h)
            ..lineTo(bx + w * 0.04, cy + ry * 0.8)
            ..close();
          canvas.drawPath(path, _hairPaint(rect));
          // Braid pattern
          final braidPaint = Paint()
            ..color = highlight.withAlpha(80)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.006;
          for (int i = 0; i < 6; i++) {
            final ty = cy + ry * 0.8 + (h - cy - ry * 0.8) * (i / 6.0);
            canvas.drawLine(Offset(bx - w * 0.04, ty), Offset(bx + w * 0.04, ty), braidPaint);
          }
        }

      case HairStyle.halfUp:
        // Lower half flows down
        final rect = Rect.fromLTRB(cx - rx * 1.06, cy - ry * 0.8, cx + rx * 1.06, h);
        final path = Path()
          ..moveTo(cx - rx * 1.06, cy + ry * 0.15)
          ..quadraticBezierTo(cx - rx * 1.15, cy + ry * 0.5, cx - rx * 1.05, h)
          ..lineTo(cx + rx * 1.05, h)
          ..quadraticBezierTo(cx + rx * 1.15, cy + ry * 0.5, cx + rx * 1.06, cy + ry * 0.15)
          ..arcTo(rect, math.pi * 0.85, -math.pi * 0.70, false)
          ..close();
        canvas.drawPath(path, _hairPaint(rect));

      case HairStyle.ponytail:
        // Draw a back tail
        final tailPath = Path()
          ..moveTo(cx - w * 0.05, cy - ry * 0.50)
          ..quadraticBezierTo(cx + rx * 1.30, cy + ry * 0.20, cx + rx * 0.80, h * 0.85)
          ..lineTo(cx + rx * 0.60, h * 0.85)
          ..quadraticBezierTo(cx + rx * 0.95, cy + ry * 0.20, cx + w * 0.05, cy - ry * 0.50)
          ..close();
        final tailRect = Rect.fromLTRB(cx - w * 0.05, cy - ry * 0.5, cx + rx * 1.30, h);
        canvas.drawPath(tailPath, _hairPaint(tailRect));

      case HairStyle.bun:
      case HairStyle.pixie:
        // No back layer needed; handled in front layer
        break;
    }
  }

  // ── Hair (front layer, on top of head/face) ────────────────────────────────
  void _drawHairFront(Canvas canvas, double w, double h) {
    final style = avatar.hairStyle;
    final hairColor = avatar.hairColor.color;
    final highlight = avatar.hairColor.highlight;
    final (cx, cy, rx, ry) = _headOval(w, h);

    Paint _hairPaint(Rect rect) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [highlight, hairColor, _darken(hairColor, 0.12)],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    final topRect = Rect.fromLTRB(cx - rx * 1.10, cy - ry, cx + rx * 1.10, cy - ry * 0.50);

    switch (style) {
      case HairStyle.longStraight:
      case HairStyle.shortBob:
      case HairStyle.braids:
      case HairStyle.halfUp:
      case HairStyle.longWavy:
        // Straight/flat top cap
        _drawHairCap(canvas, cx, cy, rx, ry, _hairPaint(topRect));

      case HairStyle.curlySoft:
        // Curly top with bumps
        _drawCurlyTop(canvas, cx, cy, rx, ry, hairColor, highlight);

      case HairStyle.bun:
        // Bun circle on top
        _drawHairCap(canvas, cx, cy, rx, ry, _hairPaint(topRect));
        final bunRect = Rect.fromCenter(
            center: Offset(cx, cy - ry * 1.10),
            width: rx * 0.90,
            height: ry * 0.72);
        canvas.drawOval(bunRect,
            _hairPaint(Rect.fromLTRB(cx - rx * 0.5, cy - ry * 1.5, cx + rx * 0.5, cy - ry * 0.8)));

      case HairStyle.ponytail:
        _drawHairCap(canvas, cx, cy, rx, ry, _hairPaint(topRect));

      case HairStyle.pixie:
        // Short cap hugging head
        final pixieRect = Rect.fromCenter(
            center: Offset(cx, cy - ry * 0.10),
            width: rx * 2.10,
            height: ry * 1.55);
        final pixiePath = Path()
          ..addOval(pixieRect);
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(0, 0, w, cy + ry * 0.4));
        canvas.drawPath(pixiePath, _hairPaint(pixieRect));
        canvas.restore();

      case HairStyle.halfUp:
        // Top bun/twist
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx, cy - ry * 0.80),
                width: rx * 0.70,
                height: ry * 0.45),
            _hairPaint(topRect));
    }
  }

  void _drawHairCap(Canvas canvas, double cx, double cy, double rx, double ry,
      Paint paint) {
    // Semi-circle cap at the top of the head
    final path = Path()
      ..addArc(
          Rect.fromCenter(
              center: Offset(cx, cy), width: rx * 2.12, height: ry * 2.08),
          math.pi,
          math.pi);
    canvas.drawPath(path, paint);
  }

  void _drawCurlyTop(Canvas canvas, double cx, double cy, double rx, double ry,
      Color hairColor, Color highlight) {
    final rect =
        Rect.fromCenter(center: Offset(cx, cy - ry * 0.6), width: rx * 2.4, height: ry * 1.4);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [highlight, hairColor, _darken(hairColor, 0.1)],
      ).createShader(rect);

    // Multiple bumpy ovals simulate curls across the top
    for (int i = 0; i < 6; i++) {
      final t = i / 5.0;
      final bx = (cx - rx * 1.0) + t * rx * 2.0;
      final by = cy - ry * (0.80 + 0.20 * math.sin(t * math.pi));
      canvas.drawOval(
          Rect.fromCenter(center: Offset(bx, by), width: rx * 0.62, height: ry * 0.55),
          paint);
    }
  }

  // ── Accessories ───────────────────────────────────────────────────────────
  void _drawAccessories(Canvas canvas, double w, double h) {
    for (final acc in avatar.accessories) {
      switch (acc) {
        case AccessoryType.moonEarrings:
          _drawMoonEarrings(canvas, w, h);
        case AccessoryType.starEarrings:
          _drawStarEarrings(canvas, w, h);
        case AccessoryType.moonCrown:
          _drawMoonCrown(canvas, w, h);
        case AccessoryType.glasses:
          _drawGlasses(canvas, w, h);
        case AccessoryType.starHairpin:
          _drawStarHairpin(canvas, w, h);
        case AccessoryType.necklace:
          _drawNecklace(canvas, w, h);
        case AccessoryType.sleepyBow:
          _drawSleepyBow(canvas, w, h);
      }
    }
  }

  void _drawMoonEarrings(Canvas canvas, double w, double h) {
    final color = const Color(0xFFFFD700);
    final (cx, cy, rx, _) = _headOval(w, h);
    for (final side in [-1.0, 1.0]) {
      final ex = cx + side * (rx + w * 0.03);
      final ey = cy + h * 0.05;
      final paint = Paint()..color = color;
      // Crescent shape
      canvas.drawCircle(Offset(ex, ey + h * 0.02), w * 0.022, paint);
      canvas.drawCircle(
          Offset(ex + side * w * 0.010, ey),
          w * 0.018,
          Paint()..color = const Color(0xFF0A0118));
    }
  }

  void _drawStarEarrings(Canvas canvas, double w, double h) {
    final color = const Color(0xFFFFD700);
    final (cx, cy, rx, _) = _headOval(w, h);
    for (final side in [-1.0, 1.0]) {
      final ex = cx + side * (rx + w * 0.02);
      final ey = cy + h * 0.05;
      _drawStar(canvas, Offset(ex, ey), w * 0.020, color);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final radius = i.isEven ? r : r * 0.4;
      final pt = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawMoonCrown(Canvas canvas, double w, double h) {
    final (cx, cy, _, ry) = _headOval(w, h);
    final goldPaint = Paint()..color = const Color(0xFFFFD700);
    final ty = cy - ry * 1.08;

    // Three moon arcs
    for (final (dx, scale) in [(-w * 0.10, 0.75), (0.0, 1.0), (w * 0.10, 0.75)]) {
      canvas.drawCircle(Offset(cx + dx, ty - h * 0.02 * scale), w * 0.028 * scale, goldPaint);
      canvas.drawCircle(
          Offset(cx + dx + w * 0.018 * scale, ty - h * 0.025 * scale),
          w * 0.022 * scale,
          Paint()..color = const Color(0xFF0A0118));
    }
  }

  void _drawGlasses(Canvas canvas, double w, double h) {
    final glassPaint = Paint()
      ..color = const Color(0xFFAB5CF2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;

    final (lx, ly) = (w * 0.36, h * 0.268);
    final gw = w * 0.100;
    final gh = h * 0.046;

    // Left lens
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(lx, ly), width: gw, height: gh),
          Radius.circular(gh * 0.4)),
      glassPaint,
    );
    // Right lens
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w - lx, ly), width: gw, height: gh),
          Radius.circular(gh * 0.4)),
      glassPaint,
    );
    // Bridge
    canvas.drawLine(
        Offset(lx + gw / 2, ly), Offset(w - lx - gw / 2, ly), glassPaint);
  }

  void _drawStarHairpin(Canvas canvas, double w, double h) {
    final (cx, cy, rx, ry) = _headOval(w, h);
    _drawStar(canvas, Offset(cx + rx * 0.60, cy - ry * 0.72),
        w * 0.030, const Color(0xFFFFD700));
  }

  void _drawNecklace(Canvas canvas, double w, double h) {
    final neckPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012;

    final ny = h * 0.63;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.50, ny - h * 0.012),
            width: w * 0.28,
            height: h * 0.04),
        0,
        math.pi,
        false,
        neckPaint);
    // Small pendant
    canvas.drawCircle(
        Offset(w * 0.50, ny + h * 0.008),
        w * 0.015,
        Paint()..color = const Color(0xFFFFD700));
  }

  void _drawSleepyBow(Canvas canvas, double w, double h) {
    final (cx, cy, rx, ry) = _headOval(w, h);
    final bx = cx + rx * 0.48;
    final by = cy - ry * 0.68;
    final bowPaint = Paint()..color = const Color(0xFFFF69B4);

    // Two triangles = bow
    canvas.drawPath(
      Path()
        ..moveTo(bx - w * 0.03, by)
        ..lineTo(bx - w * 0.08, by - h * 0.025)
        ..lineTo(bx - w * 0.08, by + h * 0.025)
        ..close(),
      bowPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(bx + w * 0.03, by)
        ..lineTo(bx + w * 0.08, by - h * 0.025)
        ..lineTo(bx + w * 0.08, by + h * 0.025)
        ..close(),
      bowPaint,
    );
    canvas.drawCircle(Offset(bx, by), w * 0.016, bowPaint);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns (centerX, centerY, radiusX, radiusY) of the head oval.
  (double, double, double, double) _headOval(double w, double h) {
    return (w * 0.50, h * 0.285, w * 0.205, h * 0.245);
  }

  Color _lighten(Color c, double amount) {
    return Color.fromARGB(
      c.alpha,
      (c.red + (255 - c.red) * amount).round().clamp(0, 255),
      (c.green + (255 - c.green) * amount).round().clamp(0, 255),
      (c.blue + (255 - c.blue) * amount).round().clamp(0, 255),
    );
  }

  Color _darken(Color c, double amount) {
    return Color.fromARGB(
      c.alpha,
      (c.red * (1 - amount)).round().clamp(0, 255),
      (c.green * (1 - amount)).round().clamp(0, 255),
      (c.blue * (1 - amount)).round().clamp(0, 255),
    );
  }

  @override
  bool shouldRepaint(_AvatarPainter old) =>
      old.avatar != avatar || old.auraIntensity != auraIntensity;
}
