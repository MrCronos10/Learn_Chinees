import 'course_content.dart';
import 'day.dart';
import 'learner_progress.dart';
import 'scheduler.dart';

/// Course Content held in memory, for tests and fakes.
final class InMemoryCourseContent implements CourseContentReader {
  InMemoryCourseContent(
    List<Lesson> lessons, {
    List<Acknowledgement> acknowledgements = const [],
  }) : _lessons = List.of(lessons),
       _acknowledgements = List.of(acknowledgements);

  final List<Lesson> _lessons;
  final List<Acknowledgement> _acknowledgements;

  @override
  Future<List<Acknowledgement>> acknowledgements() async =>
      List.of(_acknowledgements);

  @override
  Future<List<LessonSummary>> lessonPath() async => [
    for (final lesson in _lessons)
      LessonSummary(id: lesson.id, title: lesson.title),
  ];

  @override
  Future<Lesson> lesson(String lessonId) async => _lessons.firstWhere(
    (lesson) => lesson.id == lessonId,
    orElse: () =>
        throw ArgumentError.value(lessonId, 'lessonId', 'No such Lesson'),
  );

  @override
  Future<Map<int, Exercise>> reviewExercises(Set<int> wordIds) async {
    final found = <int, Exercise>{};
    for (final exercise in _lessons.expand((l) => l.exercises)) {
      final id = exercise.word?.id;
      if (id != null && wordIds.contains(id)) {
        found.putIfAbsent(id, () => exercise);
      }
    }
    return found;
  }
}

/// Learner Progress held in memory; lost when the app closes.
final class InMemoryLearnerProgressStore implements LearnerProgressStore {
  final List<FinishedLesson> _lessons = [];
  final List<FinishedReview> _reviews = [];
  final Map<int, WordSchedule> _schedules = {};
  bool _showPinyin = true;

  @override
  Future<bool> showPinyin() async => _showPinyin;

  @override
  Future<void> setShowPinyin(bool show) async => _showPinyin = show;

  @override
  Future<void> recordLessonFinished(FinishedLesson lesson) async {
    _lessons.add(lesson);
    lesson.enteringReview.forEach(
      (wordId, schedule) => _schedules.putIfAbsent(wordId, () => schedule),
    );
  }

  @override
  Future<void> recordReviewFinished(FinishedReview review) async {
    _reviews.add(review);
    _schedules.addAll(review.reviewed);
  }

  @override
  Future<Set<String>> passedLessonIds() async => {
    for (final lesson in _lessons)
      if (lesson.passed) lesson.lessonId,
  };

  @override
  Future<Set<Day>> studyDays() async => {
    for (final lesson in _lessons) lesson.day,
    for (final review in _reviews) review.day,
  };

  @override
  Future<int> totalXp() async =>
      _lessons.fold<int>(0, (sum, l) => sum + l.xpEarned) +
      _reviews.fold<int>(0, (sum, r) => sum + r.xpEarned);

  @override
  Future<Map<int, WordSchedule>> wordSchedules() async => Map.of(_schedules);
}
