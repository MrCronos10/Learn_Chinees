import 'package:study_engine/study_engine.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// The four Tone Recordings of [syllable], by tone.
Map<int, ToneRecording> recordingsOf(String syllable) => {
  for (var tone = 1; tone <= 4; tone++)
    tone: ToneRecording(
      syllable: syllable,
      tone: tone,
      file: '$syllable$tone.mp3',
    ),
};

StudyEngine engineWith(List<Lesson> lessons) => StudyEngine(
  content: InMemoryCourseContent(lessons),
  progress: InMemoryLearnerProgressStore(),
  clock: FixedClock(const Day(2026, 11, 10)),
);

void main() {
  group('toned pinyin', () {
    for (final (syllable, tone, toned) in [
      ('ma', 1, 'mā'),
      ('ma', 2, 'má'),
      ('ma', 3, 'mǎ'),
      ('ma', 4, 'mà'),
      ('hao', 3, 'hǎo'), // a takes the mark
      ('xie', 4, 'xiè'), // e takes the mark
      ('gou', 3, 'gǒu'), // o in ou takes the mark
      ('gui', 4, 'guì'), // otherwise the last vowel
      ('liu', 2, 'liú'),
      ('ming', 2, 'míng'),
      ('lv', 4, 'lǜ'), // v stands for ü
    ]) {
      test('$syllable tone $tone is written $toned', () {
        expect(tonedPinyin(syllable, tone), toned);
      });
    }
  });

  group('hear a syllable, pick its tone', () {
    final exercise = ToneIdentificationExercise(
      syllable: 'ma',
      tone: 3,
      recordings: recordingsOf('ma'),
    );

    test('offers the four tones and plays the recording of the right one', () {
      expect(exercise.choices, ['1', '2', '3', '4']);
      expect(exercise.answer, '3');
      expect(exercise.recording.file, 'ma3.mp3');
      expect(exercise.tonedSyllable, 'mǎ');
    });

    test('is answered right by picking the tone', () async {
      final session = await engineWith([
        Lesson(id: 'tones', title: 'Tones', exercises: [exercise]),
      ]).startLesson('tones');

      final wrong = session.answer('2');
      final right = session.answer('3');

      expect(wrong.correct, isFalse);
      expect(wrong.correctAnswer, '3');
      expect(right.correct, isTrue);
    });
  });

  group('see a toned syllable, pick its sound', () {
    final exercise = ToneMatchingExercise(
      syllable: 'ma',
      tone: 4,
      recordings: recordingsOf('ma'),
      choices: const ['2', '4', '1', '3'],
    );

    test('offers the four sounds in the given order', () {
      expect(exercise.tonedSyllable, 'mà');
      expect(
        [
          for (final choice in exercise.choices)
            exercise.recordingFor(choice).file,
        ],
        ['ma2.mp3', 'ma4.mp3', 'ma1.mp3', 'ma3.mp3'],
      );
      expect(exercise.answer, '4');
    });

    test('is answered right by picking the matching sound', () async {
      final session = await engineWith([
        Lesson(id: 'tones', title: 'Tones', exercises: [exercise]),
      ]).startLesson('tones');

      expect(session.answer('4').correct, isTrue);
    });
  });

  test('passing a Lesson with tone Exercises sends only its Words into '
      'Review', () async {
    final clock = FixedClock(const Day(2026, 11, 10));
    final words = lessonOf(1);
    final engine = StudyEngine(
      content: InMemoryCourseContent([
        Lesson(
          id: 'mixed',
          title: 'Mixed',
          exercises: [
            ToneIdentificationExercise(
              syllable: 'ma',
              tone: 1,
              recordings: recordingsOf('ma'),
            ),
            ...words.exercises,
          ],
        ),
      ]),
      progress: InMemoryLearnerProgressStore(),
      clock: clock,
    );

    await play(await engine.startLesson('mixed'));
    clock.day = const Day(2026, 11, 11);

    expect(await engine.wordsDueToday(), 1);
    final review = (await engine.startReview())!;
    expect(review.current, isA<MultipleChoiceExercise>());
  });
}
