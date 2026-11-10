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

  /// How [choice] is shown to the Learner.
  String labelFor(String choice) => choice;

  /// The correct answer as the Learner reads it in feedback.
  String get answerLabel => labelFor(answer);
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

/// One of the four Mandarin tones.
enum Tone {
  first(1, '1st tone'),
  second(2, '2nd tone'),
  third(3, '3rd tone'),
  fourth(4, '4th tone');

  const Tone(this.number, this.label);

  /// 1 to 4.
  final int number;

  /// Its name for the Learner, such as "3rd tone".
  final String label;

  /// How it is written as an Exercise choice: its number.
  String get choice => '$number';

  /// The tone numbered [number], or null if it is not 1 to 4.
  static Tone? fromNumber(int number) =>
      Tone.values.where((t) => t.number == number).firstOrNull;

  /// The tone written as [choice], or null.
  static Tone? fromChoice(String choice) =>
      Tone.values.where((t) => t.choice == choice).firstOrNull;
}

/// Whether [syllable] is plain pinyin: lowercase letters with at least one
/// vowel, no tone mark, `v` standing for `ü` (e.g. `ma`, `lv`).
bool isPlainPinyin(String syllable) =>
    RegExp(r'^[a-z]*[aeiouv][a-z]*$').hasMatch(syllable);

/// A Tone Recording: a recorded human pronunciation of one pinyin syllable
/// in one of the four tones (ADR-0002).
final class ToneRecording {
  const ToneRecording({
    required this.syllable,
    required this.tone,
    required this.file,
  });

  /// Plain pinyin (see [isPlainPinyin]), e.g. `ma`.
  final String syllable;
  final Tone tone;

  /// The bundled audio file's name.
  final String file;
}

/// An Exercise about the tone of one syllable. Its choices are tones,
/// written as [Tone.choice]. It studies no Word, so it never enters Review.
sealed class ToneExercise extends Exercise {
  const ToneExercise({
    required this.syllable,
    required this.tone,
    required this.recordings,
  });

  /// Plain pinyin (see [isPlainPinyin]), e.g. `ma`.
  final String syllable;

  /// The tone asked about.
  final Tone tone;

  /// The syllable's Tone Recording in each of the four tones.
  final Map<Tone, ToneRecording> recordings;

  @override
  String get answer => tone.choice;

  @override
  Word? get word => null;

  /// The syllable with its tone mark (e.g. `mǎ`).
  String get tonedSyllable => tonedPinyin(syllable, tone);

  /// The Tone Recording of the asked tone.
  ToneRecording get recording => recordingFor(answer);

  /// The Tone Recording for one of the [choices].
  ToneRecording recordingFor(String choice) {
    final recording = recordings[Tone.fromChoice(choice)];
    if (recording == null) {
      throw ArgumentError.value(choice, 'choice', 'No Tone Recording');
    }
    return recording;
  }
}

/// Plays a syllable from its Tone Recording and asks which tone it was.
final class ToneIdentificationExercise extends ToneExercise {
  const ToneIdentificationExercise({
    required super.syllable,
    required super.tone,
    required super.recordings,
  });

  @override
  List<String> get choices => [for (final t in Tone.values) t.choice];

  @override
  String labelFor(String choice) => Tone.fromChoice(choice)?.label ?? choice;

  @override
  String get answerLabel => '$tonedSyllable (${tone.label})';
}

/// Shows a toned syllable (e.g. `mǎ`) and asks which of four Tone
/// Recordings matches it. [choices] are tones in the order the sounds are
/// offered, shuffled so the position does not give the tone away; the
/// Learner sees them as Sound A to D.
final class ToneMatchingExercise extends ToneExercise {
  const ToneMatchingExercise({
    required super.syllable,
    required super.tone,
    required super.recordings,
    required this.choices,
  });

  @override
  final List<String> choices;

  static const _letters = 'ABCD';

  @override
  String labelFor(String choice) {
    final i = choices.indexOf(choice);
    return i < 0 || i >= _letters.length ? choice : 'Sound ${_letters[i]}';
  }

  @override
  String get answerLabel => '${labelFor(answer)} ($tonedSyllable)';
}

const _toneMarks = {
  'a': 'āáǎà',
  'e': 'ēéěè',
  'i': 'īíǐì',
  'o': 'ōóǒò',
  'u': 'ūúǔù',
  'ü': 'ǖǘǚǜ',
};

/// Writes plain-pinyin [syllable] with the mark for [tone]: on `a` or `e`
/// if present, on the `o` of `ou`, otherwise on the last vowel.
String tonedPinyin(String syllable, Tone tone) {
  if (!isPlainPinyin(syllable)) {
    throw ArgumentError.value(syllable, 'syllable', 'Not plain pinyin');
  }
  final plain = syllable.replaceAll('v', 'ü');
  var at = plain.indexOf('a');
  if (at < 0) at = plain.indexOf('e');
  if (at < 0) at = plain.indexOf('ou');
  if (at < 0) {
    for (var i = 0; i < plain.length; i++) {
      if (_toneMarks.containsKey(plain[i])) at = i;
    }
  }
  final marked = _toneMarks[plain[at]]![tone.number - 1];
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
