import 'package:flutter/material.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AppBar(
            title: const Text('الصفحة الرئيسية driver'),
            backgroundColor: const Color(0xFF0D1B36),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      body: const Center(
        child: Text('محتوى السائق هنا (قيد الإنشاء)'),
      ),
    );
  }
}