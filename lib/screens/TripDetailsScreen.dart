// ignore_for_file: file_names
import 'package:flutter/material.dart';

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key});

  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kHeaderBlue,
          elevation: 0,
          centerTitle: true,
          // ✅ هذا السطر سيجعل عنوان الصفحة (Text) باللون الأبيض تلقائياً
          foregroundColor: Colors.white,
          title: const Text(
            "تفاصيل التوقفات",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          // ✅ هذا الجزء للتحكم في لون سهم الرجوع
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
                // كود الترجمة أو تغيير اللغة هنا
                print("تغيير اللغة");
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // الإحصائيات العلوية (Tab Bar المخصص)
            _buildStatsHeader(),

            // قائمة الطلاب
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: 12, // عدد تجريبي
                itemBuilder: (context, index) {
                  return _StudentTile(index: index + 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          _StatItem(
            count: "12",
            label: "في الانتظار",
            color: Colors.blue,
            isActive: true,
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _StatItem(
            count: "5",
            label: "في الحافلة",
            color: Colors.green,
            isActive: false,
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
              color: Colors.blue,
            ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final int index;
  const _StudentTile({required this.index});

  @override
  Widget build(BuildContext context) {
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
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            "$index",
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: const Text(
          "ملك عبدالله الغامدي",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: CircleAvatar(
          radius: 15,
          backgroundColor: index % 2 == 0 ? Colors.green : Colors.grey.shade700,
          child: const Text(
            "م",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
