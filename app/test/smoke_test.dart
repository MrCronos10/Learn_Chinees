import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_chinese_app/app.dart';
import 'package:study_engine/study_engine.dart';

const words = [
  Word(id: 1, characters: '你好', pinyin: 'nǐ hǎo', meaning: 'hello'),
  Word(id: 2, characters: '谢谢', pinyin: 'xièxie', meaning: 'thank you'),
  Word(id: 3, characters: '再见', pinyin: 'zàijiàn', meaning: 'goodbye'),
];

StudyEngine fakeEngine() => StudyEngine(
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
  ]),
  progress: InMemoryLearnerProgressStore(),
  clock: FixedClock(const Day(2026, 11, 10)),
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
    await tester.pumpWidget(ChineseApp(engine: fakeEngine()));
    await tester.pumpAndSettle();

    // Lesson path shows the one Lesson and no XP yet.
    expect(find.text('Saying hello'), findsOneWidget);
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

    await tester.tap(find.text('Back to Lessons'));
    await tester.pumpAndSettle();
    expect(find.text('Saying hello'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('50 XP'), findsOneWidget);
    expect(find.text('1-Day Streak'), findsOneWidget);
  });
}
