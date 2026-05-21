// ─────────────────────────────────────────────────────────────────────────────
//  LUNAR AVATAR MODEL
//  All enums and the AvatarModel data class used by the avatar system.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── Skin Tone ─────────────────────────────────────────────────────────────────

enum SkinTone { porcelain, fair, light, medium, tan, caramel, warm, deep, ebony }

extension SkinToneX on SkinTone {
  Color get base {
    switch (this) {
      case SkinTone.porcelain: return const Color(0xFFFFF0E6);
      case SkinTone.fair:      return const Color(0xFFFADCC9);
      case SkinTone.light:     return const Color(0xFFF4C4A1);
      case SkinTone.medium:    return const Color(0xFFE8A87C);
      case SkinTone.tan:       return const Color(0xFFD4885C);
      case SkinTone.caramel:   return const Color(0xFFC06B3A);
      case SkinTone.warm:      return const Color(0xFFAA5530);
      case SkinTone.deep:      return const Color(0xFF7D3E20);
      case SkinTone.ebony:     return const Color(0xFF4A2210);
    }
  }

  Color get shadow {
    switch (this) {
      case SkinTone.porcelain: return const Color(0xFFD4B8A8);
      case SkinTone.fair:      return const Color(0xFFCDA48A);
      case SkinTone.light:     return const Color(0xFFC09070);
      case SkinTone.medium:    return const Color(0xFFB07050);
      case SkinTone.tan:       return const Color(0xFFA05030);
      case SkinTone.caramel:   return const Color(0xFF904020);
      case SkinTone.warm:      return const Color(0xFF803010);
      case SkinTone.deep:      return const Color(0xFF5A2A10);
      case SkinTone.ebony:     return const Color(0xFF2A1008);
    }
  }
}

// ── Face Shape ────────────────────────────────────────────────────────────────

enum FaceShape { oval, round, heart, square, diamond, oblong }

extension FaceShapeX on FaceShape {
  String get label {
    switch (this) {
      case FaceShape.oval:    return 'Oval';
      case FaceShape.round:   return 'Round';
      case FaceShape.heart:   return 'Heart';
      case FaceShape.square:  return 'Square';
      case FaceShape.diamond: return 'Diamond';
      case FaceShape.oblong:  return 'Oblong';
    }
  }
}

// ── Eye Style ─────────────────────────────────────────────────────────────────

enum EyeStyle { round, almond, upturned, sleepy, bright, soft }

extension EyeStyleX on EyeStyle {
  String get label {
    switch (this) {
      case EyeStyle.round:    return 'Round';
      case EyeStyle.almond:   return 'Almond';
      case EyeStyle.upturned: return 'Upturned';
      case EyeStyle.sleepy:   return 'Sleepy';
      case EyeStyle.bright:   return 'Bright';
      case EyeStyle.soft:     return 'Soft';
    }
  }
}

// ── Eye Color ─────────────────────────────────────────────────────────────────

enum EyeColor { brown, hazel, green, blue, grey, amber, violet, black }

extension EyeColorX on EyeColor {
  Color get color {
    switch (this) {
      case EyeColor.brown:  return const Color(0xFF6B3A2A);
      case EyeColor.hazel:  return const Color(0xFF8B6914);
      case EyeColor.green:  return const Color(0xFF3A7A42);
      case EyeColor.blue:   return const Color(0xFF3A72B8);
      case EyeColor.grey:   return const Color(0xFF7A8A9A);
      case EyeColor.amber:  return const Color(0xFFB8780A);
      case EyeColor.violet: return const Color(0xFF7A3AAA);
      case EyeColor.black:  return const Color(0xFF1A0A08);
    }
  }

  String get label {
    switch (this) {
      case EyeColor.brown:  return 'Brown';
      case EyeColor.hazel:  return 'Hazel';
      case EyeColor.green:  return 'Green';
      case EyeColor.blue:   return 'Blue';
      case EyeColor.grey:   return 'Grey';
      case EyeColor.amber:  return 'Amber';
      case EyeColor.violet: return 'Violet';
      case EyeColor.black:  return 'Black';
    }
  }
}

