// ─────────────────────────────────────────────────────────────────────────────
//  LUNAR COMMUNITY CHAT — Messenger-Style Private Conversations
//  UI-only implementation for connected healing connections
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Design tokens ─────────────────────────────────────────
const Color _cBg = Color(0xFF0A0118);
const Color _cSurf = Color(0xFF160330);
const Color _cPurple = Color(0xFFAB5CF2);
const Color _cPink = Color(0xFFFF69B4);
const Color _cGreen = Color(0xFF66BB6A);
const Color _cTeal = Color(0xFF4FC3F7);

// ── Message model ──────────────────────────────────────────
class _Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmoji;
  final String content;
  final DateTime timestamp;
  final bool isOwn;
  final bool isSensitive;

  _Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmoji,
    required this.content,
    required this.timestamp,
    required this.isOwn,
    this.isSensitive = false,
  });
}

// ═══════════════════════════════════════════════════════════
//  COMMUNITY CHAT SCREEN
// ═══════════════════════════════════════════════════════════

class CommunityChatScreen extends StatefulWidget {
  /// Connected user's UID and display info
  final String userId;
  final String userName;
  final String userEmoji;
  final String userColorHex;

  const CommunityChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmoji,
    required this.userColorHex,
  });

  static Route<void> route({
    required String userId,
    required String userName,
    required String userEmoji,
    required String userColorHex,
  }) {
    return MaterialPageRoute(
      builder: (_) => CommunityChatScreen(
        userId: userId,
        userName: userName,
        userEmoji: userEmoji,
        userColorHex: userColorHex,
      ),
    );
  }

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen>
    with TickerProviderStateMixin {
  late TextEditingController _messageCtrl;
  late ScrollController _scrollCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  final List<_Message> _messages = [
    _Message(
      id: '1',
      senderId: 'other',
      senderName: 'Featured Member',
      senderEmoji: '🌸',
      content: 'Hey! I loved your post on self-care today 💜',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isOwn: false,
    ),
    _Message(
      id: '2',
      senderId: 'me',
      senderName: 'You',
      senderEmoji: '✨',
      content: 'Thank you so much! Your insights have been really helpful too 🌙',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      isOwn: true,
    ),
    _Message(
      id: '3',
      senderId: 'other',
      senderName: 'Featured Member',
      senderEmoji: '🌸',
      content: 'Would love to chat more about healing practices. Are you open to connecting?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      isOwn: false,
    ),
  ];

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messageCtrl = TextEditingController();
    _scrollCtrl = ScrollController();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _messageCtrl.addListener(() {
      setState(() => _isTyping = _messageCtrl.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_messageCtrl.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(
        _Message(
          id: '${_messages.length}',
          senderId: 'me',
          senderName: 'You',
          senderEmoji: '✨',
          content: _messageCtrl.text.trim(),
          timestamp: DateTime.now(),
          isOwn: true,
        ),
      );
      _messageCtrl.clear();
      _isTyping = false;
    });

    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);

    // Simulate reply
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(
            _Message(
              id: '${_messages.length}',
              senderId: 'other',
              senderName: widget.userName,
              senderEmoji: widget.userEmoji,
              content: 'This sounds amazing! Let\'s explore this together 🌙',
              timestamp: DateTime.now(),
              isOwn: false,
            ),
          );
        });
        _scrollToBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.maybePop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        title: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: _cPurple.withOpacity(0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                content: Text(
                  '${widget.userName}\'s profile',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _cGreen,
                      boxShadow: [
                        BoxShadow(
                          color: _cGreen,
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Online now',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showChatOptions();
            },
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Messages List ────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
              ),
            ),

            // ── Typing Indicator ─────────────────────────────
            if (!_isTyping && _messages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildTypingIndicator(),
              ),

            // ── Input Area ───────────────────────────────────
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 12,
              ),
              child: _buildInputArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_Message msg) {
    final userColor = _colorFromHex(widget.userColorHex);

    if (msg.isOwn) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          _cPurple.withOpacity(0.5),
                          _cPink.withOpacity(0.35),
                        ],
                      ),
                      border: Border.all(
                        color: _cPurple.withOpacity(0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _cPurple.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      msg.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(msg.timestamp),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    userColor.withOpacity(0.8),
                    userColor.withOpacity(0.3),
                  ]),
                  border: Border.all(
                    color: userColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    msg.senderEmoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.65,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              userColor.withOpacity(0.25),
                              userColor.withOpacity(0.10),
                            ],
                          ),
                          border: Border.all(
                            color: userColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          msg.content,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(msg.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                widget.userEmoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.08),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(),
                const SizedBox(width: 6),
                _buildTypingDot(delay: 200),
                const SizedBox(width: 6),
                _buildTypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot({int delay = 0}) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) {
        final value = (_glowAnim.value - 0.55) / 0.45;
        final adjustedDelay = delay / 1000 / 0.4;
        final animValue = ((value + adjustedDelay) % 1.0);

        return Transform.translate(
          offset: Offset(
            0,
            -6 * (animValue > 0.5 ? 2 - animValue * 2 : animValue * 2),
          ),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.5 + 0.3 * animValue),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                _cPurple.withOpacity(0.15),
                _cPink.withOpacity(0.08),
              ],
            ),
            border: Border.all(
              color: _cPurple.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: _cPurple.withOpacity(0.85),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      content: const Text(
                        'Media sharing coming soon! 📸',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.add_rounded,
                    color: _cPurple.withOpacity(0.6),
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _messageCtrl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Share a thought...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                  maxLines: 1,
                ),
              ),
              if (_isTyping)
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _cPurple,
                          _cPink.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _cPurple.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: _cPink.withOpacity(0.4),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _cSurf,
                  _cBg,
                ],
              ),
              border: Border.all(
                color: _cPurple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chat Options',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildChatOptionButton(
                    '💬',
                    'View Profile',
                    'See ${widget.userName}\'s full profile',
                    () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: _cPurple.withOpacity(0.85),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          content: Text(
                            'Opening ${widget.userName}\'s profile...',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildChatOptionButton(
                    '📌',
                    'Mute Notifications',
                    'Silence messages from this connection',
                    () {
                      Navigator.pop(context);
                      HapticFeedback.lightImpact();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildChatOptionButton(
                    '❤️',
                    'Add to Favorites',
                    'Quick access to this conversation',
                    () {
                      Navigator.pop(context);
                      HapticFeedback.lightImpact();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildChatOptionButton(
                    '🗑️',
                    'Delete Chat',
                    'Remove this conversation',
                    () {
                      Navigator.pop(context);
                      HapticFeedback.lightImpact();
                    },
                    isDangerous: true,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatOptionButton(
    String icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDangerous = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDangerous
              ? Colors.red.withOpacity(0.08)
              : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: isDangerous
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDangerous
                          ? Colors.red
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDangerous
                  ? Colors.red.withOpacity(0.5)
                  : Colors.white.withOpacity(0.25),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}

// ── Helper: Parse hex color ────────────────────────────────
Color _colorFromHex(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) {
    buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
  } else {
    buffer.write(hexString.replaceFirst('#', ''));
  }
  return Color(int.parse(buffer.toString(), radix: 16));
}
