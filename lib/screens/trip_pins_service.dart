import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StudentPinModel {
  final String studentId;
  final String name;
  final double lat;
  final double lng;
  final String busIdInDoc; // ✅ Added this field

  StudentPinModel({
    required this.studentId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.busIdInDoc, // ✅ Added to constructor
  });
}

class SchoolModel {
  final String schoolId;
  final double lat;
  final double lng;
  SchoolModel({required this.schoolId, required this.lat, required this.lng});
}

class TripPinsService {
Future<SchoolModel?> getSchoolLocationForBus(String busId) async {
    debugPrint("=== START FETCHING SCHOOL FOR BUS: $busId ===");
    try {
      // 1. Check Bus Document
      DocumentSnapshot busDoc = await FirebaseFirestore.instance.collection('Buses').doc(busId).get();
      if (!busDoc.exists) {
        debugPrint("FAIL: Bus document '$busId' DOES NOT EXIST in Firestore.");
        return null;
      }
      debugPrint("SUCCESS: Found Bus document.");

      // 2. Safely extract School ID
      final busData = busDoc.data() as Map<String, dynamic>?;
      if (busData == null || !busData.containsKey('SchoolID')) {
         debugPrint("FAIL: Bus document is missing the 'SchoolID' field.");
         return null;
      }
      String schoolId = busData['SchoolID'].toString();
      debugPrint("SUCCESS: Extracted SchoolID: $schoolId");

      // 3. Fetch School Document
      DocumentSnapshot schoolDoc = await FirebaseFirestore.instance.collection('Schools').doc(schoolId).get();
      if (!schoolDoc.exists) {
        debugPrint("FAIL: School document '$schoolId' DOES NOT EXIST in 'Schools' collection.");
        return null;
      }
      debugPrint("SUCCESS: Found School document.");

      // 4. Safely extract coordinates
      final schoolData = schoolDoc.data() as Map<String, dynamic>;
      debugPrint("RAW SCHOOL DATA: $schoolData"); // This will show us your exact field names!

      double lat = double.tryParse((schoolData['Latitude'] ?? schoolData['Latitude '] ?? schoolData['latitude'] ?? 0).toString()) ?? 0.0;
      double lng = double.tryParse((schoolData['Longitude'] ?? schoolData['Longtitude '] ?? schoolData['Longtitude'] ?? schoolData['longitude'] ?? 0).toString()) ?? 0.0;

      if (lat == 0.0 || lng == 0.0) {
        debugPrint("FAIL: Coordinates are 0.0. The field names in Firestore don't match our code.");
        return null;
      }

      debugPrint("=== SUCCESS: School Model Created: Lat $lat, Lng $lng ===");
      return SchoolModel(schoolId: schoolId, lat: lat, lng: lng);
      
    } catch (e) {
      debugPrint("CRITICAL CATCH ERROR in getSchoolLocation: $e");
    }
    return null;
  }

  // ✅ Updated to accept busId for filtering
  Future<List<StudentPinModel>> getPresentStudentsData(String busId) async {
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(todayDate)
          .collection('PresentStudents')
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return StudentPinModel(
              studentId: data['StudentID']?.toString() ?? '',
              name: data['StudentName_ar']?.toString() ?? 'طالب',
              lat: double.tryParse(data['Latitude'].toString()) ?? 0.0,
              lng: double.tryParse(data['Longitude'].toString()) ?? 0.0,
              busIdInDoc: data['BusID']?.toString() ?? '', // ✅ Now defined
            );
          })
          // ✅ Filter students: only those whose BusID is part of your full busId string
          .where((student) => busId.contains(student.busIdInDoc) && student.busIdInDoc.isNotEmpty)
          .toList();
    } catch (e) {
      print("Error fetching students: $e");
      return [];
    }
  }

  Set<Marker> getMarkersFromList(List<StudentPinModel> students) {
    return students.map((s) {
      return Marker(
        markerId: MarkerId(s.studentId),
        position: LatLng(s.lat, s.lng),
        infoWindow: InfoWindow(
          title: s.name,
          snippet: "طالب",
        ),
      );
    }).toSet();
  }
}