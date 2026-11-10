/// A Word: the unit of knowledge a Learner studies, with a permanent ID.
final class Word {
  const Word({
    required this.id,
    required this.characters,
    required this.pinyin,
    required this.meaning,
  });

  /// Permanent Word ID; never reused or renumbered (ADR-0001).
  final int id;
  final String characters;
  final String pinyin;
  final String meaning;
}

/// A single question a Learner answers inside a Lesson or Review.
sealed class Exercise {
  const Exercise();

  /// The choices offered to the Learner, in display order.
  List<String> get choices;

  /// The choice that is correct.
  String get answer;
}

/// Shows a Word (characters + pinyin) and asks for its English meaning.
final class MultipleChoiceExercise extends Exercise {
  const MultipleChoiceExercise({required this.word, required this.choices});

  final Word word;

  @override
  final List<String> choices;

  @override
  String get answer => word.meaning;
}

/// A Lesson as listed on the Lesson path.
final class LessonSummary {
  const LessonSummary({required this.id, required this.title});

  final String id;
  final String title;
}

/// A Lesson with its ordered Exercises.
final class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.exercises,
  });

  final String id;
  final String title;
  final List<Exercise> exercises;
}

/// Reads the read-only Course Content.
abstract interface class CourseContentReader {
  /// Every Lesson in path order.
  Future<List<LessonSummary>> lessonPath();

  /// The Lesson with [lessonId], including its Exercises.
  Future<Lesson> lesson(String lessonId);
}
