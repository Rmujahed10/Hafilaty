import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 💡 IMPORTANT: Switched from 'firebase_database' to 'cloud_firestore'
import 'package:cloud_firestore/cloud_firestore.dart'; 

// NOTE: This should ideally be in a separate utility file or the Login file
String _convertToAuthEmail(String phone) {
  // Cleans the phone number (removes +, spaces, etc.)
  final cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
  // Using a unique domain to avoid conflicts with actual emails
  return '$cleanedPhone@hafilatyapp.com'; 
}

// -----------------------------------------------------------------
// 1. STATEFUL WIDGET DEFINITION
// -----------------------------------------------------------------
class ParentRegistrationScreen extends StatefulWidget {
  // CRUCIAL: Holds the role key passed from ChooseRoleScreen (e.g., 'parent')
  final String roleKey; 

  // New optional parameter for the success navigation route
  final String successRoute; 

  const ParentRegistrationScreen({
    super.key, 
    required this.roleKey, 
    // Default success route (adjust as needed in your main.dart)
    this.successRoute = '/login', 
  });

  @override
  State<ParentRegistrationScreen> createState() => _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> {
  // 2. TEXT EDITING CONTROLLERS
  final _formKey = GlobalKey<FormState>(); // Added a form key for full validation control
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
    if (!_formKey.currentState!.validate()) {
      _showError('الرجاء التأكد من تعبئة جميع الحقول بشكل صحيح.');
      return;
    }
    
    // Additional manual check for password match
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('كلمة المرور وتأكيد كلمة المرور غير متطابقان.');
      return;
    }

    setState(() => _isLoading = true);
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text.trim();
    final String authEmail = _convertToAuthEmail(phone);
    
    User? user; 

