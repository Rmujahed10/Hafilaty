// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORT YOUR VALIDATOR LOGIC ---
import 'package:hafilaty/utils/validators.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  // --- Styling Constants ---
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kAccentGreen = Color(0xFF98AF8D);
  static const Color _kFieldBg = Color(0xFFF9FAFB);

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
  final _licenseController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _schoolController = TextEditingController();

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _role; 
  String? _phoneDocId;

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
              primary: _kAccentGreen,
              onPrimary: Colors.white,
              onSurface: _kHeaderBlue,
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

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      _phoneDocId = user.email?.split('@')[0];
      if (_phoneDocId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(_phoneDocId).get();
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUpdating = true);
    try {
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
        updatedData.addAll({'school': _schoolController.text.trim()});
      }

      await FirebaseFirestore.instance.collection('users').doc(_phoneDocId!).update(updatedData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث البيانات بنجاح.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء تحديث البيانات.')));
      }
    }
    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              _TopHeader(
                title: 'تعديل معلومات الحساب',
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _kHeaderBlue))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _MainCardContainer(
                              children: [
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const _SectionLabel(label: "المعلومات الشخصية"),
                                      Row(
                                        children: [
                                          Expanded(child: _buildProfileField(label: 'الاسم الأول', controller: _firstNameController, icon: Icons.person_outline)),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildProfileField(label: 'الاسم الأخير', controller: _lastNameController, icon: Icons.person_outline)),
                                        ],
                                      ),
                                      _buildProfileField(label: 'الهوية', controller: _idController, isNumber: true, hint: "1xxxxxxxxx", icon: Icons.badge_outlined),

                                      if (_role == 'parent') ...[
                                        const SizedBox(height: 16),
                                        const _SectionLabel(label: "بيانات الموقع"),
                                        _buildProfileField(label: 'المدينة', controller: _cityController, icon: Icons.location_city_outlined),
                                        _buildProfileField(label: 'الحي', controller: _districtController, icon: Icons.map_outlined),
                                        _buildProfileField(label: 'الشارع', controller: _streetController, icon: Icons.streetview_outlined),
                                      ],

                                      if (_role == 'driver') ...[
                                        const SizedBox(height: 16),
                                        const _SectionLabel(label: "بيانات القيادة"),
                                        _buildProfileField(label: 'رقم الرخصة', controller: _licenseController, isNumber: true, hint: "1xxxxxxxxx", icon: Icons.card_membership_outlined),
                                        _buildProfileField(label: 'تاريخ الميلاد', controller: _birthDateController, isReadOnly: true, onTap: _pickDate, hint: "اضغط للتعديل", icon: Icons.calendar_today_outlined),
                                      ],

                                      if (_role == 'admin') ...[
                                        const SizedBox(height: 16),
                                        const _SectionLabel(label: "بيانات الإدارة"),
                                        _buildProfileField(label: 'المدرسة', controller: _schoolController, icon: Icons.school_outlined),
                                      ],

                                      const SizedBox(height: 16),
                                      const _SectionLabel(label: "معلومات التواصل"),
                                      _buildProfileField(label: 'رقم الجوال', controller: _phoneController, isNumber: true, hint: "05xxxxxxxx", icon: Icons.phone_android_outlined),
                                      _buildProfileField(label: 'البريد الإلكتروني', controller: _emailController, hint: "example@mail.com", icon: Icons.email_outlined),

                                      const SizedBox(height: 32),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _isUpdating ? null : _updateUserData,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _kHeaderBlue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                            elevation: 0,
                                          ),
                                          child: _isUpdating
                                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                              : const Text('حفظ التعديلات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isNumber = false,   
    bool isReadOnly = false, 
    VoidCallback? onTap,     
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _kAccentGreen, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          onTap: onTap,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _kHeaderBlue),
          validator: (v) {
            if (isNumber) return Validators.validateTenDigitNumber(v, label);
            if (label.contains("البريد")) return Validators.validateEmail(v);
            if (v == null || v.isEmpty) return '$label مطلوب';
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: _kFieldBg,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: _kAccentGreen, size: 20),
            counterText: "",
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kAccentGreen, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.0)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _kHeaderBlue,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        currentIndex: 1, // Profile active
        onTap: (index) {
          if (index == 0) {
            if (_role == "admin") {
              Navigator.pushReplacementNamed(context, '/AdminHome');
            } else if (_role == "parent") {
              Navigator.pushReplacementNamed(context, '/parent_home');
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 28), label: 'الملف الشخصي'),
        ],
      ),
    );
  }
}

/* -------------------- UI Kit Components -------------------- */

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopHeader({required this.title, required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)),
      child: Row(
        children: [
          const SizedBox(width: 48),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const Spacer(),
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 22)),
        ],
      ),
    );
  }
}

class _MainCardContainer extends StatelessWidget {
  final List<Widget> children;
  const _MainCardContainer({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.75),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF98AF8D))),
    );
  }
}