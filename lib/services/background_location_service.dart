import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

const String _notificationChannelId = 'rider_location_channel';
const int _notificationId = 888;

class BackgroundLocationService {
  BackgroundLocationService._();
  static final BackgroundLocationService instance =
      BackgroundLocationService._();

  final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Call once from main() before runApp.
  Future<void> initialise() async {
    final notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Create the Android notification channel for the foreground service.
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _notificationChannelId,
            'Rider Location Service',
            description: 'Used for background rider location tracking',
            importance: Importance.low,
          ),
        );

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'Zuburb Rider',
        initialNotificationContent: 'Location service ready',
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  /// Start the background service for [riderId].
  Future<void> start(String riderId) async {
    final running = await _service.isRunning();
    debugPrint('[BgService] isRunning=$running, starting for rider=$riderId');
    if (running) {
      // Stop the old service first so a fresh isolate picks up the new rider id.
      _service.invoke('stopService');
      await Future.delayed(const Duration(seconds: 1));
    }
    await _service.startService();
    // Give the background isolate time to spin up and register listeners.
    await Future.delayed(const Duration(seconds: 4));
    debugPrint('[BgService] Sending setRiderId to background isolate');
    _service.invoke('setRiderId', {'riderId': riderId});
  }

  /// Stop the background service (e.g. on logout).
  void stop() {
    _service.invoke('stopService');
  }
}

// ---------------------------------------------------------------------------
// Everything below runs in its own isolate (Android) / on the main isolate
// (iOS). It cannot share memory with the Flutter UI.
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  String? riderId;
  Timer? locationTimer;
  StreamSubscription<DocumentSnapshot>? riderSub;
  StreamSubscription<DocumentSnapshot>? rideSub;
  FirebaseFirestore? firestore;
  String? lastNotifiedRideId;

  // Register the listener FIRST so we never miss the event from the UI.
  service.on('setRiderId').listen((event) async {
    final id = event?['riderId'] as String?;
    debugPrint('[BgLocation] setRiderId received: $id');
    if (id == null || id == riderId) return;
    riderId = id;

    // Ensure Firebase is ready.
    if (firestore == null) {
      await Firebase.initializeApp();
      firestore = FirebaseFirestore.instance;
      debugPrint('[BgLocation] Firebase initialised in background isolate');
    }

    // Cancel any previous Firestore listener.
    riderSub?.cancel();

    // Listen to the rider's document in real-time.
    riderSub = firestore!
        .collection('riders')
        .doc(riderId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      final isOnline = data?['isOnline'] as bool? ?? false;
      final currentRideId = data?['currentRideId'] as String?;
      debugPrint('[BgLocation] isOnline=$isOnline, currentRideId=$currentRideId for rider $riderId');

      // ── Ride notification logic ──
      if (currentRideId != null && currentRideId != lastNotifiedRideId) {
        lastNotifiedRideId = currentRideId;
        _showRideNotification(firestore!, currentRideId);
      } else if (currentRideId == null) {
        lastNotifiedRideId = null;
        rideSub?.cancel();
        rideSub = null;
      }

      // ── Location tracking logic ──

      locationTimer?.cancel();
      locationTimer = null;

      if (isOnline) {
        // Update immediately, then every 10 seconds.
        _updateLocation(firestore!, riderId!);
        locationTimer =
            Timer.periodic(const Duration(seconds: 10), (_) {
          _updateLocation(firestore!, riderId!);
        });
        _setNotification(service, 'You are online – location tracking active');
      } else {
        _setNotification(service, 'You are offline');
      }
    });
  });

  // Called from the UI isolate to tear everything down.
  service.on('stopService').listen((_) {
    debugPrint('[BgLocation] stopService received');
    locationTimer?.cancel();
    riderSub?.cancel();
    rideSub?.cancel();
    service.stopSelf();
  });
}

Future<void> _updateLocation(
    FirebaseFirestore firestore, String riderId) async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final geohash = GeoHasher().encode(position.longitude, position.latitude, precision: 9);

    await firestore.collection('rider_locations').doc(riderId).set({
      'location': GeoPoint(position.latitude, position.longitude),
      'geohash': geohash,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('[BgLocation] Location updated: ${position.latitude}, ${position.longitude}');
  } catch (e) {
    debugPrint('[BgLocation] Location update error: $e');
  }
}

void _setNotification(ServiceInstance service, String content) {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Zuburb Rider',
      content: content,
    );
  }
}

/// Show a local notification when a new ride is assigned.
Future<void> _showRideNotification(
    FirebaseFirestore firestore, String rideId) async {
  try {
    final plugin = FlutterLocalNotificationsPlugin();

    // Ensure the ride-request channel exists in this isolate.
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'ride_request_channel',
            'Ride Requests',
            description: 'Notifications for incoming ride requests',
            importance: Importance.high,
          ),
        );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await plugin.show(
      999,
      'New Ride Request!',
      'You have a new ride request. Tap to open.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ride_request_channel',
          'Ride Requests',
          channelDescription: 'Notifications for incoming ride requests',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    debugPrint('[BgLocation] Ride notification shown for ride $rideId');
  } catch (e) {
    debugPrint('[BgLocation] Failed to show ride notification: $e');
  }
}
