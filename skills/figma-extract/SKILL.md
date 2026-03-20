---
name: figma-extract
description: Exhaustive Figma node extraction: download every detail down to leaf nodes and cache everything locally. Call Figma once, never twice. Use before any pixel-perfect implementation. Prioritizes complete local dumps over repeated API calls.
---

# Figma Exhaustive Extraction Skill

**Goal:** One complete local dump of every Figma detail. Zero repeat API calls.

---

## The Law: Cache First, Always

Before ANY Figma MCP call, check the local cache. If data exists and is < 7 days old, use it.
Never fetch what you already have.

```bash
# Check before every call
ls .figma-cache/{fileKey}-{nodeId}.json 2>/dev/null && echo "CACHED" || echo "FETCH"
```

If cached: read from disk, skip the MCP call entirely.
If not cached: fetch, save immediately, then proceed.

---

## Step 0: Parse the URL

Extract `fileKey` and `nodeId` from any Figma URL:

```
https://figma.com/design/:fileKey/:fileName?node-id=1234-5678
  fileKey = everything between /design/ and the next /
  nodeId  = node-id param with - replaced by :  (1234-5678 becomes 1234:5678)
```

---

## Step 1: Get Full Design Context (Primary Call)

This is the most data-rich call. Do it first. Save everything.

```
mcp__plugin_figma_figma__get_design_context({
  fileKey: "...",
  nodeId: "...",
  clientLanguages: "typescript",
  clientFrameworks: "react"
})
```

Immediately after the call, save the ENTIRE raw response:

```bash
mkdir -p .figma-cache/specs .figma-cache/screenshots .figma-cache/icons
```

Write the full response JSON to:
`.figma-cache/{fileKey}-{nodeId}-context.json`

Write any screenshot data to:
`.figma-cache/screenshots/{nodeId}.png`

This single call returns: reference code, screenshot, component hierarchy, style references, and asset download URLs. Extract ALL of these before making any other calls.

---

## Step 2: Get Screenshot (if not included in Step 1)

```
mcp__plugin_figma_figma__get_screenshot({
  fileKey: "...",
  nodeId: "...",
  clientLanguages: "typescript",
  clientFrameworks: "react"
})
```

Save image to: `.figma-cache/screenshots/{nodeId}.png`

---

## Step 3: Get Variable Definitions

```
mcp__plugin_figma_figma__get_variable_defs({
  fileKey: "...",
  nodeId: "..."
})
```

Save full response to: `.figma-cache/{fileKey}-{nodeId}-vars.json`

This contains all design tokens (colors, spacing, typography) as named variables.
Map these to the project's CSS custom properties or Tailwind tokens.

---

## Step 4: Get Metadata (Structure Map)

```
mcp__plugin_figma_figma__get_metadata({
  fileKey: "...",
  nodeId: "..."
})
```

Save full response to: `.figma-cache/{fileKey}-{nodeId}-meta.json`

The metadata is large. Use it to identify ALL child node IDs that need separate extraction.
Do NOT read the entire metadata response into context. Grep for specific node IDs instead:

```bash
# Find all frame/component nodeIds in the metadata
jq '[.. | objects | select(.type == "FRAME" or .type == "COMPONENT") | {id, name, type}]' \
  .figma-cache/{fileKey}-{nodeId}-meta.json > .figma-cache/{nodeId}-child-ids.json
```

---

## Step 5: Extract Each Child Component

For each child node ID found in Step 4, run `get_design_context` in batches.
Save each result before moving to the next.

Batch protocol:
- Fetch 5 child nodes at a time
- Save all 5 before fetching the next 5
- Skip any nodeId that already has a cache file

```bash
# Check which children are already cached
for id in {node_ids}; do
  [ -f ".figma-cache/{fileKey}-${id}-context.json" ] && echo "skip $id" || echo "fetch $id"
done
```

---

## Step 6: Extract Icons

From the design context responses, collect all asset download URLs. These are SVG/PNG exports
of icon components. Download them all:

```bash
# URLs come from get_design_context response in the assets field
# Download each to .figma-cache/icons/
curl -o ".figma-cache/icons/{icon-name}.svg" "{download-url}"
```

Name icons by their Figma node name, lowercased, spaces to hyphens.

---

## Step 7: Assemble the Master Spec

After all fetches complete, assemble one YAML spec per component:

