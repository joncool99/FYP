import 'package:flutter/material.dart';

class RecordGraphPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Attendance', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            // Replace with your attendance chart or widget
            Text('Generating attendace chart...\n'),
            Text('Present: 90%\nAbsent: 10%')
          ],
        ),
      ),
    );
  }
}
