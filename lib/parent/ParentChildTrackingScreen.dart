// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParentChildTrackingScreen extends StatefulWidget {
  const ParentChildTrackingScreen({super.key});

  @override
  State<ParentChildTrackingScreen> createState() => _ParentChildTrackingScreenState();
}

class _ParentChildTrackingScreenState extends State<ParentChildTrackingScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kCard = Colors.white;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

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
            stream: FirebaseFirestore.instance
                .collection('Students')
                .doc(studentId)
                .snapshots(),
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
              final busStatus = (data['busStatus'] ?? 'في المنزل').toString();
              final Timestamp? scanTime = data['lastScanTime'] as Timestamp?;

              final schoolId = (data['SchoolID'] ?? '').toString();
              final busNum = (data['BusID'] ?? '').toString();
              final fullBusId = schoolId.isNotEmpty && busNum.isNotEmpty
                  ? 'Bus_${schoolId}_$busNum'
                  : 'Bus_32438_101';

              final childName = nameAr.isNotEmpty ? nameAr : nameEn;
              final displayName = childName.isEmpty ? "طالب" : childName;
              final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

              String formattedScanTime = "";
              if (scanTime != null) {
                formattedScanTime = DateFormat('hh:mm a')
                    .format(scanTime.toDate())
                    .replaceAll("AM", "صباحاً")
                    .replaceAll("PM", "مساءً");
              }

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
                                _UserAvatarFromFirestore(
                                  parentPhone: parentPhone,
                                ),
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

                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('Attendance')
                                      .doc(todayDate)
                                      .collection('PresentStudents')
                                      .doc(studentId)
                                      .snapshots(),
                                  builder: (context, attSnap) {
                                    String currentStatus = "غائب";
                                    if (attSnap.hasData &&
                                        attSnap.data!.exists) {
                                      final attData =
                                          attSnap.data!.data()
                                              as Map<String, dynamic>;
                                      currentStatus =
                                          (attData['attendanceStatus'] ??
                                                  "غائب")
                                              .toString();
                                    }
                                    return AttendanceStatusPill(
                                      status: currentStatus,
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () =>
                                        _showQrCodeDialog(context, studentId),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.qr_code_2_rounded,
                                            color: _kHeaderBlue,
                                            size: 26,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "عرض رمز صعود الحافلة",
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: _kHeaderBlue,
                                            ),
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
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF475467),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                _MapPreview(
                                  fullBusId: fullBusId,
                                  schoolId: schoolId,
                                ),

                                const SizedBox(height: 12),

                                // ✅ Updated Timeline (No Geolocator needed)
                                _LiveTimeline(
                                  busStatus: busStatus,
                                  formattedScanTime: formattedScanTime,
                                  schoolId: schoolId,
                                  fullBusId: fullBusId,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "رمز صعود الحافلة (QR Code)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF101828),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "يرجى طباعة هذا الرمز لإبرازه للسائق عند صعود الحافلة يومياً.",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475467),
                    ),
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
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFD92D20),
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "تنبيه هام: يجب أن يكون هذا الرمز بحوزة الطالب لتجنب تسجيله كـ غائب.",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB42318),
                              height: 1.5,
                            ),
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
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "إغلاق",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
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
    );
  }
}

