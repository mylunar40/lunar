import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lunar/screen/pregnancy_screen.dart';
import 'package:lunar/screen/cycle_tracker_screen.dart';
import 'mood_screen.dart';
import 'mood_analytics_screen.dart';
import 'journal_screen.dart';
import 'sleep_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String todayMood = "No mood yet";

  Future<void> loadTodayMood() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> moods = prefs.getStringList('mood_history') ?? [];

    if (moods.isNotEmpty) {
      setState(() {
        todayMood = moods.last;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadTodayMood();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lunar"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// AI MESSAGE

            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8E2DE2),
                    Color.fromARGB(255, 0, 224, 216),
                  ],
                ),
              ),
              child: const Text(
                "AI Support Message\n\nYou are doing better than you think. Keep going 🌙",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            /// PROFILE ROW

            Row(
              children: const [
                CircleAvatar(radius: 20),
                SizedBox(width: 10),
                Text(
                  "Hi Zaheer 👋",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// SEARCH BAR

            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(241, 242, 245, 1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Search",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            /// MOOD ANALYTICS CARD

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MoodAnalyticsScreen(),
                  ),
                );
              },
              child: Container(
                height: 75,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.purple,
                      Colors.blue,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    "Mood Analytics",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// GRID CARDS

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MoodScreen(),
                        ),
                      );
                    },
                    child: dashboardCard("Mood"),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JournalScreen(),
                        ),
                      );
                    },
                    child: dashboardCard("Journal"),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CycleTrackerScreen(),
                        ),
                      );
                    },
                    child: dashboardCard("Cycle"),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PregnancyScreen(),
                        ),
                      );
                    },
                    child: dashboardCard("Pregnancy"),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SleepScreen(),
                        ),
                      );
                    },
                    child: dashboardCard("sleep"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboardCard(String title) {
    return SizedBox(
        height: 110,
        child: Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ));
  }
}
