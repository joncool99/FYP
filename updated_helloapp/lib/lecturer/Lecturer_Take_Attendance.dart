import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

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
  late Interpreter _antiSpoofingInterpreter;
  bool _isModelLoaded = false;
  bool _isAntiSpoofingModelLoaded = false;
  bool _isProcessing = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<String> _identifiedStudents = [];
  int _consecutiveClosedFrames = 0;
  static const int _blinkThreshold = 2;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    print('Loading models...');
    try {
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
      _isModelLoaded = true;
    } catch (e) {
      print('Error loading face recognition model: $e');
      _isModelLoaded = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading face recognition model: $e')),
      );
    }

    try {
      _antiSpoofingInterpreter =
          await Interpreter.fromAsset('assets/FaceAntiSpoofing.tflite');
      _isAntiSpoofingModelLoaded = true;
    } catch (e) {
      print('Error loading anti-spoofing model: $e');
      _isAntiSpoofingModelLoaded = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading anti-spoofing model: $e')),
      );
    }

    setState(() {}); // Update the UI after loading the models
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final extension = p.extension(pickedFile.path).toLowerCase();
        if (extension != '.jpeg' && extension != '.jpg') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a JPEG or JPG image.')),
          );
          return;
        }

        setState(() {
          _imageFile = File(pickedFile.path);
          _identifiedStudents.clear();
        });
      }
    } catch (e) {
      print("Failed to pick image: $e");
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null ||
        !_isModelLoaded ||
        !_isAntiSpoofingModelLoaded ||
        _isProcessing) {
      print(
          'Button disabled. _isProcessing: $_isProcessing, _isModelLoaded: $_isModelLoaded, _isAntiSpoofingModelLoaded: $_isAntiSpoofingModelLoaded, _imageFile: $_imageFile');
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
        final img.Image alignedFaceImage = _alignFace(originalImage, face);

        // Check for spoofing
        final bool isSpoof = await _checkForSpoof(alignedFaceImage);
        if (isSpoof) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Spoof detected! Please try again.')),
          );
          setState(() => _isProcessing = false);
          return;
        }

        if (!_isEyeBlinking(face)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Spoof detected: No eye blink detected!')),
          );
          setState(() => _isProcessing = false);
          return;
        }

        final embeddings = await _getEmbeddings(alignedFaceImage);
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

  Future<bool> _checkForSpoof(img.Image faceImage) async {
    final img.Image resizedImage = img.copyResize(faceImage,
        width: 224, height: 224); // Resizing for model input
    final List input = _imageToByteListFloat32(resizedImage, 224, 128, 128);

    final output = List.filled(1 * 1, 0).reshape([
      1,
      1
    ]); // Assuming the model returns a single value for spoof detection

    _antiSpoofingInterpreter.run(input, output);

    final spoofProbability = output[0][0];

    // Return true if the spoof probability is high
    return spoofProbability > 0.5; // You may adjust this threshold
  }

  bool _isEyeBlinking(Face face) {
    final leftEyeOpenProbability = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpenProbability = face.rightEyeOpenProbability ?? 1.0;

    if (leftEyeOpenProbability < 0.2 && rightEyeOpenProbability < 0.2) {
      _consecutiveClosedFrames++;
    } else {
      _consecutiveClosedFrames = 0;
    }

    return _consecutiveClosedFrames >= _blinkThreshold;
  }

  img.Image _alignFace(img.Image image, Face face) {
    final leftEye = face.getLandmark(FaceLandmarkType.leftEye)!.position;
    final rightEye = face.getLandmark(FaceLandmarkType.rightEye)!.position;
    final dx = rightEye.dx - leftEye.dx;
    final dy = rightEye.dy - leftEye.dy;
    final angle = atan2(dy, dx);

    img.Image alignedImage = img.copyRotate(image, -angle * 180 / pi);

    final alignedFace = img.copyCrop(
      alignedImage,
      face.boundingBox.left.toInt(),
      face.boundingBox.top.toInt(),
      face.boundingBox.width.toInt(),
      face.boundingBox.height.toInt(),
    );

    return alignedFace;
  }

  Future<int> _identifyAndMarkAttendance(
      List<List<double>> embeddingsList) async {
    _identifiedStudents.clear();
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('Users').get();
    int matchedFacesCount = 0;
    Set<String> usedMatches = {};

    for (var newEmbeddings in embeddingsList) {
      double maxSimilarity = -1.0;
      String bestMatch = '';

      newEmbeddings = _normalizeEmbeddings(newEmbeddings);

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final storedEmbeddings = userData['embeddings'] as List<dynamic>?;

        if (storedEmbeddings == null ||
            storedEmbeddings.isEmpty ||
            usedMatches.contains(userDoc.id)) {
          continue;
        }

        final convertedEmbeddings = storedEmbeddings
            .map((e) => e is double ? e : double.tryParse(e.toString()) ?? 0.0)
            .toList();

        final normalizedStoredEmbeddings =
            _normalizeEmbeddings(convertedEmbeddings);

        final similarity = _calculateCosineSimilarity(
            normalizedStoredEmbeddings, newEmbeddings);

        if (similarity.isNaN || similarity.isInfinite) {
          continue;
        }

        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
          bestMatch = userDoc.id;
        }
      }

      if (maxSimilarity > 0.8) {
        usedMatches.add(bestMatch);
        final matchedUserData =
            usersSnapshot.docs.firstWhere((doc) => doc.id == bestMatch).data();
        final firstName = matchedUserData['firstName'] ?? 'Unknown';
        final lastName = matchedUserData['lastName'] ?? 'Unknown';
        final studentId = matchedUserData['studentId'] ?? 'Unknown';
        _identifiedStudents.add('$firstName $lastName (ID: $studentId)');
        await _markAttendance(bestMatch);
        matchedFacesCount++;
      }
    }

    setState(() {});
    return matchedFacesCount;
  }

  List<double> _normalizeEmbeddings(List<double> embeddings) {
    double norm = 0.0;
    for (var value in embeddings) {
      norm += value * value;
    }
    norm = sqrt(norm);

    if (norm == 0.0) {
      return embeddings;
    }

    return embeddings.map((e) => e / norm).toList();
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
      return double.nan;
    }
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

  Future<List<double>> _getEmbeddings(img.Image faceImage) async {
    print('Getting embeddings...');
    final img.Image resizedImage =
        img.copyResize(faceImage, width: 112, height: 112);
    final List input = _imageToByteListFloat32(resizedImage, 112, 128, 128);

    final output = List.filled(1 * 192, 0).reshape([1, 192]);

    _interpreter.run(input, output);

    return List<double>.from(output[0]);
  }

  List _imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    final Float32List convertedBytes =
        Float32List(1 * inputSize * inputSize * 3);
    final buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < inputSize; j++) {
        final int pixel = image.getPixelSafe(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  @override
  void dispose() {
    _interpreter.close();
    _antiSpoofingInterpreter.close(); // Dispose the anti-spoofing interpreter
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lecturer Take Attendance'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _imageFile != null
                    ? Image.file(_imageFile!)
                    : Center(child: Text('Upload Class photo')),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed:
                          _isProcessing || !_isModelLoaded ? null : _pickImage,
                      child: Text('Pick Image'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: _isProcessing ||
                              !_isModelLoaded ||
                              !_isAntiSpoofingModelLoaded
                          ? null
                          : _processImage,
                      child: Text('Process and Mark Attendance'),
                    ),
                  ),
                ],
              ),
              if (_identifiedStudents.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Identified Students:'),
                      ..._identifiedStudents.map((name) => Text(name)).toList(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
