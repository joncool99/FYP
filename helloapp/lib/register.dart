import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

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

  // Function to upload the image to Firebase Storage
  Future<void> _uploadImageToStorage(String uid) async {
    if (_image == null) return;

    try {
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images/$uid.jpg'); // Use the user's UID
      UploadTask uploadTask = storageRef.putFile(_image!);

      // Wait for the upload to complete
      await uploadTask.whenComplete(() async {
        // Get the download URL after the upload is finished
        _imageUrl = await storageRef.getDownloadURL();
        print('Image uploaded successfully!');
      });
    } catch (e) {
      print('Failed to upload image: $e');
      // Handle the error appropriately (e.g., display a message to the user)
    }
  }

  // Function to add user details to Firestore
  Future<void> addUserDetails(String firstName, String lastName, String email,
      String major, String studentId, String uid, String? imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(email).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'major': major,
        'studentId': studentId,
        'imageUrl': imageUrl, // Store the image URL
      });
      print('User details saved to Firestore!');
    } catch (e) {
      print('Failed to save user details: $e');
      // Handle the error appropriately (e.g., display a message to the user)
    }
  }

  // Function to register the user (now includes image upload)
  Future<void> _register() async {
    try {
      // Create user account
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // Upload image to Firebase Storage (if selected)
      if (_image != null) {
        await _uploadImageToStorage(uid);
      }

      // Add user details to Firestore
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

      // Navigate to the home page on successful registration
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
                          child: Text('insert your face  photo here',
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
