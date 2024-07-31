import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class LiveFaceRecognitionPage extends StatefulWidget {
  final CameraDescription camera;

  const LiveFaceRecognitionPage({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  _LiveFaceRecognitionPageState createState() =>
      _LiveFaceRecognitionPageState();
}

class _LiveFaceRecognitionPageState extends State<LiveFaceRecognitionPage> {
  late CameraController _controller;
  bool _isProcessing = false;
  late Interpreter _interpreter;
  bool _isModelLoaded = false;
  bool _isCameraInitialized = false;
  List<String> _identifiedStudents = [];
  bool _showIdentifyingMessage = false;

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

    setState(() {
      _isProcessing = true;
      _showIdentifyingMessage = true;
    });

    try {
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
          FaceDetectorOptions(enableLandmarks: true),
        );
        final List<Face> faces = await faceDetector.processImage(visionImage);

        if (faces.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No face detected! Please try again.')),
          );
          setState(() {
            _isProcessing = false;
            _showIdentifyingMessage = false;
          });
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

        await Future.delayed(Duration(seconds: 1)); // Delay between captures
      }

      // Calculate average embeddings for verification
      final averageNewEmbeddings =
          _calculateAverageEmbeddings(newEmbeddingsList);

      // Identify the face with stored embeddings
      final matchedFacesCount = await _identifyStudents(averageNewEmbeddings);

      if (matchedFacesCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Students identified successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No matching faces found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during face verification: $e')),
      );
      print('Error during face verification: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _showIdentifyingMessage = false;
      });
    }
  }

  Future<int> _identifyStudents(List<double> newEmbeddings) async {
    _identifiedStudents.clear();
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('Users').get();
    int matchedFacesCount = 0;

    for (var userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final storedEmbeddings = userData['embeddings'] as List<dynamic>?;

      if (storedEmbeddings == null) {
        print('No embeddings found for user: ${userDoc.id}');
        continue;
      }

      final convertedEmbeddings = storedEmbeddings
          .map((e) => e is double ? e : double.tryParse(e.toString()) ?? 0.0)
          .toList();

      final similarity =
          _calculateCosineSimilarity(convertedEmbeddings, newEmbeddings);
      if (similarity > 0.7) {
        // Adjust threshold for higher accuracy
        final firstName = userData['firstName'] ?? 'Unknown';
        final lastName = userData['lastName'] ?? 'Unknown';
        final studentId = userData['studentId'] ?? 'Unknown';
        _identifiedStudents.add('$firstName $lastName (ID: $studentId)');
        matchedFacesCount++;
      }
    }
    setState(() {});
    return matchedFacesCount;
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

  List<double> _calculateAverageEmbeddings(List<List<double>> embeddingsList) {
    final int length = embeddingsList.first.length;
    final List<double> averageEmbeddings = List.filled(length, 0.0);

    for (List<double> embeddings in embeddingsList) {
      for (int i = 0; i < length; i++) {
        averageEmbeddings[i] += embeddings[i];
      }
    }

    for (int i = 0; i < length; i++) {
      averageEmbeddings[i] /= embeddingsList.length;
    }

    return averageEmbeddings;
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
        final int pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
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
        title: Text('Live Face Recognition'),
      ),
      body: Stack(
        children: [
          if (!_isCameraInitialized || !_isModelLoaded)
            Center(child: CircularProgressIndicator())
          else
            CameraPreview(_controller),
          if (_showIdentifyingMessage)
            Align(
              alignment: Alignment.center,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Identifying, please look in the camera...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: _isProcessing || !_isModelLoaded
                    ? null
                    : _captureAndVerifyFace,
                child: Icon(Icons.camera),
              ),
            ),
          ),
          if (_identifiedStudents.isNotEmpty)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Identified Students:',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    ..._identifiedStudents.map((name) =>
                        Text(name, style: TextStyle(color: Colors.white))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
