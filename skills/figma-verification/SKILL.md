---
name: figma-verification
description: Extract Figma design specs before implementing UI components. Use depth 5, cache to disk, extract ALL properties, map to design system tokens.
---

# Figma-to-Code Verification Skill

---

## Section 0.0: MANDATORY: Read Local Spec Files BEFORE Any Figma Call

**THIS IS THE ABSOLUTE FIRST STEP. Before fetching ANY Figma node data or writing ANY code:**

### The Rule

If a feature has local spec files (design docs, reference images, HTML mockups), you MUST read ALL of them first. Figma fetching is a complement to local specs, not a replacement.

### How to Find Spec Files

Run these globs from the project root before starting any UI work:

```bash
# Check for feature-specific spec docs
ls prompt.md *.md DRAFT*.html 2>/dev/null
# Check for reference images
ls images/*.png images/*.jpg 2>/dev/null | head -20
# Check for cached Figma node specs
ls .plans/figma/*.yaml .plans/*.md 2>/dev/null
```

### What to Read (in order)

1. **`prompt.md`** (or equivalent feature spec) - Figma file key, node IDs, design instructions
2. **ALL `images/image*.png`** - Reference screenshots showing every state of the UI
3. **`DRAFT*.html`** - HTML mockups showing intended structure
4. **`.plans/figma/*.yaml`** - Previously cached Figma node data

### Why This Matters

Figma node data (depth 5) gives you CSS values but NOT design intent. Reference images show:
- Which views exist and their default state
- Layout relationships (e.g., breadcrumb inside content, not above sidebar)
- Exact label text (e.g., "Needs Review" not "Pending")
- Which elements appear on ALL views (e.g., "Create Prompt" button)
- Icon treatments (e.g., filled blue circle, not outline Info icon)

**NEVER start implementing based on Figma data alone when local images exist.**

### Enforcement

Before writing a single line of implementation code:
- [ ] Globbed for spec files
- [ ] Read feature spec (prompt.md or equivalent)
- [ ] Read ALL reference images
- [ ] Read HTML mockups if present
- [ ] THEN proceed to Figma extraction (Section 1)

---

**Use this skill BEFORE implementing ANY UI component from Figma.**

---

## Section 0: ZERO INVENTION: Extract, Never Invent

**THIS IS THE #1 RULE. Every detail comes from the Figma node data or it does not exist.**

### The Rule

If a property, label, text, dimension, color, or layout detail is NOT present in the Figma node tree + globalVars.styles, it DOES NOT go into the code. Period.

### What This Means

- **Text content**: Only use text that appears as `text:` values in Figma TEXT nodes. Do NOT invent labels, headers, or descriptions that aren't in the node tree.
- **Dimensions**: Only use widths/heights from `layout` dimensions or `sizing` properties. If `sizing.horizontal: fixed` but no `dimensions.width`, measure from the screenshot or ask. Do not guess.
- **Colors**: Only use colors resolved through globalVars.styles. Do NOT assume a color from memory.
- **Layout structure**: Only use the structure visible in the Figma node tree children. Do NOT add wrapper divs, labels, or sections that aren't there.
- **Min/max widths**: If the Figma node shows `sizing.horizontal: fixed`, the tooltip/element has a set width. Extract it or measure it. Do not skip it.

### Enforcement Checklist

Before writing ANY code that renders Figma-designed content:

1. **List every TEXT node** from the Figma response for that component
2. **List every child FRAME** - these define the HTML structure
3. **For each text node**: extract `text:` value, `textStyle`, `fills` from globalVars.styles
4. **For each frame**: extract `layout` (mode, gap, padding, sizing, dimensions)
5. **Write ONLY what the list says**, nothing more, nothing less

If something seems missing from Figma (like a label you think should be there), it means the design intentionally omits it. Do NOT add it.

---

## Section 0.1: Mandatory Child Decomposition

**For every FRAME node with children, list EACH child and map it to a separate code element.**

### Process

1. **List every child**: type, name, fill (resolved from globalVars.styles), layout, sizing
2. **Build a ROLE TABLE** documenting what each child does visually
3. **Map each child to a separate code element**
4. **Verify**: does the code have one element per Figma child? If not, something is missing.

### Role Table Template

```
| Child | Type | Fill (Resolved) | Role | Code Element |
|-------|------|----------------|------|-------------|
| Label | TEXT | #171717 | Percentage label | ECharts label config |
| Bar top | RECT | #0858C9 | 3px cap line | Custom rect in renderItem |
| Bar background | RECT | rgba(8,88,201,0.1) | Bar body fill | Custom rect in renderItem |
```

