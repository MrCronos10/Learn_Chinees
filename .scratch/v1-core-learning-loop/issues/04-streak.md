# 04: Streak

**What to build:** The Learner sees their Streak on the Lesson path. Finishing a Lesson (passed or not) on a new Day extends the Streak; several in one Day count once; missing a Day resets it. A Day is the Learner's local calendar day, supplied by the engine's injected clock.

**Blocked by:** 02

**Status:** done

- [x] Streak shown on the Lesson path
- [x] First finished Lesson ever gives a Streak of 1
- [x] Finishing a Lesson on the next Day increases the Streak by 1
- [x] Several finished Lessons in one Day count once
- [x] Missing a Day resets the Streak on the next finished Lesson
- [x] Day boundary is local midnight (tested with a fixed clock, including 23:50 then 00:10)
- [x] Quitting a Lesson midway does not count toward the Streak

## Comments

Done. `StudyEngine.currentStreak()` counts consecutive study Days ending today or yesterday (CONTEXT.md updated): until the Learner studies today it shows yesterday's run, and once a whole Day is missed it is 0. Study Days come from the store's `studyDays()`, which ticket 05 extends with finished Reviews. `SystemClock` takes an optional `now` so tests can check local midnight. The path re-reads Streak/XP when the app returns from the background, and the stats sit in a wrapping row under the app bar so they can't overflow.

Not handled (accepted in the spec): Days dated after the clock's today, after a time-zone or clock change, are ignored.
