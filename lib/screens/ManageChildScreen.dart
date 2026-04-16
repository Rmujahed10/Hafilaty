// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:qr_flutter/qr_flutter.dart';

class ManageChildScreen extends StatefulWidget {
  const ManageChildScreen({super.key});

  @override
  State<ManageChildScreen> createState() => _ManageChildScreenState();
}

class _ManageChildScreenState extends State<ManageChildScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kCard = Colors.white;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return const Scaffold(body: Center(child: Text("لا توجد بيانات")));
    }

    // ✅ نعتمد على studentId
    final studentId = (args['StudentID'] ?? '').toString();
    if (studentId.trim().isEmpty) {
      return const Scaffold(body: Center(child: Text("studentId غير موجود")));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Students')
                .doc(studentId)
                .snapshots(),
            builder: (context, snapshot) {
              // ✅ تحميل
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // ✅ لو انحذف المستند
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("تم حذف البيانات بنجاح"));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

              // ✅ عدّل أسماء الحقول حسب الـ Students عندك
              final nameAr = (data['StudentName_ar'] ?? '').toString();
              final nameEn = (data['StudentName'] ?? '').toString();
              final parentPhone = (data['parentPhone'] ?? '').toString();

              final childName = nameAr.isNotEmpty ? nameAr : nameEn;
              final displayName = childName.isEmpty ? "طالب" : childName;

              // ✅ نفس صيغة التاريخ اللي عندك في Attendance (مثل 2026-03-06)
              final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

              return Column(
                children: [
                  _TopHeader(
                    title: "تتبع الابن",
                    onBack: () => Navigator.pop(context),
                    onLang: () {},
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 6),

                                // ✅ صورة ولي الأمر من users collection
                                _UserAvatarFromFirestore(
                                  parentPhone: parentPhone,
                                ),

                                const SizedBox(height: 12),

                                // ✅ عرض الاسم
                                Text(
                                  displayName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF101828),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // ✅ عرض حالة الحضور
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('Attendance')
                                      .doc(todayDate)
                                      .collection('PresentStudents')
                                      .doc(studentId)
                                      .snapshots(),
                                  builder: (context, attSnap) {
                                    String currentStatus = "غائب";

                                    if (attSnap.connectionState ==
                                        ConnectionState.waiting) {
                                      currentStatus = "جارٍ التحميل...";
                                    } else if (attSnap.hasData &&
                                        attSnap.data!.exists) {
                                      final attData = attSnap.data!.data()
                                          as Map<String, dynamic>;
                                      currentStatus =
                                          (attData['attendanceStatus'] ??
                                                  "غائب")
                                              .toString();
                                    }

                                    return AttendanceStatusPill(
                                      status: currentStatus,
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),

                                // --------------------------------------------------
                                // ✅✅✅ زر لفتح الباركود كـ Pop-up
                                // --------------------------------------------------
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showQrCodeDialog(context, studentId),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.qr_code_2_rounded,
                                            color: _kHeaderBlue,
                                            size: 26,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            "عرض رمز صعود الحافلة",
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: _kHeaderBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // --------------------------------------------------
                                // ✅✅✅ نهاية زر الباركود
                                // --------------------------------------------------

                                const SizedBox(height: 24),

                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    "تتبع الابن",
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF475467),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),
                                const _MapPreview(),
                                const SizedBox(height: 12),

                                const _TimelineCard(
                                  items: [
                                    _TimelineRowData(
                                      title: "تم صعود الباص بنجاح من المنزل",
                                      time: "الساعة : 7:10 صباحاً",
                                      dotColor: Color(0xFF7CB342),
                                      icon: Icons.location_on,
                                    ),
                                    _TimelineRowData(
                                      title: "تم التوصيل الى المدرسة",
                                      time: "الساعة : 7:12 صباحاً",
                                      dotColor: Color(0xFF7CB342),
                                      icon: Icons.flag,
                                    ),
                                    _TimelineRowData(
                                      title: "تم صعود الحافلة بنجاح من المدرسة",
                                      time: "",
                                      dotColor: Color(0xFF5C6BC0),
                                      icon: Icons.place,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  // ✅ الدالة المسؤولة عن إظهار الباركود في نافذة منبثقة مع التنبيه
  void _showQrCodeDialog(BuildContext context, String studentId) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "رمز صعود الحافلة (QR Code)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF101828),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "يرجى طباعة هذا الرمز لإبرازه للسائق عند صعود الحافلة يومياً.",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475467),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // ✅✅✅ رسالة التنبيه
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3F2), // خلفية حمراء فاتحة
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFEE4E2), // حدود حمراء باهتة
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFD92D20), // لون الأيقونة
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: const Text(
                            "تنبيه هام: يجب أن يكون هذا الرمز بحوزة الطالب لتجنب تسجيله كـ غائب.",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB42318), // لون النص
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: QrImageView(
                      data: studentId, // المعرف الفريد للطالب
                      version: QrVersions.auto,
                      size: 200.0, // حجم كبير وواضح
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kHeaderBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "إغلاق",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/parent_home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/role_home');
          }
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

/* -------------------- Attendance Display Only -------------------- */

class AttendanceStatusPill extends StatelessWidget {
  final String status;
  const AttendanceStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.trim();

    final bool isPresent = s == "حاضر";
    final bool isAbsent = s == "غائب";

    final Color bg = isPresent
        ? const Color(0xFFB7E4C7)
        : isAbsent
            ? const Color(0xFFF3B7B7)
            : const Color(0xFFE5E7EB);

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: Container(
        height: 44,
        width: 220,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          status,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Color(0xFF0B1220),
          ),
        ),
      ),
    );
  }
}

