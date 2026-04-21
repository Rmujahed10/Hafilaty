// ignore_for_file: file_names
import 'dart:async';
import 'dart:convert'; // ✅ Added for JSON parsing
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http; // ✅ Added for direct API calls
import 'dart:ui' as ui;

import 'TripDetailsScreen.dart';
import 'trip_pins_service.dart';
import 'trip_navigation_service.dart';

class TripMapScreen extends StatefulWidget {
  final String busId;
  final bool isMorningTrip;

  const TripMapScreen({
    super.key,
    required this.busId,
    required this.isMorningTrip,
  });

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const LatLng _initialPosition = LatLng(21.4858, 39.1925);

  final Completer<GoogleMapController> _mapController = Completer();
  final TripPinsService _tripPinsService = TripPinsService();
  final TripNavigationService _tripNavigationService = TripNavigationService();

  Set<Marker> _markers = {};
  List<StudentPinModel> _students = [];
  SchoolModel? _schoolModel;
  final Set<Polyline> _polylines = {};
  PolylinePoints polylinePoints = PolylinePoints(
    apiKey: 'AIzaSyASw9kOAjo6lWB5OX7oFFGU40CCGFPVJYY',
  );

  StreamSubscription<Position>? _positionStreamSubscription;
  Marker? _busMarker;
  LatLng? _currentBusLocation;

  // ✅ State variable for Real ETA
  String _estimatedTime = "جاري الحساب...";

  @override
  void initState() {
    super.initState();
    _loadTripData();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTripData() async {
    try {
      if (widget.busId.isEmpty) return;

      // 1. Safely handle Web GPS Restrictions
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        _currentBusLocation = LatLng(position.latitude, position.longitude);
      } catch (e) {
        debugPrint("GPS Blocked (Web). Using fallback location. Error: $e");
        _currentBusLocation = _initialPosition;
      }

      // 2. Fetch the School
      _schoolModel = await _tripPinsService.getSchoolLocationForBus(
        widget.busId,
      );

      if (_schoolModel == null) {
        debugPrint("CRITICAL: School model returned null from service.");
      }

      // 3. Fetch Students
      final List<StudentPinModel> rawStudents = await _tripPinsService
          .getPresentStudentsData(widget.busId);
      final List<StudentPinModel> presentStudents = rawStudents.where((s) {
        return s.lat != 0.0 && s.lng != 0.0;
      }).toList();

      final markers = _tripPinsService.getMarkersFromList(presentStudents);

      if (_schoolModel != null) {
        markers.add(
          Marker(
            markerId: const MarkerId("school_pin"),
            position: LatLng(_schoolModel!.lat, _schoolModel!.lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: const InfoWindow(title: "المدرسة"),
          ),
        );
      }

      _busMarker = Marker(
        markerId: const MarkerId("bus_location"),
        position: _currentBusLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: "موقعي الحالي"),
      );
      markers.add(_busMarker!);

      if (mounted) {
        setState(() {
          _students = presentStudents;
          _markers = markers;
        });
      }

      if (_students.isNotEmpty) {
        await _getRoutePolyline();
        await _fitMapToMarkers();
      }
    } catch (e) {
      debugPrint("Error loading trip data: $e");
    }
  }

