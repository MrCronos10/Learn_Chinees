# Course Content sources

The app ships one read-only Course Content database, `app/assets/content/course.db`, built from these files. Rebuild it after any change here and commit the result.

| File | What it is |
|---|---|
| `ids.json` | ID registry of Words and Lessons (ADR-0001). The builder adds new IDs; never edit or remove existing ones. To remove a Lesson on purpose, add its id to `retiredLessons`. A retired id can never be used again. |
| `unit-1/source.json` | Unit 1: Lessons, Exercises, Words and Acknowledgements. A Word with `"source": "cc-cedict"` takes its pinyin and first meaning from CC-CEDICT unless it gives its own; `cedictPinyin` (e.g. `"ma5"`) picks a reading when there are several. |
| `unit-1/cedict_extract.u8` | The CC-CEDICT entries Unit 1 uses, unchanged, with CC-CEDICT's license header (CC BY-SA 4.0). |

## Build

```sh
dart run packages/course_content/bin/build_content.dart \
  content/unit-1/source.json content/ids.json app/assets/content/course.db \
  --cedict content/unit-1/cedict_extract.u8
```

Add `--tone-recordings content/unit-1/tone_recordings.json` once Tone Recordings exist (ticket 07; format in `.scratch/v1-core-learning-loop/tone-recordings-plan.md`). The build copies them into `app/assets/content/tones/`.

## Regenerate the CC-CEDICT extract

After adding or changing a CC-CEDICT Word, download the full file from <https://www.mdbg.net/chinese/dictionary?page=cc-cedict> (`cedict_1_0_ts_utf-8_mdbg.txt.gz`), unpack it outside the repo, then:

```sh
dart run packages/course_content/bin/extract_cedict.dart \
  content/unit-1/source.json <path/to/cedict_ts.u8> content/unit-1/cedict_extract.u8
```

Only the extract is committed, never the full dictionary.
