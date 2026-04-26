// ignore_for_file: file_names
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection; 

class TripDetailsScreen extends StatelessWidget {
  final String busId; 

  const TripDetailsScreen({super.key, required this.busId});

  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    // ✅ استخراج تاريخ اليوم بصيغة مطابقة لما في الداتا بيس
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

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
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.language, color: Colors.white, size: 22),
              onPressed: () {
                if (kDebugMode) {
                  print("تغيير اللغة");
                }
              },
            ),
          ],
        ),
        
        // ✅ توجيه الـ StreamBuilder إلى كولكشن Attendance واستخدام الفلترة المحلية
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Attendance')
              .doc(todayDate)
              .collection('PresentStudents')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text(
                "لا يوجد بيانات حضور لهذا اليوم",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ));
            }

            // ✅ الفلترة المحلية: التأكد من أن رقم باص السائق يحتوي على رقم باص الطالب
            final students = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final studentBusId = data['BusID']?.toString() ?? '';
              
              return studentBusId.isNotEmpty && busId.contains(studentBusId);
            }).toList();

            final int totalStudents = students.length; 

            // في حال لم يتبقَ طلاب بعد الفلترة
            if (students.isEmpty) {
               return const Center(
                  child: Text(
                "لا يوجد طلاب حاضرين في هذه الرحلة",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ));
            }

            // ✅ إضافة العدادات الديناميكية هنا
            int waitingCount = 0;
            int boardedCount = 0;

            for (var doc in students) {
              final data = doc.data() as Map<String, dynamic>;
              // نفترض أن الحالة محفوظة في حقل اسمه busStatus
              String status = data['busStatus'] ?? 'في الانتظار'; 
              
              if (status == 'في الحافلة') {
                boardedCount++;
              } else {
                waitingCount++;
              }
            }

            return Column(
              children: [
              _buildStatsHeader(waitingCount: waitingCount, boardedCount: boardedCount),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: totalStudents, 
                    itemBuilder: (context, index) {
                      var studentData = students[index].data() as Map<String, dynamic>;
                      
                      // ✅ جلب اسم الطالب بناءً على الحقول الصحيحة في قاعدة البيانات
                      String studentName = studentData['StudentName_ar'] ?? studentData['StudentName'] ?? "طالب غير معروف";
                      String status = studentData['busStatus'] ?? 'في الانتظار';

                      return _StudentTile(
                        index: index + 1,
                        studentName: studentName, 
                        isBoarded: status == 'في الحافلة', // ✅ نمرر حالة ركوب الطالب ليتغير اللون
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsHeader({required int waitingCount, required int boardedCount}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          _StatItem(
            count: waitingCount.toString(), 
            label: "في الانتظار",
            color: Colors.blue,
            isActive: waitingCount > 0, // الخط الأزرق يظهر إذا كان في طلاب ينتظرون
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _StatItem(
            count: boardedCount.toString(), 
            label: "في الحافلة",
            color: Colors.green,
            isActive: boardedCount > 0, // الخط الأخضر يظهر إذا ركب أحد
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
  final bool isBoarded; // ✅ متغير جديد لتحديد حالة الطالب

  const _StudentTile({required this.index, required this.studentName, required this.isBoarded});

  @override
  Widget build(BuildContext context) {
    // ✅ استخراج الحرف الأول بأمان
    String firstLetter = studentName.trim().isNotEmpty ? studentName.trim()[0] : "؟";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 4), 
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isBoarded ? Colors.green.shade50 : Colors.blue.shade50, // خلفية الرقم تتغير
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            "$index",
            style:  TextStyle(
              color: isBoarded ? Colors.green : Colors.blue,
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
          backgroundColor: isBoarded ? Colors.green : Colors.grey.shade400,
          child: Text(
            firstLetter, 
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}