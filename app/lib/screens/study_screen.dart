import 'package:flutter/material.dart';
import 'package:study_engine/study_engine.dart';

/// Plays a Lesson or a Review, then shows its results in place (so "Try
/// again" restarts here and the Lesson path refreshes once this screen
/// closes). Closing it midway records nothing.
class StudyScreen<R> extends StatefulWidget {
  const StudyScreen({
    super.key,
    required this.start,
    required this.results,
    this.what = 'Lesson',
  });

  /// Starts a fresh session (again on "Try again").
  final Future<StudySession<R>> Function() start;

  /// The results view, given the result, a restart callback and a close one.
  final Widget Function(R result, VoidCallback again, VoidCallback done)
  results;

  /// What is being studied, for messages: "Lesson" or "Review".
  final String what;

  @override
  State<StudyScreen<R>> createState() => _StudyScreenState<R>();
}

class _StudyScreenState<R> extends State<StudyScreen<R>> {
  late Future<StudySession<R>> _session = widget.start();
  AnswerFeedback? _feedback;
  R? _result;
  bool _finishing = false;

  void _answer(StudySession<R> session, String choice) {
    // Ignore a second tap that lands before feedback is shown.
    if (_feedback != null) return;
    setState(() => _feedback = session.answer(choice));
  }

  Future<void> _continue(StudySession<R> session) async {
    if (session.current != null) {
      setState(() => _feedback = null);
      return;
    }
    if (_finishing) return;
    _finishing = true;
    final R result;
    try {
      result = await session.finish();
    } catch (error) {
      _finishing = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save your result. Try again. ($error)'),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _result = result);
  }

  void _again() {
    setState(() {
      _session = widget.start();
      _feedback = null;
      _result = null;
      _finishing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) {
      return widget.results(result, _again, () => Navigator.of(context).pop());
    }
    return FutureBuilder(
      future: _session,
      builder: (context, snapshot) {
        final session = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Quit ${widget.what}',
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
              child: Text('Could not load ${widget.what}: $error'),
            ),
            (null, _) => const Center(child: CircularProgressIndicator()),
            (final StudySession<R> session, _) => _exerciseView(session),
          },
        );
      },
    );
  }

  Widget _exerciseView(StudySession<R> session) {
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
