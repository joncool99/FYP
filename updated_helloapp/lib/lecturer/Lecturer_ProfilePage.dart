import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Lecturer_ProfilePage extends StatefulWidget {
  @override
  _Lecturer_ProfilePageState createState() => _Lecturer_ProfilePageState();
}

class _Lecturer_ProfilePageState extends State<Lecturer_ProfilePage> {
  File? _image;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
        } else {
          print('No image selected.');
        }
      });
    } catch (e) {
      print("Failed to pick image: $e");
    }
  }

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
            GestureDetector(
              onTap: () async {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.photo_camera),
                        title: Text('Take a photo'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.photo_library),
                        title: Text('Pick from gallery'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                );
              },
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _image == null
                    ? AssetImage('assets/profile_image.png')
                    : FileImage(_image!) as ImageProvider,
              ),
            ),
            SizedBox(height: 20),
            _buildProfileField('Email:', 'lecturer001@hotmail.com'),
            _buildProfileField('Lecturer ID:', '001', isEditable: false),
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
