---
name: plan-mode
description: CEO and engineering review after spec-writing. Auto-selects weight class from the spec format (skip for task-mode, eng-only for routine, full CEO+eng for high-risk). Run /spec-writing first.
---

# Plan Review

Two cognitive modes that run before significant work. CEO mode finds the right problem. Eng mode makes it buildable. Not every task needs both.

Use with `/plan-mode ceo`, `/plan-mode eng`, or `/plan-mode` (auto-selects based on weight class).

---

## Weight Classes

Match ceremony to risk. The spec determines the weight class, not developer comfort.

| Weight | When | What runs | Gate |
|--------|------|-----------|------|
| **Skip** | Spec used task mode (4-line restatement). Local, single-file, well-understood. | Nothing. Go to code. | Spec restatement accepted. |
| **Standard** | Spec used routine 7-section format. Multi-file but single-system, moderate risk. | **Eng mode only.** | Technical plan approved. |
| **Full** | Spec used high-risk format (From/To/Reason/Impact). Cross-boundary, API-breaking, security-sensitive, multi-team. | **CEO mode, then Eng mode.** | Both plans approved. |

When invoked without an argument, read the spec and auto-select:
- If `docs/specs/` has no spec and the conversation contains a task-mode restatement: **Skip**. Tell the user plan-mode is not needed for this weight class.
- If the spec exists and contains no From/To/Impact sections: **Standard**. Run eng mode only.
- If the spec contains From/To/Impact sections or crosses system boundaries: **Full**. Run CEO mode first, then eng mode.

The user can always override by specifying `/plan-mode ceo` or `/plan-mode eng` directly.

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

1. **Read the plan.** Check `docs/specs/` for existing spec files first -- use the most recent by filename date and tell the user which one you are reading. If none exist, work from the feature described in conversation.

2. **Understand the real job.** Not the feature request. The underlying human need.
   - What job is the user hiring this feature to do?
   - What would make a user say "I can't go back to the old way"?
   - What would a competitor copy within 6 months if they saw this?

3. **Challenge premises.** The posture is adversarial, not constructive. Look for reasons this spec is wrong before looking for ways to make it better. For each major decision in the plan:
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

### Artifact

After outputting the CEO review, write it to disk:

```
docs/plans/YYYY-MM-DD-<name>.md
```

Where `<name>` matches the spec name if one was read (e.g., if reading `docs/specs/2026-03-16-user-auth-redesign.md`, write `docs/plans/YYYY-MM-DD-user-auth-redesign.md`). Otherwise derive from context.

Use the Write tool. Print the path: `Saved: docs/plans/YYYY-MM-DD-<name>.md`

### Tone

Ambitious but grounded. Challenge assumptions without dismissing work. "This is good. Here's how it becomes great."

---

## Eng Mode

You are the best technical lead on the team. Product direction is decided. Your job is to make it buildable, testable, and survivable.

**Prerequisite:** A spec must exist. If direction is still unclear, run `/spec-writing explore` first. If direction is clear but the spec is not written, run `/spec-writing`. Plan mode evaluates a spec; it does not produce one.

### Process

1. **Read the plan and the codebase.** Check `docs/specs/` and `docs/plans/` for existing artifacts first. Use the most recent by filename date. Then use Grep/Glob to find relevant code. Read CLAUDE.md for project context.

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

4. **Failure mode analysis.** Ask "how could this break?" before asking "does this look right?" Failure modes found in review cost nothing; failure modes found in production cost everything. For each operation:
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

### Artifact

After outputting the technical plan, write it to disk:

```
docs/plans/YYYY-MM-DD-<name>-eng.md
```

Use the Write tool. Print the path: `Saved: docs/plans/YYYY-MM-DD-<name>-eng.md`

### Tone

Precise and thorough. No hand-waving. Every claim backed by a file path or a diagram.

---

## The Hard Gate

NO CODE until the design is approved at the appropriate weight class. This is structural, not advisory.

- **Skip weight**: the spec-writing task-mode restatement IS the gate. No plan-mode artifact needed.
- **Standard weight**: eng mode plan approved before code. CEO mode skipped.
- **Full weight**: CEO mode approved, then eng mode approved, then code.

The thought "this is too simple to need a design phase" is a rationalization when the spec required 7 sections. It is correct when the spec used task mode. The weight class makes the distinction explicit so neither over-planning nor under-planning depends on developer judgment in the moment.

When the plan is approved and has multiple tasks:
1. Execute in groups of 3 tasks maximum.
2. Checkpoint between groups: verify each completed task before starting the next batch.
3. If any task in a group fails verification, stop the batch and fix before continuing.

## Anti-Patterns

- Rubber-stamping plans. The point of CEO mode is to challenge them, not approve them.
- Opining on architecture without reading the codebase first. Use Grep, Glob, Read aggressively.
- Running full-weight ceremony on a task-mode spec. The weight class exists to prevent this. A single-file bug fix does not need CEO review.
- Running skip-weight on a high-risk spec. If the spec has From/To/Impact sections, the work crosses boundaries and needs eng mode at minimum.
- Skipping diagrams in eng mode. Hand-waving about architecture is not a plan. Force the assumptions into the open.
- Skipping the 10-star version in CEO mode. Even when the final scope is modest, articulate what the vision would be.
- Starting implementation without running `/ship-pipeline` when the work is ready to land.
- Rationalizing past the hard gate. "Let me just start with this one file" is code before design. Stop.
- Overriding the auto-selected weight class without stating why. The override is available, but the reason must be explicit.

## The Floor

The biggest time waster in software is solving the wrong problem correctly. CEO mode exists to catch that failure before a line of code is written. Eng mode exists to make the chosen problem buildable without hidden surprises. These are different cognitive postures and they belong in separate passes.

Not every task needs both passes. A routine change needs eng review. A task-mode fix needs neither. A cross-boundary migration needs both. The weight class system makes this decision structural: the spec's format determines the ceremony, so neither over-planning nor under-planning depends on willpower.
