import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        courseId: data['courseId'] ?? 'N/A', // Default value if null
        courseName: data['courseName'] ?? 'Unknown Course', // Default value if null
      );
    }).toList();

    for (var course in courses) {
      QuerySnapshot lessonSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(course.courseId)
          .collection('Lessons')
          .get();

      List<LessonDetail> lessons = lessonSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return LessonDetail(
          lessonId: doc.id,
          lessonName: data['lessonName'] ?? 'Unknown Lesson', // Default value if null
          lessonDate: (data['date'] as Timestamp).toDate(), // Assuming date is stored as Timestamp
        );
      }).toList();

      course.lessons = lessons;
    }

    setState(() {
      courseDetails = courses;
    });
  }

  void _navigateToRecordsDetail(BuildContext context, String courseId, String courseName, String lessonId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordsDetail(
          courseId: courseId,
          courseName: courseName,
          lessonId: lessonId,
        ),
      ),
    );
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
                  return CourseCard(
                    course: course,
                    onLessonTap: (lesson) => _navigateToRecordsDetail(
                      context,
                      course.courseId,
                      course.courseName,
                      lesson.lessonId,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final CourseDetail course;
  final Function(LessonDetail) onLessonTap;

  const CourseCard({Key? key, required this.course, required this.onLessonTap}) : super(key: key);

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
          return ListTile(
            title: Text('${lesson.lessonName} (${DateFormat('yyyy-MM-dd').format(lesson.lessonDate)})'),
            onTap: () => onLessonTap(lesson),
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

  LessonDetail({
    required this.lessonId,
    required this.lessonName,
    required this.lessonDate,
  });
}

class RecordsDetail extends StatefulWidget {
  final String courseId;
  final String courseName;
  final String lessonId;

  const RecordsDetail({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.lessonId,
  });

  @override
  State<RecordsDetail> createState() => _RecordsDetailState();
}

class _RecordsDetailState extends State<RecordsDetail> {
  List<AttendanceDetail> details = [];
  double attendancePercentage = 0.0;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .collection('Lessons')
          .doc(widget.lessonId)
          .collection('Attendance')
          .get();

      List<AttendanceDetail> fetchedDetails = [];
      int presentCount = 0;

      for (var doc in querySnapshot.docs) {
        bool isPresent = doc['status'] == 'present';
        if (isPresent) presentCount++;

        // Fetch student details
        var studentDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(doc.id)
            .get();
        var studentData = studentDoc.data() as Map<String, dynamic>;

        fetchedDetails.add(
          AttendanceDetail(
            index: fetchedDetails.length + 1,
            studentId: studentData['studentId'] ?? 'Unknown ID',
            firstName: studentData['firstName'] ?? 'Unknown',
            lastName: studentData['lastName'] ?? 'Unknown',
            attendance: isPresent,
          ),
        );
      }

      double percentage = 0.0;
      if (fetchedDetails.isNotEmpty) {
        percentage = (presentCount / fetchedDetails.length) * 100;
      }

      setState(() {
        details = fetchedDetails;
        attendancePercentage = percentage;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: const Text('Attendance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(9.0),
                child: Container(
                  color: const Color.fromRGBO(22, 22, 151, 100),
                  height: 5.0,
                ))),
        body: Padding(
            padding: const EdgeInsets.fromLTRB(30.0, 40.0, 30.0, 0),
            child: Column(children: <Widget>[
              const Text('Attendance',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 20),
              Text(
                'Overall Attendance: ${attendancePercentage.toStringAsFixed(2)}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 500,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                      children: details.map((detail) {
                    return SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: Card(
                          child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: detail.attendance
                                      ? Colors.greenAccent
                                      : Colors.redAccent),
                              child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(children: <Widget>[
                                    Text(detail.index.toString()),
              
                                    const SizedBox(width: 20),
                                    Text('${detail.firstName} ${detail.lastName}'),
                                    const SizedBox(width: 20),
                                    Text(detail.studentId),
                                    const Expanded(child: SizedBox()),
                                    Text(detail.attendance ? 'P' : 'Abs'),
                                  ])))),
                    );
                  }).toList()),
                ),
              )
            ])));
  }
}

class AttendanceDetail {
  final int index;
  final String studentId;
  final String firstName;
  final String lastName;
  final bool attendance;

  AttendanceDetail({
    required this.index,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.attendance,
  }); 
}
