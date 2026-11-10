# 05: Review with Boxes

**What to build:** Words from each Passed Lesson enter Review. The Lesson path shows how many Words are due today; the Learner can start a Review containing only due Words, answered with the same Exercise kinds as Lessons. Correct answers move a Word up one Box (1, 3, 7, 14, 30 Days, staying at 30); wrong answers send it back to the first Box. When nothing is due, the Learner is told so. Review earns XP and a finished Review counts toward the Streak. Scheduling sits behind its own scheduler interface so the Box scheme can be replaced later.

**Blocked by:** 02, 03, 04

**Status:** ready-for-agent

- [ ] Words enter the first Box, due the next Day, only when their Lesson becomes a Passed Lesson
- [ ] Lesson path shows the count of Words due today
- [ ] Review contains only Words due today
- [ ] Correct answer moves the Word up one Box with the matching next due Day; the last Box stays at 30 Days
- [ ] Wrong answer sends the Word back to the first Box, due the next Day
- [ ] "Nothing due" state shown when no Words are due
- [ ] Correct Review answers earn XP; a finished Review extends the Streak
- [ ] Scheduler is behind its own interface; engine tests cover every Box transition with a fixed clock
