import 'package:cloud_firestore/cloud_firestore.dart';

class RiderProfile {
  final String id;
  final String? currentRideId;
  final bool isOnline;
  final bool isAvailable;

  const RiderProfile({
    required this.id,
    required this.currentRideId,
    required this.isOnline,
    required this.isAvailable,
  });

  static RiderProfile? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return null;

    return RiderProfile(
      id: snapshot.id,
      currentRideId: data['currentRideId'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      isAvailable: data['isAvailable'] as bool? ?? true,
    );
  }
}
