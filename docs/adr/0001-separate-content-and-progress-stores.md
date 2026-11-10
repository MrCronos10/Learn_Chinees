# Course Content and Learner Progress are stored separately

Course Content ships as a read-only database that is built by a script and replaced wholesale on every app update; Learner Progress lives in a separate database that is never replaced. Progress refers to Words only by their permanent Word ID. We chose this over a single shared database because merging new content into a file that also holds the Learner's progress is a common way to lose it, and because there is no backend to recover from.

## Consequences

- Word IDs must never be reused or renumbered; removing a Word means retiring its ID, and progress for retired IDs is ignored.
