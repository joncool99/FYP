import 'package:flutter/material.dart';
import 'package:helloapp/admin/accounts.dart';
import 'package:helloapp/timetable/timetable_home.dart';
import 'package:helloapp/attendance/captureImages.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminhomePage extends StatelessWidget {
  const AdminhomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully logged out')),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hi, Welcome ADMIN'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8.0),
          child: Container(
            color: Colors.blue, // Change the color as needed
            height: 4.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
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
                      MaterialPageRoute(builder: (context) => AccountsPage()),
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
                      Text('ADMIN',
                          style: TextStyle(fontSize: 20, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 50),

                //TIMETABLE

                ElevatedButton(
                  onPressed: () {
                    //go student page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TimetableHome()),
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
                    Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CaptureImagePage()),
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
