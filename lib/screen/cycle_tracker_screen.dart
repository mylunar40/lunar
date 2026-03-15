import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CycleTrackerScreen extends StatefulWidget {
  const CycleTrackerScreen({super.key});

  @override
  State<CycleTrackerScreen> createState() => _CycleTrackerScreenState();
}

class _CycleTrackerScreenState extends State<CycleTrackerScreen> {
  DateTime today = DateTime.now();
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  DateTime? lastPeriodDate;

  int cycleLength = 28;
  int periodLength = 5;

  DateTime? ovulationDay;
  List<DateTime> fertileDays = [];

  Map<DateTime, String> logs = {};

  @override
  void initState() {
    super.initState();
  }

  void calculateCycle() {
    if (lastPeriodDate == null) return;

    ovulationDay = lastPeriodDate!.add(Duration(days: cycleLength - 14));

    fertileDays.clear();

    for (int i = -4; i <= 1; i++) {
      fertileDays.add(ovulationDay!.add(Duration(days: i)));
    }
  }

  int getCycleDay() {
    if (lastPeriodDate == null) return 0;

    return today.difference(lastPeriodDate!).inDays + 1;
  }

  int daysUntilNext() {
    if (lastPeriodDate == null) return 0;

    DateTime next = lastPeriodDate!.add(Duration(days: cycleLength));

    return next.difference(today).inDays;
  }

  bool isPeriodDay(DateTime day) {
    if (lastPeriodDate == null) return false;

    for (int i = 0; i < periodLength; i++) {
      DateTime d = lastPeriodDate!.add(Duration(days: i));

      if (d.year == day.year && d.month == day.month && d.day == day.day) {
        return true;
      }
    }

    return false;
  }

  bool isFertile(DateTime day) {
    for (var d in fertileDays) {
      if (d.year == day.year && d.month == day.month && d.day == day.day) {
        return true;
      }
    }

    return false;
  }

  bool isOvulation(DateTime day) {
    if (ovulationDay == null) return false;

    return ovulationDay!.year == day.year &&
        ovulationDay!.month == day.month &&
        ovulationDay!.day == day.day;
  }

  void selectPeriodDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialDate: today);

    if (picked != null) {
      lastPeriodDate = picked;

      calculateCycle();

      setState(() {});
    }
  }

  void addLog(DateTime day, String type) {
    logs[DateTime(day.year, day.month, day.day)] = type;

    setState(() {});
  }

  Widget buildDay(DateTime day) {
    Color? color;

    if (isPeriodDay(day))
      color = Colors.red;
    else if (isOvulation(day))
      color = Colors.blue;
    else if (isFertile(day)) color = Colors.orange;

    String? log = logs[DateTime(day.year, day.month, day.day)];

    return Container(
      margin: const EdgeInsets.all(4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Stack(
        children: [
          Center(
            child: Text(
              "${day.day}",
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (log != null)
            Positioned(
              bottom: 2,
              right: 2,
              child: Text(
                log,
                style: const TextStyle(fontSize: 14),
              ),
            )
        ],
      ),
    );
  }

  void showLogDialog(DateTime day) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SizedBox(
            height: 220,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text("Add Log", style: TextStyle(fontSize: 20)),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () {
                      addLog(day, "❤️");
                      Navigator.pop(context);
                    },
                    child: const Text("Sex")),
                ElevatedButton(
                    onPressed: () {
                      addLog(day, "💊");
                      Navigator.pop(context);
                    },
                    child: const Text("Pill")),
                ElevatedButton(
                    onPressed: () {
                      addLog(day, "🤒");
                      Navigator.pop(context);
                    },
                    child: const Text("Symptoms")),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cycle Tracker"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 10, color: Colors.pink),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Current Cycle"),
                    Text(
                      "Day ${getCycleDay()}",
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    Text("${daysUntilNext()} days until next period")
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("Cycle Insights",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("Last Period: $lastPeriodDate"),
                    Text("Ovulation: $ovulationDay"),
                    if (fertileDays.isNotEmpty)
                      Text(
                          "Fertile Window: ${fertileDays.first} - ${fertileDays.last}")
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TableCalendar(
              focusedDay: focusedDay,
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              selectedDayPredicate: (day) {
                return isSameDay(selectedDay, day);
              },
              onDaySelected: (selected, focused) {
                selectedDay = selected;
                focusedDay = focused;

                showLogDialog(selected);

                setState(() {});
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focused) {
                  return buildDay(day);
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: selectPeriodDate,
                child: const Text("Select Last Period Date")),
            const SizedBox(height: 40)
          ],
        ),
      ),
    );
  }
}
