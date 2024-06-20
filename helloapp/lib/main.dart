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
import 'timetable/view_timetable.dart';
import 'timetable/timetable_home.dart';
import 'timetable/create_course.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        '/create_course': (context) =>  TimetableScreen(),
        '/timetable_home': (context) => const TimetableHome(),
        '/view_timetable': (context) => ViewTimetableScreen(),
        
      
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/update') {
          final user = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => UpdatePage(user: user),
          );
        }
        return null;
      },
    );
  }
}
