import 'package:flutter/material.dart';
import 'package:perceptionv1/screens/login_screen.dart';

void main() {
  runApp(const OfpAnalyzerApp());
}

class OfpAnalyzerApp extends StatelessWidget {
  const OfpAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OFP Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const LoginScreen(),
    );
  }
}
