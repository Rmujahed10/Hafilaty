import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color _kBlue = Color(0xFF0D1B36);
const Color _kYellow = Color(0xFFFFC83D);

class StudentInfoScreen extends StatefulWidget {
  final String studentDocId;
  const StudentInfoScreen({super.key, required this.studentDocId});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  bool isArabic = true;

  DocumentReference get _ref => FirebaseFirestore.instance
      .collection('Students')
      .doc(widget.studentDocId);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _kBlue,
        body: StreamBuilder<DocumentSnapshot>(
          stream: _ref.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

            return SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // language icon
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isArabic = !isArabic;
                            });
                          },
                          icon: const Icon(
                            Icons.language,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        // return button
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            isArabic
                                ? Icons.chevron_right
                                : Icons.chevron_right,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Spacer(),
                                Icon(Icons.edit, color: Colors.grey.shade500),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const CircleAvatar(
                              radius: 45,
                              backgroundColor: _kYellow,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              isArabic
                                  ? (data['StudentNameAr'] ??
                                        data['StudentName_ar'] ??
                                        'اسم غير معروف')
                                  : (data['StudentNameEn'] ??
                                        data['StudentName'] ??
                                        'Unknown Name'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // استخدام نصوص متغيرة بناءً على اللغة
                            _infoBox(
                              isArabic ? "رقم الطالب التعريفي" : "Student ID",
                              data['StudentID'],
                            ),
                            _infoBox(
                              isArabic ? "خطوط الطول" : "Latitude",
                              data['Latitude'],
                            ),
                            _infoBox(
                              isArabic ? "خطوط العرض" : "Longitude",
                              data['Longitude'],
                            ),
                            _infoBox(
                              isArabic ? "رقم المدرسة التعريفي" : "School ID",
                              data['SchoolID'],
                            ),
                            _infoBox(
                              isArabic ? "رقم الباص التعريفي" : "Bus ID",
                              data['BusID'],
                            ),
                            const SizedBox(height: 25),
                            InkWell(
                              onTap: () async {
                                await _ref.delete();
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoBox(String label, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBDBDBD)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label :",
            style: const TextStyle(fontWeight: FontWeight.bold, color: _kBlue),
          ),
          Text(
            value?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
