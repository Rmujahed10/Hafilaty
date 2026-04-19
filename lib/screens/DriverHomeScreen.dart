import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'TripMapScreen.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});
  static const Color _kHeaderBlue = Color(0xFF0D1B36);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A5E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'لوحة التحكم',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcome(),
                      const SizedBox(height: 20),

                      const Text(
                        'رحلاتي',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 9, 34, 78),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // 🚍 رحلة الذهاب
                      _buildTripSection(
  context,
  title: 'رحلة الذهاب',
  destination: 'المدرسة',
  time: '5:30 صباحاً',
  status: 'جارية الآن',
  busId: '102',
  isActive: true,
),

                      const SizedBox(height: 20),

                      // 🔁 رحلة العودة
                      _buildTripSection(
  context,
  title: 'رحلة العودة',
  destination: 'منازل الطلاب',
  time: '1:30 مساءً',
  status: 'لم تبدأ',
  busId: '102',
  isActive: false,
),
                    ],
                  ),
                ),
              ),
            ),

            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  // ✅ الترحيب
  Widget _buildWelcome() {
    final user = FirebaseAuth.instance.currentUser;

    return Align(
      alignment: Alignment.centerRight,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.email?.split('@')[0])
            .snapshots(),
        builder: (context, snapshot) {
          String name = (snapshot.hasData && snapshot.data!.exists)
              ? snapshot.data!.get('firstName') ?? "مستخدم"
              : "...";

          final hour = DateTime.now().hour;
          String greeting = hour < 12 ? "صباح الخير" : "مساء الخير";

          return Text(
            '$greeting، $name',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A5E),
            ),
          );
        },
      ),
    );
  }

  // ✅ هنا التعديل المهم (أضفنا context)
Widget _buildTripSection(
  BuildContext context, {
  required String title,
  required String destination,
  required String time,
  required String status,
  required String busId,
  required bool isActive,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),

      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0D1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            _buildDataRow('الوجهة النهائية :', destination),
            _buildDataRow('وقت بداية الرحلة :', time),
            _buildDataRow('حالة الرحلة :', status),

            StreamBuilder<QuerySnapshot>(
  // البحث في الحضور بناءً على تاريخ اليوم
  stream: FirebaseFirestore.instance
      .collection('Attendance')
      .doc(DateFormat('yyyy-MM-dd').format(DateTime.now()))
      .collection('PresentStudents')
      // يمكنك إضافة فلتر الباص إذا كان السجل يحتوي على طلاب باصات مختلفة
      .where('BusID', isEqualTo: busId) 
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildDataRow('عدد الطلاب الحاضرين اليوم :', 'جاري التحميل...');
    }

    if (snapshot.hasError) {
      return _buildDataRow('عدد الطلاب الحاضرين اليوم :', 'حدث خطأ');
    }

    // عدد المستندات في مجموعة PresentStudents يمثل الطلاب الحاضرين
    final presentCount = snapshot.data?.docs.length ?? 0;

    return _buildDataRow(
      'عدد الطلاب الحاضرين اليوم :',
      '$presentCount طالب',
    );
  },
),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: isActive
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TripMapScreen(),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? const Color(0xFFB4C882)
                    : const Color(0xFFD4E2B5),
                minimumSize: const Size(150, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                isActive ? 'بدء الرحلة' : 'غير متاح',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _kHeaderBlue,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushReplacementNamed(context, '/role_home');
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 28),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded, size: 28),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }
}
