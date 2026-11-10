# 04: Streak

**What to build:** The Learner sees their Streak on the Lesson path. Finishing a Lesson (passed or not) on a new Day extends the Streak; several in one Day count once; missing a Day resets it. A Day is the Learner's local calendar day, supplied by the engine's injected clock.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Streak shown on the Lesson path
- [ ] First finished Lesson ever gives a Streak of 1
- [ ] Finishing a Lesson on the next Day increases the Streak by 1
- [ ] Several finished Lessons in one Day count once
- [ ] Missing a Day resets the Streak on the next finished Lesson
- [ ] Day boundary is local midnight (tested with a fixed clock, including 23:50 then 00:10)
- [ ] Quitting a Lesson midway does not count toward the Streak
