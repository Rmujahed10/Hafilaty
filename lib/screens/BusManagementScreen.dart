import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FleetManagementScreen.dart'; 

const Color kDarkBlue = Color(0xFF0D1B36);
const Color kAccent = Color(0xFF6A994E);

class BusManagementScreen extends StatefulWidget {
  const BusManagementScreen({super.key});

  @override
  State<BusManagementScreen> createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen> {
  String? currentSchoolId;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.email?.split('@')[0];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(phone)
        .get();

    setState(() {
      currentSchoolId = userDoc.get('schoolId');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentSchoolId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: kDarkBlue,
        title: const Text("إدارة الحافلات"),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Buses')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا توجد حافلات لهذه المدرسة"));
          }

          final buses = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];

              final int busNumber = bus['BusNumber'] ?? 0;
              final int totalStudents = bus['TotalStudents'] ?? 0;
              const int capacity = 50;

              final bool isFull = totalStudents >= capacity;

              return _buildBusCard(
                busNumber,
                totalStudents,
                capacity,
                isFull,
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: kDarkBlue,
        onPressed: () {
          // later: add new bus
        },
        child: const Icon(Icons.add),
      ),
    );
  }
Widget _buildBusCard(
  int busNumber,
  int totalStudents,
  int capacity,
  bool isFull,
) {
  return InkWell(
    borderRadius: BorderRadius.circular(22),
    onTap: () {
  if (busNumber == 101) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FleetManagementScreen(),
      ),
    );
  }
},
    child: Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFC8D8A4),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.yellow.shade600,
            child: const Icon(
              Icons.directions_bus,
              size: 32,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "حافلة $busNumber",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isFull ? Colors.red : kAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFull ? "ممتلئة" : "نشطة",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.groups, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "عدد الطلاب $totalStudents / $capacity",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}}