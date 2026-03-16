---
name: spec-writing
description: Use before starting any feature, task, or fix where the scope is unclear or the wrong thing could be built. No code until the spec is written.
---

# Spec-Writing

Write the spec before writing any code. Agents skip this step and build the wrong thing correctly. The spec is the forcing function that catches misunderstanding before it becomes wasted work.

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

## Anti-Patterns

- Starting with section 7 (implementation) and working backward to rationalize it.
- Success criteria that cannot be measured: "fast", "clean", "intuitive."
- Non-goals section left blank. If you have no non-goals, the scope is unbounded.
- Assumptions section left blank. Every spec has assumptions. Find them.
- Writing the spec after the code is written. At that point it is documentation, not a spec.
