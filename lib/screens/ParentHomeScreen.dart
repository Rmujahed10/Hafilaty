import 'package:flutter/material.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AppBar(
            title: const Text('الصفحة الرئيسية لولي الأمر'),
            backgroundColor: const Color(0xFF0D1B36),
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