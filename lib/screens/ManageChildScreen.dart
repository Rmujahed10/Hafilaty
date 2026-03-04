import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:hijri/hijri_calendar.dart';

class ManageChildScreen extends StatefulWidget {
  const ManageChildScreen({super.key});

  @override
  State<ManageChildScreen> createState() => _ManageChildScreenState();
}

class _ManageChildScreenState extends State<ManageChildScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kCard = Colors.white;

  String attendance = "غائب";

  // --- دالة الحذف الشاملة (المشكلة 2 و 3) ---
  Future<void> _handleDeleteAccount(
    String requestId,
    String studentName,
  ) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text("تأكيد الحذف النهائي"),
              content: Text(
                "هل أنت متأكد من حذف حساب الطالب ($studentName)؟ سيتم مسح البيانات من كافة السجلات.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("إلغاء"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    "حذف الآن",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (confirm) {
      try {
        // 1. الحذف من كولكشن StudentRequests
        await FirebaseFirestore.instance
            .collection('StudentRequests')
            .doc(requestId)
            .delete();

        // 2. الحذف من كولكشن Students (البحث بالاسم)
        var studentDoc = await FirebaseFirestore.instance
            .collection('Students')
            .where('StudentName_ar', isEqualTo: studentName)
            .get();

        for (var doc in studentDoc.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم حذف كافة بيانات الطالب بنجاح")),
          );
          // العودة للشاشة السابقة لتصفير الحالة (حل المشكلة 3)
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint("Error during deletion: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null)
      return const Scaffold(body: Center(child: Text("لا توجد بيانات")));

    final requestId = args['requestId'] as String;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('StudentRequests')
                .doc(requestId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || !snapshot.data!.exists)
                return const Center(child: Text("تم حذف البيانات بنجاح"));

              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final nameAr = (data['name_ar'] ?? '').toString();
              final parentPhone = (data['parentPhone'] ?? '').toString();

              return Column(
                children: [
                  _TopHeader(
                    title: "إدارة الابن",
                    onBack: () => Navigator.pop(context),
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
                                Row(
                                  children: [
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => _handleDeleteAccount(
                                        requestId,
                                        nameAr,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.5),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: Colors.red.withOpacity(0.05),
                                        ),
                                        child: const Text(
                                          "حذف الحساب",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                _UserAvatar(parentPhone: parentPhone),
                                const SizedBox(height: 12),
                                Text(
                                  nameAr,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF101828),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "يرجى تأكيد حضور الطالب للباص ليوم الغد قبل الساعة : 05:00 صباحاً\nلضمان وصول الباص في الموعد الملتزم به",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: Color(0xFFD64545),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // --- شريط الحضور المعدل للشهر العربي ---
                                FigmaAttendanceBar(
                                  attendance: attendance,
                                  onChanged: (val) =>
                                      setState(() => attendance = val),
                                ),
                                const SizedBox(height: 20),
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

// --- الويجيت المعدل لعرض الشهر بالعربي (حل المشكلة 1) ---
class FigmaAttendanceBar extends StatelessWidget {
  final String attendance;
  final ValueChanged<String> onChanged;
  const FigmaAttendanceBar({
    super.key,
    required this.attendance,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    var today = HijriCalendar.now();
    // مصفوفة الأشهر العربية يدوياً لضمان عدم ظهورها بالإنجليزية
    const List<String> monthsAr = [
      "محرم",
      "صفر",
      "ربيع الأول",
      "ربيع الآخر",
      "جمادى الأولى",
      "جمادى الآخرة",
      "رجب",
      "شعبان",
      "رمضان",
      "شوال",
      "ذو القعدة",
      "ذو الحجة",
    ];

    String dayName = DateFormat('EEEE', 'ar').format(DateTime.now());
    String hijriMonth = monthsAr[today.hMonth - 1];

    return Container(
      height: 85,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF8A95A5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                today.hDay.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1220),
                ),
              ),
              Text(
                "$hijriMonth - $dayName",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B1220),
                ),
              ),
            ],
          ),
          _RightPillDropdown(value: attendance, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _RightPillDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RightPillDropdown({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFC78484),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Color(0xFF0B1220),
          ),
          items: const [
            DropdownMenuItem(value: "غائب", child: Text("غائب")),
            DropdownMenuItem(value: "حاضر", child: Text("حاضر")),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          style: const TextStyle(
            color: Color(0xFF0B1220),
            fontWeight: FontWeight.bold,
          ),
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
      height: 92,
      width: double.infinity,
      color: const Color(0xFF0D1B36),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Icon(Icons.language, color: Colors.white),
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

class _UserAvatar extends StatelessWidget {
  final String parentPhone;
  const _UserAvatar({required this.parentPhone});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: Color(0xFFE6E6E6),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 50, color: Colors.white),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.shade300,
      ),
      child: const Center(child: Text("خريطة تتبع الباص")),
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
    return Column(
      children: items
          .map(
            (item) => ListTile(
              leading: Icon(item.icon, color: item.dotColor),
              title: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(item.time, style: const TextStyle(fontSize: 11)),
            ),
          )
          .toList(),
    );
  }
}
