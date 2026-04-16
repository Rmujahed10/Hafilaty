import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripMapScreen extends StatefulWidget {
  const TripMapScreen({super.key});

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);

  // إحداثيات وهمية للمثال
  static const LatLng _initialPosition = LatLng(24.7136, 46.6753);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              // الهيدر العلوي
              _TopHeader(
                title: "عرض الرحلة",
                onBack: () => Navigator.pop(context),
              ),

              Expanded(
                child: Stack(
                  children: [
                    // الخريطة
                    const GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _initialPosition,
                        zoom: 14,
                      ),
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),

                    // الأزرار والمعلومات السفلية
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildTripControlPanel(),
                    ),
                  ],
                ),
              ),

              // البار السفلي
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط التحديث
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                "التحديث المباشر | آخر تحديث قبل 20 ثانية",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // تفاصيل الرحلة (الوقت، المحطات، المرور)
          _buildInfoRow(Icons.access_time, "الوقت المتوقع: 18 دقيقة"),
          _buildInfoRow(Icons.location_on, "عدد التوقفات: 5"),
          _buildInfoRow(Icons.traffic, "حالة المرور: متوسطة"),

          const SizedBox(height: 20),

          // الأزرار الرئيسية
          _ActionButton(
            label: "تفاصيل التوقفات",
            color: const Color.fromARGB(255, 225, 240, 111),
            textColor: Colors.black,
            onPressed: () {
              // Navigator.push(context, MaterialPageRoute(builder: (_) => const TripDetailsScreen()));
            },
          ),
          const SizedBox(height: 10),
          _ActionButton(
            label: "بدء الرحلة",
            color: const Color(0xFF6A994E),
            onPressed: () {},
          ),
          const SizedBox(height: 10),
          _ActionButton(
            label: "إنهاء الرحلة",
            color: const Color(0xFFD64545),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _kHeaderBlue),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person, color: Colors.grey),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.home, color: _kHeaderBlue, size: 30),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/* -------------------- المكونات الفرعية -------------------- */

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
