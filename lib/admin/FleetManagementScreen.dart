// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FleetManagementScreen extends StatefulWidget {
  final String busId; 

  const FleetManagementScreen({super.key, required this.busId});

  @override
  State<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends State<FleetManagementScreen> {
  // --- Styling Constants ---
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              _TopHeader(
                title: "تفاصيل الأسطول",
                onBack: () => Navigator.pop(context),
                onLang: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _MainCardContainer(
                        children: [
                          /// Map Preview Section
                          _MapSection(targetBusID: widget.busId), 

                          const SizedBox(height: 24),

                          /// ✅ Live Fleet Stats Grid (Now with Last Updated time)
                          _buildStatsGrid(),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Buses')
          .doc(widget.busId) 
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;

        // Fallbacks for OBD metrics
        String fuelRate = data['fuelRate']?.toString() ?? "--";
        String mileage = data['mileage']?.toString() ?? "--";
        String battery = data['batteryLevel']?.toString() ?? "--";
        String currentSpeed = data['obdSpeed']?.toString() ?? "0";
        String engineTemp = data['engineTemp']?.toString() ?? "--";
        String engineLoad = data['engineLoad']?.toString() ?? "--";

// ✅ Extract and format the last update timestamp with Date & Time
        String lastUpdatedStr = "غير متوفر";
        if (data['obdLastUpdated'] != null) {
          DateTime dt = (data['obdLastUpdated'] as Timestamp).toDate();
          
          // 1. Format Time
          String amPm = dt.hour >= 12 ? 'مساءً' : 'صباحاً';
          int hour12 = dt.hour % 12;
          if (hour12 == 0) hour12 = 12; 
          String minute = dt.minute.toString().padLeft(2, '0');
          
          // 2. Format Date in Arabic
          List<String> months = [
            'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 
            'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
          ];
          String monthName = months[dt.month - 1];
          
          // Final Format: "6 مايو 2026، 3:27 مساءً"
          lastUpdatedStr = "${dt.day} $monthName ${dt.year}، $hour12:$minute $amPm"; 
        }

        return Column(
          children: [
            // ✅ NEW: Last Updated Indicator Row
            // ✅ NEW: Last Updated Indicator Row (Fixed for Overflow)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.update, size: 16, color: Color(0xFF667085)),
                  const SizedBox(width: 6),
                  Expanded( // ✅ ADDED: Expanded to prevent horizontal overflow
                    child: Text(
                      "آخر تحديث لقراءات الحافلة: $lastUpdatedStr",
                      textAlign: TextAlign.center, // ✅ Centers the wrapped text
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ROW 1: Fuel Consumption & Mileage
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    color: Colors.green[50]!,
                    icon: Icons.local_gas_station,
                    title: "استهلاك الوقود",
                    value: "$fuelRate لتر/س",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    color: Colors.blue[50]!,
                    icon: Icons.map,
                    title: "المسافة المقطوعة",
                    value: "$mileage كم",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // ROW 2: Battery & Speed
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    color: Colors.grey[100]!,
                    icon: Icons.battery_charging_full,
                    title: "نسبة البطارية",
                    value: "$battery%",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    color: Colors.orange[50]!,
                    icon: Icons.speed,
                    title: "السرعة الحالية",
                    value: "$currentSpeed كم/س",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ROW 3: Engine Temp & Load
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    color: Colors.red[50]!,
                    icon: Icons.thermostat,
                    title: "حرارة المحرك",
                    value: "$engineTemp°C",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    color: Colors.purple[50]!,
                    icon: Icons.settings_applications, // Gear icon
                    title: "حمل المحرك",
                    value: "$engineLoad%",
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _infoCard({
    required Color color,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: _kHeaderBlue),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _kHeaderBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      // ❌ REMOVED: height: 85, 
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: SafeArea( // ✅ ADDED: SafeArea
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
              Navigator.pushReplacementNamed(context, '/AdminHome');
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

/* -------------------- Sub-Components -------------------- */

class _MapSection extends StatefulWidget {
  final String targetBusID;
  const _MapSection({required this.targetBusID});

  @override
  State<_MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<_MapSection> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFEDEFF2),
      ),
      clipBehavior: Clip.antiAlias,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Buses')
            .doc(widget.targetBusID)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;

          double lat = data['lat'] ?? 21.4858;
          double lng = data['lng'] ?? 39.1925;
          LatLng busLocation = LatLng(lat, lng);

          _mapController?.animateCamera(CameraUpdate.newLatLng(busLocation));

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: busLocation,
              zoom: 15.0,
            ),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(
                markerId: const MarkerId('bus_marker'),
                position: busLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
              ),
            },
          );
        },
      ),
    );
  }
}

/* -------------------- Generic Project UI Kit -------------------- */

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
      height: 85,
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

          const SizedBox(width: 48),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),

          IconButton(
            onPressed: onLang,
            icon: const Icon(Icons.language, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _MainCardContainer extends StatelessWidget {
  final List<Widget> children;
  const _MainCardContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}