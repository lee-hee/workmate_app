import 'package:flutter/material.dart';
import 'package:workmate_app/widgets/booking_calendar.dart';

void main() {
  runApp(const WorkMateApp());
}

class WorkMateApp extends StatelessWidget {
  const WorkMateApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkMate',
      theme: ThemeData.light().copyWith(
        //useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 97, 100, 101),
          brightness: Brightness.light,
          surface: const Color.fromARGB(255, 163, 175, 185),
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 209, 229, 244),
      ),
      home: TableComplexExample(),
    );
  }
}
