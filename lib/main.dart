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

// --- 1. Define the Initializer/Future ---
// You will likely check if a user is logged in here later.
Future<String> _initializeAppAndDetermineRoute() async {
  // 1. Ensure Flutter binding is initialized (done in main, but safe here)
  // 2. Initialize Firebase (Already done in main, but let's keep it here for clarity if you moved it)
  
  // NOTE: Assuming Firebase.initializeApp() is done in the main function.
  
  // 3. Simulate other loading/authentication checks (e.g., SharedPreferences, Auth state)
  await Future.delayed(const Duration(seconds: 2)); // Wait 2 seconds for effect
  
  // *** LOGIC TO DETERMINE START ROUTE GOES HERE ***
  // e.g., if (userIsLoggedIn) return '/choose_role'; else return '/login';
  
  return '/login'; // Default route after loading
}
// ----------------------------------------

void main() async {
  // 1. Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize Firebase FIRST, before running the app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const HafilatyApp());
}

// --- 2. Create a dedicated Splash Screen Widget (Pure Flutter) ---
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blue, // Use your app's primary color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace with your actual logo/image asset
            FlutterLogo(size: 100, style: FlutterLogoStyle.horizontal, textColor: Colors.white), 
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 10),
            Text(
              'جاري التحميل...', // Loading... in Arabic
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
// ----------------------------------------


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
        
        // ** MODIFICATION 1: Use the 'home' property to handle the initial loading **
        home: FutureBuilder<String>(
          future: _initializeAppAndDetermineRoute(),
          builder: (context, snapshot) {
            // Display the splash screen while loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen(); // Show our custom splash widget
            }
            
            // Check for errors during initialization
            if (snapshot.hasError) {
              return const Center(child: Text("An error occurred during startup."));
            }

            // Once loading is complete, navigate to the determined route
            // The snapshot.data contains the determined initial route string
            if (snapshot.hasData) {
              // We use Navigator.pushReplacement to start the app on the determined route
              // and ensure the back button doesn't lead back to the splash screen.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 Navigator.pushReplacementNamed(context, snapshot.data!);
              });
              
              // Return an empty container while the navigation happens
              return Container(); 
            }

            // Fallback (Should not happen)
            return const Center(child: Text("Starting app..."));
          },
        ),
        
        // ** MODIFICATION 2: Remove initialRoute since 'home' now controls the start **
        // initialRoute: '/login', // REMOVED
        
        // ** MODIFICATION 3: Keep all named routes for navigation within the app **
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