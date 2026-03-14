import 'package:flutter/material.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  int water = 0;
  int sleep = 7;
  int steps = 4200;

  void addWater() {
    setState(() {
      water++;
    });
  }

  void addSteps() {
    setState(() {
      steps += 500;
    });
  }

  void addSleep() {
    setState(() {
      sleep++;
    });
  }

  @override
  Widget build(BuildContext context) {
    double waterProgress = water / 8;
    double sleepProgress = sleep / 8;
    double stepsProgress = steps / 10000;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lunar Health"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daily Wellness",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// WATER TRACKER

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.water_drop, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          "Water Intake",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: waterProgress,
                      minHeight: 10,
                    ),
                    const SizedBox(height: 10),
                    Text("$water / 8 glasses"),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: addWater,
                      child: const Text("Drink Water"),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// SLEEP TRACKER

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bedtime, color: Colors.purple),
                        SizedBox(width: 10),
                        Text(
                          "Sleep Tracker",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: sleepProgress,
                      minHeight: 10,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 10),
                    Text("$sleep / 8 hours"),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: addSleep,
                      child: const Text("Add Sleep Hour"),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// STEP TRACKER

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.directions_walk, color: Colors.green),
                        SizedBox(width: 10),
                        Text(
                          "Daily Steps",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: stepsProgress,
                      minHeight: 10,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    Text("$steps / 10000 steps"),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: addSteps,
                      child: const Text("Add Steps"),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// HEALTH TIPS

            const Text(
              "Health Tips",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              color: Colors.pink.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Tip: Drink enough water and maintain a regular sleep schedule. It helps balance mood and hormones.",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// AI HEALTH INSIGHT

            const Text(
              "AI Health Insight",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              color: Colors.purple.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "AI Insight: Your activity looks moderate today. A short walk or meditation can improve emotional balance.",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
