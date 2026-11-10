import 'package:study_engine/study_engine.dart';

/// Plays study audio from two sources: whole Words come from the device
/// speech engine; tone Exercises use bundled Tone Recordings only, never the
/// speech engine (ADR-0002).
abstract interface class AudioPlayer {
  /// Speaks a whole Word. Returns false, without sound, when the device has
  /// no Chinese voice.
  Future<bool> speakWord(Word word);

  /// Plays a bundled Tone Recording.
  Future<void> playToneRecording(ToneRecording recording);
}
