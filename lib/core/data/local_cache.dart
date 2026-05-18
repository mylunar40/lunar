import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════════
//  LOCAL CACHE — SharedPreferences wrapper
//  All public methods are safe to call before [init]; they are
//  no-ops and return null/defaults until the prefs instance
//  is ready.
// ══════════════════════════════════════════════════════════════

abstract final class LocalCache {
  static SharedPreferences? _prefs;

  /// Must be called once (in main) before any other method.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── String ─────────────────────────────────────────────────
  static Future<void> setString(String key, String value) async =>
      _prefs?.setString(key, value);
  static String? getString(String key) => _prefs?.getString(key);

  // ── Int ────────────────────────────────────────────────────
  static Future<void> setInt(String key, int value) async =>
      _prefs?.setInt(key, value);
  static int? getInt(String key) => _prefs?.getInt(key);

  // ── Double ─────────────────────────────────────────────────
  static Future<void> setDouble(String key, double value) async =>
      _prefs?.setDouble(key, value);
  static double? getDouble(String key) => _prefs?.getDouble(key);

  // ── Bool ───────────────────────────────────────────────────
  static Future<void> setBool(String key, bool value) async =>
      _prefs?.setBool(key, value);
  static bool? getBool(String key) => _prefs?.getBool(key);

  // ── JSON object ────────────────────────────────────────────
  static Future<void> setJson(
      String key, Map<String, dynamic> json) async {
    await _prefs?.setString(key, jsonEncode(json));
  }

  static Map<String, dynamic>? getJson(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── JSON list ──────────────────────────────────────────────
  static Future<void> setJsonList(
      String key, List<Map<String, dynamic>> list) async {
    await _prefs?.setString(key, jsonEncode(list));
  }

  static List<Map<String, dynamic>>? getJsonList(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────
  static Future<void> remove(String key) async =>
      _prefs?.remove(key);

  static Future<void> clear() async => _prefs?.clear();
}
