import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Color Constants ---
const Color _kDarkBlue = Color(0xFF0D1B36);
const Color _kLightGrey = Color(0xFFF5F5F5);

class RegistrationRequests extends StatefulWidget {
  const RegistrationRequests({super.key});

  @override
  State<RegistrationRequests> createState() => _RegistrationRequestsState();
}

class _RegistrationRequestsState extends State<RegistrationRequests> {
  String? currentSchoolId;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.email?.split('@')[0];
    final doc = await FirebaseFirestore.instance.collection('users').doc(phone).get();
    if (mounted) {
      setState(() {
        currentSchoolId = doc.get('schoolId').toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildRequestList()),
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
          const Text('طلبات التسجيل',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList() {
    if (currentSchoolId == null) return const Center(child: CircularProgressIndicator());

    // Filter by the integer SchoolID field
    int schoolIdInt = int.parse(currentSchoolId!);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('StudentRequests')
          .where('schoolId', isEqualTo: schoolIdInt)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return const Center(child: Text("لا توجد طلبات معلقة حالياً"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final doc = requests[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildRequestCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(String requestId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Header with Name and Actions
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFD166),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(data['name_ar'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                _actionButton("قبول", const Color(0xFFE8F5E9), Colors.green, () => _handleAccept(requestId, data)),
                const SizedBox(width: 8),
                _actionButton("رفض", const Color(0xFFFFEBEE), Colors.red, () => _handleRefuse(requestId)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Details Body
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                _detailRow("اسم ولي الأمر", data['name_en'] ?? ''), // Or separate parentName field
                _detailRow("رقم الجوال", data['parentPhone'] ?? ''),
                _detailRow("الصف", data['Grade'] ?? ''),
                _detailRow("رقم الهوية", data['IDNumber'] ?? ''),
                _detailRow("العنوان الوطني", data['NationalAddress'] ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label:", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _kDarkBlue)),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color bg, Color text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  // --- Logic Handlers ---

  Future<void> _handleAccept(String requestId, Map<String, dynamic> data) async {
    try {
      // 1. Generate a Student ID (e.g., STU + timestamp suffix)
      String newStudentId = "STU${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

      // 2. Add to Students Collection
      await FirebaseFirestore.instance.collection('Students').doc(newStudentId).set({
        'BusID': "101", // Default/Fake as requested for now
        'Latitude': 21.664476, // Default/Fake until Geocoding integrated
        'Longitude': 39.128645, 
        'SchoolID': data['schoolId'], 
        'StudentID': newStudentId,
        'StudentName': data['name_en'],
        'StudentName_ar': data['name_ar'],
        'parentPhone': data['parentPhone'],
        'Grade': data['Grade'],
      });
      // 3. Update Request Status
      await FirebaseFirestore.instance.collection('StudentRequests').doc(requestId).update({
        'status': 'approved',
      }); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم قبول الطالب وإضافته للنظام")));
    } catch (e) {
      debugPrint("Accept Error: $e");
    }
  }

  Future<void> _handleRefuse(String requestId) async {
    // Simply update status so parent can see it was refused
    await FirebaseFirestore.instance.collection('StudentRequests').doc(requestId).update({
      'status': 'refused',
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم رفض الطلب")));
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(color: _kLightGrey, border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5))),
      child: BottomNavigationBar(
        elevation: 0, backgroundColor: Colors.transparent, type: BottomNavigationBarType.fixed,
        showSelectedLabels: false, showUnselectedLabels: false,
        selectedItemColor: _kDarkBlue, unselectedItemColor: Colors.grey.shade400,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/AdminHome');
          if (index == 1) Navigator.pushReplacementNamed(context, '/role_home');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 28), label: 'Profile'),
        ],
      ),
    );
  }
}