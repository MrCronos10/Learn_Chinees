import 'course_content.dart';
import 'day.dart';
import 'learner_progress.dart';

enum LessonState { locked, unlocked, passed }

/// A Lesson on the Lesson path with its current state.
final class PathLesson {
  const PathLesson({
    required this.id,
    required this.title,
    required this.state,
  });

  final String id;
  final String title;
  final LessonState state;
}

/// Immediate feedback on one answer.
final class AnswerFeedback {
  const AnswerFeedback({required this.correct, required this.correctAnswer});

  final bool correct;
  final String correctAnswer;
}

/// The outcome of a finished Lesson.
final class LessonResult {
  const LessonResult({required this.passed, required this.firstTryPercent});

  /// Whether this is a Passed Lesson (at least 80% correct on the first try).
  final bool passed;

  /// Percentage of Exercises answered correctly on the first try, rounded down.
  final int firstTryPercent;
}

/// Holds all learning rules. Depends only on injected collaborators.
final class StudyEngine {
  StudyEngine({
    required CourseContentReader content,
    required LearnerProgressStore progress,
    required Clock clock,
  }) : _content = content,
       _progress = progress,
       _clock = clock;

  final CourseContentReader _content;
  final LearnerProgressStore _progress;
  final Clock _clock;

  /// Every Lesson in path order with its state. Passed Lessons are passed;
  /// the first Lesson not yet passed is unlocked; the rest are locked.
  Future<List<PathLesson>> lessonPath() async {
    final lessons = await _content.lessonPath();
    final passed = await _progress.passedLessonIds();
    var unlockedOne = false;
    final path = <PathLesson>[];
    for (final lesson in lessons) {
      final LessonState state;
      if (passed.contains(lesson.id)) {
        state = LessonState.passed;
      } else if (!unlockedOne) {
        state = LessonState.unlocked;
        unlockedOne = true;
      } else {
        state = LessonState.locked;
      }
      path.add(PathLesson(id: lesson.id, title: lesson.title, state: state));
    }
    return path;
  }

  /// Starts a Lesson. Nothing is recorded until the session is finished.
  Future<LessonSession> startLesson(String lessonId) async {
    final lesson = await _content.lesson(lessonId);
    if (lesson.exercises.isEmpty) {
      throw StateError('Lesson "$lessonId" has no Exercises');
    }
    return LessonSession._(lesson, _onFinished);
  }

  Future<void> _onFinished(Lesson lesson, LessonResult result) async {
    if (result.passed) {
      await _progress.recordPassedLesson(lesson.id, _clock.today());
    }
  }
}

/// One play-through of a Lesson.
final class LessonSession {
  LessonSession._(this._lesson, this._onFinished)
    : _queue = [for (var i = 0; i < _lesson.exercises.length; i++) i];

  final Lesson _lesson;
  final Future<void> Function(Lesson, LessonResult) _onFinished;

  /// Positions of Exercises still to answer; missed ones are re-queued at the end.
  final List<int> _queue;
  final Set<int> _answeredOnce = {};
  int _firstTryCorrect = 0;

  /// The Exercise to answer now, or null once every Exercise is answered correctly.
  Exercise? get current =>
      _queue.isEmpty ? null : _lesson.exercises[_queue.first];

  /// How many Exercises have been answered correctly so far (for a progress bar).
  int get completedCount => _lesson.exercises.length - _queue.length;

  int get exerciseCount => _lesson.exercises.length;

  /// Answers the current Exercise. A miss sends it to the end of the Lesson;
  /// only the first try counts towards the mark.
  AnswerFeedback answer(String choice) {
    if (_queue.isEmpty) throw StateError('Every Exercise is already answered');
    final position = _queue.removeAt(0);
    final exercise = _lesson.exercises[position];
    final correct = choice == exercise.answer;
    final isFirstTry = _answeredOnce.add(position);
    if (correct && isFirstTry) _firstTryCorrect++;
    if (!correct) _queue.add(position);
    return AnswerFeedback(correct: correct, correctAnswer: exercise.answer);
  }

  Future<LessonResult> finish() async {
    if (_queue.isNotEmpty) {
      throw StateError('Lesson finished before every Exercise was answered');
    }
    final total = _lesson.exercises.length;
    final result = LessonResult(
      passed: _firstTryCorrect * 5 >= total * 4,
      firstTryPercent: _firstTryCorrect * 100 ~/ total,
    );
    await _onFinished(_lesson, result);
    return result;
  }
}
