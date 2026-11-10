/// One calendar day in the Learner's local time zone on their device.
final class Day implements Comparable<Day> {
  const Day(this.year, this.month, this.day);

  /// The local calendar Day containing [moment].
  factory Day.of(DateTime moment) {
    final local = moment.toLocal();
    return Day(local.year, local.month, local.day);
  }

  /// Parses the `YYYY-MM-DD` form produced by [toString].
  /// Rejects anything that is not a real calendar Day, such as 2026-11-31.
  factory Day.parse(String text) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) throw FormatException('Not a Day', text);
    final day = Day(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
    if (day.addDays(0) != day) throw FormatException('Not a Day', text);
    return day;
  }

  final int year;
  final int month;
  final int day;

  /// The Day [days] calendar days after this one (before, if negative).
  /// Calculated in UTC so daylight-saving changes cannot skip or repeat a Day.
  Day addDays(int days) {
    final moved = DateTime.utc(year, month, day + days);
    return Day(moved.year, moved.month, moved.day);
  }

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
  /// [now] defaults to the device's current time; tests pass a fixed moment.
  const SystemClock({this.now = DateTime.now});

  final DateTime Function() now;

  @override
  Day today() => Day.of(now());
}

/// Clock that always returns the same Day, for tests.
final class FixedClock implements Clock {
  FixedClock(this.day);

  Day day;

  @override
  Day today() => day;
}
