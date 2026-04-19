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
        
        // Safely handle missing or malformed coordinate data
        double parsedLat = 0.0;
        double parsedLng = 0.0;
        
        if (data['Latitude'] != null) {
          parsedLat = double.tryParse(data['Latitude'].toString()) ?? 0.0;
        }
        if (data['Longitude'] != null) {
          parsedLng = double.tryParse(data['Longitude'].toString()) ?? 0.0;
        }

        return StudentPinModel(
          studentId: data['StudentID']?.toString() ?? '',
          name: data['StudentName_ar']?.toString() ?? 'طالب غير معروف', 
          lat: parsedLat,
          lng: parsedLng,
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