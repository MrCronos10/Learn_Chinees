# 10: Unit 1 "Greetings & introductions" content

**What to build:** The real first Unit replaces the fixture content: 4 Lessons of about 5 Words each (e.g. 你好, 谢谢, 再见, 我, 你, 是, 叫, 名字), built by the content builder from a hand-written Lesson definition plus CC-CEDICT and Tatoeba data. Lesson 1 opens with the four tones; all three Exercise kinds appear across the Unit. The app is playable from the first Lesson to the last.

**Blocked by:** 08, 09

**Status:** ready-for-agent

- [x] Word list drafted and reviewed and approved by the developer before building
- [ ] Unit 1 has 4 Lessons along a fixed path; Lesson 1 starts with the four tones
- [ ] Multiple-choice, listening and tone Exercises all appear in the Unit
- [ ] CC-CEDICT, Tatoeba and Tone Recording sources each have an Acknowledgement
- [x] Fixture content no longer ships
- [ ] Manual play-through on the iOS simulator: all 4 Lessons can be passed, Words appear in Review the next Day

## Comments

2026-11-11: Draft Word list in `unit-1-word-list.md` (19 Words, 4 Lessons), waiting for the developer's approval.

2026-11-11: The developer approved the Word list as drafted (Words, Lesson titles, and 他/她 together in Lesson 3).

2026-11-12: Audio-free part built ahead of 08/07 (developer's request).
- Unit 1 in `content/unit-1/source.json`: the approved 19 Words and 4 Lessons, with multiple-choice and listening Exercises in every Lesson. Tone Exercises (Lesson 1's opening and the tone drills) are added once ticket 07 supplies Tone Recordings.
- CC-CEDICT: Words marked `"source": "cc-cedict"` take pinyin (converted to tone marks) and meaning from it; the approved short meanings and three approved spellings (nǐ hǎo, bú kèqi, méi guānxi) are kept as overrides. Only a 19-entry extract with the license header is committed (`cedict_extract.u8`); it builds the same content as the full file. Acknowledgement: CC-CEDICT, MDBG and contributors, CC BY-SA 4.0.
- Tatoeba: left out by the developer's decision (2026-11-12): v1 has no Exercise that shows a sentence, so the app does not credit a source it never uses. It comes back with a future sentence Exercise.
- Lesson ID registry: `content/ids.json` (moved from the fixture's `word_ids.json`, so Word IDs 1–5 carry over). A Lesson that was built before cannot silently disappear; removing one means listing it under `retiredLessons`, and a retired id is never used again. The fixture Lessons are retired.
- Builder CLI now takes named options: `--cedict`, `--tone-recordings`. See `content/README.md`.
- Checked on the iOS simulator: the Lesson path shows the 4 Unit 1 Lessons in order; existing Learner Progress (XP, Streak) survived the content replacement.
Still open: tone Exercises (07/08), the Acknowledgement for Tone Recordings, and the full play-through of all 4 Lessons with Review the next Day.

2026-11-12, after code review: a Word citing CC-CEDICT is always checked against it (even when it gives its own pinyin and meaning), and a build given a CC-CEDICT file must have its Acknowledgement. The Course Content is marked CC BY-SA 4.0 in `content/LICENSE.md`, as the spec's licensing rule requires. ADR-0001 now records that Lesson IDs are permanent too. CC-CEDICT reading moved to `packages/course_content/lib/src/cedict.dart`.
Fixed 2026-11-12: wrong meanings now rotate through the Lesson's meanings (the ones following the Word, wrapping round), so every meaning is also a wrong choice in other Exercises and none can be spotted by elimination (e.g. "teacher" now appears in four questions, not one).

