import 'package:flutter/material.dart';
import 'mood_screen.dart';
import 'journal_screen.dart';
import 'ai_chat_screen.dart';
import 'period_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LUNAR"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// PROFILE ROW
            Row(
              children: const [
                CircleAvatar(radius: 20),
                SizedBox(width: 10),
                Text("Hi Zaheer")
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
            Container(
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Health"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "AI"),
        ],
      ),
    );
  }

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
