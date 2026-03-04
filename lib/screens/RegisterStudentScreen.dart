// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- Controllers ---
  final _nameAr = TextEditingController();
  final _nameEn = TextEditingController();
  final _idNumber = TextEditingController();
  final _nationalAddress = TextEditingController();
  
  // ✅ This controller will now show the phone number immediately
  final _parentPhone = TextEditingController(); 
  final _secondPhone = TextEditingController();

  String? selectedSchoolName;
  String? selectedSchoolId;
  String? selectedGrade;

  final List<String> grades = [
    "الأول ابتدائي", "الثاني ابتدائي", "الثالث ابتدائي",
    "الرابع ابتدائي", "الخامس ابتدائي", "السادس ابتدائي",
    "الأول متوسط", "الثاني متوسط", "الثالث متوسط",
    "الأول ثانوي", "الثاني ثانوي", "الثالث ثانوي",
  ];

  static const Color _kDarkBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kAccent = Color(0xFF6A994E);

@override
void initState() {
  super.initState();
  // This must be called to fill the controller text
  _autoPopulateParentPhone();
}

void _autoPopulateParentPhone() {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && user.email != null) {
    // Extracts the phone prefix from your login email
    final realPhone = user.email!.split('@')[0];
    setState(() {
      _parentPhone.text = realPhone; // This puts the text into the box
    });
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
                                _SectionLabel(label: "بيانات الطالب الأساسية"),
                                _buildSmartField(
                                  "اسم الطالب ثلاثي (بالعربي)", _nameAr, Icons.person_outline,
                                  hint: "مثال: محمد أحمد الغامدي",
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return "الاسم مطلوب";
                                    if (v.trim().split(' ').length < 3) return "يجب إدخال الاسم ثلاثي على الأقل";
                                    return null;
                                  },
                                ),
                                _buildSmartField(
                                  "Student Triple Name (English)", _nameEn, Icons.person_outline,
                                  isEnglish: true,
                                  hint: "Ex: Mohammed Ahmed Alghamdi",
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return "Name is required";
                                    if (v.trim().split(' ').length < 3) return "Please enter triple name";
                                    return null;
                                  },
                                ),
                                _buildSmartField(
                                  "رقم الهوية", _idNumber, Icons.badge_outlined,
                                  isNumber: true,
                                  hint: "١xxxxxxxxx",
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return "رقم الهوية مطلوب";
                                    if (v.length != 10) return "يجب أن يتكون من ١٠ أرقام";
                                    return null;
                                  },
                                ),
                                _buildSmartField(
                                  "العنوان الوطني", _nationalAddress, Icons.location_on_outlined,
                                  isEnglish: true,
                                  hint: "مثال: ABCD1234",
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return "العنوان الوطني مطلوب";
                                    if (!RegExp(r'^[a-zA-Z]{4}\d{4}$').hasMatch(v)) return "تنسيق غير صحيح (٤ حروف ثم ٤ أرقام)";
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 20),
                                _SectionLabel(label: "بيانات التواصل"),
                                
                                // ✅ Locked & Auto-filled real phone field (Visible to Parent)
                                _buildSmartField(
                                  "رقم الجوال المسجل", _parentPhone, Icons.verified_user_outlined,
                                  isReadOnly: true,
                                  fillColor: Colors.grey[50], // Slightly different shade to show it's locked
                                ),

                                _buildSmartField(
                                  "رقم الجوال الإضافي (اختياري)", _secondPhone, Icons.phone_enabled_outlined,
                                  isNumber: true,
                                  hint: "٠٥xxxxxxxx",
                                  validator: (v) {
                                    if (v != null && v.isNotEmpty) {
                                      if (!RegExp(r'^(05|5)\d{8}$').hasMatch(v)) return "رقم الجوال غير صحيح";
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 20),
                                _SectionLabel(label: "المعلومات الدراسية"),
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
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- Field Logic Helper ---
  Widget _buildSmartField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
    bool isEnglish = false,
    bool isReadOnly = false,
    String? hint,
    Color? fillColor,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: _kDarkBlue, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          textAlign: isEnglish ? TextAlign.left : TextAlign.right,
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
          maxLength: isNumber ? 10 : null,
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 14, 
            color: isReadOnly ? Colors.grey[600] : _kDarkBlue,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor ?? Colors.grey[100],
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.normal),
            counterText: "",
            prefixIcon: Icon(icon, color: _kAccent, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          validator: validator,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Saving linked phone number in the Firestore document
        await FirebaseFirestore.instance.collection("StudentRequests").doc(_idNumber.text).set({
          "name_ar": _nameAr.text.trim(),
          "name_en": _nameEn.text.trim(),
          "IDNumber": _idNumber.text.trim(),
          "NationalAddress": _nationalAddress.text.trim(),
          "parentPhone": _parentPhone.text.trim(), // ✅ Correctly saved linked number
          "secondPhone": _secondPhone.text.trim(),
          "SchoolName": selectedSchoolName,
          "schoolId": int.parse(selectedSchoolId!), 
          "Grade": selectedGrade,
          "status": "pending",
          "createdAt": FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال الطلب بنجاح")));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- Dropdowns & Navigation Components ---
  Widget _buildSchoolDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("Schools").snapshots(),
      builder: (context, snapshot) {
        return _dropdownWrapper(
          label: "المدرسة",
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: InputBorder.none, hintText: "اختر المدرسة"),
            value: selectedSchoolId,
            items: snapshot.hasData ? snapshot.data!.docs.map((doc) {
              return DropdownMenuItem(value: doc.id, child: Text(doc['School Name_ar'].toString()));
            }).toList() : [],
            onChanged: (val) {
              setState(() {
                selectedSchoolId = val;
                var doc = snapshot.data!.docs.firstWhere((d) => d.id == val);
                selectedSchoolName = doc['School Name_ar'];
              });
            },
            validator: (val) => val == null ? "الرجاء اختيار المدرسة" : null,
          ),
        );
      },
    );
  }

  Widget _buildGradeDropdown() {
    return _dropdownWrapper(
      label: "الصف الدراسي",
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(border: InputBorder.none, hintText: "اختر الصف"),
        value: selectedGrade,
        items: grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
        onChanged: (val) => setState(() => selectedGrade = val),
        validator: (val) => val == null ? "الرجاء اختيار الصف" : null,
      ),
    );
  }

  Widget _dropdownWrapper({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: _kDarkBlue, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
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
          : const Text("إرسال الطلب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(color: const Color(0xFFE6E6E6), border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5))),
      child: BottomNavigationBar(
        elevation: 0, backgroundColor: Colors.transparent, type: BottomNavigationBarType.fixed,
        selectedItemColor: _kDarkBlue, unselectedItemColor: Colors.grey[600],
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 28), label: 'الملف الشخصي'),
        ],
      ),
    );
  }

  Widget _buildStudentAvatar() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: Colors.white,
              border: Border.all(color: _kDarkBlue.withOpacity(0.1), width: 4),
              image: const DecorationImage(image: NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'), fit: BoxFit.cover),
            ),
          ),
          CircleAvatar(radius: 18, backgroundColor: _kDarkBlue, child: const Icon(Icons.add_a_photo, color: Colors.white, size: 18)),
        ],
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopHeader({required this.title, required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85, padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)),
      child: Row(children: [
        const SizedBox(width: 48), const Spacer(),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const Spacer(),
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 22)),
      ]),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8))]),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF98AF8D))),
    );
  }
}