import 'package:flutter/foundation.dart';
import '../models/deep_memory.dart';
import '../models/chat_message.dart';
import '../repositories/memory_repository.dart';

// ══════════════════════════════════════════════════════════════
//  MEMORY PROVIDER
//  State management for the Deep Emotional Memory System.
//  Exposes memories, pattern detection, and AI context strings.
// ══════════════════════════════════════════════════════════════

class MemoryProvider extends ChangeNotifier {
  List<DeepMemory> _memories = [];
  String? _uid;
  bool _firestoreSynced = false;

  // ── Public getters ─────────────────────────────────────────

  List<DeepMemory> get memories => List.unmodifiable(_memories);

  List<DeepMemory> get recentMemories => _memories.reversed.take(10).toList();

  int get memoryCount => _memories.length;

  bool get hasMemories => _memories.isNotEmpty;

  Map<MemoryCategory, List<DeepMemory>> get memoriesByCategory {
    final map = <MemoryCategory, List<DeepMemory>>{};
    for (final m in _memories) {
      map.putIfAbsent(m.category, () => []).add(m);
    }
    return map;
  }

  /// Returns memories sorted from newest to oldest.
  List<DeepMemory> get timeline =>
      [..._memories]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  // ── Pattern detection ──────────────────────────────────────

  /// True when anxiety appears 3+ times in stored memories.
  bool get hasRecurringAnxiety => _countCategory(MemoryCategory.anxiety) >= 3;

  /// True when stress appears 3+ times in stored memories.
  bool get hasRecurringStress => _countCategory(MemoryCategory.stress) >= 3;

  /// True when loneliness appears 2+ times.
  bool get hasRecurringLoneliness =>
      _countCategory(MemoryCategory.loneliness) >= 2;

  /// True when confidence struggles appear 2+ times.
  bool get hasConfidencePattern =>
      _countCategory(MemoryCategory.confidence) >= 2;

  /// True when there is at least one victory and it is more recent than
  /// the last negative memory — suggests emotional improvement.
  bool get hasEmotionalImprovement {
    final victories =
        _memories.where((m) => m.category == MemoryCategory.victory).toList();
    if (victories.isEmpty) return false;
    final lastVictory =
        victories.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
    final negatives = _memories.where((m) =>
        m.category != MemoryCategory.victory &&
        m.category != MemoryCategory.general);
    if (negatives.isEmpty) return true;
    final lastNegative =
        negatives.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
    return lastVictory.timestamp.isAfter(lastNegative.timestamp);
  }

  /// The most frequently occurring category (ignores 'general').
  MemoryCategory? get dominantPattern {
    final byCategory = memoriesByCategory;
    byCategory.remove(MemoryCategory.general);
    if (byCategory.isEmpty) return null;
    return byCategory.entries
        .reduce((a, b) => a.value.length >= b.value.length ? a : b)
        .key;
  }

  // ── AI context building ────────────────────────────────────

  /// Builds a rich natural-language context string to inject into
  /// the AI system prompt, making Lunar aware of the user's history.
  String? buildContextString() {
    if (_memories.isEmpty) return null;
    final parts = <String>[];

    // ── Recent significant memories (last 30 days, significance ≥ 0.65) ──
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = _memories
        .where((m) =>
            m.timestamp.isAfter(cutoff) &&
            m.significance >= 0.65 &&
            !m.isResolved)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (recent.isNotEmpty) {
      final top = recent.take(3).toList();
      final summaries = top.map((m) =>
          '• ${m.timeAgoLabel}: ${m.summary} (${m.category.emoji} ${m.category.label})');
      parts.add('RECENT EMOTIONAL MEMORIES:\n${summaries.join('\n')}');
    }

    // ── Pattern insights ───────────────────────────────────────
    final patternParts = <String>[];

    if (hasRecurringAnxiety) {
      patternParts.add(
          'Anxiety is a recurring theme in her life — be especially gentle and grounding; she is familiar with this feeling and knows it is manageable with your presence.');
    }
    if (hasRecurringStress) {
      patternParts.add(
          'Stress and overwhelm come up repeatedly — validate before advising; she needs to feel heard before she can receive perspective.');
    }
    if (hasRecurringLoneliness) {
      patternParts.add(
          'Loneliness is a deep pattern for her — emphasise your presence, that she is truly seen and not alone here.');
    }
    if (hasConfidencePattern) {
      patternParts.add(
          'Self-worth struggles appear in her history — approach with deep tenderness; never minimise or jump to reassurance without first truly holding the pain.');
    }
    if (hasEmotionalImprovement) {
      patternParts.add(
          'She has shown real emotional growth and recent victories — gently acknowledge her resilience when it feels authentic, without over-praising.');
    }

    // ── Unresolved high-significance memories ──────────────────
    final oldUnresolved = _memories
        .where((m) =>
            m.significance >= 0.80 &&
            !m.isResolved &&
            m.timestamp.isBefore(cutoff))
        .toList();
    if (oldUnresolved.isNotEmpty) {
      final oldest = oldUnresolved.first;
      patternParts.add(
          'She has been carrying "${oldest.summary}" (${oldest.timeAgoLabel}) — if it comes up, acknowledge it as something you remember gently.');
    }

    if (patternParts.isNotEmpty) {
      parts.add('EMOTIONAL PATTERNS:\n${patternParts.join('\n')}');
    }

    // ── Breakup awareness ──────────────────────────────────────
    final recentBreakup =
        recent.any((m) => m.category == MemoryCategory.breakup);
    if (recentBreakup) {
      parts.add(
          'She recently went through a breakup — be especially warm, avoid advice unless asked. Hold the grief first.');
    }

    // ── Grief awareness ────────────────────────────────────────
    final recentGrief = recent.any((m) => m.category == MemoryCategory.grief);
    if (recentGrief) {
      parts.add(
          'She is currently grieving a loss — approach with extreme tenderness. Never minimise, never rush healing.');
    }

    return parts.isEmpty ? null : parts.join('\n\n');
  }

