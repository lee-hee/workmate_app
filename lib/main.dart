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
      theme: ThemeData.dark().copyWith(
        //useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 147, 229, 250),
          brightness: Brightness.dark,
          surface: const Color.fromARGB(255, 42, 51, 59),
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 50, 58, 60),
      ),
      home: const BookingsCalendar(),
    );
  }
}
