import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class StudentRegisterFacePage extends StatefulWidget {
  final CameraDescription camera;

  const StudentRegisterFacePage({Key? key, required this.camera})
      : super(key: key);

  @override
  _StudentRegisterFacePageState createState() =>
      _StudentRegisterFacePageState();
}

class _StudentRegisterFacePageState extends State<StudentRegisterFacePage> {
  late CameraController _controller;
  bool _isProcessing = false;
  late Interpreter _interpreter;
  bool _isModelLoaded = false;
  bool _isCameraInitialized = false;
  bool _isFaceRegistered = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
    _checkIfFaceIsRegistered();
  }

  Future<void> _initializeCamera() async {
    print('Initializing camera...');
    final cameras = await availableCameras();
    CameraDescription? frontCamera;

    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }

    if (frontCamera != null) {
      _controller = CameraController(frontCamera, ResolutionPreset.high);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Front camera not found.')),
      );
      return;
    }

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

  Future<void> _checkIfFaceIsRegistered() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.email)
            .get();

        if (docSnapshot.exists && docSnapshot.data()?['embeddings'] != null) {
          setState(() {
            _isFaceRegistered = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face already registered.')),
          );
        }
      }
    } catch (e) {
      print('Error checking face registration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking face registration: $e')),
      );
    }
  }

  Future<void> _captureAndRegisterFace() async {
    if (!_controller.value.isInitialized ||
        !_isModelLoaded ||
        _isProcessing ||
        _isFaceRegistered) {
      print(
          'Button disabled. _isProcessing: $_isProcessing, _isModelLoaded: $_isModelLoaded, _isFaceRegistered: $_isFaceRegistered, _controller initialized: ${_controller.value.isInitialized}');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Show an alert dialog to remind the user that face registration can only be done once
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Face Registration'),
            content: const Text('Face registration can only be done once.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );

      List<List<double>> embeddingsList = [];
      List<Map<String, dynamic>> landmarksList = [];

      for (int i = 0; i < 5; i++) {
        print('Capturing image...');
        final XFile imageFile = await _controller.takePicture();
        print('Picture taken: ${imageFile.path}');
        final Uint8List imageBytes = await imageFile.readAsBytes();

        print('Detecting faces...');
        final GoogleVisionImage visionImage =
        GoogleVisionImage.fromFilePath(imageFile.path);
        final FaceDetector faceDetector = GoogleVision.instance.faceDetector(
          const FaceDetectorOptions(enableLandmarks: true),
        );
        final List<Face> faces = await faceDetector.processImage(visionImage);

        if (faces.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No face detected! Please try again.')),
          );
          setState(() => _isProcessing = false);
          return;
        }

        print('Extracting and aligning face...');
        final Face face = faces[0];
        final img.Image originalImage = img.decodeImage(imageBytes)!;

        // Apply histogram equalization to improve image quality
        final img.Image equalizedImage =
        _applyHistogramEqualization(originalImage);

        final img.Image alignedFaceImage = _alignFace(equalizedImage, face);

        final embeddings = await _getEmbeddings(alignedFaceImage);
        embeddingsList.add(embeddings);

        // Capture landmarks
        final landmarks = {
          'leftEye': {
            'x': face.getLandmark(FaceLandmarkType.leftEye)!.position.dx,
            'y': face.getLandmark(FaceLandmarkType.leftEye)!.position.dy
          },
          'rightEye': {
            'x': face.getLandmark(FaceLandmarkType.rightEye)!.position.dx,
            'y': face.getLandmark(FaceLandmarkType.rightEye)!.position.dy
          },
          'noseBase': {
            'x': face.getLandmark(FaceLandmarkType.noseBase)!.position.dx,
            'y': face.getLandmark(FaceLandmarkType.noseBase)!.position.dy
          },
        };
        landmarksList.add(landmarks);

        await Future.delayed(Duration(seconds: 1));
      }

      final averageEmbeddings =
      _normalizeEmbeddings(_calculateAverageEmbeddings(embeddingsList));

      await _saveEmbeddingsAndLandmarksToFirestore(
          averageEmbeddings, landmarksList);

      setState(() {
        _isFaceRegistered = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Face registered successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during face registration: $e')),
      );
      print('Error during face registration: $e');
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
    final leftEye = face.getLandmark(FaceLandmarkType.leftEye)?.position;
    final rightEye = face.getLandmark(FaceLandmarkType.rightEye)?.position;
    final noseBase = face.getLandmark(FaceLandmarkType.noseBase)?.position;

    if (leftEye == null || rightEye == null || noseBase == null) {
      return image;
    }

    // Calculate the angle for rotation
    final dx = rightEye.dx - leftEye.dx;
    final dy = rightEye.dy - leftEye.dy;
    final angle = atan2(dy, dx) * 180 / pi;

    // Get the center of the image
    final centerX = image.width / 2;
    final centerY = image.height / 2;

    // Create a new image with the same size as the original
    final rotatedImage = img.Image(image.width, image.height);

    // Rotate the image manually
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        // Calculate the original coordinates before rotation
        final xOffset = x - centerX;
        final yOffset = y - centerY;

        final rotatedX = (xOffset * cos(angle * pi / 180) - yOffset * sin(angle * pi / 180) + centerX).round();
        final rotatedY = (xOffset * sin(angle * pi / 180) + yOffset * cos(angle * pi / 180) + centerY).round();

        if (rotatedX >= 0 && rotatedX < image.width && rotatedY >= 0 && rotatedY < image.height) {
          rotatedImage.setPixel(x, y, image.getPixel(rotatedX, rotatedY));
        }
      }
    }

    return rotatedImage;
  }

  Future<List<double>> _getEmbeddings(img.Image image) async {
    final imageBytes = Uint8List.fromList(img.encodeJpg(image));
    final inputImage = img.Image.fromBytes(image.width, image.height, imageBytes);

    final input = TensorImage.fromImage(inputImage);
    final output = TensorBuffer.createFixedSize(<int>[1, 128], TfLiteType.float32);

    _interpreter.run(input.buffer, output.buffer);

    final embeddings = output.getDoubleList();
    return embeddings;
  }

  List<double> _calculateAverageEmbeddings(List<List<double>> embeddingsList) {
    final numEmbeddings = embeddingsList[0].length;
    final averageEmbeddings = List.filled(numEmbeddings, 0.0);

    for (var embeddings in embeddingsList) {
      for (int i = 0; i < numEmbeddings; i++) {
        averageEmbeddings[i] += embeddings[i];
      }
    }

    for (int i = 0; i < numEmbeddings; i++) {
      averageEmbeddings[i] /= embeddingsList.length;
    }

    return averageEmbeddings;
  }

  List<double> _normalizeEmbeddings(List<double> embeddings) {
    final norm = sqrt(embeddings.fold(0.0, (sum, e) => sum + e * e));
    if (norm == 0.0) return embeddings;

    return embeddings.map((e) => e / norm).toList();
  }

  Future<void> _saveEmbeddingsAndLandmarksToFirestore(
      List<double> embeddings, List<Map<String, dynamic>> landmarksList) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docRef = FirebaseFirestore.instance.collection('Users').doc(user.email);
        await docRef.set({
          'embeddings': embeddings,
          'landmarks': landmarksList,
        });
      }
    } catch (e) {
      print('Error saving data to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data to Firestore: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Face'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isCameraInitialized)
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.5,
              child: CameraPreview(_controller),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _captureAndRegisterFace,
            child: Text(
              _isProcessing
                  ? 'Processing...'
                  : _isFaceRegistered
                  ? 'Face Registered'
                  : 'Register Face',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
