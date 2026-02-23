import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/rider_repository.dart';

class RiderOnlineCubit extends Cubit<bool> {
  final RiderRepository _riderRepository;
  final String _riderId;
  StreamSubscription? _sub;

  RiderOnlineCubit(this._riderRepository, this._riderId) : super(false) {
    _sub = _riderRepository.watchRiderProfile(_riderId).listen(
      (profile) => emit(profile?.isOnline ?? false),
      onError: (error, stackTrace) {},
    );
  }

  Future<void> setOnline(bool isOnline) {
    return _riderRepository.setOnlineStatus(_riderId, isOnline);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
