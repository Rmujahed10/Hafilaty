import 'package:url_launcher/url_launcher.dart';
import 'trip_pins_service.dart';

class TripNavigationService {
  int currentBatchIndex = 0;

  Future<void> startSmartNavigation({
    required double driverLat,
    required double driverLng,
    required List<StudentPinModel> students,
    required SchoolModel school,
    required bool isMorningTrip,
  }) async {
    if (students.isEmpty && !isMorningTrip) return;

    // Calculate how many students we've already dealt with
    int studentsRouted = currentBatchIndex * 9;
    List<StudentPinModel> remainingStudents = students.skip(studentsRouted).toList();

    // If all students are done but it's morning, route directly to School
    if (remainingStudents.isEmpty && isMorningTrip) {
      await _launchGoogleMaps('$driverLat,$driverLng', '${school.lat},${school.lng}', '');
      currentBatchIndex = 999; // Finished
      return;
    }

    String origin = (currentBatchIndex == 0 && !isMorningTrip) 
        ? '${school.lat},${school.lng}' 
        : '$driverLat,$driverLng';

    String destination = '';
    String waypointsStr = '';

    if (remainingStudents.length <= 9) {
      // --- FINAL BATCH ---
      if (isMorningTrip) {
        destination = '${school.lat},${school.lng}'; // SCHOOL IS ALWAYS LAST
        waypointsStr = remainingStudents.map((s) => '${s.lat},${s.lng}').join('%7C');
      } else {
        destination = '${remainingStudents.last.lat},${remainingStudents.last.lng}';
        waypointsStr = remainingStudents.take(remainingStudents.length - 1).map((s) => '${s.lat},${s.lng}').join('%7C');
      }
      currentBatchIndex = 999;
    } else {
      // --- INTERMEDIATE BATCH ---
      List<StudentPinModel> batch = remainingStudents.take(9).toList();
      destination = '${batch.last.lat},${batch.last.lng}';
      waypointsStr = batch.take(8).map((s) => '${s.lat},${s.lng}').join('%7C');
      currentBatchIndex++;
    }

    await _launchGoogleMaps(origin, destination, waypointsStr);
  }

  Future<void> _launchGoogleMaps(String origin, String dest, String ways) async {
    // Official Google Maps URL scheme
    String url = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=driving&dir_action=navigate';
    if (ways.isNotEmpty) url += '&waypoints=$ways';
    
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Google Maps';
    }
  }
}