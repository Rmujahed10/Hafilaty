// ignore_for_file: unused_element, file_names

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';

import 'ChooseRoleScreen.dart';

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

  String _convertToAuthEmail(String phone) {
    final cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return '$cleanedPhone@hafilatyapp.com';
  }

  Future<void> _saveFCMToken(String phone) async {
    try {
      String? token;

      if (kIsWeb) {
        token = await FirebaseMessaging.instance.getToken(
          vapidKey:
              'BKCFfRwDB7R0WllNIhWMMSg3pPizOkog7c-gTnThRLCZc9J9p09HcEKxLnp3yT4Pvg9yJ_lljmT5m_cUgk4D8s8',
        );
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token != null && token.trim().isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(phone).update({
          'fcmToken': token,
        });

        debugPrint("FCM token saved successfully");
      }
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  Future<void> _checkRoleAndNavigate(String cleanedPhone) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cleanedPhone)
          .get();

      if (!doc.exists) {
        _showError('error_user_not_found'.tr());
        await FirebaseAuth.instance.signOut();
        return;
      }

      String role = doc.get('role') ?? 'user';
      if (role == 'admin') {
        Navigator.of(context).pushReplacementNamed('/AdminHome');
      } else if (role == 'parent') {
        Navigator.of(context).pushReplacementNamed('/parent_home');
       } else if (role == 'driver') {
        Navigator.of(context).pushReplacementNamed('/driver_home');
      }
      else {
        Navigator.of(context).pushReplacementNamed('/role_home');
      }
    } catch (e) {
      _showError('حدث خطأ أثناء التحقق');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final phoneRaw = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final cleanedPhone = phoneRaw.replaceAll(RegExp(r'[^\d]'), '');
    final authEmail = '$cleanedPhone@hafilatyapp.com';

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: authEmail,
        password: password,
      );

      if (credential.user != null) {
        await _saveFCMToken(cleanedPhone);
        await _checkRoleAndNavigate(cleanedPhone);
      }
    } on FirebaseAuthException {
      String message = 'error_wntials'.tr();
      _showError(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

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
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Text(
                    'login_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Form(key: _formKey, child: _buildLoginCard()),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChooseRoleScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'register_new_account'.tr(),
                    style: const TextStyle(color: _kDarkBlue),
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
              child: Image.asset('assets/LaunchImage@3x.png', height: 100),
            ),
            _buildInputField(
              'Phone Number'.tr(),
              _phoneController,
              Icons.phone,
              TextInputType.phone,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'phone_required'.tr() : null,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              'Password'.tr(),
              _passwordController,
              Icons.lock,
              TextInputType.text,
              isPassword: true,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'password_required'.tr()
                  : null,
            ),
            Align(
              alignment: context.locale.languageCode == 'ar'
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: TextButton(
                onPressed: () {},
                child: Text('Forgot Password?'.tr()),
              ),
            ),
            const SizedBox(height: 10),
            _buildLoginButton(),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                if (context.locale.languageCode == 'ar') {
                  context.setLocale(const Locale('en'));
                } else {
                  context.setLocale(const Locale('ar'));
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('اللغة / Language'),
                  SizedBox(width: 8),
                  Icon(Icons.language),
                ],
              ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            suffixIcon: Icon(icon, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
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
        gradient: const LinearGradient(colors: [_kDarkBlue, _kGreenAccent]),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Login'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}