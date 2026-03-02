import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final Color _kDarkBlue = const Color(0xFF192252); // اللون الكحلي للخلفية
  final user = FirebaseAuth.instance.currentUser;

  // دالة لجلب اسم المستخدم الحالي ديناميكياً
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

    return Scaffold(
      backgroundColor: _kDarkBlue,
      // الجزء العلوي (لوحة التحكم)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'لوحة التحكم',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: const Icon(
          Icons.arrow_back_ios,
          color: Colors.white,
          size: 20,
        ),
      ),
      body: Column(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    /// --- الترحيب الديناميكي ---
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
                            color: Color(0xFF192252),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    /// --- إدارة الأبناء ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF90A4AE),
                            size: 30,
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/add_student'),
                        ),
                        const Text(
                          'ادارة الابناء',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// --- بطاقات الأبناء ---
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Students')
                          .where('parentPhone', isEqualTo: phoneDocId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        var students = snapshot.data?.docs ?? [];
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

                    /// --- قسم تأكيد الحضور ---
                    const Text(
                      'حالة تأكيد الحضور',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'يرجى تأكيد حضور الطالب للباص ليوم الغد قبل الساعة ٥:٠٠ صباحاً لضمان وصول الباص في الموعد الملتزم به',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),

                    const SizedBox(height: 15),

                    // مثال لبطاقات التأكيد كما في الصورة
                    _buildAttendanceCard("علي غازي القحطاني"),
                    _buildAttendanceCard("عبدالعزيز غازي القحطاني"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// --- ويدجت بطاقة الطالب (التصميم العلوي) ---
  Widget _buildStudentCard(String name, String grade, String school) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF91A3AD), // نفس لون الصورة
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF192252),
                ),
              ),
              Text(
                'الصف: $grade',
                style: const TextStyle(fontSize: 13, color: Color(0xFF192252)),
              ),
              Text(
                'المدرسة: $school',
                style: const TextStyle(fontSize: 13, color: Color(0xFF192252)),
              ),
            ],
          ),
          const SizedBox(width: 15),
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// --- ويدجت بطاقة الحضور (التصميم السفلي) ---
  Widget _buildAttendanceCard(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE1E4D1), // اللون الأخضر الباهت في الصورة
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('غائب', style: TextStyle(color: Colors.white)),
          ),
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF192252),
                ),
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 20, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Slightly darker white
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        elevation: 0, // Elevation handled by container border
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,

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