// ── Brow Style ────────────────────────────────────────────────────────────────

enum BrowStyle { natural, straight, arched, softArch, thin, bold }

extension BrowStyleX on BrowStyle {
  String get label {
    switch (this) {
      case BrowStyle.natural:  return 'Natural';
      case BrowStyle.straight: return 'Straight';
      case BrowStyle.arched:   return 'Arched';
      case BrowStyle.softArch: return 'Soft Arch';
      case BrowStyle.thin:     return 'Thin';
      case BrowStyle.bold:     return 'Bold';
    }
  }
}

// ── Lip Style ─────────────────────────────────────────────────────────────────

enum LipStyle { natural, full, cupid, thin, glossy, matte }

extension LipStyleX on LipStyle {
  String get label {
    switch (this) {
      case LipStyle.natural: return 'Natural';
      case LipStyle.full:    return 'Full';
      case LipStyle.cupid:   return 'Cupid';
      case LipStyle.thin:    return 'Thin';
      case LipStyle.glossy:  return 'Glossy';
      case LipStyle.matte:   return 'Matte';
    }
  }
}

// ── Lip Color ─────────────────────────────────────────────────────────────────

enum LipColor { nude, rose, berry, red, coral, mauve, burgundy, lavender }

extension LipColorX on LipColor {
  Color get color {
    switch (this) {
      case LipColor.nude:     return const Color(0xFFD4956A);
      case LipColor.rose:     return const Color(0xFFE87890);
      case LipColor.berry:    return const Color(0xFF993366);
      case LipColor.red:      return const Color(0xFFCC2230);
      case LipColor.coral:    return const Color(0xFFFF6648);
      case LipColor.mauve:    return const Color(0xFFB06680);
      case LipColor.burgundy: return const Color(0xFF7A1A2E);
      case LipColor.lavender: return const Color(0xFF9980CC);
    }
  }

  String get label {
    switch (this) {
      case LipColor.nude:     return 'Nude';
      case LipColor.rose:     return 'Rose';
      case LipColor.berry:    return 'Berry';
      case LipColor.red:      return 'Red';
      case LipColor.coral:    return 'Coral';
      case LipColor.mauve:    return 'Mauve';
      case LipColor.burgundy: return 'Burgundy';
      case LipColor.lavender: return 'Lavender';
    }
  }
}

// ── Blush Level ───────────────────────────────────────────────────────────────

enum BlushLevel { none, subtle, soft, medium, bold }

extension BlushLevelX on BlushLevel {
  String get label {
    switch (this) {
      case BlushLevel.none:   return 'None';
      case BlushLevel.subtle: return 'Subtle';
      case BlushLevel.soft:   return 'Soft';
      case BlushLevel.medium: return 'Medium';
      case BlushLevel.bold:   return 'Bold';
    }
  }

  double get opacity {
    switch (this) {
      case BlushLevel.none:   return 0.0;
      case BlushLevel.subtle: return 0.12;
      case BlushLevel.soft:   return 0.22;
      case BlushLevel.medium: return 0.36;
      case BlushLevel.bold:   return 0.52;
    }
  }
}

// ── Hair Style ────────────────────────────────────────────────────────────────

enum HairStyle {
  longStraight,
  longWavy,
  curlySoft,
  shortBob,
  braids,
  halfUp,
  ponytail,
  bun,
  pixie,
}

extension HairStyleX on HairStyle {
  String get label {
    switch (this) {
      case HairStyle.longStraight: return 'Long Straight';
      case HairStyle.longWavy:     return 'Long Wavy';
      case HairStyle.curlySoft:    return 'Curly';
      case HairStyle.shortBob:     return 'Short Bob';
      case HairStyle.braids:       return 'Braids';
      case HairStyle.halfUp:       return 'Half Up';
      case HairStyle.ponytail:     return 'Ponytail';
      case HairStyle.bun:          return 'Bun';
      case HairStyle.pixie:        return 'Pixie';
    }
  }

