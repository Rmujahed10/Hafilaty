import 'package:url_launcher/url_launcher.dart';
import 'trip_pins_service.dart';

class TripNavigationService {
  Future<void> startMultiStopNavigation({
    required double driverLat,
    required double driverLng,
    required List<StudentPinModel> students,
  }) async {
    if (students.isEmpty) return;

    // 1. Origin: The driver's live GPS location
    String origin = '$driverLat,$driverLng';

    // 2. Batching: Take up to 10 students (Google Maps URL limit is 9 waypoints + 1 destination)
    List<StudentPinModel> batch = students.take(10).toList();

    // 3. Destination: The last student in this batch
    String destination = '${batch.last.lat},${batch.last.lng}';

    // 4. Waypoints: All students in the batch EXCEPT the last one
    String waypoints = '';
    if (batch.length > 1) {
      // Loop through and format as lat,lng|lat,lng|lat,lng
      for (int i = 0; i < batch.length - 1; i++) {
        waypoints += '${batch[i].lat},${batch[i].lng}';
        if (i < batch.length - 2) {
          waypoints += '%7C'; // This is the URL-encoded version of the pipe symbol '|'
        }
      }
    }

    // 5. Construct the official Google Maps URL
    // This uses the correct cross-platform scheme that works on Android, iOS, and Web
    String urlString = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '&travelmode=driving'
        '&dir_action=navigate'; // Forces navigation mode to start automatically

    if (waypoints.isNotEmpty) {
      urlString += '&waypoints=$waypoints';
    }

    final Uri googleMapsUrl = Uri.parse(urlString);

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