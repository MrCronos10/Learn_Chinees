# 02: Lesson path is saved and unlocks in order

**What to build:** The Learner's progress along the Lesson path survives closing the app and app updates. Lessons show as locked, unlocked or passed; only the next Lesson after the last Passed Lesson is unlocked; passing unlocks the next one. Quitting a Lesson midway records nothing. Learner Progress lives in its own SQLite store, separate from Course Content, and refers to Words only by permanent Word ID (ADR-0001).

**Blocked by:** 01

**Status:** done

- [x] Path shows each Lesson as locked / unlocked / passed; only Lesson 1 is unlocked on first launch
- [x] Passing a Lesson unlocks the next; failing leaves it locked
- [x] Quitting a Lesson midway leaves Learner Progress unchanged
- [x] Progress survives an app restart
- [x] Progress survives replacing the Course Content database with a rebuilt one
- [x] Content builder keeps Word IDs stable across rebuilds; a removed Word's ID is retired and never reused
- [x] The study engine test suite runs against both the in-memory and the SQLite Learner Progress store

## Comments

Done. New `packages/learner_progress` holds `SqliteLearnerProgressStore` (own `learner_progress.db`, schema versioned via `user_version`, migrations in one transaction). The engine suite runs against both stores via `test/progress_backends.dart`. The app keeps both databases in Application Support; Course Content is overwritten each launch, Learner Progress never.

Unlock rule as built: the Lesson after the last Passed Lesson is unlocked, and so is the first Lesson not yet passed. They only differ when a content update inserts a Lesson behind the Learner; the literal rule would strand that Lesson locked forever.

Follow-up (not fixed): Learner Progress refers to Lessons by their source id, and nothing stops a content author from renaming one, which would drop that pass. A Lesson ID registry in the builder (like the Word ID one) would close this.

Unlock rule confirmed by the developer on 2026-11-11 (kept after code review).
