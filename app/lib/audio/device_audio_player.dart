import 'package:audioplayers/audioplayers.dart' as audioplayers;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:study_engine/study_engine.dart';

import 'audio_player.dart';

/// Speaks whole Words with the device's speech engine in Mandarin, and plays
/// Tone Recordings bundled in the app's assets.
class DeviceAudioPlayer implements AudioPlayer {
  final FlutterTts _tts = FlutterTts();
  final audioplayers.AudioPlayer _recordingPlayer = audioplayers.AudioPlayer();

  /// Where the content builder puts Tone Recordings, under `assets/`.
  static const _toneRecordings = 'content/tones';
  Future<bool>? _ready;

  static const _language = 'zh-CN';

  Future<bool> _setUp() async {
    final available = await _tts.isLanguageAvailable(_language);
    if (available != true) return false;
    await _tts.setLanguage(_language);
    // A little slower than normal speech, for beginners.
    await _tts.setSpeechRate(0.4);
    await _tts.awaitSpeakCompletion(true);
    return true;
  }

  @override
  Future<bool> speakWord(Word word) async {
    if (!await (_ready ??= _setUp())) return false;
    await _recordingPlayer.stop();
    await _tts.stop();
    await _tts.speak(word.characters);
    return true;
  }

  @override
  Future<void> playToneRecording(ToneRecording recording) async {
    await _tts.stop();
    await _recordingPlayer.stop();
    await _recordingPlayer.play(
      audioplayers.AssetSource('$_toneRecordings/${recording.file}'),
    );
  }
}
