import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Lecturer_View_Records.dart';
import 'Lecturer_Take_Attendance.dart';
import 'Lecturer_Timetable.dart';
import 'Lecturer_ProfilePage.dart';

class LecturerHomePage extends StatefulWidget {
  final String email;

  LecturerHomePage({required this.email});

  @override
  _LecturerHomePageState createState() => _LecturerHomePageState();
}

class _LecturerHomePageState extends State<LecturerHomePage> {
  int _selectedIndex = 0;
  String lecturerName = '';
  String? profilePhotoUrl;
  List<Map<String, dynamic>> todayLessons = [];

  @override
  void initState() {
    super.initState();
    _fetchLecturerData();
  }

  Future<void> _fetchLecturerData() async {
    try {
      if (widget.email.isEmpty) {
        print('Email is empty, cannot fetch lecturer name.');
        return;
      }

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.email)
          .get();

      if (snapshot.exists) {
        setState(() {
          lecturerName = snapshot.get('firstName') ?? 'Lecturer';
          profilePhotoUrl = snapshot.get('imageUrl');
        });
        _fetchTodayLessons();
      } else {
        print('No document found for the email: ${widget.email}');
      }
    } catch (e) {
      print('Error fetching lecturer name: $e');
    }
  }

  Future<void> _fetchTodayLessons() async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .where('lecturers', arrayContains: widget.email)
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
            'courseId': courseDoc.get('courseId'),
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
      HomeWidget(
          lecturerName: lecturerName,
          profilePhotoUrl: profilePhotoUrl,
          lessons: todayLessons),
      LecturerTimetable(),
      LecturerRecordsPage(),
      LecturerProfilePage(),
    ];

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 220, 26, 26),
              Color.fromARGB(255, 238, 134, 134)
            ],
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
                icon: Icon(Icons.check_box), label: 'Records'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class HomeWidget extends StatelessWidget {
  final String lecturerName;
  final String? profilePhotoUrl;
  final List<Map<String, dynamic>> lessons;

  const HomeWidget(
      {super.key,
      required this.lecturerName,
      required this.profilePhotoUrl,
      required this.lessons});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                      'Hi, $lecturerName',
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
                      builder: (context) => LecturerTakeAttendancePage(
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
          }).toList(),
        ],
      ),
    );
  }
}
