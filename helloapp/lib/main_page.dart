import 'package:flutter/material.dart';
import 'login.dart';
import 'homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomePage();
          } else {
            return const LoginPage();
          }
        },
      ) 
    );
  }
}
