# Tone Recordings plan (ticket 07, used by tickets 08 and 10)

Everything needed to close ticket 07 quickly, whichever source is used: Tone Perfect (if MSU confirms a compatible license in writing) or the developer's own recordings (fallback).

## 1. Syllables needed for Unit 1

12 syllables × 4 tones = **48 recordings**. They come from the draft Word list in `unit-1-word-list.md`; if that list changes, update this table.

| Syllable | Tone 1 | Tone 2 | Tone 3 | Tone 4 | From |
|---|---|---|---|---|---|
| ma | mā | má | mǎ | mà | tone intro (Lesson 1) |
| ni | nī | ní | nǐ | nì | 你 |
| hao | hāo | háo | hǎo | hào | 好 |
| wo | wō | wó | wǒ | wò | 我 |
| xie | xiē | xié | xiě | xiè | 谢谢 |
| zai | zāi | zái | zǎi | zài | 再见 |
| jian | jiān | jián | jiǎn | jiàn | 再见 |
| shi | shī | shí | shǐ | shì | 是, 老师 |
| bu | bū | bú | bǔ | bù | 不 |
| ta | tā | tá | tǎ | tà | 他, 她 |
| jiao | jiāo | jiáo | jiǎo | jiào | 叫 |
| ming | mīng | míng | mǐng | mìng | 名字 |

All four tones are needed for every syllable, even where one tone is rare in real words (wó, zái, mīng): "see a toned syllable, pick the matching sound" plays the other tones as wrong choices. Neutral-tone syllables (xie in 谢谢, ma in 吗, zi in 名字) get no tone Exercise.

## 2. Tone Recordings list (manifest) format

Proposed file: `content/unit-1/tone_recordings.json`, read by the content builder (ticket 08). Audio files live next to it in `content/unit-1/tones/` and are bundled with the app.

```json
{
  "recordings": [
    { "syllable": "ma", "tone": 1, "file": "tones/ma1.mp3", "source": "tone-perfect" },
    { "syllable": "ma", "tone": 2, "file": "tones/ma2.mp3", "source": "tone-perfect" }
  ]
}
```

- `syllable`: plain pinyin, lowercase, no tone mark (ü written as `v`, e.g. `lv`).
- `tone`: 1–4.
- `file`: path relative to the list; the build fails if it is missing.
- `source`: an `id` in the `acknowledgements` list of the content source; the build fails if it has none. Every recording names its source, so a mix of sets (e.g. Tone Perfect plus a few own recordings) stays credited.
- The build fails if a tone Exercise asks for a syllable or tone with no recording (spec story 52), or if a syllable/tone appears twice.

Acknowledgement entries (fill in once the source is settled):

```json
{ "id": "tone-perfect", "name": "Tone Perfect", "author": "Michigan State University Libraries", "license": "<from MSU's written reply>", "url": "https://tone.lib.msu.edu" }
{ "id": "own-recordings", "name": "Tone Recordings", "author": "<speaker's name>", "license": "CC BY-SA 4.0", "url": "https://github.com/MrCronos10/Learn_Chinees" }
```

## 3a. If Tone Perfect: steps when the dataset arrives

1. Save MSU's written license reply (email/PDF) in `content/licenses/tone-perfect.*`, and check it allows: bundling in a free iOS/Android app, light edits (trim, convert, level), and redistribution alongside CC BY-SA Course Content. NC or ND terms are not compatible.
2. Pick **one speaker** for every syllable so the voice stays consistent (the dataset has 3 female and 3 male voices; file names carry a speaker code).
3. Copy the 48 files for that speaker into `content/unit-1/tones/`, renamed `<syllable><tone>.mp3`.
4. Listen to each once to check the tone is right and the clip is clean.
5. Write `tone_recordings.json` with `"source": "tone-perfect"`, and the Acknowledgement with MSU's exact attribution text.

## 3b. If own recordings: script and checklist

**Speaker:** one native (or near-native) Mandarin speaker for all 48 clips. If it is not the developer, get a one-line signed release: "I release these recordings under CC BY-SA 4.0 and agree to being credited as <name>."

**Setup:** quiet room with soft furnishings, phone or USB mic about 20 cm away, mono, 44.1 kHz WAV, same position and volume for every take.

**Script:** read each row left to right, one clean take per syllable, about 1 second of silence between takes. Say each as an isolated syllable, carefully, not as part of a word.

```
mā  má  mǎ  mà
nī  ní  nǐ  nì
hāo háo hǎo hào
wō  wó  wǒ  wò
xiē xié xiě xiè
zāi zái zǎi zài
jiān jián jiǎn jiàn
shī shí shǐ shì
bū  bú  bǔ  bù
tā  tá  tǎ  tà
jiāo jiáo jiǎo jiào
mīng míng mǐng mìng
```

**Editing checklist (per clip):**
- [ ] Cut into one file per syllable and tone, named `<syllable><tone>.mp3` (`ma1.mp3` … `ming4.mp3`).
- [ ] Trim silence to about 0.1 s before and after.
- [ ] Even out the volume across all clips (normalize to the same loudness, e.g. −16 LUFS).
- [ ] Export as mono MP3, 128 kbps.
- [ ] Listen to every clip once: right tone, no clipping, no background noise.
- [ ] Ideally a second native speaker checks the tones.
- [ ] Write `tone_recordings.json` with `"source": "own-recordings"` and the Acknowledgement above.

## 4. Closing ticket 07

Tick its boxes when: the source is chosen, its license is confirmed in writing (or the recordings are your own), the Acknowledgement details above are filled in, and all 48 files from section 1 exist.

## Update 2026-11-12: source settled (ticket 07)

The 12-syllable plan above is on hold. Ticket 07 closed with The Shtooka Project recordings from Wikimedia Commons, which cover only **ji** and **chan** in one voice each (8 recordings, in `content/unit-1/tones/`, listed in `content/unit-1/tone_recordings.json`). Unit 1's tone Exercises use those two syllables. Sections 3a and 3b still apply if Tone Perfect or own recordings are added later to cover more syllables.
