import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodAnalyticsScreen extends StatelessWidget {
  const MoodAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> moodSpots = [
      FlSpot(0, 3),
      FlSpot(1, 4),
      FlSpot(2, 2),
      FlSpot(3, 5),
      FlSpot(4, 4),
      FlSpot(5, 3),
      FlSpot(6, 4),
    ];

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
              /// WEEKLY MOOD CHART

              const Text(
                "Weekly Mood",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: moodSpots,
                            isCurved: true,
                            color: Colors.purple,
                            barWidth: 4,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.purple.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// MOOD SCORE

              const Text(
                "Emotional Score",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.purple),
                  title: const Text("Mood Score"),
                  subtitle: const Text("Your emotional balance this week"),
                  trailing: const Text(
                    "78%",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// MOST COMMON MOOD

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
                  subtitle: const Text(
                    "You felt happy most days this week",
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// MOOD HISTORY

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
                    ListTile(
                      leading: Text("😢", style: TextStyle(fontSize: 24)),
                      title: Text("Yesterday"),
                      subtitle: Text("Low energy"),
                    ),
                    ListTile(
                      leading: Text("😊", style: TextStyle(fontSize: 24)),
                      title: Text("2 days ago"),
                      subtitle: Text("Positive mood"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// AI INSIGHT

              const Text(
                "AI Emotional Insight",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Card(
                color: Colors.purple.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "AI Insight:\n\nYour mood pattern shows slight drops mid-week. Try journaling or short breaks during stressful days.",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
