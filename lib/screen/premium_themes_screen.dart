// ═══════════════════════════════════════════════════════════
//  LUNAR — PREMIUM THEME ENGINE
//  AI Chat Themes + Community Themes
//  Design-locked: only recolors, never redesigns
// ═══════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/data/local_cache.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/premium_provider.dart';

// ── Keys ──────────────────────────────────────────────────
const _kAiThemeKey        = 'lunar_ai_chat_theme_v1';
const _kCommunityThemeKey = 'lunar_community_theme_v1';

// ── AI Chat theme descriptors ─────────────────────────────
class LunarAiTheme {
  final String id;
  final String emoji;
  final String name;
  final Color bg;
  final Color accent;
  final Color bubble;
  final bool isPremium;

  const LunarAiTheme({
    required this.id,
    required this.emoji,
    required this.name,
    required this.bg,
    required this.accent,
    required this.bubble,
    this.isPremium = true,
  });
}

const kAiThemes = [
  LunarAiTheme(
    id: 'moonlight', emoji: '🌙', name: 'Moonlight Purple',
    bg: Color(0xFF0A0118), accent: Color(0xFFAB5CF2), bubble: Color(0xFF7B39BD),
    isPremium: false,
  ),
  LunarAiTheme(
    id: 'aurora', emoji: '✨', name: 'Aurora',
    bg: Color(0xFF01100A), accent: Color(0xFF66BB6A), bubble: Color(0xFF2E7D32),
  ),
  LunarAiTheme(
    id: 'sakura', emoji: '🌸', name: 'Sakura Pink',
    bg: Color(0xFF180510), accent: Color(0xFFFF69B4), bubble: Color(0xFFC2185B),
  ),
  LunarAiTheme(
    id: 'lavender', emoji: '💜', name: 'Lavender Dream',
    bg: Color(0xFF0D0825), accent: Color(0xFFBA68C8), bubble: Color(0xFF7B1FA2),
  ),
  LunarAiTheme(
    id: 'midnight', emoji: '🌌', name: 'Midnight Black',
    bg: Color(0xFF000A18), accent: Color(0xFF4FC3F7), bubble: Color(0xFF0277BD),
  ),
  LunarAiTheme(
    id: 'ocean', emoji: '🌊', name: 'Ocean Calm',
    bg: Color(0xFF010D18), accent: Color(0xFF0288D1), bubble: Color(0xFF01579B),
  ),
  LunarAiTheme(
    id: 'emerald', emoji: '🌿', name: 'Emerald Forest',
    bg: Color(0xFF021208), accent: Color(0xFF4CAF50), bubble: Color(0xFF1B5E20),
  ),
  LunarAiTheme(
    id: 'roseGold', emoji: '🌅', name: 'Rose Gold',
    bg: Color(0xFF160A08), accent: Color(0xFFE57373), bubble: Color(0xFFB71C1C),
  ),
];

// ── Community theme descriptors ───────────────────────────
class LunarCommunityTheme {
  final String id;
  final String emoji;
  final String name;
  final Color accent;
  final bool isPremium;

  const LunarCommunityTheme({
    required this.id,
    required this.emoji,
    required this.name,
    required this.accent,
    this.isPremium = true,
  });
}

const kCommunityThemes = [
  LunarCommunityTheme(
    id: 'lunar', emoji: '🌙', name: 'Lunar Purple',
    accent: Color(0xFFAB5CF2), isPremium: false,
  ),
  LunarCommunityTheme(
    id: 'rose',    emoji: '🌸', name: 'Rose',    accent: Color(0xFFFF69B4)),
  LunarCommunityTheme(
    id: 'aurora',  emoji: '✨', name: 'Aurora',  accent: Color(0xFF66BB6A)),
  LunarCommunityTheme(
    id: 'midnight',emoji: '🌌', name: 'Midnight',accent: Color(0xFFFFD700)),
  LunarCommunityTheme(
    id: 'ocean',   emoji: '🌊', name: 'Ocean',   accent: Color(0xFF4FC3F7)),
  LunarCommunityTheme(
    id: 'sakura',  emoji: '🌺', name: 'Sakura',  accent: Color(0xFFE91E63)),
];

// ═══════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════

class PremiumThemesScreen extends StatefulWidget {
  final String currentAiTheme;
  final String currentCommunityTheme;
  final void Function(String) onAiThemeChanged;
  final void Function(String) onCommunityThemeChanged;

