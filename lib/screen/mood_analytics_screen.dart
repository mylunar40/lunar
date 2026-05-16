import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodAnalyticsScreen extends StatefulWidget {
  const MoodAnalyticsScreen({super.key});

  @override
  State<MoodAnalyticsScreen> createState() => _MoodAnalyticsScreenState();
}

class _MoodAnalyticsScreenState extends State<MoodAnalyticsScreen> {
  List<FlSpot> moodSpots = [
    FlSpot(0, 3),
    FlSpot(1, 4),
    FlSpot(2, 2),
    FlSpot(3, 5),
    FlSpot(4, 4),
    FlSpot(5, 3),
    FlSpot(6, 4),
  ];

  @override
  Widget build(BuildContext context) {
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
              /// Animated Graph
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
                        colors: [
                          Color(0xff8E2DE2),
                          Color(0xff4A00E0),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: moodSpots
                                .map((spot) => FlSpot(spot.x, spot.y * value))
                                .toList(),
                            isCurved: true,
                            barWidth: 4,
                            color: Colors.white,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 5,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: Colors.purple,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.5),
                                  Colors.transparent
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

              /// AI Insight
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Your mood improved mid-week. Try activities that bring calm and happiness.",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 30),

              /// Emotional Score
              const Text(
                "Emotional Score",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.favorite,
                    color: Colors.purple,
                  ),
                  title: const Text("Mood Score"),
                  subtitle: const Text("Your emotional balance this week"),
                  trailing: const Text(
                    "78%",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// Most Frequent Mood
              const Text(
                "Most Frequent Mood",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Card(
                child: ListTile(
                  leading: const Text(
                    "😊",
                    style: TextStyle(fontSize: 28),
                  ),
                  title: const Text("Happy"),
                  subtitle: const Text("You felt happy most days this week"),
                ),
              ),

              const SizedBox(height: 30),

              /// Mood Timeline
              const Text(
                "Mood Timeline",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Card(
                child: Column(
                  children: const [
                    ListTile(
                      leading: Text("😊", style: TextStyle(fontSize: 24)),
                      title: Text("Today"),
                      subtitle: Text("Feeling good"),
                    ),
                    Divider(),
                    ListTile(
                      leading: Text("😐", style: TextStyle(fontSize: 24)),
                      title: Text("Yesterday"),
                      subtitle: Text("Neutral mood"),
                    ),
                    Divider(),
                    ListTile(
                      leading: Text("😢", style: TextStyle(fontSize: 24)),
                      title: Text("2 days ago"),
                      subtitle: Text("A bit sad"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
