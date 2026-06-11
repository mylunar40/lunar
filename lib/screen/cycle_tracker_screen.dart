import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/providers/lunar_data_provider.dart';
import '../core/models/cycle_model.dart';

// ── Design tokens ─────────────────────────────────────────────
const Color _kBg = Color(0xFF0A0118);
const Color _kSurface = Color(0xFF160330);
const Color _kPurple = Color(0xFFAB5CF2);
const Color _kDeep = Color(0xFF5C2DB8);
const Color _kMuted = Color(0xFF9B89B8);
const Color _kText = Color(0xFFF0E6FF);

// Phase accent colours (per spec)
const Color _kRose = Color(0xFFF06292); // Menstrual
const Color _kGold = Color(0xFFFFD700); // Follicular
const Color _kTeal = Color(0xFF4FC3F7); // Ovulation
// Luteal uses _kPurple

// ── Day-type enum ─────────────────────────────────────────────
enum _DayType { normal, today, period, ovulation, fertile, predictedPeriod }

class CycleTrackerScreen extends StatefulWidget {
  const CycleTrackerScreen({super.key});

  @override
  State<CycleTrackerScreen> createState() => _CycleTrackerScreenState();
}

class _CycleTrackerScreenState extends State<CycleTrackerScreen>
    with TickerProviderStateMixin {
  // ── Local state (session) ─────────────────────────────────
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, String> _logs = {}; // date → emoji symptom log

  // ── Animations ───────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _pulseAnim =
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Phase helpers ─────────────────────────────────────────
  Color _phaseAccent(LunarCyclePhase p) {
    switch (p) {
      case LunarCyclePhase.period:
        return _kRose;
      case LunarCyclePhase.follicular:
        return _kGold;
      case LunarCyclePhase.ovulation:
        return _kTeal;
      case LunarCyclePhase.luteal:
        return _kPurple;
      default:
        return _kPurple;
    }
  }

  String _phaseName(LunarCyclePhase p) {
    switch (p) {
      case LunarCyclePhase.period:
        return 'Menstrual Phase';
      case LunarCyclePhase.follicular:
        return 'Follicular Phase';
      case LunarCyclePhase.ovulation:
        return 'Ovulation Phase';
      case LunarCyclePhase.luteal:
        return 'Luteal Phase';
      default:
        return 'Track Your Cycle';
    }
  }

  String _phaseEmoji(LunarCyclePhase p) {
    switch (p) {
      case LunarCyclePhase.period:
        return '🌑';
      case LunarCyclePhase.follicular:
        return '🌱';
      case LunarCyclePhase.ovulation:
        return '✨';
      case LunarCyclePhase.luteal:
        return '🌕';
      default:
        return '🌙';
    }
  }

  String _phaseDescription(LunarCyclePhase p) {
    switch (p) {
      case LunarCyclePhase.period:
        return 'Your body is releasing. Rest, warmth, and gentle movement are sacred right now.';
      case LunarCyclePhase.follicular:
        return 'Energy is building. Estrogen rises, creativity awakens, and optimism is returning.';
      case LunarCyclePhase.ovulation:
        return 'Peak energy and connection. You radiate confidence — communication flows naturally.';
      case LunarCyclePhase.luteal:
        return 'Your inner world deepens. Honor the need for quiet, nourishment, and reflection.';
      default:
        return 'Log your first period date to unlock phase-aware insights personalised to your body.';
    }
  }

  List<String> _phaseInsights(LunarCyclePhase p) {
    switch (p) {
      case LunarCyclePhase.period:
        return [
          'Your energy may be lower than usual — this is completely natural.',
          'Warmth supports your body through cramping and discomfort.',
          'Emotions may feel more intense — allow them without judgment.',
          'Iron-rich foods help replenish what your body is releasing.',
        ];
      case LunarCyclePhase.follicular:
        return [
          'Your energy may be increasing with each passing day.',
          'This is an ideal time for starting new projects or intentions.',
          'Cognitive sharpness is rising — lean into creative thinking.',
          'Social energy is returning — connection feels more natural.',
        ];
      case LunarCyclePhase.ovulation:
        return [
          'You may feel more confident and expressive today.',
          'Your body is at peak fertility — this window lasts 3–5 days.',
          'Communication and leadership come more naturally now.',
          'High energy supports intense workouts and social activity.',
        ];
      case LunarCyclePhase.luteal:
        return [
          'Your body may benefit from additional rest and nourishment.',
          'Progesterone rises — bloating and mood shifts are normal.',
          'This is a powerful time for deep reflection and journaling.',
          'Reducing caffeine and prioritising sleep eases symptoms.',
        ];
      default:
        return [
          'Track your cycle to receive personalised phase insights.',
          'Lunar learns your patterns with every cycle you log.',
        ];
    }
  }

  List<Map<String, String>> _phaseRecs(LunarCyclePhase p) {
    switch (p) {
      case LunarCyclePhase.period:
        return [
          {'icon': '🛁', 'title': 'Warm Bath', 'desc': 'Ease cramps with heat'},
          {'icon': '🧘', 'title': 'Gentle Yoga', 'desc': 'Restorative movement'},
          {'icon': '🍵', 'title': 'Herbal Tea', 'desc': 'Ginger or chamomile'},
          {'icon': '😴', 'title': 'Extra Rest', 'desc': 'Sleep is medicine now'},
        ];
      case LunarCyclePhase.follicular:
        return [
          {'icon': '🏃', 'title': 'Light Cardio', 'desc': 'Energy is building'},
          {'icon': '🎨', 'title': 'Create', 'desc': 'Harness your creativity'},
          {'icon': '🥗', 'title': 'Fresh Foods', 'desc': 'Feed rising energy'},
          {'icon': '🌞', 'title': 'Sun Time', 'desc': 'Vitamin D boosts mood'},
        ];
      case LunarCyclePhase.ovulation:
        return [
          {'icon': '💪', 'title': 'Peak Training', 'desc': 'Your strongest days'},
          {'icon': '💬', 'title': 'Connect', 'desc': 'Relationships flourish'},
          {'icon': '🎯', 'title': 'Big Goals', 'desc': 'Tackle hard challenges'},
          {'icon': '✨', 'title': 'Shine', 'desc': 'Express yourself freely'},
        ];
      case LunarCyclePhase.luteal:
        return [
          {'icon': '📖', 'title': 'Journal', 'desc': 'Process your feelings'},
          {'icon': '🌙', 'title': 'Early Sleep', 'desc': 'Prioritise rest'},
          {'icon': '🥜', 'title': 'Magnesium', 'desc': 'Reduces PMS symptoms'},
          {'icon': '🎵', 'title': 'Calm Music', 'desc': 'Soothe your nervous system'},
        ];
      default:
        return [
          {'icon': '📅', 'title': 'Log Cycle', 'desc': 'Unlock insights'},
          {'icon': '🌙', 'title': 'Track Mood', 'desc': 'Spot your patterns'},
        ];
    }
  }

  // ── Calendar day categorisation ───────────────────────────
  _DayType _getDayType(
    DateTime day,
    DateTime? lpd,
    int periodDur,
    DateTime? ovulationDate,
    DateTime? fertileStart,
    DateTime? fertileEnd,
    DateTime? nextPeriod,
  ) {
    final now = DateTime.now();
    final d = DateTime(day.year, day.month, day.day);
    final today = DateTime(now.year, now.month, now.day);

    if (d.isAtSameMomentAs(today)) return _DayType.today;
    if (lpd == null) return _DayType.normal;

    final lpdN = DateTime(lpd.year, lpd.month, lpd.day);
    final periodDiff = d.difference(lpdN).inDays;

    // Current period window
    if (periodDiff >= 0 && periodDiff < periodDur) return _DayType.period;

    // Ovulation day
    if (ovulationDate != null) {
      final ovdN = DateTime(ovulationDate.year, ovulationDate.month, ovulationDate.day);
      if (d.isAtSameMomentAs(ovdN)) return _DayType.ovulation;
    }

    // Fertile window
    if (fertileStart != null && fertileEnd != null) {
      final fsN = DateTime(fertileStart.year, fertileStart.month, fertileStart.day);
      final feN = DateTime(fertileEnd.year, fertileEnd.month, fertileEnd.day);
      if (!d.isBefore(fsN) && !d.isAfter(feN)) return _DayType.fertile;
    }

    // Predicted next period
    if (nextPeriod != null) {
      final npN = DateTime(nextPeriod.year, nextPeriod.month, nextPeriod.day);
      final npDiff = d.difference(npN).inDays;
      if (npDiff >= 0 && npDiff < periodDur) return _DayType.predictedPeriod;
    }

    return _DayType.normal;
  }

  // ── Actions ───────────────────────────────────────────────
  Future<void> _selectPeriodDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kPurple,
            onPrimary: Colors.white,
            surface: Color(0xFF1E0440),
            onSurface: _kText,
          ),
          dialogBackgroundColor: _kSurface,
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      await context.read<LunarDataProvider>().logPeriodStart(date: picked);
      setState(() {});
    }
  }

  void _addLog(DateTime day, String emoji) {
    setState(() => _logs[DateTime(day.year, day.month, day.day)] = emoji);
  }

  void _showLogDialog(DateTime day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LogSheet(
        day: day,
        existingLog: _logs[DateTime(day.year, day.month, day.day)],
        onLog: (emoji) {
          _addLog(day, emoji);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── Date formatting ───────────────────────────────────────
  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final data = context.watch<LunarDataProvider>();

    // Pregnancy mode guard
    if (data.isPregnant) return _buildPregnancyMode(context, data);

    final analysis = data.cycleAnalysis;
    final phase = analysis.currentPhase;
    final accent = _phaseAccent(phase);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
                child: _buildHeader(context, phase, accent, topPad, data)),
            SliverToBoxAdapter(
                child: _buildPhaseHeroCard(phase, accent, analysis, data.lastPeriodDate)),
            SliverToBoxAdapter(child: _buildInsightCards(phase, accent)),
            SliverToBoxAdapter(
                child: _buildCalendarSection(
                    accent, data.lastPeriodDate, analysis)),
            SliverToBoxAdapter(child: _buildStatsRow(analysis, accent)),
            SliverToBoxAdapter(child: _buildWellnessSection(phase, accent)),
            SliverToBoxAdapter(child: _buildLogButton(accent, data.lastPeriodDate)),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, LunarCyclePhase phase,
      Color accent, double topPad, LunarDataProvider data) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withOpacity(0.08), _kBg.withOpacity(0)],
        ),
      ),
      child: Row(
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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kPurple, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cycle',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6)),
                Text('${_phaseEmoji(phase)}  ${_phaseName(phase)}',
                    style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (data.lastPeriodDate != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: accent.withOpacity(0.35)),
              ),
              child: Text(
                data.isIrregular ? '⚡ Irregular' : '✓ Regular',
                style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  // ── Phase Hero Card ───────────────────────────────────────
  Widget _buildPhaseHeroCard(LunarCyclePhase phase, Color accent,
      CycleAnalysis analysis, DateTime? lpd) {
    final hasData = lpd != null && analysis.currentCycleDay > 0;
    final daysUntil = analysis.nextPeriodDate != null
        ? analysis.nextPeriodDate!
            .difference(DateTime.now())
            .inDays
            .clamp(0, 99)
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withOpacity(0.18),
                _kDeep.withOpacity(0.25),
                _kSurface.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withOpacity(0.28 + _pulseAnim.value * 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    accent.withOpacity(0.07 + _pulseAnim.value * 0.07),
                blurRadius: 24,
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phase orb + title
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        accent.withOpacity(0.35),
                        accent.withOpacity(0.08),
                      ]),
                      border: Border.all(
                          color: accent.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(
                              0.18 + _pulseAnim.value * 0.14),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(_phaseEmoji(phase),
                          style: const TextStyle(fontSize: 30)),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _phaseName(phase),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasData
                              ? 'Day ${analysis.currentCycleDay} of ${analysis.averageCycleLength}'
                              : 'No cycle data yet',
                          style: TextStyle(
                              color: accent.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Description
              Text(
                _phaseDescription(phase),
                style: TextStyle(
                    color: _kText.withOpacity(0.78),
                    fontSize: 13,
                    height: 1.65,
                    fontStyle: FontStyle.italic),
              ),
              if (hasData) ...[
                const SizedBox(height: 16),
                // Stat boxes
                Row(
                  children: [
                    Expanded(
                      child: _statBox(
                          accent, '${daysUntil}d', 'until next period'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statBox(accent,
                          'Day ${analysis.currentCycleDay}', 'current day'),
                    ),
                  ],
                ),
                // Window pills
                if (analysis.isInFertileWindow || analysis.isInPmsWindow) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (analysis.isInFertileWindow)
                        _heroPill(_kTeal, '🌿 Fertile Window Active'),
                      if (analysis.isInFertileWindow &&
                          analysis.isInPmsWindow)
                        const SizedBox(width: 8),
                      if (analysis.isInPmsWindow)
                        _heroPill(
                            Colors.deepOrangeAccent, '⚡ PMS Window'),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(Color accent, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: _kMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _heroPill(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 9.5, fontWeight: FontWeight.w700)),
    );
  }

  // ── AI Cycle Awareness Cards ──────────────────────────────
  Widget _buildInsightCards(LunarCyclePhase phase, Color accent) {
    final insights = _phaseInsights(phase);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Text('CYCLE AWARENESS',
              style: TextStyle(
                  color: _kMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4)),
        ),
        SizedBox(
          height: 112,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: insights.length,
            itemBuilder: (ctx, i) => Container(
              width: 218,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kSurface.withOpacity(0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withOpacity(0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(
                                color: accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text('Insight',
                        style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ]),
                  const SizedBox(height: 8),
                  Text(insights[i],
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: _kText.withOpacity(0.82),
                          fontSize: 12,
                          height: 1.55)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Calendar Section ──────────────────────────────────────
  Widget _buildCalendarSection(
      Color accent, DateTime? lpd, CycleAnalysis analysis) {
    final periodDur = analysis.averagePeriodDuration;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withOpacity(0.15)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
        child: Column(
          children: [
            // Legend
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 6,
                children: [
                  _legendDot(_kRose, 'Period'),
                  _legendDot(_kTeal, 'Fertile'),
                  _legendDot(_kGold, 'Ovulation'),
                  _legendDot(_kPurple, 'Today'),
                ],
              ),
            ),
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                _showLogDialog(selected);
              },
              onPageChanged: (focused) =>
                  setState(() => _focusedDay = focused),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
                leftChevronIcon: Icon(Icons.chevron_left_rounded,
                    color: accent, size: 22),
                rightChevronIcon: Icon(Icons.chevron_right_rounded,
                    color: accent, size: 22),
                headerPadding:
                    const EdgeInsets.symmetric(vertical: 8),
                decoration:
                    const BoxDecoration(color: Colors.transparent),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                    color: _kMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3),
                weekendStyle: TextStyle(
                    color: accent.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(
                    color: _kText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                weekendTextStyle: TextStyle(
                    color: _kText.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                outsideTextStyle: TextStyle(
                    color: _kMuted.withOpacity(0.3), fontSize: 12),
                todayDecoration: BoxDecoration(
                  color: _kPurple.withOpacity(0.28),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kPurple, width: 1.5),
                ),
                todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
                selectedDecoration: BoxDecoration(
                  color: accent.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 1.5),
                ),
                selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (ctx, day, _) => _calendarDay(
                    day, accent, lpd, periodDur, analysis,
                    isToday: false, isSelected: false),
                todayBuilder: (ctx, day, _) => _calendarDay(
                    day, accent, lpd, periodDur, analysis,
                    isToday: true, isSelected: false),
                selectedBuilder: (ctx, day, _) => _calendarDay(
                    day, accent, lpd, periodDur, analysis,
                    isToday: false, isSelected: true),
                outsideBuilder: (ctx, day, _) => Container(
                  margin: const EdgeInsets.all(3),
                  child: Center(
                    child: Text('${day.day}',
                        style: TextStyle(
                            color: _kMuted.withOpacity(0.22),
                            fontSize: 12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarDay(
    DateTime day,
    Color accent,
    DateTime? lpd,
    int periodDur,
    CycleAnalysis analysis, {
    required bool isToday,
    required bool isSelected,
  }) {
    final dtype = _getDayType(
      day,
      lpd,
      periodDur,
      analysis.ovulationDate,
      analysis.fertileWindowStart,
      analysis.fertileWindowEnd,
      analysis.nextPeriodDate,
    );

    Color? bg;
    Color? border;
    Color text = _kText;
    double bgOpacity = 0.22;

    if (isToday) {
      bg = _kPurple;
      border = _kPurple;
      text = Colors.white;
      bgOpacity = 0.3;
    } else if (isSelected) {
      bg = accent;
      border = accent;
      text = Colors.white;
      bgOpacity = 0.28;
    } else {
      switch (dtype) {
        case _DayType.period:
          bg = _kRose;
          text = Colors.white;
          break;
        case _DayType.ovulation:
          bg = _kGold;
          text = Colors.black87;
          bgOpacity = 0.55;
          break;
        case _DayType.fertile:
          bg = _kTeal;
          text = Colors.white;
          bgOpacity = 0.18;
          break;
        case _DayType.predictedPeriod:
          bg = _kRose;
          border = _kRose;
          bgOpacity = 0.08;
          break;
        default:
          break;
      }
    }

    final log = _logs[DateTime(day.year, day.month, day.day)];

    return Container(
      margin: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: bg != null ? bg.withOpacity(bgOpacity) : Colors.transparent,
        shape: BoxShape.circle,
        border: border != null
            ? Border.all(color: border.withOpacity(0.65), width: 1.2)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                  color: text,
                  fontSize: 12,
                  fontWeight: (isToday || bg != null)
                      ? FontWeight.w700
                      : FontWeight.w400),
            ),
          ),
          if (log != null)
            Positioned(
                bottom: 1,
                child: Text(log, style: const TextStyle(fontSize: 7))),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: color.withOpacity(0.72), shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: _kMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Stats Row ─────────────────────────────────────────────
  Widget _buildStatsRow(CycleAnalysis analysis, Color accent) {
    final hasData = analysis.currentCycleDay > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _statCard(accent, '${analysis.averageCycleLength}d',
              'Avg Cycle', Icons.loop_rounded),
          const SizedBox(width: 10),
          _statCard(accent, '${analysis.averagePeriodDuration}d',
              'Period Duration', Icons.water_drop_rounded),
          const SizedBox(width: 10),
          _statCard(accent, hasData ? '${analysis.regularityScore}%' : '—',
              'Regularity', Icons.bar_chart_rounded),
        ],
      ),
    );
  }

  Widget _statCard(
      Color accent, String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _kSurface.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _kMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── Wellness Recommendations ──────────────────────────────
  Widget _buildWellnessSection(LunarCyclePhase phase, Color accent) {
    final recs = _phaseRecs(phase);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WELLNESS FOR THIS PHASE',
              style: TextStyle(
                  color: _kMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
            children: recs
                .map((r) => Container(
                      decoration: BoxDecoration(
                        color: _kSurface.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: accent.withOpacity(0.12)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Text(r['icon']!,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(r['title']!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Text(r['desc']!,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: _kMuted, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Log Period Button ─────────────────────────────────────
  Widget _buildLogButton(Color accent, DateTime? lpd) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: _selectPeriodDate,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kDeep, accent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: accent.withOpacity(0.22),
                  blurRadius: 16,
                  spreadRadius: 0),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            lpd == null
                ? '+ Log My Period Start'
                : '🔄  Update Period Start',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2),
          ),
        ),
      ),
    );
  }

  // ── Pregnancy Mode View ───────────────────────────────────
  Widget _buildPregnancyMode(
      BuildContext context, LunarDataProvider data) {
    final topPad = MediaQuery.of(context).padding.top;
    const pink = Color(0xFFFF69B4);
    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _kPurple.withOpacity(0.22)),
                        ),
                        child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _kPurple,
                            size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text('Cycle Tracker',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      pink.withOpacity(0.12),
                      _kSurface.withOpacity(0.6),
                    ]),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: pink.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      const Text('🤱',
                          style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 18),
                      const Text('Pregnancy Mode Active',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(
                        "Your cycle tracker is paused while you're on your pregnancy journey. All your cycle history is safely preserved.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _kMuted,
                            fontSize: 13.5,
                            height: 1.65),
                      ),
                      const SizedBox(height: 22),
                      Text('Week ${data.currentPregnancyWeek}',
                          style: const TextStyle(
                              color: pink,
                              fontSize: 38,
                              fontWeight: FontWeight.w800)),
                      Text('of your pregnancy',
                          style:
                              TextStyle(color: _kMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Log Sheet — symptom logging bottom sheet
// ─────────────────────────────────────────────────────────────
class _LogSheet extends StatelessWidget {
  final DateTime day;
  final String? existingLog;
  final ValueChanged<String> onLog;

  const _LogSheet({
    required this.day,
    required this.existingLog,
    required this.onLog,
  });

  static const _kSurface = Color(0xFF160330);
  static const _kPurple = Color(0xFFAB5CF2);
  static const _kMuted = Color(0xFF9B89B8);

  static const _options = [
    {'emoji': '💖', 'label': 'Intimacy'},
    {'emoji': '💊', 'label': 'Medication'},
    {'emoji': '😊', 'label': 'Good Mood'},
    {'emoji': '😣', 'label': 'Pain'},
    {'emoji': '🤢', 'label': 'Nausea'},
    {'emoji': '💧', 'label': 'Spotting'},
    {'emoji': '😴', 'label': 'Fatigue'},
    {'emoji': '😰', 'label': 'Anxiety'},
  ];

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF160330),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
            top: BorderSide(color: Color(0x40AB5CF2), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _kPurple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Log for',
                      style: TextStyle(color: _kMuted, fontSize: 11)),
                  Text(_fmt(day),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              if (existingLog != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kPurple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: _kPurple.withOpacity(0.3)),
                  ),
                  child: Text('Logged: $existingLog',
                      style: const TextStyle(
                          color: _kPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _options.map((o) {
              final isSel = existingLog == o['emoji'];
              return GestureDetector(
                onTap: () => onLog(o['emoji']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel
                        ? _kPurple.withOpacity(0.2)
                        : _kSurface.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel
                          ? _kPurple.withOpacity(0.6)
                          : _kPurple.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(o['emoji']!,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(o['label']!,
                          style: TextStyle(
                              color: isSel ? Colors.white : _kMuted,
                              fontSize: 12,
                              fontWeight: isSel
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
