---
name: visual-verify
description: Verify UI changes at element level before declaring any frontend work done. Full-page screenshots are forbidden for component verification.
---

# Visual Verification

Element-level proof for every UI change. Full-page screenshots miss the bugs that matter.

## With ABP (default)

ABP returns before and after screenshots on every action automatically. No extra calls needed.

Every navigate, click, type, or scroll returns:

```json
{
  "screenshot_before": { "data": "base64...", "width": 1280, "height": 720 },
  "screenshot_after":  { "data": "base64...", "width": 1280, "height": 720 },
  "events": [],
  "timing": { "duration_ms": 50 }
}
```

Use `screenshot_after` as your verification evidence. Request element markup to see interactive regions:

```
browser_screenshot with markup: "interactive"
```

This draws bounding boxes around clickable and typeable elements directly in the image.

### What to check in the screenshot

- Are borders fully visible on all four sides?
- Is background color correct?
- Is text not truncated or overflowing its container?
- Is spacing correct on all sides?
- Does the component look the same before and after unrelated actions?

### When you need a tighter crop

ABP returns full-viewport screenshots. For a 1px border or small component, get the bounding box first:

```
browser_execute: document.querySelector('.your-selector').getBoundingClientRect()
```

Request a screenshot with a grid overlay to verify exact coordinates:

```
browser_screenshot with markup: ["grid", "clickable"]
```

Crop and zoom with ImageMagick if needed:

```bash
magick screenshot.webp -crop WxH+X+Y +repage -resize 300% zoomed.png
```

## Without ABP (Playwright fallback)

If running with Playwright MCP instead of ABP, the manual path applies:

1. `browser_snapshot` to get the a11y tree and find the `ref` for your component
2. `browser_take_screenshot(element="...", ref="<ref>")` to crop to element bounds
3. If no ref exists: `browser_evaluate getBoundingClientRect` then ImageMagick crop

## The floor

Every UI fix is either visually confirmed or assumed. ABP eliminates the assumption by returning the post-action state automatically. Read `screenshot_after`. If it shows the correct state, the work is done.
