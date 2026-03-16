---
name: browser-testing
description: Deep browser testing with ABP (Agent Browser Protocol). Use when testing UI behavior, verifying network requests, checking console errors, filling forms, handling dialogs, or doing multi-tab testing. Covers the full ABP MCP tool inventory.
---

# Browser Testing with ABP

ABP (Agent Browser Protocol) is a Chromium fork with MCP baked into the engine. It exposes a complete browser testing toolkit, not just screenshots. This skill covers the full tool inventory.

## Tool inventory

**Navigation and screenshots**
- `browser_navigate(url)` - navigate to URL; also accepts `action: "back" | "forward" | "reload"`
- `browser_wait(animation)` - wait for network to settle, return screenshot. `animation=true` guarantees 5s of page execution for JS/CSS
- `browser_screenshot(markup, disable_markup)` - take screenshot with optional overlays

**Interaction**
- `browser_action(actions)` - click, type, keyboard press (1-3 actions per call, one screenshot returned)
- `browser_clear_text(x, y)` - clear an input field by focus + select-all + backspace
- `browser_scroll(x, y, scrolls)` - scroll with mouse wheel at coordinates
- `browser_slider(orientation, min, max, target_value, ...)` - move a range input to a value
- `browser_select_picker(popup_id, indices)` - choose from an open select dropdown
- `browser_dialog(action)` - handle alert / confirm / prompt dialogs

**DOM inspection**
- `browser_javascript(expression)` - execute JS, returns value and screenshot
- `browser_text(selector)` - get visible text content, optionally scoped to a CSS selector
- `browser_console(level, pattern, after_id)` - query buffered JS console messages

**Network**
- `browser_network(action, url, status, include_body, tag)` - query, save, or clear captured requests
- `browser_curl(tab_id, url, method, headers, body)` - HTTP request using the tab's session cookies

**Tabs and browser**
- `browser_tabs(action, tab_id, url)` - list, new, close, info, activate, stop
- `browser_get_status()` - check browser readiness
- `browser_shutdown()` - shut down ABP

**Files, downloads, permissions**
- `browser_files` - handle file upload inputs
- `browser_downloads` - query download state
- `respond_to_permission` - accept or deny browser permission prompts

---

## Standard test loop

```
1. browser_navigate(url)
2. browser_wait(animation=true)          # required: lets JS/SSE/fetch settle
3. browser_console(level="error")        # catch load-time JS errors
4. browser_javascript(DOM inspection)    # verify state before interacting
5. browser_action([click or type])
6. browser_wait()                        # wait for any triggered network calls
7. browser_network(action="query")       # verify the right API call fired
```

Every tool call returns a screenshot automatically. You do not need a separate `browser_screenshot` call after actions.

---

## Network inspection

ABP captures network requests on every action automatically.

```javascript
// After an action you expect to trigger a fetch:
browser_network({
  action: "query",
  path: "/api/v1/items",
  include_body: true
})
```

To preserve requests across multiple actions, tag them at the action level:

```javascript
browser_action({
  actions: [{ type: "mouse_click", x: 350, y: 200 }],
  network_tag: "submit-click"
})

// Later, query by tag:
browser_network({ action: "query", tag: "submit-click", include_body: true })
```

For authenticated API testing using the browser's session cookies:

```javascript
browser_curl({
  tab_id: "<tab_id from browser_tabs>",
  url: "https://app.example.com/api/me",
  method: "GET"
})
```

This fires the request with the same cookies the logged-in browser session holds. No manual auth headers needed.

---

## Console error checking

Check for JS errors immediately after page load and after significant interactions:

```javascript
browser_console({ level: "error" })
```

To check only for new errors since the last check, use `after_id`:

```javascript
// First call: note the highest id in the response
browser_console({ level: "error" })
// → returns entries with ids [1, 2, 3], note id=3

// Second call: only entries after id 3
browser_console({ level: "error", after_id: 3 })
```

Filter by pattern to find specific errors:

```javascript
browser_console({ level: "warning", pattern: "React" })
```

Run `browser_console(level="error")` before declaring any page "working."

---

## Form testing

**Text input (clear then type)**

```javascript
// 1. Clear the field
browser_clear_text({ x: 400, y: 300 })

// 2. Type the new value
browser_action({ actions: [{ type: "keyboard_type", text: "new value" }] })
```

**Select / dropdown**

Click the select to open it. The response events include a `select_open` event with a `popup_id`. Then:

```javascript
browser_select_picker({ popup_id: "<from event>", indices: [2] })
```

To cancel without selecting: `browser_select_picker({ popup_id: "...", cancel: true })`

**Range slider**

```javascript
browser_slider({
  orientation: "horizontal",
  y: 350,             // Y coordinate of track
  x_start: 100,       // left edge of track
  x_end: 500,         // right edge of track
  current_x: 220,     // current thumb position
  min: 0,
  max: 100,
  target_value: 75
})
```

If the slider has a non-linear scale or custom CSS, fall back to `browser_action` with `mouse_drag`.

**Dialogs (alert / confirm / prompt)**

After triggering an action that opens a dialog:

```javascript
browser_dialog({ action: "check" })             // is a dialog pending?
browser_dialog({ action: "accept" })            // click OK / confirm
browser_dialog({ action: "dismiss" })           // click Cancel
browser_dialog({ action: "accept", prompt_text: "my answer" })  // prompt input
```

---

## Multi-tab testing

```javascript
// Open a second tab
browser_tabs({ action: "new", url: "https://example.com/page2" })
// → returns tab_id for the new tab

// Act on a specific tab
browser_action({
  tab_id: "<new tab id>",
  actions: [{ type: "mouse_click", x: 300, y: 200 }]
})

// Switch focus to the new tab
browser_tabs({ action: "activate", tab_id: "<new tab id>" })

// List all open tabs
browser_tabs({ action: "list" })
```

All tools accept an optional `tab_id`. Omit it to target the active tab.

---

## Scroll handling

Before scrolling, check whether the page is scrollable:

```javascript
// From any action response:
scroll.pageHeight === scroll.viewportHeight   // true = no scrollable content, scroll is a no-op
```

To scroll:

```javascript
browser_scroll({
  x: 728,   // center of viewport
  y: 500,
  scrolls: [{ direction: "y", delta_px: 500 }]
})

// Scroll multiple viewports in one call (up to 3):
browser_scroll({
  x: 728, y: 500,
  scrolls: [
    { direction: "y", delta_px: 800 },
    { direction: "y", delta_px: 800 },
    { direction: "y", delta_px: 800 }
  ]
})
```

Each scroll in the array returns a separate screenshot.

---

## What NOT to do

- Do not use `["grid"]` markup when you need element coordinates for cropping. Grid captures the full physical screen, not just the viewport.
- Do not call `browser_scroll` without first checking `scroll.pageHeight === scroll.viewportHeight`. If they are equal, scrolling does nothing.
- Do not trust a single screenshot as proof. Verify with `browser_javascript` (getBoundingClientRect) or `browser_text` before concluding anything.
- Do not skip `browser_wait(animation=true)` after navigation. `browser_navigate` returns before JS executes. Without the wait, the page is blank or partially rendered.
- Do not call `browser_screenshot` repeatedly to wait for state changes. Use `browser_wait` to let the page settle, then check once.