```yaml
# .figma-cache/specs/{component-name}-{nodeId}.yaml
node_id: "YOUR_NODE_ID"
node_name: "Component Name"
file_key: "YOUR_FILE_KEY"
fetched_at: "2026-01-01"

# From get_variable_defs
design_tokens:
  color/primary: "#0858C9"
  color/success: "#20A58A"
  color/surface: "#FAF9FA"
  spacing/md: "16px"

# From get_design_context - resolved styles
global_styles:
  fill_XXX: "#FFFFFF"
  style_YYY: { fontFamily: "Inter", fontWeight: 600, fontSize: 14 }
  layout_ZZZ: { mode: "column", gap: 8, padding: [16, 16, 16, 16] }

# Component tree (from metadata + design context combined)
children:
  - id: "CHILD_NODE_1"
    name: "Sidebar"
    type: "FRAME"
    cached: ".figma-cache/{fileKey}-CHILD_NODE_1-context.json"
  - id: "CHILD_NODE_2"
    name: "Card"
    type: "COMPONENT"
    cached: ".figma-cache/{fileKey}-CHILD_NODE_2-context.json"

# Icons found
icons:
  - name: "bookmark"
    path: ".figma-cache/icons/bookmark.svg"
  - name: "check-circle"
    path: ".figma-cache/icons/check-circle.svg"

# Screenshot
screenshot: ".figma-cache/screenshots/YOUR_NODE_ID.png"
```

---

## Step 8: Map Tokens to Project Design System

After extracting Figma variables, map them to the project's existing tokens:

| Figma Variable | Figma Value | Project Token | Tailwind Class |
|----------------|-------------|---------------|----------------|
| color/primary | #0858C9 | `--color-primary` | `text-primary` / `bg-primary` |
| color/success | #20A58A | `--color-success` | `text-green-600` |
| color/surface | #FAF9FA | `bg-surface-accent` | `bg-surface-accent` |
| color/border | #EBEAEB | `bg-border` | `border-border` |

Check the project's CSS variables file first:
```bash
grep -r "css\|:root\|--color" src/index.css src/styles/ --include="*.css" | head -30
```

---

## Cache File Inventory

After extraction, verify completeness:

```bash
echo "=== Context files ===" && ls .figma-cache/*-context.json | wc -l
echo "=== Specs ===" && ls .figma-cache/specs/*.yaml | wc -l
echo "=== Screenshots ===" && ls .figma-cache/screenshots/*.png | wc -l
echo "=== Icons ===" && ls .figma-cache/icons/*.svg | wc -l
```

If any count is 0 when you expect data, investigate before proceeding.

---

## Anti-Patterns

- Calling get_metadata without saving the result: it is 1MB+, don't lose it
- Reading full metadata into context: grep/jq it from disk, don't parse in context
- Fetching the same nodeId twice: always check cache first
- Making more than 5 MCP calls without saving: save after every call, no exceptions
- Inventing any property: if it's not in the fetched data, it does not go in the code

---

## Quick Start (Copy-Paste)

```bash
# 1. Set variables
FILE_KEY="YOUR_FILE_KEY"
NODE_ID="YOUR_NODE_ID"

# 2. Create cache dirs
mkdir -p .figma-cache/specs .figma-cache/screenshots .figma-cache/icons

# 3. Check cache
ls .figma-cache/${FILE_KEY}-${NODE_ID}-context.json 2>/dev/null \
  && echo "CACHED - skip fetch" \
  || echo "MISSING - call get_design_context"

# 4. After fetch, extract child IDs from metadata
jq '[.. | objects | select(.type? == "FRAME" or .type? == "COMPONENT") | {id, name, type}]' \
  .figma-cache/${FILE_KEY}-${NODE_ID}-meta.json \
  > .figma-cache/${NODE_ID}-children.json

# 5. Show what needs fetching vs cached
cat .figma-cache/${NODE_ID}-children.json | \
  jq -r '.[].id' | \
  while read id; do
    [ -f ".figma-cache/${FILE_KEY}-${id}-context.json" ] \
      && echo "cached: $id" \
      || echo "NEEDED: $id"
  done
```

---

## Relationship to figma-verification

This skill (figma-extract) handles data collection: getting everything from Figma and saving it locally.

`figma-verification` handles implementation verification: comparing Figma specs against running code using the pixel diff pipeline.

Run `figma-extract` first to build the complete local cache, then use `figma-verification` to verify the implementation against that cache.
