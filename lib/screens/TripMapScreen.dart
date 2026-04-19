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
  // Default to Jeddah area instead of Riyadh to prevent massive jumps if GPS is slow
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

  @override
  void initState() {
    super.initState();
    _loadTripData();
    _startLiveTracking(); // Start tracking immediately to get the driver's pin
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTripData() async {
    try {
      // 1. Get Driver Location First for the Pin
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentBusLocation = LatLng(position.latitude, position.longitude);

      // 2. Fetch School and Students
      _schoolModel = await _tripPinsService.getSchoolLocationForBus(widget.busId);
      final List<StudentPinModel> presentStudents = await _tripPinsService.getPresentStudentsData();

      if (presentStudents.isEmpty) {
        debugPrint("لا يوجد طلاب حاضرون اليوم.");
        return;
      }

      // 3. Prepare All Markers (Students + School + Driver)
      final markers = _tripPinsService.getMarkersFromList(presentStudents);

      if (_schoolModel != null) {
        markers.add(
          Marker(
            markerId: const MarkerId("school_pin"),
            position: LatLng(_schoolModel!.lat, _schoolModel!.lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: "المدرسة"),
          ),
        );
      }

      // Add Driver Pin immediately
      _busMarker = Marker(
        markerId: const MarkerId("bus_location"),
        position: _currentBusLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: "موقعي الحالي"),
      );
      markers.add(_busMarker!);

      setState(() {
        _students = presentStudents;
        _markers = markers;
      });

      // 4. Draw Route and Zoom to fit everyone immediately
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

    // Initial zoom to show all points
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Future<void> _startLiveTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentBusLocation = newLocation;
        _busMarker = Marker(
          markerId: const MarkerId("bus_location"),
          position: newLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "موقعي الحالي"),
        );
        _markers.removeWhere((m) => m.markerId.value == "bus_location");
        _markers.add(_busMarker!);
      });
    });
  }

  Future<void> _handleTripAction() async {
    if (_students.isEmpty || _schoolModel == null) return;

    // Refresh location one last time before launching
    Position position = await Geolocator.getCurrentPosition();
    _currentBusLocation = LatLng(position.latitude, position.longitude);

    await _tripNavigationService.startSmartNavigation(
      driverLat: _currentBusLocation!.latitude,
      driverLng: _currentBusLocation!.longitude,
      students: _students,
      school: _schoolModel!,
      isMorningTrip: widget.isMorningTrip,
    );
    setState(() {}); 
  }

  Future<void> _getRoutePolyline() async {
    if (_students.isEmpty || _schoolModel == null || _currentBusLocation == null) return;

    // Origin is ALWAYS the driver's real current location
    PointLatLng origin = PointLatLng(_currentBusLocation!.latitude, _currentBusLocation!.longitude);

    PointLatLng destination = widget.isMorningTrip
        ? PointLatLng(_schoolModel!.lat, _schoolModel!.lng)
        : PointLatLng(_students.last.lat, _students.last.lng);

    List<PolylineWayPoint> wayPoints = _students
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
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            color: const Color(0xFF0D1B36),
            width: 5,
            points: result.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          ),
        );
      });
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
                      myLocationEnabled: true, // Shows the native blue dot too
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      markers: _markers,
                      polylines: _polylines,
                      onMapCreated: (controller) => _mapController.complete(controller),
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
    String buttonText = isFinished ? "اكتملت الرحلة" : (isFirstBatch ? "بدء الرحلة" : "المجموعة التالية");

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
              Text("التحديث المباشر نشط", style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.access_time, "الوقت المتوقع: 18 دقيقة"),
          _buildColoredInfoRow('assets/placeholder.png', "عدد التوقفات: ${_students.length}"),
          const SizedBox(height: 20),
          _ActionButton(
            label: "تفاصيل التوقفات",
            color: const Color(0xFFFFC107),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TripDetailsScreen())),
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
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // --- Utility Widgets ---
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [Icon(icon, size: 18, color: _kHeaderBlue), const SizedBox(width: 10), Text(text, style: const TextStyle(fontWeight: FontWeight.w600))]),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(height: 70, color: const Color(0xFFE6E6E6), child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Icon(Icons.person, color: Colors.grey), Icon(Icons.home, color: _kHeaderBlue, size: 30), Icon(Icons.settings, color: Colors.grey)]));
  }
}

class _TopHeader extends StatelessWidget {
  final String title; final VoidCallback onBack;
  const _TopHeader({required this.title, required this.onBack});
  @override Widget build(BuildContext context) {
    return Container(height: 70, color: const Color(0xFF0D1B36), child: Row(children: [IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)), const Spacer(), Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), const SizedBox(width: 40)]));
  }
}

class _ActionButton extends StatelessWidget {
  final String label; final Color color; final VoidCallback onPressed;
  const _ActionButton({required this.label, required this.color, required this.onPressed});
  @override Widget build(BuildContext context) {
    return SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))));
  }
}

Widget _buildColoredInfoRow(String imagePath, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [Image.asset(imagePath, width: 24, height: 24, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 24, color: Colors.grey)), const SizedBox(width: 10), Text(text, style: const TextStyle(fontWeight: FontWeight.w600))]),
    ),
  );
}