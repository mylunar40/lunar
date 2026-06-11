import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../core/providers/lunar_data_provider.dart';
import '../core/models/mood_model.dart';

class MoodAnalyticsScreen extends StatelessWidget {
  const MoodAnalyticsScreen({super.key});

  // Build FlSpot list from the last 7 logged mood entries (oldest → newest).
  static List<FlSpot> _buildSpots(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return [
        const FlSpot(0, 3), const FlSpot(1, 3), const FlSpot(2, 3),
        const FlSpot(3, 3), const FlSpot(4, 3), const FlSpot(5, 3),
        const FlSpot(6, 3),
      ];
    }
    final recent = entries.take(7).toList().reversed.toList();
    return List.generate(recent.length, (i) =>
        FlSpot(i.toDouble(), recent[i].score.toDouble()));
  }

  static String _moodScoreLabel(double avg) {
    final pct = ((avg / 5.0) * 100).round();
    if (pct >= 80) return 'Excellent 🌟';
    if (pct >= 60) return 'Good 😊';
    if (pct >= 40) return 'Okay 😐';
    return 'Needs Care 💜';
  }

  static String _patternInsight(String pattern) {
    switch (pattern) {
      case 'improving':   return 'Your mood is trending upward this week. Keep it up! 🌱';
      case 'declining':   return 'Your mood has dipped recently. Some self-care may help 💜';
      case 'fluctuating': return 'Your emotions have been mixed — that is completely normal 🌊';
      default:            return 'Your mood has been steady and balanced this week 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lunarData = context.watch<LunarDataProvider>();
    final entries = lunarData.moodEntries;
    final trend = lunarData.moodTrend;
    final moodSpots = _buildSpots(entries);
    final scorePct = ((trend.averageScore / 5.0) * 100).round();
    final dominantEmoji = entries.isNotEmpty ? entries.first.emoji : '😊';
    final dominantLabel = entries.isNotEmpty
        ? trend.dominantMood.name[0].toUpperCase() +
          trend.dominantMood.name.substring(1)
        : 'No data yet';
    final recent3 = entries.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lunar Mood Analytics"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated mood chart — real data
              TweenAnimationBuilder(
                duration: const Duration(seconds: 2),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, double value, child) {
                  return Container(
                    height: 220,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xff8E2DE2), Color(0xff4A00E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: entries.isEmpty
                        ? const Center(
                            child: Text(
                              'Log your first mood to see your chart 💜',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: 5,
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: moodSpots
                                      .map((s) =>
                                          FlSpot(s.x, s.y * value))
                                      .toList(),
                                  isCurved: true,
                                  barWidth: 4,
                                  color: Colors.white,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, _, __, ___) =>
                                        FlDotCirclePainter(
                                      radius: 5,
                                      color: Colors.white,
                                      strokeWidth: 2,
                                      strokeColor: Colors.purple,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.5),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  );
                },
              ),

              const SizedBox(height: 25),

              // Pattern insight — from MoodTrend
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _patternInsight(trend.pattern),
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 30),

              const Text('Emotional Score',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),

              const SizedBox(height: 15),

              Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.favorite, color: Colors.purple),
                  title: const Text('Mood Score'),
                  subtitle:
                      Text(_moodScoreLabel(trend.averageScore)),
                  trailing: Text(
                    '$scorePct%',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text('Most Frequent Mood',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),

              const SizedBox(height: 15),

              Card(
                child: ListTile(
                  leading: Text(dominantEmoji,
                      style: const TextStyle(fontSize: 28)),
                  title: Text(dominantLabel),
                  subtitle: entries.isEmpty
                      ? const Text('No mood logs yet')
                      : Text(
                          'Based on your last ${entries.length > 14 ? 14 : entries.length} entries'),
                ),
              ),

              const SizedBox(height: 30),

              const Text('Mood Timeline',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),

              const SizedBox(height: 15),

              Card(
                child: recent3.isEmpty
                    ? const ListTile(
                        title: Text('No entries yet'),
                        subtitle:
                            Text('Start logging your mood to see history'),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < recent3.length; i++) ...[
                            ListTile(
                              leading: Text(recent3[i].emoji,
                                  style: const TextStyle(fontSize: 24)),
                              title: Text(recent3[i].label),
                              subtitle: Text(
                                  _relativeDate(recent3[i].date)),
                            ),
                            if (i < recent3.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Just now';
    if (diff.inHours < 24) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}

