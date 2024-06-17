import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'adminhome.dart';
import 'login.dart';
import 'homepage.dart';
import 'students.dart';
import 'register.dart';
import 'updateinfo.dart';
import 'forgotpassword.dart';

void main() async {
  print('-- main');

  WidgetsFlutterBinding.ensureInitialized();
  print('-- WidgetsFlutterBinding.ensureInitialized');

  await Firebase.initializeApp();
  print('-- main: Firebase.initializeApp');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      initialRoute: '/',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => HomePage(),
        '/student': (context) => StudentPage(),
        '/register': (context) => RegisterPage(),
        '/update': (context) => UpdatePage(),
        '/forgotpassword': (context) => const ForgotpasswordPage(),
        '/adminhome': (context) => const AdminhomePage(),
      },
    );
  }
}
