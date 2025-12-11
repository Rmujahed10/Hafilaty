import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kDarkBlue = Color(0xFF0D1B36);
const Color kAccent = Color(0xFF6A994E);

String convertToAuthEmail(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
  return '$cleaned@hafilatyapp.com';
}

class RegistrationScreen extends StatefulWidget {
  final String role;
  final String successRoute;

  const RegistrationScreen({
    super.key,
    required this.role,
    this.successRoute = "/login",
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

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

  Map<String, dynamic> buildUserData(String uid) {
    final role = widget.role;

    Map<String, dynamic> base = {
      "uid": uid,
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
        "school": school.text.trim(),
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

    final authEmail = convertToAuthEmail(phone.text);

    try {
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: authEmail,
        password: password.text,
      );

      final uid = userCred.user!.uid;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(buildUserData(uid));

      Navigator.pushNamedAndRemoveUntil(
        context,
        widget.successRoute,
        (route) => false,
      );
    } catch (e) {
      showError("حدث خطأ أثناء التسجيل");
    }

    setState(() => loading = false);
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<Widget> roleFields() {
    switch (widget.role) {
      case "parent":
        return [
          buildField("المدينة", city, Icons.location_city),
          buildField("الحي", district, Icons.map),
          buildField("الشارع", street, Icons.streetview),
        ];
      case "driver":
        return [
          buildField("رقم الرخصة", licenseNumber, Icons.badge),
          buildField("تاريخ الميلاد", birthDate, Icons.calendar_today),
        ];
      case "admin":
        return [
          buildField("اسم المدرسة", school, Icons.school),
          buildField("تاريخ الميلاد", birthDate, Icons.calendar_today),
        ];
    }
    return [];
  }

  Widget buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: kAccent),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          textAlign: TextAlign.right,
          validator: (v) => v!.isEmpty ? "الحقل مطلوب" : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
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
        const SizedBox(height: 18),
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
            // BLUE HEADER
            Container(
              height: MediaQuery.of(context).size.height * 0.28,
              padding: const EdgeInsets.only(top: 40, left: 15, right: 15),
              color: kDarkBlue,
              child: Column(
                children: [
                  // FIXED BACK BUTTON (always points left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Directionality(
                      textDirection: TextDirection.ltr, // forces left arrow
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
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
                ],
              ),
            ),

            // WHITE FORM CONTAINER
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
                      buildField("الاسم الأول", firstName, Icons.person),
                      buildField("الاسم الأخير", lastName, Icons.person),
                      buildField("رقم الهوية", nationalId, Icons.credit_card),

                      ...roleFields(),

                      buildField("رقم الجوال", phone, Icons.phone),
                      buildField("البريد الإلكتروني", email, Icons.email),

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

                      const SizedBox(height: 10),

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
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "تسجيل الآن",
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
          ],
        ),
      ),
    );
  }
}
