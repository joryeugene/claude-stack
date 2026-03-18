---
name: browser-testing
description: Deep browser testing. Use when testing UI behavior, verifying network requests, checking console errors, filling forms, handling dialogs, or doing multi-tab testing. Covers MCP browser tools and the browse CLI.
---

# Browser Testing

Two tools for browser automation and inspection. Pick based on the project.

## Which tool?

| Situation | Use | Why |
|-----------|-----|-----|
| E2E test automation, form filling | Playwright MCP | Native tool calls, structured output |
| Network inspection, console monitoring | Chrome DevTools MCP | Real-time Chrome inspection |
| Rapid iteration, many sequential checks | browse CLI | Persistent daemon, 100ms per call |
| Accessibility tree snapshots, element refs | browse CLI | `@e1` refs with fast-fail on stale DOM |
| Cookie import from real browser session | browse CLI | Pulls from Chrome/Arc/Brave/Edge via macOS Keychain |
| Quick one-off screenshot or navigation | Either | Both work, MCP is zero-setup |

## Setup

**MCP tools** (zero build step):
```bash
mcp-use browser    # playwright + chrome-devtools -> .mcp.json
mcp-use playwright # playwright only
mcp-use chrome     # chrome-devtools only
```

Restart Claude Code after running to pick up the new `.mcp.json`.

**browse CLI** (persistent daemon, requires bun):
```bash
cd ${CLAUDE_PLUGIN_ROOT}/browse && ./setup
```

The binary lands at `${CLAUDE_PLUGIN_ROOT}/browse/dist/browse`. First call ~3s to launch Chromium; subsequent calls 100-200ms. Auto-shuts down after 30 minutes of inactivity.

---

## MCP tools: Playwright

When `mcp-use playwright` or `mcp-use browser` is active, the Playwright MCP server provides these tools:

**Navigation**
- `browser_navigate` - go to a URL
- `browser_go_back` / `browser_go_forward` - history navigation
- `browser_wait` - wait for page to settle

**Content reading**
- `browser_snapshot` - accessibility tree with element refs
- `browser_take_screenshot` - viewport or element screenshot
- `browser_get_text` - extract visible text

**Interaction**
- `browser_click` - click an element (by ref from snapshot)
- `browser_type` - type text into a field
- `browser_select_option` - select from dropdown
- `browser_hover` - hover over element
- `browser_press_key` - keyboard input (Enter, Tab, Escape, etc.)
- `browser_drag` - drag and drop

**Tabs**
- `browser_tab_list` - list open tabs
- `browser_tab_new` - open new tab
- `browser_tab_select` - switch tab
- `browser_tab_close` - close tab

### Standard test loop (Playwright MCP)

```
1. browser_navigate to the target URL
2. browser_snapshot to see initial state and get element refs
3. browser_click / browser_type to interact
4. browser_snapshot again to verify the DOM changed
5. browser_take_screenshot for visual proof
```

After page mutations, always re-snapshot before using element refs. Stale refs from a previous snapshot will target the wrong element.

---

## MCP tools: Chrome DevTools

When `mcp-use chrome` or `mcp-use browser` is active, the Chrome DevTools MCP server provides inspection tools for a running Chrome instance.

**Network**
- Capture and inspect network requests/responses
- View headers, status codes, timing, payload sizes

**Console**
- Read console messages (errors, warnings, logs)
- Evaluate JavaScript expressions in page context

**DOM**
- Inspect and query DOM nodes
- Get computed styles, element attributes

### When to use DevTools vs Playwright

Playwright drives a headless browser from scratch. Chrome DevTools attaches to an existing Chrome session. Use DevTools when you need to inspect a page that requires a real logged-in browser session, or when you need network-level detail that Playwright does not expose.

---

## browse CLI