  String get emoji {
    switch (this) {
      case HairStyle.longStraight: return '💇';
      case HairStyle.longWavy:     return '🌊';
      case HairStyle.curlySoft:    return '🌀';
      case HairStyle.shortBob:     return '✂️';
      case HairStyle.braids:       return '🪢';
      case HairStyle.halfUp:       return '🎀';
      case HairStyle.ponytail:     return '🐎';
      case HairStyle.bun:          return '🍡';
      case HairStyle.pixie:        return '✨';
    }
  }
}

// ── Hair Color ────────────────────────────────────────────────────────────────

enum HairColor {
  black,
  darkBrown,
  brown,
  lightBrown,
  auburn,
  blonde,
  platinum,
  red,
  pink,
  purple,
}

extension HairColorX on HairColor {
  Color get color {
    switch (this) {
      case HairColor.black:      return const Color(0xFF0A0808);
      case HairColor.darkBrown:  return const Color(0xFF2A1A0E);
      case HairColor.brown:      return const Color(0xFF6B3A1E);
      case HairColor.lightBrown: return const Color(0xFFA06030);
      case HairColor.auburn:     return const Color(0xFF8B2A1A);
      case HairColor.blonde:     return const Color(0xFFD4A820);
      case HairColor.platinum:   return const Color(0xFFE8E0D8);
      case HairColor.red:        return const Color(0xFFCC2010);
      case HairColor.pink:       return const Color(0xFFEE6090);
      case HairColor.purple:     return const Color(0xFF7A30AA);
    }
  }

  Color get highlight {
    switch (this) {
      case HairColor.black:      return const Color(0xFF302828);
      case HairColor.darkBrown:  return const Color(0xFF5A3A20);
      case HairColor.brown:      return const Color(0xFF9A5A30);
      case HairColor.lightBrown: return const Color(0xFFD08050);
      case HairColor.auburn:     return const Color(0xFFBB5A38);
      case HairColor.blonde:     return const Color(0xFFEED060);
      case HairColor.platinum:   return const Color(0xFFF8F5F0);
      case HairColor.red:        return const Color(0xFFEE5040);
      case HairColor.pink:       return const Color(0xFFF898C0);
      case HairColor.purple:     return const Color(0xFFAA60D8);
    }
  }

  String get label {
    switch (this) {
      case HairColor.black:      return 'Black';
      case HairColor.darkBrown:  return 'Dark Brown';
      case HairColor.brown:      return 'Brown';
      case HairColor.lightBrown: return 'Light Brown';
      case HairColor.auburn:     return 'Auburn';
      case HairColor.blonde:     return 'Blonde';
      case HairColor.platinum:   return 'Platinum';
      case HairColor.red:        return 'Red';
      case HairColor.pink:       return 'Pink';
      case HairColor.purple:     return 'Purple';
    }
  }
}

// ── Outfit Mood ────────────────────────────────────────────────────────────────

enum OutfitMood { cozy, dreamy, bold, mystical, fresh, celestial, earthy, edgy }

extension OutfitMoodX on OutfitMood {
  String get label {
    switch (this) {
      case OutfitMood.cozy:      return '🧸 Cozy';
      case OutfitMood.dreamy:    return '🌙 Dreamy';
      case OutfitMood.bold:      return '🔥 Bold';
      case OutfitMood.mystical:  return '🔮 Mystical';
      case OutfitMood.fresh:     return '🌸 Fresh';
      case OutfitMood.celestial: return '⭐ Celestial';
      case OutfitMood.earthy:    return '🌿 Earthy';
      case OutfitMood.edgy:      return '🖤 Edgy';
    }
  }

  List<Color> get gradient {
    switch (this) {
      case OutfitMood.cozy:
        return [const Color(0xFFE8B98A), const Color(0xFFC8906A)];
      case OutfitMood.dreamy:
        return [const Color(0xFFAB5CF2), const Color(0xFFFF69B4)];
      case OutfitMood.bold:
        return [const Color(0xFFFF4444), const Color(0xFFFF8800)];
      case OutfitMood.mystical:
        return [const Color(0xFF5A1E99), const Color(0xFF3A0E66)];
      case OutfitMood.fresh:
        return [const Color(0xFF88D8A8), const Color(0xFF50B888)];
      case OutfitMood.celestial:
        return [const Color(0xFF7EC8E3), const Color(0xFF4A90C8)];
      case OutfitMood.earthy:
        return [const Color(0xFF8B6914), const Color(0xFF5A4010)];
      case OutfitMood.edgy:
        return [const Color(0xFF2A2A3A), const Color(0xFF111118)];
    }
  }
}

