import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  String? _selectedMood;

  /// SAVE MOOD
  Future<void> saveMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> moods = prefs.getStringList('mood_history') ?? [];

    moods.add(mood);

    await prefs.setStringList('mood_history', moods);
  }

  /// AI MESSAGE
  String getMoodMessage() {
    switch (_selectedMood) {
      case 'happy':
        return "That's wonderful! Keep spreading positivity.";

      case 'sad':
        return "It's okay to feel sad sometimes. I'm here with you.";

      case 'angry':
        return "Take a deep breath. Let's calm down together.";

      case 'loving':
        return "Love makes life beautiful ❤️";

      default:
        return "";
    }
  }

  /// MOOD DATA
  final Map<String, ({String emoji, String label, Color color})> _moods = {
    'happy': (emoji: '😊', label: 'Happy', color: Colors.amber),
    'sad': (emoji: '😔', label: 'Sad', color: Colors.blueGrey),
    'angry': (emoji: '😡', label: 'Angry', color: Colors.red),
    'loving': (emoji: '🥰', label: 'Loving', color: Colors.pink),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lunar Mood Check"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// TITLE

              const Text(
                "How are you feeling today?",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              /// SELECTED MOOD

              if (_selectedMood != null)
                Column(
                  children: [
                    AnimatedScale(
                      scale: 1,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _moods[_selectedMood]!.emoji,
                        style: const TextStyle(fontSize: 100),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _moods[_selectedMood]!.label,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _moods[_selectedMood]!.color,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      getMoodMessage(),
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

              const SizedBox(height: 40),

              /// MOOD BUTTONS

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _moods.entries.map((entry) {
                  final moodKey = entry.key;
                  final mood = entry.value;

                  final isSelected = _selectedMood == moodKey;

                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        _selectedMood = moodKey;
                      });

                      await saveMood(moodKey);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${mood.label} mood saved"),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? mood.color.withOpacity(0.3)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            mood.emoji,
                            style: const TextStyle(fontSize: 35),
                          ),
                          const SizedBox(height: 5),
                          Text(mood.label),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              /// VIEW ANALYTICS BUTTON

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/moodAnalytics");
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  "View Mood Analytics",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
