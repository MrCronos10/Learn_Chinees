import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_chinese_app/app.dart';
import 'package:study_engine/study_engine.dart';

import 'fake_audio_player.dart';

const words = [
  Word(id: 1, characters: '你好', pinyin: 'nǐ hǎo', meaning: 'hello'),
  Word(id: 2, characters: '谢谢', pinyin: 'xièxie', meaning: 'thank you'),
  Word(id: 3, characters: '再见', pinyin: 'zàijiàn', meaning: 'goodbye'),
];

/// Tone Recordings of "ma" in all four tones.
const ma = {
  1: ToneRecording(syllable: 'ma', tone: 1, file: 'ma1.mp3'),
  2: ToneRecording(syllable: 'ma', tone: 2, file: 'ma2.mp3'),
  3: ToneRecording(syllable: 'ma', tone: 3, file: 'ma3.mp3'),
  4: ToneRecording(syllable: 'ma', tone: 4, file: 'ma4.mp3'),
};

const acknowledgements = [
  Acknowledgement(
    name: 'CC-CEDICT',
    author: 'MDBG',
    license: 'CC BY-SA 4.0',
    url: 'https://cc-cedict.org/',
  ),
];

StudyEngine fakeEngine([Clock? clock]) => StudyEngine(
  content: InMemoryCourseContent([
    Lesson(
      id: 'lesson-1',
      title: 'Saying hello',
      exercises: [
        for (final word in words)
          MultipleChoiceExercise(
            word: word,
            choices: const ['goodbye', 'hello', 'thank you'],
          ),
      ],
    ),
    Lesson(
      id: 'lesson-2',
      title: 'Listening',
      exercises: [
        ListeningExercise(word: words[0], choices: const ['goodbye', 'hello']),
        ToneIdentificationExercise(syllable: 'ma', tone: 3, recordings: ma),
        ToneMatchingExercise(
          syllable: 'ma',
          tone: 2,
          recordings: ma,
          choices: const ['4', '2', '1', '3'],
        ),
      ],
    ),
  ], acknowledgements: acknowledgements),
  progress: InMemoryLearnerProgressStore(),
  clock: clock ?? FixedClock(const Day(2026, 11, 10)),
);

/// The meaning of the Word currently shown on the Lesson screen.
String shownMeaning(WidgetTester tester) => words
    .firstWhere((w) => find.text(w.characters).evaluate().isNotEmpty)
    .meaning;

Future<void> choose(WidgetTester tester, String choice) async {
  await tester.tap(find.widgetWithText(OutlinedButton, choice));
  await tester.pumpAndSettle();
}