// ── Accessory Type ────────────────────────────────────────────────────────────

enum AccessoryType {
  moonEarrings,
  starEarrings,
  moonCrown,
  glasses,
  starHairpin,
  necklace,
  sleepyBow,
}

extension AccessoryTypeX on AccessoryType {
  String get label {
    switch (this) {
      case AccessoryType.moonEarrings: return 'Moon Earrings';
      case AccessoryType.starEarrings: return 'Star Earrings';
      case AccessoryType.moonCrown:    return 'Moon Crown';
      case AccessoryType.glasses:      return 'Glasses';
      case AccessoryType.starHairpin:  return 'Star Hairpin';
      case AccessoryType.necklace:     return 'Necklace';
      case AccessoryType.sleepyBow:    return 'Sleepy Bow';
    }
  }

  String get emoji {
    switch (this) {
      case AccessoryType.moonEarrings: return '🌙';
      case AccessoryType.starEarrings: return '⭐';
      case AccessoryType.moonCrown:    return '👑';
      case AccessoryType.glasses:      return '🕶';
      case AccessoryType.starHairpin:  return '📌';
      case AccessoryType.necklace:     return '📿';
      case AccessoryType.sleepyBow:    return '🎀';
    }
  }
}

// ── Aura Style ────────────────────────────────────────────────────────────────

enum AuraStyle {
  none,
  lunar,
  rose,
  golden,
  aqua,
  amethyst,
  crimson,
  emerald,
  twilight,
}

extension AuraStyleX on AuraStyle {
  String get label {
    switch (this) {
      case AuraStyle.none:     return 'No Aura';
      case AuraStyle.lunar:    return 'Lunar';
      case AuraStyle.rose:     return 'Rose';
      case AuraStyle.golden:   return 'Golden';
      case AuraStyle.aqua:     return 'Aqua';
      case AuraStyle.amethyst: return 'Amethyst';
      case AuraStyle.crimson:  return 'Crimson';
      case AuraStyle.emerald:  return 'Emerald';
      case AuraStyle.twilight: return 'Twilight';
    }
  }

  String get emoji {
    switch (this) {
      case AuraStyle.none:     return '○';
      case AuraStyle.lunar:    return '🌙';
      case AuraStyle.rose:     return '🌸';
      case AuraStyle.golden:   return '✨';
      case AuraStyle.aqua:     return '💧';
      case AuraStyle.amethyst: return '💜';
      case AuraStyle.crimson:  return '❤️';
      case AuraStyle.emerald:  return '💚';
      case AuraStyle.twilight: return '🌌';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AuraStyle.none:     return Colors.transparent;
      case AuraStyle.lunar:    return const Color(0xFFAB5CF2);
      case AuraStyle.rose:     return const Color(0xFFFF69B4);
      case AuraStyle.golden:   return const Color(0xFFFFD700);
      case AuraStyle.aqua:     return const Color(0xFF7EC8E3);
      case AuraStyle.amethyst: return const Color(0xFF9B59B6);
      case AuraStyle.crimson:  return const Color(0xFFCC2230);
      case AuraStyle.emerald:  return const Color(0xFF2ECC71);
      case AuraStyle.twilight: return const Color(0xFF6A5ACD);
    }
  }

  Color get secondaryColor {
    switch (this) {
      case AuraStyle.none:     return Colors.transparent;
      case AuraStyle.lunar:    return const Color(0xFFD4AAFF);
      case AuraStyle.rose:     return const Color(0xFFFFB3D1);
      case AuraStyle.golden:   return const Color(0xFFFFEA80);
      case AuraStyle.aqua:     return const Color(0xFFB3E8F7);
      case AuraStyle.amethyst: return const Color(0xFFD7BDE2);
      case AuraStyle.crimson:  return const Color(0xFFFF9999);
      case AuraStyle.emerald:  return const Color(0xFF82E0AA);
      case AuraStyle.twilight: return const Color(0xFFBBB3E8);
    }
  }
}

