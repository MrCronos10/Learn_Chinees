import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'schema.dart';

/// The content source is invalid; [message] says what to fix.
final class ContentBuildException implements Exception {
  ContentBuildException(this.message);

  final String message;

  @override
  String toString() => 'ContentBuildException: $message';
}

/// How many wrong meanings a multiple-choice Exercise offers.
const _distractorCount = 3;

/// Builds the read-only Course Content database from source files.
///
/// [registryPath] is the Word ID registry: it is read if present and
/// rewritten with any newly assigned IDs. Entries are never removed, so a
/// Word ID is never reused (ADR-0001). An existing file at [outputPath] is
/// replaced only after the source validates and the database is written.
void buildCourseContent({
  required String sourcePath,
  required String registryPath,
  required String outputPath,
}) {
  final _Source source;
  final _WordIdRegistry registry;
  try {
    source = _Source.parse(File(sourcePath).readAsStringSync());
    registry = _WordIdRegistry.load(File(registryPath));
  } on ContentBuildException {
    rethrow;
  } on FileSystemException catch (e) {
    throw ContentBuildException('Cannot read ${e.path}: ${e.message}');
  } on FormatException catch (e) {
    throw ContentBuildException('Invalid JSON: ${e.message}');
  } on TypeError catch (e) {
    throw ContentBuildException(
      'Source or Word ID registry is badly shaped: $e',
    );
  }
  final wordIds = {
    for (final word in source.words) word.characters: registry.idFor(word),
  };

  final staging = File('$outputPath.building');
  if (staging.existsSync()) staging.deleteSync();
  final db = sqlite3.open(staging.path);
  try {
    db.execute(createSchemaSql);
    db.execute('BEGIN');
    for (final word in source.words) {
      db.execute(
        'INSERT INTO words (id, characters, pinyin, meaning) VALUES (?, ?, ?, ?)',
        [wordIds[word.characters], word.characters, word.pinyin, word.meaning],
      );
    }
    var lessonPosition = 0;
    for (final (unitPosition, unit) in source.units.indexed) {
      db.execute('INSERT INTO units (id, position, title) VALUES (?, ?, ?)', [
        unit.id,
        unitPosition,
        unit.title,
      ]);
      for (final lesson in unit.lessons) {
        db.execute(
          'INSERT INTO lessons (id, unit_id, position, title) VALUES (?, ?, ?, ?)',
          [lesson.id, unit.id, lessonPosition++, lesson.title],
        );
        for (final (position, exercise) in lesson.exercises.indexed) {
          final word = source.wordFor(exercise.word, lesson.id);
          db.execute(
            'INSERT INTO exercises (lesson_id, position, kind, word_id, choices) '
            'VALUES (?, ?, ?, ?, ?)',
            [
              lesson.id,
              position,
              exercise.kind,
              wordIds[word.characters],
              jsonEncode(source.choicesFor(word, lesson)),
            ],
          );
        }
      }
    }
    db.execute('COMMIT');
  } finally {
    db.close();
  }

  registry.save();
  staging.renameSync(outputPath);
}

final class _SourceWord {
  _SourceWord(this.characters, this.pinyin, this.meaning);

  final String characters;
  final String pinyin;
  final String meaning;

  /// Identity in the Word ID registry: the characters alone (they are unique
  /// in the source), so correcting pinyin or meaning keeps the Word ID.
  String get registryKey => characters;
}

final class _SourceExercise {
  _SourceExercise(this.kind, this.word);

  final String kind;
  final String word;
}

final class _SourceLesson {
  _SourceLesson(this.id, this.title, this.exercises);

  final String id;
  final String title;
  final List<_SourceExercise> exercises;
}

final class _SourceUnit {
  _SourceUnit(this.id, this.title, this.lessons);

  final String id;
  final String title;
  final List<_SourceLesson> lessons;
}

final class _Source {
  _Source(this.units, this.words);

  final List<_SourceUnit> units;
  final List<_SourceWord> words;

