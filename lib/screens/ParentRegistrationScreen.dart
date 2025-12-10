import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for FilteringTextInputFormatter
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// Helper function (MUST match the one in LoginScreen.dart)
String _convertToAuthEmail(String phone) {
  // Cleans the phone number (removes +, spaces, etc.)
  final cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
  return '$cleanedPhone@hafilatyapp.com'; 
}

// -----------------------------------------------------------------
// 1. STATEFUL WIDGET DEFINITION
// -----------------------------------------------------------------
class ParentRegistrationScreen extends StatefulWidget {
  // CRUCIAL: Holds the role key passed from ChooseRoleScreen (e.g., 'parent')
  final String roleKey; 

  const ParentRegistrationScreen({super.key, required this.roleKey});

  @override
  State<ParentRegistrationScreen> createState() => _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> {
  // 2. TEXT EDITING CONTROLLERS
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); 
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _streetController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // 3. CORE REGISTRATION LOGIC
  // -----------------------------------------------------------------
  Future<void> _handleRegistration() async {
    // Simple Input validation
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('كلمة المرور وتأكيد كلمة المرور غير متطابقان.');
      return;
    }
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty || _firstNameController.text.isEmpty) {
        _showError('الرجاء تعبئة الحقول المطلوبة.');
        return;
    }

    setState(() => _isLoading = true);
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text.trim();
    final String authEmail = _convertToAuthEmail(phone);
    
    try {
      // A. Create the user in Firebase Authentication
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: authEmail, password: password);
      
      final User? user = userCredential.user;

      if (user != null) {
        final String uid = user.uid;
        
        // B. Save User Data and ROLE to Firebase Realtime Database
        final DatabaseReference userRef =
            FirebaseDatabase.instance.ref().child('users').child(uid);
        
        await userRef.set({
            'phone': phone,
            'role': widget.roleKey, // Saves the role ('parent')
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'nationalId': _idController.text.trim(),
            'city': _cityController.text.trim(),
            'district': _districtController.text.trim(),
            'street': _streetController.text.trim(),
            'email': _emailController.text.trim(), 
            'createdAt': ServerValue.timestamp,
        });

        // Success: Navigate to the home screen and clear the navigation stack
        ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('تم التسجيل بنجاح! يتم نقلك إلى الشاشة الرئيسية.'))
        );
        // Navigate to the role-specific home route (e.g., /parent_home)
        Navigator.of(context).pushNamedAndRemoveUntil('/${widget.roleKey}_home', (Route<dynamic> route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'فشل التسجيل. يرجى التأكد من كلمة المرور (6 أحرف على الأقل).';
      if (e.code == 'email-already-in-use') {
        message = 'رقم الجوال مسجل بالفعل. يرجى تسجيل الدخول.';
      } 
      _showError(message);
    } catch (e) {
      print('Unexpected error during registration: $e');
      _showError('حدث خطأ غير متوقع أثناء التسجيل.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }

  // -----------------------------------------------------------------
  // 4. UI BUILDER METHODS
  // -----------------------------------------------------------------

  Widget _buildLabeledTextField({
    required String labelText,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    IconData? roleIcon, 
  }) {
    // 1. التسمية (الاسم الأول، رقم الهوية، إلخ)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        // 2. حقل الإدخال نفسه
        TextFormField(
          controller: controller, // <--- CONTROLLER ASSIGNED
          obscureText: isPassword,
          keyboardType: keyboardType,
          textAlign: TextAlign.right,
          // Restrict phone input to digits only
          inputFormatters: keyboardType == TextInputType.phone
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: 'أدخل $labelText', // Simplified hint text
            hintStyle: const TextStyle(color: Colors.grey),

            // *الأيقونة في اليمين (prefixIcon في اتجاه RTL)*
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Icon(icon, color: Colors.grey.shade500),
            ),

            // *أيقونة الدور (roleIcon) على أقصى اليمين*
            suffixIcon: roleIcon != null
                ? Icon(roleIcon, color: const Color(0xFF0D47A1))
                : null,

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
    // تعيين الاتجاه لـ RTL (من اليمين لليسار) للغة العربية
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,

        // *AppBar مع سهم الرجوع لليسار*
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          title: Text(
            // Use the role key to dynamically set the title
            'إنشاء حساب ${widget.roleKey == 'parent' ? 'ولي أمر' : widget.roleKey}', 
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.language),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // حقل الاسم الأول
              _buildLabeledTextField(
                labelText: 'الاسم الأول',
                controller: _firstNameController,
                icon: Icons.person_outline,
                roleIcon: Icons.group,
              ),
              const SizedBox(height: 20),

              // حقل الاسم الأخير
              _buildLabeledTextField(
                labelText: 'الاسم الأخير',
                controller: _lastNameController,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              // حقل رقم الهوية
              _buildLabeledTextField(
                labelText: 'رقم الهوية',
                controller: _idController,
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // حقل المدينة
              _buildLabeledTextField(
                labelText: 'المدينة',
                controller: _cityController,
                icon: Icons.location_city_outlined,
              ),
              const SizedBox(height: 20),

              // حقل الحي
              _buildLabeledTextField(
                labelText: 'الحي',
                controller: _districtController,
                icon: Icons.apartment_outlined,
              ),
              const SizedBox(height: 20),

              // حقل الشارع
              _buildLabeledTextField(
                labelText: 'الشارع',
                controller: _streetController,
                icon: Icons.map_outlined,
              ),
              const SizedBox(height: 20),

              // حقل رقم الجوال
              _buildLabeledTextField(
                labelText: 'رقم الجوال',
                controller: _phoneController,
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // حقل البريد الإلكتروني
              _buildLabeledTextField(
                labelText: 'البريد الإلكتروني',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // حقل كلمة المرور
              _buildLabeledTextField(
                labelText: 'كلمة المرور',
                controller: _passwordController,
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 30),

              // حقل تأكيد كلمة المرور
              _buildLabeledTextField(
                labelText: 'تأكيد كلمة المرور',
                controller: _confirmPasswordController,
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 30),

              // زر التسجيل (باستخدام حالة التحميل)
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistration, // Disable when loading
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
    );
  }
}