// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FleetManagementScreen extends StatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  State<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends State<FleetManagementScreen> {
  // --- Styling Constants ---
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);

  int selectedTab = 0; // 0 = يومي, 1 = شهري

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
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _MainCardContainer(
                        children: [
                          /// Map Preview Section
                          _MapSection(),

                          const SizedBox(height: 24),

                          /// Day/Month Toggle
                          _segmentedTabs(),

                          const SizedBox(height: 24),

                          /// Fleet Stats Grid
                          _buildStatsGrid(),

                          // ✅ Added Divider for section distinction
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF2F3F5),
                            ),
                          ),

                          /// Driver Behavior Section
                          _SectionHeader(title: "سلوك السائق"),
                          _DriverBehaviorCard(selectedTab: selectedTab),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(context), // ✅ Standardized Labeled Toolbar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _infoCard(
                color: Colors.green[50]!,
                icon: Icons.local_gas_station,
                title: "خزان الوقود",
                value: "45%",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                color: Colors.blue[50]!,
                icon: Icons.speed,
                title: "المسافة المقطوعة",
                value: "342 كم",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _infoCard(
                color: Colors.grey[100]!,
                icon: Icons.battery_charging_full,
                title: "نسبة البطارية",
                value: "70%",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                color: Colors.red[50]!,
                icon: Icons.oil_barrel,
                title: "زيت المحرك",
                value: "متبقي 1756 كم",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _segmentedTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(children: [_tabItem("يومي", 0), _tabItem("شهري", 1)]),
    );
  }

  Widget _tabItem(String label, int index) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? _kHeaderBlue : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
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

  // ✅ New Standardized Bottom Navigation with Titles
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
        currentIndex: 0, // Home active
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
    );
  }
}

/* -------------------- Sub-Components -------------------- */

class _MapSection extends StatefulWidget {
  @override
  State<_MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<_MapSection> {
  GoogleMapController? _mapController;

  // 💡 Note: Currently hardcoded to one bus for parity with ManageChildScreen.
  // In a full Fleet Management view, you might want to pass this in dynamically
  // or query ALL active buses to show multiple markers!
  final String targetBusID = "Bus_32438_101";

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180, // Slightly taller for better visibility
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFEDEFF2),
      ),
      clipBehavior:
          Clip.antiAlias, // Important: Keeps the map inside the rounded borders
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Buses')
            .doc(targetBusID)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;

          // Fallback coordinates in case they are missing (Jeddah, SA)
          double lat = data['lat'] ?? 21.4858;
          double lng = data['lng'] ?? 39.1925;
          LatLng busLocation = LatLng(lat, lng);

          // Animate the camera whenever the Firestore location updates
          _mapController?.animateCamera(CameraUpdate.newLatLng(busLocation));

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: busLocation,
              zoom: 15.0,
            ),
            myLocationButtonEnabled: false,
            zoomControlsEnabled:
                false, // Keeps the UI clean inside the small card
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

class _DriverBehaviorCard extends StatelessWidget {
  final int selectedTab; // 0 = يومي, 1 = شهري
  final String targetBusID = "Bus_32438_101"; // Make sure this matches your map!

  const _DriverBehaviorCard({required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    // 1. Calculate the starting date based on the selected tab
    DateTime now = DateTime.now();
    DateTime startDate;
    if (selectedTab == 0) {
      // Daily: Start of today
      startDate = DateTime(now.year, now.month, now.day);
    } else {
      // Monthly: Start of this month
      startDate = DateTime(now.year, now.month, 1);
    }

    return StreamBuilder<QuerySnapshot>(
      // 2. Query Firestore for Speeding events from the chosen date onwards
      stream: FirebaseFirestore.instance
          .collection('Buses')
          .doc(targetBusID)
          .collection('DrivingEvents')
          .where('type', isEqualTo: 'Speeding')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .snapshots(),
      builder: (context, snapshot) {
        
        // 3. Set default static values for metrics we aren't tracking yet
        double brakingScore = 1.0;   // 100%
        double corneringScore = 1.0; // 100%

        // 4. Calculate dynamic Speeding Score
        double speedingScore = 1.0; // Start at 100%
        int speedingEventsCount = 0;

        if (snapshot.hasData) {
          speedingEventsCount = snapshot.data!.docs.length;
          
          // Deduct 5% for every speeding event logged (adjust this penalty as you see fit)
          speedingScore = 1.0 - (speedingEventsCount * 0.05);
          
          // Prevent the score from dropping below 0%
          if (speedingScore < 0) speedingScore = 0.0; 
        }

        // 5. Calculate Overall Score (Average of the three)
        double overallScore = (speedingScore + brakingScore + corneringScore) / 3;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF2F3F5)),
          ),
          child: Column(
            children: [
              _ProgressCircle(
                label: "التقييم العام", 
                value: overallScore, 
                color: _getColorForScore(overallScore), // Dynamic color!
                size: 120, 
                stroke: 10
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ProgressCircle(
                    label: "الانعطافات", 
                    value: corneringScore, 
                    color: _getColorForScore(corneringScore), 
                    size: 60, 
                    stroke: 5
                  ),
                  _ProgressCircle(
                    label: "الفرملة", 
                    value: brakingScore, 
                    color: _getColorForScore(brakingScore), 
                    size: 60, 
                    stroke: 5
                  ),
                  _ProgressCircle(
                    label: "السرعة", 
                    value: speedingScore, 
                    color: _getColorForScore(speedingScore), 
                    size: 60, 
                    stroke: 5
                  ),
                ],
              ),
              
              // ✅ Bonus: Show a warning text if there are violations!
              if (speedingEventsCount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "تم تسجيل $speedingEventsCount مخالفات سرعة ${selectedTab == 0 ? 'اليوم' : 'هذا الشهر'}",
                    style: const TextStyle(
                      color: Color(0xFFD92D20), 
                      fontSize: 12, 
                      fontWeight: FontWeight.w800
                    ),
                  ),
                )
              ]
            ],
          ),
        );
      },
    );
  }

  // Helper function to change ring colors from Green -> Orange -> Red based on the grade
  Color _getColorForScore(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

class _ProgressCircle extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double size, stroke;

  const _ProgressCircle({
    required this.label,
    required this.value,
    required this.color,
    required this.size,
    required this.stroke,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: stroke,
                color: color,
                backgroundColor: Colors.grey[200],
              ),
            ),
            Text(
              "${(value * 100).toInt()}%",
              style: TextStyle(
                fontSize: size * 0.2,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF101828),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/* -------------------- Generic Project UI Kit -------------------- */

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)),
      child: Row(
        children: [
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
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 22,
            ),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF98AF8D),
          ),
        ),
      ),
    );
  }
}
