import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 💡 IMPORTANT: Switch to Cloud Firestore for role lookup
import 'package:cloud_firestore/cloud_firestore.dart'; 

import 'ChooseRoleScreen.dart';

// --- Color Constants (Maintaining original color values from your provided code) ---
const Color _kDarkBlue = Color(0xFF0D1B36);
const Color _kGreenAccent = Color(0xFF6A994E);


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Added FormKey for validation
  bool _isLoading = false; 

// --- Crucial: Define DB keys and Routes (Ensure these match your main.dart routes)---
  static const String PARENT_KEY = 'parent';
  static const String DRIVER_KEY = 'driver';
  // Renamed 'SUPERVISOR_KEY' to 'admin' to match the ChooseRoleScreen
  static const String ADMIN_KEY = 'admin'; 

  // Define Navigation Routes (MUST match main.dart routes)
  static const String PARENT_HOME_ROUTE = '/parent_home'; 
  static const String DRIVER_HOME_ROUTE = '/driver_home'; 
  static const String ADMIN_HOME_ROUTE = '/admin_home'; 

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  // Helper function to convert phone number to a Firebase-compatible email
  // MUST match the format used during registration!
  String _convertToAuthEmail(String phone) {
    final cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return '$cleanedPhone@hafilatyapp.com'; 
  }

  // ----------------------------------------------------
  // CORE ROLE CHECK AND NAVIGATION LOGIC (The 'route' function equivalent)
  // ----------------------------------------------------
  Future<void> _checkRoleAndNavigate(User user) async {
    try {
      // 1. Get the Document Snapshot from Firestore
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (documentSnapshot.exists) {
        final String? userRole = documentSnapshot.get('role');
        String destinationRoute;

        // 2. Determine the correct destination route
        if (userRole == PARENT_KEY) {
          destinationRoute = PARENT_HOME_ROUTE;
        } else if (userRole == DRIVER_KEY) {
          destinationRoute = DRIVER_HOME_ROUTE;
        } else if (userRole == ADMIN_KEY) {
          destinationRoute = ADMIN_HOME_ROUTE;
        } else {
          // Handle unknown role
          _showError('خطأ: الدور ($userRole) غير معترف به.');
          await FirebaseAuth.instance.signOut();
          return;
        }

        // 3. Navigate to the appropriate home screen
        Navigator.of(context).pushReplacementNamed(destinationRoute);

      } else {
        // Document doesn't exist (user registered via Auth but failed Firestore write)
        _showError('خطأ: بيانات المستخدم غير مكتملة. يرجى مراجعة الإدارة.');
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      print('Error during role check: $e');
      _showError('حدث خطأ في التحقق من دور المستخدم.');
      await FirebaseAuth.instance.signOut();
    }
  }

  // ----------------------------------------------------
  // CORE LOGIN LOGIC (The 'signIn' function equivalent)
  // ----------------------------------------------------
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text.trim();
    
    setState(() => _isLoading = true);
    final String authEmail = _convertToAuthEmail(phone);
    
    try {
      // 1. Authenticate the user (Sign In)
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: authEmail, password: password);
      
      final User? user = userCredential.user;

      if (user != null) {
        // 2. If Auth is successful, proceed to check the role in Firestore
        await _checkRoleAndNavigate(user);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ في تسجيل الدخول. الرجاء المحاولة مرة أخرى.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'رقم الجوال أو كلمة المرور غير صحيحة.';
      } else if (e.code == 'invalid-email') {
         message = 'صيغة رقم الجوال غير صحيحة.';
      } else if (e.code == 'too-many-requests') {
         message = 'تم حظر هذا الحساب مؤقتًا بسبب محاولات متكررة فاشلة.';
      }
      _showError(message);

    } catch (e) {
      print('Error during login: $e');
      _showError('حدث خطأ غير متوقع.');
    } finally {
      setState(() => _isLoading = false); // Hide loading state
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }

  // ----------------------------------------------------
  // UI Building Methods
  // ----------------------------------------------------

  Widget _buildBody() {
    // ... (Your existing UI structure)
    return Stack(
      children: <Widget>[
        // الخلفية الزرقاء الداكنة في الأعلى
        Container(
          height: MediaQuery.of(context).size.height * 0.4,
          color: _kDarkBlue, // 0xFF0D1B36
        ),
        
        // محتوى تسجيل الدخول (Card)
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(bottom: 40.0),
                  child: Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Form( // Wrap the card content in a Form
                  key: _formKey,
                  child: _buildLoginCard(),
                ),
                
                // ---------------- الانتقال لشاشة اختيار الدور ----------------
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChooseRoleScreen(), 
                      ),
                    );
                  },
                  child: const Text(
                    'تسجيل حساب جديد',
                    style: TextStyle(color: _kDarkBlue), // 0xFF0D1B36
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Image.asset(
                'assets/hafilaty_logo.png', // Ensure this path is correct
                height: 100, // <-- MODIFIED: Increased logo size from 50 to 80
              ),
            ),
            _buildInputField(
              'رقم الجوال',
              _phoneController,
              Icons.phone,
              TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال رقم الجوال';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildInputField(
              'كلمة المرور',
              _passwordController,
              Icons.lock,
              TextInputType.text,
              isPassword: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال كلمة المرور';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implement forgot password logic
                },
                child: const Text('هل نسيت كلمة المرور؟'),
              ),
            ),
            const SizedBox(height: 10),
            _buildLoginButton(),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('اللغة / Language'),
                SizedBox(width: 8),
                Icon(Icons.language),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData suffixIcon,
    TextInputType keyboardType, {
    bool isPassword = false,
    String? Function(String?)? validator, // Added validator
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              color: _kGreenAccent, // 0xFF6A994E
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          textAlign: TextAlign.right,
          validator: validator, // Applied validator
          inputFormatters: keyboardType == TextInputType.phone
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            suffixIcon: Icon(suffixIcon, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    // (Existing button code)
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            _kDarkBlue, // 0xFF0D1B36
            _kGreenAccent, // 0xFF6A994E
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}