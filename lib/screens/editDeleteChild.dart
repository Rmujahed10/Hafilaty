// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditDeleteChildScreen extends StatefulWidget {
  const EditDeleteChildScreen({super.key});

  @override
  State<EditDeleteChildScreen> createState() => _EditDeleteChildScreenState();
}

class _EditDeleteChildScreenState extends State<EditDeleteChildScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);

  String parentPhone = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadParentPhone();
  }

  Future<void> _loadParentPhone() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => loading = false);
        return;
      }

      final phone = user.email?.split('@')[0] ?? "";
      setState(() {
        parentPhone = phone;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading parent phone: $e");
      setState(() => loading = false);
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
              _TopHeader(
                title: "أبنائي",
                onBack: () => Navigator.pop(context),
                onLang: () {},
              ),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: _kHeaderBlue),
                      )
                    : parentPhone.trim().isEmpty
                    ? const Center(
                        child: Text("لم يتم العثور على رقم ولي الأمر"),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Students')
                            .where('parentPhone', isEqualTo: parentPhone)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: _kHeaderBlue,
                              ),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                "لا يوجد أبناء مسجلين حالياً",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final doc = docs[i];
                              final data =
                                  doc.data() as Map<String, dynamic>? ?? {};
                              final studentId = doc.id;

                              final nameAr = (data['StudentName_ar'] ?? '')
                                  .toString()
                                  .trim();
                              final nameEn = (data['StudentName'] ?? '')
                                  .toString()
                                  .trim();
                              final displayName = nameAr.isNotEmpty
                                  ? nameAr
                                  : (nameEn.isNotEmpty ? nameEn : "طالب");

                              return _StudentTileCard(
                                name: displayName,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChildDetailsEditDeleteScreen(
                                            studentId: studentId,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ========================= Child Details (Fixed View + Edit Icon) ========================= */

class ChildDetailsEditDeleteScreen extends StatefulWidget {
  final String studentId;
  const ChildDetailsEditDeleteScreen({super.key, required this.studentId});

  @override
  State<ChildDetailsEditDeleteScreen> createState() =>
      _ChildDetailsEditDeleteScreenState();
}

class _ChildDetailsEditDeleteScreenState
    extends State<ChildDetailsEditDeleteScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kCard = Colors.white;
  static const Color _kDanger = Color(0xFFD64545);

  final _formKey = GlobalKey<FormState>();

  final _nameArCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  final _secondPhoneCtrl = TextEditingController();

  bool _initialized = false;
  bool _isEditing = false;
  bool _saving = false;

  String _studentNameAr = "";
  String _studentNameEn = "";
  String _parentPhone = "";
  String _secondPhone = "";
  String _schoolName = "";
  String _grade = "";
  String _titleName = "بيانات الابن";

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _parentPhoneCtrl.dispose();
    _secondPhoneCtrl.dispose();
    super.dispose();
  }

  void _initOnce(Map<String, dynamic> data) {
    if (_initialized) return;

    _studentNameAr = (data['StudentName_ar'] ?? '').toString().trim();
    _studentNameEn = (data['StudentName'] ?? '').toString().trim();
    _parentPhone = (data['parentPhone'] ?? '').toString().trim();
    _secondPhone = (data['secondPhone'] ?? '').toString().trim();
    _schoolName = (data['SchoolName'] ?? '').toString().trim();
    _grade = (data['Grade'] ?? '').toString().trim();

    _nameArCtrl.text = _studentNameAr;
    _nameEnCtrl.text = _studentNameEn;
    _parentPhoneCtrl.text = _parentPhone;
    _secondPhoneCtrl.text = _secondPhone;

    _titleName = _studentNameAr.isNotEmpty
        ? _studentNameAr
        : (_studentNameEn.isNotEmpty ? _studentNameEn : "طالب");

    _initialized = true;
  }

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditMode() {
    setState(() {
      _isEditing = false;
      _nameArCtrl.text = _studentNameAr;
      _nameEnCtrl.text = _studentNameEn;
      _parentPhoneCtrl.text = _parentPhone;
      _secondPhoneCtrl.text = _secondPhone;
    });
  }

  String? _validateRequired(String? v) {
    if (v == null || v.trim().isEmpty) return "هذا الحقل مطلوب";
    return null;
  }

  Future<void> _saveEdits() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final newNameAr = _nameArCtrl.text.trim();
      final newNameEn = _nameEnCtrl.text.trim();
      final newParentPhone = _parentPhoneCtrl.text.trim();
      final newSecondPhone = _secondPhoneCtrl.text.trim();

      await FirebaseFirestore.instance
          .collection('Students')
          .doc(widget.studentId)
          .update({
            'StudentName_ar': newNameAr,
            'StudentName': newNameEn,
            'parentPhone': newParentPhone,
            'secondPhone': newSecondPhone,
          });

      setState(() {
        _studentNameAr = newNameAr;
        _studentNameEn = newNameEn;
        _parentPhone = newParentPhone;
        _secondPhone = newSecondPhone;

        _titleName = _studentNameAr.isNotEmpty
            ? _studentNameAr
            : (_studentNameEn.isNotEmpty ? _studentNameEn : "طالب");

        _isEditing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم حفظ التعديلات بنجاح")));
    } catch (e) {
      debugPrint("Save error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("حدث خطأ أثناء الحفظ")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "حذف حساب الابن",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Text("هل تريد تحذف حساب ($_titleName) نهائياً؟"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _kDanger),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "حذف",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final studentRef = db.collection('Students').doc(widget.studentId);
      batch.delete(studentRef);

      final reqQ = await db
          .collection('StudentRequests')
          .where('studentId', isEqualTo: widget.studentId)
          .get();
      for (final d in reqQ.docs) {
        batch.delete(d.reference);
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم حذف حساب الابن بنجاح")));

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Delete error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("حدث خطأ أثناء حدف الحساب")),
      );
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
              _TopHeader(
                title: "بيانات الابن",
                onBack: () => Navigator.pop(context),
                onLang: () {},
              ),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Students')
                      .doc(widget.studentId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _kHeaderBlue),
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(
                        child: Text("الطالب غير موجود أو تم حذفه"),
                      );
                    }

                    final data =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    _initOnce(data);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _titleName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF101828),
                                      ),
                                    ),
                                  ),
                                  if (!_isEditing) ...[
                                    IconButton(
                                      tooltip: "تعديل",
                                      onPressed: _enterEditMode,
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Color(0xFF98A2B3),
                                      ),
                                    ),
                                  ] else ...[
                                    IconButton(
                                      tooltip: "حفظ",
                                      onPressed: _saving ? null : _saveEdits,
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: "إلغاء",
                                      onPressed: _saving
                                          ? null
                                          : _cancelEditMode,
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Color(0xFFD64545),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 14),

                              const _SectionTitle(title: "معلومات الطالب"),
                              const SizedBox(height: 10),

                              _EditableOrReadOnly(
                                label: "اسم الطالب عربي",
                                icon: Icons.person_outline,
                                isEditing: _isEditing,
                                controller: _nameArCtrl,
                                value: _studentNameAr.isEmpty
                                    ? "-"
                                    : _studentNameAr,
                                validator: _validateRequired,
                              ),
                              const SizedBox(height: 12),
                              _EditableOrReadOnly(
                                label: "اسم الطالب إنجليزي",
                                icon: Icons.person_outline,
                                isEditing: _isEditing,
                                controller: _nameEnCtrl,
                                value: _studentNameEn.isEmpty
                                    ? "-"
                                    : _studentNameEn,
                                validator: _validateRequired,
                              ),

                              const SizedBox(height: 18),
                              const _SectionTitle(title: "أرقام التواصل"),
                              const SizedBox(height: 10),

                              _EditableOrReadOnly(
                                label: "رقم ولي الأمر",
                                icon: Icons.phone_android,
                                isEditing: _isEditing,
                                controller: _parentPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                value: _parentPhone.isEmpty
                                    ? "-"
                                    : _parentPhone,
                                validator: _validateRequired,
                              ),
                              const SizedBox(height: 12),
                              _EditableOrReadOnly(
                                label: "رقم الهاتف الثاني",
                                icon: Icons.phone,
                                isEditing: _isEditing,
                                controller: _secondPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                value: _secondPhone.isEmpty
                                    ? "-"
                                    : _secondPhone,
                              ),

                              const SizedBox(height: 18),
                              const _SectionTitle(title: "بيانات المدرسة"),
                              const SizedBox(height: 10),

                              _ReadOnlyBox(
                                label: "اسم المدرسة",
                                value: _schoolName.isEmpty ? "-" : _schoolName,
                                icon: Icons.school_outlined,
                              ),
                              const SizedBox(height: 12),
                              _ReadOnlyBox(
                                label: "الصف",
                                value: _grade.isEmpty ? "-" : _grade,
                                icon: Icons.class_outlined,
                              ),

                              const SizedBox(height: 18),
                              const Divider(thickness: 1),
                              const SizedBox(height: 12),

                              SizedBox(
                                height: 56,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: _kDanger,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    backgroundColor: _kDanger.withValues(alpha: 0.06), // FIXED DEPRECATION
                                  ),
                                  onPressed: _confirmAndDelete,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: _kDanger,
                                    size: 28,
                                  ),
                                  label: const Text(
                                    "حذف حساب الابن",
                                    style: TextStyle(
                                      color: _kDanger,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ========================= UI Widgets ========================= */

class _StudentTileCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _StudentTileCard({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6E6E6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101828),
                    fontSize: 15.5,
                  ),
                ),
              ),
              const Icon(Icons.chevron_left, color: Color(0xFF98A2B3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onLang;

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
            onPressed: onLang,
            icon: const Icon(Icons.language, color: Colors.white),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF98AF8D),
          fontWeight: FontWeight.w900,
          fontSize: 13.5,
        ),
      ),
    );
  }
}

class _EditableOrReadOnly extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isEditing;

  final TextEditingController controller;
  final String value;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _EditableOrReadOnly({
    required this.label,
    required this.icon,
    required this.isEditing,
    required this.controller,
    required this.value,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      return _ReadOnlyBox(label: label, value: value, icon: icon);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF475467),
              fontSize: 12.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F7F8),
            prefixIcon: Icon(icon, color: const Color(0xFF98AF8D)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0x330D1B36)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF475467),
              fontSize: 12.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F8),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF98AF8D)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}