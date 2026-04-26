// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentMyChildrenListScreen extends StatefulWidget {
  const ParentMyChildrenListScreen({super.key});

  @override
  State<ParentMyChildrenListScreen> createState() => _ParentMyChildrenListScreenState();
}

class _ParentMyChildrenListScreenState extends State<ParentMyChildrenListScreen> {
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

/* ========================= Child Details Screen ========================= */

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
  String _selectedGrade = "";
  String _titleName = "بيانات الابن";

  final List<String> _gradesList = [
    "الأول الابتدائي",
    "الثاني الابتدائي",
    "الثالث الابتدائي",
    "الرابع الابتدائي",
    "الخامس الابتدائي",
    "السادس الابتدائي",
    "الأول متوسط",
    "الثاني متوسط",
    "الثالث متوسط",
    "الأول ثانوي",
    "الثاني ثانوي",
    "الثالث ثانوي",
  ];

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
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
    _selectedGrade = _grade; // تهيئة قيمة الـ Dropdown

    _nameArCtrl.text = _studentNameAr;
    _nameEnCtrl.text = _studentNameEn;
    _secondPhoneCtrl.text = _secondPhone;

    _titleName = _studentNameAr.isNotEmpty
        ? _studentNameAr
        : (_studentNameEn.isNotEmpty ? _studentNameEn : "طالب");
    _initialized = true;
  }

  void _enterEditMode() => setState(() => _isEditing = true);

  void _cancelEditMode() {
    setState(() {
      _isEditing = false;
      _nameArCtrl.text = _studentNameAr;
      _nameEnCtrl.text = _studentNameEn;
      _secondPhoneCtrl.text = _secondPhone;
      _selectedGrade = _grade;
    });
  }

  Future<void> _saveEdits() async {
    if (!_formKey.currentState!.validate()) return;

    // التحقق من أن المستخدم اختار صفاً
    if (_selectedGrade.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء اختيار الصف الدراسي")),
      );
      return;
    }
    setState(() => _saving = true);

    try {
      final db = FirebaseFirestore.instance;

      // 🛑 NEW CONSTRAINT: Check for any active trips BEFORE saving edits
      final studentDoc = await db
          .collection('Students')
          .doc(widget.studentId)
          .get();
      final schoolId = studentDoc.data()?['SchoolID'];

      if (schoolId != null) {
        final activeBusesQuery = await db
            .collection('Buses')
            .where('SchoolID', isEqualTo: schoolId)
            .get();

        bool hasActiveTrip = activeBusesQuery.docs.any((doc) {
          final data = doc.data();
          return data['morningTripStatus'] == 'جارية' ||
              data['afternoonTripStatus'] == 'جارية';
        });

        if (hasActiveTrip) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "لا يمكن التعديل الآن: يوجد حافلة في رحلة جارية. يرجى الانتظار لحماية مسار السائق.",
                ),
                backgroundColor: _kDanger,
              ),
            );
            setState(() => _saving = false);
          }
          return; // Abort completely!
        }
      }
      // 🛑 END OF NEW CONSTRAINT

      final batch = db.batch();

      final studentRef = db.collection('Students').doc(widget.studentId);
      final requestRef = db.collection('StudentRequests').doc(widget.studentId);

      // Mapping for Students collection
      batch.update(studentRef, {
        'StudentName_ar': _nameArCtrl.text.trim(),
        'StudentName': _nameEnCtrl.text.trim(),
        'secondPhone': _secondPhoneCtrl.text.trim(),
        'Grade': _selectedGrade,
      });

      // Mapping for StudentRequests collection
      batch.update(requestRef, {
        'name_ar': _nameArCtrl.text.trim(),
        'name_en': _nameEnCtrl.text.trim(),
        'secondPhone': _secondPhoneCtrl.text.trim(),
        'Grade': _selectedGrade,
      });

      await batch.commit();

      setState(() {
        _studentNameAr = _nameArCtrl.text.trim();
        _studentNameEn = _nameEnCtrl.text.trim();
        _secondPhone = _secondPhoneCtrl.text.trim();
        _titleName = _studentNameAr.isNotEmpty
            ? _studentNameAr
            : _studentNameEn;
        _isEditing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم تحديث البيانات بنجاح")));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("حدث خطأ أثناء الحفظ")));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "حذف حساب الابن",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            "هل تريد حذف حساب ($_titleName) نهائياً من النظام والحافلة؟",
          ),
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
      ),
    );

    if (confirm != true) return;

    try {
      final db = FirebaseFirestore.instance;

      // 🛑 NEW CONSTRAINT: Check for active trips BEFORE deleting
      final studentDoc = await db
          .collection('Students')
          .doc(widget.studentId)
          .get();
      final schoolId = studentDoc.data()?['SchoolID'];

      if (schoolId != null) {
        final activeBusesQuery = await db
            .collection('Buses')
            .where('SchoolID', isEqualTo: schoolId)
            .get();

        bool hasActiveTrip = activeBusesQuery.docs.any((doc) {
          final data = doc.data();
          return data['morningTripStatus'] == 'جارية' ||
              data['afternoonTripStatus'] == 'جارية';
        });

        if (hasActiveTrip) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "لا يمكن الحذف الآن: يوجد حافلة في رحلة جارية. يرجى الانتظار لحماية مسار السائق.",
                ),
                backgroundColor: _kDanger,
              ),
            );
          }
          return; // Abort completely!
        }
      }
      // 🛑 END OF NEW CONSTRAINT

      final batch = db.batch();

      // IDs are identical, so we delete from both collections directly
      batch.delete(db.collection('Students').doc(widget.studentId));
      batch.delete(db.collection('StudentRequests').doc(widget.studentId));

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حذف بيانات الطالب بنجاح")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل الحذف. يرجى المحاولة لاحقاً")),
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
                      return const Center(child: Text("الطالب غير موجود"));
                    }

                    final data =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    _initOnce(data);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: Container(
                        padding: const EdgeInsets.all(18),
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
                              _buildHeaderActions(),
                              const SizedBox(height: 14),
                              const _SectionTitle(
                                title: "معلومات الطالب الأساسية",
                              ),
                              const SizedBox(height: 10),
                              _ReadOnlyBox(
                                label: "رقم الهوية",
                                value: widget.studentId,
                                icon: Icons.badge_outlined,
                              ),
                              const SizedBox(height: 12),
                              _EditableOrReadOnly(
                                label: "اسم الطالب عربي",
                                icon: Icons.person_outline,
                                isEditing: _isEditing,
                                controller: _nameArCtrl,
                                value: _studentNameAr,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? "الاسم مطلوب"
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _EditableOrReadOnly(
                                label: "اسم الطالب إنجليزي",
                                icon: Icons.person_outline,
                                isEditing: _isEditing,
                                controller: _nameEnCtrl,
                                value: _studentNameEn,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? "Name required"
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              const _SectionTitle(title: "أرقام التواصل"),
                              const SizedBox(height: 10),
                              _ReadOnlyBox(
                                label: "رقم ولي الأمر",
                                value: _parentPhone,
                                icon: Icons.phone_android,
                              ),
                              const SizedBox(height: 12),
                              _EditableOrReadOnly(
                                label: "رقم الهاتف الإضافي",
                                icon: Icons.phone_enabled_outlined,
                                isEditing: _isEditing,
                                controller: _secondPhoneCtrl,
                                value: _secondPhone.isEmpty
                                    ? "غير مضاف"
                                    : _secondPhone,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 18),
                              const _SectionTitle(title: "بيانات المدرسة"),
                              const SizedBox(height: 10),
                              _ReadOnlyBox(
                                label: "المدرسة",
                                value: _schoolName,
                                icon: Icons.school_outlined,
                              ),
                              const SizedBox(height: 12),
                              _EditableDropdownOrReadOnly(
                                label: "الصف",
                                icon: Icons.class_outlined,
                                isEditing: _isEditing,
                                value: _selectedGrade,
                                items: _gradesList,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedGrade = val;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 24),
                              _buildDeleteButton(),
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

  Widget _buildHeaderActions() {
    return Row(
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
        if (!_isEditing)
          IconButton(
            onPressed: _enterEditMode,
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF98A2B3)),
          )
        else ...[
          IconButton(
            onPressed: _saving ? null : _saveEdits,
            icon: const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
          ),
          IconButton(
            onPressed: _saving ? null : _cancelEditMode,
            icon: const Icon(Icons.cancel, color: Color(0xFFD64545)),
          ),
        ],
      ],
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kDanger, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: _kDanger.withValues(alpha: 0.06),
        ),
        onPressed: _confirmAndDelete,
        icon: const Icon(Icons.delete_outline, color: _kDanger, size: 28),
        label: const Text(
          "حذف حساب الابن",
          style: TextStyle(
            color: _kDanger,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/* ========================= UI Helper Widgets ========================= */

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
              const CircleAvatar(
                backgroundColor: Color(0xFFE6E6E6),
                child: Icon(Icons.person, color: Colors.white),
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

class _ReadOnlyBox extends StatelessWidget {
  final String label, value;
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
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF475467),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF98AF8D)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB0B0B0),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditableOrReadOnly extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isEditing;
  final TextEditingController controller;
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
    if (!isEditing) return _ReadOnlyBox(label: label, value: value, icon: icon);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF475467),
            fontSize: 12.5,
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
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
      color: const Color(0xFF0D1B36),
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
            onPressed: onLang,
            icon: const Icon(Icons.language, color: Colors.white, size: 22),
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
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF98AF8D),
        fontWeight: FontWeight.w900,
        fontSize: 13.5,
      ),
    );
  }
}

class _EditableDropdownOrReadOnly extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isEditing;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _EditableDropdownOrReadOnly({
    required this.label,
    required this.icon,
    required this.isEditing,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEditing) return _ReadOnlyBox(label: label, value: value, icon: icon);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF475467),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          // نتحقق إذا كانت القيمة الحالية موجودة في القائمة لتجنب الـ Exception
          initialValue: items.contains(value) ? value : null,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF98AF8D)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F7F8),
            prefixIcon: Icon(icon, color: const Color(0xFF98AF8D)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(
                val,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475467),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
