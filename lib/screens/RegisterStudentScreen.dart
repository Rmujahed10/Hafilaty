import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  // وحدات التحكم (Controllers)
  final TextEditingController _nameAr = TextEditingController();
  final TextEditingController _nameEn = TextEditingController();
  final TextEditingController _idNumber = TextEditingController();
  final TextEditingController _nationalAddress = TextEditingController();
  final TextEditingController _parentPhone = TextEditingController();
  final TextEditingController _secondPhone = TextEditingController();

  String? selectedSchoolName;
  String? selectedSchoolId; // متغير لحفظ الـ ID الخاص بالمدرسة
  String? selectedGrade;
  bool _isLoading = false;

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

  // ألوان التصميم المطلوبة من كودك
  final Color _kDarkBlue = const Color(0xFF0D1B36);
  final Color _kInputFill = const Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kDarkBlue,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "تسجيل ابن جديد",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.language,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            _buildStudentAvatar(),
            const SizedBox(height: 25),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(45)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 35,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
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
                        _buildTextField(
                          _nationalAddress,
                          "العنوان الوطني (مثال: ABCD1234) :",
                          isEnglish: true,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "العنوان الوطني مطلوب";
                            if (!RegExp(r'^[a-zA-Z]{4}\d{4}$').hasMatch(value))
                              return "يجب أن يتكون من 4 حروف ثم 4 أرقام";
                            return null;
                          },
                        ),
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
                        _buildSchoolDropdown(),
                        _buildGradeDropdown(),
                        const SizedBox(height: 35),
                        _buildSubmitButton(),
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
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
            image: const DecorationImage(
              image: NetworkImage(
                'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(5),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? TextInputType.number
            : (isEnglish ? TextInputType.emailAddress : TextInputType.text),
        textAlign: isEnglish ? TextAlign.left : TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: _kInputFill,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSchoolDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("Schools").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "اسم المدرسة :",
              filled: true,
              fillColor: _kInputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            value: selectedSchoolId, // نستخدم الـ ID كقيمة
            items: snapshot.data!.docs.map((doc) {
              return DropdownMenuItem<String>(
                value: doc.id, // حفظ الـ ID (مثل 32438)
                child: Text(doc['School Name_ar'].toString()),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                selectedSchoolId = val;
                // الحصول على الاسم للعرض فقط
                var doc = snapshot.data!.docs.firstWhere((d) => d.id == val);
                selectedSchoolName = doc['School Name_ar'];
              });
            },
            validator: (val) => val == null ? "مطلوب" : null,
          );
        },
      ),
    );
  }

  Widget _buildGradeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "الصف :",
          filled: true,
          fillColor: _kInputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        value: selectedGrade,
        items: grades
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (val) => setState(() => selectedGrade = val),
        validator: (val) => val == null ? "مطلوب" : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: 180,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: _isLoading ? null : _submitData,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                "إرسال الطلب",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // تم استخدام .doc(_idNumber.text) لحفظ السجل برقم الهوية
        await FirebaseFirestore.instance
            .collection("StudentRequests")
            .doc(_idNumber.text)
            .set({
              "name_ar": _nameAr.text,
              "name_en": _nameEn.text,
              "IDNumber": _idNumber.text,
              "NationalAddress": _nationalAddress.text,
              "parentPhone": _parentPhone.text,
              "secondPhone": _secondPhone.text,
              "SchoolName": selectedSchoolName, // حفظ الاسم
              "SchoolId": int.parse(selectedSchoolId!), 
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
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
