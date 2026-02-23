import 'dart:convert';

import 'package:http/http.dart' as http;

class DirectionsRepository {
  final http.Client _client;

  DirectionsRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> fetchOverviewPolyline({
    required String apiKey,
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    if (apiKey.isEmpty) return null;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '$originLat,$originLng',
      'destination': '$destinationLat,$destinationLng',
      'mode': 'driving',
      'key': apiKey,
    });

    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw StateError('Directions API failed (${resp.statusCode})');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final status = json['status'] as String?;

    if (status != 'OK') {
      // Common values: ZERO_RESULTS, REQUEST_DENIED, OVER_QUERY_LIMIT
      final message = json['error_message'] as String?;
      throw StateError('Directions API status=$status ${message ?? ''}'.trim());
    }

    final routes = json['routes'] as List<dynamic>;
    if (routes.isEmpty) return null;

    final overview = routes.first as Map<String, dynamic>;
    final poly = overview['overview_polyline'] as Map<String, dynamic>?;
    return poly?['points'] as String?;
  }
}
