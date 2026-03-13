import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodAnalyticsScreen extends StatelessWidget {
  const MoodAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mood Analytics"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: [
                  FlSpot(0, 3),
                  FlSpot(1, 4),
                  FlSpot(2, 2),
                  FlSpot(3, 5),
                  FlSpot(4, 4),
                  FlSpot(5, 3),
                  FlSpot(6, 4),
                ],
                isCurved: true,
                barWidth: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}