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
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);

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

  // ✅ INCREMENT triggers your AI clustering
  Future<void> _updateBusCount(int change) async {
    if (currentSchoolId == null) return;

    try {
      final schoolRef = FirebaseFirestore.instance.collection('Schools').doc(currentSchoolId!);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(schoolRef);
        if (!snapshot.exists) return;

        int currentBusCount = snapshot.get('BusCount') ?? 1;
        int newCount = currentBusCount + change;

        if (newCount < 1) return; // Prevent 0 buses

        transaction.update(schoolRef, {
          'BusCount': newCount,
          'LastUpdateAction': change > 0 ? "ADD" : "DELETE",
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(change > 0 
              ? "جاري إضافة حافلة وإعادة توزيع الطلاب..." 
              : "جاري حذف حافلة وإعادة توزيع الطلاب..."),
            backgroundColor: _kHeaderBlue,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating fleet: $e");
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
                    : _buildBusList(),
              ),
              _buildActionButtons(), // ✅ Buttons added above the toolbar
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ New widget for Add/Delete buttons
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateBusCount(1),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("إضافة حافلة", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A994E),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateBusCount(-1),
              icon: const Icon(Icons.remove, color: Colors.white),
              label: const Text("حذف حافلة", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD64545),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
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
            return _BusCardItem(
              busNumber: data['BusNumber'] ?? 0,
              totalStudents: data['TotalStudents'] ?? 0,
              capacity: 50,
              isFull: (data['TotalStudents'] ?? 0) >= 50,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetManagementScreen())),
            );
          },
        );
      },
    );
  }

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
          if (index == 1) Navigator.pushReplacementNamed(context, '/role_home');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 28), label: 'الملف الشخصي'),
        ],
      ),
    );
  }
}

/* --- Components _TopHeader and _BusCardItem remain the same as previous response --- */

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
        color: const Color(0xFFC8D8A4), 
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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