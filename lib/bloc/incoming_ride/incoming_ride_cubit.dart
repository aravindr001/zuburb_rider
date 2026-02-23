import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/ride_repository.dart';
import 'incoming_ride_state.dart';

class IncomingRideCubit extends Cubit<IncomingRideState> {
  final RideRepository _rideRepository;
  final String _rideId;
  final String _riderId;
  StreamSubscription? _sub;

  bool _accepting = false;

  IncomingRideCubit(this._rideRepository, {required String rideId, required String riderId})
      : _rideId = rideId,
        _riderId = riderId,
        super(const IncomingRideLoading()) {
    _sub = _rideRepository.watchRide(_rideId).listen(
      (ride) {
        if (ride == null) {
          emit(const IncomingRideNotFound());
          return;
        }

        // While accepting, the ride will typically transition to 'accepted'.
        // That should not be treated as "not found".
        if (_accepting && ride.status == 'accepted') {
          emit(const IncomingRideCompleted('accepted'));
          return;
        }

        if (ride.status != 'requested') {
          emit(const IncomingRideNotFound());
          return;
        }

        emit(IncomingRideLoaded(ride: ride));
      },
      onError: (e, _) => emit(IncomingRideError(e.toString())),
    );
  }

  Future<void> accept() async {
    _accepting = true;
    final current = state;
    if (current is IncomingRideLoaded) {
      emit(IncomingRideLoaded(ride: current.ride, actionInProgress: true));
    }

    try {
      await _rideRepository.acceptRide(rideId: _rideId, riderId: _riderId);
      emit(const IncomingRideCompleted('accepted'));
    } catch (e) {
      _accepting = false;
      emit(IncomingRideError(e.toString()));
    }
  }

  Future<void> reject() async {
    final current = state;
    if (current is IncomingRideLoaded) {
      emit(IncomingRideLoaded(ride: current.ride, actionInProgress: true));
    }

    try {
      await _rideRepository.rejectRide(rideId: _rideId, riderId: _riderId);
      emit(const IncomingRideCompleted('rejected'));
    } catch (e) {
      emit(IncomingRideError(e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
