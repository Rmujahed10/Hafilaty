// ignore_for_file: file_names
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection; 

class TripDetailsScreen extends StatelessWidget {
  final String busId; 
  final bool isReturnTrip; // ✅ إضافة متغير لتحديد نوع الرحلة

  // جعلنا القيمة الافتراضية false (رحلة ذهاب) عشان ما يأثر على استدعاءاتك السابقة
  const TripDetailsScreen({super.key, required this.busId, this.isReturnTrip = false});

  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    // ✅ استخراج تاريخ اليوم بصيغة مطابقة لما في الداتا بيس
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // ✅ تحديد نصوص الحالات ديناميكياً بناءً على نوع الرحلة
    String label1 = isReturnTrip ? "في الحافلة" : "في الانتظار";
    String label2 = isReturnTrip ? "تم الوصول" : "في الحافلة";

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
            int count1 = 0; // يمثل: في الانتظار (ذهاب) أو في الحافلة (عودة)
            int count2 = 0; // يمثل: في الحافلة (ذهاب) أو تم الوصول (عودة)

            for (var doc in students) {
              final data = doc.data() as Map<String, dynamic>;
              // الحالة الافتراضية تعتمد على نوع الرحلة إذا لم تكن موجودة
              String defaultStatus = isReturnTrip ? 'في الحافلة' : 'في الانتظار';
              String status = data['busStatus'] ?? defaultStatus; 
              
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: totalStudents, 
                    itemBuilder: (context, index) {
                      var studentData = students[index].data() as Map<String, dynamic>;
                      
                      // ✅ جلب اسم الطالب بناءً على الحقول الصحيحة في قاعدة البيانات
                      String studentName = studentData['StudentName_ar'] ?? studentData['StudentName'] ?? "طالب غير معروف";
                      String defaultStatus = isReturnTrip ? 'في الحافلة' : 'في الانتظار';
                      String status = studentData['busStatus'] ?? defaultStatus;

                      // ✅ نحدد إذا الطالب أكمل المرحلة (ركب في الذهاب، أو وصل في العودة)
                      bool isCompleted = isReturnTrip ? (status == 'تم الوصول') : (status == 'في الحافلة');

                      return _StudentTile(
                        index: index + 1,
                        studentName: studentName, 
                        isCompleted: isCompleted, // نمرر الحالة الديناميكية
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

  // ✅ تعديل دالة الإحصائيات لتقبل نصوص وعدادات ديناميكية
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
  final bool isCompleted; // ✅ تم تغيير الاسم ليكون أشمل من isBoarded

  const _StudentTile({required this.index, required this.studentName, required this.isCompleted});

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