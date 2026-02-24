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

  /// Fetch a list of rides by their IDs.
  /// Firestore `whereIn` is limited to 30 values, so we chunk accordingly.
  Future<List<Ride>> fetchRidesByIds(List<String> rideIds) async {
    if (rideIds.isEmpty) return [];

    final rides = <Ride>[];
    // Firestore whereIn supports up to 30 items per query.
    const chunkSize = 30;
    for (var i = 0; i < rideIds.length; i += chunkSize) {
      final chunk = rideIds.sublist(
        i,
        i + chunkSize > rideIds.length ? rideIds.length : i + chunkSize,
      );
      final snap = await _firestore
          .collection('rides')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final ride = Ride.fromSnapshot(doc);
        if (ride != null) rides.add(ride);
      }
    }
    return rides;
  }

  /// Watch scheduled rides for a rider in real-time.
  /// Streams a list of rides whenever any of the ride docs change.
  Stream<List<Ride>> watchScheduledRides(List<String> rideIds) {
    if (rideIds.isEmpty) return Stream.value([]);

    // For simplicity, watch all in one query (up to 30).
    // If more, we fetch and combine.
    if (rideIds.length <= 30) {
      return _firestore
          .collection('rides')
          .where(FieldPath.documentId, whereIn: rideIds)
          .snapshots()
          .map((snap) {
        final rides = <Ride>[];
        for (final doc in snap.docs) {
          final ride = Ride.fromSnapshot(doc);
          if (ride != null) rides.add(ride);
        }
        // Sort by scheduledAt ascending.
        rides.sort((a, b) {
          final aTime = a.scheduledAt ?? DateTime(2100);
          final bTime = b.scheduledAt ?? DateTime(2100);
          return aTime.compareTo(bTime);
        });
        return rides;
      });
    }

    // Fallback for 30+ IDs: use periodic fetch.
    return Stream.periodic(const Duration(seconds: 15))
        .asyncMap((_) => fetchRidesByIds(rideIds))
        .map((rides) {
      rides.sort((a, b) {
        final aTime = a.scheduledAt ?? DateTime(2100);
        final bTime = b.scheduledAt ?? DateTime(2100);
        return aTime.compareTo(bTime);
      });
      return rides;
    });
  }

  /// Remove a scheduled ride ID from both rider and customer docs.
  /// Uses a batch for atomic consistency.
  Future<void> removeScheduledRideId({
    required String rideId,
    required String riderId,
    String? customerId,
  }) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('riders').doc(riderId),
      {'scheduledRideIds': FieldValue.arrayRemove([rideId])},
    );

    if (customerId != null && customerId.isNotEmpty) {
      batch.update(
        _firestore.collection('customers').doc(customerId),
        {'scheduledRideIds': FieldValue.arrayRemove([rideId])},
      );
    }

    await batch.commit();
  }

  /// Cancel a scheduled ride and clean up references.
  Future<void> cancelScheduledRide({
    required String rideId,
    required String riderId,
    String? customerId,
  }) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('rides').doc(rideId),
      {
        'status': 'cancelled',
        'canceledAt': FieldValue.serverTimestamp(),
      },
    );

    batch.update(
      _firestore.collection('riders').doc(riderId),
      {'scheduledRideIds': FieldValue.arrayRemove([rideId])},
    );

    if (customerId != null && customerId.isNotEmpty) {
      batch.update(
        _firestore.collection('customers').doc(customerId),
        {'scheduledRideIds': FieldValue.arrayRemove([rideId])},
      );
    }

    await batch.commit();
  }

  /// Activate a scheduled ride when its time is due.
  /// Changes ride status from 'scheduled' → 'requested' and assigns
  /// the rider's currentRideId so the existing incoming ride flow kicks in.
  Future<void> activateScheduledRide({
    required String rideId,
    required String riderId,
  }) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('rides').doc(rideId),
      {
        'status': 'requested',
        'activatedAt': FieldValue.serverTimestamp(),
      },
    );

    batch.update(
      _firestore.collection('riders').doc(riderId),
      {
        'currentRideId': rideId,
        'isAvailable': false,
      },
    );

    await batch.commit();
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
      'scheduledRideIds': FieldValue.arrayRemove([rideId]),
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
      'scheduledRideIds': FieldValue.arrayRemove([rideId]),
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
        'scheduledRideIds': FieldValue.arrayRemove([rideId]),
      });
    });
  }
}
