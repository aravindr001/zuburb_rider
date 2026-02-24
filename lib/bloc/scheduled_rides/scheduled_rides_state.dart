import '../../models/ride.dart';

sealed class ScheduledRidesState {
  const ScheduledRidesState();
}

class ScheduledRidesLoading extends ScheduledRidesState {
  const ScheduledRidesLoading();
}

class ScheduledRidesLoaded extends ScheduledRidesState {
  final List<Ride> rides;
  const ScheduledRidesLoaded(this.rides);

  /// Only rides that are still active (scheduled or accepted).
  List<Ride> get upcoming => rides
      .where((r) {
        final s = r.status;
        return s == 'scheduled' || s == 'accepted' || s == 'requested';
      })
      .toList();

  int get count => upcoming.length;
}

class ScheduledRidesError extends ScheduledRidesState {
  final String message;
  const ScheduledRidesError(this.message);
}
