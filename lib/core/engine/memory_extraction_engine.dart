import '../models/deep_memory.dart';
import '../models/chat_message.dart';

// ══════════════════════════════════════════════════════════════
//  MEMORY EXTRACTION ENGINE
//  Pure keyword + pattern analysis — NO API calls.
//  Runs after every user message and decides whether to store
//  a persistent emotional memory.
// ══════════════════════════════════════════════════════════════

abstract final class MemoryExtractionEngine {
  // Minimum message length to consider extracting a memory.
  static const _kMinLength = 18;
  // Significance threshold — below this, nothing is stored.
  static const _kMinSignificance = 0.44;

  /// Attempts to extract a persistent emotional memory from a user message.
  /// Returns null if the message is not significant enough.
  static DeepMemory? extract(String text, EmotionTag? detectedEmotion) {
    if (text.trim().length < _kMinLength) return null;
    final l = text.toLowerCase();

    final match = _bestMatch(l, text, detectedEmotion);
    if (match == null || match.significance < _kMinSignificance) return null;

    final raw = text.length > 300 ? text.substring(0, 300) : text;

    return DeepMemory(
      id: '${DateTime.now().microsecondsSinceEpoch}_m',
      category: match.category,
      summary: match.summary,
      rawText: raw,
      timestamp: DateTime.now(),
      emotionTag: detectedEmotion ?? EmotionTag.neutral,
      significance: match.significance,
    );
  }

  // ── Pattern matching ───────────────────────────────────────

  static _MemoryMatch? _bestMatch(String l, String raw, EmotionTag? emotion) {
    _MemoryMatch? best;

    void consider(_MemoryMatch? m) {
      if (m == null) return;
      if (best == null || m.significance > best!.significance) best = m;
    }

    consider(_checkBreakup(l, raw));
    consider(_checkGrief(l, raw));
    consider(_checkPregnancy(l, raw));
    consider(_checkVictory(l, raw));
    consider(_checkConfidence(l, raw));
    consider(_checkAnxiety(l, raw));
    consider(_checkRelationship(l, raw));
    consider(_checkFamily(l, raw));
    consider(_checkWork(l, raw));
    consider(_checkSleep(l, raw));
    consider(_checkLoneliness(l, raw));
    consider(_checkHealth(l, raw));
    consider(_checkStress(l, raw));

    // Emotion-boost: if a mid-significance match exists but emotion confirms it
    if (best != null && emotion != null) {
      const boostEmotions = {
        EmotionTag.sad,
        EmotionTag.anxious,
        EmotionTag.stressed,
        EmotionTag.lonely,
        EmotionTag.emotional,
      };
      if (boostEmotions.contains(emotion) && best!.significance < 0.75) {
        best = _MemoryMatch(
          best!.category,
          best!.summary,
          (best!.significance + 0.08).clamp(0.0, 1.0),
        );
      }
    }

    return best;
  }

  // ── Category checkers ──────────────────────────────────────

  static _MemoryMatch? _checkBreakup(String l, String raw) {
    if (_any(l, [
      'broke up',
      'break up',
      'broken up',
      'we broke',
      'he left me',
      'she left me',
      'they left me',
      'ended things',
      'ended our relationship',
      'cheated on me',
      'was cheating',
      'he cheated',
      'she cheated',
      'betrayed me',
      'heartbroken',
      'heartbreak',
      'we\'re done',
      'we are done',
      'i got dumped',
      'dumped me',
      'separated from',
    ])) {
      final who = _extractRelationshipPerson(l);
      return _MemoryMatch(
        MemoryCategory.breakup,
        who != null
            ? 'Went through a breakup with $who'
            : 'Went through a breakup',
        0.92,
      );
    }
    return null;
  }

  static _MemoryMatch? _checkGrief(String l, String raw) {
    if (_any(l, [
      'passed away',
      'he died',
      'she died',
      'they died',
      'someone died',
      'funeral',
      'grieving',
      'mourning',
      'lost my',
      'loss of',
      'died today',
      'died last',
      'no longer with us',
    ])) {
      return _MemoryMatch(
          MemoryCategory.grief, 'Experiencing grief and loss', 0.92);
    }
    return null;
  }

  static _MemoryMatch? _checkPregnancy(String l, String raw) {
    if (_any(l, [
      'pregnancy test',
      'pregnancy scare',
      'might be pregnant',
      'scared i\'m pregnant',
      'scared of being pregnant',
      'think i\'m pregnant',
      'i\'m pregnant',
      'scared about pregnancy',
      'pregnancy fear',
      'not ready to be pregnant',
      'don\'t want to be pregnant',
    ])) {
      return _MemoryMatch(
          MemoryCategory.pregnancy, 'Worried about pregnancy', 0.85);
    }
    return null;
  }

  static _MemoryMatch? _checkVictory(String l, String raw) {
    if (_any(l, [
      'i did it',
      'so proud of myself',
      'finally did it',
      'i overcame',
      'got the job',
      'got accepted',
      'i graduated',
      'we made up',
      'feeling so much better',
      'i feel better now',
      'things are better',
      'big win',
      'huge win',
      'i won',
      'promoted',
      'passed my',
    ])) {
      return _MemoryMatch(
          MemoryCategory.victory, 'Achieved something meaningful', 0.82);
    }
    return null;
  }

  static _MemoryMatch? _checkConfidence(String l, String raw) {
    if (_any(l, [
      'hate myself',
      'i\'m worthless',
      'feel worthless',
      'i\'m not good enough',
      'not good enough',
      'hate my body',
      'i\'m ugly',
      'feel ugly',
      'i\'m a failure',
      'feel like a failure',
      'hate who i am',
      'i\'m disgusting',
      'nobody wants me',
      'unlovable',
      'i don\'t deserve',
    ])) {
      return _MemoryMatch(
          MemoryCategory.confidence, 'Struggling with self-worth', 0.80);
    }
    return null;
  }

