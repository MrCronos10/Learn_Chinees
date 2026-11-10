# Spec: v1 core learning loop

Status: ready-for-agent

## Problem Statement

An adult absolute beginner who wants to speak everyday Mandarin has no easy, free way to start that teaches tones properly from day one, keeps them coming back daily, and makes sure the Words they learn actually stick. Existing apps in this category are commercial, push premium upsells, and require accounts. The Learner wants to open an app, start learning immediately with no sign-up, hear correct pronunciation, be told clearly whether they passed, and be reminded of Words right before they would forget them.

## Solution

A free Flutter app (iOS first, Android from the same codebase) that works fully offline with no account. The Learner follows a fixed path of Lessons in the first Unit, "Greetings & introductions". Each Lesson is a short set of Exercises of three kinds: multiple choice, listening, and tone. Tone Exercises use real Tone Recordings; whole Words use the device's speech engine. A Lesson is a Passed Lesson at 80% first-try correct; passing unlocks the next Lesson and sends its Words into Review. Review uses five Boxes (1/3/7/14/30 Days). The Learner earns XP for correct answers and builds a Streak by studying on consecutive Days. All teaching material is original or openly licensed and credited in an Acknowledgements screen.

## User Stories

### Getting started
1. As a Learner, I want to start learning the moment I open the app, so that I don't abandon it at a sign-up screen.
2. As a Learner, I want my Learner Progress saved on my device automatically, so that I can close the app and continue later.
3. As a Learner, I want to see the first Unit's Lesson path on the home screen, so that I know where I am and what comes next.
4. As a Learner, I want only the next available Lesson unlocked, so that I'm guided in a sensible order.
5. As a Learner, I want locked Lessons to look clearly locked, so that I understand why I can't open them yet.
6. As a Learner, I want Passed Lessons to look clearly finished, so that I can see my progress along the path.

### Taking a Lesson
7. As a Learner, I want to start any unlocked Lesson with one tap, so that studying is effortless.
8. As a Learner, I want to see how far through the Lesson I am, so that I know how much is left.
9. As a Learner, I want to see Chinese characters and pinyin together on every Word, so that I learn to read both from the start.
10. As a Learner, I want a setting to hide pinyin, so that I can test myself on characters once I'm ready.
11. As a Learner, I want immediate feedback on whether each answer was right, so that I learn from mistakes straight away.
12. As a Learner, I want to see the correct answer when I'm wrong, so that I don't keep the wrong idea.
13. As a Learner, I want Exercises I got wrong repeated at the end of the Lesson, so that I practise them again before finishing.
14. As a Learner, I want repeated Exercises not to change my pass mark, so that the result reflects my first try honestly.
15. As a Learner, I want to be able to quit a Lesson midway, so that I'm not trapped if I'm interrupted.
16. As a Learner, I want quitting a Lesson to leave my Learner Progress unchanged, so that a half-finished Lesson doesn't count as passed or failed.

### Exercise kinds
17. As a Learner, I want multiple-choice Exercises that ask me to match a Word to its meaning, so that I build vocabulary.
18. As a Learner, I want listening Exercises where I hear a Word and pick its English meaning, so that I learn to understand spoken Chinese.
19. As a Learner, I want to replay the audio of a listening Exercise, so that I can listen again before answering.
20. As a Learner, I want tone Exercises where I hear a syllable and pick its tone (1–4), so that I train my ear for tones.
21. As a Learner, I want tone Exercises where I see a toned syllable and pick the matching sound, so that I connect tone marks to sounds.
22. As a Learner, I want tone audio to be real human recordings, so that I'm never taught a wrong tone by a robotic voice.
23. As a Learner, I want whole Words spoken aloud, so that I hear how they sound in practice.

### Lesson results
24. As a Learner, I want a results screen at the end of each Lesson, so that I know how I did.
25. As a Learner, I want to be told clearly whether the Lesson is a Passed Lesson, so that I know whether I can move on.
26. As a Learner, I want to see my first-try percentage, so that I understand why I passed or didn't.
27. As a Learner, I want to see the XP I earned in this Lesson, so that I feel rewarded.
28. As a Learner, I want to earn XP for correct answers even when I don't pass, so that effort still counts.
29. As a Learner, I want to retry a failed Lesson immediately, so that I can try again while it's fresh.
30. As a Learner, I want the next Lesson unlocked as soon as I pass, so that I can keep going.
31. As a Learner, I want the Words from a Passed Lesson added to my Review, so that I don't forget them.

