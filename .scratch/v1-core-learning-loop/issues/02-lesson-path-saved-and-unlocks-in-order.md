# 02: Lesson path is saved and unlocks in order

**What to build:** The Learner's progress along the Lesson path survives closing the app and app updates. Lessons show as locked, unlocked or passed; only the next Lesson after the last Passed Lesson is unlocked; passing unlocks the next one. Quitting a Lesson midway records nothing. Learner Progress lives in its own SQLite store, separate from Course Content, and refers to Words only by permanent Word ID (ADR-0001).

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Path shows each Lesson as locked / unlocked / passed; only Lesson 1 is unlocked on first launch
- [ ] Passing a Lesson unlocks the next; failing leaves it locked
- [ ] Quitting a Lesson midway leaves Learner Progress unchanged
- [ ] Progress survives an app restart
- [ ] Progress survives replacing the Course Content database with a rebuilt one
- [ ] Content builder keeps Word IDs stable across rebuilds; a removed Word's ID is retired and never reused
- [ ] The study engine test suite runs against both the in-memory and the SQLite Learner Progress store
