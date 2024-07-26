import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';

class LecturerTakeAttendancePage extends StatefulWidget {
  final String courseId;
  final String courseName;
  final String lessonName;
  final String startTime;
  final String endTime;
  final String location;

  const LecturerTakeAttendancePage({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.lessonName,
    required this.startTime,
    required this.endTime,
    required this.location,
  }) : super(key: key);

  @override
  _LecturerTakeAttendancePageState createState() =>
      _LecturerTakeAttendancePageState();
}

class _LecturerTakeAttendancePageState
    extends State<LecturerTakeAttendancePage> {
  late Interpreter _interpreter;
  bool _isModelLoaded = false;
  bool _isProcessing = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<String> _identifiedStudents = [];

  @override
  void initState() {
    super.initState();
    _loadModel();
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

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Failed to pick image: $e");
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null || !_isModelLoaded || _isProcessing) {
      print(
          'Button disabled. _isProcessing: $_isProcessing, _isModelLoaded: $_isModelLoaded, _imageFile: $_imageFile');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final Uint8List imageBytes = await _imageFile!.readAsBytes();
      final GoogleVisionImage visionImage =
          GoogleVisionImage.fromFile(_imageFile!);
      final FaceDetector faceDetector = GoogleVision.instance.faceDetector(
        FaceDetectorOptions(enableLandmarks: true),
      );
      final List<Face> faces = await faceDetector.processImage(visionImage);

      if (faces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No faces detected in the image!')),
        );
        setState(() => _isProcessing = false);
        return;
      }

      final img.Image originalImage = img.decodeImage(imageBytes)!;
      List<List<double>> embeddingsList = [];

      for (Face face in faces) {
        final img.Image faceImage = img.copyCrop(
          originalImage,
          x: face.boundingBox.left.toInt(),
          y: face.boundingBox.top.toInt(),
          width: face.boundingBox.width.toInt(),
          height: face.boundingBox.height.toInt(),
        );
        final embeddings = await _getEmbeddings(faceImage);
        embeddingsList.add(embeddings);
      }

      final matchedFacesCount =
          await _identifyAndMarkAttendance(embeddingsList);

      if (matchedFacesCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance marked successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No matching faces found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during face processing: $e')),
      );
      print('Error during face processing: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<int> _identifyAndMarkAttendance(
      List<List<double>> embeddingsList) async {
    _identifiedStudents.clear();
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('Users').get();
    int matchedFacesCount = 0;

    for (var userDoc in usersSnapshot.docs) {
      final storedEmbeddings = (userDoc.data()['embeddings'] as List)
          .map((e) => e is double ? e : double.tryParse(e.toString()) ?? 0.0)
          .toList();

      for (var newEmbeddings in embeddingsList) {
        final similarity =
            _calculateCosineSimilarity(storedEmbeddings, newEmbeddings);
        if (similarity > 0.7) {
          // Adjust threshold for higher accuracy
          _identifiedStudents.add(userDoc.id);
          await _markAttendance(userDoc.id);
          matchedFacesCount++;
          break;
        }
      }
    }
    setState(() {});
    return matchedFacesCount;
  }

  Future<void> _markAttendance(String email) async {
    try {
      final attendanceRef = FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .collection('Lessons')
          .doc(widget.lessonName)
          .collection('Attendance')
          .doc(email);

      await attendanceRef.set({
        'email': email,
        'status': 'present',
        'courseName': widget.courseName,
        'courseId': widget.courseId,
        'lessonName': widget.lessonName,
        'startTime': widget.startTime,
        'endTime': widget.endTime,
        'location': widget.location,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Attendance marked in Firestore for $email!');
    } catch (e) {
      print('Failed to mark attendance for $email: $e');
    }
  }

  double _calculateCosineSimilarity(
      List<double> vectorA, List<double> vectorB) {
    double dotProduct = 0.0;
    double magnitudeA = 0.0;
    double magnitudeB = 0.0;

    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
      magnitudeA += vectorA[i] * vectorA[i];
      magnitudeB += vectorB[i] * vectorB[i];
    }

    magnitudeA = sqrt(magnitudeA);
    magnitudeB = sqrt(magnitudeB);

    if (magnitudeA != 0.0 && magnitudeB != 0.0) {
      return dotProduct / (magnitudeA * magnitudeB);
    } else {
      return 0.0;
    }
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
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lecturer Take Attendance'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageFile != null) Image.file(_imageFile!),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isProcessing || !_isModelLoaded ? null : _pickImage,
                child: Text('Pick Image'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed:
                    _isProcessing || !_isModelLoaded ? null : _processImage,
                child: Text('Process and Mark Attendance'),
              ),
            ),
            if (_identifiedStudents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Identified Students:'),
                    ..._identifiedStudents.map((email) => Text(email)).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
