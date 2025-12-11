import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers مشتركة
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // للسائق
  final _licenseController = TextEditingController();
  final _birthDateController = TextEditingController();

  // للمشرف
  final _schoolController = TextEditingController();

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _role; // parent / driver / admin

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _streetController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    _birthDateController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // ما فيه مستخدم مسجل دخول
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على مستخدم مسجل الدخول.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على بيانات الحساب.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final data = doc.data() ?? {};
      setState(() {
        _role = data['role'];

        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _idController.text = data['nationalId'] ?? '';

        _cityController.text = data['city'] ?? '';
        _districtController.text = data['district'] ?? '';
        _streetController.text = data['street'] ?? '';

        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';

        _licenseController.text = data['licenseNumber'] ?? '';
        _birthDateController.text = data['birthDate'] ?? '';

        _schoolController.text = data['school'] ?? '';

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تحميل البيانات.')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final Map<String, dynamic> updatedData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'nationalId': _idController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      };

      if (_role == 'parent') {
        updatedData.addAll({
          'city': _cityController.text.trim(),
          'district': _districtController.text.trim(),
          'street': _streetController.text.trim(),
        });
      } else if (_role == 'driver') {
        updatedData.addAll({
          'licenseNumber': _licenseController.text.trim(),
          'birthDate': _birthDateController.text.trim(),
        });
      } else if (_role == 'admin') {
        updatedData.addAll({
          'school': _schoolController.text.trim(),
          'birthDate': _birthDateController.text.trim(),
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث البيانات بنجاح.')),
      );
    } catch (e) {
      debugPrint('Error updating user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تحديث البيانات.')),
      );
    }

    setState(() => _isUpdating = false);
  }

  // ويدجيت لحقل ثابت زي تصميمك (Label يمين + Box أخضر فاتح)
  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$label :',
            style: const TextStyle(
              color: Color(0xFF8BAA3C),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: TextAlign.right,
          validator: validator,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FFF4), // خلفية خفيفة
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color(0xFF8BAA3C), // نفس الأخضر في الصورة
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color(0xFF8BAA3C),
                width: 2.0,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B36),
        body: SafeArea(
          child: Column(
            children: [
              // AppBar مشابه للصورة
              Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(
    children: [
      // ← سهم الرجوع (يسار)
       // أيقونة اللغة (يمين)
      const Icon(Icons.language, color: Colors.white),

      const Spacer(),

      // عنوان الصفحة في الوسط
      const Text(
        'تعديل معلومات الحساب',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      const Spacer(),

      IconButton( icon: const 
      Icon( Icons.arrow_forward, color: Colors.white, ), 
      onPressed: () => Navigator.pop(context), ),
    ],
  ),
),


              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // الاسم الأول
                                  _buildProfileField(
                                    label: 'الاسم الأول',
                                    controller: _firstNameController,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'الرجاء إدخال الاسم الأول'
                                        : null,
                                  ),

                                  // الاسم الأخير
                                  _buildProfileField(
                                    label: 'الاسم الأخير',
                                    controller: _lastNameController,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'الرجاء إدخال الاسم الأخير'
                                        : null,
                                  ),

                                  // الهوية
                                  _buildProfileField(
                                    label: 'الهوية',
                                    controller: _idController,
                                    keyboardType: TextInputType.number,
                                  ),

                                  if (_role == 'parent') ...[
                                    _buildProfileField(
                                      label: 'المدينة',
                                      controller: _cityController,
                                    ),
                                    _buildProfileField(
                                      label: 'الحي',
                                      controller: _districtController,
                                    ),
                                    _buildProfileField(
                                      label: 'الشارع',
                                      controller: _streetController,
                                    ),
                                  ],

                                  if (_role == 'driver') ...[
                                    _buildProfileField(
                                      label: 'رقم الرخصة',
                                      controller: _licenseController,
                                      keyboardType: TextInputType.number,
                                    ),
                                    _buildProfileField(
                                      label: 'تاريخ الميلاد',
                                      controller: _birthDateController,
                                    ),
                                  ],

                                  if (_role == 'admin') ...[
                                    _buildProfileField(
                                      label: 'المدرسة',
                                      controller: _schoolController,
                                    ),
                                    _buildProfileField(
                                      label: 'تاريخ الميلاد',
                                      controller: _birthDateController,
                                    ),
                                  ],

                                  _buildProfileField(
                                    label: 'رقم الجوال',
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                  ),

                                  _buildProfileField(
                                    label: 'البريد الإلكتروني',
                                    controller: _emailController,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                  ),

                                  const SizedBox(height: 16),

                                  // زر تعديل
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isUpdating
                                          ? null
                                          : _updateUserData,
                                      icon: const Icon(Icons.edit_outlined),
                                      label: _isUpdating
                                          ? const Text('جاري التحديث...')
                                          : const Text('تعديل'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFCD4D8),
                                        foregroundColor: Colors.black87,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
