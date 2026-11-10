import 'package:study_engine/study_engine.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  const hello = Word(
    id: 1,
    characters: '你好',
    pinyin: 'nǐ hǎo',
    meaning: 'hello',
  );
  final lesson = Lesson(
    id: 'a',
    title: 'Listening',
    exercises: [
      ListeningExercise(word: hello, choices: const ['goodbye', 'hello']),
    ],
  );

  test('a listening Exercise is answered with the Word\'s meaning', () async {
    final engine = StudyEngine(
      content: InMemoryCourseContent([lesson]),
      progress: InMemoryLearnerProgressStore(),
      clock: FixedClock(const Day(2026, 11, 10)),
    );
    final session = await engine.startLesson('a');

    expect(session.answer('goodbye').correctAnswer, 'hello');
    expect(session.answer('hello').correct, isTrue);
  });

  test('a Word met only in a listening Exercise enters Review', () async {
    final clock = FixedClock(const Day(2026, 11, 10));
    final engine = StudyEngine(
      content: InMemoryCourseContent([lesson]),
      progress: InMemoryLearnerProgressStore(),
      clock: clock,
    );
    await play(await engine.startLesson('a'));

    clock.day = const Day(2026, 11, 11);
    final review = (await engine.startReview())!;

    expect(review.current, isA<ListeningExercise>());
  });
}
