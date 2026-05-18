import 'package:flutter/material.dart';
import 'package:lunar/user_provider.dart';
import 'package:table_calendar/table_calendar.dart';

class PeriodScreen extends StatefulWidget {
  const PeriodScreen({super.key});

  @override
  State<PeriodScreen> createState() => _PeriodScreenState();
}

class _PeriodScreenState extends State<PeriodScreen> {
  DateTime? lastPeriodDate;
  int cycleLength = 28;

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  String mood = "😊";
  double painLevel = 0;

  List<String> selectedSymptoms = [];

  final List<String> symptoms = [
    "Cramps",
    "Headache",
    "Tired",
    "Bloating",
    "Cravings",
    "Back Pain"
  ];

  get provider => null;

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        lastPeriodDate = picked;
      });

      provider
          // ignore: use_build_context_synchronously
          .of<UserProvider>(context, listen: false)
          .updatePeriodDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? nextPeriod;
    DateTime? ovulationDay;
    DateTime? fertileStart;
    DateTime? fertileEnd;

    if (lastPeriodDate != null) {
      nextPeriod = lastPeriodDate!.add(Duration(days: cycleLength));

      ovulationDay = lastPeriodDate!.add(Duration(days: cycleLength - 14));

      fertileStart = ovulationDay.subtract(const Duration(days: 4));

      fertileEnd = ovulationDay.add(const Duration(days: 1));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lunar Period Tracker"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// CALENDAR

              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(selectedDay, day);
                },
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDay = selected;
                    focusedDay = focused;
                  });
                },
              ),

              const SizedBox(height: 20),

              /// LAST PERIOD

              const Text(
                "Last Period Date",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                lastPeriodDate == null
                    ? "No date selected"
                    : "${lastPeriodDate!.day}-${lastPeriodDate!.month}-${lastPeriodDate!.year}",
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: pickDate,
                child: const Text("Select Period Date"),
              ),

              const SizedBox(height: 30),

              /// CYCLE PREDICTION

              if (nextPeriod != null)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Cycle Prediction",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Next Period: ${nextPeriod.day}-${nextPeriod.month}-${nextPeriod.year}",
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Ovulation: ${ovulationDay!.day}-${ovulationDay.month}-${ovulationDay.year}",
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Fertile Window: ${fertileStart!.day}-${fertileStart.month} to ${fertileEnd!.day}-${fertileEnd.month}",
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              /// MOOD

              const Text(
                "Mood Today",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  moodButton("😊"),
                  moodButton("😢"),
                  moodButton("😡"),
                  moodButton("😴"),
                  moodButton("😍"),
                ],
              ),

              const SizedBox(height: 30),

              /// SYMPTOMS

              const Text(
                "Symptoms Today",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                children: symptoms.map((symptom) {
                  bool selected = selectedSymptoms.contains(symptom);

                  return FilterChip(
                    label: Text(symptom),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          selectedSymptoms.add(symptom);
                        } else {
                          selectedSymptoms.remove(symptom);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              /// PAIN LEVEL

              const Text(
                "Pain Level",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              Slider(
                value: painLevel,
                min: 0,
                max: 10,
                divisions: 10,
                label: painLevel.round().toString(),
                onChanged: (value) {
                  setState(() {
                    painLevel = value;
                  });
                },
              ),

              Text("Pain Level: ${painLevel.toInt()} / 10"),

              const SizedBox(height: 30),

              /// AI INSIGHT

              Card(
                color: Colors.purple[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "AI Insight:\n\nYour mood and pain levels may be related to PMS. Stay hydrated and get enough rest.",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget moodButton(String emoji) {
    return GestureDetector(
      onTap: () {
        setState(() {
          mood = emoji;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mood == emoji ? Colors.purple : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