**If code only has ONE bar element but Figma has THREE children, TWO children are missing.**

### Why This Matters

The #1 failure mode in Figma implementation is treating a multi-child FRAME as a single element:
- A "Bar" frame with 3 children is NOT one bar element
- It's a label + cap line + body, each rendered separately
- Missing children = wrong visual output (e.g., solid bar instead of cap + light body)

---

## Section 0.2: State Variant Detection

**When the same component appears multiple times, compare fills to detect state variants.**

### Process

1. Find all instances of the same component (e.g., 7 bars in a chart)
2. Compare fill references across instances for the same-position child
3. Different fills on same-position children = state variants (hover, active, disabled)
4. Document EVERY variant as a separate state in the spec

### Example

7 bars in a chart. First bar has `fill_234G9H` (rgba 0.5), others have `fill_H75A7S` (rgba 0.1):
- First bar = **hover state** (more opaque fill + hand cursor)
- Other bars = **normal state** (light fill)

```
| State | Trigger | Fill (Body) | Fill (Cap) | Cursor |
|-------|---------|------------|-----------|--------|
| Normal | - | rgba(8,88,201,0.1) | #0858C9 | default |
| Hover | mouseover | rgba(8,88,201,0.5) | #0858C9 | pointer |
```

### Common Indicators

- **Different opacity** on same child = hover/active state
- **Shadow/effect** on one instance = hover/focus state
- **Different text color** on one instance = selected/active state
- **Cursor icon** (hand) visible in Figma = interactive element

---

## Section 1: Cache to Disk FIRST

**Every Figma fetch MUST be saved to `.figma-cache/specs/` immediately. No exceptions.**

### Cache Directory Structure

```
.figma-cache/
├── {fileKey}-{nodeId}.json              # Raw Figma data (full response)
├── pages/                               # Figma page screenshots
│   ├── 01-topics-default.png
│   └── 07-dialog-cluster-detail.png
└── specs/                               # Extracted component specs (YAML)
    ├── tooltip-{nodeId}.yaml
    ├── dialog-{nodeId}.yaml
    └── treemap-card-{nodeId}.yaml
```

### Cache Protocol

1. **Before any Figma MCP call**, check if cached data exists:
   ```bash
   ls .figma-cache/{fileKey}-{nodeId}.json
   ```

2. **After every Figma MCP call**, immediately save to disk:
   - Raw JSON response: `.figma-cache/{fileKey}-{nodeId}.json`
   - Extracted specs: `.figma-cache/specs/{component}-{nodeId}.yaml`

3. **YAML spec format** (one per component):
   ```yaml
   node_id: "6174:45962"
   node_name: "Tooltip Card"
   fetched_at: "2026-02-12"
   global_vars_styles:
     style_7TVKOF: { fontFamily: "Inter", fontWeight: 500, fontSize: 12 }
     fill_JVA1MH: "#FFFFFF"
     layout_GHLSY6: { mode: "column", gap: 4, padding: [8,8,8,8] }
   ```

4. **7-day TTL** on cache. Older than 7 days = refetch.

### Why Cache First?

- Reduces Figma API calls by 80%
- Creates a permanent audit trail of specs
- Allows offline comparison without re-fetching
- The YAML specs become the source of truth for code review

---

## Section 2: globalVars.styles is the Source of Truth

**The node tree shows reference IDs, NOT actual values. The `globalVars.styles` section resolves all IDs to real CSS values.**

### How Figma Data Works

When you fetch a node at depth 5, the response has two sections:

1. **Node tree**: shows the component hierarchy with style reference IDs:
   ```
   TEXT "Total FTEs"
     style: style_A5AX5F
     fills: [fill_X10KHO]
   ```

2. **globalVars.styles**: resolves every reference ID to actual values:
   ```
   style_A5AX5F: { fontFamily: "Inter", fontWeight: 600, fontSize: 14 }
   fill_X10KHO: "#565656"
   ```

### The Mapping Workflow

**Step 1**: Find the element in the node tree
**Step 2**: Note the reference ID (e.g., `fill_X10KHO`)
**Step 3**: Look up the ID in `globalVars.styles`
**Step 4**: Get the actual value (`#565656`)
**Step 5**: Map to Tailwind token (`text-muted-foreground`)

### Common Mistake

