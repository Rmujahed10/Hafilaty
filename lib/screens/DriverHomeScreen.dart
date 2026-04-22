// ignore_for_file: file_names
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'TripMapScreen.dart';
import 'package:intl/intl.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});
  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  String? assignedBusId;
  bool isLoadingBus = true;
  static const bool isTestingMode = true;

  @override
  void initState() {
    super.initState();
    _loadDriverBus();
  }

  Future<void> _loadDriverBus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final phone = user.email?.split('@')[0];
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(phone)
        .get();

    if (mounted) {
      setState(() {
        assignedBusId = doc.data()?['AssignedBusID'];
        isLoadingBus = false;
      });

      _checkAndResetDailyTrips();
    }
  }

  Future<void> _checkAndResetDailyTrips() async {
    if (assignedBusId == null) return;

    final busDoc = await FirebaseFirestore.instance
        .collection('Buses')
        .doc(assignedBusId)
        .get();
    if (!busDoc.exists) return;

    final data = busDoc.data()!;
    final afternoonStatus = data['afternoonTripStatus'] ?? 'لم تبدأ';
    final Timestamp? lastUpdated = data['LastUpdated'] as Timestamp?;

    if (lastUpdated != null) {
      final lastUpdatedDate = lastUpdated.toDate();
      final now = DateTime.now();

      // Check if the last update was on a previous day
      bool isNewDay =
          now.day != lastUpdatedDate.day ||
          now.month != lastUpdatedDate.month ||
          now.year != lastUpdatedDate.year;

      // Check if it is past 3:00 PM (15:00) today
      bool isPast3PM = now.hour >= 15;

      // Trigger reset if it's a completely new day OR (it's past 3 PM and the afternoon trip isn't already reset)
      if (isNewDay || (isPast3PM && afternoonStatus != 'لم تبدأ')) {
        await FirebaseFirestore.instance
            .collection('Buses')
            .doc(assignedBusId)
            .update({
              'morningTripStatus': 'لم تبدأ',
              'afternoonTripStatus': 'لم تبدأ',
              'LastUpdated': FieldValue.serverTimestamp(),
            });

        // Optional: Trigger a quick UI refresh if the status changed while the user is looking at the screen
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              _TopHeader(title: "لوحة التحكم", onLang: () {}),
              Expanded(
                child: isLoadingBus
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _MainCardContainer(
                              children: [
                                _buildWelcome(),
                                const SizedBox(height: 24),
                                const _SectionHeader(title: "رحلاتي اليومية"),
                                if (assignedBusId == null)
                                  const Text(
                                    "لم يتم تعيين حافلة لك بعد",
                                    style: TextStyle(color: Colors.grey),
                                  )
                                else
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('Buses')
                                        .doc(assignedBusId)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      // ✅ 1. Set distinct default statuses
                                      String morningStatus = "لم تبدأ";
                                      String afternoonStatus = "لم تبدأ";

                                      if (snapshot.hasData &&
                                          snapshot.data!.exists) {
                                        final busData =
                                            snapshot.data!.data()
                                                as Map<String, dynamic>;

                                        // ✅ 2. Read the specific fields defined by your backend AI
                                        morningStatus =
                                            busData['morningTripStatus'] ??
                                            "لم تبدأ";
                                        afternoonStatus =
                                            busData['afternoonTripStatus'] ??
                                            "لم تبدأ";
                                      }

                                      final hour = DateTime.now().hour;
                                      bool isMorningActive = isTestingMode
                                          ? true
                                          : (hour >= 4 && hour < 11);
                                      bool isAfternoonActive = isTestingMode
                                          ? true
                                          : (hour >= 11 && hour < 17);

                                      return Column(
                                        children: [
                                          _buildTripSection(
                                            context,
                                            title: 'رحلة الذهاب',
                                            destination: 'المدرسة',
                                            time: '5:30 صباحاً',
                                            status:
                                                morningStatus, // ✅ 3. Pass specific morning status
                                            busId: assignedBusId!,
                                            isActive: isMorningActive,
                                            isMorningTrip: true,
                                          ),
                                          const SizedBox(height: 20),
                                          _buildTripSection(
                                            context,
                                            title: 'رحلة العودة',
                                            destination: 'منازل الطلاب',
                                            time: '1:30 مساءً',
                                            status:
                                                afternoonStatus, // ✅ 4. Pass specific afternoon status
                                            busId: assignedBusId!,
                                            isActive: isAfternoonActive,
                                            isMorningTrip: false,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
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
        return Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$greeting، $name',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF101828),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripSection(
    BuildContext context, {
    required String title,
    required String destination,
    required String time,
    required String status,
    required String busId,
    required bool isActive,
    required bool isMorningTrip,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F3F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMorningTrip ? Icons.wb_sunny_outlined : Icons.home_outlined,
                size: 18,
                color: const Color(0xFF98AF8D),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF0D1B36),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF2F3F5)),
          _buildDataRow('الوجهة النهائية', destination),
          _buildDataRow('وقت البداية', time),
          _buildDataRow('الحالة', status),

          // ✅ Local filtering logic for accurate student count
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Attendance')
                .doc(DateFormat('yyyy-MM-dd').format(DateTime.now()))
                .collection('PresentStudents')
                .snapshots(),
            builder: (context, snapshot) {
              int count = 0;

              if (snapshot.hasData && snapshot.data != null) {
                count = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final studentBusId = data['BusID']?.toString() ?? '';

                  // Checks if "Bus_32438_102" contains "102"
                  return studentBusId.isNotEmpty &&
                      busId.contains(studentBusId);
                }).length;
              }

              return _buildDataRow('الطلاب الحاضرين', '$count طالب');
            },
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isActive
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripMapScreen(
                          busId: busId,
                          isMorningTrip: isMorningTrip,
                        ),
                      ),
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? const Color(0xFFD4E09B)
                    : Colors.grey.shade300,
                foregroundColor: const Color(0xFF0D1B36),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isActive ? 'ادخل على الرحلة' : 'غير متاح',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
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
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
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

/* --- Reusable Components --- */
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
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
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
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF98AF8D),
          ),
        ),
      ),
    );
  }
}
