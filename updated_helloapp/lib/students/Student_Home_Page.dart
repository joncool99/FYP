import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'Student_Timetable.dart';
import 'Student_View_Attendance.dart';
import 'Student_View_Profile.dart';
import 'StudentTakeAttendance.dart';

class StudentHomePage extends StatefulWidget {
  final String email;

  StudentHomePage({required this.email});

  @override
  _StudentHomepageState createState() => _StudentHomepageState();
}

class _StudentHomepageState extends State<StudentHomePage> {
  int _selectedIndex = 0;
  String studentName = '';
  String? profilePhotoUrl;
  CameraDescription? firstCamera;
  List<Map<String, dynamic>> todayLessons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchStudentData();
    await _initializeCamera();
    await _fetchTodayLessons();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchStudentData() async {
    try {
      if (widget.email.isEmpty) {
        print('Email is empty, cannot fetch student name.');
        return;
      }

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.email)
          .get();

      if (snapshot.exists) {
        setState(() {
          studentName = snapshot.get('firstName') ?? 'Student';
          profilePhotoUrl = snapshot.get('imageUrl');
        });
      } else {
        print('No document found for the email: ${widget.email}');
      }
    } catch (e) {
      print('Error fetching student name: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      setState(() {
        firstCamera = cameras.first;
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _fetchTodayLessons() async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
        .collection('Courses')
        .where('students', arrayContains: widget.email)
        .get();

    List<Future<Map<String, dynamic>>> lessonsFutures = [];

    for (var courseDoc in coursesSnapshot.docs) {
      QuerySnapshot lessonsSnapshot = await courseDoc.reference
          .collection('Lessons')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .get();

      for (var lessonDoc in lessonsSnapshot.docs) {
        lessonsFutures.add(_buildLessonMap(courseDoc, lessonDoc));
      }
    }

    todayLessons = await Future.wait(lessonsFutures);

    // Check and mark absent if necessary
    _checkAndMarkAbsent();
    setState(() {});
  }

  Future<void> _checkAndMarkAbsent() async {
    DateTime now = DateTime.now();

    for (var lesson in todayLessons) {
      DateTime endTime = _parseTime(now, lesson['endTime']);

      // If the current time is after the lesson's end time and the student hasn't been marked present
      if (now.isAfter(endTime) && lesson['status'] != 'present') {
        // Mark the student as absent if they haven't taken attendance
        await _markAbsent(lesson['courseId'], lesson['lessonName']);
      }
    }
  }

  Future<void> _markAbsent(String courseId, String lessonName) async {
    try {
      DocumentReference attendanceRef = FirebaseFirestore.instance
          .collection('Courses')
          .doc(courseId)
          .collection('Lessons')
          .doc(lessonName)
          .collection('Attendance')
          .doc(widget.email);

      await attendanceRef.set({
        'email': widget.email,
        'status': 'absent',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print(
          'Attendance marked as absent for lesson $lessonName in course $courseId');
    } catch (e) {
      print('Error marking attendance as absent: $e');
    }
  }

  Future<Map<String, dynamic>> _buildLessonMap(
      DocumentSnapshot courseDoc, DocumentSnapshot lessonDoc) async {
    DocumentSnapshot attendanceDoc = await lessonDoc.reference
        .collection('Attendance')
        .doc(widget.email)
        .get();

    String status =
        attendanceDoc.exists ? attendanceDoc.get('status') : 'absent';

    return {
      'courseName': courseDoc.get('courseName') ?? 'No Course Name',
      'courseId': courseDoc.get('courseId'),
      'lessonName': lessonDoc.get('lessonName') ?? 'No Lesson Name',
      'startTime': lessonDoc.get('startTime') ?? '00:00',
      'endTime': lessonDoc.get('endTime') ?? '00:00',
      'location': lessonDoc.get('location') ?? 'No Location',
      'status': status,
    };
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshLessons() async {
    setState(() {
      isLoading = true;
    });
    await _fetchTodayLessons();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> _widgetOptions = <Widget>[
      HomeWidget(
        studentName: studentName,
        profilePhotoUrl: profilePhotoUrl,
        lessons: todayLessons,
        onRefresh: _refreshLessons,
      ),
      ViewTimetable(),
      const RecordPage(),
      ViewProfilePage(),
    ];

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A31DC), Color(0xFF9C86EE)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.schedule), label: 'Timetable'),
            BottomNavigationBarItem(
                icon: Icon(Icons.check), label: 'Attendance'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

DateTime _parseTime(DateTime now, String timeString) {
  List<String> timeParts = timeString.split(':');
  int hour = int.parse(timeParts[0]);
  int minute = int.parse(timeParts[1]);
  return DateTime(now.year, now.month, now.day, hour, minute);
}

class HomeWidget extends StatelessWidget {
  final String studentName;
  final String? profilePhotoUrl;
  final List<Map<String, dynamic>> lessons;
  final Future<void> Function() onRefresh;

  const HomeWidget({
    super.key,
    required this.studentName,
    required this.profilePhotoUrl,
    required this.lessons,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: kToolbarHeight), // height of app bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundImage: profilePhotoUrl != null
                        ? NetworkImage(profilePhotoUrl!)
                        : const AssetImage('assets/images/default_user.png')
                            as ImageProvider,
                    backgroundColor: Colors.grey,
                    radius: 30,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Hi, $studentName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Welcome!',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 2,
              color: Colors.blue[900],
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Today\'s Agenda',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ...lessons.map((lesson) {
              DateTime now = DateTime.now();
              DateTime startTime = _parseTime(now, lesson['startTime']);
              DateTime endTime = _parseTime(now, lesson['endTime']);
              String status = lesson['status'] ?? 'absent';

              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: status == 'present'
                      ? const Color.fromARGB(255, 132, 240, 199)
                      : null, // Change to green if present,
                  gradient: status == 'present'
                      ? null
                      : const LinearGradient(
                          colors: [Colors.white, Color(0xFFAAACF8)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(
                    '${lesson['courseId']} - ${lesson['lessonName']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(lesson['courseName']),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 20, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text('${lesson['startTime']} - ${lesson['endTime']}'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.place, size: 20, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(lesson['location']),
                        ],
                      ),
                      if (status == 'present')
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Present',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    if (now.isBefore(startTime) || now.isAfter(endTime)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Lesson duration has not started or has ended.'),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentTakeAttendancePage(
                            courseId: lesson['courseId'],
                            courseName: lesson['courseName'],
                            lessonName: lesson['lessonName'],
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  DateTime _parseTime(DateTime now, String timeString) {
    List<String> timeParts = timeString.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}
