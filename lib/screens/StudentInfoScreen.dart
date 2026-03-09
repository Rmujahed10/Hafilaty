// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentInfoScreen extends StatefulWidget {
  final String studentDocId;
  const StudentInfoScreen({super.key, required this.studentDocId});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kDanger = Color(0xFFD64545);
  static const Color _kSuccess = Color(0xFF6A994E);

  bool isArabic = true;
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _busIdController;

  @override
  void initState() {
    super.initState();
    _nameArController = TextEditingController();
    _nameEnController = TextEditingController();
    _busIdController = TextEditingController();
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _busIdController.dispose();
    super.dispose();
  }

  DocumentReference get _ref => FirebaseFirestore.instance
      .collection('Students')
      .doc(widget.studentDocId);

  // --- REFINED SAVE LOGIC ---
  Future<void> _saveChanges() async {
    if (_nameArController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // 1. Update Students collection
      batch.update(_ref, {
        'StudentName_ar': _nameArController.text.trim(),
        'StudentName': _nameEnController.text.trim(),
        'BusID': _busIdController.text.trim(),
      });

      // 2. Update StudentRequests collection (Standardized ID)
      batch.update(db.collection('StudentRequests').doc(widget.studentDocId), {
        'name_ar': _nameArController.text.trim(),
        'name_en': _nameEnController.text.trim(),
      });

      await batch.commit();

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _kSuccess,
            content: Text(isArabic ? "تم حفظ التعديلات بنجاح" : "Changes saved successfully"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isArabic ? "تأكيد الحذف" : "Confirm Delete"),
          content: Text(isArabic ? "سيتم حذف الطالب من كافة السجلات." : "Student will be removed from all records."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isArabic ? "إلغاء" : "Cancel")),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isArabic ? "حذف" : "Delete", style: const TextStyle(color: _kDanger)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        final db = FirebaseFirestore.instance;
        final batch = db.batch();
        batch.delete(_ref);
        batch.delete(db.collection('StudentRequests').doc(widget.studentDocId));
        await batch.commit();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        debugPrint("Delete Error: $e");
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
          child: StreamBuilder<DocumentSnapshot>(
            stream: _ref.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (!snapshot.data!.exists) return const Center(child: Text("تم حذف البيانات"));

              final data = snapshot.data!.data() as Map<String, dynamic>;
              
              if (!_isEditing) {
                _nameArController.text = data['StudentName_ar'] ?? '';
                _nameEnController.text = data['StudentName'] ?? '';
                _busIdController.text = data['BusID']?.toString() ?? '';
              }

              final displayName = isArabic ? _nameArController.text : _nameEnController.text;

              return Column(
                children: [
                  _TopHeader(
                    title: isArabic ? "بيانات الطالب" : "Student Details",
                    onBack: () => Navigator.pop(context),
                    onLang: () => setState(() => isArabic = !isArabic),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _MainCardContainer(
                            children: [
                              _ProfileSection(
                                name: displayName, 
                                isEditing: _isEditing,
                                onEditToggle: () {
                                  setState(() {
                                    if (_isEditing) {
                                      // Cancel changes
                                      _isEditing = false;
                                    } else {
                                      _isEditing = true;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              _SectionLabel(label: isArabic ? "المعلومات الأساسية" : "Basic Info", isArabic: isArabic),
                              _InfoGroupCard(
                                children: [
                                  if (_isEditing) ...[
                                    _EditRow(label: "الاسم (عربي)", controller: _nameArController),
                                    _EditRow(label: "Name (En)", controller: _nameEnController),
                                    _EditRow(label: "رقم الحافلة", controller: _busIdController),
                                  ] else ...[
                                    _InfoRow(label: isArabic ? "رقم الطالب" : "Student ID", value: data['StudentID']),
                                    _InfoRow(label: isArabic ? "رقم المدرسة" : "School ID", value: data['SchoolID']),
                                    _InfoRow(label: isArabic ? "رقم الحافلة" : "Bus ID", value: data['BusID']),
                                  ]
                                ],
                              ),
                              const SizedBox(height: 24),
                              _SectionLabel(label: isArabic ? "الموقع الجغرافي" : "Location", isArabic: isArabic),
                              _InfoGroupCard(
                                children: [
                                  _InfoRow(label: isArabic ? "خطوط الطول" : "Lat", value: data['Latitude']),
                                  _InfoRow(label: isArabic ? "خطوط العرض" : "Lng", value: data['Longitude']),
                                ],
                              ),
                              const SizedBox(height: 32),
                              _ActionButton(
                                label: _isSaving 
                                  ? (isArabic ? "جاري الحفظ..." : "Saving...")
                                  : _isEditing 
                                    ? (isArabic ? "حفظ التعديلات" : "Save Changes")
                                    : (isArabic ? "حذف بيانات الطالب" : "Delete Student"),
                                icon: _isEditing ? Icons.save : Icons.delete_outline,
                                color: _isEditing ? _kSuccess : _kDanger,
                                onTap: _isSaving ? null : () {
                                  if (_isEditing) {
                                    _saveChanges();
                                  } else {
                                    _confirmDelete(context);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomNav(context),
                ],
              );
            },
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
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _kHeaderBlue,
        unselectedItemColor: Colors.grey.shade600,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/AdminHome');
          if (index == 1) Navigator.pushReplacementNamed(context, '/role_home');
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_rounded, size: 28), label: isArabic ? 'الرئيسية' : 'Home'),
          BottomNavigationBarItem(icon: const Icon(Icons.person_rounded, size: 28), label: isArabic ? 'الملف' : 'Profile'),
        ],
      ),
    );
  }
}

/* -------------------- UI COMPONENTS -------------------- */

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack, onLang;
  const _TopHeader({required this.title, required this.onBack, required this.onLang});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)),
      child: Row(
        children: [
          IconButton(onPressed: onLang, icon: const Icon(Icons.language, color: Colors.white, size: 22)),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const Spacer(),
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20)),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String name;
  final bool isEditing;
  final VoidCallback onEditToggle;
  const _ProfileSection({required this.name, required this.isEditing, required this.onEditToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onEditToggle,
            icon: Icon(isEditing ? Icons.close : Icons.edit, color: Colors.blueGrey, size: 24),
          ),
        ),
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(color: Color(0xFFFFC83D), shape: BoxShape.circle),
          child: const Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF101828))),
      ],
    );
  }
}

class _InfoGroupCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoGroupCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF2F3F5))),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final dynamic value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF667085), fontSize: 13)),
          Text(value?.toString() ?? '---', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0D1B36), fontSize: 14)),
        ],
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _EditRow({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF98AF8D)),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isArabic;
  const _SectionLabel({required this.label, required this.isArabic});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF98AF8D))),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton({required this.label, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(color: color.withOpacity(0.3))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}