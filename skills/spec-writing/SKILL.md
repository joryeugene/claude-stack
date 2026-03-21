---
name: spec-writing
description: Use before starting any feature, task, or fix. Explore mode for brainstorming and research when direction is unclear. Task mode for concrete fixes. Structured mode for the 7-section spec. The spec format determines plan-mode's weight class.
---

# Spec-Writing

Write the spec before writing any code. Agents skip this step and build the wrong thing correctly. The spec is the forcing function that catches misunderstanding before it becomes wasted work.

## Two Modes

Invoke with `/spec-writing explore` for free ideation and research. Invoke with `/spec-writing` for the structured 7-section spec. If no argument and direction is not yet clear, start with explore.

---

## Explore Mode

Use when direction is unclear, multiple approaches are possible, or research is needed before the problem can be defined. No required output format. No gate.

### What to do

1. **Research prior art.** What already exists? Search the codebase for related utilities. Find existing tools, libraries, and approaches. Read what came before.
2. **Generate options.** List 3-5 distinct approaches without committing to any. Name each one. Name the trade-offs.
3. **Surface constraints.** What cannot change? What must interoperate? What has already been decided? Constraints define the solution space more than preferences do.
4. **Identify the decision point.** Name the one question whose answer eliminates most alternatives. When that question is answered, exploring becomes deciding.

### Output

A short note with:
- The options considered and their trade-offs
- The key constraint or decision point
- A recommendation, or the open question that blocks one

When the output is clear enough to write a problem statement, move to structured mode.

---

## Task Mode

Use when the problem is already understood and the task is concrete: fix X, add Y, change Z. The problem does not need exploration. What needs externalizing is Claude's interpretation before any code runs.

Invoke with `/spec-writing task`.

### What to output

Four items, printed inline. No artifact written to disk.

1. **Restatement**: one sentence restating the task in Claude's own words
2. **Files**: the files that will be touched, with a brief reason for each
3. **Done criteria**: the observable state that means the task is complete
4. **Out of scope**: adjacent things that will not be touched

### The gate

The user reads the restatement. If it is wrong, they correct it and Claude restates. Coding begins only after an uncorrected restatement. One correction loop is enough; if the task is still unclear after one restatement, move to explore mode.

---

## The Seven Sections

Write one paragraph per section. No code appears until all seven are written.

### 1. Problem Statement

What is wrong or missing? Describe the gap, not the solution. If you find yourself describing implementation details here, rewrite it.

### 2. Success Criteria

How will you know it worked? State measurable outcomes. "The user can do X" is a criterion. "It should feel smooth" is not.

### 3. Non-Goals

What is explicitly out of scope? Name the adjacent features you are not building. Non-goals prevent scope creep and make design decisions explicit.

### 4. Assumptions

What must be true for this spec to be valid? List dependencies, environmental requirements, and unstated facts you are relying on. Surfacing assumptions prevents building on a false foundation.

### 5. Edge Cases

What inputs or states could break this? Name them before coding. An edge case named before implementation is a design constraint. An edge case found after is a bug.

### 6. Trade-off Log

What alternatives did you consider and why did you reject them? This section prevents re-litigating decisions and makes the reasoning auditable.

### 7. Verification Strategy

How will you prove it works? Name the specific tests, tools, or user actions that constitute proof. If you cannot describe verification, you do not understand the success criteria.

---

## The Gate

No code until all seven sections are complete. If a section cannot be written, that is a signal: the problem is not understood well enough to build. The correct response is to go back to the problem statement, not to skip the section.

---

## Progressive Rigor

Not every spec needs the same depth. Match rigor to risk.

**Routine change** (local, low-risk, single-system): concise seven sections, no additional ceremony. The gate still applies; the sections can be brief.

**High-risk change** (cross-boundary, API-breaking, security-sensitive, data migration, multi-team impact): add to each relevant section:
- From: the current state or behavior
- To: the future state or behavior
- Reason: why the change is necessary
- Impact: breaking or non-breaking, who is affected, what needs to migrate

The distinction matters before writing section 1. A high-risk spec that looks like a routine spec will pass the gate and still produce surprises.

---

## Artifact

After completing all seven sections, write the spec to disk:

```
docs/specs/YYYY-MM-DD-<name>.md
```

Where `<name>` is 2-4 words in kebab-case derived from the feature being specced (e.g., `user-auth-redesign`, `payment-webhook-handler`). If the name is not clear from context, use `untitled`.

Use the Write tool to create `docs/specs/YYYY-MM-DD-<name>.md` with the full spec content. Print the path after writing: `Saved: docs/specs/YYYY-MM-DD-<name>.md`

After implementation, update the spec to reflect what was actually built. If execution diverged from the spec, record why in the Trade-off Log before the spec is considered final. A spec that is never updated after shipping is documentation of intent, not reality.

---

## After the Spec

The spec format determines what happens next:

- **Task mode** (4-line restatement): go straight to code. Plan-mode is not needed.
- **Routine 7-section spec** (no From/To/Impact): `/plan-mode` runs eng mode only.
- **High-risk spec** (From/To/Reason/Impact sections): `/plan-mode` runs CEO mode first, then eng mode.

Do not invoke plan-mode before the spec exists. Plan mode evaluates a spec; it does not produce one.

---

## Anti-Patterns

- Skipping explore mode when direction is unclear and jumping straight to the 7-section format. The gate cannot be met when the problem is not yet understood.
- Invoking `/plan-mode` before the spec is written. Plan mode evaluates a spec; it does not replace one.
- Starting with section 7 (implementation) and working backward to rationalize it.
- Success criteria that cannot be measured: "fast", "clean", "intuitive."
- Non-goals section left blank. If you have no non-goals, the scope is unbounded.
- Assumptions section left blank. Every spec has assumptions. Find them.
- Writing the spec after the code is written. At that point it is documentation, not a spec.
