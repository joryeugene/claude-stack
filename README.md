# claude-stack

Skills alone make Claude better at tasks. This makes Claude better at engineering.

---

## Three layers

```
                    claude-stack
                          |
        +-----------------+-----------------+
        |                 |                 |
   CLAUDE.md           hooks/            skills/
  (philosophy)       (enforcement)      (workflow)
  always loaded      always fires       on demand
        |                 |                 |
        +-----------------+-----------------+
                          |
             ./setup installs all three
```

MCP servers extend what Claude can reach. `mcp-use` manages them per-project.

**Philosophy** (`CLAUDE.md`) defines how Claude reasons: the Tripod (antifragile, simple, research-first), the Contract (total saturation, no shortcuts), and the Error Recovery Protocol.

**Enforcement** (`hooks/`) makes rules structural. A rule in CLAUDE.md is a suggestion. A hook is a hard constraint. The wrong pattern becomes structurally impossible, not just discouraged.

**Skills** (`skills/`) give Claude the right cognitive mode for each moment in the workflow.

---

## Why three layers

Most Claude Code setups are skills-only. Skills are cognitive suggestions. Claude receives them as context, weighs them probabilistically, and may or may not follow them. A skill that says "don't use em-dashes" works until it doesn't.

A hook that blocks em-dashes at the file write level is a different category of thing. It cannot be forgotten. It cannot be deprioritized mid-session. It fires before the tool call completes.

CLAUDE.md works at a third level: it changes how Claude frames problems before any decision is made. The Tripod (antifragile, simple, research-first) runs before architecture, before implementation, before choosing what to build. Skills change what Claude does. CLAUDE.md changes how Claude thinks.

The three layers are not additive. They are multiplicative. Each one makes the other two more effective.

