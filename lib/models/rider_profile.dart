import 'package:cloud_firestore/cloud_firestore.dart';

import 'availability_schedule.dart';

class RiderProfile {
  final String id;
  final String? name;
  final String? phone;
  final String? currentRideId;
  final bool isOnline;
  final bool isAvailable;
  final bool acceptsScheduledRides;
  final WeeklySchedule availabilitySchedule;
  final String scheduleTimeZone;
  final List<String> scheduledRideIds;

  const RiderProfile({
    required this.id,
    this.name,
    this.phone,
    required this.currentRideId,
    required this.isOnline,
    required this.isAvailable,
    this.acceptsScheduledRides = false,
    required this.availabilitySchedule,
    this.scheduleTimeZone = 'Asia/Kolkata',
    this.scheduledRideIds = const [],
  });

  /// Whether the rider has completed their initial profile setup.
  bool get isProfileComplete =>
      name != null && name!.trim().isNotEmpty;

  static RiderProfile? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return null;

    return RiderProfile(
      id: snapshot.id,
      name: data['name'] as String?,
      phone: data['phone'] as String?,
      currentRideId: data['currentRideId'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      isAvailable: data['isAvailable'] as bool? ?? true,
      acceptsScheduledRides: data['acceptsScheduledRides'] as bool? ?? false,
      availabilitySchedule: scheduleFromMap(
        data['availabilitySchedule'] as Map<String, dynamic>?,
      ),
      scheduleTimeZone: data['scheduleTimeZone'] as String? ?? 'Asia/Kolkata',
      scheduledRideIds: (data['scheduledRideIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}
