---
name: ship-pipeline
description: Use when ready to ship. Runs the full release pipeline: merge, test, pre-landing review, commit, push, PR. Includes pre-ship paranoid diff review.
disable-model-invocation: true
---

# Ship

The full release pipeline in one command. Merge, test, review, commit, push, PR. The user sees the PR URL at the end.

**Only stop for:**

- On `main` branch (abort)
- Merge conflicts that can't be auto-resolved
- Test failures
- Critical review findings where the user chooses to fix
- Missing test/build commands (ask once, then go)

**Never stop for:**

- Uncommitted changes (always include them)
- Commit message approval (auto-generate)
- Changelog content (skip unless project config says otherwise)

---

## Step 1: Pre-flight

```bash
git branch --show-current
```

If on `main` or `master`: abort with "Ship from a feature branch."

```bash
git status
git diff main...HEAD --stat
git log main..HEAD --oneline
```

---

## Step 2: Read project config

Read the project's CLAUDE.md. Look for a section titled `## Ship`.

Expected format:

```
## Ship
test: <test command>
build: <build command or "none">
version: <version file path or "none">
changelog: <true/false>
```

If no `## Ship` section: ask the user "What command runs your tests?" and "What command builds the project (or 'none')?" Remember the answers for this session.

---

## Step 3: Merge origin/main

```bash
git fetch origin main && git merge origin/main --no-edit
```

If merge conflicts: try to auto-resolve simple ones (version files, lockfiles). If complex, stop and show them.

If already up to date: continue silently.

---

## Step 4: Run tests

Run the test command from the project config.

If tests fail: show the failures and stop. Do not proceed.

If tests pass: note the counts briefly and continue.

---

## Step 5: Pre-landing review

```bash
git diff origin/main
```

Read the FULL diff before commenting. Do not flag issues already addressed in the diff.

Read the project's CLAUDE.md for a `## Review Checklist` section. If found, use it as the primary checklist. If not found, use the default below.

**Default checklist:**

Pass 1 (CRITICAL):
- SQL/data safety: raw SQL injection, missing parameterization, destructive operations without confirmation
- Trust boundaries: unsanitized user input flowing into queries, file paths, or shell commands
- Race conditions: concurrent access to shared state, TOCTOU bugs
- Resource leaks: unclosed connections, unjoined tasks, missing cleanup

Pass 2 (INFORMATIONAL):
- Dead code introduced by this diff
- Magic numbers or string coupling
- Missing error handling (unwrap in Rust, unhandled promises in JS, bare except in Python)
- Test gaps: new code paths without corresponding tests
- Consistency: does this diff follow patterns established elsewhere?

For each CRITICAL finding: use AskUserQuestion. Show the problem and fix. Options: A) Fix it now, B) Acknowledge and ship anyway, C) False positive.

If fixes applied: re-run tests before continuing.

If no critical issues: continue.

---

## Step 6: Build (if configured)

If the project config specifies a build command (not "none"):

```bash
<build command>
```

This ensures the shipped artifact is current.

---

## Step 7: Commit

Analyze the diff and create logical commits.

**If the diff is small (< 50 lines, < 4 files):** Single commit.

**If larger:** Split into bisectable chunks:

- Infrastructure/config changes first
- Core logic second
- Tests with their corresponding code
- Build artifacts last

Each commit message: `<type>: <summary>` (feat/fix/chore/refactor/docs).

Stage specific files by name. Never `git add -A`.

---

## Step 8: Push + PR

```bash
git push -u origin <branch-name>
```

Create PR:

```bash
gh pr create --title "<type>: <summary>" --body "$(cat <<'EOF'
## Summary
<bullet points of what changed>

## Test plan
- [x] All tests pass
- [x] Pre-landing review: <N issues found / no issues>

EOF
)"
```

Output the PR URL. Done.

---

## Anti-Patterns

- Force pushing. Never. Use fast-forward or resolve conflicts manually.
- `git add -A`. Stage specific files by name. Secrets and junk get committed this way.
- Skipping tests. The pipeline always runs tests. If tests don't exist, ask for the test command.
- Continuing after test failures. Stop. Do not push broken code.
- Committing `.env` files, credentials, or secrets. Check `git status` before staging.
- Running ship from main. Always ship from a feature branch.

## The Floor

The ship pipeline makes release structural rather than ceremonial. Every step is required, every step is verified, and the sequence never changes. The discipline of running tests and review before every push is not overhead. It is the mechanism that makes shipping feel safe. When the pipeline is structural, shipping becomes routine. When it is optional, it becomes an argument every time.
