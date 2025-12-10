import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AppBar(
            title: const Text('الصفحة الرئيسية admin '),
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      body: const Center(
        child: Text('محتوى ولي الأمر هنا (قيد الإنشاء)'),
      ),
    );
  }
}