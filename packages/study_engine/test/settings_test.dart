import 'package:study_engine/study_engine.dart';
import 'package:test/test.dart';

import 'helpers.dart';
import 'progress_backends.dart';

void main() {
  const cedict = Acknowledgement(
    name: 'CC-CEDICT',
    author: 'MDBG',
    license: 'CC BY-SA 4.0',
    url: 'https://cc-cedict.org/',
  );

  StudyEngine engineOn(LearnerProgressStore progress) => StudyEngine(
    content: InMemoryCourseContent(
      [lessonOf(3)],
      acknowledgements: const [cedict],
    ),
    progress: progress,
    clock: FixedClock(const Day(2026, 11, 10)),
  );

  for (final backend in progressBackends) {
    group('with ${backend.name} Learner Progress:', () {
      setUp(backend.setUp);
      tearDown(backend.tearDown);

      test('pinyin is shown by default', () async {
        expect(await engineOn(backend.store).showPinyin(), isTrue);
      });

      test('hiding pinyin is remembered', () async {
        final engine = engineOn(backend.store);

        await engine.setShowPinyin(false);

        expect(await engine.showPinyin(), isFalse);
      });

      test('the pinyin setting survives an app restart', () async {
        if (!backend.persistent) {
          return markTestSkipped('in-memory progress does not outlive the app');
        }
        await engineOn(backend.store).setShowPinyin(false);

        expect(await engineOn(backend.restart()).showPinyin(), isFalse);
      });
    });
  }

  test('lists the Acknowledgements from the Course Content', () async {
    final engine = engineOn(InMemoryLearnerProgressStore());

    final acknowledgements = await engine.acknowledgements();

    expect(acknowledgements.single.name, 'CC-CEDICT');
    expect(acknowledgements.single.license, 'CC BY-SA 4.0');
  });
}
