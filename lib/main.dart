import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LunarApp());
}

class LunarApp extends StatelessWidget {
  const LunarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final screens = [
    const HomeScreen(),
    const JournalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Journal",
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int days = 0;

  @override
  void initState() {
    super.initState();
    loadDate();
  }

  class _HomeScreenState extends State<HomeScreen> {

  int days = 0;

  @override
  void initState() {
    super.initState();
    loadDate();
  }

  // 👇 YAHI paste karna hai
  Future<void> loadDate() async {
      ...
  }
    final prefs = await SharedPreferences.getInstance();
    String? savedDate = prefs.getString("start_date");

    if (savedDate != null) {
      DateTime startDate = DateTime.parse(savedDate);
      setState(() {
        days = DateTime.now().difference(startDate).inDays;
      });
    }
  }

  Future<void> startHealing() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    await prefs.setString("start_date", now.toIso8601String());
    setState(() {
      days = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("No Contact Days",
                style: TextStyle(fontSize: 22)),
            const SizedBox(height: 10),
            Text("$days",
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold)),const SizedBox(height: 20),

LinearProgressIndicator(
  value: days / 30 > 1 ? 1 : days / 30,
  minHeight: 8,
),
Column(
  children: [
    if (days >= 7)
      const Text("🏅 7 Day Streak Unlocked!",
          style: TextStyle(color: Colors.white)),

    if (days >= 15)
      const Text("🥈 15 Day Warrior!",
          style: TextStyle(color: Colors.white)),

    if (days >= 30)
      const Text("🥇 30 Day Champion!",
          style: TextStyle(color: Colors.white))
  ],
),

const SizedBox(height: 20),
const SizedBox(height: 10),


            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: startHealing,
              child: const Text("Start Healing"),
            )
          ],
        ),
      ),
    );
  }
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadNote();
  }

  Future<void> loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    controller.text = prefs.getString("journal_note") ?? "";
  }

  Future<void> saveNote() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("journal_note", controller.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Note Saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Journal")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: "Write your thoughts...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveNote,
              child: const Text("Save Note"),
            )
          ],
        ),
      ),
    );
  }
}