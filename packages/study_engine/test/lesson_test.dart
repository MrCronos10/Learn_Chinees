import 'package:study_engine/study_engine.dart';
import 'package:test/test.dart';

/// A Lesson of [count] multiple-choice Exercises, one per Word.
Lesson lessonOf(int count, {String id = 'lesson-1'}) => Lesson(
  id: id,
  title: 'Lesson $id',
  exercises: [
    for (var i = 1; i <= count; i++)
      MultipleChoiceExercise(
        word: Word(
          id: i,
          characters: '字$i',
          pinyin: 'zi$i',
          meaning: 'meaning $i',
        ),
        choices: ['meaning $i', 'wrong'],
      ),
  ],
);

StudyEngine engineWith(List<Lesson> lessons) => StudyEngine(
  content: InMemoryCourseContent(lessons),
  progress: InMemoryLearnerProgressStore(),
  clock: FixedClock(const Day(2026, 11, 10)),
);

/// Answers the first [wrongCount] first-try Exercises wrong and the rest right;
/// repeated Exercises are then answered right.
Future<LessonResult> play(LessonSession session, {int wrongCount = 0}) {
  var firstTries = 0;
  final missed = <Exercise>{};
  for (
    var exercise = session.current;
    exercise != null;
    exercise = session.current
  ) {
    final isFirstTry = !missed.contains(exercise);
    if (isFirstTry && firstTries++ < wrongCount) {
      missed.add(exercise);
      session.answer('wrong');
    } else {
      session.answer(exercise.answer);
    }
  }
  return session.finish();
}

void main() {
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
