import 'package:flutter/material.dart';

class StudentProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'My Profile',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            )
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container(
            color: Colors.blue[800],
            height: 3.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('images/face_icon.png'),
            ),
            const SizedBox(height: 20),
            buildTextField('Email:', 'email@example.com', false),
            buildTextField('Student ID:', '123456789', true),
            buildTextField('First Name:', 'John', false),
            buildTextField('Last Name:', 'Doe', false),
            buildTextField('Major:', 'Computer Science', true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
              ),child: Text('Update')
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Timetable'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
      ),
    );
  }

  Widget buildTextField(String label, String placeholder, bool readOnly) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: TextEditingController(text: placeholder),
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
