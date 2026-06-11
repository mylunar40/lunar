// ─────────────────────────────────────────────────────────────────────────────
//  SELFIE AVATAR SERVICE
//  Takes a selfie → runs ML Kit face detection → pixel-samples skin/hair/lip
//  colours → returns a best-guess AvatarModel the user can then fine-tune.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/avatar_model.dart';

// ── Public result type ────────────────────────────────────────────────────────

enum SelfieAvatarStatus { success, noFaceFound, permissionDenied, cancelled, error }

class SelfieAvatarResult {
  final SelfieAvatarStatus status;
  final AvatarModel? avatar;
  final String? message;
  const SelfieAvatarResult(this.status, {this.avatar, this.message});
}

// ─────────────────────────────────────────────────────────────────────────────

class SelfieAvatarService {
  SelfieAvatarService._();

  static Future<SelfieAvatarResult> scanAndBuild(
      {AvatarModel? currentAvatar}) async {
    // ── 1. Capture selfie ─────────────────────────────────────────────────
    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
    } catch (_) {
      return const SelfieAvatarResult(SelfieAvatarStatus.permissionDenied,
          message: 'Camera permission required. Please allow in Settings.');
    }

    if (file == null) {
      return const SelfieAvatarResult(SelfieAvatarStatus.cancelled);
    }

    // ── 2. ML Kit face detection ──────────────────────────────────────────
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: true,
        enableClassification: true, // smile + eye-open probability
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    Face? face;
    try {
      final inputImage = InputImage.fromFile(File(file.path));
      final faces = await detector.processImage(inputImage);
      if (faces.isEmpty) {
        await detector.close();
        return const SelfieAvatarResult(SelfieAvatarStatus.noFaceFound,
            message: 'No face detected. Try better lighting and look straight at the camera.');
      }
      // Use the largest face
      face = faces.reduce((a, b) =>
          (a.boundingBox.width * a.boundingBox.height) >
                  (b.boundingBox.width * b.boundingBox.height)
              ? a
              : b);
    } catch (e) {
      await detector.close();
      return SelfieAvatarResult(SelfieAvatarStatus.error,
          message: 'Face detection failed: $e');
    }
    await detector.close();

    // ── 3. Decode image for pixel sampling ────────────────────────────────
    final bytes = await File(file.path).readAsBytes();
    ui.Image? uiImage;
    try {
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      uiImage = frame.image;
    } catch (_) {
      uiImage = null;
    }

    // ── 4. Map ML Kit data → AvatarModel ─────────────────────────────────
    final base = currentAvatar ?? _defaultAvatar();

    final skinTone = uiImage != null
        ? await _detectSkinTone(uiImage, face.boundingBox)
        : base.skinTone;

    final hairColor = uiImage != null
        ? await _detectHairColor(uiImage, face.boundingBox)
        : base.hairColor;

    final lipColor = uiImage != null
        ? await _detectLipColor(uiImage, face, uiImage.width, uiImage.height)
        : base.lipColor;

    final eyeStyle = _detectEyeStyle(face);
    final browStyle = _detectBrowStyle(face);
    final faceShape = _detectFaceShape(face);

    uiImage?.dispose();

    final result = base.copyWith(
      skinTone: skinTone,
      hairColor: hairColor,
      lipColor: lipColor,
      eyeStyle: eyeStyle,
      browStyle: browStyle,
      faceShape: faceShape,
      blush: BlushLevel.soft,
    );

