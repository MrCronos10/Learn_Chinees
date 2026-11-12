# Course Content and Learner Progress are stored separately

Course Content ships as a read-only database that is built by a script and replaced wholesale on every app update; Learner Progress lives in a separate database that is never replaced. Progress refers to Words only by their permanent Word ID. We chose this over a single shared database because merging new content into a file that also holds the Learner's progress is a common way to lose it, and because there is no backend to recover from.

## Consequences

- Word IDs must never be reused or renumbered; removing a Word means retiring its ID, and progress for retired IDs is ignored.
- Lesson IDs are permanent too, because progress records which Lessons were passed by Lesson ID. The content builder keeps them in the same ID registry as Word IDs (`content/ids.json`): a Lesson ID that was built before may not silently disappear (a renamed Lesson would drop Learners' passes), removing one means listing it under `retiredLessons`, and a retired Lesson ID is never used again. (Added 2026-11-12, ticket 10.)
