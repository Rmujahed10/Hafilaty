// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'RegistrationScreen.dart';

class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key});

  // --- Styling Constants ---
  static const Color _kBg = Color(0xFFF2F3F5);

  void _goToRegistration(BuildContext context, String roleKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RegistrationScreen(role: roleKey, successRoute: "/login"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              // ✅ Standardized Top Header
              _TopHeader(
                title: "تسجيل حساب جديد",
                onBack: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/login",
                  (route) => false,
                ),
                onLang: () {},
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // ✅ Signature 75% Min-Height Card
                      _MainCardContainer(
                        children: [
                          const SizedBox(height: 10),

                          const _SectionLabel(
                            label: "يرجى اختيار نوع الحساب للتسجيل",
                          ),

                          const SizedBox(height: 30),

                          // --- Role Selection Buttons ---
                          _RoleButton(
                            title: "السائق",
                            icon: Icons.directions_bus,
                            onTap: () => _goToRegistration(context, "driver"),
                          ),
                          const SizedBox(height: 16),

                          _RoleButton(
                            title: "ولي الأمر",
                            icon: Icons.family_restroom,
                            onTap: () => _goToRegistration(context, "parent"),
                          ),
                          const SizedBox(height: 16),

                          _RoleButton(
                            title: "المشرف التعليمي",
                            icon: Icons.person_pin_outlined,
                            onTap: () => _goToRegistration(context, "admin"),
                          ),

                          const SizedBox(height: 40),

                          const Text(
                            "جميع الحقوق محفوظة ٢٠٢٦",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------- Custom UI Components -------------------- */

class _RoleButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF2F3F5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF98AF8D), size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF0D1B36),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(24),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Color(0xFF98AF8D),
        ),
      ),
    );
  }
}
