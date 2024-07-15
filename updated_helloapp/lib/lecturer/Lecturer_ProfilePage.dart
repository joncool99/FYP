import 'package:flutter/material.dart';

class Lecturer_ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/profile_image.png'),
            ),
            SizedBox(height: 20),
            _buildProfileField('Email:', 'johnD@gmail.com'),
            _buildProfileField('Lecturer ID:', '12345', isEditable: false),
            _buildProfileField('First Name:', 'John'),
            _buildProfileField('Last Name:', 'Doe'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add update functionality here
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value, {bool isEditable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              enabled: isEditable,
              decoration: InputDecoration(
                hintText: value,
                filled: !isEditable,
                fillColor: isEditable ? Colors.white : Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
