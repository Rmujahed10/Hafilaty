// ignore_for_file: file_names
import 'package:flutter/material.dart';

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
                            child: Divider(height: 1, thickness: 1, color: Color(0xFFF2F3F5)),
                          ),

                          /// Driver Behavior Section
                          _SectionHeader(title: "سلوك السائق"),
                          _DriverBehaviorCard(),
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
      child: Row(
        children: [
          _tabItem("يومي", 0),
          _tabItem("شهري", 1),
        ],
      ),
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
                ? [const BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 2))]
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

  Widget _infoCard({required Color color, required IconData icon, required String title, required String value}) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kHeaderBlue),
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
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _kHeaderBlue,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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

class _MapSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFEDEFF2),
        image: const DecorationImage(
          image: NetworkImage("https://maps.gstatic.com/tactile/basepage/pegman_sherlock.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _DriverBehaviorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F3F5)),
      ),
      child: Column(
        children: [
          _ProgressCircle(label: "التقييم العام", value: 0.75, color: Colors.green, size: 120, stroke: 10),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProgressCircle(label: "الانعطافات", value: 0.72, color: Colors.orange, size: 60, stroke: 5),
              _ProgressCircle(label: "الفرملة", value: 0.60, color: Colors.red, size: 60, stroke: 5),
              _ProgressCircle(label: "السرعة", value: 0.85, color: Colors.blue, size: 60, stroke: 5),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressCircle extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double size, stroke;

  const _ProgressCircle({required this.label, required this.value, required this.color, required this.size, required this.stroke});

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
              style: TextStyle(fontSize: size * 0.2, fontWeight: FontWeight.w900, color: const Color(0xFF101828)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const Spacer(),
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 22)),
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
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.75),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8))],
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
        child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF98AF8D))),
      ),
    );
  }
}