// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FleetManagementScreen.dart'; 

class BusManagementScreen extends StatefulWidget {
  const BusManagementScreen({super.key});

  @override
  State<BusManagementScreen> createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen> {
  // --- Styling Constants ---
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kBusGreen = Color(0xFFC8D8A4); // ✅ Your original olive green
  static const Color _kAccentGreen = Color(0xFF6A994E);

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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              _TopHeader(
                title: "إدارة الحافلات",
                onBack: () => Navigator.pushReplacementNamed(context, '/AdminHome'),
              ),
              Expanded(
                child: isLoading 
                    ? const Center(child: CircularProgressIndicator(color: _kHeaderBlue))
                    : _buildBusList(), // ✅ List directly here to keep individual cards
              ),
              _buildBottomNav(context), // ✅ Standardized Labeled Toolbar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusList() {
    if (currentSchoolId == null) return const Center(child: Text("خطأ في تحميل البيانات"));
    
    int schoolIdInt = int.parse(currentSchoolId!);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Buses')
          .where('SchoolID', isEqualTo: schoolIdInt)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('حدث خطأ في جلب البيانات'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final buses = snapshot.data?.docs ?? [];
        if (buses.isEmpty) {
          return const Center(child: Text('لا توجد حافلات حالياً', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: buses.length,
          itemBuilder: (context, index) {
            final data = buses[index].data() as Map<String, dynamic>;
            final int busNumber = data['BusNumber'] ?? 0;
            final int totalStudents = data['TotalStudents'] ?? 0;
            const int capacity = 50;
            final bool isFull = totalStudents >= capacity;

            return _BusCardItem(
              busNumber: busNumber,
              totalStudents: totalStudents,
              capacity: capacity,
              isFull: isFull,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FleetManagementScreen()),
                );
              },
            );
          },
        );
      },
    );
  }

  // ✅ Standardized Bottom Navigation with Labels
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _kHeaderBlue,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/role_home');
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

/* -------------------- Custom UI Components -------------------- */

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)),
      child: Row(
        children: [
          const SizedBox(width: 48), 
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const Spacer(),
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _BusCardItem extends StatelessWidget {
  final int busNumber;
  final int totalStudents;
  final int capacity;
  final bool isFull;
  final VoidCallback onTap;

  const _BusCardItem({
    required this.busNumber,
    required this.totalStudents,
    required this.capacity,
    required this.isFull,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFC8D8A4), // ✅ Restored original olive green
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.yellow.shade600,
          child: const Icon(Icons.directions_bus, size: 32, color: Color(0xFF0D1B36)),
        ),
        title: Text(
          "حافلة $busNumber",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0D1B36),
            fontSize: 20,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isFull ? const Color(0xFFD64545) : const Color(0xFF6A994E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isFull ? "ممتلئة" : "نشطة",
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.groups, size: 18, color: Color(0xFF0D1B36)),
                const SizedBox(width: 6),
                Text(
                  "عدد الطلاب $totalStudents / $capacity",
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B36), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF0D1B36), size: 30),
      ),
    );
  }
}