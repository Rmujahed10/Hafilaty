import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'TripDetailsScreen.dart';
import 'trip_pins_service.dart';
import 'trip_navigation_service.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;


class TripMapScreen extends StatefulWidget {
  const TripMapScreen({super.key});

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const LatLng _initialPosition = LatLng(24.7136, 46.6753);

  final Completer<GoogleMapController> _mapController = Completer();
  final TripPinsService _tripPinsService = TripPinsService();
  final TripNavigationService _tripNavigationService = TripNavigationService();

  final String busId = "102";

  Set<Marker> _markers = {};
  List<StudentPinModel> _students = [];
  Set<Polyline> _polylines = {};
List<LatLng> polylineCoordinates = [];
PolylinePoints polylinePoints = PolylinePoints();
 

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

// داخل _TripMapScreenState في ملف TripMapScreen.dart

Future<void> _loadPins() async {
  try {
    // جلب البيانات كاملة (بدون تكرار وبدون طلبات إضافية)
    final List<StudentPinModel> presentStudents = await _tripPinsService.getPresentStudentsData();

    if (presentStudents.isEmpty) {
      debugPrint("لا يوجد طلاب حاضرون اليوم.");
      setState(() {
        _markers = {};
        _students = [];
      });
      return;
    }

    // إنشاء الماركرز مباشرة من البيانات المحملة
    final markers = _tripPinsService.getMarkersFromList(presentStudents);

    setState(() {
      _students = presentStudents;
      _markers = markers;
    });

    if (_students.isNotEmpty) {
      _getRoutePolyline(); 
    }

    await _fitMapToMarkers();
  } catch (e) {
    debugPrint("Error loading pins: $e");
  }
}

  Future<void> _fitMapToMarkers() async {
    if (_markers.isEmpty) return;

    final controller = await _mapController.future;
    final positions = _markers.map((m) => m.position).toList();

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  Future<void> _startTrip() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد طلاب لهذا الباص')),
      );
      return;
    }

    final firstStudent = _students.first;

    await _tripNavigationService.startNavigationToPoint(
      lat: firstStudent.lat,
      lng: firstStudent.lng,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              _TopHeader(
                title: "عرض الرحلة",
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: _initialPosition,
                        zoom: 14,
                      ),
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      markers: _markers,
                      polylines: _polylines,
                      onMapCreated: (controller) {
                        _mapController.complete(controller);
                      },
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildTripControlPanel(),
                    ),
                  ],
                ),
              ),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _getRoutePolyline() async {
  if (_students.isEmpty) return;

  // إعداد نقاط البداية والنهاية
  PointLatLng origin = PointLatLng(_initialPosition.latitude, _initialPosition.longitude);
  PointLatLng destination = PointLatLng(_students.last.lat, _students.last.lng);

  // إضافة الطلاب كنقاط توقف (Waypoints)
  List<PolylineWayPoint> wayPoints = _students
      .skip(1) 
      .take(10) 
      .map((s) => PolylineWayPoint(location: "${s.lat},${s.lng}"))
      .toList();

  // طلب المسار من Google Directions API
  PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
    "AIzaSyCMOPv3-LdcAPUteoIZIE1jnePnP6oLPi8", // استبدليه بمفتاحك
    origin,
    destination,
    wayPoints: wayPoints,
    travelMode: TravelMode.driving,
  );

  if (result.points.isNotEmpty) {
    setState(() {
      _polylines.add(Polyline(
        polylineId: const PolylineId("route"),
        color: const Color(0xFF0D1B36), // لون الهيدر الخاص بكِ ليكون متناسقاً
        width: 5,
        points: result.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
      ));
    });
  }

  if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
  print("Google Maps Error Message: ${result.errorMessage}");
  print("Status: ${result.status}");
}
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

          _buildInfoRow(Icons.access_time, "الوقت المتوقع: 18 دقيقة"),
          _buildColoredInfoRow('assets/placeholder.png', "عدد التوقفات: ${_students.length}"),
          _buildColoredInfoRow('assets/traffic-lights.png', "حالة المرور: متوسطة"),

          const SizedBox(height: 20),

          _ActionButton(
            label: "تفاصيل التوقفات",
            color: const Color(0xFFFFC107),
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TripDetailsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          _ActionButton(
            label: "بدء الرحلة",
            color: const Color(0xFF6A994E),
            onPressed: _startTrip,
          ),

          const SizedBox(height: 10),

          _ActionButton(
            label: "إنهاء الرحلة",
            color: const Color(0xFFD64545),
            onPressed: () {
              print("تم إنهاء الرحلة");
            },
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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
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

Widget _buildColoredInfoRow(String imagePath, String text) {
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
          Image.asset(
            imagePath,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}