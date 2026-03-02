import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FleetManagementScreen.dart'; 

// --- Color Constants ---
const Color _kDarkBlue = Color(0xFF0D1B36);
const Color _kLightGrey = Color(0xFFF5F5F5);
const Color _kBusGreen = Color(0xFFC8D8A4); // Original Olive Green from your snippet
const Color _kAccent = Color(0xFF6A994E);

class BusManagementScreen extends StatefulWidget {
  const BusManagementScreen({super.key});

  @override
  State<BusManagementScreen> createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen> {
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
        backgroundColor: Colors.white,
        body: isLoading 
            ? const Center(child: CircularProgressIndicator(color: _kDarkBlue))
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildBusList()),
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
            'إدارة الحافلات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 22),
            onPressed: () => Navigator.pushReplacementNamed(context, '/AdminHome'),
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
        if (snapshot.hasError) return const Center(child: Text('حدث خطأ'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final buses = snapshot.data?.docs ?? [];
        if (buses.isEmpty) {
          return const Center(child: Text('لا توجد حافلات حالياً', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          itemCount: buses.length,
          itemBuilder: (context, index) {
            final bus = buses[index];
            final int busNumber = bus['BusNumber'] ?? 0;
            final int totalStudents = bus['TotalStudents'] ?? 0;
            const int capacity = 50;
            final bool isFull = totalStudents >= capacity;

            return _buildBusCard(busNumber, totalStudents, capacity, isFull);
          },
        );
      },
    );
  }

  Widget _buildBusCard(int busNumber, int totalStudents, int capacity, bool isFull) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: _kBusGreen, // RESTORED: Original light green color
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        onTap: () {
          if (busNumber == 101) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FleetManagementScreen()),
            );
          }
        },
        // Leading: Yellow bus avatar on the right
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.yellow.shade600,
          child: const Icon(Icons.directions_bus, size: 32, color: Colors.blue),
        ),
        // Title: Bus number
        title: Text(
          "حافلة $busNumber",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _kDarkBlue,
          ),
        ),
        // Subtitle: Status badge and student count
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isFull ? Colors.red : _kAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isFull ? "ممتلئة" : "نشطة",
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.groups, size: 18, color: _kDarkBlue),
                const SizedBox(width: 6),
                Text(
                  "عدد الطلاب $totalStudents / $capacity",
                  style: const TextStyle(fontSize: 14, color: _kDarkBlue),
                ),
              ],
            ),
          ],
        ),
        // Trailing: Left chevron
        trailing: const Icon(Icons.chevron_right, color: _kDarkBlue, size: 28),
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