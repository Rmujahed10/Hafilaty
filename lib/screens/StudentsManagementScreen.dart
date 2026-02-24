import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_info_screen.dart';

// --- Color Constants (Matching your Login Screen) ---
const Color _kDarkBlue = Color(0xFF0D1B36);
const Color _kGreenAccent = Color(0xFF6A994E);

class StudentsManagementScreen extends StatefulWidget {
  const StudentsManagementScreen({super.key});

  @override
  State<StudentsManagementScreen> createState() =>
      _StudentsManagementScreenState();
}

class _StudentsManagementScreenState extends State<StudentsManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Custom AppBar/Header to match the Figma design
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildStudentList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () {
          // Navigate to add student screen
          Navigator.pushNamed(context, '/register_student');
        },
        backgroundColor: _kDarkBlue,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // 1. The Blue Header with the Title
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      decoration: const BoxDecoration(
        color: _kDarkBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: const Center(
        child: Text(
          'إدارة الطلاب',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 2. The List of Student Cards
  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Students') // ← Capital S
          .where('SchoolID', isEqualTo: 32438) // ← نفس الاسم بالضبط
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data?.docs ?? [];

        if (students.isEmpty) {
          return const Center(child: Text('لا يوجد طلاب لهذه المدرسة'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final data = students[index].data() as Map<String, dynamic>;

            return _buildStudentCard(
              data['StudentName'] ?? 'اسم غير متوفر', // ← نفس الحقل
              students[index].id,
            );
          },
        );
      },
    );
  }

  // كارد وهمي (Rectangle) نفس شكل الفيجما
  Widget _placeholderStudentCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.chevron_left, size: 26, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFFFD166),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // 3. Individual Student Card Item
<<<<<<< HEAD
Widget _buildStudentCard(String name, String docId) {
  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentInfoScreen(studentDocId: docId),
        ),
      );
    },
    borderRadius: BorderRadius.circular(18),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
=======
  Widget _buildStudentCard(String name, String id) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white, // خليها أبيض صريح
        borderRadius: BorderRadius.circular(22), // أكثر استدارة
        border: Border.all(
          color: const Color(0xFFE5E5E5), // بوردر أوضح
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // ظل خفيف جداً
            blurRadius: 8,
>>>>>>> e64c90b02a9bb44dde216dcdc33fe03f342eaa57
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
<<<<<<< HEAD
          const Icon(Icons.chevron_left, size: 26, color: Colors.grey),
          const SizedBox(width: 12),
=======
          Icon(Icons.chevron_left, size: 26, color: Colors.grey.shade500),

          const SizedBox(width: 14),

>>>>>>> e64c90b02a9bb44dde216dcdc33fe03f342eaa57
          Expanded(
            child: Text(
              name,
              textAlign: TextAlign.right,
<<<<<<< HEAD
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(width: 14),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFFFD166),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    ),
  );
}
=======
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD166),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
>>>>>>> e64c90b02a9bb44dde216dcdc33fe03f342eaa57

  // 4. Bottom Navigation Bar
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _kDarkBlue,
      unselectedItemColor: Colors.grey,
      currentIndex: 1, // لأنك الآن في صفحة الطلاب
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;

          case 1:
            //طلاب
            break;

          case 2:
            Navigator.pushReplacementNamed(context, '/drivers_management');
            break;

          case 3:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Image.asset('assets/HomeIcon.png', width: 28, height: 28),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/StudentMangeIcon.png',
            width: 28,
            height: 28,
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/DriverMangeIcon.png',
            width: 28,
            height: 28,
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/ProfileIcon.png', width: 28, height: 28),
          label: '',
        ),
      ],
    );
  }
}
