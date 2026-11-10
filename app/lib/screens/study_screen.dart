import 'package:flutter/material.dart';
import 'package:study_engine/study_engine.dart';

import '../audio/audio_player.dart';

/// Plays a Lesson or a Review, then shows its results in place (so "Try
/// again" restarts here and the Lesson path refreshes once this screen
/// closes). Closing it midway records nothing.
class StudyScreen<R> extends StatefulWidget {
  const StudyScreen({
    super.key,
    required this.audio,
    required this.showPinyin,
    required this.start,
    required this.results,
    this.what = 'Lesson',
  });

  final AudioPlayer audio;

  /// Whether Words show pinyin with their characters (a Learner setting).
  final Future<bool> Function() showPinyin;

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
  late final Future<bool> _showPinyin = widget.showPinyin();
  AnswerFeedback? _feedback;

  /// The Exercise just answered, shown with its feedback.
  Exercise? _answered;
  R? _result;
  bool _finishing = false;

  /// Counts Exercises shown, so a repeated Exercise gets a fresh prompt
  /// (and plays its audio again).
  int _shown = 0;

  void _answer(StudySession<R> session, String choice) {
    // Ignore a second tap that lands before feedback is shown.
    if (_feedback != null) return;
    setState(() {
      _answered = session.current;
      _feedback = session.answer(choice);
    });
  }

  Future<void> _continue(StudySession<R> session) async {
    if (session.current != null) {
      setState(() {
        _feedback = null;
        _shown++;
      });
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
      _shown++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) {
      return widget.results(result, _again, () => Navigator.of(context).pop());
    }
    return FutureBuilder(
      future: Future.wait([_session, _showPinyin]),
      builder: (context, snapshot) {
        final session = snapshot.data?[0] as StudySession<R>?;
        final showPinyin = snapshot.data?[1] as bool? ?? true;
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
            (final StudySession<R> session, _) => _exerciseView(
              session,
              showPinyin: showPinyin,
            ),
          },
        );
      },
    );
  }

  Widget _exerciseView(StudySession<R> session, {required bool showPinyin}) {
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
            if (feedback == null && exercise != null) ...[
              switch (exercise) {
                final MultipleChoiceExercise e => Column(
                  children: [
                    const Text('What does this mean?'),
                    const SizedBox(height: 24),
                    _WordCard(word: e.word, showPinyin: showPinyin),
                  ],
                ),
                final ListeningExercise e => _ListeningPrompt(
                  key: ValueKey(_shown),
                  word: e.word,
                  audio: widget.audio,
                ),
              },
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
              _FeedbackPanel(
                feedback: feedback,
                word: _answered?.word,
                showPinyin: showPinyin,
              ),
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

/// Plays the Word when shown, offers a replay, and explains clearly when
/// the device has no Chinese voice instead of staying silent.
class _ListeningPrompt extends StatefulWidget {
  const _ListeningPrompt({super.key, required this.word, required this.audio});

  final Word word;
  final AudioPlayer audio;

  @override
  State<_ListeningPrompt> createState() => _ListeningPromptState();
}

class _ListeningPromptState extends State<_ListeningPrompt> {
  bool _noVoice = false;

  @override
  void initState() {
    super.initState();
    _play();
  }

  Future<void> _play() async {
    final spoke = await widget.audio.speakWord(widget.word);
    if (mounted && !spoke) setState(() => _noVoice = true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        const Text('What did you hear?'),
        const SizedBox(height: 24),
        if (_noVoice) ...[
          Text(
            'No Chinese voice is installed on this device, so the Word '
            'cannot be played. Add a Chinese (Mandarin) voice in your '
            "device's speech settings. Until then, here is its pinyin:",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(widget.word.pinyin, style: text.titleLarge),
        ] else
          FilledButton.tonalIcon(
            onPressed: _play,
            icon: const Icon(Icons.volume_up),
            label: const Text('Play again'),
          ),
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.word, required this.showPinyin});

  final Word word;
  final bool showPinyin;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(word.characters, style: text.displayMedium),
        if (showPinyin) ...[
          const SizedBox(height: 8),
          Text(word.pinyin, style: text.titleLarge),
        ],
      ],
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.feedback,
    required this.word,
    required this.showPinyin,
  });

  final AnswerFeedback feedback;

  /// The Word the Exercise was about, shown so a Word only heard is also
  /// seen as characters and pinyin.
  final Word? word;
  final bool showPinyin;

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
          if (word case final word?) ...[
            const SizedBox(height: 16),
            _WordCard(word: word, showPinyin: showPinyin),
          ],
        ],
      ),
    );
  }
}