  static _MemoryMatch? _checkAnxiety(String l, String raw) {
    if (_any(l, [
      'panic attack',
      'had a panic',
      'anxiety attack',
      'can\'t stop worrying',
      'spiraling',
      'i\'m spiraling',
      'feel like i\'m going to panic',
      'heart racing',
      'can\'t breathe',
      'anxious about',
      'severe anxiety',
      'crippling anxiety',
      'so anxious',
    ])) {
      return _MemoryMatch(
          MemoryCategory.anxiety, 'Experiencing intense anxiety', 0.75);
    }
    return null;
  }

  static _MemoryMatch? _checkRelationship(String l, String raw) {
    final hasPerson = _any(l, [
      'boyfriend',
      'girlfriend',
      'partner',
      'husband',
      'wife',
      'he ',
      'she ',
      'him',
      'her ',
    ]);
    if (!hasPerson) return null;

    if (_any(l, [
      'fight with',
      'argument with',
      'we argued',
      'we fought',
      'he hurt me',
      'she hurt me',
      'toxic relationship',
      'he said',
      'she said',
      'doesn\'t care',
      'not there for me',
      'ignoring me',
      'doesn\'t listen',
      'abusive',
      'controlling',
    ])) {
      final who = _extractRelationshipPerson(l);
      return _MemoryMatch(
        MemoryCategory.relationship,
        who != null
            ? 'Having difficulties with $who'
            : 'Relationship difficulties',
        0.70,
      );
    }
    return null;
  }

  static _MemoryMatch? _checkFamily(String l, String raw) {
    final hasFamilyWord = _any(l, [
      'my mom',
      'my mother',
      'my dad',
      'my father',
      'my sister',
      'my brother',
      'my parents',
      'my family',
    ]);
    if (!hasFamilyWord) return null;

    if (_any(l, [
      'fight',
      'argument',
      'toxic',
      'hurt me',
      'don\'t understand',
      'controlling',
      'abusive',
      'yelled at me',
      'disappointed in me',
      'hate me',
      'pressure',
      'difficult',
    ])) {
      return _MemoryMatch(
          MemoryCategory.family, 'Family tension and difficulties', 0.65);
    }
    return null;
  }

  static _MemoryMatch? _checkWork(String l, String raw) {
    if (_any(l, [
      'got fired',
      'lost my job',
      'quit my job',
      'i quit today',
      'laid off',
      'got laid off',
      'workplace',
      'hostile work',
    ])) {
      return _MemoryMatch(
          MemoryCategory.work, 'Facing a major work challenge', 0.78);
    }
    if (_any(l, [
      'work is',
      'my boss',
      'coworker',
      'work stress',
      'work is overwhelming',
      'burnout from work',
      'deadline',
      'overworked',
    ])) {
      return _MemoryMatch(
          MemoryCategory.work, 'Struggling with work stress', 0.60);
    }
    return null;
  }

  static _MemoryMatch? _checkSleep(String l, String raw) {
    if (_any(l, [
      'can\'t sleep',
      'couldn\'t sleep',
      'haven\'t slept',
      'insomnia',
      'sleep problems',
      'nightmares',
      'woke up at 3',
      'woke up at 4',
      'awake at 3',
      'awake at 4',
      'up all night',
      'no sleep',
      'barely slept',
    ])) {
      return _MemoryMatch(MemoryCategory.sleep, 'Struggling with sleep', 0.65);
    }
    return null;
  }

  static _MemoryMatch? _checkLoneliness(String l, String raw) {
    if (_any(l, [
      'so alone',
      'completely alone',
      'no one cares',
      'nobody cares',
      'no friends',
      'nobody understands',
      'no one understands me',
      'feel invisible',
      'feel unseen',
      'cut off from everyone',
      'isolated',
      'no one to talk to',
    ])) {
      return _MemoryMatch(
          MemoryCategory.loneliness, 'Feeling deeply alone', 0.70);
    }
    return null;
  }

  static _MemoryMatch? _checkHealth(String l, String raw) {
    if (_any(l, [
      'diagnosed with',
      'health scare',
      'test results',
      'doctor said',
      'went to the doctor',
      'in the hospital',
      'been sick',
      'chronic pain',
      'illness',
      'medical',
    ])) {
      return _MemoryMatch(
          MemoryCategory.health, 'Dealing with a health concern', 0.72);
    }
    return null;
  }

  static _MemoryMatch? _checkStress(String l, String raw) {
    if (_any(l, [
      'completely overwhelmed',
      'too much to handle',
      'breaking point',
      'can\'t take it anymore',
      'burned out',
      'burnout',
      'everything is falling apart',
      'falling apart',
    ])) {
      return _MemoryMatch(
          MemoryCategory.stress, 'Feeling overwhelmed and burned out', 0.68);
    }
    return null;
  }

  // ── Helpers ────────────────────────────────────────────────

  static bool _any(String l, List<String> keywords) =>
      keywords.any((k) => l.contains(k));

  static String? _extractRelationshipPerson(String l) {
    if (l.contains('boyfriend')) return 'my boyfriend';
    if (l.contains('girlfriend')) return 'my girlfriend';
    if (l.contains('husband')) return 'my husband';
    if (l.contains('wife')) return 'my wife';
    if (l.contains('partner')) return 'my partner';
    return null;
  }
}

// ── Internal result class ──────────────────────────────────

class _MemoryMatch {
  final MemoryCategory category;
  final String summary;
  final double significance;
  const _MemoryMatch(this.category, this.summary, this.significance);
}
