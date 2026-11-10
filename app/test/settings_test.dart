import 'package:flutter_test/flutter_test.dart';
import 'package:my_chinese_app/app.dart';
import 'package:study_engine/study_engine.dart';

import 'fake_audio_player.dart';

const hello = Word(id: 1, characters: '你好', pinyin: 'nǐ hǎo', meaning: 'hello');

StudyEngine engineWith({List<Acknowledgement> acknowledgements = const []}) =>
    StudyEngine(
      content: InMemoryCourseContent([
        Lesson(
          id: 'a',
          title: 'Saying hello',
          exercises: [
            MultipleChoiceExercise(
              word: hello,
              choices: const ['goodbye', 'hello'],
            ),
          ],
        ),
      ], acknowledgements: acknowledgements),
      progress: InMemoryLearnerProgressStore(),
      clock: FixedClock(const Day(2026, 11, 10)),
    );

Future<void> openSettings(WidgetTester tester, StudyEngine engine) async {
  await tester.pumpWidget(ChineseApp(engine: engine, audio: FakeAudioPlayer()));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hiding pinyin in Settings hides it in Exercises', (
    tester,
  ) async {
    await openSettings(tester, engineWith());

    await tester.tap(find.text('Show pinyin'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saying hello'));
    await tester.pumpAndSettle();

    expect(find.text('你好'), findsOneWidget);
    expect(find.text('nǐ hǎo'), findsNothing);
  });

  testWidgets('Acknowledgements list each source, author, license and link', (
    tester,
  ) async {
    await openSettings(
      tester,
      engineWith(
        acknowledgements: const [
          Acknowledgement(
            name: 'CC-CEDICT',
            author: 'MDBG',
            license: 'CC BY-SA 4.0',
            url: 'https://cc-cedict.org/',
          ),
        ],
      ),
    );

    await tester.tap(find.text('Acknowledgements'));
    await tester.pumpAndSettle();

    expect(find.text('CC-CEDICT'), findsOneWidget);
    expect(find.textContaining('MDBG'), findsOneWidget);
    expect(find.textContaining('CC BY-SA 4.0'), findsOneWidget);
    expect(find.textContaining('https://cc-cedict.org/'), findsOneWidget);
  });

  testWidgets('Acknowledgements say so when no third-party source is used', (
    tester,
  ) async {
    await openSettings(tester, engineWith());

    await tester.tap(find.text('Acknowledgements'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No third-party sources'), findsOneWidget);
  });
}
