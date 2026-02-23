sealed class RiderHomeState {
  const RiderHomeState();
}

class RiderHomeLoading extends RiderHomeState {
  const RiderHomeLoading();
}

class RiderHomeWaiting extends RiderHomeState {
  const RiderHomeWaiting();
}

class RiderHomeIncomingRide extends RiderHomeState {
  final String rideId;
  const RiderHomeIncomingRide(this.rideId);
}

/// The rider has an active ride that has already been accepted.
/// Used to restore the navigation screen after app restart / swipe-away.
class RiderHomeActiveRide extends RiderHomeState {
  final String rideId;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;

  const RiderHomeActiveRide({
    required this.rideId,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
  });
}

class RiderHomeError extends RiderHomeState {
  final String message;
  const RiderHomeError(this.message);
}
