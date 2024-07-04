import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helloapp/students/StudentTakeAttendance.dart';
import 'package:helloapp/students/Student_Enrolment.dart';
import 'package:helloapp/students/Student_Timetable.dart';

class StudentHomePage extends StatefulWidget {
  final String email;

  StudentHomePage({required this.email});

  @override
  _StudentHomepageState createState() => _StudentHomepageState();
}

class _StudentHomepageState extends State<StudentHomePage> {
  int _selectedIndex = 0;
  String studentName = '';

  @override
  void initState() {
    super.initState();
    _fetchStudentName();
  }

  Future<void> _fetchStudentName() async {
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
          studentName = snapshot['firstName'] ?? 'Student';
        });
      } else {
        print('No document found for the email: ${widget.email}');
      }
    } catch (e) {
      print('Error fetching student name: $e');
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
      HomeWidget(studentName: studentName),
      ViewTimetable(),
      StudentEnrollmentScreen(),
      const Text('Profile Page'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Student Home'
              : _selectedIndex == 1
                  ? 'Timetable'
                  : _selectedIndex == 2
                      ? 'Take Attendance'
                      : 'Profile Page',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
  const HomeWidget({super.key, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            child: const ListTile(
              title: Text(
                'CSIT 321 - L01',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Project'),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 20, color: Colors.grey),
                      SizedBox(width: 5),
                      Text('03:30 PM - 06:30PM'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.place, size: 20, color: Colors.grey),
                      SizedBox(width: 5),
                      Text('Room 101'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
