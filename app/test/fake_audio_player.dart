import 'package:my_chinese_app/audio/audio_player.dart';
import 'package:study_engine/study_engine.dart';

/// Records what it was asked to play instead of making sound.
class FakeAudioPlayer implements AudioPlayer {
  FakeAudioPlayer({this.hasChineseVoice = true});

  final bool hasChineseVoice;
  final List<String> spokenWords = [];

  @override
  Future<bool> speakWord(Word word) async {
    if (!hasChineseVoice) return false;
    spokenWords.add(word.characters);
    return true;
  }
}
