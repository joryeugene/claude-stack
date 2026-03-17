---
name: code-hygiene
description: Review your codebase for drift introduced by isolated AI sessions: dead exports, duplicate logic, and orphaned types.
---

# Code Hygiene

AI sessions are stateless. Each one writes code without knowledge of what the last one wrote.

## The Core Problem

Every AI session starts fresh. Without deliberate effort, each one will:

- Write a new `formatDate` utility that already exists in three other files.
- Leave exports that nothing imports.
- Create types for APIs that no longer exist.
- Swallow errors in empty catch blocks.
- Introduce config drift: env vars documented but unused, or used but undocumented.

## Prevention During Work

Before writing new code:

1. Search the codebase for existing implementations.
2. Search project notes and CLAUDE.md for prior decisions.
3. If something similar exists, extend it rather than duplicate it.

After finishing work:

- Remove dead code you introduced.
- Handle or log all exceptions (never empty catch blocks).
- Remove unused imports.

## Before Closing This Session

Run this before ending any session where code was written. Takes two minutes. Prevents the
next session from inheriting noise that compounds.

1. **Unused imports**: search for imports you added that are no longer referenced. Remove them.
2. **Dead variables**: any variable declared but never read in code you touched this session.
3. **Empty catch blocks**: any exception silently swallowed in code you wrote or modified. Log it or rethrow it.
4. **TODO comments**: any `TODO` or `FIXME` you added this session. Convert to a tracked issue or remove.
5. **Hardcoded values**: any magic strings or numbers that should be named constants or config.
6. **Debug output**: any `console.log`, `print`, `logger.debug` left in production code paths.
7. **Config drift**: any environment variable now used in code but not documented, or documented but removed.

These seven checks catch the most common residue of a working session before it becomes the
starting state of the next one.

## The Weekly Sweep

Combine automated tools with manual review:

1. Run unused-code detection (ruff, knip, depcheck, or equivalent for your language).
2. Search for duplicate function signatures across the codebase.
3. Audit recent AI-generated changes for consolidation opportunities.
4. Check env var drift: compare documented vars against actual usage.
5. Update dependencies.

## During AI Sessions

Each AI response is an opportunity to introduce drift. Manage it actively:

- When the user gives multiple requests, log each as a TODO before starting work.
- Verify each change individually before moving to the next.
- Record architecture decisions as they happen.
- At session end: check for orphaned imports, dead code, and uncovered changes.

## Tech Debt Audit

When invoked with `/code-hygiene debt`, run a systematic tech debt assessment.

### Debt Categories

| Type | Examples | Risk if ignored |
|------|----------|-----------------|
| Code | Duplicated logic, poor abstractions, magic numbers | Bugs, slow development |
| Architecture | Monolith that needs splitting, wrong data store | Scaling limits |
| Test | Low coverage, flaky tests, missing integration tests | Regressions ship undetected |
| Dependency | Outdated libraries, unmaintained dependencies | Security vulnerabilities |
| Documentation | Missing runbooks, outdated READMEs, tribal knowledge | Onboarding pain |
| Infrastructure | Manual deploys, no monitoring, no IaC | Incidents, slow recovery |

### Prioritization

Score each item on three dimensions:

- **Impact** (1-5): How much does it slow the team down?
- **Risk** (1-5): What happens if it stays unfixed?
- **Effort** (1-5): How hard is the fix?

**Priority = (Impact + Risk) x (6 - Effort)**

High score = fix first. Low effort amplifies urgency. High effort dampens it.

### Output

```markdown
## Tech Debt Audit: [Project Name]

| # | Item | Category | Impact | Risk | Effort | Priority | Action |
|---|------|----------|--------|------|--------|----------|--------|
| 1 | [Description] | Code | 4 | 5 | 2 | 36 | [Fix] |
| 2 | [Description] | Test | 3 | 4 | 1 | 35 | [Fix] |

### Phase 1 (this sprint)
[Top 3 items by priority score]

### Phase 2 (next sprint)
[Next 3 items]

### Accepted debt
[Items intentionally deferred with justification]
```

## Anti-Patterns

- Writing a new utility without searching for an existing one first. Three similar lines of code are better than a premature abstraction, but five separate implementations are a maintenance problem.
- Empty catch blocks. If an exception is swallowed silently, every failure becomes invisible.
- Skipping the weekly sweep. Drift compounds. Each isolated session adds a little. The sweep is what keeps it bounded.
- Leaving dead exports because removing them seems risky. If nothing imports it, remove it.

## The Floor

AI-assisted codebases accumulate debt differently than human-only codebases. The mechanism is session isolation: each agent writes confidently without knowing what already exists. The hygiene practices here are the antidote. They are not about aesthetics or preferences. They are about keeping a codebase comprehensible to the next session, which starts without any memory of this one.
