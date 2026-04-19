// ignore_for_file: file_names, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // Ensure 'flutter pub add url_launcher' was run

class StudentInfoScreen extends StatefulWidget {
  final String studentDocId;
  const StudentInfoScreen({super.key, required this.studentDocId});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kDanger = Color(0xFFD64545);
  static const Color _kSuccess = Color(0xFF6A994E);

  bool isArabic = true;
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _secondPhoneController;
  late TextEditingController _busIdController;

  @override
  void initState() {
    super.initState();
    _nameArController = TextEditingController();
    _nameEnController = TextEditingController();
    _secondPhoneController = TextEditingController();
    _busIdController = TextEditingController();
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _secondPhoneController.dispose();
    _busIdController.dispose();
    super.dispose();
  }

  DocumentReference get _ref => FirebaseFirestore.instance
      .collection('Students')
      .doc(widget.studentDocId);

  // --- External Map Launcher (Fixed) ---
  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;

    // Universal URL that works on Web and Mobile
    final String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final Uri url = Uri.parse(googleUrl);

    try {
      // For Web/Chrome, we MUST use externalApplication mode
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? "تعذر فتح الخريطة" : "Could not open map"),
          ),
        );
      }
    }
  }

  // --- Atomic Sync Save ---
  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      batch.update(_ref, {
        'StudentName_ar': _nameArController.text.trim(),
        'StudentName': _nameEnController.text.trim(),
        'secondPhone': _secondPhoneController.text.trim(),
        'BusID': _busIdController.text.trim(),
      });

      batch.update(db.collection('StudentRequests').doc(widget.studentDocId), {
        'name_ar': _nameArController.text.trim(),
        'name_en': _nameEnController.text.trim(),
        'secondPhone': _secondPhoneController.text.trim(),
      });

      await batch.commit();
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
      debugPrint("Save error: $e");
    }
  }

  // --- Legacy-Safe Delete ---
  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(isArabic ? "حذف الطالب" : "Delete Student"),
          content: Text(
            isArabic
                ? "هل أنت متأكد من حذف هذا الطالب من كافة السجلات؟"
                : "Are you sure you want to delete this student?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isArabic ? "إلغاء" : "Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                isArabic ? "حذف" : "Delete",
                style: const TextStyle(
                  color: _kDanger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      batch.delete(_ref);
      batch.delete(db.collection('StudentRequests').doc(widget.studentDocId));
      await batch.commit();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: _ref.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.data!.exists) {
                return const Center(child: Text("تم حذف البيانات"));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              if (!_isEditing) {
                _nameArController.text = data['StudentName_ar'] ?? '';
                _nameEnController.text = data['StudentName'] ?? '';
                _secondPhoneController.text = data['secondPhone'] ?? '';
                _busIdController.text = data['BusID']?.toString() ?? '';
              }

              return Column(
                children: [
                  _TopHeader(
                    title: isArabic ? "ملف الطالب" : "Student Profile",
                    onBack: () => Navigator.pop(context),
                    onLang: () => setState(() => isArabic = !isArabic),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: _MainCardContainer(
                        children: [
                          _ProfileSection(
                            name: isArabic
                                ? _nameArController.text
                                : _nameEnController.text,
                            isEditing: _isEditing,
                            onEditToggle: () =>
                                setState(() => _isEditing = !_isEditing),
                          ),
                          const SizedBox(height: 24),

                          _SectionLabel(
                            label: isArabic
                                ? "بيانات الحافلة والدراسة"
                                : "Bus & Academic",
                            isArabic: isArabic,
                          ),
                          _InfoGroupCard(
                            children: [
                              _InfoRow(
                                label: isArabic ? "رقم الهوية" : "National ID",
                                value: widget.studentDocId,
                              ),
                              const Divider(height: 1),
                              _isEditing
                                  ? _EditRow(
                                      label: "رقم الحافلة",
                                      controller: _busIdController,
                                    )
                                  : _InfoRow(
                                      label: isArabic
                                          ? "رقم الحافلة"
                                          : "Bus ID",
                                      value: data['BusID'],
                                    ),
                              const Divider(height: 1),
                              _InfoRow(
                                label: isArabic ? "المدرسة" : "School",
                                value: data['SchoolName'],
                              ),
                              const Divider(height: 1),
                              _InfoRow(
                                label: isArabic ? "الصف" : "Grade",
                                value: data['Grade'],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          _SectionLabel(
                            label: isArabic
                                ? "معلومات التواصل"
                                : "Contact Info",
                            isArabic: isArabic,
                          ),
                          _InfoGroupCard(
                            children: [
                              if (_isEditing) ...[
                                _EditRow(
                                  label: "الاسم (عربي)",
                                  controller: _nameArController,
                                ),
                                _EditRow(
                                  label: "Name (En)",
                                  controller: _nameEnController,
                                ),
                                _EditRow(
                                  label: "الجوال الإضافي",
                                  controller: _secondPhoneController,
                                ),
                              ] else ...[
                                _InfoRow(
                                  label: isArabic
                                      ? "جوال ولي الأمر"
                                      : "Parent Phone",
                                  value: data['parentPhone'],
                                ),
                                const Divider(height: 1),
                                _InfoRow(
                                  label: isArabic
                                      ? "جوال إضافي"
                                      : "Secondary Phone",
                                  value: data['secondPhone'],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),

                          _SectionLabel(
                            label: isArabic ? "الموقع الجغرافي" : "Location",
                            isArabic: isArabic,
                          ),
                          _ActionButton(
                            label: isArabic
                                ? "عرض الموقع على الخريطة"
                                : "View on Map",
                            icon: Icons.map_outlined,
                            color: Colors.blueAccent,
                            onTap: () =>
                                _openMap(data['Latitude'], data['Longitude']),
                          ),
                          const SizedBox(height: 32),

                          _ActionButton(
                            label: _isSaving
                                ? (isArabic ? "جاري الحفظ..." : "Saving...")
                                : (_isEditing
                                      ? (isArabic
                                            ? "حفظ التعديلات"
                                            : "Save Changes")
                                      : (isArabic
                                            ? "حذف الطالب"
                                            : "Delete Student")),
                            icon: _isEditing
                                ? Icons.save
                                : Icons.delete_outline,
                            color: _isEditing ? _kSuccess : _kDanger,
                            onTap: () => _isSaving
                                ? null
                                : (_isEditing
                                      ? _saveChanges()
                                      : _confirmDelete(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/* -------------------- UI COMPONENTS -------------------- */

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
            onPressed: onLang,
            icon: const Icon(Icons.language, color: Colors.white, size: 22),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
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
      child: Column(children: children),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String name;
  final bool isEditing;
  final VoidCallback onEditToggle;
  const _ProfileSection({
    required this.name,
    required this.isEditing,
    required this.onEditToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onEditToggle,
            icon: Icon(
              isEditing ? Icons.close : Icons.edit,
              color: Colors.blueGrey,
              size: 24,
            ),
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFFFC83D),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F3F5)),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF667085),
              fontSize: 13,
            ),
          ),
          Text(
            value?.toString() ?? '---',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D1B36),
              fontSize: 14,
            ),
          ),
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
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
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
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF98AF8D),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
