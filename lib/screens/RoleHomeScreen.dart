import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Color Constants ---
const Color kDarkBlue = Color(0xFF0D1B36);
const Color kAccent = Color(0xFF6A994E);
const Color kLightGrey = Color(0xFFF5F5F5);

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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Derived phone from email as per your custom auth system
      final phone = user.email?.split('@')[0];

      if (phone == null) return;

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phone)
          .get();

      if (!doc.exists) {
        setState(() => loading = false);
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        fullName = "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}";
        role = data['role'] ?? "";
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading info: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف الحساب'),
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
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      await _deleteAccount(context);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final phone = user.email?.split('@')[0];

      // 1) Delete Firestore data using phone number as Doc ID
      await FirebaseFirestore.instance.collection('users').doc(phone).delete();

      // 2) Delete Auth account
      await user.delete();

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول مرة أخرى لحذف الحساب أمنياً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Sync Header with AdminHome
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    // Profile Header
                    _buildProfileCircle(),
                    const SizedBox(height: 20),
                    _buildMenuCard(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.18,
      padding: const EdgeInsets.only(top: 50, right: 20, left: 20),
      color: kDarkBlue,
      alignment: Alignment.topRight,
      child: const Text(
        "الملف الشخصي",
        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProfileCircle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 60, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          fullName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkBlue),
        ),
      ],
    );
  }

  Widget _buildMenuCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            if (role == "parent")
              _menuItem(label: "أبنائي", icon: Icons.family_restroom, onTap: null),
            _menuItem(label: "تعديل الملف الشخصي", icon: Icons.edit, 
              onTap: () => Navigator.pushNamed(context, "/edit_profile")),
            _menuItem(label: "تغيير كلمة المرور", icon: Icons.lock, onTap: null),
            _menuItem(label: "الدعم الفني", icon: Icons.headset_mic_outlined, onTap: null),
            
            const Divider(indent: 20, endIndent: 20, height: 30),
            
            _dangerItem(label: "حذف الحساب", icon: Icons.delete_forever, 
              onTap: () => _confirmDeleteAccount(context)),
            _dangerItem(label: "تسجيل الخروج", icon: Icons.logout, 
              onTap: () => _signOut(context)),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({required String label, required IconData icon, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: kAccent),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: kDarkBlue)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      enabled: onTap != null,
    );
  }

  Widget _dangerItem({required String label, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.red.shade400),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade400)),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: kLightGrey,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: kDarkBlue,
        unselectedItemColor: Colors.grey.shade400,
        currentIndex: 1, // Profile is active
        onTap: (index) {
          if (index == 0) {
            // Navigate based on Role
            if (role == "admin") {
              Navigator.pushReplacementNamed(context, '/AdminHome');
            } else if (role == "parent") {
              Navigator.pushReplacementNamed(context, '/ParentHome');
            } else if (role == "driver") {
              Navigator.pushReplacementNamed(context, '/DriverHome');
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 28), label: 'Profile'),
        ],
      ),
    );
  }
}