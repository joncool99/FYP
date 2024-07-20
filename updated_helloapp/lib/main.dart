import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:helloapp/lecturer/Lecturer_Home_Page.dart';
import 'package:helloapp/students/Student_Home_Page.dart';
import 'admin/adminhome.dart';
import 'login.dart';
import 'homepage.dart';
import 'students.dart';
import 'admin/register.dart';
import 'admin/updateinfo.dart';
import 'forgotpassword.dart';
import 'admin/accounts.dart';
import 'timetable/view_timetable.dart';
import 'timetable/timetable_home.dart';
import 'timetable/create_course.dart';
import 'attendance/captureImages.dart';
import 'attendance/uploadImages.dart';
import 'admin/delete_account.dart';
import 'timetable/edit_course.dart';

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
        '/register': (context) => RegisterPage(),
        '/account': (context) => AccountsPage(),
        '/forgotpassword': (context) => const ForgotpasswordPage(),
        '/adminhome': (context) => const AdminhomePage(),
        '/create_course': (context) => TimetableScreen(),
        '/timetable_home': (context) => const TimetableHome(),
        '/view_timetable': (context) => ViewTimetable(),
        '/capture_image': (context) => CaptureImagePage(),
        'delete_account': (context) => DeleteAccountPage(),
        'edit_course': (context) => EditCourseTimetable(courseId: ''),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/update') {
          final user = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => UpdatePage(user: user),
          );
        } else if (settings.name == '/upload_images') {
          final args = settings.arguments as Map<String, dynamic>;
          final imagePath = args['imagePath'] as String;
          return MaterialPageRoute(
            builder: (context) => UploadImagesPage(imagePath: imagePath),
          );
        } else if (settings.name == '/studenthomepage') {
          final args = settings.arguments as Map<String, dynamic>;
          final email = args['email'] as String;
          return MaterialPageRoute(
            builder: (context) => StudentHomePage(email: email),
          );
        } else if (settings.name == '/lecturerhomepage') {
          final args = settings.arguments as Map<String, dynamic>;
          final email = args['email'] as String;
          return MaterialPageRoute(
            builder: (context) => LecturerHomePage(email: email),
          );
        }
        return null;
      },
    );
  }
}
