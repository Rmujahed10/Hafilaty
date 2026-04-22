// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FleetManagementScreen.dart'; 

class BusManagementScreen extends StatefulWidget {
  const BusManagementScreen({super.key});

  @override
  State<BusManagementScreen> createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen> {
  static const Color _kHeaderBlue = Color(0xFF0D1B36);
  static const Color _kBg = Color(0xFFF2F3F5);
  static const int _kBusCapacity = 50; // Standardized capacity

  String? currentSchoolId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final phone = user?.email?.split('@')[0];
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(phone).get();
      
      if (mounted) {
        setState(() {
          currentSchoolId = userDoc.get('schoolId').toString();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading school ID: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ Core Logic: Handles Add/Delete with Capacity & Driver Safety
  Future<void> _handleFleetUpdate(int change) async {
    if (currentSchoolId == null) return;

    try {
      // ✅ Validate driver availability BEFORE adding a bus
      if (change > 0) {
        // REMOVED schoolId filter. Now fetches all drivers.
        final driversQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'driver')
            .get();

        // Filter locally to find drivers who are NOT assigned to a bus yet
        final availableDrivers = driversQuery.docs.where((doc) {
          final data = doc.data();
          return !data.containsKey('AssignedBusID') || 
                 data['AssignedBusID'] == null || 
                 data['AssignedBusID'] == '';
        }).toList();

        // Block the addition if no drivers are available
        if (availableDrivers.isEmpty) {
          _showWarning("لا يمكن إضافة حافلة جديدة: لا يوجد سائقون متاحون (غير معينين). الرجاء تسجيل حساب سائق جديد أولاً.");
          return; // Abort so the Cloud Function is never triggered
        }
      }

      final schoolRef = FirebaseFirestore.instance.collection('Schools').doc(currentSchoolId!);
      final studentsQuery = await FirebaseFirestore.instance
          .collection('Students')
          .where('SchoolID', isEqualTo: int.parse(currentSchoolId!))
          .get();
      
      final totalStudents = studentsQuery.docs.length;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(schoolRef);
        if (!snapshot.exists) return;

        int currentBusCount = snapshot.get('BusCount') ?? 1;
        int newCount = currentBusCount + change;

        // Validation 1: Prevent 0 buses
        if (newCount < 1) return;

        // Validation 2: Capacity Check for Deletion
        if (change < 0) {
          int maxPossibleCapacity = newCount * _kBusCapacity;
          if (totalStudents > maxPossibleCapacity) {
            _showWarning("لا يمكن حذف الحافلة: عدد الطلاب ($totalStudents) يتجاوز سعة الحافلات المتبقية ($maxPossibleCapacity).");
            return;
          }
        }

        // Trigger AI Cloud Function
        transaction.update(schoolRef, {
          'BusCount': newCount,
          'LastAction': change > 0 ? "ADD" : "DELETE",
        });
      });
    } catch (e) {
      debugPrint("Fleet Update Error: $e");
    }
  }

  // ✅ Driver Assignment Logic
  Future<void> _assignDriverToBus(String busDocId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // REMOVED schoolId filter
      final driversQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .get();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Filter to ONLY show unassigned drivers
      final availableDrivers = driversQuery.docs.where((doc) {
        final data = doc.data();
        return !data.containsKey('AssignedBusID') || 
               data['AssignedBusID'] == null || 
               data['AssignedBusID'] == '';
      }).toList();

      if (availableDrivers.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("لا يوجد سائقين متاحين", textAlign: TextAlign.right),
            content: const Text(
                "جميع السائقين المسجلين تم تعيينهم لحافلات أخرى، أو لا يوجد أي سائق مسجل في النظام. الرجاء تسجيل حساب سائق جديد.",
                textAlign: TextAlign.right),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("حسناً"),
              ),
            ],
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context, // This is your main screen context
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) { // ✅ Renamed to sheetContext
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("اختر سائقاً للحافلة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableDrivers.length,
                      itemBuilder: (itemContext, index) { // ✅ Renamed to itemContext
                        final driverDoc = availableDrivers[index];
                        final data = driverDoc.data();
                        
                        final firstName = data.containsKey('firstName') ? data['firstName'] : '';
                        final lastName = data.containsKey('lastName') ? data['lastName'] : '';
                        final driverName = "$firstName $lastName".trim();
                        final displayName = driverName.isEmpty ? 'سائق ${index + 1}' : driverName;
                        
                        final driverPhone = data.containsKey('phone') ? data['phone'] : driverDoc.id;
                        final driverId = driverDoc.id; 

                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(displayName),
                          subtitle: Text(driverPhone),
                          trailing: const Icon(Icons.check_circle_outline, color: Colors.green),
                          onTap: () async {
                            // ✅ 1. Pop using the sheet's specific context
                            Navigator.pop(sheetContext); 
                            
                            // 2. Do the background database work
                            WriteBatch batch = FirebaseFirestore.instance.batch();
                            
                            batch.update(FirebaseFirestore.instance.collection('Buses').doc(busDocId), {
                              'DriverID': driverPhone, 
                              'DriverName': displayName,
                            });

                            batch.update(FirebaseFirestore.instance.collection('users').doc(driverId), {
                              'AssignedBusID': busDocId,
                            });

                            await batch.commit();

                            // ✅ 3. Safely use the MAIN screen's context for the SnackBar
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم تعيين السائق بنجاح', textAlign: TextAlign.right)),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Error fetching drivers: $e");
      if (mounted) Navigator.pop(context);
    }
  }

  void _showWarning(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تنبيه", textAlign: TextAlign.right),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("موافق")),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف", textAlign: TextAlign.right),
        content: const Text("هل أنت متأكد من رغبتك في حذف حافلة؟ سيتم إعادة توزيع جميع الطلاب.", textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) _handleFleetUpdate(-1);
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
                title: "إدارة الحافلات",
                onBack: () => Navigator.pushReplacementNamed(context, '/AdminHome'),
              ),
              Expanded(
                child: isLoading 
                    ? const Center(child: CircularProgressIndicator(color: _kHeaderBlue))
                    : _buildBusList(),
              ),
              _buildActionRow(), 
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleFleetUpdate(1),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("إضافة حافلة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A994E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
              label: const Text("حذف حافلة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD64545),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildBusList() {
    if (currentSchoolId == null) return const Center(child: Text("خطأ في البيانات"));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Buses')
          .where('SchoolID', isEqualTo: int.parse(currentSchoolId!))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final buses = snapshot.data?.docs ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: buses.length,
          itemBuilder: (context, index) {
            final data = buses[index].data() as Map<String, dynamic>;
            final busDocId = buses[index].id;
            
            // 🔥 NEW: Fetch the driver from the 'users' collection instead of 'Buses'
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'driver')
                  .where('AssignedBusID', isEqualTo: busDocId)
                  .snapshots(),
              builder: (context, driverSnap) {
                String? driverBadgeText;

                // Check if a driver was found with this bus ID
                if (driverSnap.hasData && driverSnap.data!.docs.isNotEmpty) {
                  final driverData = driverSnap.data!.docs.first.data() as Map<String, dynamic>;
                  
                  final firstName = driverData.containsKey('firstName') ? driverData['firstName'] : '';
                  final lastName = driverData.containsKey('lastName') ? driverData['lastName'] : '';
                  final fullName = "$firstName $lastName".trim();

                  // Fallback to phone number if they didn't set a name
                  driverBadgeText = fullName.isNotEmpty ? fullName : (driverData['phone'] ?? 'سائق');
                }
                
                return _BusCardItem(
                  busNumber: data['BusNumber'] ?? 0,
                  totalStudents: data['TotalStudents'] ?? 0,
                  capacity: _kBusCapacity,
                  isFull: (data['TotalStudents'] ?? 0) >= _kBusCapacity,
                  driverName: driverBadgeText, // ✅ Now strictly driven by the users collection
                  onAssignDriver: () => _assignDriverToBus(busDocId),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetManagementScreen())),
                );
              },
            );
          },
        );
      },
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
        onTap: (index) { if (index == 1) Navigator.pushReplacementNamed(context, '/role_home'); },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'الملف الشخصي'),
        ],
      ),
    );
  }
}

