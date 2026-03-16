---
name: browser-testing
description: Deep browser testing with gstack. Use when testing UI behavior, verifying network requests, checking console errors, filling forms, handling dialogs, or doing multi-tab testing. Covers the full gstack command inventory.
---

# Browser Testing with gstack

[gstack](https://github.com/garrytan/gstack) is a persistent Chromium daemon built on Playwright and Bun by Garry Tan. It exposes a complete browser testing toolkit through a CLI binary. No MCP protocol, no token overhead from protocol framing. First call takes ~3 seconds to launch Chromium; subsequent calls take 100-200ms. Auto-shuts down after 30 minutes of inactivity.

## Installation

The `browse` binary is bundled with claude-stack at `${CLAUDE_PLUGIN_ROOT}/skills/gstack/browse/dist/browse`. No separate installation needed. Requires [bun](https://bun.sh) v1.0+ (for the Playwright daemon).

## Command reference

**Navigation**
- `goto <url>` - navigate to URL
- `back` - go back
- `forward` - go forward
- `reload` - reload page
- `url` - print current URL

**Content reading**
- `text` - get visible text content
- `html` - get page HTML
- `links` - list all links on page
- `forms` - list all forms and their fields
- `accessibility` - get accessibility tree

**Snapshots (element refs)**
- `snapshot` - get accessibility tree with `@e1`, `@e2` element refs
- `snapshot -i` - inline mode (compact output)
- `snapshot -c` - compact mode
- `snapshot -d N` - limit depth to N levels
- `snapshot -s <selector>` - scope to CSS selector
- `snapshot -D` - diff mode (show what changed since last snapshot)
- `snapshot -a` - annotate mode

Element refs (`@e1`, `@e2`) are based on the accessibility tree, not DOM injection. They fail fast (~5ms) when the DOM has changed, instead of hanging for 30 seconds on a stale selector.

**Interaction**
- `click [selector|@ref]` - click an element
- `fill <selector|@ref> <text>` - fill a text input
- `select <selector|@ref> <value>` - select dropdown option
- `hover <selector|@ref>` - hover over element
- `type <text>` - type text into focused element
- `press <key>` - press a keyboard key (Enter, Tab, Escape, j, l, Shift+L, etc.)
- `scroll [direction] [amount]` - scroll the page
- `wait [selector|timeout]` - wait for element or duration
- `viewport <width> <height>` - resize viewport
- `upload <selector> <filepath>` - upload file to input

**Debugging**
- `js <expression>` - execute JavaScript, returns value
- `eval <filepath>` - evaluate a JS file
- `css <selector>` - get computed styles for element
- `attrs <selector>` - get element attributes
- `is <selector> <state>` - check if element is visible, enabled, checked, etc.
- `console` - get console messages (errors, warnings, logs)
- `network` - list captured network requests
- `dialog` - check for and handle alert/confirm/prompt dialogs
- `cookies` - list cookies
- `storage` - inspect localStorage/sessionStorage
- `perf` - performance metrics

**Visual capture**
- `screenshot` - take viewport screenshot
- `screenshot --viewport <w>x<h>` - screenshot at specific size
- `screenshot --clip <selector>` - screenshot cropped to element
- `pdf` - save page as PDF
- `responsive` - screenshots at multiple breakpoints

**Cookie/Auth import**
- `cookie-import <filepath>` - import cookies from JSON file
- `cookie-import-browser` - auto-import sessions from Chrome/Arc/Brave/Edge via macOS Keychain

**Tab management**
- `tabs` - list open tabs
- `tab <index>` - switch to tab by index
- `newtab [url]` - open new tab
- `closetab` - close current tab

---

## Standard test loop

```
1. goto <url>
2. snapshot                    # see initial state + get element refs
3. console                    # check for JS errors on load
4. js "DOM assertion"         # verify state before interacting
5. click @e3 / press Enter    # perform action
6. snapshot -D                # diff to see what changed
7. network                    # verify API calls fired
```

After page mutations (clicks, form submissions, navigation), always re-snapshot before using element refs. Stale refs from a previous snapshot will fail fast with an error rather than silently targeting the wrong element.

---

## Network inspection

Check which API calls fired after an action:

```
network
```

For authenticated API testing, use `cookie-import-browser` to pull your real browser session, then `goto` the authenticated page directly.

---

## Console error checking

Check for JS errors immediately after page load and after significant interactions:

```
console
```

Run `console` before declaring any page "working."

---

## Form testing

**Text input (clear then fill)**

```
fill @e5 "new value"
```

Or with a CSS selector:

```
fill "#email" "user@example.com"
```

**Select / dropdown**

```
select @e7 "Option B"
```

**Keyboard shortcuts**

```
press j           # single key
press Shift+L     # modifier + key
press Enter       # submit
press Escape      # dismiss
press Tab         # focus next
```

**Dialogs (alert / confirm / prompt)**

```
dialog                 # check if dialog is pending
dialog accept          # click OK
dialog dismiss         # click Cancel
```

---

## Multi-tab testing

```
newtab https://example.com/page2
tabs                   # list all open tabs
tab 1                  # switch to tab by index
closetab               # close current tab
```

---

## What NOT to do

- Do not trust a single screenshot as proof. Verify with `js` or `snapshot` to confirm DOM state matches visual appearance.
- Do not use stale `@ref` element refs after page mutations. Always re-snapshot to get fresh refs.
- Do not skip `console` after navigation. JS errors that break functionality are silent without checking.
- Do not use `snapshot` as the only verification. Combine with `js` for precise DOM assertions (class presence, attribute values, computed styles).
- Do not poll with repeated `screenshot` calls. Use `wait` to let the page settle, then check once.

---

## Credit

Built by [Garry Tan](https://github.com/garrytan). Persistent Chromium daemon, Playwright locators, Bun compiled binary, accessibility tree element refs.
