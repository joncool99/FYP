import 'package:flutter/material.dart';
import 'login.dart';
import 'homepage.dart';
import 'students.dart';

import 'register.dart';
import 'updateinfo.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Name',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/student': (context) => StudentPage(), 
        '/register': (context) => RegisterPage(),
        '/update': (context) => UpdatePage(),
        
        

      },
    );
  }
}
