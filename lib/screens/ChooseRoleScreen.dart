import 'package:flutter/material.dart';
import 'RegistrationScreen.dart';

const Color kPrimaryColor = Color(0xFF0D1B36);
const Color kAccentColor = Color(0xFF8BAA3C);

class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key});

  void _goToRegistration(BuildContext context, String roleKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationScreen(
          role: roleKey,
          successRoute: "/login",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kPrimaryColor,
        body: SafeArea(
          child: Column(
            children: [
              // ---------------- AppBar ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // SAME ARROW STYLE + ALWAYS LEFT
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          // ALWAYS return to login page
                          Navigator.pushNamedAndRemoveUntil(
                              context, "/login", (route) => false);
                        },
                      ),
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

              // ---------------- White Content ----------------
              Expanded(
                child: Container(
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

                        const Text(
                          "يرجى اختيار نوع الحساب للتسجيل",
                          style: TextStyle(
                            color: kAccentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 40),

                        _roleButton(
                          title: "السائق",
                          icon: Icons.directions_bus,
                          onTap: () => _goToRegistration(context, "driver"),
                        ),
                        const SizedBox(height: 20),

                        _roleButton(
                          title: "ولي الأمر",
                          icon: Icons.family_restroom,
                          onTap: () => _goToRegistration(context, "parent"),
                        ),
                        const SizedBox(height: 20),

                        _roleButton(
                          title: "المشرف التعليمي",
                          icon: Icons.person_pin_outlined,
                          onTap: () => _goToRegistration(context, "admin"),
                        ),

                        const Spacer(),

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
      ),
    );
  }

  Widget _roleButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
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
        child: Column(
          children: [
            Icon(icon, color: kAccentColor, size: 35),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
