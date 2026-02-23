import 'package:geolocator/geolocator.dart';

sealed class LocationPermissionState {
  const LocationPermissionState();
}

class LocationPermissionInitial extends LocationPermissionState {
  const LocationPermissionInitial();
}

class LocationPermissionGranted extends LocationPermissionState {
  const LocationPermissionGranted();
}

class LocationPermissionDenied extends LocationPermissionState {
  const LocationPermissionDenied();
}

class LocationPermissionPermanentlyDenied extends LocationPermissionState {
  const LocationPermissionPermanentlyDenied();
}

class LocationPermissionServiceDisabled extends LocationPermissionState {
  const LocationPermissionServiceDisabled();
}

LocationPermissionState mapGeolocatorPermissionToState(
  LocationPermission permission,
) {
  return switch (permission) {
    LocationPermission.always || LocationPermission.whileInUse =>
      const LocationPermissionGranted(),
    LocationPermission.deniedForever =>
      const LocationPermissionPermanentlyDenied(),
    LocationPermission.denied => const LocationPermissionDenied(),
    // Fallback for any future enum values.
    _ => const LocationPermissionDenied(),
  };
}
