// ═══════════════════════════════════════════════════════════
//  CHAT PROVIDER
//  State management for Lunar AI chat — persistence, memory,
//  contextual AI routing, and voice-ready architecture.
// ═══════════════════════════════════════════════════════════

import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_message.dart';
import '../models/cycle_model.dart';
import '../models/emotional_memory.dart';
import '../data/local_cache.dart';
import '../../services/lunar_ai_service.dart';
import '../../services/relationship_service.dart';
import '../engine/memory_extraction_engine.dart';
import 'app_provider.dart';
import 'lunar_data_provider.dart';
import 'memory_provider.dart';

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
  int _relationshipMentions = 0; // Tracks heartbreak/relationship pain

  // ── Voice-ready structure (future implementation) ─────────
  bool _voiceMode = false; // Reserved for future voice feature

  // ── Firestore sync ─────────────────────────────────────
  String? _firestoreUid;
  bool _firestoreSynced = false;
  static const _firestoreCollection = 'chatHistory';

  // ── Emotional memory (cross-session) ────────────────────────
  DateTime? _previousSessionAt; // Time of the LAST session (before this one)

  // ── Premium features gate ─────────────────────────────────
  static const _historyLimit = 100; // Free tier: 100 stored messages
  static const _persistKey = 'lunar_chat_history_v1';
  static const _emotionKey = 'lunar_emotion_history_v1';
  static const _lastSessionKey = 'lunar_last_session_v1';

  // Daily AI message counter (free-tier limit)
  static const _dailyLimitKey   = 'ai_daily_count_v1';
  static const _dailyDateKey    = 'ai_daily_date_v1';
  static const freeAiDailyLimit = 20; // messages per day for free users

  int    _dailyAiCount = 0;
  String _dailyAiDate  = ''; // 'yyyy-MM-dd'

  // ── Getters ───────────────────────────────────────────────
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _status == ChatStatus.thinking;
  bool get isLoaded => _isLoaded;
  bool get apiKeyConfigured => _apiKeyConfigured;
  bool get voiceMode => _voiceMode; // voice-ready
  int get sessionMessageCount => _sessionMessageCount;

  // ── Daily limit helpers (free tier) ───────────────────────
  /// Returns remaining free AI messages for today.
  /// Returns the caller's tier limit (effectively unlimited) if [isPremium].
  int remainingAiMessages(bool isPremium) {
    if (isPremium) return ChatProvider.freeAiDailyLimit * 999; // effectively unlimited for display
    _syncDailyDate();
    return (freeAiDailyLimit - _dailyAiCount).clamp(0, freeAiDailyLimit);
  }

  /// Exposes today's message count for UI indicators.
  int get dailyAiCount => _dailyAiCount;

  /// True when the user can still send a message today.
  bool canSendAiMessage(bool isPremium) {
    if (isPremium) return true;
    _syncDailyDate();
    return _dailyAiCount < freeAiDailyLimit;
  }

  void _syncDailyDate() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_dailyAiDate != today) {
      _dailyAiDate  = today;
      _dailyAiCount = 0;
      LocalCache.setString(_dailyDateKey, today);
      LocalCache.setInt(_dailyLimitKey, 0);
    }
  }

  void _incrementDailyCount() {
    _syncDailyDate();
    _dailyAiCount++;
    LocalCache.setInt(_dailyLimitKey, _dailyAiCount);
  }

  // Dominant emotion this session
  EmotionTag? get dominantEmotion {
    if (_emotionHistory.isEmpty) return null;
    return _emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // ── Emotional profile (cross-session intelligence) ────────
  EmotionalProfile get emotionalProfile {
    final happy = (_emotionCounts[EmotionTag.happy] ?? 0) +
        (_emotionCounts[EmotionTag.energetic] ?? 0);
    // Last 10 emotions for trajectory detection
    final recent = _emotionHistory.length > 10
        ? _emotionHistory.sublist(_emotionHistory.length - 10)
        : List<EmotionTag>.from(_emotionHistory);
    return EmotionalProfile(
      dominantEmotion: dominantEmotion,
      daysSinceLastVisit: _daysSinceLastSession(),
      emotionCounts: Map.unmodifiable(_emotionCounts),
      anxietyMentions: _emotionCounts[EmotionTag.anxious] ?? 0,
      stressMentions: _emotionCounts[EmotionTag.stressed] ?? 0,
      sleepMentions: _emotionCounts[EmotionTag.tired] ?? 0,
      periodMentions: _emotionCounts[EmotionTag.period] ?? 0,
      hasPositiveStreak: happy >= 3,
      relationshipMentions: _relationshipMentions,
      recentEmotions: recent,
    );
  }

  /// Generates a warm, personalised greeting based on emotional history.
  String generateGreeting(String name) =>
      emotionalProfile.generateGreeting(name);

  /// Generates a rich daily emotional reading for the home screen card.
  DailyEmotionalReading get dailyReading =>
      emotionalProfile.generateDailyReading(
        _lastContextName ?? '',
      );

  String? _lastContextName;

  // Contextual phase label for UI display
  String get cyclePhaseDisplay => _lastPhaseLabel ?? '';
  String? _lastPhaseLabel;

  // ═══════════════════════════════════════════════════════════
  //  INITIALISATION
  // ═══════════════════════════════════════════════════════════

  Future<void> init() async {
    await _loadHistory();
    await _loadEmotionHistory();

    // Record previous session time BEFORE overwriting with now
    final lastStr = LocalCache.getString(_lastSessionKey);
    _previousSessionAt = lastStr != null ? DateTime.tryParse(lastStr) : null;
    LocalCache.setString(_lastSessionKey, DateTime.now().toIso8601String());

    // Restore daily AI message counter
    _dailyAiDate  = LocalCache.getString(_dailyDateKey) ?? '';
    _dailyAiCount = LocalCache.getInt(_dailyLimitKey) ?? 0;
    _syncDailyDate(); // resets counter if it's a new day

    final key = await LunarAIService.getApiKey();
    _apiKeyConfigured = key != null && key.isNotEmpty;
    if (_messages.isEmpty) {
      _messages.add(ChatMessage.ai(
          LunarAIService.getWelcomeMsg(daysSince: _daysSinceLastSession())));
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Call when auth state changes. Syncs Firestore history.
  Future<void> setUser(String? uid) async {
    if (uid == null || uid == _firestoreUid) return;
    _firestoreUid = uid;
    _firestoreSynced = false;
    await _loadFromFirestore(uid);
  }

  // ═══════════════════════════════════════════════════════════
  //  WELCOME CONTEXT SEEDING
  //  Call from AI screen once pregnancy/intent context is available.
  //  Only acts if the welcome message is the only message (no real
  //  conversation has happened yet) so it is safe to call repeatedly.
  // ═══════════════════════════════════════════════════════════

  void seedWelcomeContext({
    bool isPregnant = false,
    int? pregnancyWeek,
    String? emotionalIntent,
  }) {
    // Don't touch the history if the user has already had a conversation.
    if (_messages.length != 1) return;
    if (_messages.first.isUser) return; // sanity guard — first msg must be AI

    final newWelcome = LunarAIService.getWelcomeMsg(
      daysSince: _daysSinceLastSession(),
      isPregnant: isPregnant,
      pregnancyWeek: pregnancyWeek,
      emotionalIntent: emotionalIntent,
    );
    _messages[0] = ChatMessage.ai(newWelcome);
    notifyListeners();
    // Don't persist seeded welcome — it will be re-seeded on next launch
    // if the conversation is still empty.
  }

  // ═══════════════════════════════════════════════════════════
  //  SEND MESSAGE
  // ═══════════════════════════════════════════════════════════

  Future<void> send(String text, BuildContext context) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _status == ChatStatus.thinking) return;

    // ── Crisis detection: respond INSTANTLY without async delay ─
    // Safety-critical: do not make someone in crisis wait for a
    // "thinking" animation before seeing help resources.
    if (LunarAIService.isCrisis(trimmed)) {
      final emotionTag = _detectEmotion(trimmed);
      _messages.add(ChatMessage.user(trimmed, emotionTag: emotionTag));
      _sessionMessageCount++;
      notifyListeners();
      _saveHistory();
      _syncMessageToFirestore(_messages.last);

      final crisisResp = LunarAIService.crisisResponse();
      _messages.add(ChatMessage.ai(crisisResp.text));
      notifyListeners();
      _saveHistory();
      _syncMessageToFirestore(_messages.last);
      return; // do NOT increment daily counter for crisis responses
    }

    // Build context BEFORE any async gap (context may be gone after await)
    final ctx = _buildContext(context);
    final history = _buildOpenAIHistory();

    // Detect emotion tag for memory
    final emotionTag = _detectEmotion(trimmed);

    // Add user message immediately
    _messages.add(ChatMessage.user(trimmed, emotionTag: emotionTag));
    _status = ChatStatus.thinking;
    _sessionMessageCount++;
    _incrementDailyCount(); // track daily free-tier usage
    notifyListeners();
    _saveHistory(); // fire-and-forget
    _syncMessageToFirestore(_messages.last); // fire-and-forget

    // Update emotional memory
    if (emotionTag != null) {
      _emotionHistory.add(emotionTag);
      _emotionCounts[emotionTag] = (_emotionCounts[emotionTag] ?? 0) + 1;
      _saveEmotionHistory(); // fire-and-forget
    }

    // Track relationship mentions
    if (_isRelationshipMessage(trimmed)) {
      _relationshipMentions++;
    }

    // Extract and store persistent emotional memory
    try {
      if (context.mounted) {
        final memProvider = Provider.of<MemoryProvider>(context, listen: false);
        final extracted = MemoryExtractionEngine.extract(trimmed, emotionTag);
        if (extracted != null) {
          unawaited(memProvider.addMemory(extracted));
        }
      }
    } catch (_) {}

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
    RelationshipService.recordMessage(); // deepen Lunar relationship
    notifyListeners();

    // Healing card follows after a short delay
    if (response.healing != null) {
      await Future.delayed(const Duration(milliseconds: 680));
      _messages.add(ChatMessage.healingCard(response.healing!));
      notifyListeners();
    }

    _saveHistory(); // fire-and-forget
    _syncMessageToFirestore(_messages
        .lastWhere((m) => m.type != ChatMsgType.healingCard)); // sync AI reply
  }

  // ═══════════════════════════════════════════════════════════
  //  SEND WITH MEDIA
  // ═══════════════════════════════════════════════════════════

  Future<void> sendWithMedia(
      XFile file, MediaType mediaType, BuildContext context,
      {bool isPremiumUser = false}) async {
    if (_status == ChatStatus.thinking) return;
    // Gate: respect the same daily limit as text sends.
    // The call site should already show the paywall, but guard here too.
    if (!canSendAiMessage(isPremiumUser)) return;

    final ctx = _buildContext(context);
    final history = _buildOpenAIHistory();

    final attachment = MediaAttachment(
      type: mediaType,
      localPath: file.path,
      fileName: file.name,
    );

    final caption = switch (mediaType) {
      MediaType.image => '🖼️ Shared an image',
      MediaType.video => '🎬 Shared a video',
      MediaType.document => '📎 Shared a document',
    };

    _messages.add(ChatMessage.user(caption, media: attachment));
    _status = ChatStatus.thinking;
    _sessionMessageCount++;
    _incrementDailyCount(); // count media sends against the daily limit
    notifyListeners();
    _saveHistory();
    _syncMessageToFirestore(_messages.last);

    await Future.delayed(const Duration(milliseconds: 900));

    final mediaPrompt = switch (mediaType) {
      MediaType.image =>
        'The user shared an image with me. Please respond warmly and acknowledge it in your Lunar companion persona.',
      MediaType.video =>
        'The user shared a video with me. Please respond warmly and acknowledge it.',
      MediaType.document =>
        'The user shared a document with me. Please respond warmly and acknowledge it.',
    };

    final response = await LunarAIService.respond(
      mediaPrompt,
      context: ctx,
      conversationHistory: history,
    );

    _status = ChatStatus.idle;
    _messages.add(ChatMessage.ai(response.text, healing: response.healing));
    notifyListeners();
    _saveHistory();
    _syncMessageToFirestore(_messages.last);

    if (response.healing != null) {
      await Future.delayed(const Duration(milliseconds: 680));
      _messages.add(ChatMessage.healingCard(response.healing!));
      notifyListeners();
      _saveHistory();
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> sendQuickAction(String label, BuildContext context) =>
      send(label, context);

  // ── Daily check-in state ──────────────────────────────────
  static const _checkInKey = 'lunar_checkin_day_v1';

  /// Returns the day-of-month when the user last completed a check-in, or null.
  int? get lastCheckInDay {
    final stored = LocalCache.getInt(_checkInKey);
    return stored;
  }

  /// Marks today as checked in — persists across app restarts.
  void markCheckInToday() {
    LocalCache.setInt(_checkInKey, DateTime.now().day);
    notifyListeners();
  }

  // ── Check-in seed prompt ──────────────────────────────────
  String? _checkInSeedPrompt;
  String? get checkInSeedPrompt => _checkInSeedPrompt;

  /// Queues a seed prompt to be auto-sent when AI screen opens.
  void queueCheckInSeed(String prompt) {
    _checkInSeedPrompt = prompt;
  }

  /// Clears the queued seed prompt (call after consuming it).
  void clearCheckInSeed() {
    _checkInSeedPrompt = null;
  }

  // ═══════════════════════════════════════════════════════════
  //  HISTORY MANAGEMENT
  // ═══════════════════════════════════════════════════════════

  void clearHistory() {
    _messages.clear();
    _messages.add(ChatMessage.ai(LunarAIService.welcomeMsg));
    _emotionHistory.clear();
    _emotionCounts.clear();
    _sessionMessageCount = 0;
    _relationshipMentions = 0;
    notifyListeners();
    LocalCache.setString(_persistKey, '[]');
    LocalCache.setString(_emotionKey, '[]');
    _clearFirestoreHistory();
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
      _lastContextName = app.userName; // Cache for dailyReading getter

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
        // ── Emotional memory (session-level) ────────────────
        'memoryContext': _buildMemoryContextStr(),
        'dominantEmotion': dominantEmotion?.name,
        'daysSinceLastSession': _daysSinceLastSession(),
        // ── Deep emotional memory (persistent, cross-session) ─
        'deepMemoryContext': () {
          try {
            return Provider.of<MemoryProvider>(ctx, listen: false)
                .buildContextString();
          } catch (_) {
            return null;
          }
        }(),
        // ── Emotional intelligence ───────────────────────────
        'emotionalTrajectory': emotionalProfile.emotionalTrajectory,
        'patternInsight': emotionalProfile.patternInsight,
      };
    } catch (_) {
      return {};
    }
  }

  // ── Emotional memory helpers ─────────────────────────────

  /// Days since the previous session (0 if first or same day).
  int _daysSinceLastSession() {
    if (_previousSessionAt == null) return 0;
    return DateTime.now().difference(_previousSessionAt!).inDays;
  }

  /// Builds a soft memory context string for injection into the AI system prompt.
  String? _buildMemoryContextStr() {
    final parts = <String>[];
    final anxious = _emotionCounts[EmotionTag.anxious] ?? 0;
    final stressed = _emotionCounts[EmotionTag.stressed] ?? 0;
    final tired = _emotionCounts[EmotionTag.tired] ?? 0;
    final sad = _emotionCounts[EmotionTag.sad] ?? 0;
    final lonely = _emotionCounts[EmotionTag.lonely] ?? 0;
    final period = _emotionCounts[EmotionTag.period] ?? 0;
    final happy = (_emotionCounts[EmotionTag.happy] ?? 0) +
        (_emotionCounts[EmotionTag.energetic] ?? 0);
    if (anxious >= 2) {
      parts.add(
          'She has mentioned feeling anxious $anxious times recently — be especially gentle and grounding.');
    }
    if (stressed >= 2) {
      parts.add(
          'She has felt overwhelmed or stressed $stressed times recently — validate before advising.');
    }
    if (tired >= 2) {
      parts.add(
          'Sleep struggles or exhaustion have come up $tired times — honor her tiredness with warmth.');
    }
    if (sad >= 2) {
      parts.add(
          'She has been feeling sad or down $sad times — hold extra emotional space, poetic validation first.');
    }
    if (lonely >= 1) {
      parts.add(
          'Loneliness has come up recently — emphasize your presence and connection.');
    }
    if (period >= 1) {
      parts.add(
          'She has mentioned her period or menstrual symptoms — be extra warm and comfort-aware.');
    }
    if (happy >= 3) {
      parts.add(
          'She has been in a positive emotional space recently — celebrate this gently.');
    }
    final days = _daysSinceLastSession();
    if (days >= 3) {
      parts.add(
          'She has been away for $days days — welcome her return warmly with gentle acknowledgment.');
    }
    return parts.isEmpty ? null : parts.join('\n');
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

  /// Detects relationship/heartbreak mentions for emotional memory.
  static bool _isRelationshipMessage(String text) {
    final l = text.toLowerCase();
    return l.contains('breakup') ||
        l.contains('break up') ||
        l.contains('heartbreak') ||
        l.contains('heartbroken') ||
        l.contains('he left') ||
        l.contains('she left') ||
        l.contains('they left') ||
        l.contains('cheated') ||
        l.contains('betrayed') ||
        l.contains('rejection') ||
        l.contains('rejected') ||
        (l.contains('love') && (l.contains('lost') || l.contains('miss')));
  }

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

  // ═══════════════════════════════════════════════════════════
  //  FIRESTORE PERSISTENCE
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadFromFirestore(String uid) async {
    if (_firestoreSynced) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(_firestoreCollection)
          .orderBy('timestamp')
          .limitToLast(_historyLimit)
          .get();
      if (snap.docs.isEmpty) {
        // First login — push existing local messages to Firestore
        for (final m
            in _messages.where((m) => m.type != ChatMsgType.healingCard)) {
          _syncMessageToFirestore(m);
        }
        _firestoreSynced = true;
        return;
      }
      // Merge Firestore messages that are not already in local cache
      final localIds = _messages.map((m) => m.id).toSet();
      final remote = snap.docs
          .map((d) {
            try {
              return ChatMessage.fromJson(d.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<ChatMessage>()
          .where((m) => !localIds.contains(m.id))
          .toList();
      if (remote.isNotEmpty) {
        _messages.insertAll(0, remote);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _saveHistory();
        notifyListeners();
      }
      _firestoreSynced = true;
    } catch (e) {
      debugPrint('[ChatProvider] Firestore load error: $e');
    }
  }

  void _syncMessageToFirestore(ChatMessage msg) {
    final uid = _firestoreUid;
    if (uid == null || msg.type == ChatMsgType.healingCard) return;
    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(_firestoreCollection)
          .doc(msg.id)
          .set(msg.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[ChatProvider] Firestore sync error: $e');
    }
  }

  void _clearFirestoreHistory() {
    final uid = _firestoreUid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(_firestoreCollection)
        .get()
        .then((snap) {
      for (final doc in snap.docs) {
        doc.reference.delete();
      }
    }).catchError((e) {
      debugPrint('[ChatProvider] Firestore clear error: $e');
    });
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
