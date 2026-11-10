import 'dart:convert';
import 'dart:io';

import 'package:course_content/course_content.dart';
import 'package:learner_progress/learner_progress.dart';
import 'package:path/path.dart' as p;
import 'package:study_engine/study_engine.dart';
import 'package:test/test.dart';

const fixture = 'test/fixtures/one_lesson.json';

void main() {
  late Directory dir;
  late String registry;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('course_content_test');
    registry = p.join(dir.path, 'word_ids.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// Builds [source] into a fresh database and opens it for reading.
  SqliteCourseContent build(String source, String name) {
    final output = p.join(dir.path, name);
    buildCourseContent(
      sourcePath: source,
      registryPath: registry,
      outputPath: output,
    );
    final content = SqliteCourseContent.open(output);
    addTearDown(content.close);
    return content;
  }

  test('builds the Lesson path from the source', () async {
    final content = build(fixture, 'course.db');

    final path = await content.lessonPath();

    expect(path.map((l) => (l.id, l.title)), [
      ('fixture-lesson-1', 'Saying hello'),
    ]);
  });

  test('builds multiple-choice Exercises showing each Word with its '
      'meaning among the choices', () async {
    final content = build(fixture, 'course.db');

    final lesson = await content.lesson('fixture-lesson-1');
    final exercises = lesson.exercises.cast<MultipleChoiceExercise>();

    expect(exercises.map((e) => (e.word.characters, e.word.pinyin)), [
      ('你好', 'nǐ hǎo'),
      ('谢谢', 'xièxie'),
      ('再见', 'zàijiàn'),
    ]);
    expect(exercises.first.answer, 'hello');
    for (final exercise in exercises) {
      expect(
        exercise.choices,
        unorderedEquals(['hello', 'thank you', 'goodbye']),
      );
    }
  });

  test('assigns each Word a distinct permanent Word ID', () async {
    final content = build(fixture, 'course.db');

    final lesson = await content.lesson('fixture-lesson-1');
    final ids = lesson.exercises
        .cast<MultipleChoiceExercise>()
        .map((e) => e.word.id)
        .toList();

    expect(ids.toSet(), hasLength(3));
  });

  test('a rebuild keeps every Word ID', () async {
    Future<Map<String, int>> idsIn(SqliteCourseContent content) async {
      final lesson = await content.lesson('fixture-lesson-1');
      return {
        for (final e in lesson.exercises.cast<MultipleChoiceExercise>())
          e.word.characters: e.word.id,
      };
    }

    final first = await idsIn(build(fixture, 'first.db'));
    final second = await idsIn(build(fixture, 'second.db'));

    expect(second, first);
  });

  test('correcting a Word\'s pinyin keeps its Word ID', () async {
    Future<int> idOf(SqliteCourseContent content, String characters) async {
      final lesson = await content.lesson('fixture-lesson-1');
      return lesson.exercises
          .cast<MultipleChoiceExercise>()
          .firstWhere((e) => e.word.characters == characters)
          .word
          .id;
    }

    final before = await idOf(build(fixture, 'first.db'), '谢谢');
    final corrected = File(p.join(dir.path, 'corrected.json'))
      ..writeAsStringSync(
        File(fixture).readAsStringSync().replaceFirst('xièxie', 'xièxiè'),
      );
    final after = await idOf(build(corrected.path, 'second.db'), '谢谢');

    expect(after, before);
  });

  test('fails with a ContentBuildException on badly shaped source', () {
    final source = File(p.join(dir.path, 'bad.json'))
      ..writeAsStringSync('{"units": ["not a unit"], "words": []}');

    expect(
      () => build(source.path, 'course.db'),
      throwsA(isA<ContentBuildException>()),
    );
  });

  test('fails with a clear message when an Exercise names an unknown Word', () {
    final source = File(p.join(dir.path, 'bad.json'))
      ..writeAsStringSync(
        File(
          fixture,
        ).readAsStringSync().replaceFirst('"word": "再见"', '"word": "不在"'),
      );

    expect(
      () => build(source.path, 'course.db'),
      throwsA(
        isA<ContentBuildException>().having(
          (e) => e.message,
          'message',
          contains('不在'),
        ),
      ),
    );
  });

  test('a built Lesson can be played through the study engine', () async {
    final engine = StudyEngine(
      content: build(fixture, 'course.db'),
      progress: InMemoryLearnerProgressStore(),
      clock: FixedClock(const Day(2026, 11, 10)),
    );
    final lessonId = (await engine.lessonPath()).single.id;
    final session = await engine.startLesson(lessonId);

    for (var e = session.current; e != null; e = session.current) {
      session.answer(e.answer);
    }
    final result = await session.finish();

    expect(result.passed, isTrue);
    expect(result.firstTryPercent, 100);
  });

  test('a removed Word\'s ID is retired and never reused', () async {
    Future<Map<String, int>> idsIn(SqliteCourseContent content) async {
      final lesson = await content.lesson('fixture-lesson-1');
      return {
        for (final e in lesson.exercises.cast<MultipleChoiceExercise>())
          e.word.characters: e.word.id,
      };
    }

    final before = await idsIn(build(fixture, 'first.db'));
    // Replace 再见 with a new Word in both the Word list and the Lesson.
    final changed = File(p.join(dir.path, 'changed.json'))
      ..writeAsStringSync(
        File(fixture)
            .readAsStringSync()
            .replaceAll('再见', '早上好')
            .replaceFirst('zàijiàn', 'zǎoshang hǎo')
            .replaceFirst('goodbye', 'good morning'),
      );
    final after = await idsIn(build(changed.path, 'second.db'));

    expect(after['你好'], before['你好']);
    expect(after['谢谢'], before['谢谢']);
    expect(before.values, isNot(contains(after['早上好'])));
  });

  test('Learner Progress survives replacing the Course Content database '
      'with a rebuilt one', () async {
    final progressPath = p.join(dir.path, 'learner_progress.db');
    final contentPath = p.join(dir.path, 'course.db');
    final clock = FixedClock(const Day(2026, 11, 10));

    buildCourseContent(
      sourcePath: fixture,
      registryPath: registry,
      outputPath: contentPath,
    );
    var content = SqliteCourseContent.open(contentPath);
    var progress = SqliteLearnerProgressStore.open(progressPath);
    var engine = StudyEngine(
      content: content,
      progress: progress,
      clock: clock,
    );
    final session = await engine.startLesson('fixture-lesson-1');
    for (var e = session.current; e != null; e = session.current) {
      session.answer(e.answer);
    }
    await session.finish();
    content.close();
    progress.close();

    // An app update ships a rebuilt Course Content database over the old one.
    buildCourseContent(
      sourcePath: fixture,
      registryPath: registry,
      outputPath: contentPath,
    );
    content = SqliteCourseContent.open(contentPath);
    progress = SqliteLearnerProgressStore.open(progressPath);
    addTearDown(content.close);
    addTearDown(progress.close);
    engine = StudyEngine(content: content, progress: progress, clock: clock);

    expect((await engine.lessonPath()).single.state, LessonState.passed);
  });

  test(
    'Words from a Passed Lesson come back for Review the next Day',
    () async {
      final clock = FixedClock(const Day(2026, 11, 10));
      final engine = StudyEngine(
        content: build(fixture, 'course.db'),
        progress: InMemoryLearnerProgressStore(),
        clock: clock,
      );
      final lesson = await engine.startLesson('fixture-lesson-1');
      for (var e = lesson.current; e != null; e = lesson.current) {
        lesson.answer(e.answer);
      }
      await lesson.finish();

      clock.day = const Day(2026, 11, 11);
      final review = (await engine.startReview())!;
      final reviewed = <String>[];
      for (var e = review.current; e != null; e = review.current) {
        reviewed.add(e.word!.characters);
        review.answer(e.answer);
      }

      expect(reviewed, unorderedEquals(['你好', '谢谢', '再见']));
    },
  );

  test('builds listening Exercises defined in the source', () async {
    final source = File(p.join(dir.path, 'listening.json'))
      ..writeAsStringSync(
        File(fixture).readAsStringSync().replaceFirst(
          '{ "kind": "multipleChoice", "word": "谢谢" }',
          '{ "kind": "listening", "word": "谢谢" }',
        ),
      );
    final content = build(source.path, 'course.db');

    final exercise = (await content.lesson('fixture-lesson-1')).exercises[1];

    expect(exercise, isA<ListeningExercise>());
    expect(exercise.word!.characters, '谢谢');
    expect(exercise.answer, 'thank you');
    expect(exercise.choices, contains('thank you'));
  });

  group('Acknowledgements', () {
    /// The fixture with Word 谢谢 citing [source] and these [acknowledgements].
    File sourceWith(String source, String acknowledgements) =>
        File(p.join(dir.path, 'sourced.json'))..writeAsStringSync(
          File(fixture)
              .readAsStringSync()
              .replaceFirst(
                '"meaning": "thank you" }',
                '"meaning": "thank you", "source": "$source" }',
              )
              .replaceFirst(
                '"words": [',
                '"acknowledgements": [$acknowledgements],\n  "words": [',
              ),
        );

    const cedict =
        '{ "id": "cc-cedict", "name": "CC-CEDICT", "author": "MDBG", '
        '"license": "CC BY-SA 4.0", "url": "https://cc-cedict.org/" }';

    test('are listed from the Course Content', () async {
      final content = build(sourceWith('cc-cedict', cedict).path, 'course.db');

      final acknowledgements = await content.acknowledgements();

      expect(acknowledgements.single.name, 'CC-CEDICT');
      expect(acknowledgements.single.author, 'MDBG');
      expect(acknowledgements.single.license, 'CC BY-SA 4.0');
      expect(acknowledgements.single.url, 'https://cc-cedict.org/');
    });

    test('the build fails when a source has no Acknowledgement', () {
      expect(
        () => build(sourceWith('tatoeba', cedict).path, 'course.db'),
        throwsA(
          isA<ContentBuildException>().having(
            (e) => e.message,
            'message',
            allOf(contains('tatoeba'), contains('Acknowledgement')),
          ),
        ),
      );
    });

    test('the build fails when an Acknowledgement has no license', () {
      final noLicense = cedict.replaceFirst('"license": "CC BY-SA 4.0", ', '');

      expect(
        () => build(sourceWith('cc-cedict', noLicense).path, 'course.db'),
        throwsA(
          isA<ContentBuildException>().having(
            (e) => e.message,
            'message',
            contains('license'),
          ),
        ),
      );
    });
  });

  group('tone Exercises', () {
    const ack = {
      'id': 'own-recordings',
      'name': 'Tone Recordings',
      'author': 'Test Speaker',
      'license': 'CC BY-SA 4.0',
      'url': 'https://example.org/',
    };

    /// A source with one Lesson of two tone Exercises on "ma" plus one
    /// multiple-choice Exercise.
    File toneSource({
      List<Map<String, Object>> acknowledgements = const [ack],
    }) => File(p.join(dir.path, 'tones.json'))
      ..writeAsStringSync(
        jsonEncode({
          'acknowledgements': acknowledgements,
          'units': [
            {
              'id': 'u',
              'title': 'Unit',
              'lessons': [
                {
                  'id': 'tones',
                  'title': 'The four tones',
                  'exercises': [
                    {'kind': 'toneIdentification', 'syllable': 'ma', 'tone': 3},
                    {'kind': 'toneMatching', 'syllable': 'ma', 'tone': 2},
                    {'kind': 'multipleChoice', 'word': '你好'},
                  ],
                },
              ],
            },
          ],
          'words': [
            {'characters': '你好', 'pinyin': 'nǐ hǎo', 'meaning': 'hello'},
            {'characters': '谢谢', 'pinyin': 'xièxie', 'meaning': 'thank you'},
          ],
        }),
      );

    /// A Tone Recordings list for "ma" in [tones], with each audio file
    /// written next to it unless [missingFile].
    File recordings({
      List<int> tones = const [1, 2, 3, 4],
      String source = 'own-recordings',
      bool missingFile = false,
    }) {
      final audio = Directory(p.join(dir.path, 'audio'))..createSync();
      for (final tone in tones) {
        if (!missingFile) {
          File(p.join(audio.path, 'ma$tone.mp3')).writeAsStringSync('ma$tone');
        }
      }
      return File(p.join(dir.path, 'tone_recordings.json'))..writeAsStringSync(
        jsonEncode({
          'recordings': [
            for (final tone in tones)
              {
                'syllable': 'ma',
                'tone': tone,
                'file': 'audio/ma$tone.mp3',
                'source': source,
              },
          ],
        }),
      );
    }

    SqliteCourseContent buildTones(File source, File? recordingsFile) {
      final output = p.join(dir.path, 'out', 'course.db');
      Directory(p.dirname(output)).createSync(recursive: true);
      buildCourseContent(
        sourcePath: source.path,
        registryPath: registry,
        outputPath: output,
        recordingsPath: recordingsFile?.path,
      );
      final content = SqliteCourseContent.open(output);
      addTearDown(content.close);
      return content;
    }

    Matcher failsWith(List<String> parts) => throwsA(
      isA<ContentBuildException>().having(
        (e) => e.message,
        'message',
        allOf([for (final part in parts) contains(part)]),
      ),
    );

    test('are built in both directions with their Tone Recordings', () async {
      final content = buildTones(toneSource(), recordings());

      final exercises = (await content.lesson('tones')).exercises;

      final hear = exercises[0] as ToneIdentificationExercise;
      expect((hear.syllable, hear.tone), ('ma', 3));
      expect(hear.choices, ['1', '2', '3', '4']);
      expect(hear.recording.file, 'ma3.mp3');

      final see = exercises[1] as ToneMatchingExercise;
      expect(see.tonedSyllable, 'má');
      expect(see.choices, unorderedEquals(['1', '2', '3', '4']));
      expect([
        for (final c in see.choices) see.recordingFor(c).file,
      ], unorderedEquals(['ma1.mp3', 'ma2.mp3', 'ma3.mp3', 'ma4.mp3']));
    });

    test('copy their Tone Recordings next to the database', () {
      buildTones(toneSource(), recordings());

      final copied = File(p.join(dir.path, 'out', 'tones', 'ma3.mp3'));
      expect(copied.readAsStringSync(), 'ma3');
    });

    test('never enter Review', () async {
      final content = buildTones(toneSource(), recordings());

      final lesson = await content.lesson('tones');
      final wordId = lesson.exercises[2].word!.id;

      final review = await content.reviewExercises({wordId});
      expect(review[wordId], isA<MultipleChoiceExercise>());
    });

    test('the build fails when a tone Exercise has no Tone Recording', () {
      expect(
        () => buildTones(toneSource(), recordings(tones: [1, 3, 4])),
        failsWith(['tones', 'ma', 'tone 2', 'Tone Recording']),
      );
    });

    test(
      'the build fails when tone Exercises have no Tone Recordings list',
      () {
        expect(
          () => buildTones(toneSource(), null),
          failsWith(['ma', 'Tone Recording']),
        );
      },
    );

    test('the build fails when a Tone Recording file is missing', () {
      expect(
        () => buildTones(toneSource(), recordings(missingFile: true)),
        failsWith(['ma1.mp3']),
      );
    });

    test('the build fails when a Tone Recording source has no '
        'Acknowledgement', () {
      expect(
        () => buildTones(toneSource(acknowledgements: []), recordings()),
        failsWith(['own-recordings', 'Acknowledgement']),
      );
    });

    test('the build fails when a syllable is not plain pinyin', () {
      final source = toneSource();
      source.writeAsStringSync(
        source.readAsStringSync().replaceFirst(
          '"syllable":"ma","tone":3',
          '"syllable":"mm","tone":3',
        ),
      );

      expect(() => buildTones(source, recordings()), failsWith(['"mm"']));
    });

    test('the build fails when a tone is not 1 to 4', () {
      final source = toneSource();
      source.writeAsStringSync(
        source.readAsStringSync().replaceFirst('"tone":3', '"tone":5'),
      );

      expect(() => buildTones(source, recordings()), failsWith(['tone']));
    });
  });
}
