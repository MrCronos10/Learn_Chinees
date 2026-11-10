import 'package:flutter_tts/flutter_tts.dart';
import 'package:study_engine/study_engine.dart';

import 'audio_player.dart';

/// Speaks whole Words with the device's speech engine in Mandarin.
class DeviceAudioPlayer implements AudioPlayer {
  final FlutterTts _tts = FlutterTts();
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
    await _tts.stop();
    await _tts.speak(word.characters);
    return true;
  }
}