### Review
32. As a Learner, I want to see how many Words are due for Review today, so that I know whether I have Review to do.
33. As a Learner, I want to start a Review with one tap, so that daily Review is quick.
34. As a Learner, I want Review to contain only Words that are due today, so that my time isn't wasted.
35. As a Learner, I want a Word I answer correctly in Review to come back later than before, so that I spend time on what I don't know yet.
36. As a Learner, I want a Word I get wrong in Review to come back tomorrow, so that I relearn it quickly.
37. As a Learner, I want Words I know well to come back only every 30 Days, so that Review stays short as I progress.
38. As a Learner, I want Review to use the same Exercise kinds as Lessons, so that it feels familiar.
39. As a Learner, I want to see when nothing is due, so that I know I'm finished for today.
40. As a Learner, I want to earn XP in Review too, so that daily Review feels worthwhile.

### XP and Streak
41. As a Learner, I want to see my total XP, so that I can see how much I've done overall.
42. As a Learner, I want to see my current Streak, so that I'm motivated to come back every Day.
43. As a Learner, I want my Streak to grow when I complete a Lesson or Review on a new Day, so that daily study is rewarded.
44. As a Learner, I want completing several Lessons in one Day to count as that one Day, so that the Streak measures consistency, not volume.
45. As a Learner, I want my Streak to reset if I miss a Day, so that it means something.
46. As a Learner, I want Days to follow my own local time zone, so that midnight on my clock is when the Day changes.

### Settings and acknowledgements
47. As a Learner, I want a settings screen with the pinyin toggle, so that I can change how Words are shown.
48. As a Learner, I want an Acknowledgements screen listing every source and its license, so that the creators of the material are credited.

### Updates and content (developer as actor)
49. As a Learner, I want my Learner Progress kept when the app updates, so that I never lose my Streak, XP, or Review schedule.
50. As the developer, I want Course Content built by a repeatable script from source files, so that I can fix or extend Lessons and rebuild.
51. As the developer, I want every Word to keep the same permanent ID across content builds, so that Learner Progress still points to the right Words after an update.
52. As the developer, I want the build to fail if a tone Exercise has no Tone Recording, so that broken Lessons never ship.
53. As the developer, I want the build to fail if a source has no Acknowledgement, so that licensing is never forgotten.
54. As the developer, I want a Word removed from the content to have its ID retired rather than reused, so that old progress never attaches to a different Word.
55. As the developer, I want the scheduler to sit behind one interface, so that Boxes can later be replaced by a better spaced-repetition algorithm.

## Implementation Decisions

- **Platform:** Flutter, one codebase; iOS is the primary test target, Android is built from the same code. Offline-only; no backend, no accounts, no analytics, no payments.
- **Two stores (ADR-0001):** Course Content ships as a read-only SQLite database, replaced wholesale on each app update. Learner Progress lives in a separate SQLite database that is never replaced. Learner Progress refers to Words only by permanent Word ID.
- **Modules:**
  - **Study engine** (pure Dart, no Flutter dependency): the deep module holding all learning rules. It is the main test seam.
    - Lesson path: list Lessons with their state (locked / unlocked / passed); start a Lesson; answer an Exercise; finish a Lesson, returning the result (Passed Lesson or not, first-try percentage, XP earned, next Lesson unlocked).
    - Review: Words due on a given Day; start a Review; answer a Review Exercise.
    - Progress: total XP; current Streak.
    - Depends on three injected collaborators: a Course Content reader, a Learner Progress store, and a clock that supplies the current Day.
  - **Scheduler** behind its own small interface inside the engine: given a Word's Box and an answer, returns the new Box and the next due Day. v1 uses five Boxes (1, 3, 7, 14, 30 Days); correct moves up one Box (stays at the last), wrong goes back to the first.
  - **Course Content reader** and **Learner Progress store**: SQLite adapters, plus in-memory versions for tests.
  - **Content builder** (Dart command-line script, outside the app): reads the source files (hand-written Unit/Lesson definitions, a Word list, CC-CEDICT, Tatoeba sentences, a Tone Recordings manifest, a sources-and-licenses list), validates them, and writes the Course Content database. It owns the Word ID registry so that IDs are permanent and retired IDs are never reused.
  - **Audio player**: a small interface with two sources, Tone Recordings (bundled files) for tone Exercises and the device speech engine for whole Words (ADR-0002). A fake is used in tests.
  - **UI** (Flutter): thin screens that only call the study engine. Screens: Lesson path (home), Lesson, Lesson results, Review, Settings (pinyin toggle, Acknowledgements).
