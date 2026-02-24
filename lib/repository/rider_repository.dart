import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';

import '../models/availability_schedule.dart';
import '../models/rider_profile.dart';

class RiderRepository {
  final FirebaseFirestore _firestore;

  RiderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<RiderProfile?> watchRiderProfile(String riderId) {
    return _firestore
        .collection('riders')
        .doc(riderId)
        .snapshots()
        .map(RiderProfile.fromSnapshot);
  }

  /// One-time fetch to check if rider profile exists.
  Future<RiderProfile?> getRiderProfile(String riderId) async {
    final snap = await _firestore.collection('riders').doc(riderId).get();
    return RiderProfile.fromSnapshot(snap);
  }

  /// Create a brand-new rider profile document.
  Future<void> createRiderProfile({
    required String riderId,
    required String name,
    required String phone,
  }) {
    return _firestore.collection('riders').doc(riderId).set({
      'name': name,
      'phone': phone,
      'isOnline': false,
      'isAvailable': true,
      'acceptsScheduledRides': false,
      'availabilitySchedule': scheduleToMap(emptySchedule()),
      'scheduleTimeZone': 'Asia/Kolkata',
      'currentRideId': null,
      'rating': 0.0,
      'ratingCount': 0,
      'totalRides': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearCurrentRide(String riderId) {
    return _firestore.collection('riders').doc(riderId).update({
      'isAvailable': true,
      'currentRideId': null,
    });
  }

  Future<void> setOnlineStatus(String riderId, bool isOnline) {
    return _firestore.collection('riders').doc(riderId).update({
      'isOnline': isOnline,
    });
  }

  Future<void> updateRiderLocation(
      String riderId, double latitude, double longitude) {
    final geohash = GeoHasher().encode(longitude, latitude, precision: 9);
    return _firestore.collection('rider_locations').doc(riderId).set({
      'location': GeoPoint(latitude, longitude),
      'geohash': geohash,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update availability-related fields (merge, preserves other fields).
  Future<void> updateAvailability({
    required String riderId,
    required bool isOnline,
    required bool isAvailable,
    required bool acceptsScheduledRides,
    required WeeklySchedule schedule,
    required String scheduleTimeZone,
  }) {
    return _firestore.collection('riders').doc(riderId).set({
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'acceptsScheduledRides': acceptsScheduledRides,
      'availabilitySchedule': scheduleToMap(schedule),
      'scheduleTimeZone': scheduleTimeZone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
