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
  const LessonResult({
    required this.passed,
    required this.firstTryPercent,
    required this.xpEarned,
  });

  /// Whether this is a Passed Lesson (at least 80% correct on the first try).
  final bool passed;

  /// Percentage of Exercises answered correctly on the first try, rounded down.
  final int firstTryPercent;

  /// XP earned in this Lesson, whether or not it was passed.
  final int xpEarned;
}

/// XP for each Exercise answered correctly on the first try. Repeats of a
/// missed Exercise earn nothing: they always end correct, so counting them
/// would give every finished Lesson the same XP.
const xpPerFirstTryCorrect = 10;

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

  /// Every Lesson in path order with its state. Passed Lessons are passed.
  /// The Lesson right after the last Passed Lesson is unlocked; so is the
  /// first Lesson not yet passed, which only differs when a content update
  /// inserted a Lesson behind the Learner. Everything else is locked.
  Future<List<PathLesson>> lessonPath() async {
    final lessons = await _content.lessonPath();
    final passed = await _progress.passedLessonIds();
    final firstNotPassed = lessons.indexWhere((l) => !passed.contains(l.id));
    final afterLastPassed =
        lessons.lastIndexWhere((l) => passed.contains(l.id)) + 1;
    return [
      for (final (i, lesson) in lessons.indexed)
        PathLesson(
          id: lesson.id,
          title: lesson.title,
          state: passed.contains(lesson.id)
              ? LessonState.passed
              : (i == firstNotPassed || i == afterLastPassed)
              ? LessonState.unlocked
              : LessonState.locked,
        ),
    ];
  }

  /// Starts an unlocked or passed Lesson on the path. Nothing is recorded
  /// until the session is finished, so quitting midway leaves Learner
  /// Progress unchanged.
  Future<LessonSession> startLesson(String lessonId) async {
    final state = [
      for (final l in await lessonPath())
        if (l.id == lessonId) l.state,
    ];
    if (state.isEmpty) {
      throw StateError('Lesson "$lessonId" is not on the Lesson path');
    }
    if (state.single == LessonState.locked) {
      throw StateError('Lesson "$lessonId" is locked');
    }
    final lesson = await _content.lesson(lessonId);
    if (lesson.exercises.isEmpty) {
      throw StateError('Lesson "$lessonId" has no Exercises');
    }
    return LessonSession._(lesson, _onFinished);
  }

  /// Total XP the Learner has earned.
  Future<int> totalXp() => _progress.totalXp();

  /// Consecutive Days, ending today or yesterday, on which the Learner
  /// finished at least one Lesson. Until today's study it still shows
  /// yesterday's run; once a whole Day is missed it is 0.
  Future<int> currentStreak() async {
    final days = await _progress.studyDays();
    final today = _clock.today();
    var day = days.contains(today) ? today : today.addDays(-1);
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = day.addDays(-1);
    }
    return streak;
  }

  Future<void> _onFinished(Lesson lesson, LessonResult result) =>
      _progress.recordLessonFinished(
        FinishedLesson(
          lessonId: lesson.id,
          day: _clock.today(),
          passed: result.passed,
          xpEarned: result.xpEarned,
        ),
      );
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
  bool _finishing = false;

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

  /// Records the finished Lesson and returns its result. Can be called once;
  /// if saving fails it may be called again.
  Future<LessonResult> finish() async {
    if (_queue.isNotEmpty) {
      throw StateError('Lesson finished before every Exercise was answered');
    }
    if (_finishing) throw StateError('Lesson already finished');
    _finishing = true;
    final total = _lesson.exercises.length;
    final result = LessonResult(
      passed: _firstTryCorrect * 5 >= total * 4,
      firstTryPercent: _firstTryCorrect * 100 ~/ total,
      xpEarned: _firstTryCorrect * xpPerFirstTryCorrect,
    );
    try {
      await _onFinished(_lesson, result);
    } catch (_) {
      _finishing = false;
      rethrow;
    }
    return result;
  }
}
