// ignore_for_file: file_names
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ChildTrackingScreen extends StatefulWidget {
  const ChildTrackingScreen({super.key});

  @override
  State<ChildTrackingScreen> createState() => _ChildTrackingScreenState();
}

class _ChildTrackingScreenState extends State<ChildTrackingScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kCard = Colors.white;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return const Scaffold(body: Center(child: Text("لا توجد بيانات")));
    }

    final studentId = (args['StudentID'] ?? '').toString();
    if (studentId.trim().isEmpty) {
      return const Scaffold(body: Center(child: Text("studentId غير موجود")));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('Students').doc(studentId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("تم حذف البيانات بنجاح"));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final nameAr = (data['StudentName_ar'] ?? '').toString();
              final nameEn = (data['StudentName'] ?? '').toString();
              final parentPhone = (data['parentPhone'] ?? '').toString();

              final schoolId = (data['SchoolID'] ?? '').toString();
              final busNum = (data['BusID'] ?? '').toString();
              final fullBusId = schoolId.isNotEmpty && busNum.isNotEmpty
                  ? 'Bus_${schoolId}_$busNum'
                  : 'Bus_32438_101';

              final childName = nameAr.isNotEmpty ? nameAr : nameEn;
              final displayName = childName.isEmpty ? "طالب" : childName;

              // ✅ Shift to tomorrow after 7 PM and enforce English numerals for Firebase
              DateTime targetDate = DateTime.now();
              if (targetDate.hour >= 19) {
                targetDate = targetDate.add(const Duration(days: 1));
              }
              final targetDateStr = DateFormat('yyyy-MM-dd', 'en_US').format(targetDate);

              return Column(
                children: [
                  _TopHeader(
                    title: "تتبع الابن",
                    onBack: () => Navigator.pop(context),
                    onLang: () {},
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 6),
                                _UserAvatarFromFirestore(parentPhone: parentPhone),
                                const SizedBox(height: 12),
                                Text(
                                  displayName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF101828),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ✅ LISTENING TO TODAY'S ATTENDANCE FOR LIVE STATUS & TIMELINE
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('Attendance')
                                      .doc(targetDateStr)
                                      .collection('PresentStudents')
                                      .doc(studentId)
                                      .snapshots(),
                                  builder: (context, attSnap) {
                                    
                                    // Default Fallback States (Start of the day)
                                    String currentStatus = "غائب";
                                    String dailyBusStatus = "في انتظار الحافلة";
                                    String dailyFormattedTime = "";

                                    if (attSnap.hasData && attSnap.data!.exists) {
                                      final attData = attSnap.data!.data() as Map<String, dynamic>;
                                      
                                      // 1. Get Attendance Status (Present/Absent)
                                      currentStatus = (attData['attendanceStatus'] ?? "غائب").toString();
                                      
                                      // 2. Get Today's Bus Status
                                      dailyBusStatus = (attData['busStatus'] ?? "في انتظار الحافلة").toString();

                                      // 3. Get Today's Exact Scan Time
                                      final Timestamp? dailyScanTime = attData['lastScanTime'] as Timestamp?;
                                      if (dailyScanTime != null) {
                                        dailyFormattedTime = DateFormat('hh:mm a')
                                            .format(dailyScanTime.toDate())
                                            .replaceAll("AM", "صباحاً")
                                            .replaceAll("PM", "مساءً");
                                      }
                                    }

                                    return Column(
                                      children: [
                                        // The Present/Absent Pill
                                        AttendanceStatusPill(status: currentStatus),
                                        
                                        const SizedBox(height: 24),
                                        
                                        // The QR Code Button
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _showQrCodeDialog(context, studentId),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.qr_code_2_rounded, color: _kHeaderBlue, size: 26),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "عرض رمز صعود الحافلة",
                                                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _kHeaderBlue),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 24),
                                        const Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            "تتبع الابن",
                                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF475467)),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // The Live Map
                                        _MapPreview(fullBusId: fullBusId, schoolId: schoolId),

                                        const SizedBox(height: 12),

                                        // ✅ The Timeline (Now reading from daily Attendance!)
                                        _LiveTimeline(
                                          busStatus: dailyBusStatus,
                                          formattedScanTime: dailyFormattedTime,
                                          schoolId: schoolId,
                                          fullBusId: fullBusId,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  void _showQrCodeDialog(BuildContext context, String studentId) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "رمز صعود الحافلة (QR Code)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF101828)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "يرجى طباعة هذا الرمز لإبرازه للسائق عند صعود الحافلة يومياً.",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475467)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEE4E2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFD92D20), size: 24),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "تنبيه هام: يجب أن يكون هذا الرمز بحوزة الطالب لتجنب تسجيله كـ غائب.",
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFB42318), height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    ),
                    child: QrImageView(
                      data: studentId,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kHeaderBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "إغلاق",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: SafeArea( 
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _kHeaderBlue,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          currentIndex: 0,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/parent_home');
            } else if (index == 1) {
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
      ),
    );
  }
}

