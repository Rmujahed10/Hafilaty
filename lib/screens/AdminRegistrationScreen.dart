import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// نفس الفنكشن اللي استعملناه في باقي الشاشات
String _convertToAuthEmail(String phone) {
  final cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
  return '$cleanedPhone@hafilatyapp.com';
}

class SupervisorRegistrationScreen extends StatefulWidget {
  final String successRoute;

  const SupervisorRegistrationScreen({
    super.key,
    this.successRoute = '/login',
  });

  @override
  State<SupervisorRegistrationScreen> createState() =>
      _SupervisorRegistrationScreenState();
}

class _SupervisorRegistrationScreenState
    extends State<SupervisorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idController = TextEditingController();
  final _schoolController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idController.dispose();
    _schoolController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ------------------------------
  // 1) Registration logic
  // ------------------------------
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      _showError('الرجاء التأكد من تعبئة جميع الحقول بشكل صحيح.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('كلمة المرور وتأكيد كلمة المرور غير متطابقان.');
      return;
    }

    setState(() => _isLoading = true);

    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text.trim();
    final String authEmail = _convertToAuthEmail(phone);

    User? user;

    // --- PHASE 1: Firebase Auth ---
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: authEmail, password: password);
      user = userCredential.user;
    } on FirebaseAuthException catch (e) {
      String message =
          'فشل التسجيل. يرجى التأكد من كلمة المرور (6 أحرف على الأقل).';
      if (e.code == 'email-already-in-use') {
        message = 'رقم الجوال مسجل بالفعل. يرجى تسجيل الدخول.';
      } else {
        debugPrint('FirebaseAuth Error (admin): ${e.code} - ${e.message}');
      }
      _showError(message);
      setState(() => _isLoading = false);
      return;
    } catch (e) {
      debugPrint('Unexpected error during Auth (admin): $e');
      _showError('حدث خطأ غير متوقع أثناء المصادقة.');
      setState(() => _isLoading = false);
      return;
    }

    // --- PHASE 2: Firestore write ---
    if (user != null) {
      final String uid = user.uid;

      try {
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(uid);

        final Map<String, dynamic> userData = {
          'uid': uid,
          'role': 'admin', // 👈 لو تبيها 'supervisor' غيّرها هنا
          'phone': phone,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'nationalId': _idController.text.trim(),
          'school': _schoolController.text.trim(),
          'birthDate': _birthDateController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        };

        await userDocRef.set(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل المشرف بنجاح! يرجى تسجيل الدخول.')),
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          widget.successRoute,
          (route) => false,
        );
      } on FirebaseException catch (e) {
        debugPrint(
            'Firestore write failed for admin UID $uid: ${e.code} - ${e.message}');
        _showError('تم إنشاء الحساب ولكن فشل حفظ بيانات المشرف. يرجى المحاولة مرة أخرى.');

        await user.delete();
        await FirebaseAuth.instance.signOut();
      }
    }

    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ------------------------------
  // 2) Reusable TextField builder
  // ------------------------------
  Widget _buildLabeledTextField({
    required String labelText,
    String? hintText,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(right: 8.0, bottom: 6.0),
          child: Text(
            labelText,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Text field
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          textAlign: TextAlign.right,
          validator: validator,
          inputFormatters: keyboardType == TextInputType.phone ||
                  keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: hintText ?? 'أدخل $labelText',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Icon(icon, color: Colors.grey.shade500),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                color: Color(0xFF0D47A1),
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 15,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1B36),
          foregroundColor: Colors.white,
          title: const Text(
            'إنشاء حساب مشرف',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
           // سهم الرجوع (يمين لأن RTL)
   leading: const Padding( 
            padding: EdgeInsets.symmetric(horizontal: 16.0), 
          child: Icon(Icons.language), 
          ),
          
          actions: [ 
            IconButton( 
              icon: const Icon( 
                Icons.arrow_forward, 
                color: Colors.white, 
                ),
                onPressed: () => Navigator.pop(context), 
                ), 
                ],

        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(
                  Icons.person_pin_outlined,
                  size: 60,
                  color: Color(0xFF0D1B36),
                ),
                const SizedBox(height: 10),

                // First name
                _buildLabeledTextField(
                  labelText: 'الاسم الأول',
                  hintText: 'أدخل الاسم الأول',
                  controller: _firstNameController,
                  icon: Icons.person_outline,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'الرجاء إدخال الاسم الأول' : null,
                ),
                const SizedBox(height: 20),

                // Last name
                _buildLabeledTextField(
                  labelText: 'الاسم الأخير',
                  hintText: 'أدخل اسم العائلة',
                  controller: _lastNameController,
                  icon: Icons.person_outline,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'الرجاء إدخال الاسم الأخير' : null,
                ),
                const SizedBox(height: 20),

                // National ID
                _buildLabeledTextField(
                  labelText: 'رقم الهوية',
                  hintText: 'أدخل رقم الهوية',
                  controller: _idController,
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'الرجاء إدخال رقم الهوية' : null,
                ),
                const SizedBox(height: 20),

                // School
                _buildLabeledTextField(
                  labelText: 'المدرسة',
                  hintText: 'اسم المدرسة',
                  controller: _schoolController,
                  icon: Icons.apartment_outlined,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'الرجاء إدخال اسم المدرسة' : null,
                ),
                const SizedBox(height: 20),

                // Birth date
                _buildLabeledTextField(
                  labelText: 'تاريخ الميلاد',
                  hintText: 'يوم / شهر / سنة',
                  controller: _birthDateController,
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.datetime,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'الرجاء إدخال تاريخ الميلاد' : null,
                ),
                const SizedBox(height: 20),

                // Phone
                _buildLabeledTextField(
                  labelText: 'رقم الجوال',
                  hintText: 'مثال: 05xxxxxxx',
                  controller: _phoneController,
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال رقم الجوال';
                    }
                    if (value.length < 9) {
                      return 'رقم الجوال قصير جداً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email (optional but validated)
                _buildLabeledTextField(
                  labelText: 'البريد الإلكتروني',
                  hintText: 'example@domain.com',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        !RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                            .hasMatch(value)) {
                      return 'أدخل بريد إلكتروني صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                _buildLabeledTextField(
                  labelText: 'كلمة المرور',
                  hintText: 'كلمة مرور قوية',
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm password
                _buildLabeledTextField(
                  labelText: 'تأكيد كلمة المرور',
                  hintText: 'أعد إدخال كلمة المرور',
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء تأكيد كلمة المرور';
                    }
                    if (value != _passwordController.text) {
                      return 'كلمة المرور غير متطابقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BAA3C),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تسجيل الآن',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
