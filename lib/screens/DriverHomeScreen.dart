import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'TripMapScreen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  // 🎨 الألوان الثابتة
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kGreenAccent = Color(0xFF98AF8D);
  static const Color _kCardBg = Color(0xFFDDE5D1);

  final user = FirebaseAuth.instance.currentUser;
  String get driverId => user?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              // ✅ الهيدر العلوي
              _TopHeader(title: "لوحة التحكم", onLang: () {}),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _MainCardContainer(
                        children: [
                          _buildWelcome(),
                          const SizedBox(height: 20),
                          const _SectionHeader(title: "رحلاتي"),
                          const SizedBox(height: 15),
                          const _SectionHeader(title: "رحلة الذهاب"),
                          _buildTrips(type: "going"),
                          const SizedBox(height: 20),
                          const _SectionHeader(title: "رحلة العودة"),
                          _buildTrips(type: "returning"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ الشريط السفلي المطلوب
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ الترحيب
  Widget _buildWelcome() {
    return const Align(
      alignment: Alignment.centerRight,
      child: Text(
        "صباح الخير، ساجد",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      ),
    );
  }

  // ✅ جلب الرحلات
  Widget _buildTrips({required String type}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Trips")
          .where("driverId", isEqualTo: driverId)
          .where("type", isEqualTo: type)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var trips = snapshot.data!.docs;
        if (trips.isEmpty)
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text("لا توجد رحلات"),
          );

        return Column(children: trips.map((trip) => _tripCard(trip)).toList());
      },
    );
  }

  // ✅ كرت الرحلة
  Widget _tripCard(QueryDocumentSnapshot trip) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        children: [
          _row("الوجهة النهائية:", trip['destination'].toString()),
          _row("وقت بداية الرحلة:", trip['startTime'].toString()),
          _row("حالة الرحلة:", trip['status'].toString()),
          _row("عدد الطلاب:", trip['studentsCount'].toString()),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreenAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _startTrip(trip.id),
            child: const Text(
              "بدء الرحلة",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  void _startTrip(String tripId) {
    FirebaseFirestore.instance.collection("Trips").doc(tripId).update({
      "status": "started",
    });
  }

  // ✅ الـ Bottom Navigation Bar بنفس الطريقة التي طلبتِها
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
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        currentIndex: 0, // لوحة التحكم (الرئيسية) هي المفعلة هنا
        onTap: (index) {
          if (index == 0) {
            // الانتقال لصفحة الخريطة عند الضغط على الرئيسية
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TripMapScreen()),
            );
          } else if (index == 1) {
            // هنا يمكنك الانتقال لصفحة الملف الشخصي
            // Navigator.pushReplacementNamed(context, '/profile');
          }
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

// --- الكومبوننتس المساعدة ---

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onLang;
  const _TopHeader({required this.title, required this.onLang});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)),
      child: Row(
        children: [
          IconButton(
            onPressed: onLang,
            icon: const Icon(Icons.language, color: Colors.white),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Color(0xFF98AF8D),
        ),
      ),
    );
  }
}
