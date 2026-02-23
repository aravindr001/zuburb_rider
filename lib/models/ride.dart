import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  final String id;
  final GeoPoint pickup;
  final GeoPoint drop;
  final double distanceKm;
  final String? status;
  final String? pickupOtp;
  final bool pickupOtpVerified;

  const Ride({
    required this.id,
    required this.pickup,
    required this.drop,
    required this.distanceKm,
    required this.status,
    required this.pickupOtp,
    required this.pickupOtpVerified,
  });

  static Ride? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return null;

    final pickup = data['pickup'];
    final drop = data['drop'];

    if (pickup is! GeoPoint || drop is! GeoPoint) {
      throw StateError('Ride ${snapshot.id} has invalid pickup/drop');
    }

    final distanceRaw = data['distanceKm'];
    final distanceKm = switch (distanceRaw) {
      num v => v.toDouble(),
      _ => 0.0,
    };

    final pickupOtpRaw = data['pickupOtp'] ?? data['otp'];
    final pickupOtp = switch (pickupOtpRaw) {
      String s => s,
      int i => i.toString(),
      _ => null,
    };

    final pickupOtpVerifiedRaw =
        data['pickupOtpVerified'] ?? data['pickupVerified'];
    final pickupOtpVerified = pickupOtpVerifiedRaw == true ||
        (data['status'] as String?) == 'picked_up';

    return Ride(
      id: snapshot.id,
      pickup: pickup,
      drop: drop,
      distanceKm: distanceKm,
      status: data['status'] as String?,
      pickupOtp: pickupOtp,
      pickupOtpVerified: pickupOtpVerified,
    );
  }
}
