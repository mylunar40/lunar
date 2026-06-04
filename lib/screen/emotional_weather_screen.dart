import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/models/emotional_weather.dart';
import '../core/providers/weather_provider.dart';

// ══════════════════════════════════════════════════════════════
//  EMOTIONAL WEATHER SCREEN
//  Full-screen daily emotional weather reading experience.
//  Navigated to from home_dashboard's _dailyReadingCard.
// ══════════════════════════════════════════════════════════════

class EmotionalWeatherScreen extends StatefulWidget {
  const EmotionalWeatherScreen({super.key});

  @override
  State<EmotionalWeatherScreen> createState() => _EmotionalWeatherScreenState();
}

class _EmotionalWeatherScreenState extends State<EmotionalWeatherScreen>
    with TickerProviderStateMixin {
  // Design tokens — identical to home_dashboard / ai_voice_screen.
  static const _bg = Color(0xFF0A0118);
  static const _purple = Color(0xFFAB5CF2);
  static const _pink = Color(0xFFFF69B4);
  static const _gold = Color(0xFFFFD700);

  late AnimationController _glowCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _entryCtrl;

  late Animation<double> _glowAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(CurvedAnimation(
      parent: _glowCtrl,
      curve: Curves.easeInOut,
    ));
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(CurvedAnimation(
      parent: _floatCtrl,
      curve: Curves.easeInOut,
    ));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final weatherProv = context.watch<WeatherProvider>();
    final today = weatherProv.todayWeather;
    final forecast = weatherProv.forecast;
    final history = weatherProv.recentHistory;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Ambient gradient background.
          _AmbientBg(weather: today, glowAnim: _glowAnim),

          SafeArea(
            child: FadeTransition(
              opacity: _entryAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header bar.
                  SliverToBoxAdapter(child: _headerBar(context, today)),

                  // Hero weather orb.
                  SliverToBoxAdapter(
                    child: _heroOrb(today),
                  ),

                  // Today's reading.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _readingCard(today),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 18)),

                  // Lunar insight.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _insightCard(today),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 18)),

                  // Healing intention.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _intentionCard(today),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // 3-Day Forecast.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _forecastSection(forecast),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // History strip (last 7 days).
                  if (history.length > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _historySection(history),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 28)),

                  // Share button.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _shareButton(context, today),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header bar ─────────────────────────────────────────────

  Widget _headerBar(BuildContext context, DayWeather today) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 20),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Emotional Weather',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                _formattedToday(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Hero orb ───────────────────────────────────────────────

  Widget _heroOrb(DayWeather today) {
    final colors = today.gradientColors;
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnim, _floatAnim]),
      builder: (_, __) {
        return Container(
          height: 240,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(0, _floatAnim.value),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow.
                Container(
                  width: 170 + 30 * _glowAnim.value,
                  height: 170 + 30 * _glowAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withOpacity(0.28 * _glowAnim.value),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
                // Main orb.
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colors.first.withOpacity(0.9),
                        colors.last.withOpacity(0.6),
                        colors.last.withOpacity(0.15),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withOpacity(0.5 * _glowAnim.value),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      today.emoji,
                      style: const TextStyle(fontSize: 58),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Reading card ───────────────────────────────────────────

  Widget _readingCard(DayWeather today) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            today.gradientColors.first.withOpacity(0.22),
            today.gradientColors.last.withOpacity(0.12),
          ],
        ),
        border: Border.all(
          color: today.accentColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: today.accentColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: today.accentColor.withOpacity(0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${today.emoji}  ${today.label}',
                  style: TextStyle(
                    color: today.accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (today.isPersonalized)
                Text(
                  'Personalised',
                  style: TextStyle(
                    color: _gold.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            today.reading,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 15.5,
              height: 1.65,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ── Insight card ───────────────────────────────────────────

  Widget _insightCard(DayWeather today) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(
          color: _purple.withOpacity(0.18),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🌙', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lunar Insight',
                  style: TextStyle(
                    color: _purple.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  today.insight,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Intention card ─────────────────────────────────────────

  Widget _intentionCard(DayWeather today) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            _pink.withOpacity(0.12),
            _purple.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: _pink.withOpacity(0.2), width: 0.8),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🌸', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Intention",
                  style: TextStyle(
                    color: _pink.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  today.healingIntention,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 14.5,
                    height: 1.55,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3-Day Forecast section ─────────────────────────────────

  Widget _forecastSection(WeatherForecast forecast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3-DAY FORECAST',
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: forecast.days.asMap().entries.map((e) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
                child: _forecastDayCard(e.value, isToday: e.key == 0),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _forecastDayCard(DayWeather day, {required bool isToday}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            day.gradientColors.first.withOpacity(isToday ? 0.3 : 0.15),
            day.gradientColors.last.withOpacity(isToday ? 0.18 : 0.08),
          ],
        ),
        border: Border.all(
          color: day.accentColor.withOpacity(isToday ? 0.5 : 0.2),
          width: isToday ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        children: [
          Text(
            day.dayLabel ?? (isToday ? 'Today' : '—'),
            style: TextStyle(
              color: Colors.white.withOpacity(isToday ? 0.9 : 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(day.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            day.state.shortLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: day.accentColor.withOpacity(0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── History section ────────────────────────────────────────

  Widget _historySection(List<DayWeather> history) {
    // Show at most 7 items.
    final items = history.take(7).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT HISTORY',
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = items[i];
              final isToday = d.date == _todayDateKey();
              return Container(
                width: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: d.accentColor.withOpacity(isToday ? 0.22 : 0.1),
                  border: Border.all(
                    color: d.accentColor.withOpacity(isToday ? 0.5 : 0.18),
                    width: isToday ? 1.2 : 0.7,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      _shortDate(d.date),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Share button ───────────────────────────────────────────

  Widget _shareButton(BuildContext context, DayWeather today) {
    return GestureDetector(
      onTap: () => _showShareSheet(context, today),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [_purple, _pink],
          ),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Share Your Reading',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Share sheet ────────────────────────────────────────────

  void _showShareSheet(BuildContext context, DayWeather today) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShareSheet(today: today),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  String _formattedToday() {
    final d = DateTime.now();
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
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  String _todayDateKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _shortDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length < 3) return dateKey;
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
      final month = int.tryParse(parts[1]) ?? 1;
      return '${months[month - 1]} ${parts[2]}';
    } catch (_) {
      return dateKey;
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  AMBIENT BACKGROUND
// ══════════════════════════════════════════════════════════════

class _AmbientBg extends StatelessWidget {
  final DayWeather weather;
  final Animation<double> glowAnim;

  const _AmbientBg({required this.weather, required this.glowAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnim,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.2, -0.6),
              radius: 1.4,
              colors: [
                weather.gradientColors.first.withOpacity(0.18 * glowAnim.value),
                const Color(0xFF0A0118),
                const Color(0xFF0A0118),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SHARE SHEET
//  Beautiful bottom sheet with shareable card + copy action.
//  No share plugin needed — uses Clipboard.setData().
// ══════════════════════════════════════════════════════════════

class _ShareSheet extends StatelessWidget {
  final DayWeather today;

  const _ShareSheet({required this.today});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Color(0xFF12022B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle.
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Preview card.
                _PreviewCard(today: today),

                const SizedBox(height: 20),

                // Copy to clipboard button.
                _ActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Copy Reading',
                  color: today.accentColor,
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: today.buildShareText()),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Reading copied! Share it with someone you love 🌙',
                        ),
                        backgroundColor: today.accentColor.withOpacity(0.9),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Close button.
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Share preview card ──────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final DayWeather today;

  const _PreviewCard({required this.today});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            today.gradientColors.first.withOpacity(0.6),
            today.gradientColors.last.withOpacity(0.4),
          ],
        ),
        border: Border.all(
          color: today.accentColor.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: today.accentColor.withOpacity(0.22),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            today.emoji,
            style: const TextStyle(fontSize: 44),
          ),
          const SizedBox(height: 8),
          Text(
            today.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            // Limit preview to first paragraph.
            today.reading.split('\n\n').first,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '— Lunar AI 🌙',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Share action button ─────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.85),
              color.withOpacity(0.6),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
