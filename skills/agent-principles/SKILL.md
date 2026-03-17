---
name: agent-principles
description: The quality contract for AI-assisted development: verification-first, schema-before-theory, evidence over claims, no hedging. Load when establishing session standards or when output quality slips.
user-invocable: false
---

# Agent Quality Principles

The minimum operating standard for every AI-assisted session, regardless of stack.

## Verification First

Every claim needs evidence. Every change needs proof.

- "Should work" is banned. "WILL work because [evidence]" is required.
- After every code change: run it, show the output, prove it works.
- If you cannot verify: say "I cannot verify this because [reason]. Please run [command]."
- Never use checkmarks without testing.

## Schema Before Theory

When something isn't showing or working:

1. Check the data first. 80% of bugs are field name mismatches.
2. Get actual data (curl the endpoint, read the logs, check the response).
3. Compare field names character by character: API returns X, code expects Y.
4. Only after ruling out data issues, investigate logic.

## One Change, One Verification

- Make one change. Verify it works. Then make the next.
- Never batch 5 changes and test all at once.
- If incremental testing isn't possible, stop and figure out how.

## Complete Implementations

- No TODO comments in committed code.
- No "basic version, enhance later."
- If you start it, finish it.

## Error Ownership

- If you encounter an error, fix it. No "preexisting" excuses.
- If you touch a file, leave it cleaner than you found it.
- Dead code, unused imports, empty catch blocks: fix them all.

## Capture Before Execute

When a user gives multiple requests in one message:

1. Log each distinct request as a TODO immediately.
2. Then start working through them.
3. User asks get lost during complex sessions. Capture first.

## Consolidate, Don't Duplicate

Before writing new utility functions:

1. Search the codebase and project notes for existing implementations.
2. If similar code exists, extend it.
3. Three similar lines is better than a premature abstraction.

## Explore Aggressively

Use tools heavily. Read files, grep patterns, curl endpoints. Direct observation beats inference.

- More tool calls correlate with better outcomes. Don't conserve tool use.
- When unfamiliar with a codebase, 10 reads beats 3. Explore widely before narrowing.
- When a simple tool (read, grep, curl, screenshot) can give direct access, use it. Don't reason from incomplete information.

## Test Before Fixing

Run existing tests FIRST, before writing any fix.

- Failing tests reveal root cause faster than reading code alone.
- If no tests exist, write a failing test that reproduces the bug, then fix it.
- Understanding what passes and what fails gives you the root cause.

## Tripod Check

Answer these three questions before designing anything: a feature, a function, a system, a hook.

1. **Antifragile:** "Does MORE use or MORE violation make this STRONGER?" If the answer is no, redesign.
   Descriptions are fragile (forgettable). Hooks are antifragile (structurally enforced). Make the
   wrong thing structurally absent, not merely discouraged.

2. **Simple (Hickey: complecting):** "What am I complecting here?" Name each concern separately.
   If the name requires "and", the design is complected. Simple is not easy. Easy means familiar.
   Simple means one concern. Separate them.

3. **Research First:** "Who already solved this? What did they learn? What did they get wrong?"
   Search the codebase and prior decisions, find prior art on GitHub, in papers, in existing tools.
   Three similar lines of code beat a premature abstraction. Consolidate, don't duplicate.

## The Floor

Every project accumulates drift: unverified claims, duplicate utilities, incomplete implementations, and abandoned code paths. These principles encode the minimum floor beneath which no AI-assisted session should fall. They are not a checklist to scan before shipping. They are the operating mode from which every decision is made.

## Skill Routing

The claude-stack skills form a lifecycle. Each skill fires at a specific moment.

### Project start

| Step | Moment | Skill | Trigger |
|------|--------|-------|---------|
| 0 | Direction unclear, research or brainstorming needed | `/spec-writing explore` | Research prior art, generate options, identify the decision point |
| 1 | Direction set, scope unclear or wrong thing could be built | `/spec-writing` | Write problem, success criteria, non-goals. Required input for plan-mode. |
| 2 | Spec written, before any significant work | `/plan-mode` | CEO: right problem? Eng: can we build it safely? |

### During development

| Moment | Skill | Trigger |
|--------|-------|---------|
| Writing any feature or test | `/tdd` | Failing test first, always |
| Something broken | `/debugging-protocol` | Check data before theorizing |
| Bug fixed | `/rca` | Root cause, prevention, BANNED entry |
| After every change | `/verification-workflow` | Prove it works, show evidence |
| Code is slow | `/performance` | Measure, name the pattern, fix one thing |
| Feature touches user input or auth | `/security-review` | Trace inputs, check named patterns |
| AI session drift accumulating | `/code-hygiene` | Dead exports, duplicate logic, orphaned types |

### Building UI

| Moment | Skill | Trigger |
|--------|-------|---------|
| Before first line of UI code | `/visual-design` | Visual identity before implementation: color, typography, tokens |
| Before shipping UI behavior | `/interaction-design` | Discoverability, modes, feedback, keyboard-first patterns |
| After UI changes | `/visual-verify` | Element-level proof, not full-page screenshots |
| Before shipping UI | `/accessibility-review` | WCAG 2.1 AA audit, keyboard, contrast, screen reader |
| Testing behavior in browser | `/browser-testing` | Network, console, forms, multi-tab |

### Review

| Moment | Skill | Trigger |
|--------|-------|---------|
| Receiving PR feedback | `/code-review` | Read all, restate, YAGNI check, push back with evidence |
| Before merge | `/code-review` | Dispatch reviewer subagent, two-stage review |

### Incidents

| Moment | Skill | Trigger |
|--------|-------|---------|
| Production down or alert fires | `/incident-response` | Triage, classify severity, assign roles |
| During active incident | `/incident-response` | Status updates at fixed cadence |
| After resolution | `/incident-response` | Blameless postmortem with 5 whys |

### Shipping

| Moment | Skill | Trigger |
|--------|-------|---------|
| Ready to merge | `/ship-pipeline` | Pre-flight review, test, commit, push, PR |
| Cutting a versioned release | `/release` | Semver suggestion, version bump, annotated tag, GitHub release |

### Maintenance

| Moment | Skill | Trigger |
|--------|-------|---------|
| Update plugin or sync local changes | `/update` | Install, update, or sync claude-stack |

### Always active (no invocation needed)

| Skill | Role |
|-------|------|
| `/agent-principles` | Quality contract: evidence, schema-first, no hedging |
| `/agent-orchestration` | Parallel agents for independent work streams |
