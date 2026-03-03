// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// IMPORTANT: Ensure this path matches your actual file structure
import 'RegistrationRequests.dart'; 

// --- Constants ---
const Color kDarkBlue = Color(0xFF0D1B36);
const Color kAccent = Color(0xFF6A994E);
const Color kLightGrey = Color(0xFFF5F5F5); 

class AdminHome extends StatefulWidget {
  final Map<String, dynamic>? schoolData;

  const AdminHome({super.key, this.schoolData});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String schoolName = "جاري التحميل...";
  int studentCount = 0;
  int busCount = 0;
  bool isLoading = true;
  String? currentSchoolId;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final phone = user?.email?.split('@')[0];

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phone)
          .get();

      if (!userDoc.exists) return;

      String schoolIdString = userDoc.get('schoolId').toString();
      currentSchoolId = schoolIdString;
      int schoolIdInt = int.parse(schoolIdString);

      if (currentSchoolId != null) {
        final schoolDoc = await FirebaseFirestore.instance
            .collection('Schools')
            .doc(currentSchoolId)
            .get();

        final studentsQuery = await FirebaseFirestore.instance
            .collection('Students')
            .where('SchoolID', isEqualTo: schoolIdInt)
            .count()
            .get();

        final busesQuery = await FirebaseFirestore.instance
            .collection('Buses')
            .where('SchoolID', isEqualTo: schoolIdInt)
            .count()
            .get();

        if (mounted) {
          setState(() {
            schoolName = schoolDoc.exists
                ? schoolDoc.get('School Name')
                : "مدرسة غير معروفة";
            studentCount = studentsQuery.count ?? 0;
            busCount = busesQuery.count ?? 0;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("ADMIN_HOME_DATA_ERROR: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white, 
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: kDarkBlue))
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildMainContent()),
                ],
              ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.18,
      padding: const EdgeInsets.only(top: 50, right: 20, left: 20),
      color: kDarkBlue, 
      alignment: Alignment.topRight,
      child: const Text(
        "لوحة التحكم",
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                schoolName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kDarkBlue,
                ),
              ),
            ),
            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(child: _buildStatCard("عدد الحافلات", "$busCount")),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard("عدد الطلاب", "$studentCount")),
              ],
            ),

            const SizedBox(height: 30),
            _buildSectionTitle("حالة الحافلات"),
            _buildBusStatusRow(),

            const SizedBox(height: 30),
            _buildSectionTitle("إدارة الطلاب والأسطول"),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    "إدارة الحافلات",
                    Icons.directions_bus,
                    () => Navigator.pushNamed(context, '/bus_management'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildActionCard(
                    "إدارة الطلاب والطالبات",
                    Icons.people,
                    () => Navigator.pushNamed(context, '/students_management'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            _buildSectionTitle("طلبات التسجيل"),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistrationRequests()),
              ),
              child: _buildRegistrationRequests(), 
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('StudentRequests') 
          .where('schoolId', isEqualTo: int.parse(currentSchoolId ?? "0"))
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                "لا توجد طلبات حالية",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name_ar'] ?? "اسم الطالب", 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        "قيد الانتظار",
                        style: TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF98AF8D),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: kDarkBlue, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: kDarkBlue,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusStatusRow() {
    if (currentSchoolId == null) return const SizedBox();
    int schoolIdInt = int.parse(currentSchoolId!);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Buses')
          .where('SchoolID', isEqualTo: schoolIdInt)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final busDocs = snapshot.data!.docs;

        if (busDocs.isEmpty) {
          return const Center(child: Text("لا توجد حافلات مسجلة حالياً"));
        }

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 15,
            runSpacing: 15,
            children: busDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              List<String> statuses = ["متأخر", "في الطريق", "مشكلة"];
              String status = statuses[busDocs.indexOf(doc) % 3];

              return _buildBusStatusItem(
                "حافلة ${data['BusNumber'] ?? '?'}\n$status",
                const Color(0xFFD4E09B),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBusStatusItem(String text, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.42,
      height: 100,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5),
        ],
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: kDarkBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kDarkBlue, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: kDarkBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kLightGrey,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        elevation: 0, 
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: kDarkBlue,
        unselectedItemColor: Colors.grey.shade400,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/AdminHome');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/role_home');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 28),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded, size: 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}