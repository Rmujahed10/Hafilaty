import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Reuse your existing constants
const Color kDarkBlue = Color(0xFF0D1B36);
const Color kAccent = Color(0xFF6A994E);

class AdminHome extends StatefulWidget {
  final Map<String, dynamic>? schoolData; // Received from LoginScreen arguments

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
      // 1. Get current user's schoolId from their profile
      final user = FirebaseAuth.instance.currentUser;
      final phone = user?.email?.split(
        '@',
      )[0]; // Based on your custom email logic

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phone)
          .get();

      currentSchoolId = userDoc.get('schoolId');

      if (currentSchoolId != null) {
        // 2. Fetch School Name
        final schoolDoc = await FirebaseFirestore.instance
            .collection('Schools')
            .doc(currentSchoolId)
            .get();

        // 3. Fetch Counts (Optimized using count queries)
        final studentsQuery = await FirebaseFirestore.instance
            .collection('Students')
            .where('SchoolID', isEqualTo: currentSchoolId)
            .count()
            .get();

        final busesQuery = await FirebaseFirestore.instance
            .collection('Buses')
            .where('SchoolID', isEqualTo: currentSchoolId)
            .count()
            .get();

        if (mounted) {
          setState(() {
            schoolName =
                schoolDoc.get('School Name') ?? "اسم المدرسة غير متوفر";
            studentCount = studentsQuery.count ?? 0;
            busCount = busesQuery.count ?? 0;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading admin home: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kDarkBlue,
        body: Stack(
          children: [
            // Header
            _buildHeader(),
            // Main Content
            Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.15,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        schoolName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: kDarkBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Section
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard("عدد الحافلات", "$busCount"),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildStatCard("عدد الطلاب", "$studentCount"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),
                    _buildSectionTitle("حالة الحافلات"),
                    _buildBusStatusRow(),

                    const SizedBox(height: 25),
                    _buildSectionTitle("إدارة الطلاب والأسطول"),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            "إدارة الحافلات",
                            Icons.directions_bus,
                            () =>
                                Navigator.pushNamed(context, '/bus_management'),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildActionCard(
                            "إدارة الطلاب والطالبات",
                            Icons.people,
                            () => Navigator.pushNamed(
                              context,
                              '/students_management',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),
                    _buildSectionTitle("طلبات التسجيل"),
                    _buildRegistrationRequests(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      alignment: Alignment.topRight,
      child: const Text(
        "لوحة التحكم",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: kDarkBlue, fontSize: 14)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: kDarkBlue,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusStatusRow() {
    // Dummy Data as requested
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildBusStatusItem("حافلة ١٠١ :\nمتأخر", const Color(0xFFD4E09B)),
          _buildBusStatusItem(
            "حافلة ١٠٢ :\nفي الطريق",
            const Color(0xFFE1F5FE),
          ),
          _buildBusStatusItem(
            "حافلة ١٠٣ :\nمشكلة في الرحلة",
            const Color(0xFFD4E09B),
          ),
        ],
      ),
    );
  }

  Widget _buildBusStatusItem(String text, Color color) {
    return Container(
      width: 110,
      height: 110,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kDarkBlue, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: kDarkBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationRequests() {
    // This uses a StreamBuilder to reactively show requests
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('registration_requests')
          .where('schoolId', isEqualTo: currentSchoolId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "لا توجد طلبات حالية",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/request_details',
                arguments: doc.id,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E9AAF).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['studentName'] ?? "اسم غير معروف",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          "قيد الانتظار",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                    ),
                    const Text("٢٨ شعبان", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
