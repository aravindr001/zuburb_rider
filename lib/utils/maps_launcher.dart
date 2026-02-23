import 'package:url_launcher/url_launcher.dart';

class MapsLauncher {
  const MapsLauncher._();

  static Uri googleMapsDirectionsUri({
    required double destinationLat,
    required double destinationLng,
  }) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$destinationLat,$destinationLng',
      'travelmode': 'driving',
    });
  }

  static Future<bool> openDirections({
    required double destinationLat,
    required double destinationLng,
  }) async {
    final uri = googleMapsDirectionsUri(
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    );

    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
