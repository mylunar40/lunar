import 'package:flutter/material.dart';

class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sleep Tracker"),
      ),
      body: const Center(
        child: Text(
          "Sleep Tracker Coming Soon 😴",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
