import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import all screens
import 'screens/LoginScreen.dart';
import 'screens/ChooseRoleScreen.dart';

// Import your Placeholder Home Screens
import 'screens/ParentHomeScreen.dart'; 
import 'screens/DriverHomeScreen.dart'; 
import 'screens/AdminHomeScreen.dart';   


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/choose_role': (context) => const ChooseRoleScreen(),
          
          // Role-specific Home Screens (Now using placeholders)
          '/parent_home': (context) => const ParentHomeScreen(),
          '/driver_home': (context) => const DriverHomeScreen(),
          '/admin_home': (context) => const AdminHomeScreen(),
        },
      ),
    );
  }
}
