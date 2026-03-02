import 'package:flutter/material.dart';

void main() {
  runApp(const LunarApp());
}

class LunarApp extends StatelessWidget {
  const LunarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lunar',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "LUNAR",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          // 🌙 Moon Circle
          Center(
            child: Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purpleAccent.withOpacity(0.8),
                    Colors.deepPurple.shade900,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.6),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "🌙",
                  style: TextStyle(fontSize: 50),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          const Text(
            "How are you feeling today?",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 30),

          // Mood Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              MoodButton(emoji: "😊"),
              MoodButton(emoji: "😔"),
              MoodButton(emoji: "😡"),
              MoodButton(emoji: "🥰"),
            ],
          ),
        ],
      ),
    );
  }
}

class MoodButton extends StatelessWidget {
  final String emoji;

  const MoodButton({super.key, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}