Future<void> continueOn(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('launches to the Lesson path and finishes a Lesson end to end', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChineseApp(engine: fakeEngine(), audio: FakeAudioPlayer()),
    );
    await tester.pumpAndSettle();

    // Lesson path shows the one Lesson, no XP yet and nothing to review.
    expect(find.text('Saying hello'), findsOneWidget);
    expect(find.text('Nothing due for Review today'), findsOneWidget);
    expect(find.text('0 XP'), findsOneWidget);
    expect(find.text('0-Day Streak'), findsOneWidget);
    await tester.tap(find.text('Saying hello'));
    await tester.pumpAndSettle();

    // First Exercise shows characters + pinyin; answer it wrong.
    expect(find.text('你好'), findsOneWidget);
    expect(find.text('nǐ hǎo'), findsOneWidget);
    await choose(tester, 'goodbye');
    expect(find.textContaining('Correct answer: hello'), findsOneWidget);
    await continueOn(tester);

    // Answer the rest right, including the missed one repeated at the end.
    for (var i = 0; i < 3; i++) {
      await choose(tester, shownMeaning(tester));
      expect(find.text('Correct!'), findsOneWidget);
      await continueOn(tester);
    }

    // 2 of 3 on the first try: not a Passed Lesson.
    expect(find.text('Not passed yet'), findsOneWidget);
    expect(find.textContaining('66%'), findsOneWidget);
    expect(find.text('+20 XP'), findsOneWidget);

    // Retry at once and pass; the path then shows the Lesson as passed.
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await choose(tester, shownMeaning(tester));
      await continueOn(tester);
    }
    expect(find.text('Lesson passed!'), findsOneWidget);
    expect(find.textContaining('100%'), findsOneWidget);
    expect(find.text('+30 XP'), findsOneWidget);
    expect(find.text('Unlocked: Listening'), findsOneWidget);

    await tester.tap(find.text('Back to Lessons'));
    await tester.pumpAndSettle();
    expect(find.text('Saying hello'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('50 XP'), findsOneWidget);
    expect(find.text('1-Day Streak'), findsOneWidget);
  });

  testWidgets('Words from a Passed Lesson can be reviewed the next Day', (
    tester,
  ) async {
    final clock = FixedClock(const Day(2026, 11, 10));
    await tester.pumpWidget(
      ChineseApp(engine: fakeEngine(clock), audio: FakeAudioPlayer()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saying hello'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await choose(tester, shownMeaning(tester));
      await continueOn(tester);
    }
    await tester.tap(find.text('Back to Lessons'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing due for Review today'), findsOneWidget);

    // The next Day, the app comes back from the background.
    clock.day = const Day(2026, 11, 11);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('3 Words due for Review'), findsOneWidget);

    await tester.tap(find.text('Start Review'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await choose(tester, shownMeaning(tester));
      await continueOn(tester);
    }
    expect(find.text('Review done!'), findsOneWidget);
    expect(find.text('+30 XP'), findsOneWidget);

    await tester.tap(find.text('Back to Lessons'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing due for Review today'), findsOneWidget);
    expect(find.text('60 XP'), findsOneWidget);
    expect(find.text('2-Day Streak'), findsOneWidget);
  });

  testWidgets('Settings hide pinyin and list Acknowledgements; listening and '
      'tone Exercises play their audio', (tester) async {
    final audio = FakeAudioPlayer();
    final engine = fakeEngine();
    await tester.pumpWidget(ChineseApp(engine: engine, audio: audio));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saying hello'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await choose(tester, shownMeaning(tester));
      await continueOn(tester);
    }
    await tester.tap(find.text('Back to Lessons'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show pinyin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acknowledgements'));
    await tester.pumpAndSettle();
    expect(find.text('CC-CEDICT'), findsOneWidget);
    expect(find.textContaining('CC BY-SA 4.0'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Listening'));
    await tester.pumpAndSettle();
    expect(audio.spokenWords, ['你好']);
    expect(find.text('你好'), findsNothing, reason: 'heard, not read');
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(audio.spokenWords, ['你好', '你好']);

    await choose(tester, 'hello');
    expect(find.text('Correct!'), findsOneWidget);
    expect(find.text('你好'), findsOneWidget, reason: 'shown once answered');
    expect(find.text('nǐ hǎo'), findsNothing, reason: 'pinyin is hidden');
    await continueOn(tester);

    // Hear a syllable, pick its tone: played from its Tone Recording only.
    expect(audio.playedRecordings, ['ma3.mp3']);
    expect(audio.spokenWords, ['你好', '你好'], reason: 'never text-to-speech');
    await choose(tester, '2nd tone');
    expect(find.text('Correct answer: mǎ (3rd tone)'), findsOneWidget);
    await continueOn(tester);

    // See a toned syllable, play the sounds, pick the matching one.
    expect(find.text('má'), findsOneWidget);
    await tester.tap(find.byTooltip('Play sound A'));
    await tester.tap(find.byTooltip('Play sound B'));
    expect(audio.playedRecordings, ['ma3.mp3', 'ma4.mp3', 'ma2.mp3']);
    await choose(tester, 'Sound B');
    expect(find.text('Correct!'), findsOneWidget);
    await continueOn(tester);

    // The missed tone Exercise comes back, with its recording played again.
    expect(audio.playedRecordings.last, 'ma3.mp3');
    await choose(tester, '3rd tone');
    expect(find.text('Correct!'), findsOneWidget);
  });
}
