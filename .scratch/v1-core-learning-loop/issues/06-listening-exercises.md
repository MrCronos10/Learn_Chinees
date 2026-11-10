# 06: Listening Exercises

**What to build:** The Learner gets listening Exercises: they hear a Word spoken and pick its English meaning, and can replay the audio before answering. Audio goes through a small audio player interface; whole Words use the device's speech engine. Tests use a fake player.

**Blocked by:** 01

**Status:** done

- [x] Listening Exercise plays the Word and offers English meanings to choose from
- [x] Replay button plays the Word again
- [x] Audio player interface with a device speech-engine source for whole Words
- [x] Fake player in tests records what was asked to play
- [x] Content builder can define listening Exercises for a Lesson
- [x] If no Chinese voice is available on the device, the Learner sees a clear message instead of silence

## Comments

Done. `ListeningExercise` in the engine (studies a Word, so it enters Review like any other); content source kind `"listening"`. App: `AudioPlayer` interface (`app/lib/audio/`) with `DeviceAudioPlayer` (flutter_tts, zh-CN, slightly slow) for whole Words; tests use `FakeAudioPlayer`, which records what it was asked to speak. The Word plays when the Exercise appears (again when a missed one repeats), "Play again" replays it, and the characters stay hidden. Without a Chinese voice the Exercise says so and shows the pinyin so it can still be answered. Ticket 08 adds the Tone Recording source to the same interface (ADR-0002).
