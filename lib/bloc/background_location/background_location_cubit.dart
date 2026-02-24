import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/background_location_service.dart';
import '../../services/notification_service.dart';
import 'background_location_state.dart';

const _batteryChannel = MethodChannel('zuburb_rider/battery');

class BackgroundLocationCubit extends Cubit<BackgroundLocationState> {
  final BackgroundLocationService _service;

  BackgroundLocationCubit({BackgroundLocationService? service})
      : _service = service ?? BackgroundLocationService.instance,
        super(const BackgroundLocationStopped());

  /// Start the background location service for [riderId].
  ///
  /// Checks that both location services and permissions (including
  /// background / "always") are available before launching the service.
  Future<void> start(String riderId) async {
    try {
      debugPrint('[BgLocationCubit] start() called for rider: $riderId');

      // 1. Location services enabled?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[BgLocationCubit] Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        emit(const BackgroundLocationError(
            'Location services are disabled. Please enable them.'));
        return;
      }

      // 2. Permission check → request if needed.
      var permission = await Geolocator.checkPermission();
      debugPrint('[BgLocationCubit] Location permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[BgLocationCubit] After request: $permission');
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(const BackgroundLocationError(
            'Location permission is required for background tracking.'));
        return;
      }

      // 3. Request notification permission (Android 13+).
      try {
        await NotificationService.instance.requestNotificationPermission();
      } catch (e) {
        debugPrint('[BgLocationCubit] Notification permission request failed: $e');
      }

      // 4. Request battery optimization exemption (Android only).
      if (Platform.isAndroid) {
        try {
          final isDisabled = await _batteryChannel
              .invokeMethod<bool>('isBatteryOptimizationDisabled');
          debugPrint('[BgLocationCubit] Battery opt disabled: $isDisabled');
          if (isDisabled != true) {
            await _batteryChannel
                .invokeMethod<bool>('requestDisableBatteryOptimization');
            // Wait for the user to respond to the system dialog.
            await Future.delayed(const Duration(seconds: 3));
          }
        } catch (e) {
          debugPrint('[BgLocationCubit] Battery optimization check failed: $e');
          // Don't block service start if this fails.
        }
      }

      // 5. Launch the foreground service.
      debugPrint('[BgLocationCubit] Starting background service...');
      await _service.start(riderId);
      debugPrint('[BgLocationCubit] Background service started.');
      emit(const BackgroundLocationRunning());
    } catch (e) {
      debugPrint('[BgLocationCubit] Error: $e');
      emit(BackgroundLocationError(e.toString()));
    }
  }

  /// Stop the background service (e.g. on logout).
  void stop() {
    _service.stop();
    emit(const BackgroundLocationStopped());
  }
}
