import 'package:flutter/material.dart';
import 'package:me_app/register.dart';
import 'package:me_app/updateinfo.dart';

class StudentPage extends StatefulWidget {
  @override
  
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STUDENTS'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8.0),
          child: Container(
            color: Colors.blue, // Change the color as needed
            height: 4.0,
          ),
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 90),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              backgroundColor: const Color.fromARGB(255, 1, 124, 255),
            ),
            child: const Text(
              'Register',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdatePage()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              backgroundColor: const Color.fromARGB(255, 1, 124, 255),
            ),
            child: const Text(
              'Update info',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}
