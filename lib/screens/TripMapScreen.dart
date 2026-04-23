// ignore_for_file: file_names, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart'; 
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
  
  bool _isShowingArrivalDialog = false; 
  DateTime? _lastSpeedingEventTime;
  String _tripStatus = 'لم تبدأ'; // ✅ Tracks real status from Firestore

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

  String _estimatedTime = "جاري الحساب...";

  final Set<String> _scannedStudentIds = {};

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

      // ✅ Fetch the current trip status from Firestore
      final busDoc = await FirebaseFirestore.instance.collection('Buses').doc(widget.busId).get();
      if (busDoc.exists) {
        String statusField = widget.isMorningTrip ? 'morningTripStatus' : 'afternoonTripStatus';
        _tripStatus = busDoc.data()?[statusField] ?? 'لم تبدأ';
      }

      _schoolModel = await _tripPinsService.getSchoolLocationForBus(widget.busId);
      if (_schoolModel == null) {
        debugPrint("CRITICAL: School model returned null.");
      }

      final List<StudentPinModel> rawStudents = await _tripPinsService.getPresentStudentsData(widget.busId);
      List<StudentPinModel> pendingStudents = [];

      for (var student in rawStudents) {
        if (student.lat == 0.0 && student.lng == 0.0) continue;

        final studentDoc = await FirebaseFirestore.instance
            .collection('Students')
            .doc(student.studentId)
            .get();

        final status = studentDoc.data()?['busStatus'] ?? '';

        // ✅ سحب رقم الجوال لولي الأمر لاستخدامه في الإشعارات
        student.parentPhone = studentDoc.data()?['parentPhone'] ?? '';

        // ✅ Determine if the stop is complete based on trip type
        bool isStopCompleted = widget.isMorningTrip 
            ? status == 'في الحافلة' 
            : status == 'في المنزل';  

        if (!isStopCompleted) {
          pendingStudents.add(student);
        } else {
          _scannedStudentIds.add(student.studentId);
        }
      }

      final markers = _tripPinsService.getMarkersFromList(pendingStudents);

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

      _busMarker = Marker(
        markerId: const MarkerId("bus_location"),
        position: _currentBusLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: "موقعي الحالي"),
      );
      markers.add(_busMarker!);

      if (mounted) {
        setState(() {
          _students = pendingStudents; 
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
    double minLng = positions.first.longitude, maxLng = positions.first.longitude;
    
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

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);

      // 1. Update Map for Driver
      if (mounted) {
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
      }

      // 2. Send coordinates to Firebase
      FirebaseFirestore.instance.collection('Buses').doc(widget.busId).set({
        'lat': position.latitude,
        'lng': position.longitude,
        'LastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Geofencing check
      _checkArrivalProximity(newLocation);
      _checkWarningProximity(newLocation); // ✅ استدعاء فحص تنبيه الاقتراب

      // 4. Speeding check
      _checkSpeeding(position);
    });
  }

  // ✅ الدالة الجديدة لفحص الاقتراب وإرسال تنبيه "الحافلة تقترب"
  void _checkWarningProximity(LatLng currentLoc) {
    if (!widget.isMorningTrip) return;

    for (var student in _students) {
      if (student.isNearNotificationSent || student.parentPhone.isEmpty) continue;

      double distance = Geolocator.distanceBetween(
        currentLoc.latitude, currentLoc.longitude,
        student.lat, student.lng,
      );

      if (distance <= 500.0) {
        student.isNearNotificationSent = true; 

        FirebaseFirestore.instance.collection('LiveNotifications').add({
          'type': 'individual',
          'targetPhone': student.parentPhone,
          'title': 'الحافلة تقترب! 🚌',
          'body': 'حافلة ${student.name} تقترب من المنزل. يرجى الاستعداد.',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // ============================================================
  // SPEED TRACKING LOGIC
  // ============================================================
  void _checkSpeeding(Position position) {
    double speedKmh = position.speed * 3.6;
    double speedLimit = 80.0; 

    if (speedKmh > speedLimit) {
      DateTime now = DateTime.now();

      if (_lastSpeedingEventTime == null || now.difference(_lastSpeedingEventTime!).inMinutes >= 3) {
        _lastSpeedingEventTime = now;

        FirebaseFirestore.instance
            .collection('Buses')
            .doc(widget.busId)
            .collection('DrivingEvents')
            .add({
          'type': 'Speeding',
          'speed': double.parse(speedKmh.toStringAsFixed(1)),
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        });

        debugPrint("🚨 Speeding event logged: ${speedKmh.toStringAsFixed(1)} km/h");
      }
    }
  }

  // ============================================================
  // GEOFENCING & SCANNER LOGIC
  // ============================================================
  void _checkArrivalProximity(LatLng currentLoc) {
    if (_isShowingArrivalDialog) return;

    for (var student in _students) {
      if (_scannedStudentIds.contains(student.studentId)) continue;

      double distance = Geolocator.distanceBetween(
        currentLoc.latitude,
        currentLoc.longitude,
        student.lat,
        student.lng,
      );

      if (distance <= 50.0) {
        setState(() => _isShowingArrivalDialog = true); 
        _positionStreamSubscription?.pause();
        _showArrivalDialog(student);
        break;
      }
    }
  }

  void _showArrivalDialog(StudentPinModel student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("وصلت للموقع", textAlign: TextAlign.right),
        content: Text("أنت الآن عند منزل الطالب: ${student.name}.\nالرجاء مسح الـ QR الخاص به.", textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () { 
              Navigator.pop(ctx); 
              setState(() => _isShowingArrivalDialog = false); 
              _positionStreamSubscription?.resume(); 
            }, 
            child: const Text("تخطي"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              final String? result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const QRScannerScreen()),
              );

              setState(() => _isShowingArrivalDialog = false); 

              if (result != null && result.trim() == student.studentId.trim()) {
                _handleSuccessfulScan(student);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("الرمز غير مطابق!"), backgroundColor: Colors.red),
                  );
                }
                _positionStreamSubscription?.resume();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A994E)),
            child: const Text("فتح الكاميرا", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSuccessfulScan(StudentPinModel student) async {
    // ✅ Set the correct status based on the trip direction
    String newStatus = widget.isMorningTrip ? 'في الحافلة' : 'في المنزل';

    await FirebaseFirestore.instance
        .collection('Students')
        .doc(student.studentId)
        .update({
          'busStatus': newStatus,
          'lastScanTime': FieldValue.serverTimestamp(),
        });

    if (mounted) {
      setState(() {
        _scannedStudentIds.add(student.studentId);
        _students.removeWhere((s) => s.studentId == student.studentId);
        _markers.removeWhere((m) => m.markerId.value == student.studentId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم تأكيد صعود الطالب: ${student.name}"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (_scannedStudentIds.length % 9 == 0 && _scannedStudentIds.isNotEmpty) {
      _showBatchCompleteAlert();
    } else {
      _getRoutePolyline();
      _positionStreamSubscription?.resume();
    }
  }

  void _showBatchCompleteAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("اكتملت المجموعة", textAlign: TextAlign.right),
        content: const Text(
          "تم جمع جميع طلاب المجموعة. اضغط 'المجموعة التالية' للبدء في المسار القادم.",
          textAlign: TextAlign.right,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _positionStreamSubscription?.resume();
            },
            child: const Text("حسناً"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTripAction() async {
    if (widget.busId.isEmpty) return;
    try {
      if (_schoolModel == null || _currentBusLocation == null) return;

      await _updateBusStatus("جارية الآن");

      // ✅ إشعار جماعي ببدء العودة للمنزل
      if (!widget.isMorningTrip && _tripNavigationService.currentBatchIndex == 0) {
        FirebaseFirestore.instance.collection('LiveNotifications').add({
          'type': 'broadcast',
          'busId': widget.busId,
          'title': 'بدء رحلة العودة 🚌',
          'body': 'صعد الطلاب إلى الحافلة وهم في طريقهم إلى المنزل الآن.',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _tripNavigationService.startSmartNavigation(
        driverLat: _currentBusLocation!.latitude,
        driverLng: _currentBusLocation!.longitude,
        students: _students,
        school: _schoolModel!,
        isMorningTrip: widget.isMorningTrip,
      );
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("NAV_ERROR: $e");
    }
  }

  Future<void> _getRoutePolyline() async {
    if (_students.isEmpty || _schoolModel == null || _currentBusLocation == null) return;
    
    try {
      PointLatLng origin = PointLatLng(_currentBusLocation!.latitude, _currentBusLocation!.longitude);
      PointLatLng destination = widget.isMorningTrip
          ? PointLatLng(_schoolModel!.lat, _schoolModel!.lng)
          : PointLatLng(_students.last.lat, _students.last.lng);
          
      List<PolylineWayPoint> wayPoints = _students.map((s) => PolylineWayPoint(location: "${s.lat},${s.lng}")).toList();
      
      String originStr = "${origin.latitude},${origin.longitude}";
      String destStr = "${destination.latitude},${destination.longitude}";
      String wayStr = wayPoints.map((w) => w.location).join('|');
      String apiKey = 'AIzaSyASw9kOAjo6lWB5OX7oFFGU40CCGFPVJYY';
      String url = "https://maps.googleapis.com/maps/api/directions/json?origin=$originStr&destination=$destStr&waypoints=$wayStr&mode=driving&optimizeWaypoints=true&key=$apiKey";
      
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
                points: result.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Polyline Error: $e");
    }
  }

  Future<void> _updateBusStatus(String status) async {
    try {
      String fieldToUpdate = widget.isMorningTrip 
          ? 'morningTripStatus' 
          : 'afternoonTripStatus';

      await FirebaseFirestore.instance
          .collection('Buses')
          .doc(widget.busId)
          .update({
            fieldToUpdate: status,
            'LastUpdated': FieldValue.serverTimestamp(),
          });

      // ✅ إشعار جماعي بالوصول للمدرسة
      if (widget.isMorningTrip && status == "مكتملة") {
        FirebaseFirestore.instance.collection('LiveNotifications').add({
          'type': 'broadcast',
          'busId': widget.busId,
          'title': 'الوصول للمدرسة 🏫',
          'body': 'تم وصول الحافلة إلى المدرسة بسلام.',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // ✅ Update the local state so the UI button reacts instantly
      if (mounted) {
        setState(() {
          _tripStatus = status;
        });
      }
    } catch (e) {
      debugPrint("DB Error: $e");
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
                      initialCameraPosition: const CameraPosition(target: _initialPosition, zoom: 12),
                      myLocationEnabled: true,
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
    bool isFinishedLocally = _tripNavigationService.currentBatchIndex == 999;
    bool isCompleted = _tripStatus == 'مكتملة' || isFinishedLocally;

    // ✅ Determine button text based on the database's source of truth
    String buttonText;
    if (isCompleted) {
      buttonText = "اكتملت الرحلة";
    } else if (_tripStatus == 'جارية الآن') {
      buttonText = _tripNavigationService.currentBatchIndex == 0
          ? "متابعة الرحلة"
          : "المجموعة التالية";
    } else {
      buttonText = "بدء الرحلة";
    }

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
          _buildInfoRow(Icons.access_time, "الوقت المتوقع: $_estimatedTime"),
          _buildColoredInfoRow('assets/placeholder.png', "عدد التوقفات: ${_students.length}"),
          const SizedBox(height: 20),
          _ActionButton(
            label: "تفاصيل التوقفات",
            color: const Color(0xFFFFC107),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TripDetailsScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ActionButton(
            label: buttonText,
            color: isCompleted ? Colors.grey : const Color(0xFF6A994E),
            onPressed: isCompleted ? () {} : _handleTripAction,
          ),
          const SizedBox(height: 10),
          _ActionButton(
            label: "إنهاء الرحلة",
            color: const Color(0xFFD64545),
            onPressed: () async {
              await _updateBusStatus("مكتملة");
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
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
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _kHeaderBlue,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        currentIndex: 0, // Home icon remains highlighted
        onTap: (index) {
          if (index == 0) {
            // Safely return to the Driver Home Screen
            Navigator.pop(context); 
          } else if (index == 1) {
            // Navigate to the Profile / Role selection
            Navigator.pushReplacementNamed(context, '/role_home');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 28),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded, size: 28),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }
}

// ✅ SCANNER UI CLASS
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});
  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _found = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مسح رمز الطالب"),
        backgroundColor: const Color(0xFF0D1B36),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_found) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              _found = true;
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
  const _ActionButton({required this.label, required this.color, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

Widget _buildColoredInfoRow(String imagePath, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.people, size: 24, color: Colors.grey),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}