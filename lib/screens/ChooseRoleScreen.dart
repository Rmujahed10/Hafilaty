import 'package:flutter/material.dart';
import 'ParentRegistrationScreen.dart';
import 'DriverRegistrationScreen.dart';
import 'AdminRegistrationScreen.dart'; // We will reuse this screen for all roles for now

class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key});

  // Helper method for navigation
  void _navigateToRegistration(BuildContext context, String roleKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // The successRoute should point to your login screen or a welcome screen
        builder: (context) =>
            ParentRegistrationScreen(roleKey: roleKey, successRoute: '/login'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2F5A), // الأزرق الغامق العلوي
      body: SafeArea(
        child: Column(
          children: [
            // ------- AppBar Style (Back + Title) -------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    "تسجيل حساب جديد",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // ------- White Rounded Container -------
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ------- Subtitle -------
                      const Text(
                        "يرجى اختيار نوع الحساب للتسجيل",
                        style: TextStyle(
                          color: Color(0xFF8BAA3C), // اللون الأخضر
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // 1. زر السائق
                      _roleButton(
                        title: "السائق",
                        icon: Icons.directions_bus,
                        onTap: () {
                          // التنقل إلى شاشة تسجيل السائق
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DriverRegistrationScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      _roleButton(
                        title: "ولي الأمر",
                        icon: Icons.family_restroom,
                        onTap: () => _navigateToRegistration(
                          context,
                          'parent',
                        ), // Pass 'parent' role
                      ),
                      const SizedBox(height: 20),

                      // 3. زر المشرف التعليمي
                      _roleButton(
                        title: "المشرف التعليمي",
                        icon: Icons.person_pin_outlined,
                        onTap: () {
                          // التنقل إلى شاشة تسجيل المشرف التعليمي
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SupervisorRegistrationScreen(),
                            ),
                          );
                        },
                      ),

                      const Spacer(),

                      // ------- footer mini text -------
                      const Text(
                        "جميع الحقوق محفوظة 2025",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------- Custom Button Widget -------
  Widget _roleButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black54),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