    return SelfieAvatarResult(SelfieAvatarStatus.success, avatar: result);
  }

  // ── Skin tone detection ───────────────────────────────────────────────────

  static Future<SkinTone> _detectSkinTone(
      ui.Image img, Rect faceBB) async {
    // Sample a 12×12 grid from the central 50% of the face bounding box
    final sampleRect = Rect.fromCenter(
      center: faceBB.center,
      width: faceBB.width * 0.50,
      height: faceBB.height * 0.50,
    ).intersect(Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()));

    final pixels = await _sampleRect(img, sampleRect, gridSize: 10);
    if (pixels.isEmpty) return SkinTone.medium;

    // Average RGB
    int r = 0, g = 0, b = 0;
    for (final c in pixels) {
      r += c.red;
      g += c.green;
      b += c.blue;
    }
    r ~/= pixels.length;
    g ~/= pixels.length;
    b ~/= pixels.length;
    final avg = Color.fromARGB(255, r, g, b);

    // Find nearest SkinTone by comparing base colour distance
    return SkinTone.values.reduce((best, st) {
      return _colorDist(avg, st.base) < _colorDist(avg, best.base) ? st : best;
    });
  }

  // ── Hair colour detection ─────────────────────────────────────────────────

  static Future<HairColor> _detectHairColor(
      ui.Image img, Rect faceBB) async {
    // Sample region above the face bounding box
    final hairRect = Rect.fromLTWH(
      faceBB.left + faceBB.width * 0.2,
      math.max(0, faceBB.top - faceBB.height * 0.35),
      faceBB.width * 0.6,
      faceBB.height * 0.30,
    ).intersect(Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()));

    if (hairRect.isEmpty) return HairColor.darkBrown;

    final pixels = await _sampleRect(img, hairRect, gridSize: 8);
    if (pixels.isEmpty) return HairColor.darkBrown;

    int r = 0, g = 0, b = 0;
    for (final c in pixels) {
      r += c.red;
      g += c.green;
      b += c.blue;
    }
    r ~/= pixels.length;
    g ~/= pixels.length;
    b ~/= pixels.length;
    final avg = Color.fromARGB(255, r, g, b);

    return HairColor.values.reduce((best, hc) {
      return _colorDist(avg, hc.color) < _colorDist(avg, best.color) ? hc : best;
    });
  }

  // ── Lip colour detection ──────────────────────────────────────────────────

  static Future<LipColor> _detectLipColor(
      ui.Image img, Face face, int imgW, int imgH) async {
    // Use bottom-lip contour if available, else estimate from face centre
    final bottomLip = face.contours[FaceContourType.lowerLipBottom];
    Rect sampleRect;

    if (bottomLip != null && bottomLip.points.isNotEmpty) {
      double minX = double.infinity, minY = double.infinity;
      double maxX = 0, maxY = 0;
      for (final pt in bottomLip.points) {
        minX = math.min(minX, pt.x.toDouble());
        minY = math.min(minY, pt.y.toDouble());
        maxX = math.max(maxX, pt.x.toDouble());
        maxY = math.max(maxY, pt.y.toDouble());
      }
      sampleRect = Rect.fromLTRB(minX, minY, maxX, maxY + 4);
    } else {
      final bb = face.boundingBox;
      sampleRect = Rect.fromCenter(
        center: Offset(bb.center.dx, bb.bottom - bb.height * 0.18),
        width: bb.width * 0.30,
        height: bb.height * 0.08,
      );
    }

    sampleRect = sampleRect.intersect(
        Rect.fromLTWH(0, 0, imgW.toDouble(), imgH.toDouble()));
    if (sampleRect.isEmpty) return LipColor.nude;

    final pixels = await _sampleRect(img, sampleRect, gridSize: 6);
    if (pixels.isEmpty) return LipColor.nude;

    int r = 0, g = 0, b = 0;
    for (final c in pixels) {
      r += c.red;
      g += c.green;
      b += c.blue;
    }
    r ~/= pixels.length;
    g ~/= pixels.length;
    b ~/= pixels.length;
    final avg = Color.fromARGB(255, r, g, b);

    return LipColor.values.reduce((best, lc) {
      return _colorDist(avg, lc.color) < _colorDist(avg, best.color) ? lc : best;
    });
  }

  // ── Eye style from open-probability ──────────────────────────────────────

  static EyeStyle _detectEyeStyle(Face face) {
    final leftOpen = face.leftEyeOpenProbability ?? 0.8;
    final rightOpen = face.rightEyeOpenProbability ?? 0.8;
    final avg = (leftOpen + rightOpen) / 2.0;

    if (avg < 0.45) return EyeStyle.sleepy;
    if (avg > 0.92) return EyeStyle.bright;

    // Use face contour to determine almond vs round
    final eyeContour = face.contours[FaceContourType.leftEye];
    if (eyeContour != null && eyeContour.points.length >= 4) {
      final pts = eyeContour.points;
      double minX = pts.map((p) => p.x).reduce(math.min).toDouble();
      double maxX = pts.map((p) => p.x).reduce(math.max).toDouble();
      double minY = pts.map((p) => p.y).reduce(math.min).toDouble();
      double maxY = pts.map((p) => p.y).reduce(math.max).toDouble();
      final ratio = (maxX - minX) / ((maxY - minY) + 0.001);
      if (ratio > 2.8) return EyeStyle.almond;
    }
    return EyeStyle.round;
  }

  // ── Brow style from head tilt ─────────────────────────────────────────────

  static BrowStyle _detectBrowStyle(Face face) {
    final tilt = face.headEulerAngleZ ?? 0.0; // roll
    if (tilt.abs() > 6) return BrowStyle.arched;
    return BrowStyle.natural;
  }

  // ── Face shape from bounding box + contour ────────────────────────────────

  static FaceShape _detectFaceShape(Face face) {
    final bb = face.boundingBox;
    final ratio = bb.width / (bb.height + 0.001);

    final faceOval = face.contours[FaceContourType.face];
    if (faceOval != null && faceOval.points.length >= 6) {
      final pts = faceOval.points;
      // Jawline width vs cheekbone width heuristic
      final topY = pts.map((p) => p.y).reduce(math.min).toDouble();
      final botY = pts.map((p) => p.y).reduce(math.max).toDouble();
      final midY = (topY + botY) / 2;
      final cheekPts = pts.where((p) => (p.y - midY).abs() < (botY - topY) * 0.15).toList();
      final jawPts   = pts.where((p) => p.y > botY - (botY - topY) * 0.20).toList();

      if (cheekPts.isNotEmpty && jawPts.isNotEmpty) {
        final cheekW = cheekPts.map((p) => p.x).reduce(math.max).toDouble()
                     - cheekPts.map((p) => p.x).reduce(math.min).toDouble();
        final jawW   = jawPts.map((p) => p.x).reduce(math.max).toDouble()
                     - jawPts.map((p) => p.x).reduce(math.min).toDouble();
        final taper  = jawW / (cheekW + 0.001);
        if (taper < 0.65) return FaceShape.heart;
        if (taper > 0.90 && ratio > 0.90) return FaceShape.square;
        if (taper > 0.90 && ratio < 0.78) return FaceShape.oblong;
      }
    }

    if (ratio > 0.88 && ratio < 1.05) return FaceShape.round;
    if (ratio < 0.78) return FaceShape.oblong;
    return FaceShape.oval;
  }

  // ── Pixel sampling helper ─────────────────────────────────────────────────

  static Future<List<Color>> _sampleRect(
      ui.Image img, Rect rect, {int gridSize = 8}) async {
    if (rect.isEmpty || rect.width < 1 || rect.height < 1) return [];

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(img, Offset.zero, Paint());
    final picture = recorder.endRecording();

    // Render to a small image for pixel reading
    final sw = gridSize.toDouble();
    final sh = gridSize.toDouble();
    final scaleX = sw / rect.width;
    final scaleY = sh / rect.height;

    final recorder2 = ui.PictureRecorder();
    final canvas2 = Canvas(recorder2);
    canvas2.scale(scaleX, scaleY);
    canvas2.translate(-rect.left, -rect.top);
    canvas2.drawPicture(picture);
    final scaled = await recorder2.endRecording().toImage(gridSize, gridSize);

    final byteData = await scaled.toByteData(format: ui.ImageByteFormat.rawRgba);
    picture.dispose();
    scaled.dispose();

    if (byteData == null) return [];

    final colors = <Color>[];
    final buf = byteData.buffer.asUint8List();
    for (int i = 0; i < buf.length; i += 4) {
      colors.add(Color.fromARGB(buf[i + 3], buf[i], buf[i + 1], buf[i + 2]));
    }
    return colors;
  }

  // ── Colour distance (simple Euclidean in RGB) ─────────────────────────────

  static double _colorDist(Color a, Color b) {
    final dr = (a.red   - b.red).toDouble();
    final dg = (a.green - b.green).toDouble();
    final db = (a.blue  - b.blue).toDouble();
    return math.sqrt(dr * dr + dg * dg + db * db);
  }

  // ── Default avatar ────────────────────────────────────────────────────────

  static AvatarModel _defaultAvatar() => const AvatarModel(
    uid:         '',
    skinTone:    SkinTone.medium,
    hairStyle:   HairStyle.longStraight,
    hairColor:   HairColor.darkBrown,
    eyeStyle:    EyeStyle.round,
    eyeColor:    EyeColor.brown,
    lipColor:    LipColor.nude,
    browStyle:   BrowStyle.natural,
    faceShape:   FaceShape.oval,
    outfitMood:  OutfitMood.cozy,
    blush:       BlushLevel.soft,
    auraStyle:   AuraStyle.lunar,
    accessories: [],
    freckles:    false,
    emotionalState: EmotionalState.neutral,
  );
}
