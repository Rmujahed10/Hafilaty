import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_info_screen.dart';

// --- Color Constants ---
const Color _kDarkBlue = Color(0xFF0D1B36);
const Color _kLightGrey = Color(0xFFF5F5F5);

class StudentsManagementScreen extends StatefulWidget {
  const StudentsManagementScreen({super.key});

  @override
  State<StudentsManagementScreen> createState() =>
      _StudentsManagementScreenState();
}

class _StudentsManagementScreenState extends State<StudentsManagementScreen> {
  String? currentSchoolId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final phone = user?.email?.split('@')[0];
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(phone).get();
      
      if (mounted) {
        setState(() {
          // Fields: schoolId is stored as String in users collection
          currentSchoolId = userDoc.get('schoolId').toString();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading school ID: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Correct RTL orientation
      child: Scaffold(
        backgroundColor: Colors.white,
        body: isLoading 
            ? const Center(child: CircularProgressIndicator(color: _kDarkBlue))
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildStudentList()),
                ],
              ),
        bottomNavigationBar: _buildBottomNav(),
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
            'إدارة الطلاب',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Back button pointing to AdminHome
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 22),
            onPressed: () => Navigator.pushReplacementNamed(context, '/AdminHome'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (currentSchoolId == null) return const Center(child: Text("خطأ في تحميل البيانات"));
    
    // Convert to int for 'Students' collection query
    int schoolIdInt = int.parse(currentSchoolId!);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Students')
          .where('SchoolID', isEqualTo: schoolIdInt)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('حدث خطأ'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data?.docs ?? [];
        if (students.isEmpty) {
          return const Center(child: Text('لا يوجد طلاب حالياً', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final data = students[index].data() as Map<String, dynamic>;
            return _buildStudentCard(
              (data['StudentName_ar'] ?? data['StudentName'] ?? 'اسم غير متوفر').toString(),
              students[index].id,
            );
          },
        );
      },
    );
  }

  Widget _buildStudentCard(String name, String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentInfoScreen(studentDocId: docId),
            ),
          );
        },
        // Avatar on the Right side
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFFFD166),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 22),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _kDarkBlue,
          ),
        ),
        // Arrow pointing LEFT on the Left side
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 28),
      ),
    );
  }

  Widget _buildBottomNav() {
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