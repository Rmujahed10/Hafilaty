import 'package:flutter/material.dart';
// 1. Import your new screen file
import 'screens/login_screen.dart'; 

void main() {
  runApp(const HafilatyApp());
}

class HafilatyApp extends StatelessWidget {
  const HafilatyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        title: 'Hafilaty',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'HafilatyArabic', 
        ),
        home: const LoginScreen(), 
      ),
    );
  }
}