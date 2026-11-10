import 'package:study_engine/study_engine.dart';
import 'package:test/test.dart';

import 'helpers.dart';
import 'progress_backends.dart';

void main() {
  for (final backend in progressBackends) {
    group('with ${backend.name} Learner Progress:', () {
      setUp(backend.setUp);
      tearDown(backend.tearDown);

      /// The moment the injected clock reports; tests move it forward.
      late DateTime now;

      StudyEngine engineOn(LearnerProgressStore progress) => StudyEngine(
        content: InMemoryCourseContent([lessonOf(5, id: 'a')]),
        progress: progress,
        clock: SystemClock(now: () => now),
      );

      /// Finishes Lesson a at [moment] (local time), passed unless [fail].
      Future<void> finishAt(DateTime moment, {bool fail = false}) async {
        now = moment;
        final engine = engineOn(backend.store);
        await play(await engine.startLesson('a'), wrongCount: fail ? 3 : 0);
      }

      Future<int> streakAt(DateTime moment) {
        now = moment;
        return engineOn(backend.store).currentStreak();
      }

      test('is 0 before any Lesson is finished', () async {
        expect(await streakAt(DateTime(2026, 11, 10, 9)), 0);
      });

      test('the first finished Lesson ever gives a Streak of 1', () async {
        await finishAt(DateTime(2026, 11, 10, 9));

        expect(await streakAt(DateTime(2026, 11, 10, 9, 5)), 1);
      });

      test('a failed Lesson counts too', () async {
        await finishAt(DateTime(2026, 11, 10, 9), fail: true);

        expect(await streakAt(DateTime(2026, 11, 10, 9, 5)), 1);
      });

      test('finishing a Lesson on the next Day adds 1', () async {
        await finishAt(DateTime(2026, 11, 10, 9));
        await finishAt(DateTime(2026, 11, 11, 18));

        expect(await streakAt(DateTime(2026, 11, 11, 18, 5)), 2);
      });

      test('several finished Lessons in one Day count once', () async {
        await finishAt(DateTime(2026, 11, 10, 9));
        await finishAt(DateTime(2026, 11, 10, 12));
        await finishAt(DateTime(2026, 11, 10, 21));

        expect(await streakAt(DateTime(2026, 11, 10, 22)), 1);
      });

      test(
        'missing a Day resets the Streak on the next finished Lesson',
        () async {
          await finishAt(DateTime(2026, 11, 9, 9));
          await finishAt(DateTime(2026, 11, 10, 9));
          await finishAt(DateTime(2026, 11, 12, 9)); // 11th missed

          expect(await streakAt(DateTime(2026, 11, 12, 10)), 1);
        },
      );

      test('still shows the Streak the Day after, before studying', () async {
        await finishAt(DateTime(2026, 11, 9, 9));
        await finishAt(DateTime(2026, 11, 10, 9));

        expect(await streakAt(DateTime(2026, 11, 11, 8)), 2);
      });

      test('shows 0 once a whole Day has been missed', () async {
        await finishAt(DateTime(2026, 11, 9, 9));
        await finishAt(DateTime(2026, 11, 10, 9));

        expect(await streakAt(DateTime(2026, 11, 12, 8)), 0);
      });

      test(
        'the Day changes at local midnight: 23:50 then 00:10 is 2 Days',
        () async {
          await finishAt(DateTime(2026, 11, 10, 23, 50));
          await finishAt(DateTime(2026, 11, 11, 0, 10));

          expect(await streakAt(DateTime(2026, 11, 11, 0, 15)), 2);
        },
      );

      test('00:10 then 23:50 on the same Day is 1 Day', () async {
        await finishAt(DateTime(2026, 11, 10, 0, 10));
        await finishAt(DateTime(2026, 11, 10, 23, 50));

        expect(await streakAt(DateTime(2026, 11, 10, 23, 55)), 1);
      });

      test('counts across a month end', () async {
        await finishAt(DateTime(2026, 11, 30, 9));
        await finishAt(DateTime(2026, 12, 1, 9));

        expect(await streakAt(DateTime(2026, 12, 1, 10)), 2);
      });

      test('counts across a year end', () async {
        await finishAt(DateTime(2026, 12, 31, 9));
        await finishAt(DateTime(2027, 1, 1, 9));

        expect(await streakAt(DateTime(2027, 1, 1, 10)), 2);
      });

      test('counts across a leap day', () async {
        await finishAt(DateTime(2028, 2, 28, 9));
        await finishAt(DateTime(2028, 2, 29, 9));
        await finishAt(DateTime(2028, 3, 1, 9));

        expect(await streakAt(DateTime(2028, 3, 1, 10)), 3);
      });

      test('quitting a Lesson midway does not count', () async {
        now = DateTime(2026, 11, 10, 9);
        final session = await engineOn(backend.store).startLesson('a');
        for (var i = 0; i < 4; i++) {
          session.answer(session.current!.answer);
        }

        expect(await streakAt(DateTime(2026, 11, 10, 9, 5)), 0);
      });

      test('survives an app restart', () async {
        if (!backend.persistent) {
          return markTestSkipped('in-memory progress does not outlive the app');
        }
        await finishAt(DateTime(2026, 11, 9, 9));
        await finishAt(DateTime(2026, 11, 10, 9));
        backend.restart();

        expect(await streakAt(DateTime(2026, 11, 10, 10)), 2);
      });
    });
  }
}