// =========================================================================
// ✅ STATE-DRIVEN TIMELINE (With Geofencing)
// =========================================================================
class _LiveTimeline extends StatefulWidget {
  final String busStatus;
  final String formattedScanTime;
  final String schoolId;
  final String fullBusId;

  const _LiveTimeline({
    required this.busStatus,
    required this.formattedScanTime,
    required this.schoolId,
    required this.fullBusId,
  });

  @override
  State<_LiveTimeline> createState() => _LiveTimelineState();
}

class _LiveTimelineState extends State<_LiveTimeline> {
  double? schoolLat;
  double? schoolLng;

  @override
  void initState() {
    super.initState();
    _fetchSchoolLocation();
  }

  // Fetch the school coordinates to use as our geofence target
  Future<void> _fetchSchoolLocation() async {
    if (widget.schoolId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('Schools').doc(widget.schoolId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            var rawLat = data['Latitude '] ?? data['Latitude'] ?? data['lat'];
            var rawLng = data['Longtitude '] ?? data['Longtitude'] ?? data['Longitude '] ?? data['Longitude'] ?? data['lng'];
            schoolLat = rawLat != null ? double.tryParse(rawLat.toString()) : null;
            schoolLng = rawLng != null ? double.tryParse(rawLng.toString()) : null;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching school for timeline: $e");
    }
  }

  // Calculate distance in meters using the Haversine formula
  bool _isNearSchool(double busLat, double busLng) {
    if (schoolLat == null || schoolLng == null) return false;
    var R = 6371e3; // Earth radius in meters
    var phi1 = busLat * math.pi / 180;
    var phi2 = schoolLat! * math.pi / 180;
    var deltaPhi = (schoolLat! - busLat) * math.pi / 180;
    var deltaLambda = (schoolLng! - busLng) * math.pi / 180;

    var a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    var c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    var d = R * c;

    // Trigger arrival if the bus is within 150 meters of the school
    return d <= 150;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('Buses').doc(widget.fullBusId).snapshots(),
      builder: (context, snapshot) {
        bool isMorningTrip = true; // ⚠️ FOR DEMO: Forced to Morning Trip

        // Base states
        bool isBoarded = false;
        bool isOnWay = false;
        bool isArrived = false;

        // Static Titles so the UI feels like a consistent journey
        String step1Title = "صعود الحافلة (من المنزل)";
        String step2Title = "في الطريق إلى المدرسة";
        String step3Title = "الوصول للمدرسة";

        String step1Time = "في انتظار الحافلة...";
        String step2Time = "";
        String step3Time = "";

        if (snapshot.hasData && snapshot.data!.exists) {
          final busData = snapshot.data!.data() as Map<String, dynamic>;
          String morningStatus = busData['morningTripStatus'] ?? 'لم تبدأ';

          // Safely parse bus coordinates
          double busLat = double.tryParse((busData['lat'] ?? 0.0).toString()) ?? 0.0;
          double busLng = double.tryParse((busData['lng'] ?? 0.0).toString()) ?? 0.0;

          if (isMorningTrip) {
            // ================== 1. BOARDING LOGIC ==================
            isBoarded = widget.busStatus == "في الحافلة";
            if (isBoarded) {
              step1Title = "تم صعود الحافلة";
              step1Time = "الساعة: ${widget.formattedScanTime}";
            }

            // ================== 2. EN ROUTE LOGIC ==================
            // ✅ ONLY turns green if the child is actually boarded!
            if (morningStatus == 'جارية الآن' && isBoarded) {
              isOnWay = true;
              step2Time = "يتحرك الآن...";
            }

            // ================== 3. ARRIVAL LOGIC ===================
            // Check geofence first. If near school, force arrival state.
            if (isOnWay && busLat != 0.0 && busLng != 0.0) {
              if (_isNearSchool(busLat, busLng)) {
                isArrived = true;
                isOnWay = false; // Turn off the "moving" indicator
                step2Time = "";
                step3Time = "تم الوصول للمدرسة";
              }
            }
            // Fallback: Just in case the driver pressed 'Complete' before the GPS caught up
            else if (morningStatus == 'مكتملة' && isBoarded) {
              isArrived = true;
              isOnWay = false;
              step2Time = "";
              step3Time = "تم الوصول بنجاح";
            }
          }
        }

        return _TimelineCard(
          items: [
            _TimelineRowData(
              title: step1Title,
              time: step1Time,
              dotColor: isBoarded ? const Color(0xFF7CB342) : Colors.grey.shade400,
              icon: Icons.location_on,
            ),
            _TimelineRowData(
              title: step2Title,
              time: step2Time,
              dotColor: (isOnWay || isArrived) ? const Color(0xFF7CB342) : const Color(0xFFE2E8F0),
              icon: Icons.directions_bus,
            ),
            _TimelineRowData(
              title: step3Title,
              time: step3Time,
              dotColor: isArrived ? const Color(0xFF7CB342) : const Color(0xFFE2E8F0),
              icon: Icons.school,
            ),
          ],
        );
      },
    );
  }
}

