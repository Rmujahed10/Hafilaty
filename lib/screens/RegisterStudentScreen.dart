// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final nationalIdController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final schoolController = TextEditingController();
  final gradeController = TextEditingController();

  bool isLoading = false;

  /// 🔵 إرسال الطلب (بدون تحويل موقع)
  Future<void> submitStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('StudentRequests').add({
        "StudentName": nameController.text.trim(),
        "NationalID": nationalIdController.text.trim(),
        "Address": addressController.text.trim(), // ✅ نص فقط
        "Phone": phoneController.text.trim(),
        "SchoolName": schoolController.text.trim(),
        "Grade": gradeController.text.trim(),
        "parentId": FirebaseAuth.instance.currentUser!.uid,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم إرسال الطلب للإدارة ✅")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تسجيل ابن جديد"),
        backgroundColor: const Color(0xFF0D1B36),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(nameController, "اسم الطالب"),
              _buildTextField(nationalIdController, "رقم الهوية"),
              _buildTextField(addressController, "العنوان الوطني"),
              _buildTextField(phoneController, "رقم الجوال"),
              _buildTextField(schoolController, "اسم المدرسة"),
              _buildTextField(gradeController, "الصف"),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BAA3C),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: isLoading ? null : submitStudent,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("إرسال الطلب", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "هذا الحقل مطلوب" : null,
      ),
    );
  }
}
