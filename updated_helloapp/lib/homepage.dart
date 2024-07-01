import 'package:flutter/material.dart';
import 'students.dart';

class HomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hi, Welcome '),
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
                //STUDENT
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StudentPage()),
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
                      Icon(Icons.person, size: 50, color: Colors.black),
                      Text('STUDENT',
                          style: TextStyle(fontSize: 20, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 50),

                //TIMETABLE

                ElevatedButton(
                  onPressed: () {
                    //go student page
                    Navigator.pop(context);
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
                      Icon(Icons.calendar_view_month,
                          size: 50, color: Colors.black),
                      Text('TIMETABLE',
                          style: TextStyle(fontSize: 20, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 50),

                //RECORDS
                ElevatedButton(
                  onPressed: () {
                    //go student page
                    Navigator.pop(context)
                    ;
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
                      Icon(Icons.my_library_books_rounded,
                          size: 50, color: Colors.black),
                      Text('RECORDS',
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
