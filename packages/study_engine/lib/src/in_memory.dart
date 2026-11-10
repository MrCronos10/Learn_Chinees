import 'course_content.dart';
import 'day.dart';
import 'learner_progress.dart';

/// Course Content held in memory, for tests and fakes.
final class InMemoryCourseContent implements CourseContentReader {
  InMemoryCourseContent(List<Lesson> lessons) : _lessons = List.of(lessons);

  final List<Lesson> _lessons;

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
}

/// Learner Progress held in memory; lost when the app closes.
final class InMemoryLearnerProgressStore implements LearnerProgressStore {
  final Map<String, Day> _passedLessons = {};

  @override
  Future<Set<String>> passedLessonIds() async => _passedLessons.keys.toSet();

  @override
  Future<void> recordPassedLesson(String lessonId, Day day) async {
    _passedLessons.putIfAbsent(lessonId, () => day);
  }
}