MCP servers are a different category. The three layers shape how Claude behaves within a session. MCPs extend what the session can see. Two in particular are substrate rather than tooling: [gitmcp](https://gitmcp.io) eliminates the knowledge cutoff by fetching live docs from any GitHub repo, and [keephive](https://github.com/joryeugene/keephive) eliminates statelessness by persisting memory, decisions, and knowledge across sessions. The three layers work on whatever Claude can access. These two expand what that is.

---

## Install

```bash
git clone https://github.com/joryeugene/claude-stack.git ~/.claude/skills/claude-stack
cd ~/.claude/skills/claude-stack
./setup
```

Then register the hooks in `~/.claude/settings.json`. See `settings.json.example`.

Set the environment variables (recommended): see `env.sh.example`.

### mcp-use

Every MCP server loaded in a session costs context: tool schemas inject at startup, and every call response adds more. A single browser MCP adds thousands of tokens before any work begins. Loading six MCPs globally because you might need them is a different thing from loading two because this project needs them.

Skills are loaded on demand and cost almost nothing. MCP servers load at session start and stay loaded. A project that needs browser automation should have the browser MCP; a backend CLI project should not. `mcp-use` makes per-project MCP composition a one-command operation rather than editing JSON by hand each time.

`./setup` installs `mcp-use` to `~/.local/bin/mcp-use` and copies the presets to `~/.config/mcp-presets/` (only if they don't already exist, so local customizations are preserved).

From any project directory:

```bash
mcp-use                      # list available presets
mcp-use best                 # .mcp.json <- gitmcp + hive (foundation)
mcp-use browser              # .mcp.json <- ABP (deterministic browser automation)
mcp-use ui                   # .mcp.json <- ABP + shadcn
mcp-use browser workspace    # .mcp.json <- ABP + Google Workspace (merged)
mcp-use all                  # .mcp.json <- everything
```

`best` is the foundation preset. It adds two servers that belong in every project:

- **gitmcp** - fetches live documentation from any GitHub repo. Claude's training ends at August 2025; the libraries you use do not. Ask Claude to look up current docs and it reads them directly.
- **hive** ([keephive](https://github.com/joryeugene/keephive)) - persistent memory across sessions. Facts, decisions, TODOs, and knowledge guides survive between conversations. Claude builds on prior work instead of starting from zero every time.

Both are global servers: install once, available in all sessions.

```bash
# gitmcp
claude mcp add --scope user gitmcp -- npx mcp-remote https://gitmcp.io/docs

# hive (requires keephive installed first)
uv tool install keephive
claude mcp add --scope user hive -- keephive mcp-serve
```

To use `mcp-use` as a shell function instead of a binary, source it from your shell profile:

```bash
source ~/.claude/skills/claude-stack/scripts/mcp-use.sh
```

Add your own presets to `~/.config/mcp-presets/<name>.json` and they appear automatically in `mcp-use`.

---

## The workflow

```
  project starts
       |
       v
   /plan-mode  ------- CEO: is this the right problem?
       |                Eng: can we build it safely?
       |
   coding begins
       |
       +--- /debugging-protocol ----- something broken?
       |                              schema first, trace back
       |
       +--- /verification-workflow -- after every change:
       |                              prove it works, show evidence
       |
       +--- /testing-strategy ------- writing tests?
       |                              make them catch real bugs
       |
       +--- /code-hygiene ----------- AI sessions are stateless.
       |                              keep the codebase clean.
       |
       |   (building UI?)
       +--- /impeccable-design ------ visual identity before a line of code
       +--- /visual-verify ---------- element-level proof after UI changes
       +--- /browser-testing -------- network, console, forms, multi-tab
       |
   ready to ship
       |
       v
   /pre-ship ---------- paranoid check: what does CI miss?
       |
       v
   /ship-pipeline ----- merge, test, review, commit, push, PR


  always active (no invocation needed)

   /agent-principles      the quality contract: evidence, schema-first, no hedging
   /hooks-guide           teaches you to build your own enforcement layer
   /agent-orchestration   parallel agents for independent work streams
```

---

## The hooks

Five hooks ship with claude-stack. All run on `PreToolUse`.

| Hook | Blocks | Why |
|------|--------|-----|
| `block-unicode-dashes.py` | Em-dashes, en-dashes, double-hyphen substitutes in written files | Prose quality rule made structurally impossible |
| `block-co-authored-by.py` | Claude attribution lines in git commits | Claude Code hardcodes this into every commit message. This hook removes it. |
| `block-git-stash.py` | `git stash` in any form | Destroys other agents' working state. Structurally absent, not just discouraged. |
| `block-no-verify.py` | `--no-verify` in git commands | Bypassing hooks defeats the enforcement layer. Fix the root cause instead. |
| `block-tmp-files.py` | Writes to `/tmp/` and `mktemp` | Files in /tmp are silently lost on cleanup. Write to the project directory. |

Register all five in `~/.claude/settings.json`. See `settings.json.example`.

---

## The skills

Each skill owns one moment in the workflow. Invoke with `/skill-name` in Claude Code.

| Skill | When to use |
|-------|-------------|
| `/agent-principles` | Always active reference. The quality contract. |
| `/hooks-guide` | Learning to write your own enforcement hooks. |
| `/agent-orchestration` | Parallel agents for independent work streams. Task tool and agent teams. |
| `/plan-mode` | Before any significant work. CEO mode or Eng mode. |
| `/debugging-protocol` | Something isn't working. Schema first, trace back. |
| `/verification-workflow` | After a code change. Prove it works before moving on. |
| `/testing-strategy` | Writing tests. Make them fail when code breaks. |
| `/code-hygiene` | Reviewing AI-session debt: dead exports, duplicate logic, orphaned types. |
| `/impeccable-design` | Starting UI work. Visual identity before writing code. |
| `/visual-verify` | After UI changes. ABP returns a screenshot on every action automatically; this skill tells you what to read. |
| `/browser-testing` | Deep browser testing with ABP. Network inspection, console errors, forms, multi-tab, authenticated API calls. |
| `/pre-ship` | Before shipping. Paranoid check for the bugs CI misses. |
| `/ship-pipeline` | Shipping. Merge, test, review, commit, push, PR. |

---

## CLAUDE.md

`CLAUDE.md` is the operating spec. It defines three things:

1. **The Tripod** - root philosophy that governs every design decision
2. **The Contract** - rigor standards (total saturation, no shortcuts, adversarial thinking)
3. **Forbidden Patterns** - antifragile list of banned behaviors; grows with every failure

Adapt it for your stack:

**Keep as-is:** The Tripod, the Contract, Error Recovery Protocol, the absolute BANNED tier.

**Customize:** The Quick Reference trigger table (add your tools and workflows). The Forbidden Patterns anti-patterns tier (add failure patterns you encounter). The Prose Quality Standards are optional if you don't write prose with Claude.

Place the file at `~/.claude/CLAUDE.md` for global effect, or at the project root for project-specific behavior.

---

## Environment

Claude Code exposes environment variables that significantly change its behavior. These are set before a session starts. See `env.sh.example` for the full list with explanations.

Key variables:

| Variable | Value | Effect |
|----------|-------|--------|
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | `65536` | Prevents response truncation on long outputs |
| `BASH_DEFAULT_TIMEOUT_MS` | `300000` | 5-minute default; prevents premature kills |
| `BASH_MAX_OUTPUT_LENGTH` | `100000` | Captures full output from verbose commands |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | Enables parallel agent spawning |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | `80` | Compacts at 80% context, not 95% |
| `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` | `1` | Shell cwd persists across tool calls |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | `1` | No telemetry pings during sessions |
| `BASH_MAX_TIMEOUT_MS` | `600000` | 10-minute ceiling for long-running operations |
| `MAX_MCP_OUTPUT_TOKENS` | `50000` | Prevents MCP servers from flooding context with verbose output |
| `DISABLE_COST_WARNINGS` | `1` | Silences cost warnings (useful on Max plan) |
| `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY` | `1` | Silences periodic feedback survey prompts |

Two ways to apply: source `env.sh.example` from your shell profile, or copy the variables into `~/.claude/settings.json` under the `env` key (recommended: settings.json approach applies at session start without shell config changes).

### Statusline

`statusline.sh` provides a compact Claude Code status display: current directory, git branch, context usage percentage, active plan, model, and subscription tier. Wire it into `settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/statusline.sh"
}
```

---

## Adding your own hooks

The `/hooks-guide` skill covers this in full. The short version:

1. Write a Python script that reads tool input from stdin (JSON)
2. Print a block decision to stderr and exit 2 to block the tool call
3. Exit 0 to allow it
4. Register in `~/.claude/settings.json` under `hooks > PreToolUse`

The `block-unicode-dashes.py` hook is a readable reference for the pattern.

---

## Extending with more skills

Drop any directory with a `SKILL.md` into `skills/`. Re-run `./setup` to symlink it.

Skill files are markdown with a YAML frontmatter block:

```markdown
---
name: my-skill
description: One sentence. Claude uses this to decide when to load the skill.
---

# Skill content here
```

---

## Browser automation

The `browser` preset ships [Agent Browser Protocol](https://github.com/theredsix/agent-browser-protocol) (ABP), a Chromium fork with MCP baked into the engine.

Why ABP instead of Playwright or chrome-devtools:

- **Step machine semantics**: JS and virtual time freeze between agent actions. The page waits for the agent, not the other way around.
- **Automatic screenshots**: every action returns a screenshot. No extra calls needed.
- **Native input**: events go through Chromium's actual input system, not CDP synthetic dispatch.
- **~100ms overhead per action**: the bottleneck is the LLM, not the browser.

```bash
mcp-use browser   # adds ABP to .mcp.json
```

Set `ABP_HEADLESS=1` to run without a visible window (CI, background verification).

---

## keephive

[keephive](https://github.com/joryeugene/keephive) is the memory layer for Claude Code. It pairs directly with claude-stack.

Claude Code sessions are stateless. Each conversation starts from zero. keephive fixes this: a background process captures facts, decisions, and TODOs during sessions, stores them in a structured daily log, and injects the relevant context back into future sessions via the `hive` MCP server.

What it provides:

- `hive_remember` - save a fact, decision, or TODO from the current session
- `hive_recall` - search accumulated knowledge from all past sessions
- `hive_status` - see what's pending, what's stale, what needs attention
- Knowledge guides - reusable markdown files Claude loads when working in a specific domain
- The KingBee daemon - background agent that verifies stale facts, drafts standups, and surfaces patterns across sessions

Install:

```bash
uv tool install keephive
claude mcp add --scope user hive -- keephive mcp-serve
keephive setup   # registers hooks in ~/.claude/settings.json
```

The `best` preset (`mcp-use best`) adds the `hive` server to any project's `.mcp.json`.
