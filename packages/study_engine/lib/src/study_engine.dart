import 'course_content.dart';
import 'day.dart';
import 'learner_progress.dart';
import 'scheduler.dart';

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

/// The outcome of a finished Review.
final class ReviewResult {
  const ReviewResult({required this.wordsReviewed, required this.xpEarned});

  final int wordsReviewed;
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
    Scheduler scheduler = const BoxScheduler(),
  }) : _content = content,
       _progress = progress,
       _clock = clock,
       _scheduler = scheduler;

  final CourseContentReader _content;
  final LearnerProgressStore _progress;
  final Clock _clock;
  final Scheduler _scheduler;

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
    return LessonSession._(lesson, _recordLesson);
  }

  /// How many Words are due for Review today (including overdue ones).
  Future<int> wordsDueToday() async => (await _dueToday()).length;

  /// Starts a Review of every Word due today, or returns null when nothing is
  /// due. Nothing is recorded until the session is finished.
  Future<ReviewSession?> startReview() async {
    final due = await _dueToday();
    if (due.isEmpty) return null;
    return ReviewSession._(due, _recordReview);
  }

  /// Review Exercises for the Words due today, earliest due first. Words no
  /// longer in the Course Content are ignored (ADR-0001).
  Future<List<(int, WordSchedule, Exercise)>> _dueToday() async {
    final today = _clock.today();
    final due =
        (await _progress.wordSchedules()).entries
            .where((e) => e.value.due.compareTo(today) <= 0)
            .toList()
          ..sort(
            (a, b) => a.value.due.compareTo(b.value.due) != 0
                ? a.value.due.compareTo(b.value.due)
                : a.key.compareTo(b.key),
          );
    final exercises = await _content.reviewExercises({
      for (final e in due) e.key,
    });
    return [
      for (final e in due)
        if (exercises[e.key] case final exercise?) (e.key, e.value, exercise),
    ];
  }

  /// Whether Exercises show pinyin with the characters.
  Future<bool> showPinyin() => _progress.showPinyin();

  /// Saves the pinyin setting in Learner Progress.
  Future<void> setShowPinyin(bool show) => _progress.setShowPinyin(show);

  /// Credits and licenses for every third-party source in the Course Content.
  Future<List<Acknowledgement>> acknowledgements() =>
      _content.acknowledgements();

  /// Total XP the Learner has earned.
  Future<int> totalXp() => _progress.totalXp();

  /// Consecutive Days, ending today or yesterday, on which the Learner
  /// finished at least one Lesson or Review. Until today's study it still shows
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

  Future<void> _recordLesson(Lesson lesson, LessonResult result) async {
    final today = _clock.today();
    final enteringReview = <int, WordSchedule>{};
    if (result.passed) {
      for (final exercise in lesson.exercises) {
        if (exercise.word case final word?) {
          enteringReview[word.id] = _scheduler.enter(today);
        }
      }
    }
    await _progress.recordLessonFinished(
      FinishedLesson(
        lessonId: lesson.id,
        day: today,
        passed: result.passed,
        xpEarned: result.xpEarned,
        enteringReview: enteringReview,
      ),
    );
  }

  Future<ReviewResult> _recordReview(
    List<(int, WordSchedule, Exercise)> due,
    List<bool> firstTryCorrect,
  ) async {
    final today = _clock.today();
    final result = ReviewResult(
      wordsReviewed: due.length,
      xpEarned: firstTryCorrect.where((c) => c).length * xpPerFirstTryCorrect,
    );
    await _progress.recordReviewFinished(
      FinishedReview(
        day: today,
        xpEarned: result.xpEarned,
        reviewed: {
          for (final (i, (wordId, schedule, _)) in due.indexed)
            wordId: _scheduler.answered(
              schedule,
              correct: firstTryCorrect[i],
              day: today,
            ),
        },
      ),
    );
    return result;
  }
}

/// A run of Exercises, answered one at a time. A missed Exercise is repeated
/// at the end until answered right; only the first try counts.
sealed class StudySession<R> {
  StudySession._(this._exercises)
    : _queue = [for (var i = 0; i < _exercises.length; i++) i];

  final List<Exercise> _exercises;

  /// Positions still to answer; missed ones are re-queued at the end.
  final List<int> _queue;

  /// First-try outcome by position.
  final Map<int, bool> _firstTry = {};
  bool _finishing = false;

  /// The Exercise to answer now, or null once every one is answered right.
  Exercise? get current => _queue.isEmpty ? null : _exercises[_queue.first];

  /// How many Exercises are answered right so far (for a progress bar).
  int get completedCount => _exercises.length - _queue.length;

  int get exerciseCount => _exercises.length;

  int get _firstTryCorrectCount => _firstTry.values.where((c) => c).length;

  /// First-try outcome of every Exercise, in order.
  List<bool> get _firstTryOutcomes => [
    for (var i = 0; i < _exercises.length; i++) _firstTry[i]!,
  ];

  /// Answers the current Exercise and gives immediate feedback.
  AnswerFeedback answer(String choice) {
    if (_queue.isEmpty) throw StateError('Every Exercise is already answered');
    final position = _queue.removeAt(0);
    final exercise = _exercises[position];
    final correct = choice == exercise.answer;
    _firstTry.putIfAbsent(position, () => correct);
    if (!correct) _queue.add(position);
    return AnswerFeedback(correct: correct, correctAnswer: exercise.answer);
  }

  /// Records the finished session and returns its result. Can be called
  /// once; if saving fails it may be called again.
  Future<R> finish() async {
    if (_queue.isNotEmpty) {
      throw StateError('Finished before every Exercise was answered');
    }
    if (_finishing) throw StateError('Already finished');
    _finishing = true;
    try {
      return await _record();
    } catch (_) {
      _finishing = false;
      rethrow;
    }
  }

  Future<R> _record();
}

/// One play-through of a Lesson.
final class LessonSession extends StudySession<LessonResult> {
  LessonSession._(this._lesson, this._onFinished) : super._(_lesson.exercises);

  final Lesson _lesson;
  final Future<void> Function(Lesson, LessonResult) _onFinished;

  @override
  Future<LessonResult> _record() async {
    final total = exerciseCount;
    final correct = _firstTryCorrectCount;
    final result = LessonResult(
      passed: correct * 5 >= total * 4,
      firstTryPercent: correct * 100 ~/ total,
      xpEarned: correct * xpPerFirstTryCorrect,
    );
    await _onFinished(_lesson, result);
    return result;
  }
}

/// One Review of the Words due today.
final class ReviewSession extends StudySession<ReviewResult> {
  ReviewSession._(this._due, this._onFinished)
    : super._([for (final (_, _, exercise) in _due) exercise]);

  final List<(int, WordSchedule, Exercise)> _due;
  final Future<ReviewResult> Function(
    List<(int, WordSchedule, Exercise)>,
    List<bool>,
  )
  _onFinished;

  @override
  Future<ReviewResult> _record() => _onFinished(_due, _firstTryOutcomes);
}
