import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class MoodScreen extends StatefulWidget {
  Future<void> saveMood(int mood) async {
  final prefs = await SharedPreferences.getInstance();

  List<String> moods = prefs.getStringList('mood_history') ?? [];

  moods.add(mood.toString());

  await prefs.setStringList('mood_history', moods);
}
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {

Future<void> saveMood(int mood) async {

  final prefs = await SharedPreferences.getInstance();

  List<String> moods = prefs.getStringList('mood_history') ?? [];

  moods.add(mood.toString());

  await prefs.setStringList('mood_history', moods);
  
}
  String? _selectedMood;
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

  // You can later use this selected mood to save it, show recommendations, etc.
  final Map<String, ({String emoji, String label, Color color})> _moods = {
    'happy': (emoji: '😊', label: 'Happy', color: Colors.amber),
    'sad': (emoji: '😔', label: 'Sad', color: Colors.blueGrey),
    'angry': (emoji: '😡', label: 'Angry', color: Colors.red),
    'loving': (emoji: '🥰', label: 'Loving', color: Colors.pink),
    // Feel free to add more: tired, anxious, excited, etc.
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("How are you feeling?"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "How are you feeling today?",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 50),

              // Show selected mood (if any) with bigger emoji & label
              if (_selectedMood != null) ...[
                AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    children: [
                      Text(
                        _moods[_selectedMood]!.emoji,
                        style: const TextStyle(fontSize: 100),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _moods[_selectedMood]!.label,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: _moods[_selectedMood]!.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
              ],

              // Mood selection buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _moods.entries.map((entry) {
                  final moodKey = entry.key;
                  final mood = entry.value;
                  final isSelected = _selectedMood == moodKey;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = moodKey;
                      });
                      // Optional: you can add sound, save to storage, navigate, etc.
                      // Example: HapticFeedback.lightImpact();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? mood.color.withOpacity(0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? mood.color : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            mood.emoji,
                            style: const TextStyle(fontSize: 60),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? mood.color : null,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 60),

              // Optional next step button (appears after selection)
              if (_selectedMood != null)
                ElevatedButton.icon(
                  onPressed: () {
                    // → Navigate to next screen, save mood, show advice, etc.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "Great! You're feeling ${_moods[_selectedMood]!.label} today ❤️"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Continue"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