// ── Avatar Gender ─────────────────────────────────────────────────────────────

enum AvatarGender { feminine, masculine, nonBinary }

extension AvatarGenderX on AvatarGender {
  String get label {
    switch (this) {
      case AvatarGender.feminine:  return 'Feminine';
      case AvatarGender.masculine: return 'Masculine';
      case AvatarGender.nonBinary: return 'Non-Binary';
    }
  }
}

// ── Emotional State ───────────────────────────────────────────────────────────

enum EmotionalState {
  neutral,
  happy,
  glowing,
  calm,
  sleepy,
  low,
  energetic,
  cozy,
}

extension EmotionalStateX on EmotionalState {
  String get label {
    switch (this) {
      case EmotionalState.neutral:   return 'Neutral';
      case EmotionalState.happy:     return 'Happy';
      case EmotionalState.glowing:   return 'Glowing';
      case EmotionalState.calm:      return 'Calm';
      case EmotionalState.sleepy:    return 'Sleepy';
      case EmotionalState.low:       return 'Low';
      case EmotionalState.energetic: return 'Energetic';
      case EmotionalState.cozy:      return 'Cozy';
    }
  }

  String get emoji {
    switch (this) {
      case EmotionalState.neutral:   return '🌙';
      case EmotionalState.happy:     return '🌟';
      case EmotionalState.glowing:   return '✨';
      case EmotionalState.calm:      return '🌿';
      case EmotionalState.sleepy:    return '🌛';
      case EmotionalState.low:       return '🌧';
      case EmotionalState.energetic: return '⚡';
      case EmotionalState.cozy:      return '🧸';
    }
  }

  AuraStyle get defaultAura {
    switch (this) {
      case EmotionalState.neutral:   return AuraStyle.lunar;
      case EmotionalState.happy:     return AuraStyle.rose;
      case EmotionalState.glowing:   return AuraStyle.golden;
      case EmotionalState.calm:      return AuraStyle.aqua;
      case EmotionalState.sleepy:    return AuraStyle.amethyst;
      case EmotionalState.low:       return AuraStyle.twilight;
      case EmotionalState.energetic: return AuraStyle.crimson;
      case EmotionalState.cozy:      return AuraStyle.rose;
    }
  }
}

// ── Avatar Model ──────────────────────────────────────────────────────────────

class AvatarModel {
  final String uid;
  final AvatarGender gender;
  final SkinTone skinTone;
  final FaceShape faceShape;
  final EyeStyle eyeStyle;
  final EyeColor eyeColor;
  final BrowStyle browStyle;
  final LipStyle lipStyle;
  final LipColor lipColor;
  final BlushLevel blush;
  final bool freckles;
  final HairStyle hairStyle;
  final HairColor hairColor;
  final OutfitMood outfitMood;
  final List<AccessoryType> accessories;
  final AuraStyle auraStyle;
  final EmotionalState emotionalState;

  const AvatarModel({
    required this.uid,
    this.gender = AvatarGender.feminine,
    this.skinTone = SkinTone.light,
    this.faceShape = FaceShape.oval,
    this.eyeStyle = EyeStyle.almond,
    this.eyeColor = EyeColor.brown,
    this.browStyle = BrowStyle.natural,
    this.lipStyle = LipStyle.natural,
    this.lipColor = LipColor.rose,
    this.blush = BlushLevel.soft,
    this.freckles = false,
    this.hairStyle = HairStyle.longWavy,
    this.hairColor = HairColor.darkBrown,
    this.outfitMood = OutfitMood.dreamy,
    this.accessories = const [],
    this.auraStyle = AuraStyle.lunar,
    this.emotionalState = EmotionalState.neutral,
  });

  factory AvatarModel.defaultFor(String uid) => AvatarModel(uid: uid);

