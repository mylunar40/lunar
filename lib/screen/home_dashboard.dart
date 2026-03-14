import 'package:flutter/material.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// GREETING

              const Text(
                "Good Evening, Zaheer 🌙",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "How are you feeling today?",
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 30),

              /// TODAY MOOD CARD

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Text(
                    "😊",
                    style: TextStyle(fontSize: 30),
                  ),
                  title: const Text("Today's Mood"),
                  subtitle: const Text("Happy"),
                  trailing: ElevatedButton(
                    onPressed: () {},
                    child: const Text("Update"),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// PERIOD STATUS CARD

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.calendar_month,
                    color: Colors.pink,
                  ),
                  title: const Text("Cycle Status"),
                  subtitle: const Text(
                    "Next Period in 6 days",
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// QUICK ACTION TITLE

              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              /// QUICK ACTION GRID

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  actionCard("Mood", Icons.mood, Colors.orange),
                  actionCard("Journal", Icons.book, Colors.purple),
                  actionCard("AI Chat", Icons.smart_toy, Colors.blue),
                  actionCard("Period", Icons.calendar_today, Colors.pink),
                ],
              ),

              const SizedBox(height: 30),

              /// JOURNAL REMINDER

              Card(
                color: Colors.purple.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Journal Reminder",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Write your thoughts today ✍️",
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// HEALTH INSIGHT

              Card(
                color: Colors.pink.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Health Insight",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Drink more water and take short breaks today.",
                      ),
                    ],
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

/// QUICK ACTION CARD

Widget actionCard(
  String title,
  IconData icon,
  Color color,
) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 30,
          color: color,
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}
