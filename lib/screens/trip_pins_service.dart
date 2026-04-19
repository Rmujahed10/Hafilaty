import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StudentPinModel {
  final String studentId;
  final String name;
  final double lat;
  final double lng;

  StudentPinModel({required this.studentId, required this.name, required this.lat, required this.lng});
}

class SchoolModel {
  final String schoolId;
  final double lat;
  final double lng;
  SchoolModel({required this.schoolId, required this.lat, required this.lng});
}

class TripPinsService {
  Future<SchoolModel?> getSchoolLocationForBus(String busId) async {
    try {
      // Find bus by BusNumber field
      QuerySnapshot busQuery = await FirebaseFirestore.instance
          .collection('Buses')
          .where('BusNumber', whereIn: [busId, int.tryParse(busId)])
          .limit(1)
          .get();

      if (busQuery.docs.isEmpty) return null;
      
      var rawSchoolId = busQuery.docs.first.get('SchoolID');
      String schoolId = rawSchoolId.toString(); 

      DocumentSnapshot schoolDoc = await FirebaseFirestore.instance.collection('Schools').doc(schoolId).get();

      if (schoolDoc.exists) {
        final data = schoolDoc.data() as Map<String, dynamic>;
        
        // Exact matches for your DB: "Latitude " and "Longtitude "
        double lat = double.tryParse((data['Latitude '] ?? 0).toString()) ?? 0.0;
        double lng = double.tryParse((data['Longtitude '] ?? 0).toString()) ?? 0.0;

        return SchoolModel(schoolId: schoolId, lat: lat, lng: lng);
      }
    } catch (e) {
      print("Firestore Error: $e");
    }
    return null;
  }

  Future<List<StudentPinModel>> getPresentStudentsData() async {
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Attendance').doc(todayDate).collection('PresentStudents').get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return StudentPinModel(
          studentId: data['StudentID']?.toString() ?? '',
          name: data['StudentName_ar']?.toString() ?? 'طالب', 
          lat: double.tryParse(data['Latitude'].toString()) ?? 0.0,
          lng: double.tryParse(data['Longitude'].toString()) ?? 0.0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ✅ This is the missing method the error is looking for
  Set<Marker> getMarkersFromList(List<StudentPinModel> students) {
    return students.map((s) {
      return Marker(
        markerId: MarkerId(s.studentId),
        position: LatLng(s.lat, s.lng),
        infoWindow: InfoWindow(
          title: s.name,
          snippet: "طالب", // Optional: extra text under the name
        ),
      );
    }).toSet();
  }
}