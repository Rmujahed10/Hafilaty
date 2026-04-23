// ignore_for_file: file_names, use_build_context_synchronously, duplicate_ignore
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleHomeScreen extends StatefulWidget {
  const RoleHomeScreen({super.key});

  @override
  State<RoleHomeScreen> createState() => _RoleHomeScreenState();
}

class _RoleHomeScreenState extends State<RoleHomeScreen> {
  // --- Styling Constants ---
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kDanger = Color(0xFFD64545);

  String role = "";
  String fullName = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final phone = user.email?.split('@')[0];
      if (phone == null) return;

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phone)
          .get();

      if (!doc.exists) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          fullName = "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}";
          role = data['role'] ?? "";
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading info: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return; // Guard against async gap
    // ignore: use_build_context_synchronously
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'حذف الحساب',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'هل أنت متأكد أنك تريد حذف الحساب نهائيًا؟ لا يمكن التراجع عن هذه العملية.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'حذف',
                  style: TextStyle(
                    color: _kDanger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (confirm == true && mounted) {
      // ignore: use_build_context_synchronously
      await _deleteAccount(context);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final phone = user.email?.split('@')[0];

      // Delete from Firestore first
      await FirebaseFirestore.instance.collection('users').doc(phone).delete();
      // Delete from Auth
      await user.delete();

      if (!mounted) return; // Guard against async gap
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى تسجيل الدخول مرة أخرى لحذف الحساب أمنياً'),
          ),
        );
      }
    }
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
              _TopHeader(title: "الملف الشخصي", onLang: () {}),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: _kHeaderBlue),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _MainCardContainer(
                              children: [
                                const SizedBox(height: 10),
                                _ProfileAvatar(fullName: fullName),
                                const SizedBox(height: 30),

                                if (role == "parent") ...[
                                  _MenuListItem(
                                    label: "أبنائي",
                                    icon: Icons.family_restroom,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      "/editDeleteChild",
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFF2F3F5),
                                  ),
                                ],

                                _MenuListItem(
                                  label: "تعديل الملف الشخصي",
                                  icon: Icons.edit_outlined,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    "/edit_profile",
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFF2F3F5),
                                ),

                                _MenuListItem(
                                  label: "تغيير كلمة المرور",
                                  icon: Icons.lock_outline,
                                  onTap: () {},
                                ),
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFF2F3F5),
                                ),

                                _MenuListItem(
                                  label: "الدعم الفني",
                                  icon: Icons.headset_mic_outlined,
                                  onTap: () {},
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(
                                    color: Color(0xFFF2F3F5),
                                    thickness: 6,
                                  ),
                                ),

                                _MenuListItem(
                                  label: "حذف الحساب",
                                  icon: Icons.delete_outline,
                                  isDanger: true,
                                  onTap: () => _confirmDeleteAccount(context),
                                ),
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFF2F3F5),
                                ),

                                _MenuListItem(
                                  label: "تسجيل الخروج",
                                  icon: Icons.logout,
                                  isDanger: true,
                                  onTap: () => _signOut(context),
                                ),
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
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            if (role == "admin") {
              Navigator.pushReplacementNamed(context, '/AdminHome');
            } else if (role == "parent") {
              Navigator.pushReplacementNamed(context, '/parent_home');
            } else if (role == "driver") {
              Navigator.pushReplacementNamed(context, '/driver_home');
            }
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

/* -------------------- Custom UI Kit -------------------- */

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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
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

class _MenuListItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDanger;

  const _MenuListItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? const Color(0xFFD64545) : const Color(0xFF101828);
    final iconColor = isDanger
        ? const Color(0xFFD64545)
        : const Color(0xFF98AF8D);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const Spacer(),
            if (!isDanger)
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFF98A2B3),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onLang;

  const _TopHeader({required this.title, required this.onLang});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)), // kDarkBlue
      child: Row(
        children: [
          // 1. جهة اليمين (فارغة)
          // نضع SizedBox بنفس عرض أيقونة اللغة لضمان توسيط النص بدقة
          const SizedBox(width: 48),

          // 2. العنوان في المنتصف تماماً
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          // 3. أيقونة اللغة في جهة اليسار
          IconButton(
            onPressed: onLang,
            icon: const Icon(Icons.language, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String fullName;
  const _ProfileAvatar({required this.fullName});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFFE6E6E6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF101828),
          ),
        ),
      ],
    );
  }
}
