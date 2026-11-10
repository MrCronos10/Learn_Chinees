import 'package:study_engine/study_engine.dart';

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
