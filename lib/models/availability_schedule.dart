/// Represents a single time slot in a rider's weekly schedule.
class TimeSlot {
  final String start; // "HH:mm"
  final String end;   // "HH:mm"

  const TimeSlot({required this.start, required this.end});

  /// Parse "HH:mm" into total minutes since midnight.
  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int get startMinutes => _toMinutes(start);
  int get endMinutes => _toMinutes(end);

  /// Whether [hhmm] format is valid (00:00 – 23:59).
  static bool isValidFormat(String hhmm) {
    final re = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    return re.hasMatch(hhmm);
  }

  /// Validates that start < end and both are well-formed.
  bool get isValid =>
      isValidFormat(start) && isValidFormat(end) && startMinutes < endMinutes;

  /// Whether this slot overlaps with [other].
  bool overlaps(TimeSlot other) {
    return startMinutes < other.endMinutes && endMinutes > other.startMinutes;
  }

  Map<String, dynamic> toMap() => {'start': start, 'end': end};

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      start: map['start'] as String,
      end: map['end'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start–$end';
}

/// Weekday labels used as Firestore map keys.
const List<String> weekdayKeys = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

/// Alias for the weekly schedule map.
typedef WeeklySchedule = Map<String, List<TimeSlot>>;

/// Create an empty schedule with all days initialised.
WeeklySchedule emptySchedule() =>
    {for (final day in weekdayKeys) day: <TimeSlot>[]};

/// Deep-copy a schedule.
WeeklySchedule copySchedule(WeeklySchedule source) => {
      for (final entry in source.entries)
        entry.key: List<TimeSlot>.from(entry.value),
    };

/// Convert schedule to Firestore-compatible map.
Map<String, dynamic> scheduleToMap(WeeklySchedule schedule) => {
      for (final entry in schedule.entries)
        entry.key: entry.value.map((s) => s.toMap()).toList(),
    };

/// Parse schedule from Firestore map.
WeeklySchedule scheduleFromMap(Map<String, dynamic>? map) {
  final result = emptySchedule();
  if (map == null) return result;

  for (final day in weekdayKeys) {
    final slots = map[day];
    if (slots is List) {
      result[day] = slots
          .whereType<Map<String, dynamic>>()
          .map(TimeSlot.fromMap)
          .toList();
    }
  }
  return result;
}

/// Validate a day's slots: each valid, no overlaps, max [maxSlots].
List<String> validateDaySlots(List<TimeSlot> slots, {int maxSlots = 6}) {
  final errors = <String>[];

  if (slots.length > maxSlots) {
    errors.add('Maximum $maxSlots slots per day.');
  }

  for (var i = 0; i < slots.length; i++) {
    if (!slots[i].isValid) {
      errors.add('Slot ${i + 1} has invalid times.');
    }
    for (var j = i + 1; j < slots.length; j++) {
      if (slots[i].overlaps(slots[j])) {
        errors.add('Slot ${i + 1} overlaps with slot ${j + 1}.');
      }
    }
  }
  return errors;
}

/// Validate the entire weekly schedule.
Map<String, List<String>> validateSchedule(WeeklySchedule schedule) => {
      for (final entry in schedule.entries)
        if (validateDaySlots(entry.value).isNotEmpty)
          entry.key: validateDaySlots(entry.value),
    };
