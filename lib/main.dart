import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart'; // استيراد المكتبة
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- استيراد الشاشات ---
import 'screens/LoginScreen.dart';
import 'screens/ChooseRoleScreen.dart';
import 'screens/RoleHomeScreen.dart';
import 'screens/EditAccountScreen.dart';
import 'screens/AdminHome.dart';
import 'screens/StudentsManagementScreen.dart';
import 'screens/BusManagementScreen.dart';
import 'screens/ParentHomeScreen.dart';
import 'screens/RegistrationRequests.dart';
import 'screens/ManageChildScreen.dart';
import 'screens/editDeleteChild.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة فيربايس
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تهيئة مكتبة الترجمة
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('ar', null);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations', // تأكد من إنشاء المجلد والملفات فيه
      fallbackLocale: const Locale('ar'),
      child: const HafilatyApp(),
    ),
  );
}

// --- 1. منطق تحديد الشاشة الأولى ---
Future<Widget> _determineStartScreen() async {
  await Future.delayed(const Duration(seconds: 2));
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    return const RoleHomeScreen();
  } else {
    return const LoginScreen();
  }
}

// --- 2. شاشة التحميل (Splash Screen) ---
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B36),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_bus, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'login_title'.tr(), // استخدام الترجمة حتى في السلاش
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Color(0xFF6A994E)),
          ],
        ),
      ),
    );
  }
}

// --- 3. ويدجت التطبيق الرئيسية ---
class HafilatyApp extends StatelessWidget {
  const HafilatyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // تم حذف Directionality اليدوي هنا لأنه يسبب الخطأ
    // MaterialApp ستقوم بالمهمة بناءً على لغة الـ context
    return MaterialApp(
      title: 'Hafilaty',
      debugShowCheckedModeBanner: false,

      // إعدادات الترجمة والاتجاه التلقائي
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: ThemeData(
        primaryColor: const Color(0xFF0D1B36),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF6A994E),
        ),
        fontFamily: context.locale.languageCode == 'ar'
            ? 'HafilatyArabic' // اسم الخط العربي في pubspec
            : 'Roboto',
      ),

      home: FutureBuilder<Widget>(
        future: _determineStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            return snapshot.data!;
          }
          return const Scaffold(body: Center(child: Text("Error loading app")));
        },
      ),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/choose_role': (context) => const ChooseRoleScreen(),
        '/role_home': (context) => const RoleHomeScreen(),
        '/edit_profile': (context) => const EditAccountScreen(),
        '/students_management': (context) => const StudentsManagementScreen(),
        '/AdminHome': (context) => const AdminHome(),
        '/bus_management': (context) => const BusManagementScreen(),
        '/parent_home': (context) => const ParentHomeScreen(),
        '/registration_requests': (context) => const RegistrationRequests(),
        '/manage_child': (_) => const ManageChildScreen(),
        "/editDeleteChild": (context) => const EditDeleteChildScreen(),
        
      },
    );
  }
}
