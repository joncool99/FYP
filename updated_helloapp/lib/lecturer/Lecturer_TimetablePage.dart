import 'package:flutter/material.dart';

class Lecturer_TimetablePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Timetable'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Timetable'),
            // Add your timetable widget or design here
          ],
        ),
      ),
    );
  }
}
