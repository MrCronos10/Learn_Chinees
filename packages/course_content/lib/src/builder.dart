import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:study_engine/study_engine.dart';

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
/// Word ID is never reused (ADR-0001). [recordingsPath] is the Tone
/// Recordings list, needed when any Lesson has tone Exercises; its audio
/// files are copied into a `tones` folder next to [outputPath]. An existing
/// file at [outputPath] is replaced only after the source validates and the
/// database is written.
void buildCourseContent({
  required String sourcePath,
  required String registryPath,
  required String outputPath,
  String? recordingsPath,
}) {
  final _Source source;
  final _WordIdRegistry registry;
  final List<_SourceRecording> recordings;
  try {
    source = _Source.parse(File(sourcePath).readAsStringSync());
    recordings = recordingsPath == null
        ? const []
        : _SourceRecording.parseList(File(recordingsPath));
    source.validateRecordings(recordings);
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
    for (final (position, a) in source.acknowledgements.indexed) {
      db.execute(
        'INSERT INTO acknowledgements '
        '(id, position, name, author, license, url) VALUES (?, ?, ?, ?, ?, ?)',
        [a.id, position, a.name, a.author, a.license, a.url],
      );
    }
    for (final word in source.words) {
      db.execute(
        'INSERT INTO words (id, characters, pinyin, meaning, source_id) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          wordIds[word.characters],
          word.characters,
          word.pinyin,
          word.meaning,
          word.sourceId,
        ],
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
          final Object? wordId;
          final List<String> choices;
          if (exercise.isToneExercise) {
            wordId = null;
            choices = exercise.kind == exerciseKindToneMatching
                ? _shuffledTones('${lesson.id}/$position')
                : const ['1', '2', '3', '4'];
          } else {
            final word = source.wordFor(exercise.word!, lesson.id);
            wordId = wordIds[word.characters];
            choices = source.choicesFor(word, lesson);
          }
          db.execute(
            'INSERT INTO exercises '
            '(lesson_id, position, kind, word_id, syllable, tone, choices) '
            'VALUES (?, ?, ?, ?, ?, ?, ?)',
            [
              lesson.id,
              position,
              exercise.kind,
              wordId,
              exercise.syllable,
              exercise.tone,
              jsonEncode(choices),
            ],
          );
        }
      }
    }
    for (final recording in recordings) {
      db.execute(
        'INSERT INTO tone_recordings (syllable, tone, file, source_id) '
        'VALUES (?, ?, ?, ?)',
        [
          recording.syllable,
          recording.tone,
          recording.bundledName,
          recording.sourceId,
        ],
      );
    }
    db.execute('COMMIT');
  } finally {
    db.close();
  }

  registry.save();
  staging.renameSync(outputPath);
  _bundleRecordings(recordings, p.dirname(outputPath));
}

/// Replaces the `tones` folder next to the database with the Tone
/// Recordings, renamed `<syllable><tone>.<ext>`. The folder belongs to the
/// builder; a README marks it as generated and keeps it in version control.
void _bundleRecordings(List<_SourceRecording> recordings, String outputDir) {
  final folder = Directory(p.join(outputDir, toneRecordingsFolder));
  if (folder.existsSync()) folder.deleteSync(recursive: true);
  folder.createSync(recursive: true);
  File(p.join(folder.path, 'README.md')).writeAsStringSync(
    'Tone Recordings, written by the content builder. Do not edit: '
    'change the Tone Recordings list and rebuild.\n',
  );
  for (final recording in recordings) {
    recording.file.copySync(p.join(folder.path, recording.bundledName));
  }
}

/// The four tones in an order that depends only on [key], so a rebuild
/// keeps it, while the matching sound's position does not give it away.
List<String> _shuffledTones(String key) {
  final seed = key.codeUnits.fold(17, (h, c) => (h * 31 + c) & 0x7fffffff);
  return ['1', '2', '3', '4']..shuffle(Random(seed));
}

final class _SourceWord {
  _SourceWord(this.characters, this.pinyin, this.meaning, this.sourceId);

  final String characters;
  final String pinyin;
  final String meaning;

  /// The third-party source this Word comes from, if not original; it must
  /// have an Acknowledgement.
  final String? sourceId;

  /// Identity in the Word ID registry: the characters alone (they are unique
  /// in the source), so correcting pinyin or meaning keeps the Word ID.
  String get registryKey => characters;
}

final class _SourceExercise {
  _SourceExercise(this.kind, {this.word, this.syllable, this.tone});

  final String kind;

  /// The Word a multiple-choice or listening Exercise studies.
  final String? word;

  /// The syllable and tone a tone Exercise asks about.
  final String? syllable;
  final int? tone;

  bool get isToneExercise => toneExerciseKinds.contains(kind);
}

/// One entry in the Tone Recordings list.
final class _SourceRecording {
  _SourceRecording(this.syllable, this.tone, this.file, this.sourceId);

  final String syllable;
  final int tone;

  /// The audio file, resolved against the list's folder.
  final File file;

  /// The source it comes from; it must have an Acknowledgement.
  final String sourceId;

  /// Its name once bundled with the app.
  String get bundledName => '$syllable$tone${p.extension(file.path)}';