  static _Source parse(String json) {
    final root = jsonDecode(json) as Map<String, Object?>;
    final words = [
      for (final w in _list(root, 'words'))
        _SourceWord(
          _string(w, 'characters'),
          _string(w, 'pinyin'),
          _string(w, 'meaning'),
        ),
    ];
    final units = [
      for (final u in _list(root, 'units'))
        _SourceUnit(_string(u, 'id'), _string(u, 'title'), [
          for (final l in _list(u, 'lessons'))
            _SourceLesson(_string(l, 'id'), _string(l, 'title'), [
              for (final e in _list(l, 'exercises'))
                _SourceExercise(_string(e, 'kind'), _string(e, 'word')),
            ]),
        ]),
    ];
    final source = _Source(units, words);
    source._validate();
    return source;
  }

  static String _string(Object? map, String key) {
    final value = (map as Map)[key];
    if (value is! String || value.isEmpty) {
      throw ContentBuildException('Missing "$key" in ${jsonEncode(map)}');
    }
    return value;
  }

  static List<Object?> _list(Object? map, String key) {
    final value = (map as Map)[key];
    if (value is! List) {
      throw ContentBuildException('Missing list "$key"');
    }
    return value;
  }

  void _validate() {
    _requireUnique(words.map((w) => w.characters), 'Word');
    _requireUnique(units.map((u) => u.id), 'Unit id');
    _requireUnique(
      units.expand((u) => u.lessons).map((l) => l.id),
      'Lesson id',
    );
    for (final lesson in units.expand((u) => u.lessons)) {
      if (lesson.exercises.isEmpty) {
        throw ContentBuildException('Lesson "${lesson.id}" has no Exercises');
      }
      for (final exercise in lesson.exercises) {
        if (!wordExerciseKinds.contains(exercise.kind)) {
          throw ContentBuildException(
            'Lesson "${lesson.id}" has an Exercise of unknown kind '
            '"${exercise.kind}"',
          );
        }
        wordFor(exercise.word, lesson.id);
      }
    }
    if (words.map((w) => w.meaning).toSet().length < 2) {
      throw ContentBuildException(
        'Exercises need at least two Words with different '
        'meanings',
      );
    }
  }

  static void _requireUnique(Iterable<String> values, String what) {
    final seen = <String>{};
    for (final value in values) {
      if (!seen.add(value)) {
        throw ContentBuildException('$what "$value" appears more than once');
      }
    }
  }

  _SourceWord wordFor(String characters, String lessonId) => words.firstWhere(
    (w) => w.characters == characters,
    orElse: () => throw ContentBuildException(
      'Lesson "$lessonId" uses Word "$characters", which is not in the '
      'Word list',
    ),
  );

  /// The Word's meaning plus up to [_distractorCount] other meanings, taken
  /// first from the same Lesson then from the rest of the Course, sorted so
  /// the correct answer's position does not give it away.
  List<String> choicesFor(_SourceWord word, _SourceLesson lesson) {
    final lessonMeanings = lesson.exercises.map(
      (e) => wordFor(e.word, lesson.id).meaning,
    );
    final distractors = <String>{
      ...lessonMeanings,
      ...words.map((w) => w.meaning),
    }..remove(word.meaning);
    return [word.meaning, ...distractors.take(_distractorCount)]..sort();
  }
}

/// Owns permanent Word IDs: once assigned, an ID always means the same Word
/// and is never given to another one, even after the Word is removed.
final class _WordIdRegistry {
  _WordIdRegistry(this._file, this._ids);

  final File _file;
  final Map<String, int> _ids;

  static _WordIdRegistry load(File file) {
    final ids = <String, int>{};
    if (file.existsSync()) {
      final root = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      (root['words'] as Map).forEach((k, v) => ids[k as String] = v as int);
    }
    return _WordIdRegistry(file, ids);
  }

  int idFor(_SourceWord word) => _ids.putIfAbsent(
    word.registryKey,
    () => _ids.values.fold(0, (max, id) => id > max ? id : max) + 1,
  );

  void save() {
    const encoder = JsonEncoder.withIndent('  ');
    _file.writeAsStringSync('${encoder.convert({'words': _ids})}\n');
  }
}
