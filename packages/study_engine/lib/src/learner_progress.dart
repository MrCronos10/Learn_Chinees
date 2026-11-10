import 'day.dart';

/// Stores Learner Progress, separately from Course Content (ADR-0001).
abstract interface class LearnerProgressStore {
  Future<Set<String>> passedLessonIds();

  Future<void> recordPassedLesson(String lessonId, Day day);
}
