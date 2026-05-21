// ─────────────────────────────────────────────────────────────────────────────
//  LUNAR AVATAR PROVIDER
//  Manages avatar state, Firestore persistence, emotional-state auto-updates.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/avatar_model.dart';
import 'auth_provider.dart';

class AvatarProvider extends ChangeNotifier {
  AvatarModel? _avatar;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  AvatarModel? get avatar => _avatar;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  bool get hasAvatar => _avatar != null;

  static const _collection = 'avatars';

  // ── Load from Firestore ──────────────────────────────────────────────────
  Future<void> load(LunarAuthProvider auth) async {
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return;
    if (auth.isGuest) {
      // Guests get a local-only default avatar, no Firestore access
      if (_avatar == null) {
        _avatar = AvatarModel.defaultFor(uid);
        notifyListeners();
      }
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        _avatar = AvatarModel.fromMap(uid, doc.data()!);
      } else {
        _avatar = AvatarModel.defaultFor(uid);
      }
    } catch (e) {
      debugPrint('[AvatarProvider] load error: $e');
      _error = e.toString();
      _avatar = AvatarModel.defaultFor(uid);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Save to Firestore ────────────────────────────────────────────────────
  Future<void> save(LunarAuthProvider auth) async {
    final uid = auth.firebaseUser?.uid;
    if (uid == null || _avatar == null || auth.isGuest) return;

    _saving = true;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(uid)
          .set(_avatar!.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AvatarProvider] save error: $e');
      _error = e.toString();
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  // ── Optimistic local update + auto-save ──────────────────────────────────
  Future<void> update(AvatarModel updated, LunarAuthProvider auth) async {
    _avatar = updated;
    notifyListeners();
    await save(auth);
  }

  // ── Single-field helpers ─────────────────────────────────────────────────
  Future<void> setSkinTone(SkinTone v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(skinTone: v), auth);
  }

  Future<void> setEyeStyle(EyeStyle v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(eyeStyle: v), auth);
  }

  Future<void> setEyeColor(EyeColor v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(eyeColor: v), auth);
  }

  Future<void> setLipStyle(LipStyle v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(lipStyle: v), auth);
  }

  Future<void> setLipColor(LipColor v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(lipColor: v), auth);
  }

  Future<void> setBrowStyle(BrowStyle v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(browStyle: v), auth);
  }

  Future<void> setBlush(BlushLevel v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(blush: v), auth);
  }

  Future<void> setFreckles(bool v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(freckles: v), auth);
  }

  Future<void> setFaceShape(FaceShape v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(faceShape: v), auth);
  }

  Future<void> setHairStyle(HairStyle v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(hairStyle: v), auth);
  }

  Future<void> setHairColor(HairColor v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(hairColor: v), auth);
  }

  Future<void> setOutfitMood(OutfitMood v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(outfitMood: v), auth);
  }

  Future<void> toggleAccessory(AccessoryType a, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    final list = List<AccessoryType>.from(_avatar!.accessories);
    if (list.contains(a)) {
      list.remove(a);
    } else {
      list.add(a);
    }
    await update(_avatar!.copyWith(accessories: list), auth);
  }

  Future<void> setAura(AuraStyle v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(auraStyle: v), auth);
  }

  Future<void> setGender(AvatarGender v, LunarAuthProvider auth) async {
    if (_avatar == null) return;
    await update(_avatar!.copyWith(gender: v), auth);
  }

  // ── Emotional State Auto-Update ──────────────────────────────────────────
  /// Called by the app when wellness data changes (mood score, sleep hours,
  /// cycle phase, etc.).  Automatically selects the best EmotionalState and
  /// matching aura without overriding the user's chosen aura style.
  void updateEmotionalState({
    int? moodScore,       // 1-10
    double? sleepHours,   // hours last night
    bool? isPregnancy,
    bool? isHighEnergy,
  }) {
    if (_avatar == null) return;

    EmotionalState state;

    if (sleepHours != null && sleepHours < 5.5) {
      state = EmotionalState.sleepy;
    } else if (moodScore != null && moodScore >= 8) {
      state = isHighEnergy == true
          ? EmotionalState.energetic
          : EmotionalState.glowing;
    } else if (moodScore != null && moodScore >= 6) {
      state = EmotionalState.calm;
    } else if (moodScore != null && moodScore <= 3) {
      state = EmotionalState.low;
    } else if (isPregnancy == true) {
      state = EmotionalState.cozy;
    } else {
      state = EmotionalState.neutral;
    }

    if (_avatar!.emotionalState == state) return;

    // Update emotional state; aura follows if it's currently auto-managed
    final newAura = (state != EmotionalState.neutral)
        ? state.defaultAura
        : _avatar!.auraStyle;

    _avatar = _avatar!.copyWith(
      emotionalState: state,
      auraStyle: newAura,
    );
    notifyListeners();
    // Note: We intentionally do NOT call save() here to avoid hammering
    // Firestore on every wellness data change.  Emotional state is ephemeral
    // and will be persisted on the next explicit save.
  }

  // ── Ensure avatar exists for a uid ──────────────────────────────────────
  void ensureDefault(String uid) {
    if (_avatar == null) {
      _avatar = AvatarModel.defaultFor(uid);
      notifyListeners();
    }
  }

  // ── Reset ────────────────────────────────────────────────────────────────
  void clear() {
    _avatar = null;
    _error = null;
    notifyListeners();
  }
}
