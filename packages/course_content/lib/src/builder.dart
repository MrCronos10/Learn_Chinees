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
/// [registryPath] is the ID registry of Words and Lessons: it is read if present and
/// rewritten with any newly assigned IDs. Entries are never removed, so a
/// Word ID is never reused (ADR-0001). [recordingsPath] is the Tone
/// Recordings list, needed when any Lesson has tone Exercises. [cedictPath]
/// is a CC-CEDICT file (or an extract in its format), needed when any Word
/// has `"source": "cc-cedict"`: such a Word takes its pinyin and first
/// meaning from it unless the source gives its own. The Tone Recordings list's its audio
/// files are copied into a `tones` folder next to [outputPath]. An existing
/// file at [outputPath] is replaced only after the source validates and the
/// database is written.
void buildCourseContent({
  required String sourcePath,
  required String registryPath,
  required String outputPath,
  String? recordingsPath,
  String? cedictPath,
}) {
  final _Source source;
  final _IdRegistry registry;
  final List<_SourceRecording> recordings;
  try {
    final cedict = cedictPath == null ? null : _Cedict.load(File(cedictPath));
    source = _Source.parse(File(sourcePath).readAsStringSync(), cedict);
    recordings = recordingsPath == null
        ? const []
        : _SourceRecording.parseList(File(recordingsPath));
    source.validateRecordings(recordings);
    registry = _IdRegistry.load(File(registryPath))
      ..checkLessons(source.units.expand((u) => u.lessons).map((l) => l.id));
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
                : _toneChoices;
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
              exercise.tone?.number,
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
          recording.tone.number,
          recording.bundledName,
          recording.sourceId,
        ],
      );
    }
    db.execute('COMMIT');
  } finally {
    db.close();
  }

  final tones = Directory(p.join(p.dirname(outputPath), toneRecordingsFolder));
  final Directory stagedTones;
  try {
    stagedTones = _stageRecordings(
      recordings,
      Directory('${tones.path}.building'),
    );
  } catch (_) {
    staging.deleteSync();
    rethrow;
  }

  // Everything is written; only now replace the previous build.
  registry.save();
  if (tones.existsSync()) tones.deleteSync(recursive: true);
  stagedTones.renameSync(tones.path);
  staging.renameSync(outputPath);
}

/// Copies the Tone Recordings, renamed `<syllable><tone>.<ext>`, into
/// [folder], ready to replace the `tones` folder next to the database. That
/// folder belongs to the builder; a README marks it as generated and keeps
/// it in version control. On failure nothing is left behind.
Directory _stageRecordings(
  List<_SourceRecording> recordings,
  Directory folder,
) {
  if (folder.existsSync()) folder.deleteSync(recursive: true);
  folder.createSync(recursive: true);
  try {
    File(p.join(folder.path, 'README.md')).writeAsStringSync(
      'Tone Recordings, written by the content builder. Do not edit: '
      'change the Tone Recordings list and rebuild.\n',
    );
    for (final recording in recordings) {
      recording.file.copySync(p.join(folder.path, recording.bundledName));
    }
  } on FileSystemException catch (e) {
    folder.deleteSync(recursive: true);
    throw ContentBuildException(
      'Cannot copy Tone Recording ${e.path}: ${e.message}',
    );
  }
  return folder;
}

/// The four tones as Exercise choices, in order.
final _toneChoices = [for (final tone in Tone.values) tone.choice];

/// The four tones in an order that depends only on [key], so a rebuild
/// keeps it, while the matching sound's position does not give it away.
List<String> _shuffledTones(String key) {
  final seed = key.codeUnits.fold(17, (h, c) => (h * 31 + c) & 0x7fffffff);
  return List.of(_toneChoices)..shuffle(Random(seed));
}

