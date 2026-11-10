# Runbook: implementing the v1 tickets

Tickets live in `.scratch/v1-core-learning-loop/issues/`. Build one ticket per fresh session.

## Start

```
cd ~/projects/my-chinese-app && claude
```

## Loop (repeat per ticket)

```
/clear
/model opus      ← or sonnet, see the table
(paste the prompt below)
```

## The prompt

```
/implement the next ticket in .scratch/v1-core-learning-loop/issues/ — pick the lowest-numbered file whose Status is ready-for-agent and whose "Blocked by" tickets are all Status: done. Before coding, read CLAUDE.md, CONTEXT.md and docs/adr. Rules: study engine stays pure Dart (no Flutter); Course Content and Learner Progress stay in separate stores (ADR-0001); tone audio only from Tone Recordings (ADR-0002); all Day logic via the injected clock; test only through public interfaces. If the only remaining ticket needs a human (Status ready-for-human), or ticket 10's word list needs approval, STOP and ask me. When finished: tests green, /code-review done, commit, set the ticket's Status to done, and tell me which ticket is next and whether it needs Opus or Sonnet.
```

## Model per ticket

| Ticket | Model |
|---|---|
| 01 Play one Lesson | Opus |
| 02 Saved path & unlocks | Opus |
| 03 XP | Sonnet |
| 04 Streak | Sonnet |
| 05 Review with Boxes | Opus |
| 06 Listening | Sonnet |
| 07 Tone source | **You**: fill in the ticket, set `Status: done` |
| 08 Tone Exercises | Sonnet |
| 09 Settings & Acknowledgements | Sonnet |
| 10 Unit 1 content | Opus (stops for your word-list approval) |

Opus for tickets that set up architecture or tie several rules together; Sonnet for single features on top of an existing pattern.

## Rules

- Before `/clear`: tests green, `/code-review` done, work committed. If not, fix it first.
- A Sonnet run fails twice → `/clear`, `/model opus`, paste the same prompt.
- Something breaks later → `/diagnosing-bugs` on Opus, not a hand patch.
- Push whenever you like: `git push -u origin main` the first time, then `git push`.
