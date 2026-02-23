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

class RiderHomeError extends RiderHomeState {
  final String message;
  const RiderHomeError(this.message);
}