  Future<void> _fitMapToMarkers() async {
    if (_markers.isEmpty) return;
    final controller = await _mapController.future;
    final positions = _markers.map((m) => m.position).toList();
    double minLat = positions.first.latitude, maxLat = positions.first.latitude;
    double minLng = positions.first.longitude,
        maxLng = positions.first.longitude;

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
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Future<void> _startLiveTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // يحدث الموقع كل 10 أمتار
          ),
        ).listen((Position position) {
          LatLng newLocation = LatLng(position.latitude, position.longitude);

          // 1. تحديث الخريطة أمام السائق الآن
          if (mounted) {
            setState(() {
              _currentBusLocation = newLocation;
              _busMarker = Marker(
                markerId: const MarkerId("bus_location"),
                position: newLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
                infoWindow: const InfoWindow(title: "موقعي الحالي"),
              );
              _markers.removeWhere((m) => m.markerId.value == "bus_location");
              _markers.add(_busMarker!);
            });
          }

          // 2. 🔥 الجزء الأهم: إرسال الموقع لـ Firebase ليراه الأب
          FirebaseFirestore.instance.collection('Buses').doc(widget.busId).set(
            {
              'lat': position.latitude,
              'lng': position.longitude,
              'LastUpdated':
                  FieldValue.serverTimestamp(), // تحديث الوقت تلقائياً
            },
            SetOptions(merge: true),
          ); // استخدام merge للحفاظ على باقي بيانات الباص

          debugPrint(
            "✅ تم إرسال الموقع لـ Firebase: ${position.latitude}, ${position.longitude}",
          );
        });
  }

  Future<void> _handleTripAction() async {
    if (widget.busId.isEmpty) return;

    try {
      // 1. Navigation Guard
      if (_schoolModel == null || _currentBusLocation == null) {
        debugPrint(
          "Missing Data. School: ${_schoolModel != null}, Location: ${_currentBusLocation != null}",
        );
        return;
      }

      // ✅ 2. LAUNCH MAPS IMMEDIATELY!
      // Do this BEFORE the database update so Chrome doesn't block the pop-up.
      // We use the already-tracked _currentBusLocation to eliminate GPS delay.
      await _tripNavigationService.startSmartNavigation(
        driverLat: _currentBusLocation!.latitude,
        driverLng: _currentBusLocation!.longitude,
        students: _students,
        school: _schoolModel!,
        isMorningTrip: widget.isMorningTrip,
      );

      // 3. Update Status in the background (Don't await it to block the UI)
      if (_tripNavigationService.currentBatchIndex == 0 ||
          _tripNavigationService.currentBatchIndex == 1) {
        _updateBusStatus(
          "جارية الآن",
        ); // Fires off to Firestore in the background

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("تم بدء الرحلة بنجاح")));
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("START_TRIP_ACTION_ERROR: $e");
    }
  }

  Future<void> _getRoutePolyline() async {
    if (_students.isEmpty ||
        _schoolModel == null ||
        _currentBusLocation == null)
      return;

    try {
      PointLatLng origin = PointLatLng(
        _currentBusLocation!.latitude,
        _currentBusLocation!.longitude,
      );
      PointLatLng destination = widget.isMorningTrip
          ? PointLatLng(_schoolModel!.lat, _schoolModel!.lng)
          : PointLatLng(_students.last.lat, _students.last.lng);

      List<PolylineWayPoint> wayPoints = _students
          .map((s) => PolylineWayPoint(location: "${s.lat},${s.lng}"))
          .toList();

      // ✅ 1. Calculate Real ETA via Google Directions API
      String originStr = "${origin.latitude},${origin.longitude}";
      String destStr = "${destination.latitude},${destination.longitude}";
      String wayStr = wayPoints.map((w) => w.location).join('|');
      String apiKey = 'AIzaSyASw9kOAjo6lWB5OX7oFFGU40CCGFPVJYY';

      String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=$originStr&destination=$destStr&waypoints=$wayStr&mode=driving&optimizeWaypoints=true&key=$apiKey";

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            int totalSeconds = 0;
            for (var leg in data['routes'][0]['legs']) {
              totalSeconds += (leg['duration']['value'] as int);
            }
            int totalMinutes = (totalSeconds / 60).round();
            if (mounted) setState(() => _estimatedTime = "$totalMinutes دقيقة");
          }
        }
      } catch (e) {
        debugPrint("HTTP ETA Error (CORS): $e");

        // ✅ SMART FALLBACK FOR WEB TESTING
        // If Chrome blocks Google API, we calculate it mathematically!
        double totalDistanceMeters = 0.0;
        LatLng previous = LatLng(origin.latitude, origin.longitude);

        // Add up distance between all waypoints
        for (var wp in wayPoints) {
          var parts = wp.location.split(',');
          LatLng current = LatLng(
            double.parse(parts[0]),
            double.parse(parts[1]),
          );
          totalDistanceMeters += Geolocator.distanceBetween(
            previous.latitude,
            previous.longitude,
            current.latitude,
            current.longitude,
          );
          previous = current;
        }

        // Add distance from last waypoint to destination
        totalDistanceMeters += Geolocator.distanceBetween(
          previous.latitude,
          previous.longitude,
          destination.latitude,
          destination.longitude,
        );

        // Assume average city bus speed of 30 km/h (8.33 meters/second)
        // Multiply distance by 1.4 to account for road curves instead of a straight line
        double estimatedSeconds = (totalDistanceMeters * 1.4) / 8.33;
        int totalMinutes = (estimatedSeconds / 60).round();

        if (totalMinutes < 1) totalMinutes = 1;

        if (mounted)
          setState(() => _estimatedTime = "حوالي $totalMinutes دقيقة");
      }

      // ✅ 2. Draw the Route on Map
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
        if (mounted) {
          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId("route"),
                color: const Color(0xFF0D1B36),
                width: 5,
                points: result.points
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList(),
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Polyline Error (Likely CORS on Web): $e");
      // The ETA will still show because our Smart Fallback caught it earlier!
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
                title: widget.isMorningTrip ? "رحلة الذهاب" : "رحلة العودة",
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: _initialPosition,
                        zoom: 12,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      markers: _markers,
                      polylines: _polylines,
                      onMapCreated: (controller) =>
                          _mapController.complete(controller),
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
    bool isFinished = _tripNavigationService.currentBatchIndex == 999;
    bool isFirstBatch = _tripNavigationService.currentBatchIndex == 0;
    String buttonText = isFinished
        ? "اكتملت الرحلة"
        : (isFirstBatch ? "بدء الرحلة" : "المجموعة التالية");

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
                "التحديث المباشر نشط",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // ✅ Real ETA displayed here
          _buildInfoRow(Icons.access_time, "الوقت المتوقع: $_estimatedTime"),

          _buildColoredInfoRow(
            'assets/placeholder.png',
            "عدد التوقفات: ${_students.length}",
          ),
          const SizedBox(height: 20),
          _ActionButton(
            label: "تفاصيل التوقفات",
            color: const Color(0xFFFFC107),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TripDetailsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ActionButton(
            label: buttonText,
            color: isFinished ? Colors.grey : const Color(0xFF6A994E),
            onPressed: isFinished ? () {} : _handleTripAction,
          ),
          const SizedBox(height: 10),
          _ActionButton(
            label: "إنهاء الرحلة",
            color: const Color(0xFFD64545),
            onPressed: () async {
              await _updateBusStatus("لم تبدأ");
              if (mounted) Navigator.pop(context);
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
      color: const Color(0xFFE6E6E6),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.person, color: Colors.grey),
          Icon(Icons.home, color: _kHeaderBlue, size: 30),
          Icon(Icons.settings, color: Colors.grey),
        ],
      ),
    );
  }

  Future<void> _updateBusStatus(String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('Buses')
          .doc(widget.busId)
          .update({
            'tripStatus': status,
            'LastUpdated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Error updating bus status: $e");
    }
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopHeader({required this.title, required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      color: const Color(0xFF0D1B36),
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
  final VoidCallback onPressed;
  const _ActionButton({
    required this.label,
    required this.color,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
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
            errorBuilder: (c, e, s) => const Icon(
              Icons.image_not_supported,
              size: 24,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}
