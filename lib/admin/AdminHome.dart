// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'PendingRequestsScreen.dart';

class AdminHome extends StatefulWidget {
  final Map<String, dynamic>? schoolData;
  const AdminHome({super.key, this.schoolData});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);

  String schoolNameAr = "جاري التحميل...";
  int studentCount = 0;
  int busCount = 0;
  bool isLoading = true;
  String? currentSchoolId;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final phone = user?.email?.split('@')[0];
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phone)
          .get();

      if (!userDoc.exists) return;

      currentSchoolId = userDoc.get('schoolId').toString();
      int schoolIdInt = int.parse(currentSchoolId!);

      final schoolDoc = await FirebaseFirestore.instance
          .collection('Schools')
          .doc(currentSchoolId)
          .get();
      final studentsQuery = await FirebaseFirestore.instance
          .collection('Students')
          .where('SchoolID', isEqualTo: schoolIdInt)
          .count()
          .get();
      final busesQuery = await FirebaseFirestore.instance
          .collection('Buses')
          .where('SchoolID', isEqualTo: schoolIdInt)
          .count()
          .get();

      if (mounted) {
        setState(() {
          schoolNameAr = schoolDoc.exists
              ? schoolDoc.get('School Name_ar')
              : "مدرسة غير معروفة";
          studentCount = studentsQuery.count ?? 0;
          busCount = busesQuery.count ?? 0;
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
              _TopHeader(title: "لوحة التحكم", onLang: () {}),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _kHeaderBlue),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _MainCardContainer(
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    schoolNameAr,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF101828),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatBox(
                                        title: "عدد الحافلات",
                                        value: "$busCount",
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StatBox(
                                        title: "عدد الطلاب",
                                        value: "$studentCount",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _SectionHeader(title: "حالة الحافلات المباشرة"),
                                _buildBusStatusRow(),
                                const SizedBox(height: 24),
                                _SectionHeader(title: "إدارة النظام"),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.8,
                                  children: [
                                    _ActionTile(
                                      title: "إدارة الحافلات",
                                      icon: Icons.directions_bus,
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/bus_management',
                                      ),
                                    ),
                                    _ActionTile(
                                      title: "إدارة الطلاب",
                                      icon: Icons.people,
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/students_management',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _SectionHeader(title: "طلبات التسجيل الجديدة"),
                                _buildRegistrationRequests(),
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

  Widget _buildBusStatusRow() {
    if (currentSchoolId == null) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Buses')
          .where('SchoolID', isEqualTo: int.parse(currentSchoolId!))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final busDocs = snapshot.data!.docs;
        if (busDocs.isEmpty) {
          return const Center(
            child: Text(
              "لا توجد حافلات",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: busDocs.length,
          itemBuilder: (context, index) {
            final data = busDocs[index].data() as Map<String, dynamic>;
            final status = data['tripStatus'] ?? "لم تبدأ";
            final bool isActive = status == "جارية الآن";

            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFD4E09B)
                    : const Color(0xFFE6E6E6),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF98AF8D)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "حافلة ${data['BusNumber'] ?? '?'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _kHeaderBlue,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.green.shade900
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRegistrationRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('StudentRequests')
          .where('schoolId', isEqualTo: int.parse(currentSchoolId ?? "0"))
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Align(
            alignment: Alignment.centerRight,
            child: Text(
              "لا توجد طلبات معلقة",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          );
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PendingRequestsScreen()),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withAlpha(20)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1,
                      color: _kHeaderBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      data['name_ar'] ?? "طالب جديد",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/* --- Reusable UI --- */
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

          IconButton(
            onPressed: onLang,
            icon: const Icon(Icons.language, color: Colors.white),
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
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
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

class _StatBox extends StatelessWidget {
  final String title, value;
  const _StatBox({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F3F5)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF101828),
            ),
          ),
        ],
      ),
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF98AF8D),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF2F3F5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF0D1B36), size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
