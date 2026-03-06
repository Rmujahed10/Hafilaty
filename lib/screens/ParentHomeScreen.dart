// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hijri/hijri_calendar.dart'; // Import the Hijri package
import 'RegisterStudentScreen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  // --- Styling Constants ---
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kTextMain = Color(0xFF101828);

  final user = FirebaseAuth.instance.currentUser;

  String get _phoneDocId => user?.email?.split('@')[0] ?? "";

  Stream<DocumentSnapshot> _getUserStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_phoneDocId)
        .snapshots();
  }

  // --- Logic: Atomic Update with Hijri Context ---
  Future<void> _handleAttendanceUpdate({
    required String studentId,
    required String newStatus,
    required Map<String, dynamic> studentData,
  }) async {
    final now = DateTime.now();
    final currentHour = now.hour;

    // Determine Target Date (7 PM or later marks for tomorrow)
    DateTime targetDate = (currentHour >= 19) ? now.add(const Duration(days: 1)) : now;
    String formattedDate = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

    WriteBatch batch = FirebaseFirestore.instance.batch();

    DocumentReference studentRef = FirebaseFirestore.instance.collection('Students').doc(studentId);
    DocumentReference attendanceRef = FirebaseFirestore.instance
        .collection('Attendance')
        .doc(formattedDate)
        .collection('PresentStudents')
        .doc(studentId);

    batch.update(studentRef, {'attendanceStatus': newStatus});

    if (newStatus == 'حاضر') {
      batch.set(attendanceRef, {
        ...studentData,
        'attendanceStatus': 'حاضر',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      batch.delete(attendanceRef);
    }

    try {
      await batch.commit();
      if (mounted) {
        // Show Hijri date in success message too
        var hDate = HijriCalendar.fromDate(targetDate);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم التحديث ليوم ${hDate.hDay} ${hDate.longMonthName}'),
            backgroundColor: newStatus == 'حاضر' ? Colors.green : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Batch Error: $e");
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
              _TopHeader(title: "لوحة التحكم", onLang: () {}),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _MainCardContainer(
                        children: [
                          _buildWelcomeHeader(),
                          const SizedBox(height: 25),
                          _buildManagementHeader(context),
                          _buildStudentRequestsList(),
                          const SizedBox(height: 30),
                          const _SectionHeader(title: 'حالة تأكيد الحضور'),
                          _buildAttendanceWarning(),
                          _buildApprovedStudentsList(),
                        ],
                      ),
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

  // --- UI Components ---

  Widget _buildWelcomeHeader() {
    return Align(
      alignment: Alignment.centerRight,
      child: StreamBuilder<DocumentSnapshot>(
        stream: _getUserStream(),
        builder: (context, snapshot) {
          String name = (snapshot.hasData && snapshot.data!.exists)
              ? snapshot.data!.get('firstName') ?? "مستخدم"
              : "...";
          return Text('صباح الخير، $name',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _kTextMain));
        },
      ),
    );
  }

  Widget _buildManagementHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _SectionHeader(title: 'الأبناء'),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Color(0xFF6A994E), size: 30),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterStudentScreen())),
        ),
      ],
    );
  }

  Widget _buildStudentRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('StudentRequests')
          .where('parentPhone', isEqualTo: _phoneDocId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var students = snapshot.data?.docs ?? [];
        if (students.isEmpty) return _buildEmptyState("لا يوجد طلبات تسجيل حالياً");
        
        return Column(
          children: students.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return _buildInteractiveStudentCard(context, doc.id, data['name_ar'] ?? '', data['Grade'] ?? '', data['SchoolName'] ?? '', data['status'] ?? 'pending');
          }).toList(),
        );
      },
    );
  }

  Widget _buildAttendanceWarning() {
    return const Padding(
      padding: EdgeInsets.only(top: 5, bottom: 15),
      child: Text(
        'يرجى تأكيد حضور الطالب للباص ليوم الغد قبل الساعة ٥:٠٠ صباحاً لضمان وصول الباص في الموعد الملتزم به',
        style: TextStyle(fontSize: 11, color: Colors.redAccent, height: 1.4, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildApprovedStudentsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Students')
          .where('parentPhone', isEqualTo: _phoneDocId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState("لا يوجد أبناء مسجلين لعرض الحضور");
        return Column(
          children: docs.map((doc) => _buildAttendanceCard(context, doc.id, doc.data())).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13)),
    );
  }

  Widget _buildInteractiveStudentCard(BuildContext context, String id, String name, String grade, String school, String status) {
    bool isApproved = status == 'approved';
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: isApproved ? const Color(0xFFFFD166) : Colors.grey.shade300,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _kHeaderBlue)),
        subtitle: Text('المدرسة: $school\nالصف: $grade', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        trailing: _buildStatusBadge(status),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'approved' ? Colors.green : (status == 'refused' ? Colors.red : Colors.orange);
    String text = status == 'approved' ? "مسجل" : (status == 'refused' ? "مرفوض" : "قيد المعالجة");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: color, width: 0.5)
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, String studentId, Map<String, dynamic> data) {
    String currentStatus = data['attendanceStatus'] ?? 'غائب';
    String name = (data['StudentName_ar'] ?? data['StudentName'] ?? '').toString();
    
    // Time & Date Logic
    final now = DateTime.now();
    int hour = now.hour;
    bool isTimeExpired = !(hour >= 19 || hour < 5);

    // Get Target Hijri Date
    DateTime targetDate = (hour >= 19) ? now.add(const Duration(days: 1)) : now;
    HijriCalendar.setLocal('ar'); // Set calendar to Arabic
    var hDate = HijriCalendar.fromDate(targetDate);
    String hijriLabel = "${hDate.hDay} ${hDate.longMonthName}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E09B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/manage_child', arguments: {'StudentID': studentId}),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              const CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Icon(Icons.person, size: 18, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w900, color: _kHeaderBlue, fontSize: 14)),
                    const Text("اضغط لعرض الملف الشخصي", style: TextStyle(fontSize: 10, color: Colors.black45)),
                  ],
                ),
              ),
              // Date Label + Centered Toggle
              Column(
                children: [
                  Text(
                    "ليوم: $hijriLabel",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isTimeExpired ? Colors.grey : _kHeaderBlue),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 35,
                    width: 95,
                    decoration: BoxDecoration(
                      color: isTimeExpired ? Colors.grey.shade400 : (currentStatus == 'غائب' ? Colors.redAccent : Colors.green),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentStatus,
                        dropdownColor: Colors.white,
                        alignment: Alignment.center,
                        isExpanded: true,
                        icon: const SizedBox.shrink(),
                        onChanged: isTimeExpired ? (val) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('التعديل متاح من 7:00 م حتى 5:00 ص')));
                        } : (String? newValue) {
                          if (newValue != null) {
                            _handleAttendanceUpdate(studentId: studentId, newStatus: newValue, studentData: data);
                          }
                        },
                        items: ['حاضر', 'غائب'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            alignment: Alignment.center,
                            child: Text(value, style: TextStyle(color: isTimeExpired ? Colors.grey : (value == 'غائب' ? Colors.redAccent : Colors.green), fontWeight: FontWeight.bold, fontSize: 13)),
                          );
                        }).toList(),
                        selectedItemBuilder: (context) => ['حاضر', 'غائب'].map((v) => Center(child: Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(color: const Color(0xFFE6E6E6), border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5))),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _kHeaderBlue,
        currentIndex: 0,
        onTap: (index) { if (index == 1) Navigator.pushReplacementNamed(context, '/role_home'); },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 28), label: 'الملف الشخصي'),
        ],
      ),
    );
  }
}

/* --- Reusable Components --- */

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onLang;
  const _TopHeader({required this.title, required this.onLang});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)),
      child: Row(children: [
        IconButton(onPressed: onLang, icon: const Icon(Icons.language, color: Colors.white)),
        const Spacer(),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const Spacer(),
        const SizedBox(width: 48),
      ]),
    );
  }
}

class _MainCardContainer extends StatelessWidget {
  final List<Widget> children;
  const _MainCardContainer({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14), width: double.infinity,
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.75),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment.centerRight, child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF98AF8D))));
  }
}