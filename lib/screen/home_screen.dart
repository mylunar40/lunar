import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mood_screen.dart';
import 'mood_analytics_screen.dart';
import 'journal_screen.dart';
import 'ai_chat_screen.dart';
import 'period_screen.dart';
import 'profile_screen.dart';
import 'health_screen.dart';
import 'ai_voice_screen.dart';
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
  actions: [
    IconButton(
      icon: const Icon(Icons.person),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
      },
    ),
  ],
),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// AI support message
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8E2DE2),
                    Color(0xFF4A00E0),
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

            const SizedBox(height: 20),

            /// SEARCH BAR
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Search",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// BIG CARD
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
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    "Mood Analytics",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// SMALL CARDS
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
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
                          builder: (context) => const AiChatScreen(),
                        ),
                      );
                    },
                    child: dashboardCard("AI Chat"),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PeriodScreen(),
                        ),
                      );
                    },
                    child: dashboardCard("Period"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),

      /// BOTTOM BAR
      bottomNavigationBar: BottomNavigationBar(

  onTap: (index) {
if (index == 2) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AiVoiceScreen(),
    ),
  );
}
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HealthScreen(),
        ),
      );
    }

  },

  items: const [

    BottomNavigationBarItem(
        icon: Icon(Icons.home), label: "Home"),

    BottomNavigationBarItem(
        icon: Icon(Icons.favorite), label: "Health"),

    BottomNavigationBarItem(
        icon: Icon(Icons.chat), label: "AI"),

  ],
),
    ); // end Scaffold
  } // end build

  /// CARD WIDGET
  Widget dashboardCard(String title) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(title),
      ),
    );
  }
}