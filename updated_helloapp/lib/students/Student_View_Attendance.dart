import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  List<Map<String, String>> enrolledCourses = [];
  String? selectedCourseId;
  String? selectedCourseName;
  int overallAttendanceRate = -1;

  @override
  void initState() {
    super.initState();
    _loadEnrolledCourses();
  }

  Future<void> _loadEnrolledCourses() async {
    try {
      //get current user via their email
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user signed in')),
        );
        return;
      }

      String userEmail = user.email!;
      print('User email: $userEmail'); // Debug print

      QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .where('students', arrayContains: userEmail)
          .get();

      List<Map<String, String>> courses = coursesSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'courseId': doc.id,
          'courseName': data['courseName'] as String,
        };
      }).toList();

      print('Enrolled courses: $courses'); // Debug print

      int totalLessons = 0;
      int totalPresent = 0;

      for (var course in courses) {
        String courseId = course['courseId']!;
        int coursePresent = 0;
        int courseLessons = 0;

        QuerySnapshot lessonsSnapshot = await FirebaseFirestore.instance
            .collection('Courses')
            .doc(courseId)
            .collection('Lessons')
            .get();

        for (var lessonDoc in lessonsSnapshot.docs) {
          courseLessons++;
          totalLessons++;

          // Check if the student is marked present in this lesson
          DocumentSnapshot attendanceDoc = await lessonDoc.reference
              .collection('Attendance')
              .doc(userEmail)
              .get();

          if (attendanceDoc.exists && attendanceDoc['status'] == 'present') {
            coursePresent++;
            totalPresent++;
          }
        }
      }

      // Calculate overall attendance rate
      int overallRate = (totalLessons > 0)
          ? ((totalPresent / totalLessons) * 100).toInt()
          : 0;

      setState(() {
        enrolledCourses = courses;
        overallAttendanceRate = overallRate;
      });
    } catch (e) {
      print('Failed to load data: $e');
    }
  }

  void _navigateToCourseAttendance(
      BuildContext context, String courseId, String courseName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CourseAttendancePage(courseId: courseId, courseName: courseName),
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
                itemCount: enrolledCourses.length,
                itemBuilder: (context, index) {
                  String courseId = enrolledCourses[index]['courseId']!;
                  String courseName = enrolledCourses[index]['courseName']!;
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
                        _navigateToCourseAttendance(
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
            const SizedBox(height: 10),
            const Text('Overall Attendance Rate',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            Container(
              height: 25,
              width: double.infinity,
              color: const Color.fromRGBO(217, 217, 217, 100),
              child: Center(
                child: Text('$overallAttendanceRate%',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

//new class for course attendance page
class CourseAttendancePage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const CourseAttendancePage(
      {Key? key, required this.courseId, required this.courseName})
      : super(key: key);

  @override
  _CourseAttendancePageState createState() => _CourseAttendancePageState();
}

class _CourseAttendancePageState extends State<CourseAttendancePage> {
  List<Map<String, dynamic>> attendanceDetails = [];

  @override
  void initState() {
    super.initState();
    _loadAttendanceDetails();
  }

  Future<void> _loadAttendanceDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user signed in')),
        );
        return;
      }

      String userEmail = user.email!;
      QuerySnapshot lessonsSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .collection('Lessons')
          .get();

      List<Map<String, dynamic>> details = [];

      for (var lessonDoc in lessonsSnapshot.docs) {
        var data = lessonDoc.data() as Map<String, dynamic>;
        DocumentSnapshot attendanceDoc = await lessonDoc.reference
            .collection('Attendance')
            .doc(userEmail)
            .get();

        DateTime lessonDate = (data['date'] as Timestamp).toDate();
        String formattedDate = DateFormat('yyyy-MM-dd').format(lessonDate);
        String startTime = data['startTime'];
        String endTime = data['endTime'];

        // Convert startTime and endTime to HH:mm format
        String formattedStartTime = _formatTime(startTime);
        String formattedEndTime = _formatTime(endTime);

        details.add({
          'date': formattedDate,
          'present':
              attendanceDoc.exists && attendanceDoc['status'] == 'present'
                  ? 'Yes'
                  : 'No',
          'startTime': formattedStartTime,
          'endTime': formattedEndTime,
        });
      }

      setState(() {
        attendanceDetails = details;
      });
    } catch (e) {
      print('Failed to load attendance details: $e');
    }
  }

  String _formatTime(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return DateFormat('HH:mm').format(DateTime(0, 1, 1, hours, minutes));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.courseId} Attendance Details'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Present')),
              DataColumn(label: Text('Start Time')),
              DataColumn(label: Text('End Time')),
            ],
            rows: attendanceDetails.map((detail) {
              return DataRow(cells: [
                DataCell(Text(detail['date'])),
                DataCell(Text(detail['present'])),
                DataCell(Text(detail['startTime'])),
                DataCell(Text(detail['endTime'])),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
