/// A Word: the unit of knowledge a Learner studies, with a permanent ID.
final class Word {
  const Word({
    required this.id,
    required this.characters,
    required this.pinyin,
    required this.meaning,
  });

  /// Permanent Word ID; never reused or renumbered (ADR-0001).
  final int id;
  final String characters;
  final String pinyin;
  final String meaning;
}

/// A single question a Learner answers inside a Lesson or Review.
sealed class Exercise {
  const Exercise();

  /// The choices offered to the Learner, in display order.
  List<String> get choices;

  /// The choice that is correct.
  String get answer;

  /// The Word this Exercise studies, if any; Words met in a Passed Lesson
  /// enter Review.
  Word? get word;
}

/// An Exercise about one Word that asks for its English meaning.
sealed class MeaningExercise extends Exercise {
  const MeaningExercise({required this.word, required this.choices});

  @override
  final Word word;

  @override
  final List<String> choices;

  @override
  String get answer => word.meaning;
}

/// Shows a Word (characters + pinyin) and asks for its English meaning.
final class MultipleChoiceExercise extends MeaningExercise {
  const MultipleChoiceExercise({required super.word, required super.choices});
}

/// Plays a Word aloud (device speech engine; ADR-0002) and asks for its
/// English meaning. The Word itself is not shown until answered.
final class ListeningExercise extends MeaningExercise {
  const ListeningExercise({required super.word, required super.choices});
}

/// A Tone Recording: a recorded human pronunciation of one pinyin syllable
/// in one of the four tones (ADR-0002).
final class ToneRecording {
  const ToneRecording({
    required this.syllable,
    required this.tone,
    required this.file,
  });

  /// Plain pinyin without a tone mark, `v` standing for `ü` (e.g. `ma`).
  final String syllable;

  /// 1 to 4.
  final int tone;

  /// The bundled audio file's name.
  final String file;
}

/// An Exercise about the tone of one syllable. Its choices are tones,
/// written `'1'` to `'4'`. It studies no Word, so it never enters Review.
sealed class ToneExercise extends Exercise {
  const ToneExercise({
    required this.syllable,
    required this.tone,
    required this.recordings,
  });

  /// Plain pinyin without a tone mark (e.g. `ma`).
  final String syllable;

  /// The tone asked about, 1 to 4.
  final int tone;

  /// The syllable's Tone Recording in each of the four tones, by tone.
  final Map<int, ToneRecording> recordings;

  @override
  String get answer => '$tone';

  @override
  Word? get word => null;

  /// The syllable with its tone mark (e.g. `mǎ`).
  String get tonedSyllable => tonedPinyin(syllable, tone);

  /// The Tone Recording of the asked tone.
  ToneRecording get recording => recordingFor(answer);

  /// The Tone Recording for one of the [choices].
  ToneRecording recordingFor(String choice) {
    final recording = recordings[int.tryParse(choice)];
    if (recording == null) {
      throw ArgumentError.value(choice, 'choice', 'No Tone Recording');
    }
    return recording;
  }
}

/// Plays a syllable from its Tone Recording and asks which tone (1–4) it was.
final class ToneIdentificationExercise extends ToneExercise {
  const ToneIdentificationExercise({
    required super.syllable,
    required super.tone,
    required super.recordings,
  });

  @override
  List<String> get choices => const ['1', '2', '3', '4'];
}

/// Shows a toned syllable (e.g. `mǎ`) and asks which of four Tone
/// Recordings matches it. [choices] are tones in the order the sounds are
/// offered, shuffled so the position does not give the tone away.
final class ToneMatchingExercise extends ToneExercise {
  const ToneMatchingExercise({
    required super.syllable,
    required super.tone,
    required super.recordings,
    required this.choices,
  });

  @override
  final List<String> choices;
}

const _toneMarks = {
  'a': 'āáǎà',
  'e': 'ēéěè',
  'i': 'īíǐì',
  'o': 'ōóǒò',
  'u': 'ūúǔù',
  'ü': 'ǖǘǚǜ',
};

/// Writes [syllable] (plain pinyin, `v` for `ü`) with the mark for [tone]
/// (1–4): on `a` or `e` if present, on the `o` of `ou`, otherwise on the
/// last vowel.
String tonedPinyin(String syllable, int tone) {
  if (tone < 1 || tone > 4) {
    throw ArgumentError.value(tone, 'tone', 'Must be 1 to 4');
  }
  final plain = syllable.toLowerCase().replaceAll('v', 'ü');
  var at = plain.indexOf('a');
  if (at < 0) at = plain.indexOf('e');
  if (at < 0) at = plain.indexOf('ou');
  if (at < 0) {
    for (var i = 0; i < plain.length; i++) {
      if (_toneMarks.containsKey(plain[i])) at = i;
    }
  }
  if (at < 0) {
    throw ArgumentError.value(syllable, 'syllable', 'Has no vowel');
  }
  final marked = _toneMarks[plain[at]]![tone - 1];
  return plain.replaceRange(at, at + 1, marked);
}

/// A Lesson as listed on the Lesson path.
final class LessonSummary {
  const LessonSummary({required this.id, required this.title});

  final String id;
  final String title;
}

/// A Lesson with its ordered Exercises.
final class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.exercises,
  });

  final String id;
  final String title;
  final List<Exercise> exercises;
}

/// The credit and license notice for one third-party source used in the
/// Course Content.
final class Acknowledgement {
  const Acknowledgement({
    required this.name,
    required this.author,
    required this.license,
    required this.url,
  });

  final String name;
  final String author;
  final String license;
  final String url;
}

/// Reads the read-only Course Content.
abstract interface class CourseContentReader {
  /// Every Lesson in path order.
  Future<List<LessonSummary>> lessonPath();

  /// The Lesson with [lessonId], including its Exercises.
  Future<Lesson> lesson(String lessonId);

  /// One Exercise to review each of [wordIds] with: the first Exercise on the
  /// Lesson path that studies that Word. IDs no longer in the Course Content
  /// (retired Words) are left out.
  Future<Map<int, Exercise>> reviewExercises(Set<int> wordIds);

  /// Every third-party source used in the Course Content, with its license.
  Future<List<Acknowledgement>> acknowledgements();
}
