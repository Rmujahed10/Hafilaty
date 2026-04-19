import 'package:url_launcher/url_launcher.dart';

class TripNavigationService {
  Future<void> startNavigationToPoint({
    required double lat,
    required double lng,
  }) async {
    // Correct URL scheme for Google Maps external navigation
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

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