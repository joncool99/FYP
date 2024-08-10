import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p; // Import the path package

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
      print('Model loaded successfully');
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
        // Check if the file is a JPEG or JPG
        final extension = p.extension(pickedFile.path).toLowerCase();
        if (extension != '.jpeg' && extension != '.jpg') {
          // Show an error message if the file is not a JPEG or JPG
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a JPEG or JPG image.')),
          );
          return;
        }

        setState(() {
          _imageFile = File(pickedFile.path);
          _identifiedStudents.clear(); // Clear the identified students list
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
        // Apply histogram equalization before alignment
        final img.Image equalizedImage =
            _applyHistogramEqualization(originalImage);

        final img.Image alignedFaceImage = _alignFace(equalizedImage, face);
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

  img.Image _applyHistogramEqualization(img.Image image) {
    // Create histogram
    List<int> histogram = List.filled(256, 0);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int brightness = img.getRed(image.getPixel(x, y));
        histogram[brightness]++;
      }
    }

    // Create cumulative distribution function (CDF)
    List<int> cdf = List.filled(256, 0);
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }

    // Normalize CDF
    int minCDF = cdf.firstWhere((value) => value != 0);
    for (int i = 0; i < 256; i++) {
      cdf[i] = ((cdf[i] - minCDF) / (image.width * image.height - minCDF) * 255)
          .round();
    }

    // Apply equalization
    img.Image equalizedImage = img.Image.from(image);
    for (int y = 0; y < equalizedImage.height; y++) {
      for (int x = 0; x < equalizedImage.width; x++) {
        int pixel = equalizedImage.getPixel(x, y);
        int r = cdf[img.getRed(pixel)];
        int g = cdf[img.getGreen(pixel)];
        int b = cdf[img.getBlue(pixel)];
        equalizedImage.setPixel(x, y, img.getColor(r, g, b));
      }
    }

    return equalizedImage;
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
    Set<String> usedMatches = {}; // To track already matched users

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

      if (maxSimilarity > 0.85) {
        // Adjusted threshold
        usedMatches.add(bestMatch); // Mark this user as matched
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
                      onPressed: _isProcessing || !_isModelLoaded
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
