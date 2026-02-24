import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/ride_repository.dart';
import '../../repository/rider_repository.dart';
import 'scheduled_rides_state.dart';

class ScheduledRidesCubit extends Cubit<ScheduledRidesState> {
  final RiderRepository _riderRepository;
  final RideRepository _rideRepository;
  final String _riderId;

  StreamSubscription? _profileSub;
  StreamSubscription? _ridesSub;
  List<String>? _currentIds; // null means "not yet received first update"

  ScheduledRidesCubit(
    this._riderRepository,
    this._rideRepository,
    this._riderId,
  ) : super(const ScheduledRidesLoading()) {
    _watchProfile();
  }

  void _watchProfile() {
    _profileSub = _riderRepository.watchRiderProfile(_riderId).listen(
      (profile) {
        final ids = profile?.scheduledRideIds ?? [];
        // Only re-subscribe to ride docs if the list actually changed.
        if (_currentIds == null || !_listEquals(ids, _currentIds!)) {
          _currentIds = ids;
          _watchRides(ids);
        }
      },
      onError: (e, _) => emit(ScheduledRidesError(e.toString())),
    );
  }

  void _watchRides(List<String> rideIds) {
    _ridesSub?.cancel();
    if (rideIds.isEmpty) {
      emit(const ScheduledRidesLoaded([]));
      return;
    }

    _ridesSub = _rideRepository.watchScheduledRides(rideIds).listen(
      (rides) => emit(ScheduledRidesLoaded(rides)),
      onError: (e, _) => emit(ScheduledRidesError(e.toString())),
    );
  }

  /// Cancel a scheduled ride from the rider side.
  Future<void> cancelScheduledRide(String rideId, String? customerId) async {
    try {
      await _rideRepository.cancelScheduledRide(
        rideId: rideId,
        riderId: _riderId,
        customerId: customerId,
      );
    } catch (e) {
      emit(ScheduledRidesError('Failed to cancel ride: $e'));
    }
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Future<void> close() async {
    await _profileSub?.cancel();
    await _ridesSub?.cancel();
    return super.close();
  }
}
