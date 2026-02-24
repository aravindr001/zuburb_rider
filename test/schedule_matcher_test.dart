import 'package:flutter_test/flutter_test.dart';
import 'package:zuburb_rider/models/availability_schedule.dart';
import 'package:zuburb_rider/models/rider_profile.dart';
import 'package:zuburb_rider/utils/schedule_matcher.dart';

/// Helper to build a minimal RiderProfile for testing.
RiderProfile _profile({
  bool isOnline = true,
  bool acceptsScheduledRides = true,
  String scheduleTimeZone = 'Asia/Kolkata',
  WeeklySchedule? schedule,
}) {
  return RiderProfile(
    id: 'test-rider',
    currentRideId: null,
    isOnline: isOnline,
    isAvailable: true,
    acceptsScheduledRides: acceptsScheduledRides,
    availabilitySchedule: schedule ?? emptySchedule(),
    scheduleTimeZone: scheduleTimeZone,
  );
}

void main() {
  group('isRiderAvailableForScheduled', () {
    test('returns false when rider is offline', () {
      final profile = _profile(isOnline: false);
      expect(
        isRiderAvailableForScheduled(DateTime.now().toUtc(), profile),
        isFalse,
      );
    });

    test('returns false when acceptsScheduledRides is false', () {
      final profile = _profile(acceptsScheduledRides: false);
      expect(
        isRiderAvailableForScheduled(DateTime.now().toUtc(), profile),
        isFalse,
      );
    });

    test('returns false when no slots for the day', () {
      // Empty schedule → no slots on any day.
      final profile = _profile();
      expect(
        isRiderAvailableForScheduled(DateTime.now().toUtc(), profile),
        isFalse,
      );
    });

    test('returns true when UTC time falls in slot after timezone conversion', () {
      // Asia/Kolkata is UTC+5:30.
      // If the rider has a Monday slot 10:00-18:00 IST, a request at
      // Monday 12:00 IST = Monday 06:30 UTC should match.
      final sched = emptySchedule();
      sched['monday'] = [const TimeSlot(start: '10:00', end: '18:00')];
      final profile = _profile(
        schedule: sched,
        scheduleTimeZone: 'Asia/Kolkata',
      );

      // Find the next Monday at 06:30 UTC → 12:00 IST.
      var dt = DateTime.utc(2025, 7, 7, 6, 30); // 2025-07-07 is a Monday
      expect(isRiderAvailableForScheduled(dt, profile), isTrue);
    });

    test('returns false when time is outside slot in rider timezone', () {
      final sched = emptySchedule();
      sched['monday'] = [const TimeSlot(start: '10:00', end: '12:00')];
      final profile = _profile(
        schedule: sched,
        scheduleTimeZone: 'Asia/Kolkata',
      );

      // Monday 14:00 IST = Monday 08:30 UTC → outside 10:00–12:00 slot.
      var dt = DateTime.utc(2025, 7, 7, 8, 30);
      expect(isRiderAvailableForScheduled(dt, profile), isFalse);
    });

    test('slot boundary: start inclusive, end exclusive', () {
      final sched = emptySchedule();
      sched['monday'] = [const TimeSlot(start: '10:00', end: '12:00')];
      final profile = _profile(
        schedule: sched,
        scheduleTimeZone: 'UTC',
      );

      // Exactly at start → should match.
      expect(
        isRiderAvailableForScheduled(DateTime.utc(2025, 7, 7, 10, 0), profile),
        isTrue,
      );
      // Exactly at end → should NOT match (exclusive).
      expect(
        isRiderAvailableForScheduled(DateTime.utc(2025, 7, 7, 12, 0), profile),
        isFalse,
      );
    });

    test('handles different timezone correctly (America/New_York)', () {
      // New York is UTC-4 in July (EDT).
      // Slot: Wednesday 09:00-17:00 ET → corresponds to Wednesday 13:00-21:00 UTC.
      final sched = emptySchedule();
      sched['wednesday'] = [const TimeSlot(start: '09:00', end: '17:00')];
      final profile = _profile(
        schedule: sched,
        scheduleTimeZone: 'America/New_York',
      );

      // Wednesday 2025-07-09 15:00 UTC → 11:00 ET → inside slot.
      expect(
        isRiderAvailableForScheduled(DateTime.utc(2025, 7, 9, 15, 0), profile),
        isTrue,
      );
      // Wednesday 2025-07-09 22:00 UTC → 18:00 ET → outside slot.
      expect(
        isRiderAvailableForScheduled(DateTime.utc(2025, 7, 9, 22, 0), profile),
        isFalse,
      );
    });
  });
}
