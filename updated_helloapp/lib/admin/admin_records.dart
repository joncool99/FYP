import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRecordPage extends StatefulWidget {
  const AdminRecordPage({super.key});

  @override
  State<AdminRecordPage> createState() => _AdminRecordPageState();
}

class _AdminRecordPageState extends State<AdminRecordPage> {
  List<Map<String, dynamic>> coursesAttendance = [];

  @override
  void initState() {
    super.initState();
    _loadCoursesAttendance();
  }

  Future<void> _loadCoursesAttendance() async {
    try {
      QuerySnapshot coursesSnapshot =
          await FirebaseFirestore.instance.collection('Courses').get();

      List<Map<String, dynamic>> courses = [];

      for (var courseDoc in coursesSnapshot.docs) {
        String courseId = courseDoc.id;
        String courseName = courseDoc['courseName'];
        int totalLessons = 0;
        int totalPresent = 0;
        int totalAttendanceRecords = 0;

        QuerySnapshot lessonsSnapshot = await FirebaseFirestore.instance
            .collection('Courses')
            .doc(courseId)
            .collection('Lessons')
            .get();

        for (var lessonDoc in lessonsSnapshot.docs) {
          totalLessons++;
          QuerySnapshot attendanceSnapshot =
              await lessonDoc.reference.collection('Attendance').get();
          totalAttendanceRecords += attendanceSnapshot.docs.length;

          for (var attendanceDoc in attendanceSnapshot.docs) {
            if (attendanceDoc['status'] == 'present') {
              totalPresent++;
            }
          }
        }

        int attendanceRate = (totalLessons > 0 && totalAttendanceRecords > 0)
            ? ((totalPresent / totalAttendanceRecords) * 100).toInt()
            : 0;

        courses.add({
          'courseId': courseId,
          'courseName': courseName,
          'attendanceRate': attendanceRate,
        });
      }

      setState(() {
        coursesAttendance = courses;
      });
    } catch (e) {
      print('Failed to load data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Admin Attendance Data',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(9.0),
          child: Container(
            color: const Color.fromRGBO(22, 22, 151, 100),
            height: 5.0,
          ),
        ),
        
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Courses Attendance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: coursesAttendance.length,
                itemBuilder: (context, index) {
                  String courseName = coursesAttendance[index]['courseName'];
                  int attendanceRate =
                      coursesAttendance[index]['attendanceRate'];
                  return ListTile(
                    title: Text(courseName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    trailing: Text('$attendanceRate%',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
