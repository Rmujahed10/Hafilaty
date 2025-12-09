import 'package:flutter/material.dart';

class SignupRoleScreen extends StatelessWidget {
  const SignupRoleScreen({super.key});

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
                          color: Color(0xFF8BAA3C), // نفس الأخضر بالصورة
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // ------- Buttons -------
                      _roleButton(
                        title: "السائق",
                        icon: Icons.directions_bus,
                        onTap: () {},
                      ),
                      const SizedBox(height: 20),

                      _roleButton(
                        title: "ولي الأمر",
                        icon: Icons.family_restroom,
                        onTap: () {},
                      ),
                      const SizedBox(height: 20),

                      _roleButton(
                        title: "المشرف التعليمي",
                        icon: Icons.person_search,
                        onTap: () {},
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