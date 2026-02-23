import '../../models/ride.dart';

sealed class IncomingRideState {
  const IncomingRideState();
}

class IncomingRideLoading extends IncomingRideState {
  const IncomingRideLoading();
}

class IncomingRideLoaded extends IncomingRideState {
  final Ride ride;
  final bool actionInProgress;
  const IncomingRideLoaded({required this.ride, this.actionInProgress = false});
}

class IncomingRideNotFound extends IncomingRideState {
  const IncomingRideNotFound();
}

class IncomingRideCompleted extends IncomingRideState {
  final String action; // accepted | rejected
  const IncomingRideCompleted(this.action);
}

class IncomingRideError extends IncomingRideState {
  final String message;
  const IncomingRideError(this.message);
}
