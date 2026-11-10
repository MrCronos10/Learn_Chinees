# 05: Review with Boxes

**What to build:** Words from each Passed Lesson enter Review. The Lesson path shows how many Words are due today; the Learner can start a Review containing only due Words, answered with the same Exercise kinds as Lessons. Correct answers move a Word up one Box (1, 3, 7, 14, 30 Days, staying at 30); wrong answers send it back to the first Box. When nothing is due, the Learner is told so. Review earns XP and a finished Review counts toward the Streak. Scheduling sits behind its own scheduler interface so the Box scheme can be replaced later.

**Blocked by:** 02, 03, 04

**Status:** done

- [x] Words enter the first Box, due the next Day, only when their Lesson becomes a Passed Lesson
- [x] Lesson path shows the count of Words due today
- [x] Review contains only Words due today
- [x] Correct answer moves the Word up one Box with the matching next due Day; the last Box stays at 30 Days
- [x] Wrong answer sends the Word back to the first Box, due the next Day
- [x] "Nothing due" state shown when no Words are due
- [x] Correct Review answers earn XP; a finished Review extends the Streak
- [x] Scheduler is behind its own interface; engine tests cover every Box transition with a fixed clock

## Comments

Done. `Scheduler` interface with `BoxScheduler` (1/3/7/14/30 Days), injectable into `StudyEngine`. Words met in a Passed Lesson enter Box 1 due the next Day; a Word already in Review keeps its schedule. A Review plays like a Lesson (missed Exercises repeat at the end), and the first try decides the Box and the XP (10 per first-try correct). Nothing is recorded until the Review is finished; a finished Review is a study Day for the Streak. Overdue Words stay due. Word IDs no longer in the Course Content are ignored.

Lessons and Reviews share one `StudySession` base in the engine and one `StudyScreen` in the app. Learner Progress schema v3 adds `word_schedules` and `finished_reviews`; v1/v2 databases upgrade in place. The Review Exercise for a Word is the first Exercise on the Lesson path that studies it (`CourseContentReader.reviewExercises`).
