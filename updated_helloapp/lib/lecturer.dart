import 'package:flutter/material.dart';
import 'package:helloapp/attendance/captureImages.dart';
import 'package:helloapp/attendance/uploadImages.dart';
import 'register.dart';
// Ensure this file is created for the update functionality

class LecturerPage extends StatefulWidget {
  @override
  _LecturerPageState createState() => _LecturerPageState();
}

class _LecturerPageState extends State<LecturerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LECTURERS'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8.0),
          child: Container(
            color: Colors.blue, // Change the color as needed
            height: 4.0,
          ),
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 90),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const UploadImagesPage(imagePath: '')),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              backgroundColor: const Color.fromARGB(255, 1, 124, 255),
            ),
            child: const Text(
              'Attendance',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CaptureImagePage()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              backgroundColor: const Color.fromARGB(255, 1, 124, 255),
            ),
            child: const Text(
              'Update info',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}
