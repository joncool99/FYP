import 'package:flutter/material.dart';

class Lecturer_CaptureImgPage extends StatefulWidget {
  @override
  _Lecturer_CaptureImgPageState createState() => _Lecturer_CaptureImgPageState();
}

class _Lecturer_CaptureImgPageState extends State<Lecturer_CaptureImgPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capture Image'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/sample_image.png'), // Replace with your sample image path
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Do something if needed when the button is pressed
              },
              child: Text('Capture Image'),
            ),
          ],
        ),
      ),
    );
  }
}