  static List<_SourceRecording> parseList(File list) {
    final root = jsonDecode(list.readAsStringSync());
    final recordings = [
      for (final r in _Source._list(root, 'recordings'))
        _SourceRecording(
          _Source._string(r, 'syllable'),
          _Source._tone(r),
          File(p.join(list.parent.path, _Source._string(r, 'file'))),
          _Source._string(r, 'source'),
        ),
    ];
    _Source._requireUnique(
      recordings.map((r) => '"${r.syllable}" tone ${r.tone}'),
      'Tone Recording of',
    );
    for (final r in recordings) {
      if (!r.file.existsSync()) {
        throw ContentBuildException(
          'Tone Recording of "${r.syllable}" tone ${r.tone}: file '
          '${r.file.path} does not exist',
        );
      }
    }
    return recordings;
  }
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

final class _SourceAcknowledgement {
  _SourceAcknowledgement(
    this.id,
    this.name,
    this.author,
    this.license,
    this.url,
  );

  final String id;
  final String name;
  final String author;
  final String license;
  final String url;
}

final class _Source {
  _Source(this.units, this.words, this.acknowledgements);

  final List<_SourceUnit> units;
  final List<_SourceWord> words;
  final List<_SourceAcknowledgement> acknowledgements;

  static _Source parse(String json) {
    final root = jsonDecode(json) as Map<String, Object?>;
    final words = [
      for (final w in _list(root, 'words'))
        _SourceWord(
          _string(w, 'characters'),
          _string(w, 'pinyin'),
          _string(w, 'meaning'),
          _optionalString(w, 'source'),
        ),
    ];
    final acknowledgements = [
      if ((root as Map).containsKey('acknowledgements'))
        for (final a in _list(root, 'acknowledgements'))
          _SourceAcknowledgement(
            _string(a, 'id'),
            _string(a, 'name'),
            _string(a, 'author'),
            _string(a, 'license'),
            _string(a, 'url'),
          ),
    ];
    final units = [
      for (final u in _list(root, 'units'))
        _SourceUnit(_string(u, 'id'), _string(u, 'title'), [
          for (final l in _list(u, 'lessons'))
            _SourceLesson(_string(l, 'id'), _string(l, 'title'), [
              for (final e in _list(l, 'exercises')) _exercise(e),
            ]),
        ]),
    ];
    final source = _Source(units, words, acknowledgements);
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

  static _SourceExercise _exercise(Object? e) {
    final kind = _string(e, 'kind');
    if (toneExerciseKinds.contains(kind)) {
      final syllable = _string(e, 'syllable');
      final tone = _tone(e);
      try {
        tonedPinyin(syllable, tone);
      } on ArgumentError {
        throw ContentBuildException(
          'Tone Exercise syllable "$syllable" is not plain pinyin (letters '
          'with a vowel, no tone mark, v for ü)',
        );
      }
      return _SourceExercise(kind, syllable: syllable, tone: tone);
    }
    if (wordExerciseKinds.contains(kind)) {
      return _SourceExercise(kind, word: _string(e, 'word'));
    }
    throw ContentBuildException(
      'An Exercise has unknown kind "$kind" in ${jsonEncode(e)}',
    );
  }

  /// A tone, 1 to 4.
  static int _tone(Object? map) {
    final value = (map as Map)['tone'];
    if (value is! int || value < 1 || value > 4) {
      throw ContentBuildException(
        '"tone" must be 1, 2, 3 or 4 in ${jsonEncode(map)}',
      );
    }
    return value;
  }

  static String? _optionalString(Object? map, String key) =>
      (map as Map).containsKey(key) ? _string(map, key) : null;

  static List<Object?> _list(Object? map, String key) {
    final value = (map as Map)[key];
    if (value is! List) {
      throw ContentBuildException('Missing list "$key"');
    }
    return value;
  }

  void _validate() {
    _requireUnique(words.map((w) => w.characters), 'Word');
    _requireUnique(acknowledgements.map((a) => a.id), 'Acknowledgement id');
    final acknowledged = {for (final a in acknowledgements) a.id};
    for (final word in words) {
      final sourceId = word.sourceId;
      if (sourceId != null && !acknowledged.contains(sourceId)) {
        throw ContentBuildException(
          'Word "${word.characters}" comes from source "$sourceId", which has '
          'no Acknowledgement. Add it to "acknowledgements" with its name, '
          'author, license and url.',
        );
      }
    }
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
        if (exercise.word case final word?) wordFor(word, lesson.id);
      }
    }
    if (words.map((w) => w.meaning).toSet().length < 2) {
      throw ContentBuildException(
        'Exercises need at least two Words with different '
        'meanings',
      );
    }
  }

  /// Every tone Exercise needs its syllable's Tone Recording in all four
  /// tones (the other three are the wrong choices), and every recording's
  /// source needs an Acknowledgement.
  void validateRecordings(List<_SourceRecording> recordings) {
    final acknowledged = {for (final a in acknowledgements) a.id};
    for (final r in recordings) {
      if (!acknowledged.contains(r.sourceId)) {
        throw ContentBuildException(
          'Tone Recording of "${r.syllable}" tone ${r.tone} comes from source '
          '"${r.sourceId}", which has no Acknowledgement. Add it to '
          '"acknowledgements" with its name, author, license and url.',
        );
      }
    }
    final recorded = {for (final r in recordings) (r.syllable, r.tone)};
    for (final lesson in units.expand((u) => u.lessons)) {
      for (final exercise in lesson.exercises.where((e) => e.isToneExercise)) {
        final syllable = exercise.syllable!;
        for (var tone = 1; tone <= 4; tone++) {
          if (!recorded.contains((syllable, tone))) {
            throw ContentBuildException(
              'Lesson "${lesson.id}" has a tone Exercise on "$syllable", but '
              'there is no Tone Recording of "$syllable" tone $tone. Add it '
              'to the Tone Recordings list.',
            );
          }
        }
      }
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
    final lessonMeanings = [
      for (final e in lesson.exercises)
        if (e.word case final w?) wordFor(w, lesson.id).meaning,
    ];
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
