import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:helloapp/students/Student_View_Attendance.dart';
import 'package:helloapp/students/Student_View_Profile.dart';
import 'Student_Timetable.dart';
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
  List<Map<String, dynamic>> todayLessons = [];

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
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
        });
        _fetchTodayLessons();
      } else {
        print('No document found for the email: ${widget.email}');
      }
    } catch (e) {
      print('Error fetching student name: $e');
    }
  }

  Future<void> _fetchTodayLessons() async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .where('students', arrayContains: widget.email)
          .get();

      List<Map<String, dynamic>> lessons = [];

      for (var courseDoc in coursesSnapshot.docs) {
        QuerySnapshot lessonsSnapshot = await courseDoc.reference
            .collection('Lessons')
            .where('date', isGreaterThanOrEqualTo: startOfDay)
            .where('date', isLessThanOrEqualTo: endOfDay)
            .get();

        for (var lessonDoc in lessonsSnapshot.docs) {
          lessons.add({
            'courseName': courseDoc.get('courseName') ?? 'No Course Name',
            'courseId': courseDoc.get('courseId'), // Added 'courseId'
            'lessonName': lessonDoc.get('lessonName') ?? 'No Lesson Name',
            'startTime': lessonDoc.get('startTime') ?? 'No Start Time',
            'endTime': lessonDoc.get('endTime') ?? 'No End Time',
            'location': lessonDoc.get('location') ?? 'No Location',
          });
        }
      }

      setState(() {
        todayLessons = lessons;
      });
    } catch (e) {
      print('Error fetching today\'s lessons: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = <Widget>[
      HomeWidget(studentName: studentName, lessons: todayLessons),
      ViewTimetable(),
      //const RecordPage(),
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

class HomeWidget extends StatelessWidget {
  final String studentName;
  final List<Map<String, dynamic>> lessons;

  const HomeWidget(
      {super.key, required this.studentName, required this.lessons});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: kToolbarHeight), //height of app bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: <Widget>[
                const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person, color: Colors.white),
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
            return Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
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
                        Icon(Icons.access_time, size: 20, color: Colors.grey),
                        SizedBox(width: 5),
                        Text('${lesson['startTime']} - ${lesson['endTime']}'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.place, size: 20, color: Colors.grey),
                        SizedBox(width: 5),
                        Text(lesson['location']),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TakeAttendancePage(
                        courseName: lesson['courseName'],
                        courseId: lesson['courseId'],
                        lessonName: lesson['lessonName'],
                        startTime: lesson['startTime'],
                        endTime: lesson['endTime'],
                        location: lesson['location'],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
