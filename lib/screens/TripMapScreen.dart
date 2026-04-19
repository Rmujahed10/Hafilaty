import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:ui' as ui;

import 'TripDetailsScreen.dart';
import 'trip_pins_service.dart';
import 'trip_navigation_service.dart';

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
  final Set<Polyline> _polylines = {}; 
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints(apiKey: 'AIzaSyASw9kOAjo6lWB5OX7oFFGU40CCGFPVJYY');

  // --- NEW TRACKING VARIABLES ---
  StreamSubscription<Position>? _positionStreamSubscription;
  Marker? _busMarker;
  LatLng? _currentBusLocation;

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPins() async {
    try {
      final List<StudentPinModel> presentStudents = await _tripPinsService.getPresentStudentsData();

      if (presentStudents.isEmpty) {
        debugPrint("لا يوجد طلاب حاضرون اليوم.");
        setState(() {
          _markers = {};
          _students = [];
        });
        return;
      }

      final markers = _tripPinsService.getMarkersFromList(presentStudents);

      setState(() {
        _students = presentStudents;
        _markers = markers;
      });

      if (_students.isNotEmpty) {
        await _getRoutePolyline(); 
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

  Future<void> _startLiveTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Location permissions are denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("Location permissions are permanently denied");
      return;
    }

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, 
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      LatLng newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentBusLocation = newLocation;
        _busMarker = Marker(
          markerId: const MarkerId("bus_location"),
          position: newLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "موقع الباص الحالي"),
        );
      });

      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newLocation,
            zoom: 16.0,
            bearing: position.heading, 
            tilt: 45.0, 
          ),
        ),
      );
    });
  }

  Future<void> _startTrip() async {
    if (_students.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد طلاب لهذا الباص')),
        );
      }
      return;
    }

    await _startLiveTracking();
    await _getRoutePolyline();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم بدء الرحلة وبدأ التتبع المباشر')),
      );
    }
  }

  Future<void> _getRoutePolyline() async {
    if (_students.isEmpty) return;

    PointLatLng origin = _currentBusLocation != null 
        ? PointLatLng(_currentBusLocation!.latitude, _currentBusLocation!.longitude)
        : PointLatLng(_initialPosition.latitude, _initialPosition.longitude);
        
    PointLatLng destination = PointLatLng(_students.last.lat, _students.last.lng);

    List<PolylineWayPoint> wayPoints = _students
        .skip(1) 
        .take(24) // Updated to max out the waypoint limit safely
        .map((s) => PolylineWayPoint(location: "${s.lat},${s.lng}"))
        .toList();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: origin,
        destination: destination,
        mode: TravelMode.driving,
        wayPoints: wayPoints,
        optimizeWaypoints: true,
      ),
    );

    if (result.points.isNotEmpty) {
      setState(() {
        _polylines.clear(); 
        _polylines.add(Polyline(
          polylineId: const PolylineId("route"),
          color: const Color(0xFF0D1B36), 
          width: 5,
          points: result.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
        ));
      });
    }

    if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
      debugPrint("Google Maps Error Message: ${result.errorMessage}");
      debugPrint("Status: ${result.status}");
    }
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
                      markers: _busMarker != null 
                          ? {..._markers, _busMarker!} 
                          : _markers,
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
              _positionStreamSubscription?.cancel();
              debugPrint("تم إنهاء الرحلة وإيقاف التتبع");
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