Reading the node tree and seeing `style: style_A5AX5F` then guessing the values. The node tree alone tells you NOTHING about actual colors, sizes, or fonts. You MUST cross-reference with `globalVars.styles`.

---

## Section 3: Structured Pixel Verification Protocol

**No "looks correct" allowed. Every property must be checked programmatically.**

### Mandatory Comparison Table

Before writing any code, build this table for EVERY element:

```
| Element             | Figma Spec              | Current Code            | Match? |
|---------------------|-------------------------|-------------------------|--------|
| Tooltip bg          | #FFFFFF                 | bg-white                | Yes    |
| Tooltip border      | #D6D3D1 0.5px          | border-[0.5px] border-stone-300 | Yes |
| Metric label color  | #565656                 | text-foreground         | NO     |
| Bar chart labels    | Inter 500 14px          | MISSING                 | NO     |
```

### Verification with chrome-devtools

After code changes, use `evaluate_script` to verify computed styles match Figma:

```javascript
// Example: Verify metric card label color
const el = document.querySelector('.metric-label');
const style = getComputedStyle(el);
return {
  color: style.color,        // Should be rgb(86, 86, 86) = #565656
  fontSize: style.fontSize,  // Should be "14px"
  fontWeight: style.fontWeight // Should be "600"
};
```

### Verification Checklist

For every component fix:
1. Build comparison table (Figma spec vs current code)
2. Identify ALL mismatches
3. Fix all mismatches
4. Screenshot before and after
5. Programmatic verification via evaluate_script
6. No fix is complete without visual proof

---

## Extracted Component Specs

For extracted component specs, see `.figma-cache/specs/*.yaml`

---

## Extraction Workflow (Quick Reference)

1. **Cache check**: `ls .figma-cache/{fileKey}-{nodeId}.json`
2. **Fetch at depth 5**: `mcp__figma__get_figma_data({ fileKey, nodeId, depth: 5 })`
3. **Save to disk**: Write JSON + extract YAML spec
4. **For every FRAME node**: list ALL children (type, name, fills, layout)
5. **Resolve each child's styles** from globalVars.styles
6. **Build ROLE TABLE**: child name | type | fill resolved | sizing | visual purpose
7. **Compare same-named nodes across instances** to detect state variants
8. **Build COMPARISON TABLE**: every property of every child, Figma vs current code
9. **Fix ALL mismatches**, not just the obvious ones
10. **Visual verify**: chrome-devtools screenshot + evaluate_script
11. **Prove it**: before/after comparison

---

## Common Mistakes

**#1: Inventing content not in Figma**
- Adding labels, headers, or text that don't exist as TEXT nodes
- If it's not a TEXT node in the Figma tree, it does not go in the code

**#2: Selective property extraction**
- Extracting colors and fonts but skipping dimensions, gaps, lineHeight
- Build the EXHAUSTIVE comparison table: every property, not just the obvious ones

**#3: Reading node tree without resolving globalVars.styles**
- The node tree has reference IDs, not values. Always cross-reference.

**#4: Misinterpreting layout modes**
- `layout mode: row` does NOT always mean 2-column grid. Check the screenshot.
- A dialog with `mode: row` may mean header/body/footer stacking

**#5: Skipping dimensions**
- When Figma shows `sizing.horizontal: fixed`, there IS a width. Extract it.
- When Figma shows `gap: 2px`, that's a real constraint. Don't use defaults.

**#6: Skipping separator lines**
- LINE/SVG nodes between rows are real `border-top` separators, not decoration

**#7: Treating multi-child frames as single elements**
- A "Bar" frame with 3 children is NOT one bar. It's a label + cap line + body.
- Each child maps to a separate rendering element in code.
- `showBackground: true` is NOT the same as a separate RECTANGLE child with rgba fill.
- `borderRadius: [4,4,0,0]` is NOT the same as a separate RECTANGLE child for a cap line.
- RULE: Count children in Figma, count elements in code. They MUST match.

---

## Section 4: Full Page Audit Procedure

**Run against ALL visual elements on a page, dialog, or component to find every mismatch.**

### Step 1: Inventory

1. Fetch the page/component container node at depth 5
2. List EVERY visual element (frames, rectangles, texts, instances)
3. Group by component: chart, tooltip, table, metric card, button, etc.
4. For each component, list every child node recursively

### Step 2: Spec Extraction

