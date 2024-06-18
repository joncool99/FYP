import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'adminhome.dart';
import 'login.dart';
import 'homepage.dart';
import 'students.dart';
import 'register.dart';
import 'updateinfo.dart';
import 'forgotpassword.dart';
import 'accounts.dart';

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
        '/account': (context) => AccountsPage(),
        '/forgotpassword': (context) => const ForgotpasswordPage(),
        '/adminhome': (context) => const AdminhomePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/update') {
          final user = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return UpdatePage(user: user);
            },
          );
        }
        return null; // Let `MaterialApp` handle the rest of the routes
      },
    );
  }
}
 
