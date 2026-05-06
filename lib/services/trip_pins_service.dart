import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StudentPinModel {
  final String studentId;
  final String name;
  final double lat;
  final double lng;
  final String busIdInDoc;
  String parentPhone;
  bool isNearNotificationSent;

  StudentPinModel({
    required this.studentId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.busIdInDoc,
    this.parentPhone = '',
    this.isNearNotificationSent = false,
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
      DocumentSnapshot busDoc = await FirebaseFirestore.instance
          .collection('Buses')
          .doc(busId)
          .get();

      if (!busDoc.exists) {
        debugPrint("FAIL: Bus document '$busId' DOES NOT EXIST in Firestore.");
        return null;
      }
      debugPrint("SUCCESS: Found Bus document.");

      final busData = busDoc.data() as Map<String, dynamic>?;
      if (busData == null || !busData.containsKey('SchoolID')) {
        debugPrint("FAIL: Bus document is missing the 'SchoolID' field.");
        return null;
      }
      String schoolId = busData['SchoolID'].toString();
      debugPrint("SUCCESS: Extracted SchoolID: $schoolId");

      DocumentSnapshot schoolDoc = await FirebaseFirestore.instance
          .collection('Schools')
          .doc(schoolId)
          .get();

      if (!schoolDoc.exists) {
        debugPrint(
          "FAIL: School document '$schoolId' DOES NOT EXIST in 'Schools' collection.",
        );
        return null;
      }
      debugPrint("SUCCESS: Found School document.");

      final schoolData = schoolDoc.data() as Map<String, dynamic>;
      debugPrint("RAW SCHOOL DATA: $schoolData");

      double lat = double.tryParse(
            (schoolData['Latitude'] ??
                    schoolData['Latitude '] ??
                    schoolData['latitude'] ??
                    0)
                .toString(),
          ) ??
          0.0;
      double lng = double.tryParse(
            (schoolData['Longitude'] ??
                    schoolData['Longtitude '] ??
                    schoolData['Longtitude'] ??
                    schoolData['longitude'] ??
                    0)
                .toString(),
          ) ??
          0.0;

      if (lat == 0.0 || lng == 0.0) {
        debugPrint(
          "FAIL: Coordinates are 0.0. The field names in Firestore don't match our code.",
        );
        return null;
      }

      debugPrint("=== SUCCESS: School Model Created: Lat $lat, Lng $lng ===");
      return SchoolModel(schoolId: schoolId, lat: lat, lng: lng);
    } catch (e) {
      debugPrint("CRITICAL CATCH ERROR in getSchoolLocation: $e");
    }
    return null;
  }

  Future<List<StudentPinModel>> getPresentStudentsData(String busId) async {
    // FIX 1: Add 'en_US' locale so physical devices don't produce Arabic numerals
    String todayDate = DateFormat('yyyy-MM-dd', 'en_US').format(DateTime.now());

    // FIX 2: Extract numeric suffix for exact matching
    // "Bus_32438_102" → "102", but if already "102" it stays "102"
    final String busIdSuffix = busId.split('_').last;

    debugPrint("📅 getPresentStudentsData date: $todayDate");
    debugPrint("🚌 Filtering for busIdSuffix: $busIdSuffix");

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(todayDate)
          .collection('PresentStudents')
          .get();

      debugPrint("📊 Total attendance docs: ${querySnapshot.docs.length}");

      final students = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return StudentPinModel(
              studentId: data['StudentID']?.toString() ?? doc.id,
              name: data['StudentName_ar']?.toString() ?? 'طالب',
              lat: double.tryParse(data['Latitude'].toString()) ?? 0.0,
              lng: double.tryParse(data['Longitude'].toString()) ?? 0.0,
              busIdInDoc: data['BusID']?.toString() ?? '',
            );
          })
          // FIX 2: Exact match instead of contains()
          .where(
            (student) =>
                student.busIdInDoc.isNotEmpty &&
                student.busIdInDoc == busIdSuffix,
          )
          .toList();

      debugPrint("✅ Students matched for bus $busIdSuffix: ${students.length}");
      return students;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching students: $e");
      }
      return [];
    }
  }

  Set<Marker> getMarkersFromList(List<StudentPinModel> students) {
    return students.map((s) {
      return Marker(
        markerId: MarkerId(s.studentId),
        position: LatLng(s.lat, s.lng),
        infoWindow: InfoWindow(title: s.name, snippet: "طالب"),
      );
    }).toSet();
  }
}