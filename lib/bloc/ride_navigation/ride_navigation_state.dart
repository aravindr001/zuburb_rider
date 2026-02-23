import 'package:google_maps_flutter/google_maps_flutter.dart';

sealed class RideNavigationState {
  const RideNavigationState();
}

class RideNavigationLoading extends RideNavigationState {
  const RideNavigationLoading();
}

class RideNavigationLoaded extends RideNavigationState {
  final LatLng riderLocation;
  final LatLng pickupLocation;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const RideNavigationLoaded({
    required this.riderLocation,
    required this.pickupLocation,
    required this.markers,
    required this.polylines,
  });
}

class RideNavigationError extends RideNavigationState {
  final String message;
  const RideNavigationError(this.message);
}
