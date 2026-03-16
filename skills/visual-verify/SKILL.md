---
name: visual-verify
description: Verify UI changes at element level before declaring any frontend work done. Full-page screenshots are forbidden for component verification.
version: 0.3.0
---

# Visual Verification

Element-level proof for every UI change. Full-page screenshots miss the bugs that matter.

## With ABP (default)

Every ABP tool call returns a screenshot automatically. You do not need to call `browser_screenshot` explicitly after every action. `browser_navigate`, `browser_wait`, `browser_action`, and `browser_javascript` all return a `screenshot` field in their response.

### The standard verification loop

```
1. browser_navigate(url)
2. browser_wait(animation=true)         # lets JS/fetch/SSE settle (required)
3. browser_javascript(getBoundingClientRect)   # get element coords
4. browser_screenshot(markup: ["clickable"])   # see what is interactive
5. crop to element bounds if needed (see below)
```

### Markup overlays

Request overlays to see interactive regions:

```
browser_screenshot(markup: ["clickable"])                        # green boxes on clickable elements
browser_screenshot(markup: ["typeable"])                         # orange boxes on inputs
browser_screenshot(markup: ["clickable", "typeable", "scrollable"])   # all three
```

**Do not use `["grid"]` for element verification.** The `grid` overlay captures the full physical screen: the browser window appears in the upper-left corner with desktop space around it. Every other overlay captures just the viewport. Grid coordinates do not map to DOM coordinates. Use `["clickable"]` or `["typeable"]` when you need element positions.

### What to check in the screenshot

- Are borders fully visible on all four sides?
- Is background color correct?
- Is text not truncated or overflowing its container?
- Is spacing correct on all sides?

### When you need a tighter crop

ABP returns full-viewport screenshots. For a 1px border or small component, get the bounding box from JS and crop:

```javascript
// browser_javascript
document.querySelector('.your-selector').getBoundingClientRect()
// returns: { x: 344, y: 227, width: 82, height: 19, ... }
```

DOM coordinates map 1:1 to viewport screenshot pixels. `window.innerWidth` equals the screenshot width exactly. No offset adjustment needed.

Crop and zoom with ImageMagick:

```bash
# W=width, H=height, X=left, Y=top from getBoundingClientRect
magick screenshot.webp -crop WxH+X+Y +repage -resize 300% zoomed.png
```

Read `zoomed.png` to inspect at 3x zoom.

### Diagnosing missing elements

When an element exists in the DOM but is not visible in the screenshot, inject a highlight before concluding it is broken:

```javascript
// browser_javascript
const el = document.querySelector('.your-selector');
el.style.background = 'red';
el.style.border = '3px solid yellow';
'highlighted'
```

Then take a screenshot. If still not visible, the element is hidden by z-index, clipping, or display:none, not a screenshot artifact.

## Without ABP (Playwright fallback)

If running with Playwright MCP instead of ABP, the manual path applies:

1. `browser_snapshot` to get the a11y tree and find the `ref` for your component
2. `browser_take_screenshot(element="...", ref="<ref>")` to crop to element bounds
3. If no ref exists: `browser_evaluate getBoundingClientRect` then ImageMagick crop

## The floor

Every UI fix is either visually confirmed or assumed. ABP eliminates the assumption by returning a screenshot on every tool call. Read it. If it shows the correct state, the work is done.
