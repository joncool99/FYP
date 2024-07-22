import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'SelectLessonPage.dart';

class LecturerRecordsPage extends StatefulWidget {
  const LecturerRecordsPage({super.key});

  @override
  State<LecturerRecordsPage> createState() => _LecturerRecordsPageState();
}

class _LecturerRecordsPageState extends State<LecturerRecordsPage> {
  List<Map<String, String>> teachingCourses = [];
  String? selectedCourseId;
  String? selectedCourseName;

  @override
  void initState() {
    super.initState();
    _loadTeachingCourses();
  }

  Future<void> _loadTeachingCourses() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user signed in')),
        );
        return;
      }

      String userEmail = user.email!;

      QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .where('lecturers', arrayContains: userEmail)
          .get();

      List<Map<String, String>> courses = coursesSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'courseId': doc.id,
          'courseName': data['courseName'] as String,
        };
      }).toList();

      setState(() {
        teachingCourses = courses;
      });
    } catch (e) {
      print('Failed to load courses: $e');
    }
  }

  void _navigateToSelectLesson(BuildContext context, String courseId, String courseName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectLessonPage(courseId: courseId, courseName: courseName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Attendance Data',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(9.0),
          child: Container(
            color: const Color.fromRGBO(22, 22, 151, 100),
            height: 5.0,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(50, 70, 50, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Course Attendance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: teachingCourses.length,
                itemBuilder: (context, index) {
                  String courseId = teachingCourses[index]['courseId']!;
                  String courseName = teachingCourses[index]['courseName']!;
                  return ListTile(
                    title: Text(courseName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    leading: Radio<String>(
                      value: courseId,
                      groupValue: selectedCourseId,
                      onChanged: (String? value) {
                        setState(() {
                          selectedCourseId = value!;
                          selectedCourseName = courseName;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                    onPressed: () {
                      if (selectedCourseId != null) {
                        _navigateToSelectLesson(
                            context, selectedCourseId!, selectedCourseName!);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(22, 22, 151, 100)),
                    child: const Text('Enter',
                        style: TextStyle(fontSize: 20, color: Colors.white))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
