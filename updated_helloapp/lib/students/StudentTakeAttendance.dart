import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class StudentTakeAttendancePage extends StatefulWidget {
  final CameraDescription camera;
  final String courseId;
  final String courseName;
  final String lessonName;

  const StudentTakeAttendancePage({
    Key? key,
    required this.camera,
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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    print('Initializing camera...');
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    try {
      await _controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
        print('Camera initialized');
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

  Future<void> _captureAndVerifyFace() async {
    if (!_controller.value.isInitialized || !_isModelLoaded || _isProcessing) {
      print(
          'Button disabled. _isProcessing: $_isProcessing, _isModelLoaded: $_isModelLoaded, _controller initialized: ${_controller.value.isInitialized}');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Capture the image
      print('Capturing image...');
      final XFile imageFile = await _controller.takePicture();
      print('Picture taken: ${imageFile.path}');
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Detect faces using Google ML Vision
      print('Detecting faces...');
      final GoogleVisionImage visionImage =
          GoogleVisionImage.fromFilePath(imageFile.path);
      final FaceDetector faceDetector = GoogleVision.instance.faceDetector(
        FaceDetectorOptions(enableLandmarks: true),
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
        x: face.boundingBox.left.toInt(),
        y: face.boundingBox.top.toInt(),
        width: face.boundingBox.width.toInt(),
        height: face.boundingBox.height.toInt(),
      );
      final newEmbeddings = await _getEmbeddings(faceImage);

      // Verify embeddings with stored embeddings
      final isVerified = await _verifyFace(newEmbeddings);

      if (isVerified) {
        // Mark attendance
        await _markAttendance();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance marked successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face not recognized. Please try again.')),
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
          .collection('Users')
          .doc(user.email)
          .get();
      if (doc.exists) {
        final storedEmbeddings = List<double>.from(doc.data()!['embeddings']);
        final distance =
            _calculateEuclideanDistance(storedEmbeddings, newEmbeddings);

        // Define a threshold for matching faces
        const double threshold = 1.0;
        return distance < threshold;
      }
    }
    return false;
  }

  double _calculateEuclideanDistance(
      List<double> embedding1, List<double> embedding2) {
    double sum = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      sum += (embedding1[i] - embedding2[i]) * (embedding1[i] - embedding2[i]);
    }
    return sqrt(sum);
  }

  Future<List<double>> _getEmbeddings(img.Image faceImage) async {
    print('Getting embeddings...');
    // Resize and normalize the face image
    final img.Image resizedImage =
        img.copyResize(faceImage, width: 112, height: 112);
    final List input = _imageToByteListFloat32(resizedImage, 112, 128, 128);

    // Define input and output tensors
    final output = List.filled(1 * 192, 0).reshape([1, 192]);

    // Run inference
    _interpreter.run(input, output);

    return output[0];
  }

  List _imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    final Float32List convertedBytes =
        Float32List(1 * inputSize * inputSize * 3);
    final buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < inputSize; j++) {
        final pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
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
        title: Text('Take Attendance'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_isCameraInitialized || !_isModelLoaded)
            Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: CameraPreview(_controller),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isProcessing || !_isModelLoaded
                  ? null
                  : _captureAndVerifyFace,
              child: Text('Capture and Verify Face'),
            ),
          ),
        ],
      ),
    );
  }
}