/// Writes to [outputPath] an extract of the CC-CEDICT file at [cedictPath]:
/// its header with the license, then, unchanged, exactly the entries the
/// Words of the source at [sourcePath] take from CC-CEDICT. Building from the
/// extract gives the same Words as building from the full file.
void extractCedict({
  required String sourcePath,
  required String cedictPath,
  required String outputPath,
}) {
  final lines = <String>[];
  try {
    final cedict = _Cedict.load(File(cedictPath));
    final root = jsonDecode(File(sourcePath).readAsStringSync());
    lines.addAll(cedict.header);
    lines.addAll([
      '#',
      '# Extract: only the entries this course uses, copied unchanged from',
      '# the full CC-CEDICT file (content/README.md says how to regenerate).',
    ]);
    final entries = <String>{};
    for (final w in _Source._list(root, 'words')) {
      if (_Source._optionalString(w, 'source') != cedictSourceId) continue;
      entries.add(
        cedict
            .entryFor(
              _Source._string(w, 'characters'),
              _Source._optionalString(w, 'cedictPinyin'),
            )
            .line,
      );
    }
    lines.addAll(entries);
  } on FileSystemException catch (e) {
    throw ContentBuildException('Cannot read ${e.path}: ${e.message}');
  } on FormatException catch (e) {
    throw ContentBuildException('Invalid JSON: ${e.message}');
  }
  File(outputPath).writeAsStringSync('${lines.join('\n')}\n');
}

/// The Acknowledgement id that marks a Word as taken from CC-CEDICT.
const cedictSourceId = 'cc-cedict';

/// One CC-CEDICT entry: `Traditional Simplified [pin1 yin1] /def/def/`.
final class _CedictEntry {
  _CedictEntry(
    this.line,
    this.traditional,
    this.simplified,
    this.pinyin,
    this.definitions,
  );

  /// The entry exactly as written in CC-CEDICT.
  final String line;
  final String traditional;
  final String simplified;

  /// As written in CC-CEDICT, with tone numbers (e.g. `ni3 hao3`).
  final String pinyin;
  final List<String> definitions;

  /// The pinyin with tone marks, syllables joined (e.g. `nǐhǎo`); `5` is the
  /// neutral tone, `u:` is `ü`, and an apostrophe separates a syllable
  /// starting with a, e or o.
  String get markedPinyin {
    final syllables = pinyin.toLowerCase().replaceAll('u:', 'v').split(' ');
    final out = StringBuffer();
    for (final (i, syllable) in syllables.indexed) {
      final number = int.tryParse(syllable.substring(syllable.length - 1));
      final base = number == null
          ? syllable
          : syllable.substring(0, syllable.length - 1);
      final tone = number == null ? null : Tone.fromNumber(number);
      if (!isPlainPinyin(base) ||
          (number != null && number != 5 && tone == null)) {
        throw ContentBuildException(
          'CC-CEDICT pinyin "$pinyin" for "$simplified" cannot be converted; '
          'give the Word its own "pinyin"',
        );
      }
      if (i > 0 && 'aeo'.contains(base[0])) out.write("'");
      out.write(
        tone == null ? base.replaceAll('v', 'ü') : tonedPinyin(base, tone),
      );
    }
    return out.toString();
  }
}

/// CC-CEDICT entries by simplified characters.
final class _Cedict {
  _Cedict(this.header, this._entries);

  /// The comment lines at the top of the file, including its license.
  final List<String> header;
  final Map<String, List<_CedictEntry>> _entries;

  static final _line = RegExp(r'^(\S+) (\S+) \[([^\]]*)\] /(.*)/\s*$');

  static _Cedict load(File file) {
    final entries = <String, List<_CedictEntry>>{};
    final header = <String>[];
    for (final (i, line) in file.readAsLinesSync().indexed) {
      if (line.startsWith('#')) {
        if (entries.isEmpty) header.add(line);
        continue;
      }
      if (line.isEmpty) continue;
      final match = _line.firstMatch(line);
      if (match == null) {
        throw ContentBuildException(
          '${file.path} line ${i + 1} is not a CC-CEDICT entry: $line',
        );
      }
      final entry = _CedictEntry(
        line,
        match[1]!,
        match[2]!,
        match[3]!,
        match[4]!.split('/'),
      );
      entries.putIfAbsent(entry.simplified, () => []).add(entry);
    }
    return _Cedict(header, entries);
  }

