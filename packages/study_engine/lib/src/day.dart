/// One calendar day in the Learner's local time zone on their device.
final class Day implements Comparable<Day> {
  const Day(this.year, this.month, this.day);

  /// The local calendar Day containing [moment].
  factory Day.of(DateTime moment) {
    final local = moment.toLocal();
    return Day(local.year, local.month, local.day);
  }

  final int year;
  final int month;
  final int day;

  @override
  int compareTo(Day other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is Day &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// Supplies the current Day. All Day logic goes through an injected Clock.
abstract interface class Clock {
  Day today();
}

/// Clock backed by the device's local time.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  Day today() => Day.of(DateTime.now());
}

/// Clock that always returns the same Day, for tests.
final class FixedClock implements Clock {
  FixedClock(this.day);

  Day day;

  @override
  Day today() => day;
}
