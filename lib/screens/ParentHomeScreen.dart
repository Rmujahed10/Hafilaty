// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Color Constants (Synced with AdminHome) ---
const Color _kDarkBlue = Color(0xFF0D1B36);
const Color _kLightGrey = Color(0xFFF5F5F5);
const Color _kAccent = Color(0xFF6A994E);

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // Dynamically fetch user data using phone as Doc ID
  Stream<DocumentSnapshot> _getUserStream() {
    String phoneDocId = user?.email?.split('@')[0] ?? "";
    return FirebaseFirestore.instance
        .collection('users')
        .doc(phoneDocId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    String phoneDocId = user?.email?.split('@')[0] ?? "";

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
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
                      /// --- Dynamic Welcome Text ---
                      StreamBuilder<DocumentSnapshot>(
                        stream: _getUserStream(),
                        builder: (context, snapshot) {
                          String name = "...";
                          if (snapshot.hasData && snapshot.data!.exists) {
                            name = snapshot.data!.get('firstName') ?? "مستخدم";
                          }
                          return Text(
                            'صباح الخير، $name',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _kDarkBlue,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 25),

                      /// --- Section: Student Management ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'إدارة الأبناء',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF98AF8D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: _kAccent, size: 28),
                            onPressed: () => Navigator.pushNamed(context, '/add_student'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// --- Student Cards ---
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Students')
                            .where('parentPhone', isEqualTo: phoneDocId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          var students = snapshot.data?.docs ?? [];
                          if (students.isEmpty) {
                            return const Center(
                              child: Text("لا يوجد أبناء مسجلين حالياً", 
                              style: TextStyle(color: Colors.grey, fontSize: 13))
                            );
                          }
                          return Column(
                            children: students.map((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              return _buildStudentCard(
                                data['StudentName'] ?? '',
                                data['Grade'] ?? '',
                                data['SchoolName'] ?? '',
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      /// --- Section: Attendance Confirmation ---
                      const Text(
                        'حالة تأكيد الحضور',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF98AF8D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 5, bottom: 15),
                        child: Text(
                          'يرجى تأكيد حضور الطالب للباص ليوم الغد قبل الساعة ٥:٠٠ صباحاً لضمان وصول الباص في الموعد الملتزم به',
                          style: TextStyle(fontSize: 11, color: Colors.redAccent, height: 1.4),
                        ),
                      ),

                      // Attendance status items
                      _buildAttendanceCard("علي غازي القحطاني"),
                      _buildAttendanceCard("عبدالعزيز غازي القحطاني"),
                    ],
                  ),
                ),
              ),
            ),
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
      padding: const EdgeInsets.only(top: 50, right: 20, left: 10),
      color: _kDarkBlue,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'لوحة التحكم',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(String name, String grade, String school) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFFFD166), // Synced with StudentManagement color
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kDarkBlue),
                ),
                const SizedBox(height: 4),
                Text('الصف: $grade', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('المدرسة: $school', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_left, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E09B).withOpacity(0.4), // Light olive synced with Bus Status
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 18, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: _kDarkBlue, fontSize: 14),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('غائب', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kLightGrey,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: _kDarkBlue,
        unselectedItemColor: Colors.grey.shade400,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/parent_home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/role_home');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 28), label: 'Profile'),
        ],
      ),
    );
  }
}