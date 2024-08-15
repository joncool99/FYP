import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const double allowedLatitude = 1.3294548283975756; // Replace with actual latitude
const double allowedLongitude = 103.77618522345148; // Replace with actual longitude
const double allowedRadius = 100; // in meters

class StudentTakeAttendancePage extends StatefulWidget {
  final String courseId;
  final String courseName;
  final String lessonName;

  const StudentTakeAttendancePage({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.lessonName,
  }) : super(key: key);

  @override
  _StudentTakeAttendancePageState createState() =>
      _StudentTakeAttendancePageState();
}

class _StudentTakeAttendancePageState extends State<StudentTakeAttendancePage> {
  late CameraController _controller;
  bool _isProcessing = false;
  late Interpreter _interpreter;
  bool _isModelLoaded = false;
  bool _isCameraInitialized = false;
  bool _isFaceInFrame = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    print('Initializing camera...');
    CameraDescription? frontCamera;

    // Find the front camera
    for (CameraDescription camera in await availableCameras()) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }

    if (frontCamera == null) {
      print('No front camera found.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No front camera found.')),
      );
      return;
    }

    _controller = CameraController(frontCamera, ResolutionPreset.high);
    try {
      await _controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
        print('Front camera initialized');
      });
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() {
        _isCameraInitialized = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing camera: $e')),
      );
    }
  }

  Future<void> _loadModel() async {
    print('Loading model...');
    try {
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
      setState(() {
        _isModelLoaded = true;
      });
      print('Model loaded');
    } catch (e) {
      print('Error loading model: $e');
      setState(() {
        _isModelLoaded = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading model: $e')),
      );
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Get the current position
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  bool _isWithinAllowedArea(Position currentPosition) {
    double distanceInMeters = Geolocator.distanceBetween(
      allowedLatitude,
      allowedLongitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    return distanceInMeters <= allowedRadius;
  }

  Future<void> _captureAndVerifyFace() async {
    if (!_controller.value.isInitialized || !_isModelLoaded || _isProcessing) {
      print(
          'Button disabled. _isProcessing: $_isProcessing, _isModelLoaded: $_isModelLoaded, _controller initialized: ${_controller.value.isInitialized}');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // **Location Check**
      Position currentPosition = await _getCurrentLocation();
      if (!_isWithinAllowedArea(currentPosition)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are outside the allowed area for attendance.')),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // **Capture and verify face logic remains the same**
      List<List<double>> newEmbeddingsList = [];
      for (int i = 0; i < 3; i++) {
        // Capture 3 images for better accuracy
        print('Capturing image...');
        final XFile imageFile = await _controller.takePicture();
        print('Picture taken: ${imageFile.path}');
        final Uint8List imageBytes = await imageFile.readAsBytes();

        // Detect faces using Google ML Vision
        print('Detecting faces...');
        final GoogleVisionImage visionImage =
        GoogleVisionImage.fromFilePath(imageFile.path);
        final FaceDetector faceDetector = GoogleVision.instance.faceDetector(
          const FaceDetectorOptions(enableLandmarks: true),
        );
        final List<Face> faces = await faceDetector.processImage(visionImage);

        if (faces.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No face detected! Please try again.')),
          );
          setState(() => _isProcessing = false);
          return;
        }

        // Extract the first detected face and get embeddings
        print('Extracting face and getting embeddings...');
        final Face face = faces[0];
        final img.Image originalImage = img.decodeImage(imageBytes)!;
        final img.Image faceImage = img.copyCrop(
          originalImage,
          face.boundingBox.left.toInt(),
          face.boundingBox.top.toInt(),
          face.boundingBox.width.toInt(),
          face.boundingBox.height.toInt(),
        );
        final newEmbeddings = await _getEmbeddings(faceImage);
        newEmbeddingsList.add(newEmbeddings);

        // Determine if the detected face is within the oval frame.
        _isFaceInFrame = _isFaceWithinFrame(face.boundingBox);

        await Future.delayed(const Duration(seconds: 1)); // Delay between captures
      }

      // Calculate average embeddings for verification
      final averageNewEmbeddings =
      _calculateAverageEmbeddings(newEmbeddingsList);

      // Verify embeddings with stored embeddings
      final isVerified = await _verifyFace(averageNewEmbeddings);

      if (isVerified) {
        // Mark attendance
        await _markAttendance();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance marked successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Face not recognized. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during face verification: $e')),
      );
      print('Error during face verification: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  bool _isFaceWithinFrame(Rect faceRect) {
    // Define the frame's dimensions and position.
    // This example assumes the frame is centered and occupies 70% of the screen width and 50% of the screen height.
    final double frameWidth = MediaQuery.of(context).size.width * 0.7;
    final double frameHeight = MediaQuery.of(context).size.height * 0.5;
    final double frameLeft = (MediaQuery.of(context).size.width - frameWidth) / 2;
    final double frameTop = (MediaQuery.of(context).size.height - frameHeight) / 2;

    final Rect frameRect = Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight);

    // Check if the face is within the oval frame.
    return frameRect.contains(faceRect.center);
  }

  Future<void> _markAttendance() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final attendanceRef = FirebaseFirestore.instance
            .collection('Courses')
            .doc(widget.courseId)
            .collection('Lessons')
            .doc(widget.lessonName)
            .collection('Attendance')
            .doc(user.email);

        await attendanceRef.set({
          'email': user.email,
          'status': 'present',
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('Attendance marked in Firestore!');
      }
    } catch (e) {
      print('Failed to mark attendance: $e');
    }
  }

  Future<bool> _verifyFace(List<double> newEmbeddings) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('UserEmbeddings')
          .doc(user.email)
          .get();

      if (doc.exists) {
        final storedEmbeddings = List<double>.from(doc['embeddings']);
        final double similarity = _calculateCosineSimilarity(
          newEmbeddings,
          storedEmbeddings,
        );

        // Print similarity score
        print('Cosine similarity: $similarity');

        // Consider face verification successful if similarity is above a threshold
        return similarity > 0.9;
      }
    }
    return false;
  }

  Future<List<double>> _getEmbeddings(img.Image faceImage) async {
    final List<double> input = _preprocessImage(faceImage);

    final output = List.filled(192, 0.0).reshape([1, 192]);
    _interpreter.run(input, output);

    return output[0];
  }

  List<double> _preprocessImage(img.Image faceImage) {
    final resizedImage = img.copyResize(faceImage, width: 112, height: 112);
    final Float32List imageAsList = Float32List(112 * 112 * 3);

    for (int i = 0; i < 112; i++) {
      for (int j = 0; j < 112; j++) {
        final pixel = resizedImage.getPixel(j, i);
        final int index = (i * 112 + j) * 3;

        imageAsList[index] = (img.getRed(pixel) - 128) / 128;
        imageAsList[index + 1] = (img.getGreen(pixel) - 128) / 128;
        imageAsList[index + 2] = (img.getBlue(pixel) - 128) / 128;
      }
    }

    return imageAsList;
  }

  double _calculateCosineSimilarity(
      List<double> embeddings1,
      List<double> embeddings2,
      ) {
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embeddings1.length; i++) {
      dotProduct += embeddings1[i] * embeddings2[i];
      norm1 += embeddings1[i] * embeddings1[i];
      norm2 += embeddings2[i] * embeddings2[i];
    }

    norm1 = sqrt(norm1);
    norm2 = sqrt(norm2);

    return dotProduct / (norm1 * norm2);
  }

  List<double> _calculateAverageEmbeddings(List<List<double>> embeddingsList) {
    final int length = embeddingsList[0].length;
    final List<double> averageEmbeddings = List.filled(length, 0.0);

    for (int i = 0; i < length; i++) {
      for (final embeddings in embeddingsList) {
        averageEmbeddings[i] += embeddings[i];
      }
      averageEmbeddings[i] /= embeddingsList.length;
    }

    return averageEmbeddings;
  }

  @override
  void dispose() {
    _controller.dispose();
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
      ),
      body: Stack(
        children: [
          if (!_isCameraInitialized || !_isModelLoaded)
            const Center(child: CircularProgressIndicator())
          else
            CameraPreview(_controller),
          if (_isCameraInitialized && _isModelLoaded)
            CustomPaint(
              painter: FaceFramePainter(_isFaceInFrame),
              child: Container(),
            ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: ElevatedButton(
              onPressed: _isProcessing || !_isModelLoaded
                  ? null
                  : _captureAndVerifyFace,
              child: const Text('Capture and Verify Face'),
            ),
          ),
        ],
      ),
    );
  }
}

class FaceFramePainter extends CustomPainter {
  final bool isFaceInFrame;

  FaceFramePainter(this.isFaceInFrame);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = isFaceInFrame ? Colors.green : Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Define the oval frame.
    final Rect rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.height * 0.5,
    );

    // Draw the oval.
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
