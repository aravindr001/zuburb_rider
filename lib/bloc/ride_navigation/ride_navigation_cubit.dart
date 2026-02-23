import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../repository/directions_repository.dart';
import '../../platform/maps_api_key_provider.dart';
import '../../utils/polyline_codec.dart';
import 'ride_navigation_state.dart';

class RideNavigationCubit extends Cubit<RideNavigationState> {
  final DirectionsRepository _directionsRepository;

  RideNavigationCubit(this._directionsRepository)
      : super(const RideNavigationLoading());

  Future<LocationPermission> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<void> load({required LatLng pickupLocation}) async {
    emit(const RideNavigationLoading());

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw StateError('Location service is disabled');
      }

      final permission = await _ensurePermission();

      if (permission == LocationPermission.denied) {
        throw StateError('Location permission denied');
      }
      if (permission == LocationPermission.deniedForever) {
        throw StateError('Location permission permanently denied');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final rider = LatLng(pos.latitude, pos.longitude);

      final markers = <Marker>{
        Marker(
          markerId: const MarkerId('rider'),
          position: rider,
          infoWindow: const InfoWindow(title: 'You'),
        ),
      };

      final polylines = <Polyline>{};

      final apiKey = await MapsApiKeyProvider.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw StateError('Missing Google Maps API key (native config)');
      }

      final polylineEncoded = await _directionsRepository.fetchOverviewPolyline(
        apiKey: apiKey,
        originLat: rider.latitude,
        originLng: rider.longitude,
        destinationLat: pickupLocation.latitude,
        destinationLng: pickupLocation.longitude,
      );

      if (polylineEncoded != null && polylineEncoded.isNotEmpty) {
        final points = PolylineCodec.decode(polylineEncoded);
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            width: 5,
          ),
        );
      }

      emit(
        RideNavigationLoaded(
          riderLocation: rider,
          pickupLocation: pickupLocation,
          markers: markers,
          polylines: polylines,
        ),
      );
    } catch (e) {
      emit(RideNavigationError(e.toString()));
    }
  }
}
