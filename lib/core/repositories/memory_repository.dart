import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/deep_memory.dart';
import '../data/local_cache.dart';

// ══════════════════════════════════════════════════════════════
//  MEMORY REPOSITORY
//  Local cache (SharedPreferences) as primary source — fast,
//  always available. Firestore as secondary — synced in background.
//  Firestore path: users/{uid}/emotionalMemories/{memoryId}
// ══════════════════════════════════════════════════════════════

abstract final class MemoryRepository {
  static const _kLocalKey = 'lunar_deep_memories_v2';
  static const _kCollection = 'emotionalMemories';
  static const _kMaxMemories = 200;

  // ── Local persistence ──────────────────────────────────────

  static List<DeepMemory> loadLocal() {
    try {
      final raw = LocalCache.getJsonList(_kLocalKey) ?? [];
      return raw
          .map((j) {
            try {
              return DeepMemory.fromJson(j);
            } catch (_) {
              return null;
            }
          })
          .whereType<DeepMemory>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveLocal(List<DeepMemory> memories) async {
    try {
      final trimmed = memories.length > _kMaxMemories
          ? memories.sublist(memories.length - _kMaxMemories)
          : memories;
      await LocalCache.setJsonList(
        _kLocalKey,
        trimmed.map((m) => m.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('[MemoryRepository] saveLocal error: $e');
    }
  }

  // ── Firestore read ─────────────────────────────────────────

  static Future<List<DeepMemory>> loadFromFirestore(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(_kCollection)
          .orderBy('timestamp', descending: false)
          .get();
      return snap.docs
          .map((d) {
            try {
              return DeepMemory.fromJson(d.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<DeepMemory>()
          .toList();
    } catch (e) {
      debugPrint('[MemoryRepository] Firestore load error: $e');
      return [];
    }
  }

  // ── Firestore write (fire-and-forget) ─────────────────────

  static void syncToFirestore(DeepMemory memory, String uid) {
    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(_kCollection)
          .doc(memory.id)
          .set(memory.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[MemoryRepository] Firestore sync error: $e');
    }
  }

  static void deleteFromFirestore(String memoryId, String uid) {
    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(_kCollection)
          .doc(memoryId)
          .delete();
    } catch (e) {
      debugPrint('[MemoryRepository] Firestore delete error: $e');
    }
  }

  static void clearFirestore(String uid) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(_kCollection)
        .get()
        .then((snap) {
      for (final doc in snap.docs) {
        doc.reference.delete();
      }
    }).catchError((e) {
      debugPrint('[MemoryRepository] Firestore clear error: $e');
    });
  }

  // ── Merge helpers ──────────────────────────────────────────

  /// Merges remote memories into local list, deduplicating by id.
  static List<DeepMemory> merge(
    List<DeepMemory> local,
    List<DeepMemory> remote,
  ) {
    final ids = local.map((m) => m.id).toSet();
    final merged = [...local];
    for (final m in remote) {
      if (!ids.contains(m.id)) {
        merged.add(m);
      }
    }
    merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return merged;
  }
}
