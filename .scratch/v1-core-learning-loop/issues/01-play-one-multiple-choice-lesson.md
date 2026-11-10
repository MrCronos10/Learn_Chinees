# 01: Play one multiple-choice Lesson end to end

**What to build:** A Learner opens the app, sees a Lesson path with a single Lesson, plays through its multiple-choice Exercises (each Word shown with characters and pinyin), gets immediate right/wrong feedback with the correct answer shown when wrong, repeats missed Exercises at the end, and lands on a results screen that says whether it is a Passed Lesson and shows the first-try percentage. This tracer bullet stands up all three parts: the Flutter app (thin UI), the pure-Dart study engine (the main test seam, with injected Course Content reader, Learner Progress store and clock), and the content builder that turns a tiny fixture source into the read-only Course Content database, assigning permanent Word IDs from the start. Learner Progress may be in-memory only in this ticket.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Content builder turns a small fixture source (one Lesson, ~3 Words) into a Course Content database, assigning each Word a permanent Word ID
- [ ] App launches on iOS simulator to a Lesson path showing the one Lesson; Android build compiles
- [ ] Multiple-choice Exercise shows a Word with characters + pinyin and asks for its meaning
- [ ] Immediate feedback after each answer; correct answer shown when wrong
- [ ] Exercises missed on first try are repeated at the end and do not change the mark
- [ ] Results screen shows Passed Lesson (>= 80% first-try correct) or not, and the first-try percentage
- [ ] Study engine tests (through its public interface only, fixed clock, in-memory stores) cover the 80% rule at the boundary (79/80/100%) and the repeat-at-end behaviour
- [ ] One smoke widget test: app launches to the Lesson path and a Lesson can be finished end to end with fakes
