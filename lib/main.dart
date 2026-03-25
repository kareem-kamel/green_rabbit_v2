import 'package:flutter/material.dart';
import 'package:green_rabbit/features/main_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/news/news_screen.dart';

void main() {
  runApp(const GreenRabbitApp());
}

class GreenRabbitApp extends StatelessWidget {
  const GreenRabbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Rabbit',
      debugShowCheckedModeBanner: false,
      // Using your custom dark theme from app_theme.dart
      theme: darkTheme, 
      // Telling the app to open the News Screen first
      home: const MainScreen(), 
    );
  }
}