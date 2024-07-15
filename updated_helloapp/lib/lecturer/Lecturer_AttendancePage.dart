import 'package:flutter/material.dart';
import '../lecturer.dart';
import 'Lecturer_HomePage.dart';
import 'Lecturer_CaptureImgPage.dart';

class Lecturer_AttendancePage extends StatelessWidget {
  final ClassDetail classDetail;

  const Lecturer_AttendancePage({super.key, required this.classDetail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8.0),
          child: Container(
            color: Colors.blue, // Change the color as needed
            height: 4.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "${classDetail.name}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(classDetail.type),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 10.0),
                Text(classDetail.time),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 10.0),
                Text(classDetail.location),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Lecturer_CaptureImgPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                backgroundColor: const Color.fromARGB(255, 1, 124, 255),
              ),
              child: const Text(
                'Take Attendance',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
