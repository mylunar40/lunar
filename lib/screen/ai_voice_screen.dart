import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import '../core/models/chat_message.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/app_provider.dart';
import '../core/providers/lunar_data_provider.dart';
import '../core/providers/memory_provider.dart';
import '../core/models/deep_memory.dart';
import '../core/models/cycle_model.dart';
import '../services/relationship_service.dart';

// ===========================================================
//  LUNAR AI CHAT SCREEN
//  Emotional companion experience - premium, warm, intelligent
// ===========================================================

// -- Design tokens -------------------------------------------
const Color _kBg = Color(0xFF0A0118);
const Color _kPurple = Color(0xFFAB5CF2);
const Color _kPink = Color(0xFFFF69B4);
const Color _kDeep = Color(0xFF5C2DB8);
const Color _kGold = Color(0xFFFFD700);

// ===========================================================
//  HEALING CARD DATA  (UI-scoped display data)
// ===========================================================

class _HealData {
  final String emoji, title, body;
  final Color color;
  const _HealData(this.emoji, this.title, this.body, this.color);
}

const Map<HealingKind, _HealData> _kCards = {
  HealingKind.breathe: _HealData(
    '\u{1F32C}\u{FE0F}',
    'Breathing Exercise',
    'Inhale 4 \u00B7 Hold 4 \u00B7 Exhale 6 \u00B7 Hold 2\nRepeat 4 times to activate your natural calm response. \u2728',
    Color(0xFF4FC3F7),
  ),
  HealingKind.affirmation: _HealData(
    '\u{1F49C}',
    'You Are Enough',
    'You are worthy of love exactly as you are \u2014 in this moment, without changing a single thing. You are enough. \u{1F338}',
    Color(0xFFAB5CF2),
  ),
  HealingKind.sleep: _HealData(
    '\u{1F319}',
    'Sleep Ritual',
    'Dim lights 1 hour before bed \u00B7 Step away from screens \u00B7 Warm chamomile tea \u00B7 Gentle body scan. Your rest is sacred. \u2728',
    Color(0xFF7986CB),
  ),
  HealingKind.hydrate: _HealData(
    '\u{1F4A7}',
    'Hydration Reminder',
    'Your hormones need water to stay balanced. One tall glass right now can shift your mood within minutes. \u{1F33F}',
    Color(0xFF4FC3F7),
  ),
  HealingKind.cycle: _HealData(
    '\u{1FA78}',
    'Cycle Wisdom',
    'Your emotions are deeply tied to your cycle phases. What you\'re feeling is valid \u2014 it\'s your body\'s ancient wisdom speaking. \u{1F49C}',
    Color(0xFFB05C8A),
  ),
  HealingKind.gentle: _HealData(
    '\u{1F338}',
    'Gentle Reminder',
    'Treat yourself with the same tenderness you\'d offer someone you love deeply. You deserve that same softness. \u2728',
    Color(0xFFFF69B4),
  ),
};

// -- Phase display config ------------------------------------
const Map<LunarCyclePhase, Map<String, dynamic>> _kPhaseConfig = {
  LunarCyclePhase.period: {
    'emoji': '\u{1FA78}',
    'label': 'Menstrual Phase',
    'color': Color(0xFFB05C8A),
    'tip': 'Rest deeply. You deserve it.',
  },
  LunarCyclePhase.follicular: {
    'emoji': '\u{1F331}',
    'label': 'Follicular Phase',
    'color': Color(0xFF66BB6A),
    'tip': 'Energy rising. Perfect for new starts.',
  },
  LunarCyclePhase.ovulation: {
    'emoji': '\u2728',
    'label': 'Ovulation Phase',
    'color': Color(0xFFFFD700),
    'tip': 'You\'re glowing at your peak.',
  },
  LunarCyclePhase.luteal: {
    'emoji': '\u{1F319}',
    'label': 'Luteal Phase',
    'color': Color(0xFF7986CB),
    'tip': 'Honor your emotions. They\'re valid.',
  },
};

// -- Sanctuary: rotating emotional insights -----------------
const List<String> _kInsights = [
  'You seem emotionally sensitive today 🌙',
  'Your energy feels beautifully calm tonight ✨',
  "You've been so strong this week 💜",
  'Rest is productive. You deserve peace 🌸',
  'Your feelings are wisdom, not weakness 💫',
  'Breathe. You are exactly where you need to be 🌿',
  'Your body speaks truth. Listen softly 🩸',
  'Every emotion you feel is valid and seen 🌙',
];

// -- Sanctuary: quick healing actions -----------------------
const List<(String, String, Color, String)> _kSanctuaryActions = [
  (
    '🌬️',
    'Calm\nAnxiety',
    Color(0xFF4FC3F7),
    'Help me calm my anxiety right now'
  ),
  (
    '💤',
    'Sleep\nSupport',
    Color(0xFF7986CB),
    'I need help falling asleep tonight'
  ),
  ('💜', 'Emotional\nReset', Color(0xFFAB5CF2), 'I need an emotional reset'),
  ('🌸', 'Affirmation', Color(0xFFFF69B4), 'Give me a powerful affirmation'),
  ('📝', 'Journal\nFeelings', Color(0xFF66BB6A), 'Help me journal my feelings'),
  (
    '🌙',
    'Breathing\nSession',
    Color(0xFFFFB74D),
    'Guide me through a breathing session'
  ),
];

// ===========================================================
//  MAIN SCREEN WIDGET
// ===========================================================

class AIVoiceScreen extends StatefulWidget {
  const AIVoiceScreen({super.key});

  @override
  State<AIVoiceScreen> createState() => _AIVoiceState();
}

class _AIVoiceState extends State<AIVoiceScreen> with TickerProviderStateMixin {
  // -- Animation controllers ----------------------------------
  late AnimationController _glowCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _typingCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _shimmerAnim;
  late AnimationController _auraCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _pulseAnim;
  // Focus animation for input bar
  late AnimationController _focusCtrl;
  late Animation<double> _focusAnim;
  // Media FAB expansion animation
  late AnimationController _mediaFabCtrl;
  late Animation<double> _mediaFabAnim;

  // -- UI state -----------------------------------------------
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;
  bool _apiNudgeDismissed = false;
  int _tappedChipIdx = -1;
  bool _showApiKeySheet = false;
  final TextEditingController _apiKeyCtrl = TextEditingController();
  bool _apiKeyObscured = true;
  bool _isFocused = false;
  bool _showMediaOptions = false;

  // -- Voice / STT state --------------------------------------
  final stt.SpeechToText _sttService = stt.SpeechToText();
  bool _sttAvailable = false;
  String _voiceText = '';

  // -- Media state --------------------------------------------
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _pendingMedia;
  MediaType? _pendingMediaType;

  // -- Sanctuary state ----------------------------------------
  bool _inSanctuary = true;
  int _insightIdx = 0;
  Timer? _insightTimer;

  // -- Emotional presence state ─────────────────────────────
  bool _milestoneShown = false;
  bool _showMilestone = false;
  String _milestoneText = '';
  late AnimationController _milestoneCtrl;
  late Animation<double> _milestoneAnim;

  // -- WOW moment pulse ─────────────────────────────────────
  late AnimationController _wowCtrl;
  bool _wowVisible = false;
  int _prevMsgCount = 0;
  ChatProvider? _chatListenerRef; // for safe listener add/remove

  // -- Particles ----------------------------------------------
  final List<_AIStar> _stars = [];
  final math.Random _rng = math.Random();

