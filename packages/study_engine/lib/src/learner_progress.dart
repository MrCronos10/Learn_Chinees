import 'day.dart';

/// One finished Lesson, passed or not. Quitting midway records nothing.
final class FinishedLesson {
  const FinishedLesson({
    required this.lessonId,
    required this.day,
    required this.passed,
    required this.xpEarned,
  });

  final String lessonId;
  final Day day;
  final bool passed;
  final int xpEarned;
}

/// Stores Learner Progress, separately from Course Content (ADR-0001).
abstract interface class LearnerProgressStore {
  /// Records a finished Lesson in one step, so its pass and XP are saved
  /// together or not at all.
  Future<void> recordLessonFinished(FinishedLesson lesson);

  Future<Set<String>> passedLessonIds();

  Future<int> totalXp();

  /// Every Day on which the Learner finished at least one Lesson (and, once
  /// Review exists, a Review): the Days that count toward the Streak.
  Future<Set<Day>> studyDays();
}
