import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kDarkBlue = Color(0xFF0D1B36);
const Color kAccent = Color(0xFF6A994E);

class RoleHomeScreen extends StatefulWidget {
  const RoleHomeScreen({super.key});

  @override
  State<RoleHomeScreen> createState() => _RoleHomeScreenState();
}

class _RoleHomeScreenState extends State<RoleHomeScreen> {
  String role = "";
  String fullName = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    final firstName = doc['firstName'] ?? "";
    final lastName = doc['lastName'] ?? "";
    final userRole = doc['role'] ?? "";

    setState(() {
      fullName = "$firstName $lastName";
      role = userRole;
      loading = false;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          backgroundColor: kDarkBlue,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => _signOut(context),
            ),
          ],
          leading: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.language, color: Colors.white),
          ),
        ),

        body: Stack(
          children: [
            // BACKGROUND: blue on top, grey under
            Column(
              children: [
                Container(
                  height: 230,
                  color: kDarkBlue,
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF7F7F7),
                  ),
                ),
              ],
            ),

            // FOREGROUND CONTENT
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // PROFILE HEADER (avatar + name)
                  Column(
                    children: [
                      const CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 60, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // WHITE CARD OVER BLUE BACKGROUND
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 20),
                      child: Column(
                        children: [
                          if (role == "parent")
                            _menuButton(
                              label: "أبنائي",
                              icon: Icons.family_restroom,
                              onTap: null, // disabled
                            ),

                          _menuButton(
                            label: "تعديل الملف الشخصي",
                            icon: Icons.edit,
                            onTap: () => Navigator.pushNamed(
                                context, "/EditAccountScreen"),
                          ),

                          _menuButton(
                            label: "تغيير كلمة المرور",
                            icon: Icons.lock,
                            onTap: null,
                          ),

                          _menuButton(
                            label: "الدعم الفني",
                            icon: Icons.headset_mic_outlined,
                            onTap: null,
                          ),

                          _menuButton(
                            label: "الإعدادات",
                            icon: Icons.settings,
                            onTap: null,
                          ),

                          const SizedBox(height: 20),

                          _dangerButton(
                            label: "حذف الحساب",
                            icon: Icons.delete,
                            onTap: null, // disabled
                          ),

                          const SizedBox(height: 10),

                          _dangerButton(
                            label: "تسجيل الخروج",
                            icon: Icons.logout,
                            onTap: () => _signOut(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, size: 26, color: kAccent),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: kAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_back_ios,
                    size: 18, color: Colors.black54),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dangerButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22),
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
        ),
      ),
    );
  }
}
