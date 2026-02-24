import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/availability_schedule.dart';
import '../../repository/rider_repository.dart';
import 'rider_availability_state.dart';

class RiderAvailabilityCubit extends Cubit<RiderAvailabilityState> {
  final RiderRepository _riderRepository;
  final String _riderId;
  StreamSubscription? _sub;

  RiderAvailabilityCubit(this._riderRepository, this._riderId)
      : super(const RiderAvailabilityLoading()) {
    _sub = _riderRepository.watchRiderProfile(_riderId).listen(
      (profile) {
        if (profile == null) {
          emit(const RiderAvailabilityError('Rider profile not found'));
          return;
        }

        // Only replace state if we're loading or if there's no local edit
        // in progress (isSaving).
        final current = state;
        if (current is RiderAvailabilityLoaded && current.isSaving) return;

        emit(RiderAvailabilityLoaded(
          isOnline: profile.isOnline,
          isAvailable: profile.isAvailable,
          acceptsScheduledRides: profile.acceptsScheduledRides,
          schedule: copySchedule(profile.availabilitySchedule),
          scheduleTimeZone: profile.scheduleTimeZone,
        ));
      },
      onError: (e, _) => emit(RiderAvailabilityError(e.toString())),
    );
  }

  // ─── Local toggles (update UI immediately, persist on save) ───

  void toggleOnline(bool value) {
    final s = _loaded;
    if (s == null) return;
    // Going offline forces isAvailable off.
    emit(s.copyWith(
      isOnline: value,
      isAvailable: value ? s.isAvailable : false,
    ));
  }

  void toggleAvailable(bool value) {
    final s = _loaded;
    if (s == null) return;
    // Can't be available if offline.
    if (!s.isOnline && value) return;
    emit(s.copyWith(isAvailable: value));
  }

  void toggleAcceptsScheduled(bool value) {
    final s = _loaded;
    if (s == null) return;
    emit(s.copyWith(acceptsScheduledRides: value));
  }

  void updateScheduleTimeZone(String tz) {
    final s = _loaded;
    if (s == null) return;
    emit(s.copyWith(scheduleTimeZone: tz));
  }

  // ─── Schedule slot management ───

  void addSlot(String day, TimeSlot slot) {
    final s = _loaded;
    if (s == null) return;
    final updated = copySchedule(s.schedule);
    final daySlots = updated[day] ?? [];
    if (daySlots.length >= 6) {
      emit(s.copyWith(errorMessage: 'Maximum 6 slots per day'));
      return;
    }
    daySlots.add(slot);
    updated[day] = daySlots;
    emit(s.copyWith(schedule: updated));
  }

  void removeSlot(String day, int index) {
    final s = _loaded;
    if (s == null) return;
    final updated = copySchedule(s.schedule);
    updated[day]?.removeAt(index);
    emit(s.copyWith(schedule: updated));
  }

  void updateSlot(String day, int index, TimeSlot slot) {
    final s = _loaded;
    if (s == null) return;
    final updated = copySchedule(s.schedule);
    final daySlots = updated[day];
    if (daySlots == null || index >= daySlots.length) return;
    daySlots[index] = slot;
    updated[day] = daySlots;
    emit(s.copyWith(schedule: updated));
  }

  // ─── Save to Firestore ───

  Future<void> save() async {
    final s = _loaded;
    if (s == null) return;

    // Validate schedule.
    final errors = validateSchedule(s.schedule);
    if (errors.isNotEmpty) {
      final msg = errors.entries
          .map((e) => '${_capitalize(e.key)}: ${e.value.join(', ')}')
          .join('\n');
      emit(s.copyWith(errorMessage: msg));
      return;
    }

    emit(s.copyWith(isSaving: true));

    try {
      await _riderRepository.updateAvailability(
        riderId: _riderId,
        isOnline: s.isOnline,
        isAvailable: s.isAvailable,
        acceptsScheduledRides: s.acceptsScheduledRides,
        schedule: s.schedule,
        scheduleTimeZone: s.scheduleTimeZone,
      );
      emit(s.copyWith(isSaving: false, successMessage: 'Saved'));
    } catch (e) {
      emit(s.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  // ─── Helpers ───

  RiderAvailabilityLoaded? get _loaded {
    final s = state;
    return s is RiderAvailabilityLoaded ? s : null;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