- **Rules (as settled in CONTEXT.md):**
  - Passed Lesson = at least 80% of Exercises correct on the first try; missed Exercises are repeated at the end but don't change the mark.
  - XP is earned per correct answer, in Lessons and Review, whether or not the Lesson is passed.
  - A Word enters Review (first Box, due next Day) only when its Lesson becomes a Passed Lesson.
  - Streak counts consecutive Days with at least one finished Lesson or Review; a Day is the Learner's local calendar day.
  - Lessons unlock strictly in order along a fixed path.
  - Quitting a Lesson midway records nothing.
- **Content for v1:** Unit 1 "Greetings & introductions", 4 Lessons of about 5 Words each (for example 你好, 谢谢, 再见, 我, 你, 是, 叫, 名字). Lesson 1 opens with the four tones. Exact Word list to be drafted and reviewed by the developer.
- **Licensing:** CC-CEDICT (CC BY-SA 4.0) and Tatoeba (CC BY) data, and any recorded audio, must each have an Acknowledgement; the Course Content database built from CC-CEDICT is shared under CC BY-SA. Recording sets are license-checked before use.

## Testing Decisions

- **Good tests** exercise external behaviour through a module's public interface only: given these answers on this Day, the Learner sees this result. No assertions on internal state, private helpers, or SQL.
- **Seam 1, study engine:** almost every rule is tested here, with a fixed clock to control Days. Covers the 80% pass rule and repeats, XP on pass and fail, unlocking order, Words entering Review only on pass, Box movement and due Days, the 30-Day cap, Streak growth, same-Day no double count, reset after a missed Day, and quitting records nothing. The same test suite runs against both the in-memory and the SQLite Learner Progress stores, and also proves that Learner Progress survives replacing the Course Content database.
- **Seam 2, content builder:** run on small fixture source files and inspect the output. Covers stable Word IDs across rebuilds, retired IDs never reused, failure when a tone Exercise lacks a Tone Recording, and failure when a source lacks an Acknowledgement.
- **UI:** a couple of smoke widget tests only (the app launches to the Lesson path; a Lesson can be finished end to end with fakes). No per-screen logic tests, because logic lives in the engine.
- **Audio:** not tested beyond the fake player recording which source was asked to play what.
- **Prior art:** none; this is a new codebase. These suites set the pattern.

## Out of Scope

- Accounts, sign-in, cloud sync, and cross-device progress.
- Any backend or network access.
- Units beyond Unit 1.
- Stories, video Lessons, AI conversation, speaking or pronunciation scoring, handwriting.
- Coins, chests, badges, daily quests, leaderboards, lives.
- Premium, payments, ads, analytics.
- Push notifications and reminders.
- Separate scheduling for different skills of a Word (reading vs listening vs tone).
- FSRS or SM-2 scheduling (the scheduler interface leaves room for it).
- Using any HelloChinese content, art, audio, or code. The research notes describe only structure and behaviour.

## Further Notes

- Domain terms follow `CONTEXT.md`; decisions follow `docs/adr/0001` and `docs/adr/0002`.
- Open item for the developer before content work starts: choose a Tone Recording source with a compatible license, or record the syllables yourself.
- Learner Progress is lost if the app is deleted (no accounts); iOS device backups preserve it. Accepted for v1.
- A Day is the device's local calendar day; travelling across time zones may break or double a Streak. Accepted for v1.
