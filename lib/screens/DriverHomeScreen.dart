import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kDarkBlue = Color(0xFF0D1B36);
const Color kAccent = Color(0xFF6A994E); // Your requested accent color

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  String driverName = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
  }

  Future<void> _loadDriverInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final first = doc['firstName'] ?? '';
        final last = doc['lastName'] ?? '';
        setState(() {
          driverName = "$first $last";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        driverName = "مستخدم";
        isLoading = false;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),

        // ─────────────────────────────────────────────
        // FIXED RTL APPBAR
        // ─────────────────────────────────────────────
        appBar: AppBar(
          backgroundColor: kDarkBlue,
          automaticallyImplyLeading: false,

          // RTL → Logout on the RIGHT
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => _signOut(context),
            ),
          ],

          // RTL → Language icon on the LEFT
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(Icons.language, color: Colors.white),
          ),
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 20),
              _buildMenuButtons(context),
              const SizedBox(height: 20),
              _buildDangerButtons(),
            ],
          ),
        ),
      ),
    );
  }

  //──────────────────────────────────────────────
  // HEADER WITH FIRESTORE NAME
  //──────────────────────────────────────────────
  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: const BoxDecoration(
        color: kDarkBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(45)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 60, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  driverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ],
      ),
    );
  }

  //──────────────────────────────────────────────
  // MENU BUTTONS (ICON → RIGHT, ARROW → LEFT)
  //──────────────────────────────────────────────
  Widget _buildMenuButtons(BuildContext context) {
    return Column(
      children: [
        _menuButton(
          label: "تعديل الملف الشخصي",
          icon: Icons.edit,
          onTap: () => Navigator.pushNamed(context, '/driver_edit_info'),
        ),
        _menuButton(label: "تغيير كلمة المرور", icon: Icons.key),
        _menuButton(label: "الدعم الفني", icon: Icons.headset_mic_outlined),
        _menuButton(label: "الإعدادات", icon: Icons.settings),
      ],
    );
  }

  Widget _menuButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 26, color: kAccent), // ✔ ICON RIGHT

              const SizedBox(width: 12),

              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: kAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              const Icon(Icons.arrow_back_ios,
                  size: 18, color: Colors.black54), // ✔ ARROW LEFT
            ],
          ),
        ),
      ),
    );
  }

  //──────────────────────────────────────────────
  // DANGER BUTTONS (Also RTL)
  //──────────────────────────────────────────────
  Widget _buildDangerButtons() {
    return Column(
      children: [
        _dangerButton("حذف الحساب", Icons.delete),
        const SizedBox(height: 10),
        _dangerButton("تسجيل الخروج", Icons.logout),
      ],
    );
  }

  Widget _dangerButton(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.black),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}
