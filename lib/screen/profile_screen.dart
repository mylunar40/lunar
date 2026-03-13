import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const CircleAvatar(
              radius: 50,
              child: Icon(
                Icons.person,
                size: 50,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "User Name",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Lunar App User",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            ListTile(
              leading: const Icon(Icons.mood),
              title: const Text("Mood History"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.book),
              title: const Text("Journal History"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text("Health Data"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {},
            ),

          ],
        ),
      ),
    );
  }
}