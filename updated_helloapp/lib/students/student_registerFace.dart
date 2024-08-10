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
  List<List<double>> embeddingsList = [];
  List<Map<String, dynamic>> landmarksList = [];

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

  Future<void> _captureAndRegisterFace() async {
    if (!_controller.value.isInitialized || !_isModelLoaded || _isProcessing) {
      print(
          'Button disabled. _isProcessing: $_isProcessing, _isModelLoaded: $_isModelLoaded, _controller initialized: ${_controller.value.isInitialized}');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      for (int i = 0; i < 5; i++) {
        print('Capturing image...');
        final XFile imageFile = await _controller.takePicture();
        print('Picture taken: ${imageFile.path}');
        final Uint8List imageBytes = await imageFile.readAsBytes();

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

        print('Saving face image...');
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String faceImagePath = path.join(appDocDir.path,
            'face_${DateTime.now().millisecondsSinceEpoch}.png');
        final File faceImageFile = File(faceImagePath);
        faceImageFile.writeAsBytesSync(img.encodePng(alignedFaceImage));

        await Future.delayed(Duration(seconds: 1));
      }

      final averageEmbeddings =
          _normalizeEmbeddings(_calculateAverageEmbeddings(embeddingsList));

      await _saveEmbeddingsAndLandmarksToFirestore(
          averageEmbeddings, landmarksList);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Face registered successfully!')),
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
    final leftEye = face.getLandmark(FaceLandmarkType.leftEye)!.position;
    final rightEye = face.getLandmark(FaceLandmarkType.rightEye)!.position;
    final dx = rightEye.dx - leftEye.dx;
    final dy = rightEye.dy - leftEye.dy;
    final angle = atan2(dy, dx);

    if (angle.isNaN || angle.isInfinite) {
      print('Invalid angle: $angle');
      return image;
    }

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

  Future<void> _saveEmbeddingsAndLandmarksToFirestore(
      List<double> embeddings, List<Map<String, dynamic>> landmarksList) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.email)
            .set({
          'embeddings': embeddings,
          'landmarks':
              landmarksList.last, // Store only the last set of landmarks
        }, SetOptions(merge: true));
        print('Face embeddings and landmarks saved to Firestore!');
      }
    } catch (e) {
      print('Failed to save face embeddings and landmarks: $e');
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

  List<double> _normalizeEmbeddings(List<double> embeddings) {
    double magnitude = sqrt(embeddings.fold(0.0, (sum, e) => sum + e * e));
    return embeddings.map((e) => e / magnitude).toList();
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
        if (pixelIndex < buffer.length) {
          final int pixel = image.getPixelSafe(j, i);
          buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
          buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
          buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
        }
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
        title: Text('Register Face'),
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
                  : _captureAndRegisterFace,
              child: Text('Capture and Register Face'),
            ),
          ),
        ],
      ),
    );
  }
}
