import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class PeriodScreen extends StatefulWidget {
  const PeriodScreen({super.key});

  @override
  State<PeriodScreen> createState() => _PeriodScreenState();
}

class _PeriodScreenState extends State<PeriodScreen> {
  DateTime? lastPeriodDate;
  int cycleLength = 28;

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        lastPeriodDate = picked;
      });
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

      fertileStart = ovulationDay!.subtract(const Duration(days: 4));

      fertileEnd = ovulationDay!.add(const Duration(days: 1));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Period Tracker"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                const Text(
                  "Last Period Date",
                  style: TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 20),
                Text(
                  lastPeriodDate == null
                      ? "No date selected"
                      : "${lastPeriodDate!.day}-${lastPeriodDate!.month}-${lastPeriodDate!.year}",
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: pickDate,
                  child: const Text("Select Date"),
                ),
                const SizedBox(height: 40),
                if (nextPeriod != null)
                  Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: DateTime.now(),
                      ),
                      const Text(
                        "Next Period",
                        style: TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${nextPeriod.day}-${nextPeriod.month}-${nextPeriod.year}",
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 20),
                      if (ovulationDay != null)
                        Text(
                          "Ovulation Day: ${ovulationDay!.day}-${ovulationDay!.month}-${ovulationDay!.year}",
                          style: const TextStyle(fontSize: 18),
                        ),
                      const SizedBox(height: 10),
                      if (fertileStart != null)
                        Text(
                          "Fertile Window: ${fertileStart!.day}-${fertileStart!.month} to ${fertileEnd!.day}-${fertileEnd!.month}",
                          style: const TextStyle(fontSize: 18),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
