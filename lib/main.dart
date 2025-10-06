import 'package:flutter/material.dart';
import 'package:qadaa_prayer_tracker/Views/qadaa_missed.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QadaaMissed(),
    );
  }
}