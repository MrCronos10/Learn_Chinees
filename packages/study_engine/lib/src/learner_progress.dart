import 'day.dart';
import 'scheduler.dart';

/// One finished Lesson, passed or not. Quitting midway records nothing.
final class FinishedLesson {
  const FinishedLesson({
    required this.lessonId,
    required this.day,
    required this.passed,
    required this.xpEarned,
    this.enteringReview = const {},
  });

  final String lessonId;
  final Day day;
  final bool passed;
  final int xpEarned;

  /// Words entering Review because this Lesson was passed, by Word ID. A
  /// Word already in Review keeps its schedule.
  final Map<int, WordSchedule> enteringReview;
}

/// One finished Review. Quitting midway records nothing.
final class FinishedReview {
  const FinishedReview({
    required this.day,
    required this.xpEarned,
    required this.reviewed,
  });

  final Day day;
  final int xpEarned;

  /// The new schedule of every Word reviewed, by Word ID.
  final Map<int, WordSchedule> reviewed;
}

/// Stores Learner Progress, separately from Course Content (ADR-0001).
/// Refers to Words only by their permanent Word ID.
abstract interface class LearnerProgressStore {
  /// Records a finished Lesson in one step, so its pass, XP and Words
  /// entering Review are saved together or not at all.
  Future<void> recordLessonFinished(FinishedLesson lesson);

  /// Records a finished Review in one step, like [recordLessonFinished].
  Future<void> recordReviewFinished(FinishedReview review);

  Future<Set<String>> passedLessonIds();

  /// Total XP from Lessons and Reviews.
  Future<int> totalXp();

  /// Every Day on which the Learner finished at least one Lesson or Review:
  /// the Days that count toward the Streak.
  Future<Set<Day>> studyDays();

  /// The schedule of every Word in Review, by Word ID.
  Future<Map<int, WordSchedule>> wordSchedules();

  /// Whether Exercises show pinyin with characters (default true).
  Future<bool> showPinyin();

  Future<void> setShowPinyin(bool show);
}
