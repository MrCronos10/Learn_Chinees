import 'package:study_engine/study_engine.dart';
import 'package:test/test.dart';

import 'helpers.dart';
import 'progress_backends.dart';

late ProgressBackend backend;

StudyEngine engineWith(
  List<Lesson> lessons, {
  LearnerProgressStore? progress,
}) => StudyEngine(
  content: InMemoryCourseContent(lessons),
  progress: progress ?? backend.store,
  clock: FixedClock(const Day(2026, 11, 10)),
);

List<LessonState> states(List<PathLesson> path) => [
  for (final lesson in path) lesson.state,
];

void main() {
  for (final b in progressBackends) {
    group('with ${b.name} Learner Progress:', () {
      setUp(() {
        backend = b;
        b.setUp();
      });
      tearDown(b.tearDown);
      lessonSuite();
    });
  }
}

void lessonSuite() {
  test('answering every Exercise right is a Passed Lesson at 100%', () async {
    final engine = engineWith([lessonOf(5)]);

    final result = await play(await engine.startLesson('lesson-1'));

    expect(result.passed, isTrue);
    expect(result.firstTryPercent, 100);
  });

  group('Lesson path', () {
    test('shows the first Lesson unlocked before any study', () async {
      final engine = engineWith([lessonOf(3)]);

      final path = await engine.lessonPath();

      expect(path.single.id, 'lesson-1');
      expect(path.single.title, 'Lesson lesson-1');
      expect(path.single.state, LessonState.unlocked);
    });

    test('shows the Lesson as passed after a Passed Lesson', () async {
      final engine = engineWith([lessonOf(5)]);

      await play(await engine.startLesson('lesson-1'), wrongCount: 1);

      expect((await engine.lessonPath()).single.state, LessonState.passed);
    });

    test('keeps the Lesson unlocked, not passed, after failing it', () async {
      final engine = engineWith([lessonOf(5)]);

      await play(await engine.startLesson('lesson-1'), wrongCount: 2);

      expect((await engine.lessonPath()).single.state, LessonState.unlocked);
    });

    final threeLessons = [
      lessonOf(5, id: 'a'),
      lessonOf(5, id: 'b'),
      lessonOf(5, id: 'c'),
    ];

    test('unlocks only the first Lesson on first launch', () async {
      final engine = engineWith(threeLessons);

      expect(states(await engine.lessonPath()), [
        LessonState.unlocked,
        LessonState.locked,
        LessonState.locked,
      ]);
    });

    test('passing a Lesson unlocks the next one only', () async {
      final engine = engineWith(threeLessons);

      await play(await engine.startLesson('a'));

      expect(states(await engine.lessonPath()), [
        LessonState.passed,
        LessonState.unlocked,
        LessonState.locked,
      ]);
    });

    test('failing a Lesson leaves the next one locked', () async {
      final engine = engineWith(threeLessons);

      await play(await engine.startLesson('a'), wrongCount: 2);

      expect(states(await engine.lessonPath()), [
        LessonState.unlocked,
        LessonState.locked,
        LessonState.locked,
      ]);
    });

    test('a locked Lesson cannot be started', () async {
      final engine = engineWith(threeLessons);

      expect(engine.startLesson('b'), throwsStateError);
    });

    test('a Lesson that is not on the path cannot be started', () async {
      final engine = StudyEngine(
        content: _PathOmits('b', InMemoryCourseContent(threeLessons)),
        progress: backend.store,
        clock: FixedClock(const Day(2026, 11, 10)),
      );
      await play(await engine.startLesson('a'));

      expect(engine.startLesson('b'), throwsStateError);
    });

    test('a Lesson inserted by a content update before the Learner\'s '
        'position is unlocked, and the next Lesson stays unlocked', () async {
      final before = engineWith(threeLessons);
      await play(await before.startLesson('a'));
      await play(await before.startLesson('b'));

      // An update inserts Lesson x between a and b.
      final after = engineWith([
        threeLessons[0],
        lessonOf(5, id: 'x'),
        threeLessons[1],
        threeLessons[2],
      ]);

      expect(states(await after.lessonPath()), [
        LessonState.passed,
        LessonState.unlocked,
        LessonState.passed,
        LessonState.unlocked,
      ]);
    });

    test(
      'quitting a Lesson midway leaves Learner Progress unchanged',
      () async {
        final engine = engineWith(threeLessons);
        await play(await engine.startLesson('a'));
        final before = states(await engine.lessonPath());

        // Answer most of Lesson b right, then walk away without finishing.
        final session = await engine.startLesson('b');
        for (var i = 0; i < 4; i++) {
          session.answer(session.current!.answer);
        }
        final reopened = engineWith(threeLessons, progress: backend.restart());

        expect(states(await reopened.lessonPath()), before);
      },
    );

    test('Learner Progress survives an app restart', () async {
      if (!backend.persistent) {
        return markTestSkipped('in-memory progress does not outlive the app');
      }
      final engine = engineWith(threeLessons);
      await play(await engine.startLesson('a'));

      final reopened = engineWith(threeLessons, progress: backend.restart());

      expect(states(await reopened.lessonPath()), [
        LessonState.passed,
        LessonState.unlocked,
        LessonState.locked,
      ]);
    });
  });

  test('a Lesson with no Exercises cannot be started', () async {
    final engine = engineWith([lessonOf(0)]);

    expect(engine.startLesson('lesson-1'), throwsStateError);
  });

  test('a wrong answer gets feedback showing the correct answer', () async {
    final engine = engineWith([lessonOf(3)]);
    final session = await engine.startLesson('lesson-1');

    final feedback = session.answer('wrong');

    expect(feedback.correct, isFalse);
    expect(feedback.correctAnswer, 'meaning 1');
    expect(session.answer('meaning 2').correct, isTrue);
  });

  group('missed Exercises', () {
    test('are repeated at the end, after every other Exercise', () async {
      final engine = engineWith([lessonOf(3)]);
      final session = await engine.startLesson('lesson-1');
      final seen = <String>[];

      for (
        var exercise = session.current;
        exercise != null;
        exercise = session.current
      ) {
        seen.add(exercise.answer);
        // Miss Exercise 1 the first time it is shown only.
        final missNow = exercise.answer == 'meaning 1' && seen.length == 1;
        session.answer(missNow ? 'wrong' : exercise.answer);
      }

      expect(seen, ['meaning 1', 'meaning 2', 'meaning 3', 'meaning 1']);
    });

    test('keep coming back until answered right', () async {
      final engine = engineWith([lessonOf(2)]);
      final session = await engine.startLesson('lesson-1');
      final seen = <String>[];

      for (
        var exercise = session.current;
        exercise != null;
        exercise = session.current
      ) {
        seen.add(exercise.answer);
        final missNow = exercise.answer == 'meaning 1' && seen.length < 4;
        session.answer(missNow ? 'wrong' : exercise.answer);
      }

      expect(seen, ['meaning 1', 'meaning 2', 'meaning 1', 'meaning 1']);
    });

    test('do not change the mark when answered right on repeat', () async {
      final engine = engineWith([lessonOf(5)]);

      final result = await play(
        await engine.startLesson('lesson-1'),
        wrongCount: 2,
      );

      expect(result.firstTryPercent, 60);
      expect(result.passed, isFalse);
    });
  });

  group('Passed Lesson needs at least 80% first-try correct', () {
    for (final (correct, passed) in [(100, true), (80, true), (79, false)]) {
      test('$correct of 100 first-try correct: passed = $passed', () async {
        final engine = engineWith([lessonOf(100)]);

        final result = await play(
          await engine.startLesson('lesson-1'),
          wrongCount: 100 - correct,
        );

        expect(result.passed, passed);
        expect(result.firstTryPercent, correct);
      });
    }

    test(
      'first-try percentage rounds down, so 79.x% is not shown as 80%',
      () async {
        final engine = engineWith([lessonOf(24)]); // 19/24 = 79.17%

        final result = await play(
          await engine.startLesson('lesson-1'),
          wrongCount: 5,
        );

        expect(result.passed, isFalse);
        expect(result.firstTryPercent, 79);
      },
    );
  });
}

/// Course Content whose Lesson path leaves out one Lesson that can still be
/// loaded by id.
final class _PathOmits implements CourseContentReader {
  _PathOmits(this._omitted, this._inner);

  final String _omitted;
  final CourseContentReader _inner;

  @override
  Future<List<LessonSummary>> lessonPath() async => [
    for (final l in await _inner.lessonPath())
      if (l.id != _omitted) l,
  ];

  @override
  Future<Lesson> lesson(String lessonId) => _inner.lesson(lessonId);

  @override
  Future<Map<int, Exercise>> reviewExercises(Set<int> wordIds) =>
      _inner.reviewExercises(wordIds);

  @override
  Future<List<Acknowledgement>> acknowledgements() => _inner.acknowledgements();
}
