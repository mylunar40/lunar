import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? profileImage;

  String name = "Zaheer Khan";
  String email = "user@email.com";

  int moodEntries = 18;
  int journalEntries = 10;
  int healthScore = 78;

  int journalStreak = 5;
  int moodStreak = 7;

  /// PICK PROFILE IMAGE

  Future pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
    }
  }

  /// EDIT NAME

  void editName() {
    TextEditingController controller = TextEditingController(text: name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Name"),
          content: TextField(
            controller: controller,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  name = controller.text;
                });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lunar Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// PROFILE HEADER

            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage!)
                          : null,
                      child: profileImage == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: editName,
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(email),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// USER STATS

            const Text(
              "Your Stats",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.emoji_emotions),
                    title: const Text("Mood Entries"),
                    trailing: Text("$moodEntries"),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text("Journal Entries"),
                    trailing: Text("$journalEntries"),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.favorite),
                    title: const Text("Health Score"),
                    trailing: Text("$healthScore%"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// STREAKS

            const Text(
              "Streaks",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.local_fire_department),
                    title: const Text("Journal Streak"),
                    trailing: Text("$journalStreak days"),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.mood),
                    title: const Text("Mood Check Streak"),
                    trailing: Text("$moodStreak days"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// QUICK ACCESS

            const Text(
              "Quick Access",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text("Mood Analytics"),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: const Text("Journal History"),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: const Text("Period History"),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// SETTINGS

            const Text(
              "Settings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text("Notifications"),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.dark_mode),
                    title: Text("Dark Mode"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// LOGOUT

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Logout"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