  factory AvatarModel.fromMap(String uid, Map<String, dynamic> map) {
    return AvatarModel(
      uid: uid,
      gender: _enumFromName(AvatarGender.values, map['gender'], AvatarGender.feminine),
      skinTone: _enumFromName(SkinTone.values, map['skinTone'], SkinTone.light),
      faceShape: _enumFromName(FaceShape.values, map['faceShape'], FaceShape.oval),
      eyeStyle: _enumFromName(EyeStyle.values, map['eyeStyle'], EyeStyle.almond),
      eyeColor: _enumFromName(EyeColor.values, map['eyeColor'], EyeColor.brown),
      browStyle: _enumFromName(BrowStyle.values, map['browStyle'], BrowStyle.natural),
      lipStyle: _enumFromName(LipStyle.values, map['lipStyle'], LipStyle.natural),
      lipColor: _enumFromName(LipColor.values, map['lipColor'], LipColor.rose),
      blush: _enumFromName(BlushLevel.values, map['blush'], BlushLevel.soft),
      freckles: map['freckles'] as bool? ?? false,
      hairStyle: _enumFromName(HairStyle.values, map['hairStyle'], HairStyle.longWavy),
      hairColor: _enumFromName(HairColor.values, map['hairColor'], HairColor.darkBrown),
      outfitMood: _enumFromName(OutfitMood.values, map['outfitMood'], OutfitMood.dreamy),
      accessories: (map['accessories'] as List<dynamic>?)
              ?.map((e) => _enumFromName(
                  AccessoryType.values, e, AccessoryType.moonEarrings))
              .toList() ??
          const [],
      auraStyle: _enumFromName(AuraStyle.values, map['auraStyle'], AuraStyle.lunar),
      emotionalState: _enumFromName(
          EmotionalState.values, map['emotionalState'], EmotionalState.neutral),
    );
  }

  Map<String, dynamic> toMap() => {
        'gender': gender.name,
        'skinTone': skinTone.name,
        'faceShape': faceShape.name,
        'eyeStyle': eyeStyle.name,
        'eyeColor': eyeColor.name,
        'browStyle': browStyle.name,
        'lipStyle': lipStyle.name,
        'lipColor': lipColor.name,
        'blush': blush.name,
        'freckles': freckles,
        'hairStyle': hairStyle.name,
        'hairColor': hairColor.name,
        'outfitMood': outfitMood.name,
        'accessories': accessories.map((a) => a.name).toList(),
        'auraStyle': auraStyle.name,
        'emotionalState': emotionalState.name,
      };

  AvatarModel copyWith({
    String? uid,
    AvatarGender? gender,
    SkinTone? skinTone,
    FaceShape? faceShape,
    EyeStyle? eyeStyle,
    EyeColor? eyeColor,
    BrowStyle? browStyle,
    LipStyle? lipStyle,
    LipColor? lipColor,
    BlushLevel? blush,
    bool? freckles,
    HairStyle? hairStyle,
    HairColor? hairColor,
    OutfitMood? outfitMood,
    List<AccessoryType>? accessories,
    AuraStyle? auraStyle,
    EmotionalState? emotionalState,
  }) {
    return AvatarModel(
      uid: uid ?? this.uid,
      gender: gender ?? this.gender,
      skinTone: skinTone ?? this.skinTone,
      faceShape: faceShape ?? this.faceShape,
      eyeStyle: eyeStyle ?? this.eyeStyle,
      eyeColor: eyeColor ?? this.eyeColor,
      browStyle: browStyle ?? this.browStyle,
      lipStyle: lipStyle ?? this.lipStyle,
      lipColor: lipColor ?? this.lipColor,
      blush: blush ?? this.blush,
      freckles: freckles ?? this.freckles,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      outfitMood: outfitMood ?? this.outfitMood,
      accessories: accessories ?? this.accessories,
      auraStyle: auraStyle ?? this.auraStyle,
      emotionalState: emotionalState ?? this.emotionalState,
    );
  }
}

// ── Private helper ────────────────────────────────────────────────────────────

T _enumFromName<T extends Enum>(List<T> values, dynamic name, T fallback) {
  if (name is String) {
    for (final v in values) {
      if (v.name == name) return v;
    }
  }
  return fallback;
}
