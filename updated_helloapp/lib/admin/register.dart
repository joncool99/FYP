import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _image;
  String? _imageUrl;
  List<dynamic>? _faceLandmarks;

  @override
  void dispose() {
    _emailController.dispose();
    _studentIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _majorController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
        } else {
          print('No image selected.');
        }
      });
    } catch (e) {
      print("Failed to pick image: $e");
    }
  }

  Future<void> _getFaceLandmarks(File image) async {
    try {
      final bytes = image.readAsBytesSync();
      final base64Image = base64Encode(bytes);

      final requestPayload = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'FACE_DETECTION', 'maxResults': 1}
            ]
          }
        ]
      };

      final response = await http.post(
        Uri.parse(
            'https://vision.googleapis.com/v1/images:annotate?key=AIzaSyAhn64pt_dCPncx3gWoAQW9NUFlnieu52c'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestPayload),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print(
            'Face landmarks result: $result'); // Log the API response for debugging

        if (result['responses'] != null &&
            result['responses'].isNotEmpty &&
            result['responses'][0].containsKey('faceAnnotations') &&
            result['responses'][0]['faceAnnotations'].isNotEmpty) {
          setState(() {
            _faceLandmarks =
                result['responses'][0]['faceAnnotations'][0]['landmarks'];
          });
        } else {
          print('No face landmarks detected');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No face landmarks detected in the image')),
          );
        }
      } else {
        print('Failed to get face landmarks: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get face landmarks')),
        );
      }
    } catch (e) {
      print('Failed to get face landmarks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get face landmarks: $e')),
      );
    }
  }

  Future<void> _uploadImageToStorage(String uid) async {
    if (_image == null) return;

    try {
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images/$uid.jpg'); // Use the user's UID
      UploadTask uploadTask = storageRef.putFile(_image!);

      await uploadTask.whenComplete(() async {
        _imageUrl = await storageRef.getDownloadURL();
        print('Image uploaded successfully!');
      });
    } catch (e) {
      print('Failed to upload image: $e');
    }
  }

  Future<void> addUserDetails(String firstName, String lastName, String email,
      String major, String studentId, String uid, String? imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(email).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'major': major,
        'studentId': studentId,
        'imageUrl': imageUrl,
        'faceLandmarks': _faceLandmarks, // Store the face landmarks
      });
      print('User details saved to Firestore!');
    } catch (e) {
      print('Failed to save user details: $e');
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      if (_image != null) {
        await _uploadImageToStorage(uid);
        await _getFaceLandmarks(_image!); // Get face landmarks
      }

      await addUserDetails(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _emailController.text.trim(),
        _majorController.text.trim(),
        _studentIdController.text.trim(),
        uid,
        _imageUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Successful')),
      );

      Navigator.pushNamed(context, '/adminhome');
    } catch (e) {
      print("Failed to sign up: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 100,
                  width: 20,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.blue),
                  child: _image == null
                      ? const Center(
                          child: Text('Insert your face photo here',
                              style: TextStyle(color: Colors.white)))
                      : Image.file(_image!),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your student ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _majorController,
                decoration: const InputDecoration(
                  labelText: 'Major',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your major';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
