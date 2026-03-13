import 'package:flutter/material.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {

  int waterGlasses = 0;
  int sleepHours = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Tracker"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "Water Intake",
              style: TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 10),

            Text(
              "$waterGlasses glasses",
              style: const TextStyle(fontSize: 24),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  waterGlasses++;
                });
              },
              child: const Text("Add Water"),
            ),

            const SizedBox(height: 40),

            const Text(
              "Sleep Hours",
              style: TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 10),

            Text(
              "$sleepHours hours",
              style: const TextStyle(fontSize: 24),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  sleepHours++;
                });
              },
              child: const Text("Add Sleep"),
            ),

          ],
        ),
      ),
    );
  }
}