  /// The entry for [characters]. [pinyin] picks a reading when there are
  /// several; "variant of" entries are skipped, and among entries of the same
  /// reading the one written the same in traditional characters is preferred
  /// (so 你 means 你, not its variant 妳).
  _CedictEntry entryFor(String characters, String? pinyin) {
    final all = _entries[characters] ?? const <_CedictEntry>[];
    if (all.isEmpty) {
      throw ContentBuildException('Word "$characters" is not in CC-CEDICT');
    }
    var found = [
      for (final e in all)
        if (!e.definitions.any((d) => d.startsWith('variant of '))) e,
    ];
    if (pinyin != null) {
      found = [
        for (final e in found)
          if (e.pinyin == pinyin) e,
      ];
      if (found.isEmpty) {
        throw ContentBuildException(
          'Word "$characters" has no CC-CEDICT entry [$pinyin]; it has '
          '${all.map((e) => e.pinyin).toSet().join(', ')}',
        );
      }
    }
    if (found.map((e) => e.pinyin).toSet().length == 1 && found.length > 1) {
      final same = [
        for (final e in found)
          if (e.traditional == characters) e,
      ];
      if (same.length == 1) found = same;
    }
    if (found.length > 1) {
      throw ContentBuildException(
        'Word "$characters" has ${found.length} CC-CEDICT entries '
        '(${found.map((e) => e.pinyin).join(', ')}); add "cedictPinyin" '
        'naming the one it means',
      );
    }
    return found.single;
  }
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
  final Tone? tone;

  bool get isToneExercise => toneExerciseKinds.contains(kind);
}

/// One entry in the Tone Recordings list.
final class _SourceRecording {
  _SourceRecording(this.syllable, this.tone, this.file, this.sourceId);

  final String syllable;
  final Tone tone;

  /// The audio file, resolved against the list's folder.
  final File file;

  /// The source it comes from; it must have an Acknowledgement.
  final String sourceId;

  /// Its name once bundled with the app.
  String get bundledName => '$syllable${tone.number}${p.extension(file.path)}';

  /// How error messages name it.
  String get description => 'Tone Recording of "$syllable" tone ${tone.number}';