/* -------------------- Sub-Widgets remain as they were -------------------- */

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onLang;
  const _TopHeader({
    required this.title,
    required this.onBack,
    required this.onLang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
              fontSize: 18.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _UserAvatarFromFirestore extends StatelessWidget {
  final String parentPhone;
  const _UserAvatarFromFirestore({required this.parentPhone});

  @override
  Widget build(BuildContext context) {
    if (parentPhone.trim().isEmpty) return _fallbackAvatar();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(parentPhone)
          .snapshots(),
      builder: (context, snap) {
        String photoUrl = "";
        if (snap.hasData && snap.data!.exists) {
          final u = snap.data!.data() as Map<String, dynamic>;
          photoUrl = (u['photoUrl'] ?? '').toString();
        }
        if (photoUrl.trim().isEmpty) return _fallbackAvatar();

        return Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: Color(0xFFE6E6E6),
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
          ),
        );
      },
    );
  }

  Widget _fallbackAvatar() => Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          color: Color(0xFFE6E6E6),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.person, size: 60, color: Colors.white),
      );
}

class _MapPreview extends StatelessWidget {
  const _MapPreview();

  @override
  Widget build(BuildContext context) {
    const url = "https://maps.gstatic.com/tactile/basepage/pegman_sherlock.png";
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFEDEFF2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFEDEFF2),
          alignment: Alignment.center,
          child: const Text(
            "الخريطة غير متاحة حالياً",
            style: TextStyle(
              color: Color(0xFF475467),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineRowData {
  final String title, time;
  final Color dotColor;
  final IconData icon;
  const _TimelineRowData({
    required this.title,
    required this.time,
    required this.dotColor,
    required this.icon,
  });
}

class _TimelineCard extends StatelessWidget {
  final List<_TimelineRowData> items;
  const _TimelineCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: item.dotColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 14, color: item.dotColor),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 34,
                      margin: const EdgeInsets.only(top: 6),
                      color: const Color(0xFFE5E7EB),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF344054),
                          fontSize: 13.5,
                        ),
                      ),
                      if (item.time.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.time,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF98A2B3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}