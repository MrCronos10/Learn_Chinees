import 'package:study_engine/study_engine.dart';
import 'package:test/test.dart';

import 'helpers.dart';
import 'progress_backends.dart';

/// Lesson a teaches Words 1-5, Lesson b teaches Words 6-10.
final lessons = [
  lessonOf(5, id: 'a', firstWordId: 1),
  lessonOf(5, id: 'b', firstWordId: 6),
];

const day0 = Day(2026, 11, 10);

void main() {
  for (final backend in progressBackends) {
    group('with ${backend.name} Learner Progress:', () {
      setUp(backend.setUp);
      tearDown(backend.tearDown);

      final clock = FixedClock(day0);
      setUp(() => clock.day = day0);

      StudyEngine engineOn({
        LearnerProgressStore? progress,
        List<Lesson>? content,
      }) => StudyEngine(
        content: InMemoryCourseContent(content ?? lessons),
        progress: progress ?? backend.store,
        clock: clock,
      );

      Future<int> dueOn(Day day) {
        clock.day = day;
        return engineOn().wordsDueToday();
      }

      /// Reviews on [day], answering the Words in [wrong] wrong first.
      Future<ReviewResult> reviewOn(
        Day day, {
        Set<int> wrong = const {},
      }) async {
        clock.day = day;
        final session = (await engineOn().startReview())!;
        return playAnswering(
          session,
          (exercise, _) => !wrong.contains(exercise.word!.id),
        );
      }

      Future<void> passLessonOn(Day day, String lessonId) async {
        clock.day = day;
        final engine = engineOn();
        final result = await play(await engine.startLesson(lessonId));
        expect(result.passed, isTrue);
      }

      group('Words enter Review', () {
        test('not before any Lesson is passed', () async {
          expect(await dueOn(day0), 0);
          expect(await engineOn().startReview(), isNull);
        });

        test('in the first Box, due the next Day, when their Lesson is '
            'passed', () async {
          await passLessonOn(day0, 'a');

          expect(await dueOn(day0), 0);
          expect(await dueOn(day0.addDays(1)), 5);
        });

        test('not when their Lesson is failed', () async {
          final engine = engineOn();
          await play(await engine.startLesson('a'), wrongCount: 3);

          expect(await dueOn(day0.addDays(1)), 0);
        });

        test(
          'only once: passing the Lesson again keeps their schedule',
          () async {
            await passLessonOn(day0, 'a');
            await reviewOn(day0.addDays(1)); // all to Box 2, due day 4
            await passLessonOn(day0.addDays(1), 'a');

            expect(await dueOn(day0.addDays(2)), 0);
            expect(await dueOn(day0.addDays(4)), 5);
          },
        );
      });

      test('a Review contains only the Words due today', () async {
        await passLessonOn(day0, 'a');
        await passLessonOn(day0.addDays(1), 'b');

        clock.day = day0.addDays(1);
        final session = (await engineOn().startReview())!;
        final words = <int>{};
        for (var e = session.current; e != null; e = session.current) {
          words.add(e.word!.id);
          session.answer(e.answer);
        }

        expect(words, {1, 2, 3, 4, 5});
      });

      test('Words not reviewed on their due Day stay due', () async {
        await passLessonOn(day0, 'a');

        expect(await dueOn(day0.addDays(5)), 5);
      });

      group('Boxes', () {
        // Box intervals: 1, 3, 7, 14, 30 Days.
        test('each correct answer moves a Word up one Box: due again after '
            '3, 7, 14, then 30 Days, staying at 30', () async {
          await passLessonOn(day0, 'a');
          var day = day0.addDays(1); // Box 1 due after 1 Day
          for (final interval in [3, 7, 14, 30, 30, 30]) {
            await reviewOn(day);
            expect(
              await dueOn(day.addDays(interval - 1)),
              0,
              reason: 'not due before $interval Days',
            );
            expect(
              await dueOn(day.addDays(interval)),
              5,
              reason: 'due after $interval Days',
            );
            day = day.addDays(interval);
          }
        });

        test('a wrong answer sends a Word back to the first Box, due the '
            'next Day', () async {
          await passLessonOn(day0, 'a');
          final day1 = day0.addDays(1);
          await reviewOn(day1); // Box 2, due day 4
          final day4 = day1.addDays(3);
          await reviewOn(day4); // Box 3, due day 11
          final day11 = day4.addDays(7);

          await reviewOn(day11, wrong: {2});

          expect(await dueOn(day11.addDays(1)), 1);
          expect(await dueOn(day11.addDays(14)), 5);
        });

        test('only the first try counts: a Word missed then answered right '
            'still goes back to the first Box', () async {
          await passLessonOn(day0, 'a');
          final day1 = day0.addDays(1);

          await reviewOn(day1, wrong: {1});

          expect(await dueOn(day1.addDays(1)), 1);
        });
      });

      test('correct Review answers earn XP', () async {
        await passLessonOn(day0, 'a'); // 50 XP

        final result = await reviewOn(day0.addDays(1), wrong: {1, 2});

        expect(result.xpEarned, 30);
        expect(await engineOn().totalXp(), 80);
      });

      test('a finished Review extends the Streak', () async {
        await passLessonOn(day0, 'a');
        await reviewOn(day0.addDays(1));

        expect(await engineOn().currentStreak(), 2);
      });

      test('quitting a Review midway records nothing', () async {
        await passLessonOn(day0, 'a');
        clock.day = day0.addDays(1);
        final session = (await engineOn().startReview())!;
        for (var i = 0; i < 4; i++) {
          session.answer(session.current!.answer);
        }

        final reopened = engineOn(progress: backend.restart());
        expect(await reopened.wordsDueToday(), 5);
        expect(await reopened.totalXp(), 50);
        expect(await reopened.currentStreak(), 1);
      });

      test('Words whose IDs are no longer in the Course Content are '
          'ignored', () async {
        await passLessonOn(day0, 'a');

        // A content update retires Word 3.
        clock.day = day0.addDays(1);
        final updated = engineOn(
          content: [
            Lesson(
              id: 'a',
              title: 'Lesson a',
              exercises: [
                for (final e in lessons[0].exercises)
                  if (e.word!.id != 3) e,
              ],
            ),
            lessons[1],
          ],
        );

        expect(await updated.wordsDueToday(), 4);
      });

      test('the Review schedule survives an app restart', () async {
        if (!backend.persistent) {
          return markTestSkipped('in-memory progress does not outlive the app');
        }
        await passLessonOn(day0, 'a');
        await reviewOn(day0.addDays(1));

        final reopened = engineOn(progress: backend.restart());
        clock.day = day0.addDays(4);
        expect(await reopened.wordsDueToday(), 5);
      });
    });
  }
}
