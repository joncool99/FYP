import 'package:flutter/material.dart';
import 'package:helloapp/timetable/course_overview.dart';
import 'package:helloapp/timetable/create_course.dart';
import 'package:helloapp/timetable/edit_course.dart';
import 'package:helloapp/timetable/view_timetable.dart';


class TimetableHome extends StatelessWidget {
  const TimetableHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Menu'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8.0),
          child: Container(
            color: Colors.blue, // Change the color as needed
            height: 4.0,
          ),
        ),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Create Timetable Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CourseOverview()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(40),
                    backgroundColor: const Color.fromARGB(255, 172, 177, 179),
                    minimumSize: const Size(300, 100),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.zero, // Make button rectangular
                    ),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.create, size: 50, color: Colors.black),
                      Text('Course Overview',
                          style: TextStyle(fontSize: 20, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ViewTimetable()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(40),
                    backgroundColor: const Color.fromARGB(255, 172, 177, 179),
                    minimumSize: const Size(300, 100),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.zero, // Make button rectangular
                    ),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.view_agenda, size: 50, color: Colors.black),
                      Text('View Timetable',
                          style: TextStyle(fontSize: 20, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 50),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
