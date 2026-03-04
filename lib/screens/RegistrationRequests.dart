// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationRequests extends StatefulWidget {
  const RegistrationRequests({super.key});

  @override
  State<RegistrationRequests> createState() => _RegistrationRequestsState();
}

class _RegistrationRequestsState extends State<RegistrationRequests> {
  // --- Styling Constants ---
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(phone).get();
      if (mounted) {
        setState(() {
          currentSchoolId = doc.get('schoolId').toString();
          isLoading = false;
        });
      }
    } catch (e) {
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
                title: "طلبات التسجيل",
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: _kHeaderBlue))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _MainCardContainer(
                              children: [
                                _buildRequestList(),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestList() {
    if (currentSchoolId == null) return const Center(child: Text("خطأ في تحميل بيانات المدرسة"));

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
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text("لا توجد طلبات معلقة حالياً", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return Column(
          children: requests.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _RequestCard(
              requestId: doc.id,
              data: data,
              onAccept: () => _handleAccept(doc.id, data),
              onReject: () => _handleRefuse(doc.id),
            );
          }).toList(),
        );
      },
    );
  }

  // --- Logic Handlers ---

  Future<void> _handleAccept(String requestId, Map<String, dynamic> data) async {
    try {
      String newStudentId = "STU${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

      await FirebaseFirestore.instance.collection('Students').doc(newStudentId).set({
        'BusID': "101", 
        'Latitude': 21.664476, 
        'Longitude': 39.128645, 
        'SchoolID': data['schoolId'], 
        'StudentID': newStudentId,
        'StudentName': data['name_en'],
        'StudentName_ar': data['name_ar'],
        'parentPhone': data['parentPhone'],
        'Grade': data['Grade'],
      });

      await FirebaseFirestore.instance.collection('StudentRequests').doc(requestId).update({
        'status': 'approved',
      }); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم قبول الطالب وإضافته للنظام")));
    } catch (e) {
      debugPrint("Accept Error: $e");
    }
  }

  Future<void> _handleRefuse(String requestId) async {
    await FirebaseFirestore.instance.collection('StudentRequests').doc(requestId).update({
      'status': 'refused',
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم رفض الطلب")));
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
          if (index == 0) Navigator.pushReplacementNamed(context, '/AdminHome');
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

/* -------------------- Custom UI Components -------------------- */

class _RequestCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;
  final VoidCallback onAccept, onReject;

  const _RequestCard({
    required this.requestId,
    required this.data,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F3F5)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFFFD166),
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['name_ar'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0D1B36)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF2F3F5)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(label: "رقم الجوال", value: data['parentPhone'] ?? ''),
                const Divider(height: 20, color: Color(0xFFF9FAFB)),
                _DetailRow(label: "الصف", value: data['Grade'] ?? ''),
                const Divider(height: 20, color: Color(0xFFF9FAFB)),
                _DetailRow(label: "رقم الهوية", value: data['IDNumber'] ?? ''),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(label: "قبول", color: const Color(0xFF6A994E), onTap: onAccept),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionBtn(label: "رفض", color: const Color(0xFFD64545), onTap: onReject),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF98AF8D), fontSize: 13, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0D1B36))),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
      ),
    );
  }
}

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

class _MainCardContainer extends StatelessWidget {
  final List<Widget> children;
  const _MainCardContainer({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.75),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}