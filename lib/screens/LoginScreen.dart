import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ChooseRoleScreen.dart';

// --- Color Constants ---
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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  // Convert phone → Firebase email format
  String _convertToAuthEmail(String phone) {
    final cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return '$cleanedPhone@hafilatyapp.com';
  }

  // ----------------------------------------------------
  // ROLE CHECK → Always navigate to /role_home
  // ----------------------------------------------------
  Future<void> _checkRoleAndNavigate(User user) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        _showError('خطأ: بيانات المستخدم غير موجودة.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      // Now ALL roles navigate to the same home screen
      Navigator.of(context).pushReplacementNamed('/role_home');

    } catch (e) {
      print('Error during role check: $e');
      _showError('حدث خطأ أثناء التحقق من بيانات المستخدم.');
      await FirebaseAuth.instance.signOut();
    }
  }

  // ----------------------------------------------------
  // LOGIN LOGIC
  // ----------------------------------------------------
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final authEmail = _convertToAuthEmail(phone);

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: authEmail, password: password);

      if (credential.user != null) {
        await _checkRoleAndNavigate(credential.user!);
      }

    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ في تسجيل الدخول.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'رقم الجوال أو كلمة المرور غير صحيحة.';
      } else if (e.code == 'too-many-requests') {
        message = 'تم حظر الحساب مؤقتاً بسبب محاولات خاطئة متكررة.';
      }
      _showError(message);

    } catch (e) {
      print(e);
      _showError('حدث خطأ غير متوقع.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ----------------------------------------------------
  // UI
  // ----------------------------------------------------
  Widget _buildBody() {
    return Stack(
      children: <Widget>[
        Container(
          height: MediaQuery.of(context).size.height * 0.4,
          color: _kDarkBlue,
        ),

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
                  ),
                ),

                Form(
                  key: _formKey,
                  child: _buildLoginCard(),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChooseRoleScreen()),
                    );
                  },
                  child: const Text(
                    'تسجيل حساب جديد',
                    style: TextStyle(color: _kDarkBlue),
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Image.asset(
                'assets/hafilaty_logo.png',
                height: 100,
              ),
            ),

            _buildInputField(
              'رقم الجوال',
              _phoneController,
              Icons.phone,
              TextInputType.phone,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'الرجاء إدخال رقم الجوال' : null,
            ),

            const SizedBox(height: 20),

            _buildInputField(
              'كلمة المرور',
              _passwordController,
              Icons.lock,
              TextInputType.text,
              isPassword: true,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'الرجاء إدخال كلمة المرور' : null,
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
              children: [
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
    IconData icon,
    TextInputType type, {
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _kGreenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          keyboardType: type,
          obscureText: isPassword,
          textAlign: TextAlign.right,
          validator: validator,
          inputFormatters:
              type == TextInputType.phone ? [FilteringTextInputFormatter.digitsOnly] : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            suffixIcon: Icon(icon, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
          colors: [_kDarkBlue, _kGreenAccent],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
            : const Text(
                'تسجيل الدخول',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
