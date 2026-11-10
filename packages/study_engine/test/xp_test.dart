import 'package:study_engine/study_engine.dart';
import 'package:test/test.dart';

import 'helpers.dart';
import 'progress_backends.dart';

void main() {
  for (final backend in progressBackends) {
    group('with ${backend.name} Learner Progress:', () {
      setUp(backend.setUp);
      tearDown(backend.tearDown);

      StudyEngine engineOn(LearnerProgressStore progress) => StudyEngine(
        content: InMemoryCourseContent([
          lessonOf(5, id: 'a'),
          lessonOf(5, id: 'b'),
        ]),
        progress: progress,
        clock: FixedClock(const Day(2026, 11, 10)),
      );

      test('total XP starts at 0', () async {
        expect(await engineOn(backend.store).totalXp(), 0);
      });

      test(
        'a Passed Lesson earns 10 XP per first-try correct answer',
        () async {
          final engine = engineOn(backend.store);

          final result = await play(
            await engine.startLesson('a'),
            wrongCount: 1,
          );

          expect(result.passed, isTrue);
          expect(result.xpEarned, 40);
          expect(await engine.totalXp(), 40);
        },
      );

      test('a failed Lesson still earns XP for its correct answers', () async {
        final engine = engineOn(backend.store);

        final result = await play(await engine.startLesson('a'), wrongCount: 3);

        expect(result.passed, isFalse);
        expect(result.xpEarned, 20);
        expect(await engine.totalXp(), 20);
      });

      test('total XP adds up across Lessons and retries', () async {
        final engine = engineOn(backend.store);

        await play(await engine.startLesson('a'), wrongCount: 3); // 20
        await play(await engine.startLesson('a')); // 50
        await play(await engine.startLesson('b'), wrongCount: 1); // 40

        expect(await engine.totalXp(), 110);
      });

      test('a Lesson session can only be finished once', () async {
        final engine = engineOn(backend.store);
        final session = await engine.startLesson('a');
        await play(session);

        await expectLater(session.finish(), throwsStateError);
        expect(await engine.totalXp(), 50);
      });

      test('quitting a Lesson midway earns nothing', () async {
        final engine = engineOn(backend.store);

        final session = await engine.startLesson('a');
        for (var i = 0; i < 4; i++) {
          session.answer(session.current!.answer);
        }

        expect(await engineOn(backend.restart()).totalXp(), 0);
      });

      test('total XP survives an app restart', () async {
        if (!backend.persistent) {
          return markTestSkipped('in-memory progress does not outlive the app');
        }
        await play(await engineOn(backend.store).startLesson('a'));

        expect(await engineOn(backend.restart()).totalXp(), 50);
      });
    });
  }
}
