---
name: visual-verify
description: Verify UI changes at element level before declaring any frontend work done. Full-page screenshots are forbidden for component verification.
version: 0.4.0
---

# Visual Verification

Element-level proof for every UI change. Full-page screenshots miss the bugs that matter.

## With browse CLI

The `browse` command returns the accessibility tree with element refs (`@e1`, `@e2`). Use `screenshot --clip` to crop to a specific element, or `js` to inspect computed styles and bounding boxes.

### The standard verification loop

```
1. goto <url>
2. wait 2000                              # lets JS/fetch/SSE settle
3. js "document.querySelector('.target').getBoundingClientRect()"   # get element coords
4. snapshot -s ".target"                   # scoped snapshot of the component
5. screenshot --clip ".target"             # element-level screenshot
```

### What to check in the screenshot

- Are borders fully visible on all four sides?
- Is background color correct?
- Is text not truncated or overflowing its container?
- Is spacing correct on all sides?

### When you need a tighter crop

The browse CLI returns viewport-level screenshots by default. For a 1px border or small component, use `--clip`:

```
screenshot --clip ".your-selector"
```

Or get the bounding box from JS and crop with ImageMagick:

```javascript
// js command
document.querySelector('.your-selector').getBoundingClientRect()
// returns: { x: 344, y: 227, width: 82, height: 19, ... }
```

```bash
# W=width, H=height, X=left, Y=top from getBoundingClientRect
magick screenshot.png -crop WxH+X+Y +repage -resize 300% zoomed.png
```

Read `zoomed.png` to inspect at 3x zoom.

### Diagnosing missing elements

When an element exists in the DOM but is not visible in the screenshot, inject a highlight before concluding it is broken:

```javascript
// js command
const el = document.querySelector('.your-selector');
el.style.background = 'red';
el.style.border = '3px solid yellow';
'highlighted'
```

Then take a screenshot. If still not visible, the element is hidden by z-index, clipping, or display:none, not a screenshot artifact.

## The floor

Every UI fix is either visually confirmed or assumed. Element-level screenshots eliminate the assumption. Read it. If it shows the correct state, the work is done.
