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

  static const _exerciseColumns =
      'exercises.kind, exercises.choices, exercises.syllable, exercises.tone, '
      'words.id, words.characters, words.pinyin, words.meaning';

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
      'SELECT $_exerciseColumns FROM exercises '
      'LEFT JOIN words ON words.id = exercises.word_id '
      'WHERE exercises.lesson_id = ? ORDER BY exercises.position',
      [lessonId],
    );
    return Lesson(
      id: lessonId,
      title: lessonRows.single['title'] as String,
      exercises: [for (final row in exerciseRows) _exercise(row)],
    );
  }

  @override
  Future<Map<int, Exercise>> reviewExercises(Set<int> wordIds) async {
    if (wordIds.isEmpty) return {};
    final placeholders = List.filled(wordIds.length, '?').join(', ');
    final rows = _db.select(
      'SELECT $_exerciseColumns FROM exercises '
      'JOIN words ON words.id = exercises.word_id '
      'JOIN lessons ON lessons.id = exercises.lesson_id '
      'JOIN units ON units.id = lessons.unit_id '
      'WHERE exercises.word_id IN ($placeholders) '
      'ORDER BY units.position, lessons.position, exercises.position',
      wordIds.toList(),
    );
    final found = <int, Exercise>{};
    for (final row in rows) {
      found.putIfAbsent(row['id'] as int, () => _exercise(row));
    }
    return found;
  }

  Exercise _exercise(Row row) {
    final choices = (jsonDecode(row['choices'] as String) as List)
        .cast<String>();
    final kind = row['kind'] as String;
    if (toneExerciseKinds.contains(kind)) {
      final syllable = row['syllable'] as String;
      final tone = row['tone'] as int;
      final recordings = _recordingsOf(syllable);
      return kind == exerciseKindToneMatching
          ? ToneMatchingExercise(
              syllable: syllable,
              tone: tone,
              recordings: recordings,
              choices: choices,
            )
          : ToneIdentificationExercise(
              syllable: syllable,
              tone: tone,
              recordings: recordings,
            );
    }
    final word = Word(
      id: row['id'] as int,
      characters: row['characters'] as String,
      pinyin: row['pinyin'] as String,
      meaning: row['meaning'] as String,
    );
    return switch (kind) {
      exerciseKindMultipleChoice => MultipleChoiceExercise(
        word: word,
        choices: choices,
      ),
      exerciseKindListening => ListeningExercise(word: word, choices: choices),
      _ => throw StateError('Unknown Exercise kind "$kind" in Course Content'),
    };
  }

  /// The Tone Recordings of [syllable], by tone.
  Map<int, ToneRecording> _recordingsOf(String syllable) => {
    for (final row in _db.select(
      'SELECT tone, file FROM tone_recordings WHERE syllable = ?',
      [syllable],
    ))
      row['tone'] as int: ToneRecording(
        syllable: syllable,
        tone: row['tone'] as int,
        file: row['file'] as String,
      ),
  };

  @override
  Future<List<Acknowledgement>> acknowledgements() async => [
    for (final row in _db.select(
      'SELECT name, author, license, url FROM acknowledgements ORDER BY position',
    ))
      Acknowledgement(
        name: row['name'] as String,
        author: row['author'] as String,
        license: row['license'] as String,
        url: row['url'] as String,
      ),
  ];

  void close() => _db.close();
}
