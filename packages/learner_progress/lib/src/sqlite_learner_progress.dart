import 'package:sqlite3/sqlite3.dart';
import 'package:study_engine/study_engine.dart';

/// Schema version stored in SQLite's `user_version`; bump with a migration
/// whenever the schema changes, because this database is never replaced.
const _schemaVersion = 1;

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
      if (version < 1) {
        _db.execute('''
          CREATE TABLE passed_lessons (
            lesson_id TEXT PRIMARY KEY,
            passed_on TEXT NOT NULL
          )
        ''');
      }
      _db.userVersion = _schemaVersion;
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<Set<String>> passedLessonIds() async => {
    for (final row in _db.select('SELECT lesson_id FROM passed_lessons'))
      row['lesson_id'] as String,
  };

  @override
  Future<void> recordPassedLesson(String lessonId, Day day) async {
    // The first pass is kept; passing again later changes nothing.
    _db.execute(
      'INSERT OR IGNORE INTO passed_lessons (lesson_id, passed_on) '
      'VALUES (?, ?)',
      [lessonId, day.toString()],
    );
  }

  void close() => _db.close();
}
