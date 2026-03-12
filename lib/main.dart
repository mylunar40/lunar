import 'package:flutter/material.dart';
import 'screen/home_screen.dart';

void main() {
  runApp(const LunarApp());
}

class LunarApp extends StatelessWidget {
  const LunarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Lunar",
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
