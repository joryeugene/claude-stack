---
name: rca
description: Use after any bug fix, production incident, or repeated mistake. Find root cause, fix it, then make recurrence structurally impossible.
---

# RCA

A fix without a prevention step is not done. Debugging finds and resolves the instance. RCA closes the structural gap that allowed the instance to exist.

## The Five Steps

### 1. Name the failure

Two sentences. First: what broke (the observable symptom). Second: what assumption was wrong (what the code believed that was not true).

Not "the query returned null" but "the code assumed the foreign key was always indexed, and it wasn't."
Not "the hook fired on the wrong files" but "the matcher string used `|Edit|` syntax when the actual tool name is `MultiEdit`."

If you cannot write the second sentence, you have named the symptom, not the failure.

### 2. Trace to root cause

Why did the system allow this? One of:

- No test existed that would have caught it
- No type constraint made the wrong state unrepresentable
- No hook blocked the pattern at the enforcement layer
- No linter rule flagged it before commit
- A convention existed but required remembering rather than being enforced
- The error path was silent (no log, no exception, no visible signal)

Name the layer that was absent. "We forgot to check" is not a root cause. "There was no automated check" is.

### 3. Fix the immediate issue

The minimal change that resolves this instance. No refactoring scope creep. One logical unit.

### 4. Make recurrence structurally impossible

Pick the enforcement layer closest to the failure:

| Layer | When to use |
|-------|-------------|
| Hook (`PreToolUse`) | Pattern appears in file writes or shell commands |
| Failing test | Logic bug, wrong return value, missed edge case |
| Type constraint | Wrong type was representable and passed silently |
| Linter / static analysis rule | Style or structural pattern that can be detected statically |
| BANNED entry in CLAUDE.md | Behavioral anti-pattern, AI-specific failure mode |

One structural change per RCA. Do not add a convention. Conventions require remembering. Enforcement does not.

### 5. Add to BANNED (if broadly applicable)

If this pattern could affect other projects or agents working in this codebase, add it to the Forbidden Patterns section of CLAUDE.md. The BANNED list is antifragile: each entry is a ratchet. The system gets stronger with each failure encoded.

Format:
```
- <pattern name>: <what it causes>. <what to do instead>.
```

---

## The Gate

If step 4 produces only "we'll be more careful" or "we'll add a note to the docs," the root cause in step 2 is still a convention. Go back to step 2. The structural gap has not been named.

---

## Relationship to Other Skills

`/debugging-protocol` finds and fixes what is broken right now.

`/rca` runs after the fix. It asks: why was this possible, and how do we make it structurally absent?

The two skills are sequential, not redundant. Debugging resolves the instance. RCA closes the class.
