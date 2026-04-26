// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'MapPickerScreen.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameAr = TextEditingController();
  final _nameEn = TextEditingController();
  final _idNumber = TextEditingController();
  final _parentPhone = TextEditingController();
  final _secondPhone = TextEditingController();

  double? _selectedLat;
  double? _selectedLng;
  String _locationStatus = "اضغط لتحديد موقع المنزل على الخريطة";

  String? selectedSchoolName;
  String? selectedSchoolId;
  String? selectedGrade;
  String? selectedGender;
  String? currentEduLevel;

  final List<String> primaryGrades = [
    "الأول ابتدائي",
    "الثاني ابتدائي",
    "الثالث ابتدائي",
    "الرابع ابتدائي",
    "الخامس ابتدائي",
    "السادس ابتدائي",
  ];

  final List<String> middleGrades = [
    "الأول متوسط",
    "الثاني متوسط",
    "الثالث متوسط",
  ];

  final List<String> highGrades = [
    "الأول ثانوي",
    "الثاني ثانوي",
    "الثالث ثانوي",
  ];

  static const Color _kDarkBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kAccent = Color(0xFF6A994E);

  @override
  void initState() {
    super.initState();
    _autoPopulateParentPhone();
  }

  void _autoPopulateParentPhone() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final realPhone = user.email!.split('@')[0];
      setState(() {
        _parentPhone.text = realPhone;
      });
    }
  }

  // --- Location Logic with Permission Checks ---
  Future<void> _handleLocationSelection() async {
    bool proceed = await _showLocationWarning();
    if (proceed) {
      if (!mounted) return;
      final LatLng? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapPickerScreen()),
      );

      // Check mounted after async gap
      if (!mounted) return;
      if (result != null) {
        _validateAndSaveLocation(result);
      }
    }
  }

  Future<void> _validateAndSaveLocation(LatLng pickedLocation) async {
    try {
      // Ensure permissions are granted before calling getCurrentPosition
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position currentPos = await Geolocator.getCurrentPosition();
      double distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        pickedLocation.latitude,
        pickedLocation.longitude,
      );

      if (distance > 150) {
        _showSimpleAlert(
          "تنبيه: الموقع المختار بعيد عن موقعك الحالي. يرجى التأكد من دقة اختيار منزل الطالب لضمان وصول الباص.",
        );
      }

      setState(() {
        _selectedLat = pickedLocation.latitude;
        _selectedLng = pickedLocation.longitude;
        _locationStatus = "تم تحديد الموقع بنجاح ✅";
      });
    } catch (e) {
      _showSimpleAlert("تعذر التحقق من الموقع: $e");
    }
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
                title: "تسجيل ابن جديد",
                onBack: () => Navigator.pop(context),
                onLang: () {},
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _MainCardContainer(
                        children: [
                          _buildStudentAvatar(),
                          const SizedBox(height: 30),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionLabel(
                                  label: "بيانات الطالب الأساسية",
                                ),

                                _buildSmartField(
                                  "اسم الطالب ثلاثي (بالعربي)",
                                  _nameAr,
                                  Icons.person_outline,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[\u0600-\u06FF\s]'),
                                    ),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return "الاسم مطلوب";
                                    }
                                    if (v.trim().split(' ').length < 3) {
                                      return "يجب إدخال الاسم ثلاثي";
                                    }
                                    return null;
                                  },
                                ),

                                _buildSmartField(
                                  "Student Triple Name (English)",
                                  _nameEn,
                                  Icons.person_outline,
                                  isEnglish: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z\s]'),
                                    ),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return "Name is required";
                                    }
                                    if (v.trim().split(' ').length < 3) {
                                      return "Please enter triple name";
                                    }
                                    return null;
                                  },
                                ),

                                _buildGenderDropdown(), // ✅ هذا السطر اللي ناقصك

                                _buildSmartField(
                                  "رقم الهوية",
                                  _idNumber,
                                  Icons.badge_outlined,
                                  isNumber: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return "رقم الهوية مطلوب";
                                    }
                                    if (v.length != 10) {
                                      return "يجب أن يتكون من 10 أرقام";
                                    }
                                    return null;
                                  },
                                ),

                                const _SectionLabel(
                                  label: "موقع المنزل (مهم جداً للحافلة)",
                                ),
                                _buildLocationPicker(),
                                const SizedBox(height: 20),

                                const _SectionLabel(label: "بيانات التواصل"),
                                _buildSmartField(
                                  "رقم الجوال المسجل",
                                  _parentPhone,
                                  Icons.verified_user_outlined,
                                  isReadOnly: true,
                                ),

                                _buildSmartField(
                                  "رقم الجوال الإضافي",
                                  _secondPhone,
                                  Icons.phone_enabled_outlined,
                                  isNumber: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (v) {
                                    if (v != null && v.isNotEmpty) {
                                      if (v.length != 10) {
                                        return "يجب أن يكون 10 أرقام";
                                      }
                                      if (!v.startsWith('05')) {
                                        return "يجب أن يبدأ بـ 05";
                                      }
                                    }
                                    return null;
                                  },
                                ),

                                const _SectionLabel(
                                  label: "المعلومات الدراسية",
                                ),
                                _buildSchoolDropdown(),
                                _buildGradeDropdown(),

                                const SizedBox(height: 40),
                                Center(child: _buildSubmitButton()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return _dropdownWrapper(
      label: "جنس الطالب",
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(border: InputBorder.none),
        initialValue: selectedGender,
        hint: const Text("اختر الجنس"),
        items: const [
          DropdownMenuItem(value: "male", child: Text("ولد")),
          DropdownMenuItem(value: "female", child: Text("بنت")),
        ],
        onChanged: (val) {
          setState(() {
            selectedGender = val;
            selectedSchoolId = null; // مهم
          });
        },
        validator: (v) => v == null ? "الرجاء اختيار الجنس" : null,
      ),
    );
  }

  // --- UI Components ---

  Widget _buildLocationPicker() {
    return InkWell(
      onTap: _handleLocationSelection,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedLat == null
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.map_rounded, color: _kAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _locationStatus,
                style: TextStyle(
                  color: _selectedLat == null ? Colors.grey[600] : _kDarkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            if (_selectedLat != null)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
    bool isEnglish = false,
    bool isReadOnly = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _kDarkBlue,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          textAlign: isEnglish ? TextAlign.left : TextAlign.right,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isReadOnly ? Colors.grey : _kDarkBlue,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isReadOnly ? Colors.grey[50] : Colors.grey[100],
            prefixIcon: Icon(icon, color: _kAccent, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          validator:
              validator ??
              (v) => (v == null || v.isEmpty) ? "هذا الحقل مطلوب" : null,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLat == null) {
        _showSimpleAlert("الرجاء تحديد موقع المنزل على الخريطة أولاً");
        return;
      }

      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection("StudentRequests")
            .doc(_idNumber.text)
            .set({
              "name_ar": _nameAr.text.trim(),
              "name_en": _nameEn.text.trim(),
              "IDNumber": _idNumber.text.trim(),
              "parentPhone": _parentPhone.text.trim(),
              "secondPhone": _secondPhone.text.trim(),
              "SchoolName": selectedSchoolName,
              "schoolId": int.parse(selectedSchoolId!),
              "Grade": selectedGrade,
              "status": "pending",
              "createdAt": FieldValue.serverTimestamp(),
              "lat": _selectedLat,
              "lng": _selectedLng,
            });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("تم إرسال الطلب بنجاح")));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) _showSimpleAlert("حدث خطأ أثناء الحفظ: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showLocationWarning() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("تنبيه دقة الموقع", textAlign: TextAlign.right),
            content: const Text(
              "من فضلك، تأكد من أنك في منزل الطالب الآن لضمان دقة التوزيع.",
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("موافق"),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSimpleAlert(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(msg, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("حسناً"),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: selectedGender == null
          ? null
          : FirebaseFirestore.instance
                .collection("Schools")
                .where("gender", isEqualTo: selectedGender)
                .snapshots(),
      builder: (context, snapshot) {
        return _dropdownWrapper(
          label: "المدرسة",
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: InputBorder.none),
            initialValue: selectedSchoolId,
            hint: Text(
              selectedGender == null ? "اختر الجنس أولاً" : "اختر المدرسة",
            ),
            items: (snapshot.hasData && selectedGender != null)
                ? snapshot.data!.docs.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['School Name_ar']),
                    );
                  }).toList()
                : [],
            onChanged: selectedGender == null
                ? null
                : (val) {
                    final selectedDoc = snapshot.data!.docs.firstWhere(
                      (d) => d.id == val,
                    );
                    setState(() {
                      selectedSchoolId = val;
                      selectedSchoolName = selectedDoc['School Name_ar'];
                      currentEduLevel =
                          selectedDoc['EduLevel']; // جلب المرحلة من الداتا
                      selectedGrade = null; // تصفير الصف عند تغيير المدرسة
                    });
                  },
            validator: (v) => v == null ? "الرجاء اختيار المدرسة" : null,
          ),
        );
      },
    );
  }

  Widget _buildGradeDropdown() {
    // تحديد القائمة المناسبة بناءً على EduLevel المخزن في قاعدة البيانات
    List<String> currentGradesList = [];
    if (currentEduLevel == "Primary School" ||
        currentEduLevel == "Elementary School") {
      currentGradesList = primaryGrades;
    } else if (currentEduLevel == "Middle School") {
      currentGradesList = middleGrades;
    } else if (currentEduLevel == "High School") {
      currentGradesList = highGrades;
    }

    return _dropdownWrapper(
      label: "الصف الدراسي",
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(border: InputBorder.none),
        initialValue: selectedGrade,
        hint: Text(
          selectedSchoolId == null ? "اختر المدرسة أولاً" : "اختر الصف",
        ),
        // إذا لم يتم اختيار مدرسة، تكون القائمة فارغة
        items: currentGradesList
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: currentEduLevel == null
            ? null
            : (val) => setState(() => selectedGrade = val),
        validator: (v) => v == null ? "الرجاء اختيار الصف" : null,
      ),
    );
  }

  Widget _dropdownWrapper({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _kDarkBlue,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _kDarkBlue,
        minimumSize: const Size(220, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: _isLoading ? null : _submitData,
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              "إرسال الطلب",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildStudentAvatar() {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: _kDarkBlue.withValues(alpha: 0.1),
            width: 4,
          ),
          image: const DecorationImage(
            image: NetworkImage(
              'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
            ),
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack, onLang;
  const _TopHeader({
    required this.title,
    required this.onBack,
    required this.onLang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      color: const Color(0xFF0D1B36),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),

          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          IconButton(
            onPressed: onLang,
            icon: const Icon(Icons.language, color: Colors.white, size: 22),
          ),
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
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(children: children),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6A994E),
        ),
      ),
    );
  }
}