/* -------------------- Custom UI Components -------------------- */

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(color: Color(0xFF0D1B36)),
      child: Row(
        children: [
          const SizedBox(width: 48), 
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const Spacer(),
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _BusCardItem extends StatelessWidget {
  final int busNumber;
  final int totalStudents;
  final int capacity;
  final bool isFull;
  final String? driverName;
  final VoidCallback onTap;
  final VoidCallback onAssignDriver;

  const _BusCardItem({
    required this.busNumber,
    required this.totalStudents,
    required this.capacity,
    required this.isFull,
    this.driverName,
    required this.onTap,
    required this.onAssignDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFC8D8A4), 
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.yellow.shade600,
          child: const Icon(Icons.directions_bus, size: 32, color: Color(0xFF0D1B36)),
        ),
        title: Text("حافلة $busNumber", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0D1B36), fontSize: 20)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isFull ? const Color(0xFFD64545) : const Color(0xFF6A994E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(isFull ? "ممتلئة" : "نشطة", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                // ✅ Driver Status Badge
                GestureDetector(
                  onTap: onAssignDriver,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: driverName != null ? Colors.blue.shade700 : Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      driverName != null ? "السائق: $driverName" : "لم يتم تعيين سائق", 
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.groups, size: 18, color: Color(0xFF0D1B36)),
                const SizedBox(width: 6),
                Text("عدد الطلاب $totalStudents / $capacity", style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B36), fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF0D1B36), size: 30),
      ),
    );
  }
}