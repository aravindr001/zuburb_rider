import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'location_permission_state.dart';

class LocationPermissionCubit extends Cubit<LocationPermissionState> {
  LocationPermissionCubit() : super(const LocationPermissionInitial());

  bool _requestedOnce = false;

  Future<void> requestWhenInUseIfNeeded() async {
    if (_requestedOnce) return;
    _requestedOnce = true;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(const LocationPermissionServiceDisabled());
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    emit(mapGeolocatorPermissionToState(permission));
  }

  Future<void> refresh() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(const LocationPermissionServiceDisabled());
      return;
    }

    final permission = await Geolocator.checkPermission();
    emit(mapGeolocatorPermissionToState(permission));
  }

  Future<bool> openAppSettingsIfPermanentlyDenied() async {
    return Geolocator.openAppSettings();
  }
}
