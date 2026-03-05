import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'map_picker_screen.dart'; // Ensure this file is created

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- Controllers ---
  final _nameAr = TextEditingController();
  final _nameEn = TextEditingController();
  final _idNumber = TextEditingController();
  final _parentPhone = TextEditingController(); 
  final _secondPhone = TextEditingController();

  // --- Location Data for Clustering ---
  double? _selectedLat;
  double? _selectedLng;
  String _locationStatus = "اضغط لتحديد موقع المنزل على الخريطة";

  String? selectedSchoolName;
  String? selectedSchoolId;
  String? selectedGrade;

  final List<String> grades = [
    "الأول ابتدائي", "الثاني ابتدائي", "الثالث ابتدائي",
    "الرابع ابتدائي", "الخامس ابتدائي", "السادس ابتدائي",
    "الأول متوسط", "الثاني متوسط", "الثالث متوسط",
    "الأول ثانوي", "الثاني ثانوي", "الثالث ثانوي",
  ];

  static const Color _kDarkBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const Color _kAccent = Color(0xFF6A994E);

  @override
  void initState() {
    super.initState();
    _autoPopulateParentPhone();
  }

  void _autoPopulateParentPhone() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final realPhone = user.email!.split('@')[0];
      setState(() {
        _parentPhone.text = realPhone;
      });
    }
  }

  // --- Step 1: Warning & Map Logic ---
  Future<void> _handleLocationSelection() async {
    // Show importance warning
    bool proceed = await _showLocationWarning();
    
    if (proceed) {
      final LatLng? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapPickerScreen()),
      );

      if (result != null) {
        _validateAndSaveLocation(result);
      }
    }
  }

  // --- Step 2: Proximity Validation ---
  Future<void> _validateAndSaveLocation(LatLng pickedLocation) async {
    Position currentPos = await Geolocator.getCurrentPosition();
    double distance = Geolocator.distanceBetween(
      currentPos.latitude, currentPos.longitude, 
      pickedLocation.latitude, pickedLocation.longitude
    );

    // If the pin is more than 150 meters from their current GPS spot
    if (distance > 150) {
      _showSimpleAlert("تنبيه: الموقع المختار بعيد عن موقعك الحالي. يرجى التأكد من دقة اختيار منزل الطالب.");
    }

    setState(() {
      _selectedLat = pickedLocation.latitude;
      _selectedLng = pickedLocation.longitude;
      _locationStatus = "تم تحديد الموقع بنجاح ✅";
    });
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
              _TopHeader(title: "تسجيل ابن جديد", onBack: () => Navigator.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _MainCardContainer(
                        children: [
                          _buildStudentAvatar(),
                          const SizedBox(height: 30),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel(label: "بيانات الطالب الأساسية"),
                                _buildSmartField("اسم الطالب ثلاثي (بالعربي)", _nameAr, Icons.person_outline),
                                _buildSmartField("Student Triple Name (English)", _nameEn, Icons.person_outline, isEnglish: true),
                                _buildSmartField("رقم الهوية", _idNumber, Icons.badge_outlined, isNumber: true),
                                
                                // --- Location Picker UI ---
                                _SectionLabel(label: "موقع المنزل (مهم جداً للحافلة)"),
                                InkWell(
                                  onTap: _handleLocationSelection,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: _selectedLat == null ? Colors.red.withOpacity(0.3) : Colors.transparent),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.map_rounded, color: _kAccent),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(_locationStatus, 
                                            style: TextStyle(
                                              color: _selectedLat == null ? Colors.grey[600] : _kDarkBlue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            )),
                                        ),
                                        if (_selectedLat != null) const Icon(Icons.check_circle, color: Colors.green),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                _SectionLabel(label: "بيانات التواصل"),
                                _buildSmartField("رقم الجوال المسجل", _parentPhone, Icons.verified_user_outlined, isReadOnly: true),
                                _buildSmartField("رقم الجوال الإضافي (اختياري)", _secondPhone, Icons.phone_enabled_outlined, isNumber: true),
                                
                                _SectionLabel(label: "المعلومات الدراسية"),
                                _buildSchoolDropdown(),
                                _buildGradeDropdown(),
                                
                                const SizedBox(height: 40),
                                Center(child: _buildSubmitButton()),
                              ],
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

  // --- Submission Logic ---
  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLat == null) {
        _showSimpleAlert("الرجاء تحديد موقع المنزل على الخريطة أولاً");
        return;
      }

      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection("StudentRequests").doc(_idNumber.text).set({
          "name_ar": _nameAr.text.trim(),
          "name_en": _nameEn.text.trim(),
          "IDNumber": _idNumber.text.trim(),
          "parentPhone": _parentPhone.text.trim(),
          "secondPhone": _secondPhone.text.trim(),
          "SchoolName": selectedSchoolName,
          "schoolId": int.parse(selectedSchoolId!), 
          "Grade": selectedGrade,
          "status": "pending",
          "createdAt": FieldValue.serverTimestamp(),
          // Coordinates for K-Means Clustering
          "lat": _selectedLat,
          "lng": _selectedLng,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال الطلب بنجاح")));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) _showSimpleAlert("حدث خطأ أثناء الحفظ: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- UI Helpers ---

  Future<bool> _showLocationWarning() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تنبيه دقة الموقع", textAlign: TextAlign.right),
        content: const Text(
          "من فضلك، تأكد من أنك في منزل الطالب الآن. دقة الموقع تضمن تخصيص الحافلة الصحيحة لابنك.",
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("موافق، سأقوم بالتحديد")),
        ],
      ),
    ) ?? false;
  }

  void _showSimpleAlert(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(msg, textAlign: TextAlign.right),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("حسناً"))],
      ),
    );
  }

  Widget _buildSmartField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, bool isEnglish = false, bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: _kDarkBlue, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          textAlign: isEnglish ? TextAlign.left : TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isReadOnly ? Colors.grey : _kDarkBlue),
          decoration: InputDecoration(
            filled: true,
            fillColor: isReadOnly ? Colors.grey[50] : Colors.grey[100],
            prefixIcon: Icon(icon, color: _kAccent, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
          validator: (v) => (v == null || v.isEmpty) ? "هذا الحقل مطلوب" : null,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildSchoolDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("Schools").snapshots(),
      builder: (context, snapshot) {
        return _dropdownWrapper(
          label: "المدرسة",
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: InputBorder.none),
            value: selectedSchoolId,
            items: snapshot.hasData ? snapshot.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['School Name_ar']))).toList() : [],
            onChanged: (val) {
              setState(() {
                selectedSchoolId = val;
                selectedSchoolName = snapshot.data!.docs.firstWhere((d) => d.id == val)['School Name_ar'];
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildGradeDropdown() {
    return _dropdownWrapper(
      label: "الصف الدراسي",
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(border: InputBorder.none),
        value: selectedGrade,
        items: grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
        onChanged: (val) => setState(() => selectedGrade = val),
      ),
    );
  }

  Widget _dropdownWrapper({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: _kDarkBlue, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
          child: child,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _kDarkBlue,
        minimumSize: const Size(220, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: _isLoading ? null : _submitData,
      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("إرسال الطلب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStudentAvatar() {
    return Center(
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.white,
          border: Border.all(color: _kDarkBlue.withOpacity(0.1), width: 4),
          image: const DecorationImage(image: NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png')),
        ),
      ),
    );
  }
}

// Reuse your _TopHeader and _MainCardContainer from the original snippet
class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopHeader({required this.title, required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85, color: const Color(0xFF0D1B36),
      child: Row(children: [
        const Spacer(),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_forward_ios, color: Colors.white)),
      ]),
    );
  }
}

class _MainCardContainer extends StatelessWidget {
  final List<Widget> children;
  const _MainCardContainer({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(children: children),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6A994E))),
    );
  }
}