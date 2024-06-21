import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      final response = await _callGoogleCloudVisionAPI(widget.imageUrl);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('API Response: $result'); // Log the API response

        if (result['responses'][0].containsKey('faceAnnotations')) {
          List<dynamic> faces = result['responses'][0]['faceAnnotations'];
          print(
              'Faces detected: ${faces.length}'); // Log the number of faces detected

          await _compareFaces(faces);
        } else {
          print(
              'No faces detected in the image'); // Log if no faces are detected
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
    } finally {
      setState(() {
        _analyzing = false;
      });
    }
  }

  Future<void> _compareFaces(List<dynamic> detectedFaces) async {
    final studentsSnapshot =
        await FirebaseFirestore.instance.collection('Users').get();
    final List<Map<String, dynamic>> registeredStudents =
        studentsSnapshot.docs.map((doc) => doc.data()).toList();

    // Placeholder logic for matching faces
    // Replace with actual face comparison logic
    for (int i = 0;
        i < detectedFaces.length && i < registeredStudents.length;
        i++) {
      _identifiedStudents.add(registeredStudents[i]);
    }

    setState(() {});
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
            {'type': 'FACE_DETECTION'}
          ]
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
