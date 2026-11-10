# My Chinese App

A free, original mobile app that teaches adult absolute beginners everyday conversational Mandarin, starting with pinyin and tones. Built as a portfolio and learning project; inspired by studying how apps in this category are structured, but with its own content.

## Learners and progress

**Learner**:
An adult absolute beginner using the app to learn everyday conversational Chinese. Uses the app without an account; their progress lives only on their device.
_Avoid_: User, student, player

**Learner Progress**:
Everything the app knows about one Learner: Lessons passed, each Word's Box and due date, XP, and Streak. Never overwritten by a content update.
_Avoid_: Save data, user data, state

**Day**:
One calendar day in the Learner's local time zone on their device.
_Avoid_: 24 hours, session

**XP**:
Points a Learner earns for each Exercise answered correctly on the first try, whether or not the Lesson is passed. A missed Exercise repeated at the end earns nothing. XP is saved only when the Lesson is finished.
_Avoid_: Score, points, coins

**Streak**:
The count of consecutive Days on which a Learner completed at least one Lesson or Review. A failed Lesson counts; quitting midway does not. Until the Learner studies today, the Streak still shows the run ending yesterday; once a whole Day is missed it is 0.
_Avoid_: Chain, daily count

## Course content

**Course Content**:
The read-only teaching material shipped with the app: Units, Lessons, Exercises, Words, and their audio. Replaced as a whole when the app updates.
_Avoid_: Data, database, assets

**Word**:
The unit of knowledge a Learner studies and is reviewed on: its Chinese characters, pinyin, and English meaning, scheduled as one item. Has a permanent identity that is never reused or renumbered.
_Avoid_: Vocabulary item, card, entry

**Unit**:
An ordered group of Lessons around one theme (the first is "Greetings & introductions").
_Avoid_: Chapter, section, course

**Lesson**:
A short, ordered set of Exercises that introduces a few Words or one pronunciation topic. Lessons are unlocked one at a time along a fixed path.
_Avoid_: Level, quiz, module

**Passed Lesson**:
A Lesson in which at least 80% of Exercises were answered correctly on the first try. Passing unlocks the next Lesson and sends the Lesson's Words into Review; a failed Lesson can be retried at once.
_Avoid_: Completed lesson, cleared lesson

**Exercise**:
A single question a Learner answers inside a Lesson or Review. v1 kinds: multiple choice, listening (hear a Word, pick its meaning), and tone (hear a syllable and pick its tone, or see a toned syllable and pick its sound).
_Avoid_: Question, task, challenge

**Tone Recording**:
A recorded human pronunciation of one pinyin syllable in one of the four tones, used for tone Exercises instead of synthesized speech.
_Avoid_: TTS clip, sound file

## Review

**Review**:
A session of Exercises drawn from Words the Learner has already met that are due today, scheduled by spaced repetition.
_Avoid_: Practice, revision, flashcards

**Box**:
One of five spaced-repetition levels a Word sits in, due again after 1, 3, 7, 14, or 30 Days. A correct answer moves the Word up one Box (staying in the last); a wrong answer sends it back to the first.
_Avoid_: Level, stage, bucket

## Licensing

**Acknowledgement**:
The in-app credit and license notice for every third-party source used in the Course Content.
_Avoid_: Credits, about
