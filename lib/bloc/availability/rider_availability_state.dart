import '../../models/availability_schedule.dart';

sealed class RiderAvailabilityState {
  const RiderAvailabilityState();
}

class RiderAvailabilityLoading extends RiderAvailabilityState {
  const RiderAvailabilityLoading();
}

class RiderAvailabilityLoaded extends RiderAvailabilityState {
  final bool isOnline;
  final bool isAvailable;
  final bool acceptsScheduledRides;
  final WeeklySchedule schedule;
  final String scheduleTimeZone;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const RiderAvailabilityLoaded({
    required this.isOnline,
    required this.isAvailable,
    required this.acceptsScheduledRides,
    required this.schedule,
    required this.scheduleTimeZone,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  RiderAvailabilityLoaded copyWith({
    bool? isOnline,
    bool? isAvailable,
    bool? acceptsScheduledRides,
    WeeklySchedule? schedule,
    String? scheduleTimeZone,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return RiderAvailabilityLoaded(
      isOnline: isOnline ?? this.isOnline,
      isAvailable: isAvailable ?? this.isAvailable,
      acceptsScheduledRides:
          acceptsScheduledRides ?? this.acceptsScheduledRides,
      schedule: schedule ?? this.schedule,
      scheduleTimeZone: scheduleTimeZone ?? this.scheduleTimeZone,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class RiderAvailabilityError extends RiderAvailabilityState {
  final String message;
  const RiderAvailabilityError(this.message);
}
