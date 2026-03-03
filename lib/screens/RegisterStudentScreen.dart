// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameAr = TextEditingController();
  final TextEditingController _nameEn = TextEditingController();
  final TextEditingController _idNumber = TextEditingController();
  final TextEditingController _nationalAddress = TextEditingController();
  final TextEditingController _parentPhone = TextEditingController();
  final TextEditingController _secondPhone = TextEditingController();

  String? selectedSchool;
  String? selectedGrade;

  final List<String> grades = [
    "الأول ابتدائي",
    "الثاني ابتدائي",
    "الثالث ابتدائي",
    "الرابع ابتدائي",
    "الخامس ابتدائي",
    "السادس ابتدائي",
    "الأول متوسط",
    "الثاني متوسط",
    "الثالث متوسط",
    "الأول ثانوي",
    "الثاني ثانوي",
    "الثالث ثانوي",
  ];

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFD1D1D1), width: 1),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1D2755),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text(
            "تسجيل ابن جديد",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(45),
                    topRight: Radius.circular(45),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildStudentAvatar(),
                        const SizedBox(height: 30),

                        // الاسم العربي ثلاثي
                        _buildTextField(
                          _nameAr,
                          "اسم الطالب ثلاثي (بالعربي) :",
                          validator: (value) {
                            if (value == null || value.isEmpty) return "مطلوب";
                            if (value.trim().split(' ').length < 3)
                              return "يجب إدخال الاسم ثلاثي على الأقل";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // الاسم الإنجليزي ثلاثي
                        _buildTextField(
                          _nameEn,
                          "Student Triple Name (English) :",
                          isEnglish: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return "مطلوب";
                            if (value.trim().split(' ').length < 3)
                              return "Please enter triple name";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // رقم الهوية
                        _buildTextField(
                          _idNumber,
                          "رقم الهوية :",
                          isNumber: true,
                          validator: (value) {
                            if (value == null || value.length != 10)
                              return "رقم الهوية يجب أن يكون 10 أرقام";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // العنوان الوطني (4 حروف + 4 أرقام)
                        _buildTextField(
                          _nationalAddress,
                          "العنوان الوطني (مثال: ABCD1234) :",
                          isEnglish: true,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "العنوان الوطني مطلوب";
                            // ريجيكس: 4 حروف إنجليزية (كبيرة أو صغيرة) متبوعة بـ 4 أرقام
                            if (!RegExp(
                              r'^[a-zA-Z]{4}\d{4}$',
                            ).hasMatch(value)) {
                              return "يجب أن يتكون من 4 حروف ثم 4 أرقام";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // رقم الجوال الأول
                        _buildTextField(
                          _parentPhone,
                          "رقم الجوال الأساسي :",
                          isNumber: true,
                          validator: (value) {
                            if (value == null ||
                                !RegExp(r'^(05|5)\d{8}$').hasMatch(value))
                              return "أدخل رقم جوال صحيح";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // رقم الجوال الثاني (اختياري ولكن إذا أدخل يجب أن يكون صحيحاً)
                        _buildTextField(
                          _secondPhone,
                          "رقم الجوال الثاني (اختياري) :",
                          isNumber: true,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^(05|5)\d{8}$').hasMatch(value))
                                return "أدخل رقم جوال صحيح";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildSchoolDropdown(),
                        const SizedBox(height: 12),

                        _buildGradeDropdown(),
                        const SizedBox(height: 30),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 12,
                            ),
                          ),
                          onPressed: _submitData,
                          child: const Text(
                            "إرسال الطلب",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        const CircleAvatar(
          radius: 65,
          backgroundColor: Color(0xFFE0E0E0),
          backgroundImage: NetworkImage(
            'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool isEnglish = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? TextInputType.number
          : (isEnglish ? TextInputType.emailAddress : TextInputType.text),
      textAlign: isEnglish ? TextAlign.left : TextAlign.right,
      decoration: _buildInputDecoration(label),
      validator: validator,
    );
  }

  Widget _buildSchoolDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("Schools").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        var schools = snapshot.data!.docs;
        return DropdownButtonFormField<String>(
          decoration: _buildInputDecoration("اسم المدرسة :"),
          value: selectedSchool,
          items: schools
              .map(
                (doc) => DropdownMenuItem(
                  value: doc['School Name_ar'].toString(),
                  child: Text(doc['School Name_ar'].toString()),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => selectedSchool = val),
          validator: (val) => val == null ? "مطلوب" : null,
        );
      },
    );
  }

  Widget _buildGradeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _buildInputDecoration("الصف :"),
      value: selectedGrade,
      items: grades
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (val) => setState(() => selectedGrade = val),
      validator: (val) => val == null ? "مطلوب" : null,
    );
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection("StudentRequests")
            .doc(_idNumber.text)
            .set({
              "name_ar": _nameAr.text,
              "name_en": _nameEn.text,
              "IDNumber": _idNumber.text,
              "NationalAddress": _nationalAddress.text,
              "parentPhone": _parentPhone.text,
              "secondPhone": _secondPhone.text, // حفظ الرقم الثاني
              "SchoolName": selectedSchool,
              "Grade": selectedGrade,
              "status": "pending",
              "createdAt": Timestamp.now(),
            });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم إرسال الطلب بنجاح")));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("خطأ: $e")));
      }
    }
  }
}
