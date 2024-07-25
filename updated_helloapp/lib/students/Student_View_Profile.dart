import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'student_registerFace.dart';

class ViewProfilePage extends StatefulWidget {
  @override
  _ViewProfilePageState createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> enrolledCourses = [];
  CameraDescription? firstCamera;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchUserData();
    _initializeCamera();
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_user!.email)
          .get();
      setState(() {
        _userData = userDoc.data() as Map<String, dynamic>?;
      });
      _fetchEnrolledCourses();
    }
  }

  Future<void> _fetchEnrolledCourses() async {
    if (_user != null) {
      QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .where('students', arrayContains: _user!.email)
          .get();

      setState(() {
        enrolledCourses = coursesSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      var status = await Permission.camera.status;
      if (status.isDenied) {
        status = await Permission.camera.request();
      }

      if (status.isGranted) {
        final cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          setState(() {
            firstCamera = cameras.first;
          });
        } else {
          setState(() {
            firstCamera = null; // Handle no cameras available
          });
          print('No cameras available');
        }
      } else {
        print('Camera permission not granted');
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'View Profile',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8.0),
          child: Container(
            height: 2,
            color: Colors.blue[900],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: ClipOval(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: _userData!['imageUrl'] != null
                                  ? NetworkImage(_userData!['imageUrl'])
                                  : const AssetImage(
                                          'assets/images/default_user.png')
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${_userData!['firstName']} ${_userData!['lastName']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Email: ${_userData!['email']}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Student ID: ${_userData!['studentId']}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Major: ${_userData!['major']}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.blue[900]),
                    const SizedBox(height: 20),
                    Text(
                      'Enrolled Courses',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    enrolledCourses.isEmpty
                        ? const Center(
                            child: Text(
                              'No courses enrolled',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: enrolledCourses.length,
                            itemBuilder: (context, index) {
                              var course = enrolledCourses[index];
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  title: Text(
                                    course['courseName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle:
                                      Text('Course ID: ${course['courseId']}'),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: firstCamera != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentRegisterFacePage(
                                      camera: firstCamera!),
                                ),
                              );
                            }
                          : null,
                      child:
                          Text('Register Face', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        minimumSize: Size(160, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