  // ── Init & user management ─────────────────────────────────

  Future<void> init() async {
    _memories = MemoryRepository.loadLocal();
    notifyListeners();
  }

  void setUser(String? uid) {
    if (uid == null || uid == _uid) return;
    _uid = uid;
    _firestoreSynced = false;
    _syncFromFirestore();
  }

  void clearUser() {
    _uid = null;
    _firestoreSynced = false;
  }

  // ── CRUD operations ────────────────────────────────────────

  Future<void> addMemory(DeepMemory memory) async {
    // Avoid near-duplicate: skip if same category stored in last 2 hours
    final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
    final isDuplicate = _memories.any((m) =>
        m.category == memory.category && m.timestamp.isAfter(twoHoursAgo));
    if (isDuplicate) return;

    _memories.add(memory);
    _memories.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    notifyListeners();

    await MemoryRepository.saveLocal(_memories);
    if (_uid != null) {
      MemoryRepository.syncToFirestore(memory, _uid!);
    }
  }

  Future<void> deleteMemory(String id) async {
    _memories.removeWhere((m) => m.id == id);
    notifyListeners();

    await MemoryRepository.saveLocal(_memories);
    if (_uid != null) {
      MemoryRepository.deleteFromFirestore(id, _uid!);
    }
  }

  Future<void> markResolved(String id) async {
    final idx = _memories.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    _memories[idx] = _memories[idx].copyWith(isResolved: true);
    notifyListeners();

    await MemoryRepository.saveLocal(_memories);
    if (_uid != null) {
      MemoryRepository.syncToFirestore(_memories[idx], _uid!);
    }
  }

  Future<void> clearAll() async {
    _memories.clear();
    notifyListeners();

    await MemoryRepository.saveLocal([]);
    if (_uid != null) {
      MemoryRepository.clearFirestore(_uid!);
    }
  }

  // ── Private helpers ────────────────────────────────────────

  int _countCategory(MemoryCategory cat) =>
      _memories.where((m) => m.category == cat).length;

  Future<void> _syncFromFirestore() async {
    if (_uid == null || _firestoreSynced) return;
    try {
      final remote = await MemoryRepository.loadFromFirestore(_uid!);
      if (remote.isEmpty) {
        // Push local to Firestore on first login
        for (final m in _memories) {
          MemoryRepository.syncToFirestore(m, _uid!);
        }
        _firestoreSynced = true;
        return;
      }
      final merged = MemoryRepository.merge(_memories, remote);
      if (merged.length != _memories.length) {
        _memories = merged;
        await MemoryRepository.saveLocal(_memories);
        notifyListeners();
      }
      _firestoreSynced = true;
    } catch (e) {
      debugPrint('[MemoryProvider] Firestore sync error: $e');
    }
  }

  // ── Convenience: top memories for UI ──────────────────────

  /// Most significant unresolved memories, newest first, max [limit].
  List<DeepMemory> topMemories({int limit = 5}) {
    return ([..._memories]..sort((a, b) {
            if (a.isResolved != b.isResolved) {
              return a.isResolved ? 1 : -1;
            }
            return b.significance.compareTo(a.significance);
          }))
        .take(limit)
        .toList();
  }

  // ── Emotional snapshot for display ────────────────────────

  /// Returns a short insight sentence to show in the memory card.
  String? get memoryInsight {
    if (_memories.isEmpty) return null;
    if (hasEmotionalImprovement) {
      return 'You\'ve been growing beautifully 🌸 Your recent victories say so much.';
    }
    if (hasRecurringAnxiety) {
      return 'Anxiety has been present in your story 💙 You\'ve faced it before and you will again.';
    }
    if (hasRecurringStress) {
      return 'Stress has visited you often 🌧️ Your resilience in carrying it is real.';
    }
    if (hasRecurringLoneliness) {
      return 'Loneliness has been a recurring visitor 🌙 But you are truly seen here.';
    }
    if (hasConfidencePattern) {
      return 'Your heart has wrestled with self-worth 🌱 That struggle is part of how you grow.';
    }
    final dom = dominantPattern;
    if (dom != null) {
      return 'Lunar has been walking alongside your ${dom.label.toLowerCase()} ${dom.emoji}';
    }
    return 'Lunar has been holding your story 🌙';
  }
}
