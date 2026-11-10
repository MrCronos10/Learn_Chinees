import 'dart:io';

import 'package:course_content/course_content.dart';
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
}
