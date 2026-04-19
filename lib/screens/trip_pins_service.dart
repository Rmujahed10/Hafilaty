import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// مودل مبسط لاستقبال البيانات المباشرة
class StudentPinModel {
  final String studentId;
  final String name;
  final double lat;
  final double lng;

  StudentPinModel({
    required this.studentId,
    required this.name,
    required this.lat,
    required this.lng,
  });
}

class TripPinsService {
  // دالة واحدة تجلب كل شيء من سجل الحضور مباشرة
  Future<List<StudentPinModel>> getPresentStudentsData() async {
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(todayDate)
          .collection('PresentStudents')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return StudentPinModel(
          studentId: data['StudentID'] ?? '',
          name: data['StudentName_ar'] ?? '', // استخدام الاسم العربي من الصورة
          lat: (data['Latitude'] as num).toDouble(),
          lng: (data['Longitude'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      print("Error fetching attendance data: $e");
      return [];
    }
  }

  // دالة تحويل البيانات إلى ماركرز
  Set<Marker> getMarkersFromList(List<StudentPinModel> students) {
    return students.map((s) {
      return Marker(
        markerId: MarkerId(s.studentId),
        position: LatLng(s.lat, s.lng),
        infoWindow: InfoWindow(title: s.name),
      );
    }).toSet();
  }
}