import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PregnancyScreen extends StatefulWidget {
  const PregnancyScreen({super.key});

  @override
  State<PregnancyScreen> createState() => _PregnancyScreenState();
}

class _PregnancyScreenState extends State<PregnancyScreen> {
  DateTime? lastPeriod;
  DateTime? dueDate;

  int pregnancyWeek = 0;

  Map<int, String> babySize = {
    8: "Raspberry",
    12: "Lime",
    16: "Avocado",
    20: "Banana",
    24: "Corn",
    28: "Eggplant",
    32: "Coconut",
    36: "Papaya",
    40: "Watermelon"
  };

  Map<int, List<String>> symptoms = {
    12: ["Fatigue", "Mood swings", "Morning sickness"],
    20: ["Back pain", "Leg cramps"],
    28: ["Short breath", "Heartburn"],
    32: ["Braxton Hicks", "Back pain"],
    36: ["Pelvic pressure", "Swollen feet"]
  };

  Map<int, List<String>> tips = {
    12: ["Eat healthy", "Take folic acid"],
    20: ["Light exercise", "Stay hydrated"],
    28: ["Sleep left side", "Avoid stress"],
    32: ["Monitor baby kicks", "Eat calcium food"],
    36: ["Prepare hospital bag"]
  };

  Map<int, List<String>> checklist = {
    12: ["Blood test", "Doctor visit"],
    20: ["Ultrasound scan"],
    28: ["Glucose test"],
    32: ["Baby movement tracking"],
    36: ["Hospital preparation"]
  };

  void selectDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialDate: DateTime.now());

    if (picked != null) {
      setState(() {
        lastPeriod = picked;

        dueDate = picked.add(const Duration(days: 280));

        pregnancyWeek = DateTime.now().difference(picked).inDays ~/ 7;
      });
    }
  }

  String getBabySize() {
    int closestWeek = 8;

    babySize.forEach((week, value) {
      if (pregnancyWeek >= week) {
        closestWeek = week;
      }
    });

    return babySize[closestWeek] ?? "";
  }

  List<String> getSymptoms() {
    int closest = 12;

    symptoms.forEach((week, value) {
      if (pregnancyWeek >= week) {
        closest = week;
      }
    });

    return symptoms[closest] ?? [];
  }

  List<String> getTips() {
    int closest = 12;

    tips.forEach((week, value) {
      if (pregnancyWeek >= week) {
        closest = week;
      }
    });

    return tips[closest] ?? [];
  }

  List<String> getChecklist() {
    int closest = 12;

    checklist.forEach((week, value) {
      if (pregnancyWeek >= week) {
        closest = week;
      }
    });

    return checklist[closest] ?? [];
  }

  Widget buildSection(String title, List<String> data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...data.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text("• $e"),
                ))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pregnancy Tracker"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "Pregnancy Week",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            Text(
              "Week $pregnancyWeek",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (dueDate != null)
              Text(
                "Due Date: ${DateFormat('d MMM yyyy').format(dueDate!)}",
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: selectDate,
                child: const Text("Select Last Period Date")),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("Baby Development",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("Baby Size: ${getBabySize()}",
                        style: const TextStyle(fontSize: 16))
                  ],
                ),
              ),
            ),
            buildSection("Mother Symptoms", getSymptoms()),
            buildSection("Health Tips", getTips()),
            buildSection("Doctor Checklist", getChecklist()),
            const SizedBox(height: 10),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: const Icon(Icons.smart_toy),
                title: const Text("AI Pregnancy Assistant"),
                subtitle: const Text("Ask pregnancy questions"),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("AI coming soon")));
                },
              ),
            ),
            const SizedBox(height: 40)
          ],
        ),
      ),
    );
  }
}