For each component:
1. Resolve ALL fills, textStyles, layouts from globalVars.styles
2. Build a ROLE TABLE listing each child and its visual purpose
3. Detect state variants (hover, active, disabled) - see Section 0.2
4. Write/update YAML spec in `.figma-cache/specs/`

### Step 3: Code Comparison

For each component:
1. Read the corresponding code file
2. Build COMPARISON TABLE:

```
| Element | Figma Property | Figma Value | Code Value | Match? |
|---------|---------------|-------------|------------|--------|
```

3. Check EVERY property: fills, fonts, sizes, gaps, padding, borderRadius, shadows
4. Mark every mismatch

### Step 4: Mismatch Report

Produce a markdown table:

```
| Component | Element | Property | Figma | Code | Severity |
|-----------|---------|----------|-------|------|----------|
```

Severity levels:
- **CRITICAL**: Wrong visual output (wrong color, missing element, wrong structure)
- **MINOR**: Subtle difference (1px gap, slightly different font weight)
- **OK**: Matches

### Step 5: Fix

1. Fix all CRITICAL mismatches first, then MINOR
2. After each fix: chrome-devtools screenshot, compare to Figma screenshot
3. Verify emphasis/hover states match too

### Audit Template

Use this template for each audit:

```markdown
## Audit: [Component Name]
**Figma node**: [ID]
**Code file**: [path:lines]
**Screenshot**: [.figma-cache path]

### Child Decomposition
| Child | Type | Figma Fill | Figma Layout | Code Element | Match? |
|-------|------|-----------|-------------|-------------|--------|

### Property Comparison
| Element | Property | Figma | Code | Match? |
|---------|----------|-------|------|--------|

### State Variants
| State | Trigger | Figma Fill | Code Implementation | Match? |
|-------|---------|-----------|-------------------|--------|

### Findings
- [ ] Finding 1: description
- [ ] Finding 2: description
```

---

## Section 5: Pixel Diff (Objective Verification)

**Run after visual comparison to get precise, measurable mismatch data.**

Replaces subjective "looks close" with exact data: "RMSE 12.4, 3.2% pixels differ."

### Step 1: Download Figma Node as PNG

```
mcp__figma__download_figma_images({
  fileKey: "YOUR_FILE_KEY",
  nodes: [{ nodeId: "YOUR_NODE_ID", fileName: "component-figma" }],
  localPath: ".figma-cache/"
})
```

Result: `.figma-cache/component-figma.png`

### Step 2: Take Browser Screenshot

Navigate to the page and capture:

```
mcp__chrome-devtools__take_screenshot({ filePath: ".test-artifacts/component-browser.png" })
```

To crop to a specific element (get X/Y/W/H from snapshot or evaluate_script):

```bash
/opt/homebrew/bin/magick .test-artifacts/component-browser.png \
  -crop 320x600+0+64 .test-artifacts/component-browser-cropped.png
```

### Step 3: Run Pixel Diff

```bash
bash scripts/figma-diff.sh \
  .figma-cache/component-figma.png \
  .test-artifacts/component-browser.png \
  .test-artifacts/
```

Output files:
- `.test-artifacts/component-figma-scaled.png` - browser resized to Figma dimensions
- `.test-artifacts/component-figma-diff.png` - red = mismatch pixels
- `.test-artifacts/component-figma-composite.png` - [Figma | Browser | Diff] side-by-side

Stdout:
```
RMSE:      12.4 (12.4)
Dims:      320x600 (Figma to browser scaled to match)
Composite: .test-artifacts/component-figma-composite.png
```

### Step 4: Read Composite with Vision

```
Read: .test-artifacts/component-figma-composite.png
```

Claude identifies specific mismatches from the red overlay regions:

> "Left (Figma): gap between items is 12px. Right (browser): gap is 8px.
> Red band visible at each item separator. Fix: Component.tsx:47 gap-2 to gap-3."

### Key Details

- **Scale normalization**: Figma exports at 1x; browser screenshots may be retina (2x). Script force-resizes browser to Figma dimensions before diffing.
- **Fuzz 5%**: Tolerates anti-aliasing noise. Real spacing/color errors still show clearly.
- **RMSE 0**: Perfect match. RMSE > 20: significant differences worth investigating.
- **No npm changes**: pure bash + ImageMagick (`/opt/homebrew/bin/magick`).

### Quick Reference

```bash
# Full flow
bash scripts/figma-diff.sh <figma.png> <browser.png> [output-dir]

# Then read result
# Read: .test-artifacts/{name}-composite.png
```
