import 'package:flutter/material.dart';
import 'package:study_engine/study_engine.dart';

/// Shows whether the Lesson is a Passed Lesson and the first-try percentage.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.result,
    required this.onTryAgain,
    required this.onDone,
  });

  final LessonResult result;
  final VoidCallback onTryAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(result.passed ? Icons.emoji_events : Icons.replay, size: 72),
              const SizedBox(height: 16),
              Text(
                result.passed ? 'Lesson passed!' : 'Not passed yet',
                style: text.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'First try: ${result.firstTryPercent}% correct',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '+${result.xpEarned} XP',
                style: text.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (!result.passed)
                const Text(
                  'You need 80% on the first try to pass.',
                  textAlign: TextAlign.center,
                ),
              if (result.nextLessonUnlocked case final next?) ...[
                const SizedBox(height: 16),
                Text(
                  'Unlocked: ${next.title}',
                  style: text.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              if (!result.passed) ...[
                OutlinedButton(
                  onPressed: onTryAgain,
                  child: const Text('Try again'),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed: onDone,
                child: const Text('Back to Lessons'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows how a finished Review went.
class ReviewResultsScreen extends StatelessWidget {
  const ReviewResultsScreen({
    super.key,
    required this.result,
    required this.onDone,
  });

  final ReviewResult result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final words = result.wordsReviewed == 1 ? 'Word' : 'Words';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.task_alt, size: 72),
              const SizedBox(height: 16),
              Text(
                'Review done!',
                style: text.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${result.wordsReviewed} $words reviewed',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '+${result.xpEarned} XP',
                style: text.titleLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: onDone,
                child: const Text('Back to Lessons'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
