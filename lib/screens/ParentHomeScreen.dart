import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'RegisterStudentScreen.dart';

// --- Color Constants ---
const Color _kDarkBlue = Color(0xFF0D1B36);
const Color _kLightGrey = Color(0xFFF5F5F5);
const Color _kAccent = Color(0xFF6A994E);

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
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
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- الترحيب الديناميكي ---
                      StreamBuilder<DocumentSnapshot>(
                        stream: _getUserStream(),
                        builder: (context, snapshot) {
                          String name = "...";
                          if (snapshot.hasData && snapshot.data!.exists) {
                            name = snapshot.data!.get('firstName') ?? "مستخدم";
                          }
                          return Text(
                            'صباح الخير، $name',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _kDarkBlue,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 25),

                      // --- قسم إدارة الأبناء ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'إدارة الأبناء',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF98AF8D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: _kAccent,
                              size: 28,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RegisterStudentScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // --- عرض بطاقات الطلاب (الطلبات) ---
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection(
                              'StudentRequests',
                            ) // نغير المجموعة هنا لنراقب الطلبات
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
                            return const Center(
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

                      // --- حالة تأكيد الحضور (للمقبولين فقط) ---
                      const Text(
                        'حالة تأكيد الحضور',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF98AF8D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 5, bottom: 15),
                        child: Text(
                          'يرجى تأكيد حضور الطالب للباص ليوم الغد قبل الساعة ٥:٠٠ صباحاً لضمان وصول الباص في الموعد الملتزم به',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                            height: 1.4,
                          ),
                        ),
                      ),

                      // هنا يمكنك مستقبلاً فلترة الطلاب المقبولين فقط لعرض تأكيد حضورهم
                      _buildAttendanceCard("علي غازي القحطاني"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  // ويدجت البطاقة التفاعلية التي طلبتها
  Widget _buildInteractiveStudentCard(
    BuildContext context,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
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
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _kDarkBlue,
          ),
        ),
        subtitle: Text(
          'المدرسة: $school\nالصف: $grade',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusBadge(status),
            if (isApproved)
              const Icon(Icons.chevron_left, color: Colors.grey, size: 20),
          ],
        ),
        onTap: isApproved
            ? () {
                // هنا تنقل الوالد للصفحة التالية عند الموافقة
                print("تم الانتقال لصفحة الطالب $name");
              }
            : () {
                // رسالة في حال لم يتم الموافقة بعد
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("الطلب لا يزال قيد المعالجة، يرجى الانتظار."),
                  ),
                );
              },
      ),
    );
  }

  // ملصق الحالة الملون
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'approved':
        color = Colors.green;
        text = "تمت الموافقة";
        break;
      case 'rejected':
        color = Colors.red;
        text = "تم الرفض";
        break;
      default:
        color = Colors.orange;
        text = "جاري المعالجة";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  // --- باقي الودجت السابقة ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.15,
      padding: const EdgeInsets.only(top: 40, right: 20, left: 10),
      color: _kDarkBlue,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'لوحة التحكم',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E09B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
      ),
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
                  fontWeight: FontWeight.bold,
                  color: _kDarkBlue,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'غائب',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: _kDarkBlue,
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      onTap: (index) {
        if (index == 1) Navigator.pushReplacementNamed(context, '/role_home');
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'الملف',
        ),
      ],
    );
  }
}
