---
name: release
description: Use when cutting a versioned release. Detects commits since last tag, suggests semver bump, bumps version file, tags, pushes, and creates a GitHub release. Distinct from ship-pipeline which ends with a PR.
disable-model-invocation: true
---

# Release

A versioned release is a different endpoint than a PR. `ship-pipeline` ends with a review
request. `release` ends with a GitHub release URL. Run this after the PR has merged, from
the default branch.

**Stop for:**

- Version confirmation (always -- show the proposed version and wait)
- Missing version file when the project config says to bump one

**Never stop for:**

- Tag format (always `vX.Y.Z`)
- Changelog wording (auto-generate from commit log)
- Release notes content (let `gh --generate-notes` handle it)

---

## Step 1: Pre-flight

```bash
git branch --show-current
```

If not on the default branch, warn:

```
You are on <branch>. Releases are cut from the default branch.
Run: git checkout main && git pull
```

Do not proceed until on the default branch.

```bash
git status
```

If there are uncommitted changes: warn and stop. A release commit is only the version bump.
Staged work belongs in a feature branch, not a release.

---

## Step 2: Read project config

Read the project's CLAUDE.md. Look for a section titled `## Release`.

Expected format:

```
## Release
version: <file path or "none">
changelog: <true/false>
```

Supported version files: `package.json` (`.version` field), `pyproject.toml`
(`[tool.poetry].version` or `[project].version`), `Cargo.toml` (`[package].version`).

If no `## Release` section: skip version bump, skip changelog. Tag and release only.

---

## Step 3: Detect last tag and commits

```bash
git fetch --tags
git describe --tags --abbrev=0 2>/dev/null || echo "none"
```

If a prior tag exists:

```bash
LAST=$(git describe --tags --abbrev=0)
git log $LAST..HEAD --oneline
```

If no prior tag:

```bash
git log --oneline
```

Display the commits grouped by type (`feat:`, `fix:`, `chore:`, `refactor:`, other).

---

## Step 4: Suggest semver bump

Read the grouped commits and apply these rules:

| Condition | Bump |
|-----------|------|
| Any commit contains `BREAKING CHANGE` or `!:` | major |
| Any `feat:` commit | minor |
| Only `fix:`, `chore:`, `refactor:`, `docs:` | patch |
| No commits since last tag | stop -- nothing to release |

If no prior tag: propose `v0.1.0` (first release) or ask the user.

Show the proposed version:

```
Last tag:  v0.6.0
Commits:   4 feat, 2 fix, 1 chore
Proposed:  v0.7.0 (minor bump)

Confirm? (enter to accept, or type a version to override)
```

Wait for input. Use the confirmed version for all subsequent steps.

---

## Step 5: Bump version file

If `version:` is set in the project config (not `none`):

Read the version file. Find the version string. Replace with the new version.

```bash
# package.json
jq '.version = "X.Y.Z"' package.json > package.json.tmp && mv package.json.tmp package.json

# pyproject.toml (sed approach -- exact match on version line)
sed -i '' 's/^version = ".*"/version = "X.Y.Z"/' pyproject.toml

# Cargo.toml
sed -i '' 's/^version = ".*"/version = "X.Y.Z"/' Cargo.toml
```

Read the file back to confirm the replacement took effect.

---

## Step 6: Update CHANGELOG.md (if configured)

If `changelog: true` in project config:

Prepend a new section to CHANGELOG.md:

```markdown
## vX.Y.Z -- YYYY-MM-DD

### Features
- <commit summary>

### Fixes
- <commit summary>

### Other
- <commit summary>
```

Group commits by type. Use the one-line commit summaries directly.

---

## Step 7: Commit the bump

If any files changed (version file or changelog):

```bash
git add <version file> [CHANGELOG.md]
git commit -m "chore: bump to vX.Y.Z"
git push
```

Stage only the version file and changelog. Nothing else.

---

## Step 8: Tag

```bash
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin vX.Y.Z
```

Annotated tags are required (`-a`). Lightweight tags are skipped by `git describe`.

---

## Step 9: Create GitHub release

```bash
gh release create vX.Y.Z --generate-notes --title "vX.Y.Z"
```

`--generate-notes` uses GitHub's built-in commit-to-release-notes generator. This is
the fastest path and produces consistent output. If the project has a `.github/release.yml`
configuration, GitHub honors it automatically.

Output the release URL. Done.

---

## Anti-Patterns

- Releasing from a feature branch. Releases come from the default branch after the PR merges.
- Tagging before bumping the version file. Readers of the tag should see the bumped version.
- Using a lightweight tag. `git describe` cannot find lightweight tags reliably across all git versions.
- Releasing with uncommitted changes. The release commit is clean: version bump only.
- Running `gh release create` before pushing the tag. GitHub cannot find a tag that does not exist on the remote.

## The Floor

A release is a named point in history. The sequence is not negotiable: version bump first,
tag second, push third, release fourth. Reversing or skipping any step produces a release
that does not match the code it claims to represent.
