import 'dart:io';

import 'package:study_engine/study_engine.dart';

import 'builder.dart' show ContentBuildException;

// Reads CC-CEDICT (https://cc-cedict.org/wiki/), the CC BY-SA 4.0
// Chinese-English dictionary that Words may take their pinyin and meaning
// from. Internal to the content builder.

/// One CC-CEDICT entry: `Traditional Simplified [pin1 yin1] /def/def/`.
final class CedictEntry {
  CedictEntry(
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
final class Cedict {
  Cedict(this.header, this._entries);

  /// The comment lines at the top of the file, including its license.
  final List<String> header;
  final Map<String, List<CedictEntry>> _entries;

  static final _line = RegExp(r'^(\S+) (\S+) \[([^\]]*)\] /(.*)/\s*$');

  static Cedict load(File file) {
    final entries = <String, List<CedictEntry>>{};
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
      final entry = CedictEntry(
        line,
        match[1]!,
        match[2]!,
        match[3]!,
        match[4]!.split('/'),
      );
      entries.putIfAbsent(entry.simplified, () => []).add(entry);
    }
    return Cedict(header, entries);
  }

  /// The entry for [characters]. [pinyin] picks a reading when there are
  /// several; "variant of" entries are skipped, and among entries of the same
  /// reading the one written the same in traditional characters is preferred
  /// (so 你 means 你, not its variant 妳).
  CedictEntry entryFor(String characters, String? pinyin) {
    final all = _entries[characters] ?? const <CedictEntry>[];
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
