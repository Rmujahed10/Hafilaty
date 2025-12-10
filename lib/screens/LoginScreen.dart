import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ChooseRoleScreen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // State variable for loading indicator

// --- Crucial: Define DB keys and Routes ---
  static const String PARENT_KEY = 'parent';
  static const String DRIVER_KEY = 'driver';
  static const String SUPERVISOR_KEY = 'supervisor';

  // Define Navigation Routes
  static const String PARENT_HOME_ROUTE = '/parent_home'; 
  static const String DRIVER_HOME_ROUTE = '/driver_home'; 
  static const String SUPERVISOR_HOME_ROUTE = '/supervisor_home';

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
    // Cleans the phone number (removes +, spaces, etc.)
    final cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return '$cleanedPhone@hafilatyapp.com'; 
  }

  // ----------------------------------------------------
  // CORE LOGIN AND ROLE CHECK LOGIC
  // ----------------------------------------------------
  Future<void> _handleLogin() async {
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال رقم الجوال وكلمة المرور'))
      );
      return;
    }
    
    // Show loading state
    setState(() => _isLoading = true);
    final String authEmail = _convertToAuthEmail(phone);
    
    try {
      // 2. Authenticate the user
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: authEmail, password: password);
      
      final User? user = userCredential.user;

      if (user != null) {
        final String uid = user.uid;
        
        // 4. Query Realtime Database for the role
        final DatabaseReference userRef =
            FirebaseDatabase.instance.ref().child('users').child(uid);
        
        final DataSnapshot snapshot = await userRef.get();

        if (snapshot.exists && snapshot.value != null) {
          final userData = snapshot.value as Map<dynamic, dynamic>;
          final String? userRole = userData['role'] as String?;

          // 6. Conditional Navigation based on the role (using static const keys)
          if (userRole == PARENT_KEY) {
            Navigator.of(context).pushReplacementNamed(PARENT_HOME_ROUTE);
          } else if (userRole == DRIVER_KEY) {
            Navigator.of(context).pushReplacementNamed(DRIVER_HOME_ROUTE);
          } else if (userRole == SUPERVISOR_KEY) {
            Navigator.of(context).pushReplacementNamed(SUPERVISOR_HOME_ROUTE);
          } else {
            _showError('خطأ: الدور غير معترف به.');
            await FirebaseAuth.instance.signOut();
          }
        } else {
          _showError('خطأ: بيانات المستخدم غير مكتملة. يرجى مراجعة الإدارة.');
          await FirebaseAuth.instance.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ في تسجيل الدخول. الرجاء المحاولة مرة أخرى.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'رقم الجوال أو كلمة المرور غير صحيحة.';
      } else if (e.code == 'invalid-email') {
         message = 'صيغة رقم الجوال غير صحيحة.';
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

  Widget _buildBody() {
    return Stack(
      children: <Widget>[
        // الخلفية الزرقاء الداكنة في الأعلى
        Container(
          height: MediaQuery.of(context).size.height * 0.4,
          color: const Color(0xFF0D1B36),
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
                _buildLoginCard(),
                
                // ---------------- الانتقال لشاشة اختيار الدور ----------------
                TextButton(
                  onPressed: () {
                    // **تم تغيير اسم الشاشة هنا**
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChooseRoleScreen(), 
                      ),
                    );
                  },
                  child: const Text(
                    'تسجيل حساب جديد',
                    style: TextStyle(color: Color(0xFF0D1B36)),
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
                'assets/hafilaty_logo.png',
                height: 50,
              ),
            ),
            _buildInputField(
              'رقم الجوال',
              _phoneController,
              Icons.phone,
              TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              'كلمة المرور',
              _passwordController,
              Icons.lock,
              TextInputType.text,
              isPassword: true,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6A994E),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          textAlign: TextAlign.right,
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D1B36),
            Color(0xFF6A994E),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton(
        // The button is disabled while _isLoading is true
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