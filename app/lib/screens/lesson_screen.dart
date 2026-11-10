import 'package:flutter/material.dart';
import 'package:study_engine/study_engine.dart';

import 'results_screen.dart';

/// Plays one Lesson, then shows its results in place (so "Try again" restarts
/// here and the Lesson path refreshes once this screen closes). Closing it
/// midway records nothing.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.engine, required this.lessonId});

  final StudyEngine engine;
  final String lessonId;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late Future<LessonSession> _session = _start();
  AnswerFeedback? _feedback;
  LessonResult? _result;
  bool _finishing = false;

  Future<LessonSession> _start() => widget.engine.startLesson(widget.lessonId);

  void _answer(LessonSession session, String choice) {
    // Ignore a second tap that lands before feedback is shown.
    if (_feedback != null) return;
    setState(() => _feedback = session.answer(choice));
  }

  Future<void> _continue(LessonSession session) async {
    if (session.current != null) {
      setState(() => _feedback = null);
      return;
    }
    if (_finishing) return;
    _finishing = true;
    final result = await session.finish();
    if (!mounted) return;
    setState(() => _result = result);
  }

  void _tryAgain() {
    setState(() {
      _session = _start();
      _feedback = null;
      _result = null;
      _finishing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) {
      return ResultsScreen(
        result: result,
        onTryAgain: _tryAgain,
        onDone: () => Navigator.of(context).pop(),
      );
    }
    return FutureBuilder(
      future: _session,
      builder: (context, snapshot) {
        final session = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Quit Lesson',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: session == null
                ? null
                : LinearProgressIndicator(
                    value: session.completedCount / session.exerciseCount,
                  ),
          ),
          body: switch ((session, snapshot.error)) {
            (_, final Object error) => Center(
              child: Text('Could not load Lesson: $error'),
            ),
            (null, _) => const Center(child: CircularProgressIndicator()),
            (final LessonSession session, _) => _exerciseView(session),
          },
        );
      },
    );
  }

  Widget _exerciseView(LessonSession session) {
    final feedback = _feedback;
    // Once answered, the session has already moved on, so only the feedback
    // panel is shown until the Learner continues.
    final exercise = session.current;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (feedback == null && exercise is MultipleChoiceExercise) ...[
              const Text('What does this mean?', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _WordCard(word: exercise.word),
              const Spacer(),
              for (final choice in exercise.choices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => _answer(session, choice),
                    child: Text(choice),
                  ),
                ),
            ],
            if (feedback != null) ...[
              const Spacer(),
              _FeedbackPanel(feedback: feedback),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _continue(session),
                child: const Text('Continue'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(word.characters, style: text.displayMedium),
        const SizedBox(height: 8),
        Text(word.pinyin, style: text.titleLarge),
      ],
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.feedback});

  final AnswerFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: feedback.correct ? Colors.green.shade100 : colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            feedback.correct ? 'Correct!' : 'Not quite',
            style: text.headlineSmall,
          ),
          if (!feedback.correct) ...[
            const SizedBox(height: 8),
            Text('Correct answer: ${feedback.correctAnswer}'),
          ],
        ],
      ),
    );
  }
}
