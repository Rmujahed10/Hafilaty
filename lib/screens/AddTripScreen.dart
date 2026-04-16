import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);

  String? driverId;
  String? driverName;
  String tripType = "going";

  final _formKey = GlobalKey<FormState>();

  final destination = TextEditingController();
  final time = TextEditingController();
  final students = TextEditingController();

  // ✅ إضافة الرحلة
  Future<void> addTrip() async {
    if (!_formKey.currentState!.validate() || driverId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى تعبئة جميع الحقول")));
      return;
    }

    await FirebaseFirestore.instance.collection("Trips").add({
      "driverId": driverId,
      "driverName": driverName,
      "type": tripType,
      "destination": destination.text.trim(),
      "startTime": time.text.trim(),
      "status": "pending",
      "studentsCount": int.parse(students.text),
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("تم إضافة الرحلة بنجاح ✅")));

    Navigator.pop(context);
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
              // 🔹 الهيدر
              _TopHeader(title: "إضافة رحلة", onLang: () {}),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      _MainCardContainer(
                        children: [
                          const _SectionHeader(title: "بيانات الرحلة"),

                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const SizedBox(height: 10),

                                // ✅ اختيار السائق
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .where('role', isEqualTo: 'driver')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const CircularProgressIndicator();
                                    }

                                    return DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: "اختر السائق",
                                        border: OutlineInputBorder(),
                                      ),
                                      value: driverId,
                                      items: snapshot.data!.docs.map((doc) {
                                        return DropdownMenuItem(
                                          value: doc.id,
                                          child: Text(doc['firstName']),
                                          onTap: () {
                                            driverName = doc['firstName'];
                                          },
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          driverId = val;
                                        });
                                      },
                                      validator: (val) =>
                                          val == null ? "اختر السائق" : null,
                                    );
                                  },
                                ),

                                const SizedBox(height: 12),

                                // الوجهة
                                TextFormField(
                                  controller: destination,
                                  decoration: const InputDecoration(
                                    labelText: "الوجهة",
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (val) =>
                                      val!.isEmpty ? "ادخل الوجهة" : null,
                                ),

                                const SizedBox(height: 12),

                                // الوقت
                                TextFormField(
                                  controller: time,
                                  decoration: const InputDecoration(
                                    labelText: "وقت الرحلة",
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (val) =>
                                      val!.isEmpty ? "ادخل الوقت" : null,
                                ),

                                const SizedBox(height: 12),

                                // عدد الطلاب
                                TextFormField(
                                  controller: students,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "عدد الطلاب",
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (val) =>
                                      val!.isEmpty ? "ادخل العدد" : null,
                                ),

                                const SizedBox(height: 12),

                                // نوع الرحلة
                                DropdownButtonFormField<String>(
                                  value: tripType,
                                  decoration: const InputDecoration(
                                    labelText: "نوع الرحلة",
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: "going",
                                      child: Text("ذهاب"),
                                    ),
                                    DropdownMenuItem(
                                      value: "returning",
                                      child: Text("عودة"),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      tripType = val!;
                                    });
                                  },
                                ),

                                const SizedBox(height: 20),

                                // زر الحفظ
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF98AF8D),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: addTrip,
                                    child: const Text("حفظ الرحلة"),
                                  ),
                                ),
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
}

//////////////////////////////////////////////////////////
// 🔹 نفس الكومبوننتس حقتك
//////////////////////////////////////////////////////////

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onLang;

  const _TopHeader({required this.title, required this.onLang});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
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
      padding: const EdgeInsets.all(20),
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Color(0xFF98AF8D),
        ),
      ),
    );
  }
}
