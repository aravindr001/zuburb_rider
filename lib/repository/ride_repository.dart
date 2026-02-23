import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ride.dart';

class RideRepository {
  final FirebaseFirestore _firestore;

  RideRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<Ride?> watchRide(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .map(Ride.fromSnapshot);
  }

  Future<void> acceptRide({required String rideId, required String riderId}) {
    return _firestore.collection('rides').doc(rideId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'riderId': riderId,
    });
  }

  Future<void> markArrivedAtPickup({required String rideId}) async {
    final rideRef = _firestore.collection('rides').doc(rideId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(rideRef);
      final data = snap.data();
      if (data == null) {
        throw StateError('Ride not found');
      }

      final status = data['status'] as String?;
      if (status == 'cancelled' || status == 'rejected') {
        throw StateError('Ride is not active');
      }

      if (status == 'arrived_pickup' || status == 'picked_up') {
        return;
      }

      tx.update(rideRef, {
        'status': 'arrived_pickup',
        'arrivedAtPickupAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectRide({required String rideId, required String riderId}) async {
    await _firestore.collection('rides').doc(rideId).update({
      'status': 'rejected',
    });

    await _firestore.collection('riders').doc(riderId).update({
      'isAvailable': true,
      'currentRideId': null,
    });
  }

  Future<void> cancelRide({required String rideId, required String riderId}) async {
    await _firestore.collection('rides').doc(rideId).update({
      'status': 'cancelled',
      'canceledAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('riders').doc(riderId).update({
      'isAvailable': true,
      'currentRideId': null,
    });
  }

  Future<void> verifyPickupOtp({required String rideId, required String otp}) async {
    final snap = await _firestore.collection('rides').doc(rideId).get();
    final data = snap.data();
    if (data == null) {
      throw StateError('Ride not found');
    }

    final expectedRaw = data['pickupOtp'] ?? data['otp'];
    final expected = switch (expectedRaw) {
      String s => s.trim(),
      int i => i.toString(),
      _ => null,
    };
    if (expected == null || expected.isEmpty) {
      throw StateError('Pickup OTP is not set');
    }

    if (otp.trim() != expected) {
      throw StateError('Invalid OTP');
    }

    await _firestore.collection('rides').doc(rideId).update({
      'pickupOtpVerified': true,
      'pickupOtpVerifiedAt': FieldValue.serverTimestamp(),
      'status': 'picked_up',
      'pickedUpAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeDropoff({required String rideId, required String riderId}) async {
    final rideRef = _firestore.collection('rides').doc(rideId);
    final riderRef = _firestore.collection('riders').doc(riderId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(rideRef);
      final data = snap.data();
      if (data == null) {
        throw StateError('Ride not found');
      }

      final status = data['status'] as String?;
      if (status == 'cancelled' || status == 'rejected') {
        throw StateError('Ride is not active');
      }

      if (status == 'completed') {
        return;
      }

      tx.update(rideRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      tx.update(riderRef, {
        'isAvailable': true,
        'currentRideId': null,
        'totalRides': FieldValue.increment(1),
      });
    });
  }
}
