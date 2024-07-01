import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:image/image.dart' as img;

class GenerateReportPage extends StatefulWidget {
  final String imageUrl;

  const GenerateReportPage({Key? key, required this.imageUrl})
      : super(key: key);

  @override
  _GenerateReportPageState createState() => _GenerateReportPageState();
}

class _GenerateReportPageState extends State<GenerateReportPage> {
  bool _analyzing = false;
  List<Map<String, dynamic>> _identifiedStudents = [];

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    setState(() {
      _analyzing = true;
    });

    try {
      final enhancedImageUrl = await _enhanceImage(widget.imageUrl);
      final response = await _callGoogleCloudVisionAPI(enhancedImageUrl);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('API Response: $result'); // Log the API response

        if (result['responses'] != null &&
            result['responses'].isNotEmpty &&
            result['responses'][0].containsKey('faceAnnotations') &&
            result['responses'][0]['faceAnnotations'].isNotEmpty) {
          List<dynamic> faces = result['responses'][0]['faceAnnotations'];
          print(
              'Faces detected: ${faces.length}'); // Log the number of faces detected

          await _compareFaces(faces);
        } else {
          print('No faces detected in the image');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No faces detected in the image')),
          );
        }
      } else {
        print(
            'Failed to analyze image: ${response.body}'); // Log the failure response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to analyze image')),
        );
      }
    } catch (e) {
      print('Analysis failed: $e'); // Log the exception
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      setState(() {
        _analyzing = false;
      });
    }
  }

  Future<String> _enhanceImage(String imageUrl) async {
    // Enhance the image to improve face detection
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      img.Image image = img.decodeImage(response.bodyBytes)!;
      img.Image enhancedImage = img.grayscale(image); // Example enhancement
      final bytes = img.encodeJpg(enhancedImage);

      // Upload enhanced image to Firebase Storage or another service to get a URL
      // For simplicity, returning the original imageUrl here
      return imageUrl;
    } else {
      throw Exception('Failed to load image for enhancement');
    }
  }

  Future<void> _compareFaces(List<dynamic> detectedFaces) async {
    final studentsSnapshot =
        await FirebaseFirestore.instance.collection('Users').get();
    final List<Map<String, dynamic>> registeredStudents =
        studentsSnapshot.docs.map((doc) => doc.data()).toList();

    for (var detectedFace in detectedFaces) {
      List<dynamic>? detectedFaceLandmarks = detectedFace['landmarks'];
      if (detectedFaceLandmarks != null) {
        for (var student in registeredStudents) {
          List<dynamic>? studentFaceLandmarks = student['faceLandmarks'];
          if (studentFaceLandmarks != null) {
            print('Comparing face landmarks...');
            if (_isFaceMatch(detectedFaceLandmarks, studentFaceLandmarks)) {
              _identifiedStudents.add(student);
              print(
                  'Face matched with student: ${student['firstName']} ${student['lastName']}');
              break; // If a match is found, move to the next detected face
            } else {
              print(
                  'Face did not match with student: ${student['firstName']} ${student['lastName']}');
            }
          } else {
            print(
                'Student does not have face landmarks: ${student['firstName']} ${student['lastName']}');
          }
        }
      } else {
        print('Detected face does not have landmarks.');
      }
    }

    setState(() {});
  }

  bool _isFaceMatch(
      List<dynamic> detectedFaceLandmarks, List<dynamic> studentFaceLandmarks) {
    if (detectedFaceLandmarks.length != studentFaceLandmarks.length) {
      return false;
    }

    double threshold = 30.0; // Adjust threshold for better tolerance
    double totalDistance = 0.0;

    for (int i = 0; i < detectedFaceLandmarks.length; i++) {
      double dx = detectedFaceLandmarks[i]['position']['x'] -
          studentFaceLandmarks[i]['position']['x'];
      double dy = detectedFaceLandmarks[i]['position']['y'] -
          studentFaceLandmarks[i]['position']['y'];
      double dz = detectedFaceLandmarks[i]['position']['z'] -
          studentFaceLandmarks[i]['position']['z'];
      totalDistance += sqrt(dx * dx + dy * dy + dz * dz);
    }

    return totalDistance <= threshold;
  }

  Future<http.Response> _callGoogleCloudVisionAPI(String imageUrl) {
    final apiKey = 'AIzaSyAhn64pt_dCPncx3gWoAQW9NUFlnieu52c';
    final uri = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$apiKey');
    final requestPayload = {
      'requests': [
        {
          'image': {
            'source': {'imageUri': imageUrl}
          },
          'features': [
            {'type': 'FACE_DETECTION', 'maxResults': 10}
          ] // Increase maxResults to handle more faces
        }
      ]
    };

    print('Request Payload: $requestPayload'); // Log the request payload

    return http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestPayload),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Report'),
      ),
      body: Center(
        child: _analyzing
            ? CircularProgressIndicator()
            : _identifiedStudents.isNotEmpty
                ? ListView.builder(
                    itemCount: _identifiedStudents.length,
                    itemBuilder: (context, index) {
                      final student = _identifiedStudents[index];
                      return ListTile(
                        title: Text(
                            '${student['firstName']} ${student['lastName']}'),
                        subtitle: Text('ID: ${student['studentId']}'),
                      );
                    },
                  )
                : Text('No faces detected'),
      ),
    );
  }
}
