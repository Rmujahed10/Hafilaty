// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORT VALIDATOR LOGIC ---
import 'package:hafilaty/utils/validators.dart';

// --- Constants ---
const Color kDarkBlue = Color(0xFF0D1B36);
const Color kAccent = Color(0xFF6A994E);

// --- Helper Functions ---
String convertToAuthEmail(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
  return '$cleaned@hafilatyapp.com';
}

class SignUpScreen extends StatefulWidget {
  final String role;
  final String successRoute;

  const SignUpScreen({
    super.key,
    required this.role,
    this.successRoute = "/login",
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final nationalId = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  final city = TextEditingController();
  final district = TextEditingController();
  final street = TextEditingController();

  final licenseNumber = TextEditingController();
  final birthDate = TextEditingController();
  final school = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    nationalId.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    city.dispose();
    district.dispose();
    street.dispose();
    licenseNumber.dispose();
    birthDate.dispose();
    school.dispose();
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
              primary: kAccent,
              onPrimary: Colors.white,
              onSurface: kDarkBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        birthDate.text = "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }

  // --- Database Logic ---
  Map<String, dynamic> buildUserData(String uid) {
    final role = widget.role;

    Map<String, dynamic> base = {
      "uid": uid, // Keep auth UID for security rules reference
      "role": role,
      "firstName": firstName.text.trim(),
      "lastName": lastName.text.trim(),
      "nationalId": nationalId.text.trim(),
      "phone": phone.text.trim(),
      "email": email.text.trim(),
      "createdAt": FieldValue.serverTimestamp(),
    };

    if (role == "parent") {
      base.addAll({
        "city": city.text.trim(),
        "district": district.text.trim(),
        "street": street.text.trim(),
      });
    }

    if (role == "driver") {
      base.addAll({
        "licenseNumber": licenseNumber.text.trim(),
        "birthDate": birthDate.text.trim(),
      });
    }

    if (role == "admin") {
      base.addAll({
        "schoolId": school.text
            .trim(), // Stored as schoolId for clear DB mapping
        "birthDate": birthDate.text.trim(),
      });
    }

    return base;
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    if (password.text != confirmPassword.text) {
      showError("كلمة المرور غير متطابقة");
      return;
    }

    setState(() => loading = true);

    // Clean phone for both Auth Email and Document ID
    final cleanedPhone = phone.text.replaceAll(RegExp(r'[^\d]'), '');
    final authEmail = '$cleanedPhone@hafilatyapp.com';

    try {
      // 1. If Admin, verify that the School ID exists in the 'schools' collection
      if (widget.role == "admin") {
        final schoolDoc = await FirebaseFirestore.instance
            .collection("Schools")
            .doc(school.text.trim())
            .get();

        if (!schoolDoc.exists) {
          setState(() => loading = false);
          showError("كود المدرسة غير صحيح، يرجى التأكد من الكود.");
          return;
        }
      }

      // 2. Create Auth Account
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: authEmail,
            password: password.text,
          );

      final uid = userCred.user!.uid;

      // 3. Save to Firestore using cleaned PHONE as the Document ID
      await FirebaseFirestore.instance
          .collection("users")
          .doc(cleanedPhone)
          .set(buildUserData(uid));

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        widget.successRoute,
        (route) => false,
      );
    } catch (e) {
      showError("حدث خطأ أثناء التسجيل: $e");
    }

    setState(() => loading = false);
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- Role Specific Fields ---
  List<Widget> roleFields() {
    switch (widget.role) {
      case "parent":
        return [
          buildField("المدينة", city, Icons.location_city, hint: "مثال: جدة"),
          buildField("الحي", district, Icons.map, hint: "مثال: حي الروضة"),
          buildField("الشارع", street, Icons.streetview),
        ];
      case "driver":
        return [
          buildField(
            "رقم الرخصة",
            licenseNumber,
            Icons.badge,
            isNumber: true,
            hint: "1xxxxxxxxx",
          ),
          buildField(
            "تاريخ الميلاد",
            birthDate,
            Icons.calendar_today,
            isReadOnly: true,
            onTap: _pickDate,
            hint: "اضغط للاختيار",
          ),
        ];
      case "admin":
        return [
          buildField(
            "كود المدرسة (School ID)",
            school,
            Icons.domain_verification,
            hint: "أدخل الكود الخاص بمدرستك",
          ),
          buildField(
            "تاريخ الميلاد",
            birthDate,
            Icons.calendar_today,
            isReadOnly: true,
            onTap: _pickDate,
            hint: "اضغط للاختيار",
          ),
        ];
    }
    return [];
  }

  // --- Smart Field Widget ---
  Widget buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    bool isNumber = false,
    bool isReadOnly = false,
    VoidCallback? onTap,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: kAccent),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          readOnly: isReadOnly,
          onTap: onTap,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLength: isNumber ? 10 : null,
          inputFormatters: isNumber
              ? [FilteringTextInputFormatter.digitsOnly]
              : [],
          validator: (v) {
            if (isNumber) {
              return Validators.validateTenDigitNumber(v, label);
            }
            if (!isNumber && !isPassword && label.contains("البريد")) {
              return Validators.validateEmail(v);
            }
            if (v == null || v.isEmpty) return "$label مطلوب";
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            counterText: isNumber ? null : "",
            suffixIcon: Icon(icon, color: kAccent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.role == "parent"
        ? "إنشاء حساب ولي أمر"
        : widget.role == "driver"
        ? "إنشاء حساب سائق"
        : "إنشاء حساب مشرف";

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kDarkBlue,
        body: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.28,
              padding: const EdgeInsets.only(top: 40, left: 15, right: 15),
              color: kDarkBlue,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.language, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.23,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      buildField(
                        "الاسم الأول",
                        firstName,
                        Icons.person,
                        hint: "أحمد",
                      ),
                      buildField(
                        "الاسم الأخير",
                        lastName,
                        Icons.person,
                        hint: "الغامدي",
                      ),
                      buildField(
                        "رقم الهوية",
                        nationalId,
                        Icons.credit_card,
                        isNumber: true,
                        hint: "1xxxxxxxxx",
                      ),
                      ...roleFields(),
                      buildField(
                        "رقم الجوال",
                        phone,
                        Icons.phone,
                        isNumber: true,
                        hint: "05xxxxxxxx",
                      ),
                      buildField(
                        "البريد الإلكتروني",
                        email,
                        Icons.email,
                        hint: "example@mail.com",
                      ),
                      buildField(
                        "كلمة المرور",
                        password,
                        Icons.lock,
                        isPassword: true,
                      ),
                      buildField(
                        "تأكيد كلمة المرور",
                        confirmPassword,
                        Icons.lock,
                        isPassword: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: loading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccent,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "تسجيل الآن",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