The `browse` binary is a persistent Chromium daemon built on Playwright and Bun. Based on [gstack](https://github.com/garrytan/gstack) by Garry Tan (MIT).

**Navigation**
- `browse goto <url>` - navigate to URL
- `browse back` / `browse forward` - history
- `browse reload` - reload page
- `browse url` - print current URL

**Content reading**
- `browse text` - visible text content
- `browse html` - page HTML
- `browse links` - all links on page
- `browse forms` - all forms and their fields
- `browse accessibility` - accessibility tree

**Snapshots (element refs)**
- `browse snapshot` - accessibility tree with `@e1`, `@e2` element refs
- `browse snapshot -D` - diff mode (show what changed since last snapshot)
- `browse snapshot -i` - inline mode (compact output)
- `browse snapshot -c` - compact mode
- `browse snapshot -d N` - limit depth to N levels
- `browse snapshot -s <selector>` - scope to CSS selector

Element refs (`@e1`, `@e2`) are based on the accessibility tree, not DOM injection. They fail fast (~5ms) when the DOM has changed, instead of hanging for 30 seconds on a stale selector.

**Interaction**
- `browse click [selector|@ref]` - click an element
- `browse fill <selector|@ref> <text>` - fill a text input
- `browse select <selector|@ref> <value>` - select dropdown option
- `browse hover <selector|@ref>` - hover over element
- `browse type <text>` - type text into focused element
- `browse press <key>` - press a keyboard key (Enter, Tab, Escape, Shift+L, etc.)
- `browse scroll [direction] [amount]` - scroll the page
- `browse wait [selector|timeout]` - wait for element or duration
- `browse viewport <width> <height>` - resize viewport

**Debugging**
- `browse js <expression>` - execute JavaScript, returns value
- `browse console` - get console messages (errors, warnings, logs)
- `browse network` - list captured network requests
- `browse dialog` - check for and handle alert/confirm/prompt dialogs
- `browse cookies` - list cookies
- `browse storage` - inspect localStorage/sessionStorage
- `browse css <selector>` - computed styles for element
- `browse attrs <selector>` - element attributes

**Visual capture**
- `browse screenshot` - viewport screenshot
- `browse screenshot --clip <selector>` - cropped to element
- `browse responsive` - screenshots at multiple breakpoints

**Cookie/Auth import**
- `browse cookie-import <filepath>` - import cookies from JSON file
- `browse cookie-import-browser` - auto-import sessions from Chrome/Arc/Brave/Edge via macOS Keychain

**Tab management**
- `browse tabs` - list open tabs
- `browse tab <index>` - switch to tab
- `browse newtab [url]` - open new tab
- `browse closetab` - close current tab

### Standard test loop (browse CLI)

```
1. browse goto <url>
2. browse snapshot                # see initial state + get element refs
3. browse console                 # check for JS errors on load
4. browse js "DOM assertion"      # verify state before interacting
5. browse click @e3               # perform action
6. browse snapshot -D             # diff to see what changed
7. browse network                 # verify API calls fired
```

After page mutations, always re-snapshot before using element refs.

---

## Keyboard Testing

Keyboard handlers require real key simulation, not text injection.

### `press_key` vs `type_text`

| Tool | Behavior | Use when |
|------|----------|----------|
| `press_key` | Fires `keydown`, `keypress`, `keyup` events through DOM event flow | Testing keyboard shortcuts, overlay handlers, modal key dispatch |
| `type_text` | Injects text directly into focused element, bypassing DOM events | Filling form fields where you need the final value, not the event |

`type_text` bypasses the event listener chain entirely. A keyboard handler bug (undefined function, wrong dispatch, capture-phase conflict) will not surface with `type_text`. The handler never fires.

When testing keyboard shortcuts: always `press_key`. When filling an input field value: `type_text` is acceptable but `press_key` per character is more realistic.

### Keyboard test loop

```
1. Navigate to the page
2. Check console for JS errors (clean baseline)
3. press_key the shortcut
4. Check console again (catch ReferenceError, TypeError from handler)
5. Verify DOM changed (snapshot diff, js assertion, or element screenshot)
6. Test each sub-command within the overlay
7. press_key Escape to close
8. Verify overlay closed and page focus restored
```

### Common keyboard testing failures

| Failure | Symptom | Root cause |
|---------|---------|------------|
| Key does nothing | No console error, no DOM change | Key missing from dispatch logic |
| ReferenceError on keypress | Console shows undefined variable | JS references non-existent identifier |
| Overlay input broken | Cannot type in text fields | Capture-phase handler intercepts all keys without input element guard |

## What NOT to do

- Do not trust a single screenshot as proof. Verify with `js` or `snapshot` to confirm DOM state matches visual appearance.
- Do not use stale element refs after page mutations. Always re-snapshot to get fresh refs.
- Do not skip console checks after navigation. JS errors that break functionality are silent without checking.
- Do not use snapshot as the only verification. Combine with `js` for precise DOM assertions (class presence, attribute values, computed styles).
- Do not use `type_text` to test keyboard shortcuts. It bypasses event listeners entirely and hides real bugs. Use `press_key`.
