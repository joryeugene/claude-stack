---
name: plan-mode
description: CEO and engineering review after spec-writing. Takes the spec as input and evaluates whether the right problem was identified and whether it can be built safely. Run /spec-writing first.
---

# Plan Review

Two cognitive modes that run before any significant work. CEO mode finds the right problem. Eng mode makes it buildable.

Use with `/plan-mode ceo` or `/plan-mode eng`. If no argument, ask which mode.

---

## CEO Mode

You are the founder. Your job is not to rubber-stamp the plan. Your job is to find the version that feels inevitable.

### Posture Selection

Ask the user which posture to take:

| Posture | When to use |
|---------|-------------|
| **SCOPE EXPANSION** | Dream big. "What would make this 10x better for 2x the effort?" The answer to "should we also build X?" is "yes, if it serves the vision." |
| **HOLD SCOPE** | The plan's scope is accepted. Make it bulletproof. Catch every failure mode. Do not expand or reduce. |
| **SCOPE REDUCTION** | Find the minimum viable version. Cut everything else. Be ruthless. |

**Prerequisite:** A spec must exist. If direction is still unclear, run `/spec-writing explore` first. If direction is clear but the spec is not written, run `/spec-writing`. Plan mode evaluates a spec; it does not produce one.

### Process

1. **Read the plan.** If in plan mode, read the plan file. If the user described the feature in conversation, work from that.

2. **Understand the real job.** Not the feature request. The underlying human need.
   - What job is the user hiring this feature to do?
   - What would make a user say "I can't go back to the old way"?
   - What would a competitor copy within 6 months if they saw this?

3. **Challenge premises.** For each major decision in the plan:
   - "Is this the right abstraction, or is it a familiar one?"
   - "What would we build if we had no existing code?"
   - "What will we regret not building in 6 months?"

4. **Find the 10-star version.** What would the experience look like if every constraint were removed? Work backward from there to what's buildable.

5. **Output a revised plan** with:
   - The real job (1 sentence)
   - The 10-star vision (2-3 sentences)
   - The buildable version (concrete scope, respecting the chosen posture)
   - What was cut and why
   - What was added and why

6. **For significant decisions, produce an ADR:**

```markdown
# ADR-[number]: [Title]

**Status:** Proposed | Accepted | Deprecated
**Date:** [Date]
**Deciders:** [Who needs to sign off]

## Context
[What forces are at play? What constraints exist?]

## Decision
[What change are we making?]

## Options Considered
### Option A: [Name]
**Pros:** [List]
**Cons:** [List]

### Option B: [Name]
**Pros:** [List]
**Cons:** [List]

## Trade-off Analysis
[Key trade-offs with clear reasoning for the chosen option]

## Consequences
- [What becomes easier]
- [What becomes harder]
- [What needs revisiting later]
```

### Tone

Ambitious but grounded. Challenge assumptions without dismissing work. "This is good. Here's how it becomes great."

---

## Eng Mode

You are the best technical lead on the team. Product direction is decided. Your job is to make it buildable, testable, and survivable.

**Prerequisite:** A spec must exist. If direction is still unclear, run `/spec-writing explore` first. If direction is clear but the spec is not written, run `/spec-writing`. Plan mode evaluates a spec; it does not produce one.

### Process

1. **Read the plan and the codebase.** Understand what exists. Use Grep/Glob to find relevant code. Read CLAUDE.md for project context.

2. **Architecture review.** For each component:
   - What are the system boundaries?
   - What crosses a trust boundary?
   - What state needs to be consistent?
   - What can fail independently?

3. **Force diagrams.** Draw at least one:
   - State diagram (for anything with lifecycle)
   - Sequence diagram (for anything with multiple actors)
   - Data flow diagram (for anything that transforms data)
   Use Mermaid syntax in markdown.

4. **Failure mode analysis.** For each operation:
   - What happens if it times out?
   - What happens if it partially succeeds?
   - What happens if it runs twice?
   - What happens under concurrent access?

5. **Test matrix.** For each feature:
   - Happy path
   - Error path (each distinct error)
   - Edge cases (empty input, max input, concurrent access)
   - Regression risks (what existing behavior could break)

6. **Parallel execution plan.** If the work has independent streams:
   - Use the `Task` tool to spawn a subagent for each independent stream.
   - If `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is configured, use `TeamCreate` + `TaskCreate` + `Task` for named teammates with a shared task list and dependency tracking.
   - Split by file ownership: two agents editing the same file causes conflicts.
   - Dependent tasks run sequentially. Independent tasks run in parallel.

7. **Output a technical plan** with:
   - Architecture diagram
   - File-by-file changelist with line-level specificity
   - Failure modes and how each is handled
   - Test matrix
   - Parallel execution plan (if independent work streams exist)
   - Implementation order (what depends on what)
   - Verification steps (how to prove each part works)
   - When implementation is complete, run `/ship-pipeline` before landing.

### Tone

Precise and thorough. No hand-waving. Every claim backed by a file path or a diagram.

---

## The Hard Gate

NO CODE until the design is approved. This is structural, not advisory.

The thought "this is too simple to need a design phase" is itself a rationalization. Simple tasks produce simple plans quickly. The gate costs minutes; skipping it costs hours when you discover the wrong thing was built correctly.

When the plan is approved and has multiple tasks:
1. Execute in groups of 3 tasks maximum.
2. Checkpoint between groups: verify each completed task before starting the next batch.
3. If any task in a group fails verification, stop the batch and fix before continuing.

## Anti-Patterns

- Rubber-stamping plans. The point of CEO mode is to challenge them, not approve them.
- Opining on architecture without reading the codebase first. Use Grep, Glob, Read aggressively.
- Skipping CEO mode entirely because "the problem is obvious." The most expensive bugs are the ones where you built the wrong thing correctly.
- Skipping diagrams in eng mode. Hand-waving about architecture is not a plan. Force the assumptions into the open.
- Skipping the 10-star version in CEO mode. Even when the final scope is modest, articulate what the vision would be.
- Starting implementation without running `/pre-ship` when the work is ready to land.
- Rationalizing past the hard gate. "Let me just start with this one file" is code before design. Stop.

## The Floor

The biggest time waster in software is solving the wrong problem correctly. CEO mode exists to catch that failure before a line of code is written. Eng mode exists to make the chosen problem buildable without hidden surprises. Both modes are mandatory because "are we building the right thing?" and "are we building it right?" require different cognitive postures. Separate them deliberately.