// =========================================================================
// ✅ STATE-DRIVEN TIMELINE (No Geofencing)
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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Buses')
          .doc(widget.fullBusId)
          .snapshots(),
      builder: (context, snapshot) {
        bool isMorningTrip = DateTime.now().hour < 11;

        // Base states
        bool isBoarded = false;
        bool isOnWay = false;
        bool isArrived = false;

        // Dynamic Titles & Icons
        String step1Title = isMorningTrip
            ? "تم صعود الباص (من المنزل)"
            : "تم صعود الباص (من المدرسة)";
        String step2Title = isMorningTrip
            ? "في الطريق إلى المدرسة"
            : "في الطريق إلى المنزل";
        String step3Title = isMorningTrip ? "الوصول للمدرسة" : "الوصول للمنزل";

        String step1Time = "";
        String step2Time = "";
        String step3Time = "";

        IconData icon1 = Icons.location_on;
        IconData icon2 = Icons.directions_bus;
        IconData icon3 = isMorningTrip ? Icons.school : Icons.home;

        if (snapshot.hasData && snapshot.data!.exists) {
          final busData = snapshot.data!.data() as Map<String, dynamic>;
          String morningStatus = busData['morningTripStatus'] ?? 'لم تبدأ';
          String afternoonStatus = busData['afternoonTripStatus'] ?? 'لم تبدأ';

          if (isMorningTrip) {
            // ================== MORNING LOGIC ==================
            // Relies completely on driver scanning the QR and pressing buttons
            isBoarded = widget.busStatus == "في الحافلة";

            if (isBoarded) {
              step1Time = "الساعة : ${widget.formattedScanTime}";

              if (morningStatus == 'جارية الآن') {
                isOnWay = true;
                step2Time = "يتحرك الآن...";
              } else if (morningStatus == 'مكتملة') {
                // Driver pressed end trip at the school
                isArrived = true;
                isOnWay = false;
                step2Time = "";
                step3Time = "تم الوصول بنجاح";
              }
            }
          } else {
            // ================== AFTERNOON LOGIC ==================
            if (afternoonStatus == 'لم تبدأ') {
              step1Title = "الطالب متواجد في المدرسة";
              step1Time = "بانتظار رحلة العودة...";
              isBoarded = true;
              icon1 = Icons.school;
            } else if (afternoonStatus == 'جارية الآن' ||
                afternoonStatus == 'مكتملة' ||
                widget.busStatus == 'في المنزل') {
              // Driver pressed start trip at the school
              isBoarded = true;
              step1Title = "تم صعود الباص (من المدرسة)";
              step1Time = "تم التجمع والصعود";

              if (widget.busStatus != 'في المنزل') {
                if (afternoonStatus == 'جارية الآن') {
                  isOnWay = true;
                  step2Time = "يتحرك الآن...";
                }
              }
            }

            // Student successfully scanned at their house
            if (widget.busStatus == 'في المنزل' &&
                afternoonStatus != 'لم تبدأ') {
              isBoarded = true;
              isOnWay = false;
              isArrived = true;
              step2Time = "";
              step3Time = "الساعة : ${widget.formattedScanTime}";
            }
          }
        }

        return _TimelineCard(
          items: [
            _TimelineRowData(
              title: isBoarded ? step1Title : "في انتظار الحافلة",
              time: step1Time,
              dotColor: isBoarded ? const Color(0xFF7CB342) : Colors.grey,
              icon: icon1,
            ),
            _TimelineRowData(
              title: step2Title,
              time: step2Time,
              dotColor: (isOnWay || isArrived)
                  ? const Color(0xFF7CB342)
                  : const Color(0xFFE2E8F0),
              icon: icon2,
            ),
            _TimelineRowData(
              title: step3Title,
              time: step3Time,
              dotColor: isArrived
                  ? const Color(0xFF7CB342)
                  : const Color(0xFFE2E8F0),
              icon: icon3,
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
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(parentPhone)
          .snapshots(),
      builder: (context, snap) {
        String photoUrl = "";
        if (snap.hasData && snap.data!.exists) {
          photoUrl =
              (snap.data!.data() as Map<String, dynamic>)['photoUrl'] ?? '';
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
      final doc = await FirebaseFirestore.instance
          .collection('Schools')
          .doc(widget.schoolId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            // ✅ Bulletproof checks for trailing spaces, typos, and standard names
            var rawLat = data['Latitude '] ?? data['Latitude'] ?? data['lat'];
            var rawLng =
                data['Longtitude '] ??
                data['Longtitude'] ??
                data['Longitude '] ??
                data['Longitude'] ??
                data['lng'];

            // Safely convert whatever it finds into a double
            schoolLat = rawLat != null
                ? double.tryParse(rawLat.toString())
                : null;
            schoolLng = rawLng != null
                ? double.tryParse(rawLng.toString())
                : null;
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
        stream: FirebaseFirestore.instance
            .collection('Buses')
            .doc(widget.fullBusId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String morningStatus = data['morningTripStatus'] ?? 'لم تبدأ';
          String afternoonStatus = data['afternoonTripStatus'] ?? 'لم تبدأ';

          // ✅ Check if ANY trip is actively moving
          bool isTripActive =
              (morningStatus == 'جارية الآن' ||
              afternoonStatus == 'جارية الآن');

          LatLng targetLocation;
          Marker targetMarker;

          // ✅ If no trip is actively running, default to the school pin ONLY
          if (!isTripActive && schoolLat != null && schoolLng != null) {
            targetLocation = LatLng(schoolLat!, schoolLng!);
            targetMarker = Marker(
              markerId: const MarkerId('school_marker'),
              position: targetLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: const InfoWindow(title: "المدرسة"),
            );
          } else {
            // ✅ Only display the bus pin if the trip is actively "جارية الآن"
            double lat = data['lat'] ?? 0.0;
            double lng = data['lng'] ?? 0.0;
            targetLocation = LatLng(lat, lng);
            targetMarker = Marker(
              markerId: const MarkerId('bus_marker'),
              position: targetLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
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
