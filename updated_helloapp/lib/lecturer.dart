import 'package:flutter/material.dart';
import 'lecturer/Lecturer_HomePage.dart';
import 'lecturer/Lecturer_TimetablePage.dart';
import 'lecturer/Lecturer_RecordsPage.dart';
import 'lecturer/Lecturer_ProfilePage.dart';
import 'lecturer/Lecturer_AttendancePage.dart';

class LecturerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Lecturer_HomePage(),
    Lecturer_TimetablePage(),
    Lecturer_RecordsPage(),
    Lecturer_ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.black),
            label: 'Homepage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month, color: Colors.black),
            label: 'Timetable',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.data_thresholding_outlined, color: Colors.black),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.black),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