  // -- Lifecycle ----------------------------------------------
  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 12; i++) {
      _stars.add(_AIStar(rng: _rng));
    }

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _typingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear),
    );

    _auraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.93, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _focusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _focusAnim =
        CurvedAnimation(parent: _focusCtrl, curve: Curves.easeOutCubic);

    _mediaFabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _mediaFabAnim =
        CurvedAnimation(parent: _mediaFabCtrl, curve: Curves.easeOutBack);

    _milestoneCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _milestoneAnim =
        CurvedAnimation(parent: _milestoneCtrl, curve: Curves.easeOutCubic);

    _wowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _wowCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _wowCtrl.reset();
        if (mounted) setState(() => _wowVisible = false);
      }
    });

    // Focus listener for input bar glow
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _focusCtrl.forward();
        setState(() => _isFocused = true);
      } else {
        _focusCtrl.reverse();
        setState(() => _isFocused = false);
      }
    });

    // Initialize speech-to-text
    _initStt();

    _insightTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _inSanctuary) {
        setState(() => _insightIdx = (_insightIdx + 1) % _kInsights.length);
      }
    });

    // Auto-skip sanctuary if chat has ongoing conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chat = context.read<ChatProvider>();
      if (chat.messages.length > 1) setState(() => _inSanctuary = false);

      // Auto-send daily check-in seed prompt if queued
      final seed = chat.checkInSeedPrompt;
      if (seed != null && seed.isNotEmpty) {
        chat.clearCheckInSeed();
        setState(() => _inSanctuary = false);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          chat.send(seed, context);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe listener pattern — detach old, attach new
    final chat = context.read<ChatProvider>();
    if (_chatListenerRef != chat) {
      _chatListenerRef?.removeListener(_onChatUpdate);
      _chatListenerRef = chat;
      _chatListenerRef?.addListener(_onChatUpdate);
    }
  }

  void _onChatUpdate() {
    if (!mounted) return;
    final chat = _chatListenerRef;
    if (chat == null) return;
    final count = chat.messages.length;
    if (count > _prevMsgCount && !chat.isTyping) {
      final last = chat.messages.last;
      // WOW moment fires on AI healing cards — emotionally significant responses
      if (!last.isUser && last.type == ChatMsgType.healingCard) {
        _triggerWow();
      }
      _prevMsgCount = count;
    }
  }

  void _triggerWow() {
    if (!mounted || _wowCtrl.isAnimating) return;
    setState(() => _wowVisible = true);
    _wowCtrl.forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _chatListenerRef?.removeListener(_onChatUpdate);
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _typingCtrl.dispose();
    _particleCtrl.dispose();
    _waveCtrl.dispose();
    _shimmerCtrl.dispose();
    _auraCtrl.dispose();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _focusCtrl.dispose();
    _mediaFabCtrl.dispose();
    _milestoneCtrl.dispose();
    _wowCtrl.dispose();
    _insightTimer?.cancel();
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    _apiKeyCtrl.dispose();
    _sttService.cancel();
    super.dispose();
  }

  // -- Helpers ------------------------------------------------
  // Returns dynamic emotional status based on context
  String _emotionalStatus(bool isTyping) {
    if (isTyping) return 'Feeling your words... \u2728';
    final h = DateTime.now().hour;
    if (h >= 5 && h < 10) return 'Good morning, love \u{1F338}';
    if (h >= 10 && h < 14) return 'Here with you \u{1F49C}';
    if (h >= 14 && h < 18) return 'Listening softly \u{1F319}';
    if (h >= 18 && h < 22) return 'Here for you tonight \u2728';
    return 'Your space to feel \u{1F319}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _textCtrl.clear();
    _focusNode.unfocus();
    context.read<ChatProvider>().send(t, context);
    _scrollToBottom();
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyCtrl.text.trim();
    if (key.isEmpty) return;
    await context.read<ChatProvider>().saveApiKey(key);
    _apiKeyCtrl.clear();
    if (mounted) setState(() => _showApiKeySheet = false);
    HapticFeedback.lightImpact();
  }

  void _showClearConfirm() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0535),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Chat? \u{1F319}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will clear your conversation history and emotional memory from this session.',
          style: TextStyle(color: Colors.white.withOpacity(0.65), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep',
                style: TextStyle(color: Colors.white.withOpacity(0.50))),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().clearHistory();
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
            },
            child:
                const Text('Clear', style: TextStyle(color: Color(0xFFFF69B4))),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  STT — SPEECH TO TEXT
  // ===========================================================
  Future<void> _initStt() async {
    _sttAvailable = await _sttService.initialize(
      onError: (e) {
        debugPrint('[STT] error: $e');
        if (mounted) setState(() => _isRecording = false);
      },
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) {
          _handleVoiceResult();
        }
      },
    );
  }

  void _startListening() async {
    if (!_sttAvailable) {
      // Graceful fallback if STT not available
      HapticFeedback.mediumImpact();
      setState(() => _isRecording = true);
      return;
    }
    setState(() {
      _isRecording = true;
      _voiceText = '';
    });
    HapticFeedback.mediumImpact();
    await _sttService.listen(
      onResult: (r) {
        if (mounted) setState(() => _voiceText = r.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  void _stopListening() {
    _sttService.stop();
    setState(() => _isRecording = false);
    _handleVoiceResult();
  }

  void _handleVoiceResult() {
    if (!mounted) return;
    final text = _voiceText.trim();
    setState(() {
      _isRecording = false;
      _voiceText = '';
    });
    if (text.isNotEmpty) {
      _send(text);
    }
  }

  // ===========================================================
  //  MEDIA PICKER
  // ===========================================================
  Future<void> _pickImage(ImageSource source) async {
    setState(() => _showMediaOptions = false);
    _mediaFabCtrl.reverse();
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (file != null && mounted) {
        setState(() {
          _pendingMedia = file;
          _pendingMediaType = MediaType.image;
        });
      }
    } catch (e) {
      debugPrint('[Media] image pick error: $e');
    }
  }

  Future<void> _pickVideo() async {
    setState(() => _showMediaOptions = false);
    _mediaFabCtrl.reverse();
    try {
      final file = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (file != null && mounted) {
        setState(() {
          _pendingMedia = file;
          _pendingMediaType = MediaType.video;
        });
      }
    } catch (e) {
      debugPrint('[Media] video pick error: $e');
    }
  }

  void _clearPendingMedia() => setState(() {
        _pendingMedia = null;
        _pendingMediaType = null;
      });

  void _sendWithPendingMedia() {
    final file = _pendingMedia;
    final type = _pendingMediaType;
    if (file == null || type == null) return;
    _clearPendingMedia();
    context.read<ChatProvider>().sendWithMedia(file, type, context);
    _scrollToBottom();
  }

  // ===========================================================
  //  BUILD  — routes to sanctuary or chat
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final lunarData = context.watch<LunarDataProvider>();
    final size = MediaQuery.of(context).size;

    if (!_inSanctuary && chat.messages.isNotEmpty) _scrollToBottom();

    // Trigger pattern milestone "wow moment" once per session
    if (!_milestoneShown && !_inSanctuary && chat.messages.length > 4) {
      final insight = chat.emotionalProfile.patternInsight;
      if (insight != null && !_showMilestone) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _milestoneShown) return;
          setState(() {
            _milestoneShown = true;
            _showMilestone = true;
            _milestoneText = insight;
          });
          _milestoneCtrl.forward(from: 0);
          Future.delayed(const Duration(seconds: 4), () {
            if (!mounted) return;
            _milestoneCtrl.reverse().then((_) {
              if (mounted) setState(() => _showMilestone = false);
            });
          });
        });
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: _inSanctuary
          ? KeyedSubtree(
              key: const ValueKey('sanctuary'),
              child: _buildSanctuary(chat, lunarData, size),
            )
          : KeyedSubtree(
              key: const ValueKey('chat'),
              child: _buildChat(chat, size),
            ),
    );
  }

  // ===========================================================
  //  CHAT SCAFFOLD  (existing experience, untouched logic)
  // ===========================================================
  Widget _buildChat(ChatProvider chat, Size size) {
    return Scaffold(
      backgroundColor: _kBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _AIBg(size: size),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _AIStarPainter(
                    stars: _stars, progress: _particleCtrl.value),
              ),
            ),
          ),
          if (_showApiKeySheet) _apiKeyOverlay(chat),
          SafeArea(
            child: Column(
              children: [
                // Slim sanctuary-back row
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _inSanctuary = true);
                  },
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kPurple.withOpacity(0.06),
                        border: Border(
                          bottom: BorderSide(
                              color:
                                  _kPurple.withOpacity(0.18 * _glowAnim.value),
                              width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              color: _kPurple.withOpacity(0.65), size: 12),
                          const SizedBox(width: 5),
                          Text(
                            '← Back to Sanctuary',
                            style: TextStyle(
                              color: _kPurple.withOpacity(0.65),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _headerBar(chat),
                _phaseBanner(context),
                _lunarRemembersBanner(context),
                if (!chat.apiKeyConfigured && !_apiNudgeDismissed) _apiNudge(),
                Expanded(
                  child: Stack(
                    children: [
                      _chatArea(chat, size),
                      _emotionalAuraOverlay(chat),
                      if (_showMilestone) _milestoneOverlay(),
                      if (_wowVisible) _wowPulseOverlay(),
                    ],
                  ),
                ),
                _quickActions(chat),
                _inputBar(chat),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  HEADER BAR
  // ===========================================================
  Widget _headerBar(ChatProvider chat) {
    final app = context.watch<AppProvider>();
    final name = app.userName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        children: [
          // Avatar with orbital dots + breathing glow
          AnimatedBuilder(
            animation: Listenable.merge([_glowCtrl, _floatCtrl, _particleCtrl]),
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _floatAnim.value * 0.38),
              child: SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow — pulses stronger when AI is typing
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _kPurple.withOpacity(
                              chat.isTyping
                                  ? 0.72 * _glowAnim.value
                                  : 0.52 * _glowAnim.value,
                            ),
                            blurRadius: chat.isTyping ? 36 : 26,
                            spreadRadius: chat.isTyping ? 8 : 6,
                          ),
                        ],
                      ),
                    ),
                    // Moon avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFF9B59D8), Color(0xFF5C2DB8)],
                          center: Alignment(-0.3, -0.3),
                        ),
                        border: Border.all(
                          color: _kPurple.withOpacity(0.72 * _glowAnim.value),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child:
                            Text('\u{1F319}', style: TextStyle(fontSize: 26)),
                      ),
                    ),
                    // Orbital dots
                    ...List.generate(3, (i) {
                      final angle = _particleCtrl.value * math.pi * 2 +
                          i * (math.pi * 2 / 3);
                      final r = 28.0;
                      final ox = math.cos(angle) * r + 34;
                      final oy = math.sin(angle) * r + 34;
                      final twinkle =
                          (0.4 + 0.6 * math.sin(angle + i)).clamp(0.0, 1.0);
                      return Positioned(
                        left: ox - 3,
                        top: oy - 3,
                        child: Opacity(
                          opacity: twinkle,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == 0
                                  ? _kPink.withOpacity(0.85)
                                  : i == 1
                                      ? _kPurple.withOpacity(0.85)
                                      : _kGold.withOpacity(0.70),
                              boxShadow: [
                                BoxShadow(
                                  color: (i == 0
                                          ? _kPink
                                          : i == 1
                                              ? _kPurple
                                              : _kGold)
                                      .withOpacity(0.55),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Lunar AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (name.isNotEmpty)
                        TextSpan(
                          text: '  \u2736  $name',
                          style: TextStyle(
                            color: _kPurple.withOpacity(0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              chat.isTyping ? _kPink : const Color(0xFF66BB6A),
                          boxShadow: [
                            BoxShadow(
                              color: (chat.isTyping
                                      ? _kPink
                                      : const Color(0xFF66BB6A))
                                  .withOpacity(0.78 * _glowAnim.value),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _emotionalStatus(chat.isTyping),
                        key: ValueKey(_emotionalStatus(chat.isTyping)),
                        style: TextStyle(
                          color: chat.isTyping
                              ? _kPink.withOpacity(0.72)
                              : Colors.white.withOpacity(0.50),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Relationship level badge
                    Builder(builder: (_) {
                      final rel = RelationshipService.current();
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: rel.level.color.withOpacity(0.14),
                            border: Border.all(
                                color: rel.level.color.withOpacity(0.38),
                                width: 0.8),
                          ),
                          child: Text(
                            '${rel.level.emoji} ${rel.level.title}',
                            style: TextStyle(
                              color: rel.level.color.withOpacity(0.82),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              _headerBtn(
                Icons.key_rounded,
                chat.apiKeyConfigured
                    ? const Color(0xFF66BB6A)
                    : Colors.white.withOpacity(0.40),
                () => setState(() => _showApiKeySheet = !_showApiKeySheet),
              ),
              const SizedBox(width: 8),
              _headerBtn(
                Icons.auto_awesome_rounded,
                _kPurple.withOpacity(0.80),
                () => _showMemorySheet(context),
              ),
              const SizedBox(width: 8),
              _headerBtn(
                Icons.refresh_rounded,
                Colors.white.withOpacity(0.40),
                _showClearConfirm,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: Colors.white.withOpacity(0.07),
          border: Border.all(color: Colors.white.withOpacity(0.11)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ===========================================================
  //  CYCLE PHASE BANNER
  // ===========================================================
  Widget _phaseBanner(BuildContext context) {
    final lunarData = context.watch<LunarDataProvider>();
    final phase = lunarData.currentPhase;
    final cfg = _kPhaseConfig[phase];
    if (cfg == null) return const SizedBox.shrink();

    final cycleDay = lunarData.currentCycleDay;
    final dayLabel = cycleDay > 0 ? '\u00B7 Day $cycleDay' : '';

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: (cfg['color'] as Color).withOpacity(0.12),
          border: Border.all(
            color: (cfg['color'] as Color).withOpacity(0.28 * _glowAnim.value),
          ),
        ),
        child: Row(
          children: [
            Text(cfg['emoji'] as String, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cfg['label']} $dayLabel',
                    style: TextStyle(
                      color: cfg['color'] as Color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    cfg['tip'] as String,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (lunarData.isPregnant)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _kPink.withOpacity(0.18),
                ),
                child: Text(
                  '\u{1F930} Pregnant',
                  style: TextStyle(
                    color: _kPink.withOpacity(0.90),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  //  API NUDGE BANNER
  // ===========================================================
  Widget _apiNudge() {
    return GestureDetector(
      onTap: () => setState(() => _showApiKeySheet = true),
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              _kGold.withOpacity(0.12),
              _kPink.withOpacity(0.08),
            ],
          ),
          border: Border.all(color: _kGold.withOpacity(0.30)),
        ),
        child: Row(
          children: [
            const Text('\u2728', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add your OpenAI key for intelligent AI responses \u2014 tap to connect',
                style: TextStyle(
                  color: _kGold.withOpacity(0.85),
                  fontSize: 11.5,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _apiNudgeDismissed = true),
              child: Icon(Icons.close_rounded,
                  color: Colors.white.withOpacity(0.35), size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  //  API KEY OVERLAY
  // ===========================================================
  Widget _apiKeyOverlay(ChatProvider chat) {
    return GestureDetector(
      onTap: () => setState(() => _showApiKeySheet = false),
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0535).withOpacity(0.96),
                    border: Border.all(color: _kPurple.withOpacity(0.25)),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _kPurple.withOpacity(0.18),
                            ),
                            child: const Text('\u2728',
                                style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Connect OpenAI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Enable intelligent AI responses',
                                  style: TextStyle(
                                    color: Color(0xFF9B59D8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Your API key is stored only on this device and never shared. '
                        'Get your key at platform.openai.com',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withOpacity(0.06),
                              border:
                                  Border.all(color: _kPurple.withOpacity(0.28)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _apiKeyCtrl,
                                    obscureText: _apiKeyObscured,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                    cursorColor: _kPurple,
                                    decoration: InputDecoration(
                                      hintText: 'sk-...',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.25),
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _apiKeyObscured
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.white.withOpacity(0.40),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _apiKeyObscured = !_apiKeyObscured),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (chat.apiKeyConfigured)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF66BB6A), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'OpenAI key connected \u2728',
                                style: TextStyle(
                                  color:
                                      const Color(0xFF66BB6A).withOpacity(0.85),
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () async {
                                  await context
                                      .read<ChatProvider>()
                                      .removeApiKey();
                                },
                                child: Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: _kPink.withOpacity(0.75),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      GestureDetector(
                        onTap: _saveApiKey,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B2DB8), Color(0xFFAB5CF2)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kPurple.withOpacity(0.40),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Save Key \u2728',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  //  EMOTIONAL AURA OVERLAY
  //  Subtle ambient glow tinted to dominant emotion
  // ===========================================================
  Widget _emotionalAuraOverlay(ChatProvider chat) {
    final emotion = chat.dominantEmotion;
    if (emotion == null) return const SizedBox.shrink();
    final Color aura = switch (emotion) {
      EmotionTag.anxious => const Color(0xFF4FC3F7),
      EmotionTag.sad => const Color(0xFF7986CB),
      EmotionTag.lonely => const Color(0xFFAB5CF2),
      EmotionTag.stressed => const Color(0xFF7986CB),
      EmotionTag.happy => const Color(0xFFFFD700),
      EmotionTag.energetic => const Color(0xFF66BB6A),
      EmotionTag.tired => const Color(0xFF9C27B0),
      EmotionTag.emotional => const Color(0xFFFF69B4),
      EmotionTag.period => const Color(0xFFB05C8A),
      _ => _kPurple,
    };
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => Stack(children: [
          // Top ambient wash — pulses softly with glow animation
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.4,
                colors: [
                  aura.withOpacity(0.07 * _glowAnim.value),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Bottom secondary warm pulse — different color and radius
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 1.2,
                colors: [
                  aura.withOpacity(0.035 * _glowAnim.value),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ===========================================================
  //  PATTERN MILESTONE "WOW MOMENT"
  //  Surfaces when Lunar notices emotional growth
  // ===========================================================
  Widget _milestoneOverlay() {
    return Positioned(
      top: 12,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _milestoneAnim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(_milestoneAnim),
          child: GestureDetector(
            onTap: () {
              _milestoneCtrl.reverse().then((_) {
                if (mounted) setState(() => _showMilestone = false);
              });
            },
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFAB5CF2).withOpacity(0.32),
                          const Color(0xFFFF69B4).withOpacity(0.18),
                          Colors.white.withOpacity(0.06),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFAB5CF2)
                            .withOpacity(0.55 * _glowAnim.value),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFAB5CF2)
                              .withOpacity(0.28 * _glowAnim.value),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Transform.scale(
                            scale: _pulseAnim.value,
                            child: const Text('🌙',
                                style: TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lunar Noticed Something 🌸',
                                style: TextStyle(
                                  color: const Color(0xFFD8A8FF),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _milestoneText,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.82),
                                  fontSize: 12.5,
                                  height: 1.45,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  //  WOW MOMENT PULSE — Expanding ring waves on healing responses
  // ===========================================================
  Widget _wowPulseOverlay() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _wowCtrl,
        builder: (_, __) {
          final t = Curves.easeOut.transform(_wowCtrl.value);
          return Stack(
            children: [
              // Center label — briefly reveals then fades
              if (t > 0.05 && t < 0.55)
                Center(
                  child: Opacity(
                    opacity: (1.0 - t * 2).clamp(0.0, 0.7),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: const Color(0xFFAB5CF2).withOpacity(0.18),
                        border: Border.all(
                            color: const Color(0xFFAB5CF2).withOpacity(0.35),
                            width: 1),
                      ),
                      child: Text(
                        'Lunar felt that 🌙',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),

              // 4 expanding ring waves — staggered delays
              ...List.generate(4, (i) {
                final delay = i * 0.16;
                final progress = (t - delay).clamp(0.0, 1.0);
                final opacity =
                    (progress < 0.05) ? 0.0 : (1.0 - progress) * 0.30;
                final radius = 40.0 +
                    Curves.easeOut.transform(progress) * (160.0 + i * 36.0);
                return Center(
                  child: Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFAB5CF2).withOpacity(opacity),
                        width: (1.8 - i * 0.3).clamp(0.3, 1.8),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================
  //  CHAT AREA
  // ===========================================================
  Widget _chatArea(ChatProvider chat, Size size) {
    final msgs = chat.messages;
    final total = msgs.length + (chat.isTyping ? 1 : 0) + 1;

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      physics: const BouncingScrollPhysics(),
      cacheExtent: 800,
      itemCount: total,
      itemBuilder: (_, i) {
        if (i == msgs.length + (chat.isTyping ? 1 : 0)) {
          return const SizedBox(height: 12);
        }
        if (i == msgs.length && chat.isTyping) {
          return _typingBubble();
        }
        final msg = msgs[i];
        // ── Consecutive-sender grouping (within 3 min = compact)
        final prevMsg = i > 0 ? msgs[i - 1] : null;
        final isGrouped = prevMsg != null &&
            prevMsg.isUser == msg.isUser &&
            msg.timestamp.difference(prevMsg.timestamp).inMinutes < 3;
        // ── Day-change separator
        final showDate =
            prevMsg == null || !_isSameDay(prevMsg.timestamp, msg.timestamp);
        // Last AI message gets a live breathing border
        final isLastAiMsg =
            !msg.isUser && !chat.isTyping && i == msgs.length - 1;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDate) _dateSeparator(msg.timestamp),
            _AnimatedMsg(
              key: ValueKey(msg.id),
              isUser: msg.isUser,
              child: msg.type == ChatMsgType.healingCard
                  ? _buildHealingCard(msg, size)
                  : _buildBubble(msg, size,
                      isLatestAi: isLastAiMsg, isGrouped: isGrouped),
            ),
          ],
        );
      },
    );
  }

  // -- Chat bubble ---------------------------------------------
  Widget _buildBubble(ChatMessage msg, Size size,
      {bool isLatestAi = false, bool isGrouped = false}) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isGrouped ? 4 : 14,
        left: msg.isUser ? size.width * 0.16 : 0,
        right: msg.isUser ? 0 : size.width * 0.08,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            isGrouped ? const SizedBox(width: 38) : _miniMoonAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (msg.mediaAttachment != null)
                  _mediaPreviewCard(msg.mediaAttachment!),
                if (msg.text.isNotEmpty)
                  msg.isUser
                      ? _userBubble(msg)
                      : _aiBubble(msg, isLatest: isLatestAi),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaPreviewCard(MediaAttachment media) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      width: 220,
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: _kPurple.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: switch (media.type) {
          MediaType.image => _imagePreview(media),
          MediaType.video => _videoPreview(media),
          MediaType.document => _documentPreview(media),
        },
      ),
    );
  }

  Widget _imagePreview(MediaAttachment media) {
    if (media.localPath.isEmpty) return _mediaPlaceholder(media);
    return Stack(
      children: [
        Image.file(
          File(media.localPath),
          width: 220,
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _mediaPlaceholder(media),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black.withOpacity(0.50),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_rounded, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text('Image',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _videoPreview(MediaAttachment media) {
    return Container(
      height: 120,
      color: Colors.black.withOpacity(0.55),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPurple.withOpacity(0.75),
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            media.fileName ?? 'Video',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _documentPreview(MediaAttachment media) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _kPurple.withOpacity(0.18),
            ),
            child: const Icon(Icons.description_rounded,
                color: Color(0xFFAB5CF2), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.fileName ?? 'Document',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text('Tap to open',
                    style: TextStyle(
                        color: _kPurple.withOpacity(0.65), fontSize: 10.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaPlaceholder(MediaAttachment media) {
    return Container(
      height: 80,
      color: _kDeep.withOpacity(0.40),
      child: Center(
        child: Icon(Icons.broken_image_rounded,
            color: Colors.white.withOpacity(0.30), size: 32),
      ),
    );
  }

  Widget _miniMoonAvatar() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF9B59D8), Color(0xFF5C2DB8)],
            ),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withOpacity(0.38 * _glowAnim.value),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: Text('\u{1F319}', style: TextStyle(fontSize: 14)),
          ),
        ),
      ),
    );
  }

  Widget _userBubble(ChatMessage msg) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _shimmerAnim]),
      builder: (_, __) {
        // Shimmer travels left-to-right as a highlight edge
        final shimmerPos = _shimmerAnim.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(5),
            ),
            gradient: LinearGradient(
              colors: const [Color(0xFF8B2DB8), Color(0xFFAB5CF2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withOpacity(0.42 * _glowAnim.value),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
              // Shimmer edge glow
              BoxShadow(
                color: _kPink.withOpacity(
                    0.22 * math.sin(shimmerPos * math.pi).clamp(0.0, 1.0)),
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, height: 1.55),
          ),
        );
      },
    );
  }

  Widget _aiBubble(ChatMessage msg, {bool isLatest = false}) {
    // Emotion-reactive accent color — each emotion feels different
    final Color emotionAccent = switch (msg.emotionTag) {
      EmotionTag.anxious => const Color(0xFF4FC3F7), // calming teal
      EmotionTag.sad => const Color(0xFF7986CB), // soft indigo
      EmotionTag.lonely => const Color(0xFFAB5CF2), // gentle violet
      EmotionTag.stressed => const Color(0xFF7986CB), // grounding indigo
      EmotionTag.happy => const Color(0xFFFFD700), // warm gold
      EmotionTag.energetic => const Color(0xFF66BB6A), // fresh green
      EmotionTag.tired => const Color(0xFF9C27B0), // deep lavender
      EmotionTag.emotional => const Color(0xFFFF69B4), // warm pink
      EmotionTag.period => const Color(0xFFB05C8A), // soft rose
      _ => _kPurple, // default lunar
    };

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showShareCard(context, msg, emotionAccent);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowAnim, _auraCtrl]),
        builder: (_, __) {
          final glowIntensity = _glowAnim.value;
          final rotation = _auraCtrl.value;
          // Latest AI message gets extra breathing presence glow
          final presenceGlow = isLatest ? glowIntensity * 0.18 : 0.0;
          return Stack(
            children: [
              // Breathing presence aura beneath the latest message
              if (isLatest)
                Positioned(
                  left: -6,
                  right: -6,
                  top: -6,
                  bottom: -6,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(11),
                        topRight: Radius.circular(28),
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: emotionAccent.withOpacity(presenceGlow),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: _kPurple.withOpacity(presenceGlow * 0.5),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              // Rotating gradient glow border layer — tinted to emotion
              Positioned.fill(
                child: CustomPaint(
                  painter: _AiGlowBorderPainter(
                    rotation: rotation,
                    intensity: glowIntensity,
                    accentColor: emotionAccent,
                  ),
                ),
              ),
              // Bubble content
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(22),
                        bottomLeft: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          emotionAccent.withOpacity(isLatest ? 0.16 : 0.12),
                          Colors.white.withOpacity(0.05),
                          _kPurple.withOpacity(0.08),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              emotionAccent.withOpacity(0.16 * glowIntensity),
                          blurRadius: 22,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.90),
                            fontSize: 15,
                            height: 1.65,
                          ),
                        ),
                        if (msg.emotionTag != null &&
                            msg.emotionTag != EmotionTag.neutral) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: emotionAccent.withOpacity(0.18),
                                  border: Border.all(
                                      color: emotionAccent.withOpacity(0.28),
                                      width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_emotionEmoji(msg.emotionTag!),
                                        style: const TextStyle(fontSize: 9)),
                                    const SizedBox(width: 3),
                                    Text(
                                      _emotionLabel(msg.emotionTag!),
                                      style: TextStyle(
                                        color: emotionAccent.withOpacity(0.72),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Single-fire shimmer reveal sweep
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                builder: (_, t, __) {
                  if (t >= 0.98) return const SizedBox.shrink();
                  final pos = Curves.easeInOut.transform(t);
                  return Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(22),
                        bottomLeft: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                      ),
                      child: Opacity(
                        opacity: (1.0 - t) * 0.70,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(pos * 3.0 - 2.0, -0.5),
                              end: Alignment(pos * 3.0 - 0.8, 0.5),
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.22),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Shareable emotional card modal ─────────────────────────
  void _showShareCard(BuildContext ctx, ChatMessage msg, Color accent) {
    showDialog(
      context: ctx,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => _ShareCardDialog(message: msg, accentColor: accent),
    );
  }

  // -- Healing card --------------------------------------------
  Widget _buildHealingCard(ChatMessage msg, Size size) {
    final data = _kCards[msg.healing] ?? _kCards[HealingKind.gentle]!;
    final col = data.color;

    return Padding(
      padding: EdgeInsets.only(bottom: 14, left: 38, right: size.width * 0.05),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [col.withOpacity(0.22), col.withOpacity(0.07)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: col.withOpacity(0.48 * _glowAnim.value),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: col.withOpacity(0.20 * _glowAnim.value),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(data.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        data.title,
                        style: TextStyle(
                          color: col,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.body,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -- Date separator helpers ----------------------------------
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _dateSeparator(DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      label = '${months[date.month - 1]} ${date.day}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
              child: Divider(color: Colors.white.withOpacity(0.07), height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.38),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Expanded(
              child: Divider(color: Colors.white.withOpacity(0.07), height: 1)),
        ],
      ),
    );
  }

  // -- Emotion label helpers ------------------------------------
  String _emotionEmoji(EmotionTag tag) => switch (tag) {
        EmotionTag.anxious => '💙',
        EmotionTag.sad => '💜',
        EmotionTag.lonely => '🌙',
        EmotionTag.stressed => '🌿',
        EmotionTag.happy => '✨',
        EmotionTag.energetic => '⚡',
        EmotionTag.tired => '💤',
        EmotionTag.emotional => '🌸',
        EmotionTag.period => '🩸',
        _ => '💫',
      };

  String _emotionLabel(EmotionTag tag) => switch (tag) {
        EmotionTag.anxious => 'Anxiety',
        EmotionTag.sad => 'Sadness',
        EmotionTag.lonely => 'Loneliness',
        EmotionTag.stressed => 'Stress',
        EmotionTag.happy => 'Joy',
        EmotionTag.energetic => 'Energy',
        EmotionTag.tired => 'Fatigue',
        EmotionTag.emotional => 'Emotional',
        EmotionTag.period => 'Period',
        _ => 'Present',
      };

  // -- Premium voice recording panel ---------------------------
  Widget _voiceRecordingPanel() {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveCtrl, _glowAnim, _shimmerAnim]),
      builder: (_, __) {
        final pulse = (0.4 + 0.5 * math.sin(_shimmerAnim.value * math.pi * 2))
            .clamp(0.0, 1.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    _kPink.withOpacity(0.13),
                    _kPurple.withOpacity(0.09),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _kPink.withOpacity(0.38 * _glowAnim.value),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPink.withOpacity(0.14 * _glowAnim.value),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status row
                  Row(
                    children: [
                      // Live recording dot
                      AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, __) => Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kPink,
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      _kPink.withOpacity(0.7 * _glowAnim.value),
                                  blurRadius: 8,
                                  spreadRadius: 2),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Listening to you...',
                        style: TextStyle(
                          color: _kPink.withOpacity(0.85),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _stopListening,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: _kPink.withOpacity(0.16),
                            border: Border.all(
                                color: _kPink.withOpacity(0.38), width: 0.8),
                          ),
                          child: Text(
                            'Done ✓',
                            style: TextStyle(
                              color: _kPink.withOpacity(0.90),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Premium waveform — 20 bars
                  SizedBox(
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(20, (i) {
                        final phase = i / 20;
                        final t = (_waveCtrl.value + phase) % 1.0;
                        final h = 4.0 + 30.0 * math.sin(t * math.pi).abs();
                        return Container(
                          width: 3,
                          height: h,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                _kPink.withOpacity(0.55),
                                _kPurple,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kPink.withOpacity(0.32),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  if (_voiceText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '"$_voiceText"',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60 + 0.28 * pulse),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.45,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // -- Typing indicator — Lunar presence feel ----------------
  Widget _typingBubble() {
    final chat = context.read<ChatProvider>();
    final dominantEmotion = chat.emotionalProfile.dominantEmotion;
    // Emotionally contextual presence text — feels like Lunar is genuinely thinking
    final thinkingPhrases = switch (dominantEmotion) {
      EmotionTag.anxious => [
          'Sending calming energy your way... 🌬️',
          'I\'m here. Breathing with you... 💜',
          'Holding you gently right now... 🌙',
        ],
      EmotionTag.sad => [
          'Holding space for you... 🌙',
          'I feel this with you... 💜',
          'Taking a moment to be fully present... 🌸',
        ],
      EmotionTag.stressed => [
          'Finding the gentlest words... 💜',
          'Taking a breath before I respond... 🌿',
          'I want to get this right for you... 🌙',
        ],
      EmotionTag.tired => [
          'Speaking softly, just for you... 😴',
          'Keeping this quiet and gentle... 🌙',
          'I know you\'re tired. I\'m here... 💜',
        ],
      EmotionTag.happy => [
          'Celebrating with you... ✨',
          'Your joy is contagious... 🌟',
          'This made me smile too... 🌸',
        ],
      EmotionTag.period => [
          'Sending warmth and care... 🌸',
          'I feel you. I\'m right here... 💜',
          'Holding you extra gently tonight... 🌙',
        ],
      EmotionTag.lonely => [
          'I\'m here with you... 🌙',
          'You are not alone right now... 💜',
          'Reaching for you across the quiet... 🌸',
        ],
      _ => [
          'Lunar is with you... 🌙',
          'I\'m here, fully present... 💜',
          'Taking this in before I respond... ✨',
        ],
    };

    // Cycle through phrases based on time for variety
    final phrase = thinkingPhrases[
        (DateTime.now().millisecond ~/ 333) % thinkingPhrases.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _miniMoonAvatar(),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: Listenable.merge([_glowAnim, _typingCtrl]),
            builder: (_, __) {
              final glow = _glowAnim.value;
              return ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _kPurple.withOpacity(0.14),
                          _kPink.withOpacity(0.06),
                          Colors.white.withOpacity(0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                          color: _kPink.withOpacity(0.28 * glow), width: 1.1),
                      boxShadow: [
                        BoxShadow(
                          color: _kPurple.withOpacity(0.18 * glow),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Breathing dot trio
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) {
                            return AnimatedBuilder(
                              animation: _typingCtrl,
                              builder: (_, __) {
                                final t = (_typingCtrl.value + i * 0.25) % 1.0;
                                final bounce = math.sin(t * math.pi) * -9.0;
                                final opacity =
                                    (0.45 + 0.55 * math.sin(t * math.pi))
                                        .clamp(0.0, 1.0);
                                return Opacity(
                                  opacity: opacity,
                                  child: Transform.translate(
                                    offset: Offset(0, bounce),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(colors: [
                                          _kPink,
                                          _kPurple.withOpacity(0.60),
                                        ]),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _kPink.withOpacity(0.65),
                                            blurRadius: 7,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 7),
                        // Shimmering presence text
                        AnimatedBuilder(
                          animation: _shimmerAnim,
                          builder: (_, __) {
                            final shimmer = (0.40 +
                                    0.50 *
                                        math.sin(
                                            _shimmerAnim.value * math.pi * 2))
                                .clamp(0.0, 1.0);
                            return Text(
                              phrase,
                              style: TextStyle(
                                color: _kPurple.withOpacity(shimmer),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  QUICK ACTIONS
  // ===========================================================
  Widget _quickActions(ChatProvider chat) {
    final lunarData = context.watch<LunarDataProvider>();
    final phase = lunarData.currentPhase;

    final List<(String, String)> actions = [
      if (phase == LunarCyclePhase.period) ('\u{1FA78}', 'Period support'),
      if (phase == LunarCyclePhase.luteal) ('\u{1F319}', 'I feel emotional'),
      if (phase == LunarCyclePhase.ovulation) ('\u2728', 'I feel amazing'),
      if (phase == LunarCyclePhase.follicular)
        ('\u{1F331}', 'I feel energetic'),
      if (lunarData.isPregnant) ('\u{1F930}', 'Pregnancy support'),
      ('\u{1F630}', 'I feel anxious'),
      ('\u{1F49C}', 'I need support'),
      ('\u{1F33F}', 'Help me calm down'),
      ('\u{1F327}\u{FE0F}', 'I\'m feeling sad'),
      ('\u{1F32C}\u{FE0F}', 'Breathe with me'),
      ('\u{1F634}', 'I\'m so tired'),
      ('\u{1F4A7}', 'Drink water reminder'),
    ];

    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (_, i) {
          final (emoji, label) = actions[i];
          final isHighlighted = i == 0 &&
              (phase == LunarCyclePhase.period ||
                  phase == LunarCyclePhase.luteal ||
                  phase == LunarCyclePhase.ovulation ||
                  phase == LunarCyclePhase.follicular ||
                  lunarData.isPregnant);
          return GestureDetector(
            onTapDown: (_) => setState(() => _tappedChipIdx = i),
            onTapUp: (_) {
              chat.sendQuickAction('$emoji $label', context);
              Future.delayed(const Duration(milliseconds: 320), () {
                if (mounted) setState(() => _tappedChipIdx = -1);
              });
            },
            onTapCancel: () => setState(() => _tappedChipIdx = -1),
            child: AnimatedBuilder(
              animation: Listenable.merge([_glowAnim, _floatCtrl]),
              builder: (_, __) {
                final isTapped = _tappedChipIdx == i;
                return Transform.translate(
                  offset: Offset(
                      0, _floatAnim.value * 0.18 * (i % 2 == 0 ? 1.0 : -1.0)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(23),
                      color: isHighlighted || isTapped
                          ? _kPurple.withOpacity(0.22)
                          : Colors.white.withOpacity(0.07),
                      border: Border.all(
                        color: isTapped
                            ? _kPink.withOpacity(0.75)
                            : isHighlighted
                                ? _kPurple.withOpacity(0.50 * _glowAnim.value)
                                : _kPurple.withOpacity(0.25 * _glowAnim.value),
                      ),
                      boxShadow: isTapped
                          ? [
                              BoxShadow(
                                color: _kPink.withOpacity(0.40),
                                blurRadius: 16,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: TextStyle(
                            color: isHighlighted || isTapped
                                ? Colors.white.withOpacity(0.92)
                                : Colors.white.withOpacity(0.72),
                            fontSize: 12.5,
                            fontWeight: isHighlighted || isTapped
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ===========================================================
  //  INPUT BAR  (premium upgrade)
  // ===========================================================
  Widget _inputBar(ChatProvider chat) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pending media preview strip
        if (_pendingMedia != null) _pendingMediaStrip(),

        // Media options expansion row
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child:
              _showMediaOptions ? _mediaOptionsRow() : const SizedBox.shrink(),
        ),

        // Voice recording panel — premium immersive state
        if (_isRecording) _voiceRecordingPanel(),

        // Input row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: AnimatedBuilder(
            animation: Listenable.merge([_glowAnim, _focusAnim]),
            builder: (_, __) {
              final baseOpacity = 0.30 * _glowAnim.value;
              final focusExtra = 0.55 * _focusAnim.value;
              final borderColor = _kPurple
                  .withOpacity((baseOpacity + focusExtra).clamp(0.0, 1.0));
              final blurRadius = 12.0 + 14.0 * _focusAnim.value;
              return ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(color: borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: _kPurple.withOpacity(
                              0.10 * _glowAnim.value + 0.22 * _focusAnim.value),
                          blurRadius: blurRadius,
                          spreadRadius: _isFocused ? 1 : 0,
                        ),
                        if (_isFocused)
                          BoxShadow(
                            color: _kPink.withOpacity(0.10 * _focusAnim.value),
                            blurRadius: 20,
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // ── + Media FAB ───────────────────────
                        _mediaFabButton(),
                        const SizedBox(width: 4),
                        // ── Text field ───────────────────────
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            focusNode: _focusNode,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.90),
                              fontSize: 15,
                            ),
                            cursorColor: _kPurple,
                            maxLines: 4,
                            minLines: 1,
                            textInputAction: TextInputAction.newline,
                            onSubmitted: _send,
                            enabled: !chat.isTyping,
                            decoration: InputDecoration(
                              hintText: chat.isTyping
                                  ? 'Lunar is thinking... 🌙'
                                  : _isRecording
                                      ? 'Listening... 🎙️'
                                      : 'Share your heart... 🌙',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.26),
                                fontSize: 14.5,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // ── Voice mic ────────────────────────
                        _voiceMicButton(),
                        const SizedBox(width: 4),
                        // ── Send button ──────────────────────
                        _sendButton(),
                        const SizedBox(width: 2),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _mediaFabButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _showMediaOptions = !_showMediaOptions);
        if (_showMediaOptions) {
          _mediaFabCtrl.forward();
        } else {
          _mediaFabCtrl.reverse();
        }
        // Dismiss focus so keyboard doesn't clash
        _focusNode.unfocus();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowAnim, _mediaFabAnim]),
        builder: (_, __) => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _showMediaOptions
                ? _kPurple.withOpacity(0.35)
                : Colors.white.withOpacity(0.08),
            border: Border.all(
              color: _kPurple.withOpacity(
                  _showMediaOptions ? 0.75 : 0.30 * _glowAnim.value),
              width: 1.2,
            ),
            boxShadow: _showMediaOptions
                ? [
                    BoxShadow(
                      color: _kPurple.withOpacity(0.38),
                      blurRadius: 14,
                    )
                  ]
                : null,
          ),
          child: AnimatedRotation(
            turns: _showMediaOptions ? 0.125 : 0,
            duration: const Duration(milliseconds: 280),
            child: Icon(
              Icons.add_rounded,
              color: _showMediaOptions
                  ? Colors.white
                  : Colors.white.withOpacity(0.60),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _voiceMicButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startListening(),
      onLongPressEnd: (_) => _stopListening(),
      onTap: () {
        // Tap: toggle recording for STT-available devices
        if (_isRecording) {
          _stopListening();
        } else {
          _startListening();
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveCtrl, _glowAnim]),
        builder: (_, __) => SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isRecording)
                ...List.generate(3, (i) {
                  final t = (_waveCtrl.value - i * 0.28).clamp(0.0, 1.0);
                  return Transform.scale(
                    scale: 1.0 + t * 1.5,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kPink.withOpacity((1 - t) * 0.28),
                      ),
                    ),
                  );
                }),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors:
                        _isRecording ? [_kPink, _kPurple] : [_kDeep, _kPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? _kPink : _kPurple).withOpacity(
                          _isRecording ? 0.70 : 0.38 * _glowAnim.value),
                      blurRadius: _isRecording ? 20 : 10,
                      spreadRadius: _isRecording ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sendButton() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _textCtrl,
      builder: (_, value, __) {
        final hasContent =
            value.text.trim().isNotEmpty || _pendingMedia != null;
        return GestureDetector(
          onTap: () {
            if (_pendingMedia != null) {
              _sendWithPendingMedia();
            } else {
              _send(_textCtrl.text);
            }
          },
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              width: hasContent ? 48 : 42,
              height: hasContent ? 48 : 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: hasContent
                      ? [_kPurple, _kPink]
                      : [
                          _kPurple.withOpacity(0.72),
                          _kPink.withOpacity(0.72),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPurple.withOpacity(hasContent
                        ? 0.62 * _glowAnim.value
                        : 0.38 * _glowAnim.value),
                    blurRadius: hasContent ? 22 : 14,
                    spreadRadius: hasContent ? 2 : 0,
                  ),
                  if (hasContent)
                    BoxShadow(
                      color: _kPink.withOpacity(0.22 * _glowAnim.value),
                      blurRadius: 14,
                    ),
                ],
              ),
              child: Icon(
                _pendingMedia != null
                    ? Icons.send_rounded
                    : Icons.arrow_upward_rounded,
                color: Colors.white,
                size: hasContent ? 22 : 20,
              ),
            ),
          ),
        );
      },
    );
  }

  // -- Media options expansion row ----------------------------
  Widget _mediaOptionsRow() {
    final options = [
      (
        Icons.photo_library_rounded,
        'Gallery',
        _kPurple,
        () => _pickImage(ImageSource.gallery)
      ),
      (
        Icons.camera_alt_rounded,
        'Camera',
        _kPink,
        () => _pickImage(ImageSource.camera)
      ),
      (Icons.videocam_rounded, 'Video', const Color(0xFF7986CB), _pickVideo),
      (
        Icons.description_rounded,
        'File',
        const Color(0xFF4FC3F7),
        () async {
          // Document picker — show a soft message (full doc picker needs another package)
          setState(() => _showMediaOptions = false);
          _mediaFabCtrl.reverse();
        }
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: options.map((o) {
          final (icon, label, color, onTap) = o;
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedBuilder(
                animation: _mediaFabAnim,
                builder: (_, __) => Transform.scale(
                  scale: 0.6 + 0.4 * _mediaFabAnim.value,
                  child: Opacity(
                    opacity: _mediaFabAnim.value.clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.28),
                                color.withOpacity(0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                                color: color.withOpacity(0.55), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                  color: color.withOpacity(0.20),
                                  blurRadius: 12),
                            ],
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // -- Pending media preview strip ----------------------------
  Widget _pendingMediaStrip() {
    final media = _pendingMedia!;
    final type = _pendingMediaType!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _kDeep.withOpacity(0.55),
        border: Border.all(color: _kPurple.withOpacity(0.45), width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: type == MediaType.image
                ? Image.file(
                    File(media.path),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _pendingMediaIcon(type),
                  )
                : _pendingMediaIcon(type),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == MediaType.image
                      ? '📷 Image ready to send'
                      : type == MediaType.video
                          ? '🎬 Video ready to send'
                          : '📎 File ready to send',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  media.name,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.50), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearPendingMedia,
            child: Icon(Icons.close_rounded,
                color: Colors.white.withOpacity(0.45), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _pendingMediaIcon(MediaType type) {
    return Container(
      width: 48,
      height: 48,
      color: _kPurple.withOpacity(0.25),
      child: Icon(
        type == MediaType.video
            ? Icons.videocam_rounded
            : Icons.description_rounded,
        color: _kPurple,
        size: 22,
      ),
    );
  }

  // ===========================================================
  //  SANCTUARY SCAFFOLD
  // ===========================================================
  Widget _buildSanctuary(
      ChatProvider chat, LunarDataProvider lunarData, Size size) {
    return Scaffold(
      backgroundColor: _kBg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _AIBg(size: size),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _AIStarPainter(
                    stars: _stars, progress: _particleCtrl.value),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _sanctuaryHeader(lunarData),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _heroOrb(chat, lunarData, size),
                        const SizedBox(height: 22),
                        _emotionalStatusDisplay(chat, lunarData),
                        const SizedBox(height: 24),
                        _emotionalEnergyBar(lunarData),
                        const SizedBox(height: 24),
                        _memoryInsightCard(chat, lunarData),
                        const SizedBox(height: 24),
                        _sanctuaryHealingCards(chat),
                        const SizedBox(height: 24),
                        _sanctuaryAffirmation(lunarData),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _talkToLunarBtn(size),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  SANCTUARY HEADER
  // ===========================================================
  Widget _sanctuaryHeader(LunarDataProvider lunarData) {
    final phase = lunarData.currentPhase;
    final cfg = _kPhaseConfig[phase];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lunar AI \u2728',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                _sanctuarySubtitle(),
                style: TextStyle(
                    color: Colors.white.withOpacity(0.48), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          if (cfg != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (cfg['color'] as Color).withOpacity(0.14),
                border: Border.all(
                    color: (cfg['color'] as Color).withOpacity(0.34)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cfg['emoji'] as String,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    cfg['label'] as String,
                    style: TextStyle(
                      color: cfg['color'] as Color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _inSanctuary = false);
            },
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.07),
                border: Border.all(color: _kPurple.withOpacity(0.28)),
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: _kPurple.withOpacity(0.78), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  HERO ORB
  // ===========================================================

  /// Returns an emotion-aware accent color for the orb.
  Color _getEmotionOrbAccent(EmotionTag? tag) => switch (tag) {
        EmotionTag.anxious => const Color(0xFF4FC3F7), // calming blue-teal
        EmotionTag.sad => const Color(0xFF7986CB), // deep indigo
        EmotionTag.stressed => const Color(0xFF9575CD), // muted violet
        EmotionTag.lonely => const Color(0xFFB39DDB), // soft lavender
        EmotionTag.tired => const Color(0xFF78909C), // grey-blue
        EmotionTag.happy => const Color(0xFFFFD700), // warm gold
        EmotionTag.energetic => _kPink, // vibrant pink
        EmotionTag.period => const Color(0xFFB05C8A), // warm rose
        EmotionTag.emotional => const Color(0xFFCE93D8), // soft lilac
        _ => _kPurple,
      };

  Widget _heroOrb(ChatProvider chat, LunarDataProvider lunarData, Size size) {
    final phase = lunarData.currentPhase;
    final cfg = _kPhaseConfig[phase];
    // Blend phase colour with emotional accent for living, reactive orb
    final phaseColor = cfg != null ? cfg['color'] as Color : _kPurple;
    final emotionAccent = _getEmotionOrbAccent(chat.dominantEmotion);
    final orbColor = Color.lerp(phaseColor, emotionAccent, 0.30)!;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation:
            Listenable.merge([_pulseCtrl, _glowCtrl, _floatCtrl, _auraCtrl]),
        builder: (_, child) {
          final float = _floatAnim.value;
          final pulse = _pulseAnim.value;
          final glow = _glowAnim.value;
          final auraProgress = _auraCtrl.value;
          return Transform.translate(
            offset: Offset(0, float * 0.65),
            child: Transform.scale(
              scale: pulse,
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(3, (i) {
                      final pv = (auraProgress * 1.8 + i * 0.33) % 1.0;
                      return Opacity(
                        opacity: (1 - pv) * 0.20 * glow,
                        child: Container(
                          width: 140 + pv * 78,
                          height: 140 + pv * 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: orbColor, width: 1.2),
                          ),
                        ),
                      );
                    }),
                    CustomPaint(
                      size: const Size(220, 220),
                      painter: _OrbAuraPainter(
                        progress: auraProgress,
                        color: orbColor,
                        glowIntensity: glow,
                        isActive: chat.isTyping,
                      ),
                    ),
                    Container(
                      width: 136,
                      height: 136,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.26),
                            orbColor.withOpacity(0.84),
                            _kDeep,
                            const Color(0xFF0D0130),
                          ],
                          stops: const [0.0, 0.35, 0.70, 1.0],
                          center: const Alignment(-0.25, -0.30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: orbColor.withOpacity(
                                chat.isTyping ? 0.82 * glow : 0.58 * glow),
                            blurRadius: chat.isTyping ? 38 : 26,
                            spreadRadius: chat.isTyping ? 6 : 4,
                          ),
                          BoxShadow(
                              color: _kPink.withOpacity(0.26 * glow),
                              blurRadius: 28,
                              spreadRadius: 2),
                          BoxShadow(
                              color: Colors.black.withOpacity(0.50),
                              blurRadius: 20,
                              offset: const Offset(0, 8)),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18 * glow),
                          width: 1.5,
                        ),
                      ),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\ud83c\udf19', style: TextStyle(fontSize: 46)),
            const SizedBox(height: 4),
            Text(
              'Lunar AI',
              style: TextStyle(
                color: Colors.white.withOpacity(0.86),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  //  EMOTIONAL STATUS DISPLAY
  // ===========================================================
  Widget _emotionalStatusDisplay(
      ChatProvider chat, LunarDataProvider lunarData) {
    final app = context.read<AppProvider>();
    // On first view (_insightIdx==0), show personalised greeting if emotional history exists.
    // After that, rotate through standard insights.
    final profile = chat.emotionalProfile;
    final hasMemory = profile.dominantEmotion != null ||
        profile.daysSinceLastVisit >= 2 ||
        profile.anxietyMentions >= 2 ||
        profile.stressMentions >= 2;
    String displayText;
    if (chat.isTyping) {
      displayText = 'Feeling your energy... \u2728';
    } else if (_insightIdx == 0 && hasMemory) {
      // First rotation: show personalised greeting (single line from full greeting)
      displayText =
          chat.generateGreeting(app.userName).split('\n\n').last.trim();
    } else {
      displayText = _kInsights[_insightIdx % _kInsights.length];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 650),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.30),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        child: Text(
          displayText,
          key: ValueKey(chat.isTyping ? 'typing' : displayText),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.76),
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
            height: 1.52,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  // ===========================================================
  //  LUNAR REMEMBERS BANNER  (chat view — between phase and input)
  // ===========================================================
  Widget _lunarRemembersBanner(BuildContext context) {
    final memProvider = context.watch<MemoryProvider>();
    if (!memProvider.hasMemories) return const SizedBox.shrink();

    final top = memProvider.topMemories(limit: 3);
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: GestureDetector(
              onTap: () => _showMemorySheet(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      _kPurple.withOpacity(0.10),
                      _kPink.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: _kPurple.withOpacity(0.22 * _glowAnim.value),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  children: [
                    Text('🌙', style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lunar Remembers',
                            style: TextStyle(
                              color: _kPurple.withOpacity(0.85),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: top.map((m) => _memoryChip(m)).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _kPurple.withOpacity(0.45),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _memoryChip(DeepMemory memory) {
    return GestureDetector(
      onLongPress: () => _showMemoryDeleteDialog(memory),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _kPurple.withOpacity(0.13),
          border: Border.all(
            color: _kPurple.withOpacity(0.22),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(memory.category.emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(
              memory.timeAgoLabel,
              style: TextStyle(
                color: Colors.white.withOpacity(0.58),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  //  MEMORY SHEET  (full memory management bottom sheet)
  // ===========================================================
  void _showMemorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MemorySheet(
        onDeleteMemory: (id) {
          context.read<MemoryProvider>().deleteMemory(id);
        },
        onResolveMemory: (id) {
          context.read<MemoryProvider>().markResolved(id);
        },
        onClearAll: () {
          context.read<MemoryProvider>().clearAll();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showMemoryDeleteDialog(DeepMemory memory) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF160330),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${memory.category.emoji} ${memory.category.label}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              memory.summary,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75), fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              memory.timeAgoLabel,
              style:
                  TextStyle(color: _kPurple.withOpacity(0.65), fontSize: 11.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep',
                style: TextStyle(color: Colors.white.withOpacity(0.55))),
          ),
          TextButton(
            onPressed: () {
              context.read<MemoryProvider>().markResolved(memory.id);
              Navigator.pop(context);
            },
            child: Text('Mark healed ✨',
                style: TextStyle(color: _kPurple.withOpacity(0.80))),
          ),
          TextButton(
            onPressed: () {
              context.read<MemoryProvider>().deleteMemory(memory.id);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  AI MEMORY INSIGHT CARD
  // ===========================================================
  Widget _memoryInsightCard(ChatProvider chat, LunarDataProvider lunarData) {
    // Use MemoryProvider insight if available, else fall back to session-based
    final memProvider = context.watch<MemoryProvider>();
    final insight =
        memProvider.memoryInsight ?? _getMemoryInsight(chat, lunarData);
    return GestureDetector(
      onTap: memProvider.hasMemories ? () => _showMemorySheet(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      _kPurple.withOpacity(0.13),
                      _kPink.withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: _kPurple.withOpacity(0.26 * _glowAnim.value),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kPurple.withOpacity(0.18),
                      ),
                      child: const Center(
                        child: Text('💭', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lunar Remembers 🌙',
                            style: TextStyle(
                              color: _kPurple.withOpacity(0.78),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            insight,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.70),
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                          if (memProvider.hasMemories) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${memProvider.memoryCount} memories · tap to view',
                              style: TextStyle(
                                color: _kPurple.withOpacity(0.55),
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (memProvider.hasMemories)
                      Icon(Icons.chevron_right_rounded,
                          color: _kPurple.withOpacity(0.40), size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Short personalized subtitle for the sanctuary header.
  String _sanctuarySubtitle() {
    final chat = context.read<ChatProvider>();
    final days = chat.emotionalProfile.daysSinceLastVisit;
    if (days >= 3) return 'Welcome back \u2014 I\'ve been here \ud83c\udf19';
    return switch (chat.dominantEmotion) {
      EmotionTag.anxious => 'You\'re safe here \ud83c\udf19',
      EmotionTag.sad => 'Holding space for you \ud83c\udf38',
      EmotionTag.stressed => 'No rush, no pressure here \ud83c\udf19',
      EmotionTag.lonely => 'You\'re never alone here \ud83d\udc9c',
      EmotionTag.tired => 'Rest deeply here \ud83c\udf19',
      EmotionTag.happy ||
      EmotionTag.energetic =>
        'Your light is beautiful \u2728',
      EmotionTag.period => 'Be gentle with yourself today \ud83c\udf38',
      _ => 'Your emotional sanctuary',
    };
  }

  String _getMemoryInsight(ChatProvider chat, LunarDataProvider lunarData) {
    final profile = chat.emotionalProfile;
    final days = profile.daysSinceLastVisit;
    final phase = lunarData.currentPhase;
    final day = lunarData.currentCycleDay;

    // Cross-session persistent memory — most emotionally impactful
    if (days >= 5) {
      return "I\'ve been holding space for you \u2014 it\'s been $days days \ud83c\udf19";
    }
    if (days >= 2) {
      return "I\'ve been thinking of you these past few days \ud83c\udf38";
    }
    if (profile.anxietyMentions >= 2) {
      return "You\'ve been carrying some anxiety lately \u2014 that takes courage \ud83d\udc9c";
    }
    if (profile.stressMentions >= 2) {
      return "You\'ve been carrying a lot lately. Your nervous system needs care \u2728";
    }
    if (profile.sleepMentions >= 2) {
      return "You\'ve mentioned tiredness a few times \u2014 rest is sacred medicine \ud83c\udf19";
    }
    if (profile.periodMentions >= 1) {
      return "Your cycle deserves the most gentle care right now \ud83e\ude78";
    }
    if (profile.hasPositiveStreak) {
      return "Your emotional light has been so beautiful lately \u2728";
    }

    // Session-based memory
    final msgs = chat.sessionMessageCount;
    if (msgs > 5) {
      return switch (chat.dominantEmotion) {
        EmotionTag.anxious =>
          "You\'ve shared anxiety today \u2014 that takes courage \ud83d\udc9c",
        EmotionTag.sad =>
          "You\'ve been carrying heaviness. I see you \ud83c\udf19",
        EmotionTag.stressed =>
          "You\'ve been under a lot. Your nervous system needs care \u2728",
        EmotionTag.lonely =>
          "You haven\'t been alone in this \u2014 I\'ve been listening \ud83c\udf38",
        EmotionTag.tired =>
          "You\'ve been exhausted. Rest is medicine \ud83d\udca4",
        _ => "You\'ve been beautifully open with me today \ud83c\udf38",
      };
    }

    // Phase & pregnancy based
    if (lunarData.isPregnant) {
      return 'Your body is creating life. Every emotion is sacred \ud83e\udd30';
    }
    if (phase == LunarCyclePhase.period && day > 0) {
      return 'Day $day of your cycle \u2014 rest is sacred right now \ud83e\ude78';
    }
    if (phase == LunarCyclePhase.luteal) {
      return "Your luteal phase amplifies emotions. That\'s your body\'s wisdom \ud83c\udf19";
    }
    if (phase == LunarCyclePhase.ovulation) {
      return 'You\'re in your peak phase \u2014 you radiate energy right now \u2728';
    }
    return 'Your emotional journey is being honoured here \ud83d\udc9c';
  }

  // ===========================================================
  //  EMOTIONAL ENERGY BAR
  // ===========================================================
  Widget _emotionalEnergyBar(LunarDataProvider lunarData) {
    final phase = lunarData.currentPhase;
    final int activeIdx;
    if (lunarData.isPregnant) {
      activeIdx = 1;
    } else {
      activeIdx = switch (phase) {
        LunarCyclePhase.ovulation => 3,
        LunarCyclePhase.follicular => 1,
        LunarCyclePhase.period => 2,
        LunarCyclePhase.luteal => 0,
        _ => 1,
      };
    }
    const energyStates = [
      ('\ud83c\udf0a', 'Calm', Color(0xFF4FC3F7)),
      ('\ud83d\udcab', 'Balanced', Color(0xFF66BB6A)),
      ('\ud83c\udf19', 'Sensitive', Color(0xFF7986CB)),
      ('\u26a1', 'High\nEnergy', Color(0xFFFFD700)),
      ('\ud83c\udf00', 'Over-\nwhelmed', Color(0xFFFF69B4)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emotional Energy',
            style: TextStyle(
              color: Colors.white.withOpacity(0.50),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(energyStates.length, (i) {
              final (emoji, label, color) = energyStates[i];
              final isActive = i == activeIdx;
              return AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      width: isActive ? 52 : 42,
                      height: isActive ? 52 : 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? color.withOpacity(0.20)
                            : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: isActive
                              ? color.withOpacity(0.62 * _glowAnim.value)
                              : Colors.white.withOpacity(0.10),
                          width: isActive ? 1.5 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color:
                                      color.withOpacity(0.40 * _glowAnim.value),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: TextStyle(fontSize: isActive ? 22 : 17)),
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 280),
                      style: TextStyle(
                        color:
                            isActive ? color : Colors.white.withOpacity(0.28),
                        fontSize: 9.5,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                        height: 1.3,
                      ),
                      child: Text(label, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  //  SANCTUARY HEALING CARDS
  // ===========================================================
  Widget _sanctuaryHealingCards(ChatProvider chat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 12),
          child: Text(
            'Healing Experiences',
            style: TextStyle(
              color: Colors.white.withOpacity(0.50),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 108,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _kSanctuaryActions.length,
            itemBuilder: (_, i) {
              final (emoji, label, color, prompt) = _kSanctuaryActions[i];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  chat.sendQuickAction(prompt, context);
                  setState(() => _inSanctuary = false);
                },
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.17),
                          color.withOpacity(0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: color.withOpacity(0.36 * _glowAnim.value),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.12), blurRadius: 12),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================
  //  SANCTUARY AFFIRMATION
  // ===========================================================
  Widget _sanctuaryAffirmation(LunarDataProvider lunarData) {
    final h = DateTime.now().hour;
    final affirmation = h < 12
        ? '\u201cYou wake with the moon\'s grace.\nToday is entirely yours. \ud83c\udf19\u201d'
        : h < 18
            ? '\u201cYour sensitivity is your superpower.\nFeel it all, beautifully. \ud83d\udc9c\u201d'
            : '\u201cRest, beautiful soul.\nThe stars hold you tonight. \u2728\u201d';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    _kPink.withOpacity(0.11),
                    _kPurple.withOpacity(0.07),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _kPink.withOpacity(0.22 * _glowAnim.value),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '\ud83c\udf38 Today\'s Affirmation',
                    style: TextStyle(
                      color: _kPink.withOpacity(0.72),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    affirmation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.80),
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      height: 1.58,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  //  TALK TO LUNAR CTA BUTTON
  // ===========================================================
  Widget _talkToLunarBtn(Size size) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                _kBg.withOpacity(0.82),
                _kBg.withOpacity(0.97),
              ],
            ),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(context).padding.bottom + 18),
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _inSanctuary = false);
              },
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8E24AA),
                      Color(0xFFAB5CF2),
                      Color(0xFFE040FB),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          _kPurple.withOpacity(0.52 + 0.26 * _glowAnim.value),
                      blurRadius: 28,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: _kPink.withOpacity(0.18 * _glowAnim.value),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Talk to Lunar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================
//  AI GLOW BORDER PAINTER  — rotating gradient border
// ===========================================================

class _AiGlowBorderPainter extends CustomPainter {
  final double rotation; // 0.0 → 1.0, drives sweep startAngle
  final double intensity; // 0.0 → 1.0, drives opacity
  final Color accentColor; // emotion-reactive accent

  static const _br = 22.0; // border-radius value (matches bubble)

  const _AiGlowBorderPainter({
    required this.rotation,
    required this.intensity,
    this.accentColor = const Color(0xFFAB5CF2),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: const Radius.circular(5),
      topRight: const Radius.circular(_br),
      bottomLeft: const Radius.circular(_br),
      bottomRight: const Radius.circular(_br),
    );

    // ── Rotating sweep gradient border — emotion-aware ──────
    final angle = rotation * math.pi * 2;
    final sweepGrad = SweepGradient(
      startAngle: angle,
      endAngle: angle + math.pi * 2,
      colors: [
        Colors.transparent,
        accentColor.withOpacity(0.45),
        const Color(0xFFFF69B4),
        accentColor,
        const Color(0xFFD4AAFF),
        Colors.transparent,
        Colors.transparent,
      ],
      stops: const [0.0, 0.05, 0.22, 0.42, 0.62, 0.75, 1.0],
    );

    final glowPaint = Paint()
      ..shader =
          sweepGrad.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, (3.5 * intensity).clamp(0.5, 4.0));

    canvas.drawRRect(rrect, glowPaint);

    // ── Ambient outer halo — emotion-tinted ─────────────────
    final haloPaint = Paint()
      ..color = accentColor.withOpacity(0.12 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rrect, haloPaint);
  }

  @override
  bool shouldRepaint(_AiGlowBorderPainter old) =>
      old.rotation != rotation ||
      old.intensity != intensity ||
      old.accentColor != accentColor;
}

// ===========================================================
//  MESSAGE ENTRANCE ANIMATION
// ===========================================================

class _AnimatedMsg extends StatefulWidget {
  final Widget child;
  final bool isUser;

  const _AnimatedMsg({
    required this.child,
    required this.isUser,
    required super.key,
  });

  @override
  State<_AnimatedMsg> createState() => _AnimatedMsgState();
}

class _AnimatedMsgState extends State<_AnimatedMsg>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    _opacity = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.68, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: Offset(widget.isUser ? 0.16 : -0.16, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          alignment:
              widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: widget.child,
        ),
      ),
    );
  }
}

// ===========================================================
//  DREAMY BACKGROUND
// ===========================================================

class _AIBg extends StatelessWidget {
  final Size size;
  const _AIBg({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.35,
          colors: [
            Color(0xFF2D0B5C),
            Color(0xFF18063A),
            Color(0xFF0A0118),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -65,
            left: -50,
            child: _blob(300, const Color(0xFF9B59B6), 0.28),
          ),
          Positioned(
            top: 75,
            right: -65,
            child: _blob(255, const Color(0xFFE91E8C), 0.14),
          ),
          Positioned(
            top: size.height * 0.42,
            left: size.width * 0.45,
            child: _blob(265, const Color(0xFF7B2FF7), 0.12),
          ),
          Positioned(
            bottom: 55,
            left: -60,
            child: _blob(295, const Color(0xFF6C3FC8), 0.18),
          ),
          Positioned(
            bottom: 0,
            right: -40,
            child: _blob(245, const Color(0xFFFF69B4), 0.10),
          ),
          // Soft central nebula glow for depth
          Positioned(
            top: size.height * 0.25,
            left: size.width * 0.15,
            child: _blob(200, const Color(0xFFAB5CF2), 0.09),
          ),
          Positioned(
            top: size.height * 0.60,
            left: size.width * 0.30,
            child: _blob(180, const Color(0xFFFF69B4), 0.07),
          ),
          // Moon haze — upper center atmospheric glow
          Positioned(
            top: size.height * 0.05,
            left: size.width * 0.20,
            child: _blob(280, const Color(0xFFB39DDB), 0.07),
          ),
          // Horizon mist — lower screen warmth
          Positioned(
            bottom: size.height * 0.10,
            right: size.width * 0.05,
            child: _blob(220, const Color(0xFF7986CB), 0.06),
          ),
        ],
      ),
    );
  }

  Widget _blob(double s, Color c, double o) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [c.withOpacity(o), Colors.transparent],
          ),
        ),
      );
}

// ===========================================================
//  STAR PARTICLES
// ===========================================================

class _AIStar {
  late double x, y, speed, size, opacity, angle;

  _AIStar({required math.Random rng}) {
    reset(rng);
  }

  void reset(math.Random rng) {
    x = rng.nextDouble();
    y = rng.nextDouble();
    speed = 0.00015 + rng.nextDouble() * 0.00025;
    size = 0.8 + rng.nextDouble() * 2.0;
    opacity = 0.22 + rng.nextDouble() * 0.52;
    angle = rng.nextDouble() * math.pi * 2;
  }
}

class _AIStarPainter extends CustomPainter {
  final List<_AIStar> stars;
  final double progress;

  _AIStarPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final x = (s.x + math.cos(s.angle) * s.speed * progress * 120) % 1.0;
      final y = (s.y - s.speed * progress * 240) % 1.0;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        s.size,
        Paint()
          ..color = Colors.white.withOpacity(s.opacity * 0.68)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );

      if (s.size > 1.8) {
        final sp = Paint()
          ..color = const Color(0xFFAB5CF2).withOpacity(s.opacity * 0.38)
          ..strokeWidth = 0.55;
        final cx = x * size.width;
        final cy = y * size.height;
        canvas.drawLine(Offset(cx - 5, cy), Offset(cx + 5, cy), sp);
        canvas.drawLine(Offset(cx, cy - 5), Offset(cx, cy + 5), sp);
      }
    }
  }

  @override
  bool shouldRepaint(_AIStarPainter old) => old.progress != progress;
}

// ===========================================================
//  ORB AURA PAINTER
// ===========================================================
class _OrbAuraPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glowIntensity;
  final bool isActive;

  const _OrbAuraPainter({
    required this.progress,
    required this.color,
    required this.glowIntensity,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final boost = isActive ? 1.4 : 1.0;
    _drawSegmentedRing(canvas, cx, cy, 82, progress * math.pi * 2, color,
        0.38 * glowIntensity * boost, 6);
    _drawSegmentedRing(canvas, cx, cy, 98, -progress * math.pi * 1.4, _kPink,
        0.22 * glowIntensity * boost, 4);
  }

  void _drawSegmentedRing(Canvas canvas, double cx, double cy, double radius,
      double startAngle, Color col, double opacity, int segments) {
    final paint = Paint()
      ..color = col.withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final sweepAngle = (math.pi * 2 / segments) * 0.42;
    for (int i = 0; i < segments; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle + (i / segments) * math.pi * 2,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbAuraPainter old) =>
      old.progress != progress ||
      old.glowIntensity != glowIntensity ||
      old.isActive != isActive;
}

// ═══════════════════════════════════════════════════════════
//  SHAREABLE EMOTIONAL CARD — "Lunar understood me today"
//  Long-press any AI message to unlock this beautiful card.
// ═══════════════════════════════════════════════════════════
class _ShareCardDialog extends StatefulWidget {
  final ChatMessage message;
  final Color accentColor;
  const _ShareCardDialog({required this.message, required this.accentColor});

  @override
  State<_ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<_ShareCardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _shareText =>
      '"${widget.message.text}"\n\n— Lunar AI 🌙\nYour emotional wellness companion';

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Card ──────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0A0118),
                          accent.withOpacity(0.18),
                          const Color(0xFF1A0535),
                        ],
                      ),
                      border: Border.all(
                          color: accent.withOpacity(0.45), width: 1.5),
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                accent.withOpacity(0.7),
                                Colors.transparent,
                              ]),
                            ),
                            child: const Center(
                                child:
                                    Text('🌙', style: TextStyle(fontSize: 18))),
                          ),
                          const SizedBox(width: 10),
                          Text('Lunar',
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text(
                            _todayLabel(),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 11),
                          ),
                        ]),
                        const SizedBox(height: 20),
                        // Quote
                        Text(
                          '"${widget.message.text}"',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 15,
                            height: 1.65,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Divider(color: accent.withOpacity(0.20)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Text('Lunar AI  🌙',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.40),
                                  fontSize: 11.5)),
                          const Spacer(),
                          Text('Your emotional wellness companion',
                              style: TextStyle(
                                  color: accent.withOpacity(0.55),
                                  fontSize: 10.5,
                                  fontStyle: FontStyle.italic)),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Action row ────────────────────────────────
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(text: _shareText));
                        setState(() => _copied = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _copied = false);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(colors: [
                            _copied
                                ? const Color(0xFF66BB6A).withOpacity(0.6)
                                : accent.withOpacity(0.55),
                            accent.withOpacity(0.30),
                          ]),
                        ),
                        child: Center(
                          child: Text(
                            _copied ? '✓ Copied' : '📋 Copy Card',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white.withOpacity(0.07),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Text('Close',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

// ══════════════════════════════════════════════════════════════
//  MEMORY SHEET  — full memory management bottom sheet
// ══════════════════════════════════════════════════════════════

class _MemorySheet extends StatelessWidget {
  final void Function(String id) onDeleteMemory;
  final void Function(String id) onResolveMemory;
  final VoidCallback onClearAll;

  const _MemorySheet({
    required this.onDeleteMemory,
    required this.onResolveMemory,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final memProvider = context.watch<MemoryProvider>();
    final tl = memProvider.timeline;
    final insight = memProvider.memoryInsight;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF0E0220),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            child: Row(
              children: [
                const Text('🌙', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lunar Remembers',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (insight != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          insight,
                          style: TextStyle(
                            color: _kPurple.withOpacity(0.75),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (tl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _confirmClearAll(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red.withOpacity(0.10),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.22), width: 0.8),
                      ),
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.70),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.07), height: 1),
          // Memory list
          Expanded(
            child: tl.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🌙', style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 14),
                        Text(
                          'No memories yet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.50),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: Text(
                            'As you share meaningful moments with Lunar, they will be gently stored here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.34),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: tl.length,
                    separatorBuilder: (_, __) => Divider(
                        color: Colors.white.withOpacity(0.05), height: 1),
                    itemBuilder: (ctx, i) {
                      final m = tl[i];
                      return _MemoryTile(
                        memory: m,
                        onDelete: () => onDeleteMemory(m.id),
                        onResolve: () => onResolveMemory(m.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF160330),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear all memories?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'This will permanently delete all of Lunar\'s memories about you. This cannot be undone.',
          style:
              TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.55))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              onClearAll();
            },
            child: const Text('Clear all',
                style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  final DeepMemory memory;
  final VoidCallback onDelete;
  final VoidCallback onResolve;

  const _MemoryTile({
    required this.memory,
    required this.onDelete,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPurple.withOpacity(0.14),
              border: Border.all(color: _kPurple.withOpacity(0.22), width: 0.8),
            ),
            child: Center(
              child: Text(memory.category.emoji,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: _kPurple.withOpacity(0.12),
                      ),
                      child: Text(
                        memory.category.label,
                        style: TextStyle(
                          color: _kPurple.withOpacity(0.80),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (memory.isResolved) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFF66BB6A).withOpacity(0.12),
                        ),
                        child: Text(
                          '✨ healed',
                          style: TextStyle(
                            color: const Color(0xFF66BB6A).withOpacity(0.80),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      memory.timeAgoLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  memory.summary,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(memory.isResolved ? 0.45 : 0.75),
                    fontSize: 13.5,
                    height: 1.4,
                    decoration:
                        memory.isResolved ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Actions column
          Column(
            children: [
              if (!memory.isResolved)
                GestureDetector(
                  onTap: onResolve,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF66BB6A).withOpacity(0.12),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF66BB6A),
                      size: 15,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.10),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.withOpacity(0.65),
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
