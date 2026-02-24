import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android notification channel for ride request alerts.
const String rideRequestChannelId = 'ride_request_channel';
const String rideRequestChannelName = 'Ride Requests';
const String rideRequestChannelDesc =
    'Notifications for incoming ride requests';

const int _rideNotificationId = 999;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Call once from main(), after Firebase.initializeApp().
  Future<void> initialise() async {
    // ── Create a high-importance Android channel for ride alerts ──
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            rideRequestChannelId,
            rideRequestChannelName,
            description: rideRequestChannelDesc,
            importance: Importance.high,
          ),
        );

    // ── Initialise flutter_local_notifications ──
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    debugPrint('[Notification] NotificationService initialised');
  }

  /// Request POST_NOTIFICATIONS permission on Android 13+.
  /// On older Android or iOS this is a no-op.
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      debugPrint('[Notification] Current notification permission: $status');
      if (status.isDenied) {
        final result = await Permission.notification.request();
        debugPrint('[Notification] Notification permission result: $result');
        return result.isGranted;
      }
      return status.isGranted;
    }
    // iOS permission is handled by flutter_local_notifications init.
    return true;
  }

  /// Show a ride-request notification. Tapping it simply brings the app
  /// to the foreground; the existing persistence logic handles navigation.
  Future<void> showRideRequestNotification({
    String title = 'New Ride Request!',
    String body = 'You have a new ride request. Tap to open.',
  }) async {
    await _localNotifications.show(
      _rideNotificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          rideRequestChannelId,
          rideRequestChannelName,
          channelDescription: rideRequestChannelDesc,
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
    debugPrint('[Notification] Ride request notification shown');
  }

  /// Dismiss the ride notification (e.g. when rider opens the app).
  Future<void> dismissRideNotification() async {
    await _localNotifications.cancel(_rideNotificationId);
  }
}