  const PremiumThemesScreen({
    super.key,
    required this.currentAiTheme,
    required this.currentCommunityTheme,
    required this.onAiThemeChanged,
    required this.onCommunityThemeChanged,
  });

  @override
  State<PremiumThemesScreen> createState() => _PremiumThemesScreenState();
}

class _PremiumThemesScreenState extends State<PremiumThemesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late String _selectedAi;
  late String _selectedCommunity;
  bool _saving = false;

  static const _kBg      = Color(0xFF0A0118);
  static const _kSurf    = Color(0xFF14022E);
  static const _kPurple  = Color(0xFFAB5CF2);
  static const _kPink    = Color(0xFFFF69B4);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _selectedAi        = widget.currentAiTheme;
    _selectedCommunity = widget.currentCommunityTheme;
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _applyAi(LunarAiTheme t) async {
    HapticFeedback.selectionClick();
    setState(() { _selectedAi = t.id; _saving = true; });

    // Save locally
    await LocalCache.setString(_kAiThemeKey, t.id);

    // Save to Firestore for cross-device sync
    final uid = context.read<LunarAuthProvider>().firebaseUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'aiChatTheme': t.id}, SetOptions(merge: true))
          .catchError((_) {});
    }

    widget.onAiThemeChanged(t.id);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _applyCommunity(LunarCommunityTheme t) async {
    HapticFeedback.selectionClick();
    setState(() { _selectedCommunity = t.id; _saving = true; });

    // Save locally
    await LocalCache.setString(_kCommunityThemeKey, t.id);

    // Save to Firestore
    final uid = context.read<LunarAuthProvider>().firebaseUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'communityTheme': t.id}, SetOptions(merge: true))
          .catchError((_) {});
    }

    widget.onCommunityThemeChanged(t.id);
    if (mounted) setState(() => _saving = false);
  }

  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PremiumProvider>().canAccessPremiumThemes;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildAiTab(isPremium),
                  _buildCommunityTab(isPremium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const Expanded(
            child: Column(
              children: [
                Text('✨ Premium Themes',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2)),
                SizedBox(height: 2),
                Text('Personalize your Lunar experience',
                    style: TextStyle(
                        color: Color(0x66FFFFFF), fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.06),
        ),
        child: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _kPurple.withOpacity(0.3),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.4),
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '🌙 AI Chat'),
            Tab(text: '💜 Community'),
          ],
        ),
      ),
    );
  }

  // ── AI Chat themes tab ────────────────────────────────────
  Widget _buildAiTab(bool isPremium) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: kAiThemes.length,
      itemBuilder: (_, i) {
        final t = kAiThemes[i];
        final isActive = _selectedAi == t.id;
        final locked = t.isPremium && !isPremium;
        return _AiThemeCard(
          theme: t,
          isActive: isActive,
          locked: locked,
          onApply: locked ? () => _showPremiumGate() : () => _applyAi(t),
        );
      },
    );
  }

  // ── Community themes tab ──────────────────────────────────
  Widget _buildCommunityTab(bool isPremium) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: kCommunityThemes.length,
      itemBuilder: (_, i) {
        final t = kCommunityThemes[i];
        final isActive = _selectedCommunity == t.id;
        final locked = t.isPremium && !isPremium;
        return _CommunityThemeCard(
          theme: t,
          isActive: isActive,
          locked: locked,
          onApply: locked ? () => _showPremiumGate() : () => _applyCommunity(t),
        );
      },
    );
  }

  void _showPremiumGate() {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kSurf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('✨ Premium Feature',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Upgrade to Lunar Premium to unlock all themes and personalization options.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.65), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later',
                style: TextStyle(color: Color(0x66FFFFFF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Upgrade',
                style: TextStyle(color: _kPink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  AI THEME CARD  — Live mini-preview
// ═══════════════════════════════════════════════════════════

class _AiThemeCard extends StatelessWidget {
  final LunarAiTheme theme;
  final bool isActive;
  final bool locked;
  final VoidCallback onApply;

  const _AiThemeCard({
    required this.theme,
    required this.isActive,
    required this.locked,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onApply,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? theme.accent
                : Colors.white.withOpacity(0.1),
            width: isActive ? 2 : 1,
          ),
          color: Colors.white.withOpacity(0.04),
        ),
        child: Column(
          children: [
            // ── Live mini-preview ──────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(17)),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      color: theme.bg,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    // Gradient orb
                    Positioned(
                      top: -20, right: -20,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            theme.accent.withOpacity(0.22),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                    // Mock AI bubble
                    Positioned(
                      left: 10, top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        constraints: const BoxConstraints(maxWidth: 95),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                            bottomLeft: Radius.circular(3),
                          ),
                          color: Colors.white.withOpacity(0.09),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          'Hi, I\'m here for you 🌙',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 9, height: 1.4),
                        ),
                      ),
                    ),
                    // Mock user bubble
                    Positioned(
                      right: 10, top: 46,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        constraints: const BoxConstraints(maxWidth: 80),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(3),
                          ),
                          gradient: LinearGradient(
                            colors: [theme.bubble, theme.bubble.withOpacity(0.75)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Text(
                          'I feel better 💜',
                          style: TextStyle(
                              color: Colors.white, fontSize: 9, height: 1.4),
                        ),
                      ),
                    ),
                    // Mock input bar
                    Positioned(
                      bottom: 8, left: 8, right: 8,
                      child: Container(
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(
                              color: theme.accent.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [theme.accent,
                                    theme.bubble],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Lock overlay
                    if (locked)
                      Container(
                        color: Colors.black.withOpacity(0.55),
                        child: const Center(
                          child: Text('🔒',
                              style: TextStyle(fontSize: 22)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // ── Theme name + apply ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(theme.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          theme.name,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                            fontSize: 11.5,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: isActive ? null : onApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? theme.accent.withOpacity(0.2)
                            : theme.accent,
                        disabledBackgroundColor:
                            theme.accent.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: Text(
                        isActive ? '✓ Active' : locked ? '🔒 Premium' : 'Apply',
                        style: TextStyle(
                          color: isActive
                              ? theme.accent
                              : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  COMMUNITY THEME CARD
// ═══════════════════════════════════════════════════════════

class _CommunityThemeCard extends StatelessWidget {
  final LunarCommunityTheme theme;
  final bool isActive;
  final bool locked;
  final VoidCallback onApply;

  const _CommunityThemeCard({
    required this.theme,
    required this.isActive,
    required this.locked,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onApply,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? theme.accent
                : Colors.white.withOpacity(0.1),
            width: isActive ? 2 : 1,
          ),
          color: Colors.white.withOpacity(0.04),
        ),
        child: Column(
          children: [
            // ── Community mini-preview ─────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(17)),
                child: Stack(
                  children: [
                    Container(
                      color: const Color(0xFF0A0118),
                      width: double.infinity,
                    ),
                    // Gradient orb
                    Positioned(
                      top: -15, left: -15,
                      child: Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            theme.accent.withOpacity(0.3),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                    // Mock community post card
                    Positioned(
                      left: 10, top: 12, right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withOpacity(0.07),
                          border: Border.all(
                              color: theme.accent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [
                                  theme.accent.withOpacity(0.8),
                                  theme.accent.withOpacity(0.3),
                                ]),
                              ),
                              child: const Center(
                                  child: Text('🌸',
                                      style: TextStyle(fontSize: 10))),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 5,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 4, width: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: Colors.white.withOpacity(0.25),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Mock category chips
                    Positioned(
                      bottom: 8, left: 10, right: 10,
                      child: Row(
                        children: [
                          _chip(theme.accent),
                          const SizedBox(width: 5),
                          _chip(theme.accent.withOpacity(0.6)),
                          const SizedBox(width: 5),
                          _chip(theme.accent.withOpacity(0.4)),
                        ],
                      ),
                    ),
                    if (locked)
                      Container(
                        color: Colors.black.withOpacity(0.55),
                        child: const Center(
                            child: Text('🔒',
                                style: TextStyle(fontSize: 22))),
                      ),
                  ],
                ),
              ),
            ),
            // ── Name + apply ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(theme.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          theme.name,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                            fontSize: 11.5,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: isActive ? null : onApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? theme.accent.withOpacity(0.2)
                            : theme.accent,
                        disabledBackgroundColor:
                            theme.accent.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: Text(
                        isActive ? '✓ Active' : locked ? '🔒 Premium' : 'Apply',
                        style: TextStyle(
                          color: isActive ? theme.accent : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(Color color) => Container(
        width: 28,
        height: 14,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: color.withOpacity(0.25),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
      );
}
