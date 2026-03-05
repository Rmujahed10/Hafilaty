// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentInfoScreen extends StatefulWidget {
  final String studentDocId;
  const StudentInfoScreen({super.key, required this.studentDocId});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  // --- Styling Constants ---
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kDanger = Color(0xFFD64545);

  bool isArabic = true;

  DocumentReference get _ref => FirebaseFirestore.instance
      .collection('Students')
      .doc(widget.studentDocId);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: _ref.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: _kHeaderBlue),
                );
              }

              if (!snapshot.data!.exists) {
                return const Center(child: Text("تم حذف البيانات بنجاح"));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

              final nameAr =
                  (data['StudentName_ar'] ??
                          data['StudentNameAr'] ??
                          'اسم غير معروف')
                      .toString();
              final nameEn =
                  (data['StudentName'] ??
                          data['StudentNameEn'] ??
                          'Unknown Name')
                      .toString();
              final displayName = isArabic ? nameAr : nameEn;

              return Column(
                children: [
                  _TopHeader(
                    title: isArabic ? "بيانات الطالب" : "Student Details",
                    onBack: () => Navigator.pop(context),
                    onLang: () => setState(() => isArabic = !isArabic),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _MainCardContainer(
                            children: [
                              Directionality(
                                textDirection: isArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                child: Column(
                                  children: [
                                    _ProfileSection(name: displayName),
                                    const SizedBox(height: 24),

                                    _SectionLabel(
                                      label: isArabic
                                          ? "المعلومات العامة"
                                          : "General Info",
                                      isArabic: isArabic,
                                    ),
                                    _InfoGroupCard(
                                      children: [
                                        _InfoRow(
                                          label: isArabic
                                              ? "رقم الطالب"
                                              : "Student ID",
                                          value: data['StudentID'],
                                        ),
                                        const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Color(0xFFF2F3F5),
                                        ),
                                        _InfoRow(
                                          label: isArabic
                                              ? "رقم المدرسة"
                                              : "School ID",
                                          value: data['SchoolID'],
                                        ),
                                        const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Color(0xFFF2F3F5),
                                        ),
                                        _InfoRow(
                                          label: isArabic
                                              ? "رقم الحافلة"
                                              : "Bus ID",
                                          value: data['BusID'],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    _SectionLabel(
                                      label: isArabic
                                          ? "الموقع الجغرافي"
                                          : "Geographical Location",
                                      isArabic: isArabic,
                                    ),
                                    _InfoGroupCard(
                                      children: [
                                        _InfoRow(
                                          label: isArabic
                                              ? "خطوط الطول"
                                              : "Latitude",
                                          value: data['Latitude'],
                                        ),
                                        const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Color(0xFFF2F3F5),
                                        ),
                                        _InfoRow(
                                          label: isArabic
                                              ? "خطوط العرض"
                                              : "Longitude",
                                          value: data['Longitude'],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              _ActionButton(
                                label: isArabic
                                    ? "حذف بيانات الطالب"
                                    : "Delete Student",
                                icon: Icons.delete_outline,
                                color: _kDanger,
                                onTap: () => _confirmDelete(
                                  context,
                                  nameAr,
                                ), // نمرر الاسم للبحث في الطلبات
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomNav(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- دالة الحذف المعدلة (حذف الطالب + حذف الطلبات المرتبطة) ---
  Future<void> _confirmDelete(
    BuildContext context,
    String studentNameAr,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(isArabic ? "تأكيد الحذف الشامل" : "Confirm Full Delete"),
          content: Text(
            isArabic
                ? "سيتم حذف بيانات الطالب وجميع طلبات التسجيل المرتبطة به. هل أنت متأكد؟"
                : "This will delete student info and all associated registration requests. Continue?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isArabic ? "إلغاء" : "Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                isArabic ? "حذف الكل" : "Delete All",
                style: const TextStyle(color: _kDanger),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        // 1. حذف الطلبات المرتبطة من StudentRequests (البحث بالاسم العربي)
        final requestDocs = await FirebaseFirestore.instance
            .collection('StudentRequests')
            .where('name_ar', isEqualTo: studentNameAr)
            .get();

        for (var doc in requestDocs.docs) {
          await doc.reference.delete();
        }

        // 2. حذف مستند الطالب الأصلي
        await _ref.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? "تم حذف الطالب وطلباته بنجاح"
                    : "Student and requests deleted",
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint("Error during delete: $e");
      }
    }
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
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/AdminHome');
          if (index == 1) Navigator.pushReplacementNamed(context, '/role_home');
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded, size: 28),
            label: isArabic ? 'الرئيسية' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded, size: 28),
            label: isArabic ? 'الملف' : 'Profile',
          ),
        ],
      ),
    );
  }
}

/* -------------------- UI COMPONENTS -------------------- */

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack, onLang;
  const _TopHeader({
    required this.title,
    required this.onBack,
    required this.onLang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)),
      child: Row(
        children: [
          IconButton(
            onPressed: onLang,
            icon: const Icon(Icons.language, color: Colors.white, size: 22),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
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
      padding: const EdgeInsets.all(24),
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
      child: Column(children: children),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String name;
  const _ProfileSection({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Icon(Icons.edit_note, color: Colors.grey.shade300, size: 28),
        ),
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFFFFC83D),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 55, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF101828),
          ),
        ),
      ],
    );
  }
}

class _InfoGroupCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoGroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F3F5)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final dynamic value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF667085),
              fontSize: 13,
            ),
          ),
          Text(
            value?.toString() ?? '---',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D1B36),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isArabic;
  const _SectionLabel({required this.label, required this.isArabic});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10, right: 4, left: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF98AF8D),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
