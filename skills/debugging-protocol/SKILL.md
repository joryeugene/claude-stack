---
name: debugging-protocol
description: Systematic protocol for diagnosing broken behavior and making recurrence structurally impossible. Schema mismatch causes 80% of bugs. Use when something isn't showing, isn't working, or is still broken after a fix attempt.
---

# Debugging Protocol

Two phases. Phase 1 finds and fixes the instance. Phase 2 closes the structural gap so the class of bug cannot recur.

---

## Phase 1: Find and Fix

### Step 1: Schema Alignment Check

Do this first, before any other investigation.

1. Get the actual API response (curl, logs, or network tab).
2. Get the code that reads the data.
3. Compare field names character by character.
4. Identify mismatches: API returns `field_x`, code expects `field_y`.

### Step 2: Data Flow Verification

Trace backwards from the symptom:

1. What field does the component read?
2. What does the API actually return?
3. Where does the chain break?

### Step 3: Trace the Call Chain

If schema is confirmed correct, trace execution from entry to symptom:

1. Add logging or print at each layer boundary (input, transform, output).
2. Identify the first layer where the value diverges from expectation.
3. The bug lives at that boundary, not downstream of it.

Never add logging at the symptom. Add it where the data changes hands.

### Step 4: Proof-Based Fix

Show BEFORE/AFTER with evidence:

- BEFORE: `agent.display_name` (undefined)
- AFTER: `agent.agent_name` (returns value)
- PROOF: API response contains `agent_name` (show the response)

Once fixed, run `/verification-workflow` to prove the fix holds under the full change cycle.

### Step 5: Empty Output Is Not Success

If a command returns no output, that is a failure signal, not a clean pass.

```bash
# Wrong: silent exit, no output, assumed success
./run-tests

# Right: capture stderr too, check exit code
./run-tests 2>&1; echo "Exit: $?"
```

Empty output causes: command not found (silently resolved), test runner found zero tests, build step produced no artifact, API returned 0 results. Each requires investigation, not assumption.

---

## Hierarchy of Causes

1. Schema mismatch (80%)
2. Null or missing data (10%)
3. Logic error (5%)
4. Complex state issue (5%)

## AI-Specific Failure Modes

AI-generated code has a distinct failure signature beyond the standard hierarchy.

| Failure | Signs | Check |
|---------|-------|-------|
| Hallucinated API | Method exists in docs but not in library version | `grep -r "method_name" node_modules/` or read the actual source |
| Wrong import path | Code imports from correct package name but wrong sub-path | Check actual export structure in node_modules or site-packages |
| Stale field name | Code uses old field name after API migration | Compare current API response against field names in code |
| Invented method signature | Right method, wrong argument order or names | Read the function signature directly, do not trust training data |
| Version mismatch | Code uses API syntax from a different major version | Check `package.json` or `requirements.txt` against the syntax used |

When an AI-generated function call fails with "not a function", "undefined is not", or "unexpected keyword argument": check the actual library source before assuming logic error. The method may not exist as written.

## Rationalization Red Flags

These thoughts mean you are about to skip the protocol. Recognize them and stop.

| Thought | Reality |
|---------|---------|
| "One more fix attempt, I'm close." | You said that last time. Get actual data first. |
| "I think I know the issue." | Thinking is not knowing. Curl the endpoint. Read the log. |
| "Let me try this quick thing." | Quick things compound. Follow the steps in order. |
| "The schema is fine, I already checked." | Check again. Character by character. The mismatch you missed is the bug. |
| "This must be a race condition." | Race conditions are 5% of bugs. Schema mismatch is 80%. Check schema first. |

---

## Phase 2: Prevent Recurrence

A fix without a prevention step is not done. Phase 1 resolves the instance. Phase 2 closes the structural gap that allowed the instance to exist.

### Step 1: Name the failure

Two sentences. First: what broke (the observable symptom). Second: what assumption was wrong (what the code believed that was not true).

Not "the query returned null" but "the code assumed the foreign key was always indexed, and it wasn't."
Not "the hook fired on the wrong files" but "the matcher string used `|Edit|` syntax when the actual tool name is `MultiEdit`."

If you cannot write the second sentence, you have named the symptom, not the failure.

### Step 2: Trace to root cause

Why did the system allow this? One of:

- No test existed that would have caught it
- No type constraint made the wrong state unrepresentable
- No hook blocked the pattern at the enforcement layer
- No linter rule flagged it before commit
- A convention existed but required remembering rather than being enforced
- The error path was silent (no log, no exception, no visible signal)

Name the layer that was absent. "We forgot to check" is not a root cause. "There was no automated check" is.

### Step 3: Make recurrence structurally impossible

Pick the enforcement layer closest to the failure:

| Layer | When to use |
|-------|-------------|
| Hook (`PreToolUse`) | Pattern appears in file writes or shell commands |
| Failing test | Logic bug, wrong return value, missed edge case |
| Type constraint | Wrong type was representable and passed silently |
| Linter / static analysis rule | Style or structural pattern that can be detected statically |
| BANNED entry in CLAUDE.md | Behavioral anti-pattern, AI-specific failure mode |

One structural change per bug. Do not add a convention. Conventions require remembering. Enforcement does not.

### Step 4: Add to BANNED (if broadly applicable)

If this pattern could affect other projects or agents working in this codebase, add it to the Forbidden Patterns section of CLAUDE.md. The BANNED list is antifragile: each entry is a ratchet.

Format:
```
- <pattern name>: <what it causes>. <what to do instead>.
```

### The Gate

If step 3 produces only "we'll be more careful" or "we'll add a note to the docs," the root cause in step 2 is still a convention. Go back to step 2. The structural gap has not been named.

---

## Anti-Patterns

- Launching "investigation plans" before checking schema. The data is almost always the problem.
- Saying "working correctly" without verification. Proof is required: show the output.
- Skipping the BEFORE/AFTER structure. Fixes without evidence cannot be confirmed.
- Repeating the same approach after it fails. Stop, get actual data, then try a different path.
- Treating empty output as success. No output means the command failed silently. Investigate before moving on.
- Trusting training-data knowledge of library APIs. Read the actual source.
- Stopping at the fix. A fix without Phase 2 is half a repair. The next agent will hit the same class of bug.
- "We'll be more careful next time." That is not a structural change. It is a convention. Conventions fail.

## The Floor

Every debugging session is a hypothesis test, not a narrative. The hierarchy of causes is not decoration: schema mismatch accounts for most failures. Get the data first. Compare it against what the code expects.

After the fix: name what assumption was wrong, identify which enforcement layer was absent, and add a structural check that makes the wrong state impossible. A bug fixed without Phase 2 is a bug deferred.
