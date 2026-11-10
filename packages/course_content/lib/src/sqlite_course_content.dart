import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:study_engine/study_engine.dart';

import 'schema.dart';

/// Reads a Course Content database written by the content builder.
/// Opened read-only: the app never writes Course Content (ADR-0001).
final class SqliteCourseContent implements CourseContentReader {
  SqliteCourseContent.open(String path)
    : _db = sqlite3.open(path, mode: OpenMode.readOnly);

  final Database _db;

  @override
  Future<List<LessonSummary>> lessonPath() async => [
    for (final row in _db.select(
      'SELECT lessons.id, lessons.title FROM lessons '
      'JOIN units ON units.id = lessons.unit_id '
      'ORDER BY units.position, lessons.position',
    ))
      LessonSummary(id: row['id'] as String, title: row['title'] as String),
  ];

  @override
  Future<Lesson> lesson(String lessonId) async {
    final lessonRows = _db.select('SELECT title FROM lessons WHERE id = ?', [
      lessonId,
    ]);
    if (lessonRows.isEmpty) {
      throw ArgumentError.value(lessonId, 'lessonId', 'No such Lesson');
    }
    final exerciseRows = _db.select(
      'SELECT exercises.kind, exercises.choices, words.id, words.characters, '
      'words.pinyin, words.meaning FROM exercises '
      'JOIN words ON words.id = exercises.word_id '
      'WHERE exercises.lesson_id = ? ORDER BY exercises.position',
      [lessonId],
    );
    return Lesson(
      id: lessonId,
      title: lessonRows.single['title'] as String,
      exercises: [for (final row in exerciseRows) _exercise(row)],
    );
  }

  Exercise _exercise(Row row) {
    final kind = row['kind'] as String;
    if (kind != exerciseKindMultipleChoice) {
      throw StateError('Unknown Exercise kind "$kind" in Course Content');
    }
    return MultipleChoiceExercise(
      word: Word(
        id: row['id'] as int,
        characters: row['characters'] as String,
        pinyin: row['pinyin'] as String,
        meaning: row['meaning'] as String,
      ),
      choices: (jsonDecode(row['choices'] as String) as List).cast<String>(),
    );
  }

  void close() => _db.close();
}
