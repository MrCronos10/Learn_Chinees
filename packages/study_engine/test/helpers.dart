import 'package:study_engine/study_engine.dart';

/// A Lesson of [count] multiple-choice Exercises, one per Word, with Word IDs
/// starting at [firstWordId].
Lesson lessonOf(int count, {String id = 'lesson-1', int firstWordId = 1}) =>
    Lesson(
      id: id,
      title: 'Lesson $id',
      exercises: [
        for (var i = firstWordId; i < firstWordId + count; i++)
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

/// Answers the first [wrongCount] first-try Exercises wrong and the rest right;
/// repeated Exercises are then answered right.
Future<R> play<R>(StudySession<R> session, {int wrongCount = 0}) {
  return playAnswering(session, (exercise, index) => index >= wrongCount);
}

/// Answers each first try right when [rightOnFirstTry] says so (called with
/// the Exercise and how many first tries came before it); repeats are
/// answered right.
Future<R> playAnswering<R>(
  StudySession<R> session,
  bool Function(Exercise exercise, int index) rightOnFirstTry,
) {
  var firstTries = 0;
  final missed = <Exercise>{};
  for (
    var exercise = session.current;
    exercise != null;
    exercise = session.current
  ) {
    final isFirstTry = !missed.contains(exercise);
    if (isFirstTry && !rightOnFirstTry(exercise, firstTries++)) {
      missed.add(exercise);
      session.answer('wrong');
    } else {
      session.answer(exercise.answer);
    }
  }
  return session.finish();
}
