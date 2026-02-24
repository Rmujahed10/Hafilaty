import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color _kBlue = Color(0xFF0D1B36);
const Color _kYellow = Color(0xFFFFC83D);

class StudentInfoScreen extends StatelessWidget {
  final String studentDocId;
  const StudentInfoScreen({super.key, required this.studentDocId});

  DocumentReference get _ref =>
      FirebaseFirestore.instance.collection('Students').doc(studentDocId);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBlue, 
        body: StreamBuilder<DocumentSnapshot>(
          stream: _ref.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

           return SafeArea(
  child: Stack(
    children: [

      Positioned(
        top: 8,
        left: 0,
        right: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 30,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 26,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              
            ],
          ),
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

                            /// زر التعديل
                            Row(
                              children: [
                                const Spacer(),
                                Icon(Icons.edit,
                                    color: Colors.grey.shade500),
                              ],
                            ),

                            const SizedBox(height: 10),

                            /// صورة الطالب
                            const CircleAvatar(
                              radius: 45,
                              backgroundColor: _kYellow,
                              child: Icon(Icons.person,
                                  size: 50, color: Colors.white),
                            ),

                            const SizedBox(height: 14),

                            Text(
                              data['StudentName'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 20),

                            _infoBox("رقم الطالب التعريفي",
                                data['StudentID']),
                            _infoBox("خطوط الطول",
                                data['Latitude']),
                            _infoBox("خطوط العرض",
                                data['Longitude']),
                            _infoBox("رقم المدرسة التعريفي",
                                data['SchoolID']),
                            _infoBox("رقم الباص التعريفي",
                                data['BusID']),

                            const SizedBox(height: 25),

                            /// زر الحذف
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
                                child: const Icon(Icons.delete,
                                    color: Colors.white, size: 28),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _kBlue,
          ),
        ),

        Text(
          value?.toString() ?? '',
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        
      ],
    ),
  );
}
}