// =========================================================================

class AttendanceStatusPill extends StatelessWidget {
  final String status;
  const AttendanceStatusPill({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    final s = status.trim();
    final bool isPresent = s == "حاضر";
    final bool isAbsent = s == "غائب";
    final Color bg = isPresent
        ? const Color(0xFFB7E4C7)
        : isAbsent
            ? const Color(0xFFF3B7B7)
            : const Color(0xFFE5E7EB);
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: Container(
        height: 44,
        width: 220,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          status,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Color(0xFF0B1220),
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack, onLang;
  const _TopHeader({
    required this.title,
    required this.onBack,
    required this.onLang,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onLang,
            icon: const Icon(Icons.language, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _UserAvatarFromFirestore extends StatelessWidget {
  final String parentPhone;
  const _UserAvatarFromFirestore({required this.parentPhone});
  @override
  Widget build(BuildContext context) {
    if (parentPhone.trim().isEmpty) return _fallbackAvatar();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(parentPhone).snapshots(),
      builder: (context, snap) {
        String photoUrl = "";
        if (snap.hasData && snap.data!.exists) {
          photoUrl = (snap.data!.data() as Map<String, dynamic>)['photoUrl'] ?? '';
        }
        if (photoUrl.isEmpty) return _fallbackAvatar();
        return Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: Color(0xFFE6E6E6),
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
          ),
        );
      },
    );
  }

  Widget _fallbackAvatar() => Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          color: Color(0xFFE6E6E6),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.person, size: 60, color: Colors.white),
      );
}

// Dynamic MapPreview that completely hides the Bus pin if the trip isn't active
class _MapPreview extends StatefulWidget {
  final String fullBusId;
  final String schoolId;
  const _MapPreview({required this.fullBusId, required this.schoolId});
  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  GoogleMapController? _mapController;
  double? schoolLat;
  double? schoolLng;

  @override
  void initState() {
    super.initState();
    _fetchSchoolLocation();
  }

  Future<void> _fetchSchoolLocation() async {
    if (widget.schoolId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('Schools').doc(widget.schoolId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            var rawLat = data['Latitude '] ?? data['Latitude'] ?? data['lat'];
            var rawLng = data['Longtitude '] ?? data['Longtitude'] ?? data['Longitude '] ?? data['Longitude'] ?? data['lng'];

            schoolLat = rawLat != null ? double.tryParse(rawLat.toString()) : null;
            schoolLng = rawLng != null ? double.tryParse(rawLng.toString()) : null;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching school for map: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFEDEFF2),
      ),
      clipBehavior: Clip.antiAlias,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('Buses').doc(widget.fullBusId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String morningStatus = data['morningTripStatus'] ?? 'لم تبدأ';
          String afternoonStatus = data['afternoonTripStatus'] ?? 'لم تبدأ';

          bool isTripActive = (morningStatus == 'جارية الآن' || afternoonStatus == 'جارية الآن');

          LatLng targetLocation;
          Marker targetMarker;

          if (!isTripActive && schoolLat != null && schoolLng != null) {
            targetLocation = LatLng(schoolLat!, schoolLng!);
            targetMarker = Marker(
              markerId: const MarkerId('school_marker'),
              position: targetLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: const InfoWindow(title: "المدرسة"),
            );
          } else {
            double lat = data['lat'] ?? 0.0;
            double lng = data['lng'] ?? 0.0;
            targetLocation = LatLng(lat, lng);
            targetMarker = Marker(
              markerId: const MarkerId('bus_marker'),
              position: targetLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              infoWindow: const InfoWindow(title: "موقع الحافلة"),
            );
          }

          _mapController?.animateCamera(CameraUpdate.newLatLng(targetLocation));

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: targetLocation,
              zoom: 15.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {targetMarker},
          );
        },
      ),
    );
  }
}

class _TimelineRowData {
  final String title, time;
  final Color dotColor;
  final IconData icon;
  const _TimelineRowData({
    required this.title,
    required this.time,
    required this.dotColor,
    required this.icon,
  });
}

class _TimelineCard extends StatelessWidget {
  final List<_TimelineRowData> items;
  const _TimelineCard({required this.items});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: item.dotColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 14, color: item.dotColor),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 34,
                      margin: const EdgeInsets.only(top: 6),
                      color: const Color(0xFFE5E7EB),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF344054),
                          fontSize: 13.5,
                        ),
                      ),
                      if (item.time.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.time,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF98A2B3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}