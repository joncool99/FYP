import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'generate_report.dart';

class UploadImagesPage extends StatefulWidget {
  final String imagePath;

  const UploadImagesPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  _UploadImagesPageState createState() => _UploadImagesPageState();
}

class _UploadImagesPageState extends State<UploadImagesPage> {
  late File _image;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _image = File(widget.imagePath);
  }

  Future<void> _uploadFile() async {
    if (!_image.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File does not exist at path: ${_image.path}')),
      );
      return;
    }

    setState(() {
      _uploading = true;
    });

    try {
      final fileName = _image.path.split('/').last;
      final firebaseStorageRef =
          FirebaseStorage.instance.ref().child('group_photos/$fileName');
      await firebaseStorageRef.putFile(_image);
      final imageUrl = await firebaseStorageRef.getDownloadURL();
      print('Image URL: $imageUrl'); // Log the image URL

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GenerateReportPage(imageUrl: imageUrl),
        ),
      );
    } catch (e) {
      print('Upload failed: $e'); // Log the exception
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Images'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image.existsSync() ? Image.file(_image) : Text('File not found'),
            const SizedBox(height: 20),
            _uploading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _uploadFile,
                    child: const Text('Upload Image'),
                  ),
          ],
        ),
      ),
    );
  }
}
