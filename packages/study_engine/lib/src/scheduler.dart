import 'day.dart';

/// When a Word in Review is next due, and in which Box.
final class WordSchedule {
  const WordSchedule({required this.box, required this.due});

  /// 1-based Box number.
  final int box;
  final Day due;

  @override
  bool operator ==(Object other) =>
      other is WordSchedule && other.box == box && other.due == due;

  @override
  int get hashCode => Object.hash(box, due);

  @override
  String toString() => 'Box $box, due $due';
}

/// Decides when Words come back for Review. Kept behind this interface so
/// the Box scheme can later be replaced by a better algorithm.
abstract interface class Scheduler {
  /// The schedule of a Word entering Review on [day].
  WordSchedule enter(Day day);

  /// The schedule after answering a Word in Review on [day].
  WordSchedule answered(
    WordSchedule current, {
    required bool correct,
    required Day day,
  });
}

/// Five Boxes, due again after 1, 3, 7, 14 or 30 Days. A correct answer moves
/// a Word up one Box (staying in the last); a wrong one sends it back to the
/// first.
final class BoxScheduler implements Scheduler {
  const BoxScheduler();

  static const intervals = [1, 3, 7, 14, 30];

  @override
  WordSchedule enter(Day day) => _inBox(1, day);

  @override
  WordSchedule answered(
    WordSchedule current, {
    required bool correct,
    required Day day,
  }) {
    final box = correct ? (current.box + 1).clamp(1, intervals.length) : 1;
    return _inBox(box, day);
  }

  WordSchedule _inBox(int box, Day from) =>
      WordSchedule(box: box, due: from.addDays(intervals[box - 1]));
}
