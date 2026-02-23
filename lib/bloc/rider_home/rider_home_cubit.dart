import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/ride_repository.dart';
import '../../repository/rider_repository.dart';
import 'rider_home_state.dart';

class RiderHomeCubit extends Cubit<RiderHomeState> {
  final RiderRepository _riderRepository;
  final RideRepository _rideRepository;
  final String _riderId;
  StreamSubscription? _sub;
  StreamSubscription? _rideSub;
  String? _activeRideId;

  RiderHomeCubit(this._riderRepository, this._rideRepository, this._riderId)
      : super(const RiderHomeLoading()) {
    _sub = _riderRepository.watchRiderProfile(_riderId).listen(
      (profile) {
        final rideId = profile?.currentRideId;
        if (rideId == null) {
          _activeRideId = null;
          _rideSub?.cancel();
          _rideSub = null;
          emit(const RiderHomeWaiting());
        } else {
          if (_activeRideId == rideId) return;
          _activeRideId = rideId;

          _rideSub?.cancel();
          _rideSub = _rideRepository.watchRide(rideId).listen(
            (ride) {
              if (ride != null && ride.status == 'requested') {
                emit(RiderHomeIncomingRide(rideId));
              } else {
                emit(const RiderHomeWaiting());
              }
            },
            onError: (e, _) => emit(RiderHomeError(e.toString())),
          );
        }
      },
      onError: (e, _) => emit(RiderHomeError(e.toString())),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _rideSub?.cancel();
    return super.close();
  }
}
