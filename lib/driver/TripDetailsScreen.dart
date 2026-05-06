// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection; 

class TripDetailsScreen extends StatelessWidget {
  final String busId; 
  final bool isReturnTrip;

  const TripDetailsScreen({super.key, required this.busId, this.isReturnTrip = false});

  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Added 'en_US' so it doesn't break on Arabic physical devices!
    String todayDate = DateFormat('yyyy-MM-dd', 'en_US').format(DateTime.now());
    
    String label1 = isReturnTrip ? "في الحافلة" : "في الانتظار";
    String label2 = isReturnTrip ? "تم الوصول" : "في الحافلة";
    
    // استخراج رقم الباص الخاص بالطلاب (مثال: Bus_32438_101 -> 101)
    final String busIdSuffix = busId.split('_').last;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kHeaderBlue,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
          title: const Text(
            "تفاصيل التوقفات",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        
        // ✅ 1. جلب بيانات الطلاب الخاصة بهذا الباص من كولكشن Students (لمعرفة أسمائهم)
        body: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('Students')
              .where('BusID', isEqualTo: busIdSuffix)
              .get(),
          builder: (context, studentsSnapshot) {
            if (studentsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!studentsSnapshot.hasData || studentsSnapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text("لا يوجد طلاب مسجلين في هذه الحافلة",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));
            }

            // تخزين بيانات الطلاب (الاسم، ورقم الباص) في Map لسهولة البحث عنهم لاحقاً باستخدام رقمهم (ID)
            Map<String, Map<String, dynamic>> busStudentsMap = {};
            for (var doc in studentsSnapshot.data!.docs) {
              busStudentsMap[doc.id] = doc.data() as Map<String, dynamic>;
            }

            // ✅ 2. الاستماع المباشر لحالة الحضور من كولكشن Attendance
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Attendance')
                  .doc(todayDate) // This will now correctly query "2026-05-06"
                  .collection('PresentStudents')
                  .snapshots(),
              builder: (context, attendanceSnapshot) {
                if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!attendanceSnapshot.hasData || attendanceSnapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("لا يوجد بيانات حضور لهذا اليوم",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));
                }

                // ✅ 3. دمج البيانات: استخراج الطلاب الحاضرين الذين ينتمون لهذا الباص فقط
                List<Map<String, dynamic>> presentBusStudents = [];
                int count1 = 0;
                int count2 = 0;

                for (var attendanceDoc in attendanceSnapshot.data!.docs) {
                  String studentId = attendanceDoc.id;
                  
                  // هل هذا الطالب الحاضر ينتمي لحافلتنا الحالية؟
                  if (busStudentsMap.containsKey(studentId)) {
                    var studentData = busStudentsMap[studentId]!;
                    var attendanceData = attendanceDoc.data() as Map<String, dynamic>;
                    
                    // تحديد الحالة (busStatus)
                    String defaultStatus = isReturnTrip ? 'في الحافلة' : 'في الانتظار';
                    String status = attendanceData['busStatus'] ?? defaultStatus;
                    
                    presentBusStudents.add({
                      'id': studentId,
                      'name': studentData['StudentName_ar'] ?? studentData['StudentName'] ?? "طالب غير معروف",
                      'status': status,
                    });

                    // حساب الإحصائيات والأرقام
                    if (isReturnTrip) {
                      if (status == 'تم الوصول') {
                        count2++;
                      } else {
                        count1++;
                      }
                    } else {
                      if (status == 'في الحافلة') {
                        count2++;
                      } else {
                        count1++;
                      }
                    }
                  }
                }

                if (presentBusStudents.isEmpty) {
                   return const Center(
                      child: Text("لا يوجد طلاب حاضرين في هذه الرحلة",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));
                }

                // ✅ 4. عرض القائمة النهائية والعدادات
                return Column(
                  children: [
                    _buildStatsHeader(
                      count1: count1, 
                      count2: count2, 
                      label1: label1, 
                      label2: label2
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: presentBusStudents.length, 
                        itemBuilder: (context, index) {
                          var student = presentBusStudents[index];
                          String status = student['status'];

                          // نحدد إذا الطالب أكمل المرحلة
                          bool isCompleted = isReturnTrip ? (status == 'تم الوصول') : (status == 'في الحافلة');

                          return _StudentTile(
                            index: index + 1,
                            studentName: student['name'], 
                            isCompleted: isCompleted, 
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsHeader({
    required int count1, 
    required int count2, 
    required String label1, 
    required String label2
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          _StatItem(
            count: count1.toString(), 
            label: label1,
            color: Colors.blue,
            isActive: count1 > 0, 
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _StatItem(
            count: count2.toString(), 
            label: label2,
            color: Colors.green,
            isActive: count2 > 0, 
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final Color color;
  final bool isActive;

  const _StatItem({
    required this.count,
    required this.label,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 5),
              Icon(Icons.arrow_upward, size: 16, color: color),
            ],
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 3,
              width: 60,
              color: color,
            ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final int index;
  final String studentName; 
  final bool isCompleted; 

  const _StudentTile({required this.index, required this.studentName, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    String firstLetter = studentName.trim().isNotEmpty ? studentName.trim()[0] : "؟";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4), 
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.shade50 : Colors.blue.shade50, 
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            "$index",
            style:  TextStyle(
              color: isCompleted ? Colors.green : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          studentName, 
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: CircleAvatar(
          radius: 15,
          backgroundColor: isCompleted ? Colors.green : Colors.grey.shade400,
          child: Text(
            firstLetter, 
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}