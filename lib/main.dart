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
    // FIX: Wrap MaterialApp in Directionality for proper RTL support (Arabic)
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        title: 'Hafilaty',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        // 2. Set your LoginScreen as the starting page
        home: const LoginScreen(), 
      ),
    );
  }
}