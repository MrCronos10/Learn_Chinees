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

  /// The Word this Exercise studies, if any; Words met in a Passed Lesson
  /// enter Review.
  Word? get word;
}

/// Shows a Word (characters + pinyin) and asks for its English meaning.
final class MultipleChoiceExercise extends Exercise {
  const MultipleChoiceExercise({required this.word, required this.choices});

  @override
  final Word word;

  @override
  final List<String> choices;

  @override
  String get answer => word.meaning;
}

/// Plays a Word aloud (device speech engine; ADR-0002) and asks for its
/// English meaning. The Word itself is not shown until answered.
final class ListeningExercise extends Exercise {
  const ListeningExercise({required this.word, required this.choices});

  @override
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

/// The credit and license notice for one third-party source used in the
/// Course Content.
final class Acknowledgement {
  const Acknowledgement({
    required this.name,
    required this.author,
    required this.license,
    required this.url,
  });

  final String name;
  final String author;
  final String license;
  final String url;
}

/// Reads the read-only Course Content.
abstract interface class CourseContentReader {
  /// Every Lesson in path order.
  Future<List<LessonSummary>> lessonPath();

  /// The Lesson with [lessonId], including its Exercises.
  Future<Lesson> lesson(String lessonId);

  /// One Exercise to review each of [wordIds] with: the first Exercise on the
  /// Lesson path that studies that Word. IDs no longer in the Course Content
  /// (retired Words) are left out.
  Future<Map<int, Exercise>> reviewExercises(Set<int> wordIds);

  /// Every third-party source used in the Course Content, with its license.
  Future<List<Acknowledgement>> acknowledgements();
}
