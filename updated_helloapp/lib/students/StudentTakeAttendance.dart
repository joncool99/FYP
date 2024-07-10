import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TakeAttendancePage extends StatelessWidget {
  final String courseName;
  final String courseId;
  final String lessonName;
  final String startTime;
  final String endTime;
  final String location;

  const TakeAttendancePage({
    Key? key,
    required this.courseName,
    required this.courseId,
    required this.lessonName,
    required this.startTime,
    required this.endTime,
    required this.location,
  }) : super(key: key);

  Future<void> _takeAttendance(BuildContext context) async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user signed in')),
        );
        return;
      }

      String userEmail = user.email!;

      // Create or update attendance record in the database
      await FirebaseFirestore.instance
          .collection('Courses')
          .doc(courseId)
          .collection('Lessons')
          .doc(lessonName)
          .collection('Attendance')
          .doc(userEmail)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'present',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance taken for $lessonName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take attendance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Take Attendance', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container(
            color: Colors.blue[900],
            height: 3.0,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.fromLTRB(60, 40, 30, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('$courseId - $lessonName',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(courseName, style: const TextStyle(fontSize: 18)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            const Icon(Icons.access_time, size: 18),
                            const SizedBox(width: 5),
                            Text('$startTime - $endTime',
                                style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            const Icon(Icons.place, size: 18),
                            const SizedBox(width: 5),
                            Text(location,
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.only(left: 0),
                          child:
                              Image.asset('images/face_icon.png', width: 300),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _takeAttendance(context),
              child: Text('Take Attendance', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                minimumSize: Size(160, 50),
              ),
            ),
          ),
          SizedBox(height: 150)
        ],
      ),
    );
  }
}
