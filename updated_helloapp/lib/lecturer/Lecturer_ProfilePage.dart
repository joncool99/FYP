import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helloapp/login.dart';

class LecturerProfilePage extends StatefulWidget {
  @override
  _LecturerProfilePageState createState() => _LecturerProfilePageState();
}

class _LecturerProfilePageState extends State<LecturerProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> teachingCourses = [];

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchUserData();
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
      _fetchTeachingCourses();
    }
  }

  Future<void> _fetchTeachingCourses() async {
    if (_user != null) {
      QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .where('lecturers', arrayContains: _user!.email)
          .get();

      setState(() {
        teachingCourses = coursesSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
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
                      'Lecturer ID: ${_userData!['studentId']}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.blue[900]),
                    const SizedBox(height: 20),
                    const Text(
                      'Courses Taught',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    teachingCourses.isEmpty
                        ? const Center(
                            child: Text(
                              'No courses taught',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: teachingCourses.length,
                            itemBuilder: (context, index) {
                              var course = teachingCourses[index];
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
                      onPressed: () {
                        _auth.signOut();
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                            (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        minimumSize: const Size(160, 50),
                      ),
                      child: const Text('Sign Out', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
