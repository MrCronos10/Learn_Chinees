import 'package:study_engine/study_engine.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// The four Tone Recordings of [syllable], by tone.
Map<Tone, ToneRecording> recordingsOf(String syllable) => {
  for (final tone in Tone.values)
    tone: ToneRecording(
      syllable: syllable,
      tone: tone,
      file: '$syllable${tone.number}.mp3',
    ),
};

StudyEngine engineWith(List<Lesson> lessons) => StudyEngine(
  content: InMemoryCourseContent(lessons),
  progress: InMemoryLearnerProgressStore(),
  clock: FixedClock(const Day(2026, 11, 10)),
);

void main() {
  group('Tone', () {
    test('is numbered 1 to 4 and named for the Learner', () {
      expect([for (final t in Tone.values) t.number], [1, 2, 3, 4]);
      expect(Tone.third.label, '3rd tone');
    });

    test('is found by its number', () {
      expect(Tone.fromNumber(2), Tone.second);
      expect(Tone.fromNumber(0), isNull);
      expect(Tone.fromNumber(5), isNull);
    });
  });

  group('plain pinyin', () {
    for (final syllable in ['ma', 'xie', 'lv', 'er', 'zhuang']) {
      test('"$syllable" is plain pinyin', () {
        expect(isPlainPinyin(syllable), isTrue);
      });
    }
    for (final syllable in ['', 'MA', 'mā', 'm1a', 'mm', '../x', 'ma ']) {
      test('"$syllable" is not plain pinyin', () {
        expect(isPlainPinyin(syllable), isFalse);
      });
    }
  });

  group('toned pinyin', () {
    for (final (syllable, tone, toned) in [
      ('ma', Tone.first, 'mā'),
      ('ma', Tone.second, 'má'),
      ('ma', Tone.third, 'mǎ'),
      ('ma', Tone.fourth, 'mà'),
      ('hao', Tone.third, 'hǎo'), // a takes the mark
      ('xie', Tone.fourth, 'xiè'), // e takes the mark
      ('gou', Tone.third, 'gǒu'), // o in ou takes the mark
      ('gui', Tone.fourth, 'guì'), // otherwise the last vowel
      ('liu', Tone.second, 'liú'),
      ('ming', Tone.second, 'míng'),
      ('lv', Tone.fourth, 'lǜ'), // v stands for ü
    ]) {
      test('$syllable ${tone.label} is written $toned', () {
        expect(tonedPinyin(syllable, tone), toned);
      });
    }

    test('is refused for a syllable that is not plain pinyin', () {
      expect(() => tonedPinyin('MA', Tone.first), throwsArgumentError);
    });
  });

  group('hear a syllable, pick its tone', () {
    final exercise = ToneIdentificationExercise(
      syllable: 'ma',
      tone: Tone.third,
      recordings: recordingsOf('ma'),
    );

    test('offers the four tones by name and plays the right recording', () {
      expect(exercise.choices, ['1', '2', '3', '4']);
      expect(
        [for (final c in exercise.choices) exercise.labelFor(c)],
        ['1st tone', '2nd tone', '3rd tone', '4th tone'],
      );
      expect(exercise.answer, '3');
      expect(exercise.recording.file, 'ma3.mp3');
    });

    test('names the correct answer with its toned syllable', () {
      expect(exercise.answerLabel, 'mǎ (3rd tone)');
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
      tone: Tone.fourth,
      recordings: recordingsOf('ma'),
      choices: const ['2', '4', '1', '3'],
    );

    test('offers the four sounds in the given order, by letter', () {
      expect(exercise.tonedSyllable, 'mà');
      expect(
        [
          for (final choice in exercise.choices)
            exercise.recordingFor(choice).file,
        ],
        ['ma2.mp3', 'ma4.mp3', 'ma1.mp3', 'ma3.mp3'],
      );
      expect(
        [for (final c in exercise.choices) exercise.labelFor(c)],
        ['Sound A', 'Sound B', 'Sound C', 'Sound D'],
      );
      expect(exercise.answer, '4');
    });

    test('names the correct answer by the sound the Learner saw', () {
      expect(exercise.answerLabel, 'Sound B (mà)');
    });

    test('is answered right by picking the matching sound', () async {
      final session = await engineWith([
        Lesson(id: 'tones', title: 'Tones', exercises: [exercise]),
      ]).startLesson('tones');

      expect(session.answer('4').correct, isTrue);
    });
  });

  test('a meaning Exercise shows its choices and answer as they are', () {
    final exercise = lessonOf(1).exercises.single;

    expect(exercise.labelFor('meaning 1'), 'meaning 1');
    expect(exercise.answerLabel, 'meaning 1');
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
              tone: Tone.first,
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
