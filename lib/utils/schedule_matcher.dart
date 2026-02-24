import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../models/availability_schedule.dart';
import '../models/rider_profile.dart';

bool _tzInitialised = false;

void _ensureTzInit() {
  if (!_tzInitialised) {
    tz_data.initializeTimeZones();
    _tzInitialised = true;
  }
}

/// Check whether a rider is available for a *scheduled* ride at [scheduledAtUtc].
///
/// Returns `true` only when:
/// 1. `profile.isOnline == true`
/// 2. `profile.acceptsScheduledRides == true`
/// 3. The scheduled time (converted to the rider's `scheduleTimeZone`) falls
///    within one of the configured weekly time slots.
bool isRiderAvailableForScheduled(
  DateTime scheduledAtUtc,
  RiderProfile profile,
) {
  if (!profile.isOnline) return false;
  if (!profile.acceptsScheduledRides) return false;

  _ensureTzInit();

  final location = tz.getLocation(profile.scheduleTimeZone);
  final local = tz.TZDateTime.from(scheduledAtUtc.toUtc(), location);

  // DateTime.weekday: monday=1 … sunday=7. Map to our weekdayKeys index.
  final dayIndex = local.weekday - 1; // 0-based
  final dayKey = weekdayKeys[dayIndex];
  final slots = profile.availabilitySchedule[dayKey] ?? [];

  final minutesSinceMidnight = local.hour * 60 + local.minute;

  for (final slot in slots) {
    if (minutesSinceMidnight >= slot.startMinutes &&
        minutesSinceMidnight < slot.endMinutes) {
      return true;
    }
  }
  return false;
}
