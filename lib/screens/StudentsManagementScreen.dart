import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Using a StreamBuilder to get real-time data from Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('حدث خطأ ما'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data?.docs ?? [];

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: students.length,
          itemBuilder: (context, index) {
            var data = students[index].data() as Map<String, dynamic>;
            return _buildStudentCard(
              data['name'] ?? 'اسم الطالب',
              students[index].id,
            );
          },
        );
      },
    );
  }

  // 3. Individual Student Card Item
  Widget _buildStudentCard(String name, String id) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.arrow_back_ios, size: 18, color: Colors.grey),
          Expanded(
            child: Text(
              name,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const SizedBox(width: 15),
          const CircleAvatar(
            backgroundColor: Color(0xFFFFD166), // Yellow circle from your UI
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 4. Bottom Navigation Bar
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _kDarkBlue,
      unselectedItemColor: Colors.grey,
      currentIndex: 1,
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
