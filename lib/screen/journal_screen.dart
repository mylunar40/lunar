import 'package:flutter/material.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController journalController = TextEditingController();

  String selectedMood = "😊";

  List<String> selectedTags = [];

  List<Map<String, dynamic>> entries = [];

  final List<String> tags = [
    "Breakup",
    "Stress",
    "Love",
    "Lonely",
    "Motivation",
    "Anxiety"
  ];

  void saveEntry() {
    if (journalController.text.isEmpty) return;

    setState(() {
      entries.insert(0, {
        "text": journalController.text,
        "mood": selectedMood,
        "date": DateTime.now()
      });
    });

    journalController.clear();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Journal saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lunar Journal"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// MOOD SELECTOR

              const Text(
                "How do you feel today?",
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

              /// JOURNAL TEXT

              const Text(
                "Write your thoughts",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: journalController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Today I feel...",
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// EMOTION TAGS

              const Text(
                "Tags",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                children: tags.map((tag) {
                  bool selected = selectedTags.contains(tag);

                  return FilterChip(
                    label: Text(tag),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          selectedTags.add(tag);
                        } else {
                          selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              /// SAVE BUTTON

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveEntry,
                  child: const Text("Save Entry"),
                ),
              ),

              const SizedBox(height: 30),

              /// AI REFLECTION

              Card(
                color: Colors.purple.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "AI Reflection:\n\nWriting your feelings helps release emotional stress. Keep journaling regularly.",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// PREVIOUS ENTRIES

              const Text(
                "Previous Entries",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Column(
                children: entries.map((entry) {
                  return Card(
                    child: ListTile(
                      leading: Text(
                        entry["mood"],
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(entry["text"]),
                      subtitle: Text(
                        entry["date"].toString().substring(0, 16),
                      ),
                    ),
                  );
                }).toList(),
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
          selectedMood = emoji;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selectedMood == emoji ? Colors.purple : Colors.grey[300],
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
