import 'package:flutter_test/flutter_test.dart';
import 'package:zuburb_rider/models/availability_schedule.dart';

void main() {
  group('TimeSlot', () {
    group('isValid', () {
      test('valid slot', () {
        const slot = TimeSlot(start: '09:00', end: '17:00');
        expect(slot.isValid, isTrue);
      });

      test('start equals end is invalid', () {
        const slot = TimeSlot(start: '10:00', end: '10:00');
        expect(slot.isValid, isFalse);
      });

      test('start after end is invalid', () {
        const slot = TimeSlot(start: '18:00', end: '09:00');
        expect(slot.isValid, isFalse);
      });

      test('bad format is invalid', () {
        const slot = TimeSlot(start: '25:00', end: '09:00');
        expect(slot.isValid, isFalse);
      });

      test('midnight edge case', () {
        const slot = TimeSlot(start: '00:00', end: '23:59');
        expect(slot.isValid, isTrue);
      });
    });

    group('overlaps', () {
      test('overlapping slots', () {
        const a = TimeSlot(start: '09:00', end: '12:00');
        const b = TimeSlot(start: '11:00', end: '14:00');
        expect(a.overlaps(b), isTrue);
        expect(b.overlaps(a), isTrue);
      });

      test('adjacent slots do not overlap', () {
        const a = TimeSlot(start: '09:00', end: '12:00');
        const b = TimeSlot(start: '12:00', end: '14:00');
        expect(a.overlaps(b), isFalse);
      });

      test('contained slot overlaps', () {
        const a = TimeSlot(start: '08:00', end: '18:00');
        const b = TimeSlot(start: '10:00', end: '12:00');
        expect(a.overlaps(b), isTrue);
        expect(b.overlaps(a), isTrue);
      });

      test('completely disjoint', () {
        const a = TimeSlot(start: '06:00', end: '08:00');
        const b = TimeSlot(start: '14:00', end: '16:00');
        expect(a.overlaps(b), isFalse);
      });
    });

    group('serialization', () {
      test('toMap / fromMap round-trip', () {
        const slot = TimeSlot(start: '09:30', end: '17:45');
        final restored = TimeSlot.fromMap(slot.toMap());
        expect(restored, equals(slot));
      });
    });
  });

  group('validateDaySlots', () {
    test('empty list has no errors', () {
      expect(validateDaySlots([]), isEmpty);
    });

    test('valid non-overlapping slots pass', () {
      const slots = [
        TimeSlot(start: '06:00', end: '10:00'),
        TimeSlot(start: '14:00', end: '18:00'),
      ];
      expect(validateDaySlots(slots), isEmpty);
    });

    test('overlapping slots produce error', () {
      const slots = [
        TimeSlot(start: '08:00', end: '12:00'),
        TimeSlot(start: '11:00', end: '15:00'),
      ];
      final errors = validateDaySlots(slots);
      expect(errors, isNotEmpty);
      expect(errors.first, contains('overlaps'));
    });

    test('too many slots produce error', () {
      final slots = List.generate(
        7,
        (i) => TimeSlot(
          start: '${i.toString().padLeft(2, '0')}:00',
          end: '${i.toString().padLeft(2, '0')}:30',
        ),
      );
      final errors = validateDaySlots(slots);
      expect(errors.any((e) => e.contains('Maximum')), isTrue);
    });

    test('invalid slot format produces error', () {
      const slots = [TimeSlot(start: '25:00', end: '26:00')];
      final errors = validateDaySlots(slots);
      expect(errors.any((e) => e.contains('invalid')), isTrue);
    });
  });

  group('validateSchedule', () {
    test('empty schedule is valid', () {
      expect(validateSchedule(emptySchedule()), isEmpty);
    });

    test('schedule with one bad day returns that day', () {
      final sched = emptySchedule();
      sched['monday'] = [
        const TimeSlot(start: '08:00', end: '12:00'),
        const TimeSlot(start: '11:00', end: '15:00'), // overlaps
      ];
      final errors = validateSchedule(sched);
      expect(errors.containsKey('monday'), isTrue);
      expect(errors['monday']!.first, contains('overlaps'));
      expect(errors.containsKey('tuesday'), isFalse);
    });
  });

  group('scheduleToMap / scheduleFromMap', () {
    test('round-trip preserves data', () {
      final sched = emptySchedule();
      sched['wednesday'] = [
        const TimeSlot(start: '10:00', end: '14:00'),
      ];
      final map = scheduleToMap(sched);
      final restored = scheduleFromMap(map);
      expect(restored['wednesday']!.length, 1);
      expect(restored['wednesday']!.first.start, '10:00');
    });

    test('fromMap with null returns empty schedule', () {
      final sched = scheduleFromMap(null);
      expect(sched.keys.length, weekdayKeys.length);
      for (final day in weekdayKeys) {
        expect(sched[day], isEmpty);
      }
    });
  });
}
