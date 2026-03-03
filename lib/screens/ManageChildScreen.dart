// ignore_for_file: file_names

// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection; // تم إضافة hide لمنع التعارض
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

  @override
  Widget build(BuildContext context) {
    // التأكد من استقبال البيانات بشكل صحيح
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return const Scaffold(body: Center(child: Text("لا توجد بيانات")));
    
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
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

              final nameAr = (data['name_ar'] ?? '').toString();
              final nameEn = (data['name_en'] ?? '').toString();
              final grade = (data['Grade'] ?? '').toString();
              final school = (data['SchoolName'] ?? '').toString();
              final status = (data['status'] ?? 'pending').toString();
              final parentPhone = (data['parentPhone'] ?? '').toString();

              final childName = nameAr.isNotEmpty ? nameAr : nameEn;

              const noteText =
                  "يرجى تأكيد حضور الطالب للباص ليوم الغد قبل الساعة : 05:00 صباحاً\nلضمان وصول الباص ووصول الباص في الموعد الملتزم به";

              return Column(
                children: [
                  _TopHeader(
                    title: "إدارة الابن",
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
                                Row(
                                  children: [
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.edit, color: Color(0xFF98A2B3)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                _UserAvatarFromFirestore(parentPhone: parentPhone),
                                const SizedBox(height: 12),
                                Text(
                                  childName.isEmpty ? "طالب" : childName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF101828),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  noteText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: Color(0xFFD64545),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // ✅ هنا قمت بإضافة البار الذي كان مفقوداً في الكود الخاص بك
                                FigmaAttendanceBar(
                                  attendance: attendance,
                                  onChanged: (val) {
                                    setState(() => attendance = val);
                                    // هنا يمكنك إضافة تحديث Firestore لـ requestId
                                  },
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
                  const _BottomBar(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


/* -------------------- Status Bar (Figma-like) -------------------- */
class FigmaAttendanceBar extends StatelessWidget {
  final String attendance;
  final ValueChanged<String> onChanged;

  const FigmaAttendanceBar({
    super.key,
    required this.attendance,
    required this.onChanged,
  });

  Map<String, String> get _getHijriDetails {
    // تحديث التاريخ الهجري بناءً على الوقت الحالي
    var today = HijriCalendar.now();
    
    // قائمة الشهور العربية لضمان عدم ظهور null
    List<String> monthsAr = [
      "محرم", "صفر", "ربيع الأول", "ربيع الآخر", "جمادى الأولى", "جمادى الآخرة",
      "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
    ];

    return {
      'dayNumber': today.hDay.toString(),
      'monthName': monthsAr[today.hMonth - 1],
      'dayName': DateFormat('EEEE', 'ar').format(DateTime.now()),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dateInfo = _getHijriDetails;

    return Container(
      height: 85,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF8A95A5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        // إصلاح خطأ TextDirection باستخدام الأحرف الصغيرة .rtl
        textDirection: TextDirection.rtl, 
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // اليمين: التاريخ (الرقم فوق والكلمات تحت)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dateInfo['dayNumber']!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1220),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${dateInfo['monthName']} ${dateInfo['dayName']}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B1220),
                ),
              ),
            ],
          ),
          
          // اليسار: زر "غائب/حاضر"
          _RightPillDropdown(
            value: attendance,
            onChanged: onChanged,
          ),
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
          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF0B1220)),
          items: const [
            DropdownMenuItem(value: "غائب", child: Text("غائب")),
            DropdownMenuItem(value: "حاضر", child: Text("حاضر")),
          ],
          onChanged: (v) { if (v != null) onChanged(v); },
          style: const TextStyle(color: Color(0xFF0B1220), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// (أكمل بقية الكود الخاص بـ _TopHeader, _UserAvatarFromFirestore, _MapPreview, _TimelineCard كما هي في ملفك)

/* -------------------- Top Header (Updated Order) -------------------- */

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
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)), // _kHeaderBlue
      child: Row(
        children: [
          // الآن: أيقونة اللغة في أقصى اليمين
          IconButton(
            onPressed: onLang,
            icon: const Icon(Icons.language, color: Colors.white),
          ),
          
          const Spacer(),
          
          // العنوان يبقى في المنتصف
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          
          const Spacer(),
          
          // الآن: سهم الرجوع في أقصى اليسار
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white), // استخدمنا arrow_forward لأنه يشير لليسار في وضع RTL
          ),
        ],
      ),
    );
  }
}

/* -------------------- User Avatar (from users doc) -------------------- */

class _UserAvatarFromFirestore extends StatelessWidget {
  final String parentPhone;

  const _UserAvatarFromFirestore({required this.parentPhone});

  @override
  Widget build(BuildContext context) {
    if (parentPhone.trim().isEmpty) {
      return _fallbackAvatar();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(parentPhone)
          .snapshots(),
      builder: (context, snap) {
        String photoUrl = "";

        if (snap.hasData && snap.data!.exists) {
          final u = snap.data!.data() as Map<String, dynamic>;

          // ✅ إذا اسم الحقل عندك مختلف عدّله هنا فقط:
          photoUrl = (u['photoUrl'] ?? '').toString(); // <-- change field if needed
        }

        if (photoUrl.trim().isEmpty) {
          return _fallbackAvatar();
        }

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

  Widget _fallbackAvatar() {
    return Container(
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
}

/* -------------------- Map Preview (with fallback) -------------------- */

class _MapPreview extends StatelessWidget {
  const _MapPreview();

  @override
  Widget build(BuildContext context) {
    // This URL may fail on Flutter Web due to CORS. We handle it.
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
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFFEDEFF2),
            alignment: Alignment.center,
            child: const Text(
              "الخريطة غير متاحة حالياً",
              style: TextStyle(
                color: Color(0xFF475467),
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }
}

/* -------------------- Timeline -------------------- */

class _TimelineRowData {
  final String title;
  final String time;
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
                      color: item.dotColor.withOpacity(0.15),
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


/* -------------------- Bottom Bar -------------------- */

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      width: double.infinity,
      color: const Color(0xFFE6E6E6),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 120,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.black,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}