    // --- PHASE 1: FIREBASE AUTHENTICATION ---
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: authEmail, password: password);
      
      user = userCredential.user;
      
    } on FirebaseAuthException catch (e) {
      String message = 'فشل التسجيل. يرجى التأكد من كلمة المرور (6 أحرف على الأقل).';
      if (e.code == 'email-already-in-use') {
        message = 'رقم الجوال مسجل بالفعل. يرجى تسجيل الدخول.';
      } else {
        debugPrint('FirebaseAuth Error: ${e.code} - ${e.message}'); 
      }
      _showError(message);
      setState(() => _isLoading = false);
      return; 
    } catch (e) {
      debugPrint('Unexpected error during Auth phase: $e');
      _showError('حدث خطأ غير متوقع أثناء المصادقة.');
      setState(() => _isLoading = false);
      return;
    }

    // --- PHASE 2: CLOUD FIRESTORE WRITE ---
    if (user != null) {
      final String uid = user.uid;
      
      try {
        // Reference to the 'users' collection
        final DocumentReference userDocRef =
            FirebaseFirestore.instance.collection('users').doc(uid);
        
        // Data map for Parent role
        Map<String, dynamic> userData = {
            'uid': uid,
            'role': widget.roleKey, // Saves the role (e.g., 'parent')
            'phone': phone,
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'nationalId': _idController.text.trim(),
            'city': _cityController.text.trim(),
            'district': _districtController.text.trim(),
            'street': _streetController.text.trim(),
            'email': _emailController.text.trim(), 
            // Use FieldValue.serverTimestamp() for Firestore
            'createdAt': FieldValue.serverTimestamp(), 
            // NOTE: You would add other role-specific fields here for Driver/Admin
        };

        await userDocRef.set(userData);

        // SUCCESS: Firestore write completed
        ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('تم التسجيل بنجاح! يرجى تسجيل الدخول.'))
        );
        
        // Navigate to the login screen or a successful registration page
        Navigator.of(context).pushNamedAndRemoveUntil(
          widget.successRoute, 
          (Route<dynamic> route) => false,
        );
        
      } on FirebaseException catch (e) {
        // Catch Firestore-specific write errors (e.g., permission errors)
        debugPrint('Firestore write failed for UID $uid: ${e.code} - ${e.message}');
        _showError('تم إنشاء الحساب ولكن فشل حفظ البيانات. يرجى المحاولة مرة أخرى.');
        
        // CRITICAL STEP: Clean up the user created in Auth if DB write failed
        await user.delete(); 
        await FirebaseAuth.instance.signOut(); 
        
      }
    }
    
    setState(() => _isLoading = false);
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
    String? Function(String?)? validator, // Added validator
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
          key: ValueKey(labelText), // Added Key for unique identification
          controller: controller, // <--- CONTROLLER ASSIGNED
          obscureText: isPassword,
          keyboardType: keyboardType,
          textAlign: TextAlign.right,
          validator: validator, // <--- VALIDATOR ASSIGNED
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
            // Dynamically show the role in the title
            'إنشاء حساب ${widget.roleKey == 'parent' ? 'ولي أمر' : widget.roleKey == 'driver' ? 'سائق' : 'مشرف'}', 
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
        body: Form( // Wrap the form in a Form widget
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // حقل الاسم الأول
                _buildLabeledTextField(
                  labelText: 'الاسم الأول',
                  controller: _firstNameController,
                  icon: Icons.person_outline,
                  roleIcon: Icons.group,
                  validator: (value) => value!.isEmpty ? 'الرجاء إدخال الاسم الأول' : null,
                ),
                const SizedBox(height: 20),

                // حقل الاسم الأخير
                _buildLabeledTextField(
                  labelText: 'الاسم الأخير',
                  controller: _lastNameController,
                  icon: Icons.person_outline,
                  validator: (value) => value!.isEmpty ? 'الرجاء إدخال الاسم الأخير' : null,
                ),
                const SizedBox(height: 20),

                // حقل رقم الهوية
                _buildLabeledTextField(
                  labelText: 'رقم الهوية',
                  controller: _idController,
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'الرجاء إدخال رقم الهوية' : null,
                ),
                const SizedBox(height: 20),

                // حقل المدينة
                _buildLabeledTextField(
                  labelText: 'المدينة',
                  controller: _cityController,
                  icon: Icons.location_city_outlined,
                  validator: (value) => value!.isEmpty ? 'الرجاء إدخال المدينة' : null,
                ),
                const SizedBox(height: 20),

                // حقل الحي
                _buildLabeledTextField(
                  labelText: 'الحي',
                  controller: _districtController,
                  icon: Icons.apartment_outlined,
                  validator: (value) => value!.isEmpty ? 'الرجاء إدخال الحي' : null,
                ),
                const SizedBox(height: 20),

                // حقل الشارع
                _buildLabeledTextField(
                  labelText: 'الشارع',
                  controller: _streetController,
                  icon: Icons.map_outlined,
                  validator: (value) => value!.isEmpty ? 'الرجاء إدخال الشارع' : null,
                ),
                const SizedBox(height: 20),

                // حقل رقم الجوال
                _buildLabeledTextField(
                  labelText: 'رقم الجوال',
                  controller: _phoneController,
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value!.isEmpty) return 'الرجاء إدخال رقم الجوال';
                    if (value.length < 9) return 'رقم الجوال قصير جداً'; // Basic length check
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // حقل البريد الإلكتروني (جعله اختيارياً، لكن يفضل إدخاله)
                _buildLabeledTextField(
                  labelText: 'البريد الإلكتروني (اختياري)',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  // Simplified optional email validation
                  validator: (value) {
                    if (value!.isNotEmpty && !RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                      return 'أدخل بريد إلكتروني صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // حقل كلمة المرور
                _buildLabeledTextField(
                  labelText: 'كلمة المرور',
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) {
                    if (value!.isEmpty) return 'الرجاء إدخال كلمة المرور';
                    if (value.length < 6) return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // حقل تأكيد كلمة المرور
                _buildLabeledTextField(
                  labelText: 'تأكيد كلمة المرور',
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) {
                    if (value!.isEmpty) return 'الرجاء تأكيد كلمة المرور';
                    if (value != _passwordController.text) return 'كلمة المرور غير متطابقة';
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // زر التسجيل (باستخدام حالة التحميل)
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