  static List<_SourceRecording> parseList(File list) {
    final root = jsonDecode(list.readAsStringSync());
    final recordings = [
      for (final r in _Source._list(root, 'recordings'))
        _SourceRecording(
          _Source._syllable(r),
          _Source._tone(r),
          File(p.join(list.parent.path, _Source._string(r, 'file'))),
          _Source._string(r, 'source'),
        ),
    ];
    _Source._requireUnique(recordings.map((r) => r.description), 'Entry');
    for (final r in recordings) {
      if (!r.file.existsSync()) {
        throw ContentBuildException(
          '${r.description}: file ${r.file.path} does not exist',
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

  static _Source parse(String json, _Cedict? cedict) {
    final root = jsonDecode(json) as Map<String, Object?>;
    final words = [for (final w in _list(root, 'words')) _word(w, cedict)];
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

  /// A Word, its pinyin and meaning taken from CC-CEDICT when it cites it
  /// and the source does not give them.
  static _SourceWord _word(Object? w, _Cedict? cedict) {
    final characters = _string(w, 'characters');
    final sourceId = _optionalString(w, 'source');
    var pinyin = _optionalString(w, 'pinyin');
    var meaning = _optionalString(w, 'meaning');
    if (sourceId == cedictSourceId && (pinyin == null || meaning == null)) {
      if (cedict == null) {
        throw ContentBuildException(
          'Word "$characters" comes from CC-CEDICT, but no CC-CEDICT file '
          'was given (--cedict)',
        );
      }
      final entry = cedict.entryFor(
        characters,
        _optionalString(w, 'cedictPinyin'),
      );
      pinyin ??= entry.markedPinyin;
      meaning ??= entry.definitions.first;
    }
    if (pinyin == null || meaning == null) {
      throw ContentBuildException(
        'Word "$characters" needs its "pinyin" and "meaning", or '
        '"source": "$cedictSourceId" to take them from CC-CEDICT',
      );
    }
    return _SourceWord(characters, pinyin, meaning, sourceId);
  }

  static _SourceExercise _exercise(Object? e) {
    final kind = _string(e, 'kind');
    if (toneExerciseKinds.contains(kind)) {
      return _SourceExercise(kind, syllable: _syllable(e), tone: _tone(e));
    }
    if (wordExerciseKinds.contains(kind)) {
      return _SourceExercise(kind, word: _string(e, 'word'));
    }
    throw ContentBuildException(
      'An Exercise has unknown kind "$kind" in ${jsonEncode(e)}',
    );
  }

  /// A tone, written 1 to 4.
  static Tone _tone(Object? map) {
    final value = (map as Map)['tone'];
    final tone = value is int ? Tone.fromNumber(value) : null;
    if (tone == null) {
      throw ContentBuildException(
        '"tone" must be 1, 2, 3 or 4 in ${jsonEncode(map)}',
      );
    }
    return tone;
  }

  /// A syllable in plain pinyin; it also names a bundled file, so nothing
  /// else (no path, no capitals, no tone marks) gets through.
  static String _syllable(Object? map) {
    final value = _string(map, 'syllable');
    if (!isPlainPinyin(value)) {
      throw ContentBuildException(
        'Syllable "$value" is not plain pinyin (lowercase letters with a '
        'vowel, no tone mark, v for ü) in ${jsonEncode(map)}',
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
          '${r.description} comes from source "${r.sourceId}", which has no '
          'Acknowledgement. Add it to '
          '"acknowledgements" with its name, author, license and url.',
        );
      }
    }
    final recorded = {for (final r in recordings) (r.syllable, r.tone)};
    for (final lesson in units.expand((u) => u.lessons)) {
      for (final exercise in lesson.exercises.where((e) => e.isToneExercise)) {
        final syllable = exercise.syllable!;
        for (final tone in Tone.values) {
          if (!recorded.contains((syllable, tone))) {
            throw ContentBuildException(
              'Lesson "${lesson.id}" has a tone Exercise on "$syllable", but '
              'there is no Tone Recording of "$syllable" tone ${tone.number}. '
              'Add it '
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

/// Owns permanent IDs (ADR-0001). A Word ID, once assigned, always means
/// the same Word and is never given to another one, even after the Word is
/// removed. A Lesson ID, once built, may not silently disappear (a renamed
/// Lesson would drop Learners' passes): removing one means listing it under
/// `retiredLessons`, and a retired Lesson ID is never used again.
final class _IdRegistry {
  _IdRegistry(this._file, this._wordIds, this._lessons, this._retiredLessons);

  final File _file;
  final Map<String, int> _wordIds;

  /// Every Lesson ID ever built, in first-built order.
  final List<String> _lessons;
  final Set<String> _retiredLessons;

  static _IdRegistry load(File file) {
    final words = <String, int>{};
    final lessons = <String>[];
    final retired = <String>{};
    if (file.existsSync()) {
      final root = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      (root['words'] as Map).forEach((k, v) => words[k as String] = v as int);
      lessons.addAll((root['lessons'] as List? ?? const []).cast<String>());
      retired.addAll(
        (root['retiredLessons'] as List? ?? const []).cast<String>(),
      );
    }
    return _IdRegistry(file, words, lessons, retired);
  }

  int idFor(_SourceWord word) => _wordIds.putIfAbsent(
    word.registryKey,
    () => _wordIds.values.fold(0, (max, id) => id > max ? id : max) + 1,
  );

  /// Checks the source's Lesson IDs against every earlier build, then
  /// records new ones (saved only by [save], after a successful build).
  void checkLessons(Iterable<String> lessonIds) {
    final current = lessonIds.toSet();
    for (final id in current) {
      if (_retiredLessons.contains(id)) {
        throw ContentBuildException(
          'Lesson "$id" was retired and its ID cannot be used again: '
          'Learners\' old passes would count for it. Give it a new id.',
        );
      }
    }
    for (final id in _lessons) {
      if (!current.contains(id) && !_retiredLessons.contains(id)) {
        throw ContentBuildException(
          'Lesson "$id" was in an earlier build but is missing now, so '
          'Learners who passed it would lose that pass. Restore it, or '
          'retire it on purpose by adding it to "retiredLessons" in '
          '${_file.path}.',
        );
      }
    }
    for (final id in current) {
      if (!_lessons.contains(id)) _lessons.add(id);
    }
  }

  void save() {
    const encoder = JsonEncoder.withIndent('  ');
    _file.writeAsStringSync(
      '${encoder.convert({'words': _wordIds, 'lessons': _lessons, 'retiredLessons': _retiredLessons.toList()})}\n',
    );
  }
}
