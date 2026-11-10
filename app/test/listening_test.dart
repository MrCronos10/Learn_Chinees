import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_chinese_app/app.dart';
import 'package:study_engine/study_engine.dart';

import 'fake_audio_player.dart';

const hello = Word(id: 1, characters: '你好', pinyin: 'nǐ hǎo', meaning: 'hello');

StudyEngine listeningEngine() => StudyEngine(
  content: InMemoryCourseContent([
    Lesson(
      id: 'a',
      title: 'Listen',
      exercises: [
        ListeningExercise(word: hello, choices: const ['goodbye', 'hello']),
      ],
    ),
  ]),
  progress: InMemoryLearnerProgressStore(),
  clock: FixedClock(const Day(2026, 11, 10)),
);

Future<void> openLesson(WidgetTester tester, FakeAudioPlayer audio) async {
  await tester.pumpWidget(ChineseApp(engine: listeningEngine(), audio: audio));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Listen'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a listening Exercise plays the Word, can replay it, and '
      'offers English meanings', (tester) async {
    final audio = FakeAudioPlayer();
    await openLesson(tester, audio);

    expect(audio.spokenWords, ['你好']);
    expect(
      find.text('你好'),
      findsNothing,
      reason: 'the Word is heard, not read',
    );
    expect(find.widgetWithText(OutlinedButton, 'hello'), findsOneWidget);

    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(audio.spokenWords, ['你好', '你好']);

    await tester.tap(find.widgetWithText(OutlinedButton, 'hello'));
    await tester.pumpAndSettle();
    expect(find.text('Correct!'), findsOneWidget);
  });

  testWidgets('without a Chinese voice the Learner sees a clear message', (
    tester,
  ) async {
    await openLesson(tester, FakeAudioPlayer(hasChineseVoice: false));

    expect(find.textContaining('No Chinese voice'), findsOneWidget);
    expect(
      find.text('nǐ hǎo'),
      findsOneWidget,
      reason: 'pinyin is shown so the Exercise can still be answered',
    );
  });
}
