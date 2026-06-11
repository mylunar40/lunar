import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/lunar_data_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/models/journal_model.dart';
import '../core/models/cycle_model.dart';
import '../core/services/firestore_service.dart';

// ── Design tokens ────────────────────────────────────────────
const Color _kBg = Color(0xFF0A0118);
const Color _kSurface = Color(0xFF160330);
const Color _kPurple = Color(0xFFAB5CF2);
const Color _kDeep = Color(0xFF5C2DB8);
const Color _kMuted = Color(0xFF9B89B8);
const Color _kText = Color(0xFFF0E6FF);

// ── Phase-aware writing prompts ──────────────────────────────
const List<String> _periodPrompts = [
  'What does your body need most right now? 🌙',
  'What feels heavy today — can you gently put it down?',
  'What would feel tender and kind for you tonight?',
  'What is asking for your rest and attention?',
];
const List<String> _follicularPrompts = [
  'What new possibility is waking up inside you? 🌱',
  'What are you beginning to feel hopeful about?',
  'What feels fresh or energising today?',
  'What would you like to begin?',
];
const List<String> _ovulationPrompts = [
  'What lit you up today? ✨',
  'Who or what are you most grateful for right now?',
  'What did you create, share, or feel proud of?',
  'What connection felt meaningful today?',
];
const List<String> _lutealPrompts = [
  'What is weighing on your heart tonight? 💜',
  'What feels unfinished or unsettled inside you?',
  'What do you need to release before you sleep?',
  'What truth is trying to surface right now?',
];
const List<String> _defaultPrompts = [
  'What is on your heart right now? 🌙',
  'How does today feel inside your body?',
  'What do you want to remember about today?',
  'What needs to be spoken, even just to yourself?',
];

