# 08: Tone Exercises

**What to build:** The Learner gets tone Exercises in both directions: hear a syllable and pick its tone (1-4), and see a toned pinyin syllable and pick the matching sound. Tone audio always comes from Tone Recordings, never the speech engine (ADR-0002).

**Blocked by:** 06, 07

**Status:** ready-for-agent (built; one step left, blocked by 07: hear a real Tone Recording on the iOS simulator, then tick the last box and set done)

- [x] Hear-a-syllable, pick-the-tone Exercise works
- [x] See-a-toned-syllable, pick-the-sound Exercise works
- [ ] Tone audio is played from bundled Tone Recordings via the audio player's recording source
- [x] Content build fails with a clear message if any tone Exercise has no Tone Recording
- [x] Tests cover both directions with the fake player and the failing build

## Comments

2026-11-11: Built ahead of ticket 07, at the developer's request, with placeholder audio in tests. Everything is done except checking real playback: the last box stays open until ticket 07 supplies licensed Tone Recordings and a tone Exercise is heard on the iOS simulator.

As built:
- Engine: `ToneRecording`; sealed `ToneExercise` with `ToneIdentificationExercise` (hear, pick 1–4) and `ToneMatchingExercise` (see `mǎ`, pick among four sounds). Choices are tones `'1'`–`'4'`; they study no Word, so they never enter Review. `tonedPinyin(syllable, tone)` places the tone mark (a/e first, o in ou, else last vowel; v = ü).
- Source: `{"kind": "toneIdentification" | "toneMatching", "syllable": "ma", "tone": 3}`. Every tone Exercise needs its syllable in all four tones, since the other three are the wrong choices.
- Builder: `build_content <source.json> <ids.json> <out.db> [--tone-recordings tone_recordings.json]` (CLI changed to named options in ticket 10), list format as in `tone-recordings-plan.md`. Fails clearly on a missing recording, missing file, unacknowledged source, duplicate, tone outside 1–4 or a syllable that is not plain pinyin. Copies recordings into `tones/` next to the database as `<syllable><tone>.<ext>`; the folder is builder-owned. Matching choices are shuffled per Exercise, deterministically.
- Schema: `exercises.word_id` is nullable, with new `syllable` and `tone` columns, plus a `tone_recordings` table. Course Content is replaced wholesale, so no migration is needed.
- App: `AudioPlayer.playToneRecording` (device player uses `audioplayers` on bundled assets in `assets/content/tones/`); tone audio never goes through the speech engine. The fixture content has no tone Exercises until real recordings exist.

2026-11-11, after code review: a `Tone` enum replaces bare 1–4 ints; Exercises give their own choice and answer labels (`labelFor`, `answerLabel`), so a wrong matching answer names the right sound ("Sound B (má)"). Syllables in the source and the Tone Recordings list must be plain pinyin (lowercase letters with a vowel, no tone mark, v for ü), which also stops a bad entry naming a file outside `tones/`. The build now copies recordings into a staging folder first, so a failed copy leaves the previous database and recordings in place.

