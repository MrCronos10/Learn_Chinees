import 'package:study_engine/study_engine.dart';
import 'package:test/test.dart';

void main() {
  test('a Day round-trips through its text form', () {
    expect(Day.parse(const Day(2026, 3, 5).toString()), const Day(2026, 3, 5));
  });

  for (final bad in ['2026-13-01', '2026-11-31', '2026-02-29', '2026-11', '']) {
    test('"$bad" is not a Day', () {
      expect(() => Day.parse(bad), throwsFormatException);
    });
  }
}
