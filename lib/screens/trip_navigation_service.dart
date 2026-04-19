import 'package:url_launcher/url_launcher.dart';
import 'trip_pins_service.dart'; // Needed to access StudentPinModel

class TripNavigationService {
  Future<void> startMultiStopNavigation({
    required double driverLat,
    required double driverLng,
    required List<StudentPinModel> students,
  }) async {
    if (students.isEmpty) return;

    // 1. Origin: The driver's live GPS location
    String origin = '$driverLat,$driverLng';

    // 2. Batching: Take up to 10 students (9 waypoints + 1 destination)
    List<StudentPinModel> batch = students.take(10).toList();

    // 3. Destination: The last student in this batch
    String destination = '${batch.last.lat},${batch.last.lng}';

    // 4. Waypoints: All students in the batch EXCEPT the last one
    String waypoints = '';
    if (batch.length > 1) {
      // The 'optimize:true|' prefix is the magic that sorts them by closest/fastest!
      waypoints = 'optimize:true|';
      for (int i = 0; i < batch.length - 1; i++) {
        waypoints += '${batch[i].lat},${batch[i].lng}';
        if (i < batch.length - 2) {
          waypoints += '|'; // Add a pipe separator between coordinates
        }
      }
    }

    // 5. Construct the final Google Maps URL
    // dir_action=navigate tells Android to instantly start driving mode
    final String url = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&waypoints=$waypoints&travelmode=driving&dir_action=navigate';
    final Uri googleMapsUrl = Uri.parse(url);

    // 6. Launch the external app
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not launch Google Maps');
    }
  }
}