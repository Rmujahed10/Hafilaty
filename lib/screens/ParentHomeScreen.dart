// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Stream<DocumentSnapshot> _getUserStream() {
    String phoneDocId = user?.email?.split('@')[0] ?? "";
    return FirebaseFirestore.instance
        .collection('users')
        .doc(phoneDocId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    String phoneDocId = user?.email?.split('@')[0] ?? "";

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
                          // --- Dynamic Welcome ---
                          Align(
                            alignment: Alignment.centerRight,
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: _getUserStream(),
                              builder: (context, snapshot) {
                                String name = "...";
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  name =
                                      snapshot.data!.get('firstName') ??
                                      "مستخدم";
                                }
                                return Text(
                                  'صباح الخير، $name',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: _kTextMain,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 25),

                          // --- Management Section Header ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionHeader(title: 'إدارة الأبناء'),
                              const Icon(
                                Icons.add_circle,
                                color: Color(0xFF6A994E),
                                size: 30,
                              ),
                            ],
                          ),

                          // --- Student Requests List ---
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('StudentRequests')
                                .where('parentPhone', isEqualTo: phoneDocId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              var students = snapshot.data?.docs ?? [];
                              if (students.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    "لا يوجد أبناء مسجلين حالياً",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: students.map((doc) {
                                  var data = doc.data() as Map<String, dynamic>;
                                  return _buildInteractiveStudentCard(
                                    context,
                                    doc.id,
                                    data['name_ar'] ?? '',
                                    data['Grade'] ?? '',
                                    data['SchoolName'] ?? '',
                                    data['status'] ?? 'pending',
                                  );
                                }).toList(),
                              );
                            },
                          ),

                          const SizedBox(height: 30),

                          // --- Attendance Section ---
                          const _SectionHeader(title: 'حالة تأكيد الحضور'),
                          const Padding(
                            padding: EdgeInsets.only(top: 5, bottom: 15),
                            child: Text(
                              'يرجى تأكيد حضور الطالب للباص ليوم الغد قبل الساعة ٥:٠٠ صباحاً لضمان وصول الباص في الموعد الملتزم به',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.redAccent,
                                height: 1.4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // --- Approved Students Attendance List ---
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('Students')
                                .where('parentPhone', isEqualTo: phoneDocId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return const Text(
                                  "لا يوجد أبناء لعرض الحضور",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                );
                              }
                              return Column(
                                children: docs.map((doc) {
                                  final data = doc.data();
                                  final name =
                                      (data['StudentName_ar'] ??
                                              data['StudentName'] ??
                                              '')
                                          .toString();
                                  return _buildAttendanceCard(
                                    context,
                                    doc.id,
                                    name,
                                  );
                                }).toList(),
                              );
                            },
                          ),
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

  // --- Specialized Interactive Card ---
  Widget _buildInteractiveStudentCard(
    BuildContext context,
    String requestId,
    String name,
    String grade,
    String school,
    String status,
  ) {
    bool isApproved = status == 'approved';
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F3F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        // تم حذف onTap تماماً لتعطيل الانتقال أو أي تفاعل
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: isApproved
              ? const Color(0xFFFFD166)
              : Colors.grey.shade300,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: _kHeaderBlue,
          ),
        ),
        subtitle: Text(
          'المدرسة: $school\nالصف: $grade',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: _buildStatusBadge(
          status,
        ), // تم حذف أيقونة السهم الرمادي من هنا
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'approved'
        ? Colors.green
        : (status == 'rejected' ? Colors.red : Colors.orange);
    String text = status == 'approved'
        ? "مسجل"
        : (status == 'rejected' ? "مرفوض" : "قيد المعالجة");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(
    BuildContext context,
    String requestId,
    String name,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E09B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        // جعل المستطيل كاملاً قابلاً للضغط
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/manage_child',
            arguments: {'StudentID': requestId},
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 18, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _kHeaderBlue,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                // إضافة السهم بجانب زر غائب
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // يمكنك وضع منطق الغياب هنا أو تركه فارغاً إذا كنت تريد الضغط للبطاقة ككل
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'غائب',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                    size: 20,
                  ), // السهم الرمادي
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ New Standardized Bottom Navigation with Titles
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _kHeaderBlue,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushReplacementNamed(context, '/role_home');
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

/* -------------------- Generic Project UI Components -------------------- */

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onLang;
  const _TopHeader({required this.title, required this.onLang});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)),
      child: Row(
        children: [
          IconButton(
            onPressed: onLang,
            icon: const Icon(Icons.language, color: Colors.white),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
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
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Color(0xFF98AF8D),
        ),
      ),
    );
  }
}
