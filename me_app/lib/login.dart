import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:me_app/homepage.dart';

void main() {
  runApp(LoginPage());
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Me App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 200,

              color: Colors.blueGrey, // Placeholder for photo widget
              child: Center(
                child: Image.asset(
                  'asset/wallpaper.jpg', // Path to the image in the assets folder
                  fit: BoxFit
                      .cover, // Ensure the image covers the entire container,
                ),
              ),
            ),
            const SizedBox(height: 60),
            TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black))),
            ),
            const SizedBox(height: 20),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black))),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                backgroundColor: const Color.fromARGB(255, 1, 124, 255),
              ),
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
