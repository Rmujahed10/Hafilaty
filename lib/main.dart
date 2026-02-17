import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. Added for Auth check
import 'firebase_options.dart';

// --- Import all your screens ---
// Make sure these paths match your folder structure!
import 'screens/LoginScreen.dart';
import 'screens/ChooseRoleScreen.dart';
import 'screens/RoleHomeScreen.dart'; 
import 'screens/EditAccountScreen.dart'; 
// import 'screens/RegistrationScreen.dart'; // Optional: if you use named routes for it

// --- 1. The Startup Logic ---
Future<Widget> _determineStartScreen() async {
  // Wait a moment for the Splash Screen effect (Optional)
  await Future.delayed(const Duration(seconds: 2));

  // 2. CHECK AUTH STATE: Is a user already logged in?
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // User is logged in -> Go to Home
    return const RoleHomeScreen();
  } else {
    // No user -> Go to Login
    return const LoginScreen();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const HafilatyApp());
}

// --- 2. Splash Screen ---
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1B36), // Your App's Dark Blue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 80, color: Colors.white), // Simple Logo
            SizedBox(height: 20),
            Text(
              'حافلاتي', // Hafilaty
              style: TextStyle(
                color: Colors.white, 
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                fontFamily: 'HafilatyArabic',
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Color(0xFF6A994E)), // Green Accent
            SizedBox(height: 10),
            Text(
              'جاري التحميل...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. The App Widget ---
class HafilatyApp extends StatelessWidget {
  const HafilatyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Force RTL for Arabic
      child: MaterialApp(
        title: 'Hafilaty',
        debugShowCheckedModeBanner: false, // Removes the "Debug" banner
        theme: ThemeData(
          primaryColor: const Color(0xFF0D1B36),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: const Color(0xFF6A994E),
          ),
          fontFamily: 'HafilatyArabic', // Use a nice Arabic font if you have it
        ),
        
        // ** The Smart Home Property **
        // Instead of string routes, we decide the WIDGET here.
        home: FutureBuilder<Widget>(
          future: _determineStartScreen(),
          builder: (context, snapshot) {
            // 1. While loading, show Splash
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            
            // 2. If valid screen determined, return it
            if (snapshot.hasData) {
              return snapshot.data!;
            }

            // 3. Error case fallback
            return const Scaffold(body: Center(child: Text("Error loading app")));
          },
        ),

        // ** Named Routes **
        // Use these for navigation within the app (e.g., Navigator.pushNamed)
        routes: {
          '/login': (context) => const LoginScreen(),
          '/choose_role': (context) => const ChooseRoleScreen(),
          '/role_home': (context) => const RoleHomeScreen(),
          '/edit_profile': (context) => const EditAccountScreen(),
        },
      ),
    );
  }
}