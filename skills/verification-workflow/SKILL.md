---
name: verification-workflow
description: After every code change, follow this cycle: validate assumptions, make change, prove it works, show evidence.
---

# Verification Workflow

Every code change follows this cycle: validate assumptions, make change, prove it works, show evidence.

## Pre-Change: Validate Assumptions

Before writing any code:

- curl the API endpoint you'll call and get actual field names
- Read the ENTIRE file you'll modify (don't assume structure)
- Verify commands exist (`which`, `--version`) before using them
- Check types match expectations (don't over-engineer from imagination)

## During Change: One at a Time

- Make one change, verify, then make the next change
- Never batch 5 changes and test all at once
- If you can't test incrementally, stop and figure out how

## Post-Change: Prove It Works

For every change, show:

1. **Command run:** the exact command executed
2. **Actual output:** paste the real output (not "should work")
3. **Success indicator:** "All tests passed" or "Build successful"

Encode the verified behavior as a permanent test with `/tdd` so the proof survives future sessions.

## Evidence Standards

- BANNED: "should work", "looks correct", "appears working"
- REQUIRED: "WILL work because [show exact field mapping + data + proof]"
- Every claim needs: API response + code reference + expected output
- If you haven't seen it work, don't claim it works

## Per-Change-Type Verification

Different changes require different proof. Generic "run tests" is not enough.

| Change type | Minimum proof |
|-------------|---------------|
| API endpoint | `curl` before and after. Compare field names, status codes, and response shape. |
| Database query | `EXPLAIN ANALYZE` before and after. Compare rows scanned and plan type. |
| Database schema | Query the table post-migration. Confirm expected columns, types, and row count. |
| UI component | Element-level screenshot (not full-page). See `/visual-verify`. |
| Keyboard shortcut | `press_key` in browser (not `type_text`). Check console for errors after each key. Verify DOM changed. |
| Overlay/modal | Open with key, test every sub-command, test text input fields, close with Escape. Console clean throughout. |
| Inline JS in Python | Run `check-js-refs` or equivalent structural check. Every called function and referenced variable must resolve. |
| CLI command | `<command> 2>&1; echo "Exit: $?"`. Both stdout and exit code must be shown. |
| File write | Read the file back immediately after. Verify the content matches intent. |
| Test change | Run the full test suite. Show pass/fail counts and any new failures. |
| Build artifact | Confirm the artifact exists with expected size. Run a smoke test against it. |
| Config change | Show the running process or service has picked up the new value. |

Empty output is not success. If a command produces no output, check the exit code and the code path. See the BANNED pattern: "Ignoring empty output."

## UI Feature Verification

Pytest passing does not prove a UI feature works. Unit tests verify API endpoints and data logic. They cannot verify that a keyboard shortcut opens an overlay, that text input works inside that overlay, or that the JS function names are correct.

After any change to keyboard handlers, overlays, or frontend JS:

1. **Rebuild the binary** from source (not cached). The running binary is a snapshot.
2. **Restart the server** and verify it responds.
3. **Open the page in a real browser** (Chrome DevTools MCP or browse CLI).
4. **Check console** for JS errors on load (clean baseline).
5. **Press each key** with `press_key` (never `type_text` for shortcut testing).
6. **Check console after each key press.** A ReferenceError means the handler references a non-existent JS identifier. No error and no DOM change means the key is not in the dispatch logic.
7. **Test every sub-command** within overlays. Opening the overlay is not enough.
8. **Test text input fields** inside overlays. If typing does not work, the keyboard handler is intercepting keystrokes meant for the input element.

A feature that passes pytest but has not been browser-tested with real key presses is unverified.

## Goal-Backward Verification

Task completion does not equal goal achievement. A task marked done can represent a placeholder, a partial implementation, or a file that was created but never wired in. The goal may still be unmet.

When verifying a feature or phase: start from the goal, not the task list.

1. **State the goal** in one sentence: what property should now be true about the system?
2. **Work backward**: what must exist in the codebase for that property to hold? What must be wired?
3. **Check each level against the actual code**, not against your summary of what you did.

Do not trust your own summaries. Summaries record what you intended or believed you did. The codebase records what actually happened. Check the codebase.

Common failure: executor completed all tasks, wrote a summary, but the feature is not reachable because the route was never registered, the handler was never connected, or the function was called with the wrong argument. Task list: complete. Goal: not achieved.

## When You Can't Verify

Say explicitly: "I cannot verify this works because [reason]. Please verify by running [command]."
Never claim success without proof. Never use checkmarks without testing.

## Anti-Patterns

- **Batch verification:** Making 5 changes then testing all at once. When something breaks, you don't know which change caused it.
- **Defensive imagination:** "The API might return X or Y, so handle both." Check what it actually returns first.
- **Claiming success without testing:** Using checkmarks or "looks correct" without running the code.
- **Complex investigation before simple checks:** Launching a full debugging plan when the issue is a typo in a field name.
- **Repeating failed approaches:** If an approach fails, analyze why before retrying the same thing.

## The Floor

Every code change is either verified or unverified. There is no middle ground. "Looks correct" and "should work" are unverified claims. Verified means a command was run, output was observed, and the output matched expectation. The discipline of showing evidence after every change is not overhead. It is the only way to know whether the work is done.
