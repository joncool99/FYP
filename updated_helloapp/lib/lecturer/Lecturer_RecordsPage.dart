import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LecturerRecordsPage extends StatefulWidget {
  const LecturerRecordsPage({super.key});

  @override
  State<LecturerRecordsPage> createState() => _LecturerRecordsPageState();
}

class _LecturerRecordsPageState extends State<LecturerRecordsPage> {
  List<CourseDetail> courseDetails = [];

  @override
  void initState() {
    super.initState();
    _fetchCourseDetails();
  }

  Future<void> _fetchCourseDetails() async {
    QuerySnapshot courseSnapshot =
        await FirebaseFirestore.instance.collection('Courses').get();
    List<CourseDetail> courses = courseSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return CourseDetail(
        courseId: doc.id,
        courseName: data['courseName'] ?? 'Unknown Course',
      );
    }).toList();

    for (var course in courses) {
      await _fetchLessons(course);
    }

    setState(() {
      courseDetails = courses;
    });
  }

  Future<void> _fetchLessons(CourseDetail course) async {
    QuerySnapshot lessonSnapshot = await FirebaseFirestore.instance
        .collection('Courses')
        .doc(course.courseId)
        .collection('Lessons')
        .get();

    List<LessonDetail> lessons = lessonSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return LessonDetail(
        lessonId: doc.id,
        lessonName: data['lessonName'] ?? 'Unknown Lesson',
        lessonDate: (data['date'] as Timestamp).toDate(),
        students: [],
      );
    }).toList();

    for (var lesson in lessons) {
      await _fetchStudents(course.courseId, lesson);
    }

    setState(() {
      course.lessons = lessons;
    });
  }

  Future<void> _fetchStudents(String courseId, LessonDetail lesson) async {
    try {
      QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(courseId)
          .collection('Lessons')
          .doc(lesson.lessonId)
          .collection('Attendance')
          .get();

      List<Map<String, dynamic>> students = [];

      for (var doc in studentSnapshot.docs) {
        var attendanceData = doc.data() as Map<String, dynamic>;
        var email = doc.id;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(email)
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          students.add({
            'email': email,
            'firstName': userData['firstName'] ?? 'Unknown',
            'lastName': userData['lastName'] ?? 'Unknown',
            'studentId': userData['studentId'] ?? 'Unknown',
            'attendance': attendanceData['status'] == 'present',
          });
        }
      }

      setState(() {
        lesson.students = students;
      });
    } catch (e) {
      print('Failed to load students: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Attendance Records',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(9.0),
            child: Container(
              color: const Color.fromRGBO(22, 22, 151, 100),
              height: 5.0,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: courseDetails.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: courseDetails.length,
                itemBuilder: (context, index) {
                  var course = courseDetails[index];
                  return CourseCard(course: course);
                },
              ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final CourseDetail course;

  const CourseCard({Key? key, required this.course}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        title: Text(
          '${course.courseName} (${course.courseId})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        children: course.lessons.map((lesson) {
          int presentCount =
              lesson.students.where((s) => s['attendance'] == true).length;
          return ListTile(
            title: Text(
                '${lesson.lessonName} (${DateFormat('dd-MM-yyyy').format(lesson.lessonDate)})'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Present: $presentCount / ${lesson.students.length}'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount: lesson.students.length,
                    itemBuilder: (context, index) {
                      var student = lesson.students[index];
                      return Text(
                        '${student['firstName']} ${student['lastName']} (${student['studentId']}) - ${student['attendance'] ? 'Present' : 'Absent'}',
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CourseDetail {
  final String courseId;
  final String courseName;
  List<LessonDetail> lessons;

  CourseDetail({
    required this.courseId,
    required this.courseName,
    this.lessons = const [],
  });
}

class LessonDetail {
  final String lessonId;
  final String lessonName;
  final DateTime lessonDate;
  List<Map<String, dynamic>> students;

  LessonDetail({
    required this.lessonId,
    required this.lessonName,
    required this.lessonDate,
    this.students = const [],
  });
}
