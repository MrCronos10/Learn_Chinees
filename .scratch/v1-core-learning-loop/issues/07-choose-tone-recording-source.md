# 07: Choose a Tone Recording source

**What to build:** A decision, by the developer, on where Tone Recordings come from: an existing openly licensed set of Mandarin syllables in all four tones, or self-made recordings. The license must allow use in a free app, and its Acknowledgement details (name, author, license, link) must be recorded so the content builder can include them.

**Blocked by:** None (can start immediately)

**Status:** ready-for-human

- [ ] Source chosen (licensed set or own recordings)
- [ ] License verified as compatible with a free app and with sharing the Course Content under CC BY-SA
- [ ] Acknowledgement details written down
- [ ] Recordings available for at least the syllables Unit 1 needs (four tones each)

## Comments

2026-11-11: The developer chose to wait for Tone Perfect (Michigan State University Libraries, https://tone.lib.msu.edu): 410 syllables × 4 tones × 6 native speakers. Its license is unconfirmed: the site shows only "© Michigan State University", and the dataset is released on request via https://tone.lib.msu.edu/cite. The developer is requesting the dataset and written license terms.

What would make it usable: written permission under CC BY 4.0 or CC BY-SA 4.0 (or explicit permission to bundle the files in a free app whose Course Content is shared under CC BY-SA), plus the exact attribution text. A non-commercial (NC) or no-derivatives (ND) license would not fit.

Other sources checked and rejected: hugolpz/audio-cmn (unclear, possibly non-commercial license), davinfifield/mp3-chinese-pinyin-sound (unknown origin), Lingua Libre / Wikimedia Commons (CC BY-SA 4.0 but whole words, not syllables; only good for gaps), text-to-speech (ruled out by ADR-0002). Fallback if MSU declines or doesn't answer: record the syllables (own voice or a native speaker with a signed CC BY-SA 4.0 release).

2026-11-11: Prepared `tone-recordings-plan.md` (12 syllables × 4 tones = 48 recordings for the draft Unit 1 Word list, the recordings list format, the Tone Perfect steps and the own-recordings script/checklist) so this ticket can close as soon as the source is settled.
