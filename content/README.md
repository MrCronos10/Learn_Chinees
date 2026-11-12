# Course Content sources

Licensed CC BY-SA 4.0 (see `LICENSE.md`), because it is built from CC-CEDICT.

The app ships one read-only Course Content database, `app/assets/content/course.db`, built from these files. Rebuild it after any change here and commit the result.

| File | What it is |
|---|---|
| `ids.json` | ID registry of Words and Lessons (ADR-0001, including its Lesson ID addition). The builder adds new IDs; never edit or remove existing ones. To remove a Lesson on purpose, add its id to `retiredLessons`. A retired id can never be used again. |
| `unit-1/source.json` | Unit 1: Lessons, Exercises, Words and Acknowledgements. A Word with `"source": "cc-cedict"` takes its pinyin and first meaning from CC-CEDICT unless it gives its own; `cedictPinyin` (e.g. `"ma5"`) picks a reading when there are several. |
| `unit-1/cedict_extract.u8` | The CC-CEDICT entries Unit 1 uses, unchanged, with CC-CEDICT's license header (CC BY-SA 4.0). |
| `unit-1/tone_recordings.json` | The Tone Recordings list: syllable, tone, file and source (an Acknowledgement id) of each recording. |
| `unit-1/tones/` | The Tone Recordings (see below). |

## Tone Recordings

Real human recordings (ADR-0002), from The Shtooka Project via Wikimedia Commons, converted from Ogg Vorbis to AAC (`.m4a`, mono, 96 kbps) with ffmpeg so iOS can play them. Nothing else was changed. Each syllable has all four tones in one voice, so a Learner can't tell the tones apart by voice.

| Files | Speaker | License | Originals on Wikimedia Commons |
|---|---|---|---|
| `ji1`–`ji4` | Wei Gao (male, Beijing), recorded by Vion Nicolas | CC BY 2.0 FR | `File:Zh-jī.ogg`, `Zh-jí.ogg`, `Zh-jǐ.ogg`, `Zh-jì.ogg` |
| `chan1`–`chan4` | Yue Tan (female, Liaoning) | CC BY-SA 3.0; `chan3` CC BY-SA 3.0 US | `File:Zh-chān.ogg`, `Zh-chán.ogg`, `Zh-chǎn.oga`, `Zh-chàn.ogg` |

Both licenses allow sharing them inside CC BY-SA 4.0 Course Content with credit; the credits are the `shtooka-wei-gao` and `shtooka-yue-tan` Acknowledgements in `unit-1/source.json`. Only these two syllables had all four tones in one voice on Commons (checked 2026-11-12). To add syllables, or to switch to Tone Perfect or own recordings later, replace the files and the list and rebuild; no code changes are needed.

## Build

```sh
dart run packages/course_content/bin/build_content.dart \
  content/unit-1/source.json content/ids.json app/assets/content/course.db \
  --cedict content/unit-1/cedict_extract.u8 \
  --tone-recordings content/unit-1/tone_recordings.json
```

The build copies the Tone Recordings into `app/assets/content/tones/`, renamed `<syllable><tone>.<ext>`.

## Regenerate the CC-CEDICT extract

After adding or changing a CC-CEDICT Word, download the full file from <https://www.mdbg.net/chinese/dictionary?page=cc-cedict> (`cedict_1_0_ts_utf-8_mdbg.txt.gz`), unpack it outside the repo, then:

```sh
dart run packages/course_content/bin/extract_cedict.dart \
  content/unit-1/source.json <path/to/cedict_ts.u8> content/unit-1/cedict_extract.u8
```

Only the extract is committed, never the full dictionary.
