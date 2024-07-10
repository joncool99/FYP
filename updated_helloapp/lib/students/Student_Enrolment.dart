import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentEnrollmentScreen extends StatefulWidget {
  @override
  _StudentEnrollmentScreenState createState() =>
      _StudentEnrollmentScreenState();
}

class _StudentEnrollmentScreenState extends State<StudentEnrollmentScreen> {
  List<String> _availableCourses = [];
  List<String> _enrolledCourses = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableCourses();
    _loadEnrolledCourses();
  }

  Future<void> _loadAvailableCourses() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('Courses').get();
    List<String> courses =
        snapshot.docs.map((doc) => doc['courseName'] as String).toList();
    setState(() {
      _availableCourses = courses;
    });
  }

  Future<void> _loadEnrolledCourses() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Students')
        .doc('studentId')
        .collection('EnrolledCourses')
        .get();
    List<String> courses =
        snapshot.docs.map((doc) => doc['courseName'] as String).toList();
    setState(() {
      _enrolledCourses = courses;
    });
  }

  Future<void> _enrollCourse(String courseName) async {
    await FirebaseFirestore.instance
        .collection('Students')
        .doc('studentId')
        .collection('EnrolledCourses')
        .doc(courseName)
        .set({
      'courseName': courseName,
    });
    setState(() {
      _enrolledCourses.add(courseName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enroll in Courses'),
      ),
      body: ListView.builder(
        itemCount: _availableCourses.length,
        itemBuilder: (context, index) {
          String courseName = _availableCourses[index];
          bool isEnrolled = _enrolledCourses.contains(courseName);
          return ListTile(
            title: Text(courseName),
            trailing: isEnrolled
                ? Icon(Icons.check, color: Colors.green)
                : IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      _enrollCourse(courseName);
                    },
                  ),
          );
        },
      ),
    );
  }
}