// ── Mood data ────────────────────────────────────────────────
const List<Map<String, String>> _moodData = [
  {'emoji': '😊', 'label': 'Joyful'},
  {'emoji': '😢', 'label': 'Sad'},
  {'emoji': '😡', 'label': 'Angry'},
  {'emoji': '😴', 'label': 'Tired'},
  {'emoji': '😍', 'label': 'Loved'},
];

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with TickerProviderStateMixin {
  // ── Preserved state ──────────────────────────────────────
  final TextEditingController journalController = TextEditingController();
  String selectedMood = '😊';
  List<String> selectedTags = [];
  final List<String> tags = [
    'Breakup', 'Stress', 'Love', 'Lonely', 'Motivation', 'Anxiety',
  ];
  bool _saving = false;

  // ── Animation state ──────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // ── UI state ─────────────────────────────────────────────
  bool _hasText = false;
  int _promptIndex = 0;

  @override
  void initState() {
    super.initState();
    _promptIndex = math.Random().nextInt(4);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    journalController.addListener(() {
      final hasText = journalController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    journalController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ── Preserved save logic (100% unchanged) ────────────────
  Future<void> saveEntry() async {
    final text = journalController.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);

    final lunarData = context.read<LunarDataProvider>();
    final auth = context.read<LunarAuthProvider>();

    final entry = JournalEntry(
      id: DateTime.now().toIso8601String(),
      date: DateTime.now(),
      title: text.length > 60 ? '${text.substring(0, 60)}…' : text,
      content: text,
      mood: selectedMood,
      tags: List.from(selectedTags),
    );

    lunarData.addJournalEntry(entry);

    final uid = auth.firebaseUser?.uid;
    if (uid != null && !auth.isGuest) {
      try {
        await FirestoreService.saveJournal(
          uid: uid,
          title: entry.title,
          content: entry.content,
          mood: entry.mood,
          tags: entry.tags,
        );
      } catch (e) {
        debugPrint('[JournalScreen] Firestore sync failed (non-blocking): $e');
      }
    }

    journalController.clear();
    setState(() {
      selectedTags = [];
      _saving = false;
      _promptIndex = math.Random().nextInt(4);
    });

    if (mounted) {
      _showLunarToast('Your entry has been held safely 💜');
    }
  }

  void _showLunarToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🌙', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: _kText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _kSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: _kPurple.withOpacity(0.4), width: 1),
        ),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        elevation: 0,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Phase helpers ────────────────────────────────────────
  String _phaseLabel(LunarCyclePhase phase) {
    switch (phase) {
      case LunarCyclePhase.period:
        return 'Menstrual phase · rest is sacred right now 🌙';
      case LunarCyclePhase.follicular:
        return 'Follicular phase · new energy is rising 🌱';
      case LunarCyclePhase.ovulation:
        return 'Ovulation phase · your light is shining ✨';
      case LunarCyclePhase.luteal:
        return 'Luteal phase · your inner world is active 💜';
      default:
        return 'Your sacred writing space 🌙';
    }
  }

  Color _phaseAccent(LunarCyclePhase phase) {
    switch (phase) {
      case LunarCyclePhase.period:
        return _kPurple;
      case LunarCyclePhase.follicular:
        return const Color(0xFF66BB6A);
      case LunarCyclePhase.ovulation:
        return const Color(0xFFFFD700);
      case LunarCyclePhase.luteal:
        return const Color(0xFF7986CB);
      default:
        return _kPurple;
    }
  }

  List<String> _phasePrompts(LunarCyclePhase phase) {
    switch (phase) {
      case LunarCyclePhase.period:
        return _periodPrompts;
      case LunarCyclePhase.follicular:
        return _follicularPrompts;
      case LunarCyclePhase.ovulation:
        return _ovulationPrompts;
      case LunarCyclePhase.luteal:
        return _lutealPrompts;
      default:
        return _defaultPrompts;
    }
  }

  // ── Date formatting ──────────────────────────────────────
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Today · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) {
      return 'Yesterday · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${m[date.month - 1]} ${date.year}';
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lunarData = context.watch<LunarDataProvider>();
    final entries = lunarData.journalEntries;
    final phase = lunarData.currentPhase;
    final accent = _phaseAccent(phase);
    final prompts = _phasePrompts(phase);
    final prompt = prompts[_promptIndex % prompts.length];

    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, phase, accent)),
            SliverToBoxAdapter(child: _buildMoodSelector(accent)),
            SliverToBoxAdapter(child: _buildWritingSection(accent, prompt)),
            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: _hasText ? _buildTagsSection() : const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(child: _buildSaveButton(accent)),
            SliverToBoxAdapter(child: _buildSectionDivider(entries.isEmpty)),
            entries.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _buildEntryCard(entries[i], accent),
                      childCount: entries.length,
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, LunarCyclePhase phase, Color accent) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withOpacity(0.07), _kBg.withOpacity(0)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + Orb presence row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kPurple.withOpacity(0.22)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _kPurple,
                    size: 16,
                  ),
                ),
              ),
              const Spacer(),
              // Lunar Orb presence — Lunar is here with you
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: _kPurple.withOpacity(0.10),
                    border: Border.all(
                      color: _kPurple
                          .withOpacity(0.28 + _glowAnimation.value * 0.18),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kPurple
                            .withOpacity(_glowAnimation.value * 0.14),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mini breathing orb
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.22),
                              _kPurple.withOpacity(0.80),
                              _kDeep,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                            center: const Alignment(-0.2, -0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kPurple.withOpacity(
                                  0.35 + _glowAnimation.value * 0.30),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                            child: Text('🌙',
                                style: TextStyle(fontSize: 10))),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Lunar is here',
                        style: TextStyle(
                          color: _kPurple.withOpacity(0.78),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Phase pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
            child: Text(
              _phaseLabel(phase),
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Journal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Your thoughts, held safely',
            style: TextStyle(color: _kMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Mood Selector ────────────────────────────────────────
  Widget _buildMoodSelector(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: _moodData.map((m) {
          final emoji = m['emoji']!;
          final label = m['label']!;
          final isSelected = selectedMood == emoji;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedMood = emoji),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withOpacity(0.18)
                      : _kSurface.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isSelected
                        ? accent.withOpacity(0.55)
                        : _kPurple.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.22 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? accent : _kMuted,
                        fontSize: 9,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Writing Section ──────────────────────────────────────
  Widget _buildWritingSection(Color accent, String prompt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 2),
              child: Text(
                prompt,
                style: TextStyle(
                  color: accent.withOpacity(0.85),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
            TextField(
              controller: journalController,
              maxLines: null,
              minLines: 7,
              cursorColor: accent,
              cursorWidth: 2,
              style: const TextStyle(
                color: _kText,
                fontSize: 15.5,
                height: 1.72,
                letterSpacing: 0.1,
              ),
              decoration: InputDecoration(
                hintText: 'Begin writing here...',
                hintStyle: TextStyle(
                  color: _kMuted.withOpacity(0.45),
                  fontSize: 15.5,
                  fontStyle: FontStyle.italic,
                  height: 1.72,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.fromLTRB(20, 10, 20, 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tags Section (appears after writing starts) ──────────
  Widget _buildTagsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT THEMES DOES THIS TOUCH?',
            style: TextStyle(
              color: _kMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    selectedTags.remove(tag);
                  } else {
                    selectedTags.add(tag);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kPurple.withOpacity(0.2)
                        : _kSurface.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? _kPurple.withOpacity(0.6)
                          : _kPurple.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: isSelected ? _kPurple : _kMuted,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Save Button ──────────────────────────────────────────
  Widget _buildSaveButton(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glow = _hasText ? _glowAnimation.value : 0.0;
          return GestureDetector(
            onTap: (_saving || !_hasText) ? null : saveEntry,
            child: AnimatedOpacity(
              opacity: _hasText ? 1.0 : 0.38,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kDeep, _kPurple, accent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accent
                          .withOpacity(0.18 + glow * 0.28),
                      blurRadius: 14 + glow * 14,
                      spreadRadius: glow * 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                    : const Text(
                        'Hold this moment  💜',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section Divider ──────────────────────────────────────
  Widget _buildSectionDivider(bool isEmpty) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: _kPurple.withOpacity(0.14),
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              isEmpty ? 'YOUR JOURNEY BEGINS HERE' : 'PREVIOUS ENTRIES',
              style: TextStyle(
                color: _kMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: _kPurple.withOpacity(0.14),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(44, 40, 44, 20),
      child: Column(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text(
            "Your story hasn't started yet",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Write your first entry above. Your journal holds every feeling safely — no one else can see it.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kMuted,
              fontSize: 13,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  // ── Entry Card ───────────────────────────────────────────
  Widget _buildEntryCard(JournalEntry entry, Color accent) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.withOpacity(0.28)),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.redAccent,
          size: 20,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: _kSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _kPurple.withOpacity(0.2),
                  ),
                ),
                title: const Text(
                  'Delete this entry?',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                content: Text(
                  'This moment will be released. It cannot be undone.',
                  style: TextStyle(color: _kMuted, fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      'Keep it',
                      style: TextStyle(color: _kPurple),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'Release',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        context.read<LunarDataProvider>().deleteJournalEntry(entry.id);
        _showLunarToast('Entry released 🌙');
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kSurface.withOpacity(0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kPurple.withOpacity(0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: accent.withOpacity(0.22)),
              ),
              alignment: Alignment.center,
              child: Text(
                entry.mood,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date + tags row
                  Row(
                    children: [
                      Text(
                        _formatDate(entry.date),
                        style: TextStyle(
                          color: _kMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ...entry.tags.take(2).map(
                              (t) => Container(
                                margin:
                                    const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      _kPurple.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(100),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    color: _kPurple,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Content preview
                  Text(
                    entry.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _kText.withOpacity(0.8),
                      fontSize: 13.5,
                      height: 1.55,
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

