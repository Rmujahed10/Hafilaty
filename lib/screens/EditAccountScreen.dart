import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORT YOUR VALIDATOR LOGIC HERE ---
// Make sure 'hafilaty' matches the name in your pubspec.yaml
import 'package:hafilaty/utils/validators.dart';

// --- Constants ---
const Color kHeaderColor = Color(0xFF0D1B36); // Dark Blue
const Color kAccentColor = Color(0xFF8BAA3C); // Green
const Color kFieldBgColor = Color(0xFFF9FFF4); // Light Green Background

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Driver Specific
  final _licenseController = TextEditingController();
  final _birthDateController = TextEditingController();

  // Admin Specific
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

  // --- Date Picker Logic ---
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kAccentColor,
              onPrimary: Colors.white,
              onSurface: kHeaderColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text = "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }

  // --- Load Data ---
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
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
      setState(() => _isLoading = false);
    }
  }

  // --- Update Data ---
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

      if (!mounted) return;
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

  // --- Enhanced Field Widget ---
  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    bool isNumber = false,   
    bool isReadOnly = false, 
    VoidCallback? onTap,     
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$label :',
            style: const TextStyle(
              color: kAccentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.right,
          
          // --- Interaction Logic ---
          readOnly: isReadOnly,
          onTap: onTap,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          
          // --- Keyboard Logic ---
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLength: isNumber ? 10 : null, // Limit input length
          inputFormatters: isNumber
              ? [FilteringTextInputFormatter.digitsOnly] 
              : [],

          // --- MODIFIED VALIDATION LOGIC ---
          validator: (v) {
            // 1. Use the tested logic for numbers (ID, Phone, License)
            if (isNumber) {
              return Validators.validateTenDigitNumber(v, label);
            }
            
            // 2. Use the tested logic for email
            if (label.contains("البريد")) {
              return Validators.validateEmail(v);
            }
            
            // 3. Fallback for generic text fields
            if (v == null || v.isEmpty) return '$label مطلوب';
            
            return null;
          },
          // ---------------------------------

          decoration: InputDecoration(
            filled: true,
            fillColor: kFieldBgColor,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            
            // Show counter for numbers only
            counterText: isNumber ? null : "",

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: kAccentColor,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: kAccentColor,
                width: 2.0,
              ),
            ),
            // Show error border in red if invalid
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
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
        backgroundColor: kHeaderColor,
        body: SafeArea(
          child: Column(
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.white),
                    const Spacer(),
                    const Text(
                      'تعديل معلومات الحساب',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // --- White Body ---
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
                                  // Names
                                  _buildProfileField(
                                    label: 'الاسم الأول',
                                    controller: _firstNameController,
                                  ),
                                  _buildProfileField(
                                    label: 'الاسم الأخير',
                                    controller: _lastNameController,
                                  ),

                                  // ID - Validation Applied
                                  _buildProfileField(
                                    label: 'الهوية',
                                    controller: _idController,
                                    isNumber: true,
                                    hint: "1xxxxxxxxx",
                                  ),

                                  // Parent Fields
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

                                  // Driver Fields
                                  if (_role == 'driver') ...[
                                    _buildProfileField(
                                      label: 'رقم الرخصة',
                                      controller: _licenseController,
                                      isNumber: true,
                                      hint: "1xxxxxxxxx",
                                    ),
                                    _buildProfileField(
                                      label: 'تاريخ الميلاد',
                                      controller: _birthDateController,
                                      isReadOnly: true,
                                      onTap: _pickDate,
                                      hint: "اضغط للتعديل",
                                    ),
                                  ],

                                  // Admin Fields
                                  if (_role == 'admin') ...[
                                    _buildProfileField(
                                      label: 'المدرسة',
                                      controller: _schoolController,
                                    ),
                                    _buildProfileField(
                                      label: 'تاريخ الميلاد',
                                      controller: _birthDateController,
                                      isReadOnly: true,
                                      onTap: _pickDate,
                                      hint: "اضغط للتعديل",
                                    ),
                                  ],

                                  // Phone - Validation Applied
                                  _buildProfileField(
                                    label: 'رقم الجوال',
                                    controller: _phoneController,
                                    isNumber: true,
                                    hint: "05xxxxxxxx",
                                  ),

                                  // Email
                                  _buildProfileField(
                                    label: 'البريد الإلكتروني',
                                    controller: _emailController,
                                    hint: "example@mail.com",
                                  ),

                                  const SizedBox(height: 16),

                                  // Save Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isUpdating ? null : _updateUserData,
                                      icon: const Icon(Icons.edit_outlined),
                                      label: _isUpdating
                                          ? const Text('جاري التحديث...')
                                          : const Text('تعديل'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFCD4D8),
                                        foregroundColor: Colors.black87,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
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