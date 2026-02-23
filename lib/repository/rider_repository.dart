import 'package:cloud_firestore/cloud_firestore.dart';

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
    return _firestore.collection('rider_locations').doc(riderId).set({
      'location': GeoPoint(latitude, longitude),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
