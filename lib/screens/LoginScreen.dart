import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// تم تحديث اسم الملف إلى ChooseRoleScreen.dart
import 'ChooseRoleScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
        onPressed: () {
          debugPrint(
            'Phone: ${_phoneController.text}, Password: ${_passwordController.text}',
          );
          // TODO: Add actual login logic here
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
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