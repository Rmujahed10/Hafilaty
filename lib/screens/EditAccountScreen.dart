// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORT YOUR VALIDATOR LOGIC HERE ---
import 'package:hafilaty/utils/validators.dart';

// --- Constants ---
const Color kHeaderColor = Color(0xFF0D1B36); // Dark Blue
const Color kAccentColor = Color(0xFF6A994E); // Green (Updated to match AdminHome)
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
  String? _role; 
  String? _phoneDocId; // To store the document ID (phone)

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

  // --- Load Data (Using Phone as Doc ID) ---
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Extract phone from email (05xxxx@hafilatyapp.com)
      _phoneDocId = user.email?.split('@')[0];

      if (_phoneDocId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_phoneDocId)
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

  // --- Update Data (Using Phone as Doc ID) ---
  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      if (_phoneDocId == null) return;

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
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_phoneDocId)
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
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.right,
          readOnly: isReadOnly,
          onTap: onTap,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
          validator: (v) {
            if (isNumber) return Validators.validateTenDigitNumber(v, label);
            if (label.contains("البريد")) return Validators.validateEmail(v);
            if (v == null || v.isEmpty) return '$label مطلوب';
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: kFieldBgColor,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            counterText: "",
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kAccentColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        const SizedBox(height: 12),
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
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // --- Body ---
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
                      ? const Center(child: CircularProgressIndicator(color: kHeaderColor))
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildProfileField(label: 'الاسم الأول', controller: _firstNameController)),
                                      const SizedBox(width: 15),
                                      Expanded(child: _buildProfileField(label: 'الاسم الأخير', controller: _lastNameController)),
                                    ],
                                  ),
                                  _buildProfileField(label: 'الهوية', controller: _idController, isNumber: true, hint: "1xxxxxxxxx"),

                                  if (_role == 'parent') ...[
                                    _buildProfileField(label: 'المدينة', controller: _cityController),
                                    _buildProfileField(label: 'الحي', controller: _districtController),
                                    _buildProfileField(label: 'الشارع', controller: _streetController),
                                  ],

                                  if (_role == 'driver') ...[
                                    _buildProfileField(label: 'رقم الرخصة', controller: _licenseController, isNumber: true, hint: "1xxxxxxxxx"),
                                    _buildProfileField(label: 'تاريخ الميلاد', controller: _birthDateController, isReadOnly: true, onTap: _pickDate, hint: "اضغط للتعديل"),
                                  ],

                                  if (_role == 'admin') ...[
                                    _buildProfileField(label: 'المدرسة', controller: _schoolController),
                                  ],

                                  _buildProfileField(label: 'رقم الجوال', controller: _phoneController, isNumber: true, hint: "05xxxxxxxx"),
                                  _buildProfileField(label: 'البريد الإلكتروني', controller: _emailController, hint: "example@mail.com"),

                                  const SizedBox(height: 20),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isUpdating ? null : _updateUserData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFCD4D8),
                                        foregroundColor: Colors.black87,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        elevation: 0,
                                      ),
                                      child: _isUpdating
                                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                                          : const Text('تعديل البيانات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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