import 'dart:math'; // Import the dart:math library for sqrt
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import '../pre_train_model/vision_api.dart';

class TakeAttendancePage extends StatefulWidget {
  final String courseName;
  final String courseId;
  final String lessonName;
  final String startTime;
  final String endTime;
  final String location;
  final CameraDescription camera;

  const TakeAttendancePage({
    Key? key,
    required this.courseName,
    required this.courseId,
    required this.lessonName,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.camera,
  }) : super(key: key);

  @override
  _TakeAttendancePageState createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  late CameraController _controller;
  bool _isDetecting = false;
  final VisionApi _visionApi = VisionApi();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _takeAttendance(BuildContext context) async {
    if (!_controller.value.isInitialized || _isDetecting) return;

    setState(() => _isDetecting = true);

    try {
      final XFile imageFile = await _controller.takePicture();
      final imageBytes = await imageFile.readAsBytes();

      final newEmbedding = await _visionApi.detectFaces(imageBytes);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final storedEmbedding = List<double>.from(userDoc['embedding']);
          final isMatching = compareEmbeddings(storedEmbedding, newEmbedding);
          if (isMatching) {
            // Mark attendance
            await FirebaseFirestore.instance
                .collection('Courses')
                .doc(widget.courseId)
                .collection('Lessons')
                .doc(widget.lessonName)
                .collection('Attendance')
                .doc(user.email!)
                .set({
              'timestamp': FieldValue.serverTimestamp(),
              'status': 'present',
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Attendance taken for ${widget.lessonName}')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Face not recognized')),
            );
          }
        }
      }
    } catch (e) {
      print("Error during attendance: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking attendance: $e')),
      );
    } finally {
      setState(() => _isDetecting = false);
    }
  }

  bool compareEmbeddings(
      List<double> storedEmbedding, List<double> newEmbedding) {
    final distance = calculateEuclideanDistance(storedEmbedding, newEmbedding);
    return distance < 1.0; // Define a suitable threshold
  }

  double calculateEuclideanDistance(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]) * (a[i] - b[i]);
    }
    return sqrt(sum); // Use sqrt from dart:math
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }
    return FutureBuilder(
      future: _visionApi.loadModel(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading model: ${snapshot.error}'));
        } else {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text('Take Attendance',
                  style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(4.0),
                child: Container(
                  color: Colors.blue[900],
                  height: 3.0,
                ),
              ),
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: CameraPreview(_controller),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed:
                        _isDetecting ? null : () => _takeAttendance(context),
                    child: Text('Capture and Take Attendance',
                        style: TextStyle(fontSize: 18)),
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
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        }
      },
    );
  }
}
