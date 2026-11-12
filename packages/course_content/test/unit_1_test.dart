import 'dart:io';

import 'package:course_content/course_content.dart';
import 'package:path/path.dart' as p;
import 'package:study_engine/study_engine.dart';
import 'package:test/test.dart';

/// Checks the Course Content the app ships (ticket 10), as built from
/// `content/`. Rebuild it after changing the sources (see content/README.md).
void main() {
  final shipped = p.join('..', '..', 'app', 'assets', 'content');
  late SqliteCourseContent content;

  setUp(() {
    content = SqliteCourseContent.open(p.join(shipped, 'course.db'));
    addTearDown(content.close);
  });

  Future<List<Exercise>> allExercises() async => [
    for (final summary in await content.lessonPath())
      ...(await content.lesson(summary.id)).exercises,
  ];

  test('Unit 1 has 4 Lessons and Lesson 1 opens with the four tones', () async {
    final path = await content.lessonPath();
    expect(path, hasLength(4));

    final first = (await content.lesson(path.first.id)).exercises;
    final opening = first.takeWhile((e) => e is ToneExercise).toList();
    expect({
      for (final e in opening) (e as ToneExercise).tone,
    }, Tone.values.toSet());
  });

  test('every Exercise kind appears in the Unit', () async {
    final kinds = {for (final e in await allExercises()) e.runtimeType};
    expect(
      kinds,
      containsAll([
        MultipleChoiceExercise,
        ListeningExercise,
        ToneIdentificationExercise,
        ToneMatchingExercise,
      ]),
    );
  });

  test('every Tone Recording is bundled', () async {
    for (final exercise in (await allExercises()).whereType<ToneExercise>()) {
      for (final recording in exercise.recordings.values) {
        final file = File(p.join(shipped, 'tones', recording.file));
        expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
      }
    }
  });

  test('CC-CEDICT and both Tone Recording speakers are acknowledged', () async {
    final authors = [
      for (final a in await content.acknowledgements()) a.author,
    ];
    expect(
      authors,
      containsAll([
        'MDBG and the CC-CEDICT contributors',
        'Wei Gao, Vion Nicolas',
        'Yue Tan',
      ]),
    );
  });
}
