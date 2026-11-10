import 'package:sqlite3/sqlite3.dart';
import 'package:study_engine/study_engine.dart';

/// Schema version stored in SQLite's `user_version`; bump with a migration
/// whenever the schema changes, because this database is never replaced.
const _schemaVersion = 2;

/// Learner Progress persisted in its own SQLite database, separate from
/// Course Content and never replaced by an app update (ADR-0001).
final class SqliteLearnerProgressStore implements LearnerProgressStore {
  SqliteLearnerProgressStore.open(String path) : _db = sqlite3.open(path) {
    try {
      _migrate();
    } catch (_) {
      _db.close();
      rethrow;
    }
  }

  final Database _db;

  /// Brings the schema up to [_schemaVersion] in one transaction, so an
  /// interrupted first launch leaves nothing half-created.
  void _migrate() {
    final version = _db.userVersion;
    if (version > _schemaVersion) {
      throw StateError(
        'Learner Progress schema v$version is newer than this app '
        '(v$_schemaVersion)',
      );
    }
    if (version == _schemaVersion) return;
    _db.execute('BEGIN IMMEDIATE');
    try {
      if (version < 2) {
        // v2: one row per finished Lesson (passed or not) with its XP.
        _db.execute('''
          CREATE TABLE finished_lessons (
            lesson_id TEXT NOT NULL,
            finished_on TEXT NOT NULL,
            passed INTEGER NOT NULL,
            xp_earned INTEGER NOT NULL
          )
        ''');
        _db.execute(
          'CREATE INDEX finished_lessons_passed '
          'ON finished_lessons (passed, lesson_id)',
        );
      }
      if (version == 1) {
        // v1 kept only passes; they carry over with no XP, which v1 never
        // recorded.
        _db.execute(
          'INSERT INTO finished_lessons '
          'SELECT lesson_id, passed_on, 1, 0 FROM passed_lessons',
        );
        _db.execute('DROP TABLE passed_lessons');
      }
      _db.userVersion = _schemaVersion;
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<void> recordLessonFinished(FinishedLesson lesson) async {
    _db.execute(
      'INSERT INTO finished_lessons '
      '(lesson_id, finished_on, passed, xp_earned) VALUES (?, ?, ?, ?)',
      [
        lesson.lessonId,
        lesson.day.toString(),
        lesson.passed ? 1 : 0,
        lesson.xpEarned,
      ],
    );
  }

  @override
  Future<Set<String>> passedLessonIds() async => {
    for (final row in _db.select(
      'SELECT DISTINCT lesson_id FROM finished_lessons WHERE passed = 1',
    ))
      row['lesson_id'] as String,
  };

  @override
  Future<Set<Day>> studyDays() async => {
    for (final row in _db.select(
      'SELECT DISTINCT finished_on FROM finished_lessons',
    ))
      Day.parse(row['finished_on'] as String),
  };

  @override
  Future<int> totalXp() async =>
      _db
              .select(
                'SELECT COALESCE(SUM(xp_earned), 0) AS total '
                'FROM finished_lessons',
              )
              .single['total']
          as int;

  void close() => _db.close();
}
