// ═══════════════════════════════════════════════════════════
//  LUNAR AI CHAT — Premium Minimal Experience
//  Clean · Calm · Emotional · Beautiful
// ═══════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import '../core/models/chat_message.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/app_provider.dart';
import '../core/providers/lunar_data_provider.dart';
import '../core/providers/premium_provider.dart';
import '../core/data/local_cache.dart';
import '../screen/premium_themes_screen.dart';
import '../screen/paywall/paywall_screen.dart';
import '../widgets/premium_gate.dart';

// ── Design tokens ─────────────────────────────────────────
const Color _kBg = Color(0xFF0A0118);
const Color _kSurf = Color(0xFF14022E);
const Color _kPurple = Color(0xFFAB5CF2);
const Color _kPink = Color(0xFFFF69B4);
const Color _kGold = Color(0xFFFFD700);
const Color _kDeep = Color(0xFF5C2DB8);

// ─────────────────────────────────────────────────────────
//  LUNAR THINKING ANIMATION
//  Wave-style dots with subtle scale — elegant, minimal
// ─────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(3, (i) {
          // Each dot peaks at a different phase — creates a wave
          final offset = i * 0.28;
          final t = ((_ctrl.value - offset) % 1.0);
          // Sine-like bounce: up for first half, down for second
          final scale = 0.6 +
              0.7 *
                  (t < 0.4
                      ? (t / 0.4)
                      : t < 0.7
                          ? ((0.7 - t) / 0.3)
                          : 0.0);
          final glowOpacity = scale > 0.9 ? (scale - 0.9) * 3.0 : 0.0;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Transform.scale(
              scale: scale.clamp(0.6, 1.3),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPurple,
                  boxShadow: glowOpacity > 0
                      ? [
                          BoxShadow(
                            color: _kPurple.withOpacity(glowOpacity * 0.7),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════

class AIVoiceScreen extends StatefulWidget {
  const AIVoiceScreen({super.key});

  @override
  State<AIVoiceScreen> createState() => _AIVoiceState();
}

class _AIVoiceState extends State<AIVoiceScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── Animations ────────────────────────────────────────────
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late AnimationController _sweepCtrl; // rotating border shimmer

  // ── Controllers ───────────────────────────────────────────
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ── State ─────────────────────────────────────────────────
  bool _isFocused = false;
  bool _isRecording = false;
  bool _hasText = false; // drives send button active state
  String _voiceText = '';
  XFile? _pendingMedia;
  MediaType? _pendingMediaType;
  _ChatTheme _activeTheme = _ChatTheme.moonlight;

  static const _kThemeKey = 'lunar_ai_chat_theme_v1';
  static const _kSavedKey = 'lunar_ai_saved_msgs_v1';
  static const _kCommunityThemeKey = 'lunar_community_theme_v1';

  // ── Saved messages (❤️) ───────────────────────────────────
  final Set<String> _savedMsgIds = {};

  // ── STT ───────────────────────────────────────────────────
  final stt.SpeechToText _sttService = stt.SpeechToText();
  bool _sttAvailable = false;

  // ── Image picker ──────────────────────────────────────────
  final ImagePicker _imagePicker = ImagePicker();

  // ── Chat listener ─────────────────────────────────────────
  ChatProvider? _chatListenerRef;

  // ── Dynamic suggestions ───────────────────────────────────
  List<(String, String)> _suggestions = [];

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.45, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Rotating border shimmer — full continuous rotation, 4 s per cycle
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });

    // Update send button state whenever text changes
    _textCtrl.addListener(() {
      final has = _textCtrl.text.trim().isNotEmpty;
      if (has != _hasText && mounted) setState(() => _hasText = has);
    });

    _initStt();
    _computeSuggestions();

    // Restore saved theme
    final saved = LocalCache.getString(_kThemeKey);
    if (saved != null) {
      final t = _ChatTheme.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => _ChatTheme.moonlight,
      );
      if (t != _activeTheme) setState(() => _activeTheme = t);
    }

    // Restore saved message IDs
    final savedIds = LocalCache.getString(_kSavedKey);
    if (savedIds != null && savedIds.isNotEmpty) {
      _savedMsgIds.addAll(savedIds.split(','));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chat = context.read<ChatProvider>();
      final seed = chat.checkInSeedPrompt;
      if (seed != null && seed.isNotEmpty) {
        chat.clearCheckInSeed();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _send(seed);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chat = context.read<ChatProvider>();
    if (_chatListenerRef != chat) {
      _chatListenerRef?.removeListener(_onChatChanged);
      _chatListenerRef = chat;
      _chatListenerRef?.addListener(_onChatChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lunarData = context.read<LunarDataProvider>();
      final app = context.read<AppProvider>();
      context.read<ChatProvider>().seedWelcomeContext(
            isPregnant: lunarData.isPregnant || app.pregnancyMode,
            pregnancyWeek: (lunarData.isPregnant || app.pregnancyMode)
                ? lunarData.currentPregnancyWeek
                : null,
            emotionalIntent: app.emotionalIntent,
          );
      _computeSuggestions();
    });
  }

  void _onChatChanged() {
    if (!mounted) return;
    _scrollToBottom();
  }

  void _computeSuggestions() {
    if (!mounted) return;
    final lunarData = context.read<LunarDataProvider>();
    final app = context.read<AppProvider>();
    final h = DateTime.now().hour;

    final raw = <(String, String)>[];

    if (lunarData.isPregnant || app.pregnancyMode) {
      raw.addAll([
        ('🤰', 'Baby Growth'),
        ('💊', 'Medication'),
        ('🥗', 'Nutrition'),
        ('😴', 'Sleep'),
        ('💜', 'Anxiety'),
        ('👶', 'Birth Prep'),
      ]);
    } else {
      if (h < 9) raw.addAll([('☀️', 'Morning'), ('😴', 'Sleep')]);
      if (h >= 21) raw.addAll([('🌙', 'Wind Down'), ('📔', 'Journal')]);
      raw.addAll([
        ('🩸', 'Period'),
        ('💜', 'Mood'),
        ('🌬️', 'Stress'),
        ('🔄', 'Cycle'),
        ('💧', 'Hydration'),
        ('🥗', 'Nutrition'),
      ]);
    }

    final seen = <String>{};
    final result = <(String, String)>[];
    for (final s in raw) {
      if (seen.add(s.$2) && result.length < 6) result.add(s);
    }
    setState(() => _suggestions = result);
  }

  @override
  void dispose() {
    _chatListenerRef?.removeListener(_onChatChanged);
    _glowCtrl.dispose();
    _sweepCtrl.dispose();
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    _sttService.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────
  // ── Save / unsave a message ───────────────────────────────
  void _toggleSave(String msgId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_savedMsgIds.contains(msgId)) {
        _savedMsgIds.remove(msgId);
      } else {
        _savedMsgIds.add(msgId);
      }
    });
    LocalCache.setString(_kSavedKey, _savedMsgIds.join(','));
  }

  // ── Regenerate last AI response ───────────────────────────
  void _regenerateLast(ChatMessage aiMsg) {
    final msgs = context.read<ChatProvider>().messages;
    final idx = msgs.indexWhere((m) => m.id == aiMsg.id);
    // Find the user message just before this AI message
    final userMsg = idx > 0
        ? msgs
            .sublist(0, idx)
            .lastWhere((m) => m.isUser, orElse: () => msgs.first)
        : msgs.firstWhere((m) => m.isUser, orElse: () => msgs.first);
    if (userMsg.isUser) _send(userMsg.text);
  }

  // ── Share / copy a message ────────────────────────────────
  void _shareMsg(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Copied 🌙', style: TextStyle(color: Colors.white)),
      backgroundColor: _kDeep,
      duration: Duration(seconds: 1),
    ));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final premium = context.read<PremiumProvider>();
    final chat = context.read<ChatProvider>();
    if (!chat.canSendAiMessage(premium.isPaid)) {
      PaywallGate.show(context, featureHint: 'Unlimited AI support');
      return;
    }
    _textCtrl.clear();
    _focusNode.unfocus();
    chat.send(t, context);
    _scrollToBottom();
  }

  void _sendMedia() {
    final file = _pendingMedia;
    final type = _pendingMediaType;
    if (file == null || type == null) return;
    final premium = context.read<PremiumProvider>();
    final chat = context.read<ChatProvider>();
    if (!chat.canSendAiMessage(premium.isPaid)) {
      PaywallGate.show(context, featureHint: 'Unlimited AI support');
      return;
    }
    setState(() {
      _pendingMedia = null;
      _pendingMediaType = null;
    });
    chat.sendWithMedia(file, type, context, isPremiumUser: premium.isPaid);
    _scrollToBottom();
  }

  // ── STT ───────────────────────────────────────────────────
  Future<void> _initStt() async {
    _sttAvailable = await _sttService.initialize(
      onError: (_) {
        if (mounted) setState(() => _isRecording = false);
      },
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) _finishVoice();
      },
    );
  }

  void _startVoice() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = true;
      _voiceText = '';
    });
    if (!_sttAvailable) return;
    await _sttService.listen(
      onResult: (r) {
        if (mounted) {
          _voiceText = r.recognizedWords;
          _textCtrl.text = r.recognizedWords;
          setState(() {});
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  void _stopVoice() {
    _sttService.stop();
    _finishVoice();
  }

  void _finishVoice() {
    if (!mounted) return;
    final text = _voiceText.trim();
    setState(() {
      _isRecording = false;
      _voiceText = '';
    });
    if (text.isNotEmpty) _send(text);
  }

  // ── Media ─────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final f = await _imagePicker.pickImage(
          source: source, imageQuality: 85, maxWidth: 1280);
      if (f != null && mounted) {
        setState(() {
          _pendingMedia = f;
          _pendingMediaType = MediaType.image;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickVideo() async {
    Navigator.pop(context);
    try {
      final f = await _imagePicker.pickVideo(
          source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
      if (f != null && mounted) {
        setState(() {
          _pendingMedia = f;
          _pendingMediaType = MediaType.video;
        });
      }
    } catch (_) {}
  }

  // ── Dialogs & sheets ──────────────────────────────────────
  void _confirmClear() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Chat? 🌙',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('This will clear your current conversation.',
            style:
                TextStyle(color: Colors.white.withOpacity(0.6), height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().clearHistory();
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
            },
            child: const Text('Clear', style: TextStyle(color: _kPink)),
          ),
        ],
      ),
    );
  }

  void _openMoonMenu() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MoonMenuSheet(
        onNewChat: () {
          Navigator.pop(context);
          _confirmClear();
        },
        onHistory: () {
          Navigator.pop(context);
          _openHistory();
        },
        onLanguages: () {
          Navigator.pop(context);
          _openLanguages();
        },
        onSettings: () {
          Navigator.pop(context);
          _openSettings();
        },
        onThemes: () {
          Navigator.pop(context);
          _openThemes();
        },
        onExport: () {
          Navigator.pop(context);
          _exportChat();
        },
        onClear: () {
          Navigator.pop(context);
          _confirmClear();
        },
      ),
    );
  }

  void _openAttachments() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttachSheet(
        onCamera: () => _pickImage(ImageSource.camera),
        onGallery: () => _pickImage(ImageSource.gallery),
        onVideo: () => _pickVideo(),
        onFiles: () => Navigator.pop(context),
      ),
    );
  }

  void _openMessageMenu(ChatMessage msg) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MsgMenuSheet(
        msg: msg,
        onCopy: () {
          Clipboard.setData(ClipboardData(text: msg.text));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Copied 🌙', style: TextStyle(color: Colors.white)),
            backgroundColor: _kDeep,
            duration: Duration(seconds: 1),
          ));
        },
        onShare: () {
          Clipboard.setData(ClipboardData(text: msg.text));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Copied to clipboard 🌙',
                style: TextStyle(color: Colors.white)),
            backgroundColor: _kDeep,
            duration: Duration(seconds: 1),
          ));
        },
        onDelete: () => Navigator.pop(context),
        onRegenerate: msg.isUser
            ? null
            : () {
                Navigator.pop(context);
                final msgs = context.read<ChatProvider>().messages;
                if (msgs.length >= 2) {
                  final userMsg = msgs.reversed
                      .firstWhere((m) => m.isUser, orElse: () => msgs.last);
                  _send(userMsg.text);
                }
              },
      ),
    );
  }

  void _openHistory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _HistorySheet(messages: context.read<ChatProvider>().messages),
    );
  }

  void _openLanguages() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimpleListSheet(
        title: '🌍 Language',
        items: const [
          ('🇺🇸', 'English'),
          ('🇮🇳', 'Hindi'),
          ('🇫🇷', 'French'),
          ('🇪🇸', 'Spanish'),
          ('🇸🇦', 'Arabic'),
          ('🇩🇪', 'German'),
        ],
        onSelect: (v) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Language: $v 🌙',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: _kDeep,
            duration: const Duration(seconds: 1),
          ));
        },
      ),
    );
  }

  void _openSettings() {
    final chat = context.read<ChatProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _SettingsSheet(
          hasKey: chat.apiKeyConfigured,
          onSave: (key) async {
            if (key.isNotEmpty) {
              await chat.saveApiKey(key);
              if (context.mounted) Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  void _openThemes() {
    final communityTheme = LocalCache.getString(_kCommunityThemeKey) ?? 'lunar';
    Navigator.push<void>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PremiumThemesScreen(
          currentAiTheme: _activeTheme.name,
          currentCommunityTheme: communityTheme,
          onAiThemeChanged: (id) {
            final t = _ChatTheme.values.firstWhere(
              (e) => e.name == id,
              orElse: () => _ChatTheme.moonlight,
            );
            setState(() => _activeTheme = t);
          },
          onCommunityThemeChanged: (id) {
            LocalCache.setString(_kCommunityThemeKey, id);
          },
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  void _exportChat() {
    final msgs = context.read<ChatProvider>().messages;
    if (msgs.isEmpty) return;
    final buf = StringBuffer()
      ..writeln('🌙 Lunar AI Chat Export')
      ..writeln('─' * 30);
    for (final m in msgs) {
      final who = m.isUser ? 'You' : 'Lunar AI';
      final t = m.timestamp;
      final time = '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
      buf.writeln('[$time] $who: ${m.text}');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Chat copied to clipboard 🌙',
          style: TextStyle(color: Colors.white)),
      backgroundColor: _kDeep,
      duration: Duration(seconds: 2),
    ));
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final chat = context.watch<ChatProvider>();
    final theme = _activeTheme;

    return Scaffold(
      backgroundColor: theme.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.2,
                colors: [theme.accent.withOpacity(0.1), theme.bg],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────
                _buildHeader(chat),
                const Divider(height: 1, color: Color(0x12FFFFFF)),

                // ── Messages ───────────────────────────────────
                Expanded(
                  child: _buildMessages(chat, theme),
                ),

                // ── Suggestions ────────────────────────────────
                _buildSuggestions(),

                // ── Pending media ──────────────────────────────
                if (_pendingMedia != null) _buildPendingMedia(),

                // ── Input bar ──────────────────────────────────
                _buildInput(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(ChatProvider chat) {
    final statusText = _isRecording
        ? 'Listening... 🎤'
        : chat.isTyping
            ? 'Typing... ✨'
            : _isFocused
                ? 'Typing...'
                : 'Always here for you';
    final statusColor = (_isRecording || chat.isTyping || _isFocused)
        ? _kPurple
        : Colors.white.withOpacity(0.4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          // Left spacer
          const SizedBox(width: 42),

          // Center: title + status
          Expanded(
            child: Column(
              children: [
                const Text(
                  '🌙 Lunar AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Text(
                    statusText,
                    key: ValueKey(statusText),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: Moon menu button
          GestureDetector(
            onTap: _openMoonMenu,
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPurple.withOpacity(0.1),
                  border: Border.all(
                    color: _kPurple.withOpacity(_glowAnim.value * 0.35),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Text('🌙', style: TextStyle(fontSize: 19)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Messages ──────────────────────────────────────────────
  Widget _buildMessages(ChatProvider chat, _ChatTheme theme) {
    final msgs = chat.messages;
    final count = msgs.length + (chat.isTyping ? 1 : 0);

    return ListView.builder(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      itemCount: count,
      itemBuilder: (_, i) {
        if (i == msgs.length) {
          // Typing indicator
          return Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 56),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const _TypingDots(),
              ),
            ),
          );
        }

        final msg = msgs[i];
        final isUser = msg.isUser;

        return Padding(
          padding: EdgeInsets.only(
            bottom: isUser ? 8 : 2,
            left: isUser ? 52 : 0,
            right: isUser ? 0 : 52,
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: GestureDetector(
                  onLongPress: () => _openMessageMenu(msg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.userBubble,
                                theme.userBubble.withOpacity(0.82),
                              ],
                            )
                          : null,
                      color: isUser ? null : Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                    ),
                    child: msg.type == ChatMsgType.healingCard
                        ? _buildHealCard(msg)
                        : Text(
                            msg.text,
                            style: TextStyle(
                              color:
                                  Colors.white.withOpacity(isUser ? 1.0 : 0.9),
                              fontSize: 15,
                              height: 1.52,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                ),
              ),
              // ── Quick actions (AI messages only) ──────────
              if (!isUser) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _QuickActionRow(
                    isSaved: _savedMsgIds.contains(msg.id),
                    onSave: () => _toggleSave(msg.id),
                    onRegenerate: () => _regenerateLast(msg),
                    onShare: () => _shareMsg(msg.text),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealCard(ChatMessage msg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          msg.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.52,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: _kPurple.withOpacity(0.22)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✨', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(
              'Lunar Healing',
              style: TextStyle(
                color: _kPurple.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Suggestions ───────────────────────────────────────────
  Widget _buildSuggestions() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = _suggestions[i];
          return _SuggestionChip(
            emoji: s.$1,
            label: s.$2,
            onTap: () {
              HapticFeedback.selectionClick();
              _send('Tell me about ${s.$2.toLowerCase()}');
            },
          );
        },
      ),
    );
  }

  // ── Pending media ─────────────────────────────────────────
  Widget _buildPendingMedia() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _kDeep.withOpacity(0.55),
        border: Border.all(color: _kPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (_pendingMediaType == MediaType.image)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(_pendingMedia!.path),
                  width: 48, height: 48, fit: BoxFit.cover),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _kPurple.withOpacity(0.2),
              ),
              child:
                  const Icon(Icons.videocam_rounded, color: _kPurple, size: 24),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _pendingMedia!.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _pendingMedia = null;
              _pendingMediaType = null;
            }),
            child: Icon(Icons.close_rounded,
                color: Colors.white.withOpacity(0.4), size: 18),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMedia,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _kPurple,
              ),
              child: const Text('Send',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────
  //  🎤  |  Message...  |  🌙  |  ➤
  Widget _buildInput(_ChatTheme theme) {
    return AnimatedBuilder(
      animation: _sweepCtrl,
      builder: (_, child) {
        // Sweep angle: full rotation over the controller's 0→1 value
        final angle = _sweepCtrl.value * 2 * math.pi;
        // Intensity: stronger when focused or recording
        final intensity = _isFocused
            ? 0.75
            : _isRecording
                ? 0.9
                : 0.35;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            // Rotating gradient creates the "light sweeping around the border"
            gradient: SweepGradient(
              transform: GradientRotation(angle),
              colors: [
                Colors.transparent,
                _kPurple.withOpacity(intensity * 0.6),
                _kPink.withOpacity(intensity * 0.45),
                Colors.white.withOpacity(intensity * 0.3),
                _kPurple.withOpacity(intensity * 0.4),
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [0.0, 0.15, 0.30, 0.42, 0.55, 0.70, 1.0],
            ),
          ),
          // Inner container is 1.5px smaller — creates the border thickness
          child: Container(
            margin: const EdgeInsets.all(1.5),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              color: theme.bg.withOpacity(0.96),
            ),
            child: child,
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 🎤 Mic button with pulse ring when recording
          GestureDetector(
            onTap: () {
              if (_isRecording) {
                _stopVoice();
              } else {
                _startVoice();
              }
            },
            onLongPressStart: (_) => _startVoice(),
            onLongPressEnd: (_) => _stopVoice(),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse ring — only when recording
                  if (_isRecording)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (_, v, __) => Container(
                        width: 38 * v,
                        height: 38 * v,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _kPink.withOpacity(1.0 - v),
                            width: 2,
                          ),
                        ),
                      ),
                      onEnd: () {
                        if (mounted && _isRecording) setState(() {});
                      },
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? _kPink.withOpacity(0.18)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isRecording
                          ? _kPink
                          : Colors.white.withOpacity(0.45),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Text field
          Expanded(
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, height: 1.4),
              maxLines: 5,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              cursorColor: _kPurple,
              cursorWidth: 2,
              cursorRadius: const Radius.circular(2),
              decoration: InputDecoration(
                hintText: _isRecording ? 'Listening...' : 'Message...',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.28), fontSize: 15),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                isDense: true,
              ),
              onSubmitted: (_) => _send(_textCtrl.text),
            ),
          ),

          // 🌙 Attachment button
          GestureDetector(
            onTap: _openAttachments,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
                child: const Center(
                  child: Text('🌙', style: TextStyle(fontSize: 17)),
                ),
              ),
            ),
          ),

          const SizedBox(width: 2),

          // ➤ Send button — active only when text is present
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _hasText ? 1.0 : 0.38,
            child: GestureDetector(
              onTap: _hasText ? () => _send(_textCtrl.text) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _hasText
                        ? [_kPurple, _kDeep]
                        : [_kPurple.withOpacity(0.5), _kDeep.withOpacity(0.5)],
                  ),
                  boxShadow: _hasText
                      ? [
                          BoxShadow(
                            color: _kPurple.withOpacity(0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  QUICK ACTION ROW  ❤️ Save | 🔄 Regenerate | 📤 Share
// ═══════════════════════════════════════════════════════════

class _QuickActionRow extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onRegenerate;
  final VoidCallback onShare;

  const _QuickActionRow({
    required this.isSaved,
    required this.onSave,
    required this.onRegenerate,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(isSaved ? '❤️' : '🤍', isSaved ? _kPink : null, onSave),
        const SizedBox(width: 6),
        _btn('🔄', null, onRegenerate),
        const SizedBox(width: 6),
        _btn('📤', null, onShare),
      ],
    );
  }

  Widget _btn(String emoji, Color? activeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: activeColor != null
              ? activeColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: activeColor != null
                ? activeColor.withOpacity(0.3)
                : Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SUGGESTION CHIP — with press feedback
// ═══════════════════════════════════════════════════════════

class _SuggestionChip extends StatefulWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip(
      {required this.emoji, required this.label, required this.onTap});

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _kPurple.withOpacity(0.1),
            border: Border.all(color: _kPurple.withOpacity(0.22), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MOON MENU SHEET
// ═══════════════════════════════════════════════════════════

class _MoonMenuSheet extends StatelessWidget {
  final VoidCallback onNewChat,
      onHistory,
      onLanguages,
      onSettings,
      onThemes,
      onExport,
      onClear;

  const _MoonMenuSheet({
    required this.onNewChat,
    required this.onHistory,
    required this.onLanguages,
    required this.onSettings,
    required this.onThemes,
    required this.onExport,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border:
            Border(top: BorderSide(color: _kPurple.withOpacity(0.2), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('🌙', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('Lunar AI',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
            _item(Icons.add_circle_outline_rounded, 'New Chat', onNewChat),
            _item(Icons.history_rounded, 'Chat History', onHistory),
            _item(Icons.language_rounded, 'Languages', onLanguages),
            _item(Icons.tune_rounded, 'Chat Settings', onSettings),
            _item(Icons.palette_outlined, 'Premium Themes ✨', onThemes,
                accent: _kGold),
            _item(Icons.ios_share_rounded, 'Export Chat', onExport),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Divider(color: Colors.white.withOpacity(0.08), height: 1),
            ),
            _item(Icons.delete_sweep_outlined, 'Clear Current Chat', onClear,
                accent: _kPink),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: Colors.white.withOpacity(0.18),
        ),
      );

  Widget _item(IconData icon, String label, VoidCallback onTap,
      {Color? accent}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.04),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: accent ?? Colors.white.withOpacity(0.6), size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: accent ?? Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.18), size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ATTACHMENT SHEET
// ═══════════════════════════════════════════════════════════

class _AttachSheet extends StatelessWidget {
  final VoidCallback onCamera, onGallery, onVideo, onFiles;

  const _AttachSheet({
    required this.onCamera,
    required this.onGallery,
    required this.onVideo,
    required this.onFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border:
            Border(top: BorderSide(color: _kPurple.withOpacity(0.2), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _btn('📷', 'Camera', onCamera),
                _btn('🖼️', 'Gallery', onGallery),
                _btn('🎬', 'Video', onVideo),
                _btn('📁', 'Files', onFiles),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPurple.withOpacity(0.12),
              border: Border.all(color: _kPurple.withOpacity(0.2)),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MESSAGE MENU SHEET
// ═══════════════════════════════════════════════════════════

class _MsgMenuSheet extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback onCopy, onShare, onDelete;
  final VoidCallback? onRegenerate;

  const _MsgMenuSheet({
    required this.msg,
    required this.onCopy,
    required this.onShare,
    required this.onDelete,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border:
            Border(top: BorderSide(color: _kPurple.withOpacity(0.2), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            // Message preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.045),
              ),
              child: Text(
                msg.text.length > 110
                    ? '${msg.text.substring(0, 110)}...'
                    : msg.text,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _action(Icons.copy_rounded, 'Copy', onCopy),
                _action(Icons.share_rounded, 'Share', onShare),
                _action(Icons.delete_outline_rounded, 'Delete', onDelete,
                    color: _kPink),
                if (onRegenerate != null)
                  _action(Icons.refresh_rounded, 'Redo', onRegenerate!,
                      color: _kPurple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (color ?? Colors.white).withOpacity(0.09),
              border:
                  Border.all(color: (color ?? Colors.white).withOpacity(0.16)),
            ),
            child: Icon(icon,
                color: color ?? Colors.white.withOpacity(0.65), size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: color ?? Colors.white.withOpacity(0.55),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HISTORY SHEET
// ═══════════════════════════════════════════════════════════

class _HistorySheet extends StatefulWidget {
  final List<ChatMessage> messages;
  const _HistorySheet({required this.messages});

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final all = widget.messages
        .where((m) =>
            !m.isUser &&
            (_query.isEmpty ||
                m.text.toLowerCase().contains(_query.toLowerCase())))
        .toList()
        .reversed
        .toList();

    List<ChatMessage> bucket(DateTime from, DateTime to) => all.where((m) {
          final d =
              DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day);
          return !d.isBefore(from) && d.isBefore(to);
        }).toList();

    final todayMsgs = bucket(today, today.add(const Duration(days: 1)));
    final yestMsgs = bucket(yesterday, today);
    final weekMsgs = bucket(weekAgo, yesterday);
    final earlierMsgs = all
        .where((m) =>
            DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day)
                .isBefore(weekAgo))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: _kSurf,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
              top: BorderSide(color: _kPurple.withOpacity(0.2), width: 1)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            const Text('🌙 Chat History',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: _kPurple,
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.28)),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Colors.white.withOpacity(0.35), size: 20),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: all.isEmpty
                  ? Center(
                      child: Text('No conversations yet 🌙',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.38),
                              fontSize: 14)),
                    )
                  : ListView(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children: [
                        if (todayMsgs.isNotEmpty) ...[
                          _section('Today'),
                          ...todayMsgs.map(_card),
                        ],
                        if (yestMsgs.isNotEmpty) ...[
                          _section('Yesterday'),
                          ...yestMsgs.map(_card),
                        ],
                        if (weekMsgs.isNotEmpty) ...[
                          _section('This Week'),
                          ...weekMsgs.map(_card),
                        ],
                        if (earlierMsgs.isNotEmpty) ...[
                          _section('Earlier'),
                          ...earlierMsgs.map(_card),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
        child: Text(label,
            style: TextStyle(
              color: _kPurple.withOpacity(0.75),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            )),
      );

  Widget _card(ChatMessage m) {
    final t = m.timestamp;
    final time = '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
    final title = _autoTitle(m.text);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌙', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3),
                ),
                const SizedBox(height: 3),
                Text(
                  m.text.length > 60 ? '${m.text.substring(0, 60)}...' : m.text,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 11.5,
                      height: 1.4),
                ),
              ],
            ),
          ),
          Text(time,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.28), fontSize: 11)),
        ],
      ),
    );
  }

  /// Auto-generate a conversation title from message text.
  String _autoTitle(String text) {
    final t = text.toLowerCase();
    if (t.contains('pregnan') ||
        t.contains('baby') ||
        t.contains('trimest') ||
        t.contains('bump') ||
        t.contains('contraction')) return 'Pregnancy 🤰';
    if (t.contains('period') ||
        t.contains('menstrual') ||
        t.contains('cycle') ||
        t.contains('cramp') ||
        t.contains('bleed')) return 'Period Talk 🩸';
    if (t.contains('sleep') ||
        t.contains('insomnia') ||
        t.contains('tired') ||
        t.contains('rest') ||
        t.contains('awake')) return 'Sleep Wellness 🌙';
    if (t.contains('anxiet') ||
        t.contains('stress') ||
        t.contains('panic') ||
        t.contains('worry') ||
        t.contains('overwhelm')) return 'Stress & Anxiety 🌬️';
    if (t.contains('sad') ||
        t.contains('depress') ||
        t.contains('cry') ||
        t.contains('feeling') ||
        t.contains('emotion')) return 'Emotional Check-in 💜';
    if (t.contains('food') ||
        t.contains('eat') ||
        t.contains('nutrition') ||
        t.contains('diet') ||
        t.contains('water') ||
        t.contains('hydrat')) return 'Nutrition & Hydration 🥗';
    if (t.contains('mood') || t.contains('happy') || t.contains('joy'))
      return 'Mood 😊';
    if (t.contains('relation') ||
        t.contains('partner') ||
        t.contains('love') ||
        t.contains('heartbreak') ||
        t.contains('breakup')) return 'Relationships 💞';
    if (t.contains('meditation') ||
        t.contains('breath') ||
        t.contains('calm') ||
        t.contains('mindful')) return 'Mindfulness 🌿';
    if (t.contains('pain') || t.contains('ache') || t.contains('hurt'))
      return 'Pain Support 💊';
    // Fallback: first meaningful words
    final words = text.split(' ').take(4).join(' ');
    return words.length > 30 ? '${words.substring(0, 30)}...' : words;
  }
}

// ═══════════════════════════════════════════════════════════
//  SIMPLE LIST SHEET
// ═══════════════════════════════════════════════════════════

class _SimpleListSheet extends StatelessWidget {
  final String title;
  final List<(String, String)> items;
  final void Function(String) onSelect;

  const _SimpleListSheet({
    required this.title,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border:
            Border(top: BorderSide(color: _kPurple.withOpacity(0.2), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...items.map(
              (item) => GestureDetector(
                onTap: () => onSelect(item.$2),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.04),
                  ),
                  child: Row(
                    children: [
                      Text(item.$1, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(item.$2,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SETTINGS SHEET
// ═══════════════════════════════════════════════════════════

class _SettingsSheet extends StatefulWidget {
  final bool hasKey;
  final Future<void> Function(String) onSave;
  const _SettingsSheet({required this.hasKey, required this.onSave});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border:
            Border(top: BorderSide(color: _kPurple.withOpacity(0.2), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
            ),
            const Text('⚙️ Chat Settings',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text('OpenAI API Key',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              obscureText: _obscure,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: _kPurple,
              decoration: InputDecoration(
                hintText: widget.hasKey ? '●●●● (tap to update)' : 'sk-...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.28)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.055),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kPurple),
                ),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withOpacity(0.35),
                      size: 20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        await widget.onSave(_ctrl.text.trim());
                        if (mounted) setState(() => _saving = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPurple,
                  disabledBackgroundColor: _kPurple.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save API Key',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  THEME PICKER SHEET
// ═══════════════════════════════════════════════════════════

class _ThemeSheet extends StatelessWidget {
  final _ChatTheme active;
  final void Function(_ChatTheme) onSelect;

  const _ThemeSheet({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border:
            Border(top: BorderSide(color: _kPurple.withOpacity(0.2), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            const Text('✨ Premium Themes',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  _ChatTheme.values.map((t) => _card(t, t == active)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(_ChatTheme t, bool isActive) {
    return GestureDetector(
      onTap: () => onSelect(t),
      child: Container(
        width: 88,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: t.accent.withOpacity(0.1),
          border: Border.all(
            color: isActive ? t.accent : Colors.white.withOpacity(0.1),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [t.accent, t.userBubble],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.55),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CHAT THEME MODEL
// ═══════════════════════════════════════════════════════════

enum _ChatTheme {
  moonlight,
  aurora,
  lavender,
  rose,
  midnight,
  ocean,
  sakura,
  emerald,
  roseGold;

  String get label => const {
        _ChatTheme.moonlight: 'Moonlight',
        _ChatTheme.aurora: 'Aurora',
        _ChatTheme.lavender: 'Lavender',
        _ChatTheme.rose: 'Rose',
        _ChatTheme.midnight: 'Midnight',
        _ChatTheme.ocean: 'Ocean',
        _ChatTheme.sakura: 'Sakura Pink',
        _ChatTheme.emerald: 'Emerald Forest',
        _ChatTheme.roseGold: 'Rose Gold',
      }[this]!;

  Color get bg => const {
        _ChatTheme.moonlight: Color(0xFF0A0118),
        _ChatTheme.aurora: Color(0xFF01100A),
        _ChatTheme.lavender: Color(0xFF0D0825),
        _ChatTheme.rose: Color(0xFF180510),
        _ChatTheme.midnight: Color(0xFF000A18),
        _ChatTheme.ocean: Color(0xFF010D18),
        _ChatTheme.sakura: Color(0xFF180510),
        _ChatTheme.emerald: Color(0xFF021208),
        _ChatTheme.roseGold: Color(0xFF160A08),
      }[this]!;

  Color get accent => const {
        _ChatTheme.moonlight: Color(0xFFAB5CF2),
        _ChatTheme.aurora: Color(0xFF66BB6A),
        _ChatTheme.lavender: Color(0xFFBA68C8),
        _ChatTheme.rose: Color(0xFFFF69B4),
        _ChatTheme.midnight: Color(0xFF4FC3F7),
        _ChatTheme.ocean: Color(0xFF0288D1),
        _ChatTheme.sakura: Color(0xFFFF69B4),
        _ChatTheme.emerald: Color(0xFF4CAF50),
        _ChatTheme.roseGold: Color(0xFFE57373),
      }[this]!;

  Color get userBubble => const {
        _ChatTheme.moonlight: Color(0xFF7B39BD),
        _ChatTheme.aurora: Color(0xFF2E7D32),
        _ChatTheme.lavender: Color(0xFF7B1FA2),
        _ChatTheme.rose: Color(0xFFC2185B),
        _ChatTheme.midnight: Color(0xFF0277BD),
        _ChatTheme.ocean: Color(0xFF01579B),
        _ChatTheme.sakura: Color(0xFFAD1457),
        _ChatTheme.emerald: Color(0xFF1B5E20),
        _ChatTheme.roseGold: Color(0xFFB71C1C),
      }[this]!;
}
