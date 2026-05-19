// ═══════════════════════════════════════════════════════════
//  CHAT PROVIDER
//  State management for Lunar AI chat — persistence, memory,
//  contextual AI routing, and voice-ready architecture.
// ═══════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/cycle_model.dart';
import '../data/local_cache.dart';
import '../../services/lunar_ai_service.dart';
import 'app_provider.dart';
import 'lunar_data_provider.dart';

// ── Chat session status ───────────────────────────────────
enum ChatStatus { idle, thinking, error }

// ═══════════════════════════════════════════════════════════
//  CHAT PROVIDER
// ═══════════════════════════════════════════════════════════

class ChatProvider extends ChangeNotifier {
  // ── Core state ────────────────────────────────────────────
  final List<ChatMessage> _messages = [];
  ChatStatus _status = ChatStatus.idle;
  bool _isLoaded = false;
  bool _apiKeyConfigured = false;

  // ── Memory system ─────────────────────────────────────────
  final List<EmotionTag> _emotionHistory = []; // Rolling emotional log
  final Map<EmotionTag, int> _emotionCounts = {}; // Frequency counter
  int _sessionMessageCount = 0;

  // ── Voice-ready structure (future implementation) ─────────
  bool _voiceMode = false; // Reserved for future voice feature

  // ── Premium features gate (structure only) ────────────────
  static const _historyLimit = 100; // Free tier: 100 stored messages
  static const _persistKey = 'lunar_chat_history_v1';
  static const _emotionKey = 'lunar_emotion_history_v1';

  // ── Getters ───────────────────────────────────────────────
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _status == ChatStatus.thinking;
  bool get isLoaded => _isLoaded;
  bool get apiKeyConfigured => _apiKeyConfigured;
  bool get voiceMode => _voiceMode; // voice-ready
  int get sessionMessageCount => _sessionMessageCount;

  // Dominant emotion this session
  EmotionTag? get dominantEmotion {
    if (_emotionHistory.isEmpty) return null;
    return _emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Contextual phase label for UI display
  String get cyclePhaseDisplay => _lastPhaseLabel ?? '';
  String? _lastPhaseLabel;

  // ═══════════════════════════════════════════════════════════
  //  INITIALISATION
  // ═══════════════════════════════════════════════════════════

  Future<void> init() async {
    await _loadHistory();
    await _loadEmotionHistory();
    final key = await LunarAIService.getApiKey();
    _apiKeyConfigured = key != null && key.isNotEmpty;
    if (_messages.isEmpty) {
      _messages.add(ChatMessage.ai(LunarAIService.welcomeMsg));
    }
    _isLoaded = true;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  SEND MESSAGE
  // ═══════════════════════════════════════════════════════════

  Future<void> send(String text, BuildContext context) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _status == ChatStatus.thinking) return;

    // Build context BEFORE any async gap (context may be gone after await)
    final ctx = _buildContext(context);
    final history = _buildOpenAIHistory();

    // Detect emotion tag for memory
    final emotionTag = _detectEmotion(trimmed);

    // Add user message immediately
    _messages.add(ChatMessage.user(trimmed, emotionTag: emotionTag));
    _status = ChatStatus.thinking;
    _sessionMessageCount++;
    notifyListeners();
    _saveHistory(); // fire-and-forget

    // Update emotional memory
    if (emotionTag != null) {
      _emotionHistory.add(emotionTag);
      _emotionCounts[emotionTag] = (_emotionCounts[emotionTag] ?? 0) + 1;
      _saveEmotionHistory(); // fire-and-forget
    }

    // Simulate natural thinking delay
    final delay = 1000 + math.Random().nextInt(1200);
    await Future.delayed(Duration(milliseconds: delay));

    // Get AI response
    final response = await LunarAIService.respond(
      trimmed,
      context: ctx,
      conversationHistory: history,
    );

    _status = ChatStatus.idle;
    _messages.add(ChatMessage.ai(response.text, healing: response.healing));
    notifyListeners();

    // Healing card follows after a short delay
    if (response.healing != null) {
      await Future.delayed(const Duration(milliseconds: 680));
      _messages.add(ChatMessage.healingCard(response.healing!));
      notifyListeners();
    }

    _saveHistory(); // fire-and-forget
  }

  // ═══════════════════════════════════════════════════════════
  //  QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> sendQuickAction(String label, BuildContext context) =>
      send(label, context);

  // ═══════════════════════════════════════════════════════════
  //  HISTORY MANAGEMENT
  // ═══════════════════════════════════════════════════════════

  void clearHistory() {
    _messages.clear();
    _messages.add(ChatMessage.ai(LunarAIService.welcomeMsg));
    _emotionHistory.clear();
    _emotionCounts.clear();
    _sessionMessageCount = 0;
    notifyListeners();
    LocalCache.setString(_persistKey, '[]');
    LocalCache.setString(_emotionKey, '[]');
  }

  // ═══════════════════════════════════════════════════════════
  //  API KEY
  // ═══════════════════════════════════════════════════════════

  Future<void> saveApiKey(String key) async {
    await LunarAIService.setApiKey(key);
    _apiKeyConfigured = key.isNotEmpty;
    notifyListeners();
  }

  Future<void> removeApiKey() async {
    await LunarAIService.clearApiKey();
    _apiKeyConfigured = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  VOICE MODE  (structure for future voice feature)
  // ═══════════════════════════════════════════════════════════

  void setVoiceMode(bool active) {
    _voiceMode = active;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  CONTEXT BUILDER
  // ═══════════════════════════════════════════════════════════

  Map<String, dynamic> _buildContext(BuildContext ctx) {
    try {
      final lunarData = Provider.of<LunarDataProvider>(ctx, listen: false);
      final app = Provider.of<AppProvider>(ctx, listen: false);

      // Phase label
      const phaseLabels = <LunarCyclePhase, String>{
        LunarCyclePhase.period: 'Menstrual',
        LunarCyclePhase.follicular: 'Follicular',
        LunarCyclePhase.ovulation: 'Ovulation',
        LunarCyclePhase.luteal: 'Luteal',
      };
      final phaseLabel = phaseLabels[lunarData.currentPhase];
      _lastPhaseLabel = phaseLabel;

      // Last mood emoji
      String? lastMoodEmoji;
      if (lunarData.moodEntries.isNotEmpty) {
        lastMoodEmoji = lunarData.moodEntries.first.emoji;
      }

      // Pregnancy week
      int? pregnancyWeek;
      if (lunarData.isPregnant && lunarData.pregnancyData != null) {
        pregnancyWeek =
            lunarData.pregnancyData!.weeksPregnant.clamp(1, 42).toInt();
      }

      return {
        'name': app.userName,
        'cyclePhase': phaseLabel,
        'cycleDay':
            lunarData.currentCycleDay > 0 ? lunarData.currentCycleDay : null,
        'isPregnant': app.pregnancyMode || lunarData.isPregnant,
        'pregnancyWeek': pregnancyWeek,
        'lastMood': lastMoodEmoji,
        'waterGlasses': lunarData.todayWaterGlasses,
        'sleepHours': lunarData.lastSleepHours,
      };
    } catch (_) {
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  OPENAI CONVERSATION HISTORY BUILDER
  // ═══════════════════════════════════════════════════════════

  List<Map<String, String>> _buildOpenAIHistory() {
    final history = <Map<String, String>>[];
    // Use last 20 non-healing-card messages for context
    final relevant = _messages
        .where((m) => m.type != ChatMsgType.healingCard)
        .toList()
        .reversed
        .take(20)
        .toList()
        .reversed
        .toList();

    for (final msg in relevant) {
      history.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }
    return history;
  }

  // ═══════════════════════════════════════════════════════════
  //  EMOTION DETECTION  (for memory system)
  // ═══════════════════════════════════════════════════════════

  static EmotionTag? _detectEmotion(String text) {
    final l = text.toLowerCase();
    if (l.contains('anxi') ||
        l.contains('panic') ||
        l.contains('worry') ||
        l.contains('scared') ||
        l.contains('nervous')) return EmotionTag.anxious;
    if (l.contains('sad') ||
        l.contains('cry') ||
        l.contains('depress') ||
        l.contains('hurt') ||
        l.contains('broken')) return EmotionTag.sad;
    if (l.contains('lonely') || l.contains('alone') || l.contains('isolat')) {
      return EmotionTag.lonely;
    }
    if (l.contains('stress') ||
        l.contains('overwhelm') ||
        l.contains('too much') ||
        l.contains('burnout')) return EmotionTag.stressed;
    if (l.contains('happy') ||
        l.contains('great') ||
        l.contains('amazing') ||
        l.contains('excit') ||
        l.contains('wonderful')) return EmotionTag.happy;
    if (l.contains('energe') ||
        l.contains('motivated') ||
        l.contains('strong')) {
      return EmotionTag.energetic;
    }
    if (l.contains('tired') ||
        l.contains('exhaust') ||
        l.contains('fatigue') ||
        l.contains('sleep')) return EmotionTag.tired;
    if (l.contains('emotional') ||
        l.contains('sensitive') ||
        l.contains('i feel')) {
      return EmotionTag.emotional;
    }
    if (l.contains('period') ||
        l.contains('cramp') ||
        l.contains('pms') ||
        l.contains('menstrual')) return EmotionTag.period;
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  //  PERSISTENCE
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadHistory() async {
    try {
      final raw = LocalCache.getString(_persistKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      final loaded = list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      // Keep only the most recent _historyLimit messages
      final trimmed = loaded.length > _historyLimit
          ? loaded.sublist(loaded.length - _historyLimit)
          : loaded;
      _messages.addAll(trimmed);
    } catch (e) {
      debugPrint('[ChatProvider] Failed to load history: $e');
    }
  }

  void _saveHistory() {
    try {
      final toSave = _messages.length > _historyLimit
          ? _messages.sublist(_messages.length - _historyLimit)
          : _messages;
      final json = jsonEncode(toSave.map((m) => m.toJson()).toList());
      LocalCache.setString(_persistKey, json);
    } catch (e) {
      debugPrint('[ChatProvider] Failed to save history: $e');
    }
  }

  Future<void> _loadEmotionHistory() async {
    try {
      final raw = LocalCache.getString(_emotionKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final tag = EmotionTag.values.firstWhere(
          (e) => e.name == item as String,
          orElse: () => EmotionTag.neutral,
        );
        _emotionHistory.add(tag);
        _emotionCounts[tag] = (_emotionCounts[tag] ?? 0) + 1;
      }
    } catch (_) {}
  }

  void _saveEmotionHistory() {
    try {
      final recent = _emotionHistory.length > 50
          ? _emotionHistory.sublist(_emotionHistory.length - 50)
          : _emotionHistory;
      LocalCache.setString(
          _emotionKey, jsonEncode(recent.map((e) => e.name).toList()));
    } catch (_) {}
  }
}
